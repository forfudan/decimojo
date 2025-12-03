"""
Test BigDecimal arithmetic operations including:

1. addition
2. subtraction
3. multiplication
4. division
"""

from python import Python
import testing

from decimojo import BDec, RM
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path = "tests/bigdecimal/test_data/bigdecimal_arithmetics.toml"


fn test_bigdecimal_arithmetics() raises:
    # Load test cases from TOML file
    var pydecimal = Python.import_module("decimal")
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigDecimal addition...")
    print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "addition_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) + BDec(test_case.b)
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
        "Some test cases failed. See above for details.",
    )

    print("------------------------------------------------------")
    print("Testing BigDecimal subtraction...")
    print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "subtraction_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) - BDec(test_case.b)
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
        "Some test cases failed. See above for details.",
    )

    print("------------------------------------------------------")
    print("Testing BigDecimal multiplication...")
    print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "multiplication_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) * BDec(test_case.b)
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
                    * pydecimal.Decimal(test_case.b)
                ),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    print("------------------------------------------------------")
    print("Testing BigDecimal division...")
    print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "division_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).true_divide(
            BDec(test_case.b), precision=28
        )
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
                    / pydecimal.Decimal(test_case.b)
                ),
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )


fn main() raises:
    print("Running BigDecimal arithmetic tests")

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    print("All BigDecimal arithmetic tests passed!")
