const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zigtest", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addIncludeDir("src");
    exe.addIncludeDir("/usr/local/include");

    exe.linkLibC();
    exe.linkSystemLibrary("dl");

    switch (std.Target.current.os.tag) {
        .linux => {
            exe.addLibPath("/usr/lib");
            exe.addLibPath("/usr/lib/x86_64-linux-gnu");
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("glfw3");
        },
        .macos => {
            exe.addFrameworkDir("/System/Library/Frameworks");
            exe.linkFramework("OpenGL");
            exe.linkSystemLibrary("glfw");
        },
        else => {
            @panic("don't know how to build on your system");
        },
    }
    
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
