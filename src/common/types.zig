const std = @import("std");

const ray = @cImport({
    @cInclude("raylib.h");
});

pub const Vector3 = ray.Vector3;
pub const Vector4 = ray.Vector4;

pub const Line = struct {
    start: Vector3,
    end: Vector3,
};
