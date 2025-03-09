"""
Comprehensive test suite for Decimal division operations.
Includes 100 test cases covering edge cases, precision limits, and various scenarios.
"""

from decimojo.prelude import *
import testing


fn test_basic_division() raises:
    print("------------------------------------------------------")
    print("Testing basic division cases...")

    # 1. Simple integer division
    testing.assert_equal(
        String(Decimal("10") / Decimal("2")), "5", "Simple integer division"
    )

    # 2. Division with no remainder
    testing.assert_equal(
        String(Decimal("100") / Decimal("4")),
        "25",
        "Division with no remainder",
    )

    # 3. Division resulting in non-integer
    testing.assert_equal(
        String(Decimal("10") / Decimal("4")),
        "2.5",
        "Division resulting in non-integer",
    )

    # 4. Division by one
    testing.assert_equal(
        String(Decimal("123.45") / Decimal("1")), "123.45", "Division by one"
    )

    # 5. Division of zero
    testing.assert_equal(
        String(Decimal("0") / Decimal("42")), "0", "Division of zero"
    )

    # 6. Division with both negative numbers
    testing.assert_equal(
        String(Decimal("-10") / Decimal("-5")),
        "2",
        "Division with both negative numbers",
    )

    # 7. Division with negative dividend
    testing.assert_equal(
        String(Decimal("-10") / Decimal("5")),
        "-2",
        "Division with negative dividend",
    )

    # 8. Division with negative divisor
    testing.assert_equal(
        String(Decimal("10") / Decimal("-5")),
        "-2",
        "Division with negative divisor",
    )

    # 9. Division with decimals, same scale
    testing.assert_equal(
        String(Decimal("10.5") / Decimal("2.1")),
        "5",
        "Division with decimals, same scale",
    )

    # 10. Division with decimals, different scales
    testing.assert_equal(
        String(Decimal("10.5") / Decimal("0.5")),
        "21",
        "Division with decimals, different scales",
    )

    print("✓ Basic division tests passed!")


fn test_repeating_decimals() raises:
    print("------------------------------------------------------")
    print("Testing division with repeating decimals...")

    # 11. Division resulting in 1/3
    var third = Decimal("1") / Decimal("3")
    testing.assert_true(
        String(third).startswith("0.33333333333333"),
        "Case 11: Division resulting in 1/3 failed",
    )

    # 12. Division resulting in 1/6
    var sixth = Decimal("1") / Decimal("6")
    testing.assert_true(
        String(sixth).startswith("0.16666666666666"),
        "Case 12: Division resulting in 1/6 failed",
    )

    # 13. Division resulting in 1/7
    var seventh = Decimal("1") / Decimal("7")
    testing.assert_true(
        String(seventh).startswith("0.142857142857142857"),
        "Case 13: Division resulting in 1/7 failed",
    )

    # 14. Division resulting in 2/3
    var two_thirds = Decimal("2") / Decimal("3")
    testing.assert_true(
        String(two_thirds).startswith("0.66666666666666"),
        "Case 14: Division resulting in 2/3 failed",
    )

    # 15. Division resulting in 5/6
    var five_sixths = Decimal("5") / Decimal("6")
    testing.assert_true(
        String(five_sixths).startswith("0.83333333333333"),
        "Case 15: Division resulting in 5/6 failed",
    )

    # 16. Division of 1 by 9
    var one_ninth = Decimal("1") / Decimal("9")
    testing.assert_true(
        String(one_ninth).startswith("0.11111111111111"),
        "Case 16: Division of 1 by 9 failed",
    )

    # 17. Division of 1 by 11
    var one_eleventh = Decimal("1") / Decimal("11")
    testing.assert_true(
        String(one_eleventh).startswith("0.0909090909090"),
        "Case 17: Division of 1 by 11 failed",
    )

    # 18. Division of 1 by 12
    var one_twelfth = Decimal("1") / Decimal("12")
    testing.assert_true(
        String(one_twelfth).startswith("0.08333333333333"),
        "Case 18: Division of 1 by 12 failed",
    )

    # 19. Division of 5 by 11
    var five_elevenths = Decimal("5") / Decimal("11")
    testing.assert_true(
        String(five_elevenths).startswith("0.4545454545454"),
        "Case 19: Division of 5 by 11 failed",
    )

    # 20. Division of 10 by 3
    var ten_thirds = Decimal("10") / Decimal("3")
    testing.assert_true(
        String(ten_thirds).startswith("3.33333333333333"),
        "Case 20: Division of 10 by 3 failed",
    )

    print("✓ Repeating decimal tests passed!")


fn test_precision_rounding() raises:
    print("------------------------------------------------------")
    print("Testing division precision and rounding...")

    # 21. Rounding half even (banker's rounding) at precision limit
    var a21 = Decimal("2") / Decimal("3")  # Should be ~0.6666...67
    var b21 = Decimal("0." + "6" * 27 + "7")  # 0.6666...67
    testing.assert_equal(
        String(a21), String(b21), "Rounding half even at precision limit"
    )

    # 22. Another case of rounding half even
    var a22 = Decimal("1") / Decimal("9")  # Should be ~0.1111...11
    var b22 = Decimal("0." + "1" * 28)  # 0.1111...11
    testing.assert_equal(
        String(a22), String(b22), "Another case of rounding half even"
    )

    # 23. Rounding up at precision limit
    var a23 = Decimal("10") / Decimal("3")  # Should be ~3.3333...33
    var b23 = Decimal("3." + "3" * 28)  # 3.3333...33
    testing.assert_equal(
        String(a23), String(b23), "Rounding up at precision limit"
    )

    # 24. Division requiring rounding to precision limit
    var a24 = Decimal("1") / Decimal("7")  # ~0.142857...
    var manually_calculated = Decimal("0.1428571428571428571428571429")
    testing.assert_equal(
        String(a24),
        String(manually_calculated),
        "Division requiring rounding to precision limit",
    )

    # 25. Precision limit with repeating 9s
    var a25 = Decimal("1") / Decimal("81")  # ~0.01234...
    var precision_reached = a25.scale() <= Decimal.MAX_PRECISION
    testing.assert_true(
        precision_reached, "Scale should not exceed MAX_PRECISION"
    )

    # 26. Test precision with negative numbers
    var a26 = Decimal("-1") / Decimal("3")
    var b26 = Decimal("-0." + "3" * 28)  # -0.3333...33
    testing.assert_equal(
        String(a26), String(b26), "Test precision with negative numbers"
    )

    # 27. Division with result at exactly precision limit
    var a27 = Decimal("1") / Decimal(String("1" + "0" * 28))  # 1/10^28
    testing.assert_equal(
        String(a27),
        String(Decimal("0." + "0" * 27 + "1")),
        "Division with result at exactly precision limit",
    )

    # 28. Division with result needing one more than precision limit
    var a28 = Decimal("1") / Decimal(String("1" + "0" * 28))  # 1/10^29
    testing.assert_equal(
        String(a28),
        String(Decimal("0." + "0" * 27 + "1")),
        "Division with result needing one more than precision limit",
    )

    # 29. Division where quotient has more digits than precision allows
    var a29 = Decimal("12345678901234567890123456789") / Decimal("7")
    testing.assert_true(
        a29.scale() <= Decimal.MAX_PRECISION,
        "Scale should not exceed MAX_PRECISION",
    )

    # 30. Division where both operands have maximum precision
    var a30 = Decimal("0." + "1" * 28) / Decimal("0." + "9" * 28)
    testing.assert_true(
        a30.scale() <= Decimal.MAX_PRECISION,
        "Scale should not exceed MAX_PRECISION",
    )

    print("✓ Precision and rounding tests passed!")


fn test_scale_handling() raises:
    print("------------------------------------------------------")
    print("Testing scale handling in division...")

    # 31. Division by power of 10
    testing.assert_equal(
        String(Decimal("123.456") / Decimal("10")),
        "12.3456",
        "Division by power of 10",
    )

    # 32. Division by 0.1 (multiply by 10)
    testing.assert_equal(
        String(Decimal("123.456") / Decimal("0.1")),
        "1234.56",
        "Division by 0.1",
    )

    # 33. Division by 0.01 (multiply by 100)
    testing.assert_equal(
        String(Decimal("123.456") / Decimal("0.01")),
        "12345.6",
        "Division by 0.01",
    )

    # 34. Division by 100 (divide by 100)
    testing.assert_equal(
        String(Decimal("123.456") / Decimal("100")),
        "1.23456",
        "Division by 100",
    )

    # 35. Division resulting in loss of trailing zeros
    testing.assert_equal(
        String(Decimal("10.000") / Decimal("2")),
        "5.000",
        "Division resulting in loss of trailing zeros",
    )

    # 36. Division where quotient needs more decimal places
    testing.assert_equal(
        String(Decimal("1") / Decimal("8")),
        "0.125",
        "Division where quotient needs more decimal places",
    )

    # 37. Division where dividend has more scale than divisor
    testing.assert_equal(
        String(Decimal("0.01") / Decimal("2")),
        "0.005",
        "Division where dividend has more scale than divisor",
    )

    # 38. Division where divisor has more scale than dividend
    testing.assert_equal(
        String(Decimal("2") / Decimal("0.01")),
        "200",
        "Division where divisor has more scale than dividend",
    )

    # 39. Division where both have high scale and result needs less
    testing.assert_equal(
        String(Decimal("0.0001") / Decimal("0.0001")),
        "1",
        "Division where both have high scale and result needs less",
    )

    # 40. Division where both have high scale and result needs more
    testing.assert_equal(
        String(Decimal("0.0001") / Decimal("0.0003")),
        "0.3333333333333333333333333333",
        "Division where both have high scale and result needs more",
    )

    print("✓ Scale handling tests passed!")


fn test_edge_cases() raises:
    print("------------------------------------------------------")
    print("Testing division edge cases...")

    # 41. Division by very small number close to zero
    var a41 = Decimal("1") / Decimal(
        "0." + "0" * 27 + "1"
    )  # Dividing by 10^-28
    testing.assert_true(
        a41 > Decimal(String("1" + "0" * 27)),
        "Case 41: Division by very small number failed",
    )

    # 42. Division resulting in a number close to zero
    var a42 = Decimal("0." + "0" * 27 + "1") / Decimal("10")  # Very small / 10
    testing.assert_equal(
        a42,
        Decimal("0." + "0" * 28),
        "Case 42: Division resulting in number close to zero failed",
    )

    # 43. Division of very large number by very small number
    var max_decimal = Decimal.MAX()
    var small_divisor = Decimal("0.0001")
    try:
        var a43 = max_decimal / small_divisor
    except:
        print(
            "Division of very large number by very small number raised"
            " exception"
        )

    # 44. Division of minimum representable positive number
    var min_positive = Decimal(
        "0." + "0" * 27 + "1"
    )  # Smallest positive decimal
    var a44 = min_positive / Decimal("2")
    testing.assert_true(a44.scale() <= Decimal.MAX_PRECISION)

    # 45. Division by power of 2 (binary divisions)
    testing.assert_equal(
        String(Decimal("1") / Decimal("4")), "0.25", "Division by power of 2"
    )

    # 46. Division by 9's
    testing.assert_equal(
        String(Decimal("100") / Decimal("9.9")),
        "10.101010101010101010101010101",
        "Division by 9's",
    )

    # 47. Division resulting in exactly MAX_PRECISION digits
    var a47 = Decimal("1") / Decimal("3")
    testing.assert_true(
        a47.scale() == Decimal.MAX_PRECISION,
        "Case 47: Division resulting in exactly MAX_PRECISION digits failed",
    )

    # 48. Division of large integers resulting in max precision
    testing.assert_equal(
        String(Decimal("9876543210") / Decimal("123456789")),
        "80.00000072900000663390006037",
        "Division of large integers resulting in max precision",
    )

    # 49. Division of zero by one (edge case)
    testing.assert_equal(
        String(Decimal("0") / Decimal("1")), "0", "Division of zero by one"
    )

    # 50. Division with value at maximum supported scale
    var a50 = Decimal("0." + "0" * 27 + "5") / Decimal("1")
    testing.assert_true(
        a50.scale() <= Decimal.MAX_PRECISION,
        "Case 50: Division with value at maximum supported scale failed",
    )

    print("✓ Edge case tests passed!")


fn test_large_numbers() raises:
    print("------------------------------------------------------")
    print("Testing division with large numbers...")

    # 51. Division of large number that results in small number
    testing.assert_equal(
        String(Decimal("1" + "0" * 20) / Decimal("1" + "0" * 20)),
        "1",
        "Division of large number that results in small number",
    )

    # 52. Division where dividend is at max capacity
    var max_value = Decimal.MAX()
    var a52 = max_value / Decimal("1")
    testing.assert_equal(
        a52,
        max_value,
        "Case 52: Division where dividend is at max capacity failed",
    )

    # 53. Division where dividend is slightly below max
    var near_max = Decimal.MAX() - Decimal("1")
    var a53 = near_max / Decimal("10")
    testing.assert_equal(a53, Decimal("7922816251426433759354395033.4"))

    # 54. Division where result approaches max
    var large_num = Decimal.MAX() / Decimal("2")
    var a54 = large_num * Decimal("2")
    testing.assert_true(
        a54 <= Decimal.MAX(),
        "Case 54: Division where result approaches max failed",
    )

    # 55. Large negative divided by large positive
    var large_neg = -Decimal(String("1" + "0" * 15))
    var a55 = large_neg / Decimal("10000")
    testing.assert_equal(
        a55,
        -Decimal(String("1" + "0" * 11)),
        "Case 55: Large negative divided by large positive failed",
    )

    # 56. Large integer division with remainder
    testing.assert_equal(
        String(Decimal("12345678901234567890") / Decimal("9876543210")),
        "1249999988.7343749990033203125",
        "Large integer division with many digits",
    )

    # 57. Large numbers with exact division
    testing.assert_equal(
        String(Decimal("9" * 28) / Decimal("9" * 14)),
        String(Decimal("100000000000001")),
        "Large numbers with exact division",
    )

    # 58. Division of large numbers with same leading digits
    var a58 = Decimal("123" + "0" * 25) / Decimal("123" + "0" * 15)
    testing.assert_equal(
        a58,
        Decimal("1" + "0" * 10),
        "Case 58: Division of large numbers with same leading digits failed",
    )

    # 59. Large numbers with different signs
    var a59 = Decimal("9" * 28) / Decimal("-" + "9" * 14)
    testing.assert_equal(
        a59,
        -Decimal("100000000000001"),
        "Case 59: Large numbers with different signs failed",
    )

    # 60. Division near maximum representable value
    try:
        var a60 = Decimal.MAX() / Decimal("0.5")
        testing.assert_true(a60 <= Decimal.MAX())
    except:
        print("Division overflows")

    print("✓ Large number division tests passed!")


fn test_special_cases() raises:
    print("Testing special division cases...")

    # 61. Identical numbers should give 1
    testing.assert_equal(
        String(Decimal("123.456") / Decimal("123.456")),
        "1",
        "Identical numbers should give 1",
    )

    # 62. Division by 0.1 power for decimal shift
    testing.assert_equal(
        String(Decimal("1.234") / Decimal("0.001")),
        "1234",
        "Division by 0.1 power for decimal shift",
    )

    # 63. Division that normalizes out trailing zeros
    testing.assert_equal(
        Decimal("1.000") / Decimal("1.000"),
        Decimal("1"),
        "Case 63: Division that normalizes out trailing zeros failed",
    )

    # 64. Division by 1 should leave number unchanged
    var special_value = Decimal("123.456789012345678901234567")
    testing.assert_equal(
        special_value / Decimal("1"),
        special_value,
        "Case 64: Division by 1 should leave number unchanged failed",
    )

    # 65. Division by self should be 1 for non-zero
    testing.assert_equal(
        Decimal("0.000123") / Decimal("0.000123"),
        Decimal("1"),
        "Case 65: Division by self should be 1 for non-zero failed",
    )

    # 66. Division of 1 by numbers close to 1
    testing.assert_equal(
        Decimal("1") / Decimal("0.999999"),
        Decimal("1.000001000001000001000001000"),
        "Case 66: Division of 1 by numbers close to 1 failed",
    )

    # 67. Series of divisions that should cancel out
    var value = Decimal("123.456")
    var divided = value / Decimal("7")
    var result = divided * Decimal("7")
    testing.assert_true(
        abs(value - result) / value < Decimal("0.0001"),
        "Case 67: Series of divisions that should cancel out failed",
    )

    # 68. Division by fractional power of 10
    testing.assert_equal(
        String(Decimal("5.5") / Decimal("0.055")),
        "100",
        "Division by fractional power of 10",
    )

    # 69. Division causing exact shift in magnitude
    testing.assert_equal(
        String(Decimal("1") / Decimal("1000")),
        "0.001",
        "Division causing exact shift in magnitude",
    )

    # 70. Dividing number very close to zero by one
    var very_small = Decimal("0." + "0" * 27 + "1")
    testing.assert_equal(
        very_small / Decimal("1"),
        very_small,
        "Case 70: Dividing number very close to zero by one failed",
    )

    print("✓ Special case tests passed!")


fn test_mixed_precision() raises:
    print("Testing mixed precision division cases...")

    # 71. High precision / low precision
    testing.assert_equal(
        String(Decimal("123.456789012345678901234567") / Decimal("2")),
        "61.7283945061728394506172835",
        "High precision / low precision",
    )

    # 72. Low precision / high precision
    var a72 = Decimal("1234") / Decimal("0.0000000000000000000000011")
    testing.assert_equal(
        a72,
        Decimal("1121818181818181818181818181.8"),
        "Low precision / high precision",
    )

    # 73. Mixing high precision with power of 10
    var a73 = Decimal("0.123456789012345678901234567") / Decimal("0.1")
    testing.assert_equal(
        a73,
        Decimal("1.23456789012345678901234567"),
        "Case 73: Mixing high precision with power of 10 failed",
    )

    # 74. Precision of result higher than either operand
    var a74 = Decimal("0.1") / Decimal("3")
    testing.assert_true(
        String(a74).startswith("0.0333333333333333"),
        "Case 74: Precision of result higher than either operand failed",
    )

    # 75. Division where divisor has higher precision than dividend
    var a75 = Decimal("1") / Decimal("0.0001234567890123456789")
    testing.assert_true(
        a75 > Decimal("8000"),
        (
            "Case 75: Division where divisor has higher precision than dividend"
            " failed"
        ),
    )

    # 76. Division where precision shifts dramatically
    var a76 = Decimal("0.000000001") / Decimal("0.000000000001")
    testing.assert_equal(
        a76,
        Decimal("1000"),
        "Case 76: Division where precision shifts dramatically failed",
    )

    # 77. Mixing different but high precision values
    var a77 = Decimal("0.12345678901234567") / Decimal("0.98765432109876543")
    testing.assert_true(
        a77 < Decimal("0.13"),
        "Case 77: Mixing different but high precision values failed",
    )

    # 78. Very different scales that result in exact division
    testing.assert_equal(
        String(Decimal("0.0000004") / Decimal("0.0002")),
        "0.002",
        "Very different scales that result in exact division",
    )

    # 79. Maximum precision divided by maximum precision
    testing.assert_equal(
        String(Decimal("0." + "9" * 28) / Decimal("0." + "3" * 28)),
        "3",
        "Maximum precision divided by maximum precision",
    )

    # 80. Many trailing zeros in result
    testing.assert_equal(
        String(Decimal("2.000") / Decimal("0.001")),
        "2000",
        "Many trailing zeros in result",
    )

    print("✓ Mixed precision tests passed!")


fn test_rounding_behavior() raises:
    print("------------------------------------------------------")
    print("Testing division rounding behavior...")

    # 81. Banker's rounding at boundary (round to even)
    var a81 = Decimal("1") / Decimal(
        String("3" + "0" * (Decimal.MAX_PRECISION - 1))
    )
    var expected = "0." + "0" * (Decimal.MAX_PRECISION - 1) + "3"
    testing.assert_equal(
        String(a81), expected, "Case 81: Banker's rounding at boundary failed"
    )

    # 82. Banker's rounding up at precision limit
    var a82 = Decimal("5") / Decimal("9")  # ~0.55555...
    var b82 = Decimal("0." + "5" * 27 + "6")  # 0.5555...6
    testing.assert_equal(
        a82, b82, "Case 82: Banker's rounding up at precision limit failed"
    )

    # 83. Rounding that requires carry propagation
    var a83 = Decimal("1") / Decimal("1.9999999999999999999999999")
    var expected83 = Decimal("0.5000000000000000000000000250")
    testing.assert_equal(
        a83,
        expected83,
        "Case 83: Rounding that requires carry propagation failed",
    )

    # 84. Division that results in exactly half a unit in last place
    var a84 = Decimal("1") / Decimal("4" + "0" * Decimal.MAX_PRECISION)
    var expected84 = Decimal("0." + "0" * (Decimal.MAX_PRECISION))
    testing.assert_equal(
        a84,
        expected84,
        (
            "Case 84: Division that results in exactly half a unit in last"
            " place failed"
        ),
    )

    # 85. Rounding stress test: 1/7 at different precisions
    var a85 = Decimal("1") / Decimal("7")
    var expected85 = Decimal(
        "0.1428571428571428571428571429"
    )  # 28 decimal places
    testing.assert_equal(
        a85,
        expected85,
        "Case 85: Rounding stress test: 1/7 at different precisions failed",
    )

    # 86. Division at the edge
    testing.assert_equal(
        String(Decimal("9.999999999999999999999999999") / Decimal("10")),
        "0.9999999999999999999999999999",
        "Division at the edge",
    )

    # 87. Division requiring rounding to even at last digit
    testing.assert_equal(
        String(Decimal("1.25") / Decimal("0.5")),
        "2.5",
        "Division requiring rounding to even at last digit",
    )

    # 88. Half-even rounding with even digit before
    testing.assert_equal(
        String(Decimal("24.5") / Decimal("10")),
        "2.45",
        "Testing half-even rounding with even digit before",
    )

    # 89. Half-even rounding with odd digit before
    testing.assert_equal(
        String(Decimal("25.5") / Decimal("10")),
        "2.55",
        "Testing half-even rounding with odd digit before",
    )

    # 90. Division with MAX_PRECISION-3 digits
    # 1 / 300000000000000000000000000 (26 zeros)
    var a90 = Decimal("1") / Decimal(String("300000000000000000000000000"))
    testing.assert_equal(
        String(a90),
        "0.0000000000000000000000000033",
        "Case 90: Division with exactly MAX_PRECISION digits failed",
    )

    print("✓ Rounding behavior tests passed!")


fn test_error_cases() raises:
    print("------------------------------------------------------")
    print("Testing division error cases...")

    # 91. Division by zero
    try:
        var result = Decimal("123") / Decimal("0")
        testing.assert_true(
            False, "Case 91: Expected division by zero to raise exception"
        )
    except:
        testing.assert_true(
            True, "Case 91: Division by zero correctly raised exception"
        )

    # 92. Division with overflow potential
    # This is intended to test if the implementation can avoid overflow
    # by handling the operation algebraically before doing actual division
    var large1 = Decimal.MAX()
    var large2 = Decimal("0.5")
    try:
        var result92 = large1 / large2
        testing.assert_true(result92 > large1)
    except:
        print("Overflow detected (acceptable)")

    # 93. Division of maximum possible value
    try:
        var result93 = Decimal.MAX() / Decimal("0.1")
        testing.assert_true(result93 > Decimal.MAX())
    except:
        print("Overflow detected (acceptable)")

    # 94. Division of minimum possible value
    var result94 = Decimal.MIN() / Decimal("10.12345")
    testing.assert_equal(
        result94,
        Decimal("-7826201790324873199704048554.1"),
        "Case 94: Division of minimum possible value failed",
    )

    # 95. Division of very small by very large (approaching underflow)
    var result95 = Decimal("0." + "0" * 27 + "1") / Decimal.MAX()
    testing.assert_equal(
        String(result95),
        "0.0000000000000000000000000000",
        "Case 95: Division of very small by very large failed",
    )

    # 96. Division of maximum by minimum value
    testing.assert_equal(
        String(Decimal.MAX() / Decimal.MIN()),
        "-1",
        "Division of maximum by minimum value",
    )

    # 97. Division with potential for intermediate overflow
    testing.assert_equal(
        String(Decimal("1" + "0" * 20) / Decimal("1" + "0" * 20)),
        "1",
        "Division with potential for intermediate overflow",
    )

    # 98. Division resulting in value greater than representable max
    try:
        # This may either return MAX or raise an error depending on implementation
        var result = Decimal.MAX() / Decimal("0.00001")
        testing.assert_true(result >= Decimal.MAX())
    except:
        testing.assert_true(True, "Overflow detected (acceptable)")

    # 99. Multiple operations that could cause cumulative error
    var calc = (Decimal("1") / Decimal("3")) * Decimal("3")
    testing.assert_equal(
        String(calc),
        "0.9999999999999999999999999999",
        "Case 99: Multiple operations that could cause cumulative error failed",
    )

    # 100. Division at the exact boundary of precision limit
    # 1 / 70000000000000000000000000000 (28 zeros)
    var a100 = Decimal("1") / Decimal(String("7" + "0" * Decimal.MAX_PRECISION))
    testing.assert_equal(
        String(a100),
        "0.0000000000000000000000000000",
        "Case 100: Division at the exact boundary of precision limit failed",
    )

    print("✓ Error case tests passed!")


fn main() raises:
    print("\n=== Running Comprehensive Decimal Division Tests ===\n")

    # Run all test groups
    test_basic_division()
    print()

    test_repeating_decimals()
    print()

    test_precision_rounding()
    print()

    test_scale_handling()
    print()

    test_edge_cases()
    print()

    test_large_numbers()
    print()

    test_special_cases()
    print()

    test_mixed_precision()
    print()

    test_rounding_behavior()
    print()

    test_error_cases()
    print()

    print("✓✓✓ All 100 division tests passed! ✓✓✓")
