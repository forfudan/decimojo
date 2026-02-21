"""
Test BigInt2 sqrt and divmod operations: sqrt, isqrt, __divmod__
with positive, negative, mixed-sign, and consistency checks.
"""

import testing
from decimojo.bigint2.bigint2 import BigInt2


# ===----------------------------------------------------------------------=== #
# Test: sqrt / isqrt
# ===----------------------------------------------------------------------=== #


fn test_sqrt_perfect_squares() raises:
    """Test sqrt with perfect squares."""
    testing.assert_equal(String(BigInt2(0).sqrt()), "0")
    testing.assert_equal(String(BigInt2(1).sqrt()), "1")
    testing.assert_equal(String(BigInt2(4).sqrt()), "2")
    testing.assert_equal(String(BigInt2(9).sqrt()), "3")
    testing.assert_equal(String(BigInt2(16).sqrt()), "4")
    testing.assert_equal(String(BigInt2(25).sqrt()), "5")
    testing.assert_equal(String(BigInt2(100).sqrt()), "10")
    testing.assert_equal(String(BigInt2(10000).sqrt()), "100")
    testing.assert_equal(String(BigInt2(1000000).sqrt()), "1000")


fn test_sqrt_non_perfect() raises:
    """Test sqrt with non-perfect squares (floor)."""
    # sqrt(2) = 1
    testing.assert_equal(String(BigInt2(2).sqrt()), "1")

    # sqrt(3) = 1
    testing.assert_equal(String(BigInt2(3).sqrt()), "1")

    # sqrt(5) = 2
    testing.assert_equal(String(BigInt2(5).sqrt()), "2")

    # sqrt(8) = 2
    testing.assert_equal(String(BigInt2(8).sqrt()), "2")

    # sqrt(99) = 9
    testing.assert_equal(String(BigInt2(99).sqrt()), "9")

    # sqrt(101) = 10
    testing.assert_equal(String(BigInt2(101).sqrt()), "10")


fn test_sqrt_large() raises:
    """Test sqrt with large perfect squares."""
    # 10^20 → sqrt = 10^10 = 10000000000
    var x = BigInt2(10) ** 20
    testing.assert_equal(String(x.sqrt()), "10000000000")

    # (2^50)^2 = 2^100 → sqrt = 2^50 = 1125899906842624
    var big_sq = BigInt2(2) ** 100
    testing.assert_equal(String(big_sq.sqrt()), "1125899906842624")

    # Verify: sqrt * sqrt <= x < (sqrt+1)^2
    var n = BigInt2("99999999999999999999999999999")  # 29 digits
    var s = n.sqrt()
    var s_sq = s * s
    var s1_sq = (s + BigInt2(1)) * (s + BigInt2(1))
    testing.assert_true(s_sq <= n, "sqrt^2 <= n")
    testing.assert_true(s1_sq > n, "(sqrt+1)^2 > n")


fn test_sqrt_negative_raises() raises:
    """Test that sqrt of negative number raises."""
    var raised = False
    try:
        _ = BigInt2(-4).sqrt()
    except:
        raised = True
    testing.assert_true(raised, "sqrt(-4) should raise")


fn test_isqrt_equals_sqrt() raises:
    """Test that isqrt and sqrt produce the same result."""
    testing.assert_equal(
        String(BigInt2(49).isqrt()), String(BigInt2(49).sqrt())
    )
    testing.assert_equal(
        String(BigInt2(50).isqrt()), String(BigInt2(50).sqrt())
    )


# ===----------------------------------------------------------------------=== #
# Test: __divmod__
# ===----------------------------------------------------------------------=== #


fn test_divmod_basic() raises:
    """Test divmod with positive numbers."""
    var result = BigInt2(7).__divmod__(BigInt2(3))
    testing.assert_equal(String(result[0]), "2", "7 divmod 3: q")
    testing.assert_equal(String(result[1]), "1", "7 divmod 3: r")

    result = BigInt2(10).__divmod__(BigInt2(5))
    testing.assert_equal(String(result[0]), "2", "10 divmod 5: q")
    testing.assert_equal(String(result[1]), "0", "10 divmod 5: r")

    result = BigInt2(0).__divmod__(BigInt2(5))
    testing.assert_equal(String(result[0]), "0", "0 divmod 5: q")
    testing.assert_equal(String(result[1]), "0", "0 divmod 5: r")


fn test_divmod_mixed_sign() raises:
    """Test divmod with mixed signs (floor semantics)."""
    # Python: divmod(7, -3) = (-3, -2) since 7 = (-3)*(-3) + (-2)
    var result = BigInt2(7).__divmod__(BigInt2(-3))
    testing.assert_equal(String(result[0]), "-3", "7 divmod -3: q")
    testing.assert_equal(String(result[1]), "-2", "7 divmod -3: r")

    # Python: divmod(-7, 3) = (-3, 2) since -7 = (-3)*3 + 2
    result = BigInt2(-7).__divmod__(BigInt2(3))
    testing.assert_equal(String(result[0]), "-3", "-7 divmod 3: q")
    testing.assert_equal(String(result[1]), "2", "-7 divmod 3: r")

    # Python: divmod(-7, -3) = (2, -1) since -7 = 2*(-3) + (-1)
    result = BigInt2(-7).__divmod__(BigInt2(-3))
    testing.assert_equal(String(result[0]), "2", "-7 divmod -3: q")
    testing.assert_equal(String(result[1]), "-1", "-7 divmod -3: r")


fn test_divmod_consistency() raises:
    """Test that divmod(a, b) satisfies a = q * b + r."""

    fn _check_divmod(a_val: Int, b_val: Int) raises:
        var a = BigInt2(a_val)
        var b = BigInt2(b_val)
        var result = a.__divmod__(b)
        var q = result[0].copy()
        var r = result[1].copy()
        var reconstructed = q * b + r
        testing.assert_equal(
            String(reconstructed),
            String(a),
            "divmod consistency: " + String(a_val) + " divmod " + String(b_val),
        )

    _check_divmod(17, 5)
    _check_divmod(-17, 5)
    _check_divmod(17, -5)
    _check_divmod(-17, -5)
    _check_divmod(100, 7)
    _check_divmod(-100, 7)


fn test_divmod_by_zero_raises() raises:
    """Test divmod by zero raises."""
    var raised = False
    try:
        _ = BigInt2(42).__divmod__(BigInt2(0))
    except:
        raised = True
    testing.assert_true(raised, "divmod by zero should raise")


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
