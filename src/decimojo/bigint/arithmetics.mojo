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
        empty=True, capacity=max(len(x1.words), len(x2.words)) + 1
    )
    result.sign = x1.sign  # Result has the same sign as the operands

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
    var result = BigInt(empty=True, capacity=max(len(x1.words), len(x2.words)))
    var borrow: Int32 = 0
    var ith: Int = 0
    var difference: Int32 = 0  # Int32 is sufficient for the difference

    if comparison_result > 0:
        # |x1| > |x2|
        result.sign = x1.sign
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

    else:
        # |x1| < |x2|
        # Same as above, but we swap x1 and x2
        result.sign = not x2.sign
        while ith < len(x2.words):
            difference = Int32(x2.words[ith]) - borrow
            if ith < len(x1.words):
                difference -= Int32(x1.words[ith])
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
        return BigInt.from_raw_words(UInt32(0), sign=x1.sign != x2.sign)

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
    var max_result_len = len(x1.words) + len(x2.words)
    var result = BigInt(empty=True, capacity=max_result_len)
    result.sign = x1.sign != x2.sign

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


fn truncate_divide(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the quotient of two BigInt numbers, truncating toward zero.

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
        return BigInt()

    # CASE: Division by one or negative one
    if x2.is_one_or_minus_one():
        var result = x1
        # If divisor is -1, negate the result
        if x2.sign:
            result.sign = not result.sign
        return result

    # CASE: Single word division
    if len(x1.words) == 1 and len(x2.words) == 1:
        var result = BigInt.from_raw_words(
            UInt32(x1.words[0] // x2.words[0]), sign=x1.sign != x2.sign
        )
        return result

    # CASE: |dividend| < |divisor|
    if x1.compare_absolute(x2) < 0:
        return BigInt()  # Return zero

    # CASE: |dividend| == |divisor|
    if x1.compare_absolute(x2) == 0:
        return BigInt.from_raw_words(UInt32(1), sign=x1.sign != x2.sign)

    # CASE: |dividend| > |divisor|
    # Initialize the result and prepare for long division
    var result = BigInt(empty=True, capacity=len(x1.words))

    # Create a working copy of the dividend which will be modified during division
    # The dividend is always positive during the division algorithm
    var remainder = -x1 if x1.sign else x1

    # Normalized divisor
    # This makes the trial division more accurate
    var normalized_divisor = -x2 if x2.sign else x2

    # Perform the division algorithm (long division for base-10^9)
    var n_words_remainder = len(remainder.words)
    var n_words_advisor = len(normalized_divisor.words)
    var positions = n_words_remainder - n_words_advisor

    # Initialize result words with zeros
    for _ in range(positions + 1):
        result.words.append(0)

    # Process from most significant to least significant position
    for i in range(positions, -1, -1):
        # Calculate the trial quotient using the 2 most significant words
        var trial_numerator: UInt64 = 0
        if i + n_words_advisor < n_words_remainder:
            trial_numerator = (
                UInt64(remainder.words[i + n_words_advisor]) * 1_000_000_000
            )

        if i + n_words_advisor - 1 < n_words_remainder:
            trial_numerator += UInt64(remainder.words[i + n_words_advisor - 1])

        var trial_quotient = trial_numerator // UInt64(
            normalized_divisor.words[n_words_advisor - 1]
        )

        # Ensure the trial quotient isn't too large (should be <= 999,999,999)
        if trial_quotient >= 1_000_000_000:
            trial_quotient = 999_999_999

        # Make a trial product: divisor * trial_quotient
        var trial_product = normalized_divisor * BigInt.from_raw_words(
            UInt32(trial_quotient), sign=False
        )

        # Shift the trial product left by i words (multiply by 10^(9*i))
        var shifted_product = BigInt(
            empty=True, capacity=len(trial_product.words) + i
        )
        for _ in range(i):
            shifted_product.words.append(0)
        for j in range(len(trial_product.words)):
            shifted_product.words.append(trial_product.words[j])

        # Check if trial quotient is too large (shifted_product > remainder)
        while shifted_product.compare_absolute(remainder) > 0:
            trial_quotient -= 1

            # Recalculate the trial product
            trial_product = normalized_divisor * BigInt.from_raw_words(
                UInt32(trial_quotient), sign=False
            )

            # Recalculate the shifted product
            shifted_product = BigInt(
                empty=True, capacity=len(trial_product.words) + i
            )
            for _ in range(i):
                shifted_product.words.append(0)
            for j in range(len(trial_product.words)):
                shifted_product.words.append(trial_product.words[j])

            print("DEBUG: trial_quotient =", trial_quotient)
            print("DEBUG: trial_product =", trial_product)
            print("DEBUG: shifted_product =", shifted_product)
            print("DEBUG: remainder =", remainder)

        # Store the quotient digit
        result.words[i] = UInt32(trial_quotient)

        # Subtract: remainder = remainder - shifted_product
        remainder = subtract(remainder, shifted_product)

    # Remove leading zeros in the result
    while len(result.words) > 1 and result.words[len(result.words) - 1] == 0:
        result.words.resize(len(result.words) - 1)

    # Set the sign
    result.sign = x1.sign != x2.sign

    return result^


fn truncate_modulo(x1: BigInt, x2: BigInt) raises -> BigInt:
    """Returns the remainder of two BigInt numbers, truncating toward zero.
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
