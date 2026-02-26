"""Test the shunting-yard parser: infix to RPN conversion."""

import testing

from calculator.tokenizer import (
    Token,
    tokenize,
    TOKEN_NUMBER,
    TOKEN_PLUS,
    TOKEN_MINUS,
    TOKEN_STAR,
    TOKEN_SLASH,
    TOKEN_UNARY_MINUS,
)
from calculator.parser import parse_to_rpn


# ===----------------------------------------------------------------------=== #
# Helper: convert token list to a compact string for easy assertion
# e.g. "2 3 +" for RPN of "2+3"
# ===----------------------------------------------------------------------=== #


fn rpn_to_string(rpn: List[Token]) -> String:
    """Convert an RPN token list to a space-separated string."""
    var parts = List[String]()
    for i in range(len(rpn)):
        parts.append(rpn[i].value)
    var result = String("")
    for i in range(len(parts)):
        if i > 0:
            result += " "
        result += parts[i]
    return result^


fn parse_expr(expr: String) raises -> String:
    """Tokenize and parse an expression, return RPN as string."""
    var tokens = tokenize(expr)
    var rpn = parse_to_rpn(tokens^)
    return rpn_to_string(rpn^)


# ===----------------------------------------------------------------------=== #
# Tests: basic operator precedence
# ===----------------------------------------------------------------------=== #


fn test_simple_addition() raises:
    testing.assert_equal(parse_expr("2+3"), "2 3 +", "simple addition")


fn test_simple_subtraction() raises:
    testing.assert_equal(parse_expr("5-3"), "5 3 -", "simple subtraction")


fn test_mul_before_add() raises:
    """Multiplication has higher precedence than addition."""
    testing.assert_equal(parse_expr("2+3*4"), "2 3 4 * +", "mul before add")


fn test_div_before_sub() raises:
    """Division has higher precedence than subtraction."""
    testing.assert_equal(parse_expr("10-6/3"), "10 6 3 / -", "div before sub")


fn test_left_associativity_add() raises:
    """Addition is left-associative: 1+2+3 = (1+2)+3."""
    testing.assert_equal(parse_expr("1+2+3"), "1 2 + 3 +", "left assoc add")


fn test_left_associativity_mul() raises:
    """Multiplication is left-associative: 2*3*4 = (2*3)*4."""
    testing.assert_equal(parse_expr("2*3*4"), "2 3 * 4 *", "left assoc mul")


# ===----------------------------------------------------------------------=== #
# Tests: parentheses
# ===----------------------------------------------------------------------=== #


fn test_parens_override_precedence() raises:
    """Parentheses override normal precedence."""
    testing.assert_equal(parse_expr("(2+3)*4"), "2 3 + 4 *", "parens override")


fn test_nested_parens() raises:
    testing.assert_equal(
        parse_expr("((1+2)*(3+4))"), "1 2 + 3 4 + *", "nested parens"
    )


fn test_parens_around_single() raises:
    testing.assert_equal(parse_expr("(42)"), "42", "parens around single")


# ===----------------------------------------------------------------------=== #
# Tests: unary minus in RPN
# ===----------------------------------------------------------------------=== #


fn test_unary_minus_simple() raises:
    testing.assert_equal(parse_expr("-5"), "5 neg", "unary minus simple")


fn test_unary_minus_in_expr() raises:
    testing.assert_equal(parse_expr("-5+3"), "5 neg 3 +", "unary minus in expr")


fn test_unary_minus_after_mul() raises:
    testing.assert_equal(
        parse_expr("2*-3"), "2 3 neg *", "unary minus after mul"
    )


# ===----------------------------------------------------------------------=== #
# Tests: complex expressions
# ===----------------------------------------------------------------------=== #


fn test_complex_mixed() raises:
    """100*12-23/17 should parse correctly."""
    testing.assert_equal(
        parse_expr("100*12-23/17"),
        "100 12 * 23 17 / -",
        "100*12-23/17",
    )


fn test_complex_parens() raises:
    """(1+2)*(3-4)/(5+6)."""
    testing.assert_equal(
        parse_expr("(1+2)*(3-4)/(5+6)"),
        "1 2 + 3 4 - * 5 6 + /",
        "complex with parens",
    )


# ===----------------------------------------------------------------------=== #
# Tests: error handling
# ===----------------------------------------------------------------------=== #


fn test_mismatched_lparen() raises:
    var raised = False
    try:
        var tokens = tokenize("(2+3")
        _ = parse_to_rpn(tokens^)
    except:
        raised = True
    testing.assert_true(raised, "should raise on missing ')'")


fn test_mismatched_rparen() raises:
    var raised = False
    try:
        var tokens = tokenize("2+3)")
        _ = parse_to_rpn(tokens^)
    except:
        raised = True
    testing.assert_true(raised, "should raise on missing '('")


# ===----------------------------------------------------------------------=== #
# Main
# ===----------------------------------------------------------------------=== #


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
