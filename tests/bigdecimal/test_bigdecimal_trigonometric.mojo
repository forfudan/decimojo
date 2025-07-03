"""
Test BigDecimal trigonometric functions
"""

from python import Python
import testing

from decimojo import BDec
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path = "tests/bigdecimal/test_data/bigdecimal_trigonometric.toml"


fn test_bigdecimal_trignometric() raises:
    # Load test cases from TOML file
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    print("------------------------------------------------------")
    print("Testing BigDecimal arctan...")
    print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "arctan_tests")
    for test_case in test_cases:
        var result = BDec(test_case.a).arctan(precision=50)
        testing.assert_equal(
            lhs=String(result),
            rhs=test_case.expected,
            msg=test_case.description,
        )


fn main() raises:
    print("Running BigDecimal trigonometric tests")

    # Run all tests
    test_bigdecimal_trignometric()

    print("All BigDecimal trigonometric tests passed!")
