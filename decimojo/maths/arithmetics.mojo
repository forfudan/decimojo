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
                - decimojo.utility.number_of_significant_digits(summation),
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
                - decimojo.utility.number_of_significant_digits(diff),
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
            final_scale = decimojo.utility.number_of_significant_digits(
                truncated_summation
            ) - (
                decimojo.utility.number_of_significant_digits(summation)
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
            final_scale = decimojo.utility.number_of_significant_digits(
                truncated_summation
            ) - (
                decimojo.utility.number_of_significant_digits(summation)
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


fn multiply(x1: Decimal, x2: Decimal) -> Decimal:
    """
    Multiplies two Decimal values and returns a new Decimal containing the product.

    Args:
        x1: The first Decimal operand.
        x2: The second Decimal operand.

    Returns:
        A new Decimal containing the product of x1 and x2.
    """
    # Special cases for zero
    if x1.is_zero() or x2.is_zero():
        # For zero, we need to preserve the scale
        var result = Decimal.ZERO()
        var result_scale = min(x1.scale() + x2.scale(), Decimal.MAX_PRECISION)
        result.flags = UInt32(
            (result_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
        )
        return result

    # Calculate the combined scale (sum of both scales)
    var combined_scale = x1.scale() + x2.scale()

    # Determine the sign of the result (XOR of signs)
    var result_is_negative = x1.is_negative() != x2.is_negative()

    # Extract the components for multiplication
    var a_low = UInt64(x1.low)
    var a_mid = UInt64(x1.mid)
    var a_high = UInt64(x1.high)

    var b_low = UInt64(x2.low)
    var b_mid = UInt64(x2.mid)
    var b_high = UInt64(x2.high)

    # Perform 96-bit by 96-bit multiplication
    var r0 = a_low * b_low
    var r1_a = a_low * b_mid
    var r1_b = a_mid * b_low
    var r2_a = a_low * b_high
    var r2_b = a_mid * b_mid
    var r2_c = a_high * b_low
    var r3_a = a_mid * b_high
    var r3_b = a_high * b_mid
    var r4 = a_high * b_high

    # Accumulate results with carries
    var c0 = r0 & 0xFFFFFFFF
    var c1 = (r0 >> 32) + (r1_a & 0xFFFFFFFF) + (r1_b & 0xFFFFFFFF)
    var c2 = (r1_a >> 32) + (r1_b >> 32) + (r2_a & 0xFFFFFFFF) + (
        r2_b & 0xFFFFFFFF
    ) + (r2_c & 0xFFFFFFFF) + (c1 >> 32)
    c1 = c1 & 0xFFFFFFFF  # Mask after carry

    var c3 = (r2_a >> 32) + (r2_b >> 32) + (r2_c >> 32) + (
        r3_a & 0xFFFFFFFF
    ) + (r3_b & 0xFFFFFFFF) + (c2 >> 32)
    c2 = c2 & 0xFFFFFFFF  # Mask after carry

    var c4 = (r3_a >> 32) + (r3_b >> 32) + (c3 >> 32) + r4
    c3 = c3 & 0xFFFFFFFF  # Mask after carry

    var result_low = UInt32(c0)
    var result_mid = UInt32(c1)
    var result_high = UInt32(c2)

    # If we have overflow, we need to adjust the scale by dividing
    # BUT ONLY enough to fit the result in 96 bits - no more
    var scale_reduction = 0
    if c3 > 0 or c4 > 0:
        # Calculate minimum shifts needed to fit the result
        while c3 > 0 or c4 > 0:
            var remainder = UInt64(0)

            # Process c4
            var new_c4 = c4 / 10
            remainder = c4 % 10

            # Process c3 with remainder from c4
            var new_c3 = (remainder << 32 | c3) / 10
            remainder = (remainder << 32 | c3) % 10

            # Process c2 with remainder from c3
            var new_c2 = (remainder << 32 | c2) / 10
            remainder = (remainder << 32 | c2) % 10

            # Process c1 with remainder from c2
            var new_c1 = (remainder << 32 | c1) / 10
            remainder = (remainder << 32 | c1) % 10

            # Process c0 with remainder from c1
            var new_c0 = (remainder << 32 | c0) / 10

            # Update values
            c4 = new_c4
            c3 = new_c3
            c2 = new_c2
            c1 = new_c1
            c0 = new_c0

            scale_reduction += 1

        # Update result components after shifting
        result_low = UInt32(c0)
        result_mid = UInt32(c1)
        result_high = UInt32(c2)

    # Create the result with adjusted values
    var result = Decimal(result_low, result_mid, result_high, 0)

    # IMPORTANT: We account for the scale reduction separately from MAX_PRECISION capping
    # First, apply the technical scale reduction needed due to overflow
    var adjusted_scale = combined_scale - scale_reduction

    # THEN cap at MAX_PRECISION
    var final_scale = min(adjusted_scale, Decimal.MAX_SCALE)

    # Set the flags with the correct scale
    result.flags = UInt32(
        (final_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
    )
    if result_is_negative:
        result.flags |= Decimal.SIGN_MASK

    # Handle excess precision separately AFTER handling overflow
    # (this shouldn't be reducing scale twice)
    if adjusted_scale > Decimal.MAX_PRECISION:
        var scale_diff = adjusted_scale - Decimal.MAX_PRECISION
        result = result._scale_down(scale_diff, RoundingMode.HALF_EVEN())

    return result


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


# TODO: Remove this if Mojo stable version introduces UInt256
fn _add_decimals_as_string(a: Decimal, b: Decimal) -> String:
    """
    Performs addition of two Decimals using a string-based approach.
    Preserves decimal places to match the inputs.

    Args:
        a: First Decimal operand.
        b: Second Decimal operand.

    Returns:
        A string representation of the sum with decimal places preserved.
    """
    # Special case: if either number is zero, return the other
    if a.is_zero():
        return String(b)
    if b.is_zero():
        return String(a)

    # Handle different signs
    if a.is_negative() != b.is_negative():
        # If signs differ, we need subtraction
        if a.is_negative():
            # -a + b = b - |a|
            return _subtract_decimals_as_string(b, -a)
        else:
            # a + (-b) = a - |b|
            return _subtract_decimals_as_string(a, -b)

    # Determine the number of decimal places to preserve
    # We need to examine the original string representation of a and b
    var a_str = String(a)
    var b_str = String(b)
    var a_decimal_places = 0
    var b_decimal_places = 0

    # Count decimal places in a
    var a_decimal_pos = a_str.find(".")
    if a_decimal_pos >= 0:
        a_decimal_places = len(a_str) - a_decimal_pos - 1

    # Count decimal places in b
    var b_decimal_pos = b_str.find(".")
    if b_decimal_pos >= 0:
        b_decimal_places = len(b_str) - b_decimal_pos - 1

    # Determine target decimal places (maximum of both inputs)
    var target_decimal_places = max(a_decimal_places, b_decimal_places)

    # At this point, both numbers have the same sign
    var is_negative = a.is_negative()  # and b.is_negative() is the same

    # Step 1: Get coefficient strings (absolute values)
    var a_coef = String(a.coefficient())
    var b_coef = String(b.coefficient())
    var a_scale = a.scale()
    var b_scale = b.scale()

    # Step 2: Align decimal points
    var max_scale = max(a_scale, b_scale)

    # Pad coefficients with trailing zeros to align decimal points
    if a_scale < max_scale:
        a_coef += "0" * (max_scale - a_scale)
    if b_scale < max_scale:
        b_coef += "0" * (max_scale - b_scale)

    # Ensure both strings are the same length by padding with leading zeros
    var max_length = max(len(a_coef), len(b_coef))
    a_coef = "0" * (max_length - len(a_coef)) + a_coef
    b_coef = "0" * (max_length - len(b_coef)) + b_coef

    # Step 3: Perform addition from right to left
    var result = String("")
    var carry = 0

    for i in range(len(a_coef) - 1, -1, -1):
        var digit_a = ord(a_coef[i]) - ord("0")
        var digit_b = ord(b_coef[i]) - ord("0")

        var digit_sum = digit_a + digit_b + carry
        carry = digit_sum // 10
        result = String(digit_sum % 10) + result

    # Handle final carry
    if carry > 0:
        result = String(carry) + result

    # Step 4: Insert decimal point at correct position
    var final_result = String("")

    if max_scale == 0:
        # No decimal places, just return the result
        final_result = result
        # Add decimal point and zeros if needed to match target decimal places
        if target_decimal_places > 0:
            final_result += "." + "0" * target_decimal_places
    else:
        var decimal_pos = len(result) - max_scale

        if decimal_pos <= 0:
            # Result is less than 1, need leading zeros
            final_result = "0." + "0" * (0 - decimal_pos) + result

            # Ensure we have enough decimal places to match target
            var current_decimals = len(result) + (0 - decimal_pos)
            if current_decimals < target_decimal_places:
                final_result += "0" * (target_decimal_places - current_decimals)
        else:
            # Insert decimal point
            final_result = result[:decimal_pos] + "." + result[decimal_pos:]

            # Ensure we have enough decimal places to match target
            var current_decimals = len(result) - decimal_pos
            if current_decimals < target_decimal_places:
                final_result += "0" * (target_decimal_places - current_decimals)

    # Add negative sign if needed
    if (
        is_negative
        and final_result != "0"
        and final_result != "0." + "0" * target_decimal_places
    ):
        final_result = "-" + final_result

    return final_result


# TODO: Remove this if Mojo stable version introduces UInt256
fn _subtract_decimals_as_string(owned a: Decimal, owned b: Decimal) -> String:
    """
    Helper function to perform subtraction of b from a.
    Handles cases for all sign combinations and preserves decimal places.

    Args:
        a: First Decimal operand (minuend).
        b: Second Decimal operand (subtrahend).

    Returns:
        A string representation of the difference with decimal places preserved.
    """
    # Determine the number of decimal places to preserve
    # We need to examine the original string representation of a and b
    var a_str = String(a)
    var b_str = String(b)
    var a_decimal_places = 0
    var b_decimal_places = 0

    # Count decimal places in a
    var a_decimal_pos = a_str.find(".")
    if a_decimal_pos >= 0:
        a_decimal_places = len(a_str) - a_decimal_pos - 1

    # Count decimal places in b
    var b_decimal_pos = b_str.find(".")
    if b_decimal_pos >= 0:
        b_decimal_places = len(b_str) - b_decimal_pos - 1

    # Determine target decimal places (maximum of both inputs)
    var target_decimal_places = max(a_decimal_places, b_decimal_places)

    # Handle different signs
    if a.is_negative() != b.is_negative():
        # When signs differ, subtraction becomes addition
        if a.is_negative():
            # -a - b = -(a + b)
            var sum_result = _add_decimals_as_string(-a, b)
            if sum_result == "0":
                return "0." + "0" * target_decimal_places
            return "-" + sum_result
        else:
            # a - (-b) = a + b
            return _add_decimals_as_string(a, -b)

    # At this point, both numbers have the same sign
    var is_negative = a.is_negative()  # Both a and b have the same sign

    # Compare absolute values to determine which is larger
    var a_larger = True
    var a_coef = String(a.coefficient())
    var b_coef = String(b.coefficient())
    var a_scale = a.scale()
    var b_scale = b.scale()

    # First compare by number of digits before decimal point
    var a_int_digits = len(a_coef) - a_scale
    var b_int_digits = len(b_coef) - b_scale

    if a_int_digits < b_int_digits:
        a_larger = False
    elif a_int_digits == b_int_digits:
        # If same number of integer digits, align decimal points and compare
        var max_scale = max(a_scale, b_scale)

        # Pad coefficients with trailing zeros to align
        var a_padded = a_coef + "0" * (max_scale - a_scale)
        var b_padded = b_coef + "0" * (max_scale - b_scale)

        # Ensure both are the same length
        var max_length = max(len(a_padded), len(b_padded))
        a_padded = "0" * (max_length - len(a_padded)) + a_padded
        b_padded = "0" * (max_length - len(b_padded)) + b_padded

        # Compare digit by digit
        a_larger = a_padded >= b_padded

    # Determine sign of result based on comparison and original signs
    var result_is_negative = is_negative
    if not a_larger:
        # If |a| < |b|, then:
        # For positive numbers: a - b = -(b - a)
        # For negative numbers: -a - (-b) = -a + b = b - a = -(-(b - a)) = -(b - a)
        # So result sign is flipped from original
        result_is_negative = not result_is_negative

        # Swap a and b so we always subtract smaller from larger
        a, b = b, a

    # Now |a| is guaranteed to be >= |b|
    # Align decimal points again for the actual subtraction
    var max_scale = max(a.scale(), b.scale())

    # Get coefficients again (after possible swap)
    a_coef = String(a.coefficient())
    b_coef = String(b.coefficient())
    a_scale = a.scale()
    b_scale = b.scale()

    # Pad coefficients with trailing zeros to align decimal points
    a_coef += "0" * (max_scale - a_scale)
    b_coef += "0" * (max_scale - b_scale)

    # Ensure both strings are the same length
    var max_length = max(len(a_coef), len(b_coef))
    a_coef = "0" * (max_length - len(a_coef)) + a_coef
    b_coef = "0" * (max_length - len(b_coef)) + b_coef

    # Perform subtraction from right to left
    var result = String("")
    var borrow = 0

    for i in range(len(a_coef) - 1, -1, -1):
        var digit_a = ord(a_coef[i]) - ord("0") - borrow
        var digit_b = ord(b_coef[i]) - ord("0")

        if digit_a < digit_b:
            digit_a += 10
            borrow = 1
        else:
            borrow = 0

        var digit_diff = digit_a - digit_b
        result = String(digit_diff) + result

    # Remove leading zeros (but keep at least one digit before decimal point)
    var start_idx = 0
    while start_idx < len(result) - max_scale - 1 and result[start_idx] == "0":
        start_idx += 1

    result = result[start_idx:]

    # Insert decimal point
    var final_result = String("")

    if max_scale == 0:
        # No decimal places in calculation, but we still need to consider target decimal places
        final_result = result
        if target_decimal_places > 0:
            final_result += "." + "0" * target_decimal_places
    else:
        var decimal_pos = len(result) - max_scale

        if decimal_pos <= 0:
            # Result is less than 1
            final_result = "0." + "0" * (0 - decimal_pos) + result

            # Ensure we have enough decimal places to match target
            var current_decimals = len(result) + (0 - decimal_pos)
            if current_decimals < target_decimal_places:
                final_result += "0" * (target_decimal_places - current_decimals)
        else:
            # Insert decimal point
            final_result = result[:decimal_pos] + "." + result[decimal_pos:]

            # Ensure we have enough decimal places to match target
            var current_decimals = len(result) - decimal_pos
            if current_decimals < target_decimal_places:
                final_result += "0" * (target_decimal_places - current_decimals)

    # Handle case where result is zero
    if final_result == "0" or final_result.startswith("0."):
        # Check if the result contains only zeros and decimal point
        var is_all_zero = True
        for i in range(len(final_result)):
            if final_result[i] != "0" and final_result[i] != ".":
                is_all_zero = False
                break

        if is_all_zero:
            return (
                "0." + "0" * target_decimal_places if target_decimal_places
                > 0 else "0"
            )

    var is_zero_point = True
    for i in range(len(final_result)):
        if final_result[i] != "0" and final_result[i] != ".":
            is_zero_point = False
            break

    # Add negative sign if needed
    if result_is_negative and not (
        final_result == "0"
        or
        # Check if string starts with "0." and contains only zeros and decimal point
        (final_result.startswith("0.") and (is_zero_point))
    ):
        final_result = "-" + final_result

    return final_result


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
