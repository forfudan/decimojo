"""
Tests for factorial() and factorial_reciprocal() functions.
TOML-driven for exact factorial values; inline for properties,
edge cases, and reciprocal tests.
"""

import testing
import tomlmojo

from decimojo.prelude import Decimal128, Dec128, RoundingMode
from decimojo.decimal128.special import factorial, factorial_reciprocal
from decimojo.tests import parse_file, load_test_cases

comptime data_path = "tests/decimal128/test_data/decimal128_factorial.toml"


# ─── TOML-driven tests ──────────────────────────────────────────────────────


fn test_factorial_values() raises:
    """Exact factorial values for 0..27 (16 cases via TOML)."""
    var doc = parse_file(data_path)
    var cases = load_test_cases[unary=True](doc, "factorial")
    for tc in cases:
        var result = factorial(atol(tc.a))
        testing.assert_equal(String(result), tc.expected, tc.description)


# ─── Inline tests ───────────────────────────────────────────────────────────


fn test_factorial_properties() raises:
    """Mathematical property: (n+1)! = (n+1) * n! for n = 0..26."""
    for n in range(0, 26):
        var n_fact = factorial(n)
        var n_plus_1_fact = factorial(n + 1)
        var calculated = n_fact * Decimal128(String(n + 1))
        testing.assert_equal(
            String(n_plus_1_fact),
            String(calculated),
            "(n+1)! = (n+1)*n! failed for n=" + String(n),
        )


fn test_factorial_exceptions() raises:
    """Factorial of negative or > 27 should raise."""
    # Negative input
    var caught = False
    try:
        var _f = factorial(-1)
        testing.assert_true(False, "factorial(-1) should raise")
    except:
        caught = True
    testing.assert_true(caught, "factorial(-1) exception")

    # Beyond max
    caught = False
    try:
        var _f = factorial(28)
        testing.assert_true(False, "factorial(28) should raise")
    except:
        caught = True
    testing.assert_true(caught, "factorial(28) exception")


fn test_factorial_reciprocal() raises:
    """Factorial_reciprocal(n) should equal 1/factorial(n) for all n in 0..27.
    """
    var all_equal = True
    for i in range(28):
        var a = Decimal128(1) / factorial(i)
        var b = factorial_reciprocal(i)
        if a != b:
            all_equal = False
            print(
                "Mismatch at "
                + String(i)
                + ": 1/"
                + String(i)
                + "! = "
                + String(a)
                + ", reciprocal = "
                + String(b)
            )
    testing.assert_true(
        all_equal,
        "factorial_reciprocal(n) should equal 1/factorial(n) for all n",
    )


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
