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

    if x == Decimal.ONE():
        return Decimal.ONE()

    var x_coef = x.coefficient()
    var x_scale = x.scale()

    # Initial guess - a good guess helps converge faster

    var guess: Decimal

    # For integers, use floating point approach to quickly find a good guess
    if x.is_integer():
        var float_sqrt = builtin_math.sqrt(x.to_uint128())
        guess = Decimal(UInt128(float_sqrt))

    elif x_scale % 2 == 0:
        var float_sqrt = builtin_math.sqrt(Float64(x.coefficient()))
        guess = Decimal(UInt128(float_sqrt), negative=False, scale=x_scale >> 1)

    elif x_scale % 2 == 1:
        var float_sqrt = builtin_math.sqrt(Float64(x.coefficient())) * Float64(
            3.15625
        )
        guess = Decimal(
            UInt128(float_sqrt), negative=False, scale=(x_scale + 1) >> 1
        )

    # TODO: Remove the following code?
    # Use decimal guess
    else:
        # For numbers near 1, use the number itself
        # For very small or large numbers, scale appropriately

        var num_of_digits_x_int_part = decimojo.utility.number_of_digits(
            x_coef
        ) - x_scale

        # For numbers between 0.1 and 999, start with x/2 + 0.5
        if num_of_digits_x_int_part >= -1 and num_of_digits_x_int_part <= 3:
            var half_x = x / Decimal(2, 0, 0, False, 0)
            guess = half_x + Decimal(5, 0, 0, False, 1)

        # For larger/smaller numbers, make a smarter guess
        # This scales based on the magnitude of the number
        else:
            var shift: Int
            if num_of_digits_x_int_part % 2 != 0:
                # For odd exponents, adjust
                shift = (num_of_digits_x_int_part + 1) // 2
            else:
                shift = num_of_digits_x_int_part // 2

            # abs(num_of_digits_x_int_part) <= 29, so abs(shift) is less than or equal to 15
            # So 10^shift will not overflow UInt64
            # Use an approximation based on the num_of_digits_x_int_part
            if num_of_digits_x_int_part > 0:
                # shift > 0
                # guess = 10 ** shift
                guess = Decimal(UInt64(10) ** shift)
            else:
                # shift <= 0
                # guess = 0.1 ** (-shift) = 1 / (10 ** (-shift))
                guess = Decimal(1) / Decimal((UInt64(10) ** (-shift)))

    # Newton-Raphson iterations
    # x_n+1 = (x_n + S/x_n) / 2
    var prev_guess = Decimal.ZERO()
    var iteration_count = 0
    var max_iterations = 100  # Prevent infinite loops

    while guess != prev_guess and iteration_count < max_iterations:
        # print("------------------------------------------------------")
        # print("DEBUG: iteration_count", iteration_count)
        # print("DEBUG: prev_guess", prev_guess)
        # print("DEBUG: guess", guess)

        prev_guess = guess
        var division_result = x / guess
        var sum_result = guess + division_result
        guess = sum_result / Decimal(2, 0, 0, False, 0)
        iteration_count += 1

    # If exact square root found remove trailing zeros after the decimal point
    # For example, sqrt(100) = 10, not 10.000000000000000000000000000
    # Exact square means that the coefficient of guess after removing trailing zeros
    # is equal to the coefficient of x

    var guess_coef = guess.coefficient()
    var count = 0  # Count of trailing zeros
    for _ in range(guess.scale()):
        if guess_coef % 10 == 0:
            guess_coef //= 10
            count += 1
        else:
            break

    if guess_coef * guess_coef == x_coef:
        var low = UInt32(guess_coef & 0xFFFFFFFF)
        var mid = UInt32((guess_coef >> 32) & 0xFFFFFFFF)
        var high = UInt32((guess_coef >> 64) & 0xFFFFFFFF)
        return Decimal(low, mid, high, False, guess.scale() - count)

    return guess
