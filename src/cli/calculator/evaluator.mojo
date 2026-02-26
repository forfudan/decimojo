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
RPN evaluator for the Decimo CLI calculator.

Evaluates a Reverse Polish Notation token list using BigDecimal arithmetic.
"""

from decimo import BDec

from .tokenizer import (
    Token,
    TK_NUMBER,
    TK_PLUS,
    TK_MINUS,
    TK_STAR,
    TK_SLASH,
    TK_UNARY_MINUS,
)
from .parser import parse_to_rpn
from .tokenizer import tokenize


fn evaluate_rpn(rpn: List[Token], precision: Int) raises -> BDec:
    """Evaluate an RPN token list using BigDecimal arithmetic.

    All numbers are BigDecimal.  Division uses `true_divide` with
    the caller-supplied precision.
    """
    var stack = List[BDec]()

    for i in range(len(rpn)):
        var kind = rpn[i].kind

        if kind == TK_NUMBER:
            stack.append(BDec.from_string(rpn[i].value))

        elif kind == TK_UNARY_MINUS:
            if len(stack) < 1:
                raise Error("Invalid expression: missing operand for negation")
            var a = stack.pop()
            stack.append(-a)

        elif kind == TK_PLUS:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a + b)

        elif kind == TK_MINUS:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a - b)

        elif kind == TK_STAR:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a * b)

        elif kind == TK_SLASH:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a.true_divide(b, precision))

        else:
            raise Error("Unexpected token in RPN evaluation")

    if len(stack) != 1:
        raise Error("Invalid expression: too many values remaining")

    return stack.pop()


fn evaluate(expr: String, precision: Int = 50) raises -> BDec:
    """Evaluate a math expression string and return a BigDecimal result.

    This is the main entry point for the calculator engine.
    It tokenizes, parses (shunting-yard), and evaluates (RPN) the expression.

    Args:
        expr: The math expression to evaluate (e.g. "100 * 12 - 23/17").
        precision: The number of decimal digits for division (default: 50).

    Returns:
        The result as a BigDecimal.
    """
    var tokens = tokenize(expr)
    var rpn = parse_to_rpn(tokens^)
    return evaluate_rpn(rpn^, precision)
