const std = @import("std");

const ParserReader = *std.io.BufferedReader(4096, std.fs.File.Reader).Reader;

const Parser = opaque {};

pub const TokenType = enum {
    // Builtin Types
    u8, //FIXME: Work on a better way to do this
    i8,
    f8,
    u16,
    i16,
    f16,
    u32,
    i32,
    f32,
    u64,
    i64,
    f64,
    GARBAGE_TYPE,
    WHITE_SPACE,
    COMMENT,
    KEYWORD,
    VERSION_KEYWORD,
    IDENTIFIER,
    NUMERIC_LITERAL,
    STRING_LITERAL,
};

pub const BuiltinTypes = enum(u8) {
    u8,
    i8,
    f8,
    u16,
    i16,
    f16,
    u32,
    i32,
    f32,
    u64,
    i64,
    f64,
    Bool,
    String,
    Struct,
    @"fn",
};

pub const Token = struct {
    typ: TokenType,
    lexeme: []const u8, // The actual sequence of characters that make up the token

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("\n(<VTK Token> :  [Type <{}>, <{s}>])", .{ self.typ, self.lexeme });
    }
};

//Tokenizer namespace
pub const Tokenizer = struct {
    buffer: std.ArrayList(u8) = undefined,
    allocator: std.mem.Allocator = undefined,
    current_token: Token = undefined,
    tokens: std.ArrayList(Token) = undefined,

    pub fn init(allocator: std.mem.Allocator) Tokenizer {
        return .{
            .buffer = std.ArrayList(u8).init(allocator),
            .tokens = std.ArrayList(Token).init(allocator),
            .current_token = Token{
                .typ = .WHITE_SPACE,
                .lexeme = "",
            },
        };
    }

    pub fn deinit(self: *@This()) void {
        self.buffer.deinit();
        self.tokens.deinit();
    }

    fn not_string_or_comment(self: *@This()) bool {
        return self.current_token.typ != .STRING_LITERAL and self.current_token.typ != .COMMENT;
    }

    fn end_token(self: *@This()) !void {
        defer self.buffer.clearAndFree();
        defer {
            self.current_token.typ = .WHITE_SPACE;
            self.current_token.lexeme = undefined;
        }

        if ((self.current_token.typ != .WHITE_SPACE) and (self.current_token.typ != .COMMENT)) {
            self.current_token.lexeme = try self.buffer.toOwnedSlice();

            //If we have an identifier, try to check if it is a built-in keyword
            if (self.current_token.typ == .IDENTIFIER) {
                if (std.mem.eql(u8, self.current_token.lexeme, "Version"))
                    self.current_token.typ = .VERSION_KEYWORD
                else if (std.mem.eql(u8, self.current_token.lexeme, "return"))
                    self.current_token.typ = .RET_KEYWORD
                else {
                    inline for (std.meta.fields(BuiltinTypes)) |field| {
                        //std.debug.print("{s} \n", .{field.name});
                        const temp = @field(TokenType, field.name);
                        _ = temp;
                        if (std.mem.eql(u8, self.current_token.lexeme, field.name)) {
                            self.current_token.typ = @field(TokenType, field.name);
                            break;
                        }
                    }
                }
            }
            try self.tokens.append(self.current_token);
        }
    }

    //TODO: Return slice of tokens ([]Token)
    pub fn start(self: *@This(), reader: ParserReader) !void {
        var byte_buffer = try reader.readByte();

        //TODO: The goal is to parse the file as we read each byte
        while (true) {
            byte_buffer = reader.readByte() catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            std.debug.print("{c}", .{byte_buffer});

            switch (byte_buffer) {
                '0'...'9' => {
                    if (self.current_token.typ == .WHITE_SPACE) {
                        self.current_token.typ = .NUMERIC_LITERAL;
                        try self.buffer.append(byte_buffer);
                    } else {
                        try self.buffer.append(byte_buffer);
                    }
                },
                'a'...'z', 'A'...'Z' => {
                    if (self.not_string_or_comment()) {
                        self.current_token.typ = .IDENTIFIER;
                    }
                    try self.buffer.append(byte_buffer);
                },
                '_' => {
                    if (!(self.current_token.typ == .NUMERIC_LITERAL)) {
                        try self.buffer.append(byte_buffer);
                    }
                },
                ' ', '\n', '\r', '\t' => {
                    if (self.current_token.typ == .COMMENT) {
                        if (byte_buffer == '\n') try self.end_token() else try self.buffer.append(byte_buffer);
                    } else if ((self.current_token.typ == .STRING_LITERAL))
                        try self.buffer.append(byte_buffer)
                    else
                        try self.end_token();
                },
                '.' => {
                    //TODO: Make this cleaner
                    if (self.not_string_or_comment()) {
                        if (self.current_token.typ == .NUMERIC_LITERAL)
                            try self.buffer.append(byte_buffer)
                        else {
                            if (self.buffer.items.len > 0) {
                                try self.end_token();
                            }
                            self.current_token.typ = .ACCESS_OPERATOR;
                            try self.buffer.append('.');
                            try self.end_token();
                        }
                    } else try self.buffer.append(byte_buffer);
                },
                '{' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .SCOPE_START;
                        try self.buffer.append('{');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '}' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .SCOPE_END;
                        try self.buffer.append('}');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '(' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .PARAMS_START;
                        try self.buffer.append('(');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                ')' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .PARAMS_END;
                        try self.buffer.append(')');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '=' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .ASSIGNMENT_OPERATOR;
                        try self.buffer.append('=');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '+' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .ADD_OPERATOR;
                        try self.buffer.append('+');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '-' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .SUB_OPERATOR;
                        try self.buffer.append('-');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '*' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .MUL_OPERATOR;
                        try self.buffer.append('*');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '/' => {
                    if (self.not_string_or_comment()) {
                        //Check if the next byte is a '/' so that we can make it a comment
                        if (try reader.readByte() == '/') {
                            self.current_token.typ = .COMMENT;
                        } else {
                            if (self.buffer.items.len > 0) {
                                try self.end_token();
                            }
                            self.current_token.typ = .DIV_OPERATOR;
                            try self.buffer.append('/');
                            try self.end_token();
                        }
                    } else try self.buffer.append(byte_buffer);
                },
                '&' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .AND_OPERATOR;
                        try self.buffer.append('&');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '|' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .OR_OPERATOR;
                        try self.buffer.append('|');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '!' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .NOT_OPERATOR;
                        try self.buffer.append('!');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '<' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .LESS_OPERATOR;
                        try self.buffer.append('<');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                '>' => {
                    if (self.not_string_or_comment()) {
                        if (self.buffer.items.len > 0) {
                            try self.end_token();
                        }
                        self.current_token.typ = .GREATER_OPERATOR;
                        try self.buffer.append('>');
                        try self.end_token();
                    } else try self.buffer.append(byte_buffer);
                },
                else => {},
            }
            //try self.processByte(byte_buffer, &reader);
        }

        std.debug.print("Tokens: {any}", .{self.tokens});
    }
};
