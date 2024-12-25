const std = @import("std");
const rl = @import("raylib");

var list = std.ArrayList(i32);

fn GameState(comptime screenWidth: u16, comptime screenHeight: u16, comptime tileSize: u8) type {
    return struct {
        const Self = @This();
        const mapWidth = screenWidth / tileSize;
        const mapHeight = screenHeight / tileSize;

        alloc: std.mem.Allocator,

        mapWidth: u16 = mapWidth,
        mapHeight: u16 = mapHeight,
        map: [mapHeight][mapWidth]Pixel = undefined,

        tileSize: u8 = tileSize,

        pub fn init(alloc: std.mem.Allocator) std.mem.Allocator.Error!Self {
            var new = Self{
                .alloc = alloc,
            };

            for (0..new.mapHeight) |hInd| {
                for (0..new.mapWidth) |wInd| {
                    new.map[hInd][wInd] = Pixel.none;
                }
            }

            return new;
        }
    };
}

const Pixel = enum(u8) {
    none = 0,
    sand,

    pub fn color(self: Pixel) rl.Color {
        return switch (self) {
            Pixel.none => rl.Color.black,
            Pixel.sand => rl.Color.init(191, 164, 94, 255),
        };
    }
};

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 456;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const state = try GameState(screenWidth, screenHeight, 8).init(arena.allocator());

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        for (0..state.mapHeight) |hInd| {
            for (0..state.mapWidth) |wInd| {
                const x: i32 = @as(i32, @intCast(wInd)) * state.tileSize;
                const y: i32 = @as(i32, @intCast(hInd)) * state.tileSize;
                rl.drawRectangle(x, y, state.tileSize, state.tileSize, state.map[hInd][wInd].color());
            }
        }

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
