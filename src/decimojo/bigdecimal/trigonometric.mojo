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

# ===----------------------------------------------------------------------=== #
# Trigonometric functions for BigDecimal
# ===----------------------------------------------------------------------=== #

import time

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode
import decimojo.utility


# ===----------------------------------------------------------------------=== #
# Trigonometric functions
# ===----------------------------------------------------------------------=== #


fn sin(x: BigDecimal, precision: Int) raises:
    ...


# ===----------------------------------------------------------------------=== #
# Inverse trigonometric functions
# ===----------------------------------------------------------------------=== #


fn arctan(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculates arctangent (arctan) of the number.

    Notes:

    y = arctan(x),
    where x can be all real numbers,
    and y is in the range (-π/2, π/2).
    """

    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = precision + BUFFER_DIGITS

    bdec_1 = BigDecimal.from_raw_components(UInt32(1), scale=0, sign=False)
    bdec_2 = BigDecimal.from_raw_components(UInt32(2), scale=0, sign=False)
    bdec_0d5 = BigDecimal.from_raw_components(UInt32(5), scale=1, sign=False)

    if x.compare_absolute(bdec_0d5) <= 0:
        # |x| <= 0.5, use Taylor series:
        # print("Using Taylor series for arctan with |x| <= 0.5")
        return arctan_taylor_series(x, minimum_precision=precision).round(
            ndigits=precision, rounding_mode=RoundingMode.ROUND_HALF_EVEN
        )
    elif x.compare_absolute(bdec_2) <= 0:
        # |x| <= 2, use the identity:
        # arctan(x) = 2 * arctan(x / (1 + sqrt(1 + x²)))
        # This is to ensure convergence of the Taylor series.
        # print("Using identity for arctan with |x| <= 2")
        var sqrt_term = (bdec_1 + x * x).sqrt(precision=working_precision)
        var x_divided = x.true_divide(
            bdec_1 + sqrt_term, precision=working_precision
        )
        var result = bdec_2 * arctan_taylor_series(
            x_divided, minimum_precision=precision
        )
        return result.round(
            ndigits=precision, rounding_mode=RoundingMode.ROUND_HALF_EVEN
        )
    else:  # x.compare_absolute(bdec_1) > 0
        # |x| > 2, use the identity:
        # For x > 2: arctan(x) = π/2 - arctan(1/x)
        # For x < -2: arctan(x) = -π/2 - arctan(1/x)
        # This is to ensure convergence of the Taylor series.
        # print("Using identity for arctan with |x| > 2")
        var half_pi = decimojo.bigdecimal.constants.pi(
            precision=working_precision
        ).true_divide(bdec_2, precision=working_precision)
        var reciprocal_x = bdec_1.true_divide(x, precision=working_precision)
        var arctan_reciprocal = arctan_taylor_series(
            reciprocal_x^, minimum_precision=precision
        )

        var result: BigDecimal
        if x.sign:
            result = -half_pi - arctan_reciprocal
        else:
            result = half_pi - arctan_reciprocal

        return result.round(
            ndigits=precision, rounding_mode=RoundingMode.ROUND_HALF_EVEN
        )


fn arctan_taylor_series(
    x: BigDecimal, minimum_precision: Int
) raises -> BigDecimal:
    """Calculates arctangent (arctan) of a number with Taylor series.

    Args:
        x: The input number, must be in the range (-0.5, 0.5) for convergence.
        minimum_precision: The mininum precision of the result.

    Returns:
        The arctangent of the input number with the specified precision plus
        some extra digits to ensure accuracy.

    Notes:

    Using Taylor series.
    arctan(x) = x - x³/3 + x⁵/5 - x⁷/7 + ...
    The input x must be in the range (-0.5, 0.5) for convergence.
    Time complexity is O(n^4) for precision n.
    Every time you double the precision, the time taken increases by a
    factor of 16.
    """

    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = minimum_precision + BUFFER_DIGITS

    if x.is_zero():
        return BigDecimal(0)

    var term = x  # x^n
    var term_divided = x  # x^n / n
    var result = x
    var x_squared = x * x
    var n = 1
    var sign = -1

    # Continue until term is smaller than desired precision
    var epsilon = BigDecimal(BigUInt.ONE, scale=working_precision, sign=False)

    while term_divided.compare_absolute(epsilon) > 0:
        n += 2
        term = term * x_squared  # x^n = x^(n-2) * x^2
        term_divided = term.true_divide(
            BigDecimal(n), precision=working_precision
        )  # x^n / n
        if sign == 1:
            result += term_divided
        else:
            result -= term_divided
        sign *= -1
        # Ensure that the result will not explode in size
        result.round_to_precision(
            working_precision,
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )

    return result^
