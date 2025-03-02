"""
Test Decimal rounding methods with different rounding modes and precision levels.
"""
from decimojo import Decimal
from decimojo.rounding_mode import RoundingMode
import testing


fn test_basic_rounding() raises:
    print("Testing basic decimal rounding...")

    # Test case 1: Round to 2 decimal places (banker's rounding)
    var d1 = Decimal("123.456")
    var result1 = d1.round(2)
    testing.assert_equal(
        String(result1), "123.46", "Basic rounding to 2 decimal places"
    )

    # Test case 2: Round to 0 decimal places
    var d2 = Decimal("123.456")
    var result2 = d2.round(0)
    testing.assert_equal(String(result2), "123", "Rounding to 0 decimal places")

    # Test case 3: Round to more decimal places than original (should pad with zeros)
    var d3 = Decimal("123.45")
    var result3 = d3.round(4)
    testing.assert_equal(
        String(result3), "123.4500", "Rounding to more decimal places"
    )

    # Test case 4: Round number that's already at target precision
    var d4 = Decimal("123.45")
    var result4 = d4.round(2)
    testing.assert_equal(
        String(result4), "123.45", "Rounding to same precision"
    )

    print("Basic decimal rounding tests passed!")


fn test_different_rounding_modes() raises:
    print("Testing different rounding modes...")

    var test_value = Decimal("123.456")

    # Test case 1: Round down (truncate)
    var result1 = test_value.round(2, RoundingMode.DOWN())
    testing.assert_equal(String(result1), "123.45", "Rounding down")

    # Test case 2: Round up (away from zero)
    var result2 = test_value.round(2, RoundingMode.UP())
    testing.assert_equal(String(result2), "123.46", "Rounding up")

    # Test case 3: Round half up
    var result3 = test_value.round(2, RoundingMode.HALF_UP())
    testing.assert_equal(String(result3), "123.46", "Rounding half up")

    # Test case 4: Round half even (banker's rounding)
    var result4 = test_value.round(2, RoundingMode.HALF_EVEN())
    testing.assert_equal(String(result4), "123.46", "Rounding half even")

    print("Rounding mode tests passed!")


fn test_edge_cases() raises:
    print("Testing edge cases for rounding...")

    # Test case 1: Rounding exactly 0.5 with different modes
    var half_value = Decimal("123.5")

    testing.assert_equal(
        String(half_value.round(0, RoundingMode.DOWN())),
        "123",
        "Rounding 0.5 down",
    )

    testing.assert_equal(
        String(half_value.round(0, RoundingMode.UP())), "124", "Rounding 0.5 up"
    )

    testing.assert_equal(
        String(half_value.round(0, RoundingMode.HALF_UP())),
        "124",
        "Rounding 0.5 half up",
    )

    testing.assert_equal(
        String(half_value.round(0, RoundingMode.HALF_EVEN())),
        "124",
        "Rounding 0.5 half even (even is 124)",
    )

    # Another test with half to even value
    var half_even_value = Decimal("124.5")
    testing.assert_equal(
        String(half_even_value.round(0, RoundingMode.HALF_EVEN())),
        "124",
        "Rounding 124.5 half even (even is 124)",
    )

    # Test case 2: Rounding very small numbers
    var small_value = Decimal(
        "0." + "0" * 27 + "1"
    )  # 0.0000...01 (1 at 28th place)
    testing.assert_equal(
        String(small_value.round(27)),
        "0." + "0" * 27,
        "Rounding tiny number to 27 places",
    )

    # Test case 3: Rounding negative numbers
    var negative_value = Decimal("-123.456")

    testing.assert_equal(
        String(negative_value.round(2, RoundingMode.DOWN())),
        "-123.45",
        "Rounding negative number down",
    )

    testing.assert_equal(
        String(negative_value.round(2, RoundingMode.UP())),
        "-123.46",
        "Rounding negative number up",
    )

    testing.assert_equal(
        String(negative_value.round(2, RoundingMode.HALF_EVEN())),
        "-123.46",
        "Rounding negative number half even",
    )

    # Test case 4: Rounding that causes carry propagation
    var carry_value = Decimal("9.999")

    testing.assert_equal(
        String(carry_value.round(2)), "10.00", "Rounding with carry propagation"
    )

    # Test case 5: Rounding to maximum precision
    var max_precision = Decimal("0." + "1" * 28)  # 0.1111...1 (28 digits)
    testing.assert_equal(
        String(max_precision.round(14)),
        "0.11111111111111",
        "Rounding from maximum precision",
    )

    print("Edge case tests passed!")


fn test_rounding_consistency() raises:
    print("Testing rounding consistency...")

    # Test case: Verify that rounding is consistent across different ways of
    # constructing the same value

    # Two ways to create 123.45
    var d1 = Decimal("123.45")
    var d2 = Decimal(123.45)

    # Both should round the same way
    testing.assert_equal(
        String(d1.round(1)),
        String(d2.round(1)),
        "Rounding consistency across different constructors",
    )

    # Test that repeated rounding is consistent
    var start = Decimal("123.456789")
    var round_once = start.round(4)  # 123.4568
    var round_twice = round_once.round(2)  # 123.46
    var direct = start.round(2)  # 123.46

    testing.assert_equal(
        String(round_twice),
        String(direct),
        "Consistency with sequential rounding",
    )

    print("Rounding consistency tests passed!")


fn main() raises:
    print("Running decimal rounding tests")

    # Run basic rounding tests
    test_basic_rounding()

    # Run tests with different rounding modes
    test_different_rounding_modes()

    # Run edge case tests
    test_edge_cases()

    # Run rounding consistency tests
    test_rounding_consistency()

    print("All decimal rounding tests passed!")
