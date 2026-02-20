"""
Tests for root() and power() functions of the Decimal128 type.
Merged from test_decimal128_root.mojo and test_decimal128_power.mojo.
TOML-driven tests for exact-result cases; inline for startswith,
tolerance, exception, and mathematical property tests.
"""

import testing
import tomlmojo

from decimojo.prelude import Decimal128, Dec128, RoundingMode
from decimojo.decimal128.exponential import root, power
from decimojo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_root_power.toml"


# ─── TOML-driven tests ──────────────────────────────────────────────────────


fn test_root_exact() raises:
    """Exact nth-root results (9 cases via TOML)."""
    var doc = parse_file(data_path)
    var cases = load_test_cases(doc, "root_exact")
    for tc in cases:
        var result = root(Dec128(tc.a), atol(tc.b))
        testing.assert_equal(String(result), tc.expected, tc.description)


fn test_power_int() raises:
    """Power with integer exponents (5 cases via TOML)."""
    var doc = parse_file(data_path)
    var cases = load_test_cases(doc, "power_int")
    for tc in cases:
        var result = power(Dec128(tc.a), atol(tc.b))
        testing.assert_equal(String(result), tc.expected, tc.description)


fn test_power_decimal() raises:
    """Power with decimal exponents — exact results (4 cases via TOML)."""
    var doc = parse_file(data_path)
    var cases = load_test_cases(doc, "power_decimal")
    for tc in cases:
        var result = power(Dec128(tc.a), Dec128(tc.b))
        testing.assert_equal(String(result), tc.expected, tc.description)


# ─── root() inline tests ────────────────────────────────────────────────────


fn test_root_approximate() raises:
    """Non-exact roots (startswith checks)."""

    fn _check(a: String, n: Int, prefix: String, desc: String) raises:
        testing.assert_true(String(root(Dec128(a), n)).startswith(prefix), desc)

    _check("2", 2, "1.4142135623730950488", "√2")
    _check("10", 3, "2.154434690031883721", "∛10")
    _check("1.44", 2, "1.2", "√1.44")
    _check("0.5", 2, "0.7071067811865475", "√0.5")
    _check("10", 100, "1.02329299228075413096627517", "100th root of 10")


fn test_root_exceptions() raises:
    """Error conditions for root()."""
    # 0th root
    var caught = False
    try:
        var _r = root(Dec128(10), 0)
        testing.assert_true(False, "0th root should raise")
    except:
        caught = True
    testing.assert_true(caught, "0th root exception")

    # Negative root
    caught = False
    try:
        var _r = root(Dec128(10), -2)
        testing.assert_true(False, "negative root should raise")
    except:
        caught = True
    testing.assert_true(caught, "negative root exception")

    # Even root of negative number
    caught = False
    try:
        var _r = root(Dec128(-4), 2)
        testing.assert_true(False, "even root of negative should raise")
    except:
        caught = True
    testing.assert_true(caught, "even root of negative exception")


fn test_root_precision() raises:
    """High-precision root checks."""

    fn _check(a: String, n: Int, prefix: String, desc: String) raises:
        testing.assert_true(String(root(Dec128(a), n)).startswith(prefix), desc)

    _check("2", 2, "1.414213562373095048801688724", "√2 high precision")
    _check("2", 3, "1.25992104989487316476721060", "∛2 high precision")
    _check("5", 2, "2.236067977499789696", "√5 high precision")


fn test_root_identities() raises:
    """Mathematical identities for root()."""
    var tol = Dec128("0.0000000001")

    # (√x)^2 = x
    var x1 = Dec128(7)
    var sq = root(x1, 2)
    testing.assert_true(abs(sq * sq - x1) < tol, "(√7)² ≈ 7")

    # ∛(x³) = x
    var x2 = Dec128(3)
    var cubed = x2 * x2 * x2
    testing.assert_true(abs(root(cubed, 3) - x2) < tol, "∛(3³) ≈ 3")

    # √(a*b) = √a * √b
    var a = Dec128(4)
    var b = Dec128(9)
    testing.assert_true(
        abs(root(a * b, 2) - root(a, 2) * root(b, 2)) < tol,
        "√(4*9) = √4 * √9",
    )

    # x^(1/n) = nth root of x
    var x4 = Dec128(5)
    testing.assert_true(
        abs(power(x4, Dec128(1) / Dec128(3)) - root(x4, 3)) < tol,
        "5^(1/3) = ∛5",
    )


# ─── power() inline tests ───────────────────────────────────────────────────


fn test_power_approximate() raises:
    """Non-exact power results (startswith checks)."""
    testing.assert_true(
        String(power(Dec128(2), Dec128("1.5"))).startswith(
            "2.828427124746190097603377448"
        ),
        "2^1.5",
    )
    testing.assert_true(
        String(power(Dec128("2.5"), Dec128("0.5"))).startswith(
            "1.5811388300841896659994467722"
        ),
        "2.5^0.5",
    )


fn test_power_exceptions() raises:
    """Error conditions for power()."""
    # 0^(-2) should raise
    var caught = False
    try:
        var _r = power(Dec128(0), Dec128(-2))
        testing.assert_true(False, "0^-2 should raise")
    except:
        caught = True
    testing.assert_true(caught, "0^-2 exception")

    # (-2)^0.5 should raise
    caught = False
    try:
        var _r = power(Dec128(-2), Dec128("0.5"))
        testing.assert_true(False, "(-2)^0.5 should raise")
    except:
        caught = True
    testing.assert_true(caught, "(-2)^0.5 exception")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
