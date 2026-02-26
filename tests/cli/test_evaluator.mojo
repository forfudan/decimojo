"""Test the evaluator: end-to-end expression evaluation with BigDecimal."""

import testing

from calculator import evaluate


# ===----------------------------------------------------------------------=== #
# Tests: basic arithmetic
# ===----------------------------------------------------------------------=== #


fn test_addition() raises:
    testing.assert_equal(String(evaluate("2+3")), "5", "2+3")


fn test_subtraction() raises:
    testing.assert_equal(String(evaluate("10-7")), "3", "10-7")


fn test_multiplication() raises:
    testing.assert_equal(String(evaluate("6*7")), "42", "6*7")


fn test_division_exact() raises:
    testing.assert_equal(String(evaluate("10/2")), "5", "10/2")


fn test_division_repeating() raises:
    """1/3 with precision=10 should give 10 decimal digits."""
    var result = String(evaluate("1/3", precision=10))
    testing.assert_equal(result, "0.3333333333", "1/3 p=10")


fn test_zero() raises:
    testing.assert_equal(String(evaluate("0+0")), "0", "0+0")


fn test_add_zero() raises:
    testing.assert_equal(String(evaluate("42+0")), "42", "42+0")


# ===----------------------------------------------------------------------=== #
# Tests: operator precedence
# ===----------------------------------------------------------------------=== #


fn test_mul_before_add() raises:
    testing.assert_equal(String(evaluate("2+3*4")), "14", "2+3*4")


fn test_div_before_sub() raises:
    testing.assert_equal(String(evaluate("10-6/3")), "8", "10-6/3")


fn test_left_to_right() raises:
    testing.assert_equal(String(evaluate("10-3-2")), "5", "10-3-2")


# ===----------------------------------------------------------------------=== #
# Tests: parentheses
# ===----------------------------------------------------------------------=== #


fn test_parens_simple() raises:
    testing.assert_equal(String(evaluate("(2+3)*4")), "20", "(2+3)*4")


fn test_nested_parens() raises:
    testing.assert_equal(
        String(evaluate("((1+2)*(3+4))")), "21", "((1+2)*(3+4))"
    )


fn test_parens_division() raises:
    testing.assert_equal(String(evaluate("(10+2)/(3+1)")), "3", "(10+2)/(3+1)")


# ===----------------------------------------------------------------------=== #
# Tests: unary minus
# ===----------------------------------------------------------------------=== #


fn test_unary_minus_simple() raises:
    testing.assert_equal(String(evaluate("-5+3")), "-2", "-5+3")


fn test_unary_minus_in_parens() raises:
    testing.assert_equal(String(evaluate("(-5+2)*3")), "-9", "(-5+2)*3")


fn test_multiply_negative() raises:
    testing.assert_equal(String(evaluate("2*-3")), "-6", "2*-3")


fn test_double_negative() raises:
    testing.assert_equal(String(evaluate("--5")), "5", "--5")


fn test_negative_times_negative() raises:
    testing.assert_equal(String(evaluate("-2*-3")), "6", "-2*-3")


# ===----------------------------------------------------------------------=== #
# Tests: decimals
# ===----------------------------------------------------------------------=== #


fn test_decimal_addition() raises:
    testing.assert_equal(String(evaluate("1.5+2.5")), "4.0", "1.5+2.5")


fn test_decimal_multiplication() raises:
    testing.assert_equal(String(evaluate("0.1*0.2")), "0.02", "0.1*0.2")


fn test_large_integer() raises:
    """Test with numbers exceeding 64-bit integer range."""
    var result = String(evaluate("999999999999999999999999999999 + 1"))
    testing.assert_equal(
        result,
        "1000000000000000000000000000000",
        "large integer add",
    )


# ===----------------------------------------------------------------------=== #
# Tests: precision
# ===----------------------------------------------------------------------=== #


fn test_precision_20() raises:
    var result = String(evaluate("1/7", precision=20))
    testing.assert_equal(
        result,
        "0.14285714285714285714",
        "1/7 p=20",
    )


fn test_precision_5() raises:
    var result = String(evaluate("1/3", precision=5))
    testing.assert_equal(result, "0.33333", "1/3 p=5")


# ===----------------------------------------------------------------------=== #
# Tests: the showcase expression from the plan
# ===----------------------------------------------------------------------=== #


fn test_showcase_expression() raises:
    """100 * 12 - 23/17 at default precision (50)."""
    var result = String(evaluate("100*12-23/17"))
    testing.assert_equal(
        result,
        "1198.6470588235294117647058823529411764705882352941176",
        "100*12-23/17",
    )


# ===----------------------------------------------------------------------=== #
# Main
# ===----------------------------------------------------------------------=== #


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
