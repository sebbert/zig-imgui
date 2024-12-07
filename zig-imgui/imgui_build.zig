const std = @import("std");

// @src() is only allowed inside of a function, so we need this wrapper
fn srcFile() []const u8 {
    return @src().file;
}
const sep = std.fs.path.sep_str;

const zig_imgui_path = std.fs.path.dirname(srcFile()).?;
const zig_imgui_file = zig_imgui_path ++ sep ++ "imgui.zig";

pub fn addImguiModule(b: *std.Build) *std.Build.Module {
    const module = b.addModule("imgui", std.Build.Module.CreateOptions{
        .root_source_file = b.path(zig_imgui_file),
    });
    return module;
}

pub fn link(exe: *std.Build.Step.Compile, imgui_module: *std.Build.Module) void {
    linkWithoutPackage(exe);
    exe.root_module.linkLibrary(library: *Step.Compile)
}

pub fn linkWithoutPackage(exe: *std.Build.Step.Compile) void {
    const imgui_cpp_file = zig_imgui_path ++ sep ++ "cimgui_unity.cpp";

    exe.linkLibCpp();
    exe.addCSourceFile(imgui_cpp_file, &[_][]const u8{
        "-fno-sanitize=undefined",
        "-ffunction-sections",
    });
}

pub fn addTestStep(
    b: *std.Build,
    step_name: []const u8,
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
) void {
    const test_exe = b.addTest(zig_imgui_path ++ std.fs.path.sep_str ++ "tests.zig");
    test_exe.setBuildMode(optimize);
    test_exe.setTarget(target);

    link(test_exe);

    const test_step = b.step(step_name, "Run zig-imgui tests");
    test_step.dependOn(&test_exe.step);
}
