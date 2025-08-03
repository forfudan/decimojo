"""
Test BigUInt arithmetic operations including addition, subtraction, and multiplication.
BigUInt is an unsigned integer type, so it doesn't support negative values.
"""


from python import Python
from random import random_ui64
from testing import assert_equal, assert_true
from decimojo.biguint.biguint import BigUInt
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path_arithmetics = "tests/biguint/test_data/biguint_arithmetics.toml"
alias file_path_truncate_divide = "tests/biguint/test_data/biguint_truncate_divide.toml"


fn test_biguint_arithmetics() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_arithmetics)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigUInt addition...")
    test_cases = load_test_cases(toml, "addition_tests")
    assert_true(len(test_cases) > 0, "No addition test cases found")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) + BigUInt(test_case.b)
        assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt addition tests passed!")

    print("------------------------------------------------------")
    print("Testing BigUInt inplace addition...")
    test_cases = load_test_cases(toml, "addition_tests")
    assert_true(len(test_cases) > 0, "No inplace addition test cases found")
    for test_case in test_cases:
        var result = BigUInt(test_case.a)
        result += BigUInt(test_case.b)
        assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt addition tests passed!")

    print("------------------------------------------------------")
    print("Testing BigUInt subtraction...")
    test_cases = load_test_cases(toml, "subtraction_tests")
    assert_true(len(test_cases) > 0, "No subtraction test cases found")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) - BigUInt(test_case.b)
        assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt subtraction tests passed!")

    print("------------------------------------------------------")
    print("Testing BigUInt multiplication...")

    # Load test cases from TOML file
    test_cases = load_test_cases(toml, "multiplication_tests")
    assert_true(len(test_cases) > 0, "No multiplication test cases found")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) * BigUInt(test_case.b)
        assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt multiplication tests passed!")

    # Special case: Test underflow handling
    print("Testing underflow behavior (smaller - larger)...")
    test_cases = load_test_cases(toml, "subtraction_underflow")
    assert_true(len(test_cases) > 0, "No underflow test cases found")
    for test_case in test_cases:
        try:
            var result = BigUInt(test_case.a) - BigUInt(test_case.b)
            print(
                "Implementation allows underflow, result is: " + String(result)
            )
        except:
            print("Implementation correctly throws error on underflow")
    print("BigUInt multiplication tests passed!")


fn test_biguint_truncate_divide() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_truncate_divide)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigUInt truncate division...")
    test_cases = load_test_cases(toml, "truncate_divide_tests")
    assert_true(len(test_cases) > 0, "No truncate division test cases found")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) // BigUInt(test_case.b)
        assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt truncate division tests passed!")


fn test_biguint_truncate_divide_random_numbers_against_python() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt truncate division on random numbers with python...")

    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(500000)

    var number_a: String
    var number_b: String

    for _test_case in range(10):
        number_a = String("")
        number_b = String("")
        for _i in range(12345):
            number_a += String(random_ui64(0, 999_999_999_999_999_999))
        for _i in range(789):
            number_b += String(random_ui64(0, 999_999_999_999_999_999))
        decimojo_result = String(BigUInt(number_a) // BigUInt(number_b))
        python_result = String(Python.int(number_a) // Python.int(number_b))
        assert_equal(
            lhs=decimojo_result,
            rhs=python_result,
            msg="Python int division does not match BigUInt division\n"
            + "number a: \n"
            + number_a
            + "\n\nnumber b: \n"
            + number_b
            + "\n\nDeciMojo BigUInt division: \n"
            + decimojo_result
            + "\n\nPython int division: \n"
            + python_result,
        )
    print("BigUInt truncate division tests passed!")


fn main() raises:
    test_biguint_arithmetics()
    test_biguint_truncate_divide()
    test_biguint_truncate_divide_random_numbers_against_python()
    print("All BigUInt arithmetic tests passed!")
    print("------------------------------------------------------")
