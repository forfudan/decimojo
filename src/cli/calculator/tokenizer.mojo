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
Tokenizer for the Decimo CLI calculator.

Converts an expression string into a list of tokens for the parser.
"""

# ===----------------------------------------------------------------------=== #
# Token kinds
# ===----------------------------------------------------------------------=== #

comptime TK_NUMBER = 0
comptime TK_PLUS = 1
comptime TK_MINUS = 2
comptime TK_STAR = 3
comptime TK_SLASH = 4
comptime TK_LPAREN = 5
comptime TK_RPAREN = 6
comptime TK_UNARY_MINUS = 7


# ===----------------------------------------------------------------------=== #
# Token
# ===----------------------------------------------------------------------=== #


struct Token(Copyable, ImplicitlyCopyable, Movable):
    """A token produced by the lexer."""

    var kind: Int
    var value: String

    fn __init__(out self, kind: Int, value: String = ""):
        self.kind = kind
        self.value = value

    fn __copyinit__(out self, other: Self):
        self.kind = other.kind
        self.value = other.value

    fn __moveinit__(out self, deinit other: Self):
        self.kind = other.kind
        self.value = other.value^

    fn is_operator(self) -> Bool:
        """Returns True if this token is a binary or unary operator."""
        return (
            self.kind == TK_PLUS
            or self.kind == TK_MINUS
            or self.kind == TK_STAR
            or self.kind == TK_SLASH
            or self.kind == TK_UNARY_MINUS
        )

    fn precedence(self) -> Int:
        """Returns the precedence level (higher binds tighter)."""
        if self.kind == TK_PLUS or self.kind == TK_MINUS:
            return 1
        if self.kind == TK_STAR or self.kind == TK_SLASH:
            return 2
        if self.kind == TK_UNARY_MINUS:
            return 4
        return 0

    fn is_left_associative(self) -> Bool:
        """Returns True if this operator is left-associative."""
        if self.kind == TK_UNARY_MINUS:
            return False
        return True


# ===----------------------------------------------------------------------=== #
# Tokenizer
# ===----------------------------------------------------------------------=== #


fn tokenize(expr: String) raises -> List[Token]:
    """Convert an expression string into a list of tokens.

    Handles: numbers (integer and decimal), +, -, *, /, (, ),
    and distinguishes unary minus from binary minus.
    """
    var tokens = List[Token]()
    var expr_bytes = expr.as_string_slice().as_bytes()
    var n = len(expr_bytes)
    var ptr = expr_bytes.unsafe_ptr()
    var i = 0

    while i < n:
        var c = ptr[i]

        # Skip whitespace (space, tab)
        if c == 32 or c == 9:
            i += 1
            continue

        # --- Number literal: digits and at most one decimal point ---
        if (c >= 48 and c <= 57) or c == 46:  # '0'-'9' or '.'
            var start = i
            var has_dot = c == 46
            i += 1
            while i < n:
                var cc = ptr[i]
                if cc >= 48 and cc <= 57:
                    i += 1
                elif cc == 46 and not has_dot:
                    has_dot = True
                    i += 1
                else:
                    break
            # Build the number string from the byte range
            var num_bytes = List[UInt8](capacity=i - start)
            for j in range(start, i):
                num_bytes.append(ptr[j])
            tokens.append(Token(TK_NUMBER, String(unsafe_from_utf8=num_bytes^)))
            continue

        # --- Operators and parentheses ---
        if c == 43:  # '+'
            tokens.append(Token(TK_PLUS, "+"))
            i += 1
            continue

        if c == 45:  # '-'
            # Determine if this minus is unary or binary.
            # Unary if: at the start, or after an operator, or after '('
            var is_unary = len(tokens) == 0
            if not is_unary:
                var last_kind = tokens[len(tokens) - 1].kind
                is_unary = (
                    last_kind == TK_PLUS
                    or last_kind == TK_MINUS
                    or last_kind == TK_STAR
                    or last_kind == TK_SLASH
                    or last_kind == TK_LPAREN
                    or last_kind == TK_UNARY_MINUS
                )
            if is_unary:
                tokens.append(Token(TK_UNARY_MINUS, "neg"))
            else:
                tokens.append(Token(TK_MINUS, "-"))
            i += 1
            continue

        if c == 42:  # '*'
            tokens.append(Token(TK_STAR, "*"))
            i += 1
            continue

        if c == 47:  # '/'
            tokens.append(Token(TK_SLASH, "/"))
            i += 1
            continue

        if c == 40:  # '('
            tokens.append(Token(TK_LPAREN, "("))
            i += 1
            continue

        if c == 41:  # ')'
            tokens.append(Token(TK_RPAREN, ")"))
            i += 1
            continue

        raise Error("Unexpected character '" + chr(Int(c)) + "' in expression")

    return tokens^
