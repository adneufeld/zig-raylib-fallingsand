// To have a package tested ensure it is imported here so the below search finds it
pub const ds = @import("./datastructs.zig");
pub const perf = @import("./perf.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
