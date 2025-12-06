"""
Test Decimal128 conversion methods: __int__
for different numerical cases.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
import testing
import time


fn test_int_conversion() raises:
    # print("------------------------------------------------------")
    # print("--- Testing Int Conversion ---")

    # Test positive integer
    var d1 = Decimal128(123)
    var i1 = Int(d1)
    # print("Int(123) =", i1)
    testing.assert_equal(i1, 123)

    # Test negative integer
    var d2 = Decimal128(-456)
    var i2 = Int(d2)
    # print("Int(-456) =", i2)
    testing.assert_equal(i2, -456)

    # Test zero
    var d3 = Decimal128(0)
    var i3 = Int(d3)
    # print("Int(0) =", i3)
    testing.assert_equal(i3, 0)

    # Test decimal truncation
    var d4 = Decimal128(789987, 3)
    var i4 = Int(d4)
    # print("Int(789.987) =", i4)
    testing.assert_equal(i4, 789)

    # Test negative decimal truncation
    var d5 = Decimal128(-123456, 3)
    var i5 = Int(d5)
    # print("Int(-123.456) =", i5)
    testing.assert_equal(i5, -123)

    # Test large number
    var d6 = Decimal128(9999999999)
    var i6 = Int(d6)
    # print("Int(9999999999) =", i6)
    testing.assert_equal(i6, 9999999999)


fn main() raises:
    # print("Starting Decimal128 conversion __int__ tests...")

    # test_int_conversion()

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("\nAll tests completed!")
