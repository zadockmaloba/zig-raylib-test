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
