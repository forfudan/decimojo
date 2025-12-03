"""
Test BigDecimal comparison operations.
"""

import testing

from decimojo import BDec
from decimojo.bigdecimal.comparison import compare_absolute, compare
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path = "tests/bigdecimal/test_data/bigdecimal_compare.toml"


fn test_bigdecimal_compare() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigDecimal compare_absolute...")
    print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "compare_absolute_tests")
    for test_case in test_cases:
        var result = compare_absolute(BDec(test_case.a), BDec(test_case.b))
        testing.assert_equal(
            lhs=result,
            rhs=Int8(Int(test_case.expected)),
            msg=test_case.description,
        )

    print("------------------------------------------------------")
    print("Testing BigDecimal > operator...")
    print("------------------------------------------------------")
    test_cases = load_test_cases(toml, "greater_than_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a) > BDec(test_case.b)
        testing.assert_equal(
            lhs=result,
            rhs=Bool(Int(test_case.expected)),
            msg=test_case.description,
        )

    print("------------------------------------------------------")
    print("Testing BigDecimal < operator...")
    print("------------------------------------------------------")
    test_cases = load_test_cases(toml, "less_than_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a) < BDec(test_case.b)
        testing.assert_equal(
            lhs=result,
            rhs=Bool(Int(test_case.expected)),
            msg=test_case.description,
        )

    print("------------------------------------------------------")
    print("Testing BigDecimal >= operator...")
    print("------------------------------------------------------")
    test_cases = load_test_cases(toml, "greater_than_or_equal_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a) >= BDec(test_case.b)
        testing.assert_equal(
            lhs=result,
            rhs=Bool(Int(test_case.expected)),
            msg=test_case.description,
        )

    print("------------------------------------------------------")
    print("Testing BigDecimal <= operator...")
    print("------------------------------------------------------")
    test_cases = load_test_cases(toml, "less_than_or_equal_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a) <= BDec(test_case.b)
        testing.assert_equal(
            lhs=result,
            rhs=Bool(Int(test_case.expected)),
            msg=test_case.description,
        )

    print("------------------------------------------------------")
    print("Testing BigDecimal == operator...")
    print("------------------------------------------------------")
    test_cases = load_test_cases(toml, "equal_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a) == BDec(test_case.b)
        testing.assert_equal(
            lhs=result,
            rhs=Bool(Int(test_case.expected)),
            msg=test_case.description,
        )

    print("------------------------------------------------------")
    print("Testing BigDecimal != operator...")
    print("------------------------------------------------------")
    test_cases = load_test_cases(toml, "not_equal_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a) != BDec(test_case.b)
        testing.assert_equal(
            lhs=result,
            rhs=Bool(Int(test_case.expected)),
            msg=test_case.description,
        )


fn main() raises:
    print("Running BigDecimal comparison tests")

    # Run compare_absolute tests
    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    print("All BigDecimal comparison tests passed!")
