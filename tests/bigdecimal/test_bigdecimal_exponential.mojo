"""
Test BigDecimal exponential operations including square root.
"""

from python import Python
import testing

from decimojo import BigDecimal, RoundingMode
from decimojo.tests import TestCase
from tomlmojo import parse_file

alias exponential_file_path = "tests/bigdecimal/test_data/bigdecimal_exponential.toml"


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
                case_table["input"].as_string(),
                "",  # No second input for sqrt
                case_table["expected"].as_string(),
                case_table["description"].as_string(),
            )
        )

    return test_cases


fn test_sqrt() raises:
    """Test BigDecimal square root with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal square root...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases(exponential_file_path, "sqrt_tests")
    print("Loaded", len(test_cases), "test cases for square root")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var input_value = BigDecimal(test_case.a)
        var expected = BigDecimal(test_case.expected)

        # Calculate square root
        var result = input_value.sqrt()

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
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(pydecimal.Decimal(test_case.a).sqrt()),
            )
            failed += 1

    print("BigDecimal sqrt tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All square root tests should pass")


fn test_negative_sqrt() raises:
    """Test that square root of negative number raises an error."""
    print("------------------------------------------------------")
    print("Testing BigDecimal square root with negative input...")

    var negative_number = BigDecimal("-1")

    var exception_caught = False
    try:
        _ = negative_number.sqrt()
        exception_caught = False
    except:
        exception_caught = True

    testing.assert_true(
        exception_caught, "Square root of negative number should raise an error"
    )
    print("✓ Square root of negative number correctly raises an error")


fn main() raises:
    print("Running BigDecimal exponential tests")

    # Run sqrt tests
    test_sqrt()

    # Test sqrt of negative number
    test_negative_sqrt()

    print("All BigDecimal exponential tests passed!")
