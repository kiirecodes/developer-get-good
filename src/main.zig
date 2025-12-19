const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

pub const Command = struct {
    cmd: []const u8,
    params: []const u8,
    _table: [3][]const u8 = [_][]const u8{ "exit", "echo", "type" },

    pub fn parseCmd(self: Command) !void {
        if (std.mem.eql(u8, self.cmd, "echo")) {
            try stdout.print("{s}\n", .{self.params});
        } else if (std.mem.eql(u8, self.cmd, "type")) {
            var is_cmd = false;
            for (self._table) |cmd| {
                if (std.mem.eql(u8, cmd, self.params)) {
                    is_cmd = true;
                    try stdout.print("{s} is a shell builtin\n", .{self.params});
                }
            }
            if (!is_cmd) try stdout.print("{s}: not found\n", .{self.params});
        } else if (std.mem.eql(u8, self.cmd, "exit")) {
            running = false;
        } else try stdout.print("{s}: command not found\n", .{self.cmd});
    }

    pub fn init(allocator: std.mem.Allocator, _stream: []const u8) !Command {
        const stream = std.mem.trim(u8, _stream, " ");
        //Extracting command
        var _cmd_buffer: [50]u8 = undefined;
        @memset(&_cmd_buffer, 0);
        var i: usize = 0;
        while (i < stream.len and stream[i] != ' ') : (i += 1) {
            _cmd_buffer[i] = stream[i];
        }
        const cmd = try allocator.dupe(u8, _cmd_buffer[0..i]);

        //Extracting arguments
        var params_buffer: [1024]u8 = undefined;
        @memset(&params_buffer, 0);
        i += 1;
        var j: usize = 0;
        while (i < stream.len) : (j += 1) {
            params_buffer[j] = stream[i];
            i += 1;
        }
        const params = try allocator.dupe(u8, params_buffer[0..j]);

        return .{ .cmd = cmd, .params = params };
    }
};

var running = true;

pub fn main() !void {
    while (running) {
        var buffer_alloc: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer_alloc);
        const fba_alloc = fba.allocator();
        var arena = std.heap.ArenaAllocator.init(fba_alloc);
        defer arena.deinit();
        const allocator = arena.allocator();

        var buffer: [1024]u8 = undefined;
        var stdin_reader = std.fs.File.stdin().reader(&buffer);
        const stdin = &stdin_reader.interface;

        try stdout.print("$ ", .{});
        const stream = try stdin.takeDelimiterExclusive('\n');
        stdin.toss(1);

        const cmd = try Command.init(allocator, stream);
        try cmd.parseCmd();
    }
}
