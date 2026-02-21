"""
Test BigInt2 arithmetic operations including addition, subtraction,
negation, multiplication, floor division, and truncate division.

Reuses TOML test data from the BigInt10 test suite, since the test cases
use decimal string representations that are valid for both BigInt10 and BigInt2.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path_arithmetics = "tests/bigint10/test_data/bigint10_arithmetics.toml"
comptime file_path_multiply = "tests/bigint10/test_data/bigint10_multiply.toml"
comptime file_path_floor_divide = "tests/bigint10/test_data/bigint10_floor_divide.toml"
comptime file_path_truncate_divide = "tests/bigint10/test_data/bigint10_truncate_divide.toml"

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


fn test_bigint2_floor_divide_burnikel_ziegler() raises:
    """Test floor division with large operands that exercise the
    Burnikel-Ziegler dispatch path (divisor > 64 words ≈ 617 digits).

    Uses BigInt2 arithmetic to construct operands, then verifies:
      a == q * b + r, 0 <= r < |b|, and sign correctness.
    """

    # --- Case 1: 1200-digit / 700-digit ---
    # a = 10^1199 + 7, b = 10^699 + 3
    var b1 = BigInt2(10).power(699) + BigInt2(3)
    var a1 = BigInt2(10).power(1199) + BigInt2(7)
    var q1 = a1 // b1
    var r1 = a1 - q1 * b1
    # Euclidean identity (numeric, not string-based)
    testing.assert_true(
        q1 * b1 + r1 == a1,
        msg="[B-Z case 1] a == q*b + r (1200-digit / 700-digit)",
    )
    # Remainder in range [0, b)
    testing.assert_true(
        r1 >= BigInt2(0) and r1 < b1,
        msg="[B-Z case 1] 0 <= r < b",
    )
    # Cross-check D&C string conversion against BigInt10 path
    testing.assert_equal(
        lhs=String(a1),
        rhs=String(a1.to_bigint10()),
        msg="[B-Z case 1] D&C to_string matches BigInt10 path",
    )

    # --- Case 2: 2000-digit / 1000-digit ---
    # a = 2*10^1999 + 13, b = 3*10^999 + 17
    var b2 = BigInt2(3) * BigInt2(10).power(999) + BigInt2(17)
    var a2 = BigInt2(2) * BigInt2(10).power(1999) + BigInt2(13)
    var q2 = a2 // b2
    var r2 = a2 - q2 * b2
    testing.assert_true(
        q2 * b2 + r2 == a2,
        msg="[B-Z case 2] a == q*b + r (2000-digit / 1000-digit)",
    )
    testing.assert_true(
        r2 >= BigInt2(0) and r2 < b2,
        msg="[B-Z case 2] 0 <= r < b",
    )
    testing.assert_equal(
        lhs=String(a2),
        rhs=String(a2.to_bigint10()),
        msg="[B-Z case 2] D&C to_string matches BigInt10 path",
    )

    # --- Case 3: Negative / Positive (floor semantics) ---
    # a = -(10^800 + 11), b = 10^650 + 7
    # Floor division: q rounds toward -inf, r = a - q*b >= 0
    var b3 = BigInt2(10).power(650) + BigInt2(7)
    var a3 = -(BigInt2(10).power(800) + BigInt2(11))
    var q3 = a3 // b3
    var r3 = a3 - q3 * b3
    testing.assert_true(
        q3 * b3 + r3 == a3,
        msg="[B-Z case 3] a == q*b + r (negative / positive)",
    )
    testing.assert_true(
        r3 >= BigInt2(0) and r3 < b3,
        msg="[B-Z case 3] 0 <= r < b (floor semantics)",
    )
    # Quotient should be negative
    testing.assert_true(
        q3 < BigInt2(0),
        msg="[B-Z case 3] q < 0 for negative/positive",
    )

    # --- Case 4: Nearly equal sizes (700-digit / 700-digit) ---
    # a = 9*10^699 + 123456789, b = 5*10^699 + 987654321
    # Quotient should be 1
    var b4 = BigInt2(5) * BigInt2(10).power(699) + BigInt2(987654321)
    var a4 = BigInt2(9) * BigInt2(10).power(699) + BigInt2(123456789)
    var q4 = a4 // b4
    var r4 = a4 - q4 * b4
    testing.assert_true(
        q4 * b4 + r4 == a4,
        msg="[B-Z case 4] a == q*b + r (700-digit / 700-digit)",
    )
    testing.assert_equal(
        lhs=String(q4),
        rhs="1",
        msg="[B-Z case 4] quotient is 1 when a/b ≈ 1.8",
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
