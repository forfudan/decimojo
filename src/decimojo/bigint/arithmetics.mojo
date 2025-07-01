# ===----------------------------------------------------------------------=== #
# Copyright 2025 Yuhao Zhu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

"""
Implements basic arithmetic functions for the BigInt type.
"""

import time
import testing

from decimojo.bigint.bigint import BigInt
from decimojo.biguint.biguint import BigUInt
from decimojo.rounding_mode import RoundingMode


fn add(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the sum of two BigInts.

    Args:
        x1: The first BigInt operand.
        x2: The second BigInt operand.

    Returns:
        The sum of the two BigInts.
    """
    # If one of the numbers is zero, return the other number
    if x1.is_zero():
        return x2
    if x2.is_zero():
        return x1

    # If signs are different, delegate to `subtract`
    if x1.sign != x2.sign:
        return subtract(x1, -x2)

    # Same sign: add magnitudes and preserve the sign
    var magnitude: BigUInt = x1.magnitude + x2.magnitude

    return BigInt(magnitude^, sign=x1.sign)


fn add_inplace(mut x1: BigInt, x2: BigInt) raises -> None:
    """Increments a BigInt number by another BigInt number in place.

    Args:
        x1: The first BigInt operand.
        x2: The second BigInt operand.
    """

    # If signs are different, delegate to `subtract`
    if x1.sign != x2.sign:
        x1 = subtract(x1, -x2)
        return

    # Same sign: add magnitudes in place
    else:
        x1.magnitude += x2.magnitude


fn subtract(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the difference of two numbers.

    Args:
        x1: The first number (minuend).
        x2: The second number (subtrahend).

    Returns:
        The result of subtracting x2 from x1.
    """
    # If the subtrahend is zero, return the minuend
    if x2.is_zero():
        return x1
    # If the minuend is zero, return the negated subtrahend
    if x1.is_zero():
        return -x2

    # If signs are different, delegate to `add`
    if x1.sign != x2.sign:
        return x1 + (-x2)

    # Same sign, compare magnitudes to determine result sign and operation
    var comparison_result = x1.magnitude.compare(x2.magnitude)

    if comparison_result == 0:
        return BigInt()  # Equal magnitudes result in zero

    var magnitude: BigUInt
    var sign: Bool
    if comparison_result > 0:  # |x1| > |x2|
        # Subtract smaller from larger
        magnitude = x1.magnitude - x2.magnitude
        sign = x1.sign

    else:  # |x1| < |x2|
        # Subtract larger from smaller and negate the result
        magnitude = x2.magnitude - x1.magnitude
        sign = not x1.sign

    return BigInt(magnitude^, sign=sign)


fn negative(x: BigInt) -> BigInt:
    """Returns the negative of a BigInt number.

    Args:
        x: The BigInt value to compute the negative of.

    Returns:
        A new BigInt containing the negative of x.

    Notes:
        `BigInt` does allow signed zeros, so the negative of zero is zero.
    """
    # If x is zero, return zero
    if x.is_zero():
        return BigInt()

    var result = x
    result.sign = not result.sign
    return result^


fn absolute(x: BigInt) -> BigInt:
    """Returns the absolute value of a BigInt number.

    Args:
        x: The BigInt value to compute the absolute value of.

    Returns:
        A new BigInt containing the absolute value of x.
    """
    if x.sign:
        return -x
    else:
        return x


fn multiply(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the product of two BigInt numbers.

    Args:
        x1: The first BigInt operand (multiplicand).
        x2: The second BigInt operand (multiplier).

    Returns:
        The product of the two BigInt numbers.
    """
    # CASE: One of the operands is zero
    if x1.is_zero() or x2.is_zero():
        return BigInt()  # Return zero regardless of sign

    # Multiply the magnitudes using BigUInt's multiplication
    var result_magnitude = x1.magnitude * x2.magnitude

    # Create and return final result with correct sign
    return BigInt(result_magnitude^, sign=x1.sign != x2.sign)


fn floor_divide(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the quotient of two numbers, rounding toward negative infinity.
    The modulo has the same sign as the divisor and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_divide(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, rounded toward negative infinity.
    """

    if x2.is_zero():
        raise Error("Error in `floor_divide`: Division by zero")

    if x1.is_zero():
        return BigInt()

    # For floor division, the sign rules are:
    # (1) Same signs: result is positive, use `floor_divide` on magnitudes
    # (1) Different signs: result is negative, use `ceil_divide` on magnitudes

    if x1.sign == x2.sign:
        # Use floor (truncate) division between magnitudes
        return BigInt(x1.magnitude.floor_divide(x2.magnitude), sign=False)

    else:
        # Use ceil division of the magnitudes
        return BigInt(x1.magnitude.ceil_divide(x2.magnitude), sign=True)


fn truncate_divide(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the quotient of two BigInt numbers, truncating toward zero.
    The modulo has the same sign as the divisor and satisfies:
    x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero.

    Raises:
        ValueError: If the divisor is zero.
    """
    if x2.is_zero():
        raise Error("Error in `truncate_divide`: Division by zero")

    if x1.is_zero():
        return BigInt()  # Return zero

    var magnitude = x1.magnitude.floor_divide(x2.magnitude)
    return BigInt(magnitude^, sign=x1.sign != x2.sign)


fn floor_modulo(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the remainder of two numbers, truncating toward negative infinity.
    The remainder has the same sign as the divisor and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2, with the same sign as x2.
    """

    if x2.is_zero():
        raise Error("Error in `floor_modulo`: Division by zero")

    if x1.is_zero():
        return BigInt()  # Return zero

    if x1.sign == x2.sign:
        # Use floor (truncate) division between magnitudes
        return BigInt(x1.magnitude.floor_modulo(x2.magnitude), sign=x2.sign)

    else:
        # Use ceil division of the magnitudes
        return BigInt(x1.magnitude.ceil_modulo(x2.magnitude), sign=x2.sign)


fn truncate_modulo(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the remainder of two numbers, truncating toward zero.
    The remainder has the same sign as the dividend and satisfies:
    x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2, with the same sign as x1.

    Raises:
        ValueError: If the divisor is zero.
    """
    if x2.is_zero():
        raise Error("Error in `truncate_modulo`: Division by zero")

    if x1.is_zero():
        return BigInt()  # Return zero

    var magnitude = x1.magnitude.floor_modulo(x2.magnitude)
    return BigInt(magnitude^, sign=x1.sign)
