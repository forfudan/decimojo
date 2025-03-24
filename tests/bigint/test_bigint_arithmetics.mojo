"""
Test BigInt arithmetic operations including addition, subtraction, and negation.
"""

from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
import testing


fn test_add() raises:
    print("------------------------------------------------------")
    print("Testing BigInt addition...")

    # Test case 1: Simple addition of positive numbers
    var a1 = BigInt("123")
    var b1 = BigInt("456")
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1), "579", "Simple addition of positive numbers"
    )

    # Test case 2: Addition with negative numbers
    var a2 = BigInt("123")
    var b2 = BigInt("-456")
    var result2 = a2 + b2
    testing.assert_equal(
        String(result2), "-333", "Addition with negative number"
    )

    # Test case 3: Addition resulting in negative
    var a3 = BigInt("-789")
    var b3 = BigInt("456")
    var result3 = a3 + b3
    testing.assert_equal(
        String(result3), "-333", "Addition resulting in negative"
    )

    # Test case 4: Addition of negative numbers
    var a4 = BigInt("-123")
    var b4 = BigInt("-456")
    var result4 = a4 + b4
    testing.assert_equal(
        String(result4), "-579", "Addition of negative numbers"
    )

    # Test case 5: Addition with zero
    var a5 = BigInt("123")
    var b5 = BigInt("0")
    var result5 = a5 + b5
    testing.assert_equal(String(result5), "123", "Addition with zero")

    # Test case 6: Addition resulting in zero
    var a6 = BigInt("123")
    var b6 = BigInt("-123")
    var result6 = a6 + b6
    testing.assert_equal(String(result6), "0", "Addition resulting in zero")

    # Test case 7: Addition with large numbers
    var a7 = BigInt("99999999999999999999")
    var b7 = BigInt("1")
    var result7 = a7 + b7
    testing.assert_equal(
        String(result7), "100000000000000000000", "Addition with large numbers"
    )

    # Test case 8: Addition causing multiple carries
    var a8 = BigInt("9999999999")
    var b8 = BigInt("1")
    var result8 = a8 + b8
    testing.assert_equal(
        String(result8), "10000000000", "Addition causing multiple carries"
    )

    # Test case 9: Addition with numbers of different sizes
    var a9 = BigInt("12345")
    var b9 = BigInt("9876543210")
    var result9 = a9 + b9
    testing.assert_equal(
        String(result9),
        "9876555555",
        "Addition with numbers of different sizes",
    )

    # Test case 10: Addition with very large numbers spanning multiple words
    var a10 = BigInt("12345678901234567890123456789")
    var b10 = BigInt("98765432109876543210987654321")
    var result10 = a10 + b10
    testing.assert_equal(
        String(result10),
        "111111111011111111101111111110",
        "Addition with very large numbers",
    )

    # Test case 11: Adding numbers that require carry propagation through multiple words
    var a11 = BigInt("9" * 100)  # A 100-digit number of all 9's
    var b11 = BigInt("1")
    var result11 = a11 + b11
    testing.assert_equal(
        String(result11),
        "1" + "0" * 100,
        "Addition with extensive carry propagation",
    )

    print("BigInt addition tests passed!")


fn test_negation() raises:
    print("------------------------------------------------------")
    print("Testing BigInt negation...")

    # Test case 1: Negate positive number
    var a1 = BigInt("123")
    var result1 = -a1
    testing.assert_equal(String(result1), "-123", "Negating positive number")

    # Test case 2: Negate negative number
    var a2 = BigInt("-456")
    var result2 = -a2
    testing.assert_equal(String(result2), "456", "Negating negative number")

    # Test case 3: Negate zero
    var a3 = BigInt("0")
    var result3 = -a3
    testing.assert_equal(String(result3), "0", "Negating zero (signed zero)")

    # Test case 4: Double negation
    var a4 = BigInt("123")
    var result4 = -(-a4)
    testing.assert_equal(String(result4), "123", "Double negation")

    # Test case 5: Negate large number
    var a5 = BigInt("9" * 50)  # 50 nines
    var result5 = -a5
    testing.assert_equal(
        String(result5), "-" + "9" * 50, "Negating large number"
    )

    # Test case 6: Triple negation
    var a6 = BigInt("123")
    var result6 = -(-(-a6))
    testing.assert_equal(String(result6), "-123", "Triple negation")

    print("BigInt negation tests passed!")


fn test_abs() raises:
    print("------------------------------------------------------")
    print("Testing BigInt absolute value...")

    # Test case 1: Absolute value of positive number
    var a1 = BigInt("123")
    var result1 = abs(a1)
    testing.assert_equal(
        String(result1), "123", "Absolute value of positive number"
    )

    # Test case 2: Absolute value of negative number
    var a2 = BigInt("-456")
    var result2 = abs(a2)
    testing.assert_equal(
        String(result2), "456", "Absolute value of negative number"
    )

    # Test case 3: Absolute value of zero
    var a3 = BigInt("0")
    var result3 = abs(a3)
    testing.assert_equal(String(result3), "0", "Absolute value of zero")

    # Test case 4: Absolute value of large negative number
    var a4 = BigInt("-" + "9" * 50)  # 50 nines
    var result4 = abs(a4)
    testing.assert_equal(
        String(result4), "9" * 50, "Absolute value of large negative number"
    )

    print("BigInt absolute value tests passed!")


fn test_subtract() raises:
    print("------------------------------------------------------")
    print("Testing BigInt subtraction...")

    # Test case 1: Simple subtraction
    var a1 = BigInt("456")
    var b1 = BigInt("123")
    var result1 = a1 - b1
    testing.assert_equal(String(result1), "333", "Simple subtraction")

    # Test case 2: Subtraction resulting in negative
    var a2 = BigInt("123")
    var b2 = BigInt("456")
    var result2 = a2 - b2
    testing.assert_equal(
        String(result2), "-333", "Subtraction resulting in negative"
    )

    # Test case 3: Subtracting negative number (essentially addition)
    var a3 = BigInt("123")
    var b3 = BigInt("-456")
    var result3 = a3 - b3
    testing.assert_equal(String(result3), "579", "Subtracting negative number")

    # Test case 4: Negative minus positive
    var a4 = BigInt("-123")
    var b4 = BigInt("456")
    var result4 = a4 - b4
    testing.assert_equal(String(result4), "-579", "Negative minus positive")

    # Test case 5: Negative minus negative
    var a5 = BigInt("-456")
    var b5 = BigInt("-123")
    var result5 = a5 - b5
    testing.assert_equal(String(result5), "-333", "Negative minus negative")

    # Test case 6: Subtraction with zero
    var a6 = BigInt("123")
    var b6 = BigInt("0")
    var result6 = a6 - b6
    testing.assert_equal(String(result6), "123", "Subtraction with zero")

    # Test case 7: Zero minus a number
    var a7 = BigInt("0")
    var b7 = BigInt("123")
    var result7 = a7 - b7
    testing.assert_equal(String(result7), "-123", "Zero minus a number")

    # Test case 8: Subtraction resulting in zero
    var a8 = BigInt("123")
    var b8 = BigInt("123")
    var result8 = a8 - b8
    testing.assert_equal(String(result8), "0", "Subtraction resulting in zero")

    # Test case 9: Subtraction with borrow
    var a9 = BigInt("10000")
    var b9 = BigInt("1")
    var result9 = a9 - b9
    testing.assert_equal(String(result9), "9999", "Subtraction with borrow")

    # Test case 10: Subtraction with multiple borrows
    var a10 = BigInt("10000")
    var b10 = BigInt("9999")
    var result10 = a10 - b10
    testing.assert_equal(
        String(result10), "1", "Subtraction with multiple borrows"
    )

    # Test case 11: Subtraction of large numbers
    var a11 = BigInt("9" * 50)  # 50 nines
    var b11 = BigInt("1" + "0" * 49)  # 1 followed by 49 zeros (10^49)
    var result11 = a11 - b11
    testing.assert_equal(
        String(result11), "8" + "9" * 49, "Subtraction of large numbers"
    )

    # Test case 12: Self subtraction (should be zero)
    var a12 = BigInt("12345678901234567890")
    var result12 = a12 - a12
    testing.assert_equal(
        String(result12), "0", "Self subtraction should yield zero"
    )

    # Test case 13: Verify a - b = -(b - a)
    var a13 = BigInt("123456")
    var b13 = BigInt("789012")
    var result13a = a13 - b13
    var result13b = -(b13 - a13)
    testing.assert_equal(
        String(result13a), String(result13b), "a - b should equal -(b - a)"
    )

    # Test case 14: Subtraction with numbers of different sizes
    var a14 = BigInt("9876543210")
    var b14 = BigInt("12345")
    var result14 = a14 - b14
    testing.assert_equal(
        String(result14),
        "9876530865",
        "Subtraction with numbers of different sizes",
    )

    print("BigInt subtraction tests passed!")


fn test_extreme_cases() raises:
    print("------------------------------------------------------")
    print("Testing extreme cases...")

    # Test case 1: Addition/subtraction of very large numbers
    var a1 = BigInt("1" + "0" * 1000)  # 10^1000
    var b1 = BigInt("5" + "0" * 999)  # 5×10^999
    var sum1 = a1 + b1
    var diff1 = a1 - b1

    testing.assert_equal(
        String(sum1), "1" + "5" + "0" * 999, "Addition of very large numbers"
    )
    testing.assert_equal(
        String(diff1), "5" + "0" * 999, "Subtraction of very large numbers"
    )

    # Test case 2: Adding numbers that require carry propagation through many words
    var a2 = BigInt("9" * 100)  # A 100-digit number of all 9's
    var b2 = BigInt("1")
    var result2 = a2 + b2
    testing.assert_equal(
        String(result2),
        "1" + "0" * 100,
        "Addition with extensive carry propagation",
    )

    # Test case 3: Subtracting from zero with large numbers
    var a3 = BigInt("0")
    var b3 = BigInt("9" * 50)  # 50 nines
    var result3 = a3 - b3
    testing.assert_equal(
        String(result3), "-" + "9" * 50, "Subtracting large number from zero"
    )

    # Test case 4: Adding opposite large numbers (should equal zero)
    var a4 = BigInt("1" + "2" * 50)  # Large number
    var b4 = BigInt("-" + "1" + "2" * 50)  # Negative of a4
    var result4 = a4 + b4
    testing.assert_equal(String(result4), "0", "Adding opposite large numbers")

    print("Extreme case tests passed!")


fn main() raises:
    print("Running BigInt arithmetic tests")

    # Run addition tests
    test_add()

    # Run negation tests
    test_negation()

    # Run absolute value tests
    test_abs()

    # Run subtraction tests
    test_subtract()

    # Run extreme cases tests
    test_extreme_cases()

    print("All BigInt arithmetic tests passed!")
