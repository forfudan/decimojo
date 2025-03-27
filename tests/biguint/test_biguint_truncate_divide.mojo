"""
Comprehensive tests for the truncate_divide operation of the BigUInt type.
BigUInt is an unsigned integer type, so these tests focus on positive number divisions.
Tests also compare results with Python's built-in int type for verification.
"""

import testing
from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.arithmetics
from python import Python, PythonObject
from tomlmojo import parse_file
from decimojo.tests import TestCase

alias file_path = "tests/biguint/test_data/biguint_truncate_divide.toml"


fn load_test_cases(
    file_path: String, table_name: String
) raises -> List[TestCase]:
    """Load test cases from a TOML file for a specific table."""
    var toml = parse_file(file_path)
    var test_cases = List[TestCase]()

    # Get array of test cases
    var cases_array = toml.get_array_of_tables(table_name)

    for i in range(len(cases_array)):
        var case_table = cases_array[i]
        test_cases.append(
            TestCase(
                case_table["a"].as_string(),
                case_table["b"].as_string(),
                "",  # We don't need expected since we'll compare with Python
                case_table["description"].as_string(),
            )
        )

    return test_cases


fn test_basic_truncate_division() raises:
    """Test basic truncate division cases with positive numbers."""
    print("Testing basic truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "basic_division_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a // b

        # Compare with Python's result
        var py_a = py.int(test_case.a)
        var py_b = py.int(test_case.b)
        var py_result = py_a // py_b

        testing.assert_equal(
            String(result),
            String(py_result),
            test_case.description
            + " - Result doesn't match Python's int result",
        )
        print("✓ " + test_case.description)

    print("✓ Basic truncate division tests passed!")


fn test_zero_handling() raises:
    """Test truncate division cases involving zero."""
    print("Testing zero handling in truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "zero_handling_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a // b

        # Compare with Python's result
        var py_a = py.int(test_case.a)
        var py_b = py.int(test_case.b)
        var py_result = py_a // py_b

        testing.assert_equal(
            String(result),
            String(py_result),
            test_case.description
            + " - Result doesn't match Python's int result",
        )
        print("✓ " + test_case.description)

    # Special test for division by zero
    print("Testing division by zero error handling...")
    var toml = parse_file(file_path)
    var div_zero_data = toml.get("division_by_zero")
    var a_zero = BigUInt(div_zero_data.table_values["a"].as_string())
    var b_zero = BigUInt(div_zero_data.table_values["b"].as_string())

    var exception_caught = False
    try:
        var _result = a_zero // b_zero
    except:
        exception_caught = True

    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )
    print("✓ Division by zero correctly raises an error")

    print("✓ Zero handling tests passed!")


fn test_large_number_division() raises:
    """Test truncate division with very large numbers."""
    print("Testing truncate division with large numbers...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "large_number_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a // b

        # Compare with Python's result
        var py_a = py.int(test_case.a)
        var py_b = py.int(test_case.b)
        var py_result = py_a // py_b

        testing.assert_equal(
            String(result),
            String(py_result),
            test_case.description
            + " - Result doesn't match Python's int result",
        )
        print("✓ " + test_case.description)

    print("✓ Large number division tests passed!")


fn test_division_rounding() raises:
    """Test that truncate division correctly truncates toward zero."""
    print("Testing truncate division rounding behavior...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "division_rounding_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a // b

        # Compare with Python's result
        var py_a = py.int(test_case.a)
        var py_b = py.int(test_case.b)
        var py_result = py_a // py_b

        testing.assert_equal(
            String(result),
            String(py_result),
            test_case.description
            + " - Result doesn't match Python's int result",
        )
        print("✓ " + test_case.description)

    print("✓ Division rounding tests passed!")


fn test_division_identity() raises:
    """Test mathematical properties of truncate division."""
    print("Testing mathematical properties of truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "division_identity_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)

        # Mojo calculations
        var quotient = a // b
        var remainder = a % b
        var reconstructed = quotient * b + remainder

        # Python calculations
        var py_a = py.int(test_case.a)
        var py_b = py.int(test_case.b)
        var py_quotient = py_a // py_b
        var py_remainder = py_a % py_b
        var py_reconstructed = py_quotient * py_b + py_remainder

        # Verify all parts match Python and the identity holds
        testing.assert_equal(
            String(quotient),
            String(py_quotient),
            test_case.description + " - Quotient doesn't match Python's result",
        )

        testing.assert_equal(
            String(remainder),
            String(py_remainder),
            test_case.description
            + " - Remainder doesn't match Python's result",
        )

        testing.assert_equal(
            String(reconstructed),
            String(a),
            test_case.description + " - (a / b) * b + (a % b) should equal a",
        )

        testing.assert_equal(
            String(reconstructed),
            String(py_reconstructed),
            test_case.description
            + " - Reconstructed value doesn't match Python's result",
        )

        print("✓ " + test_case.description)

    print("✓ Mathematical identity tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for truncate division."""
    print("Testing edge cases for truncate division...")

    # Get Python's built-in int module
    var py = Python.import_module("builtins")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "edge_case_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a // b

        # Compare with Python's result
        var py_a = py.int(test_case.a)
        var py_b = py.int(test_case.b)
        var py_result = py_a // py_b

        testing.assert_equal(
            String(result),
            String(py_result),
            test_case.description
            + " - Result doesn't match Python's int result",
        )
        print("✓ " + test_case.description)

    print("✓ Edge cases tests passed!")


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
    print("Running BigUInt Truncate Division Tests")
    print("=========================================")

    run_test_with_error_handling(
        test_basic_truncate_division, "Basic truncate division test"
    )
    run_test_with_error_handling(test_zero_handling, "Zero handling test")
    run_test_with_error_handling(
        test_large_number_division, "Large number division test"
    )
    run_test_with_error_handling(
        test_division_rounding, "Division rounding behavior test"
    )
    run_test_with_error_handling(
        test_division_identity, "Mathematical identity test"
    )
    run_test_with_error_handling(test_edge_cases, "Edge cases test")

    print("All BigUInt truncate division tests passed!")
