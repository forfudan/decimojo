# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements logic operations for the Decimal type
#
# ===----------------------------------------------------------------------=== #
#
# List of functions in this module:
#
# compare(x: Decimal, y: Decimal) -> Int8: Compares two Decimals
# compare_absolute(x: Decimal, y: Decimal) -> Int8: Compares absolute values of two Decimals
# greater(a: Decimal, b: Decimal) -> Bool: Returns True if a > b
# less(a: Decimal, b: Decimal) -> Bool: Returns True if a < b
# greater_equal(a: Decimal, b: Decimal) -> Bool: Returns True if a >= b
# less_equal(a: Decimal, b: Decimal) -> Bool: Returns True if a <= b
# equal(a: Decimal, b: Decimal) -> Bool: Returns True if a == b
# not_equal(a: Decimal, b: Decimal) -> Bool: Returns True if a != b
#
# List of internal functions in this module:
#
# _compare_abs(a: Decimal, b: Decimal) -> Int: Compares absolute values of two Decimals
#
# ===----------------------------------------------------------------------=== #

"""
Implements functions for comparison operations on Decimal objects.
"""

import testing

from decimojo.decimal import Decimal
import decimojo.utility


fn compare(x: Decimal, y: Decimal) -> Int8:
    """
    Compares the values of two Decimal numbers and returns the result.

    Args:
        x: First Decimal value.
        y: Second Decimal value.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if x > y.
        (2)  0 if x = y.
        (3) -1 if x < y.
    """

    # If both are zero, they are equal regardless of scale or sign
    if x.is_zero() and y.is_zero():
        return 0

    # If x is zero, it is less than any non-zero number
    elif x.is_zero():
        return 1 if y.is_negative() else -1

    # If y is zero, it is less than any non-zero number
    elif y.is_zero():
        return -1 if x.is_negative() else 1

    # If signs differ, the positive one is greater
    elif x.is_negative() != y.is_negative():
        return -1 if x.is_negative() else 1

    # If they have the same sign, compare the absolute values
    elif x.is_negative():
        return -compare_absolute(x, y)

    else:
        return compare_absolute(x, y)


fn compare_absolute(x: Decimal, y: Decimal) -> Int8:
    """
    Compares the absolute values of two Decimal numbers and returns the result.

    Args:
        x: First Decimal value.
        y: Second Decimal value.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if |x| > |y|.
        (2)  0 if |x| = |y|.
        (3) -1 if |x| < |y|.
    """

    var x_coef = x.coefficient()
    var y_coef = y.coefficient()
    var x_scale = x.scale()
    var y_scale = y.scale()

    # CASE: The scales are the same
    # Compare the coefficients directly
    if x_scale == y_scale:
        if x_coef > y_coef:
            return 1
        elif x_coef < y_coef:
            return -1
        else:
            return 0

    # CASE: The scales are different
    # Compare the integral part first
    # If the integral part is the same, compare the fractional part
    else:
        var x_int = x_coef // UInt128(10) ** (x_scale)
        var y_int = y_coef // UInt128(10) ** (y_scale)

        if x_int > y_int:
            return 1
        elif x_int < y_int:
            return -1
        else:
            var x_frac = x_coef % (UInt128(10) ** (x_scale))
            var y_frac = y_coef % (UInt128(10) ** (y_scale))

            # Adjust the fractional part to have the same scale
            var scale_diff = x_scale - y_scale
            if scale_diff > 0:
                y_frac *= UInt128(10) ** scale_diff
            else:
                x_frac *= UInt128(10) ** (-scale_diff)

            if x_frac > y_frac:
                return 1
            elif x_frac < y_frac:
                return -1
            else:
                return 0


fn greater(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a > b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a is greater than b, False otherwise.
    """

    # Special case: either are zero
    if a.is_zero() and b.is_zero():
        return False  # Zero equals zero

    # Sepcial case:
    if a.is_zero():
        return b.is_negative()  # a=0 > b only if b is negative
    if b.is_zero():
        return (
            not a.is_negative() and not a.is_zero()
        )  # a > b=0 only if a is positive and non-zero

    # If they have different signs, positive is always greater
    if a.is_negative() != b.is_negative():
        return not a.is_negative()  # a > b if a is positive and b is negative

    # Now we know they have the same sign
    # Compare absolute values, considering the sign
    var compare_result = compare_absolute(a, b)

    if a.is_negative():
        # For negative numbers, the one with smaller absolute value is greater
        return compare_result < 0
    else:
        # For positive numbers, the one with larger absolute value is greater
        return compare_result > 0


fn less(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a < b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a is less than b, False otherwise.
    """
    # We can use the greater function with arguments reversed
    return greater(b, a)


fn greater_equal(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a >= b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a is greater than or equal to b, False otherwise.
    """
    # Handle special case where either or both are zero
    if a.is_zero() and b.is_zero():
        return True  # Zero equals zero
    if a.is_zero():
        return (
            b.is_zero() or b.is_negative()
        )  # a=0 >= b only if b is zero or negative
    if b.is_zero():
        return (
            a.is_negative() == False
        )  # a >= b=0 only if a is positive or zero

    # If they have different signs, positive is always greater
    if a.is_negative() != b.is_negative():
        return not a.is_negative()  # a >= b if a is positive and b is negative

    # Now we know they have the same sign
    # Compare absolute values, considering the sign
    var compare_result = compare_absolute(a, b)

    if a.is_negative():
        # For negative numbers, the one with smaller or equal absolute value is greater or equal
        return compare_result <= 0
    else:
        # For positive numbers, the one with larger or equal absolute value is greater or equal
        return compare_result >= 0


fn less_equal(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a <= b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a is less than or equal to b, False otherwise.
    """
    # We can use the greater_equal function with arguments reversed
    return greater_equal(b, a)


fn equal(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a == b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a equals b, False otherwise.
    """
    # If both are zero, they are equal regardless of scale or sign
    if a.is_zero() and b.is_zero():
        return True

    # If signs differ, they're not equal
    if a.is_negative() != b.is_negative():
        return False

    # Compare absolute values
    return compare_absolute(a, b) == 0


fn not_equal(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a != b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a is not equal to b, False otherwise.
    """
    # Simply negate the equal function
    return not equal(a, b)
