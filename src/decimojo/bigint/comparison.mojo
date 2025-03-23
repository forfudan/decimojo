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
Implements functions for comparison operations on BigInt objects.
"""

import testing

from decimojo.bigint.bigint import BigInt


fn compare_absolute(x1: BigInt, x2: BigInt) -> Int8:
    """Compares the absolute values of two numbers and returns the result.

    Args:
        x1: First number.
        x2: Second number.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if |x1| > |x2|.
        (2)  0 if |x1| = |x2|.
        (3) -1 if |x1| < |x2|.
    """
    # Compare the number of words
    if len(x1.words) > len(x2.words):
        return Int8(1)
    if len(x1.words) < len(x2.words):
        return Int8(-1)

    # If the number of words are equal,
    # compare the words from the most significant to the least significant.
    var ith = len(x1.words) - 1
    while ith >= 0:
        if x1.words[ith] > x2.words[ith]:
            return Int8(1)
        if x1.words[ith] < x2.words[ith]:
            return Int8(-1)
        ith -= 1

    # All words are equal
    return Int8(0)
