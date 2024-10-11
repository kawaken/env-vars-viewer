const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const port = std.process.getEnvVarOwned(allocator, "PORT") catch "8080";
    const port_num = try std.fmt.parseInt(u16, port, 10);
    var server = try httpz.Server().init(allocator, .{
        .port = port_num,
        .address = "0.0.0.0",
    });
    defer server.deinit();
    defer server.stop();

    // 環境変数を取得してログに出力
    var env_map = try std.process.getEnvMap(allocator);
    var env_iter = env_map.iterator();

    var writer = std.io.getStdOut().writer();
    try writer.print("環境変数\n", .{});
    while (env_iter.next()) |entry| {
        try writer.print("{s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    var router = server.router();
    router.get("/", index);

    try writer.print("http server listen: {d}\n", .{port_num});
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
