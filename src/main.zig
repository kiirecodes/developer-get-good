const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

pub fn handleComandError(comand: []const u8) !void {
    try stdout.print("{s}: command not found\n", .{comand});
}

pub fn main() !void {
    while (true) {
        var buffer: [1024]u8 = undefined;
        var stdin_reader = std.fs.File.stdin().reader(&buffer);
        const stdin = &stdin_reader.interface;

        try stdout.print("$ ", .{});
        const stream = try stdin.takeDelimiterExclusive('\n');
        try handleComandError(stream);
    }
}
