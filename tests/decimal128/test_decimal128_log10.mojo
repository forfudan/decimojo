"""
Comprehensive tests for the log10() function of the Decimal128 type.
Tests various scenarios to ensure proper calculation of base-10 logarithms.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_log10() raises:
    """Test basic logarithm base 10 calculations."""
    print("Testing basic log10 calculations...")

    # Test case 1: log10(1) = 0
    var val1 = Decimal128(1)
    var result1 = val1.log10()
    testing.assert_equal(
        String(result1), "0", "log10(1) should be 0, got " + String(result1)
    )

    # Test case 2: log10(10) = 1
    var val2 = Decimal128(10)
    var result2 = val2.log10()
    testing.assert_equal(
        String(result2), "1", "log10(10) should be 1, got " + String(result2)
    )

    # Test case 3: log10(100) = 2
    var val3 = Decimal128(100)
    var result3 = val3.log10()
    testing.assert_equal(
        String(result3), "2", "log10(100) should be 2, got " + String(result3)
    )

    # Test case 4: log10(1000) = 3
    var val4 = Decimal128(1000)
    var result4 = val4.log10()
    testing.assert_equal(
        String(result4), "3", "log10(1000) should be 3, got " + String(result4)
    )

    # Test case 5: log10(0.1) = -1
    var val5 = Decimal128("0.1")
    var result5 = val5.log10()
    testing.assert_equal(
        String(result5), "-1", "log10(0.1) should be -1, got " + String(result5)
    )

    # Test case 6: log10(0.01) = -2
    var val6 = Decimal128("0.01")
    var result6 = val6.log10()
    testing.assert_equal(
        String(result6),
        "-2",
        "log10(0.01) should be -2, got " + String(result6),
    )

    print("✓ Basic log10 calculations tests passed!")


fn test_non_powers_of_ten() raises:
    """Test logarithm base 10 of numbers that are not exact powers of 10."""
    print("Testing log10 of non-powers of 10...")

    # Test case 1: log10(2)
    var val1 = Decimal128(2)
    var result1 = val1.log10()
    testing.assert_true(
        String(result1).startswith("0.301029995663981"),
        "log10(2) should be approximately 0.301029995663981, got "
        + String(result1),
    )

    # Test case 2: log10(5)
    var val2 = Decimal128(5)
    var result2 = val2.log10()
    testing.assert_true(
        String(result2).startswith("0.698970004336018"),
        "log10(5) should be approximately 0.698970004336018, got "
        + String(result2),
    )

    # Test case 3: log10(3)
    var val3 = Decimal128(3)
    var result3 = val3.log10()
    testing.assert_true(
        String(result3).startswith("0.477121254719662"),
        "log10(3) should be approximately 0.477121254719662, got "
        + String(result3),
    )

    # Test case 4: log10(7)
    var val4 = Decimal128(7)
    var result4 = val4.log10()
    testing.assert_true(
        String(result4).startswith("0.845098040014256"),
        "log10(7) should be approximately 0.845098040014256, got "
        + String(result4),
    )

    # Test case 5: log10(0.5)
    var val5 = Decimal128("0.5")
    var result5 = val5.log10()
    testing.assert_true(
        String(result5).startswith("-0.301029995663981"),
        "log10(0.5) should be approximately -0.301029995663981, got "
        + String(result5),
    )

    print("✓ Non-powers of 10 log10 calculations tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for logarithm base 10."""
    print("Testing log10 edge cases...")

    # Test case 1: log10 of a negative number (should raise error)
    var val1 = Decimal128(-10)
    var exception_caught = False
    try:
        var _result1 = val1.log10()
        testing.assert_equal(
            True, False, "log10 of negative number should raise error"
        )
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log10 of negative number should raise error"
    )

    # Test case 2: log10 of zero (should raise error)
    var val2 = Decimal128(0)
    exception_caught = False
    try:
        var _result2 = val2.log10()
        testing.assert_equal(True, False, "log10 of zero should raise error")
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log10 of zero should raise error"
    )

    # Test case 3: log10 of value very close to 1
    var val3 = Decimal128("1.0000000001")
    var result3 = val3.log10()
    testing.assert_true(
        abs(result3) < Decimal128("0.0000001"),
        "log10 of value very close to 1 should be very close to 0",
    )

    # Test case 4: log10 of a very large number
    var val4 = Decimal128("1" + "0" * 20)  # 10^20
    var result4 = val4.log10()
    testing.assert_equal(
        String(result4),
        "20",
        "log10(10^20) should be 20, got " + String(result4),
    )

    # Test case 5: log10 of a very small number
    var val5 = Decimal128("0." + "0" * 19 + "1")  # 10^-20
    var result5 = val5.log10()
    testing.assert_equal(
        String(result5),
        "-20",
        "log10(10^-20) should be -20, got " + String(result5),
    )

    print("✓ Edge cases tests passed!")


fn test_precision() raises:
    """Test precision of logarithm base 10 calculations."""
    print("Testing log10 precision...")

    # Test case 1: High precision decimal
    var val1 = Decimal128("3.14159265358979323846")
    var result1 = val1.log10()
    testing.assert_true(
        String(result1).startswith("0.497149872694133"),
        "log10(π) should have sufficient precision",
    )

    # Test case 2: Special value - e
    var val2 = Decimal128.E()
    var result2 = val2.log10()
    testing.assert_true(
        String(result2).startswith("0.434294481903251"),
        "log10(e) should be approximately 0.434294481903251, got "
        + String(result2),
    )

    # Test case 3: Check against known value
    var val3 = Decimal128(2)
    var result3 = val3.log10()
    testing.assert_true(
        abs(result3 - Decimal128("0.301029995663981"))
        < Decimal128("0.000000000000001"),
        "log10(2) should match high precision value",
    )

    # Test case 4: Check precision with a number close to a power of 10
    var val4 = Decimal128("9.999999999")
    var result4 = val4.log10()
    testing.assert_true(
        String(result4).startswith("0.999999999"),
        "log10(9.999999999) should be precise, got " + String(result4),
    )

    print("✓ Precision tests passed!")


fn test_mathematical_properties() raises:
    """Test mathematical properties of logarithm base 10."""
    print("Testing mathematical properties of log10...")

    # Test case 1: log10(a*b) = log10(a) + log10(b)
    var a1 = Decimal128(2)
    var b1 = Decimal128(5)
    var product1 = a1 * b1
    var log_product1 = product1.log10()
    var sum_logs1 = a1.log10() + b1.log10()
    testing.assert_true(
        abs(log_product1 - sum_logs1) < Decimal128("0.000000000001"),
        "log10(a*b) should equal log10(a) + log10(b)",
    )

    # Test case 2: log10(a/b) = log10(a) - log10(b)
    var a2 = Decimal128(8)
    var b2 = Decimal128(2)
    var quotient2 = a2 / b2
    var log_quotient2 = quotient2.log10()
    var diff_logs2 = a2.log10() - b2.log10()
    testing.assert_true(
        abs(log_quotient2 - diff_logs2) < Decimal128("0.000000000001"),
        "log10(a/b) should equal log10(a) - log10(b)",
    )

    # Test case 3: log10(a^n) = n * log10(a)
    var a3 = Decimal128(3)
    var n3 = 4
    var power3 = a3**n3
    var log_power3 = power3.log10()
    var n_times_log3 = Decimal128(n3) * a3.log10()
    testing.assert_true(
        abs(log_power3 - n_times_log3) < Decimal128("0.000000000001"),
        "log10(a^n) should equal n * log10(a)",
    )

    # Test case 4: log10(1/a) = -log10(a)
    var a4 = Decimal128(7)
    var inverse4 = Decimal128(1) / a4
    var log_inverse4 = inverse4.log10()
    var neg_log4 = -a4.log10()
    testing.assert_true(
        abs(log_inverse4 - neg_log4) < Decimal128("0.000000000001"),
        "log10(1/a) should equal -log10(a)",
    )

    print("✓ Mathematical properties tests passed!")


fn test_consistency_with_other_logarithms() raises:
    """Test consistency between log10 and other logarithm functions."""
    print("Testing consistency with other logarithm functions...")

    # Test case 1: log10(x) = ln(x) / ln(10)
    var val1 = Decimal128(7)
    var log10_val1 = val1.log10()
    var ln_val1 = val1.ln()
    var ln_10 = Decimal128(10).ln()
    var ln_ratio1 = ln_val1 / ln_10
    testing.assert_true(
        abs(log10_val1 - ln_ratio1) < Decimal128("0.000000000001"),
        "log10(x) should equal ln(x) / ln(10)",
    )

    # Test case 2: log10(x) = log(x, 10) [using base 10 in generic log function]
    var val2 = Decimal128(5)
    var log10_val2 = val2.log10()
    var log_base10_val2 = val2.log(Decimal128(10))
    testing.assert_true(
        abs(log10_val2 - log_base10_val2) < Decimal128("0.000000000001"),
        "log10(x) should equal log(x, 10)",
    )

    print("✓ Consistency with other logarithms tests passed!")


fn run_test_with_error_handling(
    test_fn: fn () raises -> None, test_name: String
) raises:
    """Helper function to run a test function with error handling and reporting.
    """
    try:
        print("\n" + "=" * 50)
        print("RUNNING: " + test_name)
        print("=" * 50)
        test_fn()
        print("\n✓ " + test_name + " passed\n")
    except e:
        print("\n✗ " + test_name + " FAILED!")
        print("Error message: " + String(e))
        raise e


fn main() raises:
    print("=========================================")
    print("Running log10() Function Tests")
    print("=========================================")

    # run_test_with_error_handling(
    #     test_basic_log10, "Basic log10 calculations test"
    # )
    # run_test_with_error_handling(
    #     test_non_powers_of_ten, "Non-powers of 10 test"
    # )
    # run_test_with_error_handling(test_edge_cases, "Edge cases test")
    # run_test_with_error_handling(test_precision, "Precision test")
    # run_test_with_error_handling(
    #     test_mathematical_properties, "Mathematical properties test"
    # )
    # run_test_with_error_handling(
    #     test_consistency_with_other_logarithms,
    #     "Consistency with other logarithms test",
    # )

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    print("All log10() function tests passed!")
