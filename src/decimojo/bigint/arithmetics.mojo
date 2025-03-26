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
Implements basic arithmetic functions for the BigInt type.
"""

import time
import testing

from decimojo.bigint.bigint import BigInt
import decimojo.bigint.comparison
from decimojo.rounding_mode import RoundingMode


fn add(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the sum of two BigInts.

    Args:
        x1: The first BigInt operand.
        x2: The second BigInt operand.

    Returns:
        The sum of the two BigInts.
    """

    # If one of the numbers is zero, return the other number
    if x1.is_zero():
        return x2
    if x2.is_zero():
        return x1

    # If signs are different, we use `subtract` instead
    if x1.sign != x2.sign:
        return subtract(x1, -x2)

    # At this point, both numbers have the same sign
    # The result will have the same sign as the operands
    # The result will have at most one more word than the longer operand
    var result = BigInt(
        empty=True,
        capacity=max(len(x1.magnitude.words), len(x2.magnitude.words)) + 1,
        sign=False,
    )
    result.sign = x1.sign  # Result has the same sign as the operands

    var carry: UInt32 = 0
    var ith: Int = 0
    var sum_of_words: UInt32 = 0

    # Add corresponding words from both numbers
    while ith < len(x1.magnitude.words) or ith < len(x2.magnitude.words):
        sum_of_words = carry

        # Add x1's word if available
        if ith < len(x1.magnitude.words):
            sum_of_words += x1.magnitude.words[ith]

        # Add x2's word if available
        if ith < len(x2.magnitude.words):
            sum_of_words += x2.magnitude.words[ith]

        # Compute new word and carry
        carry = UInt32(sum_of_words // 1_000_000_000)
        result.magnitude.words.append(UInt32(sum_of_words % 1_000_000_000))

        ith += 1

    # Handle final carry if it exists
    if carry > 0:
        result.magnitude.words.append(carry)

    return result^


fn subtract(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the difference of two numbers.

    Args:
        x1: The first number (minuend).
        x2: The second number (subtrahend).

    Returns:
        The result of subtracting x2 from x1.
    """
    # If the subtrahend is zero, return the minuend
    if x2.is_zero():
        return x1
    # If the minuend is zero, return the negated subtrahend
    if x1.is_zero():
        return -x2

    # If signs are different, we use `add` instead
    if x1.sign != x2.sign:
        return add(x1, -x2)

    # At this point, both numbers have the same sign
    # We need to determine which number has the larger absolute value
    var comparison_result = decimojo.bigint.comparison.compare_absolute(x1, x2)

    if comparison_result == 0:
        # |x1| = |x2|
        return BigInt()  # Return zero

    # The result will have no more words than the larger operand
    var result = BigInt(
        empty=True,
        capacity=max(len(x1.magnitude.words), len(x2.magnitude.words)),
        sign=False,
    )
    var borrow: Int32 = 0
    var ith: Int = 0
    var difference: Int32 = 0  # Int32 is sufficient for the difference

    if comparison_result > 0:
        # |x1| > |x2|
        result.sign = x1.sign
        while ith < len(x1.magnitude.words):
            # Subtract the borrow
            difference = Int32(x1.magnitude.words[ith]) - borrow
            # Subtract smaller's word if available
            if ith < len(x2.magnitude.words):
                difference -= Int32(x2.magnitude.words[ith])
            # Handle borrowing if needed
            if difference < Int32(0):
                difference += Int32(1_000_000_000)
                borrow = Int32(1)
            else:
                borrow = Int32(0)
            result.magnitude.words.append(UInt32(difference))
            ith += 1

    else:
        # |x1| < |x2|
        # Same as above, but we swap x1 and x2
        result.sign = not x2.sign
        while ith < len(x2.magnitude.words):
            difference = Int32(x2.magnitude.words[ith]) - borrow
            if ith < len(x1.magnitude.words):
                difference -= Int32(x1.magnitude.words[ith])
            if difference < Int32(0):
                difference += Int32(1_000_000_000)
                borrow = Int32(1)
            else:
                borrow = Int32(0)
            result.magnitude.words.append(UInt32(difference))
            ith += 1

    # Remove trailing zeros
    while (
        len(result.magnitude.words) > 1
        and result.magnitude.words[len(result.magnitude.words) - 1] == 0
    ):
        result.magnitude.words.resize(len(result.magnitude.words) - 1)

    return result^


fn negative(x: BigInt) -> BigInt:
    """Returns the negative of a BigInt number.

    Args:
        x: The BigInt value to compute the negative of.

    Returns:
        A new BigInt containing the negative of x.
    """
    var result = x
    result.sign = not result.sign
    return result^


fn absolute(x: BigInt) -> BigInt:
    """Returns the absolute value of a BigInt number.

    Args:
        x: The BigInt value to compute the absolute value of.

    Returns:
        A new BigInt containing the absolute value of x.
    """
    if x.sign:
        return -x
    else:
        return x


fn multiply(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the product of two BigInt numbers.

    Args:
        x1: The first BigInt operand (multiplicand).
        x2: The second BigInt operand (multiplier).

    Returns:
        The product of the two BigInt numbers.
    """
    # CASE: One of the operands is zero
    if x1.is_zero() or x2.is_zero():
        return BigInt(UInt32(0), sign=x1.sign != x2.sign)

    # CASE: One of the operands is one or negative one
    if x1.is_one_or_minus_one():
        var result = x2
        result.sign = x1.sign != x2.sign
        return result^

    if x2.is_one_or_minus_one():
        var result = x1
        result.sign = x1.sign != x2.sign
        return result^

    # The maximum number of words in the result is the sum of the words in the operands
    var max_result_len = len(x1.magnitude.words) + len(x2.magnitude.words)
    var result = BigInt(empty=True, capacity=max_result_len, sign=False)
    result.sign = x1.sign != x2.sign

    # Initialize result words with zeros
    for _ in range(max_result_len):
        result.magnitude.words.append(0)

    # Perform the multiplication word by word (from least significant to most significant)
    # x1 = x1[0] + x1[1] * 10^9
    # x2 = x2[0] + x2[1] * 10^9
    # x1 * x2 = x1[0] * x2[0] + (x1[0] * x2[1] + x1[1] * x2[0]) * 10^9 + x1[1] * x2[1] * 10^18
    var carry: UInt64 = 0
    for i in range(len(x1.magnitude.words)):
        # Skip if the word is zero
        if x1.magnitude.words[i] == 0:
            continue

        carry = UInt64(0)

        for j in range(len(x2.magnitude.words)):
            # Skip if the word is zero
            if x2.magnitude.words[j] == 0:
                continue

            # Calculate the product of the current words
            # plus the carry from the previous multiplication
            # plus the value already at this position in the result
            var product = UInt64(x1.magnitude.words[i]) * UInt64(
                x2.magnitude.words[j]
            ) + carry + UInt64(result.magnitude.words[i + j])

            # The lower 9 digits (base 10^9) go into the current word
            # The upper digits become the carry for the next position
            result.magnitude.words[i + j] = UInt32(product % 1_000_000_000)
            carry = product // 1_000_000_000

        # If there is a carry left, add it to the next position
        if carry > 0:
            result.magnitude.words[i + len(x2.magnitude.words)] += UInt32(carry)

    # Remove trailing zeros
    while (
        len(result.magnitude.words) > 1
        and result.magnitude.words[len(result.magnitude.words) - 1] == 0
    ):
        result.magnitude.words.resize(len(result.magnitude.words) - 1)

    return result^


fn floor_divide(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the quotient of two numbers, rounding toward negative infinity.
    The modulo has the same sign as the divisor and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_divide(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 // x2, rounded toward negative infinity.
    """

    if x2.is_zero():
        raise Error("Error in `floor_divide`: Division by zero")

    if x1.is_zero():
        return BigInt()

    if x1.sign == x2.sign:
        # Use floor (truncate) division between magnitudes
        return BigInt(x1.magnitude.floor_divide(x2.magnitude), sign=False)

    else:
        # Use ceil division of the magnitudes
        return BigInt(x1.magnitude.ceil_divide(x2.magnitude), sign=True)


fn truncate_divide(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the quotient of two BigInt numbers, truncating toward zero.
    The modulo has the same sign as the divisor and satisfies:
    x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero.

    Raises:
        ValueError: If the divisor is zero.
    """
    # CASE: Division by zero
    if x2.is_zero():
        raise Error("Error in `truncate_divide`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        return BigInt()  # Return zero

    # CASE: Division by one or negative one
    if x2.is_one_or_minus_one():
        var result = x1  # Copy dividend
        # If divisor is -1, negate the result
        if x2.sign:
            result.sign = not result.sign
        return result

    # CASE: Single words division
    if len(x1.magnitude.words) == 1 and len(x2.magnitude.words) == 1:
        var result = BigInt(
            UInt32(x1.magnitude.words[0] // x2.magnitude.words[0]),
            sign=x1.sign != x2.sign,
        )
        return result

    # CASE: Powers of 10
    if BigInt.is_abs_power_of_10(x2):
        # Divisor is 10^n
        # Remove the last words (10^9) and shift the rest
        var result: BigInt
        if len(x2.magnitude.words) == 1:
            result = x1
        else:
            var word_shift = len(x2.magnitude.words) - 1
            # If we need to drop more words than exists, result is zero
            if word_shift >= len(x1.magnitude.words):
                return BigInt()
            # Create result with the remaining words
            result = BigInt(empty=True, sign=False)
            for i in range(word_shift, len(x1.magnitude.words)):
                result.magnitude.words.append(x1.magnitude.words[i])

        # Get the last word of the divisor
        var x2_word = x2.magnitude.words[len(x2.magnitude.words) - 1]
        var carry = UInt32(0)
        var power_of_carry = UInt32(1_000_000_000) // x2_word
        for i in range(len(result.magnitude.words) - 1, -1, -1):
            var quot = result.magnitude.words[i] // x2_word
            var rem = result.magnitude.words[i] % x2_word
            result.magnitude.words[i] = quot + carry * power_of_carry
            carry = rem

        # Remove leading zeros
        while (
            len(result.magnitude.words) > 1
            and result.magnitude.words[len(result.magnitude.words) - 1] == 0
        ):
            result.magnitude.words.resize(len(result.magnitude.words) - 1)

        result.sign = x1.sign != x2.sign
        return result

    # CASE: |dividend| < |divisor|
    if x1.compare_absolute(x2) < 0:
        return BigInt()  # Return zero

    # CASE: |dividend| == |divisor|
    if x1.compare_absolute(x2) == 0:
        return BigInt(UInt32(1), sign=x1.sign != x2.sign)

    # CASE: division by a single-word number
    if len(x2.magnitude.words) == 1:
        var divisor_value = x2.magnitude.words[0]
        var result = BigInt(empty=True, sign=False)
        var temp_remainder: UInt64 = 0

        # Process from most significant word to least significant
        for i in range(len(x1.magnitude.words) - 1, -1, -1):
            # Combine remainder with current digit
            var current = temp_remainder * 1_000_000_000 + UInt64(
                x1.magnitude.words[i]
            )

            # Calculate quotient and new remainder
            var quotient_digit = current // UInt64(divisor_value)
            temp_remainder = current % UInt64(divisor_value)

            # Only add significant digits to the result
            # This avoids leading zeros
            if len(result.magnitude.words) > 0 or quotient_digit > 0:
                result.magnitude.words.append(UInt32(quotient_digit))

        # If no digits were added, result is zero
        if len(result.magnitude.words) == 0:
            result.magnitude.words.append(0)

        # To match the expected base-10^9 representation,
        # we need to reverse the order of the words in the result
        var reversed_result = BigInt(
            empty=True, capacity=len(result.magnitude.words), sign=False
        )
        for i in range(len(result.magnitude.words) - 1, -1, -1):
            reversed_result.magnitude.words.append(result.magnitude.words[i])

        # Set the sign
        reversed_result.sign = x1.sign != x2.sign
        return reversed_result

    # CASE: multi-word divisors
    # Initialize result and working copy of dividend
    var result = BigInt(
        empty=True, capacity=len(x1.magnitude.words), sign=False
    )
    var remainder = absolute(x1)
    var normalized_divisor = absolute(x2)

    # Calculate the number of significant words in each operand
    var n = len(remainder.magnitude.words)
    while n > 0 and remainder.magnitude.words[n - 1] == 0:
        n -= 1

    var m = len(normalized_divisor.magnitude.words)
    while m > 0 and normalized_divisor.magnitude.words[m - 1] == 0:
        m -= 1

    # If divisor has more significant digits than dividend, result is zero
    if m > n:
        return BigInt()

    # Shift divisor left to align with dividend
    var d = n - m

    # Initialize result with zeros
    for _ in range(d + 1):
        result.magnitude.words.append(0)

    # Working variables for the division algorithm
    var j = d

    # Main division loop
    while j >= 0:
        # Calculate quotient digit estimate
        var dividend_part: UInt64 = 0

        # Get the relevant part of the dividend for this step
        if j + m < n:
            dividend_part = UInt64(remainder.magnitude.words[j + m])
            if j + m - 1 < n:
                dividend_part = dividend_part * 1_000_000_000 + UInt64(
                    remainder.magnitude.words[j + m - 1]
                )
        elif j + m - 1 < n:
            dividend_part = UInt64(remainder.magnitude.words[j + m - 1])

        # Calculate quotient digit (cap at MAX_DIGIT)
        var divisor_high = UInt64(normalized_divisor.magnitude.words[m - 1])
        if divisor_high == 0:
            divisor_high = 1  # Avoid division by zero
        var q = min(dividend_part // divisor_high, UInt64(999_999_999))

        # Create trial product: q * divisor
        var trial_product = normalized_divisor * BigInt(UInt32(q), sign=False)

        # Shift trial product left j positions
        var shifted_product = BigInt(empty=True, sign=False)
        for _ in range(j):
            shifted_product.magnitude.words.append(0)
        for word in trial_product.magnitude.words:
            shifted_product.magnitude.words.append(word[])

        # Use binary search for quotient adjustment
        if shifted_product.compare_absolute(remainder) > 0:
            # Initial estimate was too high, use binary search to find correct q
            var low: UInt64 = 0
            var high: UInt64 = q - 1

            while low <= high:
                var mid: UInt64 = (low + high) / 2

                # Recalculate trial product with new q
                trial_product = normalized_divisor * BigInt(
                    UInt32(mid), sign=False
                )

                # Recalculate shifted product
                shifted_product = BigInt(empty=True, sign=False)
                for _ in range(j):
                    shifted_product.magnitude.words.append(0)
                for word in trial_product.magnitude.words:
                    shifted_product.magnitude.words.append(word[])

                if shifted_product.compare_absolute(remainder) <= 0:
                    # This quotient works, try a larger one
                    q = mid  # Keep track of best quotient found so far
                    low = mid + 1
                else:
                    # Too large, try smaller
                    high = mid - 1

            # Recalculate final product with best q found
            trial_product = normalized_divisor * BigInt(UInt32(q), sign=False)

            # Recalculate final shifted product
            shifted_product = BigInt(empty=True, sign=False)
            for _ in range(j):
                shifted_product.magnitude.words.append(0)
            for word in trial_product.magnitude.words:
                shifted_product.magnitude.words.append(word[])

        # Store quotient digit
        result.magnitude.words[j] = UInt32(q)

        # Subtract shifted product from remainder
        remainder = subtract(remainder, shifted_product)

        # Move to next position
        j -= 1

    # Remove leading zeros
    while (
        len(result.magnitude.words) > 1
        and result.magnitude.words[len(result.magnitude.words) - 1] == 0
    ):
        result.magnitude.words.resize(len(result.magnitude.words) - 1)

    # Set the sign
    result.sign = x1.sign != x2.sign
    return result


fn floor_modulo(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the remainder of two numbers, truncating toward negative infinity.
    The remainder has the same sign as the divisor and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2, with the same sign as x2.
    """

    if x2.is_zero():
        raise Error("Error in `floor_modulo`: Division by zero")

    if x1.sign == x2.sign:
        # Use floor (truncate) division between magnitudes
        return BigInt(x1.magnitude.floor_modulo(x2.magnitude), sign=x2.sign)

    else:
        # Use ceil division of the magnitudes
        return BigInt(x1.magnitude.ceil_modulo(x2.magnitude), sign=x2.sign)


fn truncate_modulo(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the remainder of two numbers, truncating toward zero.
    The remainder has the same sign as the dividend and satisfies:
    x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2, with the same sign as x1.

    Raises:
        ValueError: If the divisor is zero.
    """
    # CASE: Division by zero
    if x2.is_zero():
        raise Error("Error in `truncate_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        return BigInt()  # Return zero

    # CASE: Divisor is one or negative one - no remainder
    if x2.is_one_or_minus_one():
        return BigInt()  # Always divisible with no remainder

    # CASE: |dividend| < |divisor| - the remainder is the dividend itself
    if decimojo.bigint.comparison.compare_absolute(x1, x2) < 0:
        return x1

    # Calculate quotient with truncation
    var quotient = truncate_divide(x1, x2)

    # Calculate remainder: dividend - (divisor * quotient)
    var remainder = subtract(x1, multiply(x2, quotient))

    return remainder
