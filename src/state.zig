const std = @import("std");
const ptcl = @import("./particle.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const Particle = ptcl.Particle;
const ParticleTime = std.EnumArray(Particle, u64);

pub fn State(comptime screenWidth: u16, comptime screenHeight: u16, comptime tileSize: u8) type {
    const mapWidth = screenWidth / tileSize;
    const mapHeight = screenHeight / tileSize;

    return struct {
        const Self = @This();

        screenWidth: u16 = screenWidth,
        screenHeight: u16 = screenHeight,

        mapWidth: u16 = mapWidth,
        mapHeight: u16 = mapHeight,
        map: [mapHeight][mapWidth]Particle = undefined,

        tileSize: u8 = tileSize,

        startTime: Instant,
        lastTick: ParticleTime = undefined,
        // tickRemainder: ParticleTime = undefined,

        pub fn init() !Self {
            const startTime = try Instant.now();
            var new = Self{
                .startTime = startTime,
            };

            // little sand column to show our simulation works
            const width = 4;
            const wStart = new.mapHeight / 2 - width / 2;
            const wEnd = new.mapHeight / 2 + width / 2;
            for (0..30) |hInd| {
                for (wStart..wEnd) |wInd| {
                    new.map[hInd][wInd] = Particle.sand;
                }
            }

            return new;
        }
    };
}
