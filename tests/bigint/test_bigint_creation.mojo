"""
Test BigInt.from_python_int() method.
Tests conversion from Python integers to Mojo BigInt.
"""

import testing
from python import Python
from decimojo.bigint.bigint import BigInt


fn test_from_python_int_basic() raises:
    """Test basic Python int to BigInt conversion."""
    var py = Python.import_module("builtins")

    # Test zero
    var py_zero = py.int(0)
    var mojo_zero = BigInt.from_python_int(py_zero)
    testing.assert_equal(String(mojo_zero), "0", "Zero conversion")

    # Test small positive integer
    var py_pos = py.int(123)
    var mojo_pos = BigInt.from_python_int(py_pos)
    testing.assert_equal(String(mojo_pos), "123", "Small positive integer")

    # Test small negative integer
    var py_neg = py.int(-456)
    var mojo_neg = BigInt.from_python_int(py_neg)
    testing.assert_equal(String(mojo_neg), "-456", "Small negative integer")


fn test_from_python_int_large() raises:
    """Test large Python int to BigInt conversion."""
    var py = Python.import_module("builtins")

    # Test large positive integer (> 2^64)
    var large_pos_str = "123456789012345678901234567890"
    var py_large_pos = py.int(large_pos_str)
    var mojo_large_pos = BigInt.from_python_int(py_large_pos)
    testing.assert_equal(
        String(mojo_large_pos), large_pos_str, "Large positive integer (> 2^64)"
    )

    # Test large negative integer
    var large_neg_str = "-987654321098765432109876543210"
    var py_large_neg = py.int(large_neg_str)
    var mojo_large_neg = BigInt.from_python_int(py_large_neg)
    testing.assert_equal(
        String(mojo_large_neg), large_neg_str, "Large negative integer"
    )

    # Test very large integer (1000+ digits)
    var very_large_str = "1" + "0" * 1000
    var py_very_large = py.int(very_large_str)
    var mojo_very_large = BigInt.from_python_int(py_very_large)
    testing.assert_equal(
        String(mojo_very_large),
        very_large_str,
        "Very large integer (1000+ digits)",
    )


fn test_from_python_int_edge_cases() raises:
    """Test edge cases for Python int conversion."""
    var py = Python.import_module("builtins")

    # Test powers of 10
    var py_1e9 = py.int("1000000000")  # 10^9
    var mojo_1e9 = BigInt.from_python_int(py_1e9)
    testing.assert_equal(String(mojo_1e9), "1000000000", "10^9")

    var py_1e18 = py.int("1000000000000000000")  # 10^18
    var mojo_1e18 = BigInt.from_python_int(py_1e18)
    testing.assert_equal(String(mojo_1e18), "1000000000000000000", "10^18")

    # Test number with all 9's (boundary word values)
    var py_nines = py.int("999999999")
    var mojo_nines = BigInt.from_python_int(py_nines)
    testing.assert_equal(String(mojo_nines), "999999999", "All 9's")

    var py_multi_word = py.int("999999999888888888")
    var mojo_multi_word = BigInt.from_python_int(py_multi_word)
    testing.assert_equal(
        String(mojo_multi_word), "999999999888888888", "Multiple words with 9's"
    )


fn test_from_python_int_arithmetic() raises:
    """Test that converted BigInt can perform arithmetic correctly."""
    var py = Python.import_module("builtins")

    # Convert two Python ints
    var py_a = py.int("123456789012345678901234567890")
    var py_b = py.int("987654321098765432109876543210")

    var mojo_a = BigInt.from_python_int(py_a)
    var mojo_b = BigInt.from_python_int(py_b)

    # Test addition
    var result_add = mojo_a + mojo_b
    var expected_add = String(py_a + py_b)
    testing.assert_equal(
        String(result_add), expected_add, "Addition after conversion"
    )

    # Test subtraction
    var result_sub = mojo_b - mojo_a
    var expected_sub = String(py_b - py_a)
    testing.assert_equal(
        String(result_sub), expected_sub, "Subtraction after conversion"
    )

    # Test multiplication
    var py_c = py.int("12345")
    var py_d = py.int("67890")
    var mojo_c = BigInt.from_python_int(py_c)
    var mojo_d = BigInt.from_python_int(py_d)
    var result_mul = mojo_c * mojo_d
    var expected_mul = String(py_c * py_d)
    testing.assert_equal(
        String(result_mul), expected_mul, "Multiplication after conversion"
    )


fn test_from_python_int_sign() raises:
    """Test sign handling in Python int conversion."""
    var py = Python.import_module("builtins")

    # Test positive sign
    var py_pos = py.int("123456")
    var mojo_pos = BigInt.from_python_int(py_pos)
    testing.assert_false(mojo_pos.sign, "Positive number has sign=False")

    # Test negative sign
    var py_neg = py.int("-123456")
    var mojo_neg = BigInt.from_python_int(py_neg)
    testing.assert_true(mojo_neg.sign, "Negative number has sign=True")

    # Test zero sign
    var py_zero = py.int(0)
    var mojo_zero = BigInt.from_python_int(py_zero)
    testing.assert_false(mojo_zero.sign, "Zero has sign=False")


fn test_from_python_int_constructor() raises:
    """Test the py= constructor syntax."""
    var py = Python.import_module("builtins")

    # Test with py= constructor
    var py_int = py.int("123456789012345678901234567890")
    var mojo_int = BigInt(py=py_int)
    testing.assert_equal(
        String(mojo_int),
        "123456789012345678901234567890",
        "Constructor with py= keyword",
    )

    # Test negative with py= constructor
    var py_neg = py.int("-987654321")
    var mojo_neg = BigInt(py=py_neg)
    testing.assert_equal(
        String(mojo_neg), "-987654321", "Negative with py= constructor"
    )


fn test_from_python_int_roundtrip() raises:
    """Test Python -> Mojo -> Python roundtrip."""
    var py = Python.import_module("builtins")

    # Create Python int
    var original_str = "123456789012345678901234567890123456789"
    var py_original = py.int(original_str)

    # Convert to Mojo BigInt
    var mojo_int = BigInt.from_python_int(py_original)

    # Convert back to Python (via string)
    var roundtrip_str = String(mojo_int)
    var py_roundtrip = py.int(roundtrip_str)

    # Compare
    testing.assert_equal(
        String(py_roundtrip),
        original_str,
        "Roundtrip conversion preserves value",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
