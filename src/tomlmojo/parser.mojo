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
A simple TOML parser for Mojo.
This provides basic parsing for TOML files, focusing on the core elements
needed for test case parsing.
"""

from collections import Dict
from .tokenizer import Token, TokenType, Tokenizer


@value
struct TOMLValue:
    """Represents a value in the TOML document."""

    var type: TOMLValueType
    var string_value: String
    var int_value: Int
    var float_value: Float64
    var bool_value: Bool
    var array_values: List[TOMLValue]
    var table_values: Dict[String, TOMLValue]

    fn __init__(out self):
        """Initialize an empty TOML value."""
        self.type = TOMLValueType.NULL
        self.string_value = ""
        self.int_value = 0
        self.float_value = 0.0
        self.bool_value = False
        self.array_values = List[TOMLValue]()
        self.table_values = Dict[String, TOMLValue]()

    fn __init__(out self, string_value: String):
        """Initialize a string TOML value."""
        self.type = TOMLValueType.STRING
        self.string_value = string_value
        self.int_value = 0
        self.float_value = 0.0
        self.bool_value = False
        self.array_values = List[TOMLValue]()
        self.table_values = Dict[String, TOMLValue]()

    fn __init__(out self, int_value: Int):
        """Initialize an integer TOML value."""
        self.type = TOMLValueType.INTEGER
        self.string_value = ""
        self.int_value = int_value
        self.float_value = 0.0
        self.bool_value = False
        self.array_values = List[TOMLValue]()
        self.table_values = Dict[String, TOMLValue]()

    fn __init__(out self, float_value: Float64):
        """Initialize a float TOML value."""
        self.type = TOMLValueType.FLOAT
        self.string_value = ""
        self.int_value = 0
        self.float_value = float_value
        self.bool_value = False
        self.array_values = List[TOMLValue]()
        self.table_values = Dict[String, TOMLValue]()

    fn __init__(out self, bool_value: Bool):
        """Initialize a boolean TOML value."""
        self.type = TOMLValueType.BOOLEAN
        self.string_value = ""
        self.int_value = 0
        self.float_value = 0.0
        self.bool_value = bool_value
        self.array_values = List[TOMLValue]()
        self.table_values = Dict[String, TOMLValue]()

    fn as_string(self) -> String:
        """Get the value as a string."""
        if self.type == TOMLValueType.STRING:
            return self.string_value
        elif self.type == TOMLValueType.INTEGER:
            return String(self.int_value)
        elif self.type == TOMLValueType.FLOAT:
            return String(self.float_value)
        elif self.type == TOMLValueType.BOOLEAN:
            return "true" if self.bool_value else "false"
        else:
            return ""

    fn as_int(self) -> Int:
        """Get the value as an integer."""
        if self.type == TOMLValueType.INTEGER:
            return self.int_value
        else:
            return 0

    fn as_float(self) -> Float64:
        """Get the value as a float."""
        if self.type == TOMLValueType.FLOAT:
            return self.float_value
        elif self.type == TOMLValueType.INTEGER:
            return Float64(self.int_value)
        else:
            return 0.0

    fn as_bool(self) -> Bool:
        """Get the value as a boolean."""
        if self.type == TOMLValueType.BOOLEAN:
            return self.bool_value
        else:
            return False


@value
struct TOMLValueType:
    """Types of values in TOML."""

    # Aliases to mimic enum constants
    alias NULL = TOMLValueType.null()
    alias STRING = TOMLValueType.string()
    alias INTEGER = TOMLValueType.integer()
    alias FLOAT = TOMLValueType.float()
    alias BOOLEAN = TOMLValueType.boolean()
    alias ARRAY = TOMLValueType.array()
    alias TABLE = TOMLValueType.table()

    var value: Int

    # Static methods for each value type
    @staticmethod
    fn null() -> TOMLValueType:
        return TOMLValueType(0)

    @staticmethod
    fn string() -> TOMLValueType:
        return TOMLValueType(1)

    @staticmethod
    fn integer() -> TOMLValueType:
        return TOMLValueType(2)

    @staticmethod
    fn float() -> TOMLValueType:
        return TOMLValueType(3)

    @staticmethod
    fn boolean() -> TOMLValueType:
        return TOMLValueType(4)

    @staticmethod
    fn array() -> TOMLValueType:
        return TOMLValueType(5)

    @staticmethod
    fn table() -> TOMLValueType:
        return TOMLValueType(6)

    # Constructor
    fn __init__(out self, value: Int):
        self.value = value

    # Equality comparison
    fn __eq__(self, other: TOMLValueType) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: TOMLValueType) -> Bool:
        return self.value != other.value

    # String representation for debugging
    fn to_string(self) -> String:
        if self == Self.NULL:
            return "NULL"
        elif self == Self.STRING:
            return "STRING"
        elif self == Self.INTEGER:
            return "INTEGER"
        elif self == Self.FLOAT:
            return "FLOAT"
        elif self == Self.BOOLEAN:
            return "BOOLEAN"
        elif self == Self.ARRAY:
            return "ARRAY"
        elif self == Self.TABLE:
            return "TABLE"
        else:
            return "UNKNOWN"


@value
struct TOMLDocument:
    """Represents a parsed TOML document."""

    var root: Dict[String, TOMLValue]

    fn __init__(out self):
        self.root = Dict[String, TOMLValue]()

    fn get(self, key: String) raises -> TOMLValue:
        """Get a value from the document."""
        if key in self.root:
            return self.root[key]
        return TOMLValue()  # Return empty/null value

    fn get_table(self, table_name: String) raises -> Dict[String, TOMLValue]:
        """Get a table from the document."""
        if (
            table_name in self.root
            and self.root[table_name].type == TOMLValueType.TABLE
        ):
            return self.root[table_name].table_values
        return Dict[String, TOMLValue]()

    fn get_array(self, key: String) raises -> List[TOMLValue]:
        """Get an array from the document."""
        if key in self.root and self.root[key].type == TOMLValueType.ARRAY:
            return self.root[key].array_values
        return List[TOMLValue]()

    fn get_array_of_tables(
        self, key: String
    ) raises -> List[Dict[String, TOMLValue]]:
        """Get an array of tables from the document."""
        var result = List[Dict[String, TOMLValue]]()

        if key in self.root:
            var value = self.root[key]
            if value.type == TOMLValueType.ARRAY:
                for table_value in value.array_values:
                    if table_value.type == TOMLValueType.TABLE:
                        result.append(table_value.table_values)

        return result


struct TOMLParser:
    """Parses TOML source text into a TOMLDocument."""

    var tokens: List[Token]
    var current_index: Int

    fn __init__(out self, source: String):
        var tokenizer = Tokenizer(source)
        self.tokens = tokenizer.tokenize()
        self.current_index = 0

    fn __init__(out self, tokens: List[Token]):
        self.tokens = tokens
        self.current_index = 0

    fn current_token(self) -> Token:
        """Get the current token."""
        if self.current_index < len(self.tokens):
            return self.tokens[self.current_index]
        # Return EOF token if we're past the end
        return Token(TokenType.EOF, "", 0, 0)

    fn advance(mut self):
        """Move to the next token."""
        self.current_index += 1

    fn parse_key_value(mut self) raises -> Tuple[String, TOMLValue]:
        """Parse a key-value pair."""
        if self.current_token().type != TokenType.KEY:
            return (String(""), TOMLValue())

        var key = self.current_token().value
        self.advance()

        if self.current_token().type != TokenType.EQUAL:
            return (key, TOMLValue())
        self.advance()

        var value = self.parse_value()
        return (key, value)

    fn parse_value(mut self) raises -> TOMLValue:
        """Parse a TOML value."""
        var token = self.current_token()
        self.advance()

        if token.type == TokenType.STRING:
            return TOMLValue(token.value)
        elif token.type == TokenType.INTEGER:
            return TOMLValue(atol(token.value))
        elif token.type == TokenType.FLOAT:
            return TOMLValue(atof(token.value))
        elif token.type == TokenType.KEY:
            if token.value == "true":
                return TOMLValue(True)
            elif token.value == "false":
                return TOMLValue(False)
            # Default to string for other keys
            return TOMLValue(token.value)
        elif token.type == TokenType.ARRAY_START:
            var array = List[TOMLValue]()

            # Parse values until we reach the end of the array
            while (
                self.current_token().type != TokenType.ARRAY_END
                and self.current_token().type != TokenType.EOF
            ):
                array.append(self.parse_value())

                # Skip comma if present
                if self.current_token().type == TokenType.COMMA:
                    self.advance()

            # Skip the closing bracket
            if self.current_token().type == TokenType.ARRAY_END:
                self.advance()

            var result = TOMLValue()
            result.type = TOMLValueType.ARRAY
            result.array_values = array
            return result

        # Default to NULL value
        return TOMLValue()

    fn parse_table(mut self) raises -> Tuple[String, Dict[String, TOMLValue]]:
        """Parse a table section."""
        # Skip '[' token
        self.advance()

        if self.current_token().type != TokenType.KEY:
            return (String(""), Dict[String, TOMLValue]())

        var table_name = self.current_token().value
        self.advance()

        # Skip ']' token
        if self.current_token().type == TokenType.ARRAY_END:
            self.advance()

        var table_values = Dict[String, TOMLValue]()

        # Skip newline after table header
        while self.current_token().type == TokenType.NEWLINE:
            self.advance()

        var key: String
        var value: TOMLValue

        # Parse key-value pairs until we reach a new table or EOF
        while self.current_token().type == TokenType.KEY:
            key, value = self.parse_key_value()
            if key:
                table_values[key] = value

            # Skip newline
            if self.current_token().type == TokenType.NEWLINE:
                self.advance()

        return (table_name, table_values)

    fn parse(mut self) raises -> TOMLDocument:
        """Parse the tokens into a TOMLDocument."""
        var document = TOMLDocument()

        while self.current_index < len(self.tokens):
            var token = self.current_token()

            if token.type == TokenType.NEWLINE:
                self.advance()
                continue

            elif token.type == TokenType.TABLE_START:
                var table_name: String
                var table_values: Dict[String, TOMLValue]
                table_name, table_values = self.parse_table()
                if table_name:
                    var table_value = TOMLValue()
                    table_value.type = TOMLValueType.TABLE
                    table_value.table_values = table_values
                    document.root[table_name] = table_value

            elif token.type == TokenType.ARRAY_OF_TABLES_START:
                # Get table name
                self.advance()
                if self.current_token().type != TokenType.KEY:
                    self.advance()
                    continue

                var table_name = self.current_token().value
                self.advance()

                # Skip closing brackets
                if self.current_token().type == TokenType.ARRAY_END:
                    self.advance()
                if self.current_token().type == TokenType.ARRAY_END:
                    self.advance()

                # Skip newlines
                while self.current_token().type == TokenType.NEWLINE:
                    self.advance()

                # Parse table contents
                var table_values = Dict[String, TOMLValue]()

                # Parse key-value pairs
                while self.current_token().type == TokenType.KEY:
                    var key: String
                    var value: TOMLValue
                    key, value = self.parse_key_value()
                    if key:
                        table_values[key] = value

                    # Skip newline
                    if self.current_token().type == TokenType.NEWLINE:
                        self.advance()

                # Create table value
                var table_value = TOMLValue()
                table_value.type = TOMLValueType.TABLE
                table_value.table_values = table_values

                # Add to array of tables
                if (
                    table_name in document.root
                    and document.root[table_name].type == TOMLValueType.ARRAY
                ):
                    # Array exists, append to it
                    document.root[table_name].array_values.append(table_value)
                else:
                    # Create new array with this table
                    var array_value = TOMLValue()
                    array_value.type = TOMLValueType.ARRAY
                    array_value.array_values = List[TOMLValue]()
                    array_value.array_values.append(table_value)
                    document.root[table_name] = array_value

            elif token.type == TokenType.KEY:
                var key: String
                var value: TOMLValue
                key, value = self.parse_key_value()
                if key:
                    document.root[key] = value

                # Skip newline
                if self.current_token().type == TokenType.NEWLINE:
                    self.advance()

            elif token.type == TokenType.ARRAY_START:
                var table_name: String
                var table_values: Dict[String, TOMLValue]
                table_name, table_values = self.parse_table()
                if table_name:
                    var table_value = TOMLValue()
                    table_value.type = TOMLValueType.TABLE
                    table_value.table_values = table_values
                    document.root[table_name] = table_value
            else:
                self.advance()

        return document


fn parse_string(input: String) raises -> TOMLDocument:
    """Parse a TOML string into a document."""
    var parser = TOMLParser(input)
    return parser.parse()


fn parse_file(file_path: String) raises -> TOMLDocument:
    """Parse a TOML file into a document."""

    with open(file_path, "r") as file:
        content = file.read()

    return parse_string(content)
