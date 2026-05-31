const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const stdiv = b.addModule("stdiv", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // const exe = b.addExecutable(.{
    //     .name = "stdiv",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/main.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "stdiv", .module = mod },
    //         },
    //     }),
    // });
    //
    // b.installArtifact(exe);
    //
    // const run_step = b.step("run", "Run the app");
    //
    // const run_cmd = b.addRunArtifact(exe);
    // run_step.dependOn(&run_cmd.step);
    //
    // run_cmd.step.dependOn(b.getInstallStep());
    //
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }
    //

    const stdiv_tests = b.addTest(.{
        .root_module = stdiv,
    });

    const run_stdiv_tests = b.addRunArtifact(stdiv_tests);

    // const exe_tests = b.addTest(.{
    //     .root_module = exe.root_module,
    // });
    //
    // const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_stdiv_tests.step);
    // test_step.dependOn(&run_exe_tests.step);
}
