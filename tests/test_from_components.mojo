"""
Test Decimal creation from integer, float, or string values.
"""

# TODO: Split into separate test files for each type of constructor

from decimojo.prelude import dm, Decimal, RoundingMode
import testing


fn test_decimal_from_components() raises:
    print("------------------------------------------------------")
    print("Testing Decimal Creation from Components")

    # Test case 1: Zero with zero scale
    var zero = Decimal(0, 0, 0, 0, False)
    testing.assert_equal(String(zero), "0", "Zero with scale 0")

    # Test case 2: One with zero scale
    var one = Decimal(1, 0, 0, 0, False)
    testing.assert_equal(String(one), "1", "One with scale 0")

    # Test case 3: Negative one
    var neg_one = Decimal(1, 0, 0, 0, True)
    testing.assert_equal(String(neg_one), "-1", "Negative one")

    # Test case 4: Simple number with scale
    var with_scale = Decimal(12345, 0, 0, 2, False)
    testing.assert_equal(
        String(with_scale), "123.45", "Simple number with scale 2"
    )

    # Test case 5: Negative number with scale
    var neg_with_scale = Decimal(12345, 0, 0, 2, True)
    testing.assert_equal(
        String(neg_with_scale), "-123.45", "Negative number with scale 2"
    )

    # Test case 6: Larger number using mid
    var large = Decimal(0xFFFFFFFF, 5, 0, 0, False)
    var expected_large = Decimal(String(0xFFFFFFFF + 5 * 4294967296))
    testing.assert_equal(
        String(large), String(expected_large), "Large number using mid field"
    )

    # Test case 7: Verify scale is correctly stored
    var high_scale = Decimal(123, 0, 0, 10, False)
    testing.assert_equal(
        high_scale.scale(), 10, "Scale should be correctly stored"
    )
    testing.assert_equal(
        String(high_scale), "0.0000000123", "High scale correctly formatted"
    )

    # Test case 8: Test large scale with negative number
    var neg_high_scale = Decimal(123, 0, 0, 10, True)
    testing.assert_equal(
        String(neg_high_scale),
        "-0.0000000123",
        "Negative high scale correctly formatted",
    )

    # Test case 9: Test sign flag
    testing.assert_equal(
        zero.is_negative(), False, "Zero should not be negative"
    )
    testing.assert_equal(one.is_negative(), False, "One should not be negative")
    testing.assert_equal(
        neg_one.is_negative(), True, "Negative one should be negative"
    )

    # Test case 10: With high component
    var with_high = Decimal(0, 0, 3, 0, False)
    testing.assert_equal(
        String(with_high),
        "55340232221128654848",
        "High component correctly handled",
    )

    # Test case 11: Maximum possible scale
    var max_scale = Decimal(123, 0, 0, 28, False)
    testing.assert_equal(max_scale.scale(), 28, "Maximum scale should be 28")

    # Test case 12: Overflow scale protection
    try:
        var _overflow_scale = Decimal(123, 0, 0, 100, False)
    except:
        print("Successfully caught overflow scale error")

    print("All component constructor tests passed!")


fn main() raises:
    test_decimal_from_components()
