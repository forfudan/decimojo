"""
Test BigInt2 new features: power, shifts, sqrt, divmod, to_int,
from_integral_scalar, number_of_digits, is_one_or_minus_one,
compare/compare_magnitudes instance methods, to_string_with_separators,
to_decimal_string with line_width, __iadd__(Int), and __repr__.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2


# ===----------------------------------------------------------------------=== #
# Test: to_int / __int__
# ===----------------------------------------------------------------------=== #


fn test_to_int_small_positive() raises:
    """Test to_int with small positive numbers."""
    testing.assert_equal(Int(BigInt2(0)), 0)
    testing.assert_equal(Int(BigInt2(1)), 1)
    testing.assert_equal(Int(BigInt2(42)), 42)
    testing.assert_equal(Int(BigInt2(1000000)), 1000000)


fn test_to_int_small_negative() raises:
    """Test to_int with small negative numbers."""
    testing.assert_equal(Int(BigInt2(-1)), -1)
    testing.assert_equal(Int(BigInt2(-42)), -42)
    testing.assert_equal(Int(BigInt2(-1000000)), -1000000)


fn test_to_int_large_values() raises:
    """Test to_int with values near Int.MAX and Int.MIN."""
    # Int.MAX = 9_223_372_036_854_775_807
    var max_val = BigInt2("9223372036854775807")
    testing.assert_equal(Int(max_val), 9223372036854775807)

    # Int.MIN = -9_223_372_036_854_775_808
    var min_val = BigInt2("-9223372036854775808")
    testing.assert_equal(Int(min_val), Int.MIN)


fn test_to_int_overflow() raises:
    """Test to_int raises on overflow."""
    var too_large = BigInt2("9223372036854775808")  # Int.MAX + 1
    var raised = False
    try:
        _ = Int(too_large)
    except:
        raised = True
    testing.assert_true(raised, "to_int should raise for Int.MAX + 1")

    var too_small = BigInt2("-9223372036854775809")  # Int.MIN - 1
    raised = False
    try:
        _ = Int(too_small)
    except:
        raised = True
    testing.assert_true(raised, "to_int should raise for Int.MIN - 1")

    var huge = BigInt2("99999999999999999999999999999999999")
    raised = False
    try:
        _ = Int(huge)
    except:
        raised = True
    testing.assert_true(raised, "to_int should raise for very large number")


# ===----------------------------------------------------------------------=== #
# Test: from_integral_scalar / Scalar constructor
# ===----------------------------------------------------------------------=== #


fn test_from_integral_scalar() raises:
    """Test construction from Scalar types."""
    # UInt8
    var u8 = BigInt2(UInt8(255))
    testing.assert_equal(String(u8), "255")

    # Int8
    var i8 = BigInt2(Int8(-128))
    testing.assert_equal(String(i8), "-128")

    # UInt16
    var u16 = BigInt2(UInt16(65535))
    testing.assert_equal(String(u16), "65535")

    # Int16
    var i16 = BigInt2(Int16(-32768))
    testing.assert_equal(String(i16), "-32768")

    # UInt32
    var u32 = BigInt2(UInt32(4294967295))
    testing.assert_equal(String(u32), "4294967295")

    # Int32
    var i32 = BigInt2(Int32(-2147483648))
    testing.assert_equal(String(i32), "-2147483648")

    # UInt64
    var u64 = BigInt2(UInt64(18446744073709551615))
    testing.assert_equal(String(u64), "18446744073709551615")

    # Int64
    var i64 = BigInt2(Int64(-9223372036854775808))
    testing.assert_equal(String(i64), "-9223372036854775808")


# ===----------------------------------------------------------------------=== #
# Test: __pow__ / power
# ===----------------------------------------------------------------------=== #


fn test_power_basic() raises:
    """Test basic exponentiation."""
    # 2^10 = 1024
    testing.assert_equal(String(BigInt2(2) ** 10), "1024")

    # 3^5 = 243
    testing.assert_equal(String(BigInt2(3) ** 5), "243")

    # 10^0 = 1
    testing.assert_equal(String(BigInt2(10) ** 0), "1")

    # 0^0 = 1 (convention)
    testing.assert_equal(String(BigInt2(0) ** 0), "1")

    # 7^1 = 7
    testing.assert_equal(String(BigInt2(7) ** 1), "7")

    # 1^1000 = 1
    testing.assert_equal(String(BigInt2(1) ** 1000), "1")

    # 0^5 = 0
    testing.assert_equal(String(BigInt2(0) ** 5), "0")


fn test_power_negative_base() raises:
    """Test exponentiation with negative base."""
    # (-2)^3 = -8
    testing.assert_equal(String(BigInt2(-2) ** 3), "-8")

    # (-2)^4 = 16
    testing.assert_equal(String(BigInt2(-2) ** 4), "16")

    # (-1)^0 = 1
    testing.assert_equal(String(BigInt2(-1) ** 0), "1")

    # (-1)^1 = -1
    testing.assert_equal(String(BigInt2(-1) ** 1), "-1")

    # (-1)^100 = 1
    testing.assert_equal(String(BigInt2(-1) ** 100), "1")

    # (-1)^99 = -1
    testing.assert_equal(String(BigInt2(-1) ** 99), "-1")


fn test_power_large() raises:
    """Test exponentiation with large results."""
    # 2^64 = 18446744073709551616
    testing.assert_equal(String(BigInt2(2) ** 64), "18446744073709551616")

    # 2^100 = 1267650600228229401496703205376
    testing.assert_equal(
        String(BigInt2(2) ** 100),
        "1267650600228229401496703205376",
    )

    # 10^20 = 100000000000000000000
    testing.assert_equal(String(BigInt2(10) ** 20), "100000000000000000000")


fn test_power_bigint2_exponent() raises:
    """Test exponentiation with BigInt2 exponent."""
    var base = BigInt2(2)
    var exp = BigInt2(10)
    testing.assert_equal(String(base**exp), "1024")


fn test_power_negative_exponent_raises() raises:
    """Test that negative exponent raises an error."""
    var raised = False
    try:
        _ = BigInt2(2) ** -1
    except:
        raised = True
    testing.assert_true(raised, "Negative exponent should raise")


# ===----------------------------------------------------------------------=== #
# Test: __lshift__ / __rshift__
# ===----------------------------------------------------------------------=== #


fn test_left_shift_basic() raises:
    """Test basic left shift operations."""
    # 1 << 0 == 1
    testing.assert_equal(String(BigInt2(1) << 0), "1")

    # 1 << 1 == 2
    testing.assert_equal(String(BigInt2(1) << 1), "2")

    # 1 << 32 == 4294967296 == 2^32
    testing.assert_equal(String(BigInt2(1) << 32), "4294967296")

    # 1 << 64 == 2^64
    testing.assert_equal(String(BigInt2(1) << 64), "18446744073709551616")

    # 5 << 3 == 40
    testing.assert_equal(String(BigInt2(5) << 3), "40")

    # 0 << 100 == 0
    testing.assert_equal(String(BigInt2(0) << 100), "0")


fn test_left_shift_negative() raises:
    """Test left shift with negative numbers."""
    # -1 << 1 == -2
    testing.assert_equal(String(BigInt2(-1) << 1), "-2")

    # -5 << 3 == -40
    testing.assert_equal(String(BigInt2(-5) << 3), "-40")


fn test_right_shift_basic() raises:
    """Test basic right shift operations."""
    # 1 >> 0 == 1
    testing.assert_equal(String(BigInt2(1) >> 0), "1")

    # 1 >> 1 == 0
    testing.assert_equal(String(BigInt2(1) >> 1), "0")

    # 8 >> 3 == 1
    testing.assert_equal(String(BigInt2(8) >> 3), "1")

    # 255 >> 4 == 15
    testing.assert_equal(String(BigInt2(255) >> 4), "15")

    # 0 >> 100 == 0
    testing.assert_equal(String(BigInt2(0) >> 100), "0")


fn test_right_shift_large() raises:
    """Test right shift with large values."""
    # 2^64 >> 32 = 2^32 = 4294967296
    var val = BigInt2(1) << 64
    testing.assert_equal(String(val >> 32), "4294967296")

    # 2^64 >> 64 = 1
    testing.assert_equal(String(val >> 64), "1")

    # 2^64 >> 65 = 0
    testing.assert_equal(String(val >> 65), "0")


fn test_right_shift_negative() raises:
    """Test right shift with negative numbers (Python-compatible arithmetic)."""
    # -1 >> 1 == -1 (Python behavior: floor toward -inf)
    testing.assert_equal(String(BigInt2(-1) >> 1), "-1")

    # -8 >> 3 == -1
    testing.assert_equal(String(BigInt2(-8) >> 3), "-1")

    # -7 >> 1 == -4 (Python: -7 // 2 = -4)
    testing.assert_equal(String(BigInt2(-7) >> 1), "-4")

    # -100 >> 3 == -13 (Python: -100 // 8 = -13)
    testing.assert_equal(String(BigInt2(-100) >> 3), "-13")

    # -1 >> 100 == -1 (any rshift of -1 is still -1)
    testing.assert_equal(String(BigInt2(-1) >> 100), "-1")


fn test_shift_augmented_assignment() raises:
    """Test <<= and >>= augmented assignment operators."""
    var x = BigInt2(1)
    x <<= 10
    testing.assert_equal(String(x), "1024")

    x >>= 5
    testing.assert_equal(String(x), "32")


fn test_shift_roundtrip() raises:
    """Test that left shift then right shift recovers original value."""
    var original = BigInt2("123456789012345678901234567890")
    var shifted = original << 100
    var recovered = shifted >> 100
    testing.assert_equal(String(recovered), String(original))


# ===----------------------------------------------------------------------=== #
# Test: sqrt / isqrt
# ===----------------------------------------------------------------------=== #


fn test_sqrt_perfect_squares() raises:
    """Test sqrt with perfect squares."""
    testing.assert_equal(String(BigInt2(0).sqrt()), "0")
    testing.assert_equal(String(BigInt2(1).sqrt()), "1")
    testing.assert_equal(String(BigInt2(4).sqrt()), "2")
    testing.assert_equal(String(BigInt2(9).sqrt()), "3")
    testing.assert_equal(String(BigInt2(16).sqrt()), "4")
    testing.assert_equal(String(BigInt2(25).sqrt()), "5")
    testing.assert_equal(String(BigInt2(100).sqrt()), "10")
    testing.assert_equal(String(BigInt2(10000).sqrt()), "100")
    testing.assert_equal(String(BigInt2(1000000).sqrt()), "1000")


fn test_sqrt_non_perfect() raises:
    """Test sqrt with non-perfect squares (floor)."""
    # sqrt(2) = 1
    testing.assert_equal(String(BigInt2(2).sqrt()), "1")

    # sqrt(3) = 1
    testing.assert_equal(String(BigInt2(3).sqrt()), "1")

    # sqrt(5) = 2
    testing.assert_equal(String(BigInt2(5).sqrt()), "2")

    # sqrt(8) = 2
    testing.assert_equal(String(BigInt2(8).sqrt()), "2")

    # sqrt(99) = 9
    testing.assert_equal(String(BigInt2(99).sqrt()), "9")

    # sqrt(101) = 10
    testing.assert_equal(String(BigInt2(101).sqrt()), "10")


fn test_sqrt_large() raises:
    """Test sqrt with large perfect squares."""
    # 10^20 → sqrt = 10^10 = 10000000000
    var x = BigInt2(10) ** 20
    testing.assert_equal(String(x.sqrt()), "10000000000")

    # (2^50)^2 = 2^100 → sqrt = 2^50 = 1125899906842624
    var big_sq = BigInt2(2) ** 100
    testing.assert_equal(String(big_sq.sqrt()), "1125899906842624")

    # Verify: sqrt * sqrt <= x < (sqrt+1)^2
    var n = BigInt2("99999999999999999999999999999")  # 29 digits
    var s = n.sqrt()
    var s_sq = s * s
    var s1_sq = (s + BigInt2(1)) * (s + BigInt2(1))
    testing.assert_true(s_sq <= n, "sqrt^2 <= n")
    testing.assert_true(s1_sq > n, "(sqrt+1)^2 > n")


fn test_sqrt_negative_raises() raises:
    """Test that sqrt of negative number raises."""
    var raised = False
    try:
        _ = BigInt2(-4).sqrt()
    except:
        raised = True
    testing.assert_true(raised, "sqrt(-4) should raise")


fn test_isqrt_equals_sqrt() raises:
    """Test that isqrt and sqrt produce the same result."""
    testing.assert_equal(
        String(BigInt2(49).isqrt()), String(BigInt2(49).sqrt())
    )
    testing.assert_equal(
        String(BigInt2(50).isqrt()), String(BigInt2(50).sqrt())
    )


# ===----------------------------------------------------------------------=== #
# Test: __divmod__
# ===----------------------------------------------------------------------=== #


fn test_divmod_basic() raises:
    """Test divmod with positive numbers."""
    var result = BigInt2(7).__divmod__(BigInt2(3))
    testing.assert_equal(String(result[0]), "2", "7 divmod 3: q")
    testing.assert_equal(String(result[1]), "1", "7 divmod 3: r")

    result = BigInt2(10).__divmod__(BigInt2(5))
    testing.assert_equal(String(result[0]), "2", "10 divmod 5: q")
    testing.assert_equal(String(result[1]), "0", "10 divmod 5: r")

    result = BigInt2(0).__divmod__(BigInt2(5))
    testing.assert_equal(String(result[0]), "0", "0 divmod 5: q")
    testing.assert_equal(String(result[1]), "0", "0 divmod 5: r")


fn test_divmod_mixed_sign() raises:
    """Test divmod with mixed signs (floor semantics)."""
    # Python: divmod(7, -3) = (-3, -2) since 7 = (-3)*(-3) + (-2)
    var result = BigInt2(7).__divmod__(BigInt2(-3))
    testing.assert_equal(String(result[0]), "-3", "7 divmod -3: q")
    testing.assert_equal(String(result[1]), "-2", "7 divmod -3: r")

    # Python: divmod(-7, 3) = (-3, 2) since -7 = (-3)*3 + 2
    result = BigInt2(-7).__divmod__(BigInt2(3))
    testing.assert_equal(String(result[0]), "-3", "-7 divmod 3: q")
    testing.assert_equal(String(result[1]), "2", "-7 divmod 3: r")

    # Python: divmod(-7, -3) = (2, -1) since -7 = 2*(-3) + (-1)
    result = BigInt2(-7).__divmod__(BigInt2(-3))
    testing.assert_equal(String(result[0]), "2", "-7 divmod -3: q")
    testing.assert_equal(String(result[1]), "-1", "-7 divmod -3: r")


fn test_divmod_consistency() raises:
    """Test that divmod(a, b) satisfies a = q * b + r."""

    fn _check_divmod(a_val: Int, b_val: Int) raises:
        var a = BigInt2(a_val)
        var b = BigInt2(b_val)
        var result = a.__divmod__(b)
        var q = result[0].copy()
        var r = result[1].copy()
        var reconstructed = q * b + r
        testing.assert_equal(
            String(reconstructed),
            String(a),
            "divmod consistency: " + String(a_val) + " divmod " + String(b_val),
        )

    _check_divmod(17, 5)
    _check_divmod(-17, 5)
    _check_divmod(17, -5)
    _check_divmod(-17, -5)
    _check_divmod(100, 7)
    _check_divmod(-100, 7)


fn test_divmod_by_zero_raises() raises:
    """Test divmod by zero raises."""
    var raised = False
    try:
        _ = BigInt2(42).__divmod__(BigInt2(0))
    except:
        raised = True
    testing.assert_true(raised, "divmod by zero should raise")


# ===----------------------------------------------------------------------=== #
# Test: to_string_with_separators
# ===----------------------------------------------------------------------=== #


fn test_to_string_with_separators() raises:
    """Test to_string_with_separators."""
    testing.assert_equal(BigInt2(0).to_string_with_separators(), "0")
    testing.assert_equal(BigInt2(1).to_string_with_separators(), "1")
    testing.assert_equal(BigInt2(100).to_string_with_separators(), "100")
    testing.assert_equal(BigInt2(1000).to_string_with_separators(), "1_000")
    testing.assert_equal(
        BigInt2(1000000).to_string_with_separators(), "1_000_000"
    )
    testing.assert_equal(
        BigInt2(-1234567).to_string_with_separators(), "-1_234_567"
    )

    # Custom separator
    testing.assert_equal(
        BigInt2(1234567890).to_string_with_separators(","), "1,234,567,890"
    )


# ===----------------------------------------------------------------------=== #
# Test: to_decimal_string with line_width
# ===----------------------------------------------------------------------=== #


fn test_to_decimal_string_line_width() raises:
    """Test to_decimal_string with line_width parameter."""
    # Default: no wrapping
    var val = BigInt2("12345678901234567890")
    testing.assert_equal(val.to_decimal_string(), "12345678901234567890")

    # line_width=10: "1234567890\n1234567890"
    var wrapped = val.to_decimal_string(line_width=10)
    testing.assert_equal(wrapped, "1234567890\n1234567890")

    # line_width=5: "12345\n67890\n12345\n67890"
    var wrapped5 = val.to_decimal_string(line_width=5)
    testing.assert_equal(wrapped5, "12345\n67890\n12345\n67890")

    # Short string: no wrapping needed
    testing.assert_equal(BigInt2(42).to_decimal_string(line_width=10), "42")


# ===----------------------------------------------------------------------=== #
# Test: number_of_digits
# ===----------------------------------------------------------------------=== #


fn test_number_of_digits() raises:
    """Test number_of_digits method."""
    testing.assert_equal(BigInt2(0).number_of_digits(), 1)
    testing.assert_equal(BigInt2(1).number_of_digits(), 1)
    testing.assert_equal(BigInt2(9).number_of_digits(), 1)
    testing.assert_equal(BigInt2(10).number_of_digits(), 2)
    testing.assert_equal(BigInt2(99).number_of_digits(), 2)
    testing.assert_equal(BigInt2(100).number_of_digits(), 3)
    testing.assert_equal(BigInt2(999).number_of_digits(), 3)
    testing.assert_equal(BigInt2(1000).number_of_digits(), 4)

    # Negative numbers: digits count of magnitude
    testing.assert_equal(BigInt2(-1).number_of_digits(), 1)
    testing.assert_equal(BigInt2(-999).number_of_digits(), 3)

    # Large number
    testing.assert_equal(BigInt2("12345678901234567890").number_of_digits(), 20)


# ===----------------------------------------------------------------------=== #
# Test: is_one_or_minus_one
# ===----------------------------------------------------------------------=== #


fn test_is_one_or_minus_one() raises:
    """Test is_one_or_minus_one method."""
    testing.assert_true(BigInt2(1).is_one_or_minus_one(), "1 is ±1")
    testing.assert_true(BigInt2(-1).is_one_or_minus_one(), "-1 is ±1")
    testing.assert_true(not BigInt2(0).is_one_or_minus_one(), "0 is not ±1")
    testing.assert_true(not BigInt2(2).is_one_or_minus_one(), "2 is not ±1")
    testing.assert_true(not BigInt2(-2).is_one_or_minus_one(), "-2 is not ±1")


# ===----------------------------------------------------------------------=== #
# Test: compare / compare_magnitudes instance methods
# ===----------------------------------------------------------------------=== #


fn test_compare_instance_method() raises:
    """Test compare() instance method."""
    testing.assert_equal(BigInt2(5).compare(BigInt2(3)), Int8(1))
    testing.assert_equal(BigInt2(3).compare(BigInt2(5)), Int8(-1))
    testing.assert_equal(BigInt2(5).compare(BigInt2(5)), Int8(0))
    testing.assert_equal(BigInt2(-5).compare(BigInt2(3)), Int8(-1))
    testing.assert_equal(BigInt2(3).compare(BigInt2(-5)), Int8(1))
    testing.assert_equal(BigInt2(0).compare(BigInt2(0)), Int8(0))


fn test_compare_magnitudes_instance_method() raises:
    """Test compare_magnitudes() instance method."""
    testing.assert_equal(BigInt2(5).compare_magnitudes(BigInt2(3)), Int8(1))
    testing.assert_equal(BigInt2(3).compare_magnitudes(BigInt2(5)), Int8(-1))
    testing.assert_equal(BigInt2(5).compare_magnitudes(BigInt2(5)), Int8(0))

    # Magnitude comparison ignores sign
    testing.assert_equal(BigInt2(-5).compare_magnitudes(BigInt2(3)), Int8(1))
    testing.assert_equal(BigInt2(-5).compare_magnitudes(BigInt2(-3)), Int8(1))
    testing.assert_equal(BigInt2(-5).compare_magnitudes(BigInt2(-5)), Int8(0))


# ===----------------------------------------------------------------------=== #
# Test: __iadd__(Int)
# ===----------------------------------------------------------------------=== #


fn test_iadd_int() raises:
    """Test optimized += with Int."""
    var x = BigInt2(100)
    x += 1
    testing.assert_equal(String(x), "101")

    x += -1
    testing.assert_equal(String(x), "100")

    x += 0
    testing.assert_equal(String(x), "100")

    x += 999
    testing.assert_equal(String(x), "1099")


# ===----------------------------------------------------------------------=== #
# Test: __repr__
# ===----------------------------------------------------------------------=== #


fn test_repr() raises:
    """Test __repr__ (Representable trait)."""
    testing.assert_equal(repr(BigInt2(42)), 'BigInt2("42")')
    testing.assert_equal(repr(BigInt2(-7)), 'BigInt2("-7")')
    testing.assert_equal(repr(BigInt2(0)), 'BigInt2("0")')


# ===----------------------------------------------------------------------=== #
# Test: power of 2 cross-checks with shifts
# ===----------------------------------------------------------------------=== #


fn test_power_of_2_vs_shift() raises:
    """Verify that 2**n equals 1 << n for various n."""
    testing.assert_equal(String(BigInt2(2) ** 0), String(BigInt2(1) << 0))
    testing.assert_equal(String(BigInt2(2) ** 1), String(BigInt2(1) << 1))
    testing.assert_equal(String(BigInt2(2) ** 31), String(BigInt2(1) << 31))
    testing.assert_equal(String(BigInt2(2) ** 32), String(BigInt2(1) << 32))
    testing.assert_equal(String(BigInt2(2) ** 63), String(BigInt2(1) << 63))
    testing.assert_equal(String(BigInt2(2) ** 64), String(BigInt2(1) << 64))
    testing.assert_equal(String(BigInt2(2) ** 100), String(BigInt2(1) << 100))
    testing.assert_equal(String(BigInt2(2) ** 128), String(BigInt2(1) << 128))


# ===----------------------------------------------------------------------=== #
# Test: D&C from_string for large numbers
# ===----------------------------------------------------------------------=== #


fn test_from_string_large_dc() raises:
    """Test that from_string correctly handles large numbers that trigger
    the D&C path (>256 digits). Validates by round-tripping: construct a
    BigInt2 via arithmetic, convert to string, parse back, and compare.
    """

    # Case 1: 500-digit number (above 256-digit D&C threshold)
    # Construct via arithmetic: 10^499 + 42
    var a1 = BigInt2(10).power(499) + BigInt2(42)
    var s1 = String(a1)
    var b1 = BigInt2(s1)
    testing.assert_true(
        a1 == b1,
        msg="[D&C from_string] round-trip 500-digit number",
    )

    # Case 2: 1000-digit number
    var a2 = BigInt2(7) * BigInt2(10).power(999) + BigInt2(123456789)
    var s2 = String(a2)
    var b2 = BigInt2(s2)
    testing.assert_true(
        a2 == b2,
        msg="[D&C from_string] round-trip 1000-digit number",
    )

    # Case 3: 2000-digit negative number
    var a3 = -(BigInt2(3) * BigInt2(10).power(1999) + BigInt2(987654321))
    var s3 = String(a3)
    var b3 = BigInt2(s3)
    testing.assert_true(
        a3 == b3,
        msg="[D&C from_string] round-trip 2000-digit negative number",
    )

    # Case 4: Cross-check with BigInt10 path (independent reference)
    var a4 = BigInt2(10).power(599) + BigInt2(10).power(300) + BigInt2(7)
    testing.assert_equal(
        lhs=String(a4),
        rhs=String(a4.to_bigint10()),
        msg="[D&C from_string] D&C to_string matches BigInt10 for 600-digit",
    )


# ===----------------------------------------------------------------------=== #
# Test: from_string with various string formats (via parse_numeric_string)
# ===----------------------------------------------------------------------=== #


fn test_from_string_with_commas() raises:
    """Test from_string handles commas as thousand separators."""
    testing.assert_equal(String(BigInt2("1,234,567")), "1234567")
    testing.assert_equal(String(BigInt2("-1,000,000")), "-1000000")
    testing.assert_equal(
        String(BigInt2("123,456,789,012,345")), "123456789012345"
    )


fn test_from_string_with_underscores() raises:
    """Test from_string handles underscores as digit separators."""
    testing.assert_equal(String(BigInt2("1_000_000")), "1000000")
    testing.assert_equal(String(BigInt2("-99_999")), "-99999")
    testing.assert_equal(String(BigInt2("1_2_3_4_5")), "12345")


fn test_from_string_with_spaces() raises:
    """Test from_string handles spaces in the string."""
    testing.assert_equal(String(BigInt2(" 42 ")), "42")
    testing.assert_equal(String(BigInt2("1 000 000")), "1000000")
    testing.assert_equal(String(BigInt2("- 123")), "-123")


fn test_from_string_with_scientific_notation() raises:
    """Test from_string handles scientific/exponential notation."""
    # 1.23e5 = 123000
    testing.assert_equal(String(BigInt2("1.23e5")), "123000")
    # 5e10 = 50000000000
    testing.assert_equal(String(BigInt2("5e10")), "50000000000")
    # -2.5E4 = -25000
    testing.assert_equal(String(BigInt2("-2.5E4")), "-25000")
    # 1e0 = 1
    testing.assert_equal(String(BigInt2("1e0")), "1")
    # 100e2 = 10000
    testing.assert_equal(String(BigInt2("100e2")), "10000")


fn test_from_string_with_decimal_point_integer() raises:
    """Test from_string with decimal point where fractional part is zero."""
    testing.assert_equal(String(BigInt2("123.0")), "123")
    testing.assert_equal(String(BigInt2("100.00")), "100")
    testing.assert_equal(String(BigInt2("-42.000")), "-42")


fn test_from_string_non_integer_raises() raises:
    """Test from_string raises error for non-integer values."""
    var raised = False
    try:
        _ = BigInt2("123.456")
    except:
        raised = True
    testing.assert_true(raised, msg="Should raise for non-integer '123.456'")

    raised = False
    try:
        _ = BigInt2(
            "1.5e2"
        )  # 150.0 is integer... wait, 1.5e2 = 150, scale=1-2=-1, coef=[1,5], that's actually integer
    except:
        raised = True
    # 1.5e2 = 150 which IS an integer, should NOT raise
    testing.assert_false(raised, msg="1.5e2 = 150 should not raise")

    raised = False
    try:
        _ = BigInt2("1.23e1")  # 12.3, not integer
    except:
        raised = True
    testing.assert_true(raised, msg="Should raise for non-integer '1.23e1'")


fn test_from_string_plus_sign() raises:
    """Test from_string handles explicit positive sign."""
    testing.assert_equal(String(BigInt2("+42")), "42")
    testing.assert_equal(String(BigInt2("+0")), "0")
    testing.assert_equal(String(BigInt2("+1,000")), "1000")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
