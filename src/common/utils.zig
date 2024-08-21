const std = @import("std");

const commontypes_namespace = @import("types.zig");

usingnamespace @import("std").math;

const Vector3 = commontypes_namespace.Vector3;

pub fn vec3_normalize(vec: Vector3) Vector3 {
    const magnitude = std.math.sqrt(std.math.pow(f32, vec.x, 2) + std.math.pow(f32, vec.y, 2) + std.math.pow(f32, vec.z, 2));

    std.debug.print("Before: {any} \n", .{vec});
    std.debug.print("After: {any} \n", .{Vector3{
        .x = vec.x * (1 / magnitude),
        .y = vec.y * (1 / magnitude),
        .z = vec.z * (1 / magnitude),
    }});

    return .{
        .x = vec.x * (1 / magnitude),
        .y = vec.y * (1 / magnitude),
        .z = vec.z * (1 / magnitude),
    };
}

pub fn normalizePoints(points: []Vector3) void {
    var max_component: f32 = 0.0;
    var min_component: f32 = 0.0;

    // Find the maximum component in the matrix
    for (points) |point| {
        max_component = if (max_component > point.x) max_component else point.x;
        max_component = if (max_component > point.y) max_component else point.y;
        max_component = if (max_component > point.z) max_component else point.z;

        min_component = if (min_component < point.x) min_component else point.x;
        min_component = if (min_component < point.y) min_component else point.y;
        min_component = if (min_component < point.z) min_component else point.z;
    }

    std.debug.print("Max component: {} \n", .{max_component});
    std.debug.print("Min component: {} \n", .{min_component});
    const range = max_component - min_component;
    if (range == 0) return; // Avoid division by zero

    // Normalize each vector by the maximum component
    for (points) |*point| {
        point.x = (2.0 * (point.x - min_component) / range) - 1;
        point.y = (2.0 * (point.y - min_component) / range) - 1;
        point.z = (2.0 * (point.z - min_component) / range) - 1;
    }

    std.debug.print("NEW POINTS: {any} \n", .{points});
}
