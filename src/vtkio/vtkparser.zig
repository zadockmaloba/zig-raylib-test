const std = @import("std");
const tokenizer_namespace = @import("vtktokenizer.zig");
const commontypes_namespace = @import("../common/types.zig");
const utils = @import("../common/utils.zig");

const TokenType = tokenizer_namespace.TokenType;
const Token = tokenizer_namespace.Token;
const Tokenizer = tokenizer_namespace.Tokenizer;

const Vector3 = commontypes_namespace.Vector3;
const Line = commontypes_namespace.Line;

const ParserFileReader = *std.io.BufferedReader(4096, std.fs.File.Reader).Reader;

const ByteOrder = enum {
    BigEndian,
    LittleEndian,
    NativeEndian,
};

const ScalarType = enum {
    Bit,
    I8,
    I16,
    I32,
    I64,
    U8,
    U16,
    U32,
    U64,
    F32,
    F64,
};

const FileType = enum {
    Ascii,
    Binary,
};

const Version = struct {
    major: u32,
    minor: u32,

    pub fn new_legacy(major: u32, minor: u32) Version {
        return Version{ .major = major, .minor = minor };
    }
};

//const Scalar: any = undefined;
const IOBuffer = []u8;

const Header = struct {
    fileType: FileType,
    version: Version,
    title: []const u8,
};

const VtkPolyData = struct {
    points: std.ArrayList(Vector3) = undefined,
    lines: std.ArrayList(Line) = undefined,
    allocator: std.mem.Allocator,
    drawLineFn: ?*const fn (start: Vector3, end: Vector3) void = null,

    pub fn init(allocator: std.mem.Allocator) VtkPolyData {
        return .{
            .allocator = allocator,
            .points = std.ArrayList(Vector3).init(allocator),
            .lines = std.ArrayList(Line).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.points.deinit();
        self.lines.deinit();
    }

    pub fn render(self: *@This()) !void {
        if (self.drawLineFn != null)
            for (self.lines.items) |line|
                self.drawLineFn(line.start, line.end);
    }
};

const DataSetType = enum {
    STRUCTURED_POINTS,
    STRUCTURED_GRID,
    UNSTRUCTURED_GRID,
    RECTILINIEAR_GRID,
    POLYDATA,
};

const DataSet = union(enum) {
    structured_points: u8,
    structured_grid: u8,
    unstructured_grid: u8,
    rectiliniear_grid: u8,
    polydata: VtkPolyData,
};

// https://people.sc.fsu.edu/~jburkardt/data/vtk/vtk.html
const VtkParserState = enum {
    NOOP,
    INIT,
    VERSION_DECL,
    TITLE_DECL,
    FILETYPE_DECL,
    DATASETTYPE_DECL,
    POINTS_ARG1,
    POINTS_ARG2,
    POINTS_ARR,
    LINES_ARG1,
    LINES_ARG2,
    LINES_ARR,
};

pub const VtkParser = struct {
    byteOrder: ByteOrder = undefined,
    state: VtkParserState,
    header: Header = undefined,
    data: DataSet = undefined,
    arena: std.heap.ArenaAllocator,
    tokenizer: Tokenizer = undefined,

    pub fn init(allocator: std.mem.Allocator) VtkParser {
        //var tmp_arena = std.heap.ArenaAllocator.init(allocator);
        return .{
            .state = .INIT,
            .arena = std.heap.ArenaAllocator.init(allocator),
            //.tokenizer = Tokenizer.init(tmp_arena.allocator()),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.arena.deinit();
        //self.tokenizer.deinit();
    }

    //Evaluate string directly
    pub fn evaluate(self: *@This(), string: []const u8) !void {
        //TODO: implement parser evaluate function
        _ = self;
        _ = string;
    }

    //Evaluate string within a file
    pub fn fevaluate(self: *@This(), filepath: []const u8) !void {
        var file = try std.fs.cwd().openFile(filepath, .{});
        defer file.close();

        self.tokenizer = Tokenizer.init(self.arena.allocator());

        var buffered = std.io.bufferedReader(file.reader());
        var reader = buffered.reader();

        //try self.fparse(&reader);

        try self.tokenizer.start(&reader);

        const tokens = self.tokenizer.tokens.items;

        var title_buffer: []const u8 = "";

        var tmpHeader = Header{
            .version = undefined,
            .title = undefined,
            .fileType = undefined,
        };

        var tmpData: DataSet = undefined;

        var tmpPointsPtr: *std.ArrayList(Vector3) = undefined;
        var tmpLinesPtr: *std.ArrayList(Line) = undefined;

        //store coords in a 256 byte buffer
        var tmpCoords: [1024]f32 = [_]f32{0} ** 1024;
        var tmpCoordCount: u32 = 0;
        var tmpCoordLimit: u32 = 0;

        for (tokens) |token| {
            switch (token.typ) {
                TokenType.VERSION_KEYWORD => {
                    self.state = .VERSION_DECL;
                    continue;
                },
                TokenType.ASCII => {
                    self.state = .NOOP;

                    tmpHeader.title = title_buffer;
                    tmpHeader.fileType = .Ascii;
                    self.header = tmpHeader;

                    std.debug.print("Header: \n {any} \n", .{self.header});

                    continue;
                },
                TokenType.BINARY => {
                    self.state = .NOOP;

                    tmpHeader.title = title_buffer;
                    tmpHeader.fileType = .Binary;
                    self.header = tmpHeader;

                    continue;
                },
                TokenType.DATASET => {
                    self.state = .DATASETTYPE_DECL;
                    continue;
                },
                TokenType.POINTS => {
                    self.state = .POINTS_ARG1;
                    continue;
                },
                TokenType.LINES => {
                    self.state = .LINES_ARG1;
                    continue;
                },
                TokenType.POLYGONS => {
                    //TODO: Implement polygons parsing
                    self.state = .NOOP;
                    continue;
                },
                TokenType.VERTICES => {
                    //TODO: Implement polygons parsing
                    self.state = .NOOP;
                    continue;
                },
                TokenType.TRIANGLE_STRIPS => {
                    //TODO: Implement polygons parsing
                    self.state = .NOOP;
                    continue;
                },
                TokenType.POINT_DATA => {
                    //TODO: Implement polygons parsing
                    self.state = .NOOP;
                    continue;
                },
                else => {},
            }

            switch (self.state) {
                VtkParserState.VERSION_DECL => {
                    std.debug.print("Version: {s} \n", .{token.lexeme});
                    var val_it = std.mem.splitAny(u8, token.lexeme, ".");
                    const tmp_major = if (val_it.next()) |v| try std.fmt.parseUnsigned(u32, v, 10) else return error.UnexpectedToken;
                    const tmp_minor = if (val_it.next()) |v| try std.fmt.parseUnsigned(u32, v, 10) else return error.UnexpectedToken;

                    tmpHeader.version = .{
                        .major = tmp_major,
                        .minor = tmp_minor,
                    };
                    self.state = .TITLE_DECL;
                },
                VtkParserState.TITLE_DECL => {
                    //TODO: parse title
                    title_buffer = try std.mem.concat(self.arena.allocator(), u8, &[_][]const u8{ title_buffer, token.lexeme });
                },
                //VtkParserState.FILETYPE_DECL => {},
                VtkParserState.DATASETTYPE_DECL => {
                    defer self.state = .NOOP;
                    std.debug.print("Dataset type: {s} \n", .{token.lexeme});

                    if (std.mem.eql(u8, token.lexeme, "STRUCTURED_POINTS"))
                        tmpData = .{ .structured_points = 0 }
                    else if (std.mem.eql(u8, token.lexeme, "STRUCTURED_GRID"))
                        tmpData = .{ .structured_grid = 0 }
                    else if (std.mem.eql(u8, token.lexeme, "UNSTRUCTURED_GRID"))
                        tmpData = .{ .unstructured_grid = 0 }
                    else if (std.mem.eql(u8, token.lexeme, "RECTILINEAR_GRID"))
                        tmpData = .{ .rectiliniear_grid = 0 }
                    else if (std.mem.eql(u8, token.lexeme, "POLYDATA")) {
                        tmpData = .{
                            .polydata = VtkPolyData.init(self.arena.allocator()),
                        };
                        tmpPointsPtr = &tmpData.polydata.points;
                        tmpLinesPtr = &tmpData.polydata.lines;
                    } else return error.UnsupportedType;
                },
                VtkParserState.POINTS_ARG1 => {
                    self.state = .POINTS_ARG2;
                    std.debug.print("Trying to parse value: {s}\n", .{token.lexeme});
                    const new_size = try std.fmt.parseUnsigned(u32, token.lexeme, 10);

                    try tmpPointsPtr.ensureTotalCapacity(new_size);
                },
                VtkParserState.POINTS_ARG2 => {
                    //Ignore arg 2 - assume we only have floats
                    self.state = .POINTS_ARR;
                    continue;
                },
                VtkParserState.POINTS_ARR => {
                    tmpCoords[tmpCoordCount] = try std.fmt.parseFloat(f32, token.lexeme);
                    tmpCoordCount += 1;

                    if (tmpCoordCount == 3) {
                        tmpCoordCount = 0;
                        try tmpPointsPtr.append(.{
                            .x = tmpCoords[0],
                            .y = tmpCoords[1],
                            .z = tmpCoords[2],
                        });
                    }
                },
                VtkParserState.LINES_ARG1 => {
                    self.state = .LINES_ARG2;
                    tmpCoordCount = 0;
                    std.debug.print("Trying parse value: {s}\n", .{token.lexeme});
                    const new_size = try std.fmt.parseUnsigned(u32, token.lexeme, 10);

                    try tmpLinesPtr.ensureTotalCapacity(new_size);
                    //TODO: Find a better place to put this
                    utils.normalizePoints(tmpPointsPtr.items);
                    continue;
                },
                VtkParserState.LINES_ARG2 => {
                    self.state = .LINES_ARR;
                    continue;
                },
                VtkParserState.LINES_ARR => {
                    //FIXME: Implement a better way to do this
                    if (tmpCoordLimit == 0) {
                        //FIXME: Assuming the max number of line points is 256
                        tmpCoordLimit = try std.fmt.parseUnsigned(u32, token.lexeme, 10);

                        std.debug.print("Number of line points: {} \n", .{tmpCoordLimit});
                        continue;
                    } else {
                        tmpCoords[tmpCoordCount] = @floatFromInt(try std.fmt.parseUnsigned(u32, token.lexeme, 10));
                        tmpCoordCount += 1;
                    }

                    if (tmpCoordCount == tmpCoordLimit) {
                        var idx: u32 = 0;
                        //TODO: Optimize this
                        while (idx <= tmpCoordLimit) : (idx += 2) {
                            if ((tmpCoordLimit - idx) == 1) {
                                try tmpLinesPtr.append(.{
                                    .start = tmpPointsPtr.items[@intFromFloat(tmpCoords[idx - 1])],
                                    .end = tmpPointsPtr.items[@intFromFloat(tmpCoords[idx])],
                                });
                            } else try tmpLinesPtr.append(.{
                                .start = tmpPointsPtr.items[@intFromFloat(tmpCoords[idx])],
                                .end = tmpPointsPtr.items[@intFromFloat(tmpCoords[idx + 1])],
                            });
                        }
                        tmpCoordCount = 0;
                        tmpCoordLimit = 0;
                    } //else if (tmpCoordCount > 2) {}
                },
                else => {},
            }
        }
        self.data = tmpData;
        std.debug.print("TMP DATA: {any} \n", .{self.data});
    }
};
