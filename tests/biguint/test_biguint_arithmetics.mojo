"""
Test BigUInt arithmetic operations including addition, subtraction, and multiplication.
BigUInt is an unsigned integer type, so it doesn't support negative values.
"""

from decimojo.biguint.biguint import BigUInt
import testing


fn test_add() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt addition...")

    # Test case 1: Simple addition of positive numbers
    var a1 = BigUInt("123")
    var b1 = BigUInt("456")
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1), "579", "Simple addition of positive numbers"
    )

    # Test case 2: Addition with zero
    var a5 = BigUInt("123")
    var b5 = BigUInt("0")
    var result5 = a5 + b5
    testing.assert_equal(String(result5), "123", "Addition with zero")

    # Test case 3: Addition with large numbers
    var a7 = BigUInt("99999999999999999999")
    var b7 = BigUInt("1")
    var result7 = a7 + b7
    testing.assert_equal(
        String(result7), "100000000000000000000", "Addition with large numbers"
    )

    # Test case 4: Addition causing multiple carries
    var a8 = BigUInt("9999999999")
    var b8 = BigUInt("1")
    var result8 = a8 + b8
    testing.assert_equal(
        String(result8), "10000000000", "Addition causing multiple carries"
    )

    # Test case 5: Addition with numbers of different sizes
    var a9 = BigUInt("12345")
    var b9 = BigUInt("9876543210")
    var result9 = a9 + b9
    testing.assert_equal(
        String(result9),
        "9876555555",
        "Addition with numbers of different sizes",
    )

    # Test case 6: Addition with very large numbers spanning multiple words
    var a10 = BigUInt("12345678901234567890123456789")
    var b10 = BigUInt("98765432109876543210987654321")
    var result10 = a10 + b10
    testing.assert_equal(
        String(result10),
        "111111111011111111101111111110",
        "Addition with very large numbers",
    )

    # Test case 7: Adding numbers that require carry propagation through multiple words
    var a11 = BigUInt("9" * 100)  # A 100-digit number of all 9's
    var b11 = BigUInt("1")
    var result11 = a11 + b11
    testing.assert_equal(
        String(result11),
        "1" + "0" * 100,
        "Addition with extensive carry propagation",
    )

    print("BigUInt addition tests passed!")


fn test_subtract() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt subtraction...")

    # Test case 1: Simple subtraction (larger - smaller)
    var a1 = BigUInt("456")
    var b1 = BigUInt("123")
    var result1 = a1 - b1
    testing.assert_equal(String(result1), "333", "Simple subtraction")

    # Test case 2: Subtraction with zero
    var a6 = BigUInt("123")
    var b6 = BigUInt("0")
    var result6 = a6 - b6
    testing.assert_equal(String(result6), "123", "Subtraction with zero")

    # Test case 3: Subtraction resulting in zero
    var a8 = BigUInt("123")
    var b8 = BigUInt("123")
    var result8 = a8 - b8
    testing.assert_equal(String(result8), "0", "Subtraction resulting in zero")

    # Test case 4: Subtraction with borrow
    var a9 = BigUInt("10000")
    var b9 = BigUInt("1")
    var result9 = a9 - b9
    testing.assert_equal(String(result9), "9999", "Subtraction with borrow")

    # Test case 5: Subtraction with multiple borrows
    var a10 = BigUInt("10000")
    var b10 = BigUInt("9999")
    var result10 = a10 - b10
    testing.assert_equal(
        String(result10), "1", "Subtraction with multiple borrows"
    )

    # Test case 6: Self subtraction (should be zero)
    var a12 = BigUInt("12345678901234567890")
    var result12 = a12 - a12
    testing.assert_equal(
        String(result12), "0", "Self subtraction should yield zero"
    )

    # Test case 7: Test underflow handling
    # Depending on implementation, this should either throw an error or wrap around
    # Let's check if it throws an error
    print("Testing underflow behavior (smaller - larger)...")
    var a2 = BigUInt("123")
    var b2 = BigUInt("456")
    var exception_caught = False
    try:
        var result2 = a2 - b2
        print("Implementation allows underflow, result is: " + String(result2))
        # If no error, maybe BigUInt wraps around or has special underflow handling
    except:
        exception_caught = True
        print("Implementation correctly throws error on underflow")

    print("BigUInt subtraction tests passed!")


fn test_multiply() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt multiplication...")

    # Test case 1: Simple multiplication
    var a1 = BigUInt("123")
    var b1 = BigUInt("456")
    var result1 = a1 * b1
    testing.assert_equal(String(result1), "56088", "Simple multiplication")

    # Test case 2: Multiplication by zero
    var a2 = BigUInt("123456789")
    var b2 = BigUInt("0")
    var result2 = a2 * b2
    testing.assert_equal(String(result2), "0", "Multiplication by zero")

    # Test case 3: Multiplication by one
    var a3 = BigUInt("123456789")
    var b3 = BigUInt("1")
    var result3 = a3 * b3
    testing.assert_equal(String(result3), "123456789", "Multiplication by one")

    # Test case 4: Multiplication of large numbers
    var a4 = BigUInt("12345")
    var b4 = BigUInt("67890")
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4), "838102050", "Multiplication of large numbers"
    )

    # Test case 5: Multiplication of very large numbers
    var a5 = BigUInt("9" * 10)  # 10 nines
    var b5 = BigUInt("9" * 10)  # 10 nines
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "9999999998" + "0" * 9 + "1",
        "Multiplication of very large numbers",
    )

    print("BigUInt multiplication tests passed!")


fn test_extreme_cases() raises:
    print("------------------------------------------------------")
    print("Testing extreme cases...")

    # Test case 1: Addition of very large numbers
    var a1 = BigUInt("1" + "0" * 1000)  # 10^1000
    var b1 = BigUInt("5" + "0" * 999)  # 5×10^999
    var sum1 = a1 + b1
    testing.assert_equal(
        String(sum1), "1" + "5" + "0" * 999, "Addition of very large numbers"
    )

    # Test case 2: Adding numbers that require carry propagation through many words
    var a2 = BigUInt("9" * 100)  # A 100-digit number of all 9's
    var b2 = BigUInt("1")
    var result2 = a2 + b2
    testing.assert_equal(
        String(result2),
        "1" + "0" * 100,
        "Addition with extensive carry propagation",
    )

    # Test case 3: Very large subtraction within range
    var a3 = BigUInt("1" + "0" * 200)  # 10^200
    var b3 = BigUInt("1")
    var result3 = a3 - b3
    testing.assert_equal(
        String(result3), "9" + "9" * 199, "Very large subtraction within range"
    )

    # Test case 4: Very large multiplication
    var a4 = BigUInt("1" + "0" * 10)  # 10^10
    var b4 = BigUInt("1" + "0" * 10)  # 10^10
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4), "1" + "0" * 20, "Very large multiplication"
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
