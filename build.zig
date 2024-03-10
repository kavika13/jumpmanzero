const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lua_lib = b.addStaticLibrary(.{
        .name = "lua-5.3.5-static",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "Jumpman/lua-5.3.5/src/lapi.c" },
        .target = target,
        .optimize = optimize,
    });

    lua_lib.addIncludePath(.{ .path = "Jumpman/lua-5.3.5/src" });

    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lapi.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lauxlib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lbaselib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lbitlib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lcode.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lcorolib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lctype.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ldblib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ldebug.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ldo.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ldump.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lfunc.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lgc.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/linit.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/liolib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/llex.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lmathlib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lmem.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/loadlib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lobject.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lopcodes.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/loslib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lparser.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lstate.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lstring.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lstrlib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ltable.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ltablib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/ltm.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lundump.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lutf8lib.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lvm.c" }, .flags = &.{} });
    lua_lib.addCSourceFile(.{ .file = .{ .path = "Jumpman/lua-5.3.5/src/lzio.c" }, .flags = &.{} });

    lua_lib.linkLibC();

    const exe = b.addExecutable(.{
        .name = "jumpmanzero",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "Jumpman/Jumpman.c" },
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(.{ .path = "Jumpman/glad/include" });
    exe.addIncludePath(.{ .path = "Jumpman/glfw-3.3.2.bin.WIN64/include" });
    exe.addIncludePath(.{ .path = "Jumpman/boxer-c/include" });
    exe.addIncludePath(.{ .path = "Jumpman/handmademath-1.7.0" });
    exe.addIncludePath(.{ .path = "Jumpman/stb-image-2.19.0" });
    exe.addIncludePath(.{ .path = "Jumpman/stb-sprintf-1.06.0" });
    exe.addIncludePath(.{ .path = "Jumpman/sokol-gfx-master-0c5bc3a" });
    exe.addIncludePath(.{ .path = "Jumpman/mini_al-0.8.9" });
    exe.addIncludePath(.{ .path = "Jumpman/tiny_sound_font-master-5506592" });
    exe.addIncludePath(.{ .path = "Jumpman/cute_files-6760a7d" });
    exe.addIncludePath(.{ .path = "Jumpman/lua-5.3.5/src" });

    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/Basic3D.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/Jumpman.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/logging.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/Main.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/Music.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/Sound.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/SoundBuffer.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/Utilities.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/boxer-c/src/boxer_win.c" }, .flags = &.{} }); // TODO: Linux or OSX if applicable
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/glad/src/glad.c" }, .flags = &.{} });
    exe.addCSourceFile(.{ .file = .{ .path = "Jumpman/glad/src/glad_wgl.c" }, .flags = &.{} });

    exe.addObjectFile(.{ .path = "Jumpman/glfw-3.3.2.bin.WIN64/lib-vc2015/glfw3dll.lib" });

    exe.linkLibrary(lua_lib);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // Install DLL along with exe
    const zig_dll = b.addInstallFile(.{ .path = "Jumpman/glfw-3.3.2.bin.WIN64/lib-vc2015/glfw3.dll" }, "bin/glfw3.dll"); // TODO: Some way to get the correct install dir?
    b.getInstallStep().dependOn(&zig_dll.step);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.cwd = "JumpmanAssets";

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // TODO: Unit tests
    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_unit_tests = b.addRunArtifact(unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_unit_tests.step);
}
