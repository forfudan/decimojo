"""
Comprehensive tests for the `factorial()` and the `factorial_reciprocal()`
functions in the DeciMojo library.
Tests various cases including edge cases and error handling for factorials 
in the range 0 to 27, which is the maximum range supported by Decimal128.
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode
from decimojo.decimal128.special import factorial, factorial_reciprocal


fn test_basic_factorials() raises:
    """Test basic factorial calculations."""
    print("Testing basic factorial calculations...")

    # Test case 1: 0! = 1
    var result0 = factorial(0)
    testing.assert_equal(
        String(result0), "1", "0! should be 1, got " + String(result0)
    )

    # Test case 2: 1! = 1
    var result1 = factorial(1)
    testing.assert_equal(
        String(result1), "1", "1! should be 1, got " + String(result1)
    )

    # Test case 3: 2! = 2
    var result2 = factorial(2)
    testing.assert_equal(
        String(result2), "2", "2! should be 2, got " + String(result2)
    )

    # Test case 4: 3! = 6
    var result3 = factorial(3)
    testing.assert_equal(
        String(result3), "6", "3! should be 6, got " + String(result3)
    )

    # Test case 5: 4! = 24
    var result4 = factorial(4)
    testing.assert_equal(
        String(result4), "24", "4! should be 24, got " + String(result4)
    )

    # Test case 6: 5! = 120
    var result5 = factorial(5)
    testing.assert_equal(
        String(result5), "120", "5! should be 120, got " + String(result5)
    )

    print("✓ Basic factorial tests passed!")


fn test_medium_factorials() raises:
    """Test medium-sized factorial calculations."""
    print("Testing medium-sized factorial calculations...")

    # Test case 7: 6! = 720
    var result6 = factorial(6)
    testing.assert_equal(
        String(result6), "720", "6! should be 720, got " + String(result6)
    )

    # Test case 8: 7! = 5040
    var result7 = factorial(7)
    testing.assert_equal(
        String(result7), "5040", "7! should be 5040, got " + String(result7)
    )

    # Test case 9: 8! = 40320
    var result8 = factorial(8)
    testing.assert_equal(
        String(result8), "40320", "8! should be 40320, got " + String(result8)
    )

    # Test case 10: 9! = 362880
    var result9 = factorial(9)
    testing.assert_equal(
        String(result9),
        "362880",
        "9! should be 362880, got " + String(result9),
    )

    # Test case 11: 10! = 3628800
    var result10 = factorial(10)
    testing.assert_equal(
        String(result10),
        "3628800",
        "10! should be 3628800, got " + String(result10),
    )

    print("✓ Medium factorial tests passed!")


fn test_large_factorials() raises:
    """Test large factorial calculations."""
    print("Testing large factorial calculations...")

    # Test case 12: 12! = 479001600
    var result12 = factorial(12)
    testing.assert_equal(
        String(result12),
        "479001600",
        "12! should be 479001600, got " + String(result12),
    )

    # Test case 13: 15! = 1307674368000
    var result15 = factorial(15)
    testing.assert_equal(
        String(result15),
        "1307674368000",
        "15! should be 1307674368000, got " + String(result15),
    )

    # Test case 14: 20! = 2432902008176640000
    var result20 = factorial(20)
    testing.assert_equal(
        String(result20),
        "2432902008176640000",
        "20! should be 2432902008176640000, got " + String(result20),
    )

    # Test case 15: 25!
    var result25 = factorial(25)
    var expected25 = "15511210043330985984000000"
    testing.assert_equal(
        String(result25),
        expected25,
        "25! should be " + expected25 + ", got " + String(result25),
    )

    # Test maximum supported factorial: 27!
    var result27 = factorial(27)
    var expected27 = "10888869450418352160768000000"
    testing.assert_equal(
        String(result27),
        expected27,
        "27! should be " + expected27 + ", got " + String(result27),
    )

    print("✓ Large factorial tests passed!")


fn test_factorial_properties() raises:
    """Test mathematical properties of factorials."""
    print("Testing factorial mathematical properties...")

    # Test case: (n+1)! = (n+1) * n!
    # Only test up to 26 because 27 is our maximum supported value
    for n in range(0, 26):
        var n_fact = factorial(n)
        var n_plus_1_fact = factorial(n + 1)
        var calculated = n_fact * Decimal128(String(n + 1))
        testing.assert_equal(
            String(n_plus_1_fact),
            String(calculated),
            "Property (n+1)! = (n+1)*n! failed for n="
            + String(n)
            + "n+1="
            + String(n + 1),
        )

    print("✓ Factorial properties tests passed!")


fn test_factorial_edge_cases() raises:
    """Test edge cases for factorial function."""
    print("Testing factorial edge cases...")

    # Test case: Error for negative input
    var exception_caught = False
    try:
        var _f1 = factorial(-1)
        testing.assert_equal(
            True, False, "factorial() of negative should raise exception"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case: Error for input > 27
    exception_caught = False
    try:
        var _f28 = factorial(28)
        testing.assert_equal(
            True,
            False,
            "factorial(28) should raise exception (exceeds maximum)",
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    print("✓ Factorial edge case tests passed!")


fn test_factorial_of_zero() raises:
    """Special test for factorial of zero."""
    print("Testing special case: 0!...")

    # Test case: Verify 0! = 1 (mathematical definition)
    var result = factorial(0)
    testing.assert_equal(String(result), "1", "0! should equal 1")

    print("✓ Special case test for 0! passed!")


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


fn test_factorial_reciprocal() raises:
    """Test that factorial_reciprocal equals 1 divided by factorial."""
    print("Testing factorial_reciprocal function...")

    # Test for all values in the supported range (0-27)
    var all_equal = True
    for i in range(28):
        var a = Decimal128(1) / factorial(i)
        var b = factorial_reciprocal(i)

        var equal = a == b
        if not equal:
            all_equal = False
            print("Mismatch at " + String(i) + ":")
            print("  1/" + String(i) + "! = " + String(a))
            print("  reciprocal = " + String(b))

    testing.assert_true(
        all_equal,
        (
            "factorial_reciprocal(n) should equal Decimal128(1)/factorial(n)"
            " for all n"
        ),
    )

    print("✓ Factorial reciprocal tests passed!")


fn main() raises:
    print("=========================================")
    print("Running Factorial Function Tests (0-27)")
    print("=========================================")

    # run_test_with_error_handling(test_basic_factorials, "Basic factorials test")
    # run_test_with_error_handling(
    #     test_medium_factorials, "Medium factorials test"
    # )
    # run_test_with_error_handling(test_large_factorials, "Large factorials test")
    # run_test_with_error_handling(
    #     test_factorial_properties, "Factorial properties test"
    # )
    # run_test_with_error_handling(
    #     test_factorial_edge_cases, "Factorial edge cases test"
    # )
    # run_test_with_error_handling(
    #     test_factorial_of_zero, "Factorial of zero test"
    # )
    # run_test_with_error_handling(
    #     test_factorial_reciprocal, "Factorial reciprocal test"
    # )

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    print("All factorial function tests passed!")
