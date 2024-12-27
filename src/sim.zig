const std = @import("std");
const ptcl = @import("./particle.zig");

const Instant = std.time.Instant;
const ParticleType = ptcl.Particle;
const ParticleSimTick = std.EnumArray(ParticleType, bool);

pub fn CellularAutomata(comptime S: type) type {
    return struct {
        const Self = @This();

        state: *S,

        pub fn init(state: *S) Self {
            return Self{
                .state = state,
            };
        }

        pub fn simulate(self: *Self, elapsed: u64) !void {
            var simThisTick: ParticleSimTick = self.doesParticleSimulate(elapsed);

            // do the simulation bottom to top for falling particles
            var h: i32 = @as(i32, self.state.mapHeight) - 1;
            while (h >= 0) : (h -= 1) {
                const hInd: usize = @intCast(h);
                for (0..self.state.mapWidth) |wInd| {
                    switch (self.state.map[hInd][wInd]) {
                        ParticleType.sand => if (simThisTick.get(ParticleType.sand)) self.sand(wInd, hInd),
                        else => continue,
                    }
                }
            }
        }

        // Whether each particle type should simulate their cellular automata on this specific update tick
        fn doesParticleSimulate(self: *Self, elapsed: u64) ParticleSimTick {
            var simThisTick = ParticleSimTick.initFill(false);
            var it = simThisTick.iterator();
            while (it.next()) |entry| {
                const particle = entry.key;
                const particleLastTick = self.state.lastTick.get(particle);
                const particleFreq = particle.freq();
                // const tickRemainder = state.tickRemainder.get(Particle.sand);

                if (elapsed > particleLastTick + particleFreq) {
                    simThisTick.set(particle, true);
                    self.state.lastTick.set(particle, elapsed);
                    // const newTickRemainder = elapsed - lastTick; - Particle.sand.freq();
                    // state.tickRemainder.set(Particle.sand, newTickRemainder);
                }
            }
            return simThisTick;
        }

        fn sand(self: *Self, x: usize, y: usize) void {
            if (y + 1 >= self.state.mapHeight) return;

            const targets = [3]struct { x: usize, y: usize }{
                .{ .x = x, .y = y + 1 }, // down
                .{ .x = x - 1, .y = y + 1 }, // down-left
                .{ .x = x + 1, .y = y + 1 }, // down-right
            };

            for (targets) |t| {
                if (self.state.map[t.y][t.x] == ParticleType.none) {
                    self.state.map[y][x] = ParticleType.none;
                    self.state.map[t.y][t.x] = ParticleType.sand;
                    return;
                }
            }
        }
    };
}
