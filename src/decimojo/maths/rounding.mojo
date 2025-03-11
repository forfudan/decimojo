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

import testing

from ..decimal import Decimal
from ..rounding_mode import RoundingMode

# ===------------------------------------------------------------------------===#
# Rounding
# ===------------------------------------------------------------------------===#


fn round(
    number: Decimal,
    ndigits: Int = 0,
    rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
) raises -> Decimal:
    """
    Rounds the Decimal to the specified number of decimal places.

    Args:
        number: The Decimal to round.
        ndigits: Number of decimal places to round to.
            Defaults to 0.
        rounding_mode: Rounding mode to use.
            Defaults to ROUND_HALF_EVEN (banker's rounding).

    Returns:
        A new Decimal rounded to the specified number of decimal places.
    """

    # Number of decimal places of the number is equal to the scale of the number
    var x_scale = number.scale()
    # `ndigits` is equal to the scale of the final number
    var scale_diff = ndigits - x_scale

    # CASE: If already at the desired scale
    # Return a copy directly
    # 情况一：如果已经在所需的标度上, 直接返回其副本
    #
    # round(Decimal("123.456"), 3) -> Decimal("123.456")
    if scale_diff == 0:
        return number

    var x_coef = number.coefficient()
    var ndigits_of_x = decimojo.utility.number_of_digits(x_coef)

    # CASE: If ndigits is larger than the current scale
    # Scale up the coefficient of the number to the desired scale
    # If scaling up causes an overflow, raise an error
    # 情况二：如果ndigits大于当前标度, 将係數放大
    #
    # Examples:
    # round(Decimal("123.456"), 5) -> Decimal("123.45600")
    # round(Decimal("123.456"), 29) -> Error

    if scale_diff > 0:
        # If the digits of result > 29, directly raise an error
        if ndigits_of_x + scale_diff > Decimal.MAX_NUM_DIGITS:
            raise Error(
                String(
                    "Error in `round()`: `ndigits = {}` causes the number of"
                    " digits in the significant figures of the result (={})"
                    " exceeds the maximum capacity (={})."
                ).format(
                    ndigits,
                    ndigits_of_x + scale_diff,
                    Decimal.MAX_NUM_DIGITS,
                )
            )

        # If the digits of result <= 29, calculate the result by scaling up
        else:
            var res_coef = x_coef * UInt128(10) ** scale_diff

            # If the digits of result == 29, but the result >= 2^96, raise an error
            if (ndigits_of_x + scale_diff == Decimal.MAX_NUM_DIGITS) and (
                res_coef > Decimal.MAX_AS_UINT128
            ):
                raise Error(
                    String(
                        "Error in `round()`: `ndigits = {}` causes the"
                        " significant digits of the result (={}) exceeds the"
                        " maximum capacity (={})."
                    ).format(ndigits, res_coef, Decimal.MAX_AS_UINT128)
                )

            # In other cases, return the result
            else:
                return Decimal(
                    res_coef, scale=ndigits, sign=number.is_negative()
                )

    # CASE: If ndigits is smaller than the current scale
    # Scale down the coefficient of the number to the desired scale and round
    # 情况三：如果ndigits小于当前标度, 将係數縮小, 然后捨去
    #
    # If `ndigits` is negative, the result need to be scaled up again.
    #
    # Examples:
    # round(Decimal("987.654321"), 3) -> Decimal("987.654")
    # round(Decimal("987.654321"), -2) -> Decimal("1000")
    # round(Decimal("987.654321"), -3) -> Decimal("1000")
    # round(Decimal("987.654321"), -4) -> Decimal("0")

    else:
        # scale_diff < 0
        # Calculate the number of digits to keep
        var ndigits_to_keep = ndigits_of_x + scale_diff

        # Keep the first `ndigits_to_keep` digits with specified rounding mode
        var res_coef = decimojo.utility.round_to_keep_first_n_digits(
            x_coef, ndigits=ndigits_to_keep, rounding_mode=rounding_mode
        )

        if ndigits >= 0:
            return Decimal(res_coef, scale=ndigits, sign=number.is_negative())

        # if `ndigits` is negative and `ndigits_to_keep` >= 0, scale up the result
        elif ndigits_to_keep >= 0:
            res_coef *= UInt128(10) ** (-ndigits)
            return Decimal(res_coef, scale=0, sign=number.is_negative())

        # if `ndigits` is negative and `ndigits_to_keep` < 0, return 0
        else:
            return Decimal.ZERO()

    # Add a fallback raise even if it seems unreachable
    testing.assert_true(False, "Unreachable code path reached")
    return number
