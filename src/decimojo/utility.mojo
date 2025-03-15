# ===----------------------------------------------------------------------=== #
#
# DeciMojo: A fixed-point decimal arithmetic library in Mojo
# https://github.com/forFudan/DeciMojo
#
# Copyright 2025 Yuhao Zhu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ===----------------------------------------------------------------------=== #
#
# Implements internal utility functions for the Decimal type
# WARNING: These functions are not meant to be used directly by the user.
#
# ===----------------------------------------------------------------------=== #

from memory import UnsafePointer
import time

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
    var max_coefficient = ~UInt128(0) / UInt128(10) ** level
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
        # Calculate how many digits to keep (MAX_NUM_DIGITS = 29)
        var ndigits = number_of_digits(value)
        var digits_to_remove = ndigits - Decimal.MAX_NUM_DIGITS

        # Collect digits for rounding decision
        var divisor = power_of_10[dtype](digits_to_remove)
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
            var rounding_digit = remainder // power_of_10[dtype](
                digits_to_remove - 1
            )

            # Check if we need to round up based on banker's rounding (ROUND_HALF_EVEN)
            var round_up = False

            # If rounding digit is > 5, round up
            if rounding_digit > 5:
                round_up = True
            # If rounding digit is 5, check if there are any non-zero digits after it
            elif rounding_digit == 5:
                var has_nonzero_after = remainder > 5 * power_of_10[dtype](
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
            divisor = power_of_10[dtype](digits_to_remove)
            truncated_value = value // divisor
            var remainder = value % divisor

            # Get the most significant digit of the remainder for rounding
            var rounding_digit = remainder // power_of_10[dtype](
                digits_to_remove - 1
            )

            # Check if we need to round up based on banker's rounding (ROUND_HALF_EVEN)
            var round_up = False

            # If rounding digit is > 5, round up
            if rounding_digit > 5:
                round_up = True
            # If rounding digit is 5, check if there are any non-zero digits after it
            elif rounding_digit == 5:
                var has_nonzero_after = remainder > 5 * power_of_10[dtype](
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


# TODO: Evaluate whether this can replace truncate_to_max in some cases.
# TODO: Add rounding modes to this function.
fn round_to_keep_first_n_digits[
    dtype: DType, //
](
    value: Scalar[dtype],
    ndigits: Int,
    rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
) -> Scalar[dtype]:
    """
    Rounds and keeps the first n digits of a integral value.
    Default to use banker's rounding (ROUND_HALF_EVEN) for any truncated digits.
    `792281625142643375935439503356` with digits 2 will be truncated to `79`.
    `997` with digits 2 will be truncated to `100`.

    Parameters:
        dtype: Must be either uint128 or uint256.

    Args:
        value: The integral value to truncate.
        ndigits: The number of significant digits to evaluate.
        rounding_mode: The rounding mode to use.

    Constraints:
        `dtype` must be either `DType.uint128` or `DType.uint256`.

    Returns:
        The truncated value.

    Notes:

    This function is useful in two cases:

    (1) When you want to evaluate whether the coefficient will overflow after
    rounding, just look the first N digits (after rounding). If the truncated
    value is larger than the maximum, then it will overflow. Then you need to
    either raise an error (in case scale = 0 or integral part overflows),
    or keep only the first 28 digits in the coefficient.

    (2) When you want to round a value.

    There are some examples:

    - When you want to apply a scale of 31 to the coefficient `997`, it will be
    `0.0000000000000000000000000000997` with 31 digits. However, we can only
    store 28 digits in the coefficient (Decimal.MAX_SCALE = 28).
    Therefore, we need to truncate the coefficient to 0 (`3 - (31 - 28)`) digits
    and round it to the nearest even number.
    The truncated ceofficient will be `1`.
    Note that `truncated_digits = 1` which is not equal to
    `ndigits = 0`, meaning there is a rounding to next digit.
    The final decimal value will be `0.0000000000000000000000000001`.

    - When you want to apply a scale of 29 to the coefficient `234567`, it will
    be `0.00000000000000000000000234567` with 29 digits. However, we can only
    store 28 digits in the coefficient (Decimal.MAX_SCALE = 28).
    Therefore, we need to truncate the coefficient to 5 (`6 - (29 - 28)`) digits
    and round it to the nearest even number.
    The truncated coefficient will be `23457`.
    The final decimal value will be `0.0000000000000000000000023457`.

    - When you want to apply a scale of 5 to the coefficient `234567`, it will
    be `2.34567` with 5 digits.
    Since `ndigits_to_keep = 6 - (5 - 28) = 29`,
    it is greater and equal to the number of digits of the input value.
    The function will return the value as it is.

    - It can also be used for rounding function. For example, if you want to
    round `12.34567` (`1234567` with scale `5`) to 2 digits,
    the function input will be `234567` and `4 = (7 - 5) + 2`.
    That is (number of digits - scale) + number of rounding points.
    The output is `1235`.
    """

    alias ValueType = Scalar[dtype]

    constrained[
        dtype == DType.uint128 or dtype == DType.uint256,
        "must be uint128 or uint256",
    ]()

    # CASE: The number of digits is less than 0
    # Return 0.
    #
    # Example:
    # 123_456 keep -1 digits => 0
    if ndigits < 0:
        return 0

    var ndigits_of_x: Int
    ndigits_of_x = number_of_digits(value)

    # CASE: If the number of digits is greater than or equal to the specified digits
    # Return the value.
    #
    # Example:
    # 123_456 keep 7 digits => 123_456
    if ndigits >= ndigits_of_x:
        return value

    # CASE: If the number of digits is less than the specified digits
    # Return the value.
    #
    # Example:
    # 123_456 keep 4 digits => 1_235
    else:
        # Calculate how many digits we need to truncate
        # Calculate how many digits to keep (MAX_NUM_DIGITS = 29)
        var ndigits_to_remove = ndigits_of_x - ndigits

        # Collect digits for rounding decision
        var divisor = power_of_10[dtype](ndigits_to_remove)
        var truncated_value = value // divisor
        var remainder = value % divisor

        # If RoundingMode is ROUND_DOWN, just truncate the value
        if rounding_mode == RoundingMode.ROUND_DOWN:
            pass

        # If RoundingMode is ROUND_UP, round up the value if remainder is greater than 0
        elif rounding_mode == RoundingMode.ROUND_UP:
            if remainder > 0:
                truncated_value += 1

        # If RoundingMode is ROUND_HALF_UP, round up the value if remainder is greater than 5
        elif rounding_mode == RoundingMode.ROUND_HALF_UP:
            var cutoff_value = 5 * power_of_10[dtype](ndigits_to_remove - 1)
            if remainder >= cutoff_value:
                truncated_value += 1

        # If RoundingMode is ROUND_HALF_EVEN, round to nearest even digit if equidistant
        else:
            var cutoff_value: ValueType = 5 * power_of_10[dtype](
                ndigits_to_remove - 1
            )
            if remainder > cutoff_value:
                truncated_value += 1
            elif remainder == cutoff_value:
                # If truncated_value is even, do not round up
                # If truncated_value is odd, round up
                truncated_value += truncated_value % 2
            else:
                pass

        return truncated_value


@always_inline
fn number_of_digits[dtype: DType](value: Scalar[dtype]) -> Int:
    """
    Returns the number of (significant) digits in an integral value using binary search.
    This implementation is significantly faster than loop division.

    Parameters:
        dtype: The Mojo scalar type to calculate the number of digits for.

    Args:
        value: The integral value to calculate the number of digits for.

    Constraints:
        `dtype` must be either `DType.uint128` or `DType.uint256`.

    Returns:
        The number of digits in the integral value.
    """

    constrained[
        dtype == DType.uint128 or dtype == DType.uint256,
        "must be uint128 or uint256",
    ]()

    alias ValueType = Scalar[dtype]

    # Handle edge cases
    if value == 0:
        return 0
    # Binary search to determine the number of digits
    # First check small numbers with direct comparison (most common case)
    if value < 10:
        return 1
    if value < 100:
        return 2
    if value < 1000:
        return 3
    if value < 10000:
        return 4
    if value < 100000:
        return 5
    if value < 1000000:
        return 6
    if value < 10000000:
        return 7
    if value < 100000000:
        return 8
    if value < 1000000000:
        return 9

    # For larger numbers, use binary search with limited indentation
    # Medium range: 10^10 to 10^19
    if value < ValueType(10) ** 19:  # < 10^19
        if value < ValueType(10) ** 13:  # < 10^13
            if value < ValueType(10) ** 10:  # < 10^10
                return 10
            if value < ValueType(10) ** 11:  # < 10^11
                return 11
            if value < ValueType(10) ** 12:  # < 10^12
                return 12
            return 13
        if value < ValueType(10) ** 16:  # < 10^16
            if value < ValueType(10) ** 14:  # < 10^14
                return 14
            if value < ValueType(10) ** 15:  # < 10^15
                return 15
            return 16
        if value < ValueType(10) ** 17:  # < 10^17
            return 17
        if value < ValueType(10) ** 18:  # < 10^18
            return 18
        return 19

    # Large range: 10^19 to 10^38 (UInt128 max is ~10^38)
    if value < ValueType(10) ** 37:  # < 10^37
        if value < ValueType(10) ** 28:  # < 10^28
            if value < ValueType(10) ** 22:  # < 10^22
                if value < ValueType(10) ** 20:  # < 10^20
                    return 20
                if value < ValueType(10) ** 21:  # < 10^21
                    return 21
                return 22
            if value < ValueType(10) ** 24:  # < 10^24
                if value < ValueType(10) ** 23:  # < 10^23
                    return 23
                return 24
            if value < ValueType(10) ** 25:  # < 10^25
                return 25
            if value < ValueType(10) ** 26:  # < 10^26
                return 26
            if value < ValueType(10) ** 27:  # < 10^27
                return 27
            return 28
        if value < ValueType(10) ** 31:  # < 10^31
            if value < ValueType(10) ** 29:  # < 10^29
                return 29
            if value < ValueType(10) ** 30:  # < 10^30
                return 30
            return 31
        if value < ValueType(10) ** 33:  # < 10^33
            if value < ValueType(10) ** 32:  # < 10^32
                return 32
            return 33
        if value < ValueType(10) ** 34:  # < 10^34
            return 34
        if value < ValueType(10) ** 35:  # < 10^35
            return 35
        if value < ValueType(10) ** 36:  # < 10^36
            return 36
        return 37

    # Very large range: 10^37 to 10^77 (UInt256 max is ~10^77)
    if value < ValueType(10) ** 38:  # < 10^38
        return 38

    # For UInt128, the maximum number of digits is 39
    # We can already return the result here
    if dtype == DType.uint128:
        return 39

    if value < ValueType(10) ** 39:  # < 10^39
        return 39

    # Use additional binary searches for UInt256 range (10^39 to 10^77)
    if value < ValueType(10) ** 58:  # < 10^58
        if value < ValueType(10) ** 47:  # < 10^47
            if value < ValueType(10) ** 43:  # < 10^43
                if value < ValueType(10) ** 40:  # < 10^40
                    return 40
                if value < ValueType(10) ** 41:  # < 10^41
                    return 41
                if value < ValueType(10) ** 42:  # < 10^42
                    return 42
                return 43
            if value < ValueType(10) ** 44:  # < 10^44
                return 44
            if value < ValueType(10) ** 45:  # < 10^45
                return 45
            if value < ValueType(10) ** 46:  # < 10^46
                return 46
            return 47
        if value < ValueType(10) ** 52:  # < 10^52
            if value < ValueType(10) ** 48:  # < 10^48
                return 48
            if value < ValueType(10) ** 49:  # < 10^49
                return 49
            if value < ValueType(10) ** 50:  # < 10^50
                return 50
            if value < ValueType(10) ** 51:  # < 10^51
                return 51
            return 52
        if value < ValueType(10) ** 54:  # < 10^54
            if value < ValueType(10) ** 53:  # < 10^53
                return 53
            return 54
        if value < ValueType(10) ** 56:  # < 10^56
            if value < ValueType(10) ** 55:  # < 10^55
                return 55
            return 56
        if value < ValueType(10) ** 57:  # < 10^57
            return 57
        return 58

    # Digits more than 58 is not possible for Decimal products
    return 59


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


# ===----------------------------------------------------------------------=== #
# Cache for powers of 10
#
# Yuhao's notes:
# This is a module-level cache for powers of 10.
# It is used to store the powers of 10 up to the required value.
# The cache is initialized with the first value (10^0 = 1).
# When a new power of 10 is requested, it is calculated and added to the cache.
# This cache is used to avoid recalculating the same powers of 10 multiple times.
#
# TODO: Currently, this won't work when you create a mojopkg to use.
# When Mojo supports module-level variables, this part can be used.
# ===----------------------------------------------------------------------=== #


# Module-level cache for powers of 10
var _power_of_10_as_uint128_cache = List[UInt128]()
var _power_of_10_as_uint256_cache = List[UInt256]()


# Initialize with the first value
@always_inline
fn _init_power_of_10_as_uint128_cache():
    if len(_power_of_10_as_uint128_cache) == 0:
        _power_of_10_as_uint128_cache.append(1)  # 10^0 = 1


@always_inline
fn _init_power_of_10_as_uint256_cache():
    if len(_power_of_10_as_uint256_cache) == 0:
        _power_of_10_as_uint256_cache.append(1)  # 10^0 = 1


@always_inline
fn power_of_10_as_uint128(n: Int) raises -> UInt128:
    """
    Returns 10^n using cached values when available.
    """

    # Check for negative exponent
    if n < 0:
        raise Error(
            "power_of_10() requires non-negative exponent, got {}".format(n)
        )

    # Initialize cache if needed
    if len(_power_of_10_as_uint128_cache) == 0:
        _init_power_of_10_as_uint128_cache()

    # Extend cache if needed
    while len(_power_of_10_as_uint128_cache) <= n:
        var next_power = _power_of_10_as_uint128_cache[
            len(_power_of_10_as_uint128_cache) - 1
        ] * 10
        _power_of_10_as_uint128_cache.append(next_power)

    return _power_of_10_as_uint128_cache[n]


@always_inline
fn power_of_10_as_uint256(n: Int) raises -> UInt256:
    """
    Returns 10^n using cached values when available.
    """

    # Check for negative exponent
    if n < 0:
        raise Error(
            "power_of_10() requires non-negative exponent, got {}".format(n)
        )

    # Initialize cache if needed
    if len(_power_of_10_as_uint256_cache) == 0:
        _init_power_of_10_as_uint256_cache()

    # Extend cache if needed
    while len(_power_of_10_as_uint256_cache) <= n:
        var next_power = _power_of_10_as_uint256_cache[
            len(_power_of_10_as_uint256_cache) - 1
        ] * 10
        _power_of_10_as_uint256_cache.append(next_power)

    return _power_of_10_as_uint256_cache[n]


@always_inline
fn power_of_10[dtype: DType](n: Int) -> Scalar[dtype]:
    """
    Returns 10^n using cached values when available.
    **WARNING**: The overflow is not checked in this function.
    Make sure that the n is less than 29 for UInt128 and 77 for UInt256.

    Parameters:
        dtype: The Mojo scalar type to calculate the power of 10 for.

    Args:
        n: The exponent to raise 10 to.

    Constraints:
        `dtype` must be either `DType.uint128` or `DType.uint256`.

    Returns:
        The value of 10^n as a Mojo scalar.

    Notes:
        The powers of 10 is hard-coded up to 10^56 since it is twice the maximum
        scale of Decimal (28). For larger values, the function calculates the
        power of 10 using the built-in `**` operator.
    """

    alias ValueType = Scalar[dtype]

    constrained[
        dtype == DType.uint128 or dtype == DType.uint256,
        "must be uint128 or uint256",
    ]()

    if n == 0:
        return ValueType(1)
    if n == 1:
        return ValueType(10)
    if n == 2:
        return ValueType(100)
    if n == 3:
        return ValueType(1000)
    if n == 4:
        return ValueType(10000)
    if n == 5:
        return ValueType(100000)
    if n == 6:
        return ValueType(1000000)
    if n == 7:
        return ValueType(10000000)
    if n == 8:
        return ValueType(100000000)
    if n == 9:
        return ValueType(1000000000)
    if n == 10:
        return ValueType(10000000000)
    if n == 11:
        return ValueType(100000000000)
    if n == 12:
        return ValueType(1000000000000)
    if n == 13:
        return ValueType(10000000000000)
    if n == 14:
        return ValueType(100000000000000)
    if n == 15:
        return ValueType(1000000000000000)
    if n == 16:
        return ValueType(10000000000000000)
    if n == 17:
        return ValueType(100000000000000000)
    if n == 18:
        return ValueType(1000000000000000000)
    if n == 19:
        return ValueType(10000000000000000000)
    if n == 20:
        return ValueType(100000000000000000000)
    if n == 21:
        return ValueType(1000000000000000000000)
    if n == 22:
        return ValueType(10000000000000000000000)
    if n == 23:
        return ValueType(100000000000000000000000)
    if n == 24:
        return ValueType(1000000000000000000000000)
    if n == 25:
        return ValueType(10000000000000000000000000)
    if n == 26:
        return ValueType(100000000000000000000000000)
    if n == 27:
        return ValueType(1000000000000000000000000000)
    if n == 28:
        return ValueType(10000000000000000000000000000)
    if n == 29:
        return ValueType(100000000000000000000000000000)
    if n == 30:
        return ValueType(1000000000000000000000000000000)
    if n == 31:
        return ValueType(10000000000000000000000000000000)
    if n == 32:
        return ValueType(100000000000000000000000000000000)
    if n == 33:
        return ValueType(10) ** 33
    if n == 34:
        return ValueType(10) ** 34
    if n == 35:
        return ValueType(10) ** 35
    if n == 36:
        return ValueType(10) ** 36
    if n == 37:
        return ValueType(10) ** 37
    if n == 38:
        return ValueType(10) ** 38
    if n == 39:
        return ValueType(10) ** 39
    if n == 40:
        return ValueType(10) ** 40
    if n == 41:
        return ValueType(10) ** 41
    if n == 42:
        return ValueType(10) ** 42
    if n == 43:
        return ValueType(10) ** 43
    if n == 44:
        return ValueType(10) ** 44
    if n == 45:
        return ValueType(10) ** 45
    if n == 46:
        return ValueType(10) ** 46
    if n == 47:
        return ValueType(10) ** 47
    if n == 48:
        return ValueType(10) ** 48
    if n == 49:
        return ValueType(10) ** 49
    if n == 50:
        return ValueType(10) ** 50
    if n == 51:
        return ValueType(10) ** 51
    if n == 52:
        return ValueType(10) ** 52
    if n == 53:
        return ValueType(10) ** 53
    if n == 54:
        return ValueType(10) ** 54
    if n == 55:
        return ValueType(10) ** 55
    if n == 56:
        return ValueType(10) ** 56

    return ValueType(10) ** n
