"""
Comprehensive tests for the multiplication operation of the BigInt type.
"""

import testing
from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics


fn test_basic_multiplication() raises:
    """Test basic integer multiplication."""
    print("Testing basic multiplication...")

    # Test case 1: Simple integer multiplication
    var a1 = BigInt(5)
    var b1 = BigInt(3)
    var result1 = a1 * b1
    testing.assert_equal(
        String(result1), "15", "5 * 3 should equal 15, got " + String(result1)
    )

    # Test case 2: Multiplication with larger numbers
    var a2 = BigInt(125)
    var b2 = BigInt(40)
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "5000",
        "125 * 40 should equal 5000, got " + String(result2),
    )

    # Test case 3: Multiplication with different sized numbers
    var a3 = BigInt(1234)
    var b3 = BigInt(9876)
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3),
        "12186984",
        "1234 * 9876 should equal 12186984, got " + String(result3),
    )

    # Test case 4: Larger numbers multiplication
    var a4 = BigInt(999999)
    var b4 = BigInt(1001)
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4),
        "1000998999",
        "999999 * 1001 should equal 1000998999, got " + String(result4),
    )

    # Test case 5: Multiplication with a two-digit number
    var a5 = BigInt(12345)
    var b5 = BigInt(67)
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "827115",
        "12345 * 67 should equal 827115, got " + String(result5),
    )

    print("✓ Basic multiplication tests passed!")


fn test_special_cases() raises:
    """Test multiplication with special cases like zero and one."""
    print("Testing multiplication with special cases...")

    # Test case 1: Multiplication by zero
    var a1 = BigInt(12345)
    var zero = BigInt(0)
    var result1 = a1 * zero
    testing.assert_equal(
        String(result1), "0", "12345 * 0 should equal 0, got " + String(result1)
    )

    # Test case 2: Multiplication by one
    var a2 = BigInt(12345)
    var one = BigInt(1)
    var result2 = a2 * one
    testing.assert_equal(
        String(result2),
        "12345",
        "12345 * 1 should equal 12345, got " + String(result2),
    )

    # Test case 3: Multiplication of zero by any number
    var a3 = BigInt(0)
    var b3 = BigInt(9876)
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3), "0", "0 * 9876 should equal 0, got " + String(result3)
    )

    # Test case 4: Multiplication by negative one
    var a4 = BigInt(12345)
    var neg_one = BigInt(-1)
    var result4 = a4 * neg_one
    testing.assert_equal(
        String(result4),
        "-12345",
        "12345 * -1 should equal -12345, got " + String(result4),
    )

    # Test case 5: Multiplication of very large values by one
    var large = BigInt("1" + "0" * 50)  # 10^50
    var result5 = large * one
    testing.assert_equal(
        String(result5),
        "1" + "0" * 50,
        "large * 1 should equal large, got " + String(result5),
    )

    print("✓ Special cases multiplication tests passed!")


fn test_negative_multiplication() raises:
    """Test multiplication involving negative numbers."""
    print("Testing multiplication with negative numbers...")

    # Test case 1: Negative * positive
    var a1 = BigInt(-5)
    var b1 = BigInt(3)
    var result1 = a1 * b1
    testing.assert_equal(
        String(result1),
        "-15",
        "-5 * 3 should equal -15, got " + String(result1),
    )

    # Test case 2: Positive * negative
    var a2 = BigInt(5)
    var b2 = BigInt(-3)
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "-15",
        "5 * -3 should equal -15, got " + String(result2),
    )

    # Test case 3: Negative * negative
    var a3 = BigInt(-5)
    var b3 = BigInt(-3)
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3), "15", "-5 * -3 should equal 15, got " + String(result3)
    )

    # Test case 4: Larger numbers with negative and positive
    var a4 = BigInt("-25000")
    var b4 = BigInt("420")
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4),
        "-10500000",
        "-25000 * 420 should equal -10500000, got " + String(result4),
    )

    # Test case 5: Two large negative numbers
    var a5 = BigInt("-99999")
    var b5 = BigInt("-99999")
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "9999800001",
        "-99999 * -99999 should equal 9999800001, got " + String(result5),
    )

    print("✓ Negative number multiplication tests passed!")


fn test_large_number_multiplication() raises:
    """Test multiplication with very large numbers."""
    print("Testing multiplication with large numbers...")

    # Test case 1: Multiplication of large numbers
    var a1 = BigInt("12345678901234567890")
    var b1 = BigInt("98765432109876543210")
    var result1 = a1 * b1
    testing.assert_equal(
        String(result1),
        "1219326311370217952237463801111263526900",
        "Large number multiplication gave incorrect result",
    )

    # Test case 2: Multiplication resulting in a number with many digits
    var a2 = BigInt("9" * 20)  # 20 nines
    var b2 = BigInt("9" * 20)  # 20 nines
    var result2 = a2 * b2
    testing.assert_equal(
        String(result2),
        "9" * 19 + "8" + "0" * 19 + "1",
        "Very large multiplication gave incorrect result",
    )

    # Test case 3: Multiplication by a power of 10
    var a3 = BigInt("12345")
    var b3 = BigInt("10" + "0" * 10)  # 10^11
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3),
        "12345" + "0" * 11,
        "Multiplication by power of 10 gave incorrect result",
    )

    # Test case 4: Multiplication of large with small
    var a4 = BigInt("9" * 50)  # 50 nines
    var b4 = BigInt("2")
    var result4 = a4 * b4
    testing.assert_equal(
        String(result4),
        "1" + "9" * 49 + "8",
        "Large * small multiplication gave incorrect result",
    )

    # Test case 5: Multiplication involving different internal word sizes
    var a5 = BigInt("1" + "0" * 20)  # 10^20
    var b5 = BigInt("1" + "0" * 18)  # 10^18
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "1" + "0" * 38,
        "Word-crossing multiplication gave incorrect result",
    )

    print("✓ Large number multiplication tests passed!")


fn test_commutative_property() raises:
    """Test the commutative property of multiplication (a*b = b*a)."""
    print("Testing commutative property of multiplication...")

    # Test pair 1: Small integers
    var a1 = BigInt(10)
    var b1 = BigInt(20)
    var result1a = a1 * b1
    var result1b = b1 * a1
    testing.assert_equal(
        String(result1a),
        String(result1b),
        "Commutative property failed for " + String(a1) + " and " + String(b1),
    )

    # Test pair 2: One large and one small number
    var a2 = BigInt("12345678901234567890")
    var b2 = BigInt(42)
    var result2a = a2 * b2
    var result2b = b2 * a2
    testing.assert_equal(
        String(result2a),
        String(result2b),
        "Commutative property failed for " + String(a2) + " and " + String(b2),
    )

    # Test pair 3: Negative and positive
    var a3 = BigInt(-500)
    var b3 = BigInt(700)
    var result3a = a3 * b3
    var result3b = b3 * a3
    testing.assert_equal(
        String(result3a),
        String(result3b),
        "Commutative property failed for " + String(a3) + " and " + String(b3),
    )

    # Test pair 4: Two large numbers
    var a4 = BigInt("9" * 15)  # 15 nines
    var b4 = BigInt("8" * 12)  # 12 eights
    var result4a = a4 * b4
    var result4b = b4 * a4
    testing.assert_equal(
        String(result4a),
        String(result4b),
        "Commutative property failed for " + String(a4) + " and " + String(b4),
    )

    # Test pair 5: Very large number and zero/one
    var a5 = BigInt("1" + "0" * 50)  # 10^50
    var b5 = BigInt(0)
    var result5a = a5 * b5
    var result5b = b5 * a5
    testing.assert_equal(
        String(result5a),
        String(result5b),
        "Commutative property failed for " + String(a5) + " and " + String(b5),
    )

    print("✓ Commutative property tests passed!")


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
    print("Running BigInt Multiplication Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_multiplication, "Basic multiplication test"
    )
    run_test_with_error_handling(test_special_cases, "Special cases test")
    run_test_with_error_handling(
        test_negative_multiplication, "Negative number multiplication test"
    )
    run_test_with_error_handling(
        test_large_number_multiplication, "Large number multiplication test"
    )
    run_test_with_error_handling(
        test_commutative_property, "Commutative property test"
    )

    print("All BigInt multiplication tests passed!")
