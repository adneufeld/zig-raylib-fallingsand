const std = @import("std");
const rl = @import("raylib");
const ptcl = @import("./particle.zig");
const state = @import("./state.zig");
const sim = @import("./sim.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 456;

pub const State = state.State(SCREEN_WIDTH, SCREEN_HEIGHT, 8);

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var game = try State.init();
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // const dt = rl.getFrameTime();
        try sim.simulateParticles(State, &game);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        for (0..game.mapHeight) |hInd| {
            for (0..game.mapWidth) |wInd| {
                const x: i32 = @as(i32, @intCast(wInd)) * game.tileSize;
                const y: i32 = @as(i32, @intCast(hInd)) * game.tileSize;
                rl.drawRectangle(
                    x,
                    y,
                    game.tileSize,
                    game.tileSize,
                    game.map[hInd][wInd].color(),
                );
            }
        }
        //----------------------------------------------------------------------------------
    }
}
