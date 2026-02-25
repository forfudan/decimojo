"""
Test BigDecimal arithmetic operations including:

1. addition
2. subtraction
3. multiplication
4. division
"""

from python import Python
import testing

from decimo import BDec
from decimo.tests import TestCase, parse_file, load_test_cases

comptime file_path = "tests/bigdecimal/test_data/bigdecimal_arithmetics.toml"


fn test_bigdecimal_arithmetics() raises:
    # Load test cases from TOML file
    var pydecimal = Python.import_module("decimal")
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    # BigDecimal add/sub/mul are exact (unlimited precision).
    # Set Python context precision high so Python doesn't round.
    pydecimal.getcontext().prec = 500

    # -------------------------------------------------------
    # Testing BigDecimal addition
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "addition_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) + BDec(test_case.b)
        var mojo_str = String(result)
        var py_str = String(
            pydecimal.Decimal(test_case.a) + pydecimal.Decimal(test_case.b)
        )
        if mojo_str != py_str:
            print(
                test_case.description,
                "\n  Mojo:   ",
                mojo_str,
                "\n  Python: ",
                py_str,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Addition: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal subtraction
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "subtraction_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) - BDec(test_case.b)
        var mojo_str = String(result)
        var py_str = String(
            pydecimal.Decimal(test_case.a) - pydecimal.Decimal(test_case.b)
        )
        if mojo_str != py_str:
            print(
                test_case.description,
                "\n  Mojo:   ",
                mojo_str,
                "\n  Python: ",
                py_str,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Subtraction: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal multiplication
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "multiplication_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) * BDec(test_case.b)
        var mojo_str = String(result)
        var py_str = String(
            pydecimal.Decimal(test_case.a) * pydecimal.Decimal(test_case.b)
        )
        if mojo_str != py_str:
            print(
                test_case.description,
                "\n  Mojo:   ",
                mojo_str,
                "\n  Python: ",
                py_str,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Multiplication: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal division
    # -------------------------------------------------------

    # Division uses precision=28, so match Python's context.
    pydecimal.getcontext().prec = 28
    test_cases = load_test_cases(toml, "division_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).true_divide(
            BDec(test_case.b), precision=28
        )
        var mojo_str = String(result)
        var py_str = String(
            pydecimal.Decimal(test_case.a) / pydecimal.Decimal(test_case.b)
        )
        if mojo_str != py_str:
            print(
                test_case.description,
                "\n  Mojo:   ",
                mojo_str,
                "\n  Python: ",
                py_str,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Division: Mojo and Python results differ. See above.",
    )


fn main() raises:
    # print("Running BigDecimal arithmetic tests")

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All BigDecimal arithmetic tests passed!")
