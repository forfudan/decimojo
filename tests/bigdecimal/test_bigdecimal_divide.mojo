"""
Test BigDecimal arithmetic operations including addition, subtraction, multiplication and division.
"""

from python import Python
import testing

from decimojo import BigDecimal, RoundingMode
from decimojo.tests import TestCase
from tomlmojo import parse_file

alias division_file_path = "tests/bigdecimal/test_data/bigdecimal_divide.toml"


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
                case_table["expected"].as_string(),
                case_table["description"].as_string(),
            )
        )

    return test_cases


fn test_true_divide() raises:
    """Test BigDecimal division with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal division...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases(division_file_path, "division_tests")
    print("Loaded", len(test_cases), "test cases for division")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Special case: Check if divisor is zero
        if String(b) == "0":
            print("Skipping division by zero test (would cause error)")
            continue

        var result = a / b

        try:
            # Using String comparison for easier debugging
            testing.assert_equal(
                String(result), String(expected), test_case.description
            )
            passed += 1
        except e:
            print(
                "=" * 50,
                "\n",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "/",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    / pydecimal.Decimal(test_case.b)
                ),
            )
            failed += 1

    print("BigDecimal division tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All division tests should pass")


fn test_division_by_zero() raises:
    """Test that division by zero raises an error."""
    print("------------------------------------------------------")
    print("Testing BigDecimal division by zero...")

    var a = BigDecimal("1")
    var b = BigDecimal("0")

    var exception_caught = False
    try:
        _ = a / b
        exception_caught = False
    except:
        exception_caught = True

    testing.assert_true(
        exception_caught, "Division by zero should raise an error"
    )
    print("✓ Division by zero correctly raises an error")


fn main() raises:
    print("Running BigDecimal arithmetic tests")

    # Run division tests
    test_true_divide()

    # Test division by zero
    test_division_by_zero()

    print("All BigDecimal arithmetic tests passed!")
