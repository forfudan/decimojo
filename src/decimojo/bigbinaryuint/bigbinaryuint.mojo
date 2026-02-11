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

"""Implements basic object methods for the big binary unsigned integer type.

This module contains the basic object methods for the BigBinaryUInt type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer, memcpy

from decimojo.biguint.biguint import BigUInt

# Type aliases
comptime BBUInt = BigBinaryUInt
"""A shorter comptime for BigBinaryUInt, an arbitrary-precision binary unsigned 
integer."""
comptime bbuint = BigBinaryUInt
"""A shortcut constructor for BigBinaryUInt, an arbitrary-precision binary 
unsigned integer."""


struct BigBinaryUInt(Copyable, Movable, Stringable, Writable):
    """Represents an arbitrary-precision binary unsigned integer.

    Notes:

    Internal Representation:

    Use base-2^30 representation for the unsigned integer.
    BigBinaryUInt uses a dynamic structure in memory, which contains:
    An pointer to an array of UInt32 words for the coefficient on the heap,
    which can be of arbitrary length stored in little-endian order.
    Each UInt32 word represents values ranging from 0 to 2^30 - 1.

    The value of the BigBinaryUInt is calculated as follows:

    (x[0] + x[1] * (2^30)^1 + x[2] * (2^30)^2 + ... x[n] * (2^30)^n)

    You can think of the BigBinaryUInt as a list of base-2^30 digits, where each
    digit is ranging from 0 to 1073741823. Depending on the context, the
    following terms are used interchangeably:
    (1) words,
    (2) limbs,
    (3) base-2^30 digits.
    """

    var words: List[UInt32]
    """A list of UInt32 words representing the coefficient."""

    # ===------------------------------------------------------------------=== #
    # Constants
    # ===------------------------------------------------------------------=== #

    comptime BASE = 1 << 30  # 2^30 = 1073741824
    """The base used for the BigBinaryInt representation."""
    comptime BASE_MAX = (1 << 30) - 1  # 2^30 - 1 = 1073741823
    """The maximum value of a single word in the BigBinaryInt representation."""
    comptime BASE_HALF = 1 << 29  # 2^29 = 536870912
    """Half of the base used for the BigBinaryInt representation."""
    comptime VECTOR_WIDTH = 4
    """The width of the SIMD vector used for arithmetic operations (128-bit)."""

    comptime ZERO = Self.zero()
    comptime ONE = Self.one()
    comptime MAX_UINT64 = (1 << 64) - 1
    comptime MAX_UINT128 = (1 << 128) - 1
    comptime MASK = (1 << 30) - 1
    """The mask used to extract the lower 30 bits of a word."""

    @always_inline
    @staticmethod
    fn zero() -> Self:
        """Returns a BigUInt with value 0."""
        return Self()

    @always_inline
    @staticmethod
    fn one() -> Self:
        """Returns a BigUInt with value 1."""
        return Self(words=[UInt32(1)])

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigBinaryInt with value 0."""
        self.words = [UInt32(0)]

    fn __init__(out self, *, uninitialized_capacity: Int):
        """Creates an uninitialized BigBinaryInt with a given capacity."""
        self.words = List[UInt32](capacity=uninitialized_capacity)

    fn __init__(out self, var words: List[UInt32]):
        """Initializes a BigBinaryInt from a list of UInt32 words.
        It does not verify whether the words are within the valid range.
        See `from_list()` for safer initialization.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents values ranging from 0 to 2^30 - 1.
                The words are stored in little-endian order.

        Notes:
            This method does not check whether the words are smaller than 2^30 - 1.
        """
        if len(words) == 0:
            self.words = [UInt32(0)]
        else:
            self.words = words^

    fn __init__(out self, var *words: UInt32):
        """Initializes a BigBinaryInt from raw words without validating the words.
        See `from_words()` for safer initialization.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents values ranging from 0 to 2^30 - 1.
                The words are stored in little-endian order.

        Notes:
            This method does not check whether the words are smaller than 2^30 - 1.
        """
        self.words = List[UInt32](elements=words^)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_list(var words: List[UInt32]) raises -> Self:
        """Initializes a BigBinaryInt from a list of UInt32 words safely.
        If the list is empty, the BigBinaryInt is initialized with value 0.
        The words are validated to ensure they are smaller than 2^30.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents values ranging from 0 to 2^30 - 1.
                The words are stored in little-endian order.

        Returns:
            The BigBinaryInt representation of the list of UInt32 words.
        """
        # Return 0 if the list is empty
        if len(words) == 0:
            return Self()

        # Check if the words are valid
        for word in words:
            if word >= Self.BASE:
                raise Error(
                    "Error in `BigBinaryInt.from_list()`: Word value exceeds"
                    " maximum value of 2^30 - 1"
                )

        return Self(words^)

    @staticmethod
    fn from_biguint(value: BigUInt) -> Self:
        """Initializes a binary unsigned integer from a decimal unsigned integer.
        """
        # Convert from base 10^9 to base 20^30 using repeated division
        # No extra words are needed, as the maximum number of words is N.
        var dividend = value.copy()
        var result = Self(uninitialized_capacity=len(value.words))
        var remainder: UInt64

        while not dividend.is_zero():
            # Repeat division by 2^30
            # The number of iterations is close to the number of words
            # After each iteration, the dividend is reduced by one word
            # So the complexity is O(N^2)
            remainder = 0
            for i in range(len(dividend.words) - 1, -1, -1):
                # Process from most significant to least significant word
                var temp = remainder * UInt64(value.BASE) + UInt64(
                    dividend.words[i]
                )
                dividend.words[i] = UInt32(temp // Self.BASE)
                remainder = temp % Self.BASE

            # Remove leading zeros
            while len(dividend.words) > 1 and dividend.words[-1] == 0:
                dividend.words.shrink(len(dividend.words) - 1)

            result.words.append(UInt32(remainder))

        return result^

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __str__(self) -> String:
        """Returns secimal string representation of the BigBinaryUInt.
        See `to_decimal_string()` for more information.
        """
        return self.to_decimal_string()

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn to_biguint(self) -> BigUInt:
        """Converts the binary integer to a decimal integer.

        Returns:
            The BigUInt representation of the BigBinaryInt.
        """
        # Convert from base 2^30 to base 10^9 using repeated division
        # log2(10^9) = 29.897
        # Max words in base 10^9 is ⌈(30 × N) / 29.897⌉ ≈ ⌈1.00345 × N⌉
        # 1 extra word is okay for most cases
        var dividend = self.copy()
        var result = BigUInt(uninitialized_capacity=len(self.words) + 1)
        var remainder: UInt64

        while not dividend.is_zero():
            # Repeat division by 10^9
            # The number of iterations is close to the number of words
            # After each iteration, the dividend is reduced by one word
            # So the complexity is O(N^2)
            remainder = 0
            for i in range(len(dividend.words) - 1, -1, -1):
                # Process from most significant to least significant word
                var temp = remainder * UInt64(Self.BASE) + UInt64(
                    dividend.words[i]
                )
                dividend.words[i] = UInt32(temp // BigUInt.BASE)
                remainder = temp % BigUInt.BASE

            # Remove leading zeros
            while len(dividend.words) > 1 and dividend.words[-1] == 0:
                dividend.words.shrink(len(dividend.words) - 1)

            result.words.append(UInt32(remainder))

        return result^

    fn to_binary_string(self) -> String:
        """Converts the BigBinaryInt to a binary string representation."""
        # Handle zero case
        if len(self.words) == 1 and self.words[0] == 0:
            return "0b0"

        var result = String("0b")
        var first_word = True

        # Process words from most significant to least significant
        for i in range(len(self.words) - 1, -1, -1):
            var word = self.words[i]

            if first_word:
                # For the first (most significant) word, don't include leading zeros
                if word != 0:
                    result += bin(word & self.MASK)[2:]
                    first_word = False
            else:
                # For subsequent words, pad to 30 bits
                result += bin(word & self.MASK)[2:].rjust(30, "0")

        return result

    fn to_decimal_string(self) -> String:
        """Converts the BigBinaryInt to a decimal string representation.

        Returns:
            The decimal string representation of the BigBinaryInt.

        Notes:

        This method first converts the BigBinaryInt to a BigUInt and then
        converts it to a decimal string representation.
        """
        # Handle zero case
        if self.is_zero():
            return "0"

        # # Convert from base 2^30 to base 10^9 using repeated division
        # var new_words: List[UInt32] = self.words
        # var result = BigUInt(uninitialized_capacity=len(self.words))

        # # Repeated division by 10^9
        # while not self.is_zero(new_words):
        #     var remainder = self.divide_inplace_by_billion_inplace(new_words)
        #     result.words.append(remainder)

        return String(self.to_biguint())

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    fn print_internal_representation(self):
        """Prints the internal representation details of a BigUInt."""
        var string_of_number = (
            self.to_biguint().to_string(line_width=32).split("\n")
        )
        print("\nInternal Representation Details of BigBinaryUInt")
        print("------------------------------------------------")
        print("number:         ", end="")
        for i in range(0, len(string_of_number)):
            if i > 0:
                print(" " * 16, end="")
            print(string_of_number[i])
        for i in range(len(self.words)):
            var ndigits = 1
            if i < 10:
                pass
            elif i < 100:
                ndigits = 2
            else:
                ndigits = 3
            print(
                "word ",
                i,
                ":",
                " " * (10 - ndigits),
                "0b",
                bin(self.words[i])[2:].rjust(30, fillchar="0"),
                sep="",
            )
        print("----------------------------------------------")

    @always_inline
    fn is_zero(self) -> Bool:
        """Checks if the word array represents zero."""
        if len(self.words) == 1 and self.words[0] == 0:
            return True
        else:
            for word in self.words:
                if word != 0:
                    return False
            else:
                return True
