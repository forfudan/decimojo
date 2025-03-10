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
    ndigits: Int = 0,
    rounding_mode: RoundingMode = RoundingMode.HALF_EVEN(),
) raises -> Decimal:
    """
    Rounds the Decimal to the specified number of decimal places.

    Args:
        number: The Decimal to round.
        ndigits: Number of decimal places to round to.
            Defaults to 0.
        rounding_mode: Rounding mode to use.
            Defaults to HALF_EVEN/banker's rounding.

    Returns:
        A new Decimal rounded to the specified number of decimal places.
    """
    var current_scale = number.scale()

    # CASE: If already at the desired scale
    # Return a copy
    # round(Decimal("123.456"), 3) -> Decimal("123.456")
    if current_scale == ndigits:
        return number

    # TODO: CASE: If the number is an integer
    # Return with more or less zeros until the desired scale
    # round(Decimal("123"), 2) -> Decimal("123.00")

    # If we need more decimal places, scale up
    if ndigits > current_scale:
        try:
            return decimojo.utility.scale_up(number, ndigits - current_scale)
        except e:
            raise Error("Error in `round()`; ", e)

    # Otherwise, scale down with the specified rounding mode
    return number._scale_down(current_scale - ndigits, rounding_mode)
