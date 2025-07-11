"""
Test BigInt arithmetic operations including addition, subtraction, and negation.
"""

import testing
from decimojo.bigint.bigint import BigInt
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path_arithmetics = "tests/bigint/test_data/bigint_arithmetics.toml"
alias file_path_multiply = "tests/bigint/test_data/bigint_multiply.toml"
alias file_path_floor_divide = "tests/bigint/test_data/bigint_floor_divide.toml"
alias file_path_truncate_divide = "tests/bigint/test_data/bigint_truncate_divide.toml"


fn test_bigint_arithmetics() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_arithmetics)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigInt addition...")
    test_cases = load_test_cases(toml, "addition_tests")
    for test_case in test_cases:
        var result = BigInt(test_case.a) + BigInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt addition tests passed!")

    print("------------------------------------------------------")
    print("Testing BigInt subtraction...")
    test_cases = load_test_cases(toml, "subtraction_tests")
    for test_case in test_cases:
        var result = BigInt(test_case.a) - BigInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt subtraction tests passed!")

    print("------------------------------------------------------")
    print("Testing BigInt negation...")
    test_cases = load_test_cases[unary=True](toml, "negation_tests")
    for test_case in test_cases:
        var result = -BigInt(test_case.a)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt negation tests passed!")

    print("------------------------------------------------------")
    print("Testing BigInt absolute value...")
    test_cases = load_test_cases[unary=True](toml, "abs_tests")
    for test_case in test_cases:
        var result = abs(BigInt(test_case.a))
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt absolute value tests passed!")


fn test_bigint_multiply() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_multiply)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigInt multiplication...")
    test_cases = load_test_cases(toml, "multiplication_tests")
    for test_case in test_cases:
        var result = BigInt(test_case.a) * BigInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt multiplication tests passed!")


fn test_bigint_floor_divide() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_floor_divide)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigInt floor division...")
    test_cases = load_test_cases(toml, "floor_divide_tests")
    for test_case in test_cases:
        var result = BigInt(test_case.a) // BigInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt floor division tests passed!")


fn test_bigint_truncate_divide() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_truncate_divide)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigInt truncate division...")
    test_cases = load_test_cases(toml, "truncate_divide_tests")
    for test_case in test_cases:
        var result = BigInt(test_case.a).truncate_divide(BigInt(test_case.b))
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigInt truncate division tests passed!")


fn main() raises:
    print("Running BigInt arithmetic tests")
    test_bigint_arithmetics()
    test_bigint_multiply()
    test_bigint_floor_divide()
    test_bigint_truncate_divide()
    print("All BigInt arithmetic tests passed!")
