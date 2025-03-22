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

from decimojo.big_int.big_int import BigInt
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
    if len(x1.words) == 1 and x1.words[0] == 0:
        return x2
    if len(x2.words) == 1 and x2.words[0] == 0:
        return x1

    # If signs are different, we use `subtract` instead
    if x1.sign != x2.sign:
        # Create a copy of x2 with opposite sign
        var neg_x2 = x2
        # TODO: Implement negate for BigInt and replce the following line
        neg_x2.sign = not neg_x2.sign
        return subtract(x1, neg_x2)

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

    return result


fn subtract(x1: BigInt, x2: BigInt) raises -> BigInt:
    return x1
