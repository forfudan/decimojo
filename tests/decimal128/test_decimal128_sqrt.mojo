"""
Tests for the sqrt() function of the Decimal128 type.
Migrated from verbose inline format; TOML for exact-result cases,
inline for startswith, tolerance, identity, and exception tests.
"""

import testing
import tomlmojo

from decimojo.decimal128.decimal128 import Decimal128, Dec128
from decimojo.rounding_mode import RoundingMode
from decimojo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_sqrt.toml"


# ─── helpers ─────────────────────────────────────────────────────────────────


fn _run_sqrt_section(doc: tomlmojo.parser.TOMLDocument, section: String) raises:
    var cases = load_test_cases[unary=True](doc, section)
    for tc in cases:
        var result = Dec128(tc.a).sqrt()
        testing.assert_equal(String(result), tc.expected, tc.description)


# ─── TOML-driven tests ──────────────────────────────────────────────────────


fn test_sqrt_perfect() raises:
    """Perfect square inputs (12 cases via TOML)."""
    var doc = parse_file(data_path)
    _run_sqrt_section(doc, "sqrt_perfect")


fn test_sqrt_decimal() raises:
    """Decimal inputs with exact square roots (7 cases via TOML)."""
    var doc = parse_file(data_path)
    _run_sqrt_section(doc, "sqrt_decimal")


fn test_sqrt_edge_exact() raises:
    """Edge cases with exact results (via TOML): sqrt(0)=0, sqrt(1)=1."""
    var doc = parse_file(data_path)
    _run_sqrt_section(doc, "sqrt_edge")


# ─── Inline tests ───────────────────────────────────────────────────────────


fn test_sqrt_non_perfect() raises:
    """Non-perfect squares (startswith checks)."""

    fn _check(input: String, prefix: String, desc: String) raises:
        testing.assert_true(
            String(Dec128(input).sqrt()).startswith(prefix), desc
        )

    _check("2", "1.414213562373095048801688724", "sqrt(2)")
    _check("3", "1.73205080756887729352744634", "sqrt(3)")
    _check("5", "2.23606797749978969640917366", "sqrt(5)")
    _check("10", "3.162277660168379331998893544", "sqrt(10)")
    _check("50", "7.071067811865475244008443621", "sqrt(50)")
    _check("99", "9.949874371066199547344798210", "sqrt(99)")
    _check("999", "31.6069612585582165452042139", "sqrt(999)")


fn test_sqrt_edge_special() raises:
    """Edge cases needing special constructors or exceptions."""
    # sqrt(1e-28) = 1e-14
    var very_small = Decimal128(1, 28)
    testing.assert_equal(
        String(very_small.sqrt()),
        "0.00000000000001",
        "sqrt(1e-28) = 1e-14",
    )

    # sqrt(10^27) — startswith check
    var very_large = Decimal128.from_uint128(
        decimojo.decimal128.utility.power_of_10[DType.uint128](27)
    )
    testing.assert_true(
        String(very_large.sqrt()).startswith("31622776601683.79331998893544"),
        "sqrt(10^27)",
    )

    # sqrt(-1) should raise
    var caught = False
    try:
        var _r = Decimal128(-1).sqrt()
        testing.assert_true(False, "sqrt(-1) should raise")
    except:
        caught = True
    testing.assert_true(caught, "sqrt(-1) exception")


fn test_sqrt_precision() raises:
    """Precision tests (startswith checks)."""

    fn _check(input: String, prefix: String, desc: String) raises:
        testing.assert_true(
            String(Dec128(input).sqrt()).startswith(prefix), desc
        )

    _check("2", "1.414213562373095048801688724", "sqrt(2) precision")

    # High-precision representation of 2
    var precise_two = Decimal128.from_uint128(
        UInt128(20000000000000000000000000), 25
    )
    testing.assert_true(
        String(precise_two.sqrt()).startswith("1.414213562373095048801688724"),
        "sqrt(high-precision 2)",
    )

    _check(
        "1894128.128951235",
        "1376.27327553478091940498131",
        "sqrt(1894128.128951235)",
    )


fn test_sqrt_identities() raises:
    """Mathematical identities: sqrt(x)^2 ≈ x and sqrt(x*y) ≈ sqrt(x)*sqrt(y).
    """

    fn _check_squared(s: String) raises:
        var x = Dec128(s)
        testing.assert_true(
            round(x.sqrt() * x.sqrt(), 10) == round(x, 10),
            "sqrt(" + s + ")² ≈ " + s,
        )

    _check_squared("2")
    _check_squared("3")
    _check_squared("5")
    _check_squared("7")
    _check_squared("10")
    _check_squared("0.5")
    _check_squared("0.25")
    _check_squared("1.44")

    fn _check_product(xs: String, ys: String) raises:
        var x = Dec128(xs)
        var y = Dec128(ys)
        testing.assert_true(
            round((x * y).sqrt(), 10) == round(x.sqrt() * y.sqrt(), 10),
            "sqrt(" + xs + "*" + ys + ") = sqrt(" + xs + ")*sqrt(" + ys + ")",
        )

    _check_product("4", "9")
    _check_product("16", "25")
    _check_product("2", "8")


fn test_sqrt_convergence() raises:
    """Convergence: sqrt(x)^2 ≈ x within relative tolerance."""

    var tol = Dec128("0.00001")

    fn _check_rel(s: String, tol: Dec128) raises:
        var x = Dec128(s)
        var sq = x.sqrt()
        var diff = sq * sq - x
        diff = -diff if diff.is_negative() else diff
        var rel = diff / x
        testing.assert_true(
            rel < tol,
            "sqrt(" + s + ")² convergence",
        )

    _check_rel("0.0001", tol)
    _check_rel("0.01", tol)
    _check_rel("1", tol)
    _check_rel("10", tol)
    _check_rel("10000", tol)
    _check_rel("10000000000", tol)
    _check_rel("3.999999999", tol)
    _check_rel("4.000000001", tol)

    # Near-boundary startswith checks
    testing.assert_true(
        String(Dec128("0.999999999").sqrt()).startswith(
            "0.99999999949999999987"
        ),
        "sqrt(0.999999999)",
    )
    testing.assert_true(
        String(Dec128("1.000000001").sqrt()).startswith(
            "1.000000000499999999875"
        ),
        "sqrt(1.000000001)",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
