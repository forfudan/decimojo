"""
Test Decimal conversion methods: __int__, __float__, and __str__
for different numerical cases.
"""

from decimojo.prelude import dm, Decimal, RoundingMode
import testing
import time


fn test_int_conversion() raises:
    print("------------------------------------------------------")
    print("--- Testing Int Conversion ---")

    # Test positive integer
    var d1 = Decimal("123")
    var i1 = Int(d1)
    print("Int(123) =", i1)
    testing.assert_equal(i1, 123)

    # Test negative integer
    var d2 = Decimal("-456")
    var i2 = Int(d2)
    print("Int(-456) =", i2)
    testing.assert_equal(i2, -456)

    # Test zero
    var d3 = Decimal("0")
    var i3 = Int(d3)
    print("Int(0) =", i3)
    testing.assert_equal(i3, 0)

    # Test decimal truncation
    var d4 = Decimal("789.987")
    var i4 = Int(d4)
    print("Int(789.987) =", i4)
    testing.assert_equal(i4, 789)

    # Test negative decimal truncation
    var d5 = Decimal("-123.456")
    var i5 = Int(d5)
    print("Int(-123.456) =", i5)
    testing.assert_equal(i5, -123)

    # Test large number
    var d6 = Decimal("9999999999")
    var i6 = Int(d6)
    print("Int(9999999999) =", i6)
    testing.assert_equal(i6, 9999999999)


fn test_float_conversion() raises:
    print("------------------------------------------------------")
    print("--- Testing Float64 Conversion ---")

    # Test positive number
    var d1 = Decimal("123.456")
    var f1 = Float64(d1)
    print("Float64(123.456) =", f1)
    testing.assert_almost_equal(f1, 123.456)

    # Test negative number
    var d2 = Decimal("-789.012")
    var f2 = Float64(d2)
    print("Float64(-789.012) =", f2)
    testing.assert_almost_equal(f2, -789.012)

    # Test zero
    var d3 = Decimal("0.0")
    var f3 = Float64(d3)
    print("Float64(0.0) =", f3)
    testing.assert_equal(f3, 0.0)

    # Test very small number
    var d4 = Decimal("0.0000000001")
    var f4 = Float64(d4)
    print("Float64(0.0000000001) =", f4)
    testing.assert_almost_equal(f4, 0.0000000001)

    # Test very large number
    var d5 = Decimal("1234567890123.4567")
    var f5 = Float64(d5)
    print("Float64(1234567890123.4567) =", f5)
    testing.assert_almost_equal(f5, 1234567890123.4567)


fn test_str_conversion() raises:
    print("------------------------------------------------------")
    print("--- Testing String Conversion ---")

    # Test positive number
    var d1 = Decimal("123.456")
    var s1 = String(d1)
    print("String(123.456) =", s1)
    testing.assert_equal(s1, "123.456")

    # Test negative number
    var d2 = Decimal("-789.012")
    var s2 = String(d2)
    print("String(-789.012) =", s2)
    testing.assert_equal(s2, "-789.012")

    # Test zero
    var d3 = Decimal("0")
    var s3 = String(d3)
    print("String(0) =", s3)
    testing.assert_equal(s3, "0")

    # Test large number with precision
    var d4 = Decimal("9876543210.0123456789")
    var s4 = String(d4)
    print("String(9876543210.0123456789) =", s4)
    testing.assert_equal(s4, "9876543210.0123456789")

    # Test small number
    var d5 = Decimal("0.0000000001")
    var s5 = String(d5)
    print("String(0.0000000001) =", s5)
    testing.assert_equal(s5, "0.0000000001")


fn main() raises:
    print("Starting Decimal conversion tests...")

    test_int_conversion()
    test_float_conversion()
    test_str_conversion()

    print("\nAll tests completed!")
