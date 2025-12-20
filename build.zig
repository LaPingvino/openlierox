const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build options
    const dedicated_only = b.option(bool, "dedicated-only", "Build dedicated server only (no graphics/sound)") orelse false;
    const enable_x11 = b.option(bool, "x11", "Enable X11 clipboard/notify support") orelse !dedicated_only;
    const enable_breakpad = b.option(bool, "breakpad", "Enable Google Breakpad crash reporting") orelse false;
    const enable_linenoise = b.option(bool, "linenoise", "Enable linenoise (readline replacement)") orelse true;
    const disable_joystick = b.option(bool, "disable-joystick", "Disable joystick support") orelse false;

    // Create main module for C++ code
    const exe = b.addExecutable(.{
        .name = "openlierox",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add all C++ source files recursively
    const src_dirs = [_][]const u8{
        "src/breakpad",
        "src/client",
        "src/common",
        "src/game",
        "src/gui",
        "src/gusanos",
        "src/level",
        "src/server",
        "src/sound",
        "src/util",
    };

    // Add main files
    exe.root_module.addCSourceFile(.{ .file = b.path("src/main.cpp"), .flags = getCxxFlags(target, optimize) });
    exe.root_module.addCSourceFile(.{ .file = b.path("src/MainLoop.cpp"), .flags = getCxxFlags(target, optimize) });

    // Add all source directories
    for (src_dirs) |src_dir| {
        addSourcesRecursive(b, exe, src_dir, target, optimize);
    }

    // Add macOS Objective-C files if targeting macOS
    if (target.result.os.tag == .macos) {
        exe.root_module.addCSourceFile(.{ .file = b.path("src/MacMain.m"), .flags = &.{"-ObjC"} });
    }

    // Include directories
    exe.root_module.addIncludePath(b.path("include"));
    exe.root_module.addIncludePath(b.path("src"));
    exe.root_module.addIncludePath(b.path("optional-includes/generated"));
    exe.root_module.addIncludePath(b.path("libs/pstreams"));

    // System library includes
    // libxml2 headers are typically in /usr/include/libxml2 on Linux
    if (target.result.os.tag != .windows) {
        exe.root_module.addSystemIncludePath(.{ .cwd_relative = "/usr/include/libxml2" });
    }

    // Builtin libraries (vendored)
    addHawkNL(b, exe, target, optimize);
    addLibZip(b, exe, target, optimize);
    addLua(b, exe, target, optimize);

    if (enable_linenoise) {
        exe.root_module.addCSourceFile(.{ .file = b.path("libs/linenoise/linenoise.cpp"), .flags = getCxxFlags(target, optimize) });
        exe.root_module.addIncludePath(b.path("libs/linenoise"));
        exe.root_module.addCMacro("HAVE_LINENOISE", "");
    }

    if (enable_breakpad) {
        exe.root_module.addIncludePath(b.path("libs/breakpad/src"));
        exe.root_module.addIncludePath(b.path("optional-includes/breakpad"));
        exe.root_module.addCMacro("BP_LOGGING_INCLUDE", "\"breakpad_logging.h\"");
        // TODO: Add breakpad sources
    } else {
        exe.root_module.addCMacro("NBREAKPAD", "");
    }

    // System libraries - these will be linked, not vendored
    linkSystemLibraries(b, exe, target, dedicated_only, enable_x11);

    // Compiler flags and defines
    exe.root_module.addCMacro("SYSTEM_DATA_DIR", "\"/usr/share/games\"");

    if (optimize == .Debug) {
        exe.root_module.addCMacro("DEBUG", "1");
    }

    if (dedicated_only) {
        exe.root_module.addCMacro("DEDICATED_ONLY", "");
    }

    if (enable_x11) {
        exe.root_module.addCMacro("X11", "");
    }

    if (disable_joystick) {
        exe.root_module.addCMacro("DISABLE_JOYSTICK", "");
    }

    // C++ standard library
    exe.linkLibCpp();

    // Platform-specific threading
    if (target.result.os.tag != .windows) {
        exe.linkSystemLibrary("pthread");
    }

    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run OpenLieroX");
    run_step.dependOn(&run_cmd.step);
}

fn getCxxFlags(target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) []const []const u8 {
    _ = optimize;
    const flags = [_][]const u8{
        "-std=c++11",
        "-Wall",
        // Enable 64-bit time_t to avoid Y2038 problem
        "-D_TIME_BITS=64",
        "-D_FILE_OFFSET_BITS=64",
    };

    if (target.result.os.tag == .windows) {
        return &(flags ++ [_][]const u8{
            "-D_CRT_SECURE_NO_DEPRECATE",
            "-DHAVE_BOOST",
            "-DZLIB_WIN32_NODLL",
        });
    }

    return &flags;
}

fn addSourcesRecursive(b: *std.Build, exe: *std.Build.Step.Compile, dir: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const cwd = std.fs.cwd();
    var src_dir = cwd.openDir(dir, .{ .iterate = true }) catch return;
    defer src_dir.close();

    var iter = src_dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind == .file) {
            const ext = std.fs.path.extension(entry.name);
            if (std.mem.eql(u8, ext, ".cpp") or std.mem.eql(u8, ext, ".c")) {
                const full_path = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ dir, entry.name }) catch continue;
                exe.root_module.addCSourceFile(.{ .file = b.path(full_path), .flags = getCxxFlags(target, optimize) });
            }
        } else if (entry.kind == .directory) {
            const subdir = std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ dir, entry.name }) catch continue;
            addSourcesRecursive(b, exe, subdir, target, optimize);
        }
    }
}

fn addHawkNL(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    exe.root_module.addIncludePath(b.path("libs/hawknl/include"));

    const hawknl_sources = [_][]const u8{
        "libs/hawknl/src/crc.c",
        "libs/hawknl/src/errorstr.c",
        "libs/hawknl/src/nl.c",
        "libs/hawknl/src/sock.c",
        "libs/hawknl/src/group.c",
        "libs/hawknl/src/loopback.c",
        "libs/hawknl/src/err.c",
        "libs/hawknl/src/thread.c",
        "libs/hawknl/src/mutex.c",
        "libs/hawknl/src/condition.c",
        "libs/hawknl/src/nltime.c",
    };

    const c_flags = [_][]const u8{"-std=c99"};
    _ = optimize;
    _ = target;

    for (hawknl_sources) |src| {
        exe.root_module.addCSourceFile(.{ .file = b.path(src), .flags = &c_flags });
    }
}

fn addLibZip(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    _ = target;
    _ = optimize;
    exe.root_module.addIncludePath(b.path("libs/libzip"));

    const cwd = std.fs.cwd();
    var libzip_dir = cwd.openDir("libs/libzip", .{ .iterate = true }) catch return;
    defer libzip_dir.close();

    const c_flags = [_][]const u8{"-std=c99"};

    var iter = libzip_dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind == .file) {
            const ext = std.fs.path.extension(entry.name);
            if (std.mem.eql(u8, ext, ".c")) {
                const full_path = std.fmt.allocPrint(b.allocator, "libs/libzip/{s}", .{entry.name}) catch continue;
                exe.root_module.addCSourceFile(.{ .file = b.path(full_path), .flags = &c_flags });
            }
        }
    }
}

fn addLua(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    _ = target;
    _ = optimize;
    exe.root_module.addIncludePath(b.path("libs/lua"));

    const cwd = std.fs.cwd();
    var lua_dir = cwd.openDir("libs/lua", .{ .iterate = true }) catch return;
    defer lua_dir.close();

    const c_flags = [_][]const u8{"-std=c99"};

    var iter = lua_dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind == .file) {
            const ext = std.fs.path.extension(entry.name);
            if (std.mem.eql(u8, ext, ".c")) {
                const full_path = std.fmt.allocPrint(b.allocator, "libs/lua/{s}", .{entry.name}) catch continue;
                exe.root_module.addCSourceFile(.{ .file = b.path(full_path), .flags = &c_flags });
            }
        }
    }
}

fn linkSystemLibraries(b: *std.Build, exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, dedicated_only: bool, enable_x11: bool) void {
    _ = b;

    const os_tag = target.result.os.tag;

    // Add standard library search paths for cross-compilation
    // This helps Zig find system libraries even when an explicit target is specified
    if (os_tag == .linux) {
        exe.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
        exe.addLibraryPath(.{ .cwd_relative = "/usr/lib/x86_64-linux-gnu" });
        exe.addLibraryPath(.{ .cwd_relative = "/usr/lib/aarch64-linux-gnu" });
    } else if (os_tag == .macos) {
        exe.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
        exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
        exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    } else if (os_tag == .windows) {
        // Windows library paths would be added here if needed
        // Typically handled through environment or pkg-config
    }

    // Common libraries across all platforms
    exe.linkSystemLibrary("curl");
    exe.linkSystemLibrary("xml2");
    exe.linkSystemLibrary("z");

    if (!dedicated_only) {
        // Graphics and sound libraries
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_image");
        exe.linkSystemLibrary("gd");

        exe.linkSystemLibrary("alut");
        exe.linkSystemLibrary("openal");
        exe.linkSystemLibrary("vorbisfile");
        exe.linkSystemLibrary("vorbis");
        exe.linkSystemLibrary("ogg");
    }

    if (os_tag == .windows) {
        exe.linkSystemLibrary("wsock32");
        exe.linkSystemLibrary("wininet");
        exe.linkSystemLibrary("dbghelp");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("winmm");
        exe.linkSystemLibrary("kernel32");
    } else if (os_tag == .macos) {
        exe.linkFramework("Cocoa");
        exe.linkFramework("Carbon");
        exe.linkFramework("OpenAL");
        exe.linkSystemLibrary("crypto");
    } else {
        // Linux and other Unix
        if (enable_x11) {
            exe.linkSystemLibrary("X11");
        }
    }
}
