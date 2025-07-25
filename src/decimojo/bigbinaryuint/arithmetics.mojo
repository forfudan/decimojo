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
Implements basic arithmetic functions for the BigBinaryUInt type.
"""

from algorithm import vectorize
import math
from memory import memcpy, memset_zero

from decimojo.bigbinaryuint.bigbinaryuint import BigBinaryUInt
from decimojo.rounding_mode import RoundingMode

alias CUTOFF_KARATSUBA: Int = 64
"""The cutoff number of words for using Karatsuba multiplication."""
alias CUTOFF_BURNIKEL_ZIEGLER = 32
"""The cutoff number of words for using Burnikel-Ziegler division."""

# ===----------------------------------------------------------------------=== #
# Unary operations
# negative, absolute
# ===----------------------------------------------------------------------=== #


fn negative(x: BigBinaryUInt) raises -> BigBinaryUInt:
    """Returns the negative of a BigBinaryUInt number if it is zero.

    Args:
        x: The BigBinaryUInt value to compute the negative of.

    Raises:
        Error: If x is not zero, as negative of non-zero unsigned integer is undefined.

    Returns:
        A new BigBinaryUInt containing the negative of x.
    """
    if not x.is_zero():
        raise Error(
            "BigBinaryUInt.arithmetics.negative(): Negative of non-zero"
            " unsigned integer is undefined"
        )
    return BigBinaryUInt()  # Return zero


fn absolute(x: BigBinaryUInt) -> BigBinaryUInt:
    """Returns the absolute value of a BigBinaryUInt number.

    Args:
        x: The BigBinaryUInt value to compute the absolute value of.

    Returns:
        A new BigBinaryUInt containing the absolute value of x.
    """
    return x


# ===----------------------------------------------------------------------=== #
# Addition algorithms
# add, add_inplace, add_inplace_by_uint32
# ===----------------------------------------------------------------------=== #


fn add_slices_simd(
    x: BigBinaryUInt,
    y: BigBinaryUInt,
    bounds_x: Tuple[Int, Int],
    bounds_y: Tuple[Int, Int],
) -> BigBinaryUInt:
    """**[PRIVATE]** Adds two BigBinaryUInt slices using SIMD operations.

    Args:
        x: The first BigBinaryUInt operand (first summand).
        y: The second BigBinaryUInt operand (second summand).
        bounds_x: A tuple containing the start and end indices of the slice in x.
        bounds_y: A tuple containing the start and end indices of the slice in y.

    Returns:
        A new BigBinaryUInt containing the sum of the two numbers.

    Notes:

    **Special cases are not handled here**. Please handle them in the caller.

    This function uses **SIMD operations** to add the words of the two
    BigBinaryUInt slices in parallel. It is optimized for performance and can
    handle large numbers efficiently.

    After the parallel addition, it normalizes the carries to ensure that
    the result is a valid BigBinaryUInt number.

    Although you use an extra loop to normalize the carries, this is still
    faster than the school method for large numbers, as the normalized carries
    can be simplified to addition and subtraction instead of floor division
    and modulo operations.

    This function conducts addtion of the two **BigBinaryUInt slices**. It avoids
    creating copies of the BigBinaryUInt objects by using the indices to access
    the words directly. This is useful for performance in cases where the
    BigBinaryUInt objects are large and we only need to add a part of them.
    """
    var n_words_x_slice = bounds_x[1] - bounds_x[0]
    var n_words_y_slice = bounds_y[1] - bounds_y[0]

    var words = List[UInt32](
        unsafe_uninit_length=max(n_words_x_slice, n_words_y_slice)
    )

    @parameter
    fn vector_add[simd_width: Int](i: Int):
        words.data.store[width=simd_width](
            i,
            x.words.data.load[width=simd_width](i + bounds_x[0])
            + y.words.data.load[width=simd_width](i + bounds_y[0]),
        )

    vectorize[vector_add, BigBinaryUInt.VECTOR_WIDTH](
        min(n_words_x_slice, n_words_y_slice)
    )

    var longer: Pointer[BigBinaryUInt, __origin_of(x, y)]
    var n_words_longer_slice: Int
    var n_words_shorter_slice: Int
    var longer_start: Int

    if n_words_x_slice >= n_words_y_slice:
        longer = Pointer[BigBinaryUInt, __origin_of(x, y)](to=x)
        n_words_longer_slice = n_words_x_slice
        n_words_shorter_slice = n_words_y_slice
        longer_start = bounds_x[0]
    else:
        longer = Pointer[BigBinaryUInt, __origin_of(x, y)](to=y)
        n_words_longer_slice = n_words_y_slice
        n_words_shorter_slice = n_words_x_slice
        longer_start = bounds_y[0]

    @parameter
    fn vector_copy_rest_from_longer[simd_width: Int](i: Int):
        words.data.store[width=simd_width](
            n_words_shorter_slice + i,
            longer[].words.data.load[width=simd_width](
                longer_start + n_words_shorter_slice + i
            ),
        )

    vectorize[vector_copy_rest_from_longer, BigBinaryUInt.VECTOR_WIDTH](
        n_words_longer_slice - n_words_shorter_slice
    )

    var result = BigBinaryUInt(words=words^)
    normalize_carries(result)
    return result^


# ===----------------------------------------------------------------------=== #
# Multiplication algorithms
# ===----------------------------------------------------------------------=== #


fn multiply_inplace_by_power_of_two(mut x: BigBinaryUInt, n: Int):
    """Multiplies by 2^n in-place if n > 0, otherwise does nothing.

    Args:
        x: The BigBinaryUInt value to multiply by power of two.
        n: The power of two to multiply by (2^n).

    Notes:

    This function multiplies the BigBinaryUInt by power of 2 in-place, which is
    equivalent to left-shifting the number by n bit. It modifies the input
    BigBinaryUInt in-place.
    """
    if n <= 0:
        return

    var number_of_zero_words = n // 30
    var number_of_remaining_bits = n % 30


# ===----------------------------------------------------------------------=== #
# Helper Functions
# ===----------------------------------------------------------------------=== #


fn normalize_carries(mut x: BigBinaryUInt):
    """Normalizes the values of words into valid range by carrying over.
    The initial values of the words should be in the range [0, BASE*2).

    Notes:

    If we adds two BigBinaryUInt numbers word-by-word, we may end up with
    a situation where some words are larger than BASE. This function
    normalizes the carries, ensuring that all words are within the valid range.
    It modifies the input BigBinaryUInt in-place.
    """

    # Yuhao ZHU:
    # By construction, the words of x are in the range [0, BASE*2).
    # Thus, the carry can only be 0 or 1.
    var carry: UInt32 = 0
    for ref word in x.words:
        if carry == 0:
            if word <= BigBinaryUInt.BASE_MAX:
                pass  # carry = 0
            else:
                word -= BigBinaryUInt.BASE
                carry = 1
        else:  # carry == 1
            if word < BigBinaryUInt.BASE_MAX:
                word += 1
                carry = 0
            else:
                word = word + 1 - BigBinaryUInt.BASE
                # carry = 1
    if carry > 0:
        # If there is still a carry, we need to add a new word
        x.words.append(UInt32(1))
    return
