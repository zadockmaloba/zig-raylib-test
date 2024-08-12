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

    // TODO: Figure out a way to use raylib as a module
    // const raylib = b.dependency("raylib", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    // _ = raylib;

    // const raylib_builder = @import("./thirdparty/raylib/build.zig");

    // const raylib = try raylib_builder.addRaylib(b, target, optimize, .{});

    const exe = b.addExecutable(.{
        .name = "zig-raylib-test",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.addObjectFile(switch (target.result.os.tag) {
        .windows => b.path("./thirdparty/raylib/zig-out/lib/raylib.lib"),
        .linux => b.path("./thirdparty/raylib/zig-out/lib/libraylib.a"),
        .macos => b.path("./thirdparty/raylib/zig-out/lib/libraylib.a"),
        .emscripten => b.path("./thirdparty/raylib/zig-out/lib/libraylib.a"),
        else => @panic("Unsupported OS"),
    });

    exe.addIncludePath(b.path("./thirdparty/raylib/src"));
    exe.addIncludePath(b.path("./thirdparty/raylib/src/external"));
    exe.addIncludePath(b.path("./thirdparty/raylib/src/external/glfw/include"));

    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("winmm");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");

            exe.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .linux => {
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");

            exe.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .macos => {
            exe.linkFramework("Foundation");
            exe.linkFramework("Cocoa");
            exe.linkFramework("OpenGL");
            exe.linkFramework("CoreAudio");
            exe.linkFramework("CoreVideo");
            exe.linkFramework("IOKit");

            exe.defineCMacro("PLATFORM_DESKTOP", null);
        },
        else => {
            @panic("Unsupported OS");
        },
    }

    //exe.root_module.addImport("raylib", raylib.module("raylib"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
    // b.installArtifact(raylib);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

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

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_unit_tests.linkLibC();
    exe_unit_tests.addObjectFile(switch (target.result.os.tag) {
        .windows => b.path("./thirdparty/raylib/zig-out/lib/raylib.lib"),
        .linux => b.path("./thirdparty/raylib/zig-out/lib/libraylib.a"),
        .macos => b.path("./thirdparty/raylib/zig-out/lib/libraylib.a"),
        .emscripten => b.path("./thirdparty/raylib/zig-out/lib/libraylib.a"),
        else => @panic("Unsupported OS"),
    });

    exe_unit_tests.addIncludePath(b.path("./thirdparty/raylib/src"));
    exe_unit_tests.addIncludePath(b.path("./thirdparty/raylib/src/external"));
    exe_unit_tests.addIncludePath(b.path("./thirdparty/raylib/src/external/glfw/include"));

    switch (target.result.os.tag) {
        .windows => {
            exe_unit_tests.linkSystemLibrary("winmm");
            exe_unit_tests.linkSystemLibrary("gdi32");
            exe_unit_tests.linkSystemLibrary("opengl32");

            exe_unit_tests.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .linux => {
            exe_unit_tests.linkSystemLibrary("GL");
            exe_unit_tests.linkSystemLibrary("rt");
            exe_unit_tests.linkSystemLibrary("dl");
            exe_unit_tests.linkSystemLibrary("m");
            exe_unit_tests.linkSystemLibrary("X11");

            exe_unit_tests.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .macos => {
            exe_unit_tests.linkFramework("Foundation");
            exe_unit_tests.linkFramework("Cocoa");
            exe_unit_tests.linkFramework("OpenGL");
            exe_unit_tests.linkFramework("CoreAudio");
            exe_unit_tests.linkFramework("CoreVideo");
            exe_unit_tests.linkFramework("IOKit");

            exe_unit_tests.defineCMacro("PLATFORM_DESKTOP", null);
        },
        else => {
            @panic("Unsupported OS");
        },
    }

    //exe_unit_tests.root_module.addImport("raylib", raylib.module("raylib"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
