const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    //@cInclude("GLFW/glfw3.h");
    @cInclude("libretro.h");
    switch (builtin.target.os.tag) {
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
    _ = err;
    panic("Error: {s}\n", .{description});
}

fn keyCallback(win: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = scancode;
    _ = mods;
    if (action != c.GLFW_PRESS) return;

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(win, c.GL_TRUE),
        else => {},
    }
}

fn setPixelFormat(format: c_int) bool {
    switch (format) {
        c.RETRO_PIXEL_FORMAT_XRGB8888 => {
            return true;
        },
        else => {
            return false;
        },
    }
}

fn environmentCb(cmd: c_uint, data: ?*anyopaque) callconv(.C) bool {
    switch (cmd) {
        c.RETRO_ENVIRONMENT_SET_PIXEL_FORMAT => {
            return setPixelFormat(@ptrCast(*c_int, data));
        },
        else => {
            std.log.info("env={d}", .{cmd});
            return false;
        },
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

    var lib = try std.DynLib.open("/Users/kivutar/nes/nes_libretro.dylib");
    defer lib.close();

    const retro_set_environment = lib.lookup(fn (c.retro_environment_t) callconv(.C) void, "retro_set_environment") orelse return error.SymbolNotFound;
    retro_set_environment(environmentCb);

    const retro_init = lib.lookup(fn () callconv(.C) void, "retro_init") orelse return error.SymbolNotFound;
    retro_init();

    const retro_load_game = lib.lookup(fn (*const c.retro_game_info) callconv(.C) void, "retro_load_game") orelse return error.SymbolNotFound;
    retro_load_game(&c.retro_game_info{
        .path = "",
        .data = "",
        .size = 0,
        .meta = undefined,
    });

    c.glfwSwapInterval(1);
    c.glClearColor(0.0, 0.0, 0.0, 1.0);

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glfwPollEvents();
        c.glfwSwapBuffers(window);
    }
}
