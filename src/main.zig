const std = @import("std");
const rl = @import("raylib");
const state = @import("./state.zig");
const sim = @import("./sim.zig");
const ui = @import("./ui.zig");
const cmd = @import("./cmd.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const GameState = state.GameState;
const UISystem = ui.UISystem;
const CmdSystem = cmd.CmdSystem;

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var game = try GameState.init();
    rl.initWindow(game.screenWidth, game.screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    rl.setExitKey(rl.KeyboardKey.key_null); // disable close on ESC
    //--------------------------------------------------------------------------------------

    var cells = sim.CellularAutomata(GameState).init(&game);
    var uisys = UISystem(GameState).init(&game);
    var cmdsys = CmdSystem.init(&game);

    while (!rl.windowShouldClose()) { // Detect window close button
        // Input
        // ---------------------------------------------------------------------------------
        uisys.input();
        // ---------------------------------------------------------------------------------

        // Update
        //----------------------------------------------------------------------------------
        // const dt = rl.getFrameTime();
        const elapsed = (try Instant.now()).since(game.startTime);

        try cells.simulate(elapsed);
        uisys.update(elapsed);
        cmdsys.update();
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
