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
