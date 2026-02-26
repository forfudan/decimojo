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
Shunting-Yard parser for the Decimo CLI calculator.

Converts infix token lists to Reverse Polish Notation (RPN).
"""

from .tokenizer import (
    Token,
    TK_NUMBER,
    TK_PLUS,
    TK_MINUS,
    TK_STAR,
    TK_SLASH,
    TK_LPAREN,
    TK_RPAREN,
    TK_UNARY_MINUS,
)


fn parse_to_rpn(tokens: List[Token]) raises -> List[Token]:
    """Convert infix tokens to Reverse Polish Notation using
    Dijkstra's shunting-yard algorithm.
    """
    var output = List[Token]()
    var op_stack = List[Token]()

    for i in range(len(tokens)):
        var kind = tokens[i].kind

        if kind == TK_NUMBER:
            output.append(tokens[i])

        elif (
            kind == TK_PLUS
            or kind == TK_MINUS
            or kind == TK_STAR
            or kind == TK_SLASH
            or kind == TK_UNARY_MINUS
        ):
            var tok_prec = tokens[i].precedence()
            var tok_left = tokens[i].is_left_associative()
            # Pop operators with higher (or equal for left-assoc) precedence
            while len(op_stack) > 0:
                var top_kind = op_stack[len(op_stack) - 1].kind
                if top_kind == TK_LPAREN:
                    break
                if not op_stack[len(op_stack) - 1].is_operator():
                    break
                var top_prec = op_stack[len(op_stack) - 1].precedence()
                if tok_left:
                    if top_prec >= tok_prec:
                        output.append(op_stack.pop())
                    else:
                        break
                else:
                    # Right-associative: only pop if strictly greater
                    if top_prec > tok_prec:
                        output.append(op_stack.pop())
                    else:
                        break
            op_stack.append(tokens[i])

        elif kind == TK_LPAREN:
            op_stack.append(tokens[i])

        elif kind == TK_RPAREN:
            # Pop until we find the matching '('
            var found_lparen = False
            while len(op_stack) > 0:
                if op_stack[len(op_stack) - 1].kind == TK_LPAREN:
                    found_lparen = True
                    break
                output.append(op_stack.pop())
            if not found_lparen:
                raise Error("Mismatched parentheses: missing '('")
            _ = op_stack.pop()  # Discard the '('

    # Pop remaining operators
    while len(op_stack) > 0:
        var top = op_stack.pop()
        if top.kind == TK_LPAREN:
            raise Error("Mismatched parentheses: missing ')'")
        output.append(top^)

    return output^
