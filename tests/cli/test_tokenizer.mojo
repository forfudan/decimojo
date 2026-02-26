"""Test the tokenizer: lexical analysis of expression strings."""

import testing

from calculator.tokenizer import (
    Token,
    tokenize,
    TK_NUMBER,
    TK_PLUS,
    TK_MINUS,
    TK_STAR,
    TK_SLASH,
    TK_LPAREN,
    TK_RPAREN,
    TK_UNARY_MINUS,
)


# ===----------------------------------------------------------------------=== #
# Helper
# ===----------------------------------------------------------------------=== #


fn assert_token(
    tokens: List[Token],
    index: Int,
    expected_kind: Int,
    expected_value: String,
    msg: String = "",
) raises:
    """Assert that tokens[index] has the expected kind and value."""
    testing.assert_equal(
        tokens[index].kind, expected_kind, msg + " (kind mismatch)"
    )
    testing.assert_equal(
        tokens[index].value, expected_value, msg + " (value mismatch)"
    )


# ===----------------------------------------------------------------------=== #
# Tests: basic tokens
# ===----------------------------------------------------------------------=== #


fn test_single_number() raises:
    var toks = tokenize("42")
    testing.assert_equal(len(toks), 1, "single number token count")
    assert_token(toks, 0, TK_NUMBER, "42", "single number")


fn test_decimal_number() raises:
    var toks = tokenize("3.14")
    testing.assert_equal(len(toks), 1, "decimal number token count")
    assert_token(toks, 0, TK_NUMBER, "3.14", "decimal number")


fn test_leading_dot() raises:
    var toks = tokenize(".5")
    testing.assert_equal(len(toks), 1, "leading dot token count")
    assert_token(toks, 0, TK_NUMBER, ".5", "leading dot")


fn test_simple_addition() raises:
    var toks = tokenize("2 + 3")
    testing.assert_equal(len(toks), 3, "2+3 token count")
    assert_token(toks, 0, TK_NUMBER, "2", "first operand")
    assert_token(toks, 1, TK_PLUS, "+", "operator")
    assert_token(toks, 2, TK_NUMBER, "3", "second operand")


fn test_all_operators() raises:
    var toks = tokenize("1+2-3*4/5")
    testing.assert_equal(len(toks), 9, "all ops token count")
    assert_token(toks, 1, TK_PLUS, "+", "plus")
    assert_token(toks, 3, TK_MINUS, "-", "minus")
    assert_token(toks, 5, TK_STAR, "*", "star")
    assert_token(toks, 7, TK_SLASH, "/", "slash")


fn test_parentheses() raises:
    var toks = tokenize("(2+3)*4")
    testing.assert_equal(len(toks), 7, "parens token count")
    assert_token(toks, 0, TK_LPAREN, "(", "left paren")
    assert_token(toks, 4, TK_RPAREN, ")", "right paren")


fn test_whitespace_handling() raises:
    var toks_no_space = tokenize("2+3")
    var toks_spaces = tokenize("  2  +  3  ")
    testing.assert_equal(
        len(toks_no_space), len(toks_spaces), "whitespace equivalence"
    )
    assert_token(toks_spaces, 0, TK_NUMBER, "2", "ws: first")
    assert_token(toks_spaces, 1, TK_PLUS, "+", "ws: op")
    assert_token(toks_spaces, 2, TK_NUMBER, "3", "ws: second")


# ===----------------------------------------------------------------------=== #
# Tests: unary minus detection
# ===----------------------------------------------------------------------=== #


fn test_unary_minus_at_start() raises:
    var toks = tokenize("-5")
    testing.assert_equal(len(toks), 2, "-5 token count")
    assert_token(toks, 0, TK_UNARY_MINUS, "neg", "unary at start")
    assert_token(toks, 1, TK_NUMBER, "5", "operand after unary")


fn test_unary_minus_after_lparen() raises:
    var toks = tokenize("(-5)")
    testing.assert_equal(len(toks), 4, "(-5) token count")
    assert_token(toks, 0, TK_LPAREN, "(", "lparen")
    assert_token(toks, 1, TK_UNARY_MINUS, "neg", "unary after lparen")
    assert_token(toks, 2, TK_NUMBER, "5", "operand")
    assert_token(toks, 3, TK_RPAREN, ")", "rparen")


fn test_unary_minus_after_operator() raises:
    var toks = tokenize("2*-3")
    testing.assert_equal(len(toks), 4, "2*-3 token count")
    assert_token(toks, 0, TK_NUMBER, "2", "first operand")
    assert_token(toks, 1, TK_STAR, "*", "multiply")
    assert_token(toks, 2, TK_UNARY_MINUS, "neg", "unary after *")
    assert_token(toks, 3, TK_NUMBER, "3", "second operand")


fn test_binary_minus() raises:
    var toks = tokenize("5-3")
    testing.assert_equal(len(toks), 3, "5-3 token count")
    assert_token(toks, 1, TK_MINUS, "-", "binary minus")


fn test_double_unary_minus() raises:
    var toks = tokenize("--5")
    testing.assert_equal(len(toks), 3, "--5 token count")
    assert_token(toks, 0, TK_UNARY_MINUS, "neg", "first neg")
    assert_token(toks, 1, TK_UNARY_MINUS, "neg", "second neg")
    assert_token(toks, 2, TK_NUMBER, "5", "operand")


# ===----------------------------------------------------------------------=== #
# Tests: multi-digit and large numbers
# ===----------------------------------------------------------------------=== #


fn test_large_integer() raises:
    var toks = tokenize("123456789012345678901234567890")
    testing.assert_equal(len(toks), 1, "large integer token count")
    assert_token(
        toks,
        0,
        TK_NUMBER,
        "123456789012345678901234567890",
        "large integer",
    )


fn test_long_decimal() raises:
    var toks = tokenize("3.141592653589793238462643383279")
    testing.assert_equal(len(toks), 1, "long decimal token count")
    assert_token(
        toks,
        0,
        TK_NUMBER,
        "3.141592653589793238462643383279",
        "long decimal",
    )


# ===----------------------------------------------------------------------=== #
# Tests: error cases
# ===----------------------------------------------------------------------=== #


fn test_invalid_character() raises:
    var raised = False
    try:
        _ = tokenize("2 @ 3")
    except:
        raised = True
    testing.assert_true(raised, "should raise on invalid character '@'")


fn test_empty_string() raises:
    var toks = tokenize("")
    testing.assert_equal(len(toks), 0, "empty string produces no tokens")


# ===----------------------------------------------------------------------=== #
# Main
# ===----------------------------------------------------------------------=== #


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
