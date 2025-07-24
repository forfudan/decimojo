"""
Comprehensive tests for the modulo (%) operation of the Decimal128 type.
Tests various scenarios to ensure proper remainder calculation behavior.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_modulo() raises:
    """Test basic modulo operations with positive integers."""
    print("Testing basic modulo operations...")

    # Test case 1: Simple modulo with remainder
    var a1 = Decimal128(10)
    var b1 = Decimal128(3)
    var result1 = a1 % b1
    testing.assert_equal(
        String(result1), "1", "10 % 3 should equal 1, got " + String(result1)
    )

    # Test case 2: Modulo with no remainder
    var a2 = Decimal128(10)
    var b2 = Decimal128(5)
    var result2 = a2 % b2
    testing.assert_equal(
        String(result2), "0", "10 % 5 should equal 0, got " + String(result2)
    )

    # Test case 3: Modulo with decimal values
    var a3 = Decimal128("10.5")
    var b3 = Decimal128("3.5")
    var result3 = a3 % b3
    testing.assert_equal(
        String(result3),
        "0.0",
        "10.5 % 3.5 should equal 0.0, got " + String(result3),
    )

    # Test case 4: Modulo with different decimal places
    var a4 = Decimal128("10.75")
    var b4 = Decimal128("2.5")
    var result4 = a4 % b4
    testing.assert_equal(
        String(result4),
        "0.75",
        "10.75 % 2.5 should equal 0.75, got " + String(result4),
    )

    # Test case 5: Modulo with modulus > dividend
    var a5 = Decimal128(3)
    var b5 = Decimal128(10)
    var result5 = a5 % b5
    testing.assert_equal(
        String(result5), "3", "3 % 10 should equal 3, got " + String(result5)
    )

    print("✓ Basic modulo operations tests passed!")


fn test_negative_modulo() raises:
    """Test modulo operations involving negative numbers."""
    print("Testing modulo with negative numbers...")

    # Test case 1: Negative dividend, positive divisor
    var a1 = Decimal128(-10)
    var b1 = Decimal128(3)
    var result1 = a1 % b1
    testing.assert_equal(
        String(result1), "-1", "-10 % 3 should equal -1, got " + String(result1)
    )

    # Test case 2: Positive dividend, negative divisor
    var a2 = Decimal128(10)
    var b2 = Decimal128(-3)
    var result2 = a2 % b2
    testing.assert_equal(
        String(result2), "1", "10 % -3 should equal 1, got " + String(result2)
    )

    # Test case 3: Negative dividend, negative divisor
    var a3 = Decimal128(-10)
    var b3 = Decimal128(-3)
    var result3 = a3 % b3
    testing.assert_equal(
        String(result3),
        "-1",
        "-10 % -3 should equal -1, got " + String(result3),
    )

    # Test case 4: Decimal128 values, Negative dividend, positive divisor
    var a4 = Decimal128("-10.5")
    var b4 = Decimal128("3.5")
    var result4 = a4 % b4
    testing.assert_equal(
        String(result4),
        "0.0",
        "-10.5 % 3.5 should equal 0.0, got " + String(result4),
    )

    # Test case 5: Decimal128 values with remainder, Negative dividend, positive divisor
    var a5 = Decimal128("-10.5")
    var b5 = Decimal128("3")
    var result5 = a5 % b5
    testing.assert_equal(
        String(result5),
        "-1.5",
        "-10.5 % 3 should equal -1.5, got " + String(result5),
    )

    # Test case 6: Decimal128 values with remainder, Positive dividend, negative divisor
    var a6 = Decimal128("10.5")
    var b6 = Decimal128("-3")
    var result6 = a6 % b6
    testing.assert_equal(
        String(result6),
        "1.5",
        "10.5 % -3 should equal 1.5, got " + String(result6),
    )

    print("✓ Negative number modulo tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for modulo operation."""
    print("Testing modulo edge cases...")

    # Test case 1: Modulo by 1
    var a1 = Decimal128(10)
    var b1 = Decimal128(1)
    var result1 = a1 % b1
    testing.assert_equal(
        String(result1), "0", "10 % 1 should equal 0, got " + String(result1)
    )

    # Test case 2: Zero dividend
    var a2 = Decimal128(0)
    var b2 = Decimal128(5)
    var result2 = a2 % b2
    testing.assert_equal(
        String(result2), "0", "0 % 5 should equal 0, got " + String(result2)
    )

    # Test case 3: Modulo with a decimal < 1
    var a3 = Decimal128(10)
    var b3 = Decimal128("0.3")
    var result3 = a3 % b3
    testing.assert_equal(
        String(result3),
        "0.1",
        "10 % 0.3 should equal 0.1, got " + String(result3),
    )

    # Test case 4: Modulo by zero (should raise error)
    var a4 = Decimal128(10)
    var b4 = Decimal128(0)
    var exception_caught = False
    try:
        var _result4 = a4 % b4
        testing.assert_equal(True, False, "Modulo by zero should raise error")
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "Modulo by zero should raise error"
    )

    # Test case 5: Large number modulo
    var a5 = Decimal128("1000000007")
    var b5 = Decimal128("13")
    var result5 = a5 % b5
    testing.assert_equal(
        String(result5), "6", "1000000007 % 13 calculated incorrectly"
    )

    # Test case 6: Small number modulo
    var a6 = Decimal128("0.0000023")
    var b6 = Decimal128("0.0000007")
    var result6 = a6 % b6
    testing.assert_equal(
        String(result6),
        "0.0000002",
        "0.0000023 % 0.0000007 calculated incorrectly",
    )

    # Test case 7: Equal values
    var a7 = Decimal128("7.5")
    var b7 = Decimal128("7.5")
    var result7 = a7 % b7
    testing.assert_equal(
        String(result7),
        "0.0",
        "7.5 % 7.5 should equal 0.0, got " + String(result7),
    )

    print("✓ Edge cases tests passed!")


fn test_mathematical_relationships() raises:
    """Test mathematical relationships involving modulo."""
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

    # Test case 2: 0 <= (a % b) < b for positive b
    var a2 = Decimal128("10.5")
    var b2 = Decimal128("3.2")
    var mod_result2 = a2 % b2
    testing.assert_true(
        (mod_result2 >= Decimal128(0)) and (mod_result2 < b2),
        "For positive b, 0 <= (a % b) < b should hold",
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

    # Test case 4: a % b for negative b
    var a4 = Decimal128("10.5")
    var b4 = Decimal128("-3.2")
    var mod_result4 = a4 % b4
    testing.assert_true(
        mod_result4 == Decimal128("0.9"),
        "10.5 % -3.2 should equal 0.9, got " + String(mod_result4),
    )

    # Test case 5: (a % b) % b = a % b
    var a5 = Decimal128(17)
    var b5 = Decimal128(5)
    var mod_once = a5 % b5
    var mod_twice = mod_once % b5
    testing.assert_equal(
        String(mod_once), String(mod_twice), "(a % b) % b should equal a % b"
    )

    print("✓ Mathematical relationships tests passed!")


fn test_consistency_with_floor_division() raises:
    """Test consistency between modulo and floor division operations."""
    print("Testing consistency with floor division...")

    # Test case 1: a % b and a - (a // b) * b
    var a1 = Decimal128(10)
    var b1 = Decimal128(3)
    var mod_result = a1 % b1
    var floor_div = a1 // b1
    var calc_mod = a1 - floor_div * b1
    testing.assert_equal(
        String(mod_result),
        String(calc_mod),
        "a % b should equal a - (a // b) * b",
    )

    # Test case 2: Consistency with negative values
    var a2 = Decimal128(-10)
    var b2 = Decimal128(3)
    var mod_result2 = a2 % b2
    var floor_div2 = a2 // b2
    var calc_mod2 = a2 - floor_div2 * b2
    testing.assert_equal(
        String(mod_result2),
        String(calc_mod2),
        "a % b should equal a - (a // b) * b with negative values",
    )

    # Test case 3: Consistency with decimal values
    var a3 = Decimal128("10.5")
    var b3 = Decimal128("2.5")
    var mod_result3 = a3 % b3
    var floor_div3 = a3 // b3
    var calc_mod3 = a3 - floor_div3 * b3
    testing.assert_equal(
        String(mod_result3),
        String(calc_mod3),
        "a % b should equal a - (a // b) * b with decimal values",
    )

    # Test case 4: Consistency with mixed positive and negative values
    var a4 = Decimal128(10)
    var b4 = Decimal128(-3)
    var mod_result4 = a4 % b4
    var floor_div4 = a4 // b4
    var calc_mod4 = a4 - floor_div4 * b4
    testing.assert_equal(
        String(mod_result4),
        String(calc_mod4),
        "a % b should equal a - (a // b) * b with mixed signs",
    )

    print("✓ Consistency with floor division tests passed!")


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
    print("Running Decimal128 Modulo Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_modulo, "Basic modulo operations test"
    )
    run_test_with_error_handling(
        test_negative_modulo, "Negative number modulo test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")
    run_test_with_error_handling(
        test_mathematical_relationships, "Mathematical relationships test"
    )
    run_test_with_error_handling(
        test_consistency_with_floor_division,
        "Consistency with floor division test",
    )

    print("All modulo tests passed!")
