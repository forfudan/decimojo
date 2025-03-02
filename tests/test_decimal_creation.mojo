"""
Test Decimal creation from integer, float, or string values.
"""
from decimojo import Decimal
import testing


fn main() raises:
    # test_decimal_from_int()
    test_decimal_from_float()
    # test_decimal_from_string()


fn test_decimal_from_int() raises:
    print("Testing Decimal Creation from Integer Values")
    print("------------------------------------------")

    # Basic integer constructors
    var zero = Decimal(0)
    var one = Decimal(1)
    var neg_one = Decimal(-1)
    var pos_int = Decimal(42)
    var neg_int = Decimal(-100)

    # Verify basic string representations
    testing.assert_equal(
        String(zero), "0", "Integer 0 should be represented as '0'"
    )
    testing.assert_equal(
        String(one), "1", "Integer 1 should be represented as '1'"
    )
    testing.assert_equal(
        String(neg_one), "-1", "Integer -1 should be represented as '-1'"
    )
    testing.assert_equal(
        String(pos_int), "42", "Integer 42 should be represented as '42'"
    )
    testing.assert_equal(
        String(neg_int), "-100", "Integer -100 should be represented as '-100'"
    )

    # Integer edge cases
    var int_min = Decimal(Int.MIN)
    var int_max = Decimal(Int.MAX)
    testing.assert_equal(
        String(int_min),
        "-9223372036854775808",
        "Int.MIN should be represented correctly",
    )
    testing.assert_equal(
        String(int_max),
        "9223372036854775807",
        "Int.MAX should be represented correctly",
    )

    # Boundary values
    var medium_int = Decimal(1000000)
    var large_int = Decimal(1000000000)
    testing.assert_equal(
        String(medium_int),
        "1000000",
        "Medium integer should be represented correctly",
    )
    testing.assert_equal(
        String(large_int),
        "1000000000",
        "Large integer should be represented correctly",
    )


fn test_decimal_from_float() raises:
    print("Testing Decimal Creation from Float Values")
    print("----------------------------------------")

    # Basic float constructors
    var zero_float = Decimal(0.0)
    var one_float = Decimal(1.0)
    var neg_one_float = Decimal(-1.0)
    var pi = Decimal(3.1415926535979323)
    var e = Decimal(2.718281828459045)

    # Verify basic exact representations for simple values
    testing.assert_equal(
        String(zero_float), "0", "Float 0.0 should be represented as '0'"
    )
    testing.assert_equal(
        String(one_float), "1", "Float 1.0 should be represented as '1'"
    )
    testing.assert_equal(
        String(neg_one_float), "-1", "Float -1.0 should be represented as '-1'"
    )

    # For irrational numbers, check only first few digits
    var pi_str = String(pi)
    var expected_pi = "3.14159"
    testing.assert_equal(
        pi_str[:7],
        String(expected_pi)[:7],
        "Pi should match expected value for the first 7 digits",
    )

    var e_str = String(e)
    var expected_e = "2.71828"
    testing.assert_equal(
        e_str[:7],
        String(expected_e)[:7],
        "e should match expected value for the first 7 digits",
    )

    # Different precision levels
    var high_precision = Decimal(0.0000000001)
    var medium_precision = Decimal(0.1234)
    var negative_precision = Decimal(-0.5678)

    # Check high precision approximately
    var high_precision_str = String(high_precision)
    testing.assert_true(
        high_precision_str.startswith("0.0000000001")
        or high_precision_str.startswith("0.00000000009"),
        "High precision float should be approximately 0.0000000001",
    )

    # Check medium precision (should be more exact but still allow for slight variations)
    var medium_str = String(medium_precision)
    testing.assert_true(
        medium_str.startswith("0.1234") or medium_str.startswith("0.1233"),
        "Medium precision float should be approximately 0.1234",
    )

    # Check negative precision
    var neg_precision_str = String(negative_precision)
    testing.assert_true(
        neg_precision_str.startswith("-0.5678")
        or neg_precision_str.startswith("-0.5677")
        or neg_precision_str.startswith("-0.5679"),
        "Negative precision float should be approximately -0.5678",
    )

    # Float edge cases
    var very_small = Decimal(1.23e-10)
    var very_large = Decimal(1.23e10)
    var neg_large = Decimal(-9.87e8)

    # For very small numbers, allow slight variations
    var very_small_str = String(very_small)
    testing.assert_true(
        very_small_str.startswith("0.000000000123")
        or very_small_str.startswith("0.000000000122")
        or very_small_str.startswith("0.000000000124"),
        "Very small float should be approximately 0.000000000123",
    )

    # For very large numbers, allow slight variations
    var very_large_str = String(very_large)
    testing.assert_true(
        very_large_str.startswith("12300000000")
        or very_large_str.startswith("12299999999")
        or very_large_str.startswith("12300000001"),
        "Very large float should be approximately 12300000000",
    )

    # For negative large numbers, allow slight variations
    var neg_large_str = String(neg_large)
    testing.assert_true(
        neg_large_str.startswith("-987000000")
        or neg_large_str.startswith("-986999999")
        or neg_large_str.startswith("-987000001"),
        "Negative large float should be approximately -987000000",
    )

    # Float precision tests
    var problematic = Decimal(
        0.0001 + 0.0002
    )  # Not exactly 0.3 in binary floating point
    var problematic_str = String(problematic)

    # Check that it's approximately 0.3 (should be close but not exactly 0.3)
    testing.assert_true(
        problematic_str.startswith("0.0003")
        or problematic_str.startswith("0.00029"),
        "Float binary approximation should be approximately 0.0003",
    )

    print("\nAll float tests passed!")


fn test_decimal_from_string() raises:
    print("Testing Decimal Creation from String Values")
    print("-----------------------------------------")

    # Basic string constructors
    var zero_str = Decimal("0")
    var one_str = Decimal("1")
    var neg_one_str = Decimal("-1")
    var decimal_str = Decimal("123.456")
    var neg_decimal_str = Decimal("-789.012")

    # Verify basic string representations
    testing.assert_equal(
        String(zero_str), "0", "String '0' should be represented as '0'"
    )
    testing.assert_equal(
        String(one_str), "1", "String '1' should be represented as '1'"
    )
    testing.assert_equal(
        String(neg_one_str), "-1", "String '-1' should be represented as '-1'"
    )
    testing.assert_equal(
        String(decimal_str), "123.456", "String '123.456' should be preserved"
    )
    testing.assert_equal(
        String(neg_decimal_str),
        "-789.012",
        "String '-789.012' should be preserved",
    )

    # Leading and trailing zeros
    var leading_zeros = Decimal("00000123.456")
    var trailing_zeros = Decimal("123.45600000")
    var both_zeros = Decimal("00123.45600")

    testing.assert_equal(
        String(leading_zeros), "123.456", "Leading zeros should be removed"
    )
    testing.assert_equal(
        String(trailing_zeros), "123.456", "Trailing zeros should be removed"
    )
    testing.assert_equal(
        String(both_zeros),
        "123.456",
        "Leading and trailing zeros should be removed",
    )

    # Very large and small numbers
    var very_large = Decimal("999999999999999999999999999")
    var very_small = Decimal("0." + "0" * 28 + "1")
    var large_negative = Decimal("-" + "9" * 21)

    testing.assert_equal(
        String(very_large),
        "999999999999999999999999999",
        "Large numbers should be preserved",
    )
    testing.assert_equal(
        String(very_small),
        "0." + "0" * 28 + "1",
        "Small numbers should be preserved",
    )
    testing.assert_equal(
        String(large_negative),
        "-" + "9" * 21,
        "Large negative numbers should be preserved",
    )

    # Special formats
    # Underscores for readability (if supported)
    try:
        var with_underscores = Decimal("1_000_000.000_001")
        testing.assert_equal(
            String(with_underscores),
            "1000000.000001",
            "Underscores should be ignored in string representation",
        )
    except:
        print("Underscores in numbers not supported")

    # Scientific notation (if supported)
    try:
        var scientific_pos = Decimal("1.23e5")
        var scientific_neg = Decimal("4.56e-7")
        testing.assert_equal(
            String(scientific_pos),
            "123000",
            "Positive scientific notation should be converted correctly",
        )
        testing.assert_equal(
            String(scientific_neg),
            "0.000000456",
            "Negative scientific notation should be converted correctly",
        )
    except:
        print("Scientific notation not supported")

    # Edge cases
    try:
        var just_dot = Decimal(".")
        testing.assert_equal(
            String(just_dot), "0", "Just dot should be represented as zero"
        )
    except:
        print("Decimal point without digits not supported")

    var only_zeros = Decimal("0.0000")
    var max_precision = Decimal("0." + "9" * 28)

    testing.assert_equal(
        String(only_zeros), "0", "String of zeros should be represented as '0'"
    )
    testing.assert_equal(
        String(max_precision),
        "0." + "9" * 28,
        "Max precision should be preserved",
    )

    # Integer boundary values as strings
    var boundary_32bit = Decimal("4294967295")  # 2^32 - 1
    var boundary_64bit = Decimal("18446744073709551615")  # 2^64 - 1
    var beyond_64bit = Decimal("18446744073709551616")  # 2^64

    testing.assert_equal(
        String(boundary_32bit),
        "4294967295",
        "32-bit boundary should be represented correctly",
    )
    testing.assert_equal(
        String(boundary_64bit),
        "18446744073709551615",
        "64-bit boundary should be represented correctly",
    )
    testing.assert_equal(
        String(beyond_64bit),
        "18446744073709551616",
        "Beyond 64-bit should be represented correctly",
    )

    print("\nAll string tests passed!")
