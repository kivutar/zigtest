const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable(.{
        .name = "zigtest",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    exe.addIncludePath("src");
    exe.addIncludePath("/usr/local/include/");

    exe.linkLibC();
    exe.linkSystemLibrary("dl");

    switch (builtin.target.os.tag) {
        .linux => {
            exe.addLibraryPath("/usr/lib");
            exe.addLibraryPath("/usr/lib/x86_64-linux-gnu");
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("glfw3");
        },
        .macos => {
            exe.addIncludePath("/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/OpenGL.framework/Headers");
            exe.addIncludePath("/System/Library/Frameworks/OpenGL.framework/Headers/");
            exe.addIncludePath("/opt/homebrew/Cellar/glfw/3.3.8/include/");
            exe.addFrameworkPath("/System/Library/Frameworks");
            exe.linkFramework("OpenGL");
            exe.linkSystemLibrary("glfw");
        },
        .windows => {
            exe.linkSystemLibrary("glfw3");
            exe.linkSystemLibrary("c");
            exe.linkSystemLibrary("opengl32");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("shell32");
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
