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

"""Implements basic object methods for the BigUInt type.

This module contains the basic object methods for the BigUInt type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer
import testing
import time

import decimojo.biguint.arithmetics
import decimojo.biguint.comparison
import decimojo.str


@value
struct BigUInt(Absable, IntableRaising, Writable):
    """Represents an unsigned integer with arbitrary length.

    Notes:

    Internal Representation:

    Use base-10^9 representation for the unsigned integer.
    BigUInt uses a dynamic structure in memory, which contains:
    An pointer to an array of UInt32 words for the coefficient on the heap,
    which can be of arbitrary length stored in little-endian order.
    Each UInt32 word represents digits ranging from 0 to 10^9 - 1.

    The value of the BigUInt is calculated as follows:

    x = x[0] * 10^0 + x[1] * 10^9 + x[2] * 10^18 + ... x[n] * 10^(9n)
    """

    var words: List[UInt32]
    """A list of UInt32 words representing the coefficient."""

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
    # __init__(out self, *words: UInt32) raises
    # __init__(out self, value: Int) raises
    # __init__(out self, value: String) raises
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigUInt with value 0."""
        self.words = List[UInt32](UInt32(0))

    fn __init__(out self, empty: Bool):
        """Initializes an empty BigUInt.

        Args:
            empty: A Bool value indicating whether the BigUInt is empty.
                If True, the BigUInt is empty.
                If False, the BigUInt is intialized with value 0.
        """
        self.words = List[UInt32]()
        if not empty:
            self.words.append(UInt32(0))

    fn __init__(out self, empty: Bool, capacity: Int):
        """Initializes an empty BigUInt with a given capacity.

        Args:
            empty: A Bool value indicating whether the BigUInt is empty.
                If True, the BigUInt is empty.
                If False, the BigUInt is intialized with value 0.
            capacity: The capacity of the BigUInt.
        """
        self.words = List[UInt32](capacity=capacity)
        if not empty:
            self.words.append(UInt32(0))

    fn __init__(out self, owned *words: UInt32):
        """Initializes a BigUInt from raw words without validating the words.
        See `from_words()` for safer initialization.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Notes:

        This method does not check whether the words are smaller than
        `999_999_999`.

        Example:
        ```console
        BigUInt(123456789, 987654321) # 987654321_123456789
        ```
        End of examples.
        """
        self.words = List[UInt32](elements=words^)

    fn __init__(out self, value: Int) raises:
        """Initializes a BigUInt from an Int.
        See `from_int()` for more information.
        """
        self = Self.from_int(value)

    fn __init__(out self, value: String) raises:
        """Initializes a BigUInt from a string representation.
        See `from_string()` for more information.
        """
        self = Self.from_string(value)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    #
    # from_words(*words: UInt32) -> Self
    # from_int(value: Int) -> Self
    # from_uint128(value: UInt128) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_words(*words: UInt32) raises -> Self:
        """Initializes a BigUInt from raw words.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Notes:

        This method validates whether the words are smaller than `999_999_999`.

        Example:
        ```console
        BigUInt.from_words(123456789, 987654321) # 987654321_123456789
        ```
        End of examples.
        """

        result = Self(empty=True, capacity=len(words))

        # Check if the words are valid
        for word in words:
            if word > Self.MAX_OF_WORD:
                raise Error(
                    "Error in `BigUInt.__init__()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                result.words.append(word)

        return result^

    @staticmethod
    fn from_int(value: Int) raises -> Self:
        """Creates a BigUInt from an integer."""
        if value == 0:
            return Self()

        if value < 0:
            raise Error("Error in `from_int()`: The value is negative")

        var result = Self(empty=True)
        var remainder: Int = value
        var quotient: Int

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            result.words.append(UInt32(remainder))
            remainder = quotient

        return result^

    @staticmethod
    fn from_uint64(value: UInt64) raises -> Self:
        """Initializes a BigUInt from an UInt64.

        Args:
            value: The UInt64 value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the UInt64 value.
        """
        if value == 0:
            return Self()

        var result = Self(empty=True)
        var remainder: UInt64 = value
        var quotient: UInt64
        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            result.words.append(UInt32(remainder))
            remainder = quotient

        return result^

    @staticmethod
    fn from_uint128(value: UInt128) -> Self:
        """Initializes a BigUInt from a UInt128 value.

        Args:
            value: The UInt128 value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the UInt128 value.
        """
        if value == 0:
            return Self()

        var result = Self(empty=True)
        var remainder: UInt128 = value
        var quotient: UInt128
        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            result.words.append(UInt32(remainder))
            remainder = quotient

        return result^

    @staticmethod
    fn from_uint256(value: UInt256) -> Self:
        """Initializes a BigUInt from a UInt256 value.

        Args:
            value: The UInt256 value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the UInt256 value.
        """
        if value == 0:
            return Self()

        var result = Self(empty=True)
        var remainder: UInt256 = value
        var quotient: UInt256
        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            result.words.append(UInt32(remainder))
            remainder = quotient

        return result^

    @staticmethod
    fn from_string(value: String) raises -> BigUInt:
        """Initializes a BigUInt from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigUInt.

        Returns:
            The BigUInt representation of the string.
        """
        var coef: List[UInt8]
        var scale: Int
        var sign: Bool
        coef, scale, sign = decimojo.str.parse_numeric_string(value)

        if sign:
            raise Error("Error in `from_string()`: The value is negative")

        # Check if the number is zero
        if len(coef) == 1 and coef[0] == UInt8(0):
            return Self()

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
        """Returns string representation of the BigUInt.
        See `to_str()` for more information.
        """
        return self.to_str()

    fn __repr__(self) -> String:
        """Returns a string representation of the BigUInt."""
        return 'BigUInt("' + self.__str__() + '")'

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the BigUInt to a writer.
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
                "Error in `BigUInt.to_int()`: The number exceeds the size"
                " of Int"
            )

        var value: Int128 = 0
        for i in range(len(self.words)):
            value += Int128(self.words[i]) * Int128(Self.BASE_OF_WORD) ** i

        if value > Int128(Int.MAX):
            raise Error(
                "Error in `BigUInt.to_int()`: The number exceeds the size"
                " of Int"
            )

        return Int(value)

    fn to_uint64(self) raises -> UInt64:
        """Returns the number as UInt64.

        Returns:
            The number as UInt64.

        Raises:
            Error: If the number is too large or too small to fit in Int.
        """

        if len(self.words) > 3:
            raise Error(
                "Error in `BigUInt.to_int()`: The number exceeds the size"
                " of UInt64"
            )

        var value: UInt128 = 0
        for i in range(len(self.words)):
            value += UInt128(self.words[i]) * UInt128(Self.BASE_OF_WORD) ** i

        if value > UInt128(UInt64.MAX):
            raise Error(
                "Error in `BigUInt.to_uint64()`: The number exceeds the size"
                " of UInt64"
            )

        return UInt64(value)

    fn to_str(self) -> String:
        """Returns string representation of the BigUInt."""

        if len(self.words) == 0:
            return String("Unitilialized BigUInt")

        if self.is_zero():
            return String("0")

        var result = String("")

        for i in range(len(self.words) - 1, -1, -1):
            if i == len(self.words) - 1:
                result += String(self.words[i])
            else:
                result += String(self.words[i]).rjust(width=9, fillchar="0")

        return result^

    fn to_str_with_separators(self, separator: String = "_") -> String:
        """Returns string representation of the BigUInt with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigUInt with separators.
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
        return decimojo.biguint.arithmetics.absolute(self)

    @always_inline
    fn __neg__(self) raises -> Self:
        """Returns the negation of this number.
        See `negative()` for more information.
        """
        return decimojo.biguint.arithmetics.negative(self)

    @always_inline
    fn __rshift__(self, shift_amount: Int) raises -> Self:
        """Returns the result of floored divison by 2 to the power of `shift_amount`.
        """
        var result = self
        for _ in range(shift_amount):
            decimojo.biguint.arithmetics.floor_divide_inplace_by_2(result)
        return result^

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.subtract(self, other)

    @always_inline
    fn __mul__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.multiply(self, other)

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.floor_divide(self, other)

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        return decimojo.biguint.arithmetics.modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.add(self, other)

    @always_inline
    fn __isub__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.subtract(self, other)

    @always_inline
    fn __imul__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.multiply(self, other)

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.floor_divide(self, other)

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        self = decimojo.biguint.arithmetics.modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn compare(self, other: Self) -> Int8:
        """Compares the magnitudes of two BigUInts.
        See `compare()` for more information.
        """
        return decimojo.biguint.comparison.compare(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this BigUInt represents zero."""
        return len(self.words) == 1 and self.words[0] == 0

    @always_inline
    fn is_one(self) -> Bool:
        """Returns True if this BigUInt represents one."""
        return len(self.words) == 1 and self.words[0] == 1

    @always_inline
    fn is_two(self) -> Bool:
        """Returns True if this BigUInt represents two."""
        return len(self.words) == 1 and self.words[0] == 2

    fn is_abs_power_of_10(x: BigUInt) -> Bool:
        """Check if abs(x) is a power of 10."""
        for i in range(len(x.words) - 1):
            if x.words[i] != 0:
                return False
        var word = x.words[len(x.words) - 1]
        if (
            (word == 1)
            or (word == 10)
            or (word == 100)
            or (word == 1000)
            or (word == 10_000)
            or (word == 100_000)
            or (word == 1_000_000)
            or (word == 10_000_000)
            or (word == 100_000_000)
        ):
            return True
        return False

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn internal_representation(value: BigUInt):
        """Prints the internal representation details of a BigUInt."""
        print("\nInternal Representation Details of BigUInt")
        print("-----------------------------------------")
        print("number:        ", value)
        print("               ", value.to_str_with_separators())
        for i in range(len(value.words)):
            print(
                "word",
                i,
                ":       ",
                String(value.words[i]).rjust(width=9, fillchar="0"),
            )
        print("--------------------------------")

    fn remove_trailing_zeros(mut number: BigUInt):
        """Removes trailing zeros from the BigUInt."""
        while len(number.words) > 1 and number.words[-1] == 0:
            number.words.resize(len(number.words) - 1)
