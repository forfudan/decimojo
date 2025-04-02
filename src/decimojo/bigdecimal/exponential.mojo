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
# Power and root functions
# ===----------------------------------------------------------------------=== #

"""Implements exponential functions for the BigDecimal type."""

import time

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode
import decimojo.utility


fn sqrt(x: BigDecimal, precision: Int = 28) raises -> BigDecimal:
    """Calculate the square root of a BigDecimal number.

    Args:
        x: The number to calculate the square root of.
        precision: The desired precision (number of significant digits) of the result.

    Returns:
        The square root of x with the specified precision.

    Raises:
        Error: If x is negative.
    """
    alias BUFFER_DIGITS = 9

    # Handle special cases
    if x.sign:
        raise Error(
            "Error in `sqrt`: Cannot compute square root of negative number"
        )

    if x.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, (x.scale + 1) // 2, False)

    # Initial guess
    # A decimal has coefficient and scale
    # Example 1:
    # 123456789012345678901234567890.12345 (sqrt ~= 351364182882014.4253111222382)
    # coef = 12345678_901234567_890123456_789012345, scale = 5
    # first three words = 12345678_901234567_890123456
    # number of integral digits = 30
    # Because it is even, no need to scale up by 10
    # not scale up by 10 => 12345678901234567890123456
    # sqrt(12345678901234567890123456) = 3513641828820
    # number of integral digits of the sqrt = (30 + 1) // 2 = 15
    # coef = 3513641828820, 13 digits, so scale = 13 - 15
    #
    # Example 2:
    # 12345678901.234567890123456789012345 (sqrt ~= 111111.1106111111099361111058)
    # coef = 12345678_901234567_890123456_789012345, scale = 24
    # first three words = 12345678_901234567_890123456
    # remaining number of words = 11
    # Because it is odd, need to scale up by 10
    # scale up by 10 => 123456789012345678901234560
    # sqrt(123456789012345678901234560) = 11111111061111
    # number of integral digits of the sqrt = (11 + 1) // 2 = 6
    # coef = 11111111061111, 14 digits, so scale = 14 - 6 => (111111.11061111)

    var guess: BigDecimal
    var ndigits_coef = x.coefficient.number_of_digits()
    var ndigits_int_part = x.coefficient.number_of_digits() - x.scale
    var ndigits_int_part_sqrt = (ndigits_int_part + 1) // 2
    var odd_ndigits_frac_part = x.scale % 2 == 1

    var value: UInt128
    if ndigits_coef <= 9:
        value = UInt128(x.coefficient.words[0]) * UInt128(
            1_000_000_000_000_000_000
        )
    elif ndigits_coef <= 18:
        value = (
            UInt128(x.coefficient.words[-1])
            * UInt128(1_000_000_000_000_000_000)
        ) + (UInt128(x.coefficient.words[-2]) * UInt128(1_000_000_000))
    else:  # ndigits_coef > 18
        value = (
            (
                UInt128(x.coefficient.words[-1])
                * UInt128(1_000_000_000_000_000_000)
            )
            + UInt128(x.coefficient.words[-2]) * UInt128(1_000_000_000)
            + UInt128(x.coefficient.words[-3])
        )
    if odd_ndigits_frac_part:
        value = value * UInt128(10)
    var sqrt_value = decimojo.utility.sqrt(value)
    var sqrt_value_biguint = BigUInt.from_scalar(sqrt_value)
    guess = BigDecimal(
        sqrt_value_biguint,
        sqrt_value_biguint.number_of_digits() - ndigits_int_part_sqrt,
        False,
    )

    # For Newton's method, we need extra precision during calculations
    # to ensure the final result has the desired precision
    var working_precision = precision + BUFFER_DIGITS

    # Newton's method iterations
    # x_{n+1} = (x_n + N/x_n) / 2
    var prev_guess = BigDecimal(BigUInt.ZERO, 0, False)
    var iteration_count = 0

    while guess != prev_guess and iteration_count < 100:
        prev_guess = guess
        var quotient = x.true_divide_fast(guess, working_precision)
        var sum = guess + quotient
        guess = sum.true_divide(BigDecimal(BigUInt(2), 0, 0), working_precision)
        iteration_count += 1

    # Round to the desired precision
    var ndigits_to_remove = guess.coefficient.number_of_digits() - precision
    if ndigits_to_remove > 0:
        var coefficient = guess.coefficient
        coefficient = coefficient.remove_trailing_digits_with_rounding(
            ndigits_to_remove,
            rounding_mode=RoundingMode.ROUND_HALF_UP,
            remove_extra_digit_due_to_rounding=True,
        )
        guess.coefficient = coefficient^
        guess.scale -= ndigits_to_remove

    # Remove trailing zeros for exact results
    # TODO: This can be done even earlier in the process
    # TODO: Implement a method that remove trailing zeros
    if guess.coefficient.ith_digit(0) == 0:
        var guess_coefficient_without_trailing_zeros = guess.coefficient.remove_trailing_digits_with_rounding(
            guess.coefficient.number_of_trailing_zeros(),
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
        )
        var x_coefficient_without_trailing_zeros = x.coefficient.remove_trailing_digits_with_rounding(
            x.coefficient.number_of_trailing_zeros(),
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
        )
        if (
            guess_coefficient_without_trailing_zeros
            * guess_coefficient_without_trailing_zeros
        ) == x_coefficient_without_trailing_zeros:
            var expected_ndigits_of_result = (
                x.coefficient.number_of_digits() + 1
            ) // 2
            guess.round_to_precision(
                precision=expected_ndigits_of_result,
                rounding_mode=RoundingMode.ROUND_DOWN,
                remove_extra_digit_due_to_rounding=False,
            )
            guess.scale = (x.scale + 1) // 2

    return guess^


# ===----------------------------------------------------------------------=== #
# Exponential functions
# ===----------------------------------------------------------------------=== #


fn exp(x: BigDecimal, precision: Int = 28) raises -> BigDecimal:
    """Calculate the natural exponential of x (e^x) to the specified precision.

    Args:
        x: The exponent value.
        precision: Desired precision in significant digits.

    Returns:
        The natural exponential of x (e^x) to the specified precision.

    Notes:
        Uses optimized algorithm combining:
        - Range reduction.
        - Taylor series.
        - Precision tracking.
    """
    # Extra working precision to ensure final result accuracy
    alias BUFFER_DIGITS = 5
    var working_precision = precision + BUFFER_DIGITS

    # Handle special cases
    if x.coefficient.is_zero():
        return BigDecimal(
            BigUInt.ONE, x.scale, x.sign
        )  # e^0 = 1, return with same scale and sign

    # For very large positive values, result will overflow BigDecimal capacity
    # Calculate rough estimate to detect overflow early
    # TODO: Use BigInt as scale can avoid overflow in this case
    if not x.sign and x.exponent() >= 20:  # x > 10^20
        raise Error("Error in `exp`: Result too large to represent")

    # For very large negative values, result will be effectively zero
    if x.sign and x.exponent() >= 20:  # x < -10^20
        return BigDecimal(BigUInt.ZERO, precision, False)

    # Handle negative x using identity: exp(-x) = 1/exp(x)
    if x.sign:
        var pos_result = exp(-x, precision + 2)
        return BigDecimal(BigUInt.ONE, 0, False).true_divide(
            pos_result, precision
        )

    # Range reduction for faster convergence
    # If x >= 0.1, use exp(x) = exp(x/2)²
    if x >= BigDecimal(BigUInt.ONE, 1, False):
        # var t_before_range_reduction = time.perf_counter_ns()
        var k = 0
        var threshold = BigDecimal(BigUInt.ONE, 0, False)
        while threshold.exponent() <= x.exponent() + 1:
            threshold.coefficient = (
                threshold.coefficient + threshold.coefficient
            )  # Multiply by 2
            k += 1

        # Calculate exp(x/2^k)
        var reduced_x = x.true_divide_fast(threshold, working_precision)

        # var t_after_range_reduction = time.perf_counter_ns()

        var result = exp_taylor_series(reduced_x, working_precision)

        # var t_after_taylor_series = time.perf_counter_ns()

        # Square result k times: exp(x) = exp(x/2^k)^(2^k)
        for _ in range(k):
            result = result * result
            result.round_to_precision(
                precision=working_precision,
                rounding_mode=RoundingMode.ROUND_HALF_UP,
                remove_extra_digit_due_to_rounding=False,
            )

        result.round_to_precision(
            precision=precision,
            rounding_mode=RoundingMode.ROUND_HALF_EVEN,
            remove_extra_digit_due_to_rounding=False,
        )

        # var t_after_scale_up = time.perf_counter_ns()

        # print(
        #     "TIME: range reduction: {}ns".format(
        #         t_after_range_reduction - t_before_range_reduction
        #     )
        # )
        # print(
        #     "TIME: taylor series: {}ns".format(
        #         t_after_taylor_series - t_after_range_reduction
        #     )
        # )
        # print(
        #     "TIME: scale up: {}ns".format(
        #         t_after_scale_up - t_after_taylor_series
        #     )
        # )

        return result^

    # For small values, use Taylor series directly
    var result = exp_taylor_series(x, working_precision)

    result.round_to_precision(
        precision=precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
    )

    return result^


fn exp_taylor_series(
    x: BigDecimal, minimum_precision: Int
) raises -> BigDecimal:
    """Calculate exp(x) using Taylor series for |x| <= 1.

    Args:
        x: The exponent value.
        minimum_precision: Minimum precision in significant digits.

    Returns:
        The natural exponential of x (e^x) to the specified precision + 9.
    """
    # Theoretical number of terms needed based on precision
    # For |x| ≤ 1, error after n terms is approximately |x|^(n+1)/(n+1)!
    # We need |x|^(n+1)/(n+1)! < 10^(-precision)
    # For x=1, we need approximately n ≈ precision * ln(10) ≈ precision * 2.3
    #
    # ZHU: About complexity:
    # In each loop, there are 2 mul (2 x 100ns) and 1 div (2000ns)
    # There are intotal 2.3 * precision iterations

    # print("DEBUG: exp_taylor_series")
    # print("DEBUG: x =", x)

    var max_number_of_terms = Int(minimum_precision * 2.5) + 1
    var result = BigDecimal(BigUInt.ONE, 0, False)
    var term = BigDecimal(BigUInt.ONE, 0, False)
    var n = BigUInt.ONE

    # Calculate Taylor series: 1 + x + x²/2! + x³/3! + ...
    for _ in range(1, max_number_of_terms):
        # Calculate next term: x^i/i! = x^{i-1} * x/i
        # We can use the previous term to calculate the next one
        var add_on = x.true_divide_fast(
            BigDecimal(n, 0, False), minimum_precision
        )
        term = term * add_on
        term.round_to_precision(
            precision=minimum_precision,
            rounding_mode=RoundingMode.ROUND_HALF_UP,
            remove_extra_digit_due_to_rounding=False,
        )
        n += BigUInt.ONE

        # Add term to result
        result += term

        # print("DEUBG: round {}, term {}, result {}".format(n, term, result))

        # Check if we've reached desired precision
        if term.exponent() < -minimum_precision:
            break

    result.round_to_precision(
        precision=minimum_precision,
        rounding_mode=RoundingMode.ROUND_HALF_UP,
        remove_extra_digit_due_to_rounding=False,
    )
    # print("DEBUG: final result", result)

    return result^
