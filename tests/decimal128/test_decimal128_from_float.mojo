"""
Comprehensive tests for the Decimal128.from_float() constructor method.
Tests 50 different cases to ensure proper conversion from Float64 values.
Note: Comparisons are based on the expected precision of the input value rather
than expecting exact decimal representation for all digits.
"""

import testing
from math import nan, inf
from python import Python

from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_simple_integers() raises:
    """Test conversion of simple integer float values."""
    # print("Testing simple integer float conversions...")

    # Test case 1: Zero
    var zero = Decimal128.from_float(0.0)
    testing.assert_equal(
        String(zero), "0", "Float 0.0 should convert to Decimal128 0"
    )

    # Test case 2: One
    var one = Decimal128.from_float(1.0)
    testing.assert_equal(
        String(one), "1", "Float 1.0 should convert to Decimal128 1"
    )

    # Test case 3: Ten
    var ten = Decimal128.from_float(10.0)
    testing.assert_equal(
        String(ten), "10", "Float 10.0 should convert to Decimal128 10"
    )

    # Test case 4: Hundred
    var hundred = Decimal128.from_float(100.0)
    testing.assert_equal(
        String(hundred), "100", "Float 100.0 should convert to Decimal128 100"
    )

    # Test case 5: Thousand
    var thousand = Decimal128.from_float(1000.0)
    testing.assert_equal(
        String(thousand),
        "1000",
        "Float 1000.0 should convert to Decimal128 1000",
    )

    # print("✓ Simple integer tests passed")


fn test_simple_decimals() raises:
    """Test conversion of simple decimal float values."""
    # print("Testing simple decimal float conversions...")

    # Test case 6: 0.5 (exact representation)
    var half = Decimal128.from_float(0.5)
    testing.assert_equal(
        String(half), "0.5", "Float 0.5 should convert to Decimal128 0.5"
    )

    # Test case 7: 0.25 (exact representation)
    var quarter = Decimal128.from_float(0.25)
    testing.assert_equal(
        String(quarter), "0.25", "Float 0.25 should convert to Decimal128 0.25"
    )

    # Test case 8: 1.5 (exact representation)
    var one_half = Decimal128.from_float(1.5)
    testing.assert_equal(
        String(one_half), "1.5", "Float 1.5 should convert to Decimal128 1.5"
    )

    # Test case 9: 3.14 (check first 3 chars)
    var pi_approx = Decimal128.from_float(3.14)
    testing.assert_true(
        String(pi_approx).startswith("3.14"),
        "Float 3.14 should convert to a Decimal128 starting with 3.14",
    )

    # Test case 10: 2.71828 (check first 6 chars)
    var e_approx = Decimal128.from_float(2.71828)
    testing.assert_true(
        String(e_approx).startswith("2.7182"),
        "Float 2.71828 should convert to a Decimal128 starting with 2.7182",
    )

    # print("✓ Simple decimal tests passed")


fn test_negative_numbers() raises:
    """Test conversion of negative float values."""
    # print("Testing negative float conversions...")

    # Test case 11: -1.0
    var neg_one = Decimal128.from_float(-1.0)
    testing.assert_equal(
        String(neg_one), "-1", "Float -1.0 should convert to Decimal128 -1"
    )

    # Test case 12: -0.5
    var neg_half = Decimal128.from_float(-0.5)
    testing.assert_equal(
        String(neg_half), "-0.5", "Float -0.5 should convert to Decimal128 -0.5"
    )

    # Test case 13: -123.456 (check first 7 chars)
    var neg_decimal = Decimal128.from_float(-123.456)
    testing.assert_true(
        String(neg_decimal).startswith("-123.45"),
        "Float -123.456 should convert to a Decimal128 starting with -123.45",
    )

    # Test case 14: -0.0 (negative zero)
    var neg_zero = Decimal128.from_float(-0.0)
    testing.assert_equal(
        String(neg_zero), "0", "Float -0.0 should convert to Decimal128 0"
    )

    # Test case 15: -999.999 (check first 7 chars)
    var neg_nines = Decimal128.from_float(-999.999)
    testing.assert_true(
        String(neg_nines).startswith("-999.99"),
        "Float -999.999 should convert to a Decimal128 starting with -999.99",
    )

    # print("✓ Negative number tests passed")


fn test_very_large_numbers() raises:
    """Test conversion of very large float values."""
    # print("Testing very large float conversions...")

    # Test case 16: 1e10
    var ten_billion = Decimal128.from_float(1e10)
    testing.assert_equal(
        String(ten_billion),
        "10000000000",
        "Float 1e10 should convert to Decimal128 10000000000",
    )

    # Test case 17: 1e15
    var quadrillion = Decimal128.from_float(1e15)
    testing.assert_equal(
        String(quadrillion),
        "1000000000000000",
        "Float 1e15 should convert to Decimal128 1000000000000000",
    )

    # Test case 18: Max safe integer in JavaScript (2^53 - 1)
    var max_safe_int = Decimal128.from_float(9007199254740991.0)
    testing.assert_equal(
        String(max_safe_int),
        "9007199254740991",
        "Float 2^53-1 should convert to exact Decimal128 9007199254740991",
    )

    # Test case 19: 1e20
    var hundred_quintillion = Decimal128.from_float(1e20)
    testing.assert_equal(
        String(hundred_quintillion),
        "100000000000000000000",
        "Float 1e20 should convert to Decimal128 100000000000000000000",
    )

    # Test case 20: Large number with limited precision
    var large_number = Decimal128.from_float(1.23456789e15)
    testing.assert_true(
        String(large_number).startswith("1234567890000000"),
        "Large float should convert with appropriate precision",
    )

    # print("✓ Very large number tests passed")


fn test_very_small_numbers() raises:
    """Test conversion of very small float values."""
    # print("Testing very small float conversions...")

    # Test case 21: 1e-10
    var tiny = Decimal128.from_float(1e-10)
    testing.assert_true(
        String(tiny).startswith("0.00000000"),
        "Float 1e-10 should convert to a Decimal128 with appropriate zeros",
    )

    # Test case 22: 1e-15
    var tinier = Decimal128.from_float(1e-15)
    testing.assert_true(
        String(tinier).startswith("0.000000000000001"),
        "Float 1e-15 should convert to a Decimal128 with appropriate zeros",
    )

    # Test case 23: Small number with precision
    var small_with_precision = Decimal128.from_float(1.234e-10)
    var expected_prefix = "0.0000000001"
    testing.assert_true(
        String(small_with_precision).startswith(expected_prefix),
        "Small float should preserve available precision",
    )

    # Test case 24: Very small but non-zero
    var very_small = Decimal128.from_float(1e-20)
    testing.assert_true(
        String(very_small).startswith("0.00000000000000000001"),
        "Very small float should convert to appropriate Decimal128",
    )

    # Test case 25: Denormalized float
    var denorm = Decimal128.from_float(1e-310)
    testing.assert_true(
        String(denorm).startswith("0."),
        "Denormalized float should convert to small Decimal128",
    )

    # print("✓ Very small number tests passed")


fn test_binary_to_decimal_conversion() raises:
    """Test conversion of float values that require binary to decimal conversion.
    """
    # print("Testing binary to decimal conversion edge cases...")

    # Test case 26: 0.1 (known inexact in binary)
    var point_one = Decimal128.from_float(0.1)
    testing.assert_true(
        String(point_one).startswith("0.1"),
        "Float 0.1 should convert to a Decimal128 starting with 0.1",
    )

    # Test case 27: 0.2 (known inexact in binary)
    var point_two = Decimal128.from_float(0.2)
    testing.assert_true(
        String(point_two).startswith("0.2"),
        "Float 0.2 should convert to a Decimal128 starting with 0.2",
    )

    # Test case 28: 0.3 (known inexact in binary)
    var point_three = Decimal128.from_float(0.3)
    testing.assert_true(
        String(point_three).startswith("0.3"),
        "Float 0.3 should convert to a Decimal128 that starts with 0.3",
    )

    # Test case 29: 0.1 + 0.2 (famously != 0.3 in binary)
    var point_one_plus_two = Decimal128.from_float(0.1 + 0.2)
    testing.assert_true(
        String(point_one_plus_two).startswith("0.3"),
        "Float 0.1+0.2 should convert to a Decimal128 starting with 0.3",
    )

    # Test case 30: Repeating binary fraction
    var repeating = Decimal128.from_float(0.1)
    testing.assert_true(
        String(repeating).startswith("0.1"),
        "Float with repeating binary fraction should convert properly",
    )

    # print("✓ Binary to decimal conversion tests passed")


fn test_rounding_behavior() raises:
    """Test rounding behavior during float to Decimal128 conversion."""
    # print("Testing rounding behavior in float to Decimal128 conversion...")

    # Test case 31: Pi with limited precision
    var pi = Decimal128.from_float(3.141592653589793)
    testing.assert_true(
        String(pi).startswith("3.14159265358979"),
        "Float Pi should maintain appropriate precision in Decimal128",
    )

    # Test case 32: 1/3 (repeating decimal in base 10)
    var one_third = Decimal128.from_float(1.0 / 3.0)
    testing.assert_true(
        String(one_third).startswith("0.33333333"),
        "Float 1/3 should maintain appropriate precision in Decimal128",
    )

    # Test case 33: 2/3 (repeating decimal in base 10)
    var two_thirds = Decimal128.from_float(2.0 / 3.0)
    testing.assert_true(
        String(two_thirds).startswith("0.66666666"),
        "Float 2/3 should maintain appropriate precision in Decimal128",
    )

    # Test case 34: Round trip conversion
    var x = 123.456
    var decimal_x = Decimal128.from_float(x)
    testing.assert_true(
        String(decimal_x).startswith("123.456"),
        "Float-to-Decimal128 conversion should preserve input precision",
    )

    # Test case 35: Number at float precision boundary
    var precision_boundary = Decimal128.from_float(9.9999999999999999)
    testing.assert_true(
        String(precision_boundary).startswith("10"),
        "Float near precision boundary should convert appropriately",
    )

    # print("✓ Rounding behavior tests passed")


fn test_special_values() raises:
    """Test handling of special float values."""
    # print("Testing special float values...")

    # Test case 36: 0.0 (already covered but included for completeness)
    var zero = Decimal128.from_float(0.0)
    testing.assert_equal(
        String(zero), "0", "Float 0.0 should convert to Decimal128 0"
    )

    # Test case 37: Epsilon (smallest Float64 increment from 1.0)
    var epsilon = Decimal128.from_float(2.220446049250313e-16)
    testing.assert_true(
        String(epsilon).startswith("0.000000000000000"),
        "Float64 epsilon should convert with appropriate precision",
    )

    # Test case 38: power of 2 (exact in binary)
    var pow2 = Decimal128.from_float(1024.0)
    testing.assert_equal(
        String(pow2), "1024", "Powers of 2 should convert exactly"
    )

    # Test case 39: Small power of 2
    var small_pow2 = Decimal128.from_float(0.125)  # 2^-3
    testing.assert_equal(
        String(small_pow2), "0.125", "Small powers of 2 should convert exactly"
    )

    # Test case 40: Float with many 9s
    var many_nines = Decimal128.from_float(9.9999)
    testing.assert_true(
        String(many_nines).startswith("9.9999"),
        "Float with many 9s should preserve precision appropriately",
    )

    # print("✓ Special value tests passed")


fn test_scientific_notation() raises:
    """Test handling of scientific notation values."""
    # print("Testing scientific notation float values...")

    # Test case 41: Simple scientific notation
    var sci1 = Decimal128.from_float(1.23e5)
    testing.assert_equal(
        String(sci1),
        "123000",
        "Float in scientific notation should convert properly",
    )

    # Test case 42: Negative exponent
    var sci2 = Decimal128.from_float(4.56e-3)
    testing.assert_true(
        String(sci2).startswith("0.00456"),
        (
            "Float with negative exponent should convert with appropriate"
            " precision"
        ),
    )

    # Test case 43: Extreme positive exponent
    var sci3 = Decimal128.from_float(1.0e20)
    testing.assert_equal(
        String(sci3),
        "100000000000000000000",
        "Float with large exponent should convert properly",
    )

    # Test case 44: Extreme negative exponent
    var sci4 = Decimal128.from_float(1.0e-10)
    testing.assert_true(
        String(sci4).startswith("0.00000000"),
        "Float with negative exponent should have appropriate zeros",
    )

    # Test case 45: Low precision, high exponent
    var sci5 = Decimal128.from_float(5e20)
    testing.assert_true(
        String(sci5).startswith("5"),
        "Float with low precision but high exponent should convert properly",
    )

    # print("✓ Scientific notation tests passed")


fn test_boundary_cases() raises:
    """Test boundary cases for float to Decimal128 conversion."""
    # print("Testing boundary cases...")

    # Test case 46: Exact power of 10
    var pow10 = Decimal128.from_float(1000.0)
    testing.assert_equal(
        String(pow10), "1000", "Powers of 10 should convert exactly"
    )

    # Test case 47: Max safe integer precision
    var safe_int = Decimal128.from_float(9007199254740990.0)
    testing.assert_equal(
        String(safe_int),
        "9007199254740990",
        "Max safe integer values should convert exactly",
    )

    # Test case 48: Just beyond safe integer precision
    var beyond_safe = Decimal128.from_float(9007199254740994.0)
    testing.assert_true(
        String(beyond_safe).startswith("9007199254740"),
        "Beyond safe integer values should maintain appropriate precision",
    )

    # Test case 49: Float with many trailing zeros
    var trailing_zeros = Decimal128.from_float(123.000000)
    testing.assert_true(
        String(trailing_zeros).startswith("123"),
        "Floats with trailing zeros should convert properly",
    )

    # Test case 50: Simple fraction
    var fraction = Decimal128.from_float(0.125)  # 1/8, exact in binary
    testing.assert_equal(
        String(fraction),
        "0.125",
        (
            "Simple fractions with exact binary representation should convert"
            " precisely"
        ),
    )

    # print("✓ Boundary case tests passed")


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
    # print("Running 50 tests for Decimal128.from_float()")
    # print("=========================================")

    # run_test_with_error_handling(test_simple_integers, "Simple integers test")
    # run_test_with_error_handling(test_simple_decimals, "Simple decimals test")
    # run_test_with_error_handling(test_negative_numbers, "Negative numbers test")
    # run_test_with_error_handling(
    #     test_very_large_numbers, "Very large numbers test"
    # )
    # run_test_with_error_handling(
    #     test_very_small_numbers, "Very small numbers test"
    # )
    # run_test_with_error_handling(
    #     test_binary_to_decimal_conversion, "Binary to decimal conversion test"
    # )
    # run_test_with_error_handling(
    #     test_rounding_behavior, "Rounding behavior test"
    # )
    # run_test_with_error_handling(test_special_values, "Special values test")
    # run_test_with_error_handling(
    #     test_scientific_notation, "Scientific notation test"
    # )
    # run_test_with_error_handling(test_boundary_cases, "Boundary cases test")

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All 50 Decimal128.from_float() tests passed!")
