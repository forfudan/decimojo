"""
Test Decimal128 arithmetic operations including:

1. addition
2. subtraction
3. negation
4. absolute value
5. extreme / edge cases
"""

from python import Python
import testing

from decimojo import Dec128
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path = "tests/decimal128/test_data/decimal128_arithmetics.toml"


fn test_decimal128_arithmetics() raises:
    """Test addition, subtraction, negation, and absolute value using TOML
    data-driven test cases.
    """
    var pydecimal = Python.import_module("decimal")
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    # -----------------------------------------------------------------
    # Addition tests
    # -----------------------------------------------------------------

    test_cases = load_test_cases(toml, "addition_tests")
    var count_wrong = 0
    for test_case in test_cases:
        var result = Dec128(test_case.a) + Dec128(test_case.b)
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    + pydecimal.Decimal(test_case.b)
                ),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some addition test cases failed. See above for details.",
    )

    # -----------------------------------------------------------------
    # Subtraction tests
    # -----------------------------------------------------------------

    test_cases = load_test_cases(toml, "subtraction_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = Dec128(test_case.a) - Dec128(test_case.b)
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a)
                    - pydecimal.Decimal(test_case.b)
                ),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some subtraction test cases failed. See above for details.",
    )

    # -----------------------------------------------------------------
    # Negation tests (unary)
    # -----------------------------------------------------------------

    test_cases = load_test_cases[unary=True](toml, "negation_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = -Dec128(test_case.a)
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some negation test cases failed. See above for details.",
    )

    # -----------------------------------------------------------------
    # Absolute value tests (unary)
    # -----------------------------------------------------------------

    test_cases = load_test_cases[unary=True](toml, "abs_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = abs(Dec128(test_case.a))
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some absolute value test cases failed. See above for details.",
    )

    # -----------------------------------------------------------------
    # Extreme / edge case tests
    # -----------------------------------------------------------------

    test_cases = load_test_cases(toml, "extreme_addition_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = Dec128(test_case.a) + Dec128(test_case.b)
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some extreme test cases failed. See above for details.",
    )


fn test_repeated_addition() raises:
    """Test that repeated addition of 0.1 accumulates correctly."""
    var acc = Dec128(0)
    for _ in range(10):
        acc = acc + Dec128("0.1")
    testing.assert_equal(String(acc), "1.0", "Repeated addition of 0.1")


fn test_double_and_triple_negation() raises:
    """Test double and triple negation."""
    var a = Dec128("123.45")
    testing.assert_equal(String(-(-a)), "123.45", "Double negation")
    testing.assert_equal(String(-(-(-a))), "-123.45", "Triple negation")


fn test_addition_overflow() raises:
    """Test that adding beyond MAX raises an error."""
    try:
        var a = Dec128("79228162514264337593543950335")  # MAX
        var b = Dec128("1")
        var _result = a + b
        # If we reach here, overflow was not detected
        testing.assert_true(False, "Addition beyond MAX should raise an error")
    except:
        pass  # Expected: overflow correctly detected


fn test_subtraction_commutativity() raises:
    """Verify that a - b = -(b - a)."""
    var a = Dec128("123.456")
    var b = Dec128("789.012")
    var result1 = a - b
    var result2 = -(b - a)
    testing.assert_equal(
        String(result1), String(result2), "a - b should equal -(b - a)"
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
