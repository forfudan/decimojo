"""
Test BigInt10 arithmetic operations including addition, subtraction, and negation.
"""

import testing
from decimojo.bigint10.bigint10 import BigInt10
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path_arithmetics = "tests/bigint10/test_data/bigint10_arithmetics.toml"
comptime file_path_multiply = "tests/bigint10/test_data/bigint10_multiply.toml"
comptime file_path_floor_divide = "tests/bigint10/test_data/bigint10_floor_divide.toml"
comptime file_path_truncate_divide = "tests/bigint10/test_data/bigint10_truncate_divide.toml"


fn test_bigint10_arithmetics() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_arithmetics)
    var test_cases: List[TestCase]

    # print("------------------------------------------------------")
    # print("Testing BigInt10 addition...")
    test_cases = load_test_cases(toml, "addition_tests")
    for test_case in test_cases:
        var result = BigInt10(test_case.a) + BigInt10(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 addition tests passed!")

    # print("------------------------------------------------------")
    # print("Testing BigInt10 subtraction...")
    test_cases = load_test_cases(toml, "subtraction_tests")
    for test_case in test_cases:
        var result = BigInt10(test_case.a) - BigInt10(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 subtraction tests passed!")

    # print("------------------------------------------------------")
    # print("Testing BigInt10 negation...")
    test_cases = load_test_cases[unary=True](toml, "negation_tests")
    for test_case in test_cases:
        var result = -BigInt10(test_case.a)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 negation tests passed!")

    # print("------------------------------------------------------")
    # print("Testing BigInt10 absolute value...")
    test_cases = load_test_cases[unary=True](toml, "abs_tests")
    for test_case in test_cases:
        var result = abs(BigInt10(test_case.a))
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 absolute value tests passed!")


fn test_bigint10_multiply() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_multiply)
    var test_cases: List[TestCase]

    # print("------------------------------------------------------")
    # print("Testing BigInt10 multiplication...")
    test_cases = load_test_cases(toml, "multiplication_tests")
    for test_case in test_cases:
        var result = BigInt10(test_case.a) * BigInt10(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 multiplication tests passed!")


fn test_bigint10_floor_divide() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_floor_divide)
    var test_cases: List[TestCase]

    # print("------------------------------------------------------")
    # print("Testing BigInt10 floor division...")
    test_cases = load_test_cases(toml, "floor_divide_tests")
    for test_case in test_cases:
        var result = BigInt10(test_case.a) // BigInt10(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 floor division tests passed!")


fn test_bigint10_truncate_divide() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_truncate_divide)
    var test_cases: List[TestCase]

    # print("------------------------------------------------------")
    # print("Testing BigInt10 truncate division...")
    test_cases = load_test_cases(toml, "truncate_divide_tests")
    for test_case in test_cases:
        var result = BigInt10(test_case.a).truncate_divide(
            BigInt10(test_case.b)
        )
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    # print("BigInt10 truncate division tests passed!")


fn main() raises:
    # print("Running BigInt10 arithmetic tests")

    # test_bigint10_arithmetics()
    # test_bigint10_multiply()
    # test_bigint10_floor_divide()
    # test_bigint10_truncate_divide()
    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All BigInt10 arithmetic tests passed!")
