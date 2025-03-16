# ===----------------------------------------------------------------------=== #
# DeciMojo: A fixed-point decimal arithmetic library in Mojo
# https://github.com/forfudan/decimojo
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

import decimojo.constants
import decimojo.special
import decimojo.utility


fn power(base: Decimal, exponent: Decimal) raises -> Decimal:
    """Raises a Decimal base to an arbitrary Decimal exponent power.

    This function handles both integer and non-integer exponents using the
    identity x^y = e^(y * ln(x)).

    Args:
        base: The base Decimal value (must be positive).
        exponent: The exponent Decimal value (can be any value).

    Returns:
        A new Decimal containing the result of base^exponent.

    Raises:
        Error: If the base is negative or the exponent is negative and not an integer.
        Error: If an error occurs in calling the power() function with an integer exponent.
        Error: If an error occurs in calling the sqrt() function with a Decimal exponent.
        Error: If an error occurs in calling the ln() function with a Decimal base.
        Error: If an error occurs in calling the exp() function with a Decimal exponent.
    """

    # CASE: If the exponent is integer
    if exponent.is_integer():
        try:
            return power(base, Int(exponent))
        except e:
            raise Error("Error in `power()` with Decimal exponent: ", e)

    # CASE: For negative bases, only integer exponents are supported
    if base.is_negative():
        raise Error(
            "Negative base with non-integer exponent results in a complex"
            " number"
        )

    # CASE: If the exponent is simple fractions
    # 0.5
    if exponent == decimojo.constants.M0D5():
        try:
            return sqrt(base)
        except e:
            raise Error("Error in `power()` with Decimal exponent: ", e)
    # -0.5
    if exponent == Decimal(5, 0, 0, 0x80010000):
        try:
            return Decimal.ONE() / sqrt(base)
        except e:
            raise Error("Error in `power()` with Decimal exponent: ", e)

    # GENERAL CASE
    # Use the identity x^y = e^(y * ln(x))
    try:
        var ln_base = ln(base)
        var product = exponent * ln_base
        return exp(product)
    except e:
        raise Error("Error in `power()` with Decimal exponent: ", e)


fn power(base: Decimal, exponent: Int) raises -> Decimal:
    """Raises a Decimal base to an integer power.

    Args:
        base: The base value.
        exponent: The integer power to raise base to.

    Returns:
        A new Decimal containing the result.
    """

    # Special cases
    if exponent == 0:
        # x^0 = 1 (including 0^0 = 1 by convention)
        return Decimal.ONE()

    if exponent == 1:
        # x^1 = x
        return base

    if base.is_zero():
        # 0^n = 0 for n > 0
        if exponent > 0:
            return Decimal.ZERO()
        else:
            # 0^n is undefined for n < 0
            raise Error("Zero cannot be raised to a negative power")

    if base.coefficient() == 1 and base.scale() == 0:
        # 1^n = 1 for any n
        return Decimal.ONE()

    # Handle negative exponents: x^(-n) = 1/(x^n)
    var negative_exponent = exponent < 0
    var abs_exp = exponent
    if negative_exponent:
        abs_exp = -exponent

    # Binary exponentiation for efficiency
    var result = Decimal.ONE()
    var current_base = base

    while abs_exp > 0:
        if abs_exp & 1:  # exp_value is odd
            result = result * current_base

        abs_exp >>= 1  # exp_value = exp_value / 2

        if abs_exp > 0:
            current_base = current_base * current_base

    # For negative exponents, take the reciprocal
    if negative_exponent:
        # For 1/x, use division
        result = Decimal.ONE() / result

    return result


fn sqrt(x: Decimal) raises -> Decimal:
    """Computes the square root of a Decimal value using Newton-Raphson method.

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
    """Calculates e^x for any Decimal value using optimized range reduction.
    x should be no greater than 66 to avoid overflow.

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
    var num_chunks: Int = 1
    var x_int = Int(x)

    if x.is_one():
        return decimojo.constants.E()

    elif x_int < 1:
        var M0D5 = decimojo.constants.M0D5()
        var M0D25 = decimojo.constants.M0D25()

        if x < M0D25:  # 0 < x < 0.25
            return exp_series(x)

        elif x < M0D5:  # 0.25 <= x < 0.5
            exp_chunk = decimojo.constants.E0D25()
            remainder = x - M0D25

        else:  # 0.5 <= x < 1
            exp_chunk = decimojo.constants.E0D5()
            remainder = x - M0D5

    elif x_int == 1:  # 1 <= x < 2, chunk = 1
        exp_chunk = decimojo.constants.E()
        remainder = x - x_int

    elif x_int == 2:  # 2 <= x < 3, chunk = 2
        exp_chunk = decimojo.constants.E2()
        remainder = x - x_int

    elif x_int == 3:  # 3 <= x < 4, chunk = 3
        exp_chunk = decimojo.constants.E3()
        remainder = x - x_int

    elif x_int == 4:  # 4 <= x < 5, chunk = 4
        exp_chunk = decimojo.constants.E4()
        remainder = x - x_int

    elif x_int == 5:  # 5 <= x < 6, chunk = 5
        exp_chunk = decimojo.constants.E5()
        remainder = x - x_int

    elif x_int == 6:  # 6 <= x < 7, chunk = 6
        exp_chunk = decimojo.constants.E6()
        remainder = x - x_int

    elif x_int == 7:  # 7 <= x < 8, chunk = 7
        exp_chunk = decimojo.constants.E7()
        remainder = x - x_int

    elif x_int == 8:  # 8 <= x < 9, chunk = 8
        exp_chunk = decimojo.constants.E8()
        remainder = x - x_int

    elif x_int == 9:  # 9 <= x < 10, chunk = 9
        exp_chunk = decimojo.constants.E9()
        remainder = x - x_int

    elif x_int == 10:  # 10 <= x < 11, chunk = 10
        exp_chunk = decimojo.constants.E10()
        remainder = x - x_int

    elif x_int == 11:  # 11 <= x < 12, chunk = 11
        exp_chunk = decimojo.constants.E11()
        remainder = x - x_int

    elif x_int == 12:  # 12 <= x < 13, chunk = 12
        exp_chunk = decimojo.constants.E12()
        remainder = x - x_int

    elif x_int == 13:  # 13 <= x < 14, chunk = 13
        exp_chunk = decimojo.constants.E13()
        remainder = x - x_int

    elif x_int == 14:  # 14 <= x < 15, chunk = 14
        exp_chunk = decimojo.constants.E14()
        remainder = x - x_int

    elif x_int == 15:  # 15 <= x < 16, chunk = 15
        exp_chunk = decimojo.constants.E15()
        remainder = x - x_int

    elif x_int < 32:  # 16 <= x < 32, chunk = 16
        num_chunks = x_int >> 4
        exp_chunk = decimojo.constants.E16()
        remainder = x - (num_chunks << 4)

    else:  # chunk = 32
        num_chunks = x_int >> 5
        exp_chunk = decimojo.constants.E32()
        remainder = x - (num_chunks << 5)

    # Calculate e^(chunk * num_chunks) = (e^chunk)^num_chunks
    var exp_main = power(exp_chunk, num_chunks)

    # Calculate e^remainder by calling exp() again
    # If it is <1, then use Taylor's series
    var exp_remainder = exp(remainder)

    # Combine: e^x = e^(main+remainder) = e^main * e^remainder
    return exp_main * exp_remainder


fn exp_series(x: Decimal) raises -> Decimal:
    """Calculates e^x using Taylor series expansion.
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
    if abs(x) == Decimal(1, 0, 0, 28 << 16):
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
        term_add_on = x / Decimal(i)

        term = term * term_add_on
        # Check for convergence
        if term.is_zero():
            break

        result = result + term

    return result


fn ln(x: Decimal) raises -> Decimal:
    """Calculates the natural logarithm (ln) of a Decimal value.

    Args:
        x: The Decimal value to compute the natural logarithm of.

    Returns:
        A Decimal approximation of ln(x).

    Raises:
        Error: If x is less than or equal to zero.

    Notes:
        This implementation uses range reduction to improve accuracy and performance.
    """

    # print("DEBUG: ln(x) called with x =", x)

    # Handle special cases
    if x.is_negative() or x.is_zero():
        raise Error(
            "Error in ln(): Cannot compute logarithm of a non-positive number"
        )

    if x.is_one():
        return Decimal.ZERO()

    # Special cases for common values
    if x == decimojo.constants.E():
        return Decimal.ONE()

    # For values close to 1, use series expansion directly
    if Decimal(95, 0, 0, 2 << 16) <= x <= Decimal(105, 0, 0, 2 << 16):
        return ln_series(x - Decimal.ONE())

    # For all other values, use range reduction
    # ln(x) = ln(m * 2^p * 10^q) = ln(m) + p*ln(2) + q*ln(10), where 1 <= m < 2

    var m: Decimal = x
    var p: Int = 0
    var q: Int = 0

    # Step 1: handle powers of 10 for large values
    if x >= decimojo.constants.M10():
        # Repeatedly divide by 10 until m < 10
        while m >= decimojo.constants.M10():
            m = m / decimojo.constants.M10()
            q += 1
    elif x < Decimal(1, 0, 0, 1 << 16):
        # Repeatedly multiply by 10 until m >= 0.1
        while m < Decimal(1, 0, 0, 1 << 16):
            m = m * decimojo.constants.M10()
            q -= 1

    # Now 0.1 <= m < 10
    # Step 2: normalize to [0.5, 2) using powers of 2
    if m >= decimojo.constants.M2():
        # Repeatedly divide by 2 until m < 2
        while m >= decimojo.constants.M2():
            m = m / decimojo.constants.M2()
            p += 1
    elif m < Decimal(5, 0, 0, 1 << 16):
        # Repeatedly multiply by 2 until m >= 0.5
        while m < Decimal(5, 0, 0, 1 << 16):
            m = m * decimojo.constants.M2()
            p -= 1

    # Now 0.5 <= m < 2
    var ln_m: Decimal

    # Use precomputed values and series expansion for accuracy and performance
    if m < Decimal.ONE():
        # For 0.5 <= m < 1
        if m >= Decimal(9, 0, 0, 1 << 16):
            ln_m = (
                ln_series(
                    (m - Decimal(9, 0, 0, 1 << 16))
                    * decimojo.constants.INV0D9()
                )
                + decimojo.constants.LN0D9()
            )
        elif m >= Decimal(8, 0, 0, 1 << 16):
            ln_m = (
                ln_series(
                    (m - Decimal(8, 0, 0, 1 << 16))
                    * decimojo.constants.INV0D8()
                )
                + decimojo.constants.LN0D8()
            )
        elif m >= Decimal(7, 0, 0, 1 << 16):
            ln_m = (
                ln_series(
                    (m - Decimal(7, 0, 0, 1 << 16))
                    * decimojo.constants.INV0D7()
                )
                + decimojo.constants.LN0D7()
            )
        elif m >= Decimal(6, 0, 0, 1 << 16):
            ln_m = (
                ln_series(
                    (m - Decimal(6, 0, 0, 1 << 16))
                    * decimojo.constants.INV0D6()
                )
                + decimojo.constants.LN0D6()
            )
        else:  # 0.5 <= m < 0.6
            ln_m = (
                ln_series(
                    (m - Decimal(5, 0, 0, 1 << 16))
                    * decimojo.constants.INV0D5()
                )
                + decimojo.constants.LN0D5()
            )

    else:
        # For 1 < m < 2
        if m < Decimal(11, 0, 0, 1 << 16):  # 1 < m < 1.1
            ln_m = ln_series(m - Decimal.ONE())
        elif m < Decimal(12, 0, 0, 1 << 16):  # 1.1 <= m < 1.2
            ln_m = (
                ln_series(
                    (m - Decimal(11, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D1()
                )
                + decimojo.constants.LN1D1()
            )
        elif m < Decimal(13, 0, 0, 1 << 16):  # 1.2 <= m < 1.3
            ln_m = (
                ln_series(
                    (m - Decimal(12, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D2()
                )
                + decimojo.constants.LN1D2()
            )
        elif m < Decimal(14, 0, 0, 1 << 16):  # 1.3 <= m < 1.4
            ln_m = (
                ln_series(
                    (m - Decimal(13, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D3()
                )
                + decimojo.constants.LN1D3()
            )
        elif m < Decimal(15, 0, 0, 1 << 16):  # 1.4 <= m < 1.5
            ln_m = (
                ln_series(
                    (m - Decimal(14, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D4()
                )
                + decimojo.constants.LN1D4()
            )
        elif m < Decimal(16, 0, 0, 1 << 16):  # 1.5 <= m < 1.6
            ln_m = (
                ln_series(
                    (m - Decimal(15, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D5()
                )
                + decimojo.constants.LN1D5()
            )
        elif m < Decimal(17, 0, 0, 1 << 16):  # 1.6 <= m < 1.7
            ln_m = (
                ln_series(
                    (m - Decimal(16, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D6()
                )
                + decimojo.constants.LN1D6()
            )
        elif m < Decimal(18, 0, 0, 1 << 16):  # 1.7 <= m < 1.8
            ln_m = (
                ln_series(
                    (m - Decimal(17, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D7()
                )
                + decimojo.constants.LN1D7()
            )
        elif m < Decimal(19, 0, 0, 1 << 16):  # 1.8 <= m < 1.9
            ln_m = (
                ln_series(
                    (m - Decimal(18, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D8()
                )
                + decimojo.constants.LN1D8()
            )
        else:  # 1.9 <= m < 2
            ln_m = (
                ln_series(
                    (m - Decimal(19, 0, 0, 1 << 16))
                    * decimojo.constants.INV1D9()
                )
                + decimojo.constants.LN1D9()
            )

    # Combine result: ln(x) = ln(m) + p*ln(2) + q*ln(10)
    var result = ln_m

    # Add power of 2 contribution
    if p != 0:
        result = result + Decimal(p) * decimojo.constants.LN2()

    # Add power of 10 contribution
    if q != 0:
        result = result + Decimal(q) * decimojo.constants.LN10()

    return result


fn ln_series(z: Decimal) raises -> Decimal:
    """Calculates ln(1+z) using Taylor series expansion at 1.
    For best accuracy, |z| should be small (< 0.5).

    Args:
        z: The value to compute ln(1+z) for.

    Returns:
        A Decimal approximation of ln(1+z).

    Notes:
        Uses the series: ln(1+z) = z - z²/2 + z³/3 - z⁴/4 + ...
        This series converges fastest when |z| is small.
    """

    # print("DEBUG: ln_series(z) called with z =", z)

    var max_terms = 500

    # For z=0, ln(1+z) = ln(1) = 0
    if z.is_zero():
        return Decimal.ZERO()

    # For z with very small magnitude, just use z approximation
    if abs(z) == Decimal(1, 0, 0, 28 << 16):
        return z

    # Initialize result and term
    var result = Decimal.ZERO()
    var term = z
    var neg: Bool = False

    # Calculate terms iteratively
    # term[i] = (-1)^(i+1) * z^i / i

    for i in range(1, max_terms + 1):
        if neg:
            result = result - term
        else:
            result = result + term

        neg = not neg  # Alternate sign

        if i <= 20:
            term = term * z * decimojo.constants.N_DIVIDE_NEXT(i)
        else:
            term = term * z * Decimal(i) / Decimal(i + 1)

        # Check for convergence
        if term.is_zero():
            # print("DEBUG: i = ", i)
            break

    # print("DEBUG: result =", result)

    return result
