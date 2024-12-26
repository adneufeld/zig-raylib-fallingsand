const std = @import("std");
const rl = @import("raylib");

pub const ParticleType = enum(u8) {
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

pub const Particle = struct {
    type: ParticleType = ParticleType.none,
    dirty: bool = false,
};
