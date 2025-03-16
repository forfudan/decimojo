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

    return power(base, exp_value)


fn power(base: Decimal, exponent: Int) raises -> Decimal:
    """
    Convenience method to raise base to an integer power.

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
        return Decimal.E()

    elif x_int < 1:
        var d05 = Decimal(5, 0, 0, scale=1, sign=False)  # 0.5
        var d025 = Decimal(25, 0, 0, scale=2, sign=False)  # 0.25

        if x < d025:  # 0 < x < 0.25
            return exp_series(x)

        elif x < d05:  # 0.25 <= x < 0.5
            exp_chunk = Decimal.E025()
            remainder = x - d025

        else:  # 0.5 <= x < 1
            exp_chunk = Decimal.E05()
            remainder = x - d05

    elif x_int == 1:  # 1 <= x < 2, chunk = 1
        exp_chunk = Decimal.E()
        remainder = x - x_int

    elif x_int == 2:  # 2 <= x < 3, chunk = 2
        exp_chunk = Decimal.E2()
        remainder = x - x_int

    elif x_int == 3:  # 3 <= x < 4, chunk = 3
        exp_chunk = Decimal.E3()
        remainder = x - x_int

    elif x_int == 4:  # 4 <= x < 5, chunk = 4
        exp_chunk = Decimal.E4()
        remainder = x - x_int

    elif x_int == 5:  # 5 <= x < 6, chunk = 5
        exp_chunk = Decimal.E5()
        remainder = x - x_int

    elif x_int == 6:  # 6 <= x < 7, chunk = 6
        exp_chunk = Decimal.E6()
        remainder = x - x_int

    elif x_int == 7:  # 7 <= x < 8, chunk = 7
        exp_chunk = Decimal.E7()
        remainder = x - x_int

    elif x_int == 8:  # 8 <= x < 9, chunk = 8
        exp_chunk = Decimal.E8()
        remainder = x - x_int

    elif x_int == 9:  # 9 <= x < 10, chunk = 9
        exp_chunk = Decimal.E9()
        remainder = x - x_int

    elif x_int == 10:  # 10 <= x < 11, chunk = 10
        exp_chunk = Decimal.E10()
        remainder = x - x_int

    elif x_int == 11:  # 11 <= x < 12, chunk = 11
        exp_chunk = Decimal.E11()
        remainder = x - x_int

    elif x_int == 12:  # 12 <= x < 13, chunk = 12
        exp_chunk = Decimal.E12()
        remainder = x - x_int

    elif x_int == 13:  # 13 <= x < 14, chunk = 13
        exp_chunk = Decimal.E13()
        remainder = x - x_int

    elif x_int == 14:  # 14 <= x < 15, chunk = 14
        exp_chunk = Decimal.E14()
        remainder = x - x_int

    elif x_int == 15:  # 15 <= x < 16, chunk = 15
        exp_chunk = Decimal.E15()
        remainder = x - x_int

    elif x_int < 32:  # 16 <= x < 32, chunk = 16
        num_chunks = x_int >> 4
        exp_chunk = Decimal.E16()
        remainder = x - (num_chunks << 4)

    else:  # chunk = 32
        num_chunks = x_int >> 5
        exp_chunk = Decimal.E32()
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
        term_add_on = x / Decimal(i)

        term = term * term_add_on
        # Check for convergence
        if term.is_zero():
            break

        result = result + term

    return result


fn ln(x: Decimal) raises -> Decimal:
    """
    Calculates the natural logarithm (ln) of a Decimal value.

    Args:
        x: The Decimal value to compute the natural logarithm of.

    Returns:
        A Decimal approximation of ln(x).

    Raises:
        Error: If x is less than or equal to zero.

    Notes:
        This implementation uses range reduction to improve accuracy and performance.
    """

    print("DEBUG: ln(x) called with x =", x)
    # Handle special cases
    if x.is_negative() or x.is_zero():
        raise Error(
            "Error in ln(): Cannot compute logarithm of a non-positive number"
        )

    if x.is_one():
        return Decimal.ZERO()

    # Special cases for common values
    if x == Decimal.E():
        return Decimal.ONE()

    # For values close to 1, use series expansion directly
    if Decimal("0.95") <= x <= Decimal("1.05"):
        return ln_series(x - Decimal.ONE())

    # For all other values, use range reduction
    # Compute ln(x) as ln(m * 2^p) = ln(m) + p*ln(2)
    # where 1 <= m < 2

    var m = x
    var p = 0

    # Normalize m to range [0.5, 1) or [1, 2)
    if x >= Decimal("2"):
        # Repeatedly divide by 2 until m < 2
        while m >= Decimal("2"):
            m = m / Decimal("2")
            p += 1
        print("DEBUG: m =", m, "p =", p)
    elif x < Decimal("0.5"):
        # Repeatedly multiply by 2 until m >= 0.5
        while m < Decimal("0.5"):
            m = m * Decimal("2")
            p -= 1

    # Now 0.5 <= m < 2
    var ln_m: Decimal

    # Use precomputed values and series expansion for accuracy and performance
    if m < Decimal.ONE():
        # For 0.5 <= m < 1
        if m >= Decimal("0.9"):
            ln_m = ln_series((m - Decimal("0.9")) * INV0D9()) + LN0D9()
        elif m >= Decimal("0.8"):
            ln_m = ln_series((m - Decimal("0.8")) * INV0D8()) + LN0D8()
        elif m >= Decimal("0.7"):
            ln_m = ln_series((m - Decimal("0.7")) * INV0D7()) + LN0D7()
        elif m >= Decimal("0.6"):
            ln_m = ln_series((m - Decimal("0.6")) * INV0D6()) + LN0D6()
        else:  # 0.5 <= m < 0.6
            ln_m = ln_series((m - Decimal("0.5")) * INV0D5()) + LN0D5()

        return ln_m

    else:
        print("DEBUG: m =", m)
        # For 1 < m < 2
        if m < Decimal("1.1"):  # 1 < m < 1.1
            ln_m = ln_series(m - Decimal("1"))
        elif m < Decimal("1.2"):  # 1.1 <= m < 1.2
            ln_m = ln_series((m - Decimal("1.1")) * INV1D1()) + LN1D1()
        elif m < Decimal("1.3"):  # 1.2 <= m < 1.3
            ln_m = ln_series((m - Decimal("1.2")) * INV1D2())
            print("DEBUG: ln_m =", ln_m)
            ln_m = ln_m + LN1D2()
            print("DEBUG: ln_1.2 =", LN1D2())
            print("DEBUG: ln_m =", ln_m)
        elif m < Decimal("1.4"):  # 1.3 <= m < 1.4
            ln_m = ln_series((m - Decimal("1.3")) * INV1D3()) + LN1D3()
        elif m < Decimal("1.5"):  # 1.4 <= m < 1.5
            ln_m = ln_series((m - Decimal("1.4")) * INV1D4()) + LN1D4()
        elif m < Decimal("1.6"):  # 1.5 <= m < 1.6
            ln_m = ln_series((m - Decimal("1.5")) * INV1D5()) + LN1D5()
        elif m < Decimal("1.7"):  # 1.6 <= m < 1.7
            ln_m = ln_series((m - Decimal("1.6")) * INV1D6()) + LN1D6()
        elif m < Decimal("1.8"):  # 1.7 <= m < 1.8
            ln_m = ln_series((m - Decimal("1.7")) * INV1D7()) + LN1D7()
        elif m < Decimal("1.9"):  # 1.8 <= m < 1.9
            ln_m = ln_series((m - Decimal("1.8")) * INV1D8()) + LN1D8()
        else:  # 1.9 <= m < 2
            ln_m = ln_series((m - Decimal("1.9")) * INV1D9()) + LN1D9()

        # Combine result: ln(x) = ln(m) + p*ln(2)
        if p != 0:
            print("DEBUG: ln_m =", ln_m)
            print("DEBUG: LN2() =", LN2())
            return ln_m + Decimal(p) * LN2()
        else:
            print("DEBUG: ln_m =", ln_m)
            return ln_m


fn ln_series(z: Decimal) raises -> Decimal:
    """
    Calculates ln(1+z) using Taylor series expansion.
    For best accuracy, |z| should be small (< 0.5).

    Args:
        z: The value to compute ln(1+z) for.

    Returns:
        A Decimal approximation of ln(1+z).

    Notes:
        Uses the series: ln(1+z) = z - z²/2 + z³/3 - z⁴/4 + ...
        This series converges fastest when |z| is small.
    """

    print("DEBUG: ln_series(z) called with z =", z)

    var max_terms = 500

    # For z=0, ln(1+z) = ln(1) = 0
    if z.is_zero():
        return Decimal.ZERO()

    # For z with very small magnitude, just use z approximation
    if abs(z) == Decimal("1e-28"):
        return z

    # Initialize result and term
    var result = Decimal.ZERO()
    var term = z
    var neg = False

    # Calculate terms iteratively
    # term[i] = (-1)^(i+1) * z^i / i

    for i in range(1, max_terms + 1):
        if neg:
            result = result - term
        else:
            result = result + term

        neg = not neg
        term = term * z * Decimal(i) / Decimal(i + 1)
        print("DEBUG: term", i, "=", term)
        print("DEBUG: result", i, "=", result)

        # Check for convergence
        if term.is_zero():
            break

    print("DEBUG: ln_series result =", result)
    return result


# ===----------------------------------------------------------------------=== #
#
# Useful constants for exponential functions
#
# ===----------------------------------------------------------------------=== #


# Define all inverse constants needed
@always_inline
fn INV0D5() -> Decimal:
    """Returns 1/0.5 = 2.0."""
    return Decimal(0x20000000, 0x0, 0x0, 0x1C0000)


@always_inline
fn INV0D6() -> Decimal:
    """Returns 1/0.6 = 1.66666666666666666666666666666667..."""
    return Decimal(0x1AAAAAAA, 0xAAAAAAAA, 0xAAAAAAAA, 0x1C0000)


@always_inline
fn INV0D7() -> Decimal:
    """Returns 1/0.7 = 1.42857142857142857142857142857143..."""
    return Decimal(0x16DB6DB6, 0xDB6DB6DB, 0x6DB6DB6D, 0x1C0000)


@always_inline
fn INV0D8() -> Decimal:
    """Returns 1/0.8 = 1.25."""
    return Decimal(0x14000000, 0x0, 0x0, 0x1C0000)


@always_inline
fn INV0D9() -> Decimal:
    """Returns 1/0.9 = 1.11111111111111111111111111111111..."""
    return Decimal(0x11C71C71, 0xC71C71C7, 0x1C71C71C, 0x1C0000)


@always_inline
fn INV1D1() -> Decimal:
    """Returns 1/1.1 = 0.90909090909090909090909090909091..."""
    return Decimal(0x9A2E8BA3, 0x4FC48DCC, 0x1D5FD2E1, 0x1C0000)


@always_inline
fn INV1D2() -> Decimal:
    """Returns 1/1.2 = 0.83333333333333333333333333333333..."""
    return Decimal(0x8D555555, 0x33C981FB, 0x1AED2BF9, 0x1C0000)


@always_inline
fn INV1D3() -> Decimal:
    """Returns 1/1.3 = 0.76923076923076923076923076923077..."""
    return Decimal(0xC4EC4EC4, 0xEC4EC4EC, 0x4EC4EC4E, 0x1C0000)


@always_inline
fn INV1D4() -> Decimal:
    """Returns 1/1.4 = 0.71428571428571428571428571428571..."""
    return Decimal(0xB6DB6DB6, 0xDB6DB6DB, 0x6DB6DB6D, 0x1C0000)


@always_inline
fn INV1D5() -> Decimal:
    """Returns 1/1.5 = 0.66666666666666666666666666666667..."""
    return Decimal(0xAAAAAAAA, 0xAAAAAAAA, 0xAAAAAAAA, 0x1C0000)


@always_inline
fn INV1D6() -> Decimal:
    """Returns 1/1.6 = 0.625."""
    return Decimal(0xA0000000, 0x0, 0x0, 0x1C0000)


@always_inline
fn INV1D7() -> Decimal:
    """Returns 1/1.7 = 0.58823529411764705882352941176471..."""
    return Decimal(0x9684BDA1, 0x2F684BDA, 0x12F684BD, 0x1C0000)


@always_inline
fn INV1D8() -> Decimal:
    """Returns 1/1.8 = 0.55555555555555555555555555555556..."""
    return Decimal(0x8E38E38E, 0x38E38E38, 0xE38E38E3, 0x1C0000)


@always_inline
fn INV1D9() -> Decimal:
    """Returns 1/1.9 = 0.52631578947368421052631578947368..."""
    return Decimal(0x86BCA1AF, 0x286BCA1A, 0xF286BCA1, 0x1C0000)


# Define ln constants (precomputed)
#
# The repr of the magic numbers can be obtained by the following code:
#
# ```mojo
# fn print_repr_from_words(value: String, ln_value: String) raises:
#     """
#     Prints the hex representation of a logarithm value.
#     Args:
#         value: The original value (for display purposes).
#         ln_value: The natural logarithm as a String.
#     """
#     var log_decimal = Decimal(ln_value)
#     print("ln(" + value + "): " + log_decimal.repr_from_words())
# ```


@always_inline
fn LN2() -> Decimal:
    """Returns ln(2) = 0.69314718055994530941723212145818..."""
    return Decimal(0xAA7A65BF, 0x81F52F01, 0x1665943F, 0x1C0000)


@always_inline
fn LN10() -> Decimal:
    """Returns ln(10) = 2.30258509299404568401799145468436..."""
    return Decimal(0x9FA69733, 0x1414B220, 0x4A668998, 0x1C0000)


# Constants for values less than 1
@always_inline
fn LN0D1() -> Decimal:
    """Returns ln(0.1) = -2.30258509299404568401799145468436..."""
    return Decimal(0x9FA69733, 0x1414B220, 0x4A668998, 0x801C0000)


@always_inline
fn LN0D2() -> Decimal:
    """Returns ln(0.2) = -1.60943791243410037460075933322619..."""
    return Decimal(0xF52C3174, 0x921F831E, 0x3400F558, 0x801C0000)


@always_inline
fn LN0D3() -> Decimal:
    """Returns ln(0.3) = -1.20397280432593599262274621776184..."""
    return Decimal(0x2B8E6822, 0x8258467, 0x26E70795, 0x801C0000)


@always_inline
fn LN0D4() -> Decimal:
    """Returns ln(0.4) = -0.91629073187415506518352721176801..."""
    return Decimal(0x4AB1CBB6, 0x102A541D, 0x1D9B6119, 0x801C0000)


@always_inline
fn LN0D5() -> Decimal:
    """Returns ln(0.5) = -0.69314718055994530941723212145818..."""
    return Decimal(0xAA7A65BF, 0x81F52F01, 0x1665943F, 0x801C0000)


@always_inline
fn LN0D6() -> Decimal:
    """Returns ln(0.6) = -0.51082562376599068320551409630366..."""
    return Decimal(0x81140263, 0x86305565, 0x10817355, 0x801C0000)


@always_inline
fn LN0D7() -> Decimal:
    """Returns ln(0.7) = -0.35667494393873237891263871124118..."""
    return Decimal(0x348BC5A8, 0x8B755D08, 0xB865892, 0x801C0000)


@always_inline
fn LN0D8() -> Decimal:
    """Returns ln(0.8) = -0.22314355131420975576629509030983..."""
    return Decimal(0xA03765F7, 0x8E35251B, 0x735CCD9, 0x801C0000)


@always_inline
fn LN0D9() -> Decimal:
    """Returns ln(0.9) = -0.10536051565782630122750098083931..."""
    return Decimal(0xB7763910, 0xFC3656AD, 0x3678591, 0x801C0000)


# Constants for values greater than or equal to 1
@always_inline
fn LN1() -> Decimal:
    """Returns ln(1) = 0."""
    return Decimal(0x0, 0x0, 0x0, 0x0)


@always_inline
fn LN1D1() -> Decimal:
    """Returns ln(1.1) = 0.09531017980432486004395212328077..."""
    return Decimal(0x7212FFD1, 0x7D9A10, 0x3146328, 0x1C0000)


@always_inline
fn LN1D2() -> Decimal:
    """Returns ln(1.2) = 0.18232155679395462621171802515451..."""
    return Decimal(0x2966635C, 0xFBC4D99C, 0x5E420E9, 0x1C0000)


@always_inline
fn LN1D3() -> Decimal:
    """Returns ln(1.3) = 0.26236426446749105203549598688095..."""
    return Decimal(0xE0BE71FD, 0xC254E078, 0x87A39F0, 0x1C0000)


@always_inline
fn LN1D4() -> Decimal:
    """Returns ln(1.4) = 0.33647223662121293050459341021699..."""
    return Decimal(0x75EEA016, 0xF67FD1F9, 0xADF3BAC, 0x1C0000)


@always_inline
fn LN1D5() -> Decimal:
    """Returns ln(1.5) = 0.40546510810816438197801311546435..."""
    return Decimal(0xC99DC953, 0x89F9FEB7, 0xD19EDC3, 0x1C0000)


@always_inline
fn LN1D6() -> Decimal:
    """Returns ln(1.6) = 0.47000362924573555365093703114834..."""
    return Decimal(0xA42FFC8, 0xF3C009E6, 0xF2FC765, 0x1C0000)


@always_inline
fn LN1D7() -> Decimal:
    """Returns ln(1.7) = 0.53062825106217039623154316318876..."""
    return Decimal(0x64BB9ED0, 0x4AB9978F, 0x11254107, 0x1C0000)


@always_inline
fn LN1D8() -> Decimal:
    """Returns ln(1.8) = 0.58778666490211900818973114061886..."""
    return Decimal(0xF3042CAE, 0x85BED853, 0x12FE0EAD, 0x1C0000)


@always_inline
fn LN1D9() -> Decimal:
    """Returns ln(1.9) = 0.64185388617239477599103597720349..."""
    return Decimal(0x12F992DC, 0xE7374425, 0x14BD4A78, 0x1C0000)
