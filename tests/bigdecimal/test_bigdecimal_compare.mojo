"""
Test BigDecimal comparison operations.
"""

from python import Python
import testing

from decimojo import BDec
from decimojo.bigdecimal.comparison import compare_absolute, compare
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path = "tests/bigdecimal/test_data/bigdecimal_compare.toml"


fn test_bigdecimal_compare() raises:
    # Load test cases from TOML file
    var pydecimal = Python.import_module("decimal")
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]
    var count_wrong: Int

    # -------------------------------------------------------
    # Testing BigDecimal compare_absolute
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "compare_absolute_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = compare_absolute(BDec(test_case.a), BDec(test_case.b))
        var mojo_val = Int(result)
        var py_cmp = (
            pydecimal.Decimal(test_case.a)
            .copy_abs()
            .compare(pydecimal.Decimal(test_case.b).copy_abs())
        )
        var py_val = Int(py=py_cmp)
        if mojo_val != py_val:
            print(
                test_case.description,
                "\n  Mojo:   ",
                mojo_val,
                "\n  Python: ",
                py_val,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "compare_absolute: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal > operator
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "greater_than_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) > BDec(test_case.b)
        var py_result = Bool(
            pydecimal.Decimal(test_case.a) > pydecimal.Decimal(test_case.b)
        )
        if result != py_result:
            print(
                test_case.description,
                "\n  Mojo:   ",
                result,
                "\n  Python: ",
                py_result,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        ">: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal < operator
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "less_than_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) < BDec(test_case.b)
        var py_result = Bool(
            pydecimal.Decimal(test_case.a) < pydecimal.Decimal(test_case.b)
        )
        if result != py_result:
            print(
                test_case.description,
                "\n  Mojo:   ",
                result,
                "\n  Python: ",
                py_result,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "<: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal >= operator
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "greater_than_or_equal_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) >= BDec(test_case.b)
        var py_result = Bool(
            pydecimal.Decimal(test_case.a) >= pydecimal.Decimal(test_case.b)
        )
        if result != py_result:
            print(
                test_case.description,
                "\n  Mojo:   ",
                result,
                "\n  Python: ",
                py_result,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        ">=: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal <= operator
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "less_than_or_equal_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) <= BDec(test_case.b)
        var py_result = Bool(
            pydecimal.Decimal(test_case.a) <= pydecimal.Decimal(test_case.b)
        )
        if result != py_result:
            print(
                test_case.description,
                "\n  Mojo:   ",
                result,
                "\n  Python: ",
                py_result,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "<=: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal == operator
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "equal_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) == BDec(test_case.b)
        var py_result = Bool(
            pydecimal.Decimal(test_case.a) == pydecimal.Decimal(test_case.b)
        )
        if result != py_result:
            print(
                test_case.description,
                "\n  Mojo:   ",
                result,
                "\n  Python: ",
                py_result,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "==: Mojo and Python results differ. See above.",
    )

    # -------------------------------------------------------
    # Testing BigDecimal != operator
    # -------------------------------------------------------

    test_cases = load_test_cases(toml, "not_equal_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a) != BDec(test_case.b)
        var py_result = Bool(
            pydecimal.Decimal(test_case.a) != pydecimal.Decimal(test_case.b)
        )
        if result != py_result:
            print(
                test_case.description,
                "\n  Mojo:   ",
                result,
                "\n  Python: ",
                py_result,
                "\n",
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "!=: Mojo and Python results differ. See above.",
    )


fn main() raises:
    # print("Running BigDecimal comparison tests")

    # Run compare_absolute tests
    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All BigDecimal comparison tests passed!")
