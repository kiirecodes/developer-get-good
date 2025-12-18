const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

pub const Command = struct {
    cmd: []const u8,
    params: []const u8,

    pub fn parseCmd(self: Command) !void {
        if (std.mem.eql(u8, self.cmd, "echo")) {
            try stdout.print("{s}\n", .{self.params});
        } else try stdout.print("{s}: command not found\n", .{self.cmd});
    }
};

pub fn main() !void {
    while (true) {
        var buffer: [1024]u8 = undefined;
        var stdin_reader = std.fs.File.stdin().reader(&buffer);
        const stdin = &stdin_reader.interface;

        try stdout.print("$ ", .{});
        const stream = try stdin.takeDelimiterExclusive('\n');
        if (std.mem.eql(u8, stream, "exit")) break;

        var _cmd_buffer: [50]u8 = undefined;
        @memset(&_cmd_buffer, 0);
        var i: usize = 0;
        while (i < stream.len and stream[i] != ' ') : (i += 1) {
            _cmd_buffer[i] = stream[i];
        }
        const _cmd = _cmd_buffer[0..i];

        var params_buffer: [1024]u8 = undefined;
        @memset(&params_buffer, 0);
        i += 1;
        var j: usize = 0;
        while (i < stream.len) : (j += 1) {
            params_buffer[j] = stream[i];
            i += 1;
        }
        const params = params_buffer[0..j];

        const cmd = Command{ .cmd = _cmd, .params = params };
        try cmd.parseCmd();
    }
}
