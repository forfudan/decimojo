"""
Test Decimal128.from_float() constructor (50 cases).
Most tests use startswith assertions due to float precision, so they remain
inline rather than TOML-driven.
"""

import testing
from decimojo import Dec128


fn test_simple_integers() raises:
    """Test conversion of simple integer float values."""
    testing.assert_equal(String(Dec128.from_float(0.0)), "0")
    testing.assert_equal(String(Dec128.from_float(1.0)), "1")
    testing.assert_equal(String(Dec128.from_float(10.0)), "10")
    testing.assert_equal(String(Dec128.from_float(100.0)), "100")
    testing.assert_equal(String(Dec128.from_float(1000.0)), "1000")


fn test_simple_decimals() raises:
    """Test conversion of simple decimal float values."""
    testing.assert_equal(String(Dec128.from_float(0.5)), "0.5")
    testing.assert_equal(String(Dec128.from_float(0.25)), "0.25")
    testing.assert_equal(String(Dec128.from_float(1.5)), "1.5")
    testing.assert_true(String(Dec128.from_float(3.14)).startswith("3.14"))
    testing.assert_true(String(Dec128.from_float(2.71828)).startswith("2.7182"))


fn test_negative_numbers() raises:
    """Test conversion of negative float values."""
    testing.assert_equal(String(Dec128.from_float(-1.0)), "-1")
    testing.assert_equal(String(Dec128.from_float(-0.5)), "-0.5")
    testing.assert_true(
        String(Dec128.from_float(-123.456)).startswith("-123.45")
    )
    testing.assert_equal(String(Dec128.from_float(-0.0)), "0")
    testing.assert_true(
        String(Dec128.from_float(-999.999)).startswith("-999.99")
    )


fn test_very_large_numbers() raises:
    """Test conversion of very large float values."""
    testing.assert_equal(String(Dec128.from_float(1e10)), "10000000000")
    testing.assert_equal(String(Dec128.from_float(1e15)), "1000000000000000")
    testing.assert_equal(
        String(Dec128.from_float(9007199254740991.0)), "9007199254740991"
    )
    testing.assert_equal(
        String(Dec128.from_float(1e20)), "100000000000000000000"
    )
    testing.assert_true(
        String(Dec128.from_float(1.23456789e15)).startswith("1234567890000000")
    )


fn test_very_small_numbers() raises:
    """Test conversion of very small float values."""
    testing.assert_true(
        String(Dec128.from_float(1e-10)).startswith("0.00000000")
    )
    testing.assert_true(
        String(Dec128.from_float(1e-15)).startswith("0.000000000000001")
    )
    testing.assert_true(
        String(Dec128.from_float(1.234e-10)).startswith("0.0000000001")
    )
    testing.assert_true(
        String(Dec128.from_float(1e-20)).startswith("0.00000000000000000001")
    )
    testing.assert_true(String(Dec128.from_float(1e-310)).startswith("0."))


fn test_binary_to_decimal_conversion() raises:
    """Test float values that are inexact in binary."""
    testing.assert_true(String(Dec128.from_float(0.1)).startswith("0.1"))
    testing.assert_true(String(Dec128.from_float(0.2)).startswith("0.2"))
    testing.assert_true(String(Dec128.from_float(0.3)).startswith("0.3"))
    testing.assert_true(String(Dec128.from_float(0.1 + 0.2)).startswith("0.3"))
    testing.assert_true(String(Dec128.from_float(0.1)).startswith("0.1"))


fn test_rounding_behavior() raises:
    """Test rounding behavior during float to Decimal128 conversion."""
    testing.assert_true(
        String(Dec128.from_float(3.141592653589793)).startswith(
            "3.14159265358979"
        )
    )
    testing.assert_true(
        String(Dec128.from_float(1.0 / 3.0)).startswith("0.33333333")
    )
    testing.assert_true(
        String(Dec128.from_float(2.0 / 3.0)).startswith("0.66666666")
    )
    testing.assert_true(
        String(Dec128.from_float(123.456)).startswith("123.456")
    )
    testing.assert_true(
        String(Dec128.from_float(9.9999999999999999)).startswith("10")
    )


fn test_special_values() raises:
    """Test handling of special float values."""
    testing.assert_equal(String(Dec128.from_float(0.0)), "0")
    testing.assert_true(
        String(Dec128.from_float(2.220446049250313e-16)).startswith(
            "0.000000000000000"
        )
    )
    testing.assert_equal(String(Dec128.from_float(1024.0)), "1024")
    testing.assert_equal(String(Dec128.from_float(0.125)), "0.125")
    testing.assert_true(String(Dec128.from_float(9.9999)).startswith("9.9999"))


fn test_scientific_notation() raises:
    """Test handling of scientific notation values."""
    testing.assert_equal(String(Dec128.from_float(1.23e5)), "123000")
    testing.assert_true(
        String(Dec128.from_float(4.56e-3)).startswith("0.00456")
    )
    testing.assert_equal(
        String(Dec128.from_float(1.0e20)), "100000000000000000000"
    )
    testing.assert_true(
        String(Dec128.from_float(1.0e-10)).startswith("0.00000000")
    )
    testing.assert_true(String(Dec128.from_float(5e20)).startswith("5"))


fn test_boundary_cases() raises:
    """Test boundary cases for float to Decimal128 conversion."""
    testing.assert_equal(String(Dec128.from_float(1000.0)), "1000")
    testing.assert_equal(
        String(Dec128.from_float(9007199254740990.0)), "9007199254740990"
    )
    testing.assert_true(
        String(Dec128.from_float(9007199254740994.0)).startswith(
            "9007199254740"
        )
    )
    testing.assert_true(String(Dec128.from_float(123.000000)).startswith("123"))
    testing.assert_equal(String(Dec128.from_float(0.125)), "0.125")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
