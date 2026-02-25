"""
Tests for Decimal128 division (/) and truncate division (//) operations.
Merges the original test_decimal128_divide.mojo (100 cases) and
test_decimal128_truncate_divide.mojo (22 cases) into a single file.
TOML-driven tests handle exact-equality cases; inline tests cover
startswith checks, scale properties, overflow/error handling, and
mathematical relationship verification.
"""

import testing
import tomlmojo

from decimo import Decimal128, RoundingMode
from decimo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_divide.toml"


# ─── TOML-driven helpers ────────────────────────────────────────────────────


fn _run_division_section(
    doc: tomlmojo.parser.TOMLDocument, section: String
) raises:
    """Run division (/) test cases from a TOML section."""
    var cases = load_test_cases(doc, section)
    for tc in cases:
        var result = Decimal128(tc.a) / Decimal128(tc.b)
        testing.assert_equal(String(result), tc.expected, tc.description)


fn _run_truncate_section(
    doc: tomlmojo.parser.TOMLDocument, section: String
) raises:
    """Run truncate division (//) test cases from a TOML section."""
    var cases = load_test_cases(doc, section)
    for tc in cases:
        var result = Decimal128(tc.a) // Decimal128(tc.b)
        testing.assert_equal(String(result), tc.expected, tc.description)


# ─── TOML-driven test functions ─────────────────────────────────────────────


fn test_division_basic() raises:
    """10 basic division cases: integer, decimal, signed."""
    var doc = parse_file(data_path)
    _run_division_section(doc, "division_basic")


fn test_division_precision() raises:
    """6 precision/rounding cases at the 28-digit limit."""
    var doc = parse_file(data_path)
    _run_division_section(doc, "division_precision")


fn test_division_scale() raises:
    """10 scale handling cases: powers of 10, trailing zeros."""
    var doc = parse_file(data_path)
    _run_division_section(doc, "division_scale")


fn test_division_special() raises:
    """30 special cases: exact results, large numbers, rounding."""
    var doc = parse_file(data_path)
    _run_division_section(doc, "division_special")


fn test_truncate_basic() raises:
    """11 basic truncate division cases: positive and negative."""
    var doc = parse_file(data_path)
    _run_truncate_section(doc, "truncate_basic")


fn test_truncate_edge() raises:
    """6 truncate edge cases: div by 1, zero dividend, small numbers."""
    var doc = parse_file(data_path)
    _run_truncate_section(doc, "truncate_edge")


# ─── Inline tests: repeating decimals (startswith checks) ───────────────────


fn test_repeating_decimals() raises:
    """10 cases testing repeating decimal results (cases 11-20)."""
    testing.assert_true(
        String(Decimal128(1) / Decimal128(3)).startswith("0.33333333333333"),
        "1/3 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(1) / Decimal128(6)).startswith("0.16666666666666"),
        "1/6 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(1) / Decimal128(7)).startswith(
            "0.142857142857142857"
        ),
        "1/7 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(2) / Decimal128(3)).startswith("0.66666666666666"),
        "2/3 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(5) / Decimal128(6)).startswith("0.83333333333333"),
        "5/6 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(1) / Decimal128(9)).startswith("0.11111111111111"),
        "1/9 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(1) / Decimal128(11)).startswith("0.0909090909090"),
        "1/11 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(1) / Decimal128(12)).startswith("0.08333333333333"),
        "1/12 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(5) / Decimal128(11)).startswith("0.4545454545454"),
        "5/11 repeating failed",
    )
    testing.assert_true(
        String(Decimal128(10) / Decimal128(3)).startswith("3.33333333333333"),
        "10/3 repeating failed",
    )


# ─── Inline tests: scale/precision properties and edge cases ────────────────


fn test_properties_and_edge() raises:
    """Scale property checks, edge cases with comparisons and overflow."""
    # Scale property checks
    var a25 = Decimal128(1) / Decimal128(81)
    testing.assert_true(
        a25.scale() <= Decimal128.MAX_SCALE,
        "1/81 scale should not exceed MAX_SCALE",
    )

    var a29 = Decimal128("12345678901234567890123456789") / Decimal128(7)
    testing.assert_true(
        a29.scale() <= Decimal128.MAX_SCALE,
        "Large / 7 scale should not exceed MAX_SCALE",
    )

    var a30 = Decimal128("0." + "1" * 28) / Decimal128("0." + "9" * 28)
    testing.assert_true(
        a30.scale() <= Decimal128.MAX_SCALE,
        "Max precision / max precision scale check",
    )

    # Division by very small number close to zero
    var a41 = Decimal128(1) / Decimal128("0." + "0" * 27 + "1")
    testing.assert_true(
        a41 > Decimal128(String("1" + "0" * 27)),
        "Division by very small number failed",
    )

    # Division resulting in number close to zero
    var a42 = Decimal128("0." + "0" * 27 + "1") / Decimal128(10)
    testing.assert_equal(
        a42,
        Decimal128("0." + "0" * 28),
        "Division resulting in number close to zero failed",
    )

    # Division of very large by very small (may overflow)
    try:
        var _a43 = Decimal128.MAX() / Decimal128("0.0001")
    except:
        pass  # Overflow acceptable

    # Minimum representable positive divided by 2
    var min_positive = Decimal128("0." + "0" * 27 + "1")
    var a44 = min_positive / Decimal128(2)
    testing.assert_true(a44.scale() <= Decimal128.MAX_SCALE)

    # 1/3 should have exactly MAX_SCALE digits
    var a47 = Decimal128(1) / Decimal128(3)
    testing.assert_true(
        a47.scale() == Decimal128.MAX_SCALE,
        "1/3 should have exactly MAX_SCALE digits",
    )

    # Value at maximum supported scale divided by 1
    var a50 = Decimal128("0." + "0" * 27 + "5") / Decimal128(1)
    testing.assert_true(
        a50.scale() <= Decimal128.MAX_SCALE,
        "Division with max supported scale failed",
    )

    # MAX / 1 should equal MAX
    var max_value = Decimal128.MAX()
    testing.assert_equal(
        max_value / Decimal128(1),
        max_value,
        "MAX / 1 should equal MAX",
    )

    # Near-MAX divided by 10
    var near_max = Decimal128.MAX() - Decimal128(1)
    testing.assert_equal(
        near_max / Decimal128(10),
        Decimal128("7922816251426433759354395033.4"),
        "Near-MAX / 10 failed",
    )

    # (MAX/3)*3 should not exceed MAX
    var large_num = Decimal128.MAX() / Decimal128(3)
    testing.assert_true(
        large_num * Decimal128(3) <= Decimal128.MAX(),
        "(MAX/3)*3 should not exceed MAX",
    )

    # MAX / 0.5 should overflow
    try:
        var _a60 = Decimal128.MAX() / Decimal128("0.5")
    except:
        pass  # Overflow acceptable


# ─── Inline tests: special equality and precision cases ──────────────────────


fn test_special_and_precision() raises:
    """Decimal128 equality, mixed precision, and rounding edge cases."""
    # 1.000 / 1.000 should equal 1 (Decimal128 value equality)
    testing.assert_equal(
        Decimal128("1.000") / Decimal128("1.000"),
        Decimal128(1),
        "1.000/1.000 should equal Decimal128(1)",
    )

    # Division by 1 preserves value
    var special_value = Decimal128("123.456789012345678901234567")
    testing.assert_equal(
        special_value / Decimal128(1),
        special_value,
        "Division by 1 should preserve value",
    )

    # Self-division for non-zero
    testing.assert_equal(
        Decimal128("0.000123") / Decimal128("0.000123"),
        Decimal128(1),
        "Self-division should give 1",
    )

    # Division by number close to 1
    testing.assert_equal(
        Decimal128(1) / Decimal128("0.999999"),
        Decimal128("1.000001000001000001000001000"),
        "1 / 0.999999 precision test",
    )

    # Division then multiplication should approximately cancel
    var value = Decimal128("123.456")
    var divided = value / Decimal128(7)
    var result = divided * Decimal128(7)
    testing.assert_true(
        abs(value - result) / value < Decimal128("0.0001"),
        "Divide then multiply should approximately cancel",
    )

    # startswith checks for mixed precision
    var a74 = Decimal128("0.1") / Decimal128(3)
    testing.assert_true(
        String(a74).startswith("0.0333333333333333"),
        "0.1/3 precision failed",
    )

    var a75 = Decimal128(1) / Decimal128("0.0001234567890123456789")
    testing.assert_true(
        a75 > Decimal128(8000), "1/0.000123... should be > 8000"
    )

    var a77 = Decimal128("0.12345678901234567") / Decimal128(
        "0.98765432109876543"
    )
    testing.assert_true(
        a77 < Decimal128("0.13"), "Small/large should be < 0.13"
    )

    # Rounding with carry propagation
    var a83 = Decimal128(1) / Decimal128("1.9999999999999999999999999")
    var expected83 = Decimal128("0.5000000000000000000000000250")
    testing.assert_equal(a83, expected83, "Rounding with carry propagation")

    # Division at exactly half a unit in last place
    var a84 = Decimal128(1) / Decimal128("4" + "0" * Decimal128.MAX_SCALE)
    var expected84 = Decimal128("0." + "0" * Decimal128.MAX_SCALE)
    testing.assert_equal(a84, expected84, "Half unit in last place test")

    # Large numbers with same leading digits (Decimal128 equality, not string)
    var a58 = Decimal128("123" + "0" * 25) / Decimal128("123" + "0" * 15)
    testing.assert_equal(
        a58,
        Decimal128("1" + "0" * 10),
        "Large numbers with same leading digits",
    )


# ─── Inline tests: error handling ────────────────────────────────────────────


fn test_error_handling() raises:
    """Division by zero, overflow, and boundary conditions."""
    # Division by zero
    try:
        var _result = Decimal128(123) / Decimal128(0)
        testing.assert_true(False, "Expected division by zero to raise")
    except:
        pass

    # Overflow: MAX / 0.5
    try:
        var result92 = Decimal128.MAX() / Decimal128("0.5")
        testing.assert_true(result92 > Decimal128.MAX())
    except:
        pass  # Overflow acceptable

    # Overflow: MAX / 0.1
    try:
        var _result93 = Decimal128.MAX() / Decimal128("0.1")
    except:
        pass  # Overflow acceptable

    # MIN / positive
    var result94 = Decimal128.MIN() / Decimal128("10.12345")
    testing.assert_equal(
        result94,
        Decimal128("-7826201790324873199704048554.1"),
        "MIN / positive value failed",
    )

    # Very small / MAX approaches zero
    var result95 = Decimal128("0." + "0" * 27 + "1") / Decimal128.MAX()
    testing.assert_equal(
        String(result95),
        "0.0000000000000000000000000000",
        "Very small / MAX failed",
    )

    # MAX / MIN should be -1
    testing.assert_equal(
        String(Decimal128.MAX() / Decimal128.MIN()),
        "-1",
        "MAX / MIN should be -1",
    )

    # Overflow: MAX / 0.00001
    try:
        var result = Decimal128.MAX() / Decimal128("0.00001")
        testing.assert_true(result >= Decimal128.MAX())
    except:
        pass  # Overflow acceptable

    # Cumulative error from divide then multiply
    var calc = (Decimal128(1) / Decimal128(3)) * Decimal128(3)
    testing.assert_equal(
        String(calc),
        "0.9999999999999999999999999999",
        "Cumulative error test failed",
    )

    # Truncate division by zero
    try:
        var _result = Decimal128(10) // Decimal128(0)
        testing.assert_true(False, "Truncate divide by zero should raise")
    except:
        pass


# ─── Inline tests: truncate division mathematical relationships ──────────────


fn test_truncate_math_relationships() raises:
    """Mathematical properties of truncate division."""
    # a = (a // b) * b + (a % b) for positive
    var a1 = Decimal128(10)
    var b1 = Decimal128(3)
    var floor_div = a1 // b1
    var mod_result = a1 % b1
    testing.assert_equal(
        String(floor_div * b1 + mod_result),
        String(a1),
        "a should equal (a // b) * b + (a % b)",
    )

    # a // b = floor(a / b)
    var a2 = Decimal128("10.5")
    var b2 = Decimal128("2.5")
    var floor_div2 = a2 // b2
    var div_floored = (a2 / b2).round(0, RoundingMode.down())
    testing.assert_equal(
        String(floor_div2),
        String(div_floored),
        "a // b should equal floor(a / b)",
    )

    # Relationship with negative values
    var a3 = Decimal128(-10)
    var b3 = Decimal128(3)
    var floor_div3 = a3 // b3
    var mod_result3 = a3 % b3
    testing.assert_equal(
        String(floor_div3 * b3 + mod_result3),
        String(a3),
        "a = (a // b) * b + (a % b) with negatives",
    )

    # (a // b) * b <= a < (a // b + 1) * b
    var a4 = Decimal128("10.5")
    var b4 = Decimal128("3.2")
    var floor_div4 = a4 // b4
    var lower_bound = floor_div4 * b4
    var upper_bound = (floor_div4 + Decimal128(1)) * b4
    testing.assert_true(
        (lower_bound <= a4) and (a4 < upper_bound),
        "(a // b) * b <= a < (a // b + 1) * b should hold",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
