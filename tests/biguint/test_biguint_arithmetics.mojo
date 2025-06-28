"""
Test BigUInt arithmetic operations including addition, subtraction, and multiplication.
BigUInt is an unsigned integer type, so it doesn't support negative values.
"""

import testing
from decimojo.biguint.biguint import BigUInt
from decimojo.tests import TestCase, load_test_cases
import tomlmojo

alias file_path = "tests/biguint/test_data/biguint_arithmetics.toml"


fn test_biguint_arithmetics() raises:
    # Load test cases from TOML file
    var toml = tomlmojo.parse_file(file_path)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigUInt addition...")
    test_cases = load_test_cases(toml, "addition_tests")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) + BigUInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt addition tests passed!")

    print("------------------------------------------------------")
    print("Testing BigUInt subtraction...")
    test_cases = load_test_cases(toml, "subtraction_tests")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) - BigUInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )

    # Special case: Test underflow handling
    print("Testing underflow behavior (smaller - larger)...")
    test_cases = load_test_cases(toml, "subtraction_underflow")
    for test_case in test_cases:
        try:
            var result = BigUInt(test_case.a) - BigUInt(test_case.b)
            print(
                "Implementation allows underflow, result is: " + String(result)
            )
        except:
            print("Implementation correctly throws error on underflow")
    print("BigUInt subtraction tests passed!")

    print("------------------------------------------------------")
    print("Testing BigUInt multiplication...")

    # Load test cases from TOML file
    test_cases = load_test_cases(toml, "multiplication_tests")
    for test_case in test_cases:
        var result = BigUInt(test_case.a) * BigUInt(test_case.b)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )
    print("BigUInt multiplication tests passed!")


fn main() raises:
    print("Running BigUInt arithmetic tests")
    test_biguint_arithmetics()
    print("All BigUInt arithmetic tests passed!")
