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

# ===----------------------------------------------------------------------=== #
# Arithmetic operations functions
# ===----------------------------------------------------------------------=== #


fn _addition_string_based(a: Decimal, b: Decimal) -> String:
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
            return _subtraction_string_based(b, -a)
        else:
            # a + (-b) = a - |b|
            return _subtraction_string_based(a, -b)

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
    var a_coef = a.coefficient()
    var b_coef = b.coefficient()
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


fn _subtraction_string_based(owned a: Decimal, owned b: Decimal) -> String:
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
            var sum_result = _addition_string_based(-a, b)
            if sum_result == "0":
                return "0." + "0" * target_decimal_places
            return "-" + sum_result
        else:
            # a - (-b) = a + b
            return _addition_string_based(a, -b)

    # At this point, both numbers have the same sign
    var is_negative = a.is_negative()  # Both a and b have the same sign

    # Compare absolute values to determine which is larger
    var a_larger = True
    var a_coef = a.coefficient()
    var b_coef = b.coefficient()
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
    a_coef = a.coefficient()
    b_coef = b.coefficient()
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


# ===------------------------------------------------------------------------===#
# Rounding
# ===------------------------------------------------------------------------===#


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
