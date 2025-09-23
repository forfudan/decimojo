"""
Comprehensive tests for the Decimal128.quantize() method.
Tests various scenarios to ensure proper quantization behavior and compatibility
with Python's decimal module implementation.
"""

import testing
from python import Python, PythonObject
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_quantization() raises:
    """Test basic quantization with different scales."""
    print("Testing basic quantization...")

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28  # Match DeciMojo's precision

    var value1 = Decimal128("3.14159")
    var quant1 = Decimal128("0.01")
    var result1 = value1.quantize(quant1)
    var py_value1 = pydecimal.Decimal("3.14159")
    var py_quant1 = pydecimal.Decimal("0.01")
    var py_result1 = py_value1.quantize(py_quant1)

    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Quantizing 3.14159 to 0.01 gave incorrect result: " + String(result1),
    )

    var value2 = Decimal128("42.7")
    var quant2 = Decimal128("1")
    var result2 = value2.quantize(quant2)
    var py_value2 = pydecimal.Decimal("42.7")
    var py_quant2 = pydecimal.Decimal("1")
    var py_result2 = py_value2.quantize(py_quant2)

    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Quantizing 42.7 to 1 gave incorrect result: " + String(result2),
    )

    var value3 = Decimal128("5.5")
    var quant3 = Decimal128("0.001")
    var result3 = value3.quantize(quant3)
    var py_value3 = pydecimal.Decimal("5.5")
    var py_quant3 = pydecimal.Decimal("0.001")
    var py_result3 = py_value3.quantize(py_quant3)

    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Quantizing 5.5 to 0.001 gave incorrect result: " + String(result3),
    )

    var value4 = Decimal128("123.456789")
    var quant4 = Decimal128("0.01")
    var result4 = value4.quantize(quant4)
    var py_value4 = pydecimal.Decimal("123.456789")
    var py_quant4 = pydecimal.Decimal("0.01")
    var py_result4 = py_value4.quantize(py_quant4)

    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Quantizing 123.456789 to 0.01 gave incorrect result: "
        + String(result4),
    )

    var value5 = Decimal128("9.876")
    var quant5 = Decimal128("1.00")
    var result5 = value5.quantize(quant5)
    var py_value5 = pydecimal.Decimal("9.876")
    var py_quant5 = pydecimal.Decimal("1.00")
    var py_result5 = py_value5.quantize(py_quant5)

    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Quantizing 9.876 to 1.00 gave incorrect result: " + String(result5),
    )

    print("✓ Basic quantization tests passed!")


fn test_rounding_modes() raises:
    """Test quantization with different rounding modes."""
    print("Testing quantization with different rounding modes...")

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    var test_value = Decimal128("3.5")
    var quantizer = Decimal128("1")
    var py_value = pydecimal.Decimal("3.5")
    var py_quantizer = pydecimal.Decimal("1")

    var result1 = test_value.quantize(quantizer, RoundingMode.half_even())
    var py_result1 = py_value.quantize(
        py_quantizer, rounding=pydecimal.ROUND_HALF_EVEN
    )
    testing.assert_equal(
        String(result1),
        String(py_result1),
        "ROUND_HALF_EVEN gave incorrect result: " + String(result1),
    )

    var result2 = test_value.quantize(quantizer, RoundingMode.half_up())
    var py_result2 = py_value.quantize(
        py_quantizer, rounding=pydecimal.ROUND_HALF_UP
    )
    testing.assert_equal(
        String(result2),
        String(py_result2),
        "ROUND_HALF_UP gave incorrect result: " + String(result2),
    )

    var result3 = test_value.quantize(quantizer, RoundingMode.down())
    var py_result3 = py_value.quantize(
        py_quantizer, rounding=pydecimal.ROUND_DOWN
    )
    testing.assert_equal(
        String(result3),
        String(py_result3),
        "ROUND_DOWN gave incorrect result: " + String(result3),
    )

    var result4 = test_value.quantize(quantizer, RoundingMode.up())
    var py_result4 = py_value.quantize(
        py_quantizer, rounding=pydecimal.ROUND_UP
    )
    testing.assert_equal(
        String(result4),
        String(py_result4),
        "ROUND_UP gave incorrect result: " + String(result4),
    )

    var neg_test_value = Decimal128("-3.5")
    var result5 = neg_test_value.quantize(quantizer, RoundingMode.down())
    var py_neg_value = pydecimal.Decimal("-3.5")
    var py_result5 = py_neg_value.quantize(
        py_quantizer, rounding=pydecimal.ROUND_DOWN
    )
    testing.assert_equal(
        String(result5),
        String(py_result5),
        "ROUND_DOWN with negative gave incorrect result: " + String(result5),
    )

    var result6 = neg_test_value.quantize(quantizer, RoundingMode.up())
    var py_result6 = py_neg_value.quantize(
        py_quantizer, rounding=pydecimal.ROUND_UP
    )
    testing.assert_equal(
        String(result6),
        String(py_result6),
        "ROUND_UP with negative gave incorrect result: " + String(result6),
    )

    print("✓ Rounding mode tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for quantization."""
    print("Testing quantization edge cases...")

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    var zero = Decimal128("0")
    var quant1 = Decimal128("0.001")
    var result1 = zero.quantize(quant1)
    var py_zero = pydecimal.Decimal("0")
    var py_quant1 = pydecimal.Decimal("0.001")
    var py_result1 = py_zero.quantize(py_quant1)

    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Quantizing 0 to 0.001 gave incorrect result: " + String(result1),
    )

    var value2 = Decimal128("123.45")
    var quant2 = Decimal128("0.01")
    var result2 = value2.quantize(quant2)
    var py_value2 = pydecimal.Decimal("123.45")
    var py_quant2 = pydecimal.Decimal("0.01")
    var py_result2 = py_value2.quantize(py_quant2)

    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Quantizing to same exponent gave incorrect result: " + String(result2),
    )

    var value3 = Decimal128("9.9999")
    var quant3 = Decimal128("1")
    var result3 = value3.quantize(quant3)
    var py_value3 = pydecimal.Decimal("9.9999")
    var py_quant3 = pydecimal.Decimal("1")
    var py_result3 = py_value3.quantize(py_quant3)

    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Rounding 9.9999 to 1 gave incorrect result: " + String(result3),
    )

    var value4 = Decimal128("0.0000001")
    var quant4 = Decimal128("0.001")
    var result4 = value4.quantize(quant4)
    var py_value4 = pydecimal.Decimal("0.0000001")
    var py_quant4 = pydecimal.Decimal("0.001")
    var py_result4 = py_value4.quantize(py_quant4)

    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Quantizing very small number gave incorrect result: "
        + String(result4),
    )

    var value5 = Decimal128("-1.5")
    var quant5 = Decimal128("1")
    var result5 = value5.quantize(quant5, RoundingMode.half_even())
    var py_value5 = pydecimal.Decimal("-1.5")
    var py_quant5 = pydecimal.Decimal("1")
    var py_result5 = py_value5.quantize(
        py_quant5, rounding=pydecimal.ROUND_HALF_EVEN
    )

    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Quantizing -1.5 with ROUND_HALF_EVEN gave incorrect result: "
        + String(result5),
    )

    print("✓ Edge cases tests passed!")


fn test_special_cases() raises:
    """Test special cases for quantization."""
    print("Testing special quantization cases...")

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    var value1 = Decimal128("12.34")
    var quant1 = Decimal128("0.0000")
    var result1 = value1.quantize(quant1)
    var py_value1 = pydecimal.Decimal("12.34")
    var py_quant1 = pydecimal.Decimal("0.0000")
    var py_result1 = py_value1.quantize(py_quant1)

    testing.assert_equal(
        String(result1),
        String(py_result1),
        "Increasing precision gave incorrect result: " + String(result1),
    )

    var value2 = Decimal128("2.5")
    var quant2 = Decimal128("1")
    var result2 = value2.quantize(quant2, RoundingMode.half_even())
    var py_value2 = pydecimal.Decimal("2.5")
    var py_quant2 = pydecimal.Decimal("1")
    var py_result2 = py_value2.quantize(
        py_quant2, rounding=pydecimal.ROUND_HALF_EVEN
    )

    testing.assert_equal(
        String(result2),
        String(py_result2),
        "Banker's rounding for 2.5 gave incorrect result: " + String(result2),
    )

    var value3 = Decimal128("123.456")
    var quant3 = Decimal128("10")
    var result3 = value3.quantize(quant3)
    var py_value3 = pydecimal.Decimal("123.456")
    var py_quant3 = pydecimal.Decimal("10")
    var py_result3 = py_value3.quantize(py_quant3)

    testing.assert_equal(
        String(result3),
        String(py_result3),
        "Quantizing with negative exponent gave incorrect result: "
        + String(result3),
    )

    var value4 = Decimal128("3.1415926535")
    var quant4 = Decimal128("0.00000001")
    var result4 = value4.quantize(quant4)
    var py_value4 = pydecimal.Decimal("3.1415926535")
    var py_quant4 = pydecimal.Decimal("0.00000001")
    var py_result4 = py_value4.quantize(py_quant4)

    testing.assert_equal(
        String(result4),
        String(py_result4),
        "Very precise quantization gave incorrect result: " + String(result4),
    )

    var value5 = Decimal128("123.456")
    var quant5 = Decimal128("1")
    var result5 = value5.quantize(quant5)
    var py_value5 = pydecimal.Decimal("123.456")
    var py_quant5 = pydecimal.Decimal("1")
    var py_result5 = py_value5.quantize(py_quant5)

    testing.assert_equal(
        String(result5),
        String(py_result5),
        "Quantizing to integer gave incorrect result: " + String(result5),
    )

    print("✓ Special cases tests passed!")


fn test_quantize_exceptions() raises:
    """Test exception conditions for quantize()."""
    print("Testing quantize exceptions...")

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    var exception_caught = False
    try:
        var value1 = Decimal128("123.456")
        var quant1 = Decimal128("1000")
        var _result1 = value1.quantize(quant1)
    except:
        exception_caught = True

    var py_exception_caught = False
    try:
        var py_value1 = pydecimal.Decimal("123.456")
        var py_quant1 = pydecimal.Decimal("1000")
        var _py_result1 = py_value1.quantize(py_quant1)
    except:
        py_exception_caught = True

    testing.assert_equal(
        exception_caught,
        py_exception_caught,
        (
            "Exception handling for invalid quantization doesn't match Python's"
            " behavior"
        ),
    )

    print("✓ Exception tests passed!")


fn test_comprehensive_comparison() raises:
    """Test a wide range of values to ensure compatibility with Python's decimal.
    """
    print("Testing comprehensive comparison with Python's decimal...")

    # Set up Python decimal
    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28  # Match DeciMojo's precision

    # Define rounding modes to test
    var mojo_round_half_even = RoundingMode.half_even()
    var mojo_round_half_up = RoundingMode.half_up()
    var mojo_round_down = RoundingMode.down()
    var mojo_round_up = RoundingMode.up()

    var py_round_half_even = pydecimal.ROUND_HALF_EVEN
    var py_round_half_up = pydecimal.ROUND_HALF_UP
    var py_round_down = pydecimal.ROUND_DOWN
    var py_round_up = pydecimal.ROUND_UP

    # Instead of looping through lists, test each case explicitly
    # Test case 1: Zero with integer quantizer
    test_single_quantize_case(
        "0", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "0", "1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "0", "1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case("0", "1", mojo_round_up, py_round_up, pydecimal)

    # Test case 2: Decimal128 with 2 decimal places quantizer
    test_single_quantize_case(
        "1.23456", "0.01", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "1.23456", "0.01", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "1.23456", "0.01", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "1.23456", "0.01", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 3: Decimal128 with 1 decimal place quantizer
    test_single_quantize_case(
        "9.999", "0.1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "9.999", "0.1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "9.999", "0.1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "9.999", "0.1", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 4: Negative value with integer quantizer
    test_single_quantize_case(
        "-0.5", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "-0.5", "1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "-0.5", "1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "-0.5", "1", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 5: Small value with larger precision
    test_single_quantize_case(
        "0.0001", "0.01", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "0.0001", "0.01", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "0.0001", "0.01", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "0.0001", "0.01", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 6: Large value with integer quantizer
    test_single_quantize_case(
        "1234.5678", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "1234.5678", "1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "1234.5678", "1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "1234.5678", "1", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 7: Rounding to larger precision
    test_single_quantize_case(
        "99.99", "100", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "99.99", "100", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "99.99", "100", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "99.99", "100", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 8: Very small value with small precision
    test_single_quantize_case(
        "0.0000001",
        "0.00001",
        mojo_round_half_even,
        py_round_half_even,
        pydecimal,
    )
    test_single_quantize_case(
        "0.0000001", "0.00001", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "0.0000001", "0.00001", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "0.0000001", "0.00001", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 9: Large value with 1 decimal place
    test_single_quantize_case(
        "987654.321", "0.1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "987654.321", "0.1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "987654.321", "0.1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "987654.321", "0.1", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 10: Testing banker's rounding
    test_single_quantize_case(
        "1.5", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "2.5", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )

    # Test case 11: Testing rounding to thousands
    test_single_quantize_case(
        "10000", "1000", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "10000", "1000", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "10000", "1000", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "10000", "1000", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 12: Rounding up very close value
    test_single_quantize_case(
        "0.999999", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "0.999999", "1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "0.999999", "1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "0.999999", "1", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 13: Pi with very high precision
    test_single_quantize_case(
        "3.14159265358979323",
        "0.00000000001",
        mojo_round_half_even,
        py_round_half_even,
        pydecimal,
    )

    # Test case 14: Negative value rounding
    test_single_quantize_case(
        "-999.9", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )
    test_single_quantize_case(
        "-999.9", "1", mojo_round_half_up, py_round_half_up, pydecimal
    )
    test_single_quantize_case(
        "-999.9", "1", mojo_round_down, py_round_down, pydecimal
    )
    test_single_quantize_case(
        "-999.9", "1", mojo_round_up, py_round_up, pydecimal
    )

    # Test case 15: Zero with trailing zeros
    test_single_quantize_case(
        "0.0", "0.0000", mojo_round_half_even, py_round_half_even, pydecimal
    )

    # Test case 16: Integer to integer
    test_single_quantize_case(
        "123", "1", mojo_round_half_even, py_round_half_even, pydecimal
    )

    print("✓ Comprehensive comparison tests passed!")


fn test_single_quantize_case(
    value_str: String,
    quant_str: String,
    mojo_mode: RoundingMode,
    py_mode: PythonObject,
    pydecimal: PythonObject,
) raises:
    """Test a single quantize case comparing Mojo and Python implementations."""

    try:
        var mojo_value = Decimal128(value_str)
        var mojo_quant = Decimal128(quant_str)
        var py_value = pydecimal.Decimal(value_str)
        var py_quant = pydecimal.Decimal(quant_str)

        var mojo_result = mojo_value.quantize(mojo_quant, mojo_mode)
        var py_result = py_value.quantize(py_quant, rounding=py_mode)

        testing.assert_equal(
            String(mojo_result),
            String(py_result),
            String("Quantizing {} to {} gave incorrect result: {}").format(
                value_str, quant_str, String(mojo_result)
            ),
        )
    except e:
        print(
            String("Exception occurred (expected): {} to {}").format(
                value_str, quant_str
            )
        )
        # Both implementations should either both succeed or both fail


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
    print("Running Decimal128.quantize() Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_quantization, "Basic quantization test"
    )
    run_test_with_error_handling(test_rounding_modes, "Rounding modes test")
    run_test_with_error_handling(test_edge_cases, "Edge cases test")
    run_test_with_error_handling(test_special_cases, "Special cases test")
    run_test_with_error_handling(
        test_quantize_exceptions, "Exception handling test"
    )
    run_test_with_error_handling(
        test_comprehensive_comparison, "Comprehensive comparison test"
    )

    print("All Decimal128.quantize() tests passed!")
