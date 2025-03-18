"""
Test Decimal logic operations for comparison, including basic comparisons,
edge cases, special handling for zero values, and operator overloads.
"""
from decimojo.prelude import dm, Decimal, RoundingMode
from decimojo.comparison import (
    greater,
    greater_equal,
    less,
    less_equal,
    equal,
    not_equal,
)
import testing


fn test_equality() raises:
    print("------------------------------------------------------")
    print("Testing decimal equality...")

    # Test case 1: Equal decimals
    var a1 = Decimal(12345, 2)
    var b1 = Decimal(12345, 2)
    testing.assert_true(equal(a1, b1), "Equal decimals should be equal")

    # Test case 2: Equal with different scales
    var a2 = Decimal("123.450")
    var b2 = Decimal(12345, 2)
    testing.assert_true(
        equal(a2, b2), "Equal decimals with different scales should be equal"
    )

    # Test case 3: Different values
    var a3 = Decimal(12345, 2)
    var b3 = Decimal("123.46")
    testing.assert_false(
        equal(a3, b3), "Different decimals should not be equal"
    )

    # Test case 4: Zeros with different scales
    var a4 = Decimal(0)
    var b4 = Decimal("0.00")
    testing.assert_true(
        equal(a4, b4), "Zeros with different scales should be equal"
    )

    # Test case 5: Zero and negative zero
    var a5 = Decimal(0)
    var b5 = Decimal("-0")
    testing.assert_true(equal(a5, b5), "Zero and negative zero should be equal")

    # Test case 6: Same absolute value but different signs
    var a6 = Decimal(12345, 2)
    var b6 = Decimal("-123.45")
    testing.assert_false(
        equal(a6, b6),
        "Same absolute value but different signs should not be equal",
    )

    print("Equality tests passed!")


fn test_inequality() raises:
    print("------------------------------------------------------")
    print("Testing decimal inequality...")

    # Test case 1: Equal decimals
    var a1 = Decimal(12345, 2)
    var b1 = Decimal(12345, 2)
    testing.assert_false(
        not_equal(a1, b1), "Equal decimals should not be unequal"
    )

    # Test case 2: Equal with different scales
    var a2 = Decimal(123450, 3)
    var b2 = Decimal(12345, 2)
    testing.assert_false(
        not_equal(a2, b2),
        "Equal decimals with different scales should not be unequal",
    )

    # Test case 3: Different values
    var a3 = Decimal(12345, 2)
    var b3 = Decimal(12346, 2)
    testing.assert_true(
        not_equal(a3, b3), "Different decimals should be unequal"
    )

    # Test case 4: Same absolute value but different signs
    var a4 = Decimal(12345, 2)
    var b4 = Decimal(-12345, 2)
    testing.assert_true(
        not_equal(a4, b4),
        "Same absolute value but different signs should be unequal",
    )

    print("Inequality tests passed!")


fn test_greater() raises:
    print("Testing greater than comparison...")

    # Test case 1: Larger decimal
    var a1 = Decimal(12346, 2)
    var b1 = Decimal(12345, 2)
    testing.assert_true(greater(a1, b1), "123.46 should be greater than 123.45")
    testing.assert_false(
        greater(b1, a1), "123.45 should not be greater than 123.46"
    )

    # Test case 2: Equal decimals
    var a2 = Decimal(12345, 2)
    var b2 = Decimal(12345, 2)
    testing.assert_false(
        greater(a2, b2), "Equal decimals should not be greater"
    )

    # Test case 3: Positive vs. negative
    var a3 = Decimal(12345, 2)
    var b3 = Decimal(-12345, 2)
    testing.assert_true(
        greater(a3, b3), "Positive should be greater than negative"
    )
    testing.assert_false(
        greater(b3, a3), "Negative should not be greater than positive"
    )

    # Test case 4: Negative with smaller absolute value
    var a4 = Decimal("-123.45")
    var b4 = Decimal("-123.46")
    testing.assert_true(
        greater(a4, b4), "-123.45 should be greater than -123.46"
    )

    # Test case 5: Zero vs. positive
    var a5 = Decimal(0)
    var b5 = Decimal(12345, 2)
    testing.assert_false(
        greater(a5, b5), "Zero should not be greater than positive"
    )

    # Test case 6: Zero vs. negative
    var a6 = Decimal(0)
    var b6 = Decimal("-123.45")
    testing.assert_true(greater(a6, b6), "Zero should be greater than negative")

    # Test case 7: Different scales
    var a7 = Decimal("123.5")
    var b7 = Decimal(12345, 2)
    testing.assert_true(greater(a7, b7), "123.5 should be greater than 123.45")

    print("Greater than tests passed!")


fn test_greater_equal() raises:
    print("Testing greater than or equal comparison...")

    # Test case 1: Larger decimal
    var a1 = Decimal("123.46")
    var b1 = Decimal(12345, 2)
    testing.assert_true(
        greater_equal(a1, b1),
        "123.46 should be greater than or equal to 123.45",
    )

    # Test case 2: Equal decimals
    var a2 = Decimal(12345, 2)
    var b2 = Decimal(12345, 2)
    testing.assert_true(
        greater_equal(a2, b2), "Equal decimals should be greater than or equal"
    )

    # Test case 3: Positive vs. negative
    var a3 = Decimal(12345, 2)
    var b3 = Decimal("-123.45")
    testing.assert_true(
        greater_equal(a3, b3),
        "Positive should be greater than or equal to negative",
    )

    # Test case 4: Equal values with different scales
    var a4 = Decimal("123.450")
    var b4 = Decimal(12345, 2)
    testing.assert_true(
        greater_equal(a4, b4),
        "Equal values with different scales should be greater than or equal",
    )

    # Test case 5: Smaller decimal
    var a5 = Decimal(12345, 2)
    var b5 = Decimal("123.46")
    testing.assert_false(
        greater_equal(a5, b5),
        "123.45 should not be greater than or equal to 123.46",
    )

    print("Greater than or equal tests passed!")


fn test_less() raises:
    print("Testing less than comparison...")

    # Test case 1: Smaller decimal
    var a1 = Decimal(12345, 2)
    var b1 = Decimal("123.46")
    testing.assert_true(less(a1, b1), "123.45 should be less than 123.46")

    # Test case 2: Equal decimals
    var a2 = Decimal(12345, 2)
    var b2 = Decimal(12345, 2)
    testing.assert_false(less(a2, b2), "Equal decimals should not be less")

    # Test case 3: Negative vs. positive
    var a3 = Decimal("-123.45")
    var b3 = Decimal(12345, 2)
    testing.assert_true(less(a3, b3), "Negative should be less than positive")

    # Test case 4: Negative with larger absolute value
    var a4 = Decimal("-123.46")
    var b4 = Decimal("-123.45")
    testing.assert_true(less(a4, b4), "-123.46 should be less than -123.45")

    # Test case 5: Zero vs. positive
    var a5 = Decimal(0)
    var b5 = Decimal(12345, 2)
    testing.assert_true(less(a5, b5), "Zero should be less than positive")

    print("Less than tests passed!")


fn test_less_equal() raises:
    print("Testing less than or equal comparison...")

    # Test case 1: Smaller decimal
    var a1 = Decimal(12345, 2)
    var b1 = Decimal("123.46")
    testing.assert_true(
        less_equal(a1, b1), "123.45 should be less than or equal to 123.46"
    )

    # Test case 2: Equal decimals
    var a2 = Decimal(12345, 2)
    var b2 = Decimal(12345, 2)
    testing.assert_true(
        less_equal(a2, b2), "Equal decimals should be less than or equal"
    )

    # Test case 3: Negative vs. positive
    var a3 = Decimal("-123.45")
    var b3 = Decimal(12345, 2)
    testing.assert_true(
        less_equal(a3, b3), "Negative should be less than or equal to positive"
    )

    # Test case 4: Equal values with different scales
    var a4 = Decimal("123.450")
    var b4 = Decimal(12345, 2)
    testing.assert_true(
        less_equal(a4, b4),
        "Equal values with different scales should be less than or equal",
    )

    # Test case 5: Larger decimal
    var a5 = Decimal("123.46")
    var b5 = Decimal(12345, 2)
    testing.assert_false(
        less_equal(a5, b5), "123.46 should not be less than or equal to 123.45"
    )

    print("Less than or equal tests passed!")


fn test_zero_comparison() raises:
    print("Testing zero comparison cases...")

    var zero = Decimal(0)
    var pos = Decimal("0.0000000000000000001")  # Very small positive
    var neg = Decimal("-0.0000000000000000001")  # Very small negative
    var zero_scale = Decimal("0.00000")  # Zero with different scale

    # Zero compared to small positive
    testing.assert_false(greater(zero, pos), "Zero should not be > positive")
    testing.assert_false(
        greater_equal(zero, pos), "Zero should not be >= positive"
    )
    testing.assert_true(less(zero, pos), "Zero should be < positive")
    testing.assert_true(less_equal(zero, pos), "Zero should be <= positive")
    testing.assert_false(equal(zero, pos), "Zero should not be == positive")
    testing.assert_true(not_equal(zero, pos), "Zero should be != positive")

    # Positive compared to zero
    testing.assert_true(greater(pos, zero), "Positive should be > zero")
    testing.assert_true(greater_equal(pos, zero), "Positive should be >= zero")
    testing.assert_false(less(pos, zero), "Positive should not be < zero")
    testing.assert_false(
        less_equal(pos, zero), "Positive should not be <= zero"
    )
    testing.assert_false(equal(pos, zero), "Positive should not be == zero")
    testing.assert_true(not_equal(pos, zero), "Positive should be != zero")

    # Zero compared to small negative
    testing.assert_true(greater(zero, neg), "Zero should be > negative")
    testing.assert_true(greater_equal(zero, neg), "Zero should be >= negative")
    testing.assert_false(less(zero, neg), "Zero should not be < negative")
    testing.assert_false(
        less_equal(zero, neg), "Zero should not be <= negative"
    )
    testing.assert_false(equal(zero, neg), "Zero should not be == negative")
    testing.assert_true(not_equal(zero, neg), "Zero should be != negative")

    # Different zeros
    testing.assert_false(
        greater(zero, zero_scale), "Zero should not be > zero with scale"
    )
    testing.assert_true(
        greater_equal(zero, zero_scale), "Zero should be >= zero with scale"
    )
    testing.assert_false(
        less(zero, zero_scale), "Zero should not be < zero with scale"
    )
    testing.assert_true(
        less_equal(zero, zero_scale), "Zero should be <= zero with scale"
    )
    testing.assert_true(
        equal(zero, zero_scale), "Zero should be == zero with scale"
    )
    testing.assert_false(
        not_equal(zero, zero_scale), "Zero should not be != zero with scale"
    )

    # Negative zero
    var neg_zero = Decimal("-0")
    testing.assert_true(
        equal(zero, neg_zero), "Zero should be == negative zero"
    )
    testing.assert_false(
        greater(zero, neg_zero), "Zero should not be > negative zero"
    )
    testing.assert_true(
        greater_equal(zero, neg_zero), "Zero should be >= negative zero"
    )
    testing.assert_false(
        less(zero, neg_zero), "Zero should not be < negative zero"
    )
    testing.assert_true(
        less_equal(zero, neg_zero), "Zero should be <= negative zero"
    )

    print("Zero comparison cases passed!")


fn test_edge_cases() raises:
    print("Testing comparison edge cases...")

    # Test case 1: Very close values
    var a1 = Decimal("1.000000000000000000000000001")
    var b1 = Decimal("1.000000000000000000000000000")
    testing.assert_true(
        greater(a1, b1), "1.000...001 should be greater than 1.000...000"
    )

    # Test case 2: Very large values
    var a2 = Decimal("79228162514264337593543950335")  # MAX value
    var b2 = Decimal("79228162514264337593543950334")  # MAX - 1
    testing.assert_true(greater(a2, b2), "MAX should be greater than MAX-1")

    # Test case 3: Very small negatives vs very small positives
    var a3 = Decimal("-0." + "0" * 27 + "1")  # -0.0000...01 (1 at 28th place)
    var b3 = Decimal("0." + "0" * 27 + "1")  # 0.0000...01 (1 at 28th place)
    testing.assert_true(
        less(a3, b3),
        "Very small negative should be less than very small positive",
    )

    # Test case 4: Transitivity checks
    var neg_large = Decimal("-1000")
    var neg_small = Decimal("-0.001")
    var pos_small = Decimal("0.001")
    var pos_large = Decimal(1000)

    # Transitivity: if a > b and b > c then a > c
    testing.assert_true(greater(pos_large, pos_small), "1000 > 0.001")
    testing.assert_true(greater(pos_small, neg_small), "0.001 > -0.001")
    testing.assert_true(greater(neg_small, neg_large), "-0.001 > -1000")
    testing.assert_true(
        greater(pos_large, neg_large), "1000 > -1000 (transitivity)"
    )

    print("Edge case tests passed!")


fn test_exact_comparison() raises:
    print("Testing exact comparison with precision handling...")

    # Test case 1: Scale handling with zeros
    var zero1 = Decimal(0)
    var zero2 = Decimal("0.0")
    var zero3 = Decimal("0.00000")

    testing.assert_true(equal(zero1, zero2), "0 == 0.0")
    testing.assert_true(equal(zero1, zero3), "0 == 0.00000")
    testing.assert_true(equal(zero2, zero3), "0.0 == 0.00000")

    # Test case 2: Equal values with different number of trailing zeros
    var d1 = Decimal("123.400")
    var d2 = Decimal("123.4")
    var d3 = Decimal("123.40000")

    testing.assert_true(equal(d1, d2), "123.400 == 123.4")
    testing.assert_true(equal(d2, d3), "123.4 == 123.40000")
    testing.assert_true(equal(d1, d3), "123.400 == 123.40000")

    # Test case 3: Numbers that appear close but are different
    var e1 = Decimal("1.2")
    var e2 = Decimal("1.20000001")

    testing.assert_false(equal(e1, e2), "1.2 != 1.20000001")
    testing.assert_true(less(e1, e2), "1.2 < 1.20000001")

    print("Exact comparison tests passed!")


fn test_comparison_operators() raises:
    print("Testing comparison operators...")

    # Create test values
    var a = Decimal(12345, 2)
    var b = Decimal("67.89")
    var c = Decimal(12345, 2)  # Equal to a
    var d = Decimal("123.450")  # Equal to a with different scale
    var e = Decimal("-50.0")  # Negative number
    var f = Decimal(0)  # Zero
    var g = Decimal("-0.0")  # Negative zero (equal to zero)

    # Greater than
    testing.assert_true(a > b, "a > b: 123.45 should be > 67.89")
    testing.assert_false(b > a, "b > a: 67.89 should not be > 123.45")
    testing.assert_false(a > c, "a > c: Equal values should not be >")
    testing.assert_true(a > e, "a > e: Positive should be > negative")
    testing.assert_true(a > f, "a > f: Positive should be > zero")
    testing.assert_true(f > e, "f > e: Zero should be > negative")

    # Less than
    testing.assert_false(a < b, "a < b: 123.45 should not be < 67.89")
    testing.assert_true(b < a, "b < a: 67.89 should be < 123.45")
    testing.assert_false(a < c, "a < c: Equal values should not be <")
    testing.assert_false(
        a < d, "a < d: Equal values (diff scale) should not be <"
    )
    testing.assert_false(a < e, "a < e: Positive should not be < negative")
    testing.assert_true(e < a, "e < a: Negative should be < positive")
    testing.assert_true(e < f, "e < f: Negative should be < zero")
    testing.assert_true(f < a, "f < a: Zero should be < positive")

    # Greater than or equal
    testing.assert_true(a >= b, "a >= b: 123.45 should be >= 67.89")
    testing.assert_false(b >= a, "b >= a: 67.89 should not be >= 123.45")
    testing.assert_true(a >= c, "a >= c: Equal values should be >=")
    testing.assert_true(
        a >= d, "a >= d: Equal values (diff scale) should be >="
    )
    testing.assert_true(a >= e, "a >= e: Positive should be >= negative")
    testing.assert_false(e >= a, "e >= a: Negative should not be >= positive")
    testing.assert_true(f >= g, "f >= g: Zero should be >= negative zero")

    # Less than or equal
    testing.assert_false(a <= b, "a <= b: 123.45 should not be <= 67.89")
    testing.assert_true(b <= a, "b <= a: 67.89 should be <= 123.45")
    testing.assert_true(a <= c, "a <= c: Equal values should be <=")
    testing.assert_true(
        a <= d, "a <= d: Equal values (diff scale) should be <="
    )
    testing.assert_false(a <= e, "a <= e: Positive should not be <= negative")
    testing.assert_true(e <= a, "e <= a: Negative should be <= positive")
    testing.assert_true(f <= a, "f <= a: Zero should be <= positive")
    testing.assert_true(g <= f, "g <= f: Negative zero should be <= zero")

    # Equality
    testing.assert_false(a == b, "a == b: Different values should not be equal")
    testing.assert_true(a == c, "a == c: Same value should be equal")
    testing.assert_true(
        a == d, "a == d: Same value with different scales should be equal"
    )
    testing.assert_true(
        f == g, "f == g: Zero and negative zero should be equal"
    )

    # Inequality
    testing.assert_true(a != b, "a != b: Different values should be unequal")
    testing.assert_false(a != c, "a != c: Same value should not be unequal")
    testing.assert_false(
        a != d, "a != d: Same value with different scales should not be unequal"
    )
    testing.assert_true(a != e, "a != e: Different values should be unequal")
    testing.assert_false(
        f != g, "f != g: Zero and negative zero should not be unequal"
    )

    print("Comparison operator tests passed!")


fn main() raises:
    print("Running decimal logic tests")

    # Basic equality tests
    test_equality()
    test_inequality()

    # Comparison tests
    test_greater()
    test_greater_equal()
    test_less()
    test_less_equal()

    # Zero handling and edge cases
    test_zero_comparison()
    test_edge_cases()
    test_exact_comparison()

    # Test operator overloads
    test_comparison_operators()

    print("All decimal logic tests passed!")
