"""
Test BigDecimal exponential operations including square root and natural logarithm.
"""

from python import Python
import testing

from decimojo import BigDecimal, RoundingMode
from decimojo.tests import TestCase
from tomlmojo import parse_file

alias exponential_file_path = "tests/bigdecimal/test_data/bigdecimal_exponential.toml"


fn load_test_cases_one_argument(
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
    return test_cases^


fn load_test_cases_two_arguments(
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
    return test_cases^


fn test_sqrt() raises:
    """Test BigDecimal square root with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal square root...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_one_argument(
        exponential_file_path, "sqrt_tests"
    )
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
        var result = input_value.sqrt(precision=28)

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
        _ = negative_number.sqrt(precision=28)
        exception_caught = False
    except:
        exception_caught = True

    testing.assert_true(
        exception_caught, "Square root of negative number should raise an error"
    )
    print("✓ Square root of negative number correctly raises an error")


fn test_ln() raises:
    """Test BigDecimal natural logarithm with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal natural logarithm (ln)...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_one_argument(
        exponential_file_path, "ln_tests"
    )
    print("Loaded", len(test_cases), "test cases for natural logarithm")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var input_value = BigDecimal(test_case.a)
        var expected = BigDecimal(test_case.expected)

        # Calculate natural logarithm
        var result = input_value.ln()

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
                String(pydecimal.Decimal(test_case.a).ln()),
            )
            failed += 1

    print("BigDecimal ln tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All natural logarithm tests should pass")


fn test_ln_invalid_inputs() raises:
    """Test that natural logarithm with invalid inputs raises appropriate errors.
    """
    print("------------------------------------------------------")
    print("Testing BigDecimal natural logarithm with invalid inputs...")

    # Test 1: ln of zero should raise an error
    var zero = BigDecimal("0")
    var exception_caught = False
    try:
        _ = zero.ln()
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(exception_caught, "ln(0) should raise an error")
    print("✓ ln(0) correctly raises an error")

    # Test 2: ln of negative number should raise an error
    var negative = BigDecimal("-1")
    exception_caught = False
    try:
        _ = negative.ln()
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "ln of negative number should raise an error"
    )
    print("✓ ln of negative number correctly raises an error")


fn test_root() raises:
    """Test BigDecimal nth root with various test cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal root function...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        exponential_file_path, "root_tests"
    )
    print("Loaded", len(test_cases), "test cases for root function")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var base_value = BigDecimal(test_case.a)
        var root_value = BigDecimal(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Calculate nth root
        var result = base_value.root(root_value, precision=28)

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
                "\n  Base:",
                test_case.a,
                "\n  Root:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    ** (pydecimal.Decimal(1) / pydecimal.Decimal(test_case.b))
                ),
            )
            failed += 1

    print("BigDecimal root tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All root function tests should pass")


fn test_root_invalid_inputs() raises:
    """Test that root function with invalid inputs raises appropriate errors."""
    print("------------------------------------------------------")
    print("Testing BigDecimal root with invalid inputs...")

    # Test 1: 0th root should raise an error
    var a1 = BigDecimal("16")
    var n1 = BigDecimal("0")
    var exception_caught = False
    try:
        _ = a1.root(n1, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(exception_caught, "0th root should raise an error")
    print("✓ 0th root correctly raises an error")

    # Test 2: Even root of negative number should raise an error
    var a2 = BigDecimal("-16")
    var n2 = BigDecimal("2")
    exception_caught = False
    try:
        _ = a2.root(n2, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Even root of negative number should raise an error"
    )
    print("✓ Even root of negative number correctly raises an error")

    # Test 3: Fractional root with even denominator of negative number should raise an error
    var a3 = BigDecimal("-16")
    var n3 = BigDecimal("2.5")  # 5/2, denominator is even
    exception_caught = False
    try:
        _ = a3.root(n3, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught,
        (
            "Fractional root with even denominator of negative number should"
            " raise an error"
        ),
    )
    print(
        "✓ Fractional root with even denominator of negative number correctly"
        " raises an error"
    )


fn main() raises:
    print("Running BigDecimal exponential tests")

    # Run sqrt tests
    test_sqrt()

    # Test sqrt of negative number
    test_negative_sqrt()

    # Run root tests
    test_root()

    # Test root with invalid inputs
    test_root_invalid_inputs()

    # Run ln tests
    test_ln()

    # Test ln with invalid inputs
    test_ln_invalid_inputs()

    print("All BigDecimal exponential tests passed!")
