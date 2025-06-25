"""
Test BigDecimal arithmetic operations including addition, subtraction, multiplication and division.
"""

from python import Python
import testing

from decimojo import BigDecimal, RoundingMode
from decimojo.tests import TestCase
from tomlmojo import parse_file

alias file_path = "tests/bigdecimal/test_data/bigdecimal_arithmetics.toml"


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


fn test_add() raises:
    """Test BigDecimal addition with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal addition...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases(file_path, "addition_tests")
    print("Loaded", len(test_cases), "test cases for addition")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = BigDecimal(test_case.expected)
        var result = a + b

        try:
            # Using String comparison for easier debugging
            testing.assert_equal(
                String(result), String(expected), test_case.description
            )
            # print("✓ Case", i + 1, ":", test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "+",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    + pydecimal.Decimal(test_case.b)
                ),
            )
            failed += 1

    print("BigDecimal addition tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All addition tests should pass")


fn test_subtract() raises:
    """Test BigDecimal subtraction with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal subtraction...")

    var pydecimal = Python.import_module("decimal")

    # Debug TOML parsing
    var toml = parse_file(file_path)
    print("TOML file loaded successfully")

    # Check what root keys are available
    print("Available root keys:")
    for key in toml.root.keys():
        print("  - " + key)

    # Try to access the specific section
    try:
        var section = toml.get_array_of_tables("subtraction_tests")
        print("Found subtraction_tests with", len(section), "entries")
    except e:
        print("Error accessing subtraction_tests:", String(e))

    # Load test cases from TOML file
    var test_cases = load_test_cases(file_path, "subtraction_tests")
    print("Loaded", len(test_cases), "test cases for subtraction")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = BigDecimal(test_case.expected)
        var result = a - b

        try:
            # Using String comparison for easier debugging
            testing.assert_equal(
                String(result), String(expected), test_case.description
            )
            # print("✓ Case", i + 1, ":", test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "-",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    - pydecimal.Decimal(test_case.b)
                ),
            )
            failed += 1

    print("BigDecimal subtraction tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All subtraction tests should pass")


fn test_multiply() raises:
    """Test BigDecimal multiplication with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal multiplication...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases(file_path, "multiplication_tests")
    print("Loaded", len(test_cases), "test cases for multiplication")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = BigDecimal(test_case.expected)
        var result = a * b

        try:
            # Using String comparison for easier debugging
            testing.assert_equal(
                String(result), String(expected), test_case.description
            )
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "*",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    * pydecimal.Decimal(test_case.b)
                ),
            )
            failed += 1

    print(
        "BigDecimal multiplication tests:", passed, "passed,", failed, "failed"
    )
    testing.assert_equal(failed, 0, "All multiplication tests should pass")


fn main() raises:
    print("Running BigDecimal arithmetic tests")

    # Run addition tests
    test_add()

    # Run subtraction tests
    test_subtract()

    # Run multiplication tests
    test_multiply()

    print("All BigDecimal arithmetic tests passed!")
