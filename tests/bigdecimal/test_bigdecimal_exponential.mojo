"""
Test BigDecimal exponential operations including square root and natural logarithm.
"""

from python import Python
import testing

from decimojo import BDec
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path = "tests/bigdecimal/test_data/bigdecimal_exponential.toml"


fn test_bigdecimal_exponential() raises:
    # Load test cases from TOML file
    var pydecimal = Python.import_module("decimal")
    var toml = parse_file(file_path)
    var test_cases: List[TestCase]

    # print("------------------------------------------------------")
    # print("Testing BigDecimal square root...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "sqrt_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).sqrt(precision=28)
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
                String(pydecimal.Decimal(test_case.a).sqrt()),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal natural logarithm (ln)...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "ln_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).ln(precision=28)
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
                String(pydecimal.Decimal(test_case.a).ln()),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal root function...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "root_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).root(BDec(test_case.b), precision=28)
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
                    pydecimal.Decimal(test_case.a)
                    ** (pydecimal.Decimal(1) / pydecimal.Decimal(test_case.b))
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )

    # print("------------------------------------------------------")
    # print("Testing BigDecimal power function...")
    # print("------------------------------------------------------")

    test_cases = load_test_cases(toml, "power_tests")
    count_wrong = 0
    for test_case in test_cases:
        var result = BDec(test_case.a).power(BDec(test_case.b), precision=28)
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
                    pydecimal.Decimal(test_case.a)
                    ** pydecimal.Decimal(test_case.b)
                ),
            )
            count_wrong += 1
    testing.assert_equal(
        count_wrong,
        0,
        "Some test cases failed. See above for details.",
    )


fn test_negative_sqrt() raises:
    """Test that square root of negative number raises an error."""
    # print("------------------------------------------------------")
    # print("Testing BigDecimal square root with negative input...")

    var negative_number = BDec("-1")

    var exception_caught: Bool
    try:
        _ = negative_number.sqrt(precision=28)
        exception_caught = False
    except:
        exception_caught = True

    testing.assert_true(
        exception_caught, "Square root of negative number should raise an error"
    )
    # print("✓ Square root of negative number correctly raises an error")


fn test_ln_invalid_inputs() raises:
    """Test that natural logarithm with invalid inputs raises appropriate errors.
    """
    # print("------------------------------------------------------")
    # print("Testing BigDecimal natural logarithm with invalid inputs...")

    # Test 1: ln of zero should raise an error
    var zero = BDec("0")
    var exception_caught: Bool
    try:
        _ = zero.ln()
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(exception_caught, "ln(0) should raise an error")
    # print("✓ ln(0) correctly raises an error")

    # Test 2: ln of negative number should raise an error
    var negative = BDec("-1")
    try:
        _ = negative.ln()
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "ln of negative number should raise an error"
    )
    # print("✓ ln of negative number correctly raises an error")


fn test_root_invalid_inputs() raises:
    """Test that root function with invalid inputs raises appropriate errors."""
    # print("------------------------------------------------------")
    # print("Testing BigDecimal root with invalid inputs...")

    # Test 1: 0th root should raise an error
    var a1 = BDec("16")
    var n1 = BDec("0")
    var exception_caught: Bool
    try:
        _ = a1.root(n1, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(exception_caught, "0th root should raise an error")
    # print("✓ 0th root correctly raises an error")

    # Test 2: Even root of negative number should raise an error
    var a2 = BDec("-16")
    var n2 = BDec("2")
    try:
        _ = a2.root(n2, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Even root of negative number should raise an error"
    )
    # print("✓ Even root of negative number correctly raises an error")

    # Test 3: Fractional root with even denominator of negative number should raise an error
    var a3 = BDec("-16")
    var n3 = BDec("2.5")  # 5/2, denominator is even
    try:
        _ = a3.root(n3, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught,
        (
            "Fractional root with even denominator of negative number should"
            " raise an error"
        ),
    )
    # print(
    #     "✓ Fractional root with even denominator of negative number correctly"
    #     " raises an error"
    # )


fn test_power_invalid_inputs() raises:
    """Test that power function with invalid inputs raises appropriate errors.
    """
    # print("------------------------------------------------------")
    # print("Testing BigDecimal power with invalid inputs...")

    # Test 1: 0^0 should raise an error (undefined)
    var base1 = BDec("0")
    var exp1 = BDec("0")
    var exception_caught: Bool
    try:
        _ = base1.power(exp1, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(exception_caught, "0^0 should raise an error")
    # print("✓ 0^0 correctly raises an error")

    # Test 2: 0^-1 should raise an error (division by zero)
    var base2 = BDec("0")
    var exp2 = BDec("-1")
    try:
        _ = base2.power(exp2, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "0 raised to a negative power should raise an error"
    )
    # print("✓ 0 raised to a negative power correctly raises an error")

    # Test 3: Negative number raised to a fractional power should raise an error
    var base3 = BDec("-2")
    var exp3 = BDec("0.5")
    try:
        _ = base3.power(exp3, precision=28)
        exception_caught = False
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught,
        "Negative number raised to a fractional power should raise an error",
    )
    # print(
    #     "✓ Fractional root with even denominator of negative number correctly"
    #     " raises an error"
    # )


fn test_sqrt_multi_precision() raises:
    """Test sqrt at various precisions against Python's decimal module.

    Exercises both perfect squares (whose natural digit count may exceed the
    requested precision) and irrationals at precisions 1, 2, 3, 5, 10, 28, 50.
    This catches the bug where exact results skip rounding and return more
    significant digits than requested.
    """
    var pydecimal = Python.import_module("decimal")

    # Inputs: perfect squares, decimal perfect squares, irrationals, sci notation
    var inputs: List[String] = [
        "0",
        "1",
        "4",
        "9",
        "25",
        "100",
        "10000",
        "90000",
        "0.25",
        "0.01",
        "2.25",
        "2",
        "3",
        "5",
        "10",
        "0.5",
        "1E+10",
        "1E-10",
        "1E+100",
        "1E-100",
    ]

    var precisions: List[Int] = [1, 2, 3, 5, 10, 28, 50]

    var count_wrong = 0
    for i in range(len(inputs)):
        for j in range(len(precisions)):
            var prec = precisions[j]
            pydecimal.getcontext().prec = prec
            var our_result = String(BDec(inputs[i]).sqrt(precision=prec))
            var py_result = String(pydecimal.Decimal(inputs[i]).sqrt())
            try:
                testing.assert_equal(
                    lhs=our_result,
                    rhs=py_result,
                    msg="sqrt(" + inputs[i] + ") at precision=" + String(prec),
                )
            except e:
                print(
                    "FAIL: sqrt("
                    + inputs[i]
                    + ") at precision="
                    + String(prec),
                    "\n  Expected (Python):",
                    py_result,
                    "\n  Got (DeciMojo):   ",
                    our_result,
                )
                count_wrong += 1

    # Restore default precision
    pydecimal.getcontext().prec = 28
    testing.assert_equal(
        count_wrong,
        0,
        "Some multi-precision sqrt test cases failed. See above for details.",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
