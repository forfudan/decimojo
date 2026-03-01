"""Test error handling and edge cases for the Decimo CLI calculator.

Phase 3 items 1 & 2: clear diagnostics for malformed expressions,
and proper handling of edge cases (empty expression, division by zero,
negative sqrt, etc.).
"""

import testing

from calculator import evaluate
from calculator.tokenizer import tokenize
from calculator.parser import parse_to_rpn


# ===----------------------------------------------------------------------=== #
# Helper: assert that an expression raises an error whose message
# contains the expected substring.
# ===----------------------------------------------------------------------=== #


fn assert_error_contains(expr: String, expected_substr: String) raises:
    """Evaluate `expr` and assert that it raises an Error containing
    `expected_substr` in its message.
    """
    try:
        var result = evaluate(expr)
        raise Error(
            "Expected an error for '"
            + expr
            + "' but got result: "
            + String(result)
        )
    except e:
        var msg = String(e)
        if expected_substr not in msg:
            raise Error(
                "Error message for '"
                + expr
                + "' was '"
                + msg
                + "', expected it to contain '"
                + expected_substr
                + "'"
            )


fn assert_tokenize_error_contains(expr: String, expected_substr: String) raises:
    """Tokenize `expr` and assert that it raises an Error containing
    `expected_substr`.
    """
    try:
        var tokens = tokenize(expr)
        raise Error(
            "Expected a tokenizer error for '"
            + expr
            + "' but got "
            + String(len(tokens))
            + " tokens"
        )
    except e:
        var msg = String(e)
        if expected_substr not in msg:
            raise Error(
                "Tokenizer error for '"
                + expr
                + "' was '"
                + msg
                + "', expected it to contain '"
                + expected_substr
                + "'"
            )


# ===----------------------------------------------------------------------=== #
# Tests: empty and whitespace-only expressions
# ===----------------------------------------------------------------------=== #


fn test_empty_expression() raises:
    assert_tokenize_error_contains("", "Empty expression")


fn test_whitespace_only() raises:
    assert_tokenize_error_contains("   ", "Empty expression")


fn test_tabs_only() raises:
    assert_tokenize_error_contains("\t\t", "Empty expression")


# ===----------------------------------------------------------------------=== #
# Tests: unknown identifiers
# ===----------------------------------------------------------------------=== #


fn test_unknown_identifier() raises:
    assert_error_contains("foo + 1", "unknown identifier 'foo'")


fn test_unknown_identifier_position() raises:
    assert_error_contains("1 + bar", "position 4")


# ===----------------------------------------------------------------------=== #
# Tests: unexpected characters
# ===----------------------------------------------------------------------=== #


fn test_unexpected_character() raises:
    assert_error_contains("1 @ 2", "unexpected character '@'")


fn test_unexpected_character_position() raises:
    assert_error_contains("1 + 2 # 3", "position 6")


# ===----------------------------------------------------------------------=== #
# Tests: mismatched parentheses
# ===----------------------------------------------------------------------=== #


fn test_missing_closing_paren() raises:
    assert_error_contains("(1 + 2", "unmatched '('")


fn test_missing_opening_paren() raises:
    assert_error_contains("1 + 2)", "unmatched ')'")


fn test_nested_missing_close() raises:
    assert_error_contains("((1+2) * 3", "unmatched '('")


fn test_extra_closing_paren() raises:
    assert_error_contains("(1+2))", "unmatched ')'")


# ===----------------------------------------------------------------------=== #
# Tests: division by zero
# ===----------------------------------------------------------------------=== #


fn test_division_by_zero() raises:
    assert_error_contains("1/0", "division by zero")


fn test_division_by_zero_expression() raises:
    assert_error_contains("10 / (5-5)", "division by zero")


fn test_division_by_zero_decimal() raises:
    assert_error_contains("1 / 0.0", "division by zero")


# ===----------------------------------------------------------------------=== #
# Tests: negative sqrt
# ===----------------------------------------------------------------------=== #


fn test_sqrt_negative() raises:
    assert_error_contains("sqrt(-4)", "sqrt() is undefined for negative")


fn test_sqrt_negative_expression() raises:
    assert_error_contains("sqrt(-1)", "sqrt() is undefined for negative")


# ===----------------------------------------------------------------------=== #
# Tests: logarithm of zero / negative
# ===----------------------------------------------------------------------=== #


fn test_ln_zero() raises:
    assert_error_contains("ln(0)", "ln() is undefined for zero")


fn test_ln_negative() raises:
    assert_error_contains("ln(-1)", "ln() is undefined for negative")


fn test_log10_zero() raises:
    assert_error_contains("log10(0)", "log10() is undefined for zero")


fn test_log10_negative() raises:
    assert_error_contains("log10(-5)", "log10() is undefined for negative")


# ===----------------------------------------------------------------------=== #
# Tests: misplaced commas
# ===----------------------------------------------------------------------=== #


fn test_comma_outside_function() raises:
    assert_error_contains("1, 2", "misplaced ','")


# ===----------------------------------------------------------------------=== #
# Tests: trailing operators
# ===----------------------------------------------------------------------=== #


fn test_trailing_plus() raises:
    assert_error_contains("1 +", "missing operand for '+'")


fn test_trailing_star() raises:
    assert_error_contains("1 *", "missing operand for '*'")


fn test_trailing_slash() raises:
    assert_error_contains("1 /", "missing operand for '/'")


fn test_leading_star() raises:
    assert_error_contains("* 1", "missing operand for '*'")


fn test_leading_slash() raises:
    assert_error_contains("/ 1", "missing operand for '/'")


# ===----------------------------------------------------------------------=== #
# Tests: consecutive operators (not unary minus)
# ===----------------------------------------------------------------------=== #


fn test_double_plus() raises:
    """1 ++ should fail: the second + has no left operand."""
    assert_error_contains("1 ++ 2", "missing operand")


fn test_double_star() raises:
    """1 * * 2 should fail."""
    assert_error_contains("1 * * 2", "missing operand")


# ===----------------------------------------------------------------------=== #
# Tests: position information in errors
# ===----------------------------------------------------------------------=== #


fn test_position_in_unknown_char() raises:
    """The '@' is at position 4 in '1 + @'."""
    assert_error_contains("1 + @", "position 4")


fn test_position_in_div_by_zero() raises:
    """The '/' is at position 1 in '1/0'."""
    assert_error_contains("1/0", "position 1")


fn test_position_in_sqrt_negative() raises:
    """'sqrt' starts at position 0 in 'sqrt(-1)'."""
    assert_error_contains("sqrt(-1)", "position 0")


# ===----------------------------------------------------------------------=== #
# Tests: edge cases that should still work
# ===----------------------------------------------------------------------=== #


fn test_negative_zero() raises:
    """Negation of zero should not raise an error."""
    var result = String(evaluate("-0"))
    testing.assert_true(
        result == "0" or result == "-0",
        "-0 should evaluate without error, got: " + result,
    )


fn test_deeply_nested_parens() raises:
    """((((1)))) should be fine."""
    testing.assert_equal(String(evaluate("((((1))))")), "1", "((((1))))")


fn test_many_operations() raises:
    """1+2+3+4+5+6+7+8+9+10 = 55."""
    testing.assert_equal(
        String(evaluate("1+2+3+4+5+6+7+8+9+10")), "55", "sum 1..10"
    )


fn test_function_of_constant() raises:
    """Compute sqrt(pi) — should not crash."""
    var result = String(evaluate("sqrt(pi)", precision=10))
    testing.assert_true(
        result.startswith("1.77245385"),
        "sqrt(pi) starts correctly: " + result,
    )


# ===----------------------------------------------------------------------=== #
# Main
# ===----------------------------------------------------------------------=== #


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
