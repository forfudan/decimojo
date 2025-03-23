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
import time

import decimojo.bigint.arithmetics
import decimojo.bigint.comparison
import decimojo.str


@value
struct BigInt(Absable, IntableRaising, Writable):
    """Represents an integer with arbitrary precision.

    Notes:

    Internal Representation:

    Use base-10^9 representation for the coefficient of the integer.
    Each integer uses a dynamic structure in memory, where:
    - An pointer to an array of UInt32 words for the coefficient on the heap,
        which can be of arbitrary length stored in little-endian order.
        Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
    - A Bool value for the sign.

    The value of the BigInt is calculated as follows:

    x = x[0] * 10^0 + x[1] * 10^9 + x[2] * 10^18 + ... x[n] * 10^(9n)
    """

    var words: List[UInt32]
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
    #
    # __init__(out self)
    # __init__(out self, empty: Bool)
    # __init__(out self, empty: Bool, capacity: Int)
    # __init__(out self, *words: UInt32, sign: Bool) raises
    # __init__(out self, value: Int) raises
    # __init__(out self, value: String) raises
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigInt with value 0."""
        self.words = List[UInt32](UInt32(0))
        self.sign = False

    fn __init__(out self, empty: Bool):
        """Initializes an empty BigInt.

        Args:
            empty: A Bool value indicating whether the BigInt is empty.
                If True, the BigInt is empty.
                If False, the BigInt is intialized with value 0.
        """
        self.words = List[UInt32]()
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
        self.words = List[UInt32](capacity=capacity)
        self.sign = False
        if not empty:
            self.words.append(UInt32(0))

    fn __init__(out self, *words: UInt32, sign: Bool) raises:
        """Initializes a BigInt from raw components.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt.

        Notes:

        This method checks whether the words are smaller than `999_999_999`.

        Example:
        ```console
        BigInt(123456789, 987654321, sign=False) # 987654321_123456789
        BigInt(123456789, 987654321, sign=True)  # -987654321_123456789
        ```

        End of examples.
        """
        self.words = List[UInt32](capacity=len(words))
        self.sign = sign

        # Check if the words are valid
        for word in words:
            if word > Self.MAX_OF_WORD:
                raise Error(
                    "Error in `BigInt.__init__()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                self.words.append(word)

    fn __init__(out self, value: Int) raises:
        """Initializes a BigInt from an Int.
        See `from_int()` for more information.
        """
        self = Self.from_int(value)

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
    #
    # from_raw_words(*words: UInt32, sign: Bool) -> Self
    # from_int(value: Int) -> Self
    # from_uint128(value: UInt128, sign: Bool = False) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_raw_words(*words: UInt32, sign: Bool) -> Self:
        """Initializes a BigInt from raw words without validating the words.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt.

        Notes:

        This method does not validate whether the words are smaller than
        `999_999_999`.
        """

        result = Self(empty=True, capacity=len(words))
        result.sign = sign
        for word in words:
            result.words.append(word)
        return result^

    @staticmethod
    fn from_int(value: Int) raises -> Self:
        """Creates a BigInt from an integer."""
        if value == 0:
            return Self()

        var result = Self(empty=True)
        var remainder: Int
        var quotient: Int
        if value < 0:
            # Handle the case of Int.MIN due to asymmetry of Int.MIN and Int.MAX
            if value == Int.MIN:
                return Self.from_raw_words(
                    UInt32(854775807), UInt32(223372036), UInt32(9), sign=True
                )
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
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigInt.

        Returns:
            The BigInt representation of the string.
        """
        var coef: List[UInt8]
        var scale: Int
        var sign: Bool
        coef, scale, sign = decimojo.str.parse_numeric_string(value)

        # Check if the number is zero
        if len(coef) == 1 and coef[0] == UInt8(0):
            return Self.from_raw_words(UInt32(0), sign=sign)

        # Check whether the number is an integer
        # If the fractional part is not zero, raise an error
        # If the fractional part is zero, remove the fractional part
        if scale > 0:
            if scale >= len(coef):
                raise Error(
                    "Error in `from_string`: The number is not an integer."
                )
            for i in range(1, scale + 1):
                if coef[-i] != 0:
                    raise Error(
                        "Error in `from_string`: The number is not an integer."
                    )
            coef.resize(-scale)
            scale = 0

        var number_of_digits = len(coef) - scale
        var number_of_words = number_of_digits // 9
        if number_of_digits % 9 != 0:
            number_of_words += 1

        var result = Self(empty=True, capacity=number_of_words)
        result.sign = sign

        if scale == 0:
            # This is a true integer
            var number_of_digits = len(coef)
            var number_of_words = number_of_digits // 9
            if number_of_digits % 9 != 0:
                number_of_words += 1

            var end: Int = number_of_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for digit in coef[start:end]:
                    word = word * 10 + UInt32(digit[])
                result.words.append(word)
                end = start
            if end > 0:
                var word: UInt32 = 0
                for digit in coef[0:end]:
                    word = word * 10 + UInt32(digit[])
                result.words.append(word)

            return result

        else:  # scale < 0
            # This is a true integer with postive exponent
            var number_of_trailing_zero_words = -scale // 9
            var remaining_trailing_zero_digits = -scale % 9

            for _ in range(number_of_trailing_zero_words):
                result.words.append(UInt32(0))

            for _ in range(remaining_trailing_zero_digits):
                coef.append(UInt8(0))

            var end: Int = number_of_digits + scale + remaining_trailing_zero_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for digit in coef[start:end]:
                    word = word * 10 + UInt32(digit[])
                result.words.append(word)
                end = start
            if end > 0:
                var word: UInt32 = 0
                for digit in coef[0:end]:
                    word = word * 10 + UInt32(digit[])
                result.words.append(word)

            return result

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __int__(self) raises -> Int:
        """Returns the number as Int.
        See `to_int()` for more information.
        """
        return self.to_int()

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

    fn to_int(self) raises -> Int:
        """Returns the number as Int.

        Returns:
            The number as Int.

        Raises:
            Error: If the number is too large or too small to fit in Int.
        """

        # 2^63-1 = 9_223_372_036_854_775_807
        # is larger than 10^18 -1 but smaller than 10^27 - 1

        if len(self.words) > 3:
            raise Error(
                "Error in `BigInt.to_int()`: The number exceeds the size of Int"
            )

        var value: Int128 = 0
        for i in range(len(self.words)):
            value += Int128(self.words[i]) * Int128(Self.BASE_OF_WORD) ** i

        value = -value if self.sign else value

        if value < Int128(Int.MIN) or value > Int128(Int.MAX):
            raise Error(
                "Error in `BigInt.to_int()`: The number exceeds the size of Int"
            )

        return Int(value)

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

    @always_inline
    fn __mul__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.multiply(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.add(self, other)

    @always_inline
    fn __isub__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.subtract(self, other)

    @always_inline
    fn __imul__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.multiply(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this BigInt represents zero."""
        return len(self.words) == 1 and self.words[0] == 0

    @always_inline
    fn is_one_or_minus_one(self) -> Bool:
        """Returns True if this BigInt represents one or negative one."""
        return len(self.words) == 1 and self.words[0] == 1

    @always_inline
    fn is_negative(self) -> Bool:
        """Returns True if this BigInt is negative."""
        return self.sign

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
