"""
Comprehensive tests for the floor_divide operation of the BigInt type.
BigInt is a signed integer type, so these tests focus on division with both positive and negative numbers.
Tests also compare results with Python's built-in int type for verification.
"""

import testing
from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
from python import Python, PythonObject


fn test_basic_floor_division_positive() raises:
    """Test basic floor division cases with positive numbers."""
    print("Testing basic floor division with positive numbers...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Simple division with no remainder
    var a1 = BigInt("10")
    var b1 = BigInt("2")
    var result1 = a1 // b1
    var py_result1 = py.int("10") // py.int("2")
    testing.assert_equal(
        String(result1), "5", "10 // 2 should equal 5, got " + String(result1)
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Division with remainder (floor towards negative infinity)
    var a2 = BigInt("10")
    var b2 = BigInt("3")
    var result2 = a2 // b2
    var py_result2 = py.int("10") // py.int("3")
    testing.assert_equal(
        String(result2), "3", "10 // 3 should equal 3, got " + String(result2)
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: Division results in zero (smaller // larger)
    var a3 = BigInt("3")
    var b3 = BigInt("10")
    var result3 = a3 // b3
    var py_result3 = py.int("3") // py.int("10")
    testing.assert_equal(
        String(result3), "0", "3 // 10 should equal 0, got " + String(result3)
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )

    # Test case 4: Division by 1
    var a4 = BigInt("42")
    var b4 = BigInt("1")
    var result4 = a4 // b4
    var py_result4 = py.int("42") // py.int("1")
    testing.assert_equal(
        String(result4), "42", "42 // 1 should equal 42, got " + String(result4)
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )

    # Test case 5: Large number division
    var a5 = BigInt("1000000000000")
    var b5 = BigInt("1000000")
    var result5 = a5 // b5
    var py_result5 = py.int("1000000000000") // py.int("1000000")
    testing.assert_equal(
        String(result5),
        "1000000",
        "1000000000000 // 1000000 should equal 1000000, got " + String(result5),
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )

    print("✓ Basic floor division with positive numbers tests passed!")


fn test_basic_floor_division_negative() raises:
    """Test basic floor division cases with negative numbers."""
    print("Testing basic floor division with negative numbers...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Negative dividend, positive divisor
    var a1 = BigInt("-10")
    var b1 = BigInt("2")
    var result1 = a1 // b1
    var py_result1 = py.int("-10") // py.int("2")
    testing.assert_equal(
        String(result1),
        "-5",
        "-10 // 2 should equal -5, got " + String(result1),
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Negative dividend, negative divisor
    var a2 = BigInt("-10")
    var b2 = BigInt("-2")
    var result2 = a2 // b2
    var py_result2 = py.int("-10") // py.int("-2")
    testing.assert_equal(
        String(result2), "5", "-10 // -2 should equal 5, got " + String(result2)
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: Positive dividend, negative divisor
    var a3 = BigInt("10")
    var b3 = BigInt("-2")
    var result3 = a3 // b3
    var py_result3 = py.int("10") // py.int("-2")
    testing.assert_equal(
        String(result3),
        "-5",
        "10 // -2 should equal -5, got " + String(result3),
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )

    # Test case 4: Negative dividend with remainder (floor division special case)
    var a4 = BigInt("-7")
    var b4 = BigInt("3")
    var result4 = a4 // b4
    var py_result4 = py.int("-7") // py.int("3")
    testing.assert_equal(
        String(result4), "-3", "-7 // 3 should equal -3, got " + String(result4)
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )

    # Test case 5: Key test for floor division (negative numbers)
    var a5 = BigInt("-5")
    var b5 = BigInt("2")
    var result5 = a5 // b5
    var py_result5 = py.int("-5") // py.int("2")
    testing.assert_equal(
        String(result5), "-3", "-5 // 2 should equal -3, got " + String(result5)
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )

    print("✓ Basic floor division with negative numbers tests passed!")


fn test_mixed_sign_floor_division() raises:
    """Test floor division cases with mixed signs."""
    print("Testing floor division with mixed signs...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Negative // positive with exact division
    var a1 = BigInt("-6")
    var b1 = BigInt("3")
    var result1 = a1 // b1
    var py_result1 = py.int("-6") // py.int("3")
    testing.assert_equal(
        String(result1), "-2", "-6 // 3 should equal -2, got " + String(result1)
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Negative // negative with exact division
    var a2 = BigInt("-6")
    var b2 = BigInt("-3")
    var result2 = a2 // b2
    var py_result2 = py.int("-6") // py.int("-3")
    testing.assert_equal(
        String(result2), "2", "-6 // -3 should equal 2, got " + String(result2)
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: Positive // negative with exact division
    var a3 = BigInt("6")
    var b3 = BigInt("-3")
    var result3 = a3 // b3
    var py_result3 = py.int("6") // py.int("-3")
    testing.assert_equal(
        String(result3), "-2", "6 // -3 should equal -2, got " + String(result3)
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )

    # Test case 4: Negative // positive with remainder (critical floor division case)
    var a4 = BigInt("-7")
    var b4 = BigInt("4")
    var result4 = a4 // b4
    var py_result4 = py.int("-7") // py.int("4")
    testing.assert_equal(
        String(result4), "-2", "-7 // 4 should equal -2, got " + String(result4)
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )

    # Test case 5: Positive // negative with remainder (critical floor division case)
    var a5 = BigInt("7")
    var b5 = BigInt("-4")
    var result5 = a5 // b5
    var py_result5 = py.int("7") // py.int("-4")
    testing.assert_equal(
        String(result5), "-2", "7 // -4 should equal -2, got " + String(result5)
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )

    print("✓ Floor division with mixed signs tests passed!")


fn test_zero_handling() raises:
    """Test floor division cases involving zero."""
    print("Testing zero handling in floor division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Zero dividend, positive divisor
    var a1 = BigInt("0")
    var b1 = BigInt("5")
    var result1 = a1 // b1
    var py_result1 = py.int("0") // py.int("5")
    testing.assert_equal(
        String(result1), "0", "0 // 5 should equal 0, got " + String(result1)
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Zero dividend, negative divisor
    var a2 = BigInt("0")
    var b2 = BigInt("-5")
    var result2 = a2 // b2
    var py_result2 = py.int("0") // py.int("-5")
    testing.assert_equal(
        String(result2), "0", "0 // -5 should equal 0, got " + String(result2)
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: Division by zero should raise an error
    var a3 = BigInt("10")
    var b3 = BigInt("0")
    var exception_caught = False
    try:
        var _result3 = a3 // b3
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
        var _result4 = a4 // b4
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )

    print("✓ Zero handling tests passed!")


fn test_large_number_division() raises:
    """Test floor division with very large numbers."""
    print("Testing floor division with large numbers...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Large positive number divided by small number
    var a1 = BigInt("1" + "0" * 50)  # 10^50
    var b1 = BigInt("7")
    var result1 = a1 // b1
    var py_result1 = py.int("1" + "0" * 50) // py.int("7")
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Large positive number division gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a1, b1, result1))

    # Test case 2: Large negative number divided by small number
    var a2 = BigInt("-" + "1" + "0" * 50)  # -10^50
    var b2 = BigInt("7")
    var result2 = a2 // b2
    var py_result2 = py.int("-" + "1" + "0" * 50) // py.int("7")
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Large negative number division gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a2, b2, result2))

    # Test case 3: Large positive number divided by small negative number
    var a3 = BigInt("1" + "0" * 50)  # 10^50
    var b3 = BigInt("-7")
    var result3 = a3 // b3
    var py_result3 = py.int("1" + "0" * 50) // py.int("-7")
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Large positive // small negative gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a3, b3, result3))

    # Test case 4: Large negative number divided by small negative number
    var a4 = BigInt("-" + "1" + "0" * 50)  # -10^50
    var b4 = BigInt("-7")
    var result4 = a4 // b4
    var py_result4 = py.int("-" + "1" + "0" * 50) // py.int("-7")
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Large negative // small negative gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a4, b4, result4))

    # Test case 5: Large number divided by large number (same sign)
    var a5 = BigInt("9" * 30)  # 30 nines
    var b5 = BigInt("9" * 15)  # 15 nines
    var result5 = a5 // b5
    var py_result5 = py.int("9" * 30) // py.int("9" * 15)
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Large // large (same sign) gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a5, b5, result5))

    # Test case 6: Large number divided by large number (opposite sign)
    var a6 = BigInt("9" * 30)  # 30 nines
    var b6 = BigInt("-" + "9" * 15)  # -15 nines
    var result6 = a6 // b6
    var py_result6 = py.int("9" * 30) // py.int("-" + "9" * 15)
    testing.assert_equal(
        String(result6),
        String(py_result6),
        "Large // large (opposite sign) gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a6, b6, result6))

    # Test case 7: Very large number divisible by power of 10 (positive)
    var a7 = BigInt("1" + "0" * 100)  # 10^100
    var b7 = BigInt("1" + "0" * 40)  # 10^40
    var result7 = a7 // b7
    var py_result7 = py.int("1" + "0" * 100) // py.int("1" + "0" * 40)
    testing.assert_equal(
        String(result7),
        String(py_result7),
        "Power of 10 division gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a7, b7, result7))

    # Test case 8: Very large number divisible by power of 10 (negative dividend)
    var a8 = BigInt("-" + "1" + "0" * 100)  # -10^100
    var b8 = BigInt("1" + "0" * 40)  # 10^40
    var result8 = a8 // b8
    var py_result8 = py.int("-" + "1" + "0" * 100) // py.int("1" + "0" * 40)
    testing.assert_equal(
        String(result8),
        String(py_result8),
        "Negative power of 10 division gave incorrect result",
    )
    print("passed: {} // {} = {}".format(a8, b8, result8))

    # Test case 9: Very large complex numbers
    stra = "123456789" * 50
    strb = "987654321" * 20
    var a9 = BigInt(stra)
    var b9 = BigInt(strb)
    var result9 = a9 // b9
    var py_result9 = py.int(stra) // py.int(strb)
    testing.assert_equal(
        String(result9),
        String(py_result9),
        "Complex large number division incorrect",
    )
    print("passed: {} // {} = {}".format(a9, b9, result9))

    # Test case 10: Very large negative complex numbers
    var a10 = BigInt("-" + stra)
    var b10 = BigInt("-" + strb)
    var result10 = a10 // b10
    var py_result10 = py.int("-" + stra) // py.int("-" + strb)
    testing.assert_equal(
        String(result10),
        String(py_result10),
        "Complex large negative number division incorrect",
    )
    print("passed: {} // {} = {}".format(a10, b10, result10))

    print("✓ Large number division tests passed!")


fn test_floor_division_rounding() raises:
    """Test that floor division correctly rounds toward negative infinity."""
    print("Testing floor division rounding behavior...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Positive // positive with remainder
    var a1 = BigInt("7")
    var b1 = BigInt("2")
    var result1 = a1 // b1
    var py_result1 = py.int("7") // py.int("2")
    testing.assert_equal(
        String(result1), "3", "7 // 2 should equal 3, got " + String(result1)
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Result doesn't match Python's int result",
    )

    # Test case 2: Negative // positive with remainder (key floor division case)
    var a2 = BigInt("-7")
    var b2 = BigInt("2")
    var result2 = a2 // b2
    var py_result2 = py.int("-7") // py.int("2")
    testing.assert_equal(
        String(result2), "-4", "-7 // 2 should equal -4, got " + String(result2)
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Result doesn't match Python's int result",
    )

    # Test case 3: Positive // negative with remainder (key floor division case)
    var a3 = BigInt("7")
    var b3 = BigInt("-2")
    var result3 = a3 // b3
    var py_result3 = py.int("7") // py.int("-2")
    testing.assert_equal(
        String(result3), "-4", "7 // -2 should equal -4, got " + String(result3)
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Result doesn't match Python's int result",
    )

    # Test case 4: Negative // negative with remainder
    var a4 = BigInt("-7")
    var b4 = BigInt("-2")
    var result4 = a4 // b4
    var py_result4 = py.int("-7") // py.int("-2")
    testing.assert_equal(
        String(result4), "3", "-7 // -2 should equal 3, got " + String(result4)
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Result doesn't match Python's int result",
    )

    # Test case 5: Different dividend/divisor patterns
    var a5 = BigInt("1")
    var b5 = BigInt("4")
    var result5 = a5 // b5
    var py_result5 = py.int("1") // py.int("4")
    testing.assert_equal(
        String(result5), "0", "1 // 4 should equal 0, got " + String(result5)
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )

    # Test case 6: Negative small // positive large
    var a6 = BigInt("-1")
    var b6 = BigInt("4")
    var result6 = a6 // b6
    var py_result6 = py.int("-1") // py.int("4")
    testing.assert_equal(
        String(result6), "-1", "-1 // 4 should equal -1, got " + String(result6)
    )
    testing.assert_equal(
        String(result6),
        String(py_result6),
        "Result doesn't match Python's int result",
    )

    # Test case 7: Borderline case
    var a7 = BigInt("-9")
    var b7 = BigInt("5")
    var result7 = a7 // b7
    var py_result7 = py.int("-9") // py.int("5")
    testing.assert_equal(
        String(result7), "-2", "-9 // 5 should equal -2, got " + String(result7)
    )
    testing.assert_equal(
        String(result7),
        String(py_result7),
        "Result doesn't match Python's int result",
    )

    # Test case 8: Another borderline case
    var a8 = BigInt("9")
    var b8 = BigInt("-5")
    var result8 = a8 // b8
    var py_result8 = py.int("9") // py.int("-5")
    testing.assert_equal(
        String(result8), "-2", "9 // -5 should equal -2, got " + String(result8)
    )
    testing.assert_equal(
        String(result8),
        String(py_result8),
        "Result doesn't match Python's int result",
    )

    # Test case 9: Close to zero negative
    var a9 = BigInt("-1")
    var b9 = BigInt("3")
    var result9 = a9 // b9
    var py_result9 = py.int("-1") // py.int("3")
    testing.assert_equal(
        String(result9), "-1", "-1 // 3 should equal -1, got " + String(result9)
    )
    testing.assert_equal(
        String(result9),
        String(py_result9),
        "Result doesn't match Python's int result",
    )

    # Test case 10: Close to zero positive with negative divisor
    var a10 = BigInt("1")
    var b10 = BigInt("-3")
    var result10 = a10 // b10
    var py_result10 = py.int("1") // py.int("-3")
    testing.assert_equal(
        String(result10),
        "-1",
        "1 // -3 should equal -1, got " + String(result10),
    )
    testing.assert_equal(
        String(result10),
        String(py_result10),
        "Result doesn't match Python's int result",
    )

    print("✓ Floor division rounding tests passed!")


fn test_division_identity() raises:
    """Test mathematical properties of floor division."""
    print("Testing mathematical properties of floor division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test property: (a // b) * b + (a % b) = a
    # Test case 1: Positive dividend, positive divisor
    var a1 = BigInt("17")
    var b1 = BigInt("5")
    var quotient1 = a1 // b1
    var remainder1 = a1 % b1
    var reconstructed1 = quotient1 * b1 + remainder1

    # Python equivalent
    var py_a1 = py.int("17")
    var py_b1 = py.int("5")
    var py_quotient1 = py_a1 // py_b1
    var py_remainder1 = py_a1 % py_b1

    testing.assert_equal(
        String(reconstructed1),
        String(a1),
        "(a // b) * b + (a % b) should equal a for positive numbers",
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

    # Test case 2: Negative dividend, positive divisor
    var a2 = BigInt("-17")
    var b2 = BigInt("5")
    var quotient2 = a2 // b2
    var remainder2 = a2 % b2
    var reconstructed2 = quotient2 * b2 + remainder2

    # Python equivalent
    var py_a2 = py.int("-17")
    var py_b2 = py.int("5")
    var py_quotient2 = py_a2 // py_b2
    var py_remainder2 = py_a2 % py_b2

    testing.assert_equal(
        String(reconstructed2),
        String(a2),
        "(a // b) * b + (a % b) should equal a for negative dividend",
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

    # Test case 3: Positive dividend, negative divisor
    var a3 = BigInt("17")
    var b3 = BigInt("-5")
    var quotient3 = a3 // b3
    var remainder3 = a3 % b3
    var reconstructed3 = quotient3 * b3 + remainder3

    # Python equivalent
    var py_a3 = py.int("17")
    var py_b3 = py.int("-5")
    var py_quotient3 = py_a3 // py_b3
    var py_remainder3 = py_a3 % py_b3

    testing.assert_equal(
        String(reconstructed3),
        String(a3),
        "(a // b) * b + (a % b) should equal a for negative divisor",
    )
    testing.assert_equal(
        String(quotient3),
        String(py_quotient3),
        "Quotient doesn't match Python's int result",
    )
    testing.assert_equal(
        String(remainder3),
        String(py_remainder3),
        "Remainder doesn't match Python's int result",
    )

    # Test case 4: Negative dividend, negative divisor
    var a4 = BigInt("-17")
    var b4 = BigInt("-5")
    var quotient4 = a4 // b4
    var remainder4 = a4 % b4
    var reconstructed4 = quotient4 * b4 + remainder4

    # Python equivalent
    var py_a4 = py.int("-17")
    var py_b4 = py.int("-5")
    var py_quotient4 = py_a4 // py_b4
    var py_remainder4 = py_a4 % py_b4

    testing.assert_equal(
        String(reconstructed4),
        String(a4),
        (
            "(a // b) * b + (a % b) should equal a for negative dividend and"
            " divisor"
        ),
    )
    testing.assert_equal(
        String(quotient4),
        String(py_quotient4),
        "Quotient doesn't match Python's int result",
    )
    testing.assert_equal(
        String(remainder4),
        String(py_remainder4),
        "Remainder doesn't match Python's int result",
    )

    # Test case 5: With large numbers
    var a5 = BigInt("12345678901234567890")
    var b5 = BigInt("987654321")
    var quotient5 = a5 // b5
    var remainder5 = a5 % b5
    var reconstructed5 = quotient5 * b5 + remainder5
    var py_a5 = py.int("12345678901234567890")
    var py_b5 = py.int("987654321")
    var py_quotient5 = py_a5 // py_b5
    var py_remainder5 = py_a5 % py_b5
    testing.assert_equal(
        String(reconstructed5),
        String(a5),
        "(a // b) * b + (a % b) should equal a for large numbers",
    )
    testing.assert_equal(
        String(quotient5),
        String(py_quotient5),
        "Quotient doesn't match Python's int result",
    )
    testing.assert_equal(
        String(remainder5),
        String(py_remainder5),
        "Remainder doesn't match Python's int result",
    )

    print("✓ Mathematical identity tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for floor division."""
    print("Testing edge cases for floor division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Test case 1: Maximum divisor (just below dividend)
    var a1 = BigInt("1000")
    var b1 = BigInt("999")
    var result1 = a1 // b1
    var py_result1 = py.int("1000") // py.int("999")
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "1000 // 999 doesn't match Python's result",
    )

    # Test case 2: Maximum negative divisor (just below dividend in magnitude)
    var a2 = BigInt("1000")
    var b2 = BigInt("-999")
    var result2 = a2 // b2
    var py_result2 = py.int("1000") // py.int("-999")
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "1000 // -999 doesn't match Python's result",
    )

    # Test case 3: Consecutive numbers (positive)
    var a3 = BigInt("101")
    var b3 = BigInt("100")
    var result3 = a3 // b3
    var py_result3 = py.int("101") // py.int("100")
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "101 // 100 doesn't match Python's result",
    )

    # Test case 4: Consecutive numbers (negative)
    var a4 = BigInt("-101")
    var b4 = BigInt("100")
    var result4 = a4 // b4
    var py_result4 = py.int("-101") // py.int("100")
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "-101 // 100 doesn't match Python's result",
    )

    # Test case 5: Equal numbers (positive)
    var a5 = BigInt("9" * 100)
    var b5 = BigInt("9" * 100)
    var result5 = a5 // b5
    var py_result5 = py.int("9" * 100) // py.int("9" * 100)
    testing.assert_equal(
        String(result5),
        "1",
        "Equal large positive numbers division should equal 1",
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Result doesn't match Python's int result",
    )

    # Test case 6: Equal numbers (negative)
    var a6 = BigInt("-" + "9" * 100)
    var b6 = BigInt("-" + "9" * 100)
    var result6 = a6 // b6
    var py_result6 = py.int("-" + "9" * 100) // py.int("-" + "9" * 100)
    testing.assert_equal(
        String(result6),
        "1",
        "Equal large negative numbers division should equal 1",
    )
    testing.assert_equal(
        String(result6),
        String(py_result6),
        "Result doesn't match Python's int result",
    )

    # Test case 7: Very small remainder (positive numbers)
    var a7 = BigInt("10000000001")
    var b7 = BigInt("10000000000")
    var result7 = a7 // b7
    var py_result7 = py.int("10000000001") // py.int("10000000000")
    testing.assert_equal(
        String(result7),
        String(py_result7),
        "Floor division with small remainder incorrect",
    )

    # Test case 8: Very small remainder (negative dividend)
    var a8 = BigInt("-10000000001")
    var b8 = BigInt("10000000000")
    var result8 = a8 // b8
    var py_result8 = py.int("-10000000001") // py.int("10000000000")
    testing.assert_equal(
        String(result8),
        String(py_result8),
        "Floor division with small negative remainder incorrect",
    )

    # Test case 9: Different input formats - integer init
    var a9 = BigInt.from_int(123)
    var b9 = BigInt.from_int(45)
    var result9 = a9 // b9
    var py_result9 = py.int("123") // py.int("45")
    testing.assert_equal(
        String(result9),
        String(py_result9),
        "Division with BigInt.from_int constructor mismatch",
    )

    # Test case 10: Power of 2 divisions (positive)
    var a10 = BigInt("128")
    var b10 = BigInt("2")
    var result10 = a10 // b10
    var py_result10 = py.int("128") // py.int("2")
    testing.assert_equal(
        String(result10), String(py_result10), "Power of 2 division mismatch"
    )

    # Test case 11: Power of 2 divisions (negative dividend)
    var a11 = BigInt("-128")
    var b11 = BigInt("2")
    var result11 = a11 // b11
    var py_result11 = py.int("-128") // py.int("2")
    testing.assert_equal(
        String(result11),
        String(py_result11),
        "Negative power of 2 division mismatch",
    )

    # Test case 12: Power of 10 divisions
    var a12 = BigInt("1000")
    var b12 = BigInt("10")
    var result12 = a12 // b12
    var py_result12 = py.int("1000") // py.int("10")
    testing.assert_equal(
        String(result12), String(py_result12), "Power of 10 division mismatch"
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
    print("Running BigInt Floor Division Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_floor_division_positive,
        "Basic floor division with positive numbers test",
    )
    run_test_with_error_handling(
        test_basic_floor_division_negative,
        "Basic floor division with negative numbers test",
    )
    run_test_with_error_handling(
        test_mixed_sign_floor_division, "Mixed sign floor division test"
    )
    run_test_with_error_handling(test_zero_handling, "Zero handling test")
    run_test_with_error_handling(
        test_large_number_division, "Large number division test"
    )
    run_test_with_error_handling(
        test_floor_division_rounding, "Floor division rounding behavior test"
    )
    run_test_with_error_handling(
        test_division_identity, "Mathematical identity test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")

    print("All BigInt floor division tests passed!")
