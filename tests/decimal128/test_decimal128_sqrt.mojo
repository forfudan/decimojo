"""
Comprehensive tests for the sqrt function of the Decimal128 type.
"""
from decimojo.prelude import dm, Decimal128, RoundingMode
import testing


fn test_perfect_squares() raises:
    print("Testing square root of perfect squares...")

    # Test case 1: sqrt(1) = 1
    try:
        var d1 = Decimal128(1)
        print("  Testing sqrt(1)...")
        var result1 = d1.sqrt()
        print("  Got result: " + String(result1))
        testing.assert_equal(
            String(result1),
            "1",
            "Case 1: sqrt(1) should be 1, got " + String(result1),
        )
        print("  Test case 1 passed.")
    except e:
        print("ERROR in test case 1: sqrt(1) = 1")
        print("Exception: " + String(e))
        raise e

    # Test case 2: sqrt(4) = 2
    try:
        var d2 = Decimal128(4)
        print("  Testing sqrt(4)...")
        var result2 = d2.sqrt()
        print("  Got result: " + String(result2))
        testing.assert_equal(
            String(result2),
            "2",
            "Case 2: sqrt(4) should be 2, got " + String(result2),
        )
        print("  Test case 2 passed.")
    except e:
        print("ERROR in test case 2: sqrt(4) = 2")
        print("Exception: " + String(e))
        raise e

    # Test case 3: sqrt(9) = 3
    try:
        var d3 = Decimal128(9)
        print("  Testing sqrt(9)...")
        var result3 = d3.sqrt()
        print("  Got result: " + String(result3))
        testing.assert_equal(
            String(result3),
            "3",
            "Case 3: sqrt(9) should be 3, got " + String(result3),
        )
        print("  Test case 3 passed.")
    except e:
        print("ERROR in test case 3: sqrt(9) = 3")
        print("Exception: " + String(e))
        raise e

    # Test case 4: sqrt(16) = 4
    try:
        var d4 = Decimal128(16)
        print("  Testing sqrt(16)...")
        var result4 = d4.sqrt()
        print("  Got result: " + String(result4))
        testing.assert_equal(
            String(result4),
            "4",
            "Case 4: sqrt(16) should be 4, got " + String(result4),
        )
        print("  Test case 4 passed.")
    except e:
        print("ERROR in test case 4: sqrt(16) = 4")
        print("Exception: " + String(e))
        raise e

    # Test case 5: sqrt(25) = 5
    try:
        var d5 = Decimal128(25)
        print("  Testing sqrt(25)...")
        var result5 = d5.sqrt()
        print("  Got result: " + String(result5))
        testing.assert_equal(
            String(result5),
            "5",
            "Case 5: sqrt(25) should be 5, got " + String(result5),
        )
        print("  Test case 5 passed.")
    except e:
        print("ERROR in test case 5: sqrt(25) = 5")
        print("Exception: " + String(e))
        raise e

    # Test case 6: sqrt(36) = 6
    try:
        var d6 = Decimal128(36)
        print("  Testing sqrt(36)...")
        var result6 = d6.sqrt()
        print("  Got result: " + String(result6))
        testing.assert_equal(
            String(result6),
            "6",
            "Case 6: sqrt(36) should be 6, got " + String(result6),
        )
        print("  Test case 6 passed.")
    except e:
        print("ERROR in test case 6: sqrt(36) = 6")
        print("Exception: " + String(e))
        raise e

    # Test case 7: sqrt(49) = 7
    try:
        var d7 = Decimal128(49)
        print("  Testing sqrt(49)...")
        var result7 = d7.sqrt()
        print("  Got result: " + String(result7))
        testing.assert_equal(
            String(result7),
            "7",
            "Case 7: sqrt(49) should be 7, got " + String(result7),
        )
        print("  Test case 7 passed.")
    except e:
        print("ERROR in test case 7: sqrt(49) = 7")
        print("Exception: " + String(e))
        raise e

    # Test case 8: sqrt(64) = 8
    try:
        var d8 = Decimal128(64)
        print("  Testing sqrt(64)...")
        var result8 = d8.sqrt()
        print("  Got result: " + String(result8))
        testing.assert_equal(
            String(result8),
            "8",
            "Case 8: sqrt(64) should be 8, got " + String(result8),
        )
        print("  Test case 8 passed.")
    except e:
        print("ERROR in test case 8: sqrt(64) = 8")
        print("Exception: " + String(e))
        raise e

    # Test case 9: sqrt(81) = 9
    try:
        var d9 = Decimal128(81)
        print("  Testing sqrt(81)...")
        var result9 = d9.sqrt()
        print("  Got result: " + String(result9))
        testing.assert_equal(
            String(result9),
            "9",
            "Case 9: sqrt(81) should be 9, got " + String(result9),
        )
        print("  Test case 9 passed.")
    except e:
        print("ERROR in test case 9: sqrt(81) = 9")
        print("Exception: " + String(e))
        raise e

    # Test case 10: sqrt(100) = 10
    try:
        var d10 = Decimal128(100)
        print("  Testing sqrt(100)...")
        var result10 = d10.sqrt()
        print("  Got result: " + String(result10))
        testing.assert_equal(
            String(result10),
            "10",
            "Case 10: sqrt(100) should be 10, got " + String(result10),
        )
        print("  Test case 10 passed.")
    except e:
        print("ERROR in test case 10: sqrt(100) = 10")
        print("Exception: " + String(e))
        raise e

    # Test case 11: sqrt(10000) = 100
    try:
        var d11 = Decimal128(10000)
        print("  Testing sqrt(10000)...")
        var result11 = d11.sqrt()
        print("  Got result: " + String(result11))
        testing.assert_equal(
            String(result11),
            "100",
            "Case 11: sqrt(10000) should be 100, got " + String(result11),
        )
        print("  Test case 11 passed.")
    except e:
        print("ERROR in test case 11: sqrt(10000) = 100")
        print("Exception: " + String(e))
        raise e

    # Test case 12: sqrt(1000000) = 1000
    try:
        var d12 = Decimal128(1000000)
        print("  Testing sqrt(1000000)...")
        var result12 = d12.sqrt()
        print("  Got result: " + String(result12))
        testing.assert_equal(
            String(result12),
            "1000",
            "Case 12: sqrt(1000000) should be 1000, got " + String(result12),
        )
        print("  Test case 12 passed.")
    except e:
        print("ERROR in test case 12: sqrt(1000000) = 1000")
        print("Exception: " + String(e))
        raise e

    print("Perfect square tests passed!")


fn test_non_perfect_squares() raises:
    print("Testing square root of non-perfect squares...")

    # Test case 1
    try:
        var d1 = Decimal128(2)
        var expected_prefix1 = "1.414213562373095048801688724"
        var result1 = d1.sqrt()
        var result_str1 = String(result1)
        testing.assert_true(
            result_str1.startswith(expected_prefix1),
            "sqrt("
            + String(d1)
            + ") should start with "
            + expected_prefix1
            + ", got "
            + result_str1,
        )
    except e:
        print("ERROR in test_non_perfect_squares case 1: sqrt(2) ≈ 1.414...")
        raise e

    # Test case 2
    var d2 = Decimal128(3)
    var expected_prefix2 = "1.73205080756887729352744634"
    var result2 = d2.sqrt()
    var result_str2 = String(result2)
    testing.assert_true(
        result_str2.startswith(expected_prefix2),
        "sqrt("
        + String(d2)
        + ") should start with "
        + expected_prefix2
        + ", got "
        + result_str2,
    )

    # Test case 3
    var d3 = Decimal128(5)
    var expected_prefix3 = "2.23606797749978969640917366"
    var result3 = d3.sqrt()
    var result_str3 = String(result3)
    testing.assert_true(
        result_str3.startswith(expected_prefix3),
        "sqrt("
        + String(d3)
        + ") should start with "
        + expected_prefix3
        + ", got "
        + result_str3,
    )

    # Test case 4
    var d4 = Decimal128(10)
    var expected_prefix4 = "3.162277660168379331998893544"
    var result4 = d4.sqrt()
    var result_str4 = String(result4)
    testing.assert_true(
        result_str4.startswith(expected_prefix4),
        "sqrt("
        + String(d4)
        + ") should start with "
        + expected_prefix4
        + ", got "
        + result_str4,
    )

    # Test case 5
    var d5 = Decimal128(50)
    var expected_prefix5 = "7.071067811865475244008443621"
    var result5 = d5.sqrt()
    var result_str5 = String(result5)
    testing.assert_true(
        result_str5.startswith(expected_prefix5),
        "sqrt("
        + String(d5)
        + ") should start with "
        + expected_prefix5
        + ", got "
        + result_str5,
    )

    # Test case 6
    var d6 = Decimal128(99)
    var expected_prefix6 = "9.949874371066199547344798210"
    var result6 = d6.sqrt()
    var result_str6 = String(result6)
    testing.assert_true(
        result_str6.startswith(expected_prefix6),
        "sqrt("
        + String(d6)
        + ") should start with "
        + expected_prefix6
        + ", got "
        + result_str6,
    )

    # Test case 7
    var d7 = Decimal128(999)
    var expected_prefix7 = "31.6069612585582165452042139"
    var result7 = d7.sqrt()
    var result_str7 = String(result7)
    testing.assert_true(
        result_str7.startswith(expected_prefix7),
        "sqrt("
        + String(d7)
        + ") should start with "
        + expected_prefix7
        + ", got "
        + result_str7,
    )

    print("Non-perfect square tests passed!")


fn test_decimal_values() raises:
    print("Testing square root of decimal values...")

    # Test case 1
    try:
        var d1 = Decimal128("0.25")
        var expected1 = "0.5"
        var result1 = d1.sqrt()
        testing.assert_equal(
            String(result1),
            expected1,
            "sqrt(" + String(d1) + ") should be " + expected1,
        )
    except e:
        print("ERROR in test_decimal_values case 1: sqrt(0.25) = 0.5")
        raise e

    # Test case 2
    var d2 = Decimal128("0.09")
    var expected2 = "0.3"
    var result2 = d2.sqrt()
    testing.assert_equal(
        String(result2),
        expected2,
        "sqrt(" + String(d2) + ") should be " + expected2,
    )

    # Test case 3
    var d3 = Decimal128("0.04")
    var expected3 = "0.2"
    var result3 = d3.sqrt()
    testing.assert_equal(
        String(result3),
        expected3,
        "sqrt(" + String(d3) + ") should be " + expected3,
    )

    # Test case 4
    var d4 = Decimal128("0.01")
    var expected4 = "0.1"
    var result4 = d4.sqrt()
    testing.assert_equal(
        String(result4),
        expected4,
        "sqrt(" + String(d4) + ") should be " + expected4,
    )

    # Test case 5
    var d5 = Decimal128("1.44")
    var expected5 = "1.2"
    var result5 = d5.sqrt()
    testing.assert_equal(
        String(result5),
        expected5,
        "sqrt(" + String(d5) + ") should be " + expected5,
    )

    # Test case 6
    var d6 = Decimal128("2.25")
    var expected6 = "1.5"
    var result6 = d6.sqrt()
    testing.assert_equal(
        String(result6),
        expected6,
        "sqrt(" + String(d6) + ") should be " + expected6,
    )

    # Test case 7
    var d7 = Decimal128("6.25")
    var expected7 = "2.5"
    var result7 = d7.sqrt()
    testing.assert_equal(
        String(result7),
        expected7,
        "sqrt(" + String(d7) + ") should be " + expected7,
    )

    print("Decimal128 value tests passed!")


fn test_edge_cases() raises:
    print("Testing edge cases...")

    # Test sqrt(0) = 0
    try:
        var zero = Decimal128(0)
        var result_zero = zero.sqrt()
        testing.assert_equal(String(result_zero), "0", "sqrt(0) should be 0")
    except e:
        print("ERROR in test_edge_cases: sqrt(0) = 0")
        raise e

    # Test sqrt(1) = 1
    try:
        var one = Decimal128(1)
        var result_one = one.sqrt()
        testing.assert_equal(String(result_one), "1", "sqrt(1) should be 1")
    except e:
        print("ERROR in test_edge_cases: sqrt(1) = 1")
        raise e

    # Test very small positive number
    try:
        var very_small = Decimal128(1, 28)  # Smallest possible positive decimal
        var result_small = very_small.sqrt()
        testing.assert_equal(
            String(result_small),
            "0.00000000000001",
            String(
                "sqrt of very small number should be positive and smaller,"
                " very_small={}, result_small={}"
            ).format(String(very_small), String(result_small)),
        )
    except e:
        print("ERROR in test_edge_cases: sqrt of very small number")
        raise e

    # Test very large number
    try:
        var very_large = Decimal128.from_uint128(
            decimojo.decimal128.utility.power_of_10[DType.uint128](27)
        )  # Large decimal
        var result_large = very_large.sqrt()
        testing.assert_true(
            String(result_large).startswith("31622776601683.79331998893544"),
            "sqrt of 10^27 should start with 31622776601683.79331998893544...",
        )
    except e:
        print("ERROR in test_edge_cases: sqrt of very large number (10^27)")
        raise e

    # Test negative number exception
    var negative_exception_caught = False
    try:
        var negative = Decimal128(-1)
        var _result_negative = negative.sqrt()
        testing.assert_equal(
            True, False, "sqrt() of negative should raise exception"
        )
    except:
        negative_exception_caught = True

    try:
        testing.assert_equal(
            negative_exception_caught,
            True,
            "sqrt() of negative correctly raised exception",
        )
    except e:
        print(
            "ERROR in test_edge_cases: sqrt of negative number didn't raise"
            " exception properly"
        )
        raise e

    print("Edge cases tests passed!")


fn test_precision() raises:
    print("Testing precision of square root calculations...")
    var expected_sqrt2 = (
        "1.414213562373095048801688724"  # First 10 decimal places of sqrt(2)
    )

    # Test precision for irrational numbers
    var two = Decimal128(2)
    var result = two.sqrt()

    # Check at least 10 decimal places (should be enough for most applications)
    testing.assert_true(
        String(result).startswith(expected_sqrt2),
        "sqrt(2) should start with " + expected_sqrt2,
    )

    # Test high precision values
    var precise_value = Decimal128.from_uint128(
        UInt128(20000000000000000000000000), 25
    )
    var precise_result = precise_value.sqrt()
    testing.assert_true(
        String(precise_result).startswith(expected_sqrt2),
        "sqrt of high precision 2 should start with " + expected_sqrt2,
    )

    # Check that results are appropriately rounded
    var d = Decimal128(1894128128951235, 9)
    var sqrt_d = d.sqrt()
    testing.assert_true(
        String(sqrt_d).startswith("1376.27327553478091940498131"),
        (
            "sqrt(1894128.128951235) should startwith"
            " 1376.273275534780919404981314 but got "
            + String(sqrt_d)
        ),
    )

    print("Precision tests passed!")


fn test_mathematical_identities() raises:
    print("Testing mathematical identities...")

    # Test that sqrt(x)² = x - Expanded for each test number
    # Test number 1
    var num1 = Decimal128(2)
    var sqrt_num1 = num1.sqrt()
    var squared1 = sqrt_num1 * sqrt_num1
    var original_rounded1 = round(num1, 10)
    var squared_rounded1 = round(squared1, 10)
    testing.assert_true(
        original_rounded1 == squared_rounded1,
        "sqrt("
        + String(num1)
        + ")² should approximately equal "
        + String(num1)
        + ", but got "
        + String(squared_rounded1),
    )

    # Test number 2
    var num2 = Decimal128(3)
    var sqrt_num2 = num2.sqrt()
    var squared2 = sqrt_num2 * sqrt_num2
    var original_rounded2 = round(num2, 10)
    var squared_rounded2 = round(squared2, 10)
    testing.assert_true(
        original_rounded2 == squared_rounded2,
        "sqrt("
        + String(num2)
        + ")² should approximately equal "
        + String(num2),
    )

    # Test number 3
    var num3 = Decimal128(5)
    var sqrt_num3 = num3.sqrt()
    var squared3 = sqrt_num3 * sqrt_num3
    var original_rounded3 = round(num3, 10)
    var squared_rounded3 = round(squared3, 10)
    testing.assert_true(
        original_rounded3 == squared_rounded3,
        "sqrt("
        + String(num3)
        + ")² should approximately equal "
        + String(num3),
    )

    # Test number 4
    var num4 = Decimal128(7)
    var sqrt_num4 = num4.sqrt()
    var squared4 = sqrt_num4 * sqrt_num4
    var original_rounded4 = round(num4, 10)
    var squared_rounded4 = round(squared4, 10)
    testing.assert_true(
        original_rounded4 == squared_rounded4,
        "sqrt("
        + String(num4)
        + ")² should approximately equal "
        + String(num4),
    )

    # Test number 5
    var num5 = Decimal128(10)
    var sqrt_num5 = num5.sqrt()
    var squared5 = sqrt_num5 * sqrt_num5
    var original_rounded5 = round(num5, 10)
    var squared_rounded5 = round(squared5, 10)
    testing.assert_true(
        original_rounded5 == squared_rounded5,
        "sqrt("
        + String(num5)
        + ")² should approximately equal "
        + String(num5),
    )

    # Test number 6
    var num6 = Decimal128(5, 1)
    var sqrt_num6 = num6.sqrt()
    var squared6 = sqrt_num6 * sqrt_num6
    var original_rounded6 = round(num6, 10)
    var squared_rounded6 = round(squared6, 10)
    testing.assert_true(
        original_rounded6 == squared_rounded6,
        "sqrt("
        + String(num6)
        + ")² should approximately equal "
        + String(num6),
    )

    # Test number 7
    var num7 = Decimal128(25, 2)
    var sqrt_num7 = num7.sqrt()
    var squared7 = sqrt_num7 * sqrt_num7
    var original_rounded7 = round(num7, 10)
    var squared_rounded7 = round(squared7, 10)
    testing.assert_true(
        original_rounded7 == squared_rounded7,
        "sqrt("
        + String(num7)
        + ")² should approximately equal "
        + String(num7),
    )

    # Test number 8
    var num8 = Decimal128(144, 2)
    var sqrt_num8 = num8.sqrt()
    var squared8 = sqrt_num8 * sqrt_num8
    var original_rounded8 = round(num8, 10)
    var squared_rounded8 = round(squared8, 10)
    testing.assert_true(
        original_rounded8 == squared_rounded8,
        "sqrt("
        + String(num8)
        + ")² should approximately equal "
        + String(num8),
    )

    # Test that sqrt(x*y) = sqrt(x) * sqrt(y) - Expanded for each pair
    # Pair 1: 4 and 9
    try:
        var x1 = Decimal128(4)
        var y1 = Decimal128(9)
        var product1 = x1 * y1
        var sqrt_product1 = product1.sqrt()
        var sqrt_x1 = x1.sqrt()
        var sqrt_y1 = y1.sqrt()
        var sqrt_product_separate1 = sqrt_x1 * sqrt_y1
        var sqrt_product_rounded1 = round(sqrt_product1, 10)
        var sqrt_product_separate_rounded1 = round(sqrt_product_separate1, 10)
        testing.assert_true(
            sqrt_product_rounded1 == sqrt_product_separate_rounded1,
            "sqrt("
            + String(x1)
            + "*"
            + String(y1)
            + ") should equal sqrt("
            + String(x1)
            + ") * sqrt("
            + String(y1)
            + ")",
        )
    except e:
        print(
            "ERROR in test_mathematical_identities: sqrt(4*9) = sqrt(4) *"
            " sqrt(9)"
        )
        raise e

    # Pair 2: 16 and 25
    var x2 = Decimal128(16)
    var y2 = Decimal128(25)
    var product2 = x2 * y2
    var sqrt_product2 = product2.sqrt()
    var sqrt_x2 = x2.sqrt()
    var sqrt_y2 = y2.sqrt()
    var sqrt_product_separate2 = sqrt_x2 * sqrt_y2
    var sqrt_product_rounded2 = round(sqrt_product2, 10)
    var sqrt_product_separate_rounded2 = round(sqrt_product_separate2, 10)
    testing.assert_true(
        sqrt_product_rounded2 == sqrt_product_separate_rounded2,
        "sqrt("
        + String(x2)
        + "*"
        + String(y2)
        + ") should equal sqrt("
        + String(x2)
        + ") * sqrt("
        + String(y2)
        + ")",
    )

    # Pair 3: 2 and 8
    var x3 = Decimal128(2)
    var y3 = Decimal128(8)
    var product3 = x3 * y3
    var sqrt_product3 = product3.sqrt()
    var sqrt_x3 = x3.sqrt()
    var sqrt_y3 = y3.sqrt()
    var sqrt_product_separate3 = sqrt_x3 * sqrt_y3
    var sqrt_product_rounded3 = round(sqrt_product3, 10)
    var sqrt_product_separate_rounded3 = round(sqrt_product_separate3, 10)
    testing.assert_true(
        sqrt_product_rounded3 == sqrt_product_separate_rounded3,
        "sqrt("
        + String(x3)
        + "*"
        + String(y3)
        + ") should equal sqrt("
        + String(x3)
        + ") * sqrt("
        + String(y3)
        + ")",
    )

    print("Mathematical identity tests passed!")


fn test_sqrt_performance() raises:
    print("Testing square root performance and convergence...")

    # Test case 1
    try:
        var num1 = Decimal128("0.0001")
        var result1 = num1.sqrt()
        var squared1 = result1 * result1
        var diff1 = squared1 - num1
        diff1 = -diff1 if diff1.is_negative() else diff1
        var rel_diff1 = diff1 / num1
        var diff_float1 = Float64(String(rel_diff1))
        testing.assert_true(
            diff_float1 < 0.00001,
            "Square root calculation for "
            + String(num1)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 1: small number 0.0001")
        raise e

    # Test case 2
    try:
        var num2 = Decimal128("0.01")
        var result2 = num2.sqrt()
        var squared2 = result2 * result2
        var diff2 = squared2 - num2
        diff2 = -diff2 if diff2.is_negative() else diff2
        var rel_diff2 = diff2 / num2
        var diff_float2 = Float64(String(rel_diff2))
        testing.assert_true(
            diff_float2 < 0.00001,
            "Square root calculation for "
            + String(num2)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 2: small number 0.01")
        raise e

    # Test case 3
    try:
        var num3 = Decimal128(1)
        var result3 = num3.sqrt()
        var squared3 = result3 * result3
        var diff3 = squared3 - num3
        diff3 = -diff3 if diff3.is_negative() else diff3
        var rel_diff3 = diff3 / num3
        var diff_float3 = Float64(String(rel_diff3))
        testing.assert_true(
            diff_float3 < 0.00001,
            "Square root calculation for "
            + String(num3)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 3: small number 1")
        raise e

    # Test case 4
    try:
        var num4 = Decimal128(10)
        var result4 = num4.sqrt()
        var squared4 = result4 * result4
        var diff4 = squared4 - num4
        diff4 = -diff4 if diff4.is_negative() else diff4
        var rel_diff4 = diff4 / num4
        testing.assert_true(
            rel_diff4 < Decimal128(0.00001),
            "Square root calculation for "
            + String(num4)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 4: small number 10")
        raise e

    # Test case 5
    try:
        var num5 = Decimal128(10000)
        var result5 = num5.sqrt()
        var squared5 = result5 * result5
        var diff5 = squared5 - num5
        diff5 = -diff5 if diff5.is_negative() else diff5
        var rel_diff5 = diff5 / num5
        var diff_float5 = Float64(String(rel_diff5))
        testing.assert_true(
            diff_float5 < 0.00001,
            "Square root calculation for "
            + String(num5)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 5: small number 10000")
        raise e

    # Test case 6
    try:
        var num6 = Decimal128("10000000000")
        var result6 = num6.sqrt()
        var squared6 = result6 * result6
        var diff6 = squared6 - num6
        diff6 = -diff6 if diff6.is_negative() else diff6
        var rel_diff6 = diff6 / num6
        var diff_float6 = Float64(String(rel_diff6))
        testing.assert_true(
            diff_float6 < 0.00001,
            "Square root calculation for "
            + String(num6)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 6: small number 10000000000")
        raise e

    # Test case 7
    try:
        var num7 = Decimal128("0.999999999")
        var result7 = String(num7.sqrt())
        var expected_result7 = String("0.99999999949999999987")
        testing.assert_true(
            result7.startswith(expected_result7), "sqrt(0.999999999)"
        )
    except e:
        print("ERROR in test_sqrt_performance case 7: sqrt(0.9999999999)")
        raise e

    # Test case 8
    try:
        var num8 = Decimal128("1.000000001")
        var result8 = String(num8.sqrt())
        var expected_result8 = String("1.000000000499999999875")
        testing.assert_true(
            result8.startswith(expected_result8), "sqrt(1.000000001)"
        )
    except e:
        print("ERROR in test_sqrt_performance case 8: sqrt(1.000000001)")
        raise e

    # Test case 9
    try:
        var num9 = Decimal128("3.999999999")
        var result9 = num9.sqrt()
        var squared9 = result9 * result9
        var diff9 = squared9 - num9
        diff9 = -diff9 if diff9.is_negative() else diff9
        var rel_diff9 = diff9 / num9
        var diff_float9 = Float64(String(rel_diff9))
        testing.assert_true(
            diff_float9 < 0.00001,
            "Square root calculation for "
            + String(num9)
            + " should be accurate within 0.001%",
        )
    except e:
        print("ERROR in test_sqrt_performance case 9: small number 3.999999999")
        raise e

    # Test case 10
    try:
        var num10 = Decimal128("4.000000001")
        var result10 = num10.sqrt()
        var squared10 = result10 * result10
        # Using manual absolute difference calculation
        var diff10 = squared10 - num10
        diff10 = -diff10 if diff10.is_negative() else diff10
        var rel_diff10 = diff10 / num10
        testing.assert_true(
            rel_diff10 < Decimal128("0.00001"),
            "Square root calculation for "
            + String(num10)
            + " should be accurate within 0.001%",
        )
    except e:
        print(
            "ERROR in test_sqrt_performance case 10: small number 4.000000001"
        )
        raise e

    print("Performance and convergence tests passed!")


fn run_test_with_error_handling(
    test_fn: fn () raises -> None, test_name: String
) raises:
    """Helper function to run a test function with error handling and reporting.
    """
    try:
        print("\n" + "=" * 50)
        print("RUNNING: " + test_name)
        print("=" * 50)
        test_fn()
        print("\n✓ " + test_name + " passed\n")
    except e:
        print("\n✗ " + test_name + " FAILED!")
        print("Error message: " + String(e))
        raise e


fn main() raises:
    print("=========================================")
    print("Running comprehensive Decimal128 square root tests")

    # run_test_with_error_handling(test_perfect_squares, "Perfect squares test")
    # run_test_with_error_handling(
    #     test_non_perfect_squares, "Non-perfect squares test"
    # )
    # run_test_with_error_handling(test_decimal_values, "Decimal128 values test")
    # run_test_with_error_handling(test_edge_cases, "Edge cases test")
    # run_test_with_error_handling(test_precision, "Precision test")
    # run_test_with_error_handling(
    #     test_mathematical_identities, "Mathematical identities test"
    # )
    # run_test_with_error_handling(
    #     test_sqrt_performance, "Performance and convergence test"
    # )

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    print("All square root tests passed!")
