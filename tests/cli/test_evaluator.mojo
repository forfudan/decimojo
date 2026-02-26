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
# Tests: power operator (Phase 2)
# ===----------------------------------------------------------------------=== #


fn test_power_simple() raises:
    testing.assert_equal(String(evaluate("2^10")), "1024", "2^10")


fn test_power_double_star() raises:
    """** alias for ^."""
    testing.assert_equal(String(evaluate("2**10")), "1024", "2**10")


fn test_power_zero() raises:
    testing.assert_equal(String(evaluate("5^0")), "1", "5^0")


fn test_power_one() raises:
    testing.assert_equal(String(evaluate("7^1")), "7", "7^1")


fn test_power_large() raises:
    """2^256 should produce the correct value."""
    var result = String(evaluate("2^256"))
    # BigDecimal may render this in scientific notation
    testing.assert_true(
        result.startswith(
            "1.1579208923731619542357098500868790785326998466564"
        ),
        "2^256 starts correctly: " + result,
    )


fn test_power_right_associative() raises:
    """2^3^2 = 2^(3^2) = 2^9 = 512."""
    testing.assert_equal(String(evaluate("2^3^2")), "512", "2^3^2")


fn test_power_with_subtraction() raises:
    """10^2 - 1 = 99."""
    testing.assert_equal(String(evaluate("10^2-1")), "99", "10^2-1")


fn test_power_negative_exponent() raises:
    """2^-3 = 0.125."""
    testing.assert_equal(String(evaluate("2^-3")), "0.125", "2^-3")


# ===----------------------------------------------------------------------=== #
# Tests: built-in functions (Phase 2)
# ===----------------------------------------------------------------------=== #


fn test_sqrt_perfect() raises:
    testing.assert_equal(String(evaluate("sqrt(9)")), "3", "sqrt(9)")


fn test_sqrt_irrational() raises:
    """Irrational sqrt(2) with precision 20."""
    var result = String(evaluate("sqrt(2)", precision=20))
    testing.assert_true(
        result.startswith("1.414213562373095048"),
        "sqrt(2) p=20 starts correctly: " + result,
    )


fn test_ln_1() raises:
    testing.assert_equal(String(evaluate("ln(1)")), "0", "ln(1)")


fn test_exp_0() raises:
    testing.assert_equal(String(evaluate("exp(0)")), "1", "exp(0)")


fn test_abs_negative() raises:
    testing.assert_equal(String(evaluate("abs(-42)")), "42", "abs(-42)")


fn test_abs_positive() raises:
    testing.assert_equal(String(evaluate("abs(7)")), "7", "abs(7)")


fn test_root_cube() raises:
    """Cube root(27, 3) = 3."""
    testing.assert_equal(String(evaluate("root(27, 3)")), "3", "root(27,3)")


fn test_function_in_expression() raises:
    """1 + sqrt(4) = 3."""
    testing.assert_equal(String(evaluate("1+sqrt(4)")), "3", "1+sqrt(4)")


fn test_nested_functions() raises:
    """Nested sqrt(abs(-9)) = 3."""
    testing.assert_equal(
        String(evaluate("sqrt(abs(-9))")), "3", "sqrt(abs(-9))"
    )


fn test_function_with_power() raises:
    """Power of sqrt(2)^2 should be very close to 2."""
    var result = String(evaluate("sqrt(2)^2"))
    testing.assert_true(
        result.startswith("1.999999999999999999") or result.startswith("2"),
        "sqrt(2)^2 should be close to 2: " + result,
    )


# ===----------------------------------------------------------------------=== #
# Tests: built-in constants (Phase 2)
# ===----------------------------------------------------------------------=== #


fn test_pi_constant() raises:
    """Constant pi with precision 20."""
    var result = String(evaluate("pi", precision=20))
    testing.assert_true(
        result.startswith("3.1415926535897932"),
        "pi p=20 starts correctly: " + result,
    )


fn test_e_constant() raises:
    """Constant e with precision 20."""
    var result = String(evaluate("e", precision=20))
    testing.assert_true(
        result.startswith("2.7182818284590452"),
        "e p=20 starts correctly: " + result,
    )


fn test_pi_in_expression() raises:
    """Expression 2*pi should start with 6.2831853..."""
    var result = String(evaluate("2*pi", precision=20))
    testing.assert_true(
        result.startswith("6.283185307179586"),
        "2*pi p=20: " + result,
    )


fn test_ln_e_is_one() raises:
    """Expression ln(e) should be approximately 1."""
    var result = String(evaluate("ln(e)", precision=20))
    testing.assert_true(
        result.startswith("1.0000000000000000000"),
        "ln(e) ≈ 1",
    )


# ===----------------------------------------------------------------------=== #
# Tests: remaining functions (Phase 2 – smoke tests per function)
# ===----------------------------------------------------------------------=== #


fn test_cbrt_27() raises:
    """cbrt(27) ≈ 3."""
    var result = String(evaluate("cbrt(27)"))
    testing.assert_true(
        result == "3" or result.startswith("3."),
        "cbrt(27) should be 3, got: " + result,
    )


fn test_log10_1000() raises:
    """log10(1000) = 3."""
    testing.assert_equal(String(evaluate("log10(1000)")), "3", "log10(1000)")


fn test_log10_1() raises:
    """log10(1) = 0."""
    testing.assert_equal(String(evaluate("log10(1)")), "0", "log10(1)")


fn test_log_base_2() raises:
    """log(8, 2) ≈ 3."""
    var result = String(evaluate("log(8, 2)"))
    testing.assert_true(
        result == "3" or result.startswith("3."),
        "log(8,2) should be 3, got: " + result,
    )


fn test_log_base_100() raises:
    """log(1000000, 100) ≈ 3."""
    var result = String(evaluate("log(1000000, 100)"))
    testing.assert_true(
        result == "3" or result.startswith("3."),
        "log(1000000,100) should be 3, got: " + result,
    )


fn test_cos_0() raises:
    """cos(0) = 1."""
    testing.assert_equal(String(evaluate("cos(0)")), "1", "cos(0)")


fn test_tan_0() raises:
    """tan(0) = 0."""
    testing.assert_equal(String(evaluate("tan(0)")), "0", "tan(0)")


fn test_cot_pi_over_4() raises:
    """cot(pi/4) is very close to 1."""
    var result = String(evaluate("cot(pi/4)", precision=20))
    testing.assert_true(
        result == "1" or result.startswith("1.") or result.startswith("0.9999"),
        "cot(pi/4) ≈ 1: " + result,
    )


fn test_csc_pi_over_2() raises:
    """csc(pi/2) is very close to 1."""
    var result = String(evaluate("csc(pi/2)", precision=20))
    testing.assert_true(
        result == "1" or result.startswith("1.") or result.startswith("0.9999"),
        "csc(pi/2) ≈ 1: " + result,
    )


# ===----------------------------------------------------------------------=== #
# Main
# ===----------------------------------------------------------------------=== #


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
