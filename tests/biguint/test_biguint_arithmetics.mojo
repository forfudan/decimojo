"""
Test BigUInt arithmetic operations including addition, subtraction, and multiplication.
BigUInt is an unsigned integer type, so it doesn't support negative values.
"""

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
    print("BigUInt subtraction tests passed!")


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
    print("BigUInt addition tests passed!")


fn main() raises:
    print("Running BigUInt arithmetic tests")
    test_biguint_arithmetics()
    test_biguint_truncate_divide()
    print("All BigUInt arithmetic tests passed!")
