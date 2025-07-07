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
# add_inplace(x1: BigUInt, x2: BigUInt)
# add_inplace_by_1(x: BigUInt) -> None
#
# subtract(x1: BigUInt, x2: BigUInt) -> BigUInt
# subtract_inplace(x1: BigUInt, x2: BigUInt) -> None
#
# multiply(x1: BigUInt, x2: BigUInt) -> BigUInt
# multiply_slices(x: BigUInt, y: BigUInt, start_x: Int, end_x: Int, start_y: Int, end_y: Int) -> BigUInt
# multiply_karatsuba(x: BigUInt, y: BigUInt, start_x: Int, end_x: Int, start_y: Int, end_y: Int, cutoff_number_of_words: Int) -> BigUInt
# scale_up_by_power_of_10(x: BigUInt, n: Int) -> BigUInt
# scale_up_inplace_by_power_of_billion(mut x: BigUInt, n: Int)
#
# floor_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_general(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_divide_inplace_by_single_word(x1: BigUInt, x2: BigUInt) -> None
# floor_divide_inplace_by_double_words(x1: BigUInt, x2: BigUInt) -> None
# floor_divide_inplace_by_2(x: BigUInt) -> Nonet, x2: BigUInt) -> BigUInt
# truncate_divide(x1: BigUInt, x2: BigUInt) -> BigUInt
# floor_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# ceil_divide(x1: BigUInt, x2: BigUInt) -> BigUIntulo(x1: BigUIn# floor_divide_general(x1: BigUInt, x2: BigUInt) -> BigUInt
# ceil_modulo(x1: BigUInt, x2: BigUInt) -> BigUInt
# divmod(x1: BigUInt, x2: BigUInt) -> Tuple[BigUInt, BigUInt]
# scale_down_by_power_of_10(x: BigUInt, n: Int) -> BigUInt
#
# floor_divide_estimate_quotient(x1: BigUInt, x2: BigUInt, j: Int, m: Int) -> UInt64
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
        raise Error(
            "biguint.arithmetics.negative(): Negative of non-zero unsigned"
            " integer is undefined"
        )
    return BigUInt()  # Return zero


fn negative_inplace(mut x: BigUInt) raises -> None:
    """Does nothing as negative of non-zero unsigned integer is undefined."""
    if not x.is_zero():
        raise Error(
            "biguint.arithmetics.negative_inplace(): Negative of non-zero"
            " unsigned integer is undefined"
        )
    return


fn absolute(x: BigUInt) -> BigUInt:
    """Returns the absolute value of a BigUInt number.

    Args:
        x: The BigUInt value to compute the absolute value of.

    Returns:
        A new BigUInt containing the absolute value of x.
    """
    return x


fn absolute_inplace(mut x: BigUInt) -> None:
    """Does nothing as absolute value of unsigned integer is itself.

    Args:
        x: The BigUInt value to compute the absolute value of.
    """
    return


# ===----------------------------------------------------------------------=== #
# Addition algorithms
# add, add_inplace, add_inplace_by_1
# ===----------------------------------------------------------------------=== #


fn add(x: BigUInt, y: BigUInt) -> BigUInt:
    """Returns the sum of two unsigned integers.

    Args:
        x: The first unsigned integer operand.
        y: The second unsigned integer operand.

    Returns:
        The sum of the two unsigned integers.
    """

    # Short circuit cases
    # Zero cases
    if x.is_zero():
        return y

    if y.is_zero():
        return x

    # If both numbers are single-word, we can handle them with UInt32
    if len(x.words) == 1 and len(y.words) == 1:
        return BigUInt.from_uint32(x.words[0] + y.words[0])

    # If both numbers are double-word, we can handle them with UInt64
    if len(x.words) <= 2 and len(y.words) <= 2:
        return BigUInt.from_unsigned_integral_scalar(
            x.to_uint64_with_first_2_words() + y.to_uint64_with_first_2_words()
        )

    # Normal cases
    return add_slices(x, y, 0, len(x.words), 0, len(y.words))


fn add_slices(
    read x: BigUInt,
    read y: BigUInt,
    start_x: Int,
    end_x: Int,
    start_y: Int,
    end_y: Int,
) -> BigUInt:
    """Adds two BigUInt slices using the school method.

    Args:
        x: The first BigUInt operand (first summand).
        y: The second BigUInt operand (second summand).
        start_x: The starting index of x to consider.
        end_x: The ending index of x to consider.
        start_y: The starting index of y to consider.
        end_y: The ending index of y to consider.

    Returns:
        A new BigUInt containing the sum of the two slices.

    Notes:
        This function conducts addtion of the two BigUInt slices. It avoids
        creating copies of the BigUInt objects by using the indices to access
        the words directly. This is useful for performance in cases where the
        BigUInt objects are large and we only need to add a part of them.
    """

    n_words_x_slice = end_x - start_x
    n_words_y_slice = end_y - start_y

    # Short circuit cases
    if n_words_x_slice == 1:
        # x is zero, return y
        if x.words[start_x] == 0:
            return BigUInt(words=y.words[start_y:end_y])
        # If both numbers are single-word, we can handle them with UInt32
        if n_words_y_slice == 1:
            return BigUInt.from_uint32(x.words[start_x] + y.words[start_y])
    if n_words_y_slice == 1:
        if y.words[start_y] == 0:
            return BigUInt(words=x.words[start_x:end_x])

    # Normal cases
    # The result will have at most one more word than the longer operand
    var words = List[UInt32](capacity=max(n_words_x_slice, n_words_y_slice) + 1)

    var carry: UInt32 = 0
    var ith: Int = 0
    var sum_of_words: UInt32

    # Add corresponding words from both numbers
    while ith < n_words_x_slice or ith < n_words_y_slice:
        sum_of_words = carry

        # Add x1's word if available
        if ith < n_words_x_slice:
            sum_of_words += x.words[start_x + ith]

        # Add x2's word if available
        if ith < n_words_y_slice:
            sum_of_words += y.words[start_y + ith]

        # Compute new word and carry
        carry = sum_of_words // BigUInt.BASE
        words.append(sum_of_words % BigUInt.BASE)

        ith += 1

    # Handle final carry if it exists
    if carry > 0:
        words.append(carry)

    return BigUInt(words=words^)


fn add_inplace(mut x1: BigUInt, x2: BigUInt) -> None:
    """Increments a BigUInt number by another BigUInt number in place.

    Args:
        x1: The first unsigned integer operand.
        x2: The second unsigned integer operand.
    """

    # Short circuit cases
    if len(x1.words) == 1:
        if x1.is_zero():
            x1.words[0] = x2.words[0]
            return
        if len(x2.words) == 1:
            var value = x1.words[0] + x2.words[0]
            if value <= BigUInt.BASE_MAX:
                x1.words[0] = value
                return
            else:
                x1.words[0] = value % BigUInt.BASE
                x1.words.append(value // BigUInt.BASE)
                return
        else:
            pass

    if len(x2.words) == 1:
        if x2.words[0] == 0:
            return  # No change needed
        elif x2.words[0] == 1:
            # Optimized case for adding 1
            add_inplace_by_1(x1)
            return

    # Normal cases
    if len(x1.words) < len(x2.words):
        x1.words.resize(new_size=len(x2.words), value=UInt32(0))

    var carry: UInt32 = 0

    for i in range(len(x2.words)):
        x1.words[i] += carry + x2.words[i]
        carry = x1.words[i] // BigUInt.BASE
        x1.words[i] %= BigUInt.BASE

    # If len(x1.words) == len(x2.words), this loop is skipped
    for i in range(len(x2.words), len(x1.words)):
        x1.words[i] += carry
        carry = x1.words[i] // BigUInt.BASE
        if carry == 0:
            break  # No more carry, we can stop early
        x1.words[i] %= BigUInt.BASE

    # Handle final carry if it exists
    if carry > 0:
        x1.words.append(carry)

    return


fn add_inplace_by_1(mut x: BigUInt) -> None:
    """Increments a BigUInt number by 1."""
    var i = 0
    while i < len(x.words):
        if x.words[i] < BigUInt.BASE_MAX:
            x.words[i] += UInt32(1)
            return
        else:  # If the word is 999_999_999, we need to carry over
            x.words[i] = 0
            i += 1
    # If we reach here, we need to add a new word
    x.words.append(UInt32(1))
    return


# ===----------------------------------------------------------------------=== #
# Subtraction algorithms
# ===----------------------------------------------------------------------=== #


fn subtract(x1: BigUInt, x2: BigUInt) raises -> BigUInt:
    """Returns the difference of two unsigned integers.

    Args:
        x1: The first unsigned integer (minuend).
        x2: The second unsigned integer (subtrahend).

    Raises:
        Error: If x2 is greater than x1, resulting in an underflow.

    Returns:
        The result of subtracting x2 from x1.
    """
    # If the subtrahend is zero, return the minuend
    if x2.is_zero():
        return x1

    # We need to determine which number has the larger magnitude
    var comparison_result = x1.compare(x2)
    if comparison_result == 0:
        # |x1| = |x2|
        return BigUInt()  # Return zero
    if comparison_result < 0:
        raise Error("biguint.arithmetics.subtract(): Underflow due to x1 < x2")

    # Now it is safe to subtract the smaller number from the larger one
    # The result will have no more words than the larger operand
    var words = List[UInt32](capacity=max(len(x1.words), len(x2.words)))
    var borrow: Int32 = 0
    var ith: Int = 0
    var difference: Int32  # Int32 is sufficient for the difference

    while ith < len(x1.words):
        # Subtract the borrow
        difference = Int32(x1.words[ith]) - borrow
        # Subtract smaller's word if available
        if ith < len(x2.words):
            difference -= Int32(x2.words[ith])
        # Handle borrowing if needed
        if difference < Int32(0):
            difference += Int32(BigUInt.BASE)
            borrow = Int32(1)
        else:
            borrow = Int32(0)
        words.append(UInt32(difference))
        ith += 1

    var result = BigUInt(words=words^)
    result.remove_leading_empty_words()
    return result^


fn subtract_inplace(mut x: BigUInt, y: BigUInt) raises -> None:
    """Subtracts y from x in place."""

    # If the subtrahend is zero, return the minuend
    if y.is_zero():
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
    var borrow: Int32 = 0
    var ith: Int = 0
    var difference: Int32  # Int32 is sufficient for the difference

    while ith < len(x.words):
        # Subtract the borrow
        difference = Int32(x.words[ith]) - borrow
        # Subtract smaller's word if available
        if ith < len(y.words):
            difference -= Int32(y.words[ith])
        # Handle borrowing if needed
        if difference < Int32(0):
            difference += Int32(BigUInt.BASE)
            borrow = Int32(1)
        else:
            borrow = Int32(0)
        x.words[ith] = UInt32(difference)
        ith += 1

    x.remove_leading_empty_words()
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

    alias CUTOFF_KARATSUBA: Int = 64
    """The cutoff number of words for using Karatsuba multiplication."""

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
        # return multiply_slices (x, y)
        return multiply_slices(x, y, 0, len(x.words), 0, len(y.words))
        # multiply_slices can also takes in x, y, and indices

    # CASE 2
    # Use Karatsuba multiplication for larger numbers
    else:
        return multiply_karatsuba(
            x, y, 0, len(x.words), 0, len(y.words), CUTOFF_KARATSUBA
        )


fn multiply_slices(
    read x: BigUInt,
    read y: BigUInt,
    start_x: Int,
    end_x: Int,
    start_y: Int,
    end_y: Int,
) -> BigUInt:
    """Multiplies two BigUInt slices using the school method.

    Args:
        x: The first BigUInt operand (multiplicand).
        y: The second BigUInt operand (multiplier).
        start_x: The starting index of x to consider.
        end_x: The ending index of x to consider.
        start_y: The starting index of y to consider.
        end_y: The ending index of y to consider.
    """

    n_words_x_slice = end_x - start_x
    n_words_y_slice = end_y - start_y

    # CASE: One of the operands is zero or one
    if n_words_x_slice == 1:
        var x_word = x.words[start_x]
        if x_word == 0:
            return BigUInt(UInt32(0))
        elif x_word == 1:
            return BigUInt(words=y.words[start_y:end_y])
        else:
            var result = BigUInt(words=y.words[start_y:end_y])
            multiply_inplace_by_uint32(result, x_word)
            return result^
    if n_words_y_slice == 1:
        var y_word = y.words[start_y]
        if y_word == 0:
            return BigUInt(UInt32(0))
        elif y_word == 1:
            return BigUInt(words=x.words[start_x:end_x])
        else:
            var result = BigUInt(words=x.words[start_x:end_x])
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
        if x.words[start_x + i] == 0:
            continue

        carry = UInt64(0)

        for j in range(n_words_y_slice):
            # Calculate the product of the current words
            # plus the carry from the previous multiplication
            # plus the value already at this position in the result
            var product = (
                UInt64(x.words[start_x + i]) * UInt64(y.words[start_y + j])
                + carry
                + UInt64(words[i + j])
            )

            # The lower 9 digits (base 10^9) go into the current word
            # The upper digits become the carry for the next position
            words[i + j] = UInt32(product % BigUInt.BASE)
            carry = product // BigUInt.BASE

        # If there is a carry left, add it to the next position
        if carry > 0:
            words[i + n_words_y_slice] += UInt32(carry)

    var result = BigUInt(words=words^)
    result.remove_leading_empty_words()
    return result^


fn multiply_karatsuba(
    read x: BigUInt,
    read y: BigUInt,
    start_x: Int,
    end_x: Int,
    start_y: Int,
    end_y: Int,
    cutoff_number_of_words: Int,
) -> BigUInt:
    """Multiplies two BigUInt numbers using the Karatsuba algorithm.

    Args:
        x: The first BigUInt operand (multiplicand).
        y: The second BigUInt operand (multiplier).
        start_x: The starting index of x to consider.
        end_x: The ending index of x to consider.
        start_y: The starting index of y to consider.
        end_y: The ending index of y to consider.
        cutoff_number_of_words: The cutoff number of words for using Karatsuba
            multiplication. If the number of words in either operand is less
            than or equal to this value, the school method is used instead.

    Returns:
        The product of the two BigUInt numbers.

    Notes:

    This function uses a technique to avoid making copies of x and y.
    We just need to consider the slices of x and y by using the indices.
    """

    # Number of words in the slice 1: end_x - start_x
    # Number of words in the slice 2: end_y - start_y
    var n_words_x_slice = end_x - start_x
    var n_words_y_slice = end_y - start_y

    # CASE 1:
    # If one number is only one-word long
    # we can use school multiplication because this is only one loop
    # No need to split the long number into two parts
    if n_words_x_slice == 1 or n_words_y_slice == 1:
        return multiply_slices(x, y, start_x, end_x, start_y, end_y)

    # CASE 2:
    # The allocation cost is too high for small numbers to use Karatsuba
    # Use school multiplication for small numbers
    var n_words_max = max(n_words_x_slice, n_words_y_slice)
    if n_words_max <= cutoff_number_of_words:
        # return multiply_slices (x, y)
        return multiply_slices(x, y, start_x, end_x, start_y, end_y)
        # multiply_slices can also takes in x, y, and indices

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
        z0 = multiply_karatsuba(
            x, y, start_x, end_x, start_y, start_y + m, cutoff_number_of_words
        )
        z1 = multiply_karatsuba(
            x, y, start_x, end_x, start_y + m, end_y, cutoff_number_of_words
        )
        # z2 = 0

        z1.scale_up_inplace_by_power_of_billion(m)
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
        z0 = multiply_karatsuba(
            x, y, start_x, start_x + m, start_y, end_y, cutoff_number_of_words
        )
        z1 = multiply_karatsuba(
            x, y, start_x + m, end_x, start_y, end_y, cutoff_number_of_words
        )
        # z2 = 0
        z1.scale_up_inplace_by_power_of_billion(m)
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

        # z0 = multiply_karatsuba(x0, y0)
        z0 = multiply_karatsuba(
            x,
            y,
            start_x,
            start_x + m,
            start_y,
            start_y + m,
            cutoff_number_of_words,
        )
        # z2 = multiply_karatsuba(x1, y1)
        z2 = multiply_karatsuba(
            x, y, start_x + m, end_x, start_y + m, end_y, cutoff_number_of_words
        )
        # z3 = multiply_karatsuba(x0 + x1, y0 + y1)
        # z1 = z3 - z2 -z0
        var x0_plus_x1 = add_slices(
            x, x, start_x, start_x + m, start_x + m, end_x
        )
        var y0_plus_y1 = add_slices(
            y, y, start_y, start_y + m, start_y + m, end_y
        )
        z1 = multiply_karatsuba(
            x0_plus_x1,
            y0_plus_y1,
            0,
            len(x0_plus_x1.words),
            0,
            len(y0_plus_y1.words),
            cutoff_number_of_words,
        )
        try:
            z1 -= z2
            z1 -= z0
        except e:
            print(
                (
                    "biguint.arithmetics.multiply_karatsuba(): Error in"
                    " subtraction"
                ),
                e,
            )
            print("z1:", z1)
            print("z2:", z2)
            print("z0:", z0)

        # z2*9^(m * 2) + z1*9^m + z0
        z2.scale_up_inplace_by_power_of_billion(2 * m)
        z1.scale_up_inplace_by_power_of_billion(m)
        z2 += z1
        z2 += z0

        return z2^


fn multiply_inplace_by_uint32(mut x: BigUInt, y: UInt32):
    """Multiplies a BigUInt by an UInt32 word in-place.

    Args:
        x: The BigUInt value to multiply.
        y: The single word to multiply by.
    """
    if y == 0:
        x.words = List[UInt32](0)
        return

    if y == 1:
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


fn scale_up_by_power_of_10(x: BigUInt, n: Int) -> BigUInt:
    """Multiplies a BigUInt by 10^n if n > 0, otherwise doing nothing.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.

    Returns:
        A new BigUInt containing the result of the multiplication.
    """
    if n <= 0:
        return x

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


fn scale_up_inplace_by_power_of_10(mut x: BigUInt, n: Int):
    """Multiplies a BigUInt in-place by 10^n if n > 0, otherwise doing nothing.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.
    """
    if n <= 0:
        return

    var number_of_zero_words = n // 9
    var number_of_remaining_digits = n % 9

    # SPECIAL CASE: If n is a multiple of 9
    if number_of_remaining_digits == 0:
        # If n is a multiple of 9, we just need to add zero words
        x.scale_up_inplace_by_power_of_billion(number_of_zero_words)
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


fn scale_up_inplace_by_power_of_billion(mut x: BigUInt, n: Int):
    """Multiplies a BigUInt in-place by (10^9)^n if n > 0.
    This equals to adding 9n zeros (n words) to the end of the number.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10^9 to multiply by. Should be non-negative.
    """

    if n <= 0:
        return  # No change needed

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
# floor_divide_general, floor_divide_inplace_by_2
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

    # CASE: division of very, very large numbers
    # Use Newton-Raphson division for large numbers?

    # CASE: all other situations
    # Normalize divisor to improve quotient estimation
    # Calculate normalization factor to make leading digit of divisor
    # as large as possible
    # I use table lookup to find the normalization factor
    var normalization_factor: Int  # Number of digits to shift
    var msw = x2.words[len(x2.words) - 1]
    if msw < 10_000:
        if msw < 100:
            if msw < 10:
                normalization_factor = 8  # Shift by 8 digits
            else:  # 10 <= msw < 100
                normalization_factor = 7  # Shift by 7 digits
        else:  # 100 <= msw < 10_000
            if msw < 1_000:  # 100 <= msw < 1_000
                normalization_factor = 6  # Shift by 6 digits
            else:  # 1_000 <= msw < 10_000:
                normalization_factor = 5  # Shift by 5 digits
    elif msw < 100_000_000:  # 10_000 <= msw < 100_000_000
        if msw < 1_000_000:
            if msw < 100_000:  # 10_000 <= msw < 100_000
                normalization_factor = 4  # Shift by 4 digits
            else:  # 100_000 <= msw < 1_000_000
                normalization_factor = 3  # Shift by 3 digits
        else:  # 1_000_000 <= msw < 100_000_000
            if msw < 10_000_000:  # 1_000_000 <= msw < 10_000_000
                normalization_factor = 2  # Shift by 2 digits
            else:  # 10_000_000 <= msw < 100_000_000
                normalization_factor = 1  # Shift by 1 digit
    else:  # 100_000_000 <= msw < 1_000_000_000
        normalization_factor = 0  # No shift needed

    if normalization_factor == 0:
        # No normalization needed, just use the general division algorithm
        return floor_divide_general(x1, x2)
    else:
        # Normalize the divisor and dividend
        var normalized_x1 = scale_up_by_power_of_10(x1, normalization_factor)
        var normalized_x2 = scale_up_by_power_of_10(x2, normalization_factor)
        return floor_divide_general(normalized_x1, normalized_x2)


fn floor_divide_general(dividend: BigUInt, divisor: BigUInt) raises -> BigUInt:
    """General division algorithm for BigInt numbers.

    Args:
        dividend: The dividend.
        divisor: The divisor.

    Returns:
        The quotient of dividend // divisor.

    Raises:
        Error: If the divisor is zero.
    """

    if divisor.is_zero():
        raise Error(
            "`biguint.arithmetics.floor_divide_general()`: Division by zero"
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
        scale_up_inplace_by_power_of_billion(trial_product, index_of_word)

        # Should need at most 1-2 corrections after the estimation
        # At most cases, no correction is needed
        # Add correction attempts counter to avoid infinite loop
        var correction_attempts = 0
        while (trial_product.compare(remainder) > 0) and (quotient > 0):
            quotient -= 1
            correction_attempts += 1

            trial_product = divisor
            multiply_inplace_by_uint32(trial_product, UInt32(quotient))
            scale_up_inplace_by_power_of_billion(trial_product, index_of_word)

            if correction_attempts > 3:
                print("correction attempts:", correction_attempts)
                break

        # Store the quotient word
        result.words[index_of_word] = UInt32(quotient)
        subtract_inplace(remainder, trial_product)
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
        return

    var carry: UInt32 = 0

    # Process from most significant to least significant word
    for ith in range(len(x.words) - 1, -1, -1):
        x.words[ith] += carry
        carry = BigUInt.BASE if (x.words[ith] & 1) else 0
        x.words[ith] >>= 1

    # Remove leading zeros
    while len(x.words) > 1 and x.words[len(x.words) - 1] == 0:
        x.words.resize(len(x.words) - 1, UInt32(0))


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
        raise Error("Error in `truncate_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
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
        raise Error("Error in `truncate_modulo`: Division by zero")

    # CASE: Dividend is zero
    if x1.is_zero():
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
        return BigUInt()  # No remainder
    else:
        return subtract(x2, remainder)


fn divmod(x1: BigUInt, x2: BigUInt) raises -> Tuple[BigUInt, BigUInt]:
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


fn scale_down_by_power_of_10(x: BigUInt, n: Int) raises -> BigUInt:
    """Floor divide a BigUInt by 10^n (n>=0).
    It is equal to removing the last n digits of the number.

    Args:
        x: The BigUInt value to multiply.
        n: The power of 10 to multiply by.

    Raises:
        Error: If n is negative.

    Returns:
        A new BigUInt containing the result of the multiplication.
    """
    if n < 0:
        raise Error(
            "biguint.arithmetics.scale_down_by_power_of_10(): "
            "n must be non-negative"
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


# ===----------------------------------------------------------------------=== #
# Division Helper Functions
# power_of_10
# ===----------------------------------------------------------------------=== #


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

    # Add trailing zeros for full power-of-billion words
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
