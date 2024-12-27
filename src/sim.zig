const std = @import("std");
const ptcl = @import("./particle.zig");

const Instant = std.time.Instant;
const ParticleType = ptcl.Particle;
const ParticleSimTick = std.EnumArray(ParticleType, bool);

pub fn simulateParticles(comptime S: type, state: *S) !void {
    const elapsed = (try Instant.now()).since(state.startTime);

    // for each particle type determine whether it should simulate this tick based on it's frequency
    var simThisTick: ParticleSimTick = ParticleSimTick.initFill(false);
    var it = simThisTick.iterator();
    while (it.next()) |entry| {
        const particle = entry.key;
        const particleLastTick = state.lastTick.get(particle);
        const particleFreq = particle.freq();
        // const tickRemainder = state.tickRemainder.get(Particle.sand);

        if (elapsed > particleLastTick + particleFreq) {
            simThisTick.set(particle, true);
            state.lastTick.set(particle, elapsed);
            // const newTickRemainder = elapsed - lastTick; - Particle.sand.freq();
            // state.tickRemainder.set(Particle.sand, newTickRemainder);
        }
    }

    // do the simulation bottom to top for falling particles
    var h: i32 = @as(i32, state.mapHeight) - 1;
    while (h >= 0) : (h -= 1) {
        const hInd: usize = @intCast(h);
        for (0..state.mapWidth) |wInd| {
            switch (state.map[hInd][wInd]) {
                ParticleType.sand => if (simThisTick.get(ParticleType.sand)) sand(S, state, wInd, hInd),
                else => continue,
            }
        }
    }
}

fn sand(comptime S: type, state: *S, x: usize, y: usize) void {
    if (y + 1 >= state.mapHeight) return;

    const targets = [3]struct { x: usize, y: usize }{
        .{ .x = x, .y = y + 1 }, // down
        .{ .x = x - 1, .y = y + 1 }, // down-left
        .{ .x = x + 1, .y = y + 1 }, // down-right
    };

    for (targets) |t| {
        if (state.map[t.y][t.x] == ParticleType.none) {
            state.map[y][x] = ParticleType.none;
            state.map[t.y][t.x] = ParticleType.sand;
            return;
        }
    }
}
