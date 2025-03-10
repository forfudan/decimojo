# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements internal utility functions for the Decimal type
# WARNING: These functions are not meant to be used directly by the user.
#
# ===----------------------------------------------------------------------=== #

from memory import UnsafePointer

from decimojo.decimal import Decimal


# UNSAFE
fn bitcast[dtype: DType](dec: Decimal) -> Scalar[dtype]:
    """
    Direct memory bit copy from Decimal (low, mid, high) to Mojo's Scalar type.
    This performs a bitcast/reinterpretation rather than bit manipulation.
    ***UNSAFE***: This function is unsafe and should be used with caution.

    Parameters:
        dtype: The Mojo scalar type to bitcast to.

    Args:
        dec: The Decimal to bitcast.

    Constraints:
        `dtype` must be `DType.uint128`.

    Returns:
        The bitcasted Decimal (low, mid, high) as a Mojo scalar.

    """

    # Compile-time checker: ensure the dtype is either uint128 or uint256
    constrained[
        dtype == DType.uint128,
        "must be uint128",
    ]()

    # Bitcast the Decimal to the desired Mojo scalar type
    var result = UnsafePointer[Decimal].address_of(dec).bitcast[
        Scalar[dtype]
    ]().load()
    # Mask out the bits in flags
    result &= 0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF
    return result


fn scale_up(value: Decimal, owned level: Int) raises -> Decimal:
    """
    Increase the scale of a Decimal while keeping the value unchanged.
    Internally, this means multiplying the coefficient by 10^scale_diff
    and increasing the scale by scale_diff simultaneously.

    Args:
        value: The Decimal to scale up.
        level: Number of decimal places to scale up by.

    Returns:
        A new Decimal with the scaled up value.

    Raises:
        Error: If the level is less than 0.

    Examples:

    ```mojo
    from decimojo import Decimal
    from decimojo.utility import scale_up
    var d1 = Decimal("5")       # 5
    var d2 = scale_up(d1, 2)    # Result: 5.00 (same value, different representation)
    print(d1)                   # 5
    print(d2)                   # 5.00
    print(d2.scale())           # 2

    var d3 = Decimal("123.456") # 123.456
    var d4 = scale_up(d3, 3)    # Result: 123.456000
    print(d3)                   # 123.456
    print(d4)                   # 123.456000
    print(d4.scale())           # 6
    ```
    .
    """

    if level < 0:
        raise Error("Error in `scale_up()`: Level must be greater than 0")

    # Early return if no scaling needed
    if level == 0:
        return value

    var result = value

    # Update the scale in the flags
    var new_scale = value.scale() + level

    # TODO: Check if multiplication by 10^level would cause overflow
    # If yes, then raise an error
    if new_scale > Decimal.MAX_SCALE + 1:
        # Cannot scale beyond max precision, limit the scaling
        level = Decimal.MAX_SCALE + 1 - value.scale()
        new_scale = Decimal.MAX_SCALE + 1

    # With UInt128, we can represent the coefficient as a single value
    var coefficient = UInt128(value.high) << 64 | UInt128(
        value.mid
    ) << 32 | UInt128(value.low)

    # TODO: Check if multiplication by 10^level would cause overflow
    # If yes, then raise an error
    #
    var max_coefficient = ~UInt128(0) / UInt128(10**level)
    if coefficient > max_coefficient:
        # Handle overflow case - limit to maximum value or raise error
        coefficient = ~UInt128(0)
    else:
        # No overflow - safe to multiply
        coefficient *= UInt128(10**level)

    # Extract the 32-bit components from the UInt128
    result.low = UInt32(coefficient & 0xFFFFFFFF)
    result.mid = UInt32((coefficient >> 32) & 0xFFFFFFFF)
    result.high = UInt32((coefficient >> 64) & 0xFFFFFFFF)

    # Set the new scale
    result.flags = (value.flags & ~Decimal.SCALE_MASK) | (
        UInt32(new_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
    )

    return result


fn truncate_to_max[dtype: DType, //](value: Scalar[dtype]) -> Scalar[dtype]:
    """
    Truncates a UInt256 or UInt128 value to be as closer to the max value of
    Decimal coefficient (`2^96 - 1`) as possible with rounding.
    Uses banker's rounding (ROUND_HALF_EVEN) for any truncated digits.
    `792281625142643375935439503356` will be truncated to
    `7922816251426433759354395034`.
    `792281625142643375935439503353` will be truncated to
    `79228162514264337593543950345`.

    Parameters:
        dtype: Must be either uint128 or uint256.

    Args:
        value: The UInt256 value to truncate.

    Constraints:
        `dtype` must be either `DType.uint128` or `DType.uint256`.

    Returns:
        The truncated UInt256 value, guaranteed to fit within 96 bits.
    """

    alias ValueType = Scalar[dtype]

    constrained[
        dtype == DType.uint128 or dtype == DType.uint256,
        "must be uint128 or uint256",
    ]()

    # If the value is already less than the maximum possible value, return it
    if value <= ValueType(Decimal.MAX_AS_UINT128):
        return value

    else:
        # Calculate how many digits we need to truncate
        # Calculate how many digits to keep (MAX_VALUE_DIGITS = 29)
        var num_digits = number_of_digits(value)
        var digits_to_remove = num_digits - Decimal.MAX_VALUE_DIGITS

        # Collect digits for rounding decision
        var divisor = ValueType(10) ** ValueType(digits_to_remove)
        var truncated_value = value // divisor

        if truncated_value == ValueType(Decimal.MAX_AS_UINT128):
            # Case 1:
            # Truncated_value == MAX_AS_UINT128
            # Rounding may not cause overflow depending on rounding digit
            # If removed digits do not caue rounding up. Return truncated value.
            # If removed digits cause rounding up, return MAX // 10 - 1
            # 79228162514264337593543950335[removed part] -> 7922816251426433759354395034

            var remainder = value % divisor

            # Get the most significant digit of the remainder for rounding
            var rounding_digit = remainder // 10 ** (digits_to_remove - 1)

            # Check if we need to round up based on banker's rounding (ROUND_HALF_EVEN)
            var round_up = False

            # If rounding digit is > 5, round up
            if rounding_digit > 5:
                round_up = True
            # If rounding digit is 5, check if there are any non-zero digits after it
            elif rounding_digit == 5:
                var has_nonzero_after = remainder > 5 * 10 ** (
                    digits_to_remove - 1
                )
                # If there are non-zero digits after, round up
                if has_nonzero_after:
                    round_up = True
                # Otherwise, round to even (round up if last kept digit is odd)
                else:
                    round_up = (truncated_value % 2) == 1

            # Apply rounding if needed
            if round_up:
                truncated_value = (
                    truncated_value // 10 + 1
                )  # 7922816251426433759354395034

            return truncated_value

        else:
            # Case 3:
            # Truncated_value > MAX_AS_UINT128
            # Always overflow, increase the digits_to_remove by 1

            # Case 2:
            # Trucated_value < MAX_AS_UINT128
            # Rounding will not case overflow

            if truncated_value > ValueType(Decimal.MAX_AS_UINT128):
                digits_to_remove += 1

            # Collect digits for rounding decision
            divisor = ValueType(10) ** ValueType(digits_to_remove)
            truncated_value = value // divisor
            var remainder = value % divisor

            # Get the most significant digit of the remainder for rounding
            var rounding_digit = remainder // 10 ** (digits_to_remove - 1)

            # Check if we need to round up based on banker's rounding (ROUND_HALF_EVEN)
            var round_up = False

            # If rounding digit is > 5, round up
            if rounding_digit > 5:
                round_up = True
            # If rounding digit is 5, check if there are any non-zero digits after it
            elif rounding_digit == 5:
                var has_nonzero_after = remainder > 5 * 10 ** (
                    digits_to_remove - 1
                )
                # If there are non-zero digits after, round up
                if has_nonzero_after:
                    round_up = True
                # Otherwise, round to even (round up if last kept digit is odd)
                else:
                    round_up = (truncated_value % 2) == 1

            # Apply rounding if needed
            if round_up:
                truncated_value += 1

            return truncated_value


# TODO: Evalulate whether this can replace truncate_to_max in some cases.
# TODO: Add rounding modes to this function.
fn truncate_to_digits[
    dtype: DType, //
](value: Scalar[dtype], num_digits: Int) -> Scalar[dtype]:
    """
    Truncates a UInt256 or UInt128 value to the specified number of digits.
    Uses banker's rounding (ROUND_HALF_EVEN) for any truncated digits.
    `792281625142643375935439503356` with digits 2 will be truncated to `79`.
    `997` with digits 2 will be truncated to `100`.

    This is useful in two cases:
    (1) When you want to evaluate whether the coefficient will overflow after
    rounding, just look the first N digits (after rounding). If the truncated
    value is larger than the maximum, then it will overflow. Then you need to
    either raise an error (in case scale = 0 or integral part overflows),
    or keep only the first 28 digits in the coefficient.
    (2) When you want to round a value.

    The function is useful in the following cases.

    When you want to apply a scale of 31 to the coefficient `997`, it will be
    `0.0000000000000000000000000000997` with 31 digits. However, we can only
    store 28 digits in the coefficient (Decimal.MAX_SCALE = 28).
    Therefore, we need to truncate the coefficient to 0 (`3 - (31 - 28)`) digits
    and round it to the nearest even number.
    The truncated ceofficient will be `1`.
    Note that `truncated_digits = 1` which is not equal to
    `num_digits = 0`, meaning there is a rounding to next digit.
    The final decimal value will be `0.0000000000000000000000000001`.

    When you want to apply a scale of 29 to the coefficient `234567`, it will be
    `0.00000000000000000000000234567` with 29 digits. However, we can only
    store 28 digits in the coefficient (Decimal.MAX_SCALE = 28).
    Therefore, we need to truncate the coefficient to 5 (`6 - (29 - 28)`) digits
    and round it to the nearest even number.
    The truncated ceofficient will be `23457`.
    The final decimal value will be `0.0000000000000000000000023457`.

    When you want to apply a scale of 5 to the coefficient `234567`, it will be
    `2.34567` with 5 digits.
    Since `num_digits_to_keep = 6 - (5 - 28) = 29`,
    it is greater and equal to the number of digits of the input value.
    The function will return the value as it is.

    It can also be used for rounding function. For example, if you want to round
    `12.34567` (`1234567` with scale `5`) to 2 digits,
    the function input will be `234567` and `4 = (7 - 5) + 2`.
    That is (number of digits - scale) + number of rounding points.
    The output is `1235`.

    Parameters:
        dtype: Must be either uint128 or uint256.

    Args:
        value: The UInt256 value to truncate.
        num_digits: The number of significant digits to evalulate.

    Constraints:
        `dtype` must be either `DType.uint128` or `DType.uint256`.

    Returns:
        The truncated UInt256 value, guaranteed to fit within 96 bits.
    """

    alias ValueType = Scalar[dtype]

    constrained[
        dtype == DType.uint128 or dtype == DType.uint256,
        "must be uint128 or uint256",
    ]()

    if num_digits < 0:
        return 0

    var num_significant_digits = number_of_digits(value)
    # If the number of digits is less than or equal to the specified digits,
    # return the value
    if num_significant_digits <= num_digits:
        return value

    else:
        # Calculate how many digits we need to truncate
        # Calculate how many digits to keep (MAX_VALUE_DIGITS = 29)
        var num_digits_to_remove = num_significant_digits - num_digits

        # Collect digits for rounding decision
        divisor = ValueType(10) ** ValueType(num_digits_to_remove)
        truncated_value = value // divisor
        var remainder = value % divisor

        # Get the most significant digit of the remainder for rounding
        var rounding_digit = remainder // 10 ** (num_digits_to_remove - 1)

        # Check if we need to round up based on banker's rounding (ROUND_HALF_EVEN)
        var round_up = False

        # If rounding digit is > 5, round up
        if rounding_digit > 5:
            round_up = True
        # If rounding digit is 5, check if there are any non-zero digits after it
        elif rounding_digit == 5:
            var has_nonzero_after = remainder > 5 * 10 ** (
                num_digits_to_remove - 1
            )
            # If there are non-zero digits after, round up
            if has_nonzero_after:
                round_up = True
            # Otherwise, round to even (round up if last kept digit is odd)
            else:
                round_up = (truncated_value % 2) == 1

        # Apply rounding if needed
        if round_up:
            truncated_value += 1

        return truncated_value


fn number_of_digits[dtype: DType, //](owned value: Scalar[dtype]) -> Int:
    """
    Returns the number of (significant) digits in an intergral value.

    Constraints:
        `dtype` must be integral.
    """

    constrained[
        dtype.is_integral(),
        "must be intergral",
    ]()

    if value < 0:
        value = -value

    var count = 0
    while value > 0:
        value //= 10
        count += 1

    return count


fn number_of_bits[dtype: DType, //](owned value: Scalar[dtype]) -> Int:
    """
    Returns the number of significant bits in an integer value.

    Constraints:
        `dtype` must be integral.
    """

    constrained[
        dtype.is_integral(),
        "must be intergral",
    ]()

    if value < 0:
        value = -value

    var count = 0
    while value > 0:
        value >>= 1
        count += 1

    return count
