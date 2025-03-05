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
# round(x: Decimal, places: Int, mode: RoundingMode): Rounds x to specified decimal places
#
# TODO Additional functions planned for future implementation:
#
# root(x: Decimal, n: Int): Computes the nth root of x using Newton's method
# exp(x: Decimal): Computes e raised to the power of x
# ln(x: Decimal): Computes the natural logarithm of x
# log10(x: Decimal): Computes the base-10 logarithm of x
# sin(x: Decimal): Computes the sine of x (in radians)
# cos(x: Decimal): Computes the cosine of x (in radians)
# tan(x: Decimal): Computes the tangent of x (in radians)
# abs(x: Decimal): Returns the absolute value of x
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
