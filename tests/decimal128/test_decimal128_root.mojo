"""
Comprehensive tests for the root() function in the DeciMojo library.
Tests various cases including basic nth roots, mathematical identities,
and edge cases to ensure proper calculation of x^(1/n).
"""

import testing
from decimojo.prelude import dm, Decimal128, RoundingMode
from decimojo.decimal128.exponential import root


fn test_basic_root_calculations() raises:
    """Test basic root calculations for common values."""
    # print("Testing basic root calculations...")

    # Test case 1: Square root (n=2)
    var num1 = Decimal128(9)
    var result1 = root(num1, 2)
    testing.assert_equal(
        String(result1), "3", "√9 should be 3, got " + String(result1)
    )

    # Test case 2: Cube root (n=3)
    var num2 = Decimal128(8)
    var result2 = root(num2, 3)
    testing.assert_equal(
        String(result2), "2", "∛8 should be 2, got " + String(result2)
    )

    # Test case 3: Fourth root (n=4)
    var num3 = Decimal128(16)
    var result3 = root(num3, 4)
    testing.assert_equal(
        String(result3), "2", "∜16 should be 2, got " + String(result3)
    )

    # Test case 4: Square root of non-perfect square
    var num4 = Decimal128(2)
    var result4 = root(num4, 2)
    testing.assert_true(
        String(result4).startswith("1.4142135623730950488"),
        "√2 should be approximately 1.414..., got " + String(result4),
    )

    # Test case 5: Cube root of non-perfect cube
    var num5 = Decimal128(10)
    var result5 = root(num5, 3)
    testing.assert_true(
        String(result5).startswith("2.154434690031883721"),
        "∛10 should be approximately 2.154..., got " + String(result5),
    )

    # print("✓ Basic root calculations tests passed!")


fn test_fractional_inputs() raises:
    """Test root calculations with fractional inputs."""
    # print("Testing root calculations with fractional inputs...")

    # Test case 1: Square root of decimal
    var num1 = Decimal128("0.25")
    var result1 = root(num1, 2)
    testing.assert_equal(
        String(result1), "0.5", "√0.25 should be 0.5, got " + String(result1)
    )

    # Test case 2: Cube root of decimal
    var num2 = Decimal128("0.125")
    var result2 = root(num2, 3)
    testing.assert_equal(
        String(result2), "0.5", "∛0.125 should be 0.5, got " + String(result2)
    )

    # Test case 3: High precision decimal input
    var num3 = Decimal128("1.44")
    var result3 = root(num3, 2)
    testing.assert_true(
        String(result3).startswith("1.2"),
        "√1.44 should be 1.2, got " + String(result3),
    )

    # Test case 4: Decimal128 input with non-integer result
    var num4 = Decimal128("0.5")
    var result4 = root(num4, 2)
    testing.assert_true(
        String(result4).startswith("0.7071067811865475"),
        "√0.5 should be approximately 0.7071..., got " + String(result4),
    )

    # print("✓ Fractional input tests passed!")


fn test_edge_cases() raises:
    """Test edge cases for the root function."""
    # print("Testing root edge cases...")

    # Test case 1: Root of 0
    var zero = Decimal128(0)
    var result1 = root(zero, 2)
    testing.assert_equal(
        String(result1), "0", "√0 should be 0, got " + String(result1)
    )

    # Test case 2: Root of 1
    var one = Decimal128(1)
    var result2 = root(one, 100)  # Any root of 1 is 1
    testing.assert_equal(
        String(result2),
        "1",
        "100th root of 1 should be 1, got " + String(result2),
    )

    # Test case 3: 1st root of any number is the number itself
    var num3 = Decimal128("123.456")
    var result3 = root(num3, 1)
    testing.assert_equal(
        String(result3),
        "123.456",
        "1st root of 123.456 should be 123.456, got " + String(result3),
    )

    # Test case 4: Very large root of a number
    var num4 = Decimal128(10)
    var result4 = root(num4, 100)  # 100th root of 10
    testing.assert_true(
        String(result4).startswith("1.02329299228075413096627517"),
        "100th root of 10 should be approximately"
        " 1.02329299228075413096627517..., got "
        + String(result4),
    )

    # print("✓ Edge cases tests passed!")


fn test_error_conditions() raises:
    """Test error conditions for the root function."""
    # print("Testing root error conditions...")

    # Test case 1: 0th root (should raise error)
    var num1 = Decimal128(10)
    var exception_caught = False
    try:
        var _result = root(num1, 0)
        testing.assert_equal(
            True, False, "0th root should raise error but didn't"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 2: Negative root (should raise error)
    var num2 = Decimal128(10)
    exception_caught = False
    try:
        var _result = root(num2, -2)
        testing.assert_equal(
            True, False, "Negative root should raise error but didn't"
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 3: Negative number with even root (should raise error)
    var num3 = Decimal128(-4)
    exception_caught = False
    try:
        var _result = root(num3, 2)
        testing.assert_equal(
            True,
            False,
            "Even root of negative number should raise error but didn't",
        )
    except:
        exception_caught = True
    testing.assert_equal(exception_caught, True)

    # Test case 4: Negative number with odd root (should work)
    var num4 = Decimal128(-8)
    var result4 = root(num4, 3)
    testing.assert_equal(
        String(result4), "-2", "∛-8 should be -2, got " + String(result4)
    )

    # print("✓ Error conditions tests passed!")


fn test_precision() raises:
    """Test precision of root calculations."""
    # print("Testing precision of root calculations...")

    # Test case 1: High precision square root
    var num1 = Decimal128(2)
    var result1 = root(num1, 2)
    testing.assert_true(
        String(result1).startswith("1.414213562373095048801688724"),
        "√2 with high precision should be accurate to at least 25 digits",
    )

    # Test case 2: High precision cube root
    var num2 = Decimal128(2)
    var result2 = root(num2, 3)
    testing.assert_true(
        String(result2).startswith("1.25992104989487316476721060"),
        "∛2 with high precision should be accurate to at least 25 digits",
    )

    # Test case 3: Compare with known precise values
    var num3 = Decimal128(5)
    var result3 = root(num3, 2)
    testing.assert_true(
        String(result3).startswith("2.236067977499789696"),
        "√5 should match known value starting with 2.236067977499789696...",
    )

    # print("✓ Precision tests passed!")


fn test_mathematical_identities() raises:
    """Test mathematical identities involving roots."""
    # print("Testing mathematical identities involving roots...")

    # Test case 1: (√x)^2 = x
    var x1 = Decimal128(7)
    var sqrt_x1 = root(x1, 2)
    var squared_back = sqrt_x1 * sqrt_x1
    testing.assert_true(
        abs(squared_back - x1) < Decimal128("0.0000000001"),
        "(√x)^2 should equal x within tolerance",
    )

    # Test case 2: ∛(x^3) = x
    var x2 = Decimal128(3)
    var cubed = x2 * x2 * x2
    var root_back = root(cubed, 3)
    testing.assert_true(
        abs(root_back - x2) < Decimal128("0.0000000001"),
        "∛(x^3) should equal x within tolerance",
    )

    # Test case 3: √(a*b) = √a * √b
    var a = Decimal128(4)
    var b = Decimal128(9)
    var sqrt_product = root(a * b, 2)
    var product_sqrts = root(a, 2) * root(b, 2)
    testing.assert_true(
        abs(sqrt_product - product_sqrts) < Decimal128("0.0000000001"),
        "√(a*b) should equal √a * √b within tolerance",
    )

    # Test case 4: Consistency with power function: x^(1/n) = nth root of x
    var x4 = Decimal128(5)
    var n = 3  # Cube root
    var power_result = x4 ** (Decimal128(1) / Decimal128(n))
    var root_result = root(x4, n)
    testing.assert_true(
        abs(power_result - root_result) < Decimal128("0.0000000001"),
        "x^(1/n) should equal nth root of x within tolerance",
    )

    # print("✓ Mathematical identities tests passed!")


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
        raise e^


fn main() raises:
    # print("=========================================")
    # print("Running Root Function Tests")
    # print("=========================================")

    # run_test_with_error_handling(
    #     test_basic_root_calculations, "Basic root calculations test"
    # )
    # run_test_with_error_handling(
    #     test_fractional_inputs, "Fractional inputs test"
    # )
    # run_test_with_error_handling(test_edge_cases, "Edge cases test")
    # run_test_with_error_handling(test_error_conditions, "Error conditions test")
    # run_test_with_error_handling(test_precision, "Precision test")
    # run_test_with_error_handling(
    #     test_mathematical_identities, "Mathematical identities test"
    # )

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("All root function tests passed!")
