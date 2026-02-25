"""
Tests for Decimal128 log(base) and log10() functions.
Merged from test_decimal128_log.mojo and test_decimal128_log10.mojo.
TOML-driven tests for exact-result cases; inline for startswith,
tolerance, exception, and mathematical property tests.
"""

import testing
import tomlmojo

from decimo.decimal128.decimal128 import Decimal128, Dec128
from decimo.rounding_mode import RoundingMode
from decimo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_logarithm.toml"


# ─── TOML-driven tests ──────────────────────────────────────────────────────


fn test_log_exact() raises:
    """5 exact log(value, base) results via TOML."""
    var doc = parse_file(data_path)
    var cases = load_test_cases(doc, "log_exact")
    for tc in cases:
        var result = Dec128(tc.a).log(Dec128(tc.b))
        testing.assert_equal(String(result), tc.expected, tc.description)


fn test_log10_exact() raises:
    """8 exact log10(value) results via TOML."""
    var doc = parse_file(data_path)
    var cases = load_test_cases[unary=True](doc, "log10_exact")
    for tc in cases:
        var result = Dec128(tc.a).log10()
        testing.assert_equal(String(result), tc.expected, tc.description)


# ─── log() inline tests ─────────────────────────────────────────────────────


fn test_log_rounded() raises:
    """Log results that are exact after rounding."""
    # log_3(27) ≈ 3, log_5(125) ≈ 3, log_0.1(0.001) ≈ 3, log_2(1024) ≈ 10
    testing.assert_equal(
        String(Decimal128(27).log(Decimal128(3)).round()),
        "3",
        "log_3(27) rounded",
    )
    testing.assert_equal(
        String(Decimal128(125).log(Decimal128(5)).round()),
        "3",
        "log_5(125) rounded",
    )
    testing.assert_equal(
        String(Decimal128("0.001").log(Decimal128("0.1")).round()),
        "3",
        "log_0.1(0.001) rounded",
    )
    testing.assert_equal(
        String(Decimal128(1024).log(Decimal128(2)).round()),
        "10",
        "log_2(1024) rounded",
    )

    # log_e(e) = 1 (also accessible via Decimal128.E())
    testing.assert_equal(
        String(Decimal128.E().log(Decimal128.E())),
        "1",
        "log_e(e) = 1",
    )

    # log_b(b) = 1
    testing.assert_equal(
        String(Decimal128("3.14159").log(Decimal128("3.14159"))),
        "1",
        "log_b(b) = 1",
    )


fn test_log_non_integer() raises:
    """Log results with non-integer values (startswith checks)."""
    testing.assert_true(
        String(Decimal128(10).log(Decimal128(2))).startswith(
            "3.321928094887362347"
        ),
        "log_2(10) failed",
    )
    testing.assert_true(
        String(Decimal128(10).log(Decimal128(3))).startswith(
            "2.0959032742893846"
        ),
        "log_3(10) failed",
    )
    testing.assert_true(
        String(Decimal128(2).log(Decimal128(10))).startswith(
            "0.301029995663981195"
        ),
        "log_10(2) failed",
    )
    testing.assert_true(
        String(Decimal128(10).log(Decimal128.E())).startswith(
            "2.302585092994045684"
        ),
        "log_e(10) failed",
    )
    testing.assert_true(
        String(Decimal128(19).log(Decimal128(7))).startswith("1.5131423106"),
        "log_7(19) failed",
    )
    testing.assert_true(
        String(Decimal128("0.125").log(Decimal128(3))).startswith(
            "-1.89278926"
        ),
        "log_3(0.125) failed",
    )
    testing.assert_true(
        String(Decimal128("1.5").log(Decimal128("2.5"))).startswith(
            "0.4425070493497599"
        ),
        "log_2.5(1.5) failed",
    )


fn test_log_exceptions() raises:
    """Invalid log inputs should raise exceptions."""
    # log of negative
    var caught = False
    try:
        var _r = Decimal128(-10).log(Decimal128(10))
        testing.assert_true(False, "log(negative) should raise")
    except:
        caught = True
    testing.assert_true(caught, "log(negative) exception")

    # log of zero
    caught = False
    try:
        var _r = Decimal128(0).log(Decimal128(10))
        testing.assert_true(False, "log(0) should raise")
    except:
        caught = True
    testing.assert_true(caught, "log(0) exception")

    # base 1
    caught = False
    try:
        var _r = Decimal128(10).log(Decimal128(1))
        testing.assert_true(False, "log base 1 should raise")
    except:
        caught = True
    testing.assert_true(caught, "log base 1 exception")

    # base 0
    caught = False
    try:
        var _r = Decimal128(10).log(Decimal128(0))
        testing.assert_true(False, "log base 0 should raise")
    except:
        caught = True
    testing.assert_true(caught, "log base 0 exception")

    # negative base
    caught = False
    try:
        var _r = Decimal128(10).log(Decimal128(-2))
        testing.assert_true(False, "log negative base should raise")
    except:
        caught = True
    testing.assert_true(caught, "log negative base exception")


fn test_log_properties() raises:
    """Mathematical properties: product, quotient, power, inverse, change of base.
    """
    var tol = Decimal128("0.000000000001")

    # log_a(x*y) = log_a(x) + log_a(y)
    var x = Decimal128(3)
    var y = Decimal128(4)
    var a = Decimal128(5)
    testing.assert_true(
        abs((x * y).log(a) - (x.log(a) + y.log(a))) < tol,
        "log_a(x*y) = log_a(x) + log_a(y)",
    )

    # log_a(x/y) = log_a(x) - log_a(y)
    testing.assert_true(
        abs(
            Decimal128(20).log(Decimal128(2))
            - Decimal128(5).log(Decimal128(2))
            - (Decimal128(20) / Decimal128(5)).log(Decimal128(2))
        )
        < tol,
        "log_a(x/y) = log_a(x) - log_a(y)",
    )

    # log_a(x^n) = n * log_a(x)
    testing.assert_true(
        abs(
            (Decimal128(3) ** 4).log(Decimal128(7))
            - Decimal128(4) * Decimal128(3).log(Decimal128(7))
        )
        < tol,
        "log_a(x^n) = n * log_a(x)",
    )

    # log_a(1/x) = -log_a(x)
    testing.assert_true(
        abs(
            (Decimal128(1) / Decimal128(7)).log(Decimal128(3))
            + Decimal128(7).log(Decimal128(3))
        )
        < tol,
        "log_a(1/x) = -log_a(x)",
    )

    # Change of base: log_a(b) = log_c(b) / log_c(a)
    var direct = Decimal128(7).log(Decimal128(3))
    var changed = Decimal128(7).log(Decimal128(10)) / Decimal128(3).log(
        Decimal128(10)
    )
    testing.assert_true(abs(direct - changed) < tol, "Change of base formula")

    # log(x,10) == log10(x)
    testing.assert_true(
        abs(Decimal128(7).log(Decimal128(10)) - Decimal128(7).log10()) < tol,
        "log(x,10) == log10(x)",
    )

    # log(x,e) == ln(x)
    testing.assert_true(
        abs(Decimal128(5).log(Decimal128.E()) - Decimal128(5).ln()) < tol,
        "log(x,e) == ln(x)",
    )


# ─── log10() inline tests ───────────────────────────────────────────────────


fn test_log10_non_powers() raises:
    """Tests log10 of non-powers of 10 (startswith checks)."""
    testing.assert_true(
        String(Decimal128(2).log10()).startswith("0.301029995663981"),
        "log10(2) failed",
    )
    testing.assert_true(
        String(Decimal128(5).log10()).startswith("0.698970004336018"),
        "log10(5) failed",
    )
    testing.assert_true(
        String(Decimal128(3).log10()).startswith("0.477121254719662"),
        "log10(3) failed",
    )
    testing.assert_true(
        String(Decimal128(7).log10()).startswith("0.845098040014256"),
        "log10(7) failed",
    )
    testing.assert_true(
        String(Decimal128("0.5").log10()).startswith("-0.301029995663981"),
        "log10(0.5) failed",
    )


fn test_log10_exceptions() raises:
    """Tests log10 of negative and zero should raise."""
    var caught = False
    try:
        var _r = Decimal128(-10).log10()
        testing.assert_true(False, "log10(negative) should raise")
    except:
        caught = True
    testing.assert_true(caught, "log10(negative) exception")

    caught = False
    try:
        var _r = Decimal128(0).log10()
        testing.assert_true(False, "log10(0) should raise")
    except:
        caught = True
    testing.assert_true(caught, "log10(0) exception")


fn test_log10_precision() raises:
    """Precision tests for log10."""
    testing.assert_true(
        String(Decimal128("3.14159265358979323846").log10()).startswith(
            "0.497149872694133"
        ),
        "log10(pi) precision",
    )
    testing.assert_true(
        String(Decimal128.E().log10()).startswith("0.434294481903251"),
        "log10(e) precision",
    )
    testing.assert_true(
        abs(Decimal128(2).log10() - Decimal128("0.301029995663981"))
        < Decimal128("0.000000000000001"),
        "log10(2) high precision",
    )
    testing.assert_true(
        abs(Decimal128("1.0000000001").log10()) < Decimal128("0.0000001"),
        "log10(~1) ≈ 0",
    )
    testing.assert_true(
        String(Decimal128("9.999999999").log10()).startswith("0.999999999"),
        "log10(~10) ≈ 1",
    )


fn test_log10_properties() raises:
    """Mathematical properties of log10."""
    var tol = Decimal128("0.000000000001")

    # log10(a*b) = log10(a) + log10(b)
    testing.assert_true(
        abs(
            (Decimal128(2) * Decimal128(5)).log10()
            - (Decimal128(2).log10() + Decimal128(5).log10())
        )
        < tol,
        "log10(a*b) = log10(a) + log10(b)",
    )

    # log10(a/b) = log10(a) - log10(b)
    testing.assert_true(
        abs(
            (Decimal128(8) / Decimal128(2)).log10()
            - (Decimal128(8).log10() - Decimal128(2).log10())
        )
        < tol,
        "log10(a/b) = log10(a) - log10(b)",
    )

    # log10(a^n) = n * log10(a)
    testing.assert_true(
        abs(
            (Decimal128(3) ** 4).log10() - Decimal128(4) * Decimal128(3).log10()
        )
        < tol,
        "log10(a^n) = n * log10(a)",
    )

    # log10(1/a) = -log10(a)
    testing.assert_true(
        abs((Decimal128(1) / Decimal128(7)).log10() + Decimal128(7).log10())
        < tol,
        "log10(1/a) = -log10(a)",
    )

    # log10(x) = ln(x) / ln(10)
    testing.assert_true(
        abs(Decimal128(7).log10() - Decimal128(7).ln() / Decimal128(10).ln())
        < tol,
        "log10(x) = ln(x)/ln(10)",
    )

    # log10(x) = log(x, 10)
    testing.assert_true(
        abs(Decimal128(5).log10() - Decimal128(5).log(Decimal128(10))) < tol,
        "log10(x) = log(x,10)",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
