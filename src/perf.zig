const ds = @import("./datastructs.zig");
const std = @import("std");
const time = std.time;

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;
const Timer = time.Timer;

const ENTRIES: usize = 60;
const RingBuff = ds.RingBuffer(u64, ENTRIES);

pub const RollingAverage = struct {
    ringBuff: RingBuff = RingBuff{},

    pub fn put(r: *RollingAverage, val: u64) void {
        r.ringBuff.put(val);
    }

    pub fn average(r: *RollingAverage) f64 {
        if (r.ringBuff.count <= 0) return 0;

        var acc: u64 = 0;
        for (0..r.ringBuff.count) |i| {
            acc += r.ringBuff.items[i];
        }
        return @as(f64, @floatFromInt(acc)) / @as(f64, @floatFromInt(r.ringBuff.count));
    }
};

test "RollingAverage small count" {
    var ravg = RollingAverage{};

    ravg.put(1);
    ravg.put(1);
    ravg.put(1);
    try expectEqual(ravg.average(), 1);
}

test "RollingAverage over capacity" {
    var ravg = RollingAverage{};
    for (0..ENTRIES) |_| {
        ravg.put(1);
    }
    const val = 1_000_000_000_000;
    ravg.put(val);
    try expectEqual(ravg.ringBuff.items[0], val);
    try expect(ravg.average() > 1000);
}

pub const RollingStepTimer = struct {
    ravg: RollingAverage,
    timer: Timer,
    name: []const u8,

    pub fn init(name: []const u8) Timer.Error!RollingStepTimer {
        return RollingStepTimer{
            .ravg = RollingAverage{},
            .timer = try Timer.start(),
            .name = name,
        };
    }

    pub fn reset(r: *RollingStepTimer) void {
        r.timer.reset();
    }

    pub fn step(r: *RollingStepTimer) void {
        const stepNanos = r.timer.lap();
        r.ravg.put(stepNanos);
    }

    pub fn average(r: *RollingStepTimer) f64 {
        return r.ravg.average();
    }

    const nsToMs = @as(f64, @floatFromInt(time.ns_per_ms));

    pub fn format(
        r: *RollingStepTimer,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const avgMs: f64 = r.average() / nsToMs;
        try writer.print("{s}: {d:.2}ms", .{ r.name, avgMs });
    }
};

// test "RollingStepTimer" {
//     var t = try RollingStepTimer.init("test 1");
//     for (0..1000) |_| {
//         t.reset();
//         std.time.sleep(1 * time.ns_per_ms);
//         t.step();
//     }
//     std.debug.print("asdf{}", .{&t});
// }
