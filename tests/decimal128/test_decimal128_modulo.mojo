"""
Tests for Decimal128 modulo (%) operations.
TOML-driven tests for basic, negative, and edge cases.
Inline tests for exception handling, mathematical relationships,
and consistency with floor division.
"""

import testing
import tomlmojo

from decimojo.prelude import dm, Decimal128, Dec128, RoundingMode
from decimojo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_modulo.toml"


fn _run_section(doc: tomlmojo.parser.TOMLDocument, section: String) raises:
    """Run modulo test cases from a TOML section."""
    var cases = load_test_cases(doc, section)
    for tc in cases:
        var result = Dec128(tc.a) % Dec128(tc.b)
        testing.assert_equal(String(result), tc.expected, tc.description)


fn test_modulo_basic() raises:
    """5 basic modulo cases with positive values."""
    var doc = parse_file(data_path)
    _run_section(doc, "modulo_basic")


fn test_modulo_negative() raises:
    """6 modulo cases with negative numbers."""
    var doc = parse_file(data_path)
    _run_section(doc, "modulo_negative")


fn test_modulo_edge() raises:
    """6 edge cases: mod by 1, zero dividend, small/large numbers."""
    var doc = parse_file(data_path)
    _run_section(doc, "modulo_edge")


fn test_modulo_exception() raises:
    """Modulo by zero should raise an error."""
    var exception_caught = False
    try:
        var _result = Decimal128(10) % Decimal128(0)
        testing.assert_true(False, "Modulo by zero should raise error")
    except:
        exception_caught = True
    testing.assert_true(exception_caught, "Modulo by zero should raise error")


fn test_mathematical_relationships() raises:
    """Mathematical properties of modulo."""
    # a = (a // b) * b + (a % b) for positive
    var a1 = Decimal128(10)
    var b1 = Decimal128(3)
    testing.assert_equal(
        String((a1 // b1) * b1 + (a1 % b1)),
        String(a1),
        "a should equal (a // b) * b + (a % b)",
    )

    # 0 <= (a % b) < b for positive b
    var a2 = Decimal128("10.5")
    var b2 = Decimal128("3.2")
    var mod2 = a2 % b2
    testing.assert_true(
        (mod2 >= Decimal128(0)) and (mod2 < b2),
        "For positive b, 0 <= (a % b) < b should hold",
    )

    # a = (a // b) * b + (a % b) with negative values
    var a3 = Decimal128(-10)
    var b3 = Decimal128(3)
    testing.assert_equal(
        String((a3 // b3) * b3 + (a3 % b3)),
        String(a3),
        "a = (a // b) * b + (a % b) with negatives",
    )

    # a % b for negative b
    var mod4 = Decimal128("10.5") % Decimal128("-3.2")
    testing.assert_true(
        mod4 == Decimal128("0.9"),
        "10.5 % -3.2 should equal 0.9, got " + String(mod4),
    )

    # (a % b) % b = a % b
    var mod_once = Decimal128(17) % Decimal128(5)
    var mod_twice = mod_once % Decimal128(5)
    testing.assert_equal(
        String(mod_once), String(mod_twice), "(a % b) % b should equal a % b"
    )


fn test_consistency_with_floor_division() raises:
    """Verify a % b equals a - (a // b) * b for various inputs."""

    fn _check(a_str: String, b_str: String) raises:
        var a = Decimal128(a_str)
        var b = Decimal128(b_str)
        testing.assert_equal(
            String(a % b),
            String(a - (a // b) * b),
            "a % b == a - (a // b) * b for (" + a_str + ", " + b_str + ")",
        )

    _check("10", "3")
    _check("-10", "3")
    _check("10.5", "2.5")
    _check("10", "-3")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
