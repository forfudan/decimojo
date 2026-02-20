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

    The result is the largest integer y such that y * y <= x
    (for non-negative x).

    Algorithm (CPython precision-doubling, adapted from Modules/mathmodule.c):
        Uses a series of precision-doubling steps starting from a 1-bit
        approximation. At each step, the approximation doubles in precision
        via a division of the appropriate size. Total work is dominated by
        the last step, giving O(M(n)) total where M(n) is multiplication
        cost, rather than O(M(n) * log n) for standard Newton's method.

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

    # Special case: single word — use hardware sqrt
    if len(x.words) == 1:
        if x.words[0] <= 1:
            return x.copy()
        var val = x.words[0]
        var guess = UInt32(math.sqrt(val))
        # Refine: ensure guess^2 <= val < (guess+1)^2
        while guess * guess > val:
            guess -= 1
        while (guess + 1) * (guess + 1) <= val:
            guess += 1
        return BigInt2.from_int(Int(guess))

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

    # For numbers up to ~520 digits (≤ 54 words), Newton's method with a tight
    # initial guess converges in 3-5 iterations and has less per-iteration
    # overhead than the precision-doubling algorithm.
    if len(x.words) <= 54:
        return _sqrt_newton(x)

    # For larger numbers, use CPython's precision-doubling algorithm.
    # This has O(M(n)) total cost vs O(M(n) * log(n)) for Newton's method,
    # but higher per-iteration overhead.
    return _sqrt_precision_doubling(x)


fn _sqrt_newton(x: BigInt2) raises -> BigInt2:
    """Newton's method integer sqrt with tight initial guess from top words.

    Best for medium-sized numbers (3-54 words / up to ~512 digits) where
    the per-iteration overhead of BigInt2 operations is the bottleneck.

    Args:
        x: The BigInt2 value (must be positive, >= 3 words).

    Returns:
        The integer square root.
    """
    var n = len(x.words)

    # Build initial overestimate from top 1-2 words using hardware sqrt
    var top_val: UInt64
    var n_lower_words: Int

    if n % 2 == 0:
        top_val = UInt64(x.words[n - 1]) << 32 | UInt64(x.words[n - 2])
        n_lower_words = n - 2
    else:
        top_val = UInt64(x.words[n - 1])
        n_lower_words = n - 1

    var top_sqrt = UInt64(math.sqrt(top_val)) + 2  # overestimate
    var shift_words = n_lower_words // 2
    var shift_bits = shift_words * 32

    var guess = BigInt2.from_uint64(top_sqrt)
    if shift_bits > 0:
        guess = decimojo.bigint2.arithmetics.left_shift(guess, shift_bits)

    # Newton iterations: converges monotonically from above
    while True:
        var quotient = x // guess
        var new_guess = (guess + quotient) >> 1
        if new_guess >= guess:
            break
        guess = new_guess^

    # Final adjustment
    while True:
        var guess_sq = guess * guess
        if guess_sq > x:
            guess = guess - BigInt2(1)
        else:
            var next = guess + BigInt2(1)
            var next_sq = next * next
            if next_sq <= x:
                guess = next^
            else:
                break

    return guess^


fn _sqrt_precision_doubling(x: BigInt2) raises -> BigInt2:
    """CPython-style precision-doubling integer sqrt.

    Adapted from CPython Modules/mathmodule.c. Each iteration doubles
    the precision of the approximation. Total work is O(M(n)) where
    M(n) is multiplication cost, making this superior to Newton's method
    for large numbers.

    Args:
        x: The BigInt2 value (must be positive, >= 3 words).

    Returns:
        The integer square root.
    """
    var bit_len = x.bit_length()
    var c = (bit_len - 1) // 2

    var a = BigInt2(1)
    var d: Int = 0

    # c.bit_length()
    var c_bits = 0
    var tmp = c
    while tmp > 0:
        c_bits += 1
        tmp >>= 1

    for s in range(c_bits - 1, -1, -1):
        var e = d
        d = c >> s

        var shift_a = d - e - 1
        var shift_n = 2 * c - e - d + 1

        var a_shifted = decimojo.bigint2.arithmetics.left_shift(a, shift_a)
        var n_shifted = decimojo.bigint2.arithmetics.right_shift(x, shift_n)
        var quotient = n_shifted // a
        a = a_shifted + quotient

    # Final adjustment: a - (1 if a*a > x else 0)
    var a_sq = a * a
    if a_sq > x:
        a = a - BigInt2(1)

    return a^


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
