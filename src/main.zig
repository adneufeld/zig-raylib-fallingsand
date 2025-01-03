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
const CellularAutomata = sim.CellularAutomata;

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const startTime = try Instant.now();
    var game = GameState.init(startTime);
    rl.initWindow(game.screenWidth, game.screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    rl.setExitKey(rl.KeyboardKey.key_null); // disable close on ESC
    //--------------------------------------------------------------------------------------

    var cells = CellularAutomata.init(&game);
    var uisys = UISystem.init(&game);
    var cmdsys = CmdSystem.init(&game);

    while (!rl.windowShouldClose()) { // Detect window close button
        // Input
        // ---------------------------------------------------------------------------------
        try uisys.input();
        // ---------------------------------------------------------------------------------

        // Update
        //----------------------------------------------------------------------------------
        // const dt = rl.getFrameTime();
        const elapsed = (try Instant.now()).since(game.startTime);

        try cells.simulate(elapsed);
        try uisys.update(elapsed);
        cmdsys.update();

        // TODO - create a little performance tracking util which can be named and keep track of a rolling average

        // how long does update take? Last check ~0.16-0.33ms
        // const updateTime = (try Instant.now()).since(game.startTime);
        // const ms: f64 = (@as(f64, @floatFromInt(updateTime)) - @as(f64, @floatFromInt(elapsed))) / std.time.ns_per_ms;
        // std.log.debug("{d:.2}ms", .{ms});
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        const drawStartTime = try Instant.now();

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

        // how long does draw take? Last check 1.3-3ms avg (9ms rarely)
        const drawEndTime = try Instant.now();
        const ms: f64 = @as(f64, @floatFromInt(drawEndTime.since(drawStartTime))) / std.time.ns_per_ms;
        std.log.debug("{d:.2}ms", .{ms});
        //----------------------------------------------------------------------------------
    }
}
