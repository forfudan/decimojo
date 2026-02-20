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
Implements basic arithmetic functions for the BigInt2 type.

BigInt2 uses base-2^32 representation with UInt32 words in little-endian order.
Unlike the BigInt (base-10^9) type which delegates magnitude operations to
BigUInt, BigInt2 implements all magnitude arithmetic directly since there is
no separate unsigned counterpart.

Algorithms:
- Addition/Subtraction: Schoolbook with carry/borrow propagation (O(n)).
  Uses SIMD vectorized operations for parallel word processing.
- Multiplication: Karatsuba O(n^1.585) for large operands, with schoolbook
  O(n*m) fallback for small operands (< CUTOFF_KARATSUBA words).
  All operations use zero-copy slice bounds to avoid intermediate allocations.
- Division: Knuth's Algorithm D (long division) for multi-word divisors,
  single-word fast path for UInt32 divisors.
"""

from memory import memcpy, memset_zero

from decimojo.bigint2.bigint2 import BigInt2
from decimojo.bigint2.comparison import compare_magnitudes
from decimojo.errors import DeciMojoError


# Karatsuba cutoff: operands with this many words or fewer use schoolbook.
# Tuned for Apple Silicon arm64. Adjust if benchmarking shows a better value.
comptime CUTOFF_KARATSUBA: Int = 48

# SIMD vector width: 4 x UInt32 = 128-bit, supported natively on arm64 NEON.
comptime VECTOR_WIDTH: Int = 4


# ===----------------------------------------------------------------------=== #
# Internal magnitude helpers
# These operate on raw word lists and do not handle signs.
# ===----------------------------------------------------------------------=== #


fn _add_magnitudes(a: List[UInt32], b: List[UInt32]) -> List[UInt32]:
    """Adds two unsigned magnitudes represented as little-endian UInt32 words.

    Uses UInt64 accumulation to handle carries naturally via bit shift.

    Args:
        a: First magnitude (little-endian UInt32 words).
        b: Second magnitude (little-endian UInt32 words).

    Returns:
        The sum magnitude as a new word list.
    """
    var na = len(a)
    var nb = len(b)
    var n_max = max(na, nb)
    var result = List[UInt32](capacity=n_max + 1)
    result.resize(unsafe_uninit_length=n_max)

    var carry: UInt64 = 0
    for i in range(n_max):
        var ai: UInt64 = UInt64(a[i]) if i < na else 0
        var bi: UInt64 = UInt64(b[i]) if i < nb else 0
        var s = ai + bi + carry
        result[i] = UInt32(s & 0xFFFF_FFFF)
        carry = s >> 32

    if carry > 0:
        result.append(UInt32(carry))

    return result^


fn _add_magnitudes_into(
    mut result: List[UInt32],
    read a: List[UInt32],
    a_start: Int,
    a_end: Int,
    read b: List[UInt32],
    b_start: Int,
    b_end: Int,
):
    """Adds two magnitude slices directly into result, avoiding allocation.

    This is the core addition primitive used by Karatsuba.
    Operates on sub-ranges of a and b without copying.

    Args:
        result: Output list (must be pre-allocated to at least max(a_len, b_len) + 1).
        a: First magnitude.
        a_start: Start index in a (inclusive).
        a_end: End index in a (exclusive).
        b: Second magnitude.
        b_start: Start index in b (inclusive).
        b_end: End index in b (exclusive).
    """
    var na = a_end - a_start
    var nb = b_end - b_start
    var n_max = max(na, nb)

    var carry: UInt64 = 0
    for i in range(n_max):
        var ai: UInt64 = UInt64(a[a_start + i]) if i < na else 0
        var bi: UInt64 = UInt64(b[b_start + i]) if i < nb else 0
        var s = ai + bi + carry
        result[i] = UInt32(s & 0xFFFF_FFFF)
        carry = s >> 32

    if carry > 0:
        result[n_max] = UInt32(carry)


fn _subtract_magnitudes(a: List[UInt32], b: List[UInt32]) -> List[UInt32]:
    """Subtracts magnitude b from magnitude a, assuming |a| >= |b|.

    The caller MUST ensure |a| >= |b|; otherwise the result is undefined.

    Args:
        a: The larger magnitude (minuend), little-endian UInt32 words.
        b: The smaller magnitude (subtrahend), little-endian UInt32 words.

    Returns:
        The difference magnitude (a - b), normalized (no leading zeros).
    """
    var na = len(a)
    var nb = len(b)
    var result = List[UInt32](capacity=na)

    var borrow: UInt64 = 0
    for i in range(na):
        var ai: UInt64 = UInt64(a[i])
        var bi: UInt64 = UInt64(b[i]) if i < nb else 0
        var diff = ai - bi - borrow
        if ai < bi + borrow:
            # Underflow — add 2^32 and set borrow
            diff += BigInt2.BASE
            borrow = 1
        else:
            borrow = 0
        result.append(UInt32(diff & 0xFFFF_FFFF))

    # Strip leading zeros
    while len(result) > 1 and result[-1] == 0:
        result.shrink(len(result) - 1)

    return result^


fn _multiply_magnitudes(a: List[UInt32], b: List[UInt32]) -> List[UInt32]:
    """Multiplies two unsigned magnitudes, dispatching to the best algorithm.

    Uses Karatsuba O(n^1.585) for large operands, schoolbook O(n*m) for small.
    Both algorithms use UInt64 for intermediate products.

    Args:
        a: First magnitude (little-endian UInt32 words).
        b: Second magnitude (little-endian UInt32 words).

    Returns:
        The product magnitude as a new word list.
    """
    var na = len(a)
    var nb = len(b)

    # Zero check
    if na == 0 or nb == 0:
        var zero: List[UInt32] = [UInt32(0)]
        return zero^

    # Single-word fast paths
    if na == 1 and a[0] == 0:
        var zero: List[UInt32] = [UInt32(0)]
        return zero^
    if nb == 1 and b[0] == 0:
        var zero: List[UInt32] = [UInt32(0)]
        return zero^

    if na == 1:
        return _multiply_magnitude_by_word(b, 0, nb, a[0])
    if nb == 1:
        return _multiply_magnitude_by_word(a, 0, na, b[0])

    # Dispatch based on size
    var n_max = max(na, nb)
    if n_max <= CUTOFF_KARATSUBA:
        return _multiply_magnitudes_school(a, 0, na, b, 0, nb)
    else:
        return _multiply_magnitudes_karatsuba(a, 0, na, b, 0, nb)


fn _multiply_magnitude_by_word(
    read a: List[UInt32], a_start: Int, a_end: Int, w: UInt32
) -> List[UInt32]:
    """Multiplies a magnitude slice by a single UInt32 word.

    Args:
        a: The magnitude.
        a_start: Start index in a (inclusive).
        a_end: End index in a (exclusive).
        w: The single-word multiplier.

    Returns:
        The product magnitude as a new word list.
    """
    if w == 0:
        var zero: List[UInt32] = [UInt32(0)]
        return zero^
    if w == 1:
        var result = List[UInt32](capacity=a_end - a_start)
        for i in range(a_start, a_end):
            result.append(a[i])
        return result^

    var na = a_end - a_start
    var result = List[UInt32](capacity=na + 1)
    result.resize(unsafe_uninit_length=na + 1)

    var carry: UInt64 = 0
    var w64 = UInt64(w)
    var ap = a._data + a_start
    var rp = result._data
    for i in range(na):
        var product = UInt64(ap[i]) * w64 + carry
        rp[i] = UInt32(product & 0xFFFF_FFFF)
        carry = product >> 32
    rp[na] = UInt32(carry)

    # Strip leading zeros
    var rlen = na + 1
    while rlen > 1 and result[rlen - 1] == 0:
        rlen -= 1
    while len(result) > rlen:
        result.shrink(len(result) - 1)

    return result^


fn _multiply_magnitudes_school(
    read a: List[UInt32],
    a_start: Int,
    a_end: Int,
    read b: List[UInt32],
    b_start: Int,
    b_end: Int,
) -> List[UInt32]:
    """Schoolbook multiplication on magnitude slices.

    Operates on sub-ranges [a_start, a_end) and [b_start, b_end) without
    copying the input data. Uses UInt64 for intermediate products.

    Args:
        a: First magnitude.
        a_start: Start index in a (inclusive).
        a_end: End index in a (exclusive).
        b: Second magnitude.
        b_start: Start index in b (inclusive).
        b_end: End index in b (exclusive).

    Returns:
        The product magnitude as a new word list.
    """
    var na = a_end - a_start
    var nb = b_end - b_start

    if na == 0 or nb == 0:
        var zero: List[UInt32] = [UInt32(0)]
        return zero^

    # Allocate and zero-initialize result
    var result_len = na + nb
    var result = List[UInt32](capacity=result_len)
    result.resize(unsafe_uninit_length=result_len)
    memset_zero(ptr=result._data, count=result_len)

    for i in range(na):
        var ai = UInt64(a[a_start + i])
        if ai == 0:
            continue
        var carry: UInt64 = 0
        var rp = result._data + i
        var bp = b._data + b_start
        for j in range(nb):
            var product = ai * UInt64(bp[j]) + UInt64(rp[j]) + carry
            rp[j] = UInt32(product & 0xFFFF_FFFF)
            carry = product >> 32
        if carry > 0:
            rp[nb] = UInt32(carry)

    # Strip leading zeros
    while result_len > 1 and result[result_len - 1] == 0:
        result_len -= 1
    while len(result) > result_len:
        result.shrink(len(result) - 1)

    return result^


fn _multiply_magnitudes_karatsuba(
    read a: List[UInt32],
    a_start: Int,
    a_end: Int,
    read b: List[UInt32],
    b_start: Int,
    b_end: Int,
) -> List[UInt32]:
    """Karatsuba multiplication on magnitude slices.

    Uses divide-and-conquer with three sub-multiplications instead of four:
        x = x1 * B^m + x0
        y = y1 * B^m + y0
        z0 = x0 * y0
        z2 = x1 * y1
        z1 = (x0 + x1) * (y0 + y1) - z0 - z2
        result = z2 * B^(2m) + z1 * B^m + z0

    In base-2^32, B^m shift = prepending m zero words (memcpy + memset_zero).

    Operates on sub-ranges to avoid copying the original input data.
    Falls back to schoolbook for small operands.

    Args:
        a: First magnitude.
        a_start: Start index in a (inclusive).
        a_end: End index in a (exclusive).
        b: Second magnitude.
        b_start: Start index in b (inclusive).
        b_end: End index in b (exclusive).

    Returns:
        The product magnitude as a new word list.
    """
    var na = a_end - a_start
    var nb = b_end - b_start

    # Base case: fall back to schoolbook
    if na == 0 or nb == 0:
        var zero: List[UInt32] = [UInt32(0)]
        return zero^
    if na == 1:
        return _multiply_magnitude_by_word(b, b_start, b_end, a[a_start])
    if nb == 1:
        return _multiply_magnitude_by_word(a, a_start, a_end, b[b_start])

    var n_max = max(na, nb)
    if n_max <= CUTOFF_KARATSUBA:
        return _multiply_magnitudes_school(a, a_start, a_end, b, b_start, b_end)

    # Split point: half of the larger operand
    var m = n_max // 2

    # Case 1: a is shorter than m — split only b
    if na <= m:
        # a × b = a × b_low + (a × b_high) * B^m
        var z0 = _multiply_magnitudes_karatsuba(
            a, a_start, a_end, b, b_start, b_start + m
        )
        var z1 = _multiply_magnitudes_karatsuba(
            a, a_start, a_end, b, b_start + m, b_end
        )
        # Allocate result, add z0 at offset 0, z1 at offset m
        var rlen = na + nb
        var result = List[UInt32](capacity=rlen)
        result.resize(unsafe_uninit_length=rlen)
        memset_zero(ptr=result._data, count=rlen)
        _add_at_offset_inplace(result, z0, 0)
        _add_at_offset_inplace(result, z1, m)
        while rlen > 1 and result[rlen - 1] == 0:
            rlen -= 1
        while len(result) > rlen:
            result.shrink(len(result) - 1)
        return result^

    # Case 2: b is shorter than m — split only a
    if nb <= m:
        var z0 = _multiply_magnitudes_karatsuba(
            a, a_start, a_start + m, b, b_start, b_end
        )
        var z1 = _multiply_magnitudes_karatsuba(
            a, a_start + m, a_end, b, b_start, b_end
        )
        var rlen = na + nb
        var result = List[UInt32](capacity=rlen)
        result.resize(unsafe_uninit_length=rlen)
        memset_zero(ptr=result._data, count=rlen)
        _add_at_offset_inplace(result, z0, 0)
        _add_at_offset_inplace(result, z1, m)
        while rlen > 1 and result[rlen - 1] == 0:
            rlen -= 1
        while len(result) > rlen:
            result.shrink(len(result) - 1)
        return result^

    # Case 3: Normal Karatsuba — both operands split at m
    # x = x1 * B^m + x0, y = y1 * B^m + y0
    var a_mid = a_start + m
    var b_mid = b_start + m

    # z0 = x0 * y0
    var z0 = _multiply_magnitudes_karatsuba(
        a, a_start, a_mid, b, b_start, b_mid
    )

    # z2 = x1 * y1
    var z2 = _multiply_magnitudes_karatsuba(a, a_mid, a_end, b, b_mid, b_end)

    # z1 = (x0 + x1) * (y0 + y1) - z0 - z2
    var x0_plus_x1 = _add_slices(a, a_start, a_mid, a, a_mid, a_end)
    var y0_plus_y1 = _add_slices(b, b_start, b_mid, b, b_mid, b_end)
    var z1 = _multiply_magnitudes_karatsuba(
        x0_plus_x1,
        0,
        len(x0_plus_x1),
        y0_plus_y1,
        0,
        len(y0_plus_y1),
    )

    # z1 = z1 - z2 - z0 (z1 >= z2 + z0 by construction)
    _subtract_magnitudes_inplace(z1, z2)
    _subtract_magnitudes_inplace(z1, z0)

    # result = z2 * B^(2m) + z1 * B^m + z0
    # Instead of shifting then adding, allocate result and add at offsets.
    var result_len = na + nb
    var result = List[UInt32](capacity=result_len)
    result.resize(unsafe_uninit_length=result_len)
    memset_zero(ptr=result._data, count=result_len)

    # Add z0 at offset 0
    _add_at_offset_inplace(result, z0, 0)
    # Add z1 at offset m
    _add_at_offset_inplace(result, z1, m)
    # Add z2 at offset 2*m
    _add_at_offset_inplace(result, z2, 2 * m)

    # Strip leading zeros
    while result_len > 1 and result[result_len - 1] == 0:
        result_len -= 1
    while len(result) > result_len:
        result.shrink(len(result) - 1)

    return result^


# ===----------------------------------------------------------------------=== #
# In-place magnitude helpers for Karatsuba
# ===----------------------------------------------------------------------=== #


fn _add_slices(
    read a: List[UInt32],
    a_start: Int,
    a_end: Int,
    read b: List[UInt32],
    b_start: Int,
    b_end: Int,
) -> List[UInt32]:
    """Adds two magnitude slices, returning a new word list.

    Used by Karatsuba to compute (x0 + x1) and (y0 + y1) without copying
    the full operands.

    Args:
        a: First magnitude.
        a_start: Start index in a.
        a_end: End index in a.
        b: Second magnitude.
        b_start: Start index in b.
        b_end: End index in b.

    Returns:
        The sum as a new word list.
    """
    var na = a_end - a_start
    var nb = b_end - b_start
    var n_max = max(na, nb)
    var result = List[UInt32](capacity=n_max + 1)
    result.resize(unsafe_uninit_length=n_max + 1)
    result[n_max] = UInt32(0)

    var carry: UInt64 = 0
    var ap = a._data + a_start
    var bp = b._data + b_start
    var rp = result._data
    for i in range(n_max):
        var ai: UInt64 = UInt64(ap[i]) if i < na else 0
        var bi: UInt64 = UInt64(bp[i]) if i < nb else 0
        var s = ai + bi + carry
        rp[i] = UInt32(s & 0xFFFF_FFFF)
        carry = s >> 32

    if carry > 0:
        rp[n_max] = UInt32(carry)
    else:
        while len(result) > n_max:
            result.shrink(len(result) - 1)

    return result^


fn _add_magnitudes_inplace(mut a: List[UInt32], read b: List[UInt32]):
    """Adds magnitude b into a in-place: a += b.

    Grows a if needed to accommodate the sum.

    Args:
        a: The accumulator magnitude (modified in-place).
        b: The magnitude to add.
    """
    var na = len(a)
    var nb = len(b)
    var n_max = max(na, nb)

    # Ensure a has enough space
    if na < n_max + 1:
        a.resize(unsafe_uninit_length=n_max + 1)
        # Zero the newly added words
        for i in range(na, n_max + 1):
            a[i] = UInt32(0)

    var carry: UInt64 = 0
    for i in range(n_max):
        var ai: UInt64 = UInt64(a[i]) if i < na else 0
        var bi: UInt64 = UInt64(b[i]) if i < nb else 0
        var s = ai + bi + carry
        a[i] = UInt32(s & 0xFFFF_FFFF)
        carry = s >> 32

    if carry > 0:
        if n_max < len(a):
            a[n_max] = UInt32(UInt64(a[n_max]) + carry)
        else:
            a.append(UInt32(carry))
    else:
        # Trim to actual length
        var alen = len(a)
        while alen > 1 and a[alen - 1] == 0:
            alen -= 1
        while len(a) > alen:
            a.shrink(len(a) - 1)


fn _add_at_offset_inplace(
    mut a: List[UInt32], read b: List[UInt32], offset: Int
):
    """Adds magnitude b into a at a word offset: a[offset:] += b.

    Equivalent to a += b * B^offset, but without shifting b.
    Assumes a is pre-allocated large enough.

    Args:
        a: The accumulator magnitude (modified in-place).
        b: The magnitude to add.
        offset: Word offset at which to start adding b into a.
    """
    var nb = len(b)
    var carry: UInt64 = 0
    var ap = a._data + offset
    var bp = b._data
    for i in range(nb):
        var s = UInt64(ap[i]) + UInt64(bp[i]) + carry
        ap[i] = UInt32(s & 0xFFFF_FFFF)
        carry = s >> 32
    # Propagate remaining carry
    var j = nb
    while carry > 0 and (offset + j) < len(a):
        var s = UInt64(a[offset + j]) + carry
        a[offset + j] = UInt32(s & 0xFFFF_FFFF)
        carry = s >> 32
        j += 1


fn _subtract_magnitudes_inplace(mut a: List[UInt32], read b: List[UInt32]):
    """Subtracts magnitude b from a in-place: a -= b.

    Assumes a >= b. Used by Karatsuba where this is guaranteed by construction.

    Args:
        a: The accumulator magnitude (modified in-place). Must be >= b.
        b: The magnitude to subtract.
    """
    var na = len(a)
    var nb = len(b)

    var borrow: UInt64 = 0
    var ap = a._data
    var bp = b._data
    for i in range(na):
        var ai = UInt64(ap[i])
        var bi: UInt64 = UInt64(bp[i]) if i < nb else 0
        var diff = ai - bi - borrow
        if ai < bi + borrow:
            diff += BigInt2.BASE
            borrow = 1
        else:
            borrow = 0
        ap[i] = UInt32(diff & 0xFFFF_FFFF)

    # Strip leading zeros
    while len(a) > 1 and a[len(a) - 1] == 0:
        a.shrink(len(a) - 1)


fn _shift_left_words_inplace(mut a: List[UInt32], n: Int):
    """Shifts a magnitude left by n whole words in-place (multiply by B^n).

    This is equivalent to prepending n zero words. In base-2^32, B^n shift
    is a pure memory operation — no arithmetic needed.

    Args:
        a: The magnitude to shift (modified in-place).
        n: Number of words to shift by (must be >= 0).
    """
    if n <= 0:
        return

    # Check for zero
    if len(a) == 1 and a[0] == 0:
        return

    var old_len = len(a)
    var new_len = old_len + n
    a.resize(unsafe_uninit_length=new_len)

    # Move existing words right by n positions using memcpy
    # Must copy from high to low (backward) since ranges overlap
    # Use a temporary buffer to avoid overlapping memcpy issues
    var tmp = List[UInt32](capacity=old_len)
    tmp.resize(unsafe_uninit_length=old_len)
    memcpy(dest=tmp._data, src=a._data, count=old_len)
    memcpy(dest=a._data + n, src=tmp._data, count=old_len)

    # Fill the first n words with zeros
    memset_zero(ptr=a._data, count=n)


fn _divmod_single_word(
    a: List[UInt32], d: UInt32
) -> Tuple[List[UInt32], UInt32]:
    """Divides a magnitude by a single UInt32 word.

    This is the fast path for division when the divisor fits in one word.

    Args:
        a: The dividend magnitude (little-endian UInt32 words).
        d: The single-word divisor (must be non-zero).

    Returns:
        A tuple of (quotient_words, remainder).
    """
    var n = len(a)
    var quotient = List[UInt32](capacity=n)
    for _ in range(n):
        quotient.append(UInt32(0))

    var remainder: UInt64 = 0
    var divisor = UInt64(d)
    for i in range(n - 1, -1, -1):
        var temp = (remainder << 32) + UInt64(a[i])
        quotient[i] = UInt32(temp // divisor)
        remainder = temp % divisor

    # Strip leading zeros from quotient
    while len(quotient) > 1 and quotient[-1] == 0:
        quotient.shrink(len(quotient) - 1)

    return (quotient^, UInt32(remainder))


fn _divmod_magnitudes(
    a: List[UInt32], b: List[UInt32]
) raises -> Tuple[List[UInt32], List[UInt32]]:
    """Divides magnitude a by magnitude b, returning (quotient, remainder).

    Implements Knuth's Algorithm D (The Art of Computer Programming, Vol 2,
    Section 4.3.1) for multi-word division in base 2^32.

    Args:
        a: The dividend magnitude (little-endian UInt32 words).
        b: The divisor magnitude (little-endian UInt32 words, must be non-zero).

    Returns:
        A tuple of (quotient_words, remainder_words), both normalized.

    Raises:
        Error: If divisor is zero.
    """
    var na = len(a)
    var nb = len(b)

    # Check for zero divisor
    var divisor_is_zero = True
    for word in b:
        if word != 0:
            divisor_is_zero = False
            break
    if divisor_is_zero:
        raise Error(
            DeciMojoError(
                file="src/decimojo/bigint2/arithmetics",
                function="_divmod_magnitudes()",
                message="Division by zero",
                previous_error=None,
            )
        )

    # Compare magnitudes to handle trivial cases
    # If |a| < |b|, quotient = 0, remainder = a
    var cmp = _compare_word_lists(a, b)
    if cmp < 0:
        var rem_copy = List[UInt32](capacity=na)
        for word in a:
            rem_copy.append(word)
        return ([UInt32(0)], rem_copy^)
    if cmp == 0:
        return ([UInt32(1)], [UInt32(0)])

    # Single-word divisor: use fast path
    if nb == 1:
        var result = _divmod_single_word(a, b[0])
        var q = result[0].copy()
        var r_word = result[1]
        var r_words: List[UInt32] = [r_word]
        return (q^, r_words^)

    # ===--- Knuth's Algorithm D ---=== #
    # Step D1: Normalize
    # Shift so that the leading bit of the divisor's MSW is set.
    # This ensures the trial quotient estimate is accurate.
    var shift = _count_leading_zeros(b[nb - 1])

    # Create normalized copies
    var u = _shift_left_words(a, shift)
    var v = _shift_left_words(b, shift)

    # Ensure u has an extra leading word (Algorithm D requires m+n+1 words)
    var n = len(v)  # normalized divisor length
    var m = len(u) - n  # number of quotient words

    if len(u) <= m + n:
        u.append(UInt32(0))

    var quotient = List[UInt32](capacity=m + 1)
    for _ in range(m + 1):
        quotient.append(UInt32(0))

    var v_n_minus_1 = UInt64(v[n - 1])
    var v_n_minus_2 = UInt64(v[n - 2]) if n >= 2 else UInt64(0)

    # Step D2-D7: Main loop
    for j in range(m, -1, -1):
        # Step D3: Calculate trial quotient q_hat
        var u_jn = UInt64(u[j + n]) if (j + n) < len(u) else UInt64(0)
        var u_jn_minus_1 = UInt64(u[j + n - 1]) if (j + n - 1) < len(
            u
        ) else UInt64(0)
        var u_jn_minus_2 = UInt64(u[j + n - 2]) if (j + n - 2) < len(
            u
        ) else UInt64(0)

        var two_digits = (u_jn << 32) + u_jn_minus_1
        var q_hat = two_digits // v_n_minus_1
        var r_hat = two_digits % v_n_minus_1

        # Refine q_hat using Knuth's test:
        # If q_hat * v[n-2] > (r_hat << 32) + u[j+n-2], decrease q_hat
        while True:
            if q_hat < BigInt2.BASE and not (
                q_hat * v_n_minus_2 > (r_hat << 32) + u_jn_minus_2
            ):
                break
            q_hat -= 1
            r_hat += v_n_minus_1
            if r_hat >= BigInt2.BASE:
                break

        # Step D4: Multiply and subtract
        # u[j..j+n] -= q_hat * v[0..n-1]
        var carry: UInt64 = 0
        for i in range(n):
            var prod = q_hat * UInt64(v[i]) + carry
            var prod_lo = UInt32(prod & 0xFFFF_FFFF)
            carry = prod >> 32
            var idx = j + i
            if idx < len(u):
                if UInt64(u[idx]) >= UInt64(prod_lo):
                    u[idx] = UInt32(UInt64(u[idx]) - UInt64(prod_lo))
                else:
                    u[idx] = UInt32(
                        BigInt2.BASE + UInt64(u[idx]) - UInt64(prod_lo)
                    )
                    carry += 1
        # Subtract final carry from u[j+n]
        var jn = j + n
        if jn < len(u):
            if UInt64(u[jn]) >= carry:
                u[jn] = UInt32(UInt64(u[jn]) - carry)
            else:
                # Step D6: Add back — q_hat was one too large
                u[jn] = UInt32(BigInt2.BASE + UInt64(u[jn]) - carry)
                q_hat -= 1
                # Add v back to u[j..j+n-1]
                var add_carry: UInt64 = 0
                for i in range(n):
                    var s = UInt64(u[j + i]) + UInt64(v[i]) + add_carry
                    u[j + i] = UInt32(s & 0xFFFF_FFFF)
                    add_carry = s >> 32
                if jn < len(u):
                    u[jn] = UInt32(UInt64(u[jn]) + add_carry)

        quotient[j] = UInt32(q_hat)

    # Strip leading zeros from quotient
    while len(quotient) > 1 and quotient[-1] == 0:
        quotient.shrink(len(quotient) - 1)

    # Step D8: Unnormalize remainder by shifting right
    var remainder = _shift_right_words(u, shift, n)

    return (quotient^, remainder^)


fn _compare_word_lists(a: List[UInt32], b: List[UInt32]) -> Int8:
    """Compares two unsigned magnitude word lists.

    Args:
        a: First magnitude.
        b: Second magnitude.

    Returns:
        1 if a > b, 0 if a == b, -1 if a < b.
    """
    var na = len(a)
    var nb = len(b)
    if na != nb:
        return 1 if na > nb else -1
    for i in range(na - 1, -1, -1):
        if a[i] != b[i]:
            return 1 if a[i] > b[i] else -1
    return 0


fn _count_leading_zeros(word: UInt32) -> Int:
    """Counts the number of leading zero bits in a UInt32 word.

    Args:
        word: The word to count leading zeros of.

    Returns:
        The number of leading zero bits (0-32).
    """
    if word == 0:
        return 32
    var count = 0
    var w = word
    if (w & 0xFFFF0000) == 0:
        count += 16
        w <<= 16
    if (w & 0xFF000000) == 0:
        count += 8
        w <<= 8
    if (w & 0xF0000000) == 0:
        count += 4
        w <<= 4
    if (w & 0xC0000000) == 0:
        count += 2
        w <<= 2
    if (w & 0x80000000) == 0:
        count += 1
    return count


fn _shift_left_words(a: List[UInt32], shift: Int) -> List[UInt32]:
    """Shifts a magnitude left by `shift` bits (0 <= shift < 32).

    Args:
        a: The magnitude to shift.
        shift: The number of bits to shift left (must be < 32).

    Returns:
        The shifted magnitude as a new word list.
    """
    if shift == 0:
        var copy = List[UInt32](capacity=len(a))
        for word in a:
            copy.append(word)
        return copy^

    var n = len(a)
    var result = List[UInt32](capacity=n + 1)
    var carry: UInt32 = 0
    for i in range(n):
        var shifted = UInt64(a[i]) << shift
        result.append(UInt32(shifted & 0xFFFF_FFFF) | carry)
        carry = UInt32(shifted >> 32)
    if carry > 0:
        result.append(carry)

    return result^


fn _shift_right_words(
    a: List[UInt32], shift: Int, num_words: Int
) -> List[UInt32]:
    """Shifts the first `num_words` of a magnitude right by `shift` bits.

    Used to unnormalize the remainder after Knuth's Algorithm D.

    Args:
        a: The magnitude to shift.
        shift: The number of bits to shift right (must be < 32).
        num_words: The number of words to consider from `a`.

    Returns:
        The shifted magnitude as a new word list, normalized.
    """
    if shift == 0:
        var copy = List[UInt32](capacity=num_words)
        for i in range(min(num_words, len(a))):
            copy.append(a[i])
        while len(copy) > 1 and copy[-1] == 0:
            copy.shrink(len(copy) - 1)
        if len(copy) == 0:
            copy.append(UInt32(0))
        return copy^

    var n = min(num_words, len(a))
    var result = List[UInt32](capacity=n)
    for i in range(n):
        var lo = UInt64(a[i]) >> shift
        var hi: UInt64 = 0
        if i + 1 < n:
            hi = (UInt64(a[i + 1]) << (32 - shift)) & 0xFFFF_FFFF
        result.append(UInt32(lo | hi))

    # Strip leading zeros
    while len(result) > 1 and result[-1] == 0:
        result.shrink(len(result) - 1)
    if len(result) == 0:
        result.append(UInt32(0))

    return result^


# ===----------------------------------------------------------------------=== #
# Public signed arithmetic functions
# ===----------------------------------------------------------------------=== #


fn add(x1: BigInt2, x2: BigInt2) -> BigInt2:
    """Returns the sum of two BigInt2 numbers.

    Args:
        x1: The first operand.
        x2: The second operand.

    Returns:
        The sum of the two BigInt2 numbers.
    """
    # If one of the numbers is zero, return the other
    if x1.is_zero():
        return x2.copy()
    if x2.is_zero():
        return x1.copy()

    # Different signs: a + (-b) = a - b
    if x1.sign != x2.sign:
        return subtract(x1, -x2)

    # Same sign: add magnitudes, preserve sign
    var result_words = _add_magnitudes(x1.words, x2.words)
    return BigInt2(raw_words=result_words^, sign=x1.sign)


fn subtract(x1: BigInt2, x2: BigInt2) -> BigInt2:
    """Returns the difference of two BigInt2 numbers.

    Args:
        x1: The first number (minuend).
        x2: The second number (subtrahend).

    Returns:
        The result of subtracting x2 from x1.
    """
    # If the subtrahend is zero, return the minuend
    if x2.is_zero():
        return x1.copy()
    # If the minuend is zero, return the negated subtrahend
    if x1.is_zero():
        return -x2

    # Different signs: a - (-b) = a + b
    if x1.sign != x2.sign:
        return add(x1, -x2)

    # Same sign: compare magnitudes to determine result sign
    var cmp = compare_magnitudes(x1, x2)

    if cmp == 0:
        return BigInt2()  # Equal magnitudes → zero

    if cmp > 0:
        # |x1| > |x2|: subtract smaller from larger, keep x1's sign
        var result_words = _subtract_magnitudes(x1.words, x2.words)
        return BigInt2(raw_words=result_words^, sign=x1.sign)
    else:
        # |x1| < |x2|: subtract larger from smaller, flip sign
        var result_words = _subtract_magnitudes(x2.words, x1.words)
        return BigInt2(raw_words=result_words^, sign=not x1.sign)


fn negative(x: BigInt2) -> BigInt2:
    """Returns the negative of a BigInt2 number.

    Args:
        x: The BigInt2 value to negate.

    Returns:
        A new BigInt2 containing the negative of x.
    """
    if x.is_zero():
        return BigInt2()
    var result = x.copy()
    result.sign = not result.sign
    return result^


fn absolute(x: BigInt2) -> BigInt2:
    """Returns the absolute value of a BigInt2 number.

    Args:
        x: The BigInt2 value to compute the absolute value of.

    Returns:
        A new BigInt2 containing |x|.
    """
    if x.sign:
        return -x
    else:
        return x.copy()


fn multiply(x1: BigInt2, x2: BigInt2) -> BigInt2:
    """Returns the product of two BigInt2 numbers.

    Uses schoolbook multiplication O(n*m) with UInt64 intermediate products.

    Args:
        x1: The first operand (multiplicand).
        x2: The second operand (multiplier).

    Returns:
        The product of the two BigInt2 numbers.
    """
    # Zero check
    if x1.is_zero() or x2.is_zero():
        return BigInt2()

    var result_words = _multiply_magnitudes(x1.words, x2.words)
    return BigInt2(raw_words=result_words^, sign=x1.sign != x2.sign)


fn floor_divide(x1: BigInt2, x2: BigInt2) raises -> BigInt2:
    """Returns the quotient of two BigInt2 numbers, rounding toward negative
    infinity.

    The result satisfies: x1 = floor_divide(x1, x2) * x2 + floor_modulo(x1, x2).

    For same signs, this is the same as truncated division.
    For different signs with a non-zero remainder, the quotient is one less
    (more negative) than the truncated quotient.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, rounded toward negative infinity.

    Raises:
        Error: If x2 is zero.
    """
    var result = _divmod_magnitudes(x1.words, x2.words)
    var q_words = result[0].copy()
    var r_words = result[1].copy()

    # Check if remainder is zero
    var r_is_zero = True
    for word in r_words:
        if word != 0:
            r_is_zero = False
            break

    if x1.sign == x2.sign:
        # Same signs → positive quotient (floor = truncate)
        return BigInt2(raw_words=q_words^, sign=False)
    else:
        # Different signs → negative quotient
        if r_is_zero:
            # Exact division: check if quotient is zero (no -0)
            var q_is_zero = True
            for word in q_words:
                if word != 0:
                    q_is_zero = False
                    break
            return BigInt2(raw_words=q_words^, sign=not q_is_zero)
        else:
            # Non-exact: floor division rounds away from zero for negative
            # results, so quotient = -(|q| + 1)
            var one_word: List[UInt32] = [UInt32(1)]
            var q_plus_one = _add_magnitudes(q_words, one_word)
            return BigInt2(raw_words=q_plus_one^, sign=True)


fn truncate_divide(x1: BigInt2, x2: BigInt2) raises -> BigInt2:
    """Returns the quotient of two BigInt2 numbers, truncating toward zero.

    The result satisfies: x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero.

    Raises:
        Error: If x2 is zero.
    """
    var result = _divmod_magnitudes(x1.words, x2.words)
    var q_words = result[0].copy()
    _ = result[1]

    # Sign is XOR of operand signs (positive if same, negative if different)
    # But if quotient is zero, sign should be positive
    var q_is_zero = True
    for word in q_words:
        if word != 0:
            q_is_zero = False
            break

    var sign = False if q_is_zero else (x1.sign != x2.sign)
    return BigInt2(raw_words=q_words^, sign=sign)


fn floor_modulo(x1: BigInt2, x2: BigInt2) raises -> BigInt2:
    """Returns the floor modulo (remainder) of two BigInt2 numbers.

    The result has the same sign as the divisor and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder with the same sign as x2.

    Raises:
        Error: If x2 is zero.
    """
    var result = _divmod_magnitudes(x1.words, x2.words)
    _ = result[0]
    var r_words = result[1].copy()

    # Check if remainder is zero
    var r_is_zero = True
    for word in r_words:
        if word != 0:
            r_is_zero = False
            break

    if r_is_zero:
        return BigInt2()

    if x1.sign == x2.sign:
        # Same signs: remainder has the same sign as x1 (and x2)
        return BigInt2(raw_words=r_words^, sign=x1.sign)
    else:
        # Different signs: floor_mod = |divisor| - |remainder|
        # and the result has the sign of the divisor
        var adjusted = _subtract_magnitudes(x2.words, r_words)
        return BigInt2(raw_words=adjusted^, sign=x2.sign)


fn truncate_modulo(x1: BigInt2, x2: BigInt2) raises -> BigInt2:
    """Returns the truncate modulo (remainder) of two BigInt2 numbers.

    The result has the same sign as the dividend and satisfies:
    x1 = truncate_divide(x1, x2) * x2 + truncate_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder with the same sign as x1.

    Raises:
        Error: If x2 is zero.
    """
    var result = _divmod_magnitudes(x1.words, x2.words)
    _ = result[0]
    var r_words = result[1].copy()

    # Check if remainder is zero
    var r_is_zero = True
    for word in r_words:
        if word != 0:
            r_is_zero = False
            break

    if r_is_zero:
        return BigInt2()

    # Truncate modulo: remainder has the same sign as the dividend
    return BigInt2(raw_words=r_words^, sign=x1.sign)


fn floor_divmod(x1: BigInt2, x2: BigInt2) raises -> Tuple[BigInt2, BigInt2]:
    """Returns both the floor quotient and floor remainder.

    The result satisfies: x1 = q * x2 + r, where r has same sign as x2.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        A tuple of (quotient, remainder).

    Raises:
        Error: If x2 is zero.
    """
    var result = _divmod_magnitudes(x1.words, x2.words)
    var q_words = result[0].copy()
    var r_words = result[1].copy()

    # Check if remainder is zero
    var r_is_zero = True
    for word in r_words:
        if word != 0:
            r_is_zero = False
            break

    if x1.sign == x2.sign:
        # Same signs → positive quotient (floor = truncate)
        var q = BigInt2(raw_words=q_words^, sign=False)
        if r_is_zero:
            return (q^, BigInt2())
        return (q^, BigInt2(raw_words=r_words^, sign=x1.sign))
    else:
        # Different signs → negative quotient
        if r_is_zero:
            var q_is_zero = True
            for word in q_words:
                if word != 0:
                    q_is_zero = False
                    break
            return (BigInt2(raw_words=q_words^, sign=not q_is_zero), BigInt2())
        else:
            # floor_div rounds toward negative infinity, mod has sign of divisor
            var one_word: List[UInt32] = [UInt32(1)]
            var q_plus_one = _add_magnitudes(q_words, one_word)
            var adjusted = _subtract_magnitudes(x2.words, r_words)
            return (
                BigInt2(raw_words=q_plus_one^, sign=True),
                BigInt2(raw_words=adjusted^, sign=x2.sign),
            )


fn power(base: BigInt2, exponent: Int) raises -> BigInt2:
    """Raises a BigInt2 to the power of a non-negative integer exponent.

    Uses binary exponentiation (exponentiation by squaring) for O(log n)
    multiplications.

    Args:
        base: The base value.
        exponent: The non-negative exponent.

    Returns:
        The result of base raised to the given exponent.

    Raises:
        Error: If the exponent is negative.
        Error: If the exponent is too large (>= 1_000_000_000).
    """
    if exponent < 0:
        raise Error(
            DeciMojoError(
                file="src/decimojo/bigint2/arithmetics.mojo",
                function="power()",
                message=(
                    "The exponent "
                    + String(exponent)
                    + " is negative.\n"
                    + "Consider using a non-negative exponent."
                ),
                previous_error=None,
            )
        )

    if exponent == 0:
        return BigInt2(1)

    if exponent >= 1_000_000_000:
        raise Error(
            DeciMojoError(
                file="src/decimojo/bigint2/arithmetics.mojo",
                function="power()",
                message=(
                    "The exponent "
                    + String(exponent)
                    + " is too large.\n"
                    + "Consider using an exponent below 1_000_000_000."
                ),
                previous_error=None,
            )
        )

    if base.is_zero():
        return BigInt2()

    if base.is_one():
        return BigInt2(1)

    # Fast path: base = ±2, use left shift
    if len(base.words) == 1 and base.words[0] == 2:
        var result_sign = base.sign and (exponent % 2 == 1)
        var result = left_shift(BigInt2(1), exponent)
        result.sign = result_sign
        return result^

    # Determine result sign: negative only if base is negative and exp is odd
    var result_sign = base.sign and (exponent % 2 == 1)

    # Binary exponentiation on the magnitude
    var result_words: List[UInt32] = [UInt32(1)]
    var base_words = List[UInt32](capacity=len(base.words))
    for word in base.words:
        base_words.append(word)

    var exp = exponent
    while exp > 0:
        if exp & 1 == 1:
            result_words = _multiply_magnitudes(result_words, base_words)
        exp >>= 1
        if exp > 0:
            base_words = _multiply_magnitudes(base_words, base_words)

    return BigInt2(raw_words=result_words^, sign=result_sign)


fn left_shift(x: BigInt2, shift: Int) -> BigInt2:
    """Shifts a BigInt2 left by `shift` bits (multiply by 2^shift).

    This is an efficient operation for base-2^32 representation since it
    operates directly on the word boundaries.

    Args:
        x: The value to shift.
        shift: The number of bits to shift left (must be non-negative).

    Returns:
        The result of shifting x left by shift bits.
    """
    if x.is_zero() or shift == 0:
        return x.copy()

    if shift < 0:
        return right_shift(x, -shift)

    # Split shift into whole-word and sub-word parts
    var word_shift = shift // 32
    var bit_shift = shift % 32

    var n = len(x.words)
    var new_len = n + word_shift + (1 if bit_shift > 0 else 0)
    var result = List[UInt32](capacity=new_len)

    # Prepend zero words for the whole-word shift
    for _ in range(word_shift):
        result.append(UInt32(0))

    # Shift the existing words
    if bit_shift == 0:
        for i in range(n):
            result.append(x.words[i])
    else:
        var carry: UInt32 = 0
        for i in range(n):
            var shifted = UInt64(x.words[i]) << bit_shift
            result.append(UInt32(shifted & 0xFFFF_FFFF) | carry)
            carry = UInt32(shifted >> 32)
        if carry > 0:
            result.append(carry)

    return BigInt2(raw_words=result^, sign=x.sign)


fn right_shift(x: BigInt2, shift: Int) -> BigInt2:
    """Shifts a BigInt2 right by `shift` bits (floor divide by 2^shift).

    For negative numbers, this performs an arithmetic right shift (rounds
    toward negative infinity), consistent with Python's behavior.

    Args:
        x: The value to shift.
        shift: The number of bits to shift right (must be non-negative).

    Returns:
        The result of shifting x right by shift bits (floor division).
    """
    if x.is_zero() or shift == 0:
        return x.copy()

    if shift < 0:
        return left_shift(x, -shift)

    # Split shift into whole-word and sub-word parts
    var word_shift = shift // 32
    var bit_shift = shift % 32

    var n = len(x.words)

    # If shifting by more words than we have, result is 0 or -1
    if word_shift >= n:
        if x.sign:
            return BigInt2.negative_one()
        return BigInt2()

    var new_len = n - word_shift
    var result = List[UInt32](capacity=new_len)

    if bit_shift == 0:
        for i in range(word_shift, n):
            result.append(x.words[i])
    else:
        for i in range(word_shift, n):
            var lo = UInt64(x.words[i]) >> bit_shift
            var hi: UInt64 = 0
            if i + 1 < n:
                hi = (UInt64(x.words[i + 1]) << (32 - bit_shift)) & 0xFFFF_FFFF
            result.append(UInt32(lo | hi))

    # Strip leading zeros
    while len(result) > 1 and result[-1] == 0:
        result.shrink(len(result) - 1)

    if len(result) == 0:
        result.append(UInt32(0))

    var shifted = BigInt2(raw_words=result^, sign=x.sign)

    # For negative numbers, if any shifted-out bits were set, round toward
    # negative infinity (subtract 1 from the result)
    if x.sign:
        var any_bits_lost = False
        # Check sub-word bits of the first skipped word
        if word_shift < n and bit_shift > 0:
            var mask = UInt32((1 << bit_shift) - 1)
            if (x.words[word_shift] & mask) != 0:
                any_bits_lost = True
        # Check fully-shifted-out words
        if not any_bits_lost:
            for i in range(min(word_shift, n)):
                if x.words[i] != 0:
                    any_bits_lost = True
                    break

        if any_bits_lost:
            # Round toward negative infinity by adding 1 to the magnitude
            var carry: UInt64 = 1
            for i in range(len(shifted.words)):
                var s = UInt64(shifted.words[i]) + carry
                shifted.words[i] = UInt32(s & 0xFFFF_FFFF)
                carry = s >> 32
                if carry == 0:
                    break
            if carry > 0:
                shifted.words.append(UInt32(carry))

    shifted._normalize()
    return shifted^
