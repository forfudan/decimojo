"""
Tests for Decimal128 round operations with different rounding modes.
TOML-driven tests for standard cases; inline for dynamic/consistency tests.
"""

import testing
import tomlmojo

from decimojo.prelude import Decimal128, Dec128, RoundingMode
from decimojo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_round.toml"


fn _run_round_section(
    doc: tomlmojo.parser.TOMLDocument,
    section: String,
    mode: RoundingMode,
) raises:
    """Run round test cases. Field b = number of decimal places."""
    var cases = load_test_cases(doc, section)
    for tc in cases:
        var result = Dec128(tc.a).round(Int(tc.b), mode)
        testing.assert_equal(String(result), tc.expected, tc.description)


fn _run_round_default_section(
    doc: tomlmojo.parser.TOMLDocument, section: String
) raises:
    """Run round test cases using builtin round() (banker's rounding)."""
    var cases = load_test_cases(doc, section)
    for tc in cases:
        var result = round(Dec128(tc.a), Int(tc.b))
        testing.assert_equal(String(result), tc.expected, tc.description)


fn test_round_default() raises:
    """6 cases using builtin round() with banker's rounding."""
    var doc = parse_file(data_path)
    _run_round_default_section(doc, "round_default")


fn test_round_down() raises:
    """3 cases rounding toward zero."""
    var doc = parse_file(data_path)
    _run_round_section(doc, "round_down", RoundingMode.down())


fn test_round_up() raises:
    """3 cases rounding away from zero."""
    var doc = parse_file(data_path)
    _run_round_section(doc, "round_up", RoundingMode.up())


fn test_round_half_up() raises:
    """2 cases rounding half up."""
    var doc = parse_file(data_path)
    _run_round_section(doc, "round_half_up", RoundingMode.half_up())


fn test_round_half_even() raises:
    """4 cases with banker's rounding via method."""
    var doc = parse_file(data_path)
    _run_round_section(doc, "round_half_even", RoundingMode.half_even())


fn test_round_small_value() raises:
    """Round a dynamically-constructed very small number."""
    var small_value = Decimal128("0." + "0" * 27 + "1")
    testing.assert_equal(
        String(round(small_value, 27)),
        "0." + "0" * 27,
        "Rounding tiny number to 27 places",
    )


fn test_rounding_consistency() raises:
    """Consistency across constructors and sequential rounding."""
    # Two ways to create 123.45
    var d1 = Decimal128("123.45")
    var d2 = Decimal128(123.45)
    testing.assert_equal(
        String(round(d1, 1))[:3],
        String(round(d2, 1))[:3],
        "Rounding consistency across different constructors",
    )

    # Repeated rounding should match direct rounding
    var start = Decimal128("123.456789")
    var round_twice = round(round(start, 4), 2)
    var direct = round(start, 2)
    testing.assert_equal(
        String(round_twice),
        String(direct),
        "Consistency with sequential rounding",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
