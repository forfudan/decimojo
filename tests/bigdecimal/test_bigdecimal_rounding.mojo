"""
Test BigDecimal rounding operations with various rounding modes and precision values.
"""

from python import Python
import testing

from decimojo import BigDecimal, RoundingMode
from decimojo.tests import TestCase
from tomlmojo import parse_file

alias rounding_file_path = "tests/bigdecimal/test_data/bigdecimal_rounding.toml"


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
                case_table["a"].as_string(),  # Value to round
                case_table["b"].as_string(),  # Decimal places
                case_table["expected"].as_string(),  # Expected result
                case_table["description"].as_string(),  # Test description
            )
        )
    return test_cases^


fn test_round_down() raises:
    """Test BigDecimal rounding with ROUND_DOWN mode."""
    print("------------------------------------------------------")
    print("Testing BigDecimal ROUND_DOWN mode...")

    var pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "round_down_tests"
    )
    print("Loaded", len(test_cases), "test cases for ROUND_DOWN")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding
        var result = value.round(decimal_places, RoundingMode.ROUND_DOWN)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print("BigDecimal ROUND_DOWN tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All ROUND_DOWN tests should pass")


fn test_round_up() raises:
    """Test BigDecimal rounding with ROUND_UP mode."""
    print("------------------------------------------------------")
    print("Testing BigDecimal ROUND_UP mode...")

    pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "round_up_tests"
    )
    print("Loaded", len(test_cases), "test cases for ROUND_UP")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding
        var result = value.round(decimal_places, RoundingMode.ROUND_UP)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print("BigDecimal ROUND_UP tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All ROUND_UP tests should pass")


fn test_round_half_up() raises:
    """Test BigDecimal rounding with ROUND_HALF_UP mode."""
    print("------------------------------------------------------")
    print("Testing BigDecimal ROUND_HALF_UP mode...")

    pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "round_half_up_tests"
    )
    print("Loaded", len(test_cases), "test cases for ROUND_HALF_UP")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding
        var result = value.round(decimal_places, RoundingMode.ROUND_HALF_UP)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print(
        "BigDecimal ROUND_HALF_UP tests:", passed, "passed,", failed, "failed"
    )
    testing.assert_equal(failed, 0, "All ROUND_HALF_UP tests should pass")


fn test_round_half_even() raises:
    """Test BigDecimal rounding with ROUND_HALF_EVEN (banker's rounding) mode.
    """
    print("------------------------------------------------------")
    print("Testing BigDecimal ROUND_HALF_EVEN mode...")

    pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "round_half_even_tests"
    )
    print("Loaded", len(test_cases), "test cases for ROUND_HALF_EVEN")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding
        var result = value.round(decimal_places, RoundingMode.ROUND_HALF_EVEN)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print(
        "BigDecimal ROUND_HALF_EVEN tests:", passed, "passed,", failed, "failed"
    )
    testing.assert_equal(failed, 0, "All ROUND_HALF_EVEN tests should pass")


fn test_extreme_values() raises:
    """Test BigDecimal rounding with extreme values."""
    print("------------------------------------------------------")
    print("Testing BigDecimal rounding with extreme values...")

    pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 100

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "extreme_value_tests"
    )
    print("Loaded", len(test_cases), "test cases for extreme values")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding with default ROUND_HALF_EVEN mode
        var result = value.round(decimal_places, RoundingMode.ROUND_HALF_EVEN)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(decimal_places)
                ),
            )
            failed += 1

    print(
        "BigDecimal extreme value tests:", passed, "passed,", failed, "failed"
    )
    testing.assert_equal(failed, 0, "All extreme value tests should pass")


fn test_edge_cases() raises:
    """Test BigDecimal rounding with special edge cases."""
    print("------------------------------------------------------")
    print("Testing BigDecimal rounding with special edge cases...")

    pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "edge_case_tests"
    )
    print("Loaded", len(test_cases), "test cases for edge cases")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)

        # Perform rounding with default ROUND_HALF_EVEN mode
        var result = value.round(decimal_places, RoundingMode.ROUND_HALF_EVEN)

        try:
            # Using String comparison for easier debugging
            testing.assert_equal(
                String(result), test_case.expected, test_case.description
            )
            passed += 1
        except e:
            print(
                "=" * 50,
                "\n",
                i + 1,
                "failed:",
                test_case.description,
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print("BigDecimal edge case tests:", passed, "passed,", failed, "failed")
    testing.assert_equal(failed, 0, "All edge case tests should pass")


fn test_precision_conversions() raises:
    """Test BigDecimal rounding with negative precision (rounding to tens, hundreds, etc.).
    """
    print("------------------------------------------------------")
    print("Testing BigDecimal rounding with precision conversions...")

    pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "precision_tests"
    )
    print("Loaded", len(test_cases), "test cases for precision conversions")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding with default ROUND_HALF_EVEN mode
        var result = value.round(decimal_places, RoundingMode.ROUND_HALF_EVEN)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print(
        "BigDecimal precision conversion tests:",
        passed,
        "passed,",
        failed,
        "failed",
    )
    testing.assert_equal(
        failed, 0, "All precision conversion tests should pass"
    )


fn test_scientific_notation() raises:
    """Test BigDecimal rounding with scientific notation inputs."""
    print("------------------------------------------------------")
    print("Testing BigDecimal rounding with scientific notation inputs...")

    pydecimal = Python.import_module("decimal")

    # Load test cases from TOML file
    var test_cases = load_test_cases_two_arguments(
        rounding_file_path, "scientific_tests"
    )
    print("Loaded", len(test_cases), "test cases for scientific notation")

    # Track test results
    var passed = 0
    var failed = 0

    # Run all test cases in a loop
    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var value = BigDecimal(test_case.a)
        var decimal_places = Int(test_case.b)
        var expected = BigDecimal(test_case.expected)

        # Perform rounding with default ROUND_HALF_EVEN mode
        var result = value.round(decimal_places, RoundingMode.ROUND_HALF_EVEN)

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
                "\n  Value:",
                test_case.a,
                "\n  Decimal places:",
                test_case.b,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            failed += 1

    print(
        "BigDecimal scientific notation tests:",
        passed,
        "passed,",
        failed,
        "failed",
    )
    testing.assert_equal(failed, 0, "All scientific notation tests should pass")


fn test_default_rounding_mode() raises:
    """Test that the default rounding mode is ROUND_HALF_EVEN."""
    print("------------------------------------------------------")
    print("Testing BigDecimal default rounding mode...")

    var value = BigDecimal("2.5")
    var result = value.round(0, RoundingMode.ROUND_HALF_EVEN)
    var expected = BigDecimal("2")  # HALF_EVEN rounds 2.5 to 2 (nearest even)

    testing.assert_equal(
        String(result),
        String(expected),
        "Default rounding mode should be ROUND_HALF_EVEN",
    )

    value = BigDecimal("3.5")
    result = round(value, 0)  # No rounding mode specified
    expected = BigDecimal("4")  # HALF_EVEN rounds 3.5 to 4 (nearest even)

    testing.assert_equal(
        String(result),
        String(expected),
        "Default rounding mode should be ROUND_HALF_EVEN",
    )

    print("✓ Default rounding mode tests passed")


fn main() raises:
    print("Running BigDecimal rounding tests")

    # Test different rounding modes
    test_round_down()
    test_round_up()
    test_round_half_up()
    test_round_half_even()

    # Test special cases
    test_extreme_values()
    test_edge_cases()
    test_precision_conversions()
    test_scientific_notation()

    # Test default rounding mode
    test_default_rounding_mode()

    print("All BigDecimal rounding tests passed!")
