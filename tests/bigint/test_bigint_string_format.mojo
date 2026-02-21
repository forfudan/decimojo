"""
Test BigInt string formatting: to_string_with_separators,
to_decimal_string with line_width, number_of_digits, and __repr__.
"""

import testing
from decimojo.bigint.bigint import BigInt


# ===----------------------------------------------------------------------=== #
# Test: to_string_with_separators
# ===----------------------------------------------------------------------=== #


fn test_to_string_with_separators() raises:
    """Test to_string_with_separators."""
    testing.assert_equal(BigInt(0).to_string_with_separators(), "0")
    testing.assert_equal(BigInt(1).to_string_with_separators(), "1")
    testing.assert_equal(BigInt(100).to_string_with_separators(), "100")
    testing.assert_equal(BigInt(1000).to_string_with_separators(), "1_000")
    testing.assert_equal(
        BigInt(1000000).to_string_with_separators(), "1_000_000"
    )
    testing.assert_equal(
        BigInt(-1234567).to_string_with_separators(), "-1_234_567"
    )

    # Custom separator
    testing.assert_equal(
        BigInt(1234567890).to_string_with_separators(","), "1,234,567,890"
    )


# ===----------------------------------------------------------------------=== #
# Test: to_decimal_string with line_width
# ===----------------------------------------------------------------------=== #


fn test_to_decimal_string_line_width() raises:
    """Test to_decimal_string with line_width parameter."""
    # Default: no wrapping
    var val = BigInt("12345678901234567890")
    testing.assert_equal(val.to_decimal_string(), "12345678901234567890")

    # line_width=10: "1234567890\n1234567890"
    var wrapped = val.to_decimal_string(line_width=10)
    testing.assert_equal(wrapped, "1234567890\n1234567890")

    # line_width=5: "12345\n67890\n12345\n67890"
    var wrapped5 = val.to_decimal_string(line_width=5)
    testing.assert_equal(wrapped5, "12345\n67890\n12345\n67890")

    # Short string: no wrapping needed
    testing.assert_equal(BigInt(42).to_decimal_string(line_width=10), "42")


# ===----------------------------------------------------------------------=== #
# Test: number_of_digits
# ===----------------------------------------------------------------------=== #


fn test_number_of_digits() raises:
    """Test number_of_digits method."""
    testing.assert_equal(BigInt(0).number_of_digits(), 1)
    testing.assert_equal(BigInt(1).number_of_digits(), 1)
    testing.assert_equal(BigInt(9).number_of_digits(), 1)
    testing.assert_equal(BigInt(10).number_of_digits(), 2)
    testing.assert_equal(BigInt(99).number_of_digits(), 2)
    testing.assert_equal(BigInt(100).number_of_digits(), 3)
    testing.assert_equal(BigInt(999).number_of_digits(), 3)
    testing.assert_equal(BigInt(1000).number_of_digits(), 4)

    # Negative numbers: digits count of magnitude
    testing.assert_equal(BigInt(-1).number_of_digits(), 1)
    testing.assert_equal(BigInt(-999).number_of_digits(), 3)

    # Large number
    testing.assert_equal(BigInt("12345678901234567890").number_of_digits(), 20)


# ===----------------------------------------------------------------------=== #
# Test: __repr__
# ===----------------------------------------------------------------------=== #


fn test_repr() raises:
    """Test __repr__ (Representable trait)."""
    testing.assert_equal(repr(BigInt(42)), 'BigInt("42")')
    testing.assert_equal(repr(BigInt(-7)), 'BigInt("-7")')
    testing.assert_equal(repr(BigInt(0)), 'BigInt("0")')


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
