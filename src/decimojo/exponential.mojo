# ===----------------------------------------------------------------------=== #
#
# DeciMojo: A fixed-point decimal arithmetic library in Mojo
# https://github.com/forFudan/DeciMojo
#
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
#
# ===----------------------------------------------------------------------=== #
#
# Implements exponential functions for the Decimal type
#
# ===----------------------------------------------------------------------=== #
#
# List of functions in this module:
#
# power(base: Decimal, exponent: Decimal): Raises base to the power of exponent (integer exponents only)
# power(base: Decimal, exponent: Int): Convenience method for integer exponents
# sqrt(x: Decimal): Computes the square root of x using Newton-Raphson method
#
# ===----------------------------------------------------------------------=== #

import math as builtin_math
import testing

import decimojo.special
import decimojo.utility


fn power(base: Decimal, exponent: Decimal) raises -> Decimal:
    """
    Raises base to the power of exponent and returns a new Decimal.

    Currently supports integer exponents only.

    Args:
        base: The base value.
        exponent: The power to raise base to.
            It must be an integer or effectively an integer (e.g., 2.0).

    Returns:
        A new Decimal containing the result of base^exponent

    Raises:
        Error: If exponent is not an integer or if the operation would overflow.
        Error: If zero is raised to a negative power.
    """
    # Check if exponent is an integer
    if not exponent.is_integer():
        raise Error("Power operation is only supported for integer exponents")

    # Convert exponent to integer
    var exp_value = Int(exponent)

    # Special cases
    if exp_value == 0:
        # x^0 = 1 (including 0^0 = 1 by convention)
        return Decimal.ONE()

    if exp_value == 1:
        # x^1 = x
        return base

    if base.is_zero():
        # 0^n = 0 for n > 0
        if exp_value > 0:
            return Decimal.ZERO()
        else:
            # 0^n is undefined for n < 0
            raise Error("Zero cannot be raised to a negative power")

    if base.coefficient() == 1 and base.scale() == 0:
        # 1^n = 1 for any n
        return Decimal.ONE()

    # Handle negative exponents: x^(-n) = 1/(x^n)
    var negative_exponent = exp_value < 0
    if negative_exponent:
        exp_value = -exp_value

    # Binary exponentiation for efficiency
    var result = Decimal.ONE()
    var current_base = base

    while exp_value > 0:
        if exp_value & 1:  # exp_value is odd
            result = result * current_base

        exp_value >>= 1  # exp_value = exp_value / 2

        if exp_value > 0:
            current_base = current_base * current_base

    # For negative exponents, take the reciprocal
    if negative_exponent:
        # For 1/x, use division
        result = Decimal.ONE() / result

    return result


fn power(base: Decimal, exponent: Int) raises -> Decimal:
    """
    Convenience method to raise base to an integer power.

    Args:
        base: The base value.
        exponent: The integer power to raise base to.

    Returns:
        A new Decimal containing the result.
    """
    return power(base, Decimal(exponent))


fn sqrt(x: Decimal) raises -> Decimal:
    """
    Computes the square root of a Decimal value using Newton-Raphson method.

    Args:
        x: The Decimal value to compute the square root of.

    Returns:
        A new Decimal containing the square root of x.

    Raises:
        Error: If x is negative.
    """
    # Special cases
    if x.is_negative():
        raise Error(
            "Error in sqrt: Cannot compute square root of a negative number"
        )

    if x.is_zero():
        return Decimal.ZERO()

    var x_coef: UInt128 = x.coefficient()
    var x_scale = x.scale()

    # Initial guess - a good guess helps converge faster
    # use floating point approach to quickly find a good guess

    var guess: Decimal

    # For numbers with zero scale (true integers)
    if x_scale == 0:
        var float_sqrt = builtin_math.sqrt(Float64(x_coef))
        guess = Decimal.from_uint128(UInt128(float_sqrt))
        # print("DEBUG: scale = 0")

    # For numbers with even scale
    elif x_scale % 2 == 0:
        var float_sqrt = builtin_math.sqrt(Float64(x_coef))
        guess = Decimal.from_uint128(
            UInt128(float_sqrt), scale=x_scale >> 1, sign=False
        )
        # print("DEBUG: scale is even")

    # For numbers with odd scale
    else:
        var float_sqrt = builtin_math.sqrt(Float64(x_coef)) * Float64(3.15625)
        guess = Decimal.from_uint128(
            UInt128(float_sqrt), scale=(x_scale + 1) >> 1, sign=False
        )
        # print("DEBUG: scale is odd")

    # print("DEBUG: initial guess", guess)
    testing.assert_false(guess.is_zero(), "Initial guess should not be zero")

    # Newton-Raphson iterations
    # x_n+1 = (x_n + S/x_n) / 2
    var prev_guess = Decimal.ZERO()
    var iteration_count = 0

    # Iterate until guess converges or max iterations reached
    # max iterations is set to 100 to avoid infinite loop
    # log2(1e18) ~= 60, so 100 iterations should be enough
    while guess != prev_guess and iteration_count < 100:
        prev_guess = guess
        var division_result = x / guess
        var sum_result = guess + division_result
        guess = sum_result / Decimal(2, 0, 0, 0, False)
        iteration_count += 1

        # print("------------------------------------------------------")
        # print("DEBUG: iteration_count", iteration_count)
        # print("DEBUG: prev guess", prev_guess)
        # print("DEBUG: new guess ", guess)

    # print("DEBUG: iteration_count", iteration_count)

    # If exact square root found remove trailing zeros after the decimal point
    # For example, sqrt(81) = 9, not 9.000000
    # For example, sqrt(100.0000) = 10.00 not 10.000000
    # Exact square means that the coefficient of guess after removing trailing zeros
    # is equal to the coefficient of x

    var guess_coef = guess.coefficient()

    # No need to do this if the last digit of the coefficient of guess is not zero
    if guess_coef % 10 == 0:
        var num_digits_x_ceof = decimojo.utility.number_of_digits(x_coef)
        var num_digits_x_sqrt_coef = (num_digits_x_ceof >> 1) + 1
        var num_digits_guess_coef = decimojo.utility.number_of_digits(
            guess_coef
        )
        var num_digits_to_decrease = num_digits_guess_coef - num_digits_x_sqrt_coef

        testing.assert_true(
            num_digits_to_decrease >= 0,
            "sqrt of x has fewer digits than expected",
        )
        for _ in range(num_digits_to_decrease):
            if guess_coef % 10 == 0:
                guess_coef //= 10
            else:
                break
        else:
            # print("DEBUG: guess", guess)
            # print("DEBUG: guess_coef after removing trailing zeros", guess_coef)
            if (guess_coef * guess_coef == x_coef) or (
                guess_coef * guess_coef == x_coef * 10
            ):
                var low = UInt32(guess_coef & 0xFFFFFFFF)
                var mid = UInt32((guess_coef >> 32) & 0xFFFFFFFF)
                var high = UInt32((guess_coef >> 64) & 0xFFFFFFFF)
                return Decimal(
                    low,
                    mid,
                    high,
                    guess.scale() - num_digits_to_decrease,
                    False,
                )

    return guess


fn exp(x: Decimal) raises -> Decimal:
    """
    Calculates e^x for any Decimal value using optimized range reduction.
    x should be no greater than 66 to avoid overflow.
    A special algorithm is used to reduce the number of multiplications
    and improve accuracy. This function can achieve high accuracy at a
    high speed for a wide range of input values.

    Args:
        x: The exponent.

    Returns:
        A Decimal approximation of e^x.

    Notes:
        Because ln(2^96-1) ~= 66.54212933375474970405428366,
        the x value should be no greater than 66 to avoid overflow.
    """

    # Handle special cases
    if x.is_zero():
        return Decimal.ONE()

    if x.is_negative():
        return Decimal.ONE() / exp(-x)

    # For x < 1, use Taylor series expansion
    # For x > 1, use optimized range reduction with smaller chunks
    # Yuhao's notes:
    # e^50 is more accurate than (e^2)^25 if e^2 needs to be approximated
    #   because estimating e^x would introduce errors
    # e^50 is less accurate than (e^2)^25 if e^2 is precomputed
    #   because too many multiplications would introduce errors
    # So we need to find a way to reduce both the number of multiplications
    #   and the error introduced by approximating e^x
    # This helps improve accuracy as well as speed.
    # My solution is to factorize x into a combination of integers and
    #   a fractional part smaller than 1.
    # Then use precomputed e^integer values to calculate e^x
    # For example, e^59.12 = (e^50)^1 * (e^5)^1 * (e^2)^2 * e^0.12
    # This way, we just need to do 4 multiplications instead of 59.
    # The fractional part is then calculated using the series expansion.
    # Because the fractional part is <1, the series converges quickly.

    var exp_chunk: Decimal
    var remainder: Decimal
    var num_chunks: Int
    var x_int = Int(x)

    if x.is_one():
        return Decimal.E()

    elif x_int < 1:
        return exp_series(x)

        # TODO: Improve from float so that exact float can be stored in Decimal
        # if x < Decimal(0.01):
        #     return exp_series(x)

        # elif x < Decimal(0.05):
        #     # chunk = 0.01
        #     num_chunks = (x * 100).round(0, RoundingMode.ROUND_DOWN)
        #     # Use precise e^(chunk) = e^0.01
        #     exp_chunk = Decimal.from_words(
        #         0xDB32A629, 0xBC6A8DA6, 0x20A2F06C, 0x1C0000
        #     )
        #     remainder = x - num_chunks * Decimal("0.01")

        # elif x < Decimal(0.1):
        #     # chunk = 0.05
        #     num_chunks = (x * 20).round(0, RoundingMode.ROUND_DOWN)
        #     # Use precise e^(chunk) = e^0.05
        #     exp_chunk = Decimal.from_words(
        #         0x22877AAB, 0x47F300D6, 0x21F7E923, 0x1C0000
        #     )
        #     remainder = x - num_chunks * Decimal("0.05")

        # elif x < Decimal(0.2):
        #     # chunk = 0.1
        #     num_chunks = (x * 10).round(0, RoundingMode.ROUND_DOWN)
        #     # Use precise e^(chunk) = e^0.1
        #     exp_chunk = Decimal.from_words(
        #         0x1079E8F9, 0x2C369C6C, 0x23B5C273, 0x1C0000
        #     )
        #     remainder = x - num_chunks * Decimal("0.1")

        # elif x < Decimal(0.5):
        #     # chunk = 0.2
        #     num_chunks = (x * 5).round(0, RoundingMode.ROUND_DOWN)
        #     # Use precise e^(chunk) = e^0.2
        #     exp_chunk = Decimal.from_words(
        #         0x716CF2CA, 0xF042F48C, 0x277734F1, 0x1C0000
        #     )
        #     remainder = x - num_chunks * Decimal("0.2")

        # else:
        #     # chunk = 0.5
        #     num_chunks = Decimal.ONE()
        #     # Use precise e^(chunk) = e^0.5
        #     exp_chunk = Decimal.from_words(
        #         0x8E99DD66, 0xC210E35C, 0x3545E717, 0x1C0000
        #     )
        #     remainder = x - Decimal("0.5")

    elif x_int < 2:  # 1 < x < 2
        # chunk = 1
        num_chunks = 1
        # Use precise e^(chunk) = e^1
        exp_chunk = Decimal.E()
        remainder = x - num_chunks

    elif x_int < 4:  # 2 <= x < 4
        # chunk = 2
        num_chunks = x_int >> 1
        # Use precise e^(chunk) = e^2
        exp_chunk = Decimal.from_words(
            0xE4DFDCAE, 0x89F7E295, 0xEEC0D6E9, 0x1C0000
        )
        remainder = x - (num_chunks << 1)

    elif x_int < 8:
        # chunk = 4
        num_chunks = x_int >> 2
        # Use precise e^(chunk) = e^4
        exp_chunk = Decimal.from_words(
            0x7121EFD3, 0xFB318FB5, 0xB06A87FB, 0x1B0000
        )
        remainder = x - (num_chunks << 2)

    elif x_int < 16:
        # chunk = 8
        num_chunks = x_int >> 3
        # Use precise e^(chunk) = e^8
        exp_chunk = Decimal.from_words(
            0x1E892E63, 0xD1BF8B5C, 0x6051E812, 0x190000
        )
        remainder = x - (num_chunks << 3)

    elif x_int < 32:
        # chunk = 16
        num_chunks = x_int >> 4
        # Use precise e^(chunk) = e^16
        exp_chunk = Decimal.from_words(
            0xB46A97D, 0x90655BBD, 0x1CB66B18, 0x150000
        )
        remainder = x - (num_chunks << 4)

    else:
        # chunk = 32
        num_chunks = x_int >> 5
        # Use precise e^(chunk) = e^32
        exp_chunk = Decimal.from_words(
            0x18420EB, 0xCC2501E6, 0xFF24A138, 0xF0000
        )
        remainder = x - (num_chunks << 5)

    # Calculate e^(chunk * num_chunks) = (e^chunk)^num_chunks
    var exp_main = power(exp_chunk, num_chunks)

    # Calculate e^remainder by calling exp() again
    # If it is <1, then use Taylor's series
    var exp_remainder = exp(remainder)

    # Combine: e^x = e^(main+remainder) = e^main * e^remainder
    return exp_main * exp_remainder


fn exp_series(x: Decimal) raises -> Decimal:
    """
    Calculates e^x using Taylor series expansion.
    Do not use this function for values larger than 1, but `exp()` instead.

    Args:
        x: The exponent.

    Returns:
        A Decimal approximation of e^x.

    Notes:

    Sum terms of Taylor series: e^x = 1 + x + x²/2! + x³/3! + ...
    Because ln(2^96-1) ~= 66.54212933375474970405428366,
    the x value should be no greater than 66 to avoid overflow.
    """

    var max_terms = 500

    # For x=0, e^0 = 1
    if x.is_zero():
        return Decimal.ONE()

    # For x with very small magnitude, just use 1+x approximation
    if abs(x) == Decimal("1e-28"):
        return Decimal.ONE() + x

    # Initialize result and term
    var result = Decimal.ONE()
    var term = Decimal.ONE()
    var term_add_on: Decimal

    # Calculate terms iteratively
    # term[x] = x^i / i!
    # term[x-1] = x^{i-1} / (i-1)!
    # => term[x] / term[x-1] = x / i

    for i in range(1, max_terms + 1):
        # print("DEBUG: i =", i)
        term_add_on = x / Decimal(i)
        # print("DEBUG: term_add_on", i, "=", term_add_on)

        term = term * term_add_on
        # Check for convergence
        if term.is_zero():
            break
        # print("DEBUG: term", i, "=", term)

        result = result + term
        # print("DEBUG: result", i, "=", result)

    return result
