const std = @import("std");
const rl = @import("raylib");

pub const Particle = enum(u8) {
    none = 0,
    sand,

    pub fn color(self: Particle) rl.Color {
        return switch (self) {
            Particle.none => rl.Color.black,
            Particle.sand => rl.Color.init(191, 164, 94, 255),
        };
    }

    pub fn freq(self: Particle) u64 {
        return switch (self) {
            // Particle.sand => 1 * std.time.ns_per_s,
            else => 100 * std.time.ns_per_ms,
        };
    }

    pub fn simulate(
        self: Particle,
    ) void {
        switch (self) {
            Particle.sand => return,
            else => return,
        }
    }
};
