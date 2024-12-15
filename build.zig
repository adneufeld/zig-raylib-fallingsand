const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.host;
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = std.builtin.OptimizeMode.Debug,
    });

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    // RAYLIB START - See https://github.com/Not-Nik/raylib-zig?tab=readme-ov-file#building-and-using
    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
    // RAYLIB END

    b.installArtifact(exe);
}
