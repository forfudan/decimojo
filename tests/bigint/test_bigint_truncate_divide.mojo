"""
Comprehensive tests for the truncate_divide operation of the BigInt type.
Truncate division divides toward zero (truncates the fractional part).
"""

import testing
from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics


fn test_basic_truncate_division() raises:
    """Test basic truncate division cases with positive numbers."""
    print("Testing basic truncate division...")

    # Test case 1: Division with no remainder
    var a1 = BigInt(10)
    var b1 = BigInt(2)
    var result1 = a1.truncate_divide(b1)
    testing.assert_equal(
        String(result1), "5", "10 / 2 should equal 5, got " + String(result1)
    )

    # Test case 2: Division with remainder (truncate toward zero)
    var a2 = BigInt(10)
    var b2 = BigInt(3)
    var result2 = a2.truncate_divide(b2)
    testing.assert_equal(
        String(result2), "3", "10 / 3 should equal 3, got " + String(result2)
    )

    # Test case 3: Division results in zero (smaller / larger)
    var a3 = BigInt(3)
    var b3 = BigInt(10)
    var result3 = a3.truncate_divide(b3)
    testing.assert_equal(
        String(result3), "0", "3 / 10 should equal 0, got " + String(result3)
    )

    # Test case 4: Division by 1
    var a4 = BigInt(42)
    var b4 = BigInt(1)
    var result4 = a4.truncate_divide(b4)
    testing.assert_equal(
        String(result4), "42", "42 / 1 should equal 42, got " + String(result4)
    )

    # Test case 5: Large number division
    var a5 = BigInt("1000000000000")
    var b5 = BigInt("1000000")
    var result5 = a5.truncate_divide(b5)
    testing.assert_equal(
        String(result5),
        "1000000",
        "1000000000000 / 1000000 should equal 1000000, got " + String(result5),
    )

    print("✓ Basic truncate division tests passed!")


fn test_negative_truncate_division() raises:
    """Test truncate division involving negative numbers."""
    print("Testing truncate division with negative numbers...")

    # Test case 1: Negative dividend, positive divisor (truncate toward zero)
    var a1 = BigInt(-10)
    var b1 = BigInt(3)
    var result1 = a1.truncate_divide(b1)
    testing.assert_equal(
        String(result1), "-3", "-10 / 3 should equal -3, got " + String(result1)
    )

    # Test case 2: Positive dividend, negative divisor (truncate toward zero)
    var a2 = BigInt(10)
    var b2 = BigInt(-3)
    var result2 = a2.truncate_divide(b2)
    testing.assert_equal(
        String(result2), "-3", "10 / -3 should equal -3, got " + String(result2)
    )

    # Test case 3: Negative dividend, negative divisor (truncate toward zero)
    var a3 = BigInt(-10)
    var b3 = BigInt(-3)
    var result3 = a3.truncate_divide(b3)
    testing.assert_equal(
        String(result3), "3", "-10 / -3 should equal 3, got " + String(result3)
    )

    # Test case 4: Exact division with negative numbers
    var a4 = BigInt(-12)
    var b4 = BigInt(-4)
    var result4 = a4.truncate_divide(b4)
    testing.assert_equal(
        String(result4), "3", "-12 / -4 should equal 3, got " + String(result4)
    )

    # Test case 5: Negative number division with remainder
    var a5 = BigInt(-11)
    var b5 = BigInt(4)
    var result5 = a5.truncate_divide(b5)
    testing.assert_equal(
        String(result5), "-2", "-11 / 4 should equal -2, got " + String(result5)
    )

    print("✓ Negative number truncate division tests passed!")


fn test_zero_handling() raises:
    """Test truncate division cases involving zero."""
    print("Testing zero handling in truncate division...")

    # Test case 1: Zero dividend
    var a1 = BigInt(0)
    var b1 = BigInt(5)
    var result1 = a1.truncate_divide(b1)
    testing.assert_equal(
        String(result1), "0", "0 / 5 should equal 0, got " + String(result1)
    )

    # Test case 2: Zero dividend with negative divisor
    var a2 = BigInt(0)
    var b2 = BigInt(-5)
    var result2 = a2.truncate_divide(b2)
    testing.assert_equal(
        String(result2), "0", "0 / -5 should equal 0, got " + String(result2)
    )

    # Test case 3: Division by zero should raise an error
    var a3 = BigInt(10)
    var b3 = BigInt(0)
    var exception_caught = False
    try:
        var _result3 = a3.truncate_divide(b3)
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )

    print("✓ Zero handling tests passed!")


fn test_large_number_division() raises:
    """Test truncate division with very large numbers."""
    print("Testing truncate division with large numbers...")

    # Test case 1: Large number divided by small number
    var a1 = BigInt("1" + "0" * 50)  # 10^50
    var b1 = BigInt(7)
    var expected1 = BigInt(
        "14285714285714285714285714285714285714285714285714"
    )  # 10^50 / 7 = 14285714285714285714285714...
    var result1 = a1.truncate_divide(b1)
    testing.assert_equal(
        String(result1),
        String(expected1),
        "Large number division gave incorrect result",
    )

    # Test case 2: Large number divided by large number
    var a2 = BigInt("9" * 30)  # 30 nines
    var b2 = BigInt("9" * 15)  # 15 nines
    var expected2 = BigInt("1" + "0" * 14 + "1")  # 10^15 + 1
    var result2 = a2.truncate_divide(b2)
    testing.assert_equal(
        String(result2),
        String(expected2),
        "Large / large division gave incorrect result",
    )

    # Test case 3: Very large number divisible by power of 10
    var a3 = BigInt("1" + "0" * 100)  # 10^100
    var b3 = BigInt("1" + "0" * 40)  # 10^40
    var expected3 = BigInt("1" + "0" * 60)  # 10^60
    var result3 = a3.truncate_divide(b3)
    testing.assert_equal(
        String(result3),
        String(expected3),
        "Power of 10 division gave incorrect result",
    )

    # Test case 4: Large number with large divisor resulting in small quotient
    var a4 = BigInt("9" * 50)  # 50 nines
    var b4 = BigInt("3" * 49 + "4")  # slightly less than a third of a4
    var result4 = a4.truncate_divide(b4)
    testing.assert_equal(
        String(result4),
        "2",
        (
            "Large numbers division resulting in small quotient gave incorrect"
            " result"
        ),
    )

    print("✓ Large number division tests passed!")


fn test_division_rounding() raises:
    """Test that truncate division correctly truncates toward zero."""
    print("Testing truncate division rounding behavior...")

    # Positive / Positive - should truncate toward zero

    # Test case 1: 7/2 = 3.5 -> 3
    var a1 = BigInt(7)
    var b1 = BigInt(2)
    var expected1 = BigInt(3)
    var result1 = a1.truncate_divide(b1)
    testing.assert_equal(
        String(result1),
        String(expected1),
        "7 / 2 should equal 3, got " + String(result1),
    )

    # Test case 2: 1/3 = 0.333... -> 0
    var a2 = BigInt(1)
    var b2 = BigInt(3)
    var expected2 = BigInt(0)
    var result2 = a2.truncate_divide(b2)
    testing.assert_equal(
        String(result2),
        String(expected2),
        "1 / 3 should equal 0, got " + String(result2),
    )

    # Test case 3: 5/4 = 1.25 -> 1
    var a3 = BigInt(5)
    var b3 = BigInt(4)
    var expected3 = BigInt(1)
    var result3 = a3.truncate_divide(b3)
    testing.assert_equal(
        String(result3),
        String(expected3),
        "5 / 4 should equal 1, got " + String(result3),
    )

    # Test case 4: 99/100 = 0.99 -> 0
    var a4 = BigInt(99)
    var b4 = BigInt(100)
    var expected4 = BigInt(0)
    var result4 = a4.truncate_divide(b4)
    testing.assert_equal(
        String(result4),
        String(expected4),
        "99 / 100 should equal 0, got " + String(result4),
    )

    # Negative / Positive - should truncate toward zero

    # Test case 5: -7/2 = -3.5 -> -3
    var a5 = BigInt(-7)
    var b5 = BigInt(2)
    var expected5 = BigInt(-3)
    var result5 = a5.truncate_divide(b5)
    testing.assert_equal(
        String(result5),
        String(expected5),
        "-7 / 2 should equal -3, got " + String(result5),
    )

    # Test case 6: -1/3 = -0.333... -> 0
    var a6 = BigInt(-1)
    var b6 = BigInt(3)
    var expected6 = BigInt(0)
    var result6 = a6.truncate_divide(b6)
    testing.assert_equal(
        String(result6),
        String(expected6),
        "-1 / 3 should equal 0, got " + String(result6),
    )

    # Test case 7: -5/4 = -1.25 -> -1
    var a7 = BigInt(-5)
    var b7 = BigInt(4)
    var expected7 = BigInt(-1)
    var result7 = a7.truncate_divide(b7)
    testing.assert_equal(
        String(result7),
        String(expected7),
        "-5 / 4 should equal -1, got " + String(result7),
    )

    # Test case 8: -99/100 = -0.99 -> 0
    var a8 = BigInt(-99)
    var b8 = BigInt(100)
    var expected8 = BigInt(0)
    var result8 = a8.truncate_divide(b8)
    testing.assert_equal(
        String(result8),
        String(expected8),
        "-99 / 100 should equal 0, got " + String(result8),
    )

    # Positive / Negative - should truncate toward zero

    # Test case 9: 7/-2 = -3.5 -> -3
    var a9 = BigInt(7)
    var b9 = BigInt(-2)
    var expected9 = BigInt(-3)
    var result9 = a9.truncate_divide(b9)
    testing.assert_equal(
        String(result9),
        String(expected9),
        "7 / -2 should equal -3, got " + String(result9),
    )

    # Test case 10: 1/-3 = -0.333... -> 0
    var a10 = BigInt(1)
    var b10 = BigInt(-3)
    var expected10 = BigInt(0)
    var result10 = a10.truncate_divide(b10)
    testing.assert_equal(
        String(result10),
        String(expected10),
        "1 / -3 should equal 0, got " + String(result10),
    )

    # Negative / Negative - should truncate toward zero

    # Test case 11: -7/-2 = 3.5 -> 3
    var a11 = BigInt(-7)
    var b11 = BigInt(-2)
    var expected11 = BigInt(3)
    var result11 = a11.truncate_divide(b11)
    testing.assert_equal(
        String(result11),
        String(expected11),
        "-7 / -2 should equal 3, got " + String(result11),
    )

    # Test case 12: -99/-100 = 0.99 -> 0
    var a12 = BigInt(-99)
    var b12 = BigInt(-100)
    var expected12 = BigInt(0)
    var result12 = a12.truncate_divide(b12)
    testing.assert_equal(
        String(result12),
        String(expected12),
        "-99 / -100 should equal 0, got " + String(result12),
    )

    print("✓ Division rounding tests passed!")


fn test_division_identity() raises:
    """Test mathematical properties of truncate division."""
    print("Testing mathematical properties of truncate division...")

    # Test property: (a / b) * b + (a % b) = a
    var a1 = BigInt(17)
    var b1 = BigInt(5)
    var quotient1 = a1.truncate_divide(b1)  # 3
    var remainder1 = a1.truncate_modulo(b1)  # 2
    var reconstructed1 = quotient1 * b1 + remainder1  # 3*5 + 2 = 17
    testing.assert_equal(
        String(reconstructed1),
        String(a1),
        "(a / b) * b + (a % b) should equal a for positive numbers",
    )

    # Same test with negative dividend
    var a2 = BigInt(-17)
    var b2 = BigInt(5)
    var quotient2 = a2.truncate_divide(b2)  # -3
    var remainder2 = a2.truncate_modulo(b2)  # -2
    var reconstructed2 = quotient2 * b2 + remainder2  # -3*5 + (-2) = -17
    testing.assert_equal(
        String(reconstructed2),
        String(a2),
        "(a / b) * b + (a % b) should equal a for negative dividend",
    )

    # Same test with negative divisor
    var a3 = BigInt(17)
    var b3 = BigInt(-5)
    var quotient3 = a3.truncate_divide(b3)  # -3
    var remainder3 = a3.truncate_modulo(b3)  # 2
    var reconstructed3 = quotient3 * b3 + remainder3  # -3*(-5) + 2 = 17
    testing.assert_equal(
        String(reconstructed3),
        String(a3),
        "(a / b) * b + (a % b) should equal a for negative divisor",
    )

    # Same test with both negative
    var a4 = BigInt(-17)
    var b4 = BigInt(-5)
    var quotient4 = a4.truncate_divide(b4)  # 3
    var remainder4 = a4.truncate_modulo(b4)  # -2
    var reconstructed4 = quotient4 * b4 + remainder4  # 3*(-5) + (-2) = -17
    testing.assert_equal(
        String(reconstructed4),
        String(a4),
        "(a / b) * b + (a % b) should equal a for both negative",
    )

    print("✓ Mathematical identity tests passed!")


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
    print("Running BigInt Truncate Division Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_truncate_division, "Basic truncate division test"
    )
    run_test_with_error_handling(
        test_negative_truncate_division,
        "Negative number truncate division test",
    )
    run_test_with_error_handling(test_zero_handling, "Zero handling test")
    run_test_with_error_handling(
        test_large_number_division, "Large number division test"
    )
    run_test_with_error_handling(
        test_division_rounding, "Division rounding behavior test"
    )
    run_test_with_error_handling(
        test_division_identity, "Mathematical identity test"
    )

    print("All BigInt truncate division tests passed!")
