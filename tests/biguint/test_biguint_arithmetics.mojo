"""
Test BigUInt arithmetic operations including addition, subtraction, and multiplication.
BigUInt is an unsigned integer type, so it doesn't support negative values.
"""

from decimojo.biguint.biguint import BigUInt
from decimojo.tests import TestCase
import testing
from tomlmojo import parse_file

alias file_path = "tests/biguint/test_data/biguint_arithmetics.toml"


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
    print("------------------------------------------------------")
    print("Testing BigUInt addition...")

    # Load test cases from TOML file
    var test_cases = load_test_cases(file_path, "addition_tests")

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a + b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    print("BigUInt addition tests passed!")


fn test_subtract() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt subtraction...")

    # Load test cases from TOML file
    var test_cases = load_test_cases(file_path, "subtraction_tests")

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a - b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    # Special case: Test underflow handling
    print("Testing underflow behavior (smaller - larger)...")
    var toml = parse_file(file_path)
    var underflow_data = toml.get("subtraction_underflow")
    var a_underflow = BigUInt(underflow_data.table_values["a"].as_string())
    var b_underflow = BigUInt(underflow_data.table_values["b"].as_string())

    try:
        var result = a_underflow - b_underflow
        print("Implementation allows underflow, result is: " + String(result))
    except:
        print("Implementation correctly throws error on underflow")

    print("BigUInt subtraction tests passed!")


fn test_multiply() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt multiplication...")

    # Load test cases from TOML file
    var test_cases = load_test_cases(
        file_path,
        "multiplication_tests",
    )

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a * b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    print("BigUInt multiplication tests passed!")


fn test_extreme_cases() raises:
    print("------------------------------------------------------")
    print("Testing extreme cases...")

    # Load extreme addition test cases from TOML file
    var extreme_cases = load_test_cases(
        file_path,
        "extreme_addition_tests",
    )

    # Run addition test cases
    for i in range(len(extreme_cases)):
        var test_case = extreme_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a + b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    # Load extreme subtraction test cases from TOML file
    var subtraction_cases = load_test_cases(
        file_path,
        "extreme_subtraction_tests",
    )

    # Run subtraction test cases
    for i in range(len(subtraction_cases)):
        var test_case = subtraction_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a - b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    # Load extreme multiplication test cases from TOML file
    var multiplication_cases = load_test_cases(
        file_path,
        "extreme_multiplication_tests",
    )

    # Run multiplication test cases
    for i in range(len(multiplication_cases)):
        var test_case = multiplication_cases[i]
        var a = BigUInt(test_case.a)
        var b = BigUInt(test_case.b)
        var result = a * b
        testing.assert_equal(
            String(result), test_case.expected, test_case.description
        )

    print("Extreme case tests passed!")


fn main() raises:
    print("Running BigUInt arithmetic tests")

    # Run addition tests
    test_add()

    # Run subtraction tests
    test_subtract()

    # Run multiplication tests
    test_multiply()

    # Run extreme cases tests
    test_extreme_cases()

    print("All BigUInt arithmetic tests passed!")
