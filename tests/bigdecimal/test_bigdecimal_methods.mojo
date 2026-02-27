"""
Tests for BigDecimal utility methods added in v0.8.x:
  - is_positive()
  - __rtruediv__()
  - to_scientific_string() / to_eng_string()
  - number_of_digits()
  - as_tuple()
"""

import testing
from decimo.bigdecimal.bigdecimal import BigDecimal
from decimo.biguint.biguint import BigUInt


# ===----------------------------------------------------------------------=== #
# is_positive()
# ===----------------------------------------------------------------------=== #


fn test_is_positive_positive_values() raises:
    """Positive values return True."""
    testing.assert_true(BigDecimal("1").is_positive())
    testing.assert_true(BigDecimal("0.001").is_positive())
    testing.assert_true(BigDecimal("999999999999999999").is_positive())
    testing.assert_true(BigDecimal("1E+50").is_positive())


fn test_is_positive_negative_values() raises:
    """Negative values return False."""
    testing.assert_false(BigDecimal("-1").is_positive())
    testing.assert_false(BigDecimal("-0.001").is_positive())
    testing.assert_false(BigDecimal("-1E+50").is_positive())


fn test_is_positive_zero() raises:
    """Zero is not positive."""
    testing.assert_false(BigDecimal("0").is_positive())
    testing.assert_false(BigDecimal("0.000").is_positive())


fn test_is_positive_matches_bigint_semantics() raises:
    """Strictly positive (zero excluded), matching BigInt semantics."""
    var pos = BigDecimal("1")
    var neg = BigDecimal("-1")
    var zero = BigDecimal("0")
    testing.assert_true(pos.is_positive())
    testing.assert_false(neg.is_positive())
    testing.assert_false(zero.is_positive())
    # Consistency: is_positive and is_negative are mutually exclusive, and
    # both false for zero.
    testing.assert_false(pos.is_negative())
    testing.assert_true(neg.is_negative())
    testing.assert_false(zero.is_negative())


# ===----------------------------------------------------------------------=== #
# __rtruediv__()
# ===----------------------------------------------------------------------=== #


fn test_rtruediv_basic() raises:
    """Int / BigDecimal dispatches via __rtruediv__."""
    # 1 / 2  -> 0.5
    var result = BigDecimal("1") / BigDecimal("2")
    # Now test __rtruediv__ path: BigDecimal("2").__rtruediv__(BigDecimal("1"))
    var lhs = BigDecimal("1")
    var rhs = BigDecimal("2")
    var r = rhs.__rtruediv__(lhs)
    testing.assert_equal(String(r), String(result), "1 / 2 via __rtruediv__")
    # Also test language-level dispatch: 1 / x
    var x = BigDecimal("2")
    var dispatched = BigDecimal(1) / x
    testing.assert_equal(String(dispatched), String(result), "1 / x dispatch")


fn test_rtruediv_integer_numerator() raises:
    """Verify 1 / x == x.__rtruediv__(1)."""
    var x = BigDecimal("4")
    var expected = BigDecimal("1") / x
    var got = x.__rtruediv__(BigDecimal("1"))
    testing.assert_equal(String(got), String(expected))


fn test_rtruediv_negative() raises:
    """-1 / 2 == BigDecimal('2').__rtruediv__(BigDecimal('-1'))."""
    var x = BigDecimal("2")
    var got = x.__rtruediv__(BigDecimal("-1"))
    var expected = BigDecimal("-1") / BigDecimal("2")
    testing.assert_equal(String(got), String(expected))


fn test_rtruediv_symmetry() raises:
    """Verify a / b == b.__rtruediv__(a) for various pairs."""
    var as_: List[String] = ["10", "1", "100", "-5"]
    var bs: List[String] = ["3", "7", "6", "2"]
    for i in range(len(as_)):
        var a = BigDecimal(as_[i])
        var b = BigDecimal(bs[i])
        var direct = a / b
        var reflected = b.__rtruediv__(a)
        testing.assert_equal(
            String(direct),
            String(reflected),
            "a/b == b.__rtruediv__(a) for a=" + as_[i] + ", b=" + bs[i],
        )


# ===----------------------------------------------------------------------=== #
# to_scientific_string()
# ===----------------------------------------------------------------------=== #


fn test_to_scientific_string_basic() raises:
    """Basic scientific notation examples."""
    testing.assert_equal(
        BigDecimal("123456.789").to_scientific_string(), "1.23456789E+5"
    )
    testing.assert_equal(
        BigDecimal("0.00123").to_scientific_string(), "1.23E-3"
    )
    testing.assert_equal(BigDecimal("1").to_scientific_string(), "1E0")
    testing.assert_equal(BigDecimal("10").to_scientific_string(), "1E+1")


fn test_to_scientific_string_trailing_zeros_stripped() raises:
    """Trailing zeros are stripped in scientific notation."""
    # "1.23000" stored as coefficient=123000, scale=5
    var v = BigDecimal("1.23000")
    var s = v.to_scientific_string()
    # Should not end with trailing zeros
    testing.assert_equal(s, "1.23E0")


fn test_to_scientific_string_negative() raises:
    """Negative numbers keep the minus sign."""
    testing.assert_equal(
        BigDecimal("-0.00123").to_scientific_string(), "-1.23E-3"
    )


fn test_to_scientific_string_zero() raises:
    """Zero renders correctly."""
    testing.assert_equal(BigDecimal("0").to_scientific_string(), "0E0")


# ===----------------------------------------------------------------------=== #
# to_eng_string()
# ===----------------------------------------------------------------------=== #


fn test_to_eng_string_basic() raises:
    """Engineering notation: exponent is a multiple of 3."""
    testing.assert_equal(
        BigDecimal("123456.789").to_eng_string(), "123.456789E+3"
    )
    testing.assert_equal(BigDecimal("0.00123").to_eng_string(), "1.23E-3")
    testing.assert_equal(BigDecimal("1000000").to_eng_string(), "1E+6")


fn test_to_eng_string_trailing_zeros_stripped() raises:
    """Trailing zeros are stripped in engineering notation."""
    var v = BigDecimal("1230.00")
    var s = v.to_eng_string()
    # Should not have trailing zeros in mantissa
    testing.assert_false(
        s.startswith("1230.00"), "trailing zeros should be stripped: " + s
    )


fn test_to_eng_string_negative() raises:
    """Negative numbers keep the minus sign."""
    var s = BigDecimal("-123456").to_eng_string()
    testing.assert_true(s.startswith("-"), "negative sign preserved: " + s)


fn test_to_eng_string_is_alias() raises:
    """Verify to_eng_string() returns the same as to_string(engineering=True).
    """
    var values: List[String] = ["123456.789", "0.00123", "-9.99E+10", "0"]
    for i in range(len(values)):
        var d = BigDecimal(values[i])
        testing.assert_equal(
            d.to_eng_string(),
            d.to_string(engineering=True),
            "to_eng_string() == to_string(engineering=True) for " + values[i],
        )


fn test_to_scientific_string_is_alias() raises:
    """Verify to_scientific_string() returns the same as to_string(scientific=True).
    """
    var values: List[String] = ["123456.789", "0.00123", "-9.99E+10", "0"]
    for i in range(len(values)):
        var d = BigDecimal(values[i])
        testing.assert_equal(
            d.to_scientific_string(),
            d.to_string(scientific=True),
            "to_scientific_string() == to_string(scientific=True) for "
            + values[i],
        )


# ===----------------------------------------------------------------------=== #
# number_of_digits()
# ===----------------------------------------------------------------------=== #


fn test_number_of_digits_basic() raises:
    """Counts all coefficient digits."""
    testing.assert_equal(BigDecimal("123.456").number_of_digits(), 6)
    testing.assert_equal(BigDecimal("0.00123").number_of_digits(), 3)
    # Trailing zeros in fractional part are stored in the coefficient
    testing.assert_equal(BigDecimal("100.00").number_of_digits(), 5)
    testing.assert_equal(BigDecimal("100").number_of_digits(), 3)
    testing.assert_equal(BigDecimal("1.0000").number_of_digits(), 5)


fn test_number_of_digits_zero() raises:
    """Zero has one digit."""
    testing.assert_equal(BigDecimal("0").number_of_digits(), 1)
    testing.assert_equal(BigDecimal("0.0").number_of_digits(), 1)


fn test_number_of_digits_after_normalize() raises:
    """After normalize(), trailing zeros are stripped, reducing digit count."""
    # "1.0000" normalizes to "1" (coefficient = 1, scale = 0)
    var one_with_zeros = BigDecimal("1.0000")
    testing.assert_equal(one_with_zeros.number_of_digits(), 5)
    var normalized = one_with_zeros.normalize()
    testing.assert_equal(normalized.number_of_digits(), 1)


fn test_number_of_digits_zero_normalize() raises:
    """Normalizing zero keeps 1 digit."""
    var z = BigDecimal("0")
    testing.assert_equal(z.number_of_digits(), 1)
    var zn = z.normalize()
    testing.assert_equal(zn.number_of_digits(), 1)


fn test_number_of_digits_large_integer() raises:
    """Large integers keep all digits in the coefficient."""
    var big = BigDecimal("100")
    testing.assert_equal(big.number_of_digits(), 3)
    # normalize() removes trailing zeros: coefficient becomes 1, scale=-2
    var big_norm = big.normalize()
    testing.assert_equal(big_norm.number_of_digits(), 1)


# ===----------------------------------------------------------------------=== #
# as_tuple()
# ===----------------------------------------------------------------------=== #


fn test_as_tuple_positive_decimal() raises:
    """7.25 → (False, [7,2,5], -2)."""
    var t = BigDecimal("7.25").as_tuple()
    testing.assert_false(t[0], "sign should be False for positive")
    testing.assert_equal(len(t[1]), 3, "digits length")
    testing.assert_equal(Int(t[1][0]), 7)
    testing.assert_equal(Int(t[1][1]), 2)
    testing.assert_equal(Int(t[1][2]), 5)
    testing.assert_equal(t[2], -2, "exponent")


fn test_as_tuple_negative_decimal() raises:
    """-0.001 → (True, [1], -3)."""
    var t = BigDecimal("-0.001").as_tuple()
    testing.assert_true(t[0], "sign should be True for negative")
    testing.assert_equal(len(t[1]), 1)
    testing.assert_equal(Int(t[1][0]), 1)
    testing.assert_equal(t[2], -3, "exponent")


fn test_as_tuple_integer() raises:
    """12345 → (False, [1,2,3,4,5], 0)."""
    var t = BigDecimal("12345").as_tuple()
    testing.assert_false(t[0])
    testing.assert_equal(len(t[1]), 5)
    testing.assert_equal(Int(t[1][0]), 1)
    testing.assert_equal(Int(t[1][4]), 5)
    testing.assert_equal(t[2], 0)


fn test_as_tuple_scientific_positive_exp() raises:
    """1E+5 → (False, [1], 5)."""
    var t = BigDecimal("1E+5").as_tuple()
    testing.assert_false(t[0])
    testing.assert_equal(len(t[1]), 1)
    testing.assert_equal(Int(t[1][0]), 1)
    testing.assert_equal(t[2], 5)


fn test_as_tuple_zero() raises:
    """0 → (False, [0], 0)."""
    var t = BigDecimal("0").as_tuple()
    testing.assert_false(t[0], "zero is not negative")
    testing.assert_equal(len(t[1]), 1)
    testing.assert_equal(Int(t[1][0]), 0)
    testing.assert_equal(t[2], 0)


fn test_as_tuple_reconstruct() raises:
    """Round-trip: reconstruct BigDecimal from (sign, digits, exponent)."""
    var values: List[String] = ["123.456", "-0.001", "12345", "0"]
    for vi in range(len(values)):
        var d = BigDecimal(values[vi])
        var t = d.as_tuple()
        # Rebuild coefficient string from digit list
        var coef_str = String()
        for i in range(len(t[1])):
            coef_str += String(Int(t[1][i]))
        # exponent = -scale  =>  scale = -exponent
        var reconstructed = BigDecimal(
            BigUInt(coef_str), scale=-t[2], sign=t[0]
        )
        testing.assert_equal(
            String(reconstructed),
            String(d),
            "round-trip for " + values[vi],
        )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
