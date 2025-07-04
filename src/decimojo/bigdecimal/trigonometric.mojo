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


fn sin(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculates sine (sin) of the number.

    Args:
        x: The input number in radians.
        precision: The desired precision of the result.

    Returns:
        The sine of x with the specified precision.

    Notes:
    This function adopts range reduction for optimal convergence.
    """

    # Yuhao Zhu's notes:
    # I use a very comservative number of buffer digits because we need to have
    # a very high precision to calculate the pi so that we can conduct range
    # reduction accurately.
    # Otherwise, the result will be inaccurate when x is close to π-related
    # values, e.g., π/2, π, 3π/2, 2π, etc.
    alias BUFFER_DIGITS = 99
    var working_precision = precision + BUFFER_DIGITS

    var result: BigDecimal

    if x.is_zero():
        return BigDecimal.from_raw_components(
            UInt32(0), scale=precision, sign=x.sign
        )

    var bdec_2 = BigDecimal.from_raw_components(UInt32(2), scale=0, sign=False)
    var bdec_4 = BigDecimal.from_raw_components(UInt32(4), scale=0, sign=False)
    var bdec_6 = BigDecimal.from_raw_components(UInt32(6), scale=0, sign=False)
    var bdec_pi = decimojo.bigdecimal.constants.pi(precision=working_precision)
    var bdec_2pi = bdec_2 * bdec_pi
    var bdec_pi_div_2 = bdec_pi.true_divide(bdec_2, precision=working_precision)
    var bdec_1d6 = BigDecimal.from_raw_components(
        UInt32(16), scale=1, sign=False
    )
    var bdec_pi_div_4 = bdec_pi.true_divide(bdec_4, precision=working_precision)

    # Step 1: Reduce to (-2π, 2π) using modulo and symmetry
    # sin(x) = sin(x mod 2π)
    var x_reduced = x
    if x.compare_absolute(bdec_2pi) >= 0:
        # x_reduced = x mod 2π
        x_reduced = x % bdec_2pi

    # Step 2: Reduce [-2π, -6] or [6, 2π] to [6-2π, 2π-6]
    # sin(x) = sin(x - 2π)
    # This is because 2π is an instable point for comparison.
    # To avoid infinite recursion in the final step,
    # we reduce it to [6-2π, 2π-6].
    if x.compare_absolute(bdec_6) >= 0:
        if x.sign:
            # x in [-2π, -6], reduce to [0, 2π-6]
            x_reduced = x + bdec_2pi
        else:
            # x in [6, 2π], reduce to [0, 2π-6]
            x_reduced = x - bdec_2pi

    # Step 2: Reduce to [0, 2π) using symmetry
    # At this stage, the value should be in the range [0, 6].
    var is_negative: Bool
    if x_reduced.sign:
        is_negative = True
        x_reduced = -x_reduced
    else:
        is_negative = False

    # Step 3: Reduce to [0, π/4] with different cases

    # |x| ≤ π/4: Use Taylor series directly
    if x_reduced.compare_absolute(bdec_pi_div_4) <= 0:
        print("Using Taylor series for sin(x) in [-π/4, π/4]")
        result = sin_taylor_series(
            x_reduced, minimum_precision=working_precision
        )

    # π/4 < |x| ≤ π/2: Use identity sin(x) = cos(π/2 - x)
    # 0 ≤ (π/2 - x) < π/4
    # Use 1.6 because π/4 is an instable point for the next case.
    # To avoid infinite recursion, we use 1.6 as a threshold.
    # π/4 < |x| ≤ 1.6
    elif x_reduced.compare_absolute(bdec_1d6) <= 0:
        x_reduced = bdec_pi_div_2 - x_reduced
        result = cos_taylor_series(
            x_reduced, minimum_precision=working_precision
        )

    # π/2 < |x| ≤ π: Use identity sin(x) = sin(π - x)
    # 0 ≤ (π - x) < π/2
    # Because 1.6 is used as a threshold before
    # π/2 < 1.6 < |x| ≤ π
    # 0 ≤ (π - x) < π - 1.6 < π/2
    elif x_reduced.compare_absolute(bdec_pi) <= 0:
        x_reduced = bdec_pi - x_reduced
        result = sin(x_reduced, precision=precision)

    # π < |x| < 2π: Use identity sin(x) = -sin(x - π)
    # 0 < (x - π) < π
    # Note tha the acutal range is (π, 6), so it is reduced to (0, 6- π).
    else:
        x_reduced = x_reduced - bdec_pi
        result = -sin(x_reduced, precision=precision)

    if is_negative:
        result = -result

    result.round_to_precision(
        precision,
        RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )

    return result^


fn sin_taylor_series(
    x: BigDecimal, minimum_precision: Int
) raises -> BigDecimal:
    """Calculates sine of a number with Taylor series.

    Args:
        x: The input number in radians.
        minimum_precision: The minimum precision of the result.

    Returns:
        The sine of the input number with the specified precision plus
        some extra digits to ensure accuracy.

    Notes:

    Using Taylor series.
    sin(x) = x - x³/3! + x⁵/5! - x⁷/7! + ...
    """

    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = minimum_precision + BUFFER_DIGITS

    if x.is_zero():
        return BigDecimal.from_raw_components(
            UInt32(0), scale=minimum_precision, sign=x.sign
        )

    var term = x  # x^n / n!
    var result = x
    var x_squared = x * x
    var n = 1
    var sign = -1

    # Continue until term is smaller than desired precision
    var epsilon = BigDecimal(BigUInt.ONE, scale=working_precision, sign=False)

    while term.compare_absolute(epsilon) > 0:
        # x^n = x^(n-2) * x^2 / ((n-1)(n))
        n += 2
        term = term * x_squared
        term = term.true_divide(
            BigDecimal(n) * BigDecimal(n - 1), precision=working_precision
        )
        if sign == 1:
            result += term
        else:
            result -= term
        sign *= -1

        # Ensure that the result will not explode in size
        result.round_to_precision(
            working_precision,
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )

    return result^


fn cos(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculates cosine (cos) of the number.

    Args:
        x: The input number in radians.
        precision: The desired precision of the result.

    Returns:
        The cosine of x with the specified precision.

    Notes:
    This function adopts range reduction for optimal convergence.
    """

    alias BUFFER_DIGITS = 99
    var working_precision = precision + BUFFER_DIGITS

    if x.is_zero():
        return BigDecimal.from_raw_components(
            UInt32(1), scale=precision, sign=x.sign
        )

    # cos(x) = sin(π/2 - x)
    var pi = decimojo.bigdecimal.constants.pi(precision=working_precision)
    var pi_div_2 = pi.true_divide(2, precision=working_precision)
    var result = sin(pi_div_2 - x, precision=precision)
    return result^


fn cos_taylor_series(
    x: BigDecimal, minimum_precision: Int
) raises -> BigDecimal:
    """Calculates cosine using Taylor series.

    Args:
        x: The input number in radians.
        minimum_precision: The minimum precision of the result.

    Returns:
        The cosine of the input number with the specified precision plus
        some extra digits to ensure accuracy.

    Notes:

    Using Taylor series.
    cos(x) = 1 - x²/2! + x⁴/4! - x⁶/6! + ...
    """

    alias BUFFER_DIGITS = 9
    var working_precision = minimum_precision + BUFFER_DIGITS

    if x.is_zero():
        return BigDecimal.from_raw_components(
            UInt32(1), scale=minimum_precision, sign=x.sign
        )

    var bdec_1 = BigDecimal.from_raw_components(UInt32(1), scale=0, sign=False)
    var term = bdec_1  # Current term: x^n / n!
    var result = bdec_1  # Start with 1
    var x_squared = x * x
    var n = 0  # Current power (0, 2, 4, 6, ...)
    var sign = -1  # Alternating sign

    var epsilon = BigDecimal(BigUInt.ONE, scale=working_precision, sign=False)

    while term.compare_absolute(epsilon) > 0:
        n += 2  # Next even power: 2, 4, 6, 8, ...
        term = term * x_squared
        term = term.true_divide(
            BigDecimal(n) * BigDecimal(n - 1), precision=working_precision
        )

        if sign == 1:
            result += term
        else:
            result -= term

        sign *= -1

        # # Prevent size explosion
        result.round_to_precision(
            working_precision,
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )

    return result^


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

    var result: BigDecimal

    if x.compare_absolute(bdec_0d5) <= 0:
        # |x| <= 0.5, use Taylor series:
        # print("Using Taylor series for arctan with |x| <= 0.5")
        result = arctan_taylor_series(x, minimum_precision=precision)

    elif x.compare_absolute(bdec_2) <= 0:
        # |x| <= 2, use the identity:
        # arctan(x) = 2 * arctan(x / (1 + sqrt(1 + x²)))
        # This is to ensure convergence of the Taylor series.
        # print("Using identity for arctan with |x| <= 2")
        var sqrt_term = (bdec_1 + x * x).sqrt(precision=working_precision)
        var x_divided = x.true_divide(
            bdec_1 + sqrt_term, precision=working_precision
        )
        result = bdec_2 * arctan_taylor_series(
            x_divided, minimum_precision=precision
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

        if x.sign:
            result = -half_pi - arctan_reciprocal
        else:
            result = half_pi - arctan_reciprocal

    result.round_to_precision(
        precision,
        RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )
    return result^


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
    """

    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = minimum_precision + BUFFER_DIGITS

    if x.is_zero():
        return BigDecimal.from_raw_components(
            UInt32(0), scale=minimum_precision, sign=x.sign
        )

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
