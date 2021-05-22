const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
    @cInclude("libretro.h");
    switch (std.Target.current.os.tag) {
        .macos => {
            @cInclude("OpenGL/gl.h");
        },
        .linux => {
            @cInclude("GL/gl.h");
        },
        else => {
            @panic("unsupported system");
        },
    }
});
const panic = std.debug.panic;

var window: *c.GLFWwindow = undefined;

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    panic("Error: {}\n", .{description});
}

fn keyCallback(win: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    if (action != c.GLFW_PRESS) return;

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(win, c.GL_TRUE),
        else => {},
    }
}

pub fn main() !void {
    _ = c.glfwSetErrorCallback(errorCallback);

    if (c.glfwInit() == c.GL_FALSE) {
        panic("GLFW init failure\n", .{});
    }
    defer c.glfwTerminate();

    window = c.glfwCreateWindow(320, 240, "zigarch", null, null) orelse {
        panic("unable to create window\n", .{});
    };
    defer c.glfwDestroyWindow(window);

    _ = c.glfwSetKeyCallback(window, keyCallback);
    c.glfwMakeContextCurrent(window);

    var lib = try std.DynLib.open("/Users/kivutar/ludo/cores/snes9x_libretro.dylib");
    defer lib.close();

    const retro_init = lib.lookup(fn () callconv(.C) void, "retro_init") orelse return error.SymbolNotFound;
    //retro_init();

    c.glfwSwapInterval(1);
    c.glClearColor(0.0, 0.0, 0.0, 1.0);

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glfwPollEvents();
        c.glfwSwapBuffers(window);
    }
}
