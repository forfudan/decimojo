"""
Tests for Decimal128 exp() and ln() functions.
Merged from test_decimal128_exp.mojo and test_decimal128_ln.mojo.
Most tests use startswith prefix matching for high-precision results.
"""

import testing
from decimojo.decimal128.decimal128 import Decimal128
from decimojo.rounding_mode import RoundingMode
from decimojo.decimal128.exponential import exp, ln


# ─── exp() tests ────────────────────────────────────────────────────────────


fn test_exp_values() raises:
    """Test e^x for basic, negative, fractional, and high-precision inputs."""
    # e^0 = 1 (exact)
    testing.assert_equal(String(exp(Decimal128("0"))), "1", "e^0 should be 1")

    # e^1 ≈ 2.71828...
    testing.assert_true(
        String(exp(Decimal128("1"))).startswith("2.71828182845904523536028"),
        "e^1 failed",
    )
    # e^2
    testing.assert_true(
        String(exp(Decimal128("2"))).startswith("7.38905609893065022723042"),
        "e^2 failed",
    )
    # e^3
    testing.assert_true(
        String(exp(Decimal128("3"))).startswith("20.0855369231876677409285"),
        "e^3 failed",
    )
    # e^5
    testing.assert_true(
        String(exp(Decimal128("5"))).startswith("148.413159102576603421115"),
        "e^5 failed",
    )
    # e^(-1)
    testing.assert_true(
        String(exp(Decimal128("-1"))).startswith("0.36787944117144232159552"),
        "e^(-1) failed",
    )
    # e^(-2)
    testing.assert_true(
        String(exp(Decimal128("-2"))).startswith("0.13533528323661269189399"),
        "e^(-2) failed",
    )
    # e^(-5)
    testing.assert_true(
        String(exp(Decimal128("-5"))).startswith("0.00673794699908546709663"),
        "e^(-5) failed",
    )
    # e^0.5
    testing.assert_true(
        String(exp(Decimal128("0.5"))).startswith("1.64872127070012814684865"),
        "e^0.5 failed",
    )
    # e^0.1
    testing.assert_true(
        String(exp(Decimal128("0.1"))).startswith("1.10517091807564762481170"),
        "e^0.1 failed",
    )
    # e^(-0.5)
    testing.assert_true(
        String(exp(Decimal128("-0.5"))).startswith("0.60653065971263342360379"),
        "e^(-0.5) failed",
    )
    # e^1.5
    testing.assert_true(
        String(exp(Decimal128("1.5"))).startswith("4.48168907033806482260205"),
        "e^1.5 failed",
    )
    # e^π
    testing.assert_true(
        String(
            exp(Decimal128("3.14159265358979323846264338327950288"))
        ).startswith("23.1406926327792690057290"),
        "e^pi failed",
    )
    # e^(~e)
    testing.assert_true(
        String(exp(Decimal128("2.71828"))).startswith(
            "15.1542345325567272110572"
        ),
        "e^(~e) failed",
    )


fn test_exp_identities() raises:
    """Test e^(a+b) = e^a * e^b and e^(-x) = 1/e^x."""
    # e^(a+b) = e^a * e^b
    var a = Decimal128("2")
    var b = Decimal128("3")
    var diff1 = abs(exp(a + b) - exp(a) * exp(b)) / exp(a + b)
    testing.assert_true(
        diff1 < Decimal128("0.0000001"),
        "e^(a+b) != e^a * e^b, rel diff: " + String(diff1),
    )

    # e^(-x) = 1/e^x
    var x = Decimal128("1.5")
    var diff2 = abs(exp(-x) - Decimal128("1") / exp(x)) / exp(-x)
    testing.assert_true(
        diff2 < Decimal128("0.0000001"),
        "e^(-x) != 1/e^x, rel diff: " + String(diff2),
    )

    # e^0 = 1 (identity)
    testing.assert_equal(String(exp(Decimal128("0"))), "1", "e^0 should be 1")


fn test_exp_extreme() raises:
    """Test exp with very small inputs and large inputs."""
    testing.assert_true(
        String(exp(Decimal128("0.0000001"))).startswith("1.0000001"),
        "e^0.0000001 failed",
    )
    testing.assert_true(
        String(exp(Decimal128("-0.0000001"))).startswith("0.9999999"),
        "e^(-0.0000001) failed",
    )
    testing.assert_true(
        exp(Decimal128("20")) > Decimal128("100000000"),
        "e^20 should be > 10^8",
    )
    # High precision input should produce high precision output
    var result = exp(Decimal128("1.23456789012345678901234567"))
    testing.assert_true(len(String(result)) > 15, "High precision exp failed")


# ─── ln() tests ─────────────────────────────────────────────────────────────


fn test_ln_values() raises:
    """Test ln(x) for basic, fractional, and precision inputs."""
    # ln(1) = 0 (exact)
    testing.assert_equal(String(ln(Decimal128(1))), "0", "ln(1) should be 0")

    # ln(e) ≈ 1
    testing.assert_true(
        String(Decimal128("2.718281828459045235360287471").ln()).startswith(
            "1.00000000000000000000"
        ),
        "ln(e) failed",
    )
    # ln(10)
    testing.assert_true(
        String(ln(Decimal128(10))).startswith("2.30258509299404568401799145"),
        "ln(10) failed",
    )
    # ln(0.1)
    testing.assert_true(
        String(ln(Decimal128("0.1"))).startswith(
            "-2.302585092994045684017991454"
        ),
        "ln(0.1) failed",
    )
    # ln(0.5)
    testing.assert_true(
        String(ln(Decimal128("0.5"))).startswith(
            "-0.693147180559945309417232121"
        ),
        "ln(0.5) failed",
    )
    # ln(2)
    testing.assert_true(
        String(ln(Decimal128(2))).startswith("0.693147180559945309417232121"),
        "ln(2) failed",
    )
    # ln(5)
    testing.assert_true(
        String(ln(Decimal128(5))).startswith("1.609437912434100374600759333"),
        "ln(5) failed",
    )


fn test_ln_identities() raises:
    """Test ln(a*b)=ln(a)+ln(b), ln(a/b)=ln(a)-ln(b), ln(e^x)=x."""
    var a = Decimal128(2)
    var b = Decimal128(3)

    # ln(a*b) = ln(a) + ln(b)
    testing.assert_true(
        abs(ln(a * b) - (ln(a) + ln(b))) < Decimal128("0.0000000001"),
        "ln(a*b) != ln(a)+ln(b)",
    )
    # ln(a/b) = ln(a) - ln(b)
    testing.assert_true(
        abs(ln(a / b) - (ln(a) - ln(b))) < Decimal128("0.0000000001"),
        "ln(a/b) != ln(a)-ln(b)",
    )
    # ln(e^x) = x
    var x = Decimal128(5)
    testing.assert_true(
        abs(ln(x.exp()) - x) < Decimal128("0.0000000001"),
        "ln(e^x) != x",
    )


fn test_ln_edge_cases() raises:
    """Test ln(0), ln(negative), and extreme values."""
    # ln(0) should raise
    var caught = False
    try:
        var _r = ln(Decimal128(0))
        testing.assert_true(False, "ln(0) should raise")
    except:
        caught = True
    testing.assert_true(caught, "ln(0) should raise exception")

    # ln(negative) should raise
    caught = False
    try:
        var _r = ln(Decimal128(-1))
        testing.assert_true(False, "ln(-1) should raise")
    except:
        caught = True
    testing.assert_true(caught, "ln(-1) should raise exception")

    # ln(very small)
    testing.assert_true(
        String(ln(Decimal128("0.000000000000000000000000001"))).startswith(
            "-62.16979751083923346848576927"
        ),
        "ln(very small) failed",
    )
    # ln(very large)
    testing.assert_true(
        String(ln(Decimal128("10000000000000000000000000000"))).startswith(
            "64.4723"
        ),
        "ln(very large) failed",
    )


fn test_ln_properties() raises:
    """Test ln monotonicity and sign properties."""
    # ln(x) > 0 for x > 1
    testing.assert_true(Decimal128(3).ln() > Decimal128(0), "ln(3) > 0")
    testing.assert_true(Decimal128(10).ln() > Decimal128(2), "ln(10) > 2")
    # ln(x) < 0 for 0 < x < 1
    testing.assert_true(Decimal128("0.1").ln() < Decimal128(0), "ln(0.1) < 0")
    testing.assert_true(Decimal128("0.9").ln() < Decimal128(0), "ln(0.9) < 0")

    # ln(1) = 0 revisited
    testing.assert_equal(String(ln(Decimal128(1))), "0", "ln(1) == 0")

    # ln(e) close to 1
    var e = Decimal128("2.718281828459045235360287471")
    testing.assert_true(
        abs(ln(e) - Decimal128(1)) < Decimal128("0.0000000001"),
        "ln(e) ≈ 1",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
