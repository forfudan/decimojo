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
Implements functions for mathematical operations on BigDecimal objects.
"""

import time
import testing

from decimojo.decimal.decimal import Decimal
from decimojo.rounding_mode import RoundingMode
import decimojo.utility


fn add(x1: BigDecimal, x2: BigDecimal) raises -> BigDecimal:
    """Returns the sum of two numbers.

    Args:
        x1: The first operand.
        x2: The second operand.

    Returns:
        The sum of x1 and x2.

    Notes:

    Rules for addition:
    - This function always return the exact result of the addition.
    - The result's scale is the maximum of the two operands' scales.
    - The result's sign is determined by the signs of the operands.
    """
    var max_scale = max(x1.scale, x2.scale)
    var scale_factor1 = (max_scale - x1.scale) if x1.scale < max_scale else 0
    var scale_factor2 = (max_scale - x2.scale) if x2.scale < max_scale else 0

    # Handle zero operands as special cases for efficiency
    if x1.coefficient.is_zero():
        if x2.coefficient.is_zero():
            return BigDecimal(
                coefficient=BigUInt.ZERO,
                scale=max_scale,
                sign=False,
            )
        else:
            return x2.extend_precision(scale_factor2)
    if x2.coefficient.is_zero():
        return x1.extend_precision(scale_factor1)

    # Scale coefficients to match
    var coef1 = x1.coefficient.scale_up_by_power_of_10(scale_factor1)
    var coef2 = x2.coefficient.scale_up_by_power_of_10(scale_factor2)

    # Handle addition based on signs
    if x1.sign == x2.sign:
        # Same sign: Add coefficients, keep sign
        var result_coef = coef1 + coef2
        return BigDecimal(
            coefficient=result_coef^, scale=max_scale, sign=x1.sign
        )
    # Different signs: Subtract smaller coefficient from larger
    if coef1 > coef2:
        # |x1| > |x2|, result sign is x1's sign
        var result_coef = coef1 - coef2
        return BigDecimal(
            coefficient=result_coef^, scale=max_scale, sign=x1.sign
        )
    elif coef2 > coef1:
        # |x2| > |x1|, result sign is x2's sign
        var result_coef = coef2 - coef1
        return BigDecimal(
            coefficient=result_coef^, scale=max_scale, sign=x2.sign
        )
    else:
        # |x1| == |x2|, signs differ, result is 0
        return BigDecimal(
            coefficient=BigUInt(UInt32(0)), scale=max_scale, sign=False
        )


fn subtract(x1: BigDecimal, x2: BigDecimal) raises -> BigDecimal:
    """Returns the difference of two numbers.

    Args:
        x1: The first operand (minuend).
        x2: The second operand (subtrahend).

    Returns:
        The difference of x1 and x2 (x1 - x2).

    Notes:

    - This function always return the exact result of the subtraction.
    - The result's scale is the maximum of the two operands' scales.
    - The result's sign is determined by the signs of the operands.
    """

    var max_scale = max(x1.scale, x2.scale)
    var scale_factor1 = (max_scale - x1.scale) if x1.scale < max_scale else 0
    var scale_factor2 = (max_scale - x2.scale) if x2.scale < max_scale else 0

    # Handle zero operands as special cases for efficiency
    if x2.coefficient.is_zero():
        if x1.coefficient.is_zero():
            return BigDecimal(
                coefficient=BigUInt.ZERO,
                scale=max_scale,
                sign=False,
            )
        else:
            return x1.extend_precision(scale_factor1)
    if x1.coefficient.is_zero():
        var result = x2.extend_precision(scale_factor2)
        result.sign = not result.sign
        return result^

    # Scale coefficients to match
    var coef1 = x1.coefficient.scale_up_by_power_of_10(scale_factor1)
    var coef2 = x2.coefficient.scale_up_by_power_of_10(scale_factor2)

    # Handle subtraction based on signs
    if x1.sign != x2.sign:
        # Different signs: x1 - (-x2) = x1 + x2, or (-x1) - x2 = -(x1 + x2)
        var result_coef = coef1 + coef2
        return BigDecimal(
            coefficient=result_coef^, scale=max_scale, sign=x1.sign
        )

    # Same signs: Must perform actual subtraction
    if coef1 > coef2:
        # |x1| > |x2|, result sign is x1's sign
        var result_coef = coef1 - coef2
        return BigDecimal(
            coefficient=result_coef^, scale=max_scale, sign=x1.sign
        )
    elif coef2 > coef1:
        # |x1| < |x2|, result sign is opposite of x1's sign
        var result_coef = coef2 - coef1
        return BigDecimal(
            coefficient=result_coef^, scale=max_scale, sign=not x1.sign
        )
    else:
        # |x1| == |x2|, result is 0
        return BigDecimal(coefficient=BigUInt.ZERO, scale=max_scale, sign=False)


fn multiply(x1: BigDecimal, x2: BigDecimal) raises -> BigDecimal:
    """Returns the product of two numbers.

    Args:
        x1: The first operand (multiplicand).
        x2: The second operand (multiplier).

    Returns:
        The product of x1 and x2.

    Notes:

    - This function always returns the exact result of the multiplication.
    - The result's scale is the sum of the two operands' scales (except for zero).
    - The result's sign follows the standard sign rules for multiplication.
    """
    # Handle zero operands as special cases for efficiency
    if x1.coefficient.is_zero() or x2.coefficient.is_zero():
        return BigDecimal(
            coefficient=BigUInt.ZERO,
            scale=x1.scale + x2.scale,
            sign=x1.sign != x2.sign,
        )

    return BigDecimal(
        coefficient=x1.coefficient * x2.coefficient,
        scale=x1.scale + x2.scale,
        sign=x1.sign != x2.sign,
    )


fn true_divide(
    x1: BigDecimal, x2: BigDecimal, max_precision: Int = 28
) raises -> BigDecimal:
    """Returns the quotient of two numbers.

    Args:
        x1: The first operand (dividend).
        x2: The second operand (divisor).
        max_precision: The maximum precision for the result. It should be
            non-negative.

    Returns:
        The quotient of x1 and x2, with precision up to max_precision.

    Notes:

    - If the coefficients can be divided exactly, the number of digits after
        the decimal point is the difference of the scales of the two operands.
    - If the coefficients cannot be divided exactly, the number of digits after
        the decimal point is max_precision.
    - If the division is not exact, the number of digits after the decimal
        point is calcuated to max_precision + BUFFER_DIGITS, and the result is
        rounded to max_precision according to the specified rules.
    """
    alias BUFFER_DIGITS = 2  # Buffer digits for rounding

    # Check for division by zero
    if x2.coefficient.is_zero():
        raise Error("Division by zero")

    # Handle dividend of zero
    if x1.coefficient.is_zero():
        return BigDecimal(
            coefficient=BigUInt(UInt32(0)),
            scale=max(0, x1.scale - x2.scale),
            sign=x1.sign != x2.sign,
        )

    # TODO: Divided by power of 10

    # Check whether the coefficients can be divided exactly
    # If division is exact, return the result immediately
    if len(x1.coefficient.words) >= len(x2.coefficient.words):
        # Check if x1 is divisible by x2
        var quotient: BigUInt
        var remainder: BigUInt
        quotient, remainder = x1.coefficient.divmod(x2.coefficient)
        if remainder.is_zero():
            return BigDecimal(
                coefficient=quotient,
                scale=x1.scale - x2.scale,
                sign=x1.sign != x2.sign,
            )

    # Calculate how many extra digits we need to scale x1 by
    # We want (max_precision + BUFFER_DIGITS) decimal places in the result
    var desired_result_scale = max_precision + BUFFER_DIGITS
    var current_result_scale = x1.scale - x2.scale
    var scale_factor = max(0, desired_result_scale - current_result_scale)

    # Scale the dividend coefficient
    var scaled_x1_coefficient = x1.coefficient
    if scale_factor > 0:
        scaled_x1_coefficient = x1.coefficient.scale_up_by_power_of_10(
            scale_factor
        )

    # Perform the division and get remainder
    var result_coefficient: BigUInt
    var remainder: BigUInt
    result_coefficient, remainder = scaled_x1_coefficient.divmod(x2.coefficient)
    var result_scale = x1.scale + scale_factor - x2.scale

    # If the division is exact
    # we may need to remove the extra trailing zeros.
    # TODO: Think about the behavior, whether division should always return the
    # maximum precision even if the result scale is less than max_precision.
    # Example: 1 / 1 = 1.0000000000000000000000000000
    if remainder.is_zero():
        # result_scale == scale_factor + (x1.scale - x2.scale)
        var number_of_trailing_zeros = result_coefficient.number_of_trailing_zeros()
        print("DEBUG: result_coefficient = ", result_coefficient)
        print("DEBUG: remainder = ", remainder)
        print("DEBUG: number_of_trailing_zeros = ", number_of_trailing_zeros)
        print("DEBUG: scale_factor = ", scale_factor)
        # If number_of_trailing_zeros <= scale_factor:
        #   Just remove the trailing zeros, the scale is larger than expected
        #   scale (x1.scale - x2.scale) because the division is exact but with
        #   fractional part.
        # If number_of_trailing_zeros > scale_factor:
        #   We can remove at most scale_factor digits because the result scale
        #   should be no less than expected scale
        var number_of_zeros_to_remove = min(
            number_of_trailing_zeros, scale_factor
        )
        result_coefficient = result_coefficient.scale_down_by_power_of_10(
            number_of_zeros_to_remove
        )

        return BigDecimal(
            coefficient=result_coefficient^,
            scale=result_scale - number_of_zeros_to_remove,
            sign=x1.sign != x2.sign,
        )

    # Otherwise, the division is not exact or have too many digits
    # round to max_precision
    # TODO: Use round() function when it is available
    var digits_to_remove = result_scale - max_precision
    if digits_to_remove > BUFFER_DIGITS:
        print(
            "Warning: Remove (={}) more than BUFFER_DIGITS digits (={}), the"
            " algorithm may not be optimal.".format(
                digits_to_remove, BUFFER_DIGITS
            )
        )

    # Extract the digits to be rounded
    # Example: 2 digits to remove
    # divisor = 100
    # half_divisor = 50
    # rounding_digits = 123456 % 100 = 56
    # result_coefficient = 123456 // 100 = 1234
    # If rounding_digits > half_divisor, round up
    # If rounding_digits == half_divisor, round up if the last digit of
    # result_coefficient is odd
    # If rounding_digits < half_divisor, round down
    var divisor = BigUInt.ONE.scale_up_by_power_of_10(digits_to_remove)
    var half_divisor = divisor // BigUInt(2)
    var rounding_digits: BigUInt
    result_coefficient, rounding_digits = result_coefficient.divmod(divisor)

    # Apply rounding rules
    var round_up = False
    if rounding_digits > half_divisor:
        round_up = True
    elif rounding_digits == half_divisor:
        round_up = result_coefficient.words[0] % 2 == 1

    if round_up:
        result_coefficient += BigUInt(1)

    # Update scale
    result_scale = max_precision

    return BigDecimal(
        coefficient=result_coefficient^,
        scale=result_scale,
        sign=x1.sign != x2.sign,
    )
