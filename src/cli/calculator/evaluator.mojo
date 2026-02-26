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
    TOKEN_NUMBER,
    TOKEN_PLUS,
    TOKEN_MINUS,
    TOKEN_STAR,
    TOKEN_SLASH,
    TOKEN_UNARY_MINUS,
    TOKEN_CARET,
    TOKEN_FUNC,
    TOKEN_CONST,
)
from .parser import parse_to_rpn
from .tokenizer import tokenize


# ===----------------------------------------------------------------------=== #
# Helper: dispatch a function call by name
# ===----------------------------------------------------------------------=== #


fn _call_func(name: String, mut stack: List[BDec], precision: Int) raises:
    """Pop argument(s) from `stack`, call the named Decimo function,
    and push the result back.

    Single-argument functions:
        sqrt, cbrt, ln, log, log10, exp, sin, cos, tan, cot, csc, abs

    Two-argument functions:
        root(x, n)  — the n-th root of x.
    """
    if name == "root":
        # root(x, n): x was pushed first, then n
        if len(stack) < 2:
            raise Error("root() requires two arguments: root(x, n)")
        var n_val = stack.pop()
        var x_val = stack.pop()
        stack.append(x_val.root(n_val, precision))
        return

    # All remaining functions take exactly one argument
    if len(stack) < 1:
        raise Error(name + "() requires one argument")
    var a = stack.pop()

    if name == "sqrt":
        stack.append(a.sqrt(precision))
    elif name == "cbrt":
        stack.append(a.cbrt(precision))
    elif name == "ln":
        stack.append(a.ln(precision))
    elif name == "log":
        stack.append(a.log10(precision))
    elif name == "log10":
        stack.append(a.log10(precision))
    elif name == "exp":
        stack.append(a.exp(precision))
    elif name == "sin":
        stack.append(a.sin(precision))
    elif name == "cos":
        stack.append(a.cos(precision))
    elif name == "tan":
        stack.append(a.tan(precision))
    elif name == "cot":
        stack.append(a.cot(precision))
    elif name == "csc":
        stack.append(a.csc(precision))
    elif name == "abs":
        stack.append(abs(a))
    else:
        raise Error("Unknown function: " + name)


# ===----------------------------------------------------------------------=== #
# Evaluator
# ===----------------------------------------------------------------------=== #


fn evaluate_rpn(rpn: List[Token], precision: Int) raises -> BDec:
    """Evaluate an RPN token list using BigDecimal arithmetic.

    All numbers are BigDecimal.  Division uses `true_divide` with
    the caller-supplied precision.
    """
    var stack = List[BDec]()

    for i in range(len(rpn)):
        var kind = rpn[i].kind

        if kind == TOKEN_NUMBER:
            stack.append(BDec.from_string(rpn[i].value))

        elif kind == TOKEN_CONST:
            if rpn[i].value == "pi":
                stack.append(BDec.pi(precision))
            elif rpn[i].value == "e":
                stack.append(BDec.from_string("1").exp(precision))
            else:
                raise Error("Unknown constant: " + rpn[i].value)

        elif kind == TOKEN_UNARY_MINUS:
            if len(stack) < 1:
                raise Error("Invalid expression: missing operand for negation")
            var a = stack.pop()
            stack.append(-a)

        elif kind == TOKEN_PLUS:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a + b)

        elif kind == TOKEN_MINUS:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a - b)

        elif kind == TOKEN_STAR:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a * b)

        elif kind == TOKEN_SLASH:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a.true_divide(b, precision))

        elif kind == TOKEN_CARET:
            if len(stack) < 2:
                raise Error("Invalid expression: missing operand")
            var b = stack.pop()
            var a = stack.pop()
            stack.append(a.power(b, precision))

        elif kind == TOKEN_FUNC:
            _call_func(rpn[i].value, stack, precision)

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
