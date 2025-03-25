"""
Comprehensive tests for the truncate_divide operation of the BigUInt type.
BigUInt is an unsigned integer type, so these tests focus on positive number divisions.
Tests also compare results with Python's built-in int type for verification.
"""

import testing
from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.arithmetics
from python import Python, PythonObject


fn test_basic_truncate_division() raises:
    """Test basic truncate division cases with positive numbers."""
    print("Testing basic truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Division with no remainder
    var a1 = BigUInt("10")
    var b1 = BigUInt("2")
    var result1 = a1 // b1
    var py_result1 = py.int("10") // py.int("2")
    testing.assert_equal(
        String(result1), "5", "10 / 2 should equal 5, got " + String(result1)
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Division with remainder (truncate toward zero)
    var a2 = BigUInt("10")
    var b2 = BigUInt("3")
    var result2 = a2 // b2
    testing.assert_equal(
        String(result2), "3", "10 / 3 should equal 3, got " + String(result2)
    )

    # Test case 3: Division results in zero (smaller / larger)
    var a3 = BigUInt("3")
    var b3 = BigUInt("10")
    var result3 = a3 // b3
    testing.assert_equal(
        String(result3), "0", "3 / 10 should equal 0, got " + String(result3)
    )

    # Test case 4: Division by 1
    var a4 = BigUInt("42")
    var b4 = BigUInt("1")
    var result4 = a4 // b4
    testing.assert_equal(
        String(result4), "42", "42 / 1 should equal 42, got " + String(result4)
    )

    # Test case 5: Large number division
    var a5 = BigUInt("1000000000000")
    var b5 = BigUInt("1000000")
    var result5 = a5 // b5
    var py_result5 = py.int("1000000000000") // py.int("1000000")
    testing.assert_equal(
        String(result5),
        "1000000",
        "1000000000000 / 1000000 should equal 1000000, got " + String(result5),
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )

    print("✓ Basic truncate division tests passed!")


fn test_zero_handling() raises:
    """Test truncate division cases involving zero."""
    print("Testing zero handling in truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Zero dividend
    var a1 = BigUInt("0")
    var b1 = BigUInt("5")
    var result1 = a1 // b1
    var py_result1 = py.int("0") // py.int("5")
    testing.assert_equal(
        String(result1), "0", "0 / 5 should equal 0, got " + String(result1)
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Division by zero should raise an error
    var a2 = BigUInt("10")
    var b2 = BigUInt("0")
    var exception_caught = False
    try:
        var _result2 = a2 // b2
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )

    print("✓ Zero handling tests passed!")


fn test_large_number_division() raises:
    """Test truncate division with very large numbers."""
    print("Testing truncate division with large numbers...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Large number divided by small number
    var a1 = BigUInt("1" + "0" * 50)  # 10^50
    var b1 = BigUInt("7")
    var expected1 = BigUInt(
        "14285714285714285714285714285714285714285714285714"
    )  # 10^50 / 7 = 14285714285714285714285714...
    var result1 = a1 // b1
    var py_result1 = py.int("1" + "0" * 50) // py.int("7")
    testing.assert_equal(
        String(result1),
        String(expected1),
        "Large number division gave incorrect result",
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )
    print("passed: {} / {} = {}".format(a1, b1, result1))

    # Test case 2: Large number divided by large number
    var a2 = BigUInt("9" * 30)  # 30 nines
    var b2 = BigUInt("9" * 15)  # 15 nines
    var expected2 = BigUInt("1" + "0" * 14 + "1")  # 10^15 + 1
    var result2 = a2 // b2
    var py_result2 = py.int("9" * 30) // py.int("9" * 15)
    testing.assert_equal(
        String(result2),
        String(expected2),
        "Large / large division gave incorrect result",
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )
    print("passed: {} / {} = {}".format(a2, b2, result2))

    # Test case 3: Very large number divisible by power of 10
    var a3 = BigUInt("1" + "0" * 100)  # 10^100
    var b3 = BigUInt("1" + "0" * 40)  # 10^40
    var expected3 = BigUInt("1" + "0" * 60)  # 10^60
    var result3 = a3 // b3
    var py_result3 = py.int("1" + "0" * 100) // py.int("1" + "0" * 40)
    testing.assert_equal(
        String(result3),
        String(expected3),
        "Power of 10 division gave incorrect result",
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )
    print("passed: {} / {} = {}".format(a3, b3, result3))

    # Test case 4: Large number with large divisor resulting in small quotient
    var a4 = BigUInt("9" * 50)  # 50 nines
    var b4 = BigUInt("3" * 49 + "4")  # slightly less than a third of a4
    var result4 = a4 // b4
    var py_result4 = py.int("9" * 50) // py.int("3" * 49 + "4")
    testing.assert_equal(
        String(result4),
        "2",
        (
            "Large numbers division resulting in small quotient gave incorrect"
            " result"
        ),
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )
    print("passed: {} / {} = {}".format(a4, b4, result4))

    # Test case 5: Large number with very large divisor
    # x1 is more than twice the length of x2
    # x2 is 20 words long (>= 10^180)
    stra = "123456789" * 50
    strb = "987654321" * 20
    var a5 = BigUInt(stra)
    var b5 = BigUInt(strb)
    var result5 = a5 // b5
    var py_result5 = py.int(stra) // py.int(strb)
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )
    print("passed: {} / {} = {}".format(a5, b5, result5))

    # Test case 5: Large number with very large divisor
    # x1 is more than 200 words long (>= 10^1800)
    # x2 is more than 50 words long (>= 10^450)
    stra = "123456789" * 250
    strb = "987654321" * 100
    var a6 = BigUInt(stra)
    var b6 = BigUInt(strb)
    var result6 = a6 // b6
    var py_result6 = py.int(stra) // py.int(strb)
    testing.assert_equal(
        String(result6),
        String(py_result6),
        "Result doesn't match Python's int result",
    )
    print("passed: {} / {} = {}".format(a6, b6, result6))

    print("✓ Large number division tests passed!")


fn test_division_rounding() raises:
    """Test that truncate division correctly truncates toward zero."""
    print("Testing truncate division rounding behavior...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: 7/2 = 3.5 -> 3
    var a1 = BigUInt("7")
    var b1 = BigUInt("2")
    var expected1 = BigUInt("3")
    var result1 = a1 // b1
    var py_result1 = py.int("7") // py.int("2")
    testing.assert_equal(
        String(result1),
        String(expected1),
        "7 / 2 should equal 3, got " + String(result1),
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: 1/3 = 0.333... -> 0
    var a2 = BigUInt("1")
    var b2 = BigUInt("3")
    var expected2 = BigUInt("0")
    var result2 = a2 // b2
    var py_result2 = py.int("1") // py.int("3")
    testing.assert_equal(
        String(result2),
        String(expected2),
        "1 / 3 should equal 0, got " + String(result2),
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: 5/4 = 1.25 -> 1
    var a3 = BigUInt("5")
    var b3 = BigUInt("4")
    var expected3 = BigUInt("1")
    var result3 = a3 // b3
    var py_result3 = py.int("5") // py.int("4")
    testing.assert_equal(
        String(result3),
        String(expected3),
        "5 / 4 should equal 1, got " + String(result3),
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )

    # Test case 4: 99/100 = 0.99 -> 0
    var a4 = BigUInt("99")
    var b4 = BigUInt("100")
    var expected4 = BigUInt("0")
    var result4 = a4 // b4
    var py_result4 = py.int("99") // py.int("100")
    testing.assert_equal(
        String(result4),
        String(expected4),
        "99 / 100 should equal 0, got " + String(result4),
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )

    print("✓ Division rounding tests passed!")


fn test_division_identity() raises:
    """Test mathematical properties of truncate division."""
    print("Testing mathematical properties of truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test property: (a / b) * b + (a % b) = a
    var a1 = BigUInt("17")
    var b1 = BigUInt("5")
    var quotient1 = a1 // b1  # 3
    var remainder1 = a1 % b1  # 2
    var reconstructed1 = quotient1 * b1 + remainder1  # 3*5 + 2 = 17

    # Python equivalent
    var py_a1 = py.int("17")
    var py_b1 = py.int("5")
    var py_quotient1 = py_a1 // py_b1
    var py_remainder1 = py_a1 % py_b1
    var py_reconstructed1 = py_quotient1 * py_b1 + py_remainder1

    testing.assert_equal(
        String(reconstructed1),
        String(a1),
        "(a / b) * b + (a % b) should equal a for positive numbers",
    )
    testing.assert_equal(
        String(quotient1),
        String(py_quotient1),
        "Quotient doesn't match Python's int result",
    )
    testing.assert_equal(
        String(remainder1),
        String(py_remainder1),
        "Remainder doesn't match Python's int result",
    )
    testing.assert_equal(
        String(reconstructed1),
        String(py_reconstructed1),
        "Reconstructed value doesn't match Python's result",
    )

    # Test case with larger numbers
    var a2 = BigUInt("12345678901234567890")
    var b2 = BigUInt("987654321")
    var quotient2 = a2 // b2
    var remainder2 = a2 % b2
    var reconstructed2 = quotient2 * b2 + remainder2
    var py_a2 = py.int("12345678901234567890")
    var py_b2 = py.int("987654321")
    var py_quotient2 = py_a2 // py_b2
    var py_remainder2 = py_a2 % py_b2
    var py_reconstructed2 = py_quotient2 * py_b2 + py_remainder2
    testing.assert_equal(
        String(reconstructed2),
        String(a2),
        "(a / b) * b + (a % b) should equal a for large numbers",
    )
    testing.assert_equal(
        String(quotient2),
        String(py_quotient2),
        "Quotient doesn't match Python's int result",
    )
    testing.assert_equal(
        String(remainder2),
        String(py_remainder2),
        "Remainder doesn't match Python's int result",
    )
    testing.assert_equal(
        String(reconstructed2),
        String(py_reconstructed2),
        "Reconstructed value doesn't match Python's result",
    )

    print("✓ Mathematical identity tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for truncate division."""
    print("Testing edge cases for truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Maximum divisor
    # Dividing by a number almost as large as the dividend
    var a1 = BigUInt("1000")
    var b1 = BigUInt("999")
    var result1 = a1 // b1
    var py_result1 = py.int("1000") // py.int("999")
    testing.assert_equal(
        String(result1),
        "1",
        "1000 / 999 should equal 1, got " + String(result1),
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Consecutive numbers
    var a2 = BigUInt("101")
    var b2 = BigUInt("100")
    var result2 = a2 // b2
    var py_result2 = py.int("101") // py.int("100")
    testing.assert_equal(
        String(result2),
        "1",
        "101 / 100 should equal 1, got " + String(result2),
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: Equal large numbers
    var a3 = BigUInt("9" * 100)
    var b3 = BigUInt("9" * 100)
    var result3 = a3 // b3
    var py_result3 = py.int("9" * 100) // py.int("9" * 100)
    testing.assert_equal(
        String(result3),
        "1",
        "Equal large numbers division should equal 1",
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )

    # Test case 4: Powers of 10
    var a4 = BigUInt("1" + "0" * 20)  # 10^20
    var b4 = BigUInt("1" + "0" * 10)  # 10^10
    var result4 = a4 // b4
    var py_result4 = py.int("1" + "0" * 20) // py.int("1" + "0" * 10)
    testing.assert_equal(
        String(result4),
        "1" + "0" * 10,  # 10^10
        "Powers of 10 division gave incorrect result",
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )

    # Test case 5: Division resulting in large quotient
    var a5 = BigUInt("2" + "0" * 200)  # 2 × 10^200
    var b5 = BigUInt("2")
    var result5 = a5 // b5
    var py_result5 = py.int("2" + "0" * 200) // py.int("2")
    testing.assert_equal(
        String(result5),
        "1" + "0" * 200,  # 10^200
        "Large quotient division gave incorrect result",
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
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
    print("Running BigUInt Truncate Division Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_truncate_division, "Basic truncate division test"
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
    run_test_with_error_handling(test_edge_cases, "Edge cases test")

    print("All BigUInt truncate division tests passed!")
