# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements basic arithmetic functions for the Decimal type
#
# ===----------------------------------------------------------------------=== #
#
# List of functions in this module:
#
# add(x1: Decimal, x2: Decimal): Adds two Decimal values and returns a new Decimal containing the sum
# subtract(x1: Decimal, x2: Decimal): Subtracts the x2 Decimal from x1 and returns a new Decimal
# multiply(x1: Decimal, x2: Decimal): Multiplies two Decimal values and returns a new Decimal containing the product
# true_divide(x1: Decimal, x2: Decimal): Divides x1 by x2 and returns a new Decimal containing the quotient
#
# ===----------------------------------------------------------------------=== #

"""
Implements functions for mathematical operations on Decimal objects.
"""

import testing

from decimojo.decimal import Decimal
from decimojo.rounding_mode import RoundingMode
import decimojo.utility


# TODO: Like `multiply` use combined bits to determine the appropriate method
fn add(x1: Decimal, x2: Decimal) raises -> Decimal:
    """
    Adds two Decimal values and returns a new Decimal containing the sum.
    The results will be rounded (up to even) if digits are too many.

    Args:
        x1: The first Decimal operand.
        x2: The second Decimal operand.

    Returns:
        A new Decimal containing the sum of x1 and x2.

    Raises:
        Error: If the operation would overflow.
    """

    # Special case for zero
    if x1.is_zero():
        return Decimal(
            x2.low,
            x2.mid,
            x2.high,
            max(x1.scale(), x2.scale()),
            x1.flags & x2.flags == Decimal.SIGN_MASK,
        )

    elif x2.is_zero():
        return Decimal(
            x1.low,
            x1.mid,
            x1.high,
            max(x1.scale(), x2.scale()),
            x1.flags & x2.flags == Decimal.SIGN_MASK,
        )

    # Integer addition with scale of 0 (true integers)
    elif x1.scale() == 0 and x2.scale() == 0:
        var x1_coef = x1.coefficient()
        var x2_coef = x2.coefficient()

        # Same sign: add absolute values and keep the sign
        if x1.is_negative() == x2.is_negative():
            # Add directly using UInt128 arithmetic
            var summation = x1_coef + x2_coef

            # Check for overflow (UInt128 can store values beyond our 96-bit limit)
            # We need to make sure the sum fits in 96 bits (our Decimal capacity)
            if summation > Decimal.MAX_AS_UINT128:  # 2^96-1
                raise Error("Error in `addition()`: Decimal overflow")

            # Extract the 32-bit components from the UInt128 sum
            var low = UInt32(summation & 0xFFFFFFFF)
            var mid = UInt32((summation >> 32) & 0xFFFFFFFF)
            var high = UInt32((summation >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, 0, x1.is_negative())

        # Different signs: subtract the smaller from the larger
        else:
            var diff: UInt128
            var is_negative: Bool
            if x1_coef > x2_coef:
                diff = x1_coef - x2_coef
                is_negative = x1.is_negative()
            else:
                diff = x2_coef - x1_coef
                is_negative = x2.is_negative()

            # Extract the 32-bit components from the UInt128 difference
            low = UInt32(diff & 0xFFFFFFFF)
            mid = UInt32((diff >> 32) & 0xFFFFFFFF)
            high = UInt32((diff >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, 0, is_negative)

    # Integer addition with positive scales
    elif x1.is_integer() and x2.is_integer():
        # Same sign: add absolute values and keep the sign
        if x1.is_negative() == x2.is_negative():
            # Add directly using UInt128 arithmetic
            var summation = x1.to_uint128() + x2.to_uint128()

            # Check for overflow (UInt128 can store values beyond our 96-bit limit)
            # We need to make sure the sum fits in 96 bits (our Decimal capacity)
            if summation > Decimal.MAX_AS_UINT128:  # 2^96-1
                raise Error("Error in `addition()`: Decimal overflow")

            # Determine the scale for the result
            var scale = min(
                max(x1.scale(), x2.scale()),
                Decimal.MAX_NUM_DIGITS
                - decimojo.utility.number_of_digits(summation),
            )
            ## If summation > 7922816251426433759354395033
            if (summation > Decimal.MAX_AS_UINT128 // 10) and (scale > 0):
                scale -= 1
            summation *= UInt128(10) ** scale

            # Extract the 32-bit components from the UInt128 sum
            var low = UInt32(summation & 0xFFFFFFFF)
            var mid = UInt32((summation >> 32) & 0xFFFFFFFF)
            var high = UInt32((summation >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, scale, x1.is_negative())

        # Different signs: subtract the smaller from the larger
        else:
            var diff: UInt128
            var is_negative: Bool
            if x1.coefficient() > x2.coefficient():
                diff = x1.to_uint128() - x2.to_uint128()
                is_negative = x1.is_negative()
            else:
                diff = x2.to_uint128() - x1.to_uint128()
                is_negative = x2.is_negative()

            # Determine the scale for the result
            var scale = min(
                max(x1.scale(), x2.scale()),
                Decimal.MAX_NUM_DIGITS
                - decimojo.utility.number_of_digits(diff),
            )
            ## If summation > 7922816251426433759354395033
            if (diff > Decimal.MAX_AS_UINT128 // 10) and (scale > 0):
                scale -= 1
            diff *= UInt128(10) ** scale

            # Extract the 32-bit components from the UInt128 difference
            low = UInt32(diff & 0xFFFFFFFF)
            mid = UInt32((diff >> 32) & 0xFFFFFFFF)
            high = UInt32((diff >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, scale, is_negative)

    # Float addition with the same scale
    elif x1.scale() == x2.scale():
        var summation: Int128  # 97-bit signed integer can be stored in Int128
        summation = (-1) ** x1.is_negative() * Int128(x1.coefficient()) + (
            -1
        ) ** x2.is_negative() * Int128(x2.coefficient())

        var is_negative = summation < 0
        if is_negative:
            summation = -summation

        # Now we need to truncate the summation to fit in 96 bits
        var final_scale: Int
        var truncated_summation = UInt128(summation)

        # If the summation fits in 96 bits, we can use the original scale
        if summation < Decimal.MAX_AS_INT128:
            final_scale = x1.scale()

        # Otherwise, we need to truncate the summation to fit in 96 bits
        else:
            truncated_summation = decimojo.utility.truncate_to_max(
                truncated_summation
            )
            final_scale = decimojo.utility.number_of_digits(
                truncated_summation
            ) - (
                decimojo.utility.number_of_digits(summation)
                - max(x1.scale(), x2.scale())
            )

        # Extract the 32-bit components from the Int256 difference
        low = UInt32(truncated_summation & 0xFFFFFFFF)
        mid = UInt32((truncated_summation >> 32) & 0xFFFFFFFF)
        high = UInt32((truncated_summation >> 64) & 0xFFFFFFFF)

        return Decimal(low, mid, high, final_scale, is_negative)

    # Float addition which with different scales
    else:
        var summation: Int256
        if x1.scale() == x2.scale():
            summation = (-1) ** x1.is_negative() * Int256(x1.coefficient()) + (
                -1
            ) ** x2.is_negative() * Int256(x2.coefficient())
        elif x1.scale() > x2.scale():
            summation = (-1) ** x1.is_negative() * Int256(x1.coefficient()) + (
                -1
            ) ** x2.is_negative() * Int256(x2.coefficient()) * Int256(10) ** (
                x1.scale() - x2.scale()
            )
        else:
            summation = (-1) ** x1.is_negative() * Int256(
                x1.coefficient()
            ) * Int256(10) ** (x2.scale() - x1.scale()) + (
                -1
            ) ** x2.is_negative() * Int256(
                x2.coefficient()
            )

        var is_negative = summation < 0
        if is_negative:
            summation = -summation

        # Now we need to truncate the summation to fit in 96 bits
        var final_scale: Int
        var truncated_summation = UInt256(summation)

        # If the summation fits in 96 bits, we can use the original scale
        if summation < Decimal.MAX_AS_INT256:
            final_scale = max(x1.scale(), x2.scale())

        # Otherwise, we need to truncate the summation to fit in 96 bits
        else:
            truncated_summation = decimojo.utility.truncate_to_max(
                truncated_summation
            )
            final_scale = decimojo.utility.number_of_digits(
                truncated_summation
            ) - (
                decimojo.utility.number_of_digits(summation)
                - max(x1.scale(), x2.scale())
            )

        # Extract the 32-bit components from the Int256 difference
        low = UInt32(truncated_summation & 0xFFFFFFFF)
        mid = UInt32((truncated_summation >> 32) & 0xFFFFFFFF)
        high = UInt32((truncated_summation >> 64) & 0xFFFFFFFF)

        return Decimal(low, mid, high, final_scale, is_negative)


fn subtract(x1: Decimal, x2: Decimal) raises -> Decimal:
    """
    Subtracts the x2 Decimal from x1 and returns a new Decimal.

    Args:
        x1: The Decimal to subtract from.
        x2: The Decimal to subtract.

    Returns:
        A new Decimal containing the difference.

    Notes:
    ------
    This method is implemented using the existing `__add__()` and `__neg__()` methods.

    Examples:
    ---------
    ```console
    var a = Decimal("10.5")
    var b = Decimal("3.2")
    var result = a - b  # Returns 7.3
    ```
    .
    """
    # Implementation using the existing `__add__()` and `__neg__()` methods
    try:
        return x1 + (-x2)
    except e:
        raise Error("Error in `subtract()`; ", e)


fn multiply(x1: Decimal, x2: Decimal) raises -> Decimal:
    """
    Multiplies two Decimal values and returns a new Decimal containing the product.

    Args:
        x1: The first Decimal operand.
        x2: The second Decimal operand.

    Returns:
        A new Decimal containing the product of x1 and x2.
    """

    var x1_coef = x1.coefficient()
    var x2_coef = x2.coefficient()
    var x1_scale = x1.scale()
    var x2_scale = x2.scale()
    var combined_scale = x1_scale + x2_scale
    """Combined scale of the two operands."""
    var is_negative = x1.is_negative() != x2.is_negative()

    # SPECIAL CASE: zero
    # Return zero while preserving the scale
    if x1_coef == 0 or x2_coef == 0:
        var result = Decimal.ZERO()
        var result_scale = min(combined_scale, Decimal.MAX_SCALE)
        result.flags = UInt32(
            (result_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
        )
        return result

    # SPECIAL CASE: Both operands have coefficient of 1
    if x1_coef == 1 and x2_coef == 1:
        # If the combined scale exceeds the maximum precision,
        # return 0 with leading zeros after the decimal point and correct sign
        if combined_scale > Decimal.MAX_SCALE:
            return Decimal(
                0,
                0,
                0,
                Decimal.MAX_SCALE,
                is_negative,
            )
        # Otherwise, return 1 with correct sign and scale
        var final_scale = min(Decimal.MAX_SCALE, combined_scale)
        return Decimal(1, 0, 0, final_scale, is_negative)

    # SPECIAL CASE: First operand has coefficient of 1
    if x1_coef == 1:
        # If x1 is 1, return x2 with correct sign
        if x1_scale == 0:
            var result = x2
            result.flags &= ~Decimal.SIGN_MASK
            if is_negative:
                result.flags |= Decimal.SIGN_MASK
            return result
        else:
            var prod = x2_coef
            # Rounding may be needed.
            var num_digits_prod = decimojo.utility.number_of_digits(prod)
            var num_digits_to_keep = num_digits_prod - (
                combined_scale - Decimal.MAX_SCALE
            )
            var truncated_prod = decimojo.utility.round_to_keep_first_n_digits(
                prod, num_digits_to_keep
            )
            var final_scale = min(Decimal.MAX_SCALE, combined_scale)
            var low = UInt32(truncated_prod & 0xFFFFFFFF)
            var mid = UInt32((truncated_prod >> 32) & 0xFFFFFFFF)
            var high = UInt32((truncated_prod >> 64) & 0xFFFFFFFF)
            return Decimal(
                low,
                mid,
                high,
                final_scale,
                is_negative,
            )

    # SPECIAL CASE: Second operand has coefficient of 1
    if x2_coef == 1:
        # If x2 is 1, return x1 with correct sign
        if x2_scale == 0:
            var result = x1
            result.flags &= ~Decimal.SIGN_MASK
            if is_negative:
                result.flags |= Decimal.SIGN_MASK
            return result
        else:
            var prod = x1_coef
            # Rounding may be needed.
            var num_digits_prod = decimojo.utility.number_of_digits(prod)
            var num_digits_to_keep = num_digits_prod - (
                combined_scale - Decimal.MAX_SCALE
            )
            var truncated_prod = decimojo.utility.round_to_keep_first_n_digits(
                prod, num_digits_to_keep
            )
            var final_scale = min(Decimal.MAX_SCALE, combined_scale)
            var low = UInt32(truncated_prod & 0xFFFFFFFF)
            var mid = UInt32((truncated_prod >> 32) & 0xFFFFFFFF)
            var high = UInt32((truncated_prod >> 64) & 0xFFFFFFFF)
            return Decimal(
                low,
                mid,
                high,
                final_scale,
                is_negative,
            )

    # Determine the number of bits in the coefficients
    # Used to determine the appropriate multiplication method
    # The coefficient of result would be the sum of the two numbers of bits
    var x1_num_bits = decimojo.utility.number_of_bits(x1_coef)
    """Number of significant bits in the coefficient of x1."""
    var x2_num_bits = decimojo.utility.number_of_bits(x2_coef)
    """Number of significant bits in the coefficient of x2."""
    var combined_num_bits = x1_num_bits + x2_num_bits
    """Number of significant bits in the coefficient of the result."""

    # SPECIAL CASE: Both operands are true integers
    if x1_scale == 0 and x2_scale == 0:
        # Small integers, use UInt64 multiplication
        if combined_num_bits <= 64:
            var prod: UInt64 = UInt64(x1.low) * UInt64(x2.low)
            var low = UInt32(prod & 0xFFFFFFFF)
            var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
            return Decimal(low, mid, 0, 0, is_negative)

        # Moderate integers, use UInt128 multiplication
        elif combined_num_bits <= 128:
            var prod: UInt128 = UInt128(x1_coef) * UInt128(x2_coef)
            var low = UInt32(prod & 0xFFFFFFFF)
            var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
            var high = UInt32((prod >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, 0, is_negative)

        # Large integers, use UInt256 multiplication
        else:
            var prod: UInt256 = UInt256(x1_coef) * UInt256(x2_coef)
            if prod > Decimal.MAX_AS_UINT256:
                raise Error("Error in `prodtiply()`: Decimal overflow")
            else:
                var low = UInt32(prod & 0xFFFFFFFF)
                var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
                var high = UInt32((prod >> 64) & 0xFFFFFFFF)
                return Decimal(low, mid, high, 0, is_negative)

    # SPECIAL CASE: Both operands are integers but with scales
    # Examples: 123.0 * 456.00
    if x1.is_integer() and x2.is_integer():
        var x1_integral_part = x1_coef // (UInt128(10) ** UInt128(x1_scale))
        var x2_integral_part = x2_coef // (UInt128(10) ** UInt128(x2_scale))
        var prod: UInt256 = UInt256(x1_integral_part) * UInt256(
            x2_integral_part
        )
        if prod > Decimal.MAX_AS_UINT256:
            raise Error("Error in `multiply()`: Decimal overflow")
        else:
            var num_digits = decimojo.utility.number_of_digits(prod)
            var final_scale = min(
                Decimal.MAX_NUM_DIGITS - num_digits, combined_scale
            )
            # Scale up before it overflows
            prod = prod * 10**final_scale
            if prod > Decimal.MAX_AS_UINT256:
                prod = prod // 10
                final_scale -= 1

            var low = UInt32(prod & 0xFFFFFFFF)
            var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
            var high = UInt32((prod >> 64) & 0xFFFFFFFF)
            return Decimal(
                low,
                mid,
                high,
                final_scale,
                is_negative,
            )

    # GENERAL CASES: Decimal multiplication with any scales

    # SUB-CASE: Both operands are small
    # The bits of the product will not exceed 96 bits
    # It can just fit into Decimal's capacity without overflow
    # Result coefficient will less than 2^96 - 1 = 79228162514264337593543950335
    # Examples: 1.23 * 4.56
    if combined_num_bits <= 96:
        var prod: UInt128 = x1_coef * x2_coef

        # Combined scale more than max precision, no need to truncate
        if combined_scale <= Decimal.MAX_SCALE:
            var low = UInt32(prod & 0xFFFFFFFF)
            var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
            var high = UInt32((prod >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, combined_scale, is_negative)

        # Combined scale no more than max precision, truncate with rounding
        else:
            var num_digits = decimojo.utility.number_of_digits(prod)
            var num_digits_to_keep = num_digits - (
                combined_scale - Decimal.MAX_SCALE
            )
            prod = decimojo.utility.round_to_keep_first_n_digits(
                prod, num_digits_to_keep
            )
            var final_scale = min(Decimal.MAX_SCALE, combined_scale)

            if final_scale > Decimal.MAX_SCALE:
                var ndigits_prod = decimojo.utility.number_of_digits(prod)
                prod = decimojo.utility.round_to_keep_first_n_digits(
                    prod, ndigits_prod - (final_scale - Decimal.MAX_SCALE)
                )
                final_scale = Decimal.MAX_SCALE

            var low = UInt32(prod & 0xFFFFFFFF)
            var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
            var high = UInt32((prod >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, final_scale, is_negative)

    # SUB-CASE: Both operands are moderate
    # The bits of the product will not exceed 128 bits
    # Result coefficient will less than 2^128 - 1 but more than 2^96 - 1
    # IMPORTANT: This means that the product will exceed Decimal's capacity
    # Either raises an error if intergral part overflows
    # Or truncates the product to fit into Decimal's capacity
    if combined_num_bits <= 128:
        var prod: UInt128 = x1_coef * x2_coef

        # Check outflow
        # The number of digits of the integral part
        var num_digits_of_integral_part = decimojo.utility.number_of_digits(
            prod
        ) - combined_scale
        # Truncated first 29 digits
        var truncated_prod_at_max_length = decimojo.utility.round_to_keep_first_n_digits(
            prod, Decimal.MAX_NUM_DIGITS
        )
        if (num_digits_of_integral_part >= Decimal.MAX_NUM_DIGITS) & (
            truncated_prod_at_max_length > Decimal.MAX_AS_UINT128
        ):
            raise Error("Error in `multiply()`: Decimal overflow")

        # Otherwise, the value will not overflow even after rounding
        # Determine the final scale after rounding
        # If the first 29 digits does not exceed the limit,
        # the final coefficient can be of 29 digits.
        # The final scale can be 29 - num_digits_of_integral_part.
        var num_digits_of_decimal_part = Decimal.MAX_NUM_DIGITS - num_digits_of_integral_part
        # If the first 29 digits exceed the limit,
        # we need to adjust the num_digits_of_decimal_part by -1
        # so that the final coefficient will be of 28 digits.
        if truncated_prod_at_max_length > Decimal.MAX_AS_UINT128:
            num_digits_of_decimal_part -= 1
            prod = decimojo.utility.round_to_keep_first_n_digits(
                prod, Decimal.MAX_NUM_DIGITS - 1
            )
        else:
            prod = truncated_prod_at_max_length

        # Yuhao's notes: I think combined_scale should always be smaller
        var final_scale = min(num_digits_of_decimal_part, combined_scale)

        if final_scale > Decimal.MAX_SCALE:
            var ndigits_prod = decimojo.utility.number_of_digits(prod)
            prod = decimojo.utility.round_to_keep_first_n_digits(
                prod, ndigits_prod - (final_scale - Decimal.MAX_SCALE)
            )
            final_scale = Decimal.MAX_SCALE

        # Extract the 32-bit components from the UInt128 product
        var low = UInt32(prod & 0xFFFFFFFF)
        var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
        var high = UInt32((prod >> 64) & 0xFFFFFFFF)

        return Decimal(low, mid, high, final_scale, is_negative)

    # REMAINING CASES: Both operands are big
    # The bits of the product will not exceed 192 bits
    # Result coefficient will less than 2^192 - 1 but more than 2^128 - 1
    # IMPORTANT: This means that the product will exceed Decimal's capacity
    # Either raises an error if intergral part overflows
    # Or truncates the product to fit into Decimal's capacity
    var prod: UInt256 = UInt256(x1_coef) * UInt256(x2_coef)

    # Check outflow
    # The number of digits of the integral part
    var num_digits_of_integral_part = decimojo.utility.number_of_digits(
        prod
    ) - combined_scale
    # Truncated first 29 digits
    var truncated_prod_at_max_length = decimojo.utility.round_to_keep_first_n_digits(
        prod, Decimal.MAX_NUM_DIGITS
    )
    # Check for overflow of the integral part after rounding
    if (num_digits_of_integral_part >= Decimal.MAX_NUM_DIGITS) & (
        truncated_prod_at_max_length > Decimal.MAX_AS_UINT256
    ):
        raise Error("Error in `multiply()`: Decimal overflow")

    # Otherwise, the value will not overflow even after rounding
    # Determine the final scale after rounding
    # If the first 29 digits does not exceed the limit,
    # the final coefficient can be of 29 digits.
    # The final scale can be 29 - num_digits_of_integral_part.
    var num_digits_of_decimal_part = Decimal.MAX_NUM_DIGITS - num_digits_of_integral_part
    # If the first 29 digits exceed the limit,
    # we need to adjust the num_digits_of_decimal_part by -1
    # so that the final coefficient will be of 28 digits.
    if truncated_prod_at_max_length > Decimal.MAX_AS_UINT256:
        num_digits_of_decimal_part -= 1
        prod = decimojo.utility.round_to_keep_first_n_digits(
            prod, Decimal.MAX_NUM_DIGITS - 1
        )
    else:
        prod = truncated_prod_at_max_length

    # I think combined_scale should always be smaller
    final_scale = min(num_digits_of_decimal_part, combined_scale)

    if final_scale > Decimal.MAX_SCALE:
        var ndigits_prod = decimojo.utility.number_of_digits(prod)
        prod = decimojo.utility.round_to_keep_first_n_digits(
            prod, ndigits_prod - (final_scale - Decimal.MAX_SCALE)
        )
        final_scale = Decimal.MAX_SCALE

    # Extract the 32-bit components from the UInt256 product
    var low = UInt32(prod & 0xFFFFFFFF)
    var mid = UInt32((prod >> 32) & 0xFFFFFFFF)
    var high = UInt32((prod >> 64) & 0xFFFFFFFF)

    return Decimal(low, mid, high, final_scale, is_negative)


fn true_divide(x1: Decimal, x2: Decimal) raises -> Decimal:
    """
    Divides x1 by x2 and returns a new Decimal containing the quotient.
    Uses a simpler string-based long division approach as fallback.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        A new Decimal containing the result of x1 / x2.

    Raises:
        Error: If x2 is zero.
    """

    # print("----------------------------------------")
    # print("DEBUG divide()")
    # print("DEBUG: x1", x1)
    # print("DEBUG: x2", x2)

    # Treatment for special cases
    # 對各類特殊情況進行處理

    # SPECIAL CASE: zero divisor
    # 特例: 除數爲零
    # Check for division by zero
    if x2.is_zero():
        raise Error("Error in `__truediv__`: Division by zero")

    # SPECIAL CASE: zero dividend
    # If dividend is zero, return zero with appropriate scale
    # The final scale is the (scale 1 - scale 2) floored to 0
    # For example, 0.000 / 1234.0 = 0.00
    # For example, 0.00 / 1.3456 = 0
    if x1.is_zero():
        var result = Decimal.ZERO()
        var result_scale = max(0, x1.scale() - x2.scale())
        result.flags = UInt32(
            (result_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
        )
        return result

    var x1_coef = x1.coefficient()
    var x2_coef = x2.coefficient()
    var x1_scale = x1.scale()
    var x2_scale = x2.scale()
    var diff_scale = x1_scale - x2_scale
    var is_negative = x1.is_negative() != x2.is_negative()

    # SPECIAL CASE: one dividend or coefficient of dividend is one
    # 特例: 除數爲一或者除數的係數爲一
    # Return divisor with appropriate scale and sign
    # For example, 1.412 / 1 = 1.412
    # For example, 10.123 / 0.0001 = 101230
    # For example, 1991.10180000 / 0.01 = 199110.180000
    if x2_coef == 1:
        # SUB-CASE: divisor is 1
        # If divisor is 1, return dividend with correct sign
        if x2_scale == 0:
            return Decimal(x1.low, x1.mid, x1.high, x1_scale, is_negative)

        # SUB-CASE: divisor is of coefficient 1 with positive scale
        # diff_scale > 0, then final scale is diff_scale
        elif diff_scale > 0:
            return Decimal(x1.low, x1.mid, x1.high, diff_scale, is_negative)

        # diff_scale < 0, then times 10 ** (-diff_scale)
        else:
            # print("DEBUG: x1_coef", x1_coef)
            # print("DEBUG: x1_scale", x1_scale)
            # print("DEBUG: x2_coef", x2_coef)
            # print("DEBUG: x2_scale", x2_scale)
            # print("DEBUG: diff_scale", diff_scale)

            # If the result can be stored in UInt128
            if (
                decimojo.utility.number_of_digits(x1_coef) - diff_scale
                < Decimal.MAX_NUM_DIGITS
            ):
                var quot = x1_coef * UInt128(10) ** (-diff_scale)
                # print("DEBUG: quot", quot)
                var low = UInt32(quot & 0xFFFFFFFF)
                var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
                var high = UInt32((quot >> 64) & 0xFFFFFFFF)
                return Decimal(low, mid, high, 0, is_negative)

            # If the result should be stored in UInt256
            else:
                var quot = UInt256(x1_coef) * UInt256(10) ** (-diff_scale)
                # print("DEBUG: quot", quot)
                if quot > Decimal.MAX_AS_UINT256:
                    raise Error("Error in `true_divide()`: Decimal overflow")
                else:
                    var low = UInt32(quot & 0xFFFFFFFF)
                    var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
                    var high = UInt32((quot >> 64) & 0xFFFFFFFF)
                    return Decimal(low, mid, high, 0, is_negative)

    # SPECIAL CASE: The coefficients are equal
    # 特例: 係數相等
    # For example, 1234.5678 / 1234.5678 = 1.0000
    # Return 1 with appropriate scale and sign
    if x1_coef == x2_coef:
        # SUB-CASE: The scales are equal
        # If the scales are equal, return 1 with the scale of 0
        # For example, 1234.5678 / 1234.5678 = 1
        # SUB-CASE: The scales are positive
        # If the scales are positive, return 1 with the difference in scales
        # For example, 0.1234 / 1234 = 0.0001
        if diff_scale >= 0:
            return Decimal(1, 0, 0, diff_scale, is_negative)

        # SUB-CASE: The scales are negative
        # diff_scale < 0, then times 1e-diff_scale
        # For example, 1234 / 0.1234 = 10000
        # Since -diff_scale is less than 28, the result would not overflow
        else:
            var quot = UInt128(1) * UInt128(10) ** (-diff_scale)
            var low = UInt32(quot & 0xFFFFFFFF)
            var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
            var high = UInt32((quot >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, 0, is_negative)

    # SPECIAL CASE: Modulus of coefficients is zero (exact division)
    # 特例: 係數的餘數爲零 (可除盡)
    # For example, 32 / 2 = 16
    # For example, 18.00 / 3.0 = 6.0
    # For example, 123456780000 / 1000 = 123456780
    # For example, 246824.68 / 12.341234 = 20000
    if x1_coef % x2_coef == 0:
        if diff_scale >= 0:
            # If diff_scale >= 0, return the quotient with diff_scale
            # Yuhao's notes:
            # Because the dividor == 1 has been handled before dividor shoud be greater than 1
            # High will be zero because the quotient is less than 2^48
            # For safety, we still calcuate the high word
            var quot = x1_coef // x2_coef
            var low = UInt32(quot & 0xFFFFFFFF)
            var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
            var high = UInt32((quot >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, diff_scale, is_negative)

        else:
            # If diff_scale < 0, return the quotient with scaling up
            # Posibly overflow, so we need to check

            var quot = x1_coef // x2_coef

            # If the result can be stored in UInt128
            if (
                decimojo.utility.number_of_digits(quot) - diff_scale
                < Decimal.MAX_NUM_DIGITS
            ):
                var quot = quot * UInt128(10) ** (-diff_scale)
                var low = UInt32(quot & 0xFFFFFFFF)
                var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
                var high = UInt32((quot >> 64) & 0xFFFFFFFF)
                return Decimal(low, mid, high, 0, is_negative)

            # If the result should be stored in UInt256
            else:
                var quot = UInt256(quot) * UInt256(10) ** (-diff_scale)
                if quot > Decimal.MAX_AS_UINT256:
                    raise Error("Error in `true_divide()`: Decimal overflow")
                else:
                    var low = UInt32(quot & 0xFFFFFFFF)
                    var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
                    var high = UInt32((quot >> 64) & 0xFFFFFFFF)
                    return Decimal(low, mid, high, 0, is_negative)

    # REMAINING CASES: Perform long division
    # 其他情況: 進行長除法
    #
    # Example: 123456.789 / 12.8 = 964506.1640625
    # x1_coef = 123456789, x2_coef = 128
    # x1_scale = 3, x2_scale = 1, diff_scale = 2
    # Step 0: 123456789 // 128 -> quot = 964506, rem = 21
    # Step 1: (21 * 10) // 128 -> quot = 1, rem = 82
    # Step 2: (82 * 10) // 128 -> quot = 6, rem = 52
    # Step 3: (52 * 10) // 128 -> quot = 4, rem = 8
    # Step 4: (8 * 10) // 128 -> quot = 0, rem = 80
    # Step 5: (80 * 10) // 128 -> quot = 6, rem = 32
    # Step 6: (32 * 10) // 128 -> quot = 2, rem = 64
    # Step 7: (64 * 10) // 128 -> quot = 5, rem = 0
    # Result: 9645061640625 with scale 9 (= step_counter + diff_scale)
    #
    # Example: 12345678.9 / 1.28 = 9645061.640625
    # x1_coef = 123456789, x2_coef = 128
    # x1_scale = 1, x2_scale = 2, diff_scale = -1
    # Result: 9645061640625 with scale 6 (= step_counter + diff_scale)
    #
    # Long division algorithm
    # Stop when remainder is zero or precision is reached or the optimal number of steps is reached
    #
    # Yuhao's notes: How to determine the optimal number of steps?
    # First, we need to consider that the max scale (precision) is 28
    # Second, we need to consider the significant digits of the quotient
    # EXAMPLE: 1 / 1.1111111111111111111111111111 ~= 0.900000000000000000000000000090
    # If we only consider the precision, we just need 28 steps
    # Then quotient of coefficients would be zeros
    # Approach 1: The optimal number of steps should be approximately
    #             max_len - diff_digits - digits_of_first_quotient + 1
    # Approach 2: Times 10**(-diff_digits) to the dividend and then perform the long division
    #             The number of steps is set to be max_len - digits_of_first_quotient + 1
    #             so that we just need to scale up one than loop -diff_digits times
    #
    # Get intitial quotient and remainder
    # Yuhao's notes: remainder should be positive beacuse the previous cases have been handled
    # 朱宇浩注: 餘數應該爲正,因爲之前的特例已經處理過了

    var x1_ndigits = decimojo.utility.number_of_digits(x1_coef)
    var x2_ndigits = decimojo.utility.number_of_digits(x2_coef)
    var diff_digits = x1_ndigits - x2_ndigits
    # Here is an estimation of the maximum possible number of digits of the quotient's integral part
    # If it is higher than 28, we need to use UInt256 to store the quotient
    var est_max_ndigits_quot_int_part = diff_digits - diff_scale + 1
    var is_use_uint128 = est_max_ndigits_quot_int_part < Decimal.MAX_NUM_DIGITS

    # SUB-CASE: Use UInt128 to store the quotient
    # If the quotient's integral part is less than 28 digits, we can use UInt128
    # if is_use_uint128:
    var quot: UInt128
    var rem: UInt128
    var adjusted_scale = 0

    # The adjusted dividend coefficient will not exceed 2^96 - 1
    if diff_digits < 0:
        var adjusted_x1_coef = x1_coef * UInt128(10) ** (-diff_digits)
        quot = adjusted_x1_coef // x2_coef
        rem = adjusted_x1_coef % x2_coef
        adjusted_scale = -diff_digits
    else:
        quot = x1_coef // x2_coef
        rem = x1_coef % x2_coef

    if is_use_uint128:
        # Maximum number of steps is minimum of the following two values:
        # - MAX_NUM_DIGITS - ndigits_initial_quot + 1
        # - Decimal.MAX_SCALE - diff_scale - adjusted_scale + 1 (significant digits be rounded off)
        # ndigits_initial_quot is the number of digits of the quotient before using long division
        # The extra digit is used for rounding up when it is 5 and not exact division

        # digit is the tempory quotient digit
        var digit = UInt128(0)
        # The final step counter stands for the number of dicimal points
        var step_counter = 0
        var ndigits_initial_quot = decimojo.utility.number_of_digits(quot)
        while (
            (rem != 0)
            and (
                step_counter
                < (Decimal.MAX_NUM_DIGITS - ndigits_initial_quot + 1)
            )
            and (
                step_counter
                < Decimal.MAX_SCALE - diff_scale - adjusted_scale + 1
            )
        ):
            # Multiply remainder by 10
            rem *= 10
            # Calculate next quotient digit
            digit = rem // x2_coef
            quot = quot * 10 + digit
            # Calculate new remainder
            rem = rem % x2_coef
            # Increment step counter
            step_counter += 1
            # Check if division is exact

        # Yuhao's notes: When the remainder is non-zero at the end and the the digit to round is 5
        # we always round up, even if the rounding mode is round half to even
        # 朱宇浩注: 捨去項爲5時,其後方的數字可能會影響捨去項,但後方數字可能是無限位,所以無法確定
        # 比如: 1.0000000000000000000000000000_5 可能是 1.0000000000000000000000000000_5{100 zeros}1
        # 但我們只能算到 1.0000000000000000000000000000_5,
        # 在銀行家捨去法中,我們將捨去項爲5時,向上捨去, 保留28位後爲1.0000000000000000000000000000
        # 這樣的捨去法是不準確的,所以我們一律在到達餘數非零且捨去項爲5時,向上捨去
        var is_exact_division: Bool = False
        if rem == 0:
            is_exact_division = True
        else:
            if digit == 5:
                # Not exact division, round up the last digit
                quot += 1

        var scale_of_quot = step_counter + diff_scale + adjusted_scale

        # If the scale is negative, we need to scale up the quotient
        if scale_of_quot < 0:
            quot = quot * UInt128(10) ** (-scale_of_quot)
            scale_of_quot = 0
        var ndigits_quot = decimojo.utility.number_of_digits(quot)
        var ndigits_quot_int_part = ndigits_quot - scale_of_quot

        # If quot is within MAX, return the result
        if quot <= Decimal.MAX_AS_UINT128:
            if scale_of_quot > Decimal.MAX_SCALE:
                quot = decimojo.utility.round_to_keep_first_n_digits(
                    quot,
                    ndigits_quot - (scale_of_quot - Decimal.MAX_SCALE),
                )
                scale_of_quot = Decimal.MAX_SCALE

            var low = UInt32(quot & 0xFFFFFFFF)
            var mid = UInt32((quot >> 32) & 0xFFFFFFFF)
            var high = UInt32((quot >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, scale_of_quot, is_negative)

        # Otherwise, we need to truncate the first 29 or 28 digits
        else:
            var truncated_quot = decimojo.utility.round_to_keep_first_n_digits(
                quot, Decimal.MAX_NUM_DIGITS
            )
            var scale_of_truncated_quot = (
                Decimal.MAX_NUM_DIGITS - ndigits_quot_int_part
            )

            if truncated_quot > Decimal.MAX_AS_UINT128:
                truncated_quot = decimojo.utility.round_to_keep_first_n_digits(
                    quot, Decimal.MAX_NUM_DIGITS - 1
                )
                scale_of_truncated_quot -= 1

            if scale_of_truncated_quot > Decimal.MAX_SCALE:
                var num_digits_truncated_quot = decimojo.utility.number_of_digits(
                    truncated_quot
                )
                truncated_quot = decimojo.utility.round_to_keep_first_n_digits(
                    truncated_quot,
                    num_digits_truncated_quot
                    - (scale_of_truncated_quot - Decimal.MAX_SCALE),
                )
                scale_of_truncated_quot = Decimal.MAX_SCALE

            var low = UInt32(truncated_quot & 0xFFFFFFFF)
            var mid = UInt32((truncated_quot >> 32) & 0xFFFFFFFF)
            var high = UInt32((truncated_quot >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, scale_of_truncated_quot, is_negative)

    # SUB-CASE: Use UInt256 to store the quotient
    # Also the FALLBACK approach for the remaining cases
    # If the quotient's integral part is possibly more than 28 digits, we use UInt256
    # It is almost the same also the case above, so we just use the same code

    else:
        # Maximum number of steps is MAX_NUM_DIGITS - ndigits_initial_quot + 1
        # The extra digit is used for rounding up when it is 5 and not exact division
        # 最大步數加一,用於捨去項爲5且非精確相除時向上捨去

        var quot256: UInt256 = UInt256(quot)
        var rem256: UInt256 = UInt256(rem)
        # digit is the tempory quotient digit
        var digit = UInt256(0)
        # The final step counter stands for the number of dicimal points
        var step_counter = 0
        var ndigits_initial_quot = decimojo.utility.number_of_digits(quot256)
        while (
            (rem256 != 0)
            and (
                step_counter
                < (Decimal.MAX_NUM_DIGITS - ndigits_initial_quot + 1)
            )
            and (
                step_counter
                < Decimal.MAX_SCALE - diff_scale - adjusted_scale + 1
            )
        ):
            # Multiply remainder by 10
            rem256 *= 10
            # Calculate next quotient digit
            digit = rem256 // UInt256(x2_coef)
            quot256 = quot256 * 10 + digit
            # Calculate new remainder
            rem256 = rem256 % UInt256(x2_coef)
            # Increment step counter
            step_counter += 1
            # Check if division is exact

        var is_exact_division: Bool = False
        if rem256 == 0:
            is_exact_division = True
        else:
            if digit == 5:
                # Not exact division, round up the last digit
                quot256 += 1

        var scale_of_quot = step_counter + diff_scale + adjusted_scale

        # If the scale is negative, we need to scale up the quotient
        if scale_of_quot < 0:
            quot256 = quot256 * UInt256(10) ** (-scale_of_quot)
            scale_of_quot = 0
        var ndigits_quot = decimojo.utility.number_of_digits(quot256)
        var ndigits_quot_int_part = ndigits_quot - scale_of_quot

        # If quot is within MAX, return the result
        if quot256 <= Decimal.MAX_AS_UINT256:
            if scale_of_quot > Decimal.MAX_SCALE:
                quot256 = decimojo.utility.round_to_keep_first_n_digits(
                    quot256,
                    ndigits_quot - (scale_of_quot - Decimal.MAX_SCALE),
                )
                scale_of_quot = Decimal.MAX_SCALE

            var low = UInt32(quot256 & 0xFFFFFFFF)
            var mid = UInt32((quot256 >> 32) & 0xFFFFFFFF)
            var high = UInt32((quot256 >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, scale_of_quot, is_negative)

        # Otherwise, we need to truncate the first 29 or 28 digits
        else:
            var truncated_quot = decimojo.utility.round_to_keep_first_n_digits(
                quot256, Decimal.MAX_NUM_DIGITS
            )

            # If integer part of quot is more than max, raise error
            if (ndigits_quot_int_part > Decimal.MAX_NUM_DIGITS) or (
                (ndigits_quot_int_part == Decimal.MAX_NUM_DIGITS)
                and (truncated_quot > Decimal.MAX_AS_UINT256)
            ):
                raise Error("Error in `true_divide()`: Decimal overflow")

            var scale_of_truncated_quot = (
                Decimal.MAX_NUM_DIGITS - ndigits_quot_int_part
            )

            if truncated_quot > Decimal.MAX_AS_UINT256:
                truncated_quot = decimojo.utility.round_to_keep_first_n_digits(
                    quot256, Decimal.MAX_NUM_DIGITS - 1
                )
                scale_of_truncated_quot -= 1

            if scale_of_truncated_quot > Decimal.MAX_SCALE:
                var num_digits_truncated_quot = decimojo.utility.number_of_digits(
                    truncated_quot
                )
                truncated_quot = decimojo.utility.round_to_keep_first_n_digits(
                    truncated_quot,
                    num_digits_truncated_quot
                    - (scale_of_truncated_quot - Decimal.MAX_SCALE),
                )
                scale_of_truncated_quot = Decimal.MAX_SCALE

            var low = UInt32(truncated_quot & 0xFFFFFFFF)
            var mid = UInt32((truncated_quot >> 32) & 0xFFFFFFFF)
            var high = UInt32((truncated_quot >> 64) & 0xFFFFFFFF)

            return Decimal(low, mid, high, scale_of_truncated_quot, is_negative)
