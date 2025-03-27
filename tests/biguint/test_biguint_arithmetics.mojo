"""
Test BigUInt arithmetic operations including addition, subtraction, and multiplication.
BigUInt is an unsigned integer type, so it doesn't support negative values.
"""

from decimojo.biguint.biguint import BigUInt
from decimojo.tests import TestCase
import testing


fn test_add() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt addition...")

    # Define all test cases in a list
    var test_cases = List[TestCase]()
    test_cases.append(
        TestCase("123", "456", "579", "Simple addition of positive numbers")
    )
    test_cases.append(TestCase("123", "0", "123", "Addition with zero"))
    test_cases.append(
        TestCase(
            "99999999999999999999",
            "1",
            "100000000000000000000",
            "Addition with large numbers",
        )
    )
    test_cases.append(
        TestCase(
            "9999999999",
            "1",
            "10000000000",
            "Addition causing multiple carries",
        )
    )
    test_cases.append(
        TestCase(
            "12345",
            "9876543210",
            "9876555555",
            "Addition with numbers of different sizes",
        )
    )
    test_cases.append(
        TestCase(
            "12345678901234567890123456789",
            "98765432109876543210987654321",
            "111111111011111111101111111110",
            "Addition with very large numbers",
        )
    )
    test_cases.append(
        TestCase(
            "9" * 100,  # A 100-digit number of all 9's
            "1",
            "1" + "0" * 100,
            "Addition with extensive carry propagation",
        )
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a + b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    print("BigUInt addition tests passed!")


fn test_subtract() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt subtraction...")

    # Define all test cases in a list
    var test_cases = List[TestCase]()
    test_cases.append(TestCase("456", "123", "333", "Simple subtraction"))
    test_cases.append(TestCase("123", "0", "123", "Subtraction with zero"))
    test_cases.append(
        TestCase("123", "123", "0", "Subtraction resulting in zero")
    )
    test_cases.append(TestCase("10000", "1", "9999", "Subtraction with borrow"))
    test_cases.append(
        TestCase("10000", "9999", "1", "Subtraction with multiple borrows")
    )
    test_cases.append(
        TestCase(
            "12345678901234567890",
            "12345678901234567890",
            "0",
            "Self subtraction should yield zero",
        )
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a - b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    # Special case: Test underflow handling
    print("Testing underflow behavior (smaller - larger)...")
    var a_underflow = BigUInt("123")
    var b_underflow = BigUInt("456")
    var exception_caught = False
    try:
        var result = a_underflow - b_underflow
        print("Implementation allows underflow, result is: " + String(result))
    except:
        exception_caught = True
        print("Implementation correctly throws error on underflow")

    print("BigUInt subtraction tests passed!")


fn test_multiply() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt multiplication...")

    # Define all test cases in a list
    var test_cases = List[TestCase]()
    test_cases.append(TestCase("123", "456", "56088", "Simple multiplication"))
    test_cases.append(TestCase("123456789", "0", "0", "Multiplication by zero"))
    test_cases.append(
        TestCase("123456789", "1", "123456789", "Multiplication by one")
    )
    test_cases.append(
        TestCase(
            "12345", "67890", "838102050", "Multiplication of large numbers"
        )
    )
    test_cases.append(
        TestCase(
            "9" * 10,  # 10 nines
            "9" * 10,  # 10 nines
            "9999999998" + "0" * 9 + "1",
            "Multiplication of very large numbers",
        )
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a * b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    print("BigUInt multiplication tests passed!")


fn test_extreme_cases() raises:
    print("------------------------------------------------------")
    print("Testing extreme cases...")

    # Define all extreme test cases in a list
    var extreme_cases = List[TestCase]()
    extreme_cases.append(
        TestCase(
            "1" + "0" * 1000,  # 10^1000
            "5" + "0" * 999,  # 5×10^999
            "1" + "5" + "0" * 999,
            "Addition of very large numbers",
        )
    )
    extreme_cases.append(
        TestCase(
            "9" * 100,  # A 100-digit number of all 9's
            "1",
            "1" + "0" * 100,
            "Addition with extensive carry propagation",
        )
    )

    # Subtraction case
    var subtraction_cases = List[TestCase]()
    subtraction_cases.append(
        TestCase(
            "1" + "0" * 200,  # 10^200
            "1",
            "9" + "9" * 199,
            "Very large subtraction within range",
        )
    )

    # Multiplication case
    var multiplication_cases = List[TestCase]()
    multiplication_cases.append(
        TestCase(
            "1" + "0" * 10,  # 10^10
            "1" + "0" * 10,  # 10^10
            "1" + "0" * 20,
            "Very large multiplication",
        )
    )

    # Run addition test cases
    for i in range(len(extreme_cases)):
        var test_case = extreme_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a + b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    # Run subtraction test cases
    for i in range(len(subtraction_cases)):
        var test_case = subtraction_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a - b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    # Run multiplication test cases
    for i in range(len(multiplication_cases)):
        var test_case = multiplication_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a * b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    print("Extreme case tests passed!")


fn main() raises:
    print("Running BigUInt arithmetic tests")

    # Run addition tests
    test_add()

    # Run subtraction tests
    test_subtract()

    # Run multiplication tests
    test_multiply()

    # Run extreme cases tests
    test_extreme_cases()

    print("All BigUInt arithmetic tests passed!")
