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
#
# ===----------------------------------------------------------------------=== #

"""
Implements functions for mathematical operations on Decimal objects.
"""

from decimojo.decimal import Decimal
from decimojo.rounding_mode import RoundingMode

# ===----------------------------------------------------------------------=== #
# Binary arithmetic operations functions
# ===----------------------------------------------------------------------=== #


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
            x1.flags & x2.flags == Decimal.SIGN_MASK,
            max(x1.scale(), x2.scale()),
        )

    elif x2.is_zero():
        return Decimal(
            x1.low,
            x1.mid,
            x1.high,
            x1.flags & x2.flags == Decimal.SIGN_MASK,
            max(x1.scale(), x2.scale()),
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

            return Decimal(low, mid, high, x1.is_negative(), 0)

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

            return Decimal(low, mid, high, is_negative, 0)

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
                Decimal.MAX_VALUE_DIGITS
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

            return Decimal(low, mid, high, x1.is_negative(), scale)

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
                Decimal.MAX_VALUE_DIGITS
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

            return Decimal(low, mid, high, is_negative, scale)

    # Float addition with the same scale
    elif x1.scale() == x2.scale():
        var summation: Int128  # 97-bit signed integer can be stored in Int128
        summation = (-1) ** x1.is_negative() * Int128(x1.coefficient()) + (
            -1
        ) ** x2.is_negative() * Int128(x2.coefficient())

        var is_nagative = summation < 0
        if is_nagative:
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

        return Decimal(low, mid, high, is_nagative, final_scale)

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

        var is_nagative = summation < 0
        if is_nagative:
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

        return Decimal(low, mid, high, is_nagative, final_scale)


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
    var is_nagative = x1.is_negative() != x2.is_negative()

    # SPECIAL CASE: zero
    # Return zero while preserving the scale
    if x1_coef == 0 or x2_coef == 0:
        var result = Decimal.ZERO()
        var result_scale = min(combined_scale, Decimal.MAX_PRECISION)
        result.flags = UInt32(
            (result_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
        )
        return result

    # SPECIAL CASE: Both operands have coefficient of 1
    if x1_coef == 1 and x2_coef == 1:
        # If the combined scale exceeds the maximum precision,
        # return 0 with leading zeros after the decimal point and correct sign
        if combined_scale > Decimal.MAX_PRECISION:
            return Decimal(
                0,
                0,
                0,
                is_nagative,
                Decimal.MAX_PRECISION,
            )
        # Otherwise, return 1 with correct sign and scale
        var final_scale = min(Decimal.MAX_PRECISION, combined_scale)
        return Decimal(1, 0, 0, is_nagative, final_scale)

    # SPECIAL CASE: First operand has coefficient of 1
    if x1_coef == 1:
        # If x1 is 1, return x2 with correct sign
        if x1_scale == 0:
            var result = x2
            result.flags &= ~Decimal.SIGN_MASK
            if is_nagative:
                result.flags |= Decimal.SIGN_MASK
            return result
        else:
            var mul = x2_coef
            # Rounding may be needed.
            var num_digits_mul = decimojo.utility.number_of_digits(mul)
            var num_digits_to_keep = num_digits_mul - (
                combined_scale - Decimal.MAX_PRECISION
            )
            var truncated_mul = decimojo.utility.truncate_to_digits(
                mul, num_digits_to_keep
            )
            var final_scale = min(Decimal.MAX_PRECISION, combined_scale)
            var low = UInt32(truncated_mul & 0xFFFFFFFF)
            var mid = UInt32((truncated_mul >> 32) & 0xFFFFFFFF)
            var high = UInt32((truncated_mul >> 64) & 0xFFFFFFFF)
            return Decimal(
                low,
                mid,
                high,
                is_nagative,
                final_scale,
            )

    # SPECIAL CASE: Second operand has coefficient of 1
    if x2_coef == 1:
        # If x2 is 1, return x1 with correct sign
        if x2_scale == 0:
            var result = x1
            result.flags &= ~Decimal.SIGN_MASK
            if is_nagative:
                result.flags |= Decimal.SIGN_MASK
            return result
        else:
            var mul = x1_coef
            # Rounding may be needed.
            var num_digits_mul = decimojo.utility.number_of_digits(mul)
            var num_digits_to_keep = num_digits_mul - (
                combined_scale - Decimal.MAX_PRECISION
            )
            var truncated_mul = decimojo.utility.truncate_to_digits(
                mul, num_digits_to_keep
            )
            var final_scale = min(Decimal.MAX_PRECISION, combined_scale)
            var low = UInt32(truncated_mul & 0xFFFFFFFF)
            var mid = UInt32((truncated_mul >> 32) & 0xFFFFFFFF)
            var high = UInt32((truncated_mul >> 64) & 0xFFFFFFFF)
            return Decimal(
                low,
                mid,
                high,
                is_nagative,
                final_scale,
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
            var mul: UInt64 = UInt64(x1.low) * UInt64(x2.low)
            var low = UInt32(mul & 0xFFFFFFFF)
            var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
            return Decimal(low, mid, 0, is_nagative, 0)

        # Moderate integers, use UInt128 multiplication
        elif combined_num_bits <= 128:
            var mul: UInt128 = UInt128(x1_coef) * UInt128(x2_coef)
            var low = UInt32(mul & 0xFFFFFFFF)
            var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
            var high = UInt32((mul >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, is_nagative, 0)

        # Large integers, use UInt256 multiplication
        else:
            var mul: UInt256 = UInt256(x1_coef) * UInt256(x2_coef)
            if mul > Decimal.MAX_AS_UINT256:
                raise Error("Error in `multiply()`: Decimal overflow")
            else:
                var low = UInt32(mul & 0xFFFFFFFF)
                var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
                var high = UInt32((mul >> 64) & 0xFFFFFFFF)
                return Decimal(low, mid, high, is_nagative, 0)

    # SPECIAL CASE: Both operands are integers but with scales
    # Examples: 123.0 * 456.00
    if x1.is_integer() and x2.is_integer():
        var x1_integral_part = x1_coef // (UInt128(10) ** UInt128(x1_scale))
        var x2_integral_part = x2_coef // (UInt128(10) ** UInt128(x2_scale))
        var mul: UInt256 = UInt256(x1_integral_part) * UInt256(x2_integral_part)
        if mul > Decimal.MAX_AS_UINT256:
            raise Error("Error in `multiply()`: Decimal overflow")
        else:
            var num_digits = decimojo.utility.number_of_digits(mul)
            var final_scale = min(
                Decimal.MAX_VALUE_DIGITS - num_digits, combined_scale
            )
            # Scale up before it overflows
            mul = mul * 10**final_scale
            if mul > Decimal.MAX_AS_UINT256:
                mul = mul // 10
                final_scale -= 1

            var low = UInt32(mul & 0xFFFFFFFF)
            var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
            var high = UInt32((mul >> 64) & 0xFFFFFFFF)
            return Decimal(
                low,
                mid,
                high,
                is_nagative,
                final_scale,
            )

    # GENERAL CASES: Decimal multiplication with any scales
    # TODO: Consider different sub-cases

    # SUB-CASE: Both operands are small
    # The bits of the product will not exceed 96 bits
    # It can just fit into Decimal's capacity without overflow
    # Result coefficient will less than 2^96 - 1 = 79228162514264337593543950335
    # Examples: 1.23 * 4.56
    if combined_num_bits <= 96:
        var mul: UInt128 = x1_coef * x2_coef

        # Combined scale more than max precision, no need to truncate
        if combined_scale <= Decimal.MAX_PRECISION:
            var low = UInt32(mul & 0xFFFFFFFF)
            var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
            var high = UInt32((mul >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, is_nagative, combined_scale)

        # Combined scale no more than max precision, truncate with rounding
        else:
            var num_digits = decimojo.utility.number_of_digits(mul)
            var num_digits_to_keep = num_digits - (
                combined_scale - Decimal.MAX_PRECISION
            )
            mul = decimojo.utility.truncate_to_digits(mul, num_digits_to_keep)
            var final_scale = min(Decimal.MAX_PRECISION, combined_scale)
            var low = UInt32(mul & 0xFFFFFFFF)
            var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
            var high = UInt32((mul >> 64) & 0xFFFFFFFF)
            return Decimal(low, mid, high, is_nagative, final_scale)

    # SUB-CASE: Both operands are moderate
    # The bits of the product will not exceed 128 bits
    # Result coefficient will less than 2^128 - 1 but more than 2^96 - 1
    # IMPORTANT: This means that the product will exceed Decimal's capacity
    # Either raises an error if intergral part overflows
    # Or truncates the product to fit into Decimal's capacity
    if combined_num_bits <= 128:
        var mul: UInt128 = x1_coef * x2_coef

        # Check outflow
        # The number of digits of the integral part
        var num_digits_of_integral_part = decimojo.utility.number_of_digits(
            mul
        ) - combined_scale
        # Truncated first 29 digits
        var truncated_mul_at_max_length = decimojo.utility.truncate_to_digits(
            mul, Decimal.MAX_VALUE_DIGITS
        )
        if (num_digits_of_integral_part >= Decimal.MAX_VALUE_DIGITS) & (
            truncated_mul_at_max_length > Decimal.MAX_AS_UINT128
        ):
            raise Error("Error in `multiply()`: Decimal overflow")

        # Otherwise, the value will not overflow even after rounding
        # Determine the final scale after rounding
        # If the first 29 digits does not exceed the limit,
        # the final coefficient can be of 29 digits.
        # The final scale can be 29 - num_digits_of_integral_part.
        var num_digits_of_decimal_part = Decimal.MAX_VALUE_DIGITS - num_digits_of_integral_part
        # If the first 29 digits exceed the limit,
        # we need to adjust the num_digits_of_decimal_part by -1
        # so that the final coefficient will be of 28 digits.
        if truncated_mul_at_max_length > Decimal.MAX_AS_UINT128:
            num_digits_of_decimal_part -= 1
            mul = decimojo.utility.truncate_to_digits(
                mul, Decimal.MAX_VALUE_DIGITS - 1
            )
        else:
            mul = truncated_mul_at_max_length

        # I think combined_scale should always be smaller
        var final_scale = min(num_digits_of_decimal_part, combined_scale)

        # Extract the 32-bit components from the UInt128 product
        var low = UInt32(mul & 0xFFFFFFFF)
        var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
        var high = UInt32((mul >> 64) & 0xFFFFFFFF)
        return Decimal(low, mid, high, is_nagative, final_scale)

    # REMAINING CASES: Both operands are big
    # The bits of the product will not exceed 192 bits
    # Result coefficient will less than 2^192 - 1 but more than 2^128 - 1
    # IMPORTANT: This means that the product will exceed Decimal's capacity
    # Either raises an error if intergral part overflows
    # Or truncates the product to fit into Decimal's capacity
    var mul: UInt256 = UInt256(x1_coef) * UInt256(x2_coef)

    # Check outflow
    # The number of digits of the integral part
    var num_digits_of_integral_part = decimojo.utility.number_of_digits(
        mul
    ) - combined_scale
    # Truncated first 29 digits
    var truncated_mul_at_max_length = decimojo.utility.truncate_to_digits(
        mul, Decimal.MAX_VALUE_DIGITS
    )
    # Check for overflow of the integral part after rounding
    if (num_digits_of_integral_part >= Decimal.MAX_VALUE_DIGITS) & (
        truncated_mul_at_max_length > Decimal.MAX_AS_UINT256
    ):
        raise Error("Error in `multiply()`: Decimal overflow")

    # Otherwise, the value will not overflow even after rounding
    # Determine the final scale after rounding
    # If the first 29 digits does not exceed the limit,
    # the final coefficient can be of 29 digits.
    # The final scale can be 29 - num_digits_of_integral_part.
    var num_digits_of_decimal_part = Decimal.MAX_VALUE_DIGITS - num_digits_of_integral_part
    # If the first 29 digits exceed the limit,
    # we need to adjust the num_digits_of_decimal_part by -1
    # so that the final coefficient will be of 28 digits.
    if truncated_mul_at_max_length > Decimal.MAX_AS_UINT256:
        num_digits_of_decimal_part -= 1
        mul = decimojo.utility.truncate_to_digits(
            mul, Decimal.MAX_VALUE_DIGITS - 1
        )
    else:
        mul = truncated_mul_at_max_length

    # I think combined_scale should always be smaller
    final_scale = min(num_digits_of_decimal_part, combined_scale)

    # Extract the 32-bit components from the UInt256 product
    var low = UInt32(mul & 0xFFFFFFFF)
    var mid = UInt32((mul >> 32) & 0xFFFFFFFF)
    var high = UInt32((mul >> 64) & 0xFFFFFFFF)

    return Decimal(low, mid, high, is_nagative, final_scale)


fn true_divide(x1: Decimal, x2: Decimal) raises -> Decimal:
    """
    Divides x1 by x2 and returns a new Decimal containing the quotient.
    Uses a simpler string-based long division approach.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        A new Decimal containing the result of x1 / x2.

    Raises:
        Error: If x2 is zero.
    """

    # Check for division by zero
    if x2.is_zero():
        raise Error("Error in `__truediv__`: Division by zero")

    # Special case: if dividend is zero, return zero with appropriate scale
    if x1.is_zero():
        var result = Decimal.ZERO()
        var result_scale = max(0, x1.scale() - x2.scale())
        result.flags = UInt32(
            (result_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
        )
        return result

    # If dividing identical numbers, return 1
    if (
        x1.low == x2.low
        and x1.mid == x2.mid
        and x1.high == x2.high
        and x1.scale() == x2.scale()
    ):
        return Decimal.ONE()

    # Determine sign of result (positive if signs are the same, negative otherwise)
    var result_is_negative = x1.is_negative() != x2.is_negative()

    # Get coefficients as strings (absolute values)
    var dividend_coef = String(x1.coefficient())
    var divisor_coef = String(x2.coefficient())

    # Use string-based division to avoid overflow with large numbers

    # Determine precision needed for calculation
    var working_precision = Decimal.MAX_VALUE_DIGITS + 1  # +1 for potential rounding

    # Perform long division algorithm
    var quotient = String("")
    var remainder = String("")
    var digit = 0
    var current_pos = 0
    var processed_all_dividend = False
    var number_of_significant_digits_of_quotient = 0

    while number_of_significant_digits_of_quotient < working_precision:
        # Grab next digit from dividend if available
        if current_pos < len(dividend_coef):
            remainder += dividend_coef[current_pos]
            current_pos += 1
        else:
            # If we've processed all dividend digits, add a zero
            if not processed_all_dividend:
                processed_all_dividend = True
            remainder += "0"

        # Remove leading zeros from remainder for cleaner comparison
        var remainder_start = 0
        while (
            remainder_start < len(remainder) - 1
            and remainder[remainder_start] == "0"
        ):
            remainder_start += 1
        remainder = remainder[remainder_start:]

        # Compare remainder with divisor to determine next quotient digit
        digit = 0
        var can_subtract = False

        # Check if remainder >= divisor_coef
        if len(remainder) > len(divisor_coef) or (
            len(remainder) == len(divisor_coef) and remainder >= divisor_coef
        ):
            can_subtract = True

        if can_subtract:
            # Find how many times divisor goes into remainder
            while True:
                # Try to subtract divisor from remainder
                var new_remainder = _subtract_strings(remainder, divisor_coef)
                if (
                    new_remainder[0] == "-"
                ):  # Negative result means we've gone too far
                    break
                remainder = new_remainder
                digit += 1

        # Add digit to quotient
        quotient += String(digit)
        number_of_significant_digits_of_quotient = len(
            decimojo.str._remove_leading_zeros(quotient)
        )

    # Check if division is exact
    var is_exact = remainder == "0" and current_pos >= len(dividend_coef)

    # Remove leading zeros
    var leading_zeros = 0
    for i in range(len(quotient)):
        if quotient[i] == "0":
            leading_zeros += 1
        else:
            break

    if leading_zeros == len(quotient):
        # All zeros, keep just one
        quotient = "0"
    elif leading_zeros > 0:
        quotient = quotient[leading_zeros:]

    # Handle trailing zeros for exact division
    var trailing_zeros = 0
    if is_exact and len(quotient) > 1:  # Don't remove single digit
        for i in range(len(quotient) - 1, 0, -1):
            if quotient[i] == "0":
                trailing_zeros += 1
            else:
                break

        if trailing_zeros > 0:
            quotient = quotient[: len(quotient) - trailing_zeros]

    # Calculate decimal point position
    var dividend_scientific_exponent = x1.scientific_exponent()
    var divisor_scientific_exponent = x2.scientific_exponent()
    var result_scientific_exponent = dividend_scientific_exponent - divisor_scientific_exponent

    if decimojo.str._remove_trailing_zeros(
        dividend_coef
    ) < decimojo.str._remove_trailing_zeros(divisor_coef):
        # If dividend < divisor, result < 1
        result_scientific_exponent -= 1

    var decimal_pos = result_scientific_exponent + 1

    # Format result with decimal point
    var result_str = String("")

    if decimal_pos <= 0:
        # decimal_pos <= 0, needs leading zeros
        # For example, decimal_pos = -1
        # 1234 -> 0.1234
        result_str = "0." + "0" * (-decimal_pos) + quotient
    elif decimal_pos >= len(quotient):
        # All digits are to the left of the decimal point
        # For example, decimal_pos = 5
        # 1234 -> 12340
        result_str = quotient + "0" * (decimal_pos - len(quotient))
    else:
        # Insert decimal point within the digits
        # For example, decimal_pos = 2
        # 1234 -> 12.34
        result_str = quotient[:decimal_pos] + "." + quotient[decimal_pos:]

    # Apply sign
    if result_is_negative and result_str != "0":
        result_str = "-" + result_str

    # Convert to Decimal and return
    var result = Decimal(result_str)

    return result


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


# ===----------------------------------------------------------------------=== #
# Unary arithmetic operations functions
# ===----------------------------------------------------------------------=== #


fn absolute(x: Decimal) raises -> Decimal:
    """
    Returns the absolute value of a Decimal number.

    Args:
        x: The Decimal value to compute the absolute value of.

    Returns:
        A new Decimal containing the absolute value of x.
    """
    if x.is_negative():
        return -x
    return x


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
        raise Error("Cannot compute square root of negative number")

    if x.is_zero():
        return Decimal.ZERO()

    if x == Decimal.ONE():
        return Decimal.ONE()

    # Working precision - we'll compute with extra digits and round at the end
    var working_precision = UInt32(x.scale() * 2)
    working_precision = max(working_precision, UInt32(10))  # At least 10 digits

    # Initial guess - a good guess helps converge faster
    # For numbers near 1, use the number itself
    # For very small or large numbers, scale appropriately
    var guess: Decimal
    var exponent = len(x.coefficient()) - x.scale()

    if exponent >= 0 and exponent <= 3:
        # For numbers between 0.1 and 1000, start with x/2 + 0.5
        try:
            var half_x = x / Decimal("2")
            guess = half_x + Decimal("0.5")
        except e:
            raise e
    else:
        # For larger/smaller numbers, make a smarter guess
        # This scales based on the magnitude of the number
        var shift: Int
        if exponent % 2 != 0:
            # For odd exponents, adjust
            shift = (exponent + 1) // 2
        else:
            shift = exponent // 2

        try:
            # Use an approximation based on the exponent
            if exponent > 0:
                guess = Decimal("10") ** shift
            else:
                guess = Decimal("0.1") ** (-shift)

        except e:
            raise e

    # Newton-Raphson iterations
    # x_n+1 = (x_n + S/x_n) / 2
    var prev_guess = Decimal.ZERO()
    var iteration_count = 0
    var max_iterations = 100  # Prevent infinite loops

    while guess != prev_guess and iteration_count < max_iterations:
        prev_guess = guess

        try:
            var division_result = x / guess
            var sum_result = guess + division_result
            guess = sum_result / Decimal("2")
        except e:
            raise e

        iteration_count += 1

    # Round to appropriate precision - typically half the working precision
    var result_precision = x.scale()
    if result_precision % 2 == 1:
        # For odd scales, add 1 to ensure proper rounding
        result_precision += 1

    # The result scale should be approximately half the input scale
    result_precision = result_precision // 2

    # Format to the appropriate number of decimal places
    var result_str = String(guess)

    try:
        var rounded_result = Decimal(result_str)
        return rounded_result
    except e:
        raise e


fn _subtract_strings(a: String, b: String) -> String:
    """
    Subtracts string b from string a and returns the result as a string.
    The input strings must be integers.

    Args:
        a: The string to subtract from. Must be an integer.
        b: The string to subtract. Must be an integer.

    Returns:
        A string containing the result of the subtraction.
    """

    # Ensure a is longer or equal to b by padding with zeros
    var a_padded = a
    var b_padded = b

    if len(a) < len(b):
        a_padded = "0" * (len(b) - len(a)) + a
    elif len(b) < len(a):
        b_padded = "0" * (len(a) - len(b)) + b

    var result = String("")
    var borrow = 0

    # Perform subtraction digit by digit from right to left
    for i in range(len(a_padded) - 1, -1, -1):
        var digit_a = ord(a_padded[i]) - ord("0")
        var digit_b = ord(b_padded[i]) - ord("0") + borrow

        if digit_a < digit_b:
            digit_a += 10
            borrow = 1
        else:
            borrow = 0

        result = String(digit_a - digit_b) + result

    # Check if result is negative
    if borrow > 0:
        return "-" + result

    # Remove leading zeros
    var start_idx = 0
    while start_idx < len(result) - 1 and result[start_idx] == "0":
        start_idx += 1

    return result[start_idx:]
