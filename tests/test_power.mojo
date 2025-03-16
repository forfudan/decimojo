"""
Comprehensive tests for the power function of the Decimal type.
"""

import testing
from decimojo.prelude import dm, Decimal, RoundingMode
from decimojo.exponential import power


fn test_integer_powers() raises:
    """Test raising a Decimal to an integer power."""
    print("Testing integer powers...")

    # Test case 1: Positive base, positive exponent
    var base1 = Decimal("2")
    var exponent1 = 3
    var result1 = power(base1, exponent1)
    testing.assert_equal(
        String(result1), "8", "2^3 should be 8, got " + String(result1)
    )

    # Test case 2: Positive base, zero exponent
    var base2 = Decimal("5")
    var exponent2 = 0
    var result2 = power(base2, exponent2)
    testing.assert_equal(
        String(result2), "1", "5^0 should be 1, got " + String(result2)
    )

    # Test case 3: Positive base, negative exponent
    var base3 = Decimal("2")
    var exponent3 = -2
    var result3 = power(base3, exponent3)
    testing.assert_equal(
        String(result3), "0.25", "2^-2 should be 0.25, got " + String(result3)
    )

    # Test case 4: Decimal base, positive exponent
    var base4 = Decimal("2.5")
    var exponent4 = 2
    var result4 = power(base4, exponent4)
    testing.assert_equal(
        String(result4), "6.25", "2.5^2 should be 6.25, got " + String(result4)
    )

    # Test case 5: Decimal base, negative exponent
    var base5 = Decimal("0.5")
    var exponent5 = -1
    var result5 = power(base5, exponent5)
    testing.assert_equal(
        String(result5), "2", "0.5^-1 should be 2, got " + String(result5)
    )

    print("✓ Integer powers tests passed!")


fn test_decimal_powers() raises:
    """Test raising a Decimal to a Decimal power."""
    print("Testing decimal powers...")

    # Test case 1: Positive base, simple fractional exponent (0.5)
    var base1 = Decimal("9")
    var exponent1 = Decimal("0.5")
    var result1 = power(base1, exponent1)
    testing.assert_equal(
        String(result1), "3", "9^0.5 should be 3, got " + String(result1)
    )

    # Test case 2: Positive base, more complex fractional exponent
    var base2 = Decimal("2")
    var exponent2 = Decimal("1.5")
    var result2 = power(base2, exponent2)
    testing.assert_true(
        String(result2).startswith("2.828427124746190097603377448"),
        "2^1.5 should be approximately 2.828..., got " + String(result2),
    )

    # Test case 3: Decimal base, decimal exponent
    var base3 = Decimal("2.5")
    var exponent3 = Decimal("0.5")
    var result3 = power(base3, exponent3)
    testing.assert_true(
        String(result3).startswith("1.5811388300841896659994467722"),
        "2.5^0.5 should be approximately 1.5811388300841896659994467722...,"
        " got "
        + String(result3),
    )

    # Test case 4: Base > 1, exponent < 0
    var base4 = Decimal("4")
    var exponent4 = Decimal("-0.5")
    var result4 = power(base4, exponent4)
    testing.assert_equal(
        String(result4), "0.5", "4^-0.5 should be 0.5, got " + String(result4)
    )

    print("✓ Decimal powers tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for the power function."""
    print("Testing power edge cases...")

    # Test case 1: Zero base, positive exponent
    var base1 = Decimal("0")
    var exponent1 = Decimal("2")
    var result1 = power(base1, exponent1)
    testing.assert_equal(
        String(result1), "0", "0^2 should be 0, got " + String(result1)
    )

    # Test case 2: Zero base, negative exponent (should raise error)
    var base2 = Decimal("0")
    var exponent2 = Decimal("-2")
    var exception_caught = False
    try:
        var _result = power(base2, exponent2)
        testing.assert_equal(
            True, False, "0^-2 should raise an exception, but it didn't"
        )
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "0^-2 should raise an exception"
    )

    # Test case 3: Negative base, integer exponent
    var base3 = Decimal("-2")
    var exponent3 = Decimal("3")
    var result3 = power(base3, exponent3)
    testing.assert_equal(
        String(result3), "-8", "(-2)^3 should be -8, got " + String(result3)
    )

    # Test case 4: Negative base, non-integer exponent (should raise error)
    var base4 = Decimal("-2")
    var exponent4 = Decimal("0.5")
    exception_caught = False
    try:
        var _result2 = power(base4, exponent4)
        testing.assert_equal(
            True, False, "(-2)^0.5 should raise an exception, but it didn't"
        )
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "(-2)^0.5 should raise an exception"
    )

    print("✓ Edge cases tests passed!")


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
    print("Running Decimal Power Function Tests")
    print("=========================================")

    run_test_with_error_handling(test_integer_powers, "Integer powers test")
    run_test_with_error_handling(test_decimal_powers, "Decimal powers test")
    run_test_with_error_handling(test_edge_cases, "Edge cases test")

    print("All power function tests passed!")
