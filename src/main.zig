const std = @import("std");
const zlm = @import("zlm");
const ray = @import("raylib");

const utils = @import("common/utils.zig");
const vtkparser = @import("vtkio/vtkparser.zig").VtkParser;
const commontypes_namespace = @import("common/types.zig");
const Vector3 = commontypes_namespace.Vector3;
const Line = commontypes_namespace.Line;

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 450;
    //const rotation = 0.0;

    const args = std.os.argv;
    std.debug.print("Args: {s} \n", .{args[0]});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == std.heap.Check.ok);

    var parser = vtkparser.init(gpa.allocator());
    defer parser.deinit();

    _ = try parser.fevaluate("./test/vtk.vtk");

    const camera = ray.Camera{
        .position = Vector3{ .x = 0.0, .y = 0.0, .z = 10.0 },
        .target = Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = .camera_perspective,
    };

    ray.initWindow(screen_width, screen_height, "Zig - VTK parser/renderer");
    errdefer ray.closeWindow();
    defer ray.closeWindow(); // Close window and OpenGL context

    ray.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    while (!ray.windowShouldClose()) {
        ray.beginDrawing();
        defer ray.endDrawing();

        ray.clearBackground(ray.getColor(0x000000FF));
        ray.beginMode3D(camera);
        defer ray.endMode3D();

        for (parser.data.polydata.lines.items) |line| {
            ray.drawLine3D(line.start, line.end, ray.getColor(0x00FF00FF));
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "simple zlm test" {
    const math = zlm;

    var v = math.Vec3.new(200, 10.0, 4.0);
    var a = math.Vec3.new(310, 120, 10);
    const res = v.add(a.scale(2.0));
    std.debug.print("Result: {} \n", .{res});
}

test "simple vtk file parsing test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == std.heap.Check.ok);

    var parser = vtkparser.init(gpa.allocator());
    defer parser.deinit();

    _ = try parser.fevaluate("./test/hello.vtk");
}

test "display simple structured polydata from buffer" {
    const screen_width = 800;
    const screen_height = 450;
    const rotation = 0.0;

    var points: [22]Vector3 = [22]Vector3{
        Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 0.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
        Vector3{ .x = 1.0, .y = 1.0, .z = 0.0 },
        Vector3{ .x = 1.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 1.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 2.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 3.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 2.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 3.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 2.0, .y = 1.0, .z = 0.0 },
        Vector3{ .x = 3.0, .y = 1.0, .z = 0.0 },
        Vector3{ .x = 4.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 5.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 4.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 6.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 7.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 6.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 8.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 9.0, .y = 0.0, .z = 0.0 },
        Vector3{ .x = 8.0, .y = 2.0, .z = 0.0 },
        Vector3{ .x = 9.0, .y = 2.0, .z = 0.0 },
    };

    utils.normalizePoints(points[0..]);

    const lines: [15]Line = [_]Line{
        Line{ .start = points[0], .end = points[1] },
        Line{ .start = points[4], .end = points[5] },
        Line{ .start = points[2], .end = points[3] },
        Line{ .start = points[6], .end = points[8] },
        Line{ .start = points[6], .end = points[7] },
        Line{ .start = points[10], .end = points[11] },
        Line{ .start = points[8], .end = points[9] },
        Line{ .start = points[12], .end = points[13] },
        Line{ .start = points[12], .end = points[14] },
        Line{ .start = points[15], .end = points[16] },
        Line{ .start = points[15], .end = points[17] },
        Line{ .start = points[18], .end = points[19] },
        Line{ .start = points[20], .end = points[21] },
        Line{ .start = points[18], .end = points[20] },
        Line{ .start = points[19], .end = points[21] },
    };

    const camera = ray.Camera{
        .position = Vector3{ .x = 0.0, .y = 0.0, .z = 10.0 },
        .target = Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = .camera_perspective,
    };

    ray.initWindow(screen_width, screen_height, "raylib [core] example - basic window");
    errdefer ray.closeWindow();
    //defer ray.CloseWindow(); // Close window and OpenGL context

    ray.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //
    var i: u8 = 0;
    while (i < 200) : (i += 1) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        //ray.UpdateCamera(&camera, 0);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        ray.beginDrawing();
        defer ray.endDrawing();

        ray.clearBackground(ray.RAYWHITE);
        //ray.DrawText("Congrats! You created your first window!", 190, 200, 20, ray.LIGHTGRAY);
        ray.beginMode3D(camera);
        defer ray.endMode3D();

        ray.drawPoint3D(.{ .x = 20, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));
        ray.drawPoint3D(.{ .x = 21, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));
        ray.drawPoint3D(.{ .x = 22, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));
        ray.drawPoint3D(.{ .x = 23, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));
        ray.drawPoint3D(.{ .x = 24, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));
        ray.drawPoint3D(.{ .x = 25, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));
        ray.drawPoint3D(.{ .x = 26, .y = 20, .z = 1 }, ray.getColor(0xFF0000FF));

        inline for (lines) |line| {
            ray.drawLine3D(line.start, line.end, ray.getColor(0xFF0000FF));
        }

        // Polygon shapes and lines
        //ray.DrawPoly(.{ .x = screen_width / 4.0 * 3, .y = 330 }, 6, 80, rotation, ray.BROWN);
        ray.DrawPolyLines(.{ .x = screen_width / 4.0 * 3, .y = 330 }, 6, 90, rotation, ray.BROWN);
        //ray.DrawPolyLinesEx(.{ .x = screen_width / 4.0 * 3, .y = 330 }, 6, 85, rotation, 6, ray.BEIGE);
        //----------------------------------------------------------------------------------
    }

    ray.CloseWindow();

    return;
}
