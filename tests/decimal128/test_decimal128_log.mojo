"""
Comprehensive tests for the log() function of the Decimal128 type.
Tests various scenarios to ensure proper calculation of logarithms with arbitrary bases.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode


fn test_basic_log() raises:
    """Test basic logarithm calculations with common bases."""
    print("Testing basic logarithm calculations...")

    # Test case 1: log_2(8) = 3
    var val1 = Decimal128(8)
    var base1 = Decimal128(2)
    var result1 = val1.log(base1)
    testing.assert_equal(
        String(result1), "3", "log_2(8) should be 3, got " + String(result1)
    )

    # Test case 2: log_3(27) = 3
    var val2 = Decimal128(27)
    var base2 = Decimal128(3)
    var result2 = val2.log(base2)
    testing.assert_equal(
        String(result2.round()),
        "3",
        "log_3(27) should be 3, got " + String(result2),
    )

    # Test case 3: log_5(125) = 3
    var val3 = Decimal128(125)
    var base3 = Decimal128(5)
    var result3 = val3.log(base3)
    testing.assert_equal(
        String(result3.round()),
        "3",
        "log_5(125) should be 3, got " + String(result3),
    )

    # Test case 4: log_10(1000) = 3
    var val4 = Decimal128(1000)
    var base4 = Decimal128(10)
    var result4 = val4.log(base4)
    testing.assert_equal(
        String(result4), "3", "log_10(1000) should be 3, got " + String(result4)
    )

    # Test case 5: log_e(e) = 1  (natural log of e)
    var val5 = Decimal128.E()
    var base5 = Decimal128.E()
    var result5 = val5.log(base5)
    testing.assert_equal(
        String(result5), "1", "log_e(e) should be 1, got " + String(result5)
    )

    print("✓ Basic logarithm calculations tests passed!")


fn test_non_integer_results() raises:
    """Test logarithm calculations that result in non-integer values."""
    print("Testing logarithm calculations with non-integer results...")

    # Test case 1: log_2(10)
    var val1 = Decimal128(10)
    var base1 = Decimal128(2)
    var result1 = val1.log(base1)
    testing.assert_true(
        String(result1).startswith("3.321928094887362347"),
        "log_2(10) should be approximately 3.32192809, got " + String(result1),
    )

    # Test case 2: log_3(10)
    var val2 = Decimal128(10)
    var base2 = Decimal128(3)
    var result2 = val2.log(base2)
    testing.assert_true(
        String(result2).startswith("2.0959032742893846"),
        "log_3(10) should be approximately 2.0959032742893846, got "
        + String(result2),
    )

    # Test case 3: log_10(2)
    var val3 = Decimal128(2)
    var base3 = Decimal128(10)
    var result3 = val3.log(base3)
    testing.assert_true(
        String(result3).startswith("0.301029995663981195"),
        "log_10(2) should be approximately 0.30102999, got " + String(result3),
    )

    # Test case 4: log_e(10)
    var val4 = Decimal128(10)
    var base4 = Decimal128.E()
    var result4 = val4.log(base4)
    testing.assert_true(
        String(result4).startswith("2.302585092994045684"),
        "log_e(10) should be approximately 2.30258509, got " + String(result4),
    )

    # Test case 5: log_7(19)
    var val5 = Decimal128(19)
    var base5 = Decimal128(7)
    var result5 = val5.log(base5)
    testing.assert_true(
        String(result5).startswith("1.5131423106"),
        "log_7(19) should be approximately 1.5131423106, got "
        + String(result5),
    )

    print("✓ Non-integer result logarithm tests passed!")


fn test_fractional_inputs() raises:
    """Test logarithm calculations with fractional inputs."""
    print("Testing logarithm calculations with fractional inputs...")

    # Test case 1: log_2(0.5) = -1
    var val1 = Decimal128("0.5")
    var base1 = Decimal128(2)
    var result1 = val1.log(base1)
    testing.assert_equal(
        String(result1), "-1", "log_2(0.5) should be -1, got " + String(result1)
    )

    # Test case 2: log_3(0.125)
    var val2 = Decimal128("0.125")
    var base2 = Decimal128(3)
    var result2 = val2.log(base2)
    testing.assert_true(
        String(result2).startswith("-1.89278926"),
        "log_3(0.125) should be approximately -1.89278926, got "
        + String(result2),
    )

    # Test case 3: log_0.5(2) = -1 (logarithm with fractional base)
    var val3 = Decimal128(2)
    var base3 = Decimal128("0.5")
    var result3 = val3.log(base3)
    testing.assert_equal(
        String(result3), "-1", "log_0.5(2) should be -1, got " + String(result3)
    )

    # Test case 4: log_0.1(0.001) = 3
    var val4 = Decimal128("0.001")
    var base4 = Decimal128("0.1")
    var result4 = val4.log(base4)
    testing.assert_equal(
        String(result4.round()),
        "3",
        "log_0.1(0.001) should be 3, got " + String(result4),
    )

    # Test case 5: log with fractional base and value
    var val5 = Decimal128("1.5")
    var base5 = Decimal128("2.5")
    var result5 = val5.log(base5)
    testing.assert_true(
        String(result5).startswith("0.4425070493497599"),
        "log_2.5(1.5) should be approximately 0.4425070493497599, got "
        + String(result5),
    )

    print("✓ Fractional input logarithm tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for the logarithm function."""
    print("Testing logarithm edge cases...")

    # Test case 1: log of a negative number (should raise error)
    var val1 = Decimal128(-10)
    var base1 = Decimal128(10)
    var exception_caught = False
    try:
        var _result1 = val1.log(base1)
        testing.assert_equal(
            True, False, "log of negative number should raise error"
        )
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log of negative number should raise error"
    )

    # Test case 2: log of zero (should raise error)
    var val2 = Decimal128(0)
    var base2 = Decimal128(10)
    exception_caught = False
    try:
        var _result2 = val2.log(base2)
        testing.assert_equal(True, False, "log of zero should raise error")
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log of zero should raise error"
    )

    # Test case 3: log with base 1 (should raise error)
    var val3 = Decimal128(10)
    var base3 = Decimal128(1)
    exception_caught = False
    try:
        var _result3 = val3.log(base3)
        testing.assert_equal(True, False, "log with base 1 should raise error")
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log with base 1 should raise error"
    )

    # Test case 4: log with base 0 (should raise error)
    var val4 = Decimal128(10)
    var base4 = Decimal128(0)
    exception_caught = False
    try:
        var _result4 = val4.log(base4)
        testing.assert_equal(True, False, "log with base 0 should raise error")
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log with base 0 should raise error"
    )

    # Test case 5: log with negative base (should raise error)
    var val5 = Decimal128(10)
    var base5 = Decimal128(-2)
    exception_caught = False
    try:
        var _result5 = val5.log(base5)
        testing.assert_equal(
            True, False, "log with negative base should raise error"
        )
    except:
        exception_caught = True
    testing.assert_equal(
        exception_caught, True, "log with negative base should raise error"
    )

    # Test case 6: log_b(1) = 0 for any base b
    var val6 = Decimal128(1)
    var base6 = Decimal128(7.5)  # Any base should give result 0
    var result6 = val6.log(base6)
    testing.assert_equal(
        String(result6),
        "0",
        "log_b(1) should be 0 for any base, got " + String(result6),
    )

    # Test case 7: log_b(b) = 1 for any base b
    var base7 = Decimal128("3.14159")
    var val7 = base7  # Value same as base should give result 1
    var result7 = val7.log(base7)
    testing.assert_equal(
        String(result7),
        "1",
        "log_b(b) should be 1 for any base, got " + String(result7),
    )

    print("✓ Edge cases tests passed!")


fn test_precision() raises:
    """Test precision of logarithm calculations."""
    print("Testing logarithm precision...")

    # Test case 1: High precision logarithm
    var val1 = Decimal128(
        "2.718281828459045235360287471352"
    )  # e to high precision
    var base1 = Decimal128(10)
    var result1 = val1.log(base1)
    testing.assert_true(
        String(result1).startswith("0.434294481903251827651"),
        "log_10(e) should have sufficient precision, got " + String(result1),
    )

    # Test case 2: log_2(1024) = 10 exactly
    var val2 = Decimal128(1024)
    var base2 = Decimal128(2)
    var result2 = val2.log(base2)
    testing.assert_equal(
        String(result2.round()),
        "10",
        "log_2(1024) should be exactly 10, got " + String(result2),
    )

    # Test case 3: Small difference in value
    var val3a = Decimal128("1.000001")
    var val3b = Decimal128("1.000002")
    var base3 = Decimal128(10)
    var result3a = val3a.log(base3)
    var result3b = val3b.log(base3)
    testing.assert_true(
        result3a < result3b,
        "log(1.000001) should be less than log(1.000002)",
    )

    # Test case 4: Verify log precision with a known value
    var val4 = Decimal128(2)
    var base4 = Decimal128.E()
    var result4 = val4.log(base4)
    testing.assert_true(
        String(result4).startswith("0.693147180559945309"),
        "log_e(2) should match known value 0.69314718..., got "
        + String(result4),
    )

    print("✓ Precision tests passed!")


fn test_mathematical_properties() raises:
    """Test mathematical properties of logarithms."""
    print("Testing mathematical properties of logarithms...")

    # Test case 1: log_a(x*y) = log_a(x) + log_a(y)
    var x1 = Decimal128(3)
    var y1 = Decimal128(4)
    var a1 = Decimal128(5)
    var log_product1 = (x1 * y1).log(a1)
    var sum_logs1 = x1.log(a1) + y1.log(a1)
    testing.assert_true(
        abs(log_product1 - sum_logs1) < Decimal128("0.000000000001"),
        "log_a(x*y) should equal log_a(x) + log_a(y)",
    )

    # Test case 2: log_a(x/y) = log_a(x) - log_a(y)
    var x2 = Decimal128(20)
    var y2 = Decimal128(5)
    var a2 = Decimal128(2)
    var log_quotient2 = (x2 / y2).log(a2)
    var diff_logs2 = x2.log(a2) - y2.log(a2)
    testing.assert_true(
        abs(log_quotient2 - diff_logs2) < Decimal128("0.000000000001"),
        "log_a(x/y) should equal log_a(x) - log_a(y)",
    )

    # Test case 3: log_a(x^n) = n * log_a(x)
    var x3 = Decimal128(3)
    var n3 = 4
    var a3 = Decimal128(7)
    var log_power3 = (x3**n3).log(a3)
    var n_times_log3 = Decimal128(n3) * x3.log(a3)
    testing.assert_true(
        abs(log_power3 - n_times_log3) < Decimal128("0.000000000001"),
        "log_a(x^n) should equal n * log_a(x)",
    )

    # Test case 4: log_a(1/x) = -log_a(x)
    var x4 = Decimal128(7)
    var a4 = Decimal128(3)
    var log_inverse4 = (Decimal128(1) / x4).log(a4)
    var neg_log4 = -x4.log(a4)
    testing.assert_true(
        abs(log_inverse4 - neg_log4) < Decimal128("0.000000000001"),
        "log_a(1/x) should equal -log_a(x)",
    )

    # Test case 5: log_a(b) = log_c(b) / log_c(a) (change of base formula)
    var b5 = Decimal128(7)
    var a5 = Decimal128(3)
    var c5 = Decimal128(10)  # Arbitrary third base
    var direct_log5 = b5.log(a5)
    var change_base5 = b5.log(c5) / a5.log(c5)
    testing.assert_true(
        abs(direct_log5 - change_base5) < Decimal128("0.000000000001"),
        "log_a(b) should equal log_c(b) / log_c(a)",
    )

    print("✓ Mathematical properties tests passed!")


fn test_consistency_with_other_logarithms() raises:
    """Test consistency between log(base) and other logarithm functions."""
    print("Testing consistency with other logarithm functions...")

    # Test case 1: log_10(x) == log10(x)
    var val1 = Decimal128(7)
    var log_base10_val1 = val1.log(Decimal128(10))
    var log10_val1 = val1.log10()
    testing.assert_true(
        abs(log_base10_val1 - log10_val1) < Decimal128("0.000000000001"),
        "log(x, 10) should equal log10(x)",
    )

    # Test case 2: log_e(x) == ln(x)
    var val2 = Decimal128(5)
    var log_base_e_val2 = val2.log(Decimal128.E())
    var ln_val2 = val2.ln()
    testing.assert_true(
        abs(log_base_e_val2 - ln_val2) < Decimal128("0.000000000001"),
        "log(x, e) should equal ln(x)",
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
    print("Running log() Function Tests")
    print("=========================================")

    # run_test_with_error_handling(test_basic_log, "Basic logarithm test")
    # run_test_with_error_handling(
    #     test_non_integer_results, "Non-integer results test"
    # )
    # run_test_with_error_handling(
    #     test_fractional_inputs, "Fractional inputs test"
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

    print("All log() function tests passed!")
