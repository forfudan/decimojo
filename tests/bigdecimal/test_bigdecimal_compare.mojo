"""
Test BigDecimal comparison operations.
"""

import testing
from python import PythonObject
from tomlmojo import parse_file
from decimojo import BigDecimal
from decimojo.bigdecimal.comparison import compare_absolute, compare
from decimojo.tests import TestCase
from collections import List

alias file_path = "tests/bigdecimal/test_data/bigdecimal_compare.toml"


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


fn test_compare_absolute() raises:
    """Test the compare_absolute function for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal compare_absolute...")

    # Load test cases from TOML file
    var test_cases = load_test_cases(file_path, "compare_absolute_tests")
    print("Loaded", len(test_cases), "test cases for compare_absolute")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = Int8(Int(test_case.expected))
        var result = compare_absolute(a, b)

        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input: |",
                test_case.a,
                "| compare |",
                test_case.b,
                "|",
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print(
        "BigDecimal compare_absolute tests:",
        passed,
        "passed,",
        failed,
        "failed",
    )
    testing.assert_equal(failed, 0, "All compare_absolute tests should pass")


fn test_greater_than() raises:
    """Test the > operator for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal > operator...")
    var test_cases = load_test_cases(file_path, "greater_than_tests")
    var passed = 0
    var failed = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = test_case.expected == "true"
        var result = a > b
        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                ">",
                test_case.b,
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print("BigDecimal > tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All > tests should pass")


fn test_less_than() raises:
    """Test the < operator for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal < operator...")
    var test_cases = load_test_cases(file_path, "less_than_tests")
    var passed = 0
    var failed = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = test_case.expected == "true"
        var result = a < b
        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "<",
                test_case.b,
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print("BigDecimal < tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All < tests should pass")


fn test_greater_than_or_equal() raises:
    """Test the >= operator for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal >= operator...")
    var test_cases = load_test_cases(file_path, "greater_than_or_equal_tests")
    var passed = 0
    var failed = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = test_case.expected == "true"
        var result = a >= b
        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                ">=",
                test_case.b,
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print("BigDecimal >= tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All >= tests should pass")


fn test_less_than_or_equal() raises:
    """Test the <= operator for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal <= operator...")
    var test_cases = load_test_cases(file_path, "less_than_or_equal_tests")
    var passed = 0
    var failed = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = test_case.expected == "true"
        var result = a <= b
        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "<=",
                test_case.b,
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print("BigDecimal <= tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All <= tests should pass")


fn test_equal() raises:
    """Test the == operator for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal == operator...")
    var test_cases = load_test_cases(file_path, "equal_tests")
    var passed = 0
    var failed = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = test_case.expected == "true"
        var result = a == b
        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "==",
                test_case.b,
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print("BigDecimal == tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All == tests should pass")


fn test_not_equal() raises:
    """Test the != operator for BigDecimal."""
    print("------------------------------------------------------")
    print("Testing BigDecimal != operator...")
    var test_cases = load_test_cases(file_path, "not_equal_tests")
    var passed = 0
    var failed = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigDecimal(test_case.a)
        var b = BigDecimal(test_case.b)
        var expected = test_case.expected == "true"
        var result = a != b
        try:
            testing.assert_equal(result, expected, test_case.description)
            passed += 1
        except e:
            print(
                "✗ Case",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Input:",
                test_case.a,
                "!=",
                test_case.b,
                "\n  Expected:",
                expected,
                "\n  Got:",
                result,
            )
            failed += 1

    print("BigDecimal != tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All != tests should pass")


fn main() raises:
    print("Running BigDecimal comparison tests")

    # Run compare_absolute tests
    test_compare_absolute()

    # Run comparison operator tests
    test_greater_than()
    test_less_than()
    test_greater_than_or_equal()
    test_less_than_or_equal()
    test_equal()
    test_not_equal()

    print("All BigDecimal comparison tests passed!")
