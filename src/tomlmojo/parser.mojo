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
A TOML parser for Mojo, implementing the core TOML v1.0 specification.

Supports:
- All basic types: strings, integers, floats, booleans
- Inline tables: {key = "value", port = 8080}
- Dotted keys: a.b.c = "value" → nested tables
- Dotted table headers: [a.b.c] → nested tables
- Quoted keys: "my key" = "value"
- Array of tables: [[section]]
- Multiline arrays with comments and trailing commas
- Unicode escape sequences: \\uXXXX, \\UXXXXXXXX
- Duplicate key detection
"""

from collections import Dict
from .tokenizer import Token, TokenType, Tokenizer


struct TOMLValue(Copyable, ImplicitlyCopyable, Movable):
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

    fn __copyinit__(out self, other: Self):
        self.type = other.type
        self.string_value = other.string_value
        self.int_value = other.int_value
        self.float_value = other.float_value
        self.bool_value = other.bool_value
        self.array_values = other.array_values.copy()
        self.table_values = other.table_values.copy()

    fn is_table(self) -> Bool:
        """Check if this value is a table."""
        return self.type == TOMLValueType.TABLE

    fn is_array(self) -> Bool:
        """Check if this value is an array."""
        return self.type == TOMLValueType.ARRAY

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

    fn as_table(self) -> Dict[String, TOMLValue]:
        """Get the value as a table dictionary."""
        if self.type == TOMLValueType.TABLE:
            return self.table_values.copy()
        return Dict[String, TOMLValue]()

    fn as_array(self) -> List[TOMLValue]:
        """Get the value as an array."""
        if self.type == TOMLValueType.ARRAY:
            return self.array_values.copy()
        return List[TOMLValue]()


struct TOMLValueType(Copyable, ImplicitlyCopyable, Movable):
    """Types of values in TOML."""

    comptime NULL = TOMLValueType.null()
    comptime STRING = TOMLValueType.string()
    comptime INTEGER = TOMLValueType.integer()
    comptime FLOAT = TOMLValueType.float()
    comptime BOOLEAN = TOMLValueType.boolean()
    comptime ARRAY = TOMLValueType.array()
    comptime TABLE = TOMLValueType.table()

    var value: Int

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

    fn __init__(out self, value: Int):
        self.value = value

    fn __eq__(self, other: TOMLValueType) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: TOMLValueType) -> Bool:
        return self.value != other.value

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


struct TOMLDocument(Copyable, Movable):
    """Represents a parsed TOML document."""

    var root: Dict[String, TOMLValue]

    fn __init__(out self):
        self.root = Dict[String, TOMLValue]()

    fn get(self, key: String) raises -> TOMLValue:
        """Get a value from the document."""
        if key in self.root:
            return self.root[key]
        return TOMLValue()

    fn get_table(self, table_name: String) raises -> Dict[String, TOMLValue]:
        """Get a table from the document."""
        if (
            table_name in self.root
            and self.root[table_name].type == TOMLValueType.TABLE
        ):
            return self.root[table_name].table_values.copy()
        return Dict[String, TOMLValue]()

    fn get_array(self, key: String) raises -> List[TOMLValue]:
        """Get an array from the document."""
        if key in self.root and self.root[key].type == TOMLValueType.ARRAY:
            return self.root[key].array_values.copy()
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
                        result.append(table_value.table_values.copy())

        return result^


# ---------------------------------------------------------------------------
# Helper: create a TOMLValue wrapping a Dict as a TABLE
# ---------------------------------------------------------------------------
fn _make_table(var d: Dict[String, TOMLValue]) -> TOMLValue:
    var v = TOMLValue()
    v.type = TOMLValueType.TABLE
    v.table_values = d^
    return v^


# ---------------------------------------------------------------------------
# Helper: set a value at a nested path inside a table dict, creating
# intermediate tables as needed.  Detects duplicate keys.
# path = ["a", "b"] and key = "c" means root["a"]["b"]["c"] = value
# ---------------------------------------------------------------------------
fn _set_value(
    mut root: Dict[String, TOMLValue],
    path: List[String],
    key: String,
    var value: TOMLValue,
) raises:
    """Set a key-value pair at the given table path inside root.

    Navigates through `path` (creating intermediate tables as needed),
    then sets `key = value` in the target table.  Raises on duplicate
    non-table keys.
    """
    if len(path) == 0:
        # Set directly in root
        if key in root:
            # Both existing and new are tables → merge
            if (
                root[key].type == TOMLValueType.TABLE
                and value.type == TOMLValueType.TABLE
            ):
                var existing = root[key].table_values.copy()
                for entry in value.table_values.items():
                    if entry.key in existing:
                        raise Error("Duplicate key: " + key + "." + entry.key)
                    existing[entry.key] = entry.value.copy()
                root[key] = _make_table(existing^)
                return
            raise Error("Duplicate key: " + key)
        root[key] = value^
        return

    # Navigate / create intermediate tables
    var first = path[0]
    if first not in root:
        root[first] = _make_table(Dict[String, TOMLValue]())
    elif root[first].type != TOMLValueType.TABLE:
        # If it's an array-of-tables, we add to the last element
        if root[first].type == TOMLValueType.ARRAY:
            var arr = root[first].array_values.copy()
            if len(arr) > 0:
                var last_tbl = arr[len(arr) - 1].table_values.copy()
                var remaining = List[String]()
                for i in range(1, len(path)):
                    remaining.append(path[i])
                _set_value(last_tbl, remaining, key, value^)
                arr[len(arr) - 1] = _make_table(last_tbl^)
                root[first].array_values = arr^
                return
        raise Error("Key exists but is not a table: " + first)

    var table = root[first].table_values.copy()
    var remaining = List[String]()
    for i in range(1, len(path)):
        remaining.append(path[i])
    _set_value(table, remaining, key, value^)
    root[first] = _make_table(table^)


# ---------------------------------------------------------------------------
# Helper: ensure a table path exists and return a mutable reference-path
# For [a.b.c], ensure root["a"]["b"]["c"] exists as a table.
# ---------------------------------------------------------------------------
fn _ensure_table_path(
    mut root: Dict[String, TOMLValue], path: List[String]
) raises:
    """Ensure all tables along `path` exist in `root`."""
    if len(path) == 0:
        return

    var first = path[0]
    if first not in root:
        root[first] = _make_table(Dict[String, TOMLValue]())
    elif root[first].type == TOMLValueType.ARRAY:
        # For array-of-tables: navigate into the last element
        var arr = root[first].array_values.copy()
        if len(arr) > 0:
            var last_tbl = arr[len(arr) - 1].table_values.copy()
            var remaining = List[String]()
            for i in range(1, len(path)):
                remaining.append(path[i])
            _ensure_table_path(last_tbl, remaining)
            arr[len(arr) - 1] = _make_table(last_tbl^)
            root[first].array_values = arr^
            return
    elif root[first].type != TOMLValueType.TABLE:
        raise Error("Key exists but is not a table: " + first)

    if len(path) > 1:
        var table = root[first].table_values.copy()
        var remaining = List[String]()
        for i in range(1, len(path)):
            remaining.append(path[i])
        _ensure_table_path(table, remaining)
        root[first] = _make_table(table^)


# ---------------------------------------------------------------------------
# Helper: for [[a.b.c]], ensure path and append a new empty table to the
# array at the final key.
# ---------------------------------------------------------------------------
fn _append_array_of_tables(
    mut root: Dict[String, TOMLValue], path: List[String]
) raises:
    """Append a new empty table to the array-of-tables at `path`."""
    if len(path) == 0:
        raise Error("Array of tables path cannot be empty")

    if len(path) == 1:
        var key = path[0]
        if key not in root:
            # Create new array with one empty table
            var arr_val = TOMLValue()
            arr_val.type = TOMLValueType.ARRAY
            arr_val.array_values = List[TOMLValue]()
            arr_val.array_values.append(_make_table(Dict[String, TOMLValue]()))
            root[key] = arr_val^
        elif root[key].type == TOMLValueType.ARRAY:
            root[key].array_values.append(
                _make_table(Dict[String, TOMLValue]())
            )
        else:
            raise Error("Cannot redefine as array of tables: " + key)
        return

    # Multi-part path: navigate to the parent, then handle the last key
    var first = path[0]
    if first not in root:
        root[first] = _make_table(Dict[String, TOMLValue]())

    if root[first].type == TOMLValueType.TABLE:
        var table = root[first].table_values.copy()
        var remaining = List[String]()
        for i in range(1, len(path)):
            remaining.append(path[i])
        _append_array_of_tables(table, remaining)
        root[first] = _make_table(table^)
    elif root[first].type == TOMLValueType.ARRAY:
        # Navigate into last element of the array
        var arr = root[first].array_values.copy()
        if len(arr) > 0:
            var last_tbl = arr[len(arr) - 1].table_values.copy()
            var remaining = List[String]()
            for i in range(1, len(path)):
                remaining.append(path[i])
            _append_array_of_tables(last_tbl, remaining)
            arr[len(arr) - 1] = _make_table(last_tbl^)
            root[first].array_values = arr^
    else:
        raise Error("Key exists but is not a table or array: " + first)


# ---------------------------------------------------------------------------
# Helper: get a reference to the "current table" for a given path.
# For array-of-tables paths, this returns the last element's table_values.
# We return a copy; the caller must write it back.
# ---------------------------------------------------------------------------
fn _get_table_at_path(
    root: Dict[String, TOMLValue], path: List[String]
) raises -> Dict[String, TOMLValue]:
    """Return a copy of the table at the given nested path."""
    if len(path) == 0:
        return root.copy()

    var first = path[0]
    if first not in root:
        raise Error("Table path not found: " + first)

    var remaining = List[String]()
    for i in range(1, len(path)):
        remaining.append(path[i])

    if root[first].type == TOMLValueType.TABLE:
        return _get_table_at_path(root[first].table_values, remaining)
    elif root[first].type == TOMLValueType.ARRAY:
        var arr = root[first].array_values.copy()
        if len(arr) > 0:
            return _get_table_at_path(arr[len(arr) - 1].table_values, remaining)
    raise Error("Not a table at path: " + first)


struct TOMLParser:
    """Parses TOML source text into a TOMLDocument."""

    var tokens: List[Token]
    var pos: Int

    fn __init__(out self, source: String):
        var tokenizer = Tokenizer(source)
        self.tokens = tokenizer.tokenize()
        self.pos = 0

    fn __init__(out self, tokens: List[Token]):
        self.tokens = tokens.copy()
        self.pos = 0

    # ---- token helpers ---------------------------------------------------

    fn _tok(self) -> Token:
        """Get current token."""
        if self.pos < len(self.tokens):
            return self.tokens[self.pos].copy()
        return Token(TokenType.EOF, "", 0, 0)

    fn _advance(mut self):
        """Move to next token."""
        self.pos += 1

    fn _skip_newlines(mut self):
        """Skip NEWLINE tokens."""
        while self._tok().type == TokenType.NEWLINE:
            self._advance()

    fn _skip_ws(mut self):
        """Skip NEWLINE and COMMA tokens (for arrays)."""
        while (
            self._tok().type == TokenType.NEWLINE
            or self._tok().type == TokenType.COMMA
        ):
            self._advance()

    fn _is_key_token(self) -> Bool:
        """Check if current token can be a key (KEY or STRING)."""
        return (
            self._tok().type == TokenType.KEY
            or self._tok().type == TokenType.STRING
        )

    # ---- key parsing (supports dotted and quoted keys) -------------------

    fn _parse_key_path(mut self) raises -> List[String]:
        """Parse a dotted key path like a.b."c d".e.

        Returns a list of key parts.  Accepts both KEY and STRING tokens
        as key components.
        """
        var parts = List[String]()

        if not self._is_key_token():
            raise Error("Expected key")

        parts.append(self._tok().value)
        self._advance()

        # Continue while we see DOT followed by another key
        while self._tok().type == TokenType.DOT:
            self._advance()  # skip dot
            if not self._is_key_token():
                raise Error("Expected key after dot")
            parts.append(self._tok().value)
            self._advance()

        return parts^

    # ---- value parsing ---------------------------------------------------

    fn _parse_integer(self, val_str: String) raises -> TOMLValue:
        """Parse an integer string, handling hex/octal/binary prefixes."""
        if len(val_str) > 2:
            var prefix = String(val_str[:2])
            if prefix == "0x" or prefix == "0X":
                var hex_str = String(val_str[2:])
                var result: Int = 0
                for i in range(len(hex_str)):
                    var ch = String(hex_str[byte=i])
                    result *= 16
                    if ch >= "0" and ch <= "9":
                        result += ord(ch) - ord("0")
                    elif ch >= "a" and ch <= "f":
                        result += ord(ch) - ord("a") + 10
                    elif ch >= "A" and ch <= "F":
                        result += ord(ch) - ord("A") + 10
                return TOMLValue(result)
            elif prefix == "0o" or prefix == "0O":
                var oct_str = String(val_str[2:])
                var result: Int = 0
                for i in range(len(oct_str)):
                    result = result * 8 + (
                        ord(String(oct_str[byte=i])) - ord("0")
                    )
                return TOMLValue(result)
            elif prefix == "0b" or prefix == "0B":
                var bin_str = String(val_str[2:])
                var result: Int = 0
                for i in range(len(bin_str)):
                    result = result * 2 + (
                        ord(String(bin_str[byte=i])) - ord("0")
                    )
                return TOMLValue(result)
        return TOMLValue(atol(val_str))

    fn _parse_float(self, val_str: String) raises -> TOMLValue:
        """Parse a float string, handling inf/nan."""
        if val_str == "inf" or val_str == "+inf":
            return TOMLValue(Float64.MAX)
        elif val_str == "-inf":
            return TOMLValue(-Float64.MAX)
        elif val_str == "nan" or val_str == "+nan" or val_str == "-nan":
            return TOMLValue(atof("nan"))
        return TOMLValue(atof(val_str))

    fn _parse_value(mut self) raises -> TOMLValue:
        """Parse a TOML value."""
        var token = self._tok()
        self._advance()

        if token.type == TokenType.STRING:
            return TOMLValue(token.value)

        elif token.type == TokenType.INTEGER:
            return self._parse_integer(token.value)

        elif token.type == TokenType.FLOAT:
            return self._parse_float(token.value)

        elif token.type == TokenType.KEY:
            if token.value == "true":
                return TOMLValue(True)
            elif token.value == "false":
                return TOMLValue(False)
            elif token.value == "inf":
                return TOMLValue(Float64.MAX)
            elif token.value == "nan":
                return TOMLValue(atof("nan"))
            # Bare key used as a value — treat as string
            return TOMLValue(token.value)

        elif token.type == TokenType.ARRAY_START:
            return self._parse_array()

        elif token.type == TokenType.TABLE_START:
            # In value context, [ is an array start (tokenizer emits
            # TABLE_START for all [ tokens; the parser provides context)
            return self._parse_array()

        elif token.type == TokenType.INLINE_TABLE_START:
            return self._parse_inline_table()

        # Default
        return TOMLValue()

    # ---- arrays (with newline/comment support) ---------------------------

    fn _parse_array(mut self) raises -> TOMLValue:
        """Parse an array value (opening [ already consumed)."""
        var elements = List[TOMLValue]()

        self._skip_newlines()

        while (
            self._tok().type != TokenType.ARRAY_END
            and self._tok().type != TokenType.EOF
        ):
            elements.append(self._parse_value())
            self._skip_newlines()

            # Skip comma (optional trailing comma allowed)
            if self._tok().type == TokenType.COMMA:
                self._advance()
                self._skip_newlines()

        # Skip closing ]
        if self._tok().type == TokenType.ARRAY_END:
            self._advance()

        var result = TOMLValue()
        result.type = TOMLValueType.ARRAY
        result.array_values = elements^
        return result^

    # ---- inline tables ---------------------------------------------------

    fn _parse_inline_table(mut self) raises -> TOMLValue:
        """Parse an inline table { key = value, ... } (opening { consumed)."""
        var table = Dict[String, TOMLValue]()

        if self._tok().type == TokenType.INLINE_TABLE_END:
            self._advance()
            return _make_table(table^)

        while True:
            # Parse key (may be dotted)
            var key_parts = self._parse_key_path()

            # Expect equals
            if self._tok().type != TokenType.EQUAL:
                raise Error("Expected '=' in inline table")
            self._advance()

            # Parse value
            var value = self._parse_value()

            # Set value at potentially nested path
            if len(key_parts) == 1:
                if key_parts[0] in table:
                    raise Error(
                        "Duplicate key in inline table: " + key_parts[0]
                    )
                table[key_parts[0]] = value^
            else:
                # Dotted key: build nested structure
                var last_key = key_parts[len(key_parts) - 1]
                var path = List[String]()
                for i in range(len(key_parts) - 1):
                    path.append(key_parts[i])
                _set_value(table, path, last_key, value^)

            # Check what's next
            if self._tok().type == TokenType.COMMA:
                self._advance()
            elif self._tok().type == TokenType.INLINE_TABLE_END:
                self._advance()
                break
            else:
                raise Error("Expected ',' or '}' in inline table")

        return _make_table(table^)

    # ---- table header parsing --------------------------------------------

    fn _parse_table_header(mut self) raises -> List[String]:
        """Parse [a.b.c] and return the path.  Opening [ already consumed."""
        var path = self._parse_key_path()

        # Expect closing ]
        if self._tok().type == TokenType.ARRAY_END:
            self._advance()
        else:
            raise Error("Expected ']' after table header")

        return path^

    fn _parse_array_of_tables_header(mut self) raises -> List[String]:
        """Parse [[a.b.c]] and return the path.  Opening [[ already consumed."""
        var path = self._parse_key_path()

        # Expect closing ]]
        if self._tok().type == TokenType.ARRAY_END:
            self._advance()
        else:
            raise Error("Expected ']]' after array of tables header")
        if self._tok().type == TokenType.ARRAY_END:
            self._advance()
        else:
            raise Error("Expected ']]' after array of tables header")

        return path^

    # ---- main parse loop -------------------------------------------------

    fn parse(mut self) raises -> TOMLDocument:
        """Parse the tokens into a TOMLDocument."""
        var document = TOMLDocument()
        var current_path = List[String]()
        var is_array_of_tables = False

        while self.pos < len(self.tokens):
            var token = self._tok()

            if token.type == TokenType.NEWLINE:
                self._advance()
                continue

            elif token.type == TokenType.EOF:
                break

            elif token.type == TokenType.TABLE_START:
                # [table.path]
                self._advance()  # skip [
                current_path = self._parse_table_header()
                is_array_of_tables = False
                _ensure_table_path(document.root, current_path)
                self._skip_newlines()

            elif token.type == TokenType.ARRAY_OF_TABLES_START:
                # [[array.of.tables]]
                self._advance()  # skip [[
                current_path = self._parse_array_of_tables_header()
                is_array_of_tables = True
                _append_array_of_tables(document.root, current_path)
                self._skip_newlines()

            elif self._is_key_token():
                # Key-value pair (may have dotted key)
                var key_parts = self._parse_key_path()

                # Expect =
                if self._tok().type != TokenType.EQUAL:
                    self._advance()
                    continue
                self._advance()  # skip =

                var value = self._parse_value()

                # Build the full path: current_path + key_parts[:-1]
                var last_key = key_parts[len(key_parts) - 1]
                var full_path = List[String]()
                for p in current_path:
                    full_path.append(p)
                for i in range(len(key_parts) - 1):
                    full_path.append(key_parts[i])

                if is_array_of_tables:
                    # We need to set inside the last element of the array
                    _set_value(document.root, full_path, last_key, value^)
                else:
                    _set_value(document.root, full_path, last_key, value^)

                self._skip_newlines()

            else:
                # Unknown token — skip
                self._advance()

        return document^


fn parse_string(input: String) raises -> TOMLDocument:
    """Parse a TOML string into a document."""
    var parser = TOMLParser(input)
    return parser.parse()


fn parse_file(file_path: String) raises -> TOMLDocument:
    """Parse a TOML file into a document."""

    with open(file_path, "r") as file:
        content = file.read()

    return parse_string(content)
