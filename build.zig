const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const write_files = b.addWriteFiles();

    const glfw_c = b.addTranslateC(.{
        .root_source_file = b.path("Jumpman/glfw-3.3.2.bin.WIN64/include/GLFW/glfw3.h"), // TODO: Use deps instead of vendored source
        .target = target,
        .optimize = optimize,
    });
    glfw_c.defineCMacro("GLFW_INCLUDE_NONE", "");

    const glad_c = b.addTranslateC(.{
        .root_source_file = b.path("Jumpman/glad/include/glad/glad.h"), // TODO: Use deps instead of vendored source
        .target = target,
        .optimize = optimize,
    });

    const sokol_dep = b.dependency("sokol", .{ .target = target, .optimize = optimize });
    const sokol_gfx_include_header = write_files.add("sokol_gfx_include.h",
        \\#include <sokol_gfx.h>
        \\#define ZIG_SKIP_SHADER_DEF
        \\#include "shader.h"
    );
    const sokol_gfx_c = b.addTranslateC(.{
        .root_source_file = sokol_gfx_include_header,
        .target = target,
        .optimize = optimize,
    });
    sokol_gfx_c.addIncludePath(sokol_dep.path(""));
    sokol_gfx_c.addIncludePath(b.path("Jumpman"));

    const miniaudio_dep = b.dependency("miniaudio", .{ .target = target, .optimize = optimize });
    const miniaudio_c = b.addTranslateC(.{
        .root_source_file = miniaudio_dep.path("miniaudio.h"),
        .target = target,
        .optimize = optimize,
    });
    miniaudio_c.defineCMacro("MAL_NO_AVX2", "");

    const tiny_sound_font_dep = b.dependency("tiny_sound_font", .{ .target = target, .optimize = optimize });
    const tiny_sound_font_c = b.addTranslateC(.{
        .root_source_file = tiny_sound_font_dep.path("tsf.h"),
        .target = target,
        .optimize = optimize,
    });
    const tiny_midi_loader_c = b.addTranslateC(.{
        .root_source_file = tiny_sound_font_dep.path("tml.h"),
        .target = target,
        .optimize = optimize,
    });

    const lua_dep = b.dependency("lua", .{
        .target = target,
        .release = optimize != .Debug,
        .shared = false,
    });
    const lua_include_header = write_files.add("lua_include.h",
        \\#include <lua.h>
        \\#include <lualib.h>
        \\#include <lauxlib.h>
    );
    const lua_c = b.addTranslateC(.{
        .root_source_file = lua_include_header,
        .target = target,
        .optimize = optimize,
    });
    lua_c.addIncludePath(lua_dep.builder.dependency("lua", .{}).path("src")); // Dep of dep - TODO: Better way?
    const lua_lib = lua_dep.artifact("lua");

    const stb_dep = b.dependency("stb", .{ .target = target, .optimize = optimize });
    const stb_image_c = b.addTranslateC(.{
        .root_source_file = stb_dep.path("stb_image.h"),
        .target = target,
        .optimize = optimize,
    });

    const boxer_c = b.addTranslateC(.{
        .root_source_file = b.path("Jumpman/boxer-c/include/boxer/boxer.h"), // TODO: Use deps instead of vendored source
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/game/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "boxer_c", .module = boxer_c.createModule() },
            .{ .name = "glad_c", .module = glad_c.createModule() },
            .{ .name = "glfw_c", .module = glfw_c.createModule() },
            .{ .name = "lua_c", .module = lua_c.createModule() },
            .{ .name = "miniaudio_c", .module = miniaudio_c.createModule() },
            .{ .name = "sokol_gfx_c", .module = sokol_gfx_c.createModule() },
            .{ .name = "stb_image_c", .module = stb_image_c.createModule() },
            .{ .name = "tml_c", .module = tiny_midi_loader_c.createModule() },
            .{ .name = "tsf_c", .module = tiny_sound_font_c.createModule() },
        },
    });
    const exe = b.addExecutable(.{
        .name = "jumpmanzero",
        .root_module = exe_mod,
    });

    exe_mod.addCSourceFiles(.{
        .files = &.{
            "Jumpman/boxer-c/src/boxer_win.c",
            "Jumpman/glad/src/glad.c",
            "Jumpman/glad/src/glad_wgl.c",
        },
        .flags = &.{
            // ...
        },
    });
    // TODO: Use deps instead of vendored source
    exe_mod.addIncludePath(b.path("Jumpman/glad/include"));
    exe_mod.addIncludePath(b.path("Jumpman/boxer-c/include"));

    const lib_impl_c_source = write_files.add("lib_impl.c",
        \\#include <math.h>
        \\#include "glad/glad.h"
        \\#define SOKOL_IMPL
        \\#define SOKOL_GLCORE33
        \\#define SOKOL_EXTERNAL_GL_LOADER
        \\#include "sokol_gfx.h"
        \\
        \\#define STB_IMAGE_IMPLEMENTATION
        \\#include "stb_image.h"
        \\
        \\#define MA_NO_AVX2
        \\#define MINIAUDIO_IMPLEMENTATION
        \\#include "miniaudio.h"
        \\
        \\#define TSF_IMPLEMENTATION
        \\#include "tsf.h"
        \\
        \\#define TML_IMPLEMENTATION
        \\#include "tml.h"
    );
    exe_mod.addCSourceFile(.{
        .file = lib_impl_c_source,
        .flags = &.{
            // ...
        },
    });
    exe_mod.addIncludePath(sokol_dep.path(""));
    exe_mod.addIncludePath(stb_dep.path(""));
    exe_mod.addIncludePath(miniaudio_dep.path(""));
    exe_mod.addIncludePath(tiny_sound_font_dep.path(""));

    exe_mod.linkLibrary(lua_lib);
    exe_mod.addObjectFile(b.path("Jumpman/glfw-3.3.2.bin.WIN64/lib-vc2015/glfw3dll.lib"));

    b.installArtifact(exe);

    const glfw_dll = b.addInstallFile(b.path("Jumpman/glfw-3.3.2.bin.WIN64/lib-vc2015/glfw3.dll"), "bin/glfw3.dll"); // TODO: Some way to get the correct install dir?
    b.getInstallStep().dependOn(&glfw_dll.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.cwd = b.path("JumpmanAssets");

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
