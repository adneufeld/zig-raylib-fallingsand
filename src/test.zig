// To have a package tested ensure it is imported here so the below search finds it

test {
    @import("std").testing.refAllDecls(@This());
}
