"""
Tests for the utility functions in the decimojo.utility module.
"""

from testing import assert_equal, assert_true
import max

from decimojo.prelude import *
from decimojo.utility import truncate_to_max, number_of_significant_digits


fn test_number_of_significant_digits() raises:
    """Tests for number_of_significant_digits function."""
    print("Testing number_of_significant_digits...")

    # Test with simple UInt128 values
    assert_equal(number_of_significant_digits(UInt128(0)), 0)
    assert_equal(number_of_significant_digits(UInt128(1)), 1)
    assert_equal(number_of_significant_digits(UInt128(9)), 1)
    assert_equal(number_of_significant_digits(UInt128(10)), 2)
    assert_equal(number_of_significant_digits(UInt128(123)), 3)
    assert_equal(number_of_significant_digits(UInt128(9999)), 4)

    # Test with powers of 10
    assert_equal(number_of_significant_digits(UInt128(10**6)), 7)
    assert_equal(number_of_significant_digits(UInt128(10**12)), 13)

    # Test with UInt256 values
    assert_equal(number_of_significant_digits(UInt256(0)), 0)
    assert_equal(number_of_significant_digits(UInt256(123456789)), 9)
    assert_equal(number_of_significant_digits(UInt256(10) ** 20), 21)

    # Test with large values approaching UInt128 maximum
    var large_value = UInt128(Decimal.MAX_AS_UINT128)
    assert_equal(number_of_significant_digits(large_value), 29)

    # Test with values larger than UInt128 max (using UInt256)
    var very_large = UInt256(Decimal.MAX_AS_UINT128) * UInt256(10)
    assert_equal(number_of_significant_digits(very_large), 30)

    print("✓ All number_of_significant_digits tests passed!")


fn test_truncate_to_max_below_max() raises:
    """Test truncate_to_max with values below MAX_AS_UINT128."""
    print("Testing truncate_to_max with values below MAX...")

    # Test with values that should remain unchanged
    var small_value = UInt128(123456)
    assert_equal(truncate_to_max(small_value), small_value)

    # Test with UInt256
    var small_value_256 = UInt256(7654321)
    assert_equal(truncate_to_max(small_value_256), small_value_256)

    # Test with value exactly at MAX_AS_UINT128
    var max_value = UInt128(Decimal.MAX_AS_UINT128)
    assert_equal(truncate_to_max(max_value), max_value)

    # Test with UInt256 at exact MAX value
    var max_value_256 = UInt256(Decimal.MAX_AS_UINT128)
    assert_equal(truncate_to_max(max_value_256), max_value_256)

    print("✓ All truncate_to_max tests with values below MAX passed!")


fn test_truncate_to_max_above_max() raises:
    """Test truncate_to_max with values above MAX_AS_UINT128."""
    print("Testing truncate_to_max with values above MAX...")

    # Test with value MAX + 1 (should round appropriately)
    var max_plus_1 = UInt256(Decimal.MAX_AS_UINT128) + UInt256(1)
    var result = truncate_to_max(max_plus_1)

    # The result should be exactly MAX or a truncated value (depending on rounding)
    assert_true(result <= UInt256(Decimal.MAX_AS_UINT128))

    # Test with a value that requires truncating 1 digit, rounding down
    # 79228162514264337593543950354 (79228162514264337593543950335 + 19)
    var above_max = UInt256(79228162514264337593543950354)
    assert_equal(
        truncate_to_max(above_max), UInt256(7922816251426433759354395035)
    )

    # Test with a value that requires truncating 1 digit, rounding up
    # 79228162514264337593543950356 (79228162514264337593543950335 + 21)
    var above_max_round_up = UInt256(79228162514264337593543950356)
    var expected_value = UInt256(7922816251426433759354395036)
    assert_equal(truncate_to_max(above_max_round_up), expected_value)

    # Test banker's rounding with a value ending in 5 with an even digit before it
    # 79228162514264337593543950355 (MAX + 20) - should round to even (down)
    var banker_round_down = UInt256(Decimal.MAX_AS_UINT128) + UInt256(20)
    assert_equal(
        truncate_to_max(banker_round_down),
        UInt256(7922816251426433759354395036),
    )

    # Test banker's rounding with a value ending in 5 with an even digit before it
    # For this specific test case, we need to use a specially constructed number
    # Since we can't directly represent very large numbers as literals, we'll construct it
    var base = UInt256(79228162514264337593543950330)
    var banker_round_up = base * UInt256(10) + UInt256(
        5
    )  # Creates 792281625142643375935439503305
    assert_equal(
        truncate_to_max(banker_round_up), base + UInt256(0)
    )  # Rounds to ..330

    # Test with a much larger value that requires truncating multiple digits
    var much_larger = UInt256(Decimal.MAX_AS_UINT128) * UInt256(1000) + UInt256(
        555
    )
    # Result should be a properly truncated value
    assert_true(truncate_to_max(much_larger) <= UInt256(Decimal.MAX_AS_UINT128))

    print("✓ All truncate_to_max tests with values above MAX passed!")


fn test_truncate_to_max_banker_rounding() raises:
    """Test the banker's rounding aspect of truncate_to_max particularly carefully.
    """
    print("Testing truncate_to_max banker's rounding...")

    # For testing larger numbers, we'll use direct numeric literals where possible

    # Case 1a: Round down to even with 5 as rounding digit (last digit is even)
    var case1a = UInt256(7922816251426433759354395033250)
    var case1a_expected = UInt256(
        79228162514264337593543950332
    )  # Should round to even (.....332)
    assert_equal(truncate_to_max(case1a), case1a_expected)

    # Case 1b: Round up to even with 5 as rounding digit (last digit is odd)
    var case1b = UInt256(7922816251426433759354395033150)
    var case1b_expected = UInt256(
        79228162514264337593543950332
    )  # Should round to even (.....332)
    assert_equal(truncate_to_max(case1b), case1b_expected)

    # Case 2a: Round up when 5 is followed by non-zero digits (last digit even)
    var case2a = UInt256(79228162514264337593543950332501)
    var case2a_expected = UInt256(79228162514264337593543950333)
    assert_equal(truncate_to_max(case2a), case2a_expected)

    # Case 2b: Round up when 5 is followed by non-zero digits (last digit odd)
    var case2b = UInt256(79228162514264337593543950331501)
    var case2b_expected = UInt256(79228162514264337593543950332)
    assert_equal(truncate_to_max(case2b), case2b_expected)

    # Case 3: Round up when rounding digit > 5
    var case3 = UInt256(7922816251426433759354395033207)
    var case3_expected = UInt256(79228162514264337593543950332)
    assert_equal(truncate_to_max(case3), case3_expected)

    # Case 4: Round down when rounding digit < 5
    var case4 = UInt256(7922816251426433759354395033204)
    var case4_expected = UInt256(79228162514264337593543950332)
    assert_equal(truncate_to_max(case4), case4_expected)

    print("✓ All truncate_to_max banker's rounding tests passed!")


fn test_bitcast() raises:
    """Test the bitcast utility function for direct memory bit conversion."""
    print("Testing utility.bitcast...")

    # Test case 1: Basic decimal with fractional part
    var original = Decimal("123.456")
    var coef = original.coefficient()
    var bits = dm.utility.bitcast[DType.uint128](original)
    assert_equal(coef, bits)

    # Test case 2: Zero value
    var zero = Decimal(0)
    var zero_coef = zero.coefficient()
    var zero_bits = dm.utility.bitcast[DType.uint128](zero)
    assert_equal(zero_coef, zero_bits)

    # Test case 3: Maximum value
    var max_value = Decimal.MAX()
    var max_coef = max_value.coefficient()
    var max_bits = dm.utility.bitcast[DType.uint128](max_value)
    assert_equal(max_coef, max_bits)

    # Test case 4: Negative value
    var negative = Decimal("-987.654321")
    var neg_coef = negative.coefficient()
    var neg_bits = dm.utility.bitcast[DType.uint128](negative)
    assert_equal(neg_coef, neg_bits)

    # Test case 5: Different scales
    var large_scale = Decimal("0.000000000123456789")
    var large_scale_coef = large_scale.coefficient()
    var large_scale_bits = dm.utility.bitcast[DType.uint128](large_scale)
    assert_equal(large_scale_coef, large_scale_bits)

    # Test case 6: Custom bit pattern
    var test_decimal = Decimal(12345, 67890, 0xABCDEF, 0x55)
    var test_coef = test_decimal.coefficient()
    var test_bits = dm.utility.bitcast[DType.uint128](test_decimal)
    assert_equal(test_coef, test_bits)

    print("✓ All bitcast tests passed!")


# Update the test_all function to include the new test
fn test_all() raises:
    """Run all tests for the utility module."""
    print("\n=== Running Utility Module Tests ===\n")

    test_number_of_significant_digits()
    print()

    test_truncate_to_max_below_max()
    print()

    test_truncate_to_max_above_max()
    print()

    test_truncate_to_max_banker_rounding()
    print()

    test_bitcast()
    print()

    print("✓✓✓ All utility module tests passed! ✓✓✓")


fn main() raises:
    test_all()
