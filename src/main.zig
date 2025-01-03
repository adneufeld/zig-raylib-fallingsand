const std = @import("std");
const rl = @import("raylib");
const state = @import("./state.zig");
const sim = @import("./sim.zig");
const ui = @import("./ui.zig");
const cmd = @import("./cmd.zig");
const perf = @import("./perf.zig");

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

    var updatePerfTimer = try perf.RollingStepTimer.init("update");
    var drawPerfTimer = try perf.RollingStepTimer.init("draw");

    while (!rl.windowShouldClose()) { // Detect window close button
        // Input
        // ---------------------------------------------------------------------------------
        try uisys.input();
        // ---------------------------------------------------------------------------------

        // Update
        //----------------------------------------------------------------------------------
        updatePerfTimer.reset();

        const elapsed = (try Instant.now()).since(game.startTime);
        try cells.simulate(elapsed);
        try uisys.update(elapsed);
        cmdsys.update();

        updatePerfTimer.step();
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        drawPerfTimer.reset();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        // DRAW CELLS
        for (0..game.mapHeight) |hInd| {
            for (0..game.mapWidth) |wInd| {
                const x: i32 = @as(i32, @intCast(wInd));
                const y: i32 = @as(i32, @intCast(hInd));
                const cell = game.map[hInd][wInd];
                var color = cell.type.color();

                if (cell.type == sim.CellType.none) {
                    var numWaterNeighbour: u32 = 0;
                    for (neighbourOffsets) |nOffset| {
                        const nx = x + nOffset.x;
                        const ny = y + nOffset.y;
                        if (nx < 0 or ny < 0 or !cells.insideMap(@intCast(nx), @intCast(ny))) continue;
                        if (game.map[@intCast(ny)][@intCast(nx)].type == sim.CellType.water) {
                            numWaterNeighbour += 1;
                        }
                    }

                    if (numWaterNeighbour >= 4) {
                        color = rl.Color.init(80, 151, 243, 255);
                    }
                }

                rl.drawRectangle(
                    x * game.tileSize,
                    y * game.tileSize,
                    game.tileSize,
                    game.tileSize,
                    color,
                );

                game.map[hInd][wInd].dirty = false;
            }
        }

        // DRAW UI
        uisys.draw();

        drawPerfTimer.step();
        //----------------------------------------------------------------------------------

        std.debug.print("{}, {}\n", .{ &updatePerfTimer, &drawPerfTimer });
    }
}

const neighbourOffsets = [8]struct { x: i32, y: i32 }{
    .{ .x = -1, .y = -1 }, // topleft, then clockwise
    .{ .x = 0, .y = -1 },
    .{ .x = 1, .y = -1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 1, .y = 1 },
    .{ .x = 0, .y = 1 },
    .{ .x = -1, .y = 1 },
    .{ .x = -1, .y = 0 },
};
