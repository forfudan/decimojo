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


fn truncate_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, truncating toward zero.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to floored division for positive numbers.
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
        return result

    # TODO
    # CASE: Duo, quad, or octa words division by means of UInt64, UInt128, or UInt256

    # CASE: Powers of 10
    if BigUInt.is_abs_power_of_10(x2):
        # Divisor is 10^n
        # Remove the last words (10^9) and shift the rest
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

    # CASE: division by a single-word number
    if len(x2.words) == 1:
        var divisor_value = x2.words[0]
        var result = BigUInt(empty=True)
        var temp_remainder: UInt64 = 0

        # Process from most significant word to least significant
        for i in range(len(x1.words) - 1, -1, -1):
            # Combine remainder with current digit
            var current = temp_remainder * 1_000_000_000 + UInt64(x1.words[i])

            # Calculate quotient and new remainder
            var quotient_digit = current // UInt64(divisor_value)
            temp_remainder = current % UInt64(divisor_value)

            # Only add significant digits to the result
            # This avoids leading zeros
            if len(result.words) > 0 or quotient_digit > 0:
                result.words.append(UInt32(quotient_digit))

        # If no digits were added, result is zero
        if len(result.words) == 0:
            result.words.append(0)

        # To match the expected base-10^9 representation,
        # we need to reverse the order of the words in the result
        var reversed_result = BigUInt(empty=True, capacity=len(result.words))
        for i in range(len(result.words) - 1, -1, -1):
            reversed_result.words.append(result.words[i])

        return reversed_result

    # CASE: multi-word divisors
    # Initialize result and working copy of dividend
    var result = BigUInt(empty=True, capacity=len(x1.words))
    var remainder = x1
    var normalized_divisor = x2

    # Calculate the number of significant words in each operand
    var n = len(remainder.words)
    while n > 0 and remainder.words[n - 1] == 0:
        n -= 1

    var m = len(normalized_divisor.words)
    while m > 0 and normalized_divisor.words[m - 1] == 0:
        m -= 1

    # If divisor has more significant digits than dividend, result is zero
    if m > n:
        return BigUInt()

    # Shift divisor left to align with dividend
    var d = n - m

    # Initialize result with zeros
    for _ in range(d + 1):
        result.words.append(0)

    # Working variables for the division algorithm
    var j = d

    # Main division loop
    while j >= 0:
        # Calculate quotient digit estimate
        var dividend_part: UInt64 = 0

        # Get the relevant part of the dividend for this step
        if j + m < n:
            dividend_part = UInt64(remainder.words[j + m])
            if j + m - 1 < n:
                dividend_part = dividend_part * 1_000_000_000 + UInt64(
                    remainder.words[j + m - 1]
                )
        elif j + m - 1 < n:
            dividend_part = UInt64(remainder.words[j + m - 1])

        # Calculate quotient digit (cap at MAX_DIGIT)
        var divisor_high = UInt64(normalized_divisor.words[m - 1])
        if divisor_high == 0:
            divisor_high = 1  # Avoid division by zero
        var q = min(dividend_part // divisor_high, UInt64(999_999_999))

        # Create trial product: q * divisor
        var trial_product = normalized_divisor * BigUInt.from_raw_words(
            UInt32(q)
        )

        # Shift trial product left j positions
        var shifted_product = BigUInt(empty=True)
        for _ in range(j):
            shifted_product.words.append(0)
        for word in trial_product.words:
            shifted_product.words.append(word[])

        # Use binary search for quotient adjustment
        if shifted_product.compare(remainder) > 0:
            # Initial estimate was too high, use binary search to find correct q
            var low: UInt64 = 0
            var high: UInt64 = q - 1

            while low <= high:
                var mid: UInt64 = (low + high) / 2

                # Recalculate trial product with new q
                trial_product = normalized_divisor * BigUInt.from_raw_words(
                    UInt32(mid)
                )

                # Recalculate shifted product
                shifted_product = BigUInt(empty=True)
                for _ in range(j):
                    shifted_product.words.append(0)
                for word in trial_product.words:
                    shifted_product.words.append(word[])

                if shifted_product.compare(remainder) <= 0:
                    # This quotient works, try a larger one
                    q = mid  # Keep track of best quotient found so far
                    low = mid + 1
                else:
                    # Too large, try smaller
                    high = mid - 1

            # Recalculate final product with best q found
            trial_product = normalized_divisor * BigUInt.from_raw_words(
                UInt32(q)
            )

            # Recalculate final shifted product
            shifted_product = BigUInt(empty=True)
            for _ in range(j):
                shifted_product.words.append(0)
            for word in trial_product.words:
                shifted_product.words.append(word[])

        # Store quotient digit
        result.words[j] = UInt32(q)

        # Subtract shifted product from remainder
        remainder = subtract(remainder, shifted_product)

        # Move to next position
        j -= 1

    # Remove leading zeros
    while len(result.words) > 1 and result.words[len(result.words) - 1] == 0:
        result.words.resize(len(result.words) - 1)

    return result


fn truncate_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, truncating toward zero.
    The remainder has the same sign as the dividend and satisfies:
    x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

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
    var quotient = truncate_divide(x1, x2)

    # Calculate remainder: dividend - (divisor * quotient)
    var remainder = subtract(x1, multiply(x2, quotient))

    return remainder
