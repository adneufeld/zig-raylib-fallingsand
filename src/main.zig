const std = @import("std");
const rl = @import("raylib");
const state = @import("./state.zig");
const sim = @import("./sim.zig");
const ui = @import("./ui.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const UISystem = ui.UISystem;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 456;
const TILE_SIZE = 8;
// const MAP_WIDTH = SCREEN_WIDTH / TILE_SIZE;
// const MAP_HEIGHT = SCREEN_HEIGHT / TILE_SIZE;

pub const State = state.State(SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE);

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    rl.setExitKey(rl.KeyboardKey.key_null); // disable close on ESC
    //--------------------------------------------------------------------------------------

    var game = try State.init();
    var cells = sim.CellularAutomata(State).init(&game);
    var uisys = UISystem(State).init(&game);

    while (!rl.windowShouldClose()) { // Detect window close button
        // Update
        //----------------------------------------------------------------------------------
        // const dt = rl.getFrameTime();
        const elapsed = (try Instant.now()).since(game.startTime);
        try cells.simulate(elapsed);
        uisys.update(elapsed);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        // DRAW CELLS
        for (0..game.mapHeight) |hInd| {
            for (0..game.mapWidth) |wInd| {
                const x: i32 = @as(i32, @intCast(wInd)) * game.tileSize;
                const y: i32 = @as(i32, @intCast(hInd)) * game.tileSize;
                rl.drawRectangle(
                    x,
                    y,
                    game.tileSize,
                    game.tileSize,
                    game.map[hInd][wInd].type.color(),
                );
                game.map[hInd][wInd].dirty = false;
            }
        }

        // DRAW UI
        uisys.draw();

        //----------------------------------------------------------------------------------
    }
}
