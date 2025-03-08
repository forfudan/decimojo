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
# round(x: Decimal, places: Int, mode: RoundingMode): Rounds x to specified decimal places
#
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
