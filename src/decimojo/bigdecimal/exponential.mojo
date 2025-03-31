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

"""Implements exponential functions for the BigDecimal type."""

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode


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
    alias BUFFER_DIGITS = 0

    # Handle special cases
    if x.sign:
        raise Error(
            "Error in `sqrt`: Cannot compute square root of negative number"
        )

    if x.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, (x.scale + 1) // 2, False)

    # Initial guess
    # For numbers close to 1, start with 1
    # Otherwise, use a simple approximation based on the exponent
    var exponent = x.exponent()
    var guess: BigDecimal

    if exponent >= -1 and exponent <= 1:
        # 0.1 <= x < 100
        # Start with 1 for numbers around 1
        guess = BigDecimal(BigUInt.ONE, 0, False)
    else:
        # For numbers far from 1, use a better initial guess
        # Start with 10^(exponent/2)
        var exp_half = exponent // 2
        guess = BigDecimal(
            BigUInt.ONE.scale_up_by_power_of_10(exp_half), 0, False
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
        var quotient = x.true_divide(guess, working_precision)
        var sum = guess + quotient
        guess = sum.true_divide(BigDecimal(BigUInt(2), 0, 0), working_precision)
        iteration_count += 1

    print("Newton's method iterations:", iteration_count)
    # Round to the desired precision
    var ndigits_to_remove = guess.coefficient.number_of_digits() - precision
    if ndigits_to_remove > 0:
        var coefficient = guess.coefficient
        coefficient = coefficient.remove_trailing_digits_with_rounding(
            ndigits_to_remove,
            rounding_mode=RoundingMode.ROUND_HALF_UP,
            remove_extra_digit_due_to_rounding=True,
        )
        return BigDecimal(coefficient, guess.scale - ndigits_to_remove, False)
    else:
        return guess^
