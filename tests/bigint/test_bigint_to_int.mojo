"""
Test BigInt conversion methods: to_int() and __int__
for different numerical cases.
"""

import testing

from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics as arithmetics


fn test_int_conversion() raises:
    # print("------------------------------------------------------")
    # print("--- Testing BigInt to Int Conversion ---")

    # Test positive integer
    var b1 = BigInt("123")
    var i1 = b1.to_int()
    # print("BigInt(123).to_int() =", i1)
    testing.assert_equal(i1, 123)

    # Test through __int__() operator
    var i1b = Int(b1)
    # print("Int(BigInt(123)) =", i1b)
    testing.assert_equal(i1b, 123)

    # Test negative integer
    var b2 = BigInt("-456")
    var i2 = b2.to_int()
    # print("BigInt(-456).to_int() =", i2)
    testing.assert_equal(i2, -456)

    # Test zero
    var b3 = BigInt("0")
    var i3 = b3.to_int()
    # print("BigInt(0).to_int() =", i3)
    testing.assert_equal(i3, 0)

    # Test large positive number within Int range
    var b4 = BigInt("9999999999")  # 10 billion is within Int64 range
    var i4 = b4.to_int()
    # print("BigInt(9999999999).to_int() =", i4)
    testing.assert_equal(i4, 9999999999)

    # Test large negative number within Int range
    var b5 = BigInt("-9999999999")
    var i5 = b5.to_int()
    # print("BigInt(-9999999999).to_int() =", i5)
    testing.assert_equal(i5, -9999999999)

    # Test Int.MAX edge case
    var b6 = BigInt(String(Int.MAX))
    var i6 = b6.to_int()
    # print("BigInt(Int.MAX).to_int() =", i6)
    testing.assert_equal(i6, Int.MAX)

    # Test Int.MIN edge case
    var b7 = BigInt(String(Int.MIN))
    var i7 = b7.to_int()
    # print("BigInt(Int.MIN).to_int() =", i7)
    testing.assert_equal(i7, Int.MIN)


fn test_error_cases() raises:
    # print("------------------------------------------------------")
    # print("--- Testing Error Cases ---")

    # Test number larger than Int.MAX
    var b1 = BigInt(String(Int.MAX)) + BigInt("1")
    # print("Testing conversion of:", b1, "(Int.MAX + 1)")
    var exception_caught = False
    try:
        var _b1 = b1.to_int()
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Expected error for value exceeding Int.MAX"
    )

    # Test number smaller than Int.MIN
    var b2 = BigInt(String(Int.MIN)) - BigInt("1")
    # print("Testing conversion of:", b2, "(Int.MIN - 1)")
    exception_caught = False
    try:
        var _b2 = b2.to_int()
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Expected error for value less than Int.MIN"
    )

    # Test very large number
    var b3 = BigInt("99999999999999999999999999999")  # Way beyond Int64 range
    # print("Testing conversion of very large number:", b3)
    exception_caught = False
    try:
        var _b3 = b3.to_int()
    except:
        exception_caught = True
    testing.assert_true(
        exception_caught, "Expected error for very large BigInt"
    )


fn main() raises:
    # print("Starting BigInt to Int conversion tests...")

    # test_int_conversion()
    # test_error_cases()
    testing.TestSuite.discover_tests[__functions_in_module()]().run()

    # print("\nAll tests completed!")
