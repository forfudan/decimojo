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
A simple TOML tokenizer for Mojo.
This provides basic tokenization for TOML files, focusing on the core elements
needed for test case parsing.
"""

alias WHITESPACE = " \t"
alias COMMENT_START = "#"
alias QUOTE = '"'
alias LITERAL_QUOTE = "'"


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
    alias KEY = TokenType.key()
    alias STRING = TokenType.string()
    alias INTEGER = TokenType.integer()
    alias FLOAT = TokenType.float()
    alias BOOLEAN = TokenType.boolean()
    alias DATETIME = TokenType.datetime()
    alias ARRAY_START = TokenType.array_start()
    alias ARRAY_END = TokenType.array_end()
    alias TABLE_START = TokenType.table_start()
    alias TABLE_END = TokenType.table_end()
    alias ARRAY_OF_TABLES_START = TokenType.array_of_tables_start()
    alias EQUAL = TokenType.equal()
    alias COMMA = TokenType.comma()
    alias NEWLINE = TokenType.newline()
    alias DOT = TokenType.dot()
    alias EOF = TokenType.eof()
    alias ERROR = TokenType.error()

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
            self.current_char = String(source[0])
        else:
            self.current_char = ""

    fn _get_char(self, index: Int) -> String:
        """Get character at given index or empty string if out of bounds."""
        if index >= len(self.source):
            return ""
        return String(self.source[index])

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
        """Read a string value."""
        start_line = self.position.line
        start_column = self.position.column
        quote_char = self.current_char

        # Skip opening quote
        self._advance()

        var chars = List[String]()

        while self.current_char and self.current_char != quote_char:
            # Handle escape sequence
            if (
                self.current_char == r"\\"
                and self._get_char(self.position.index + 1) == quote_char
            ):
                self._advance()
                chars.append(quote_char)
            else:
                chars.append(self.current_char)
            self._advance()

        result = String.join("", chars)

        # Skip closing quote
        if self.current_char == quote_char:
            self._advance()
            return Token(TokenType.STRING, result, start_line, start_column)
        else:
            return Token(
                TokenType.ERROR, "Unterminated string", start_line, start_column
            )

    fn _read_number(mut self) -> Token:
        """Read a number value."""
        start_line = self.position.line
        start_column = self.position.column
        result = String("")
        is_float = False

        while self.current_char and (
            self.current_char.isdigit() or self.current_char == "."
        ):
            if self.current_char == ".":
                is_float = True
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
            self.current_char.isdigit()
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

        if self.current_char.isdigit():
            return self._read_number()

        if (
            self.current_char.isdigit()
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
