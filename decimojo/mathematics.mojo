# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements basic object methods for the Decimal type
# which supports correctly-rounded, fixed-point arithmetic.
#
# ===----------------------------------------------------------------------=== #
#
# List of functions in this module:
#
# power(base: Decimal, exponent: Decimal): Raises base to the power of exponent (integer exponents only)
# power(base: Decimal, exponent: Int): Convenience method for integer exponents
# sqrt(x: Decimal): Computes the square root of x using Newton-Raphson method
# root(x: Decimal, n: Int): Computes the nth root of x using Newton's method
#
# TODO Additional functions planned for future implementation:
#
# exp(x: Decimal): Computes e raised to the power of x
# ln(x: Decimal): Computes the natural logarithm of x
# log10(x: Decimal): Computes the base-10 logarithm of x
# sin(x: Decimal): Computes the sine of x (in radians)
# cos(x: Decimal): Computes the cosine of x (in radians)
# tan(x: Decimal): Computes the tangent of x (in radians)
# abs(x: Decimal): Returns the absolute value of x
# round(x: Decimal, places: Int, mode: RoundingMode): Rounds x to specified decimal places
# floor(x: Decimal): Returns the largest integer <= x
# ceil(x: Decimal): Returns the smallest integer >= x
# gcd(a: Decimal, b: Decimal): Returns greatest common divisor of a and b
# lcm(a: Decimal, b: Decimal): Returns least common multiple of a and b
# ===----------------------------------------------------------------------=== #

"""
Implements functions for mathematical operations on Decimal objects.
"""

from decimojo.decimal import Decimal
from decimojo.rounding_mode import RoundingMode

# ===----------------------------------------------------------------------=== #
# Arithmetic operations functions
# ===----------------------------------------------------------------------=== #


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

    if base.coefficient() == "1" and base.scale() == 0:
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


# fn sqrt(x: Decimal) raises -> Decimal:
#     """
#     Computes the square root of a Decimal value using Newton-Raphson method.

#     Args:
#         x: The Decimal value to compute the square root of.

#     Returns:
#         A new Decimal containing the square root of x.

#     Raises:
#         Error: If x is negative.
#     """
#     # Special cases
#     if x.is_negative():
#         raise Error("Cannot compute square root of negative number")

#     if x.is_zero():
#         return Decimal.ZERO()

#     if x == Decimal.ONE():
#         return Decimal.ONE()

#     # Working precision - we'll compute with extra digits and round at the end
#     var working_precision = x.scale() * 2
#     working_precision = max(working_precision, UInt32(10))  # At least 10 digits

#     # Initial guess - a good guess helps converge faster
#     # For numbers near 1, use the number itself
#     # For very small or large numbers, scale appropriately
#     var guess: Decimal
#     var exponent = len(x.coefficient()) - x.scale()

#     if exponent >= 0 and exponent <= 3:
#         # For numbers between 0.1 and 1000, start with x/2 + 0.5
#         guess = (x / Decimal("2")) + Decimal("0.5")
#     else:
#         # For larger/smaller numbers, make a smarter guess
#         # This scales based on the magnitude of the number
#         var shift = exponent / 2
#         if exponent % 2 != 0:
#             # For odd exponents, adjust
#             shift = (exponent + 1) / 2

#         # Use an approximation based on the exponent
#         if exponent > 0:
#             guess = Decimal("10") ** shift
#         else:
#             guess = Decimal("0.1") ** (-shift)

#     # Newton-Raphson iterations
#     # x_n+1 = (x_n + S/x_n) / 2
#     var prev_guess = Decimal.ZERO()
#     var iteration_count = 0
#     var max_iterations = 100  # Prevent infinite loops

#     while guess != prev_guess and iteration_count < max_iterations:
#         prev_guess = guess
#         guess = (guess + (x / guess)) / Decimal("2")
#         iteration_count += 1

#     # Round to appropriate precision - typically half the working precision
#     var result_precision = x.scale()
#     if result_precision % 2 == 1:
#         # For odd scales, add 1 to ensure proper rounding
#         result_precision += 1

#     # The result scale should be approximately half the input scale
#     result_precision = result_precision / 2

#     # Format to the appropriate number of decimal places
#     var result_str = String(guess)
#     var rounded_result = Decimal(result_str)

#     return rounded_result


# # Additional helper function to compute nth root
# fn root(x: Decimal, n: Int) raises -> Decimal:
#     """
#     Computes the nth root of x using Newton's method.

#     Args:
#         x: The base value
#         n: The root to compute (must be positive)

#     Returns:
#         The nth root of x as a Decimal

#     Raises:
#         Error: If x is negative and n is even, or if n is not positive
#     """
#     # Special cases
#     if n <= 0:
#         raise Error("Root index must be positive")

#     if n == 1:
#         return x

#     if n == 2:
#         return sqrt(x)

#     if x.is_zero():
#         return Decimal.ZERO()

#     if x == Decimal.ONE():
#         return Decimal.ONE()

#     if x.is_negative() and n % 2 == 0:
#         raise Error("Cannot compute even root of negative number")

#     # The sign of the result
#     var result_is_negative = x.is_negative() and n % 2 == 1
#     var abs_x = x.abs()

#     # Newton's method for nth root:
#     # x_k+1 = ((n-1)*x_k + num/(x_k^(n-1)))/n

#     # Initial guess
#     var guess = Decimal.ONE()
#     if abs_x > Decimal.ONE():
#         guess = abs_x / Decimal(n)  # Simple initial approximation

#     var prev_guess = Decimal.ZERO()
#     var n_minus_1 = Decimal(n - 1)
#     var n_decimal = Decimal(n)
#     var max_iterations = 100
#     var iteration_count = 0

#     while guess != prev_guess and iteration_count < max_iterations:
#         prev_guess = guess

#         # Compute x_k^(n-1)
#         var guess_pow_n_minus_1 = power(guess, n - 1)

#         # Next approximation
#         guess = (n_minus_1 * guess + abs_x / guess_pow_n_minus_1) / n_decimal
#         iteration_count += 1

#     return -guess if result_is_negative else guess


# ===------------------------------------------------------------------------===#
# Rounding
# ===------------------------------------------------------------------------===#


fn round(
    number: Decimal,
    decimal_places: Int,
    rounding_mode: RoundingMode = RoundingMode.HALF_EVEN(),
) -> Decimal:
    """
    Rounds the Decimal to the specified number of decimal places.

    Args:
        number: The Decimal to round.
        decimal_places: Number of decimal places to round to.
        rounding_mode: Rounding mode to use (defaults to HALF_EVEN/banker's rounding).

    Returns:
        A new Decimal rounded to the specified number of decimal places.
    """
    var current_scale = number.scale()

    # If already at the desired scale, return a copy
    if current_scale == decimal_places:
        return number

    # If we need more decimal places, scale up
    if decimal_places > current_scale:
        return number._scale_up(decimal_places - current_scale)

    # Otherwise, scale down with the specified rounding mode
    return number._scale_down(current_scale - decimal_places, rounding_mode)
