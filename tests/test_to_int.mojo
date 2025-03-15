"""
Test Decimal conversion methods: __int__
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


fn main() raises:
    print("Starting Decimal conversion __int__ tests...")

    test_int_conversion()

    print("\nAll tests completed!")
