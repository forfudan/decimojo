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

from algorithm import vectorize
import math
from memory import memcpy, memset_zero
import time
import testing

from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.comparison
from decimojo.rounding_mode import RoundingMode

# ===----------------------------------------------------------------------=== #
# List of functions in this module:
#
# negative(x: BigUInt) -> BigUInt
# absolute(x: BigUInt) -> BigUInt
#
# add(x1: BigUInt, x2: BigUInt) -> BigUInt
# add_slices_simd(x: BigUInt, y: BigUInt) -> BigUInt
# add_slices(x: BigUInt, y: BigUInt, start_x: Int, end_x: Int, start_y: Int, end_y: Int) -> BigUInt
# add_inplace(x1: BigUInt, x2: BigUInt)
# add_inplace_by_uint32(x: BigUInt, y: UInt32) -> None
#
# subtract(x1: BigUInt, x2: BigUInt) -> BigUInt
# subtract_inplace(x1: BigUInt, x2: BigUInt) -> None
# subtract_inplace_no_check(x1: BigUInt, x2: BigUInt) -> None
# subtract_inplace_by_uint32(x: BigUInt, y: UInt32) -> None
#
# multiply(x1: BigUInt, x2: BigUInt) -> BigUInt
# multiply_slices_school(x: BigUInt, y: BigUInt, start_x: Int, end_x: Int, start_y: Int, end_y: Int) -> BigUInt
# multiply_slices_karatsuba(x: BigUInt, y: BigUInt, start_x: Int, end_x: Int, start_y: Int, end_y: Int, cutoff_number_of_words: Int) -> BigUInt
# multiply_inplace_by_uint32(x: BigUInt, y: UInt32) -> None
# multiply_by_power_of_ten(x: BigUInt, n: Int) -> BigUInt
# multiply_inplace_by_power_of_billion(mut x: BigUInt, n: Int)
#
# floor_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_school(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_estimate_quotient(x1: BigUInt, x2: BigUInt, j: Int, m: Int) -> UInt64
# floor_divide_inplace_by_single_word(x1: BigUInt, x2: BigUInt) -> None
# floor_divide_inplace_by_double_words(x1: BigUInt, x2: BigUInt) -> None
# floor_divide_inplace_by_2(x: BigUInt) -> Nonet, x2: BigUInt) -> BigUInt
# floor_divide_by_power_of_ten(x: BigUInt, n: Int) -> BigUInt
#
# truncate_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# ceil_divide(x1: BigUInt, x2: BigUInt) -> BigUIntulo(x1: BigUIn# floor_divide_school(x1: BigUInt, x2: BigUInt) -> BigUInt
#
# floor_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# ceil_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_modulo(x1: BigUInt, x2: BigUInt) -> Tuple[BigUInt, BigUInt]
#
# normalize_carries_lt_2_bases(x: BigUInt) -> None
# normalize_carries_lt4_bases(x: BigUInt) -> None
# power_of_10(n: Int) -> BigUInt
# ===----------------------------------------------------------------------=== #

# ===----------------------------------------------------------------------=== #
# Unary operations
# negative, absolute
# ===----------------------------------------------------------------------=== #


fn negative(x: BigUInt) raises -> BigUInt:
    """Returns the negative of a BigUInt number if it is zero.

    Args:
        x: The BigUInt value to compute the negative of.

    Raises:
        Error: If x is not zero, as negative of non-zero unsigned integer is undefined.

    Returns:
        A new BigUInt containing the negative of x.
    """
    if not x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1, "negative(): leading zero words"
        )
        raise Error(
            "biguint.arithmetics.negative(): Negative of non-zero unsigned"
            " integer is undefined"
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


# ===----------------------------------------------------------------------=== #
# Addition algorithms
# add, add_inplace, add_inplace_by_uint32
# ===----------------------------------------------------------------------=== #


fn add(x: BigUInt, y: BigUInt) -> BigUInt:
    """Returns the sum of two unsigned integers.

    Args:
        x: The first unsigned integer operand.
        y: The second unsigned integer operand.

    Returns:
        The sum of the two unsigned integers.

    Notes:

    This function will consider the special cases first, and then call
    `add_slices_simd()` to handle the addition of the two BigUInt numbers.
    """
    debug_assert[assert_mode="none"](
        len(x.words) != 0, "BigUInt is uninitialized!"
    )
    debug_assert[assert_mode="none"](
        len(y.words) != 0, "BigUInt is uninitialized!"
    )

    # Short circuit cases
    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1, "add(): leading zero words"
        )
        return y
    if y.is_zero():
        debug_assert[assert_mode="none"](
            len(y.words) == 1, "add(): leading zero words"
        )
        return x

    if len(x.words) == 1:
        if len(y.words) == 1:
            # If both numbers are single-word, we can handle them with UInt32
            return BigUInt.from_uint32(x.words[0] + y.words[0])
        else:  # If x is single-word, we can handle it with UInt32
            var result = y
            add_inplace_by_uint32(result, x.words[0])
            return result^

    if len(y.words) == 1:
        # If y is single-word, we can handle it with UInt32
        var result = x
        add_inplace_by_uint32(result, y.words[0])
        return result^

    # If both numbers are double-word, we can handle them with UInt64
    if len(x.words) <= 2 and len(y.words) <= 2:
        return BigUInt.from_unsigned_integral_scalar(
            x.to_uint64_with_first_2_words() + y.to_uint64_with_first_2_words()
        )

    # Normal cases
    # Yuhao ZHU:
    # Use SIMD operations for addition if both numbers are large enough.
    # This will first add the words in parallel, and then handle the carries.
    # Although you use an extra loop to normalize the carries, this is still
    # faster than the school method for large numbers, as the normalized carries
    # can be simplified to addition and subtraction instead of floor division
    # and modulo operations.
    # This speeds up the addition by 2x-4x for large numbers.
    return add_slices_simd(x, y, (0, len(x.words)), (0, len(y.words)))


fn add_slices(
    x: BigUInt, y: BigUInt, bounds_x: Tuple[Int, Int], bounds_y: Tuple[Int, Int]
) -> BigUInt:
    """Adds two BigUInt slices using the school method.

    Args:
        x: The first BigUInt operand (first summand).
        y: The second BigUInt operand (second summand).
        bounds_x: A tuple containing the start and end indices of the slice in x.
        bounds_y: A tuple containing the start and end indices of the slice in y.

    Returns:
        A new BigUInt containing the sum of the two slices.

    Notes:

    This function will consider the special cases first, and then call
    `add_slices_simd()` to handle the addition of the two BigUInt slices.
    """

    n_words_x_slice = bounds_x[1] - bounds_x[0]
    n_words_y_slice = bounds_y[1] - bounds_y[0]

    # Short circuit cases
    if n_words_x_slice == 1:
        if x.words[bounds_x[0]] == 0:
            # x slice is zero, return y slice
            return BigUInt.from_slice(y, bounds_y)
        elif n_words_y_slice == 1:
            # If both numbers are single-word, we can handle them with UInt32
            return BigUInt.from_uint32(
                x.words[bounds_x[0]] + y.words[bounds_y[0]]
            )
        else:
            # If y slice is longer
            var result = BigUInt.from_slice(y, bounds_y)
            add_inplace_by_uint32(result, x.words[bounds_x[0]])
            return result^
    if n_words_y_slice == 1:
        if y.words[bounds_y[0]] == 0:
            return BigUInt.from_slice(x, bounds_x)
        else:
            # If x slice is longer
            var result = BigUInt.from_slice(x, bounds_x)
            add_inplace_by_uint32(result, y.words[bounds_y[0]])
            return result^

    # Normal cases
    # Use SIMD operations for addition if both numbers are large enough.
    return add_slices_simd(x, y, bounds_x, bounds_y)


fn add_slices_simd(
    x: BigUInt, y: BigUInt, bounds_x: Tuple[Int, Int], bounds_y: Tuple[Int, Int]
) -> BigUInt:
    """Adds two BigUInt slices using SIMD operations.

    Args:
        x: The first BigUInt operand (first summand).
        y: The second BigUInt operand (second summand).
        bounds_x: A tuple containing the start and end indices of the slice in x.
        bounds_y: A tuple containing the start and end indices of the slice in y.

    Returns:
        A new BigUInt containing the sum of the two numbers.

    Notes:

    **Special cases are not handled here**. Please handle them in the caller.

    This function uses **SIMD operations** to add the words of the two BigUInt
    slices in parallel. It is optimized for performance and can handle
    large numbers efficiently.

    After the parallel addition, it normalizes the carries to ensure that
    the result is a valid BigUInt number.

    Although you use an extra loop to normalize the carries, this is still
    faster than the school method for large numbers, as the normalized carries
    can be simplified to addition and subtraction instead of floor division
    and modulo operations.

    This function conducts addtion of the two **BigUInt slices**. It avoids
    creating copies of the BigUInt objects by using the indices to access
    the words directly. This is useful for performance in cases where the
    BigUInt objects are large and we only need to add a part of them.
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

    vectorize[vector_add, BigUInt.VECTOR_WIDTH](
        min(n_words_x_slice, n_words_y_slice)
    )

    var longer: Pointer[BigUInt, __origin_of(x, y)]
    var n_words_longer_slice: Int
    var n_words_shorter_slice: Int
    var longer_start: Int

    if n_words_x_slice >= n_words_y_slice:
        longer = Pointer[BigUInt, __origin_of(x, y)](to=x)
        n_words_longer_slice = n_words_x_slice
        n_words_shorter_slice = n_words_y_slice
        longer_start = bounds_x[0]
    else:
        longer = Pointer[BigUInt, __origin_of(x, y)](to=y)
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

    vectorize[vector_copy_rest_from_longer, BigUInt.VECTOR_WIDTH](
        n_words_longer_slice - n_words_shorter_slice
    )

    var result = BigUInt(words=words^)
    normalize_carries_lt_2_bases(result)
    return result^


fn add_inplace(mut x: BigUInt, y: BigUInt) -> None:
    """Increments a BigUInt number by another BigUInt number in place.

    Args:
        x: The first unsigned integer operand.
        y: The second unsigned integer operand.

    Notes:

    This function uses SIMD operations to add the words of the two BigUInt.
    """

    # Short circuit cases
    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1, "add_inplace(): leading zero words"
        )
        x.words = y.words  # Copy the words from y
        return
    if y.is_zero():
        debug_assert[assert_mode="none"](
            len(y.words) == 1, "add_inplace(): leading zero words"
        )
        return

    if len(y.words) == 1:
        add_inplace_by_uint32(x, y.words[0])
        return

    # Normal cases
    if len(x.words) < len(y.words):
        x.words.resize(new_size=len(y.words), value=UInt32(0))

    @parameter
    fn vector_add[simd_width: Int](i: Int):
        x.words.data.store[width=simd_width](
            i,
            x.words.data.load[width=simd_width](i)
            + y.words.data.load[width=simd_width](i),
        )

    vectorize[vector_add, BigUInt.VECTOR_WIDTH](len(y.words))

    # Normalize carries after addition
    normalize_carries_lt_2_bases(x)

    return


fn add_inplace_by_slice(
    mut x: BigUInt, y: BigUInt, bounds_y: Tuple[Int, Int]
) -> None:
    """Increments a BigUInt number in-place by another BigUInt slice.

    Args:
        x: The first unsigned integer operand.
        y: The second unsigned integer operand.
        bounds_y: A tuple containing the start and end indices of the slice in y.
    """

    # Short circuit cases
    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1, "add_inplace_by_slice(): leading zero words"
        )
        x.words = BigUInt(
            y.words[bounds_y[0] : bounds_y[1]]
        ).words  # Copy the words from y
        return
    if y.is_zero(bounds=bounds_y):
        return

    var n_words_y_slice = bounds_y[1] - bounds_y[0]

    if n_words_y_slice == 1:
        add_inplace_by_uint32(x, y.words[bounds_y[0]])
        return

    # Normal cases
    if len(x.words) < n_words_y_slice:
        x.words.resize(new_size=n_words_y_slice, value=UInt32(0))

    @parameter
    fn vector_add[simd_width: Int](i: Int):
        x.words.data.store[width=simd_width](
            i,
            x.words.data.load[width=simd_width](i)
            + y.words.data.load[width=simd_width](i + bounds_y[0]),
        )

    vectorize[vector_add, BigUInt.VECTOR_WIDTH](n_words_y_slice)

    # Normalize carries after addition
    normalize_carries_lt_2_bases(x)

    return


fn add_inplace_by_uint32(mut x: BigUInt, y: UInt32) -> None:
    """Increments a BigUInt number by a UInt32 value."""
    var carry: UInt32 = y
    for i in range(len(x.words)):
        x.words[i] += carry
        if x.words[i] <= BigUInt.BASE_MAX:
            return  # No carry, we can stop early
        else:
            carry = 1  # Cannot be more than 1
            x.words[i] -= BigUInt.BASE
    else:
        x.words.append(UInt32(1))

    return


# ===----------------------------------------------------------------------=== #
# Subtraction algorithms
# ===----------------------------------------------------------------------=== #


fn subtract(x: BigUInt, y: BigUInt) raises -> BigUInt:
    """Returns the difference of two unsigned integers.

    Args:
        x: The first unsigned integer (minuend).
        y: The second unsigned integer (subtrahend).

    Raises:
        Error: If y is greater than x, resulting in an underflow.

    Returns:
        The result of subtracting y from x.
    """
    # I will use the SIMD approach for subtraction
    # This speeds up the subtraction by 1.25x for large numbers.
    return subtract_simd(x, y)

    # Yuhao ZHU:
    # Below is a school method for subtraction.
    # You go from the least significant word to the most significant word.
    #
    # return subtract_school(x, y)


fn subtract_school(x: BigUInt, y: BigUInt) raises -> BigUInt:
    """Returns the difference of two unsigned integers using the school method.

    Args:
        x: The first unsigned integer (minuend).
        y: The second unsigned integer (subtrahend).

    Raises:
        Error: If y is greater than x, resulting in an underflow.

    Returns:
        The result of subtracting y from x.
    """
    debug_assert[assert_mode="none"](
        len(x.words) != 0, "BigUInt is uninitialized!"
    )
    debug_assert[assert_mode="none"](
        len(y.words) != 0, "BigUInt is uninitialized!"
    )

    # If the subtrahend is zero, return the minuend
    if y.is_zero():
        debug_assert[assert_mode="none"](
            len(y.words) == 1, "subtract_school(): leading zero words"
        )
        return x

    # We need to determine which number has the larger magnitude
    var comparison_result = x.compare(y)
    if comparison_result == 0:
        # |x| = |y|
        return BigUInt()  # Return zero
    if comparison_result < 0:
        raise Error("biguint.arithmetics.subtract(): Underflow due to x < y")

    # Now it is safe to subtract the smaller number from the larger one
    # The result will have no more words than the first number
    var words = List[UInt32](capacity=len(x.words))
    var borrow: UInt32 = 0  # Can either be 0 or 1

    for i in range(len(y.words)):
        if x.words[i] < borrow + y.words[i]:
            words.append(x.words[i] + BigUInt.BASE - borrow - y.words[i])
            borrow = 1  # Set borrow for the next word
        else:
            words.append(x.words[i] - borrow - y.words[i])
            borrow = 0  # No borrow for the next word

    # If x has more words than y, we need to handle the remaining words

    if borrow == 0:
        # If there is no borrow, we can just copy the remaining words
        for i in range(len(y.words), len(x.words)):
            words.append(x.words[i])

    else:
        var no_borrow_idx: Int = 0
        # At this stage, borrow can only be 0 or 1
        for i in range(len(y.words), len(x.words)):
            if x.words[i] >= borrow:
                words.append(x.words[i] - borrow)
                no_borrow_idx = i + 1
                break  # No more borrow, we can stop early
            else:  # x.words[i] == 0, borrow == 1
                words.append(BigUInt.BASE - borrow)

        for i in range(no_borrow_idx, len(x.words)):
            words.append(x.words[i])  # Copy the remaining words

    var result = BigUInt(words=words^)
    result.remove_leading_empty_words()
    return result^


fn subtract_simd(x: BigUInt, y: BigUInt) raises -> BigUInt:
    """Returns the difference of two unsigned integers using SIMD operations.

    Args:
        x: The first unsigned integer (minuend).
        y: The second unsigned integer (subtrahend).

    Raises:
        Error: If y is greater than x, resulting in an underflow.

    Returns:
        The result of subtracting y from x.

    Notes:

    I will make use of SIMD operations to subtract the words in parallel.
    This will first subtract the words in parallel and then handle the borrows.
    Note that there will be potential overflow in the subtraction,
    but I will take advantage of that.
    """
    debug_assert[assert_mode="none"](
        len(x.words) != 0, "BigUInt is uninitialized!"
    )
    debug_assert[assert_mode="none"](
        len(y.words) != 0, "BigUInt is uninitialized!"
    )

    # If the subtrahend is zero, return the minuend
    # Yuhao ZHU:
    # This step is important because y can be of zero words and is longer than x.
    # This will makes the subtraction beyond the boundary of the result number,
    # whose length is equal to the length of x.
    # Note that our subtraction is via SIMD, so it is directly worked on unsafe
    # pointers.
    if y.is_zero():
        debug_assert[assert_mode="none"](
            len(y.words) == 1, "subtract_simd(): leading zero words"
        )
        return x

    # We need to determine which number has the larger magnitude
    var comparison_result = x.compare(y)
    if comparison_result == 0:
        # |x| = |y|
        return BigUInt()  # Return zero
    if comparison_result < 0:
        raise Error("biguint.arithmetics.subtract(): Underflow due to x < y")

    # Now it is safe to subtract the smaller number from the larger one
    # The result will have no more words than the first number
    var words = List[UInt32](unsafe_uninit_length=len(x.words))

    # Yuhao ZHU:
    # We will make use of SIMD operations to subtract the words in parallel.
    # This will first subtract the words in parallel and then handle the borrows.
    # Note that there will be potential overflow in the subtraction,
    # but we will take advantage of that.
    @parameter
    fn vector_subtract[simd_width: Int](i: Int):
        words.data.store[width=simd_width](
            i,
            x.words.data.load[width=simd_width](i)
            - y.words.data.load[width=simd_width](i),
        )

    vectorize[vector_subtract, BigUInt.VECTOR_WIDTH](len(y.words))

    @parameter
    fn vector_copy_rest[simd_width: Int](i: Int):
        words.data.store[width=simd_width](
            len(y.words) + i,
            x.words.data.load[width=simd_width](len(y.words) + i),
        )

    vectorize[vector_copy_rest, BigUInt.VECTOR_WIDTH](
        len(x.words) - len(y.words)
    )

    var result = BigUInt(words=words^)
    normalize_borrows(result)
    result.remove_leading_empty_words()

    return result^


fn subtract_inplace(mut x: BigUInt, y: BigUInt) raises -> None:
    """Subtracts y from x in place."""

    # If the subtrahend is zero, return the minuend
    if y.is_zero():
        debug_assert[assert_mode="none"](
            len(y.words) == 1, "subtract_inplace(): leading zero words"
        )
        return

    # We need to determine which number has the larger magnitude
    var comparison_result = x.compare(y)
    if comparison_result == 0:
        x.words.resize(unsafe_uninit_length=1)
        x.words[0] = UInt32(0)  # Result is zero
    elif comparison_result < 0:
        raise Error(
            "biguint.arithmetics.subtract_inplace(): Underflow due to x < y"
        )

    # Now it is safe to subtract the smaller number from the larger one

    # If y is a single-word number, we can handle it with UInt32
    if len(y.words) == 1:
        subtract_inplace_by_uint32(x, y.words[0])
        return

    # Note that len(x.words) >= len(y.words) here
    # Use SIMD operations to subtract the words in parallel.
    @parameter
    fn vector_subtract[simd_width: Int](i: Int):
        x.words.data.store[width=simd_width](
            i,
            x.words.data.load[width=simd_width](i)
            - y.words.data.load[width=simd_width](i),
        )

    vectorize[vector_subtract, BigUInt.VECTOR_WIDTH](len(y.words))

    # Normalize borrows after subtraction
    normalize_borrows(x)
    x.remove_leading_empty_words()

    return


fn subtract_inplace_no_check(mut x: BigUInt, y: BigUInt) -> None:
    """Subtracts y from x in-place without checking for underflow.

    Notes:

    This function assumes that x >= y, and it does not check for underflow.
    It is the caller's responsibility to ensure that x is greater than or
    equal to y before calling this function.
    """

    # If the subtrahend is zero, return the minuend
    if y.is_zero():
        debug_assert[assert_mode="none"](
            len(y.words) == 1, "subtract_inplace_no_check(): leading zero words"
        )
        return

    # Underflow checks are skipped here, so we assume x >= y
    # Note that len(x.words) >= len(y.words) under this assumption

    @parameter
    fn vector_subtract[simd_width: Int](i: Int):
        x.words.data.store[width=simd_width](
            i,
            x.words.data.load[width=simd_width](i)
            - y.words.data.load[width=simd_width](i),
        )

    vectorize[vector_subtract, BigUInt.VECTOR_WIDTH](len(y.words))

    # Normalize borrows after subtraction
    normalize_borrows(x)
    x.remove_leading_empty_words()

    return


fn subtract_inplace_by_uint32(mut x: BigUInt, y: UInt32) -> None:
    """Subtracts a UInt32 value from a BigUInt number in-place.

    Args:
        x: The BigUInt number to subtract from.
        y: The UInt32 value to subtract.

    Notes:
        This function assumes that x >= y, and it does not check for underflow.
        It is the caller's responsibility to ensure that x is greater than or
        equal to y before calling this function.
    """

    debug_assert[assert_mode="none"](
        (len(x.words) > 1) or (x.words[0] >= y),
        "subtract_inplace_by_uint32(): Underflow due to x < y.",
    )

    x.words[0] -= y

    if len(x.words) == 1:
        return
    else:  # len(x.words) > 1
        # We need to handle the borrow for the rest of the words
        var borrow: UInt32 = 0
        for ref word in x.words:
            if borrow == 0:
                if word <= BigUInt.BASE_MAX:  # 0 <= word <= 999_999_999
                    break  # No borrow, we can stop early
                else:  # word >= 3294967297, overflowed value
                    word += BigUInt.BASE
                    borrow = 1
            else:  # borrow == 1
                if (word >= 1) and (
                    word <= BigUInt.BASE_MAX
                ):  # 1 <= word <= 999_999_999
                    word -= 1
                    borrow = 0
                else:  # word >= 3294967297 or word == 0, overflowed value
                    word = (word + BigUInt.BASE) - 1
                    # borrow = 1
        return


# ===----------------------------------------------------------------------=== #
# Multiplication algorithms
# ===----------------------------------------------------------------------=== #


fn multiply(x: BigUInt, y: BigUInt) -> BigUInt:
    """Returns the product of two BigUInt numbers.

    Args:
        x: The first BigUInt operand (multiplicand).
        y: The second BigUInt operand (multiplier).

    Returns:
        The product of the two BigUInt numbers.

    Notes:
        This function will adopts the Karatsuba multiplication algorithm
        for larger numbers, and the school multiplication algorithm for smaller
        numbers. The cutoff number of words is used to determine which algorithm
        to use. If the number of words in either operand is less than or equal
        to the cutoff number, the school multiplication algorithm is used.
    """

    # TODO: Make this a global constant
    alias CUTOFF_KARATSUBA: Int = 64
    """The cutoff number of words for using Karatsuba multiplication."""

    debug_assert[assert_mode="none"](
        len(x.words) != 0, "BigUInt is uninitialized!"
    )
    debug_assert[assert_mode="none"](
        len(y.words) != 0, "BigUInt is uninitialized!"
    )

    # SPECIAL CASES
    # If x or y is a single-word number
    # We can use `multiply_inplace_by_uint32` because this is only one loop
    # No need to split the long number into two parts
    if len(x.words) == 1:
        var x_word = x.words[0]
        if x_word == 0:
            return BigUInt(UInt32(0))
        elif x_word == 1:
            return y
        else:
            var result = y
            multiply_inplace_by_uint32(result, x_word)
            return result^

    if len(y.words) == 1:
        var y_word = y.words[0]
        if y_word == 0:
            return BigUInt(UInt32(0))
        if y_word == 1:
            return x
        else:
            var result = x
            multiply_inplace_by_uint32(result, y_word)
            return result^

    # CASE 1
    # The allocation cost is too high for small numbers to use Karatsuba
    # Use school multiplication for small numbers
    var max_words = max(len(x.words), len(y.words))
    if max_words <= CUTOFF_KARATSUBA:
        # return multiply_slices_school (x, y)
        return multiply_slices_school(
            x, y, (0, len(x.words)), (0, len(y.words))
        )
        # multiply_slices_school can also takes in x, y, and indices

    # CASE 2
    # Use Karatsuba multiplication for larger numbers
    else:
        return multiply_slices_karatsuba(
            x, y, (0, len(x.words)), (0, len(y.words)), CUTOFF_KARATSUBA
        )


fn multiply_slices(
    x: BigUInt,
    y: BigUInt,
    bounds_x: Tuple[Int, Int],
    bounds_y: Tuple[Int, Int],
) -> BigUInt:
    """Returns the product of two BigUInt numbers.

    Args:
        x: The first BigUInt operand (multiplicand).
        y: The second BigUInt operand (multiplier).
        bounds_x: A tuple containing the start and end indices of the slice in x.
        bounds_y: A tuple containing the start and end indices of the slice in y.

    Returns:
        The product of the two BigUInt numbers.

    Notes:
        This function will adopts the Karatsuba multiplication algorithm
        for larger numbers, and the school multiplication algorithm for smaller
        numbers. The cutoff number of words is used to determine which algorithm
        to use. If the number of words in either operand is less than or equal
        to the cutoff number, the school multiplication algorithm is used.
    """

    # TODO: Make this a global constant
    alias CUTOFF_KARATSUBA: Int = 64
    """The cutoff number of words for using Karatsuba multiplication."""

    n_words_x_slice = bounds_x[1] - bounds_x[0]
    n_words_y_slice = bounds_y[1] - bounds_y[0]

    # CASE 1
    # The allocation cost is too high for small numbers to use Karatsuba
    # Use school multiplication for small numbers
    var max_words = max(n_words_x_slice, n_words_y_slice)
    if max_words <= CUTOFF_KARATSUBA:
        # return multiply_slices_school (x, y)
        return multiply_slices_school(x, y, bounds_x, bounds_y)
        # multiply_slices_school can also takes in x, y, and indices

    # CASE 2
    # Use Karatsuba multiplication for larger numbers
    else:
        return multiply_slices_karatsuba(
            x, y, bounds_x, bounds_y, CUTOFF_KARATSUBA
        )


fn multiply_slices_school(
    read x: BigUInt,
    read y: BigUInt,
    bounds_x: Tuple[Int, Int],
    bounds_y: Tuple[Int, Int],
) -> BigUInt:
    """Multiplies two BigUInt slices using the school method.

    Args:
        x: The first BigUInt operand (multiplicand).
        y: The second BigUInt operand (multiplier).
        bounds_x: A tuple containing the start and end indices of the slice in x.
        bounds_y: A tuple containing the start and end indices of the slice in y.
    """

    n_words_x_slice = bounds_x[1] - bounds_x[0]
    n_words_y_slice = bounds_y[1] - bounds_y[0]

    # CASE: One of the operands is zero or one
    if n_words_x_slice == 1:
        var x_word = x.words[bounds_x[0]]
        if x_word == 0:
            return BigUInt(UInt32(0))
        elif x_word == 1:
            return BigUInt.from_slice(y, (bounds_y[0], bounds_y[1]))
        else:
            var result = BigUInt.from_slice(y, (bounds_y[0], bounds_y[1]))
            multiply_inplace_by_uint32(result, x_word)
            return result^
    if n_words_y_slice == 1:
        var y_word = y.words[bounds_y[0]]
        if y_word == 0:
            return BigUInt(UInt32(0))
        elif y_word == 1:
            return BigUInt.from_slice(x, (bounds_x[0], bounds_x[1]))
        else:
            var result = BigUInt.from_slice(x, (bounds_x[0], bounds_x[1]))
            multiply_inplace_by_uint32(result, y_word)
            return result^

    # The max number of words in the result is the sum of the words in the operands
    var max_result_len = n_words_x_slice + n_words_y_slice
    var words = List[UInt32](capacity=max_result_len)

    # Initialize result words with zeros
    for _ in range(max_result_len):
        words.append(0)

    # Perform the multiplication word by word (from least significant to most significant)
    # x = x[start_x] + x[start_x + 1] * 10^9
    # y = y[start_y] + y[start_y + 1] * 10^9
    # x * y = x[start_x] * y[start_y]
    #       + (x[start_x] * y[start_y + 1]
    #       + x[start_x + 1] * y[start_y]) * 10^9
    #       + x[start_x + 1] * y[start_y + 1] * 10^18
    var carry: UInt64
    for i in range(n_words_x_slice):
        # Skip if the word is zero
        if x.words[bounds_x[0] + i] == 0:
            continue

        carry = UInt64(0)

        for j in range(n_words_y_slice):
            # Calculate the product of the current words
            # plus the carry from the previous multiplication
            # plus the value already at this position in the result
            var product = (
                UInt64(x.words[bounds_x[0] + i])
                * UInt64(y.words[bounds_y[0] + j])
                + carry
                + UInt64(words[i + j])
            )

            # The lower 9 digits (base 10^9) go into the current word
            # The upper digits become the carry for the next position
            words[i + j] = UInt32(product % UInt64(BigUInt.BASE))
            carry = product // UInt64(BigUInt.BASE)

        # If there is a carry left, add it to the next position
        if carry > 0:
            words[i + n_words_y_slice] += UInt32(carry)

    var result = BigUInt(words=words^)
    result.remove_leading_empty_words()
    return result^


fn multiply_slices_karatsuba(
    read x: BigUInt,
    read y: BigUInt,
    bounds_x: Tuple[Int, Int],
    bounds_y: Tuple[Int, Int],
    cutoff_number_of_words: Int,
) -> BigUInt:
    """Multiplies two BigUInt numbers using the Karatsuba algorithm.

    Args:
        x: The first BigUInt operand (multiplicand).
        y: The second BigUInt operand (multiplier).
        bounds_x: A tuple containing the start and end indices of the slice in x.
        bounds_y: A tuple containing the start and end indices of the slice in y.
        cutoff_number_of_words: The cutoff number of words for using Karatsuba
            multiplication. If the number of words in either operand is less
            than or equal to this value, the school method is used instead.

    Returns:
        The product of the two BigUInt numbers.

    Notes:

    This function uses a technique to avoid making copies of x and y.
    We just need to consider the slices of x and y by using the indices.
    """

    if x.is_zero(bounds=bounds_x) or y.is_zero(bounds=bounds_y):
        return BigUInt(UInt32(0))

    # Number of words in the slice 1: end_x - start_x
    # Number of words in the slice 2: end_y - start_y
    var n_words_x_slice = bounds_x[1] - bounds_x[0]
    var n_words_y_slice = bounds_y[1] - bounds_y[0]

    # CASE 1:
    # If one number is only one-word long
    # we can use school multiplication because this is only one loop
    # No need to split the long number into two parts
    if n_words_x_slice == 1 or n_words_y_slice == 1:
        return multiply_slices_school(x, y, bounds_x, bounds_y)

    # CASE 2:
    # The allocation cost is too high for small numbers to use Karatsuba
    # Use school multiplication for small numbers
    var n_words_max = max(n_words_x_slice, n_words_y_slice)
    if n_words_max <= cutoff_number_of_words:
        # return multiply_slices_school (x, y)
        return multiply_slices_school(x, y, bounds_x, bounds_y)
        # multiply_slices_school can also takes in x, y, and indices

    # Otherwise, use Karatsuba

    # A number is split into two as-equal-length-as-possible parts:
    # x = x1 * 10^(9*m) + x0
    # The low part takes the first m words, the high part takes the rest.
    var m = n_words_max // 2
    var z0: BigUInt
    var z1: BigUInt
    var z2: BigUInt

    if n_words_x_slice <= m:
        # print("Karatsuba multiplication with x slice shorter than m words")
        # x slice is shorter than m words
        # Two times of multiplication
        # x0 = x_slice
        # x1 = 0
        # y0 = y_slice.words[:m]
        # y1 = y_slice.words[m:]
        z0 = multiply_slices_karatsuba(
            x,
            y,
            bounds_x,
            (bounds_y[0], bounds_y[0] + m),
            cutoff_number_of_words,
        )
        z1 = multiply_slices_karatsuba(
            x,
            y,
            bounds_x,
            (bounds_y[0] + m, bounds_y[1]),
            cutoff_number_of_words,
        )
        # z2 = 0

        z1.multiply_inplace_by_power_of_billion(m)
        z1 += z0
        return z1^

    elif n_words_y_slice <= m:
        # print("Karatsuba multiplication with y slice shorter than m words")
        # y slice is shorter than m words
        # Two times of multiplication
        # x0 = x_slice.words[0:m]
        # x1 = x_slice.words[m:]
        # y0 = y_slice
        # y1 = 0
        z0 = multiply_slices_karatsuba(
            x,
            y,
            (bounds_x[0], bounds_x[0] + m),
            bounds_y,
            cutoff_number_of_words,
        )
        z1 = multiply_slices_karatsuba(
            x,
            y,
            (bounds_x[0] + m, bounds_x[1]),
            bounds_y,
            cutoff_number_of_words,
        )
        # z2 = 0
        z1.multiply_inplace_by_power_of_billion(m)
        z1 += z0
        return z1^

    else:
        # print("normal Karatsuba multiplication")
        # Normal Karatsuba multiplication
        # Three times of multiplication
        # x0 = x_slice.words[0:m]
        # x1 = x_slice.words[m:]
        # y0 = y_slice.words[0:m]
        # y1 = y_slice.words[m:]

        # z0 = multiply_slices_karatsuba(x0, y0)
        z0 = multiply_slices_karatsuba(
            x,
            y,
            (bounds_x[0], bounds_x[0] + m),
            (bounds_y[0], bounds_y[0] + m),
            cutoff_number_of_words,
        )
        # z2 = multiply_slices_karatsuba(x1, y1)
        z2 = multiply_slices_karatsuba(
            x,
            y,
            (bounds_x[0] + m, bounds_x[1]),
            (bounds_y[0] + m, bounds_y[1]),
            cutoff_number_of_words,
        )
        # z3 = multiply_slices_karatsuba(x0 + x1, y0 + y1)
        # z1 = z3 - z2 -z0
        var x0_plus_x1 = add_slices(
            x,
            x,
            (bounds_x[0], bounds_x[0] + m),
            (bounds_x[0] + m, bounds_x[1]),
        )
        var y0_plus_y1 = add_slices(
            y,
            y,
            (bounds_y[0], bounds_y[0] + m),
            (bounds_y[0] + m, bounds_y[1]),
        )
        z1 = multiply_slices_karatsuba(
            x0_plus_x1,
            y0_plus_y1,
            (0, len(x0_plus_x1.words)),
            (0, len(y0_plus_y1.words)),
            cutoff_number_of_words,
        )

        # z1 >= z2 + z0 by construction
        subtract_inplace_no_check(z1, z2)
        subtract_inplace_no_check(z1, z0)

        # z2*9^(m * 2) + z1*9^m + z0
        z2.multiply_inplace_by_power_of_billion(2 * m)
        z1.multiply_inplace_by_power_of_billion(m)
        z2 += z1
        z2 += z0

        return z2^


fn multiply_inplace_by_uint32(mut x: BigUInt, y: UInt32):
    """Multiplies in-place a BigUInt by a UInt32 value.

    Args:
        x: The BigUInt value to multiply.
        y: The single word to multiply by.
    """
    # Short circuit cases when y is between 0 and 4
    # See `multiply_inplace_by_uint32_le_4()` for details
    # The performance is the best when `y <= 2`
    if y <= 2:
        multiply_inplace_by_uint32_le_4(x, y)
        return

    var y_as_uint64 = UInt64(y)
    var product: UInt64
    var carry: UInt64 = 0

    for i in range(len(x.words)):
        product = UInt64(x.words[i]) * y_as_uint64 + carry
        x.words[i] = UInt32(product % UInt64(BigUInt.BASE))
        carry = product // UInt64(BigUInt.BASE)

    if carry > 0:
        x.words.append(UInt32(carry))


@always_inline
fn multiply_inplace_by_uint32_le_4(mut x: BigUInt, y: UInt32):
    """Multiplies in-place a BigUInt by a UInt32 value which is between 0 and 4.

    Args:
        x: The BigUInt value to multiply.
        y: The single word to multiply by. It must be between 0 and 4.

    Notes:

    This function will be used in the `multiply_inplace_by_uint32()` function.
    It is optimized for the case where y is between 0 and 4.

    When a valid word times 2, 3, or 4, the result is no larger than 4*10^9,
    which is less than 2^32-1. This means that we do not need to use UInt64 to
    store the product but use UInt32 directly. We can first use SIMD to do
    word-by-word multiplication, and then handle the carries.

    This function works the best when y is 0, 1, or 2. For y = 3 or 4, the
    normalization of carries is more expensive and may not compensate for the
    extra loop overhead.
    """

    # y is 0, x becomes 1
    if y == 0:
        x.words = List[UInt32](0)
        return

    # y is 1, x stays the same
    if y == 1:
        return

    # y is 2, we can just shift the digits of each word to the left by 1
    @parameter
    fn vector_multiply_by_2[simd_width: Int](i: Int):
        """Shifts the digits of each word to the left by 1."""
        x.words.data.store[width=simd_width](
            i, x.words.data.load[width=simd_width](i) << 1
        )

    if y == 2:
        vectorize[vector_multiply_by_2, BigUInt.VECTOR_WIDTH](len(x.words))
        normalize_carries_lt_2_bases(x)
        return

    # y is 3, we can just multiply the digits of each word by 3
    @parameter
    fn vector_multiply_by_3[simd_width: Int](i: Int):
        """Multiplies the digits of each word by 3."""
        x.words.data.store[width=simd_width](
            i, x.words.data.load[width=simd_width](i) * 3
        )

    if y == 3:
        vectorize[vector_multiply_by_3, BigUInt.VECTOR_WIDTH](len(x.words))
        normalize_carries_lt_4_bases(x)
        return

    # y is 4, we can just shift the digits of each word to the left by 2
    @parameter
    fn vector_multiply_by_4[simd_width: Int](i: Int):
        """Shifts the digits of each word to the left by 2."""
        x.words.data.store[width=simd_width](
            i, x.words.data.load[width=simd_width](i) << 2
        )

    if y == 4:
        vectorize[vector_multiply_by_4, BigUInt.VECTOR_WIDTH](len(x.words))
        normalize_carries_lt_4_bases(x)
        return


fn multiply_by_power_of_ten(x: BigUInt, n: Int) -> BigUInt:
    """Multiplies a BigUInt by 10^n if n > 0, otherwise doing nothing.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.

    Returns:
        A new BigUInt containing the result of the multiplication.
    """
    if n <= 0:
        return x

    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1, "multiply_by_power_of_ten(): leading zero words"
        )
        return BigUInt(UInt32(0))  # Multiplying zero by anything is still zero

    var number_of_zero_words = n // 9
    var number_of_remaining_digits = n % 9

    var words = List[UInt32](capacity=number_of_zero_words + len(x.words) + 1)
    # Add zero words
    for _ in range(number_of_zero_words):
        words.append(UInt32(0))
    # Add the original words times 10^number_of_remaining_digits
    if number_of_remaining_digits == 0:
        for i in range(len(x.words)):
            words.append(x.words[i])
    else:  # number_of_remaining_digits > 0
        var carry = UInt64(0)
        var multiplier: UInt64
        var product: UInt64

        if number_of_remaining_digits == 1:
            multiplier = UInt64(10)
        elif number_of_remaining_digits == 2:
            multiplier = UInt64(100)
        elif number_of_remaining_digits == 3:
            multiplier = UInt64(1000)
        elif number_of_remaining_digits == 4:
            multiplier = UInt64(10_000)
        elif number_of_remaining_digits == 5:
            multiplier = UInt64(100_000)
        elif number_of_remaining_digits == 6:
            multiplier = UInt64(1_000_000)
        elif number_of_remaining_digits == 7:
            multiplier = UInt64(10_000_000)
        else:  # number_of_remaining_digits == 8
            multiplier = UInt64(100_000_000)

        for i in range(len(x.words)):
            product = UInt64(x.words[i]) * multiplier + carry
            words.append(UInt32(product % UInt64(BigUInt.BASE)))
            carry = product // UInt64(BigUInt.BASE)
        # Add the last carry if it exists
        if carry > 0:
            words.append(UInt32(carry))

    return BigUInt(words=words^)


fn multiply_inplace_by_power_of_ten(mut x: BigUInt, n: Int):
    """Multiplies a BigUInt in-place by 10^n if n > 0, otherwise doing nothing.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.
    """
    if n <= 0:
        return

    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1,
            "multiply_inplace_by_power_of_ten(): leading zero words",
        )
        # If x is zero, we can just return
        # No need to add zeros, it will still be zero
        return

    var number_of_zero_words = n // 9
    var number_of_remaining_digits = n % 9

    # SPECIAL CASE: If n is a multiple of 9
    if number_of_remaining_digits == 0:
        # If n is a multiple of 9, we just need to add zero words
        x.multiply_inplace_by_power_of_billion(number_of_zero_words)
        return

    else:  # number_of_remaining_digits > 0
        # The number of words to add is number_of_zero_words + 1
        # For example, if n = 10, we add two words
        # The most significant word may not be used
        # We need to make sure that it is initialized to zero finally
        x_original_length = len(x.words)
        x.words.resize(
            unsafe_uninit_length=len(x.words) + number_of_zero_words + 1
        )  # New length = original length + number of zero words + 1

        var carry = UInt64(0)
        var multiplier: UInt64
        var product: UInt64

        if number_of_remaining_digits == 1:
            multiplier = UInt64(10)
        elif number_of_remaining_digits == 2:
            multiplier = UInt64(100)
        elif number_of_remaining_digits == 3:
            multiplier = UInt64(1000)
        elif number_of_remaining_digits == 4:
            multiplier = UInt64(10_000)
        elif number_of_remaining_digits == 5:
            multiplier = UInt64(100_000)
        elif number_of_remaining_digits == 6:
            multiplier = UInt64(1_000_000)
        elif number_of_remaining_digits == 7:
            multiplier = UInt64(10_000_000)
        else:  # number_of_remaining_digits == 8
            multiplier = UInt64(100_000_000)

        for i in range(x_original_length):
            product = UInt64(x.words[i]) * multiplier + carry
            x.words[i] = UInt32(product % UInt64(BigUInt.BASE))
            carry = product // UInt64(BigUInt.BASE)

        # Add the last carry no matter it is 0 or not
        x.words[x_original_length] = UInt32(carry)

        # Now we shift the words to the right by number_of_zero_words
        for i in range(len(x.words) - 1, number_of_zero_words - 1, -1):
            x.words[i] = x.words[i - number_of_zero_words]

        # Fill the first number_of_zero_words with zeros
        for i in range(number_of_zero_words):
            x.words[i] = UInt32(0)

        # Remove the most significant zero word
        x.remove_leading_empty_words()
        return


fn multiply_by_power_of_billion(x: BigUInt, n: Int) -> BigUInt:
    """Multiplies a BigUInt by (10^9)^n if n > 0.
    This equals to adding 9n zeros (n words) to the end of the number.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10^9 to multiply by. Should be non-negative.
    """

    if n <= 0:
        return x  # No change needed

    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1,
            "multiply_inplace_by_power_of_billion(): leading zero words",
        )
        # If x is zero, we can just return
        # No need to add zeros, it will still be zero
        return BigUInt()

    var words = List[UInt32](unsafe_uninit_length=len(x.words) + n)
    # Fill the first n words with zeros
    memset_zero(ptr=words.data, count=n)
    # Copy the original words to the end of the new list
    memcpy(dest=words.data + n, src=x.words.data, count=len(x.words))

    return BigUInt(words=words^)


fn multiply_inplace_by_power_of_billion(mut x: BigUInt, n: Int):
    """Multiplies a BigUInt in-place by (10^9)^n if n > 0.
    This equals to adding 9n zeros (n words) to the end of the number.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10^9 to multiply by. Should be non-negative.
    """

    if n <= 0:
        return  # No change needed

    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1,
            "multiply_inplace_by_power_of_billion(): leading zero words",
        )
        # If x is zero, we can just return
        # No need to add zeros, it will still be zero
        return

    # The number of words to add is n
    # For example, if n = 3, we add three words of zeros
    # x1, x2, x3, x4 -> x1, x2, x3, x4, 0, 0, 0
    x.words.resize(unsafe_uninit_length=len(x.words) + n)
    # Move the existing words to the right by n positions
    # x1, x2, x3, x4, _, _, _ -> 0, 0, 0, x1, x2, x3, x4
    for i in range(len(x.words) - 1, n - 1, -1):
        x.words[i] = x.words[i - n]
    # Fill the first n words with zeros
    for i in range(n):
        x.words[i] = UInt32(0)
    return


# ===----------------------------------------------------------------------=== #
# Division Algorithms
# floor_divide
# floor_divide_school
# floor_divide_burnikel_ziegler
# ===----------------------------------------------------------------------=== #


fn floor_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, truncating toward zero.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to truncated division for positive numbers.
    """

    alias CUTOFF_BURNIKEL_ZIEGLER = 64

    debug_assert[assert_mode="none"](
        len(x1.words) != 0, "BigUInt ", x1, " is uninitialized!"
    )
    debug_assert[assert_mode="none"](
        len(x2.words) != 0, "BigUInt ", x2, " is uninitialized!"
    )

    # CASE: x2 is single word
    if len(x2.words) == 1:
        # SUB-CASE: Division by zero
        if x2.words[0] == 0:
            raise Error("biguint.arithmetics.floor_divide(): Division by zero")

        # SUB-CASE: Division by one
        if x2.words[0] == 1:
            return x1

        # SUB-CASE: Division by two
        if x2.words[0] == 2:
            var result = x1
            floor_divide_inplace_by_2(result)
            return result^

        # SUB-CASE: Single word // single word
        if len(x1.words) == 1:
            var result = BigUInt(List[UInt32](x1.words[0] // x2.words[0]))
            return result^

        # SUB-CASE: Divisor is single word and is power of 2
        if (x2.words[0] & (x2.words[0] - 1)) == 0:
            var result = x1
            var remainder = x2.words[0]
            while remainder > 1:
                floor_divide_inplace_by_2(result)
                remainder >>= 1
            return result^

        # SUB-CASE: Divisor is single word (<= 9 digits)
        else:
            var result = x1
            floor_divide_inplace_by_single_word(result, x2)
            return result^

    # CASE: Divisor is double-word (<= 20 digits)
    if len(x2.words) == 2:
        var result = x1
        floor_divide_inplace_by_double_words(result, x2)
        return result^

    # CASE: Dividend is zero
    if x1.is_zero():
        debug_assert[assert_mode="none"](
            len(x1.words) == 1, "floor_divide(): x1 has leading zero words"
        )
        return BigUInt()  # Return zero

    var comparison_result: Int8 = x1.compare(x2)
    # CASE: dividend < divisor
    if comparison_result < 0:
        return BigUInt()  # Return zero
    # CASE: dividend == divisor
    if comparison_result == 0:
        return BigUInt(UInt32(1))

    # CASE: Divisor is 10^n
    # First remove the last words (10^9) and then shift the rest
    if x2.is_power_of_10():
        var result: BigUInt
        if len(x2.words) == 1:
            result = x1
        else:
            var word_shift = len(x2.words) - 1
            # If we need to drop more words than exists, result is zero
            if word_shift >= len(x1.words):
                return BigUInt()
            # Create result with the remaining words
            words = List[UInt32]()
            for i in range(word_shift, len(x1.words)):
                words.append(x1.words[i])
            result = BigUInt(words=words^)

        # Get the last word of the divisor
        var x2_word = x2.words[len(x2.words) - 1]
        var carry = UInt32(0)
        var power_of_carry = BigUInt.BASE // x2_word
        for i in range(len(result.words) - 1, -1, -1):
            var quot = result.words[i] // x2_word
            var rem = result.words[i] % x2_word
            result.words[i] = quot + carry * power_of_carry
            carry = rem

        result.remove_leading_empty_words()
        return result^

    # CASE: Division of small numbers
    # If the number of words in a or b is small enough,
    # we can use the schoolbook division algorithm.
    if (len(x1.words) <= CUTOFF_BURNIKEL_ZIEGLER) and (
        len(x2.words) <= CUTOFF_BURNIKEL_ZIEGLER
    ):
        # I will normalize the divisor to improve quotient estimation
        var ndigits_to_shift: Int  # Number of digits to shift
        # Calculate normalization factor to make leading digit of divisor
        # as large as possible
        ndigits_to_shift = calculate_ndigits_for_normalization(x2.words[-1])

        if ndigits_to_shift == 0:
            # No normalization needed, just use the general division algorithm
            return floor_divide_school(x1, x2)
        else:
            # Normalize the divisor and dividend
            var normalized_x1 = multiply_by_power_of_ten(x1, ndigits_to_shift)
            var normalized_x2 = multiply_by_power_of_ten(x2, ndigits_to_shift)
            return floor_divide_school(normalized_x1, normalized_x2)

    # CASE: division of very, very large numbers
    # Use the Burnikel-Ziegler division algorithm
    # print("Using Burnikel-Ziegler division algorithm for large numbers")
    return floor_divide_burnikel_ziegler(
        x1, x2, cut_off=CUTOFF_BURNIKEL_ZIEGLER
    )


fn floor_divide_school(dividend: BigUInt, divisor: BigUInt) raises -> BigUInt:
    """General schoolbook division algorithm for BigInt numbers.

    Args:
        dividend: The dividend.
        divisor: The divisor.

    Returns:
        The quotient of dividend // divisor.

    Raises:
        Error: If the divisor is zero.
    """

    if divisor.is_zero():
        debug_assert[assert_mode="none"](
            len(divisor.words) == 1,
            "floor_divide_school(): leading zero words",
        )
        raise Error(
            "`biguint.arithmetics.floor_divide_school()`: Division by zero"
        )

    # Initialize result and remainder
    var result = BigUInt(List[UInt32](capacity=len(dividend.words)))
    var remainder = dividend

    # Shift and initialize
    var n_words_diff = len(remainder.words) - len(divisor.words)
    # The quotient will have at most n_words_diff + 1 words
    for _ in range(n_words_diff + 1):
        result.words.append(0)

    # Main division loop
    var index_of_word = n_words_diff  # Start from the most significant word
    var trial_product: BigUInt
    while index_of_word >= 0:
        # OPTIMIZATION: Better quotient estimation
        var quotient = floor_divide_estimate_quotient(
            remainder, divisor, index_of_word
        )

        # Calculate trial product
        trial_product = divisor
        multiply_inplace_by_uint32(trial_product, UInt32(quotient))
        multiply_inplace_by_power_of_billion(trial_product, index_of_word)

        # By construction, no correction is needed
        # Add correction attempts counter to avoid infinite loop
        var correction_attempts = 0
        while (trial_product.compare(remainder) > 0) and (quotient > 0):
            quotient -= 1
            correction_attempts += 1

            trial_product = divisor
            multiply_inplace_by_uint32(trial_product, UInt32(quotient))
            multiply_inplace_by_power_of_billion(trial_product, index_of_word)

            debug_assert[assert_mode="none"](
                correction_attempts <= 3, "Too many correction attempts"
            )

        # Store the quotient word
        result.words[index_of_word] = UInt32(quotient)
        # By construction, trial_product <= remainder
        subtract_inplace_no_check(remainder, trial_product)
        index_of_word -= 1

    result.remove_leading_empty_words()
    return result^


fn floor_divide_estimate_quotient(
    dividend: BigUInt, divisor: BigUInt, index_of_word: Int
) -> UInt64:
    """Estimates the quotient digit using 3-by-2 division.

    This function implements a 3-by-2 quotient estimation algorithm,
    which divides a 3-word dividend portion by a 2-word divisor to get
    an accurate quotient estimate.

    Args:
        dividend: The dividend BigUInt number.
        divisor: The divisor BigUInt number.
        index_of_word: The current position in the division algorithm.

    Returns:
        An estimated quotient digit (0 to 999_999_999).

    Notes:

    The function performs division of a 3-word number by a 2-word number:
    Dividend portion: R = r2 * 10^18 + r1 * 10^9 + r0.
    Divisor: D = d1 * 10^9 + d0.
    Goal: Estimate Q = R // D.
    """

    # Extract three highest words of relevant dividend portion
    var r2 = UInt64(0)
    if index_of_word + len(divisor.words) < len(dividend.words):
        r2 = UInt64(dividend.words[index_of_word + len(divisor.words)])

    var r1 = UInt64(0)
    if index_of_word + len(divisor.words) - 1 < len(dividend.words):
        r1 = UInt64(dividend.words[index_of_word + len(divisor.words) - 1])

    var r0 = UInt64(0)
    if index_of_word + len(divisor.words) - 2 < len(dividend.words):
        r0 = UInt64(dividend.words[index_of_word + len(divisor.words) - 2])

    # Extract two highest words of divisor
    var d1 = UInt64(divisor.words[len(divisor.words) - 1])
    var d0 = UInt64(0)
    if len(divisor.words) >= 2:
        d0 = UInt64(divisor.words[len(divisor.words) - 2])

    # Special case: if divisor is single word, fall back to 2-by-1 division
    if len(divisor.words) == 1:
        if r2 == d1:
            return BigUInt.BASE_MAX
        return min(
            (r2 * UInt64(BigUInt.BASE) + r1) // d1, UInt64(BigUInt.BASE_MAX)
        )

    # Special case: if high word of dividend equals high word of divisor
    # The quotient is likely to be large, so we use a conservative estimate
    if r2 == d1:
        return UInt64(BigUInt.BASE_MAX)

    # 3-by-2 division using 128-bit arithmetic
    # We need to compute: (r2 * 10^18 + r1 * 10^9 + r0) // (d1 * 10^9 + d0)

    # Convert to 128-bit for high precision calculation
    var dividend_high = UInt128(r2) * UInt128(BigUInt.BASE) + UInt128(r1)
    var dividend_low = UInt128(r0)
    var divisor_128 = UInt128(d1) * UInt128(BigUInt.BASE) + UInt128(d0)

    # Handle the case where we need to consider the full 3-word dividend
    # We compute: (dividend_high * 10^9 + dividend_low) // divisor_128
    var full_dividend = dividend_high * UInt128(BigUInt.BASE) + dividend_low

    # Perform the division
    var quotient_128 = full_dividend // divisor_128

    # Convert back to UInt64
    var quotient = UInt64(quotient_128)

    # Ensure we don't exceed the maximum value for a single word
    return min(quotient, UInt64(BigUInt.BASE_MAX))


fn floor_divide_inplace_by_single_word(
    mut x1: BigUInt, x2: BigUInt
) raises -> None:
    """Divides a BigUInt by a single word divisor in-place.

    Args:
        x1: The BigUInt value to divide by the divisor.
        x2: The single word divisor.
    """
    if x2.is_zero():
        debug_assert[assert_mode="none"](
            len(x2.words) == 1,
            "floor_divide_inplace_by_single_word(): leading zero words",
        )
        raise Error(
            "Error in `floor_divide_inplace_by_single_word`: Division by zero"
        )

    # CASE: all other situations
    var x2_value = UInt64(x2.words[0])
    var carry = UInt64(0)
    for i in range(len(x1.words) - 1, -1, -1):
        var dividend = carry * UInt64(BigUInt.BASE) + UInt64(x1.words[i])
        x1.words[i] = UInt32(dividend // x2_value)
        carry = dividend % x2_value
    x1.remove_leading_empty_words()


fn floor_divide_inplace_by_double_words(
    mut x1: BigUInt, x2: BigUInt
) raises -> None:
    """Divides a BigUInt by double-word divisor in-place.

    Args:
        x1: The BigUInt value to divide by the divisor.
        x2: The double-word divisor.

    Raises:
        Error: If the divisor is zero.
    """
    if x2.is_zero():
        debug_assert[assert_mode="none"](
            len(x2.words) == 1,
            "floor_divide_inplace_by_double_words(): leading zero words",
        )
        raise Error(
            "biguint.arithmetics.floor_divide_inplace_by_double_words():"
            " Division by zero"
        )

    # CASE: all other situations
    var x2_value = UInt128(x2.words[1]) * UInt128(BigUInt.BASE) + UInt128(
        x2.words[0]
    )

    var carry = UInt128(0)
    if len(x1.words) % 2 == 1:
        carry = UInt128(x1.words[-1])
        x1.words.resize(len(x1.words) - 1, UInt32(0))

    for i in range(len(x1.words) - 1, -1, -2):
        var dividend = (
            carry * UInt128(1_000_000_000_000_000_000)
            + UInt128(x1.words[i]) * UInt128(BigUInt.BASE)
            + UInt128(x1.words[i - 1])
        )
        var quotient = dividend // x2_value
        x1.words[i] = UInt32(quotient // UInt128(BigUInt.BASE))
        x1.words[i - 1] = UInt32(quotient % UInt128(BigUInt.BASE))
        carry = dividend % x2_value

    x1.remove_leading_empty_words()
    return


fn floor_divide_inplace_by_2(mut x: BigUInt) -> None:
    """Divides a BigUInt by 2 in-place.

    Args:
        x: The BigUInt value to divide by 2.
    """
    if x.is_zero():
        debug_assert[assert_mode="none"](
            len(x.words) == 1, "floor_divide_inplace_by_2(): leading zero words"
        )
        return

    # Process from most significant to least significant word
    var base: UInt32 = BigUInt.BASE
    var is_carry: Bool = False
    for ith in range(len(x.words) - 1, -1, -1):
        if is_carry:
            x.words[ith] += base
        if x.words[ith] & 1:
            is_carry = True
        else:
            is_carry = False
        x.words[ith] >>= 1
    x.remove_leading_empty_words()


# TODO: Implement a in-place version of this function
fn floor_divide_by_power_of_ten(x: BigUInt, n: Int) -> BigUInt:
    """Floor divides a BigUInt by 10^n (n>=0).
    It is equal to removing the last n digits of the number.

    Args:
        x: The BigUInt value to divide.
        n: The power of 10 to divide by.

    Returns:
        A new BigUInt containing the result of the multiplication.

    Notes:

    Please note that this function does not check if n is negative.
    Please ensure that n is non-negative before calling this function.
    """
    debug_assert[assert_mode="none"](
        n >= 0,
        (
            "biguint.arithmetics.floor_divide_by_power_of_ten(): "
            "n must be non-negative but got "
            + String(n)
        ),
    )

    if n == 0:
        return x

    # First remove the last words (10^9)
    var result: BigUInt
    if len(x.words) == 1:
        result = x
    else:
        var word_shift = n // 9
        # If we need to drop more words than exists, result is zero
        if word_shift >= len(x.words):
            return BigUInt.ZERO
        # Create result with the remaining words
        words = List[UInt32]()
        for i in range(word_shift, len(x.words)):
            words.append(x.words[i])
        result = BigUInt(words=words^)

    # Then shift the remaining words right
    # Get the last word of the divisor
    var digit_shift = n % 9
    var carry = UInt32(0)
    var divisor: UInt32
    if digit_shift == 0:
        # No need to shift, just return the result
        return result^
    elif digit_shift == 1:
        divisor = UInt32(10)
    elif digit_shift == 2:
        divisor = UInt32(100)
    elif digit_shift == 3:
        divisor = UInt32(1000)
    elif digit_shift == 4:
        divisor = UInt32(10000)
    elif digit_shift == 5:
        divisor = UInt32(100000)
    elif digit_shift == 6:
        divisor = UInt32(1000000)
    elif digit_shift == 7:
        divisor = UInt32(10000000)
    else:  # digit_shift == 8
        divisor = UInt32(100000000)
    var power_of_carry = BigUInt.BASE // divisor
    for i in range(len(result.words) - 1, -1, -1):
        var quot = result.words[i] // divisor
        var rem = result.words[i] % divisor
        result.words[i] = quot + carry * power_of_carry
        carry = rem

    result.remove_leading_empty_words()
    return result^


# FAST RUCURSIVE DIVISION ALGORITHM
# =============================== #
# The following functions implement the Burnikel-Ziegler algorithm.
#
# floor_divide_burnikel_ziegler
# floor_divide_two_by_one
# floor_divide_three_by_two
# floor_divide_three_by_two_uint32
# floor_divide_four_by_two_uint32
#
# Yuhao Zhu:
# I tried to write this implementation based on the research report
# "Fast Recursive Division" by Christoph Burnikel and Joachim Ziegler.
# MPI-I-98-1-022, October 1998.
# The paper is mainly based on 2^k-based integers, and therefore, some tricks
# cannot be applied to 10^k-based integers. For example, when normalizing the
# divisor to let its most significant word be at least BASE//2, we cannot simply
# shift the bits until the most significant bit is 1.
# TODO:
# Some optimization needs to be done in future to
# (1) accelerate the normalization process
# (2) avoid unnecessary memory allocations and copies


fn floor_divide_burnikel_ziegler(
    a: BigUInt, b: BigUInt, cut_off: Int
) raises -> BigUInt:
    """Divides BigUInt using the Burnikel-Ziegler algorithm.

    Args:
        a: The dividend.
        b: The divisor.
        cut_off: The cutoff value for the number of words in the divisor to use
            the schoolbook division algorithm. It also determines the size of
            the blocks used in the recursive division algorithm.
    """

    var BLOCK_SIZE_OF_WORDS = cut_off

    # STEP 1:
    # Normalize the divisor b to n words so that
    # (1) it is of the form j*2^k and
    # (2) the most significant word is at least 500_000_000.

    var normalized_b = b
    var normalized_a = a
    var ndigits_to_shift: Int

    if normalized_b.words[-1] == 0:
        normalized_b.remove_leading_empty_words()
    if normalized_b.words[-1] < 500_000_000:
        ndigits_to_shift = (
            decimojo.biguint.arithmetics.calculate_ndigits_for_normalization(
                normalized_b.words[-1]
            )
        )
    else:
        ndigits_to_shift = 0

    # The targeted number of blocks should be the smallest 2^k such that
    # 2^k >= number of words in normalized_b ceil divided by BLOCK_SIZE_OF_WORDS.
    # k is the depth of the recursion.
    # n is the final number of words in the normalized b.
    var n_blocks_divisor = math.ceildiv(
        len(normalized_b.words), BLOCK_SIZE_OF_WORDS
    )
    var depth = Int(math.ceil(math.log2(Float64(n_blocks_divisor))))
    n_blocks_divisor = 2**depth
    var n = n_blocks_divisor * BLOCK_SIZE_OF_WORDS

    var n_digits_to_scale_up = (
        n - len(normalized_b.words)
    ) * 9 + ndigits_to_shift

    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_ten(
        normalized_b, n_digits_to_scale_up
    )
    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_ten(
        normalized_a, n_digits_to_scale_up
    )

    # The normalized_b is now 9 digits, but may still be smaller than 500_000_000.
    var gap_ratio: UInt32
    if normalized_b.words[-1] >= 500_000_000:  # Already normalized
        gap_ratio = 1
    elif normalized_b.words[-1] >= 250_000_000:  # 2x is enough
        gap_ratio = 2
    else:  # The most significant word is in [100_000_000, 125_000_000)
        gap_ratio = BigUInt.BASE_MAX // normalized_b.words[-1]

    if gap_ratio >= 2:
        decimojo.biguint.arithmetics.multiply_inplace_by_uint32(
            normalized_b, gap_ratio
        )
        decimojo.biguint.arithmetics.multiply_inplace_by_uint32(
            normalized_a, gap_ratio
        )

    # STEP 2: Split the normalized a into blocks of size n.
    # t is the number of blocks in the dividend.
    var t = math.ceildiv(len(normalized_a.words), n)
    if len(a.words) == t * n:
        # If the number of words in a is already a multiple of n
        # We check if the most significant word is >= 500_000_000.
        # If it is, we need to add one more block to the dividend.
        # This ensures that the most significant word of the dividend
        # is smaller than 500_000_000.
        # In this sense, the first 2-by-1 division will generate a quotient
        # of either 0 or 1, which would exceeds n-word capacity.
        if normalized_a.words[-1] >= 500_000_000:
            t += 1

    var z = BigUInt(0)
    var q = BigUInt(0)
    var q_i: BigUInt

    for i in range(t - 2, -1, -1):
        # The below function is the recursive division algorithm.
        # var q_i, r = floor_divide_two_by_one(z, normalized_b, n, cut_off)

        # The below function is the recursive division algorithm but works
        # with slices of the dividend and divisor.
        # Save the remainder in z as it will be carried over to the next
        # iteration and we can do some inplace operations.

        if i == t - 2:
            # The first iteration, we can use the slize of normalized_a
            q, z = floor_divide_slices_two_by_one(
                normalized_a,
                normalized_b,
                bounds_a=((t - 2) * n, len(normalized_a.words)),
                bounds_b=(0, len(normalized_b.words)),
                n=n,
                cut_off=cut_off,
            )
        else:
            q_i, z = floor_divide_slices_two_by_one(
                z,
                normalized_b,
                bounds_a=(0, len(z.words)),
                bounds_b=(0, len(normalized_b.words)),
                n=n,
                cut_off=cut_off,
            )
            decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
                q, n
            )
            q += q_i

        if i > 0:
            decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
                z, n
            )
            # z = r + a[(i - 1) * n : i * n]
            decimojo.biguint.arithmetics.add_inplace_by_slice(
                z,
                normalized_a,
                bounds_y=((i - 1) * n, i * n),
            )
    return q^


fn floor_divide_two_by_one(
    a: BigUInt, b: BigUInt, n: Int, cut_off: Int
) raises -> Tuple[BigUInt, BigUInt]:
    """Divides a BigUInt by another BigUInt using a recursive approach.
    The divisor has n words and the dividend has 2n words.

    Args:
        a: The dividend as a BigUInt.
        b: The divisor as a BigUInt. The most significant word must be at least
           500_000_000.
        n: The number of words in the divisor.
        cut_off: The minimum number of words for the recursive division.

    Returns:
        A tuple containing the quotient and the remainder as BigUInt.

    Notes:

    You need to ensure that n is even to continue with the algorithm.
    Otherwise, it will use the schoolbook division algorithm.
    """
    if (n & 1 == 1) or (n <= cut_off):
        var q = floor_divide_school(a, b)
        var r = a - q * b
        return (q^, r^)

    if b.words[-1] < 500_000_000:
        raise Error("b[-1] must be at least 500_000_000")

    else:
        var a0 = BigUInt(a.words[0 : n // 2])
        var a1 = BigUInt(a.words[n // 2 : n])
        var a2 = BigUInt(a.words[n : n + n // 2])
        var a3 = BigUInt(a.words[n + n // 2 : n + n])

        var b0 = BigUInt(b.words[0 : n // 2])
        var b1 = BigUInt(b.words[n // 2 : n])

        var q, r = floor_divide_three_by_two(
            a3, a2, a1, b1, b0, n // 2, cut_off
        )  # q is q1
        var r0 = BigUInt(r.words[0 : n // 2])
        var r1 = BigUInt(r.words[n // 2 : n])
        var q0, s = floor_divide_three_by_two(
            r1, r0, a0, b1, b0, n // 2, cut_off
        )

        # q -> q1q0
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            q, n // 2
        )
        q += q0

        return (q^, s^)


fn floor_divide_three_by_two(
    a2: BigUInt,
    a1: BigUInt,
    a0: BigUInt,
    b1: BigUInt,
    b0: BigUInt,
    n: Int,
    cut_off: Int,
) raises -> Tuple[BigUInt, BigUInt]:
    """Divides a 3-part number by a 2-part number.

    Args:
        a2: The most significant part of the dividend.
        a1: The middle part of the dividend.
        a0: The least significant part of the dividend.
        b1: The most significant part of the divisor.
        b0: The least significant part of the divisor.
        n: The number of part in the divisor.
        cut_off: The minimum number of part for the recursive division.

    Returns:
        A tuple containing the quotient and the remainder as BigUInt.

    Notes:

    a is a BigUInt with 3n words and b is a BigUInt with 2n words.
    """

    var a2a1: BigUInt
    if a2.is_zero():
        debug_assert[assert_mode="none"](
            len(a2.words) == 1,
            "floor_divide_three_by_two(): leading zero words",
        )
        a2a1 = a1
    else:
        a2a1 = a2
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            a2a1, n
        )
        a2a1 += a1
    var q, c = floor_divide_two_by_one(a2a1, b1, n, cut_off)
    var d = q * b0
    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(c, n)
    var r = c + a0

    if r < d:
        var b = b1
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(b, n)
        b += b0
        q -= BigUInt.ONE
        r += b
        if r < d:
            q -= BigUInt.ONE
            r += b

    r -= d
    return (q^, r^)


# Yuhao ZHU:
# The following two functions are OPTIMIZED versions of the
# `floor_divide_two_by_one` and `floor_divide_three_by_two` functions.
# They record the boundaries of the slices of the dividend and divisor
# to avoid unnecessary recursive slicing and copying of the BigUInt objects.
fn floor_divide_slices_two_by_one(
    a: BigUInt,
    b: BigUInt,
    bounds_a: Tuple[Int, Int],
    bounds_b: Tuple[Int, Int],
    n: Int,
    cut_off: Int,
) raises -> Tuple[BigUInt, BigUInt]:
    """Divides a BigUInt by another BigUInt using a recursive approach.
    The divisor has n words and the dividend has 2n words.

    Args:
        a: The dividend.
        b: The divisor.
        bounds_a: The range of words in the dividend to consider [start, end).
        bounds_b: The range of words in the divisor to consider [start, end).
            The most significant word must be at least 500_000_000.
        n: The number of words in the divisor.
        cut_off: The minimum number of words for the recursive division.

    Returns:
        A tuple containing the quotient and the remainder as BigUInt.

    Notes:

    You need to ensure that n is even to continue with the algorithm.
    Otherwise, it will use the schoolbook division algorithm.

    a_slice ~ [a0, a1, a2, a3] ~ a3a2a1a0 is a BigUInt with 2n words (n//2 per part).\\
    b_slice ~ [b0, b1] ~ b1b0 is a BigUInt with n words (n//2 per part).\\
    bounds_a3 = (bounds_a[0] + n + n // 2, bounds_a[0] + 2 * n)\\
    bounds_a2 = (bounds_a[0] + n, bounds_a[0] + n + n // 2)\\
    bounds_a1 = (bounds_a[0] + n // 2, bounds_a[0] + n)\\
    bounds_a0 = (bounds_a[0], bounds_a[0] + n // 2)\\
    bounds_b1 = (bounds_b[0] + n // 2, bounds_b[0] + n)\\
    bounds_b0 = (bounds_b[0], bounds_b[0] + n // 2).
    """

    debug_assert[assert_mode="none"](
        b.words[-1] >= 500_000_000,
        "floor_divide_slices_two_by_one(): b[-1] must be at least 500_000_000",
    )

    if (n & 1 == 1) or (n <= cut_off):
        var a_slice = BigUInt.from_slice(a, bounds_a)
        var b_slice = BigUInt.from_slice(b, bounds_b)
        var q = floor_divide_school(a_slice, b_slice)
        # r = a_slice - q * b_slice
        a_slice -= multiply_slices(q, b, (0, len(q.words)), bounds_b)
        return (q^, a_slice^)

    elif bounds_a[0] + n + n // 2 >= bounds_a[1]:
        # If a3 is empty
        # We just need to use three-by-two division once: a2a1a0 // b1b0
        var q, r = floor_divide_slices_three_by_two(
            a, b, bounds_a, bounds_b, n // 2, cut_off
        )
        return (q^, r^)

    elif a.is_zero(bounds=(bounds_a[0] + n + n // 2, bounds_a[1])):
        # If a3 is zero
        # We just need to use three-by-two division once: a2a1a0 // b1b0
        var q, r = floor_divide_slices_three_by_two(
            a, b, bounds_a, bounds_b, n // 2, cut_off
        )
        return (q^, r^)

    else:
        var bounds_a1a3 = (bounds_a[0] + n // 2, bounds_a[1])

        # We use the most significant three parts of the dividend
        # a3a2a1 // b1b0
        var q, r = floor_divide_slices_three_by_two(
            a, b, bounds_a1a3, bounds_b, n // 2, cut_off
        )

        multiply_inplace_by_power_of_billion(r, n // 2)
        add_inplace_by_slice(r, a, (bounds_a[0], bounds_a[0] + n // 2))
        var q0, s = floor_divide_slices_three_by_two(
            r, b, (0, len(r.words)), bounds_b, n // 2, cut_off
        )

        # q -> q1q0
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            q, n // 2
        )
        q += q0

        return (q^, s^)


fn floor_divide_slices_three_by_two(
    a: BigUInt,
    b: BigUInt,
    bounds_a: Tuple[Int, Int],
    bounds_b: Tuple[Int, Int],
    n: Int,
    cut_off: Int,
) raises -> Tuple[BigUInt, BigUInt]:
    """Divides a 3n-word BigUInt slice by a 2n-word BigUInt slice.

    Args:
        a: The dividend.
        b: The divisor.
        bounds_a: The range of words in the dividend to consider [start, end).
        bounds_b: The range of words in the divisor to consider [start, end).
        n: The number of words in each part of the dividend and divisor.
        cut_off: The minimum number of words for the recursive division.

    Returns:
        A tuple containing the quotient and the remainder as BigUInt.

    Notes:

    a_slice ~ [a0, a1, a2] ~ a2a1a0 is a BigUInt with 3n words.\\
    b_slice ~ [b0, b1] ~ b1b0 is a BigUInt with 2n words.\\
    bounds_a2 = (bounds_a[0] + 2 * n, bounds_a[0] + 3 * n)\\
    bounds_a1 = (bounds_a[0] + n, bounds_a[0] + 2 * n)\\
    bounds_a0 = (bounds_a[0], bounds_a[0] + n)\\
    bounds_b1 = (bounds_b[0] + n, bounds_b[0] + 2 * n)\\
    bounds_b0 = (bounds_b[0], bounds_b[0] + n).
    """

    # SPECIAL CASE:
    # If a2 is empty or zero, than it beomes a2a1 // b1b0
    # Because the most significant word of b1 is at least 500_000_000,
    # The quotient will be either 1 or 0.
    if bounds_a[0] + 2 * n == bounds_a[1]:
        debug_assert[assert_mode="none"](
            a.words[bounds_a[1] - 1] != 0,
            "the most significant word of a must not be zero",
        )
        if a.words[bounds_a[1] - 1] >= b.words[bounds_b[1] - 1]:
            var r = BigUInt.from_slice(a, (bounds_a[0], bounds_a[1]))
            subtract_inplace(r, BigUInt.from_slice(b, bounds_b))
            return (BigUInt.ONE, r^)
        else:
            return (
                BigUInt.ZERO,
                BigUInt.from_slice(a, bounds_a),
            )

    # Now we can safely assume that a2 is not empty.
    var bounds_a0 = (bounds_a[0], bounds_a[0] + n)
    var bounds_a2a1 = (bounds_a[0] + n, bounds_a[1])
    var bounds_b1 = (bounds_b[0] + n, bounds_b[1])
    var bounds_b0 = (bounds_b[0], bounds_b[0] + n)

    q, c = floor_divide_slices_two_by_one(
        a, b, bounds_a2a1, bounds_b1, n, cut_off
    )
    var d = multiply_slices(q, b, (0, len(q.words)), bounds_b0)
    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(c, n)
    var r = add_slices(c, a, bounds_x=(0, len(c.words)), bounds_y=bounds_a0)

    if r < d:
        q -= BigUInt.ONE
        # r = r + b
        add_inplace_by_slice(r, b, bounds_y=bounds_b)
        if r < d:
            q -= BigUInt.ONE
            # r = r + b
            add_inplace_by_slice(r, b, bounds_y=bounds_b)

    r -= d
    return (q^, r^)


# Yuhao ZHU:
# The following functions are most granular implementations of the
# Burnikel-Ziegler algorithm, which divide a 3-word number by a 2-word number
# and a 4-word number by a 2-word number, respectively.
# They are not used because they are too granular and not efficient.
# When then size of the divisor is less than N, we switch to the schoolbook
# division algorithm.
# However, these functions are still valid and can be used if needed.
fn floor_divide_three_by_two_uint32(
    a2: UInt32, a1: UInt32, a0: UInt32, b1: UInt32, b0: UInt32
) raises -> Tuple[UInt32, UInt32, UInt32]:
    """Divides a 3-word number by a 2-word number.
    b1 must be at least 500_000_000.

    Args:
        a2: The most significant word of the dividend.
        a1: The middle word of the dividend.
        a0: The least significant word of the dividend.
        b1: The most significant word of the divisor.
        b0: The least significant word of the divisor.

    Returns:
        A tuple containing
        (1) the quotient (as UInt32)
        (2) the most significant word of the remainder (as UInt32)
        (3) the least significant word of the remainder (as UInt32).

    Notes:

    a = a2 * BASE^2 + a1 * BASE + a0.
    b = b1 * BASE + b0.
    """
    if b1 < 500_000_000:
        raise Error("b1 must be at least 500_000_000")

    var a2a1 = UInt64(a2) * 1_000_000_000 + UInt64(a1)

    var q: UInt64 = UInt64(a2a1) // UInt64(b1)
    var c = a2a1 - q * UInt64(b1)
    var d: UInt64 = q * UInt64(b0)
    var r = UInt64(c * 1_000_000_000) + UInt64(a0)

    if r < UInt64(d):
        var b = UInt64(b1) * 1_000_000_000 + UInt64(b0)
        q -= 1
        r += b
        if r < UInt64(d):
            q -= 1
            r += b

    r -= d
    var r1: UInt32 = UInt32(r // 1_000_000_000)
    var r0: UInt32 = UInt32(r % 1_000_000_000)

    return (UInt32(q), r1, r0)


fn floor_divide_four_by_two_uint32(
    a3: UInt32,
    a2: UInt32,
    a1: UInt32,
    a0: UInt32,
    b1: UInt32,
    b0: UInt32,
) raises -> Tuple[UInt32, UInt32, UInt32, UInt32]:
    """Divides a 4-word number by a 2-word number.

    Args:
        a3: The most significant word of the dividend.
        a2: The second most significant word of the dividend.
        a1: The second least significant word of the dividend.
        a0: The least significant word of the dividend.
        b1: The most significant word of the divisor.
        b0: The least significant word of the divisor.

    Returns:
        A tuple containing
        (1) the most significant word of the quotient (as UInt32)
        (2) the least significant word of the quotient (as UInt32)
        (3) the most significant word of the remainder (as UInt32)
        (4) the least significant word of the remainder (as UInt32).
    """

    if b1 < 500_000_000:
        raise Error("b1 must be at least 500_000_000")
    if a3 > b1:
        raise Error("a must be less than b * 10^18")
    elif a3 == b1:
        if a2 > b0:
            raise Error("a must be less than b * 10^18")
        elif a2 == b0:
            if a1 > 0:
                raise Error("a must be less than b * 10^18")
            elif a1 == 0:
                if a0 >= 0:
                    raise Error("a must be less than b * 10^18")

    var q1, r1, r0 = floor_divide_three_by_two_uint32(a3, a2, a1, b1, b0)
    var q0, s1, s0 = floor_divide_three_by_two_uint32(r1, r0, a0, b1, b0)
    return (q1, q0, s1, s0)


@always_inline
fn truncate_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, truncating toward zero.
    It is equal to floored division for unsigned numbers.
    See `floor_divide` for more details.
    """
    return floor_divide(x1, x2)


fn ceil_divide(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the quotient of two BigUInt numbers, rounding up.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, rounded up.

    Raises:
        ValueError: If the divisor is zero.
    """

    # CASE: Division by zero
    if x2.is_zero():
        debug_assert[assert_mode="none"](
            len(x2.words) == 1,
            "ceil_divide(): leading zero words",
        )
        raise Error("biguint.arithmetics.ceil_divide(): Division by zero")

    # Apply floor division and check if there is a remainder
    var quotient = floor_divide(x1, x2)
    if quotient * x2 < x1:
        quotient += BigUInt(UInt32(1))
    return quotient^


fn floor_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, truncating toward zero.
    The remainder has the same sign as the dividend and satisfies:
    x1 = floor_divide(x1, x2) * x2 + floor_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being divided by x2.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to floored modulo for positive numbers.
    """
    # CASE: Division by zero
    if x2.is_zero():
        debug_assert[assert_mode="none"](
            len(x2.words) == 1,
            "truncate_modulo(): leading zero words",
        )
        raise Error("Error in `truncate_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        debug_assert[assert_mode="none"](
            len(x1.words) == 1, "truncate_modulo(): leading zero words"
        )
        return BigUInt()  # Return zero

    # CASE: Divisor is one - no remainder
    if x2.is_one():
        return BigUInt()  # Always divisible with no remainder

    # CASE: |dividend| < |divisor| - the remainder is the dividend itself
    if x1.compare(x2) < 0:
        return x1

    # Calculate quotient with truncation
    var quotient = floor_divide(x1, x2)

    # Calculate remainder: dividend - (divisor * quotient)
    var remainder = subtract(x1, multiply(x2, quotient))

    return remainder^


@always_inline
fn truncate_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, truncating toward zero.
    It is equal to floored modulo for unsigned numbers.
    See `floor_modulo` for more details.
    """
    return floor_modulo(x1, x2)


fn ceil_modulo(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the remainder of two BigUInt numbers, rounding up.
    The remainder has the same sign as the dividend and satisfies:
    x1 = ceil_divide(x1, x2) * x2 + ceil_modulo(x1, x2).

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The remainder of x1 being ceil-divided by x2.

    Raises:
        ValueError: If the divisor is zero.
    """
    # CASE: Division by zero
    if x2.is_zero():
        debug_assert[assert_mode="none"](
            len(x2.words) == 1, "ceil_modulo(): leading zero words"
        )
        raise Error("Error in `ceil_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
        debug_assert[assert_mode="none"](
            len(x1.words) == 1, "ceil_modulo(): leading zero words"
        )
        return BigUInt()  # Return zero

    # CASE: Divisor is one - no remainder
    if x2.is_one():
        return BigUInt()  # Always divisible with no remainder

    # CASE: |dividend| < |divisor| - the remainder is the dividend itself
    if x1.compare(x2) < 0:
        return x1

    # Calculate quotient with truncation
    var quotient = floor_divide(x1, x2)
    # Calculate remainder: dividend - (divisor * quotient)
    var remainder = subtract(x1, multiply(x2, quotient))

    if remainder.is_zero():
        debug_assert[assert_mode="none"](
            len(remainder.words) == 1, "ceil_modulo(): leading zero words"
        )
        return BigUInt()  # No remainder
    else:
        return subtract(x2, remainder)


fn floor_divide_modulo(
    x1: BigUInt, x2: BigUInt
) raises -> Tuple[BigUInt, BigUInt]:
    """Returns the quotient and remainder of two numbers, truncating toward zero.

    Args:
        x1: The dividend.
        x2: The divisor.

    Returns:
        The quotient of x1 / x2, truncated toward zero and the remainder.

    Raises:
        ValueError: If the divisor is zero.

    Notes:
        It is equal to truncated division for positive numbers.
    """

    var quotient = floor_divide(x1, x2)
    var remainder = subtract(x1, multiply(x2, quotient))
    return (quotient^, remainder^)


# ===----------------------------------------------------------------------=== #
# Division Helper Functions
# power_of_10
# ===----------------------------------------------------------------------=== #


fn normalize_carries_lt_2_bases(mut x: BigUInt):
    """Normalizes the values of words into valid range by carrying over.
    The initial values of the words should be in the range [0, BASE*2).

    Notes:

    If we adds two BigUInt numbers word-by-word, we may end up with
    a situation where some words are larger than BASE. This function
    normalizes the carries, ensuring that all words are within the valid range.
    It modifies the input BigUInt in-place.
    """

    # Yuhao ZHU:
    # By construction, the words of x are in the range [0, BASE*2).
    # Thus, the carry can only be 0 or 1.
    var carry: UInt32 = 0
    for ref word in x.words:
        if carry == 0:
            if word <= BigUInt.BASE_MAX:
                pass  # carry = 0
            else:
                word -= BigUInt.BASE
                carry = 1
        else:  # carry == 1
            if word < BigUInt.BASE_MAX:
                word += 1
                carry = 0
            else:
                word = word + 1 - BigUInt.BASE
                # carry = 1
    if carry > 0:
        # If there is still a carry, we need to add a new word
        x.words.append(UInt32(1))
    return


fn normalize_carries_lt_4_bases(mut x: BigUInt):
    """Normalizes the values of words into valid range by carrying over.
    The initial values of the words should be in the range [0, BASE * 4 - 4].

    Notes:

    If we multiply a BigUInt numbers word-by-word by 3 or 4, we may end up with
    a situation where some words are ge than BASE but le BASE * 4 - 4.
    This function normalizes the carries, ensuring that all words are within the
    valid range. It modifies the input BigUInt in-place.
    """

    # Yuhao ZHU:
    # By construction, the words of x are in the range [0, BASE*4).
    # Thus, the carry can only be 0, 1, 2, or 3.
    var carry: UInt32 = 0
    for ref word in x.words:
        if carry == 0:
            if word <= UInt32(999_999_999):
                pass  # carry = 0
            elif word <= UInt32(1_999_999_999):
                word -= UInt32(1_000_000_000)
                carry = 1
            elif word <= UInt32(2_999_999_999):
                word -= UInt32(2_000_000_000)
                carry = 2
            else:  # 3_000_000_000 <= word <= 3_999_999_996
                word -= UInt32(3_000_000_000)
                carry = 3
        elif carry == 1:
            if word <= UInt32(999_999_998):
                word += 1
                carry = 0
            elif word <= UInt32(1_999_999_998):
                word = word + 1 - UInt32(1_000_000_000)
                carry = 1
            elif word <= UInt32(2_999_999_998):
                word = word + 1 - UInt32(2_000_000_000)
                carry = 2
            else:  # 2_999_999_999 <= word <= 3_999_999_996
                word = word + 1 - UInt32(3_000_000_000)
                carry = 3
        elif carry == 2:
            if word <= UInt32(999_999_997):
                word += 2
                carry = 0
            elif word <= UInt32(1_999_999_997):
                word = word + 2 - UInt32(1_000_000_000)
                carry = 1
            elif word <= UInt32(2_999_999_997):
                word = word + 2 - UInt32(2_000_000_000)
                carry = 2
            else:  # 2_999_999_998 <= word <= 3_999_999_996
                word = word + 2 - UInt32(3_000_000_000)
                carry = 3
        else:  # carry == 3
            if word <= UInt32(999_999_996):
                word += 3
                carry = 0
            elif word <= UInt32(1_999_999_996):
                word = word + 3 - UInt32(1_000_000_000)
                carry = 1
            elif word <= UInt32(2_999_999_996):
                word = word + 3 - UInt32(2_000_000_000)
                carry = 2
            else:  # 2_999_999_997 <= word <= 3_999_999_996
                word = word + 3 - UInt32(3_000_000_000)
                carry = 3
    if carry > 0:
        # If there is still a carry, we need to add a new word
        x.words.append(UInt32(carry))
    return


fn normalize_borrows(mut x: BigUInt):
    """Normalizes the values of words into valid range by borrowing.
    The caller should ensure that the final result is non-negative.
    The initial values of the words should be in the range:
    [0, BASE-1] or [3294967297, 4294967295], in other words,
    [UInt32.MAX - 999_999_998, ..., UInt32.MAX, 0, ..., BASE-1].

    Notes:

    If we subtract two BigUInt numbers word-by-word, we may end up with
    a situation where some words are **underflowed**. We can take advantage of
    the overflowed values of the words to normalize the borrows,
    ensuring that all words are within the valid range.
    """

    alias NEG_BASE_MAX = UInt32(3294967297)  # UInt32(0) - BigUInt.BASE_MAX

    # Yuhao ZHU:
    # By construction, the words of x are in the range [-BASE_MAX, BASE_MAX].
    # Thus, the borrow can only be 0 or 1.
    var borrow: UInt32 = 0
    for ref word in x.words:
        if borrow == 0:
            if word <= BigUInt.BASE_MAX:  # 0 <= word <= 999_999_999
                pass  # borrow = 0
            else:  # word >= 3294967297, overflowed value
                word += BigUInt.BASE
                borrow = 1
        else:  # borrow == 1
            if (word >= 1) and (
                word <= BigUInt.BASE_MAX
            ):  # 1 <= word <= 999_999_999
                word -= 1
                borrow = 0
            else:  # word >= 3294967297 or word == 0, overflowed value
                word = (word + BigUInt.BASE) - 1
                # borrow = 1
    return


fn power_of_10(n: Int) raises -> BigUInt:
    """Calculates 10^n efficiently."""
    if n < 0:
        raise Error(
            "biguint.arithmetics.power_of_10(): Negative exponent not supported"
        )

    if n == 0:
        return BigUInt(1)

    # Handle small powers directly
    if n < 9:
        var value: UInt32 = 1
        for _ in range(n):
            value *= 10
        return BigUInt(value)

    # For larger powers, split into groups of 9 digits
    var words = n // 9
    var remainder = n % 9

    var result = BigUInt(List[UInt32]())

    # Add leading zeros for full power-of-billion words
    for _ in range(words):
        result.words.append(0)

    # Calculate partial power for the highest word
    var high_word: UInt32 = 1
    for _ in range(remainder):
        high_word *= 10

    # Only add non-zero high word
    if high_word > 1:
        result.words.append(high_word)
    else:
        # Add a 1 in the next position
        result.words.append(1)

    return result^


@always_inline
fn calculate_ndigits_for_normalization(msw: UInt32) -> Int:
    """Calculates the number of digits to shift left for normalization.

    Args:
        msw: The most significant word of the number to normalize.

    Returns:
        The number of digits to shift left to normalize the number.

    Notes:

    This is a helper function for division algorithms.
    The normalized word should be as close to BASE as possible.
    """
    if msw < 10_000:
        if msw < 100:
            if msw < 10:
                ndigits = 8  # Shift by 8 digits
            else:  # 10 <= msw < 100
                ndigits = 7  # Shift by 7 digits
        else:  # 100 <= msw < 10_000
            if msw < 1_000:  # 100 <= msw < 1_000
                ndigits = 6  # Shift by 6 digits
            else:  # 1_000 <= msw < 10_000:
                ndigits = 5  # Shift by 5 digits
    elif msw < 100_000_000:  # 10_000 <= msw < 100_000_000
        if msw < 1_000_000:
            if msw < 100_000:  # 10_000 <= msw < 100_000
                ndigits = 4  # Shift by 4 digits
            else:  # 100_000 <= msw < 1_000_000
                ndigits = 3  # Shift by 3 digits
        else:  # 1_000_000 <= msw < 100_000_000
            if msw < 10_000_000:  # 1_000_000 <= msw < 10_000_000
                ndigits = 2  # Shift by 2 digits
            else:  # 10_000_000 <= msw < 100_000_000
                ndigits = 1  # Shift by 1 digit
    else:  # 100_000_000 <= msw < 1_000_000_000
        ndigits = 0  # No shift needed

    return ndigits


fn to_uint64_with_2_words(a: BigUInt, bounds_x: Tuple[Int, Int]) -> UInt64:
    """Convert two words at given index of the BigUInt to UInt64."""
    var n_words = bounds_x[1] - bounds_x[0]
    if n_words == 1:
        return a.words.data.load[width=1](bounds_x[0]).cast[DType.uint64]()
    else:
        return (
            a.words.data.load[width=2](bounds_x[0]).cast[DType.uint64]()
            * SIMD[DType.uint64, 2](1, 1_000_000_000)
        ).reduce_add()


fn to_uint128_with_2_words(a: BigUInt, bounds_x: Tuple[Int, Int]) -> UInt128:
    """Convert two words at given index of the BigUInt to UInt128."""
    var n_words = bounds_x[1] - bounds_x[0]
    if n_words == 1:
        return a.words.data.load[width=1](bounds_x[0]).cast[DType.uint128]()
    else:
        return (
            a.words.data.load[width=2](bounds_x[0]).cast[DType.uint128]()
            * SIMD[DType.uint128, 2](1, 1_000_000_000)
        ).reduce_add()


fn to_uint128_with_4_words(a: BigUInt, bounds_x: Tuple[Int, Int]) -> UInt128:
    """Convert four words at given index of the BigUInt to UInt128."""
    var n_words = bounds_x[1] - bounds_x[0]
    if n_words == 1:
        return a.words.data.load[width=1](bounds_x[0]).cast[DType.uint128]()
    elif n_words == 2:
        return (
            a.words.data.load[width=2](bounds_x[0]).cast[DType.uint128]()
            * SIMD[DType.uint128, 2](1, 1_000_000_000)
        ).reduce_add()
    elif n_words == 3:
        return (
            a.words.data.load[width=4](bounds_x[0]).cast[DType.uint128]()
            * SIMD[DType.uint128, 4](
                1, 1_000_000_000, 1_000_000_000_000_000_000, 0
            )
        ).reduce_add()
    else:  # len(self.words) == 4
        return (
            a.words.data.load[width=4](bounds_x[0]).cast[DType.uint128]()
            * SIMD[DType.uint128, 4](
                1,
                1_000_000_000,
                1_000_000_000_000_000_000,
                1_000_000_000_000_000_000_000_000_000,
            )
        ).reduce_add()
