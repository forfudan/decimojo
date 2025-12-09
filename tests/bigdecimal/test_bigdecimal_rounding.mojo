"""
Test BigDecimal rounding operations with various rounding modes and precision values.
"""

from python import Python
import testing

from decimojo.prelude import *
from decimojo.tests import TestCase, parse_file, load_test_cases

alias file_path = "tests/bigdecimal/test_data/bigdecimal_rounding.toml"


fn test_bigdecimal_rounding() raises:
    # Load test cases from TOML file
    var pydecimal = Python.import_module("decimal")
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    # print("------------------------------------------------------")
    # print("Testing BigDecimal ROUND_DOWN mode...")
    # print("------------------------------------------------------")

    pydecimal.getcontext().rounding = pydecimal.ROUND_DOWN
    test_cases = load_test_cases(toml, "round_down_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.down()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal ROUND_UP mode...")
    # print("------------------------------------------------------")

    pydecimal.getcontext().rounding = pydecimal.ROUND_UP
    test_cases = load_test_cases(toml, "round_up_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.up()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal ROUND_HALF_UP mode...")
    # print("------------------------------------------------------")

    pydecimal.getcontext().rounding = pydecimal.ROUND_HALF_UP
    test_cases = load_test_cases(toml, "round_half_up_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.half_up()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal ROUND_HALF_EVEN (banker's rounding) mode...")
    # print("------------------------------------------------------")

    pydecimal.getcontext().rounding = pydecimal.ROUND_HALF_EVEN
    test_cases = load_test_cases(toml, "round_half_even_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.half_even()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal rounding with extreme values...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "extreme_value_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.half_even()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal rounding with special edge cases...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "edge_case_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.half_even()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print(
    #     "Testing BigDecimal rounding with negative precision (rounding to tens,"
    #     " hundreds, etc.)"
    # )
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "precision_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.half_even()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal rounding with scientific notation inputs...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "scientific_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).round(
            Int(test_case.b), RoundingMode.half_even()
        )
        try:
            testing.assert_equal(
                lhs=String(result),
                rhs=test_case.expected,
                msg=test_case.description,
            )
        except e:
            print(
                test_case.description,
                "\n  Expected:",
                test_case.expected,
                "\n  Got:",
                String(result),
                "\n  Python decimal result (for reference):",
                String(
                    pydecimal.Decimal(test_case.a).__round__(Int(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )


fn test_default_rounding_mode() raises:
    """Test that the default rounding mode is ROUND_HALF_EVEN."""
    # print("------------------------------------------------------")
    # print("Testing BigDecimal default rounding mode...")

    var value = BDec("2.5")
    var result = value.round(0)
    var expected = BDec("2")  # HALF_EVEN rounds 2.5 to 2 (nearest even)

    testing.assert_equal(
        String(result),
        String(expected),
        "Default rounding mode should be ROUND_HALF_EVEN",
    )

    value = BDec("3.5")
    result = round(value, 0)  # No rounding mode specified
    expected = BDec("4")  # HALF_EVEN rounds 3.5 to 4 (nearest even)

    testing.assert_equal(
        String(result),
        String(expected),
        "Default rounding mode should be ROUND_HALF_EVEN",
    )

    # print("✓ Default rounding mode tests passed")


fn main() raises:
    # print("Running BigDecimal rounding tests")

    # Test different rounding modes
    # test_bigdecimal_rounding()
    # Test default rounding mode
    # test_default_rounding_mode()
    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All BigDecimal rounding tests passed!")
