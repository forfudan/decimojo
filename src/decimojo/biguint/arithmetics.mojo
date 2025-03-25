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
# Arithmetic Operations
# add, subtract, negative, absolute, multiply, floor_divide, modulo
# ===----------------------------------------------------------------------=== #


fn add(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the sum of two unsigned integers.

    Args:
        x1: The first unsigned integer operand.
        x2: The second unsigned integer operand.

    Returns:
        The sum of the two unsigned integers.
    """

    # If one of the numbers is zero, return the other number
    if x1.is_zero():
        return x2
    if x2.is_zero():
        return x1

    # The result will have at most one more word than the longer operand
    var result = BigUInt(
        empty=True, capacity=max(len(x1.words), len(x2.words)) + 1
    )

    var carry: UInt32 = 0
    var ith: Int = 0
    var sum_of_words: UInt32 = 0

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
        carry = UInt32(sum_of_words // 1_000_000_000)
        result.words.append(UInt32(sum_of_words % 1_000_000_000))

        ith += 1

    # Handle final carry if it exists
    if carry > 0:
        result.words.append(carry)

    return result^


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
    var result = BigUInt(empty=True, capacity=max(len(x1.words), len(x2.words)))
    var borrow: Int32 = 0
    var ith: Int = 0
    var difference: Int32 = 0  # Int32 is sufficient for the difference

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
        result.words.append(UInt32(difference))
        ith += 1

    # Remove trailing zeros
    while len(result.words) > 1 and result.words[len(result.words) - 1] == 0:
        result.words.resize(len(result.words) - 1)

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
        return BigUInt.from_raw_words(UInt32(0))

    # CASE: One of the operands is one or negative one
    if x1.is_one():
        return x2

    if x2.is_one():
        return x1

    # The maximum number of words in the result is the sum of the words in the operands
    var max_result_len = len(x1.words) + len(x2.words)
    var result = BigUInt(empty=True, capacity=max_result_len)

    # Initialize result words with zeros
    for _ in range(max_result_len):
        result.words.append(0)

    # Perform the multiplication word by word (from least significant to most significant)
    # x1 = x1[0] + x1[1] * 10^9
    # x2 = x2[0] + x2[1] * 10^9
    # x1 * x2 = x1[0] * x2[0] + (x1[0] * x2[1] + x1[1] * x2[0]) * 10^9 + x1[1] * x2[1] * 10^18
    var carry: UInt64 = 0
    for i in range(len(x1.words)):
        # Skip if the word is zero
        if x1.words[i] == 0:
            continue

        carry = UInt64(0)

        for j in range(len(x2.words)):
            # Skip if the word is zero
            if x2.words[j] == 0:
                continue

            # Calculate the product of the current words
            # plus the carry from the previous multiplication
            # plus the value already at this position in the result
            var product = UInt64(x1.words[i]) * UInt64(
                x2.words[j]
            ) + carry + UInt64(result.words[i + j])

            # The lower 9 digits (base 10^9) go into the current word
            # The upper digits become the carry for the next position
            result.words[i + j] = UInt32(product % 1_000_000_000)
            carry = product // 1_000_000_000

        # If there is a carry left, add it to the next position
        if carry > 0:
            result.words[i + len(x2.words)] += UInt32(carry)

    # Remove trailing zeros
    while len(result.words) > 1 and result.words[len(result.words) - 1] == 0:
        result.words.resize(len(result.words) - 1)

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
    # CASE: Division by zero
    if x2.is_zero():
        raise Error("Error in `truncate_divide`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        return BigUInt()  # Return zero

    # CASE: Division by one
    if x2.is_one():
        return x1

    # CASE: dividend < divisor
    if x1.compare(x2) < 0:
        return BigUInt()  # Return zero

    # CASE: dividend == divisor
    if x1.compare(x2) == 0:
        return BigUInt.from_raw_words(UInt32(1))

    # CASE: Single words division
    if len(x1.words) == 1 and len(x2.words) == 1:
        var result = BigUInt.from_raw_words(UInt32(x1.words[0] // x2.words[0]))
        return result^

    # CASE: Duo words division by means of UInt64
    if len(x1.words) <= 2 and len(x2.words) <= 2:
        var result = BigUInt.from_uint64(x1.to_uint64() // x2.to_uint64())
        return result^

    # CASE: Divisor is 10^n
    # First remove the last words (10^9) and then shift the rest
    if BigUInt.is_abs_power_of_10(x2):
        var result: BigUInt
        if len(x2.words) == 1:
            result = x1
        else:
            var word_shift = len(x2.words) - 1
            # If we need to drop more words than exists, result is zero
            if word_shift >= len(x1.words):
                return BigUInt()
            # Create result with the remaining words
            result = BigUInt(empty=True)
            for i in range(word_shift, len(x1.words)):
                result.words.append(x1.words[i])

        # Get the last word of the divisor
        var x2_word = x2.words[len(x2.words) - 1]
        var carry = UInt32(0)
        var power_of_carry = UInt32(1_000_000_000) // x2_word
        for i in range(len(result.words) - 1, -1, -1):
            var quot = result.words[i] // x2_word
            var rem = result.words[i] % x2_word
            result.words[i] = quot + carry * power_of_carry
            carry = rem

        # Remove leading zeros
        while (
            len(result.words) > 1 and result.words[len(result.words) - 1] == 0
        ):
            result.words.resize(len(result.words) - 1)

        return result

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
            normalized_x1 = multiply(
                x1, BigUInt.from_raw_words(normalization_factor)
            )
            normalized_x2 = multiply(
                x2, BigUInt.from_raw_words(normalization_factor)
            )

    return general_divide(normalized_x1, normalized_x2)


fn truncate_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, truncating toward zero.
    It is equal to floored division for unsigned numbers.
    See `floor_divide` for more details.
    """
    return floor_divide(x1, x2)


fn modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, truncating toward zero.
    The remainder has the same sign as the dividend and satisfies:
    x1 = floor_divide(x1, x2) * x2 + modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2, with the same sign as x1.

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


# ===----------------------------------------------------------------------=== #
# Division Algorithms
# general_divide
# ===----------------------------------------------------------------------=== #


fn general_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """General division algorithm for BigInt numbers.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2.

    Raises:
        ValueError: If the divisor is zero.
    """

    if x2.is_zero():
        raise Error("Error in `general_divide`: Division by zero")

    # Initialize result and remainder
    var result = BigUInt(empty=True, capacity=len(x1.words))
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
        var trial_product = x2 * BigUInt.from_raw_words(UInt32(q))
        var shifted_product = shift_words_left(trial_product, j)

        # OPTIMIZATION: Binary search for adjustment
        if shifted_product.compare(remainder) > 0:
            var low: UInt64 = 0
            var high: UInt64 = q - 1

            while low <= high:
                var mid = (low + high) / 2

                # Recalculate with new q
                trial_product = x2 * BigUInt.from_raw_words(UInt32(mid))
                shifted_product = shift_words_left(trial_product, j)

                if shifted_product.compare(remainder) <= 0:
                    q = mid  # This works
                    low = mid + 1
                else:
                    high = mid - 1

            # Final recalculation with best q
            trial_product = x2 * BigUInt.from_raw_words(UInt32(q))
            shifted_product = shift_words_left(trial_product, j)

        result.words[j] = UInt32(q)
        remainder = subtract(remainder, shifted_product)
        j -= 1

    # Remove trailing zeros
    while len(result.words) > 1 and result.words[len(result.words) - 1] == 0:
        result.words.resize(len(result.words) - 1)

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
    """Shifts a BigUInt left by adding leading zeros.
    Equivalent to multiplying by 10^(9*positions)."""
    if num.is_zero():
        return BigUInt()

    var result = BigUInt(empty=True, capacity=len(num.words) + positions)

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
        return BigUInt.from_raw_words(1)

    # Handle small powers directly
    if n < 9:
        var value: UInt32 = 1
        for _ in range(n):
            value *= 10
        return BigUInt.from_raw_words(value)

    # For larger powers, split into groups of 9 digits
    var words = n // 9
    var remainder = n % 9

    var result = BigUInt(empty=True)

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
