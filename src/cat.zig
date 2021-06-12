const std = @import("std");
const File = std.fs.File;

pub fn main() !void {
    const stdin = std.io.getStdIn();

    var end_of_options = false;
    var has_printed = false;

    var i: usize = 1;
    const argc = std.os.argv.len;
    while (i < argc) : (i += 1) {
        const arg = std.os.argv[i];

        if (arg[0] == '-') {
            if (arg[1] == 0) {
                try toStdOut(&stdin);
                continue;
            }

            if (!end_of_options) {
                if (arg[1] == '-') {
                    end_of_options = true;
                }
                continue;
            }
        }

        const file = try std.fs.cwd().openFileZ(arg, File.OpenFlags{
            .intended_io_mode = .blocking,
        });
        try toStdOut(&file);
        file.close();
    }

    if (!has_printed) {
        try toStdOut(&stdin);
    }
}

fn toStdOut(file: *const File) !void {
    const in = file.reader();
    const stdout = std.io.getStdOut().writer();

    var buf: [1 << 12]u8 = undefined;
    while (true) {
        var bytes: usize = try in.read(buf[0..]);
        if (bytes == 0) {
            break;
        }

        try stdout.writeAll(buf[0..bytes]);
    }
}
