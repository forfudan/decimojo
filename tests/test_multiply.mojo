"""
Comprehensive tests for the multiplication operation of the Decimal type.
"""

import testing
from decimojo.prelude import dm, Decimal, RoundingMode


fn test_basic_multiplication() raises:
    """Test basic integer and decimal multiplication."""
    print("Testing basic multiplication...")

    # Test case 1: Simple integer multiplication
    var a1 = Decimal("5")
    var b1 = Decimal("3")
    var result1 = a1 * b1
    testing.assert_equal(
        String(result1), "15", "5 * 3 should equal 15, got " + String(result1)
    )

    # Test case 2: Simple decimal multiplication
    var a2 = Decimal("2.5")
    var b2 = Decimal("4")
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "10.0",
        "2.5 * 4 should equal 10.0, got " + String(result2),
    )

    # Test case 3: Decimal * decimal
    var a3 = Decimal("1.5")
    var b3 = Decimal("2.5")
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3),
        "3.75",
        "1.5 * 2.5 should equal 3.75, got " + String(result3),
    )

    # Test case 4: Multiplication with more decimal places
    var a4 = Decimal("3.14")
    var b4 = Decimal("2.0")
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4),
        "6.280",
        "3.14 * 2.0 should equal 6.280, got " + String(result4),
    )

    # Test case 5: Multiplication with different decimal places
    var a5 = Decimal("0.125")
    var b5 = Decimal("0.4")
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "0.0500",
        "0.125 * 0.4 should equal 0.0500, got " + String(result5),
    )

    print("✓ Basic multiplication tests passed!")


fn test_special_cases() raises:
    """Test multiplication with special cases like zero and one."""
    print("Testing multiplication with special cases...")

    # Test case 1: Multiplication by zero
    var a1 = Decimal("123.45")
    var zero = Decimal("0")
    var result1 = a1 * zero
    testing.assert_equal(
        String(result1),
        "0.00",
        "123.45 * 0 should equal 0.00, got " + String(result1),
    )

    # Test case 2: Multiplication by one
    var a2 = Decimal("123.45")
    var one = Decimal("1")
    var result2 = a2 * one
    testing.assert_equal(
        String(result2),
        "123.45",
        "123.45 * 1 should equal 123.45, got " + String(result2),
    )

    # Test case 3: Multiplication of zero by any number
    var a3 = Decimal("0")
    var b3 = Decimal("987.654")
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3),
        "0.000",
        "0 * 987.654 should equal 0.000, got " + String(result3),
    )

    # Test case 4: Multiplication by negative one
    var a4 = Decimal("123.45")
    var neg_one = Decimal("-1")
    var result4 = a4 * neg_one
    testing.assert_equal(
        String(result4),
        "-123.45",
        "123.45 * -1 should equal -123.45, got " + String(result4),
    )

    # Test case 5: Multiplication of very small value by one
    var small = Decimal("0." + "0" * 27 + "1")  # Smallest representable
    var result5 = small * one
    testing.assert_equal(
        String(result5),
        String(small),
        "small * 1 should equal small, got " + String(result5),
    )

    print("✓ Special cases multiplication tests passed!")


fn test_negative_multiplication() raises:
    """Test multiplication involving negative numbers."""
    print("Testing multiplication with negative numbers...")

    # Test case 1: Negative * positive
    var a1 = Decimal("-5")
    var b1 = Decimal("3")
    var result1 = a1 * b1
    testing.assert_equal(
        String(result1),
        "-15",
        "-5 * 3 should equal -15, got " + String(result1),
    )

    # Test case 2: Positive * negative
    var a2 = Decimal("5")
    var b2 = Decimal("-3")
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "-15",
        "5 * -3 should equal -15, got " + String(result2),
    )

    # Test case 3: Negative * negative
    var a3 = Decimal("-5")
    var b3 = Decimal("-3")
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3), "15", "-5 * -3 should equal 15, got " + String(result3)
    )

    # Test case 4: Decimal with negative and positive
    var a4 = Decimal("-2.5")
    var b4 = Decimal("4.2")
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4),
        "-10.50",
        "-2.5 * 4.2 should equal -10.50, got " + String(result4),
    )

    # Test case 5: Negative zero (result should be zero)
    var a5 = Decimal("-0")
    var b5 = Decimal("123.45")
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "-0.00",
        "-0 * 123.45 should equal -0.00, got " + String(result5),
    )

    print("✓ Negative number multiplication tests passed!")


fn test_precision_scale() raises:
    """Test multiplication precision and scale handling."""
    print("Testing multiplication precision and scale...")

    # Test case 1: Addition of scales
    var a1 = Decimal("0.5")  # scale 1
    var b1 = Decimal("0.25")  # scale 2
    var result1 = a1 * b1  # scale should be 3
    testing.assert_equal(
        String(result1),
        "0.125",
        "0.5 * 0.25 should equal 0.125 with scale 3, got " + String(result1),
    )
    testing.assert_equal(result1.scale(), 3)

    # Test case 2: High precision
    var a2 = Decimal("0.1234567890")
    var b2 = Decimal("0.9876543210")
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "0.12193263111263526900",
        "High precision multiplication gave incorrect result",
    )
    testing.assert_equal(result2.scale(), 20)

    # Test case 3: Maximum scale edge case
    var a3 = Decimal("0." + "1" * 14)  # scale 14
    var b3 = Decimal("0." + "9" * 14)  # scale 14
    var result3 = a3 * b3  # would be scale 28 (just at the limit)
    testing.assert_equal(result3.scale(), 28, "Scale should be capped at 28")

    # Test case 4: Scale overflow handling (scale > 28)
    var a4 = Decimal("0." + "1" * 15)  # scale 15
    var b4 = Decimal("0." + "9" * 15)  # scale 15
    var result4 = a4 * b4  # would be scale 30, but Decimal.MAX_SCALE is 28
    testing.assert_equal(
        result4.scale(), 28, "Scale should be capped at MAX_SCALE (28)"
    )

    # Test case 5: Rounding during scale adjustment
    var a5 = Decimal("0.123456789012345678901234567")  # scale 27
    var b5 = Decimal("0.2")  # scale 1
    var result5 = a5 * b5  # would be scale 28, but requires rounding
    testing.assert_equal(
        result5.scale(), 28, "Scale should be correctly adjusted with rounding"
    )

    print("✓ Precision and scale tests passed!")


fn test_boundary_cases() raises:
    """Test multiplication with boundary values."""
    print("Testing multiplication with boundary values...")

    # Test case 1: Multiplication near max value
    var near_max = Decimal("38614081257132168796771975168")  # ~half max
    var result1 = near_max * Decimal("1.9")  # Almost 2x max
    testing.assert_true(
        result1 < Decimal.MAX(), "Result should be less than MAX value"
    )

    # Test case 2: Zero scale result with different input scales
    var a2 = Decimal("0.5")
    var b2 = Decimal("2.0")
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "1.00",
        "0.5 * 2.0 should equal 1.00, got " + String(result2),
    )

    # Test case 3: Very different scales
    var tiny = Decimal("0." + "0" * 20 + "1")  # Very small
    var huge = Decimal("1" + "0" * 20)  # Very large
    var result3 = tiny * huge
    testing.assert_equal(
        String(result3),
        "0.100000000000000000000",
        "Extreme scale difference multiplication failed",
    )

    # Test case 4: Multiplication at max value
    var max_dec = Decimal.MAX()
    var one_hundredth = Decimal("0.01")
    var result4 = max_dec * one_hundredth
    testing.assert_equal(
        String(result4),
        String("792281625142643375935439503.35"),
        "MAX * 0.01 calculation incorrect",
    )

    # Test case 5: Result has trailing zeros with integer
    var a5 = Decimal("1.25")
    var b5 = Decimal("4")
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "5.00",
        "1.25 * 4 should equal 5.00 without trailing zeros, got "
        + String(result5),
    )

    print("✓ Boundary cases tests passed!")


fn test_commutative_property() raises:
    """Test the commutative property of multiplication (a*b = b*a)."""
    print("Testing commutative property of multiplication...")

    # Test pair 1: Integers
    var a1 = Decimal("10")
    var b1 = Decimal("20")
    var result1a = a1 * b1
    var result1b = b1 * a1
    testing.assert_equal(
        String(result1a),
        String(result1b),
        "Commutative property failed for " + String(a1) + " and " + String(b1),
    )

    # Test pair 2: Mixed decimal and integer
    var a2 = Decimal("3.5")
    var b2 = Decimal("2")
    var result2a = a2 * b2
    var result2b = b2 * a2
    testing.assert_equal(
        String(result2a),
        String(result2b),
        "Commutative property failed for " + String(a2) + " and " + String(b2),
    )

    # Test pair 3: Negative and positive
    var a3 = Decimal("-5")
    var b3 = Decimal("7")
    var result3a = a3 * b3
    var result3b = b3 * a3
    testing.assert_equal(
        String(result3a),
        String(result3b),
        "Commutative property failed for " + String(a3) + " and " + String(b3),
    )

    # Test pair 4: Small and large decimal
    var a4 = Decimal("0.123")
    var b4 = Decimal("9.87")
    var result4a = a4 * b4
    var result4b = b4 * a4
    testing.assert_equal(
        String(result4a),
        String(result4b),
        "Commutative property failed for " + String(a4) + " and " + String(b4),
    )

    # Test pair 5: Very small and very large
    var a5 = Decimal("0.0001")
    var b5 = Decimal("10000")
    var result5a = a5 * b5
    var result5b = b5 * a5
    testing.assert_equal(
        String(result5a),
        String(result5b),
        "Commutative property failed for " + String(a5) + " and " + String(b5),
    )

    print("✓ Commutative property tests passed!")


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
    print("Running Decimal Multiplication Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_multiplication, "Basic multiplication test"
    )
    run_test_with_error_handling(test_special_cases, "Special cases test")
    run_test_with_error_handling(
        test_negative_multiplication, "Negative number multiplication test"
    )
    run_test_with_error_handling(
        test_precision_scale, "Precision and scale test"
    )
    run_test_with_error_handling(test_boundary_cases, "Boundary cases test")
    run_test_with_error_handling(
        test_commutative_property, "Commutative property test"
    )

    print("All multiplication tests passed!")
