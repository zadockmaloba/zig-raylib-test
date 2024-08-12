const std = @import("std");
const tokenizer_namespace = @import("vtktokenizer.zig");

const TokenType = tokenizer_namespace.TokenType;
const Token = tokenizer_namespace.Token;
const Tokenizer = tokenizer_namespace.Tokenizer;

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

// https://people.sc.fsu.edu/~jburkardt/data/vtk/vtk.html
const VtkParserState = enum {
    VERSION_DECL,
    TITLE_DECL,
    FILETYPE_DECL,
};

pub const VtkParser = struct {
    byteOrder: ByteOrder = undefined,
    header: Header = undefined,
    arena: std.heap.ArenaAllocator,
    tokenizer: Tokenizer,

    pub fn init(allocator: std.mem.Allocator) VtkParser {
        const tmp_arena = std.heap.ArenaAllocator.init(allocator);
        return .{
            .arena = tmp_arena,
            .tokenizer = Tokenizer.init(tmp_arena.allocator()),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.arena.deinit();
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

        var buffered = std.io.bufferedReader(file.reader());
        const reader = buffered.reader();

        self.fparse(reader);
    }

    fn fparse(self: *@This(), reader: ParserFileReader) !void {
        _ = self;
        var byte_buffer: u8 = undefined;

        while (true) {
            byte_buffer = reader.readByte() catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            std.debug.print("{c}", .{byte_buffer});

            switch (byte_buffer) {}
        }
    }

    fn version(input: []u8) !Version {
        var index: usize = 0;

        try expectToken(&index, input, "#");
        try expectToken(&index, input, "vtk");
        try expectToken(&index, input, "DataFile");
        try expectToken(&index, input, "Version");

        const major = try parseU32(&index, input);
        try expectToken(&index, input, ".");
        const minor = try parseU32(&index, input);

        return Version.new_legacy(major, minor);
    }

    fn fileType(input: []u8) !FileType {
        if (std.mem.startsWith(u8, input, "ASCII")) {
            return FileType.Ascii;
        } else if (std.mem.startsWith(u8, input, "BINARY")) {
            return FileType.Binary;
        } else {
            return error.InvalidFileType;
        }
    }

    fn title(input: []u8) ![]const u8 {
        return std.utf8.parse(input, "\r\n");
    }

    fn header(input: []u8) !Header {
        var index: usize = 0;

        try skipWhitespace(&index, input);
        const _version = try version(input[index..]);
        const _title = try title(input[index..]);
        const _fileType = try fileType(input[index..]);

        return Header{
            .version = _version,
            .title = _title,
            .fileType = _fileType,
        };
    }

    fn dataType(input: []u8) !ScalarType {
        if (std.mem.startsWith(u8, input, "bit")) {
            return ScalarType.Bit;
        } else if (std.mem.startsWith(u8, input, "int")) {
            return ScalarType.I32;
        } else if (std.mem.startsWith(u8, input, "char")) {
            return ScalarType.I8;
        } else if (std.mem.startsWith(u8, input, "long")) {
            return ScalarType.I64;
        } else if (std.mem.startsWith(u8, input, "short")) {
            return ScalarType.I16;
        } else if (std.mem.startsWith(u8, input, "float")) {
            return ScalarType.F32;
        } else if (std.mem.startsWith(u8, input, "double")) {
            return ScalarType.F64;
        } else if (std.mem.startsWith(u8, input, "unsigned_int")) {
            return ScalarType.U32;
        } else if (std.mem.startsWith(u8, input, "unsigned_char")) {
            return ScalarType.U8;
        } else if (std.mem.startsWith(u8, input, "unsigned_long")) {
            return ScalarType.U64;
        } else if (std.mem.startsWith(u8, input, "vtkIdType")) {
            return ScalarType.I32;
        } else {
            return error.InvalidDataType;
        }
    }

    fn name(input: []u8) ![]const u8 {
        return std.utf8.parse(input, " \t\r\n");
    }

    fn attributeData(input: []u8, n: usize, dataT: ScalarType, ft: FileType) ![]u8 {
        switch (dataT) {
            ScalarType.Bit => return parseDataBitBuffer(input, n, ft),
            ScalarType.U8 => return parseDataBufferU8(input, n, ft),
            ScalarType.I8 => return parseDataBufferI8(input, n, ft),
            ScalarType.U16 => return parseDataBuffer(u16, input, n, ft),
            ScalarType.I16 => return parseDataBuffer(i16, input, n, ft),
            ScalarType.U32 => return parseDataBuffer(u32, input, n, ft),
            ScalarType.I32 => return parseDataBuffer(i32, input, n, ft),
            ScalarType.U64 => return parseDataBuffer(u64, input, n, ft),
            ScalarType.I64 => return parseDataBuffer(i64, input, n, ft),
            ScalarType.F32 => return parseDataBuffer(f32, input, n, ft),
            ScalarType.F64 => return parseDataBuffer(f64, input, n, ft),
        }
    }

    // Implement other functions similarly...

    fn expectToken(index: *usize, input: []u8, token: []const u8) !void {
        if (std.mem.startsWith(u8, input[index.*..index.*], token)) {
            index += token.len;
        } else {
            return error.UnexpectedToken;
        }
    }

    fn parseU32(index: *usize, input: []u8) !u32 {
        const value = try std.fmt.parseUnsigned(u32, input[index.*..], 10);
        index.* += value.len;
        return value;
    }

    fn skipWhitespace(index: *usize, input: []u8) void {
        while (*index < input.len and std.unicode.isWhitespace(input[index.*])) {
            index.* += 1;
        }
    }

    pub fn parseDataBuffer(comptime T: type, comptime BO: ByteOrder, input: []const u8, n: usize, ft: FileType) !IOBuffer {
        return parseDataVec(T, BO, input, n, ft);
    }

    pub fn parseDataBufferU8(input: []const u8, n: usize, ft: FileType) !IOBuffer {
        return parseDataVecU8(input, n, ft);
    }

    pub fn parseDataBufferI8(input: []const u8, n: usize, ft: FileType) !IOBuffer {
        return parseDataVecI8(input, n, ft);
    }

    pub fn parseDataBitBuffer(input: []const u8, n: usize, ft: FileType) !IOBuffer {
        return parseDataBitVec(input, n, ft);
    }

    pub fn parseDataVec(comptime T: type, comptime BO: ByteOrder, input: []const u8, n: usize, ft: FileType) ![]T {
        var result: []T = undefined;

        switch (ft) {
            FileType.Ascii => {
                // Example of ASCII parsing - you would need to define fromAscii for each type
                result = try parseAsciiVec(T, input, n);
            },
            FileType.Binary => {
                // Example of Binary parsing - you would need to define fromBinary for each type
                result = try parseBinaryVec(T, BO, input, n);
            },
        }
        return result;
    }

    fn parseAsciiVec(comptime T: type, input: []const u8, n: usize) ![]T {
        const result: []T = undefined;
        _ = input;
        _ = n;
        // TODO: Implement ASCII parsing logic specific to T here
        return result;
    }

    fn parseBinaryVec(comptime T: type, comptime BO: type, input: []const u8, n: usize) ![]T {
        const result: []T = undefined;
        _ = BO;
        _ = input;
        _ = n;
        // TODO: Implement Binary parsing logic specific to T and BO here
        return result;
    }

    pub fn parseDataVecU8(input: []const u8, n: usize, ft: FileType) ![]u8 {
        switch (ft) {
            FileType.Ascii => {
                return parseAsciiVec(u8, input, n);
            },
            FileType.Binary => {
                if (input.len < n) {
                    return error.Incomplete;
                } else {
                    return input[0..n];
                }
            },
        }
    }

    pub fn parseDataVecI8(input: []const u8, n: usize, ft: FileType) ![]i8 {
        switch (ft) {
            FileType.Ascii => {
                return parseAsciiVec(i8, input, n);
            },
            FileType.Binary => {
                if (input.len < n) {
                    return error.Incomplete;
                } else {
                    var result: []i8 = undefined;
                    result = input[0..n];
                    return result;
                }
            },
        }
    }

    pub fn parseDataBitVec(input: []const u8, n: usize, ft: FileType) ![]u8 {
        const nbytes = (n + 7) / 8;

        if (input.len < nbytes) {
            return error.Incomplete;
        }

        switch (ft) {
            FileType.Ascii => {
                return parseAsciiVec(u8, input, n);
            },
            FileType.Binary => {
                return input[0..nbytes];
            },
        }
    }
};
