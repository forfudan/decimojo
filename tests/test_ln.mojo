"""
Comprehensive tests for the ln() function in the DeciMojo library.
Tests various cases including basic values, mathematical identities,
and edge cases to ensure proper calculation of the natural logarithm.
"""

import testing
from decimojo.prelude import dm, Decimal, RoundingMode
from decimojo.exponential import ln


fn test_basic_ln_values() raises:
    """Test basic natural logarithm values."""
    print("Testing basic natural logarithm values...")

    # Test case 1: ln(1) = 0
    var one = Decimal("1")
    var result1 = ln(one)
    testing.assert_equal(
        String(result1), "0", "ln(1) should be 0, got " + String(result1)
    )

    # Test case 2: ln(e) = 1
    var e = Decimal("2.718281828459045235360287471")
    var result_e = ln(e)
    testing.assert_true(
        String(result_e).startswith("1.00000000000000000000"),
        "ln(e) should be approximately 1, got " + String(result_e),
    )

    # Test case 3: ln(10)
    var ten = Decimal("10")
    var result_ten = ln(ten)
    testing.assert_true(
        String(result_ten).startswith("2.30258509299404568401799145"),
        "ln(10) should be approximately 2.302..., got " + String(result_ten),
    )

    # Test case 4: ln(0.1)
    var tenth = Decimal("0.1")
    var result_tenth = ln(tenth)
    testing.assert_true(
        String(result_tenth).startswith("-2.3025850929940456"),
        "ln(0.1) should be approximately -2.3025850929940456..., got "
        + String(result_tenth),
    )

    print("✓ Basic natural logarithm values tests passed!")


fn test_fractional_ln_values() raises:
    """Test natural logarithm values with fractional inputs."""
    print("Testing natural logarithm values with fractional inputs...")

    # Test case 5: ln(0.5)
    var half = Decimal("0.5")
    var result_half = ln(half)
    testing.assert_true(
        String(result_half).startswith("-0.693147180559945309417232121"),
        "ln(0.5) should be approximately -0.693..., got " + String(result_half),
    )

    # Test case 6: ln(2)
    var two = Decimal("2")
    var result_two = ln(two)
    testing.assert_true(
        String(result_two).startswith("0.693147180559945309417232121"),
        "ln(2) should be approximately 0.693..., got " + String(result_two),
    )

    # Test case 7: ln(5)
    var five = Decimal("5")
    var result_five = ln(five)
    testing.assert_true(
        String(result_five).startswith("1.609437912434100374600759333"),
        "ln(5) should be approximately 1.609..., got " + String(result_five),
    )

    print("✓ Fractional natural logarithm values tests passed!")


fn test_mathematical_identities() raises:
    """Test mathematical identities related to the natural logarithm."""
    print("Testing mathematical identities for natural logarithm...")

    # Test case 8: ln(a * b) = ln(a) + ln(b)
    var a = Decimal("2")
    var b = Decimal("3")
    var ln_a_times_b = ln(a * b)
    var ln_a_plus_ln_b = ln(a) + ln(b)
    testing.assert_true(
        abs(ln_a_times_b - ln_a_plus_ln_b) < Decimal("0.0000000001"),
        "ln(a * b) should equal ln(a) + ln(b) within tolerance",
    )

    # Test case 9: ln(a / b) = ln(a) - ln(b)
    var ln_a_div_b = ln(a / b)
    var ln_a_minus_ln_b = ln(a) - ln(b)
    testing.assert_true(
        abs(ln_a_div_b - ln_a_minus_ln_b) < Decimal("0.0000000001"),
        "ln(a / b) should equal ln(a) - ln(b) within tolerance",
    )

    # Test case 10: ln(e^x) = x
    var x = Decimal("5")
    var ln_e_to_x = ln(dm.exponential.exp(x))
    testing.assert_true(
        abs(ln_e_to_x - x) < Decimal("0.0000000001"),
        "ln(e^x) should equal x within tolerance",
    )

    print("✓ Mathematical identities tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for natural logarithm function."""
    print("Testing edge cases for natural logarithm function...")

    # Test case 11: ln(0) should raise an exception
    var zero = Decimal("0")
    var exception_caught = False
    try:
        var _ln0 = ln(zero)
        testing.assert_equal(True, False, "ln(0) should raise an exception")
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 12: ln of a negative number should raise an exception
    var neg_one = Decimal("-1")
    exception_caught = False
    try:
        var _ln = ln(neg_one)
        testing.assert_equal(
            True, False, "ln of a negative number should raise an exception"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 13: ln of a very small number
    var very_small = Decimal("0.000000000000000000000000001")
    var result_small = ln(very_small)
    testing.assert_true(
        String(result_small).startswith("-62.1697"),
        "ln of a very small number should be -62.1697..., but got {}".format(
            result_small
        ),
    )

    # Test case 14: ln of a very large number
    var very_large = Decimal("10000000000000000000000000000")
    var result_large = ln(very_large)
    testing.assert_true(
        String(result_large).startswith("64.4723"),
        "ln of a very large number should be 64.4723..., but got {}".format(
            result_large
        ),
    )

    print("✓ Edge cases tests passed!")


fn test_precision() raises:
    """Test precision of natural logarithm calculations."""
    print("Testing precision of natural logarithm calculations...")

    # Test case 15: ln(2) with high precision
    var two = Decimal("2")
    var result_two = ln(two)
    testing.assert_true(
        String(result_two).startswith("0.693147180559945309417232121"),
        "ln(2) with high precision should be accurate",
    )

    # Test case 16: ln(10) with high precision
    var ten = Decimal("10")
    var result_ten = ln(ten)
    testing.assert_true(
        String(result_ten).startswith("2.30258509299404568401"),
        "ln(10) with high precision should be 2.30258509299404568401..., but"
        " got {}".format(result_ten),
    )

    print("✓ Precision tests passed!")


fn test_range_of_values() raises:
    """Test natural logarithm function across a range of values."""
    print("Testing natural logarithm function across a range of values...")

    # Test case 17: ln(x) for x in range (3, 10)
    testing.assert_true(
        Decimal(3).ln() > Decimal(0), "ln(x) should be positive for x > 2"
    )
    testing.assert_true(
        Decimal(10).ln() > Decimal(2),
        "ln(x) should be greater than x for x > 2",
    )

    # Test case 18: ln(x) for x in range (0.1, 1, 0.1)

    testing.assert_true(
        Decimal("0.1").ln() < Decimal(0), "ln(x) should be negative for x < 1"
    )
    testing.assert_true(
        Decimal("0.9").ln() < Decimal(0), "ln(x) should be negative for x < 1"
    )

    print("✓ Range of values tests passed!")


fn test_special_cases() raises:
    """Test special cases for natural logarithm function."""
    print("Testing special cases for natural logarithm function...")

    # Test case 19: ln(1) = 0 (revisited)
    var one = Decimal("1")
    var result_one = ln(one)
    testing.assert_equal(String(result_one), "0", "ln(1) should be exactly 0")

    # Test case 20: ln(e) close to 1
    var e = Decimal("2.718281828459045235360287471")
    var result_e = ln(e)
    testing.assert_true(
        abs(result_e - Decimal("1")) < Decimal("0.0000000001"),
        "ln(e) should be very close to 1",
    )

    print("✓ Special cases tests passed!")


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
    print("Running Natural Logarithm Function Tests")
    print("=========================================")

    run_test_with_error_handling(test_basic_ln_values, "Basic ln values test")
    run_test_with_error_handling(
        test_fractional_ln_values, "Fractional ln values test"
    )
    run_test_with_error_handling(
        test_mathematical_identities, "Mathematical identities test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")
    run_test_with_error_handling(test_precision, "Precision test")
    run_test_with_error_handling(test_range_of_values, "Range of values test")
    run_test_with_error_handling(test_special_cases, "Special cases test")

    print("All natural logarithm function tests passed!")
