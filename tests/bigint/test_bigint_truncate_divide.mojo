"""
Comprehensive tests for the truncate_divide operation of the BigInt type.
BigInt is a signed integer type, so these tests focus on division with both positive and negative numbers.

Note: Python's division is floor division (rounds toward negative infinity), 
while truncate division rounds toward zero. This means for negative numbers,
the results will differ between floor and truncate division.
"""

import testing
from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
from python import Python


fn test_basic_truncate_division_positive() raises:
    """Test basic truncate division cases with positive numbers."""
    print("Testing basic truncate division with positive numbers...")

    # For positive numbers, truncate division behaves the same as floor division

    # Test case 1: Simple division with no remainder
    var a1 = BigInt("10")
    var b1 = BigInt("2")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(
        String(result1), "5", "10 / 2 should equal 5, got " + String(result1)
    )

    # Test case 2: Division with remainder (truncate toward zero)
    var a2 = BigInt("10")
    var b2 = BigInt("3")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    testing.assert_equal(
        String(result2), "3", "10 / 3 should equal 3, got " + String(result2)
    )

    # Test case 3: Division results in zero (smaller / larger)
    var a3 = BigInt("3")
    var b3 = BigInt("10")
    var result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    testing.assert_equal(
        String(result3), "0", "3 / 10 should equal 0, got " + String(result3)
    )

    # Test case 4: Division by 1
    var a4 = BigInt("42")
    var b4 = BigInt("1")
    var result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)
    testing.assert_equal(
        String(result4), "42", "42 / 1 should equal 42, got " + String(result4)
    )

    # Test case 5: Large number division
    var a5 = BigInt("1000000000000")
    var b5 = BigInt("1000000")
    var result5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)
    testing.assert_equal(
        String(result5),
        "1000000",
        "1000000000000 / 1000000 should equal 1000000, got " + String(result5),
    )

    print("✓ Basic truncate division with positive numbers tests passed!")


fn test_basic_truncate_division_negative() raises:
    """Test basic truncate division cases with negative numbers."""
    print("Testing basic truncate division with negative numbers...")

    # This is where truncate division differs from floor division

    # Test case 1: Negative dividend, positive divisor
    var a1 = BigInt("-10")
    var b1 = BigInt("2")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(
        String(result1), "-5", "-10 / 2 should equal -5, got " + String(result1)
    )

    # Test case 2: Negative dividend, negative divisor
    var a2 = BigInt("-10")
    var b2 = BigInt("-2")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    testing.assert_equal(
        String(result2), "5", "-10 / -2 should equal 5, got " + String(result2)
    )

    # Test case 3: Positive dividend, negative divisor
    var a3 = BigInt("10")
    var b3 = BigInt("-2")
    var result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    testing.assert_equal(
        String(result3), "-5", "10 / -2 should equal -5, got " + String(result3)
    )

    # Test case 4: Negative dividend with remainder (truncate division case)
    var a4 = BigInt("-7")
    var b4 = BigInt("3")
    var result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)

    # In truncate division, -7/3 = -2.333... -> -2 (truncate toward zero)
    # In floor division, -7//3 = -3 (round toward negative infinity)
    testing.assert_equal(
        String(result4), "-2", "-7 / 3 should equal -2, got " + String(result4)
    )

    # Test case 5: Key test for truncate division (negative numbers)
    var a5 = BigInt("-5")
    var b5 = BigInt("2")
    var result5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)

    # In truncate division, -5/2 = -2.5 -> -2
    # In floor division, -5//2 = -3
    testing.assert_equal(
        String(result5), "-2", "-5 / 2 should equal -2, got " + String(result5)
    )

    print("✓ Basic truncate division with negative numbers tests passed!")


fn test_mixed_sign_truncate_division() raises:
    """Test truncate division cases with mixed signs."""
    print("Testing truncate division with mixed signs...")

    # Test case 1: Negative / positive with exact division
    var a1 = BigInt("-6")
    var b1 = BigInt("3")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(
        String(result1), "-2", "-6 / 3 should equal -2, got " + String(result1)
    )

    # Test case 2: Negative / negative with exact division
    var a2 = BigInt("-6")
    var b2 = BigInt("-3")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    testing.assert_equal(
        String(result2), "2", "-6 / -3 should equal 2, got " + String(result2)
    )

    # Test case 3: Positive / negative with exact division
    var a3 = BigInt("6")
    var b3 = BigInt("-3")
    var result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    testing.assert_equal(
        String(result3), "-2", "6 / -3 should equal -2, got " + String(result3)
    )

    # Test case 4: Negative / positive with remainder (critical truncate division case)
    var a4 = BigInt("-7")
    var b4 = BigInt("4")
    var result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)

    # In truncate division, -7/4 = -1.75 -> -1
    # In floor division, -7//4 = -2
    testing.assert_equal(
        String(result4), "-1", "-7 / 4 should equal -1, got " + String(result4)
    )

    # Test case 5: Positive / negative with remainder (critical truncate division case)
    var a5 = BigInt("7")
    var b5 = BigInt("-4")
    var result5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)

    # In truncate division, 7/-4 = -1.75 -> -1
    # In floor division, 7//-4 = -2
    testing.assert_equal(
        String(result5), "-1", "7 / -4 should equal -1, got " + String(result5)
    )

    print("✓ Truncate division with mixed signs tests passed!")


fn test_zero_handling() raises:
    """Test truncate division cases involving zero."""
    print("Testing zero handling in truncate division...")

    # Test case 1: Zero dividend, positive divisor
    var a1 = BigInt("0")
    var b1 = BigInt("5")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(
        String(result1), "0", "0 / 5 should equal 0, got " + String(result1)
    )

    # Test case 2: Zero dividend, negative divisor
    var a2 = BigInt("0")
    var b2 = BigInt("-5")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    testing.assert_equal(
        String(result2), "0", "0 / -5 should equal 0, got " + String(result2)
    )

    # Test case 3: Division by zero should raise an error
    var a3 = BigInt("10")
    var b3 = BigInt("0")
    var exception_caught = False
    try:
        var _result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )

    # Test case 4: Negative number division by zero should raise an error
    var a4 = BigInt("-10")
    var b4 = BigInt("0")
    exception_caught = False
    try:
        var _result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )

    print("✓ Zero handling tests passed!")


fn test_large_number_division() raises:
    """Test truncate division with very large numbers."""
    print("Testing truncate division with large numbers...")

    # Test case 1: Large positive number divided by small number
    var a1 = BigInt("1" + "0" * 50)  # 10^50
    var b1 = BigInt("7")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(
        String(result1),
        "14285714285714285714285714285714285714285714285714",
        "10^50 / 7 gave incorrect result",
    )
    print(String("passed: {} / {} = {}").format(a1, b1, result1))

    # Test case 2: Large negative number divided by small number
    var a2 = BigInt("-" + "1" + "0" * 50)  # -10^50
    var b2 = BigInt("7")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    testing.assert_equal(
        String(result2),
        "-14285714285714285714285714285714285714285714285714",
        "-10^50 / 7 gave incorrect result",
    )
    print(String("passed: {} / {} = {}").format(a2, b2, result2))

    # Test case 3: Large positive number divided by small negative number
    var a3 = BigInt("1" + "0" * 50)  # 10^50
    var b3 = BigInt("-7")
    var result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    testing.assert_equal(
        String(result3),
        "-14285714285714285714285714285714285714285714285714",
        "10^50 / -7 gave incorrect result",
    )
    print(String("passed: {} / {} = {}").format(a3, b3, result3))

    # Test case 4: Large negative number divided by small negative number
    var a4 = BigInt("-" + "1" + "0" * 50)  # -10^50
    var b4 = BigInt("-7")
    var result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)
    testing.assert_equal(
        String(result4),
        "14285714285714285714285714285714285714285714285714",
        "-10^50 / -7 gave incorrect result",
    )
    print(String("passed: {} / {} = {}").format(a4, b4, result4))

    # Test case 5: Large number divided by large number (same sign)
    var a5 = BigInt("9" * 30)  # 30 nines
    var b5 = BigInt("9" * 15)  # 15 nines
    var result5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)
    testing.assert_equal(
        String(result5),
        "1000000000000001",
        "large / large (same sign) gave incorrect result",
    )
    print(String("passed: {} / {} = {}").format(a5, b5, result5))

    # Test case 6: Large number divided by large number (opposite sign)
    var a6 = BigInt("9" * 30)  # 30 nines
    var b6 = BigInt("-" + "9" * 15)  # -15 nines
    var result6 = decimojo.bigint.arithmetics.truncate_divide(a6, b6)
    testing.assert_equal(
        String(result6),
        "-1000000000000001",
        "large / large (opposite sign) gave incorrect result",
    )
    print(String("passed: {} / {} = {}").format(a6, b6, result6))

    print("✓ Large number division tests passed!")


fn test_truncate_modulo_identity() raises:
    """Test mathematical properties of truncate division and modulo."""
    print("Testing mathematical identity: a = (a / b) * b + (a % b)...")

    # Test case 1: Positive dividend, positive divisor
    var a1 = BigInt("17")
    var b1 = BigInt("5")
    var quotient1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    var remainder1 = decimojo.bigint.arithmetics.truncate_modulo(a1, b1)
    var reconstructed1 = quotient1 * b1 + remainder1

    testing.assert_equal(
        String(reconstructed1),
        String(a1),
        "(a / b) * b + (a % b) should equal a for positive numbers",
    )
    testing.assert_equal(String(quotient1), "3", "17/5 should equal 3")
    testing.assert_equal(String(remainder1), "2", "17%5 should equal 2")

    # Test case 2: Negative dividend, positive divisor
    var a2 = BigInt("-17")
    var b2 = BigInt("5")
    var quotient2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    var remainder2 = decimojo.bigint.arithmetics.truncate_modulo(a2, b2)
    var reconstructed2 = quotient2 * b2 + remainder2

    testing.assert_equal(
        String(reconstructed2),
        String(a2),
        "(a / b) * b + (a % b) should equal a for negative dividend",
    )
    testing.assert_equal(String(quotient2), "-3", "-17/5 should equal -3")
    testing.assert_equal(String(remainder2), "-2", "-17%5 should equal -2")

    # Test case 3: Positive dividend, negative divisor
    var a3 = BigInt("17")
    var b3 = BigInt("-5")
    var quotient3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    var remainder3 = decimojo.bigint.arithmetics.truncate_modulo(a3, b3)
    var reconstructed3 = quotient3 * b3 + remainder3

    testing.assert_equal(
        String(reconstructed3),
        String(a3),
        "(a / b) * b + (a % b) should equal a for negative divisor",
    )
    testing.assert_equal(String(quotient3), "-3", "17/-5 should equal -3")
    testing.assert_equal(String(remainder3), "2", "17%-5 should equal 2")

    # Test case 4: Negative dividend, negative divisor
    var a4 = BigInt("-17")
    var b4 = BigInt("-5")
    var quotient4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)
    var remainder4 = decimojo.bigint.arithmetics.truncate_modulo(a4, b4)
    var reconstructed4 = quotient4 * b4 + remainder4

    testing.assert_equal(
        String(reconstructed4),
        String(a4),
        (
            "(a / b) * b + (a % b) should equal a for negative dividend and"
            " divisor"
        ),
    )
    testing.assert_equal(String(quotient4), "3", "-17/-5 should equal 3")
    testing.assert_equal(String(remainder4), "-2", "-17%-5 should equal -2")

    # Test case 5: With large numbers
    var a5 = BigInt("12345678901234567890")
    var b5 = BigInt("987654321")
    var quotient5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)
    var remainder5 = decimojo.bigint.arithmetics.truncate_modulo(a5, b5)
    var reconstructed5 = quotient5 * b5 + remainder5

    testing.assert_equal(
        String(reconstructed5),
        String(a5),
        "(a / b) * b + (a % b) should equal a for large numbers",
    )

    print("✓ Mathematical identity tests passed!")


fn test_truncate_division_rounding() raises:
    """Test that truncate division correctly rounds toward zero."""
    print("Testing truncate division rounding behavior...")

    # Test case 1: Positive / positive with remainder
    var a1 = BigInt("7")
    var b1 = BigInt("2")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(
        String(result1), "3", "7 / 2 should equal 3, got " + String(result1)
    )

    # Test case 2: Negative / positive with remainder (key truncate division case)
    var a2 = BigInt("-7")
    var b2 = BigInt("2")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)

    # In truncate division, -7/2 = -3.5 -> -3 (truncate toward zero)
    # In floor division, -7//2 = -4 (round toward negative infinity)
    testing.assert_equal(
        String(result2), "-3", "-7 / 2 should equal -3, got " + String(result2)
    )

    # Test case 3: Positive / negative with remainder (key truncate division case)
    var a3 = BigInt("7")
    var b3 = BigInt("-2")
    var result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)

    # In truncate division, 7/-2 = -3.5 -> -3 (truncate toward zero)
    # In floor division, 7//-2 = -4 (round toward negative infinity)
    testing.assert_equal(
        String(result3), "-3", "7 / -2 should equal -3, got " + String(result3)
    )

    # Test case 4: Negative / negative with remainder
    var a4 = BigInt("-7")
    var b4 = BigInt("-2")
    var result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)
    testing.assert_equal(
        String(result4), "3", "-7 / -2 should equal 3, got " + String(result4)
    )

    # Test case 5: Different dividend/divisor patterns
    var a5 = BigInt("1")
    var b5 = BigInt("4")
    var result5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)
    testing.assert_equal(
        String(result5), "0", "1 / 4 should equal 0, got " + String(result5)
    )

    # Test case 6: Negative small / positive large
    var a6 = BigInt("-1")
    var b6 = BigInt("4")
    var result6 = decimojo.bigint.arithmetics.truncate_divide(a6, b6)
    # In truncate division, -1/4 = -0.25 -> 0 (truncate toward zero)
    # In floor division, -1//4 = -1 (round toward negative infinity)
    testing.assert_equal(
        String(result6), "0", "-1 / 4 should equal 0, got " + String(result6)
    )

    # Test case 7: Another truncate vs. floor example
    var a7 = BigInt("-9")
    var b7 = BigInt("5")
    var result7 = decimojo.bigint.arithmetics.truncate_divide(a7, b7)
    # In truncate division, -9/5 = -1.8 -> -1
    # In floor division, -9//5 = -2
    testing.assert_equal(
        String(result7), "-1", "-9 / 5 should equal -1, got " + String(result7)
    )

    print("✓ Truncate division rounding tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for truncate division."""
    print("Testing edge cases for truncate division...")

    # Test case 1: Maximum divisor (just below dividend)
    var a1 = BigInt("1000")
    var b1 = BigInt("999")
    var result1 = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    testing.assert_equal(String(result1), "1", "1000 / 999 should equal 1")

    # Test case 2: Maximum negative divisor (just below dividend in magnitude)
    var a2 = BigInt("1000")
    var b2 = BigInt("-999")
    var result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    testing.assert_equal(String(result2), "-1", "1000 / -999 should equal -1")

    # Test case 3: Consecutive numbers (positive)
    var a3 = BigInt("101")
    var b3 = BigInt("100")
    var result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    testing.assert_equal(String(result3), "1", "101 / 100 should equal 1")

    # Test case 4: Consecutive numbers (negative)
    var a4 = BigInt("-101")
    var b4 = BigInt("100")
    var result4 = decimojo.bigint.arithmetics.truncate_divide(a4, b4)
    testing.assert_equal(String(result4), "-1", "-101 / 100 should equal -1")

    # Test case 5: Equal numbers (positive)
    var a5 = BigInt("9" * 100)  # 100 nines
    var b5 = BigInt("9" * 100)  # 100 nines
    var result5 = decimojo.bigint.arithmetics.truncate_divide(a5, b5)
    testing.assert_equal(
        String(result5),
        "1",
        "Equal large positive numbers division should equal 1",
    )

    # Test case 6: Equal numbers (negative)
    var a6 = BigInt("-" + "9" * 100)
    var b6 = BigInt("-" + "9" * 100)
    var result6 = decimojo.bigint.arithmetics.truncate_divide(a6, b6)
    testing.assert_equal(
        String(result6),
        "1",
        "Equal large negative numbers division should equal 1",
    )

    # Test case 7: Comparing truncate division with floor division
    var a7 = BigInt("-23")
    var b7 = BigInt("5")
    var truncate_result = decimojo.bigint.arithmetics.truncate_divide(a7, b7)

    testing.assert_equal(
        String(truncate_result),
        "-4",
        "Truncate division of -23 by 5 should equal -4",
    )

    # Test case 8: Powers of 10 division
    var a8 = BigInt("1" + "0" * 20)  # 10^20
    var b8 = BigInt("1" + "0" * 5)  # 10^5
    var result8 = decimojo.bigint.arithmetics.truncate_divide(a8, b8)
    testing.assert_equal(
        String(result8),
        "1" + "0" * 15,
        "Powers of 10 truncate division gave incorrect result",
    )

    print("✓ Edge cases tests passed!")


fn test_python_comparison() raises:
    """Compare BigInt truncate_divide results with Python's int division."""
    print("Testing truncate division against Python's int division...")

    var py = Python.import_module("builtins")

    # Test case 1: Simple positive division
    var a1 = BigInt("42")
    var b1 = BigInt("5")
    var mojo_result = decimojo.bigint.arithmetics.truncate_divide(a1, b1)
    var py_result = py.int(42) // py.int(5)
    testing.assert_equal(
        String(mojo_result),
        String(py_result),
        "Truncate division differs from Python for positive numbers",
    )

    # Test case 2: Negative dividend
    var a2 = BigInt("-42")
    var b2 = BigInt("5")
    var mojo_result2 = decimojo.bigint.arithmetics.truncate_divide(a2, b2)
    # Note: Python uses floor division, not truncate division
    # For negative numbers, we need to calculate truncate division explicitly

    testing.assert_equal(
        String(mojo_result2), "-8", "Truncate division should be -8 for -42/5"
    )
    print("Note: Python's // does floor division (-9), while truncate gives -8")

    # Test case 3: Large numbers
    var a3 = BigInt("9" * 20)
    var b3 = BigInt("3")
    var mojo_result3 = decimojo.bigint.arithmetics.truncate_divide(a3, b3)
    var py_div3 = py.int("9" * 20) // py.int(3)

    testing.assert_equal(
        String(mojo_result3),
        String(py_div3),
        "Truncate division differs from Python for large positive numbers",
    )

    print(
        "✓ Python comparison tests passed with expected differences for"
        " negative numbers!"
    )


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

    print("Note: Truncate division rounds toward zero, while floor division")
    print("rounds toward negative infinity.")
    print("For positive numbers, both yield the same results.")
    print("For negative numbers divided by positive numbers:")
    print("  -7/3 = -2.33... → truncate: -2, floor: -3")
    print("For positive numbers divided by negative numbers:")
    print("  7/-3 = -2.33... → truncate: -2, floor: -3")
    print()

    run_test_with_error_handling(
        test_basic_truncate_division_positive,
        "Basic truncate division with positive numbers test",
    )
    run_test_with_error_handling(
        test_basic_truncate_division_negative,
        "Basic truncate division with negative numbers test",
    )
    run_test_with_error_handling(
        test_mixed_sign_truncate_division, "Mixed sign truncate division test"
    )
    run_test_with_error_handling(test_zero_handling, "Zero handling test")
    run_test_with_error_handling(
        test_large_number_division, "Large number division test"
    )
    run_test_with_error_handling(
        test_truncate_modulo_identity, "Mathematical identity test"
    )
    run_test_with_error_handling(
        test_truncate_division_rounding, "Division rounding behavior test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")
    run_test_with_error_handling(
        test_python_comparison, "Python comparison test"
    )

    print("All BigInt truncate division tests passed!")
