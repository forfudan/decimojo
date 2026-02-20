"""
Test BigInt2 arithmetic operations including addition, subtraction,
negation, multiplication, floor division, and truncate division.

Reuses TOML test data from the BigInt test suite, since the test cases
use decimal string representations that are valid for both BigInt and BigInt2.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path_arithmetics = "tests/bigint/test_data/bigint_arithmetics.toml"
comptime file_path_multiply = "tests/bigint/test_data/bigint_multiply.toml"
comptime file_path_floor_divide = "tests/bigint/test_data/bigint_floor_divide.toml"
comptime file_path_truncate_divide = "tests/bigint/test_data/bigint_truncate_divide.toml"

# BigUInt TOML test data (unsigned, all positive values)
comptime file_path_biguint_arithmetics = "tests/biguint/test_data/biguint_arithmetics.toml"
comptime file_path_biguint_truncate_divide = "tests/biguint/test_data/biguint_truncate_divide.toml"


fn test_bigint2_addition() raises:
    """Test BigInt2 addition using shared TOML test data."""
    var toml = parse_file(file_path_arithmetics)
    var test_cases = load_test_cases(toml, "addition_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) + BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_subtraction() raises:
    """Test BigInt2 subtraction using shared TOML test data."""
    var toml = parse_file(file_path_arithmetics)
    var test_cases = load_test_cases(toml, "subtraction_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) - BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_negation() raises:
    """Test BigInt2 negation using shared TOML test data."""
    var toml = parse_file(file_path_arithmetics)
    var test_cases = load_test_cases[unary=True](toml, "negation_tests")
    for test_case in test_cases:
        var result = -BigInt2(test_case.a)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_abs() raises:
    """Test BigInt2 absolute value using shared TOML test data."""
    var toml = parse_file(file_path_arithmetics)
    var test_cases = load_test_cases[unary=True](toml, "abs_tests")
    for test_case in test_cases:
        var result = abs(BigInt2(test_case.a))
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_multiply() raises:
    """Test BigInt2 multiplication using shared TOML test data."""
    var toml = parse_file(file_path_multiply)
    var test_cases = load_test_cases(toml, "multiplication_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) * BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_floor_divide() raises:
    """Test BigInt2 floor division using shared TOML test data."""
    var toml = parse_file(file_path_floor_divide)
    var test_cases = load_test_cases(toml, "floor_divide_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) // BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_truncate_divide() raises:
    """Test BigInt2 truncate division using shared TOML test data."""
    var toml = parse_file(file_path_truncate_divide)
    var test_cases = load_test_cases(toml, "truncate_divide_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a).truncate_divide(BigInt2(test_case.b))
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn test_bigint2_comparison() raises:
    """Test BigInt2 comparison operators."""
    # Basic comparisons
    var a = BigInt2(42)
    var b = BigInt2(100)
    var c = BigInt2(-50)
    var d = BigInt2(42)
    var zero = BigInt2(0)

    # Equality
    testing.assert_true(a == d, "42 == 42")
    testing.assert_true(not (a == b), "42 != 100")
    testing.assert_true(a != b, "42 != 100")
    testing.assert_true(zero == BigInt2(0), "0 == 0")

    # Less than
    testing.assert_true(a < b, "42 < 100")
    testing.assert_true(c < a, "-50 < 42")
    testing.assert_true(c < zero, "-50 < 0")
    testing.assert_true(not (b < a), "not (100 < 42)")

    # Greater than
    testing.assert_true(b > a, "100 > 42")
    testing.assert_true(a > c, "42 > -50")
    testing.assert_true(zero > c, "0 > -50")

    # Less than or equal
    testing.assert_true(a <= d, "42 <= 42")
    testing.assert_true(a <= b, "42 <= 100")

    # Greater than or equal
    testing.assert_true(a >= d, "42 >= 42")
    testing.assert_true(b >= a, "100 >= 42")

    # Comparisons with Int
    testing.assert_true(a == 42, "BigInt2(42) == 42")
    testing.assert_true(a != 100, "BigInt2(42) != 100")
    testing.assert_true(a < 100, "BigInt2(42) < 100")
    testing.assert_true(a > 0, "BigInt2(42) > 0")
    testing.assert_true(a <= 42, "BigInt2(42) <= 42")
    testing.assert_true(a >= 42, "BigInt2(42) >= 42")

    # Large number comparisons
    var large1 = BigInt2("999999999999999999999999999999")
    var large2 = BigInt2("1000000000000000000000000000000")
    testing.assert_true(large1 < large2, "30-digit < 31-digit")
    testing.assert_true(large2 > large1, "31-digit > 30-digit")

    # Negative number comparisons
    var neg1 = BigInt2(-100)
    var neg2 = BigInt2(-200)
    testing.assert_true(neg2 < neg1, "-200 < -100")
    testing.assert_true(neg1 > neg2, "-100 > -200")


fn test_bigint2_division_by_zero() raises:
    """Test that division by zero raises an error."""
    var a = BigInt2(42)
    var zero = BigInt2(0)
    var raised = False

    try:
        _ = a // zero
    except:
        raised = True

    testing.assert_true(raised, "Floor division by zero should raise")

    raised = False
    try:
        _ = a.truncate_divide(zero)
    except:
        raised = True

    testing.assert_true(raised, "Truncate division by zero should raise")


fn test_bigint2_zero_quotient_mixed_sign() raises:
    """Regression test: 0 // negative should be +0 with sign == False."""
    # Floor divide: 0 // -5
    var result_floor = BigInt2(0) // BigInt2(-5)
    testing.assert_equal(
        lhs=String(result_floor),
        rhs="0",
        msg="0 // -5 should produce numeric 0",
    )
    testing.assert_equal(
        lhs=result_floor.sign,
        rhs=False,
        msg="0 // -5 should have sign == False (no negative zero)",
    )

    # Truncate divide: 0 truncate_divide -5
    var result_trunc = BigInt2(0).truncate_divide(BigInt2(-5))
    testing.assert_equal(
        lhs=String(result_trunc),
        rhs="0",
        msg="0 truncate_divide -5 should produce numeric 0",
    )
    testing.assert_equal(
        lhs=result_trunc.sign,
        rhs=False,
        msg="0 truncate_divide -5 should have sign == False (no negative zero)",
    )

    # Floor divide: 0 // -1
    var result_neg1 = BigInt2(0) // BigInt2(-1)
    testing.assert_equal(
        lhs=String(result_neg1),
        rhs="0",
        msg="0 // -1 should produce numeric 0",
    )
    testing.assert_equal(
        lhs=result_neg1.sign,
        rhs=False,
        msg="0 // -1 should have sign == False (no negative zero)",
    )


fn test_bigint2_augmented_assignment() raises:
    """Test augmented assignment operators (+=, -=, *=)."""
    var a = BigInt2(100)

    a += BigInt2(50)
    testing.assert_equal(lhs=String(a), rhs="150", msg="+= test")

    a -= BigInt2(30)
    testing.assert_equal(lhs=String(a), rhs="120", msg="-= test")

    a *= BigInt2(3)
    testing.assert_equal(lhs=String(a), rhs="360", msg="*= test")


# ===----------------------------------------------------------------------=== #
# Additional tests from BigUInt TOML data (unsigned / positive only)
# ===----------------------------------------------------------------------=== #


fn test_bigint2_biguint_addition() raises:
    """Test BigInt2 addition with BigUInt TOML test data (all positive)."""
    var toml = parse_file(file_path_biguint_arithmetics)
    var test_cases = load_test_cases(toml, "addition_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) + BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg="[biguint] " + test_case.description,
        )


fn test_bigint2_biguint_subtraction() raises:
    """Test BigInt2 subtraction with BigUInt TOML test data (a >= b cases)."""
    var toml = parse_file(file_path_biguint_arithmetics)
    var test_cases = load_test_cases(toml, "subtraction_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) - BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg="[biguint] " + test_case.description,
        )

    # Also test the extreme_subtraction_tests section
    var extreme_cases = load_test_cases(toml, "extreme_subtraction_tests")
    for test_case in extreme_cases:
        var result = BigInt2(test_case.a) - BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg="[biguint extreme] " + test_case.description,
        )


fn test_bigint2_biguint_subtraction_underflow() raises:
    """Test that BigInt2 handles subtraction underflow (smaller - larger).

    Unlike BigUInt which errors, BigInt2 should return a negative result.
    """
    # 123 - 456 = -333 for signed BigInt2
    var result = BigInt2("123") - BigInt2("456")
    testing.assert_equal(
        lhs=String(result),
        rhs="-333",
        msg="[biguint underflow] BigInt2 handles smaller - larger correctly",
    )


fn test_bigint2_biguint_multiplication() raises:
    """Test BigInt2 multiplication with BigUInt TOML test data (all positive).
    """
    var toml = parse_file(file_path_biguint_arithmetics)
    var test_cases = load_test_cases(toml, "multiplication_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a) * BigInt2(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg="[biguint] " + test_case.description,
        )


fn test_bigint2_biguint_truncate_divide() raises:
    """Test BigInt2 truncate division with BigUInt TOML test data (all positive).
    """
    var toml = parse_file(file_path_biguint_truncate_divide)
    var test_cases = load_test_cases(toml, "truncate_divide_tests")
    for test_case in test_cases:
        var result = BigInt2(test_case.a).truncate_divide(BigInt2(test_case.b))
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg="[biguint] " + test_case.description,
        )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
