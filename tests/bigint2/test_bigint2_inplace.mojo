"""
Test BigInt2 true in-place arithmetic operations: +=, -=, *=.

These tests verify that the in-place operators produce correct results
identical to the non-in-place operators, but mutate self.words directly
instead of creating a new BigInt2.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2


# ===----------------------------------------------------------------------=== #
# Test: __iadd__ (+=) with BigInt2
# ===----------------------------------------------------------------------=== #


fn test_iadd_basic() raises:
    """Basic iadd: positive + positive."""
    var x = BigInt2(100)
    x += BigInt2(23)
    testing.assert_equal(String(x), "123")


fn test_iadd_zero_lhs() raises:
    """Iadd: 0 += other."""
    var x = BigInt2(0)
    x += BigInt2(42)
    testing.assert_equal(String(x), "42")


fn test_iadd_zero_rhs() raises:
    """Iadd: x += 0 is no-op."""
    var x = BigInt2(42)
    x += BigInt2(0)
    testing.assert_equal(String(x), "42")


fn test_iadd_both_zero() raises:
    """Iadd: 0 += 0 = 0."""
    var x = BigInt2(0)
    x += BigInt2(0)
    testing.assert_equal(String(x), "0")


fn test_iadd_negative_result() raises:
    """Iadd with negative result: positive + negative where |neg| > |pos|."""
    var x = BigInt2(10)
    x += BigInt2(-30)
    testing.assert_equal(String(x), "-20")


fn test_iadd_cancel_to_zero() raises:
    """Iadd: x + (-x) = 0."""
    var x = BigInt2(42)
    x += BigInt2(-42)
    testing.assert_equal(String(x), "0")


fn test_iadd_both_negative() raises:
    """Iadd: negative + negative."""
    var x = BigInt2(-10)
    x += BigInt2(-20)
    testing.assert_equal(String(x), "-30")


fn test_iadd_neg_plus_pos() raises:
    """Iadd: negative + positive where |pos| > |neg|."""
    var x = BigInt2(-10)
    x += BigInt2(30)
    testing.assert_equal(String(x), "20")


fn test_iadd_carry_propagation() raises:
    """Iadd with carry: (2^32 - 1) + 1 = 2^32."""
    var x = BigInt2("4294967295")
    x += BigInt2(1)
    testing.assert_equal(String(x), "4294967296")


fn test_iadd_large_values() raises:
    """Iadd with large multi-word values."""
    var x = BigInt2("999999999999999999999999999999")
    x += BigInt2(1)
    testing.assert_equal(String(x), "1000000000000000000000000000000")

    var y = BigInt2("123456789012345678901234567890")
    y += BigInt2("876543210987654321098765432110")
    testing.assert_equal(String(y), "1000000000000000000000000000000")


fn test_iadd_matches_add() raises:
    """Iadd produces same result as add for various values."""

    fn _check(a: String, b: String) raises:
        var expected = String(BigInt2(a) + BigInt2(b))
        var x = BigInt2(a)
        x += BigInt2(b)
        testing.assert_equal(String(x), expected)

    _check("0", "0")
    _check("1", "0")
    _check("0", "-1")
    _check("123", "456")
    _check("-123", "456")
    _check("123", "-456")
    _check("-123", "-456")
    _check("999999999999999999", "1")
    _check("-1000000000000000000", "999999999999999999")


# ===----------------------------------------------------------------------=== #
# Test: __iadd__ (+=) with Int
# ===----------------------------------------------------------------------=== #


fn test_iadd_int_basic() raises:
    """Iadd with Int: positive + positive."""
    var x = BigInt2(100)
    x += 23
    testing.assert_equal(String(x), "123")


fn test_iadd_int_zero() raises:
    """Iadd with Int: x += 0 is no-op."""
    var x = BigInt2(42)
    x += 0
    testing.assert_equal(String(x), "42")

    var y = BigInt2(0)
    y += 42
    testing.assert_equal(String(y), "42")


fn test_iadd_int_negative() raises:
    """Iadd with Int: adding negative Int."""
    var x = BigInt2(10)
    x += -30
    testing.assert_equal(String(x), "-20")

    var y = BigInt2(-10)
    y += 5
    testing.assert_equal(String(y), "-5")


fn test_iadd_int_cancel() raises:
    """Iadd with Int: cancellation to zero."""
    var x = BigInt2(42)
    x += -42
    testing.assert_equal(String(x), "0")

    var y = BigInt2(-42)
    y += 42
    testing.assert_equal(String(y), "0")


fn test_iadd_int_large_base() raises:
    """Iadd with Int: large BigInt2 + small Int."""
    var x = BigInt2("999999999999999999999999999999")
    x += 1
    testing.assert_equal(String(x), "1000000000000000000000000000000")


fn test_iadd_int_accumulator_loop() raises:
    """Iadd Int in a loop: simulate accumulator pattern."""
    var sum = BigInt2(0)
    for i in range(1, 101):
        sum += i
    # Sum of 1..100 = 5050
    testing.assert_equal(String(sum), "5050")


# ===----------------------------------------------------------------------=== #
# Test: __isub__ (-=) with BigInt2
# ===----------------------------------------------------------------------=== #


fn test_isub_basic() raises:
    """Basic isub: positive - positive."""
    var x = BigInt2(100)
    x -= BigInt2(23)
    testing.assert_equal(String(x), "77")


fn test_isub_zero_rhs() raises:
    """Isub: x -= 0 is no-op."""
    var x = BigInt2(42)
    x -= BigInt2(0)
    testing.assert_equal(String(x), "42")


fn test_isub_zero_lhs() raises:
    """Isub: 0 -= other = -other."""
    var x = BigInt2(0)
    x -= BigInt2(42)
    testing.assert_equal(String(x), "-42")

    var y = BigInt2(0)
    y -= BigInt2(-42)
    testing.assert_equal(String(y), "42")


fn test_isub_cancel_to_zero() raises:
    """Isub: x - x = 0."""
    var x = BigInt2(42)
    x -= BigInt2(42)
    testing.assert_equal(String(x), "0")


fn test_isub_negative_result() raises:
    """Isub: positive - larger positive = negative."""
    var x = BigInt2(10)
    x -= BigInt2(30)
    testing.assert_equal(String(x), "-20")


fn test_isub_both_negative() raises:
    """Isub: negative - negative."""
    # -10 - (-30) = -10 + 30 = 20
    var x = BigInt2(-10)
    x -= BigInt2(-30)
    testing.assert_equal(String(x), "20")

    # -30 - (-10) = -30 + 10 = -20
    var y = BigInt2(-30)
    y -= BigInt2(-10)
    testing.assert_equal(String(y), "-20")


fn test_isub_borrow_propagation() raises:
    """Isub with borrow: 2^32 - 1 = 2^32 - 1."""
    var x = BigInt2("4294967296")
    x -= BigInt2(1)
    testing.assert_equal(String(x), "4294967295")


fn test_isub_large_values() raises:
    """Isub with large multi-word values."""
    var x = BigInt2("1000000000000000000000000000000")
    x -= BigInt2(1)
    testing.assert_equal(String(x), "999999999999999999999999999999")


fn test_isub_matches_sub() raises:
    """Isub produces same result as subtract for various values."""

    fn _check(a: String, b: String) raises:
        var expected = String(BigInt2(a) - BigInt2(b))
        var x = BigInt2(a)
        x -= BigInt2(b)
        testing.assert_equal(String(x), expected)

    _check("0", "0")
    _check("1", "0")
    _check("0", "-1")
    _check("123", "456")
    _check("-123", "456")
    _check("123", "-456")
    _check("-123", "-456")
    _check("1000000000000000000", "1")
    _check("-1000000000000000000", "999999999999999999")


# ===----------------------------------------------------------------------=== #
# Test: __imul__ (*=) with BigInt2
# ===----------------------------------------------------------------------=== #


fn test_imul_basic() raises:
    """Basic imul: positive * positive."""
    var x = BigInt2(12)
    x *= BigInt2(10)
    testing.assert_equal(String(x), "120")


fn test_imul_zero_lhs() raises:
    """Imul: 0 *= other = 0."""
    var x = BigInt2(0)
    x *= BigInt2(42)
    testing.assert_equal(String(x), "0")


fn test_imul_zero_rhs() raises:
    """Imul: x *= 0 = 0."""
    var x = BigInt2(42)
    x *= BigInt2(0)
    testing.assert_equal(String(x), "0")


fn test_imul_one() raises:
    """Imul: x *= 1 is no-op."""
    var x = BigInt2(42)
    x *= BigInt2(1)
    testing.assert_equal(String(x), "42")


fn test_imul_minus_one() raises:
    """Imul: x *= -1 negates."""
    var x = BigInt2(42)
    x *= BigInt2(-1)
    testing.assert_equal(String(x), "-42")

    var y = BigInt2(-42)
    y *= BigInt2(-1)
    testing.assert_equal(String(y), "42")


fn test_imul_sign_combinations() raises:
    """Imul: all sign combinations."""
    # pos * pos = pos
    var a = BigInt2(7)
    a *= BigInt2(6)
    testing.assert_equal(String(a), "42")

    # pos * neg = neg
    var b = BigInt2(7)
    b *= BigInt2(-6)
    testing.assert_equal(String(b), "-42")

    # neg * pos = neg
    var c = BigInt2(-7)
    c *= BigInt2(6)
    testing.assert_equal(String(c), "-42")

    # neg * neg = pos
    var d = BigInt2(-7)
    d *= BigInt2(-6)
    testing.assert_equal(String(d), "42")


fn test_imul_carry_propagation() raises:
    """Imul with carry: (2^32 - 1) * (2^32 - 1)."""
    var x = BigInt2("4294967295")
    x *= BigInt2("4294967295")
    testing.assert_equal(String(x), "18446744065119617025")


fn test_imul_large_values() raises:
    """Imul with large multi-word values."""
    var x = BigInt2("123456789012345678901234567890")
    x *= BigInt2("2")
    testing.assert_equal(String(x), "246913578024691357802469135780")


fn test_imul_matches_mul() raises:
    """Imul produces same result as multiply for various values."""

    fn _check(a: String, b: String) raises:
        var expected = String(BigInt2(a) * BigInt2(b))
        var x = BigInt2(a)
        x *= BigInt2(b)
        testing.assert_equal(String(x), expected)

    _check("0", "0")
    _check("1", "0")
    _check("0", "-1")
    _check("123", "456")
    _check("-123", "456")
    _check("123", "-456")
    _check("-123", "-456")
    _check("999999999", "999999999")
    _check("123456789012345678901234567890", "987654321098765432109876543210")


# ===----------------------------------------------------------------------=== #
# Test: chained in-place operations
# ===----------------------------------------------------------------------=== #


fn test_chained_iadd() raises:
    """Multiple iadd operations in sequence."""
    var x = BigInt2(0)
    x += BigInt2(10)
    x += BigInt2(20)
    x += BigInt2(30)
    testing.assert_equal(String(x), "60")


fn test_chained_isub() raises:
    """Multiple isub operations in sequence."""
    var x = BigInt2(100)
    x -= BigInt2(10)
    x -= BigInt2(20)
    x -= BigInt2(30)
    testing.assert_equal(String(x), "40")


fn test_chained_imul() raises:
    """Multiple imul operations: factorial-like."""
    var x = BigInt2(1)
    x *= BigInt2(2)
    x *= BigInt2(3)
    x *= BigInt2(4)
    x *= BigInt2(5)
    testing.assert_equal(String(x), "120")


fn test_mixed_inplace() raises:
    """Mixed in-place operations."""
    var x = BigInt2(10)
    x += BigInt2(5)  # 15
    x *= BigInt2(4)  # 60
    x -= BigInt2(10)  # 50
    x += BigInt2(-50)  # 0
    testing.assert_equal(String(x), "0")


fn test_iadd_int_accumulator_vs_direct() raises:
    """Int iadd accumulator gives same result as direct computation."""
    # Compute 1 + 2 + ... + 1000 via iadd
    var sum_iadd = BigInt2(0)
    for i in range(1, 1001):
        sum_iadd += i
    # n*(n+1)/2 = 500500
    testing.assert_equal(String(sum_iadd), "500500")


fn test_imul_factorial_20() raises:
    """Compute 20! via repeated imul."""
    var factorial = BigInt2(1)
    for i in range(2, 21):
        factorial *= BigInt2(i)
    # 20! = 2432902008176640000
    testing.assert_equal(String(factorial), "2432902008176640000")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
