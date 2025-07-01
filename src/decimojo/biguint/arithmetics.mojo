# ===----------------------------------------------------------------------=== #
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
# ===----------------------------------------------------------------------=== #

"""
Implements basic arithmetic functions for the BigUInt type.
"""

import time
import testing

from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.comparison
from decimojo.rounding_mode import RoundingMode

# ===----------------------------------------------------------------------=== #
# List of functions in this module:
# add(x1: BigUInt, x2: BigUInt) -> BigUInt
# add_inplace(x1: BigUInt, x2: BigUInt)
# add_inplace_by_1(x: BigUInt) -> None
# subtract(x1: BigUInt, x2: BigUInt) -> BigUInt
# negative(x: BigUInt) -> BigUInt
# absolute(x: BigUInt) -> BigUInt
# multiply(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# truncate_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# ceil_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# truncate_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# ceil_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# divmod(x1: BigUInt, x2: BigUInt) -> Tuple[BigUInt, BigUInt]
# scale_up_by_power_of_10(x: BigUInt, n: Int) -> BigUInt
# floor_divide_general(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_partition(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_inplace_by_single_word(x1: BigUInt, x2: BigUInt) -> None
# floor_divide_inplace_by_double_words(x1: BigUInt, x2: BigUInt) -> None
# floor_divide_inplace_by_2(x: BigUInt) -> None
# scale_down_by_power_of_10(x: BigUInt, n: Int) -> BigUInt
# estimate_quotient(x1: BigUInt, x2: BigUInt, j: Int, m: Int) -> UInt64
# shift_words_left(x: BigUInt, j: Int) -> BigUInt
# power_of_10(n: Int) -> BigUInt
# ===----------------------------------------------------------------------=== #

# ===----------------------------------------------------------------------=== #
# Arithmetic Operations
# add, subtract, negative, absolute, multiply, floor_divide, modulo
# ===----------------------------------------------------------------------=== #


fn add(x1: BigUInt, x2: BigUInt) -> BigUInt:
    """Returns the sum of two unsigned integers.

    Args:
        x1: The first unsigned integer operand.
        x2: The second unsigned integer operand.

    Returns:
        The sum of the two unsigned integers.
    """
    # Short circuit cases
    if len(x1.words) == 1:
        if x1.is_zero():
            return x2
        elif x1.is_one():
            # Optimized case for adding 1
            var result = x2
            add_inplace_by_1(result)
            return result^
        elif len(x2.words) == 1:
            var value = x1.words[0] + x2.words[0]
            if value <= 999_999_999:
                return BigUInt(List[UInt32](value))
            else:
                return BigUInt(
                    List[UInt32](
                        value % UInt32(1_000_000_000),
                        value // UInt32(1_000_000_000),
                    )
                )
        else:
            pass

    if x2.is_zero():
        return x1
    if x2.is_one():
        # Optimized case for adding 1
        var result = x1
        add_inplace_by_1(result)
        return result^

    # Normal cases
    # The result will have at most one more word than the longer operand
    var words = List[UInt32](capacity=max(len(x1.words), len(x2.words)) + 1)

    var carry: UInt32 = 0
    var ith: Int = 0
    var sum_of_words: UInt32

    # Add corresponding words from both numbers
    while ith < len(x1.words) or ith < len(x2.words):
        sum_of_words = carry

        # Add x1's word if available
        if ith < len(x1.words):
            sum_of_words += x1.words[ith]

        # Add x2's word if available
        if ith < len(x2.words):
            sum_of_words += x2.words[ith]

        # Compute new word and carry
        carry = sum_of_words // UInt32(1_000_000_000)
        words.append(sum_of_words % UInt32(1_000_000_000))

        ith += 1

    # Handle final carry if it exists
    if carry > 0:
        words.append(carry)

    return BigUInt(words=words^)


fn add_inplace(mut x1: BigUInt, x2: BigUInt) -> None:
    """Increments a BigUInt number by another BigUInt number in place.

    Args:
        x1: The first unsigned integer operand.
        x2: The second unsigned integer operand.
    """

    # Short circuit cases
    if len(x1.words) == 1:
        if x1.is_zero():
            x1.words[0] = x2.words[0]
            return
        if len(x2.words) == 1:
            var value = x1.words[0] + x2.words[0]
            if value <= 999_999_999:
                x1.words[0] = value
                return
            else:
                x1.words[0] = value % UInt32(1_000_000_000)
                x1.words.append(value // UInt32(1_000_000_000))
                return
        else:
            pass

    elif x2.is_zero():
        return
    elif x2.is_one():
        # Optimized case for adding 1
        add_inplace_by_1(x1)
        return

    # Normal cases
    if len(x1.words) < len(x2.words):
        x1.words.resize(new_size=len(x2.words), value=UInt32(0))

    var carry: UInt32 = 0

    for i in range(len(x1.words)):
        if i < len(x2.words):
            x1.words[i] += carry + x2.words[i]
        else:
            x1.words[i] += carry
        carry = x1.words[i] // UInt32(1_000_000_000)
        x1.words[i] %= UInt32(1_000_000_000)

    # Handle final carry if it exists
    if carry > 0:
        x1.words.append(carry)

    return


fn add_inplace_by_1(mut x: BigUInt) -> None:
    """Increments a BigUInt number by 1."""
    var i = 0
    while i < len(x.words):
        if x.words[i] < UInt32(999_999_999):
            x.words[i] += UInt32(1)
            return
        else:  # If the word is 999_999_999, we need to carry over
            x.words[i] = 0
            i += 1
    # If we reach here, we need to add a new word
    x.words.append(UInt32(1))
    return


fn subtract(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the difference of two unsigned integers.

    Args:
        x1: The first unsigned integer (minuend).
        x2: The second unsigned integer (subtrahend).

    Returns:
        The result of subtracting x2 from x1.
    """
    # If the subtrahend is zero, return the minuend
    if x2.is_zero():
        return x1
    if x1.is_zero():
        # x2 is not zero, so the result is negative, raise an error
        raise Error("Error in `subtract`: Underflow due to x1 < x2")

    # We need to determine which number has the larger magnitude
    var comparison_result = x1.compare(x2)

    if comparison_result == 0:
        # |x1| = |x2|
        return BigUInt()  # Return zero

    if comparison_result < 0:
        raise Error("Error in `subtract`: Underflow due to x1 < x2")

    # Now it is safe to subtract the smaller number from the larger one
    # The result will have no more words than the larger operand
    var words = List[UInt32](capacity=max(len(x1.words), len(x2.words)))
    var borrow: Int32 = 0
    var ith: Int = 0
    var difference: Int32  # Int32 is sufficient for the difference

    while ith < len(x1.words):
        # Subtract the borrow
        difference = Int32(x1.words[ith]) - borrow
        # Subtract smaller's word if available
        if ith < len(x2.words):
            difference -= Int32(x2.words[ith])
        # Handle borrowing if needed
        if difference < Int32(0):
            difference += Int32(1_000_000_000)
            borrow = Int32(1)
        else:
            borrow = Int32(0)
        words.append(UInt32(difference))
        ith += 1

    var result = BigUInt(words=words^)
    result.remove_leading_empty_words()
    return result^


fn negative(x: BigUInt) raises -> BigUInt:
    """Returns the negative of a BigUInt number if it is zero.

    Args:
        x: The BigUInt value to compute the negative of.

    Returns:
        A new BigUInt containing the negative of x.
    """
    if not x.is_zero():
        raise Error(
            "Error in `negative`: Negative of non-zero unsigned integer is"
            " undefined"
        )
    return BigUInt()  # Return zero


fn absolute(x: BigUInt) -> BigUInt:
    """Returns the absolute value of a BigUInt number.

    Args:
        x: The BigUInt value to compute the absolute value of.

    Returns:
        A new BigUInt containing the absolute value of x.
    """
    return x


fn multiply(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the product of two BigUInt numbers.

    Args:
        x1: The first BigUInt operand (multiplicand).
        x2: The second BigUInt operand (multiplier).

    Returns:
        The product of the two BigUInt numbers.
    """
    # CASE: One of the operands is zero
    if x1.is_zero() or x2.is_zero():
        return BigUInt(UInt32(0))

    # CASE: One of the operands is one or negative one
    if x1.is_one():
        return x2
    if x2.is_one():
        return x1

    # The maximum number of words in the result is the sum of the words in the operands
    var max_result_len = len(x1.words) + len(x2.words)
    var words = List[UInt32](capacity=max_result_len)

    # Initialize result words with zeros
    for _ in range(max_result_len):
        words.append(0)

    # Perform the multiplication word by word (from least significant to most significant)
    # x1 = x1[0] + x1[1] * 10^9
    # x2 = x2[0] + x2[1] * 10^9
    # x1 * x2 = x1[0] * x2[0] + (x1[0] * x2[1] + x1[1] * x2[0]) * 10^9 + x1[1] * x2[1] * 10^18
    var carry: UInt64
    for i in range(len(x1.words)):
        # Skip if the word is zero
        if x1.words[i] == 0:
            continue

        carry = UInt64(0)

        for j in range(len(x2.words)):
            # Calculate the product of the current words
            # plus the carry from the previous multiplication
            # plus the value already at this position in the result
            var product = (
                UInt64(x1.words[i]) * UInt64(x2.words[j])
                + carry
                + UInt64(words[i + j])
            )

            # The lower 9 digits (base 10^9) go into the current word
            # The upper digits become the carry for the next position
            words[i + j] = UInt32(product % 1_000_000_000)
            carry = product // 1_000_000_000

        # If there is a carry left, add it to the next position
        if carry > 0:
            words[i + len(x2.words)] += UInt32(carry)

    var result = BigUInt(words=words^)
    result.remove_leading_empty_words()
    return result^


fn floor_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, truncating toward zero.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to truncated division for positive numbers.
    """

    # CASE: x2 is single word
    if len(x2.words) == 1:
        # SUB-CASE: Division by zero
        if x2.words[0] == 0:
            raise Error("Error in `truncate_divide`: Division by zero")

        # SUB-CASE: Division by one
        if x2.words[0] == 1:
            return x1

        # SUB-CASE: Division by two
        if x2.words[0] == 2:
            var result = x1
            floor_divide_inplace_by_2(result)
            return result^

        # SUB-CASE: Single word // single word
        if len(x1.words) == 1:
            var result = BigUInt(UInt32(x1.words[0] // x2.words[0]))
            return result^

        # SUB-CASE: Divisor is single word and is power of 2
        if (x2.words[0] & (x2.words[0] - 1)) == 0:
            var result = x1
            var remainder = x2.words[0]
            while remainder > 1:
                floor_divide_inplace_by_2(result)
                remainder >>= 1
            return result^

        # SUB-CASE: Divisor is single word (<= 10 digits)
        else:
            var result = x1
            floor_divide_inplace_by_single_word(result, x2)
            return result^

    # CASE: Divisor is double-word (<= 20 digits)
    if len(x2.words) == 2:
        var result = x1
        floor_divide_inplace_by_double_words(result, x2)
        return result^

    # CASE: Dividend is zero
    if x1.is_zero():
        return BigUInt()  # Return zero

    var comparison_result: Int8 = x1.compare(x2)
    # CASE: dividend < divisor
    if comparison_result < 0:
        return BigUInt()  # Return zero
    # CASE: dividend == divisor
    if comparison_result == 0:
        return BigUInt(UInt32(1))

    # CASE: Divisor is 10^n
    # First remove the last words (10^9) and then shift the rest
    if x2.is_power_of_10():
        var result: BigUInt
        if len(x2.words) == 1:
            result = x1
        else:
            var word_shift = len(x2.words) - 1
            # If we need to drop more words than exists, result is zero
            if word_shift >= len(x1.words):
                return BigUInt()
            # Create result with the remaining words
            words = List[UInt32]()
            for i in range(word_shift, len(x1.words)):
                words.append(x1.words[i])
            result = BigUInt(words=words^)

        # Get the last word of the divisor
        var x2_word = x2.words[len(x2.words) - 1]
        var carry = UInt32(0)
        var power_of_carry = UInt32(1_000_000_000) // x2_word
        for i in range(len(result.words) - 1, -1, -1):
            var quot = result.words[i] // x2_word
            var rem = result.words[i] % x2_word
            result.words[i] = quot + carry * power_of_carry
            carry = rem

        result.remove_leading_empty_words()
        return result^

    # CASE: division of very, very large numbers
    # Use Newton-Raphson division for large numbers?

    # CASE: all other situations
    # Normalize divisor to improve quotient estimation
    var normalized_x1 = x1
    var normalized_x2 = x2
    var normalization_factor: UInt32 = 1

    # Calculate normalization factor to make leading digit of divisor large
    var msw = x2.words[len(x2.words) - 1]
    if msw < 500_000_000:
        while msw < 100_000_000:  # Ensure leading digit is significant
            msw *= 10
            normalization_factor *= 10

        # Apply normalization
        if normalization_factor > 1:
            normalized_x1 = multiply(x1, BigUInt(normalization_factor))
            normalized_x2 = multiply(x2, BigUInt(normalization_factor))

    return floor_divide_general(normalized_x1, normalized_x2)


@always_inline
fn truncate_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, truncating toward zero.
    It is equal to floored division for unsigned numbers.
    See `floor_divide` for more details.
    """
    return floor_divide(x1, x2)


fn ceil_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, rounding up.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, rounded up.

    Raises:
        ValueError: If the divisor is zero.
    """

    # CASE: Division by zero
    if x2.is_zero():
        raise Error("Error in `ceil_divide`: Division by zero")

    # Apply floor division and check if there is a remainder
    var quotient = floor_divide(x1, x2)
    if quotient * x2 < x1:
        quotient += BigUInt(UInt32(1))
    return quotient^


fn floor_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, truncating toward zero.
    The remainder has the same sign as the dividend and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to floored modulo for positive numbers.
    """
    # CASE: Division by zero
    if x2.is_zero():
        raise Error("Error in `truncate_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        return BigUInt()  # Return zero

    # CASE: Divisor is one - no remainder
    if x2.is_one():
        return BigUInt()  # Always divisible with no remainder

    # CASE: |dividend| < |divisor| - the remainder is the dividend itself
    if x1.compare(x2) < 0:
        return x1

    # Calculate quotient with truncation
    var quotient = floor_divide(x1, x2)

    # Calculate remainder: dividend - (divisor * quotient)
    var remainder = subtract(x1, multiply(x2, quotient))

    return remainder^


@always_inline
fn truncate_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, truncating toward zero.
    It is equal to floored modulo for unsigned numbers.
    See `floor_modulo` for more details.
    """
    return floor_modulo(x1, x2)


fn ceil_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, rounding up.
    The remainder has the same sign as the dividend and satisfies:
    x1 = ceil_divide(x1, x2) * x2 + ceil_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being ceil-divided by x2.

    Raises:
        ValueError: If the divisor is zero.
    """
    # CASE: Division by zero
    if x2.is_zero():
        raise Error("Error in `truncate_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        return BigUInt()  # Return zero

    # CASE: Divisor is one - no remainder
    if x2.is_one():
        return BigUInt()  # Always divisible with no remainder

    # CASE: |dividend| < |divisor| - the remainder is the dividend itself
    if x1.compare(x2) < 0:
        return x1

    # Calculate quotient with truncation
    var quotient = floor_divide(x1, x2)
    # Calculate remainder: dividend - (divisor * quotient)
    var remainder = subtract(x1, multiply(x2, quotient))

    if remainder.is_zero():
        return BigUInt()  # No remainder
    else:
        return subtract(x2, remainder)


fn divmod(x1: BigUInt, x2: BigUInt) raises -> Tuple[BigUInt, BigUInt]:
    """Returns the quotient and remainder of two numbers, truncating toward zero.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero and the remainder.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to truncated division for positive numbers.
    """

    var quotient = floor_divide(x1, x2)
    var remainder = subtract(x1, multiply(x2, quotient))
    return (quotient^, remainder^)


# ===----------------------------------------------------------------------=== #
# Multiplication Algorithms
# ===----------------------------------------------------------------------=== #


fn scale_up_by_power_of_10(x: BigUInt, n: Int) -> BigUInt:
    """Multiplies a BigUInt by 10^n if n > 0, otherwise doing nothing.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.

    Returns:
        A new BigUInt containing the result of the multiplication.
    """
    if n <= 0:
        return x

    var number_of_zero_words = n // 9
    var number_of_remaining_digits = n % 9

    var words = List[UInt32](capacity=number_of_zero_words + len(x.words) + 1)
    # Add zero words
    for _ in range(number_of_zero_words):
        words.append(UInt32(0))
    # Add the original words times 10^number_of_remaining_digits
    if number_of_remaining_digits == 0:
        for i in range(len(x.words)):
            words.append(x.words[i])
    else:  # number_of_remaining_digits > 0
        var carry = UInt64(0)
        var multiplier: UInt64

        if number_of_remaining_digits == 1:
            multiplier = UInt64(10)
        elif number_of_remaining_digits == 2:
            multiplier = UInt64(100)
        elif number_of_remaining_digits == 3:
            multiplier = UInt64(1000)
        elif number_of_remaining_digits == 4:
            multiplier = UInt64(10_000)
        elif number_of_remaining_digits == 5:
            multiplier = UInt64(100_000)
        elif number_of_remaining_digits == 6:
            multiplier = UInt64(1_000_000)
        elif number_of_remaining_digits == 7:
            multiplier = UInt64(10_000_000)
        else:  # number_of_remaining_digits == 8
            multiplier = UInt64(100_000_000)

        for i in range(len(x.words)):
            var product = UInt64(x.words[i]) * multiplier + carry
            words.append(UInt32(product % UInt64(1_000_000_000)))
            carry = product // UInt64(1_000_000_000)
        # Add the last carry if it exists
        if carry > 0:
            words.append(UInt32(carry))

    return BigUInt(words=words^)


# ===----------------------------------------------------------------------=== #
# Division Algorithms
# floor_divide_general, floor_divide_inplace_by_2
# ===----------------------------------------------------------------------=== #


fn floor_divide_general(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """General division algorithm for BigInt numbers.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 // x2.

    Raises:
        ValueError: If the divisor is zero.
    """

    if x2.is_zero():
        raise Error("Error in `floor_divide_general`: Division by zero")

    # Initialize result and remainder
    var result = BigUInt(List[UInt32](capacity=len(x1.words)))
    var remainder = x1

    # Calculate significant digits
    var n = len(remainder.words)
    var m = len(x2.words)

    # Shift and initialize
    var d = n - m
    for _ in range(d + 1):
        result.words.append(0)

    # Main division loop
    var j = d
    while j >= 0:
        # OPTIMIZATION: Better quotient estimation
        var q = estimate_quotient(remainder, x2, j, m)

        # Calculate trial product
        var trial_product = x2 * BigUInt(UInt32(q))
        var shifted_product = shift_words_left(trial_product, j)

        # OPTIMIZATION: Binary search for adjustment
        if shifted_product.compare(remainder) > 0:
            var low: UInt64 = 0
            var high: UInt64 = q - 1

            while low <= high:
                var mid = (low + high) / 2

                # Recalculate with new q
                trial_product = x2 * BigUInt(UInt32(mid))
                shifted_product = shift_words_left(trial_product, j)

                if shifted_product.compare(remainder) <= 0:
                    q = mid  # This works
                    low = mid + 1
                else:
                    high = mid - 1

            # Final recalculation with best q
            trial_product = x2 * BigUInt(UInt32(q))
            shifted_product = shift_words_left(trial_product, j)

        result.words[j] = UInt32(q)
        remainder = subtract(remainder, shifted_product)
        j -= 1

    result.remove_leading_empty_words()
    return result^


fn floor_divide_partition(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Partition division algorithm for BigInt numbers.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 // x2.

    Raises:
        ValueError: If the divisor is zero.

    Notes:

    If words of x1 is more than 2 times the words of x2, then partition x1 into
    several parts and divide x2 sequentially using general division.

    words of x1: m
    words of x2: n
    number of partitions: m // n
    words of first partition: n + m % n
    the remainder is appended to the next partition.
    """

    if x2.is_zero():
        raise Error("Error in `floor_divide_partition`: Division by zero")

    # Initialize result and remainder
    var number_of_partitions = len(x1.words) // len(x2.words)
    var number_of_words_remainder = len(x1.words) % len(x2.words)
    var number_of_words_dividend: Int
    var result = x1
    result.words.resize(len(x1.words) - number_of_words_remainder, UInt32(0))
    var remainder = BigUInt(List[UInt32](capacity=len(x2.words)))
    for i in range(len(x1.words) - number_of_words_remainder, len(x1.words)):
        remainder.words.append(x1.words[i])

    for ith in range(number_of_partitions):
        number_of_words_dividend = len(x2.words) + number_of_words_remainder
        var dividend_list_of_words = List[UInt32](
            capacity=number_of_words_dividend
        )
        for i in range(len(x2.words)):
            dividend_list_of_words.append(
                x1.words[(number_of_partitions - ith - 1) * len(x2.words) + i]
            )
        for i in range(number_of_words_remainder):
            dividend_list_of_words.append(remainder.words[i])

        var dividend = BigUInt(dividend_list_of_words)
        var quotient = floor_divide_general(dividend, x2)
        for i in range(len(x2.words)):
            if i < len(quotient.words):
                result.words[
                    (number_of_partitions - ith - 1) * len(x2.words) + i
                ] = quotient.words[i]
            else:
                result.words[
                    (number_of_partitions - ith - 1) * len(x2.words) + i
                ] = UInt32(0)
        remainder = subtract(dividend, multiply(quotient, x2))
        number_of_words_remainder = len(remainder.words)

    result.remove_leading_empty_words()
    return result^


fn floor_divide_inplace_by_single_word(
    mut x1: BigUInt, x2: BigUInt
) raises -> None:
    """Divides a BigUInt by a single word divisor in-place.

    Args:
        x1: The BigUInt value to divide by the divisor.
        x2: The single word divisor.
    """
    if x2.is_zero():
        raise Error(
            "Error in `floor_divide_inplace_by_single_word`: Division by zero"
        )

    # CASE: all other situations
    var x2_value = UInt64(x2.words[0])
    var carry = UInt64(0)
    for i in range(len(x1.words) - 1, -1, -1):
        var dividend = carry * UInt64(1_000_000_000) + UInt64(x1.words[i])
        x1.words[i] = UInt32(dividend // x2_value)
        carry = dividend % x2_value
    x1.remove_leading_empty_words()


fn floor_divide_inplace_by_double_words(
    mut x1: BigUInt, x2: BigUInt
) raises -> None:
    """Divides a BigUInt by double-word divisor in-place.

    Args:
        x1: The BigUInt value to divide by the divisor.
        x2: The double-word divisor.
    """
    if x2.is_zero():
        raise Error(
            "Error in `floor_divide_inplace_by_double_words`: Division by zero"
        )

    # CASE: all other situations
    var x2_value = UInt128(x2.words[1]) * UInt128(1_000_000_000) + UInt128(
        x2.words[0]
    )

    var carry = UInt128(0)
    if len(x1.words) % 2 == 1:
        carry = UInt128(x1.words[-1])
        x1.words.resize(len(x1.words) - 1, UInt32(0))

    for i in range(len(x1.words) - 1, -1, -2):
        var dividend = (
            carry * UInt128(1_000_000_000_000_000_000)
            + UInt128(x1.words[i]) * UInt128(1_000_000_000)
            + UInt128(x1.words[i - 1])
        )
        var quotient = dividend // x2_value
        x1.words[i] = UInt32(quotient // UInt128(1_000_000_000))
        x1.words[i - 1] = UInt32(quotient % UInt128(1_000_000_000))
        carry = dividend % x2_value

    x1.remove_leading_empty_words()
    return


fn floor_divide_inplace_by_2(mut x: BigUInt) -> None:
    """Divides a BigUInt by 2 in-place.

    Args:
        x: The BigUInt value to divide by 2.
    """
    if x.is_zero():
        return

    var carry: UInt32 = 0

    # Process from most significant to least significant word
    for ith in range(len(x.words) - 1, -1, -1):
        x.words[ith] += carry
        carry = UInt32(1_000_000_000) if (x.words[ith] & 1) else 0
        x.words[ith] >>= 1

    # Remove leading zeros
    while len(x.words) > 1 and x.words[len(x.words) - 1] == 0:
        x.words.resize(len(x.words) - 1, UInt32(0))


fn scale_down_by_power_of_10(x: BigUInt, n: Int) raises -> BigUInt:
    """Floor divide a BigUInt by 10^n (n>=0).
    It is equal to removing the last n digits of the number.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.

    Returns:
        A new BigUInt containing the result of the multiplication.
    """
    if n < 0:
        raise Error(
            "Error in `scale_down_by_power_of_10`: n must be non-negative"
        )
    if n == 0:
        return x

    # First remove the last words (10^9)
    var result: BigUInt
    if len(x.words) == 1:
        result = x
    else:
        var word_shift = n // 9
        # If we need to drop more words than exists, result is zero
        if word_shift >= len(x.words):
            return BigUInt.ZERO
        # Create result with the remaining words
        words = List[UInt32]()
        for i in range(word_shift, len(x.words)):
            words.append(x.words[i])
        result = BigUInt(words=words^)

    # Then shift the remaining words right
    # Get the last word of the divisor
    var digit_shift = n % 9
    var carry = UInt32(0)
    var divisor: UInt32
    if digit_shift == 0:
        # No need to shift, just return the result
        return result^
    elif digit_shift == 1:
        divisor = UInt32(10)
    elif digit_shift == 2:
        divisor = UInt32(100)
    elif digit_shift == 3:
        divisor = UInt32(1000)
    elif digit_shift == 4:
        divisor = UInt32(10000)
    elif digit_shift == 5:
        divisor = UInt32(100000)
    elif digit_shift == 6:
        divisor = UInt32(1000000)
    elif digit_shift == 7:
        divisor = UInt32(10000000)
    else:  # digit_shift == 8
        divisor = UInt32(100000000)
    var power_of_carry = UInt32(1_000_000_000) // divisor
    for i in range(len(result.words) - 1, -1, -1):
        var quot = result.words[i] // divisor
        var rem = result.words[i] % divisor
        result.words[i] = quot + carry * power_of_carry
        carry = rem

    result.remove_leading_empty_words()
    return result^


# ===----------------------------------------------------------------------=== #
# Division Helper Functions
# estimate_quotient, shift_words_left, power_of_10
# ===----------------------------------------------------------------------=== #


fn estimate_quotient(
    dividend: BigUInt, divisor: BigUInt, j: Int, m: Int
) -> UInt64:
    """Gets a better estimate of the quotient digit."""
    # Get three highest words of relevant dividend portion
    var r2 = UInt64(0)
    if j + m < len(dividend.words):
        r2 = UInt64(dividend.words[j + m])

    var r1 = UInt64(0)
    if j + m - 1 < len(dividend.words):
        r1 = UInt64(dividend.words[j + m - 1])

    var r0 = UInt64(0)
    if j + m - 2 < len(dividend.words):
        r0 = UInt64(dividend.words[j + m - 2])

    # Get two highest words of divisor
    var d1 = UInt64(divisor.words[m - 1])
    var d0 = UInt64(0)
    if m >= 2:
        d0 = UInt64(divisor.words[m - 2])

    # If three most significant digits match, quotient would be max
    if r2 == d1:
        return 999_999_999

    # Two-word by one-word division
    var qhat = (r2 * 1_000_000_000 + r1) // d1

    # Adjust if estimate is too large (happens less often with better estimate)
    while (qhat >= 1_000_000_000) or (
        qhat * d0 > (r2 * 1_000_000_000 + r1 - qhat * d1) * 1_000_000_000 + r0
    ):
        qhat -= 1

    return min(qhat, UInt64(999_999_999))


fn shift_words_left(num: BigUInt, positions: Int) -> BigUInt:
    """Shifts a BigUInt left by adding trailing zeros.
    Equivalent to multiplying by 10^(9*positions)."""
    if num.is_zero():
        return BigUInt()

    var result = BigUInt(List[UInt32](capacity=len(num.words) + positions))

    # Add zeros for the shift
    for _ in range(positions):
        result.words.append(0)

    # Add the original number's words
    for i in range(len(num.words)):
        result.words.append(num.words[i])

    return result^


fn power_of_10(n: Int) raises -> BigUInt:
    """Calculates 10^n efficiently."""
    if n < 0:
        raise Error("Error in `power_of_10`: Negative exponent not supported")

    if n == 0:
        return BigUInt(1)

    # Handle small powers directly
    if n < 9:
        var value: UInt32 = 1
        for _ in range(n):
            value *= 10
        return BigUInt(value)

    # For larger powers, split into groups of 9 digits
    var words = n // 9
    var remainder = n % 9

    var result = BigUInt(List[UInt32]())

    # Add trailing zeros for full power-of-billion words
    for _ in range(words):
        result.words.append(0)

    # Calculate partial power for the highest word
    var high_word: UInt32 = 1
    for _ in range(remainder):
        high_word *= 10

    # Only add non-zero high word
    if high_word > 1:
        result.words.append(high_word)
    else:
        # Add a 1 in the next position
        result.words.append(1)

    return result^
