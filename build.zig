const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lua_dep = b.dependency("lua", .{
        .target = target,
        .release = optimize != .Debug,
    });
    const lua_lib = lua_dep.artifact(if (target.result.os.tag == .windows) "lua54" else "lua");

    // TODO: Use deps instead of vendored source
    const cute_headers_deprecated_dep = b.dependency("cute_headers_deprecated", .{
        .target = target,
        .optimize = optimize,
    });
    // const sokol_dep = b.dependency("sokol", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    const stb_dep = b.dependency("stb", .{
        .target = target,
        .optimize = optimize,
    });
    // const handmade_math_dep = b.dependency("handmade_math", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // const miniaudio_dep = b.dependency("miniaudio", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    const tiny_sound_font_dep = b.dependency("tiny_sound_font", .{
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "jumpmanzero",
        .root_module = exe_mod,
    });

    // TODO: Use deps instead of vendored source
    exe.addIncludePath(lua_dep.path(""));
    exe.addIncludePath(cute_headers_deprecated_dep.path(""));
    // exe.addIncludePath(sokol_dep.path(""));
    exe.addIncludePath(stb_dep.path(""));
    // exe.addIncludePath(handmade_math_dep.path(""));
    // exe.addIncludePath(miniaudio_dep.path(""));
    exe.addIncludePath(tiny_sound_font_dep.path(""));

    // TODO: Use deps instead of vendored source
    exe.addIncludePath(b.path("Jumpman/glad/include"));
    exe.addIncludePath(b.path("Jumpman/glfw-3.3.2.bin.WIN64/include"));
    exe.addIncludePath(b.path("Jumpman/boxer-c/include"));
    exe.addIncludePath(b.path("Jumpman/sokol-gfx-master-0c5bc3a"));
    exe.addIncludePath(b.path("Jumpman/handmademath-1.7.0"));
    exe.addIncludePath(b.path("Jumpman/mini_al-0.8.9"));

    exe.addCSourceFiles(.{
        .files = &.{
            "Jumpman/Jumpman.c",
            "Jumpman/Basic3D.c",
            "Jumpman/logging.c",
            "Jumpman/Main.c",
            "Jumpman/Music.c",
            "Jumpman/Sound.c",
            "Jumpman/SoundBuffer.c",
            "Jumpman/Utilities.c",
            "Jumpman/boxer-c/src/boxer_win.c",
            "Jumpman/glad/src/glad.c",
            "Jumpman/glad/src/glad_wgl.c",
        },
        .flags = &.{
            // ...
        },
    });

    exe.linkLibrary(lua_lib);
    exe.addObjectFile(b.path("Jumpman/glfw-3.3.2.bin.WIN64/lib-vc2015/glfw3dll.lib"));

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
