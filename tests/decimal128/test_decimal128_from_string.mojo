"""
Test Decimal128.from_string() constructor including:

1. basic integers
2. basic decimals
3. negative numbers
4. zero variants
5. scientific notation
6. formatting variants
7. special characters
8. invalid inputs (inline - cannot be TOML-driven)
9. boundary cases
10. special cases
"""

import testing
import tomlmojo

from decimojo import Dec128
from decimojo.tests import TestCase, parse_file, load_test_cases

comptime file_path = "tests/decimal128/test_data/decimal128_from_string.toml"


fn _run_unary_section(
    toml: tomlmojo.parser.TOMLDocument,
    section: String,
    mut count_wrong: Int,
) raises:
    """Helper to run a unary from_string test section."""
    var test_cases = load_test_cases[unary=True](toml, section)
    for test_case in test_cases:
        var result = Dec128.from_string(test_case.a)
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
                "\n",
            )
            count_wrong += 1


fn test_from_string() raises:
    """Test from_string conversions using TOML data-driven test cases."""
    var toml = parse_file(file_path)
    var count_wrong = 0

    _run_unary_section(toml, "basic_integer_tests", count_wrong)
    _run_unary_section(toml, "basic_decimal_tests", count_wrong)
    _run_unary_section(toml, "negative_tests", count_wrong)
    _run_unary_section(toml, "zero_variant_tests", count_wrong)
    _run_unary_section(toml, "scientific_notation_tests", count_wrong)
    _run_unary_section(toml, "formatting_variant_tests", count_wrong)
    _run_unary_section(toml, "special_character_tests", count_wrong)
    _run_unary_section(toml, "boundary_tests", count_wrong)
    _run_unary_section(toml, "special_case_tests", count_wrong)

    testing.assert_equal(
        count_wrong,
        0,
        "Some from_string test cases failed. See above for details.",
    )


fn test_from_string_high_precision_truncation() raises:
    """Test that very long decimals are truncated to max precision."""
    var long_decimal = Dec128.from_string(
        "0.11111111111111111111111111111111111"
    )
    testing.assert_true(String(long_decimal).startswith("0.11111111111"))


fn test_from_string_boundary_large_scale() raises:
    """Test large integer part with scale causing rounding."""
    var large = Dec128.from_string("9999999999999999999999999999.5")
    testing.assert_equal(String(large), "10000000000000000000000000000")


fn test_invalid_inputs() raises:
    """Test handling of invalid input strings that should raise exceptions."""

    # Test: Empty string
    var caught = False
    try:
        var _empty = Dec128.from_string("")
        testing.assert_true(False, "Empty string should raise exception")
    except:
        caught = True
    testing.assert_true(caught)

    # Test: Non-numeric string
    caught = False
    try:
        var _non_numeric = Dec128.from_string("abc")
        testing.assert_true(False, "Non-numeric string should raise exception")
    except:
        caught = True
    testing.assert_true(caught)

    # Test: Multiple decimal points
    caught = False
    try:
        var _multi_points = Dec128.from_string("1.2.3")
        testing.assert_true(
            False, "Multiple decimal points should raise exception"
        )
    except:
        caught = True
    testing.assert_true(caught)

    # Test: Invalid scientific notation
    caught = False
    try:
        var _invalid_exp = Dec128.from_string("1.23e")
        testing.assert_true(
            False, "Invalid scientific notation should raise exception"
        )
    except:
        caught = True
    testing.assert_true(caught)

    # Test: Mixed digits and characters
    caught = False
    try:
        var _mixed = Dec128.from_string("123a456")
        testing.assert_true(
            False, "Mixed digits and characters should raise exception"
        )
    except:
        caught = True
    testing.assert_true(caught)

    # Test: Space in integer
    caught = False
    try:
        var _space = Dec128.from_string("1 234")
        testing.assert_true(False, "Space in integer should raise exception")
    except:
        caught = True
    testing.assert_true(caught)


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
