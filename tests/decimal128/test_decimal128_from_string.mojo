"""
Comprehensive tests for the Decimal128.from_string() constructor method.
Tests 50 different cases to ensure proper conversion from string values.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_integers() raises:
    """Test conversion of basic integer strings."""
    # print("Testing basic integer string conversions...")

    # Test case 1: Zero
    var zero = Decimal128.from_string("0")
    testing.assert_equal(
        String(zero), "0", "String '0' should convert to Decimal128 0"
    )

    # Test case 2: One
    var one = Decimal128.from_string("1")
    testing.assert_equal(
        String(one), "1", "String '1' should convert to Decimal128 1"
    )

    # Test case 3: Simple integer
    var simple_int = Decimal128.from_string("123")
    testing.assert_equal(
        String(simple_int), "123", "String '123' should convert correctly"
    )

    # Test case 4: Large integer
    var large_int = Decimal128.from_string("123456789")
    testing.assert_equal(String(large_int), "123456789")

    # Test case 5: Integer with internal spaces (should fail)
    var exception_caught = False
    try:
        var _invalid = Decimal128.from_string("1 234")
        testing.assert_equal(
            True, False, "Should have raised exception for space in integer"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # print("✓ Basic integer tests passed")


fn test_basic_decimals() raises:
    """Test conversion of basic decimal strings."""
    # print("Testing basic decimal string conversions...")

    # Test case 6: Simple decimal
    var simple_dec = Decimal128.from_string("123.45")
    testing.assert_equal(String(simple_dec), "123.45")

    # Test case 7: Zero decimal point
    var zero_point = Decimal128.from_string("0.0")
    testing.assert_equal(String(zero_point), "0.0")

    # Test case 8: Single digit with decimal
    var single_digit = Decimal128.from_string("1.23")
    testing.assert_equal(String(single_digit), "1.23")

    # Test case 9: One-level precision
    var one_precision = Decimal128.from_string("9.9")
    testing.assert_equal(String(one_precision), "9.9")

    # Test case 10: High precision decimal
    var high_precision = Decimal128.from_string(
        "0.12345678901234567890123456789"
    )
    testing.assert_equal(
        String(high_precision), "0.1234567890123456789012345679"
    )

    # print("✓ Basic decimal tests passed")


fn test_negative_numbers() raises:
    """Test conversion of negative number strings."""
    # print("Testing negative number string conversions...")

    # Test case 11: Negative integer
    var neg_int = Decimal128.from_string("-123")
    testing.assert_equal(String(neg_int), "-123")

    # Test case 12: Negative decimal
    var neg_dec = Decimal128.from_string("-123.45")
    testing.assert_equal(String(neg_dec), "-123.45")

    # Test case 13: Negative zero
    var neg_zero = Decimal128.from_string("-0")
    testing.assert_equal(
        String(neg_zero), "-0", "Negative zero should convert to '-0'"
    )

    # Test case 14: Negative decimal zero
    var neg_decimal_zero = Decimal128.from_string("-0.0")
    testing.assert_equal(
        String(neg_decimal_zero),
        "-0.0",
        "Negative zero decimal should convert to '-0.0'",
    )

    # Test case 15: Negative small value
    var neg_small = Decimal128.from_string("-0.001")
    testing.assert_equal(String(neg_small), "-0.001")

    # print("✓ Negative number tests passed")


fn test_zeros_variants() raises:
    """Test conversion of various zero representations."""
    # print("Testing zero variants string conversions...")

    # Test case 16: Single zero
    var single_zero = Decimal128.from_string("0")
    testing.assert_equal(String(single_zero), "0")

    # Test case 17: Zero with decimal
    var zero_decimal = Decimal128.from_string("0.0")
    testing.assert_equal(String(zero_decimal), "0.0")

    # Test case 18: Zero with high precision
    var zero_high_precision = Decimal128.from_string(
        "0.00000000000000000000000000"
    )
    testing.assert_equal(
        String(zero_high_precision), "0.00000000000000000000000000"
    )

    # Test case 19: Multiple leading zeros
    var leading_zeros = Decimal128.from_string("000000")
    testing.assert_equal(
        String(leading_zeros), "0", "Multiple zeros should convert to just '0'"
    )

    # Test case 20: Multiple leading zeros with decimal
    var leading_zeros_decimal = Decimal128.from_string("000.000")
    testing.assert_equal(String(leading_zeros_decimal), "0.000")

    # print("✓ Zero variants tests passed")


fn test_scientific_notation() raises:
    """Test conversion of strings with scientific notation."""
    # print("Testing scientific notation string conversions...")

    # Test case 21: Simple positive exponent
    var simple_pos_exp = Decimal128.from_string("1.23e2")
    testing.assert_equal(String(simple_pos_exp), "123")

    # Test case 22: Simple negative exponent
    var simple_neg_exp = Decimal128.from_string("1.23e-2")
    testing.assert_equal(String(simple_neg_exp), "0.0123")

    # Test case 23: Zero with exponent
    var zero_exp = Decimal128.from_string("0e10")
    testing.assert_equal(String(zero_exp), "0")

    # Test case 24: Explicit positive exponent
    var explicit_pos_exp = Decimal128.from_string("1.23E+2")
    testing.assert_equal(String(explicit_pos_exp), "123")

    # Test case 25: Large exponent value
    var large_exp = Decimal128.from_string("1.23e20")
    testing.assert_equal(String(large_exp), "123000000000000000000")

    # print("✓ Scientific notation tests passed")


fn test_formatting_variants() raises:
    """Test conversion of strings with various formatting variations."""
    # print("Testing string formatting variants...")

    # Test case 26: Leading zeros with integer
    var leading_zeros_int = Decimal128.from_string("00123")
    testing.assert_equal(String(leading_zeros_int), "123")

    # Test case 27: Trailing zeros after decimal point
    var trailing_zeros = Decimal128.from_string("123.4500")
    testing.assert_equal(String(trailing_zeros), "123.4500")

    # Test case 28: Both leading and trailing zeros
    var both_zeros = Decimal128.from_string("00123.4500")
    testing.assert_equal(String(both_zeros), "123.4500")

    # Test case 29: Decimal128 point with no following digits
    var decimal_no_digits = Decimal128.from_string("123.")
    testing.assert_equal(
        String(decimal_no_digits),
        "123",
        "Decimal128 point with no digits should be ignored",
    )

    # Test case 30: Decimal128 point with no preceding digits
    var decimal_no_preceding = Decimal128.from_string(".123")
    testing.assert_equal(
        String(decimal_no_preceding),
        "0.123",
        "Decimal128 point with no preceding digits should add leading 0",
    )

    # print("✓ Formatting variants tests passed")


fn test_special_characters() raises:
    """Test conversion of strings with special characters."""
    # print("Testing strings with special characters...")

    # Test case 31: Positive sign
    var positive_sign = Decimal128.from_string("+123.45")
    testing.assert_equal(String(positive_sign), "123.45")

    # Test case 32: Positive sign with scientific notation
    var pos_sign_exp = Decimal128.from_string("+1.23e+2")
    testing.assert_equal(String(pos_sign_exp), "123")

    # Test case 33: Negative sign with scientific notation
    var neg_sign_exp = Decimal128.from_string("-1.23e+2")
    testing.assert_equal(String(neg_sign_exp), "-123")

    # Test case 34: Decimal128 with positive exponent
    var decimal_pos_exp = Decimal128.from_string("1.23e+2")
    testing.assert_equal(String(decimal_pos_exp), "123")

    # Test case 35: Scientific notation with multiple digits in exponent
    var multi_digit_exp = Decimal128.from_string("1.23e+12")
    testing.assert_equal(String(multi_digit_exp), "1230000000000")

    # print("✓ Special character tests passed")


fn test_invalid_inputs() raises:
    """Test handling of invalid input strings."""
    # print("Testing invalid input strings...")

    # Test case 36: Empty string
    var exception_caught = False
    try:
        var _empty_string = Decimal128.from_string("")
        testing.assert_equal(True, False, "Empty string should raise exception")
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 37: Non-numeric string
    exception_caught = False
    try:
        var _non_numeric = Decimal128.from_string("abc")
        testing.assert_equal(
            True, False, "Non-numeric string should raise exception"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 38: Multiple decimal points
    exception_caught = False
    try:
        var _multiple_points = Decimal128.from_string("1.2.3")
        testing.assert_equal(
            True, False, "Multiple decimal points should raise exception"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 39: Invalid scientific notation
    exception_caught = False
    try:
        var _invalid_exp = Decimal128.from_string("1.23e")
        testing.assert_equal(
            True, False, "Invalid scientific notation should raise exception"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 40: Mixed digits and characters
    exception_caught = False
    try:
        var _mixed = Decimal128.from_string("123a456")
        testing.assert_equal(
            True, False, "Mixed digits and characters should raise exception"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # print("✓ Invalid input tests passed")


fn test_boundary_cases() raises:
    """Test boundary cases for string conversion."""
    # print("Testing boundary cases...")

    # Test case 41: Value at maximum precision
    var max_precision = Decimal128.from_string("0." + "1" * 28)
    testing.assert_equal(String(max_precision), "0." + "1" * 28)

    # Test case 42: Large integer part
    var large_integer_part = Decimal128.from_string("9" * 28 + ".5")
    testing.assert_equal(String(large_integer_part), "1" + "0" * 28)

    # Test case 43: Single digit maximum
    var single_digit_max = Decimal128.from_string("9")
    testing.assert_equal(String(single_digit_max), "9")

    # Test case 44: Smallest non-zero positive value
    var smallest_positive = Decimal128.from_string("0." + "0" * 27 + "1")
    testing.assert_equal(String(smallest_positive), "0." + "0" * 27 + "1")

    # Test case 45: String representing maximum possible value
    var max_value_str = "79228162514264337593543950335"
    var max_value = Decimal128.from_string(max_value_str)
    testing.assert_equal(String(max_value), max_value_str)

    # print("✓ Boundary case tests passed")


fn test_special_cases() raises:
    """Test special cases for string conversion."""
    # print("Testing special cases...")

    # Test case 46: Very long decimal
    var long_decimal = Decimal128.from_string(
        "0.11111111111111111111111111111111111"
    )
    # Should be truncated to max precision
    testing.assert_true(String(long_decimal).startswith("0.11111111111"))

    # Test case 47: Removing trailing zeros in whole number
    var whole_number = Decimal128.from_string("1230.00")
    testing.assert_equal(
        String(whole_number), "1230.00", "Trailing zeros should be preserved"
    )

    # Test case 48: Value with all 9s
    var all_nines = Decimal128.from_string("9.999999999999999999999999999")
    testing.assert_equal(String(all_nines), "9.999999999999999999999999999")

    # Test case 49: Value with alternating digits
    var alternating = Decimal128.from_string("1.010101010101010101010101010")
    testing.assert_equal(String(alternating), "1.010101010101010101010101010")

    # Test case 50: Value with specific pattern
    var pattern = Decimal128.from_string("123.456789012345678901234567")
    testing.assert_equal(String(pattern), "123.456789012345678901234567")

    # print("✓ Special case tests passed")


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
    # print("Running 50 tests for Decimal128.from_string()")
    # print("=========================================")

    # run_test_with_error_handling(test_basic_integers, "Basic integers test")
    # run_test_with_error_handling(test_basic_decimals, "Basic decimals test")
    # run_test_with_error_handling(test_negative_numbers, "Negative numbers test")
    # run_test_with_error_handling(test_zeros_variants, "Zero variants test")
    # run_test_with_error_handling(
    #     test_scientific_notation, "Scientific notation test"
    # )
    # run_test_with_error_handling(
    #     test_formatting_variants, "Formatting variants test"
    # )
    # run_test_with_error_handling(
    #     test_special_characters, "Special characters test"
    # )
    # run_test_with_error_handling(test_invalid_inputs, "Invalid inputs test")
    # run_test_with_error_handling(test_boundary_cases, "Boundary cases test")
    # run_test_with_error_handling(test_special_cases, "Special cases test")

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All 50 Decimal128.from_string() tests passed!")
