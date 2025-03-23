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

"""Implements basic object methods for the BigInt type.

This module contains the basic object methods for the BigInt type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer
import testing

import decimojo.str


@value
struct BigInt:
    """Represents an integer with arbitrary precision.

    Notes:

    Internal Representation:

    Use base-10^9 representation for the coefficient of the integer.
    Each integer uses a dynamic structure in memory, where:
    - An pointer to an array of UInt32 words for the coefficient on the heap,
        which can be of arbitrary length stored in little-endian order.
        Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
    - A Bool value for the sign.
    """

    # Internal representation fields
    alias _words_type = List[UInt32, hint_trivial_type=True]

    var words: Self._words_type
    """A list of UInt32 words representing the coefficient."""
    var sign: Bool
    """Sign information."""

    # ===------------------------------------------------------------------=== #
    # Constants
    # ===------------------------------------------------------------------=== #

    alias MAX_OF_WORD = UInt32(999_999_999)
    alias BASE_OF_WORD = UInt32(1_000_000_000)

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigInt with value 0."""
        self.words = Self._words_type(UInt32(0))
        self.sign = False

    fn __init__(out self, empty: Bool):
        """Initializes an empty BigInt.

        Args:
            empty: A Bool value indicating whether the BigInt is empty.
                If True, the BigInt is empty.
                If False, the BigInt is intialized with value 0.
        """
        self.words = Self._words_type()
        self.sign = False
        if not empty:
            self.words.append(UInt32(0))

    fn __init__(out self, empty: Bool, capacity: Int):
        """Initializes an empty BigInt with a given capacity.

        Args:
            empty: A Bool value indicating whether the BigInt is empty.
                If True, the BigInt is empty.
                If False, the BigInt is intialized with value 0.
            capacity: The capacity of the BigInt.
        """
        self.words = Self._words_type(capacity=capacity)
        self.sign = False
        if not empty:
            self.words.append(UInt32(0))

    fn __init__(out self, *words: UInt32, sign: Bool) raises:
        """Initializes a BigInt from raw components.

        Notes:

        This method checks whether the words are smaller than `999_999_999`.
        """
        self.words = Self._words_type()
        self.sign = sign

        # Check if the words are valid
        for word in words:
            if word > Self.MAX_OF_WORD:
                raise Error(
                    "Error in `from_components`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                self.words.append(word)

    fn __init__(out self, value: String) raises:
        """Initializes a BigInt from a string representation.
        See `from_string()` for more information.
        """
        try:
            self = Self.from_string(value)
        except e:
            raise Error("Error in `BigInt.__init__()` with String: ", e)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_components(*words: UInt32, sign: Bool = False) raises -> Self:
        """Creates a BigInt from raw components.

        Notes:

        Compare to `BigInt.__init__()`, this method checks the validity of words
        by checking if the words are smaller than `999_999_999`.
        """

        var result = Self(empty=True)
        result.sign = sign

        # Check if the words are valid
        for word in words:
            if word > Self.MAX_OF_WORD:
                raise Error(
                    "Error in `from_components`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                result.words.append(word)

        return result

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Creates a BigInt from an integer."""
        if value == 0:
            return Self()

        var result = Self(empty=True)

        var remainder: Int
        var quotient: Int
        if value < 0:
            result.sign = True
            remainder = -value
        else:
            result.sign = False
            remainder = value

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            result.words.append(UInt32(remainder))
            remainder = quotient

        return result

    @staticmethod
    fn from_uint128(value: UInt128, sign: Bool = False) -> Self:
        """Initializes a BigInt from a UInt128 value.

        Args:
            value: The UInt128 value to be converted to BigInt.
            sign: The sign of the BigInt. Default is False.

        Returns:
            The BigInt representation of the UInt128 value.
        """
        if value == 0:
            return Self()

        var result = Self(empty=True)
        result.sign = False

        var remainder: UInt128 = value
        var quotient: UInt128
        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            result.words.append(UInt32(remainder))
            remainder = quotient

        return result

    @staticmethod
    fn from_string(value: String) raises -> BigInt:
        """Initializes a BigInt from a string representation.
        The string is normalized with `deciomojo.str.parse_string_of_number()`.

        Args:
            value: The string representation of the BigInt.

        Returns:
            The BigInt representation of the string.
        """

        var coef_string: String
        var scale: Int
        var sign: Bool
        coef_string, scale, sign = decimojo.str.parse_string_of_number(value)

        # Check if the number is zero
        if coef_string == "0":
            return Self()

        # Check whether the number is an integer
        # If the fractional part is not zero, raise an error
        # If the fractional part is zero, remove the fractional part
        if scale > 0:
            if scale >= len(coef_string):
                raise Error(
                    "Error in `from_string`: The number is not an integer."
                )
            for i in range(1, scale + 1):
                if coef_string[-i] != "0":
                    raise Error(
                        "Error in `from_string`: The number is not an integer."
                    )
            coef_string = coef_string[:-scale]
            scale = 0

        var number_of_digits = len(coef_string) - scale
        var number_of_words = number_of_digits // 9
        if number_of_digits % 9 != 0:
            number_of_words += 1

        var result = Self(empty=True, capacity=number_of_words)
        result.sign = sign

        if scale == 0:
            # This is a true integer
            var number_of_digits = len(coef_string)
            var number_of_words = number_of_digits // 9
            if number_of_digits % 9 != 0:
                number_of_words += 1

            var result = Self(empty=True, capacity=number_of_words)
            result.sign = sign

            var end: Int = number_of_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word = UInt32(Int(coef_string[start:end]))
                result.words.append(word)
                end = start
            if end > 0:
                var word = UInt32(Int(coef_string[0:end]))
                result.words.append(word)

            return result

        else:  # scale < 0
            # This is a true integer with postive exponent
            var number_of_trailing_zero_words = -scale // 9
            var remaining_trailing_zero_digits = -scale % 9

            for _ in range(number_of_trailing_zero_words):
                result.words.append(UInt32(0))

            coef_string += "0" * remaining_trailing_zero_digits

            var end: Int = number_of_digits + scale + remaining_trailing_zero_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word = UInt32(Int(coef_string[start:end]))
                result.words.append(word)
                end = start
            if end > 0:
                var word = UInt32(Int(coef_string[0:end]))
                result.words.append(word)

            return result

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __str__(self) -> String:
        """Returns string representation of the BigInt.
        See `to_str()` for more information.
        """
        return self.to_str()

    fn __repr__(self) -> String:
        """Returns a string representation of the BigInt."""
        return 'BigInt("' + self.__str__() + '")'

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the BigInt to a writer.
        This implement the `write` method of the `Writer` trait.
        """
        writer.write(String(self))

    fn to_str(self) -> String:
        """Returns string representation of the BigInt."""

        if len(self.words) == 0:
            return String("Unitilialized BigInt")

        var result = String("-") if self.sign else String("")

        for i in range(len(self.words) - 1, -1, -1):
            if i == len(self.words) - 1:
                result = result + String(self.words[i])
            else:
                result = result + String(self.words[i]).rjust(
                    width=9, fillchar="0"
                )

        return result^

    fn to_str_with_separators(self, separator: String = "_") -> String:
        """Returns string representation of the BigInt with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigInt with separators.
        """

        var result = self.to_str()
        var end = len(result)
        var start = end - 3
        while start > 0:
            result = result[:start] + separator + result[start:]
            end = start
            start = end - 3

        return result^

    # ===------------------------------------------------------------------=== #
    # Basic unary operation dunders
    # neg
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __abs__(self) -> Self:
        """Returns the absolute value of this number.
        See `absolute()` for more information.
        """
        return decimojo.bigint.arithmetics.absolute(self)

    @always_inline
    fn __neg__(self) -> Self:
        """Returns the negation of this number.
        See `negative()` for more information.
        """
        return decimojo.bigint.arithmetics.negative(self)

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.subtract(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this BigInt represents zero."""
        return len(self.words) == 1 and self.words[0] == 0

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn internal_representation(value: BigInt):
        """Prints the internal representation details of a BigInt."""
        print("\nInternal Representation Details of BigInt")
        print("-----------------------------------------")
        print("number:        ", value)
        print("               ", value.to_str_with_separators())
        print("negative:      ", value.sign)
        for i in range(len(value.words)):
            print(
                "word",
                i,
                ":       ",
                String(value.words[i]).rjust(width=9, fillchar="0"),
            )
        print("--------------------------------")
