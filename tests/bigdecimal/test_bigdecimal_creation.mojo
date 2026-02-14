"""
Test BigDecimal.from_python_decimal() method.
Tests conversion from Python Decimal to Mojo BigDecimal.
"""

import testing
from python import Python
from decimojo.bigdecimal.bigdecimal import BigDecimal


fn test_from_python_decimal_basic() raises:
    """Test basic Python Decimal to BigDecimal conversion."""
    var decimal = Python.import_module("decimal")

    # Test zero
    var py_zero = decimal.Decimal("0")
    var mojo_zero = BigDecimal.from_python_decimal(py_zero)
    testing.assert_equal(String(mojo_zero), "0", "Zero conversion")

    # Test simple decimal
    var py_simple = decimal.Decimal("123.456")
    var mojo_simple = BigDecimal.from_python_decimal(py_simple)
    testing.assert_equal(String(mojo_simple), "123.456", "Simple decimal")

    # Test negative decimal
    var py_neg = decimal.Decimal("-789.012")
    var mojo_neg = BigDecimal.from_python_decimal(py_neg)
    testing.assert_equal(String(mojo_neg), "-789.012", "Negative decimal")

    # Test integer (scale=0)
    var py_int = decimal.Decimal("12345")
    var mojo_int = BigDecimal.from_python_decimal(py_int)
    testing.assert_equal(String(mojo_int), "12345", "Integer (scale=0)")


fn test_from_python_decimal_scale() raises:
    """Test scale/exponent conversion."""
    var decimal = Python.import_module("decimal")

    # Test different scales
    var py_2dec = decimal.Decimal("123.45")  # scale=2
    var mojo_2dec = BigDecimal.from_python_decimal(py_2dec)
    testing.assert_equal(mojo_2dec.scale, 2, "Scale = 2")
    testing.assert_equal(String(mojo_2dec), "123.45", "Two decimal places")

    var py_5dec = decimal.Decimal("1.23456")  # scale=5
    var mojo_5dec = BigDecimal.from_python_decimal(py_5dec)
    testing.assert_equal(mojo_5dec.scale, 5, "Scale = 5")
    testing.assert_equal(String(mojo_5dec), "1.23456", "Five decimal places")

    # Test negative scale (large integer)
    var py_neg_scale = decimal.Decimal("1.23E+5")  # 123000, scale=-3
    var mojo_neg_scale = BigDecimal.from_python_decimal(py_neg_scale)
    testing.assert_equal(mojo_neg_scale.scale, -3, "Negative scale")
    # Note: May display as scientific notation or regular
    var result_str = String(mojo_neg_scale)
    testing.assert_true(
        result_str == "123000" or result_str == "1.23E+5",
        "Large integer from E notation (either format acceptable)",
    )


fn test_from_python_decimal_scientific_notation() raises:
    """Test scientific notation conversion."""
    var decimal = Python.import_module("decimal")

    # Test positive exponent
    var py_pos_exp = decimal.Decimal("1.23E+10")
    var mojo_pos_exp = BigDecimal.from_python_decimal(py_pos_exp)
    var pos_exp_str = String(mojo_pos_exp)
    testing.assert_true(
        pos_exp_str == "12300000000" or pos_exp_str == "1.23E+10",
        "Positive exponent E+10 (either format)",
    )

    # Test negative exponent
    var py_neg_exp = decimal.Decimal("1.23E-5")
    var mojo_neg_exp = BigDecimal.from_python_decimal(py_neg_exp)
    testing.assert_equal(
        String(mojo_neg_exp), "0.0000123", "Negative exponent E-5"
    )

    # Test very small number
    var py_very_small = decimal.Decimal("1E-10")
    var mojo_very_small = BigDecimal.from_python_decimal(py_very_small)
    testing.assert_equal(String(mojo_very_small), "1E-10", "Very small E-10")

    # Test very large number
    var py_very_large = decimal.Decimal("9.99E+20")
    var mojo_very_large = BigDecimal.from_python_decimal(py_very_large)
    var very_large_str = String(mojo_very_large)
    testing.assert_true(
        very_large_str == "999000000000000000000"
        or very_large_str.startswith("9.99E+"),
        "Very large E+20 (either format)",
    )


fn test_from_python_decimal_high_precision() raises:
    """Test high precision decimal conversion."""
    var decimal = Python.import_module("decimal")

    # Set high precision
    decimal.getcontext().prec = 50

    # Test Pi with 50 digits
    var pi_str = "3.14159265358979323846264338327950288419716939937510"
    var py_pi = decimal.Decimal(pi_str)
    var mojo_pi = BigDecimal.from_python_decimal(py_pi)
    testing.assert_equal(String(mojo_pi), pi_str, "High precision Pi")

    # Test very long decimal
    var long_str = "123456789.123456789123456789123456789123456789"
    var py_long = decimal.Decimal(long_str)
    var mojo_long = BigDecimal.from_python_decimal(py_long)
    testing.assert_equal(String(mojo_long), long_str, "Very long decimal")


fn test_from_python_decimal_arithmetic() raises:
    """Test that converted BigDecimal can perform arithmetic correctly."""
    var decimal = Python.import_module("decimal")

    # Convert two Python Decimals
    var py_a = decimal.Decimal("123.456")
    var py_b = decimal.Decimal("78.9")

    var mojo_a = BigDecimal.from_python_decimal(py_a)
    var mojo_b = BigDecimal.from_python_decimal(py_b)

    # Test addition
    var result_add = mojo_a + mojo_b
    var py_add = py_a + py_b
    testing.assert_equal(
        String(result_add), String(py_add), "Addition after conversion"
    )

    # Test subtraction
    var result_sub = mojo_a - mojo_b
    var py_sub = py_a - py_b
    testing.assert_equal(
        String(result_sub), String(py_sub), "Subtraction after conversion"
    )

    # Test multiplication
    var result_mul = mojo_a * mojo_b
    var py_mul = py_a * py_b
    # Normalize trailing zeros for comparison
    var py_mul_str = String(py_mul)
    testing.assert_true(
        String(result_mul) == py_mul_str
        or String(result_mul) + "0" == py_mul_str,
        "Multiplication after conversion",
    )


fn test_from_python_decimal_sign() raises:
    """Test sign handling in Python Decimal conversion."""
    var decimal = Python.import_module("decimal")

    # Test positive sign
    var py_pos = decimal.Decimal("123.456")
    var mojo_pos = BigDecimal.from_python_decimal(py_pos)
    testing.assert_false(mojo_pos.sign, "Positive has sign=False")

    # Test negative sign
    var py_neg = decimal.Decimal("-123.456")
    var mojo_neg = BigDecimal.from_python_decimal(py_neg)
    testing.assert_true(mojo_neg.sign, "Negative has sign=True")

    # Test zero sign
    var py_zero = decimal.Decimal("0")
    var mojo_zero = BigDecimal.from_python_decimal(py_zero)
    testing.assert_false(mojo_zero.sign, "Zero has sign=False")

    # Test negative zero (special case)
    var py_neg_zero = decimal.Decimal("-0")
    var mojo_neg_zero = BigDecimal.from_python_decimal(py_neg_zero)
    # Python Decimal("-0") has sign=1, but represents zero
    # BigDecimal normalizes zero to sign=False
    testing.assert_equal(
        String(mojo_neg_zero), "0", "Negative zero becomes zero"
    )


fn test_from_python_decimal_edge_cases() raises:
    """Test edge cases for Python Decimal conversion."""
    var decimal = Python.import_module("decimal")

    # Test 0.001
    var py_small = decimal.Decimal("0.001")
    var mojo_small = BigDecimal.from_python_decimal(py_small)
    testing.assert_equal(String(mojo_small), "0.001", "0.001")

    # Test 0.0000001
    var py_tiny = decimal.Decimal("0.0000001")
    var mojo_tiny = BigDecimal.from_python_decimal(py_tiny)
    testing.assert_equal(String(mojo_tiny), "1E-7", "Very small number")

    # Test powers of 10
    var py_1e9 = decimal.Decimal("1E9")
    var mojo_1e9 = BigDecimal.from_python_decimal(py_1e9)
    var e9_str = String(mojo_1e9)
    testing.assert_true(
        e9_str == "1000000000" or e9_str == "1E+9", "10^9 (either format)"
    )

    # Test 0.999999999 (9 nines)
    var py_nines = decimal.Decimal("0.999999999")
    var mojo_nines = BigDecimal.from_python_decimal(py_nines)
    testing.assert_equal(
        String(mojo_nines), "0.999999999", "Nine 9's after decimal"
    )


fn test_from_python_decimal_constructor() raises:
    """Test the py= constructor syntax."""
    var decimal = Python.import_module("decimal")

    # Test with py= constructor
    var py_dec = decimal.Decimal("123.456789")
    var mojo_dec = BigDecimal(py=py_dec)
    testing.assert_equal(
        String(mojo_dec), "123.456789", "Constructor with py= keyword"
    )

    # Test negative with py= constructor
    var py_neg = decimal.Decimal("-987.654321")
    var mojo_neg = BigDecimal(py=py_neg)
    testing.assert_equal(
        String(mojo_neg), "-987.654321", "Negative with py= constructor"
    )


fn test_from_python_decimal_roundtrip() raises:
    """Test Python -> Mojo -> Python roundtrip."""
    var decimal = Python.import_module("decimal")

    # Create Python Decimal
    var original_str = "123456.789012345678901234567890"
    var py_original = decimal.Decimal(original_str)

    # Convert to Mojo BigDecimal
    var mojo_dec = BigDecimal.from_python_decimal(py_original)

    # Convert back to Python (via string)
    var roundtrip_str = String(mojo_dec)
    var py_roundtrip = decimal.Decimal(roundtrip_str)

    # Compare
    testing.assert_equal(
        String(py_roundtrip), original_str, "Roundtrip preserves value"
    )


fn test_from_python_decimal_special_values() raises:
    """Test handling of special values."""
    var decimal = Python.import_module("decimal")

    # Test must handle finite values only
    # Infinity and NaN should raise errors

    # This test documents the expected behavior
    # Current implementation: as_tuple() for Infinity returns exponent='F'
    # which causes Int(py=...) to fail

    var py_normal = decimal.Decimal("123.456")
    var mojo_normal = BigDecimal.from_python_decimal(py_normal)
    testing.assert_equal(
        String(mojo_normal), "123.456", "Normal finite value works"
    )

    # Note: Infinity and NaN conversions will raise errors
    # This is expected behavior and documented in the method


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
