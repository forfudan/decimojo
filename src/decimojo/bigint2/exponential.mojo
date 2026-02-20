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

"""Implements exponential functions for the BigInt2 type.

This module provides integer square root using Newton's method with
binary arithmetic, leveraging BigInt2's base-2^32 representation for
efficient bit-level operations.
"""

import math

from decimojo.bigint2.bigint2 import BigInt2
import decimojo.bigint2.arithmetics
from decimojo.errors import DeciMojoError


# ===----------------------------------------------------------------------=== #
# Square Root
# ===----------------------------------------------------------------------=== #


fn sqrt(x: BigInt2) raises -> BigInt2:
    """Calculates the integer square root of a BigInt2 using Newton's method.

    The result is the largest integer y such that y * y <= x.

    Args:
        x: The BigInt2 to calculate the square root of. Must be non-negative.

    Returns:
        The integer square root of x.

    Raises:
        Error: If x is negative.
    """
    if x.is_negative():
        raise Error(
            DeciMojoError(
                file="src/decimojo/bigint2/exponential.mojo",
                function="sqrt()",
                message="Cannot compute square root of a negative number",
                previous_error=None,
            )
        )

    if x.is_zero():
        return BigInt2()

    var one = BigInt2(1)

    # Special case: single word
    if len(x.words) == 1:
        if x.words[0] <= 1:
            return x.copy()
        return BigInt2.from_int(Int(math.sqrt(x.words[0])))

    # Special case: two words — compute via UInt64 sqrt
    if len(x.words) == 2:
        var val = UInt64(x.words[0]) + (UInt64(x.words[1]) << 32)
        var guess = UInt64(math.sqrt(val))
        # Refine: ensure guess^2 <= val < (guess+1)^2
        while guess * guess > val:
            guess -= 1
        while (guess + 1) * (guess + 1) <= val:
            guess += 1
        return BigInt2.from_uint64(guess)

    # Newton's method for larger numbers
    # Initial guess: shift right by half the bit length
    var bit_len = x.bit_length()
    var initial_shift = bit_len // 2
    var guess = decimojo.bigint2.arithmetics.right_shift(x, initial_shift)
    if guess.is_zero():
        guess = one.copy()

    # Newton's iteration: x_{k+1} = (x_k + n / x_k) / 2
    while True:
        var quotient = x // guess
        var new_guess = (guess + quotient) >> 1  # (guess + n/guess) / 2

        # Check for convergence: new_guess >= guess means no more improvement
        if new_guess >= guess:
            break
        guess = new_guess^

    # Verify and adjust: ensure guess^2 <= x < (guess+1)^2
    var guess_sq = guess * guess
    if guess_sq > x:
        guess = guess - one
    else:
        var next_sq = (guess + one) * (guess + one)
        if next_sq <= x:
            guess = guess + one

    return guess^


fn isqrt(x: BigInt2) raises -> BigInt2:
    """Calculates the integer square root of a BigInt2.
    Equivalent to `sqrt()`.

    Args:
        x: The BigInt2 to calculate the integer square root of.

    Returns:
        The integer square root of x.

    Raises:
        Error: If x is negative.
    """
    return sqrt(x)
