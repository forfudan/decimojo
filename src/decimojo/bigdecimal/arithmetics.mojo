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
    var coef1 = x1.coefficient.multiply_by_power_of_10(scale_factor1)
    var coef2 = x2.coefficient.multiply_by_power_of_10(scale_factor2)

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
    var coef1 = x1.coefficient.multiply_by_power_of_10(scale_factor1)
    var coef2 = x2.coefficient.multiply_by_power_of_10(scale_factor2)

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
