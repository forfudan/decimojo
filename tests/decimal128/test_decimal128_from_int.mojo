"""
Comprehensive tests for the Decimal128.from_int() method.
Tests various scenarios to ensure proper conversion from integer values to Decimal128.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_integers() raises:
    """Test conversion of basic integers."""
    print("Testing basic integer conversions...")

    # Test case 1: Zero
    var result1 = Decimal128.from_int(0)
    testing.assert_equal(
        String(result1),
        "0",
        "from_int(0) should be '0', got " + String(result1),
    )

    # Test case 2: Positive integer
    var result2 = Decimal128.from_int(123)
    testing.assert_equal(
        String(result2),
        "123",
        "from_int(123) should be '123', got " + String(result2),
    )

    # Test case 3: Negative integer
    var result3 = Decimal128.from_int(-456)
    testing.assert_equal(
        String(result3),
        "-456",
        "from_int(-456) should be '-456', got " + String(result3),
    )

    # Test case 4: Simple arithmetic with from_int results
    var a = Decimal128.from_int(10)
    var b = Decimal128.from_int(5)
    var sum_result = a + b
    testing.assert_equal(
        String(sum_result),
        "15",
        "10 + 5 should be 15, got " + String(sum_result),
    )

    print("✓ Basic integer conversion tests passed!")


fn test_large_integers() raises:
    """Test conversion of large integers."""
    print("Testing large integer conversions...")

    # Test case 1: Large positive integer
    var large_pos = Decimal128.from_int(1000000000)  # 1 billion
    testing.assert_equal(
        String(large_pos),
        "1000000000",
        "from_int(1000000000) should be '1000000000'",
    )

    # Test case 2: Large negative integer
    var large_neg = Decimal128.from_int(-2000000000)  # -2 billion
    testing.assert_equal(
        String(large_neg),
        "-2000000000",
        "from_int(-2000000000) should be '-2000000000'",
    )

    # Test case 3: INT32_MAX
    var int32_max = Decimal128.from_int(2147483647)  # 2^31 - 1
    testing.assert_equal(
        String(int32_max),
        "2147483647",
        "from_int(INT32_MAX) should be '2147483647'",
    )

    # Test case 4: INT32_MIN
    var int32_min = Decimal128.from_int(-2147483648)  # -2^31
    testing.assert_equal(
        String(int32_min),
        "-2147483648",
        "from_int(INT32_MIN) should be '-2147483648'",
    )

    # Test case 5: VERY large integer (close to INT64_MAX)
    var very_large = Decimal128.from_int(9223372036854775807)  # 2^63 - 1
    testing.assert_equal(
        String(very_large),
        "9223372036854775807",
        "from_int(INT64_MAX) conversion failed",
    )

    print("✓ Large integer conversion tests passed!")


fn test_operations_with_from_int() raises:
    """Test arithmetic operations using from_int results."""
    print("Testing operations with from_int results...")

    # Test case 1: Addition
    var a1 = Decimal128.from_int(100)
    var b1 = Decimal128.from_int(50)
    var result1 = a1 + b1
    testing.assert_equal(
        String(result1), "150", "100 + 50 should be 150, got " + String(result1)
    )

    # Test case 2: Subtraction
    var a2 = Decimal128.from_int(100)
    var b2 = Decimal128.from_int(30)
    var result2 = a2 - b2
    testing.assert_equal(
        String(result2), "70", "100 - 30 should be 70, got " + String(result2)
    )

    # Test case 3: Multiplication
    var a3 = Decimal128.from_int(25)
    var b3 = Decimal128.from_int(4)
    var result3 = a3 * b3
    testing.assert_equal(
        String(result3), "100", "25 * 4 should be 100, got " + String(result3)
    )

    # Test case 4: Division
    var a4 = Decimal128.from_int(100)
    var b4 = Decimal128.from_int(5)
    var result4 = a4 / b4
    testing.assert_equal(
        String(result4), "20", "100 / 5 should be 20, got " + String(result4)
    )

    # Test case 5: Operation with mixed types
    var a5 = Decimal128.from_int(10)
    var b5 = Decimal128("3.5")  # String constructor
    var result5 = a5 * b5
    testing.assert_equal(
        String(result5),
        "35.0",
        "10 * 3.5 should be 35.0, got " + String(result5),
    )

    print("✓ Operations with from_int results tests passed!")


fn test_comparison_with_from_int() raises:
    """Test comparison operations using from_int results."""
    print("Testing comparisons with from_int results...")

    # Test case 1: Equality with same value
    var a1 = Decimal128.from_int(100)
    var b1 = Decimal128.from_int(100)
    testing.assert_true(a1 == b1, "from_int(100) should equal from_int(100)")

    # Test case 2: Equality with string constructor
    var a2 = Decimal128.from_int(123)
    var b2 = Decimal128("123")
    testing.assert_true(
        a2 == b2, "from_int(123) should equal Decimal128('123')"
    )

    # Test case 3: Less than
    var a3 = Decimal128.from_int(50)
    var b3 = Decimal128.from_int(100)
    testing.assert_true(
        a3 < b3, "from_int(50) should be less than from_int(100)"
    )

    # Test case 4: Greater than
    var a4 = Decimal128.from_int(200)
    var b4 = Decimal128.from_int(100)
    testing.assert_true(
        a4 > b4, "from_int(200) should be greater than from_int(100)"
    )

    # Test case 5: Equality with negative values
    var a5 = Decimal128.from_int(-500)
    var b5 = Decimal128("-500")
    testing.assert_true(
        a5 == b5, "from_int(-500) should equal Decimal128('-500')"
    )

    print("✓ Comparison with from_int results tests passed!")


fn test_properties() raises:
    """Test properties of from_int results."""
    print("Testing properties of from_int results...")

    # Test case 1: Sign of positive
    var pos = Decimal128.from_int(100)
    testing.assert_false(
        pos.is_negative(), "from_int(100) should not be negative"
    )

    # Test case 2: Sign of negative
    var neg = Decimal128.from_int(-100)
    testing.assert_true(neg.is_negative(), "from_int(-100) should be negative")

    # Test case 3: Scale of integer (should be 0)
    var integer = Decimal128.from_int(123)
    testing.assert_equal(
        integer.scale(),
        0,
        "Scale of from_int integer should be 0, got " + String(integer.scale()),
    )

    # Test case 4: Is_integer test
    var int_test = Decimal128.from_int(42)
    testing.assert_true(
        int_test.is_integer(), "from_int result should satisfy is_integer()"
    )

    # Test case 5: Coefficient correctness
    var coef_test = Decimal128.from_int(9876)
    testing.assert_equal(
        coef_test.coefficient(),
        UInt128(9876),
        "Coefficient should match the input integer value",
    )

    print("✓ Properties of from_int results tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for from_int."""
    print("Testing edge cases for from_int...")

    # Test case 1: Zero remains zero
    var zero = Decimal128.from_int(0)
    testing.assert_equal(
        String(zero), "0", "from_int(0) should be '0', got " + String(zero)
    )

    # Test case 2: Result should preserve sign for negative zero
    # Note: In most contexts, -0 becomes 0, but this tests the handling of negative zero
    var neg_zero = -0
    var dec_neg_zero = Decimal128.from_int(neg_zero)
    var is_neg_zero = dec_neg_zero.is_negative() and dec_neg_zero.is_zero()
    testing.assert_equal(
        is_neg_zero,
        False,
        "Negative zero should not preserve negative sign in Decimal128",
    )

    # Test case 3: INT64_MIN
    # Note: Most extreme negative value representable in Int
    var int64_min = Decimal128.from_int(-9223372036854775807 - 1)
    testing.assert_equal(
        String(int64_min),
        "-9223372036854775808",
        "from_int(INT64_MIN) should be '-9223372036854775808'",
    )

    # Test case 4: Alternative ways to create same value
    var from_int_val = Decimal128.from_int(12345)
    var from_string_val = Decimal128("12345")
    testing.assert_true(
        from_int_val == from_string_val,
        "from_int and from_string should create equal Decimals for same value",
    )

    # Test case 5: Powers of 10
    var power10 = Decimal128.from_int(10**9)  # 1 billion
    testing.assert_equal(String(power10), "1000000000", "from_int(10^9) failed")

    print("✓ Edge cases for from_int tests passed!")


fn test_from_int_with_scale() raises:
    """Test from_int with scale argument."""
    print("Testing from_int with scale argument...")

    # Test case 1: Positive integer with positive scale
    var result1 = Decimal128.from_int(123, 2)
    testing.assert_equal(
        String(result1),
        "1.23",
        "from_int(123, 2) should be '1.23', got " + String(result1),
    )
    testing.assert_equal(result1.scale(), 2, "Scale should be set to 2")

    # Test case 2: Negative integer with positive scale
    var result2 = Decimal128.from_int(-456, 3)
    testing.assert_equal(
        String(result2),
        "-0.456",
        "from_int(-456, 3) should be '-0.456', got " + String(result2),
    )
    testing.assert_equal(result2.scale(), 3, "Scale should be set to 3")

    # Test case 3: Zero with scale
    var result3 = Decimal128.from_int(0, 4)
    testing.assert_equal(
        String(result3),
        "0.0000",
        "from_int(0, 4) should be '0.0000', got " + String(result3),
    )
    testing.assert_equal(result3.scale(), 4, "Scale should be set to 4")

    # Test case 4: Positive integer
    var result4 = Decimal128.from_int(123, 2)
    testing.assert_equal(
        String(result4),
        "1.23",
        "from_int(123, 2) should be '1.23', got " + String(result4),
    )

    # Test case 5: Large scale (close to maximum)
    var result5 = Decimal128.from_int(1, 25)
    testing.assert_equal(
        String(result5),
        "0.0000000000000000000000001",
        "from_int(1, 25) incorrect string representation",
    )
    testing.assert_equal(result5.scale(), 25, "Scale should be set to 25")

    # Test case 6: Max scale
    var result6 = Decimal128.from_int(1, Decimal128.MAX_SCALE)
    testing.assert_equal(
        result6.scale(),
        Decimal128.MAX_SCALE,
        "Scale should be set to MAX_SCALE = " + String(Decimal128.MAX_SCALE),
    )

    # Test case 7: Arithmetic with scaled value
    var a7 = Decimal128.from_int(10, 1)  # 1.0
    var b7 = Decimal128.from_int(3, 2)  # 0.03
    var result7 = a7 / b7
    testing.assert_equal(
        String(result7),
        "33.333333333333333333333333333",
        "1.0 / 0.03 should give correct result",
    )

    # Test case 8: Comparison with different scales but same value
    var a8 = Decimal128.from_int(123, 0)  # 123
    var b8 = Decimal128.from_int(123, 2)  # 1.23
    testing.assert_true(
        a8 != b8, "from_int(123, 0) should not equal from_int(123, 2)"
    )

    print("✓ from_int with scale tests passed!")


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
    print("Running Decimal128.from_int() Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_integers, "Basic integer conversion test"
    )
    run_test_with_error_handling(
        test_large_integers, "Large integer conversion test"
    )
    run_test_with_error_handling(
        test_operations_with_from_int, "Operations with from_int test"
    )
    run_test_with_error_handling(
        test_comparison_with_from_int, "Comparison with from_int test"
    )
    run_test_with_error_handling(
        test_properties, "Properties of from_int results test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")
    run_test_with_error_handling(
        test_from_int_with_scale, "from_int with scale test"
    )

    print("All Decimal128.from_int() tests passed!")
