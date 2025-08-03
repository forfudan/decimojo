"""
Test BigUInt exponential functions.
"""


from python import Python
from random import random_ui64
from testing import assert_equal, assert_true
from decimojo.biguint.biguint import BigUInt
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path_sqrt = "tests/biguint/test_data/biguint_sqrt.toml"


fn test_biguint_sqrt() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path_sqrt)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigUInt sqrt...")
    test_cases = load_test_cases[unary=True](toml, "sqrt_tests")
    assert_true(len(test_cases) > 0, "No sqrt test cases found")
    for test_case in test_cases:
        var result = BigUInt(test_case.a).sqrt()
        assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt sqrt tests passed!")


fn test_biguint_sqrt_random_numbers_against_python() raises:
    print("------------------------------------------------------")
    print("Testing BigUInt sqrt on random numbers with python...")

    var pysys = Python.import_module("sys")
    var pymath = Python.import_module("math")
    pysys.set_int_max_str_digits(25000)

    var number_a: String

    for _test_case in range(10):
        number_a = String("")
        for _i in range(666):
            number_a += String(random_ui64(0, 999_999_999_999_999_999))
        decimojo_result = String(BigUInt(number_a).sqrt())
        python_result = String(pymath.isqrt(Python.int(number_a)))
        assert_equal(
            lhs=decimojo_result,
            rhs=python_result,
            msg="Python int isqrt does not match BigUInt sqrt\n"
            + "number a: \n"
            + number_a
            + "\n\nDeciMojo BigUInt sqrt: \n"
            + decimojo_result
            + "\n\nPython int sqrt: \n"
            + python_result,
        )
    print("BigUInt sqrt tests passed!")


fn main() raises:
    test_biguint_sqrt()
    test_biguint_sqrt_random_numbers_against_python()
    print("All BigUInt exponential tests passed!")
    print("------------------------------------------------------")
