# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
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
        guess = Decimal(UInt128(float_sqrt))
        # print("DEBUG: scale = 0")

    # For numbers with even scale
    elif x_scale % 2 == 0:
        var float_sqrt = builtin_math.sqrt(Float64(x_coef))
        guess = Decimal(UInt128(float_sqrt), scale=x_scale >> 1, sign=False)
        # print("DEBUG: scale is even")

    # For numbers with odd scale
    else:
        var float_sqrt = builtin_math.sqrt(Float64(x_coef)) * Float64(3.15625)
        guess = Decimal(
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
