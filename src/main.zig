const std = @import("std");
const vtkparser = @import("vtkio/vtkparser.zig").VtkParser;

const ray = @cImport({
    @cInclude("raylib.h");
});

pub fn main() void {
    const screen_width = 800;
    const screen_height = 450;

    ray.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
    errdefer ray.CloseWindow();
    defer ray.CloseWindow(); // Close window and OpenGL context

    ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    while (!ray.WindowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawText("Congrats! You created your first window!", 190, 200, 20, ray.LIGHTGRAY);
        //----------------------------------------------------------------------------------
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "Simple VTK file parsing test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == std.heap.Check.ok);

    var parser = vtkparser.init(gpa.allocator());
    defer parser.deinit();

    _ = try parser.fevaluate("./test/hello.vtk");
}

//test "Display basic window" {
//    const screen_width = 800;
//    const screen_height = 450;
//
//    ray.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
//    errdefer ray.CloseWindow();
//    defer ray.CloseWindow(); // Close window and OpenGL context
//
//    ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
//    ray.DisableEventWaiting();
//
//    while (!ray.WindowShouldClose()) // Detect window close button or ESC key
//    {
//        // Update
//        //----------------------------------------------------------------------------------
//        //----------------------------------------------------------------------------------
//
//        // Draw
//        //----------------------------------------------------------------------------------
//        ray.BeginDrawing();
//        defer ray.EndDrawing();
//
//        ray.ClearBackground(ray.RAYWHITE);
//        ray.DrawText("Congrats! You created your first window!", 190, 200, 20, ray.LIGHTGRAY);
//        //----------------------------------------------------------------------------------
//    }
//    std.debug.print("Reached function end \n", .{});
//
//    return;
//}
//
//test "Render basic 2D shapes (Rectangle, Circle, Triangle)" {
//    const screen_width = 800;
//    const screen_height = 450;
//
//    ray.InitWindow(screen_width, screen_height, "raylib [core] example - basic window");
//    errdefer ray.CloseWindow();
//    defer ray.CloseWindow(); // Close window and OpenGL context
//
//    const player = ray.Rectangle{
//        .x = 200,
//        .y = 200,
//        .width = 100,
//        .height = 100,
//    };
//
//    const camera = ray.Camera2D{
//        .target = .{
//            .x = player.x + 20,
//            .y = player.y + 20,
//        },
//        .rotation = 0,
//        .zoom = 1,
//    };
//
//    ray.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
//    ray.DisableEventWaiting();
//
//    while (!ray.WindowShouldClose()) // Detect window close button or ESC key
//    {
//        // Update
//        //----------------------------------------------------------------------------------
//        //----------------------------------------------------------------------------------
//
//        // Draw
//        //----------------------------------------------------------------------------------
//        ray.ClearBackground(ray.BLACK);
//        ray.BeginDrawing();
//        defer ray.EndDrawing();
//        {
//            ray.BeginMode2D(camera);
//            defer ray.EndMode2D();
//
//            ray.DrawRectangleRec(player, ray.RED);
//        }
//        //----------------------------------------------------------------------------------
//    }
//    std.debug.print("Reached end of app \n", .{});
//
//    return;
//}
