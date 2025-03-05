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

from .arithmetics import (
    add,
    subtract,
    true_divide,
    power,
    absolute,
    sqrt,
)
from .rounding import round
