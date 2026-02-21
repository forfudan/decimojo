"""
Test BigInt2 bitwise operations: __and__, __or__, __xor__, __invert__,
and augmented assignment (&=, |=, ^=). All tests compare against Python's
arbitrary-precision integer bitwise semantics.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2


# ===----------------------------------------------------------------------=== #
# Test: __invert__ (bitwise NOT)
# ===----------------------------------------------------------------------=== #


fn test_invert_zero() raises:
    """~0 = -1."""
    testing.assert_equal(String(~BigInt2(0)), "-1")


fn test_invert_positive() raises:
    """~x = -(x+1) for positive x."""
    testing.assert_equal(String(~BigInt2(1)), "-2")
    testing.assert_equal(String(~BigInt2(2)), "-3")
    testing.assert_equal(String(~BigInt2(42)), "-43")
    testing.assert_equal(String(~BigInt2(255)), "-256")
    testing.assert_equal(String(~BigInt2(1000000)), "-1000001")


fn test_invert_negative() raises:
    """~(-x) = x - 1 for negative x."""
    testing.assert_equal(String(~BigInt2(-1)), "0")
    testing.assert_equal(String(~BigInt2(-2)), "1")
    testing.assert_equal(String(~BigInt2(-3)), "2")
    testing.assert_equal(String(~BigInt2(-42)), "41")
    testing.assert_equal(String(~BigInt2(-256)), "255")
    testing.assert_equal(String(~BigInt2(-1000001)), "1000000")


fn test_invert_double() raises:
    """~~x = x (involution)."""
    testing.assert_equal(String(~(~BigInt2(0))), "0")
    testing.assert_equal(String(~(~BigInt2(42))), "42")
    testing.assert_equal(String(~(~BigInt2(-42))), "-42")
    testing.assert_equal(
        String(~(~BigInt2("123456789012345678901234567890"))),
        "123456789012345678901234567890",
    )


fn test_invert_large() raises:
    """~x for large multi-word values."""
    # ~(2^32) = -(2^32 + 1)
    testing.assert_equal(String(~BigInt2("4294967296")), "-4294967297")
    # ~(2^64) = -(2^64 + 1)
    testing.assert_equal(
        String(~BigInt2("18446744073709551616")), "-18446744073709551617"
    )
    # ~(-(2^64)) = 2^64 - 1
    testing.assert_equal(
        String(~BigInt2("-18446744073709551616")), "18446744073709551615"
    )


# ===----------------------------------------------------------------------=== #
# Test: __and__ (bitwise AND)
# ===----------------------------------------------------------------------=== #


fn test_and_both_positive() raises:
    """Positive & Positive → Positive."""
    # 0xFF & 0x0F = 0x0F = 15
    testing.assert_equal(String(BigInt2(255) & BigInt2(15)), "15")
    # 0b1010 & 0b1100 = 0b1000 = 8
    testing.assert_equal(String(BigInt2(10) & BigInt2(12)), "8")
    # x & 0 = 0
    testing.assert_equal(String(BigInt2(12345) & BigInt2(0)), "0")
    # x & x = x
    testing.assert_equal(String(BigInt2(42) & BigInt2(42)), "42")


fn test_and_positive_negative() raises:
    """Positive & Negative → Positive (Python semantics).
    In Python: 5 & -3 = 5.
    5    = ...00000101
    -3   = ...11111101  (two's complement)
    AND  = ...00000101  = 5
    """
    testing.assert_equal(String(BigInt2(5) & BigInt2(-3)), "5")

    # 255 & -1 = 255 (since -1 = all bits set)
    testing.assert_equal(String(BigInt2(255) & BigInt2(-1)), "255")

    # 12 & -8 = 8
    # 12   = ...00001100
    # -8   = ...11111000
    # AND  = ...00001000 = 8
    testing.assert_equal(String(BigInt2(12) & BigInt2(-8)), "8")


fn test_and_both_negative() raises:
    """Negative & Negative → Negative (Python semantics).
    In Python: -5 & -3 = -7.
    -5   = ...11111011
    -3   = ...11111101
    AND  = ...11111001 = -7
    """
    testing.assert_equal(String(BigInt2(-5) & BigInt2(-3)), "-7")

    # -1 & -1 = -1
    testing.assert_equal(String(BigInt2(-1) & BigInt2(-1)), "-1")

    # -256 & -16 = -256
    # -256 = ...100000000 → TC = ...1_00000000
    # -16  = ...11110000 → TC = ...1_11110000
    # AND  = ...1_00000000 = -256
    testing.assert_equal(String(BigInt2(-256) & BigInt2(-16)), "-256")


fn test_and_large_values() raises:
    """AND with multi-word values."""
    # (2^64 - 1) & (2^32 - 1) = 2^32 - 1
    var all_64 = BigInt2("18446744073709551615")
    var all_32 = BigInt2("4294967295")
    testing.assert_equal(String(all_64 & all_32), "4294967295")

    # Large & 0 = 0
    testing.assert_equal(
        String(BigInt2("123456789012345678901234567890") & BigInt2(0)), "0"
    )


fn test_and_with_int() raises:
    """AND with Int overload."""
    testing.assert_equal(String(BigInt2(255) & 15), "15")
    testing.assert_equal(String(BigInt2(-5) & -3), "-7")


# ===----------------------------------------------------------------------=== #
# Test: __or__ (bitwise OR)
# ===----------------------------------------------------------------------=== #


fn test_or_both_positive() raises:
    """Positive | Positive → Positive."""
    # 0b1010 | 0b1100 = 0b1110 = 14
    testing.assert_equal(String(BigInt2(10) | BigInt2(12)), "14")
    # x | 0 = x
    testing.assert_equal(String(BigInt2(42) | BigInt2(0)), "42")
    # 0 | x = x
    testing.assert_equal(String(BigInt2(0) | BigInt2(42)), "42")
    # x | x = x
    testing.assert_equal(String(BigInt2(42) | BigInt2(42)), "42")


fn test_or_positive_negative() raises:
    """Positive | Negative → Negative (Python semantics).
    In Python: 5 | -3 = -3.
    5    = ...00000101
    -3   = ...11111101
    OR   = ...11111101  = -3
    """
    testing.assert_equal(String(BigInt2(5) | BigInt2(-3)), "-3")

    # x | -1 = -1 (all bits set)
    testing.assert_equal(String(BigInt2(255) | BigInt2(-1)), "-1")

    # 12 | -8 = -4
    # 12   = ...00001100
    # -8   = ...11111000
    # OR   = ...11111100 = -4
    testing.assert_equal(String(BigInt2(12) | BigInt2(-8)), "-4")


fn test_or_both_negative() raises:
    """Negative | Negative → Negative (Python semantics).
    In Python: -5 | -3 = -1.
    -5   = ...11111011
    -3   = ...11111101
    OR   = ...11111111 = -1
    """
    testing.assert_equal(String(BigInt2(-5) | BigInt2(-3)), "-1")

    # -256 | -16 = -16
    testing.assert_equal(String(BigInt2(-256) | BigInt2(-16)), "-16")


fn test_or_large_values() raises:
    """OR with multi-word values."""
    # (2^32) | 1 = 2^32 + 1
    testing.assert_equal(
        String(BigInt2("4294967296") | BigInt2(1)), "4294967297"
    )


fn test_or_with_int() raises:
    """OR with Int overload."""
    testing.assert_equal(String(BigInt2(10) | 12), "14")
    testing.assert_equal(String(BigInt2(5) | -3), "-3")


# ===----------------------------------------------------------------------=== #
# Test: __xor__ (bitwise XOR)
# ===----------------------------------------------------------------------=== #


fn test_xor_both_positive() raises:
    """Positive ^ Positive → Positive."""
    # 0b1010 ^ 0b1100 = 0b0110 = 6
    testing.assert_equal(String(BigInt2(10) ^ BigInt2(12)), "6")
    # x ^ 0 = x
    testing.assert_equal(String(BigInt2(42) ^ BigInt2(0)), "42")
    # x ^ x = 0
    testing.assert_equal(String(BigInt2(42) ^ BigInt2(42)), "0")
    # 0xFF ^ 0x0F = 0xF0 = 240
    testing.assert_equal(String(BigInt2(255) ^ BigInt2(15)), "240")


fn test_xor_positive_negative() raises:
    """Positive ^ Negative → Negative (Python semantics).
    In Python: 5 ^ -3 = -8.
    5    = ...00000101
    -3   = ...11111101
    XOR  = ...11111000 = -8
    """
    testing.assert_equal(String(BigInt2(5) ^ BigInt2(-3)), "-8")

    # x ^ -1 = ~x (XOR with all-ones inverts)
    testing.assert_equal(String(BigInt2(255) ^ BigInt2(-1)), "-256")
    testing.assert_equal(String(BigInt2(0) ^ BigInt2(-1)), "-1")

    # 12 ^ -8 = -4
    # 12   = ...00001100
    # -8   = ...11111000
    # XOR  = ...11110100 = -12
    testing.assert_equal(String(BigInt2(12) ^ BigInt2(-8)), "-12")


fn test_xor_both_negative() raises:
    """Negative ^ Negative → Positive (Python semantics).
    In Python: -5 ^ -3 = 6.
    -5   = ...11111011
    -3   = ...11111101
    XOR  = ...00000110 = 6
    """
    testing.assert_equal(String(BigInt2(-5) ^ BigInt2(-3)), "6")

    # -1 ^ -1 = 0
    testing.assert_equal(String(BigInt2(-1) ^ BigInt2(-1)), "0")

    # -256 ^ -16 = 240
    testing.assert_equal(String(BigInt2(-256) ^ BigInt2(-16)), "240")


fn test_xor_large_values() raises:
    """XOR with multi-word values."""
    # (2^32) ^ 1 = 2^32 + 1
    testing.assert_equal(
        String(BigInt2("4294967296") ^ BigInt2(1)), "4294967297"
    )

    # x ^ x = 0 for large numbers
    var big = BigInt2("123456789012345678901234567890")
    testing.assert_equal(String(big ^ big.copy()), "0")


fn test_xor_with_int() raises:
    """XOR with Int overload."""
    testing.assert_equal(String(BigInt2(10) ^ 12), "6")
    testing.assert_equal(String(BigInt2(5) ^ -3), "-8")


# ===----------------------------------------------------------------------=== #
# Test: augmented assignment operators (&=, |=, ^=)
# ===----------------------------------------------------------------------=== #


fn test_augmented_and() raises:
    """Test &= operator."""
    var x = BigInt2(255)
    x &= BigInt2(15)
    testing.assert_equal(String(x), "15")


fn test_augmented_or() raises:
    """Test |= operator."""
    var x = BigInt2(10)
    x |= BigInt2(12)
    testing.assert_equal(String(x), "14")


fn test_augmented_xor() raises:
    """Test ^= operator."""
    var x = BigInt2(10)
    x ^= BigInt2(12)
    testing.assert_equal(String(x), "6")


# ===----------------------------------------------------------------------=== #
# Test: identities and cross-checks
# ===----------------------------------------------------------------------=== #


fn test_demorgan_laws() raises:
    """De Morgan's laws: ~(a & b) = ~a | ~b, ~(a | b) = ~a & ~b."""
    var a = BigInt2(42)
    var b = BigInt2(99)

    # ~(a & b) = ~a | ~b
    testing.assert_equal(
        String(~(a & b)),
        String((~a) | (~b)),
    )

    # ~(a | b) = ~a & ~b
    testing.assert_equal(
        String(~(a | b)),
        String((~a) & (~b)),
    )

    # With negative values
    var c = BigInt2(-17)
    var d = BigInt2(53)
    testing.assert_equal(
        String(~(c & d)),
        String((~c) | (~d)),
    )
    testing.assert_equal(
        String(~(c | d)),
        String((~c) & (~d)),
    )


fn test_xor_self_cancels() raises:
    """a ^ a = 0 for various values."""
    testing.assert_equal(String(BigInt2(0) ^ BigInt2(0)), "0")
    testing.assert_equal(String(BigInt2(42) ^ BigInt2(42)), "0")
    testing.assert_equal(String(BigInt2(-42) ^ BigInt2(-42)), "0")
    var big = BigInt2("999999999999999999999999999")
    testing.assert_equal(String(big ^ big.copy()), "0")


fn test_and_with_minus_one() raises:
    """a & -1 = a (AND with all-ones is identity)."""
    testing.assert_equal(String(BigInt2(0) & BigInt2(-1)), "0")
    testing.assert_equal(String(BigInt2(42) & BigInt2(-1)), "42")
    testing.assert_equal(String(BigInt2(-42) & BigInt2(-1)), "-42")
    testing.assert_equal(
        String(BigInt2("12345678901234567890") & BigInt2(-1)),
        "12345678901234567890",
    )


fn test_or_with_zero() raises:
    """a | 0 = a (OR with zero is identity)."""
    testing.assert_equal(String(BigInt2(0) | BigInt2(0)), "0")
    testing.assert_equal(String(BigInt2(42) | BigInt2(0)), "42")
    testing.assert_equal(String(BigInt2(-42) | BigInt2(0)), "-42")


fn test_xor_with_zero() raises:
    """a ^ 0 = a (XOR with zero is identity)."""
    testing.assert_equal(String(BigInt2(42) ^ BigInt2(0)), "42")
    testing.assert_equal(String(BigInt2(-42) ^ BigInt2(0)), "-42")


fn test_commutativity() raises:
    """a op b = b op a for all binary bitwise ops."""
    var a = BigInt2(123)
    var b = BigInt2(-456)

    testing.assert_equal(String(a & b), String(b & a))
    testing.assert_equal(String(a | b), String(b | a))
    testing.assert_equal(String(a ^ b), String(b ^ a))


fn test_python_cross_check() raises:
    """Cross-check specific values against Python results.
    Computed in Python 3.13:
        123 & -456 = 56
        123 | -456 = -389
        123 ^ -456 = -445
        -100 & -200 = -232
        -100 | -200 = -68
        -100 ^ -200 = 164
    """
    testing.assert_equal(String(BigInt2(123) & BigInt2(-456)), "56")
    testing.assert_equal(String(BigInt2(123) | BigInt2(-456)), "-389")
    testing.assert_equal(String(BigInt2(123) ^ BigInt2(-456)), "-445")
    testing.assert_equal(String(BigInt2(-100) & BigInt2(-200)), "-232")
    testing.assert_equal(String(BigInt2(-100) | BigInt2(-200)), "-68")
    testing.assert_equal(String(BigInt2(-100) ^ BigInt2(-200)), "164")


fn test_word_boundary_values() raises:
    """Test values at word boundaries (32-bit, 64-bit)."""
    # 2^32 - 1 = 0xFFFFFFFF (single word, all bits set)
    var w32 = BigInt2("4294967295")
    # 2^32 = 0x1_00000000 (two words)
    var w32p1 = BigInt2("4294967296")

    # (2^32 - 1) & (2^32) = 0
    testing.assert_equal(String(w32 & w32p1), "0")

    # (2^32 - 1) | (2^32) = 2^33 - 1 = 8589934591
    testing.assert_equal(String(w32 | w32p1), "8589934591")

    # (2^32 - 1) ^ (2^32) = 2^33 - 1 = 8589934591
    testing.assert_equal(String(w32 ^ w32p1), "8589934591")

    # 2^64 - 1 (two full words)
    var w64 = BigInt2("18446744073709551615")
    # (2^64 - 1) & (2^32 - 1) = 2^32 - 1
    testing.assert_equal(String(w64 & w32), "4294967295")

    # ~(2^32 - 1) = -(2^32) = -4294967296
    testing.assert_equal(String(~w32), "-4294967296")

    # ~(2^64 - 1) = -(2^64) = -18446744073709551616
    testing.assert_equal(String(~w64), "-18446744073709551616")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
