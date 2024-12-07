const std = @import("std");
const builtin = @import("builtin");
const path = std.fs.path;
const LibExeObjStep = std.build.LibExeObjStep;

const imgui_build = @import("zig-imgui/imgui_build.zig");

const glslc_command = if (builtin.os.tag == .windows) "tools/win/glslc.exe" else "glslc";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    imgui_build.addTestStep(b, "test", optimize, target);

    {
        const exe = exampleExe(b, "example_glfw_vulkan", optimize, target);
        linkGlfw(exe, target);
        linkVulkan(exe, target);
    }
    {
        const exe = exampleExe(b, "example_glfw_opengl3", optimize, target);
        linkGlfw(exe, target);
        linkGlad(exe, target);
    }
}

fn exampleExe(
    b: *std.Build,
    comptime name: []const u8,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
) *LibExeObjStep {
    const exe = b.addExecutable(name, std.Build.ExecutableOptions{
        .root_source_file = b.path("examples/" ++ name ++ ".zig"),
        .target = target,
        .optimize = optimize,
        .name = name,
    });
    imgui_build.link(exe);
    exe.install();

    const run_step = b.step(name, "Run " ++ name);
    const run_cmd = exe.run();
    run_step.dependOn(&run_cmd.step);

    return exe;
}

fn linkGlad(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    _ = target;
    exe.addIncludeDir("examples/include/c_include");
    exe.addCSourceFile("examples/c_src/glad.c", &[_][]const u8{"-std=c99"});
    //exe.linkSystemLibrary("opengl");
}

fn linkGlfw(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    if (target.isWindows()) {
        exe.addObjectFile(if (target.getAbi() == .msvc) "examples/lib/win/glfw3.lib" else "examples/lib/win/libglfw3.a");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shell32");
    } else {
        exe.linkSystemLibrary("glfw");
    }
}

fn linkVulkan(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    if (target.isWindows()) {
        exe.addObjectFile("examples/lib/win/vulkan-1.lib");
    } else {
        exe.linkSystemLibrary("vulkan");
    }
}
