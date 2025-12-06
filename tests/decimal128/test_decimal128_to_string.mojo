"""
Test Decimal128 conversion methods: __str__
for different numerical cases.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
import testing
import time


fn test_str_conversion() raises:
    # print("------------------------------------------------------")
    # print("--- Testing String Conversion ---")

    # Test positive number
    var d1 = Decimal128("123.456")
    var s1 = String(d1)
    # print("String(123.456) =", s1)
    testing.assert_equal(s1, "123.456")

    # Test negative number
    var d2 = Decimal128("-789.012")
    var s2 = String(d2)
    # print("String(-789.012) =", s2)
    testing.assert_equal(s2, "-789.012")

    # Test zero
    var d3 = Decimal128(0)
    var s3 = String(d3)
    # print("String(0) =", s3)
    testing.assert_equal(s3, "0")

    # Test large number with precision
    var d4 = Decimal128("9876543210.0123456789")
    var s4 = String(d4)
    # print("String(9876543210.0123456789) =", s4)
    testing.assert_equal(s4, "9876543210.0123456789")

    # Test small number
    var d5 = Decimal128("0.0000000001")
    var s5 = String(d5)
    # print("String(0.0000000001) =", s5)
    testing.assert_equal(s5, "0.0000000001")


fn main() raises:
    # print("Starting Decimal128 conversion __str__ tests...")

    # test_str_conversion()

    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("\nAll tests completed!")
