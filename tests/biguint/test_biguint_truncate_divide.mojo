"""
Comprehensive tests for the truncate_divide operation of the BigUInt type.
BigUInt is an unsigned integer type, so these tests focus on positive number divisions.
Tests also compare results with Python's built-in int type for verification.
"""

import testing
import decimojo.biguint.arithmetics
from decimojo.biguint.biguint import BigUInt
from decimojo.tests import TestCase, parse_file, load_test_cases
from python import Python, PythonObject

alias file_path = "tests/biguint/test_data/biguint_truncate_divide.toml"


fn run_test(
    toml: tomlmojo.parser.TOMLDocument, table_name: String, msg: String
) raises:
    """Run a specific test case from the TOML document."""
    print("------------------------------------------------------")
    print("Testing ", msg, "...", sep="")
    var test_cases = load_test_cases(toml, table_name)
    for test_case in test_cases:
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a // b
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("✓ " + msg + " tests passed!", sep="")


fn test_biguint_truncate_divide() raises:
    # Get Python's built-in int module
    var py = Python.import_module("builtins")
    # Load test cases from TOML file
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    run_test(toml, "basic_division_tests", "basic truncate division")
    run_test(toml, "large_number_tests", "truncate division with large numbers")
    run_test(
        toml, "division_rounding_tests", "truncate division rounding behavior"
    )
    run_test(toml, "edge_case_tests", "edge cases for truncate division")

    print("------------------------------------------------------")
    print("Testing division by zero error handling...")
    test_cases = load_test_cases(toml, "division_by_zero_tests")
    for test_case in test_cases:
        var exception_caught = False
        try:
            var _result = BigUInt(test_case.a) // BigUInt(test_case.b)
        except:
            exception_caught = True
        testing.assert_true(
            exception_caught, "Division by zero should raise an error"
        )
    print("✓ Zero handling tests passed!")


fn main() raises:
    print("=========================================")
    print("Running BigUInt Truncate Division Tests")
    print("=========================================")

    test_biguint_truncate_divide()

    print("All BigUInt truncate division tests passed!")
