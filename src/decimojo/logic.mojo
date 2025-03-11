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
# greater(a: Decimal, b: Decimal) -> Bool: Returns True if a > b
# greater_equal(a: Decimal, b: Decimal) -> Bool: Returns True if a >= b
# less(a: Decimal, b: Decimal) -> Bool: Returns True if a < b
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

from .decimal import Decimal


fn greater(a: Decimal, b: Decimal) -> Bool:
    """
    Returns True if a > b.

    Args:
        a: First Decimal value.
        b: Second Decimal value.

    Returns:
        True if a is greater than b, False otherwise.
    """
    # Handle special case where either or both are zero
    if a.is_zero() and b.is_zero():
        return False  # Zero equals zero
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
    var compare_result = _compare_abs(a, b)

    if a.is_negative():
        # For negative numbers, the one with smaller absolute value is greater
        return compare_result < 0
    else:
        # For positive numbers, the one with larger absolute value is greater
        return compare_result > 0


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
    var compare_result = _compare_abs(a, b)

    if a.is_negative():
        # For negative numbers, the one with smaller or equal absolute value is greater or equal
        return compare_result <= 0
    else:
        # For positive numbers, the one with larger or equal absolute value is greater or equal
        return compare_result >= 0


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
    return _compare_abs(a, b) == 0


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


fn _compare_abs(a: Decimal, b: Decimal) -> Int:
    """
    Internal helper to compare absolute values of two Decimal numbers.

    Returns:
    - Positive value if |a| > |b|
    - Zero if |a| = |b|
    - Negative value if |a| < |b|

    raises:
        Error: Calling `scale_up()` failed.
    """
    # Normalize scales by scaling up the one with smaller scale
    var scale_a = a.scale()
    var scale_b = b.scale()

    # Create temporary copies that we will scale
    var a_copy = a
    var b_copy = b

    # Scale up the decimal with smaller scale to match the other
    # TODO: Treat this error properly
    if scale_a < scale_b:
        try:
            a_copy = decimojo.utility.scale_up(a, scale_b - scale_a)
        except:
            a_copy = a
    elif scale_b < scale_a:
        try:
            b_copy = decimojo.utility.scale_up(b, scale_a - scale_b)
        except:
            b_copy = b

    # Now both have the same scale, compare integer components
    # Compare high parts first (most significant)
    if a_copy.high > b_copy.high:
        return 1
    if a_copy.high < b_copy.high:
        return -1

    # High parts equal, compare mid parts
    if a_copy.mid > b_copy.mid:
        return 1
    if a_copy.mid < b_copy.mid:
        return -1

    # Mid parts equal, compare low parts (least significant)
    if a_copy.low > b_copy.low:
        return 1
    if a_copy.low < b_copy.low:
        return -1

    # All components are equal
    return 0
