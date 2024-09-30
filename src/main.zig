const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try httpz.Server().init(allocator, .{
        .port = 8080,
    });
    defer server.deinit();
    defer server.stop();

    var router = server.router();
    router.get("/", index);

    try server.listen();
}

fn index(_: *httpz.Request, res: *httpz.Response) !void {
    // Content-Typeヘッダーを設定
    res.header("Content-Type", "text/html; charset=utf-8");

    var env_map = try std.process.getEnvMap(res.arena);
    var env_iter = env_map.iterator();

    var html = std.ArrayList(u8).init(res.arena);
    const writer = html.writer();

    try writer.writeAll(
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\    <meta charset="utf-8">
        \\    <title>環境変数</title>
        \\    <style>
        \\        table { border-collapse: collapse; width: 100%; }
        \\        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        \\        th { background-color: #f2f2f2; }
        \\    </style>
        \\</head>
        \\<body>
        \\    <h1>環境変数</h1>
        \\    <table>
        \\        <tr><th>キー</th><th>値</th></tr>
    );

    while (env_iter.next()) |entry| {
        try writer.print("        <tr><td>{s}</td><td>{s}</td></tr>\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    try writer.writeAll(
        \\    </table>
        \\</body>
        \\</html>
    );

    res.body = try html.toOwnedSlice();
}
