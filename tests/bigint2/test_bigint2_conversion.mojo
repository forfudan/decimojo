"""
Test BigInt2 conversion: to_int, from_integral_scalar, from_string with
various formats (commas, underscores, spaces, scientific notation, decimal
point), and D&C from_string for large numbers.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2
from decimojo.bigint10.bigint10 import BigInt10


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
# Test: D&C from_string for large numbers
# ===----------------------------------------------------------------------=== #


fn test_from_string_large_dc() raises:
    """Test from_string round-trip for large numbers (500–2000 digits).
    These sizes exercise the simple O(n²) path. The D&C path is only
    entered at >10000 digits and is tested in test_from_string_dc_path.
    """

    # Case 1: 500-digit number
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
# Test: from_string D&C path (>10000 digits)
# ===----------------------------------------------------------------------=== #


fn test_from_string_dc_path() raises:
    """Test that from_string exercises the D&C conversion path by parsing
    a string with >10000 digits (_DC_FROM_STR_ENTRY_THRESHOLD).
    """

    # Build "1" followed by 10500 zeros → 10^10500 (a 10501-digit number)
    var s = String("1") + String("0") * 10500
    var a = BigInt2(s)
    # Verify via to_string round-trip
    testing.assert_equal(
        String(a), s, msg="[D&C from_string] 10501-digit round-trip"
    )

    # Cross-check with BigInt10 (independent reference implementation)
    var b = BigInt2.from_bigint10(BigInt10(s))
    testing.assert_true(
        a == b,
        msg="[D&C from_string] 10501-digit D&C matches BigInt10 path",
    )

    # Test a non-trivial large number: 7 followed by 10490 zeros then 123456789
    # Build the decimal string directly to avoid expensive power() + to_string
    var s2 = String("7") + String("0") * 10490 + String("123456789")
    var a2 = BigInt2(s2)
    # Cross-check against an independent BigInt10-based reference
    var b2 = BigInt2.from_bigint10(BigInt10(s2))
    testing.assert_true(
        a2 == b2,
        msg="[D&C from_string] 10500-digit non-trivial round-trip",
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

    # 1.5e2 = 150, which is an integer, so parsing should not raise.
    raised = False
    try:
        _ = BigInt2("1.5e2")
    except:
        raised = True
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
