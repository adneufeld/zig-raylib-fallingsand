const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const PixelTime = std.EnumArray(PixelType, u64);
const PixelSimTick = std.EnumArray(PixelType, bool);

pub fn GameState(comptime screenWidth: u16, comptime screenHeight: u16, comptime tileSize: u8) type {
    return struct {
        const Self = @This();
        const mapWidth = screenWidth / tileSize;
        const mapHeight = screenHeight / tileSize;

        alloc: Allocator,

        startTime: Instant,

        mapWidth: u16 = mapWidth,
        mapHeight: u16 = mapHeight,
        map: [mapHeight][mapWidth]Pixel = undefined,

        tileSize: u8 = tileSize,

        lastTick: PixelTime = undefined,
        // tickRemainder: PixelTime = undefined,

        pub fn init(alloc: Allocator) !Self {
            const startTime = try Instant.now();
            var new = Self{
                .alloc = alloc,
                .startTime = startTime,
            };

            for (0..mapHeight) |hInd| {
                for (0..mapWidth) |wInd| {
                    if (hInd == 0 and wInd >= mapWidth / 3 and wInd <= mapWidth * 2 / 3) {
                        new.map[hInd][wInd].type = PixelType.sand;
                    }
                }
            }

            return new;
        }

        pub fn simulate(self: *Self) !void {
            var simThisTick: PixelSimTick = PixelSimTick.initFill(false);
            const elapsed = (try Instant.now()).since(self.startTime);

            var it = simThisTick.iterator();
            while (it.next()) |entry| {
                const pixel = entry.key;
                const pixelLastTick = self.lastTick.get(pixel);
                // const tickRemainder = self.tickRemainder.get(Pixel.sand);

                if (elapsed < pixelLastTick + pixel.freq()) {
                    simThisTick.set(pixel, true);
                    self.lastTick.set(pixel, elapsed);
                    // const newTickRemainder = elapsed - lastTick; - Pixel.sand.freq();
                    // self.tickRemainder.set(Pixel.sand, newTickRemainder);
                }
            }

            for (0..self.mapHeight) |hInd| {
                for (0..self.mapWidth) |wInd| {
                    switch (self.map[hInd][wInd].type) {
                        PixelType.sand => if (simThisTick.get(PixelType.sand)) self.sand(wInd, hInd),
                        else => continue,
                    }
                }
            }
        }

        fn sand(self: *Self, x: usize, y: usize) void {
            if (y + 1 >= self.mapHeight or self.map[y][x].dirty == true) return;
            if (self.map[y + 1][x].type == PixelType.none and self.map[y + 1][x].dirty == false) {
                self.map[y][x].type = PixelType.none;
                self.map[y][x].dirty = true;
                self.map[y + 1][x].type = PixelType.sand;
                self.map[y + 1][x].dirty = true;
            }
        }
    };
}

const PixelType = enum(u8) {
    none = 0,
    sand,

    pub fn color(self: PixelType) rl.Color {
        return switch (self) {
            PixelType.none => rl.Color.black,
            PixelType.sand => rl.Color.init(191, 164, 94, 255),
        };
    }

    pub fn freq(self: PixelType) u64 {
        return switch (self) {
            // Pixel.sand => 1 * std.time.ns_per_s,
            else => 1 * std.time.ns_per_s,
        };
    }
};

const Pixel = struct {
    type: PixelType = PixelType.none,
    dirty: bool = false,
};

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 456;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(5); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var state = try GameState(screenWidth, screenHeight, 8)
        .init(arena.allocator());

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // const dt = rl.getFrameTime();
        try state.simulate();

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
                rl.drawRectangle(
                    x,
                    y,
                    state.tileSize,
                    state.tileSize,
                    state.map[hInd][wInd].type.color(),
                );
                state.map[hInd][wInd].dirty = false;
            }
        }

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
