"""
Comprehensive tests for the exp() function in the DeciMojo library.
Tests various cases including basic values, mathematical identities,
and edge cases to ensure proper calculation of e^x.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode
from decimojo.decimal128.exponential import exp


fn test_basic_exp_values() raises:
    """Test basic exponential function values."""
    # print("Testing basic exponential values...")

    # Test case 1: e^0 = 1
    var zero = Decimal128(String("0"))
    var result0 = exp(zero)
    testing.assert_equal(
        String(result0), String("1"), "e^0 should be 1, got " + String(result0)
    )

    # Test case 2: e^1 should be close to Euler's number
    var one = Decimal128(String("1"))
    var result1 = exp(one)
    var expected1 = String(
        "2.718281828459045235360287471"
    )  # e to 27 decimal places
    testing.assert_true(
        String(result1).startswith(expected1[0:25]),
        "e^1 should be approximately "
        + String(expected1)
        + ", got "
        + String(result1),
    )

    # Test case 3: e^2
    var two = Decimal128(String("2"))
    var result2 = exp(two)
    var expected2 = String(
        "7.389056098930650227230427461"
    )  # e^2 to 27 decimal places
    testing.assert_true(
        String(result2).startswith(expected2[0:25]),
        "e^2 should be approximately "
        + String(expected2)
        + ", got "
        + String(result2),
    )

    # Test case 4: e^3
    var three = Decimal128(String("3"))
    var result3 = exp(three)
    var expected3 = String(
        "20.08553692318766774092852965"
    )  # e^3 to 27 decimal places
    testing.assert_true(
        String(result3).startswith(expected3[0:25]),
        "e^3 should be approximately "
        + String(expected3)
        + ", got "
        + String(result3),
    )

    # Test case 5: e^5
    var five = Decimal128(String("5"))
    var result5 = exp(five)
    var expected5 = String(
        "148.41315910257660342111558004055"
    )  # e^5 to 27 decimal places
    testing.assert_true(
        String(result5).startswith(expected5[0:25]),
        "e^5 should be approximately "
        + String(expected5)
        + ", got "
        + String(result5),
    )

    # print("✓ Basic exponential values tests passed!")


fn test_negative_exponents() raises:
    """Test exponential function with negative exponents."""
    # print("Testing exponential function with negative exponents...")

    # Test case 1: e^(-1) = 1/e
    var neg_one = Decimal128(String("-1"))
    var result1 = exp(neg_one)
    var expected1 = String(
        "0.3678794411714423215955237702"
    )  # e^-1 to 27 decimal places
    testing.assert_true(
        String(result1).startswith(expected1[0:25]),
        "e^-1 should be approximately "
        + String(expected1)
        + ", got "
        + String(result1),
    )

    # Test case 2: e^(-2) = 1/e^2
    var neg_two = Decimal128(String("-2"))
    var result2 = exp(neg_two)
    var expected2 = String(
        "0.1353352832366126918939994950"
    )  # e^-2 to 27 decimal places
    testing.assert_true(
        String(result2).startswith(expected2[0:25]),
        "e^-2 should be approximately "
        + String(expected2)
        + ", got "
        + String(result2),
    )

    # Test case 3: e^(-5)
    var neg_five = Decimal128(String("-5"))
    var result3 = exp(neg_five)
    var expected3 = String(
        "0.006737946999085467096636048777"
    )  # e^-5 to 27 decimal places
    testing.assert_true(
        String(result3).startswith(expected3[0:25]),
        "e^-5 should be approximately "
        + String(expected3)
        + ", got "
        + String(result3),
    )

    # print("✓ Negative exponents tests passed!")


fn test_fractional_exponents() raises:
    """Test exponential function with fractional exponents."""
    # print("Testing exponential function with fractional exponents...")

    # Test case 1: e^0.5
    var half = Decimal128(String("0.5"))
    var result1 = exp(half)
    var expected1 = String(
        "1.648721270700128146848650787"
    )  # e^0.5 to 27 decimal places
    testing.assert_true(
        String(result1).startswith(expected1[0:25]),
        "e^0.5 should be approximately "
        + String(expected1)
        + ", got "
        + String(result1),
    )

    # Test case 2: e^0.1
    var tenth = Decimal128(String("0.1"))
    var result2 = exp(tenth)
    var expected2 = String(
        "1.105170918075647624811707826"
    )  # e^0.1 to 27 decimal places
    testing.assert_true(
        String(result2).startswith(expected2[0:25]),
        "e^0.1 should be approximately "
        + String(expected2)
        + ", got "
        + String(result2),
    )

    # Test case 3: e^(-0.5)
    var neg_half = Decimal128(String("-0.5"))
    var result3 = exp(neg_half)
    var expected3 = String(
        "0.6065306597126334236037995349"
    )  # e^-0.5 to 27 decimal places
    testing.assert_true(
        String(result3).startswith(expected3[0:25]),
        "e^-0.5 should be approximately "
        + String(expected3)
        + ", got "
        + String(result3),
    )

    # Test case 4: e^1.5
    var one_half = Decimal128(String("1.5"))
    var result4 = exp(one_half)
    var expected4 = String(
        "4.481689070338064822602055460"
    )  # e^1.5 to 27 decimal places
    testing.assert_true(
        String(result4).startswith(expected4[0:25]),
        "e^1.5 should be approximately "
        + String(expected4)
        + ", got "
        + String(result4),
    )

    # print("✓ Fractional exponents tests passed!")


fn test_high_precision_exponents() raises:
    """Test exponential function with high precision inputs."""
    # print("Testing exponential function with high precision inputs...")

    # Test case 1: e^π (approximate)
    var pi = Decimal128(String("3.14159265358979323846264338327950288"))
    var result1 = exp(pi)
    var expected1 = String(
        "23.14069263277926900572908636794"
    )  # e^pi to 27 decimal places
    testing.assert_true(
        String(result1).startswith(expected1[0:25]),
        "e^pi should be approximately "
        + String(expected1)
        + ", got "
        + String(result1),
    )

    # Test case 2: e^2.71828 (approximate e)
    var approx_e = Decimal128(String("2.71828"))
    var result2 = exp(approx_e)
    var expected2 = String(
        "15.154234532556727211057207398340"
    )  # e^(~e) to 27 decimal places
    testing.assert_true(
        String(result2).startswith(expected2[0:25]),
        "e^(~e) should be approximately "
        + String(expected2)
        + ", got "
        + String(result2),
    )

    # print("✓ High precision exponents tests passed!")


fn test_mathematical_identities() raises:
    """Test mathematical identities related to the exponential function."""
    # print("Testing mathematical identities for exponential function...")

    # Test case 1: e^(a+b) = e^a * e^b
    var a = Decimal128(String("2"))
    var b = Decimal128(String("3"))
    var exp_a_plus_b = exp(a + b)
    var exp_a_times_exp_b = exp(a) * exp(b)

    # Compare with some level of precision to account for computational differences
    var diff1 = abs(exp_a_plus_b - exp_a_times_exp_b)
    var rel_diff1 = diff1 / exp_a_plus_b
    testing.assert_true(
        rel_diff1 < Decimal128(String("0.0000001")),
        "e^(a+b) should equal e^a * e^b within tolerance, difference: "
        + String(rel_diff1),
    )

    # Test case 2: e^(-x) = 1/e^x
    var x = Decimal128(String("1.5"))
    var exp_neg_x = exp(-x)
    var one_over_exp_x = Decimal128(String("1")) / exp(x)

    # Compare with some level of precision
    var diff2 = abs(exp_neg_x - one_over_exp_x)
    var rel_diff2 = diff2 / exp_neg_x
    testing.assert_true(
        rel_diff2 < Decimal128(String("0.0000001")),
        "e^(-x) should equal 1/e^x within tolerance, difference: "
        + String(rel_diff2),
    )

    # Test case 3: e^0 = 1 (Already tested in basic values, but included here for completeness)
    var zero = Decimal128(String("0"))
    var exp_zero = exp(zero)
    testing.assert_equal(String(exp_zero), String("1"), "e^0 should equal 1")

    # print("✓ Mathematical identities tests passed!")


fn test_extreme_values() raises:
    """Test exponential function with extreme values."""
    # print("Testing exponential function with extreme values...")

    # Test case 1: Very small positive input
    var small_input = Decimal128(String("0.0000001"))
    var result1 = exp(small_input)
    testing.assert_true(
        String(result1).startswith(String("1.0000001")),
        "e^0.0000001 should be approximately 1.0000001, got " + String(result1),
    )

    # Test case 2: Very small negative input
    var small_neg_input = Decimal128(String("-0.0000001"))
    var result2 = exp(small_neg_input)
    testing.assert_true(
        String(result2).startswith(String("0.9999999")),
        "e^-0.0000001 should be approximately 0.9999999, got "
        + String(result2),
    )

    # Test case 3: Large positive value
    # This should not overflow but should produce a very large result
    # Note: The implementation may have specific limits
    var large_input = Decimal128(String("20"))
    var result3 = exp(large_input)
    testing.assert_true(
        result3 > Decimal128(String("100000000")),
        "e^20 should be a very large number > 100,000,000, got "
        + String(result3),
    )

    # print("✓ Extreme values tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for exponential function."""
    # print("Testing edge cases for exponential function...")

    # Test with very high precision input
    var high_precision = Decimal128(String("1.23456789012345678901234567"))
    var result_high = exp(high_precision)
    testing.assert_true(
        len(String(result_high)) > 15,
        "Exp with high precision input should produce high precision output",
    )

    # print("✓ Edge cases tests passed!")


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
        raise e^


fn main() raises:
    # print("=========================================")
    # print("Running Exponential Function Tests")
    # print("=========================================")

    # run_test_with_error_handling(
    #     test_basic_exp_values, "Basic exponential values test"
    # )
    # run_test_with_error_handling(
    #     test_negative_exponents, "Negative exponents test"
    # )
    # run_test_with_error_handling(
    #     test_fractional_exponents, "Fractional exponents test"
    # )
    # run_test_with_error_handling(
    #     test_high_precision_exponents, "High precision exponents test"
    # )
    # run_test_with_error_handling(
    #     test_mathematical_identities, "Mathematical identities test"
    # )
    # run_test_with_error_handling(test_extreme_values, "Extreme values test")
    # run_test_with_error_handling(test_edge_cases, "Edge cases test")

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All exponential function tests passed!")
