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
const CellType = sim.CellType;

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const startTime = try Instant.now();
    var game = GameState.init(startTime);
    rl.initWindow(game.screenWidth, game.screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    rl.setExitKey(rl.KeyboardKey.key_null); // disable close on ESC

    // Render vars
    const camera = rl.Rectangle.init(0, 0, @floatFromInt(game.mapWidth), @floatFromInt(game.mapHeight));
    const screen = rl.Rectangle.init(0, 0, @floatFromInt(game.screenWidth), @floatFromInt(game.screenHeight));
    const origin = rl.Vector2.init(0, 0);
    var screenImage = rl.genImageColor(state.MAP_WIDTH, state.MAP_HEIGHT, rl.Color.black);
    rl.imageFormat(&screenImage, .pixelformat_uncompressed_r8g8b8a8);
    const screenTexture = rl.loadTextureFromImage(screenImage);
    var screenTextureBytes: [state.MAP_HEIGHT * state.MAP_WIDTH * 4]u8 = .{ 0, 0, 0, 255 } ** (state.MAP_HEIGHT * state.MAP_WIDTH);

    //--------------------------------------------------------------------------------------

    var updatePerfTimer = try perf.RollingStepTimer.init("update");
    var drawPerfTimer = try perf.RollingStepTimer.init("draw");

    var cells = CellularAutomata.init(&game);
    var uisys = UISystem.init(&game, &updatePerfTimer, &drawPerfTimer);
    var cmdsys = CmdSystem.init(&game);

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
                const cell = game.map[hInd][wInd];
                const color = cell.color();

                const index: usize = (hInd * game.mapWidth + wInd) * 4;
                screenTextureBytes[index + 0] = color.r;
                screenTextureBytes[index + 1] = color.g;
                screenTextureBytes[index + 2] = color.b;
                screenTextureBytes[index + 3] = 255;

                game.map[hInd][wInd].dirty = false;
            }
        }

        rl.updateTexture(screenTexture, &screenTextureBytes);
        rl.drawTexturePro(screenTexture, camera, screen, origin, 0.0, rl.Color.white);

        // DRAW UI
        try uisys.draw();

        drawPerfTimer.step();
        //----------------------------------------------------------------------------------

        std.debug.print("{}, {} (={d:.2} of 16.67ms MAX)\n", .{ &updatePerfTimer, &drawPerfTimer, (updatePerfTimer.average() + drawPerfTimer.average()) / std.time.ns_per_ms });
    }
}
