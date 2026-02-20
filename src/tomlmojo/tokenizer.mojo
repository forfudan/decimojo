# ===----------------------------------------------------------------------=== #
# Copyright 2025 Yuhao Zhu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

"""
A TOML tokenizer for Mojo, implementing the core TOML v1.0 specification.
"""

comptime WHITESPACE = " \t"
comptime COMMENT_START = "#"
comptime QUOTE = '"'
comptime LITERAL_QUOTE = "'"


struct Token(Copyable, Movable):
    """Represents a token in the TOML document."""

    var type: TokenType
    var value: String
    var line: Int
    var column: Int

    fn __init__(
        out self, type: TokenType, value: String, line: Int, column: Int
    ):
        self.type = type
        self.value = value
        self.line = line
        self.column = column


struct SourcePosition:
    """Tracks position in the source text."""

    var line: Int
    var column: Int
    var index: Int

    fn __init__(out self, line: Int = 1, column: Int = 1, index: Int = 0):
        self.line = line
        self.column = column
        self.index = index

    fn advance(mut self, char: String):
        """Update position after consuming a character."""
        if char == "\n":
            self.line += 1
            self.column = 1
        else:
            self.column += 1
        self.index += 1


struct TokenType(Copyable, ImplicitlyCopyable, Movable):
    """
    TokenType mimics an enum for token types in TOML.
    """

    # Aliases for TokenType static methods to mimic enum constants
    comptime KEY = TokenType.key()
    comptime STRING = TokenType.string()
    comptime INTEGER = TokenType.integer()
    comptime FLOAT = TokenType.float()
    comptime BOOLEAN = TokenType.boolean()
    comptime DATETIME = TokenType.datetime()
    comptime ARRAY_START = TokenType.array_start()
    comptime ARRAY_END = TokenType.array_end()
    comptime TABLE_START = TokenType.table_start()
    comptime TABLE_END = TokenType.table_end()
    comptime ARRAY_OF_TABLES_START = TokenType.array_of_tables_start()
    comptime EQUAL = TokenType.equal()
    comptime COMMA = TokenType.comma()
    comptime NEWLINE = TokenType.newline()
    comptime DOT = TokenType.dot()
    comptime EOF = TokenType.eof()
    comptime ERROR = TokenType.error()

    # Attributes
    var value: Int

    # Token type constants (lowercase method names)
    @staticmethod
    fn key() -> TokenType:
        return TokenType(0)

    @staticmethod
    fn string() -> TokenType:
        return TokenType(1)

    @staticmethod
    fn integer() -> TokenType:
        return TokenType(2)

    @staticmethod
    fn float() -> TokenType:
        return TokenType(3)

    @staticmethod
    fn boolean() -> TokenType:
        return TokenType(4)

    @staticmethod
    fn datetime() -> TokenType:
        return TokenType(5)

    @staticmethod
    fn array_start() -> TokenType:
        return TokenType(6)

    @staticmethod
    fn array_end() -> TokenType:
        return TokenType(7)

    @staticmethod
    fn table_start() -> TokenType:
        return TokenType(8)

    @staticmethod
    fn table_end() -> TokenType:
        return TokenType(9)

    @staticmethod
    fn array_of_tables_start() -> TokenType:
        return TokenType(16)

    @staticmethod
    fn equal() -> TokenType:
        return TokenType(10)

    @staticmethod
    fn comma() -> TokenType:
        return TokenType(11)

    @staticmethod
    fn newline() -> TokenType:
        return TokenType(12)

    @staticmethod
    fn dot() -> TokenType:
        return TokenType(13)

    @staticmethod
    fn eof() -> TokenType:
        return TokenType(14)

    @staticmethod
    fn error() -> TokenType:
        return TokenType(15)

    # Constructor
    fn __init__(out self, value: Int):
        self.value = value

    # Comparison operators
    fn __eq__(self, other: TokenType) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: TokenType) -> Bool:
        return self.value != other.value


struct Tokenizer:
    """Tokenizes TOML source text."""

    var source: String
    var position: SourcePosition
    var current_char: String

    fn __init__(out self, source: String):
        self.source = source
        self.position = SourcePosition()
        if len(source) > 0:
            self.current_char = String(source[byte=0])
        else:
            self.current_char = ""

    fn _get_char(self, index: Int) -> String:
        """Get character at given index or empty string if out of bounds."""
        if index >= len(self.source):
            return ""
        return String(self.source[byte=index])

    fn _advance(mut self):
        """Move to the next character."""
        self.position.advance(self.current_char)
        self.current_char = self._get_char(self.position.index)

    fn _skip_whitespace(mut self):
        """Skip whitespace characters."""
        while self.current_char and self.current_char in WHITESPACE:
            self._advance()

    fn _skip_comment(mut self):
        """Skip comment lines."""
        if self.current_char == COMMENT_START:
            while self.current_char:
                # Stop at LF or CR
                if self.current_char == "\n":
                    break
                if self.current_char == "\r":
                    # If next char is \n, treat as CRLF and break
                    if self._get_char(self.position.index + 1) == "\n":
                        break
                    else:
                        break
                self._advance()

    fn _read_string(mut self) -> Token:
        """Read a quoted string value (basic or literal).

        Handles:
        - Basic strings ("..."): escape sequences \\, \", \n, \t, \r, \b, \f
        - Literal strings ('...'): no escape processing
        - Multi-line basic strings (triple double quotes)
        - Multi-line literal strings (triple single quotes)
        """
        start_line = self.position.line
        start_column = self.position.column
        quote_char = self.current_char

        # Check for multi-line string (triple quotes)
        var is_multiline = False
        if (
            self._get_char(self.position.index + 1) == quote_char
            and self._get_char(self.position.index + 2) == quote_char
        ):
            is_multiline = True
            self._advance()  # skip 1st quote
            self._advance()  # skip 2nd quote
            self._advance()  # skip 3rd quote
            # A newline immediately after the opening delimiter is trimmed
            if self.current_char == "\n":
                self._advance()
            elif (
                self.current_char == "\r"
                and self._get_char(self.position.index + 1) == "\n"
            ):
                self._advance()
                self._advance()
        else:
            # Single-line: skip opening quote
            self._advance()

        var is_literal = quote_char == "'"
        var chars = List[String]()

        while self.current_char:
            if is_multiline:
                # Check for closing triple quotes
                if (
                    self.current_char == quote_char
                    and self._get_char(self.position.index + 1) == quote_char
                    and self._get_char(self.position.index + 2) == quote_char
                ):
                    self._advance()  # skip 1st
                    self._advance()  # skip 2nd
                    self._advance()  # skip 3rd
                    return Token(
                        TokenType.STRING,
                        String.join("", chars),
                        start_line,
                        start_column,
                    )
                # Multi-line strings allow newlines
                if not is_literal and self.current_char == "\\":
                    # Process escape sequence
                    var next_ch = self._get_char(self.position.index + 1)
                    if next_ch == "\n" or next_ch == "\r":
                        # Line ending backslash: skip whitespace continuation
                        self._advance()  # skip backslash
                        while self.current_char and (
                            self.current_char == " "
                            or self.current_char == "\t"
                            or self.current_char == "\n"
                            or self.current_char == "\r"
                        ):
                            self._advance()
                        continue
                    chars.append(self._read_escape_sequence())
                else:
                    chars.append(self.current_char)
                    self._advance()
            else:
                # Single-line string
                if self.current_char == quote_char:
                    # Closing quote
                    self._advance()
                    return Token(
                        TokenType.STRING,
                        String.join("", chars),
                        start_line,
                        start_column,
                    )
                if self.current_char == "\n" or self.current_char == "\r":
                    # Newlines not allowed in single-line strings
                    return Token(
                        TokenType.ERROR,
                        "Newline in single-line string",
                        start_line,
                        start_column,
                    )
                if not is_literal and self.current_char == "\\":
                    # Process escape sequence
                    chars.append(self._read_escape_sequence())
                else:
                    chars.append(self.current_char)
                    self._advance()

        return Token(
            TokenType.ERROR, "Unterminated string", start_line, start_column
        )

    fn _read_escape_sequence(mut self) -> String:
        """Read and return the character for a backslash escape sequence.

        Assumes current_char is '\\'. Advances past the full sequence.
        Handles: \\, \", \', \n, \t, \r, \b, \f.
        """
        self._advance()  # skip the backslash
        var esc = self.current_char
        self._advance()  # skip the escape character

        if esc == "\\":
            return "\\"
        elif esc == '"':
            return '"'
        elif esc == "'":
            return "'"
        elif esc == "n":
            return "\n"
        elif esc == "t":
            return "\t"
        elif esc == "r":
            return "\r"
        elif esc == "b":
            return "\x08"
        elif esc == "f":
            return "\x0c"
        else:
            # Unknown escape: keep as-is (backslash + char)
            return "\\" + esc

    fn _read_number(mut self, sign: String = "") -> Token:
        """Read a number value.

        Handles:
        - Plain integers: 42
        - Signed numbers: +42, -42, +3.14, -3.14
        - Underscored numbers: 1_000, 1_000.5
        - Hex: 0xFF, Octal: 0o77, Binary: 0b1010
        - Scientific notation: 1e10, 1.5e-3, 6.022E+23
        - Float: 3.14
        """
        start_line = self.position.line
        start_column = self.position.column
        var result = sign
        var is_float = False

        # Check for hex/octal/binary prefixes: 0x, 0o, 0b
        if (
            self.current_char == "0"
            and self._get_char(self.position.index + 1) in "xXoObB"
        ):
            result += self.current_char  # '0'
            self._advance()
            result += self.current_char  # 'x'/'o'/'b'
            self._advance()
            # Read hex/octal/binary digits (including underscores)
            while self.current_char and (
                self.current_char.is_ascii_digit()
                or self.current_char in "abcdefABCDEF_"
            ):
                if self.current_char != "_":
                    result += self.current_char
                self._advance()
            return Token(TokenType.INTEGER, result, start_line, start_column)

        # Read digits, dots, underscores, and exponents
        while self.current_char and (
            self.current_char.is_ascii_digit()
            or self.current_char == "."
            or self.current_char == "_"
            or self.current_char == "e"
            or self.current_char == "E"
        ):
            if self.current_char == ".":
                is_float = True
                result += self.current_char
                self._advance()
            elif self.current_char == "e" or self.current_char == "E":
                is_float = True
                result += self.current_char
                self._advance()
                # Optional sign after exponent
                if self.current_char == "+" or self.current_char == "-":
                    result += self.current_char
                    self._advance()
            elif self.current_char == "_":
                # Skip underscores (TOML allows them as visual separators)
                self._advance()
            else:
                result += self.current_char
                self._advance()

        if is_float:
            return Token(TokenType.FLOAT, result, start_line, start_column)
        else:
            return Token(TokenType.INTEGER, result, start_line, start_column)

    fn _read_key(mut self) -> Token:
        """Read a key identifier."""
        start_line = self.position.line
        start_column = self.position.column
        result = String("")

        while self.current_char and (
            self.current_char.is_ascii_digit()
            or self.current_char.isupper()
            or self.current_char.islower()
            or self.current_char == "_"
            or self.current_char == "-"
        ):
            result += self.current_char
            self._advance()

        return Token(TokenType.KEY, result, start_line, start_column)

    fn next_token(mut self) -> Token:
        """Get the next token from the source."""
        self._skip_whitespace()

        if not self.current_char:
            return Token(
                TokenType.EOF, "", self.position.line, self.position.column
            )

        if self.current_char == COMMENT_START:
            self._skip_comment()
            return self.next_token()

        # Handle CRLF and LF newlines
        if self.current_char == "\r":
            # Check for CRLF
            if self._get_char(self.position.index + 1) == "\n":
                token = Token(
                    TokenType.NEWLINE,
                    "\r\n",
                    self.position.line,
                    self.position.column,
                )
                self._advance()  # Skip \r
                self._advance()  # Skip \n
                return token^
            else:
                token = Token(
                    TokenType.NEWLINE,
                    "\r",
                    self.position.line,
                    self.position.column,
                )
                self._advance()
                return token^
        elif self.current_char == "\n":
            token = Token(
                TokenType.NEWLINE,
                "\n",
                self.position.line,
                self.position.column,
            )
            self._advance()
            return token^

        if self.current_char == "=":
            token = Token(
                TokenType.EQUAL, "=", self.position.line, self.position.column
            )
            self._advance()
            return token^

        if self.current_char == ",":
            token = Token(
                TokenType.COMMA, ",", self.position.line, self.position.column
            )
            self._advance()
            return token^

        if self.current_char == ".":
            token = Token(
                TokenType.DOT, ".", self.position.line, self.position.column
            )
            self._advance()
            return token^

        if self.current_char == "[":
            # Check if next char is also [
            if self._get_char(self.position.index + 1) == "[":
                # This is an array of tables start
                token = Token(
                    TokenType.ARRAY_OF_TABLES_START,
                    "[[",
                    self.position.line,
                    self.position.column,
                )
                self._advance()  # Skip first [
                self._advance()  # Skip second [
                return token^
            else:
                # Regular table start
                token = Token(
                    TokenType.TABLE_START,
                    "[",
                    self.position.line,
                    self.position.column,
                )
                self._advance()
                return token^

        if self.current_char == "]":
            token = Token(
                TokenType.ARRAY_END,
                "]",
                self.position.line,
                self.position.column,
            )
            self._advance()
            return token^

        if self.current_char == QUOTE or self.current_char == LITERAL_QUOTE:
            return self._read_string()

        # Handle sign prefixes: +42, -42, +3.14, -3.14, +inf, -inf, +nan, -nan
        if self.current_char == "+" or self.current_char == "-":
            var sign_char = self.current_char
            var next_ch = self._get_char(self.position.index + 1)
            if next_ch.is_ascii_digit():
                self._advance()  # skip the sign
                return self._read_number(sign_char)
            # +inf, -inf, +nan, -nan
            var next2 = self._get_char(self.position.index + 2)
            var next3 = self._get_char(self.position.index + 3)
            if next_ch == "i" and next2 == "n" and next3 == "f":
                var start_line = self.position.line
                var start_col = self.position.column
                self._advance()  # skip sign
                self._advance()  # skip i
                self._advance()  # skip n
                self._advance()  # skip f
                if sign_char == "-":
                    return Token(
                        TokenType.FLOAT,
                        "-inf",
                        start_line,
                        start_col,
                    )
                return Token(TokenType.FLOAT, "inf", start_line, start_col)
            if next_ch == "n" and next2 == "a" and next3 == "n":
                var start_line = self.position.line
                var start_col = self.position.column
                self._advance()  # skip sign
                self._advance()  # skip n
                self._advance()  # skip a
                self._advance()  # skip n
                return Token(TokenType.FLOAT, "nan", start_line, start_col)

        if self.current_char.is_ascii_digit():
            return self._read_number()

        if (
            self.current_char.is_ascii_digit()
            or self.current_char.isupper()
            or self.current_char.islower()
            or self.current_char == "_"
        ):
            return self._read_key()

        # Unrecognized character
        token = Token(
            TokenType.ERROR,
            "Unexpected character: " + self.current_char,
            self.position.line,
            self.position.column,
        )
        self._advance()
        return token^

    fn tokenize(mut self) -> List[Token]:
        """Tokenize the entire source text."""
        var tokens = List[Token]()
        var token = self.next_token()

        while token.type != TokenType.EOF and token.type != TokenType.ERROR:
            tokens.append(token^)
            token = self.next_token()

        # Add EOF token
        if token.type == TokenType.EOF:
            tokens.append(token^)

        return tokens^
