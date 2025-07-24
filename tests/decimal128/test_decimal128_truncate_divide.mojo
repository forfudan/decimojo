"""
Comprehensive tests for the floor division (//) operation of the Decimal128 type.
Tests various scenarios to ensure proper integer division behavior.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_floor_division() raises:
    """Test basic integer floor division."""
    print("Testing basic floor division...")

    # Test case 1: Simple integer division with no remainder
    var a1 = Decimal128(10)
    var b1 = Decimal128(2)
    var result1 = a1 // b1
    testing.assert_equal(
        String(result1), "5", "10 // 2 should equal 5, got " + String(result1)
    )

    # Test case 2: Simple integer division with remainder
    var a2 = Decimal128(10)
    var b2 = Decimal128(3)
    var result2 = a2 // b2
    testing.assert_equal(
        String(result2), "3", "10 // 3 should equal 3, got " + String(result2)
    )

    # Test case 3: Division with decimal values
    var a3 = Decimal128("10.5")
    var b3 = Decimal128("2.5")
    var result3 = a3 // b3
    testing.assert_equal(
        String(result3),
        "4",
        "10.5 // 2.5 should equal 4, got " + String(result3),
    )

    # Test case 4: Division resulting in a decimal value
    var a4 = Decimal128(5)
    var b4 = Decimal128(2)
    var result4 = a4 // b4
    testing.assert_equal(
        String(result4), "2", "5 // 2 should equal 2, got " + String(result4)
    )

    # Test case 5: Division with different decimal places
    var a5 = Decimal128("10.75")
    var b5 = Decimal128("1.5")
    var result5 = a5 // b5
    testing.assert_equal(
        String(result5),
        "7",
        "10.75 // 1.5 should equal 7, got " + String(result5),
    )

    print("✓ Basic floor division tests passed!")


fn test_negative_floor_division() raises:
    """Test floor division involving negative numbers."""
    print("Testing floor division with negative numbers...")

    # Test case 1: Negative // Positive
    var a1 = Decimal128(-10)
    var b1 = Decimal128(3)
    var result1 = a1 // b1
    testing.assert_equal(
        String(result1),
        "-3",
        "-10 // 3 should equal -3, got " + String(result1),
    )

    # Test case 2: Positive // Negative
    var a2 = Decimal128(10)
    var b2 = Decimal128(-3)
    var result2 = a2 // b2
    testing.assert_equal(
        String(result2),
        "-3",
        "10 // -3 should equal -3, got " + String(result2),
    )

    # Test case 3: Negative // Negative
    var a3 = Decimal128(-10)
    var b3 = Decimal128(-3)
    var result3 = a3 // b3
    testing.assert_equal(
        String(result3), "3", "-10 // -3 should equal 3, got " + String(result3)
    )

    # Test case 4: Decimal128 values, Negative // Positive
    var a4 = Decimal128("-10.5")
    var b4 = Decimal128("3.5")
    var result4 = a4 // b4
    testing.assert_equal(
        String(result4),
        "-3",
        "-10.5 // 3.5 should equal -3, got " + String(result4),
    )

    # Test case 5: Decimal128 values, Positive // Negative
    var a5 = Decimal128("10.5")
    var b5 = Decimal128("-3.5")
    var result5 = a5 // b5
    testing.assert_equal(
        String(result5),
        "-3",
        "10.5 // -3.5 should equal -3, got " + String(result5),
    )

    # Test case 6: Decimal128 values, Negative // Negative
    var a6 = Decimal128("-10.5")
    var b6 = Decimal128("-3.5")
    var result6 = a6 // b6
    testing.assert_equal(
        String(result6),
        "3",
        "-10.5 // -3.5 should equal 3, got " + String(result6),
    )

    print("✓ Negative number floor division tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for floor division."""
    print("Testing floor division edge cases...")

    # Test case 1: Division by 1
    var a1 = Decimal128(10)
    var b1 = Decimal128(1)
    var result1 = a1 // b1
    testing.assert_equal(
        String(result1), "10", "10 // 1 should equal 10, got " + String(result1)
    )

    # Test case 2: Zero dividend
    var a2 = Decimal128(0)
    var b2 = Decimal128(5)
    var result2 = a2 // b2
    testing.assert_equal(
        String(result2), "0", "0 // 5 should equal 0, got " + String(result2)
    )

    # Test case 3: Division by a decimal < 1
    var a3 = Decimal128(10)
    var b3 = Decimal128("0.5")
    var result3 = a3 // b3
    testing.assert_equal(
        String(result3),
        "20",
        "10 // 0.5 should equal 20, got " + String(result3),
    )

    # Test case 4: Division resulting in a negative zero (should be 0)
    var a4 = Decimal128(0)
    var b4 = Decimal128(-5)
    var result4 = a4 // b4
    testing.assert_equal(
        String(result4), "0", "0 // -5 should equal 0, got " + String(result4)
    )

    # Test case 5: Division by zero (should raise error)
    var a5 = Decimal128(10)
    var b5 = Decimal128(0)
    var exception_caught = False
    try:
        var _result5 = a5 // b5
        testing.assert_equal(True, False, "Division by zero should raise error")
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "Division by zero should raise error"
    )

    # Test case 6: Large number division
    var a6 = Decimal128("1000000000")
    var b6 = Decimal128("7")
    var result6 = a6 // b6
    testing.assert_equal(
        String(result6), "142857142", "1000000000 // 7 calculated incorrectly"
    )

    # Test case 7: Small number division
    var a7 = Decimal128("0.0000001")
    var b7 = Decimal128("0.0000002")
    var result7 = a7 // b7
    testing.assert_equal(
        String(result7), "0", "0.0000001 // 0.0000002 should equal 0"
    )

    print("✓ Edge cases tests passed!")


fn test_mathematical_relationships() raises:
    """Test mathematical relationships involving floor division."""
    print("Testing mathematical relationships...")

    # Test case 1: a = (a // b) * b + (a % b)
    var a1 = Decimal128(10)
    var b1 = Decimal128(3)
    var floor_div = a1 // b1
    var mod_result = a1 % b1
    var reconstructed = floor_div * b1 + mod_result
    testing.assert_equal(
        String(reconstructed),
        String(a1),
        "a should equal (a // b) * b + (a % b)",
    )

    # Test case 2: a // b = floor(a / b)
    var a2 = Decimal128("10.5")
    var b2 = Decimal128("2.5")
    var floor_div2 = a2 // b2
    var div_floored = (a2 / b2).round(0, RoundingMode.ROUND_DOWN)
    testing.assert_equal(
        String(floor_div2),
        String(div_floored),
        "a // b should equal floor(a / b)",
    )

    # Test case 3: Relationship with negative values
    var a3 = Decimal128(-10)
    var b3 = Decimal128(3)
    var floor_div3 = a3 // b3
    var mod_result3 = a3 % b3
    var reconstructed3 = floor_div3 * b3 + mod_result3
    testing.assert_equal(
        String(reconstructed3),
        String(a3),
        "a should equal (a // b) * b + (a % b) with negative values",
    )

    # Test case 4: (a // b) * b ≤ a < (a // b + 1) * b
    var a4 = Decimal128("10.5")
    var b4 = Decimal128("3.2")
    var floor_div4 = a4 // b4
    var lower_bound = floor_div4 * b4
    var upper_bound = (floor_div4 + Decimal128(1)) * b4
    testing.assert_true(
        (lower_bound <= a4) and (a4 < upper_bound),
        "Relationship (a // b) * b ≤ a < (a // b + 1) * b should hold",
    )

    print("✓ Mathematical relationships tests passed!")


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
    print("Running Decimal128 Floor Division Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_floor_division, "Basic floor division test"
    )
    run_test_with_error_handling(
        test_negative_floor_division, "Negative number floor division test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")
    run_test_with_error_handling(
        test_mathematical_relationships, "Mathematical relationships test"
    )

    print("All floor division tests passed!")
