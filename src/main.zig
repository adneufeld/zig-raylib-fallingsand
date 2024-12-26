const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const ParticleTime = std.EnumArray(ParticleType, u64);
const ParticleSimTick = std.EnumArray(ParticleType, bool);

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 456;

pub fn GameState(comptime screenWidth: u16, comptime screenHeight: u16, comptime tileSize: u8) type {
    const mapWidth = screenWidth / tileSize;
    const mapHeight = screenHeight / tileSize;

    return struct {
        const Self = @This();

        alloc: Allocator,

        screenWidth: u16 = screenWidth,
        screenHeight: u16 = screenHeight,

        mapWidth: u16 = mapWidth,
        mapHeight: u16 = mapHeight,
        map: [mapHeight][mapWidth]Particle = undefined,

        tileSize: u8 = tileSize,

        startTime: Instant,
        lastTick: ParticleTime = undefined,
        // tickRemainder: ParticleTime = undefined,

        pub fn init(alloc: Allocator) !Self {
            const startTime = try Instant.now();
            var new = Self{
                .alloc = alloc,
                .startTime = startTime,
            };

            const width = 4;
            const wStart = new.mapHeight / 2 - width / 2;
            const wEnd = new.mapHeight / 2 + width / 2;
            for (0..30) |hInd| {
                for (wStart..wEnd) |wInd| {
                    new.map[hInd][wInd].type = ParticleType.sand;
                }
            }

            return new;
        }

        pub fn simulate(self: *Self) !void {
            const elapsed = (try Instant.now()).since(self.startTime);

            // for each particle type determine whether it should simulate this tick based on it's frequency
            var simThisTick: ParticleSimTick = ParticleSimTick.initFill(false);
            var it = simThisTick.iterator();
            while (it.next()) |entry| {
                const particle = entry.key;
                const particleLastTick = self.lastTick.get(particle);
                const particleFreq = particle.freq();
                // const tickRemainder = self.tickRemainder.get(Particle.sand);

                if (elapsed > particleLastTick + particleFreq) {
                    simThisTick.set(particle, true);
                    self.lastTick.set(particle, elapsed);
                    // const newTickRemainder = elapsed - lastTick; - Particle.sand.freq();
                    // self.tickRemainder.set(Particle.sand, newTickRemainder);
                }
            }

            // do the simulation bottom to top for falling particles
            var h: i32 = @as(i32, self.mapHeight) - 1;
            while (h >= 0) : (h -= 1) {
                const hInd: usize = @intCast(h);
                for (0..self.mapWidth) |wInd| {
                    switch (self.map[hInd][wInd].type) {
                        ParticleType.sand => if (simThisTick.get(ParticleType.sand)) self.sand(wInd, hInd),
                        else => continue,
                    }
                }
            }
        }

        fn sand(self: *Self, x: usize, y: usize) void {
            if (y + 1 >= self.mapHeight or self.map[y][x].dirty == true) return;

            const targets = [3]struct { x: usize, y: usize }{
                .{ .x = x, .y = y + 1 }, // down
                .{ .x = x - 1, .y = y + 1 }, // down-left
                .{ .x = x + 1, .y = y + 1 }, // down-right
            };

            for (targets) |t| {
                if (self.map[t.y][t.x].type == ParticleType.none and self.map[t.y][t.x].dirty == false) {
                    self.map[y][x].type = ParticleType.none;
                    // self.map[y][x].dirty = true;
                    self.map[t.y][t.x].type = ParticleType.sand;
                    // self.map[t.y][t.x].dirty = true;
                    return;
                }
            }
        }
    };
}

const ParticleType = enum(u8) {
    none = 0,
    sand,

    pub fn color(self: ParticleType) rl.Color {
        return switch (self) {
            ParticleType.none => rl.Color.black,
            ParticleType.sand => rl.Color.init(191, 164, 94, 255),
        };
    }

    pub fn freq(self: ParticleType) u64 {
        return switch (self) {
            // Particle.sand => 1 * std.time.ns_per_s,
            else => 100 * std.time.ns_per_ms,
        };
    }
};

const Particle = struct {
    type: ParticleType = ParticleType.none,
    dirty: bool = false,
};

pub const State = GameState(SCREEN_WIDTH, SCREEN_HEIGHT, 8);

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var state = try State.init(arena.allocator());

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
        //----------------------------------------------------------------------------------
    }
}
