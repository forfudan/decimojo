"""
Comprehensive tests for the Decimal128.__float__() method.
Tests 20 different cases to ensure proper conversion from Decimal128 to float.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_integer_conversions() raises:
    """Test conversion of basic integers to float."""
    print("Testing basic integer conversions to float...")

    # Test case 1: Zero
    var zero = Decimal128(0)
    var zero_float = Float64(zero)
    testing.assert_equal(
        zero_float, 0.0, "Decimal128('0') should convert to float 0.0"
    )

    # Test case 2: One
    var one = Decimal128(1)
    var one_float = Float64(one)
    testing.assert_equal(
        one_float, 1.0, "Decimal128('1') should convert to float 1.0"
    )

    # Test case 3: Ten
    var ten = Decimal128(10)
    var ten_float = Float64(ten)
    testing.assert_equal(
        ten_float, 10.0, "Decimal128('10') should convert to float 10.0"
    )

    # Test case 4: Large integer
    var large_int = Decimal128(123456)
    var large_int_float = Float64(large_int)
    testing.assert_equal(large_int_float, 123456.0)

    print("✓ Basic integer conversions to float passed!")


fn test_decimal_conversions() raises:
    """Test conversion of decimal values to float."""
    print("Testing decimal conversions to float...")

    # Test case 5: Simple decimal
    var simple_dec = Decimal128("3.14")
    var simple_dec_float = Float64(simple_dec)
    testing.assert_equal(
        simple_dec_float,
        3.14,
        "Decimal128('3.14') should convert to float 3.14",
    )

    # Test case 6: Decimal128 with many places
    var pi = Decimal128("3.14159265358979323846")
    var pi_float = Float64(pi)
    # Allow for small difference due to float precision
    testing.assert_true(abs(pi_float - 3.14159265358979323846) < 1e-15)

    # Test case 7: Small decimal
    var small_dec = Decimal128("0.0001")
    var small_dec_float = Float64(small_dec)
    testing.assert_equal(small_dec_float, 0.0001)

    # Test case 8: Repeating decimal
    var repeating = Decimal128("0.33333333333333")
    var repeating_float = Float64(repeating)
    testing.assert_true(abs(repeating_float - 0.33333333333333) < 1e-14)

    print("✓ Decimal128 conversions to float passed!")


fn test_negative_conversions() raises:
    """Test conversion of negative values to float."""
    print("Testing negative value conversions to float...")

    # Test case 9: Negative integer
    var neg_int = Decimal128("-123")
    var neg_int_float = Float64(neg_int)
    testing.assert_equal(neg_int_float, -123.0)

    # Test case 10: Negative decimal
    var neg_dec = Decimal128("-0.5")
    var neg_dec_float = Float64(neg_dec)
    testing.assert_equal(neg_dec_float, -0.5)

    # Test case 11: Negative zero
    var neg_zero = Decimal128("-0")
    var neg_zero_float = Float64(neg_zero)
    testing.assert_equal(
        neg_zero_float, 0.0
    )  # Note: -0.0 equals 0.0 in most comparisons

    print("✓ Negative value conversions to float passed!")


fn test_edge_cases() raises:
    """Test edge cases for conversion to float."""
    print("Testing edge cases for float conversion...")

    # Test case 12: Very small positive number
    var very_small = Decimal128("0." + "0" * 20 + "1")  # 0.00000000000000000001
    var very_small_float = Float64(very_small)
    testing.assert_true(
        very_small_float > 0.0 and very_small_float < 1e-19,
        "Very small Decimal128 should convert to near-zero positive float",
    )

    # Test case 13: Value close to float precision
    var precision_edge = Decimal128("0.1234567890123456")
    var precision_edge_float = Float64(precision_edge)
    testing.assert_true(
        abs(precision_edge_float - 0.1234567890123456) < 1e-15,
        "Float conversion should preserve precision within float limits",
    )

    # Test case 14: Very large number
    var large_num = Decimal128("1e15")  # 1,000,000,000,000,000
    var large_num_float = Float64(large_num)
    testing.assert_equal(large_num_float, 1e15)

    # Test case 15: Number larger than float precision but within range
    var large_precise = Decimal128(
        "9007199254740993"
    )  # First integer not exactly representable in float64
    var large_precise_float = Float64(large_precise)
    testing.assert_true(
        abs(large_precise_float - 9007199254740993.0) <= 1.0,
        "Large number should be converted with expected float precision loss",
    )

    print("✓ Edge case conversions to float passed!")


fn test_special_values() raises:
    """Test special values for conversion to float."""
    print("Testing special values for float conversion...")

    # Test case 16: Decimal128 with trailing zeros
    var trailing_zeros = Decimal128("5.0000")
    var trailing_zeros_float = Float64(trailing_zeros)
    testing.assert_equal(trailing_zeros_float, 5.0)

    # Test case 17: Decimal128 with leading zeros
    var leading_zeros = Decimal128("000123.456")
    var leading_zeros_float = Float64(leading_zeros)
    testing.assert_equal(leading_zeros_float, 123.456)

    # Test case 18: Scientific notation
    var sci_notation = Decimal128("1.23e5")
    var sci_notation_float = Float64(sci_notation)
    testing.assert_equal(sci_notation_float, 123000.0)

    # Test case 19: Max decimal convertible to float
    var max_decimal = Decimal128(
        "79228162514264337593543950335"
    )  # Approximate Float64 max
    var max_decimal_float = Float64(max_decimal)
    # Allow some imprecision with large values
    testing.assert_true(
        abs(
            (max_decimal_float - 79228162514264337593543950335)
            / 79228162514264337593543950335
        )
        < 1e-10,
        "Large value should convert within reasonable precision",
    )

    # Test case 20: Another number with specific precision challenges
    var challenge_num = Decimal128("0.1")
    var challenge_float = Float64(challenge_num)
    # 0.1 cannot be exactly represented in binary floating point
    testing.assert_true(
        abs(challenge_float - 0.1) < 1e-15,
        "Binary float approximation of decimal 0.1 should be very close",
    )

    print("✓ Special value conversions to float passed!")


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
    print("Running 20 tests for Decimal128.__float__()")
    print("=========================================")

    # run_test_with_error_handling(
    #     test_basic_integer_conversions, "Basic integer conversions"
    # )
    # run_test_with_error_handling(
    #     test_decimal_conversions, "Decimal128 conversions"
    # )
    # run_test_with_error_handling(
    #     test_negative_conversions, "Negative value conversions"
    # )
    # run_test_with_error_handling(test_edge_cases, "Edge cases")
    # run_test_with_error_handling(test_special_values, "Special values")

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    print("All 20 Decimal128.__float__() tests passed!")
