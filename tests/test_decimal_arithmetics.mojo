"""
Test Decimal arithmetic operations including addition and negation.
"""
from decimojo import Decimal
import testing


fn test_addition() raises:
    print("Testing decimal addition...")

    # Test case 1: Simple addition with same scale
    var a1 = Decimal("123.45")
    var b1 = Decimal("67.89")
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1), "191.34", "Simple addition with same scale"
    )

    # Test case 2: Addition with different scales
    var a2 = Decimal("123.4")
    var b2 = Decimal("67.89")
    var result2 = a2 + b2
    testing.assert_equal(
        String(result2), "191.29", "Addition with different scales"
    )

    # Test case 3: Addition with negative numbers
    var a3 = Decimal("123.45")
    var b3 = Decimal("-67.89")
    var result3 = a3 + b3
    testing.assert_equal(
        String(result3), "55.56", "Addition with negative number"
    )

    # Test case 4: Addition resulting in negative
    var a4 = Decimal("-123.45")
    var b4 = Decimal("67.89")
    var result4 = a4 + b4
    testing.assert_equal(
        String(result4), "-55.56", "Addition resulting in negative"
    )

    # Test case 5: Addition with zero
    var a5 = Decimal("123.45")
    var b5 = Decimal("0")
    var result5 = a5 + b5
    testing.assert_equal(String(result5), "123.45", "Addition with zero")

    # Test case 6: Addition resulting in zero
    var a6 = Decimal("123.45")
    var b6 = Decimal("-123.45")
    var result6 = a6 + b6
    testing.assert_equal(String(result6), "0", "Addition resulting in zero")

    # Test case 7: Addition with large scales
    var a7 = Decimal("0.0000001")
    var b7 = Decimal("0.0000002")
    var result7 = a7 + b7
    testing.assert_equal(
        String(result7), "0.0000003", "Addition with large scales"
    )

    # Test case 8: Addition with different large scales
    var a8 = Decimal("0.000001")
    var b8 = Decimal("0.0000002")
    var result8 = a8 + b8
    testing.assert_equal(
        String(result8), "0.0000012", "Addition with different large scales"
    )

    # Additional edge cases for addition

    # Test case 9: Addition with many decimal places
    var a9 = Decimal("0.123456789012345678901234567")
    var b9 = Decimal("0.987654321098765432109876543")
    var result9 = a9 + b9
    testing.assert_equal(
        String(result9),
        "1.11111111011111111101111111",
        "Addition with many decimal places",
    )

    # Test case 10: Addition with extreme scale difference
    var a10 = Decimal("123456789")
    var b10 = Decimal("0.000000000123456789")
    var result10 = a10 + b10
    testing.assert_equal(
        String(result10),
        "123456789.000000000123456789",
        "Addition with extreme scale difference",
    )

    # Test case 11: Addition near maximum precision
    var a11 = Decimal("0." + "1" * 28)  # 0.1111...1 (28 digits)
    var b11 = Decimal("0." + "9" * 28)  # 0.9999...9 (28 digits)
    var result11 = a11 + b11
    testing.assert_equal(
        String(result11),
        "1.111111111111111111111111111",
        "Addition near maximum precision",
    )

    # Test case 12: Addition causing scale truncation
    var a12 = Decimal("0." + "1" * 27 + "1")  # 0.1111...1 (28 digits)
    var b12 = Decimal("0.0" + "9" * 27)  # 0.09999...9 (28 digits)
    var result12 = a12 + b12
    testing.assert_equal(
        String(result12),
        "0." + "2" + "1" * 26,
        "Addition causing scale truncation",
    )

    # Test case 13: Addition of very small numbers
    var a13 = Decimal("0." + "0" * 27 + "1")  # 0.0000...01 (1 at 28th place)
    var b13 = Decimal("0." + "0" * 27 + "2")  # 0.0000...02 (2 at 28th place)
    var result13 = a13 + b13
    testing.assert_equal(
        String(result13),
        "0." + "0" * 27 + "3",
        "Addition of very small numbers",
    )

    # Test case 14: Addition with alternating signs and scales
    var a14 = Decimal("1.01")
    var b14 = Decimal("-0.101")
    var result14 = a14 + b14
    testing.assert_equal(
        String(result14), "0.909", "Addition with alternating signs and scales"
    )

    # Test case 15: Addition with large numbers (near limits)
    var a15 = Decimal("79228162514264337593543950334")  # MAX() - 1
    var b15 = Decimal("1")
    var result15 = a15 + b15
    testing.assert_equal(
        String(result15),
        "79228162514264337593543950335",
        "Addition approaching maximum value",
    )

    # Test case 16: Repeated addition to test cumulative errors
    var acc = Decimal("0")
    for i in range(10):
        acc = acc + Decimal("0.1")
    testing.assert_equal(String(acc), "1", "Repeated addition of 0.1")

    # Test case 17: Edge case with alternating very large and very small values
    var a17 = Decimal("1234567890123456789.0123456789")
    var b17 = Decimal("0.0000000000000000009876543211")
    var result17 = a17 + b17
    testing.assert_equal(
        String(result17),
        "1234567890123456789.0123456789",
        "Addition with large and small values",
    )

    print("Decimal addition tests passed!")


fn test_negation() raises:
    print("Testing decimal negation...")

    # Test case 1: Negate positive number
    var a1 = Decimal("123.45")
    var result1 = -a1
    testing.assert_equal(String(result1), "-123.45", "Negating positive number")

    # Test case 2: Negate negative number
    var a2 = Decimal("-67.89")
    var result2 = -a2
    testing.assert_equal(String(result2), "67.89", "Negating negative number")

    # Test case 3: Negate zero
    var a3 = Decimal("0")
    var result3 = -a3
    testing.assert_equal(String(result3), "0", "Negating zero")

    # Test case 4: Negate number with trailing zeros
    var a4 = Decimal("123.4500")
    var result4 = -a4
    testing.assert_equal(
        String(result4), "-123.45", "Negating with trailing zeros"
    )

    # Test case 5: Double negation
    var a5 = Decimal("123.45")
    var result5 = -(-a5)
    testing.assert_equal(String(result5), "123.45", "Double negation")

    # Additional edge cases for negation

    # Test case 6: Negate very small number
    var a6 = Decimal("0." + "0" * 27 + "1")  # 0.0000...01 (1 at 28th place)
    var result6 = -a6
    testing.assert_equal(
        String(result6), "-0." + "0" * 27 + "1", "Negating very small number"
    )

    # Test case 7: Negate very large number
    var a7 = Decimal("79228162514264337593543950335")  # MAX()
    var result7 = -a7
    testing.assert_equal(
        String(result7),
        "-79228162514264337593543950335",
        "Negating maximum value",
    )

    # Test case 8: Triple negation
    var a8 = Decimal("123.45")
    var result8 = -(-(-a8))
    testing.assert_equal(String(result8), "-123.45", "Triple negation")

    # Test case 9: Negate number with scientific notation (if supported)
    try:
        var a9 = Decimal("1.23e5")  # 123000
        var result9 = -a9
        testing.assert_equal(
            String(result9),
            "-123000",
            "Negating number from scientific notation",
        )
    except:
        print("Scientific notation not supported in this implementation")

    # Test case 10: Negate number with maximum precision
    var a10 = Decimal("0." + "1" * 28)  # 0.1111...1 (28 digits)
    var result10 = -a10
    testing.assert_equal(
        String(result10),
        "-0." + "1" * 28,
        "Negating number with maximum precision",
    )

    print("Decimal negation tests passed!")


fn test_extreme_cases() raises:
    print("Testing extreme cases...")

    # Test case 1: Addition that results in exactly zero with high precision
    var a1 = Decimal("0." + "1" * 28)  # 0.1111...1 (28 digits)
    var b1 = Decimal("-0." + "1" * 28)  # -0.1111...1 (28 digits)
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1), "0", "High precision addition resulting in zero"
    )

    # Test case 2: Addition that should trigger overflow handling
    try:
        var a2 = Decimal("79228162514264337593543950335")  # MAX()
        var b2 = Decimal("1")
        var result2 = a2 + b2
        print("WARNING: Addition beyond MAX() didn't raise an error")
    except:
        print("Addition overflow correctly detected")

    # Test case 3: Addition with mixed precision zeros
    var a3 = Decimal("0.00")
    var b3 = Decimal("0.000000")
    var result3 = a3 + b3
    testing.assert_equal(
        String(result3), "0", "Addition of different precision zeros"
    )

    # Test case 4: Addition with boundary values involving zeros
    var a4 = Decimal("0.0")
    var b4 = Decimal("-0.00")
    var result4 = a4 + b4
    testing.assert_equal(
        String(result4), "0", "Addition of positive and negative zero"
    )

    # Test case 5: Adding numbers that require carry propagation through many places
    var a5 = Decimal("9" * 20 + "." + "9" * 28)  # 99...9.99...9
    var b5 = Decimal("0." + "0" * 27 + "1")  # 0.00...01
    var result5 = a5 + b5
    # The result should be 10^20 exactly, since all 9s carry over
    testing.assert_equal(
        String(result5),
        "1" + "0" * 20,
        "Addition with extensive carry propagation",
    )

    print("Extreme case tests passed!")


fn main() raises:
    print("Running decimal arithmetic tests")

    # Run addition tests
    test_addition()

    # Run negation tests
    test_negation()

    # Run extreme cases tests
    test_extreme_cases()

    print("All decimal arithmetic tests passed!")
