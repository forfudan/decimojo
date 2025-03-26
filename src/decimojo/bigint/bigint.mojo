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

from decimojo.biguint.biguint import BigUInt
import decimojo.bigint.arithmetics
import decimojo.bigint.comparison
import decimojo.str


@value
struct BigInt(Absable, IntableRaising, Writable):
    """Represents a base-10 arbitrary-precision signed integer.

    Notes:

    Internal Representation:

    - A base-10 unsigned integer (BigUInt) for magnitude.
    - A Bool value for the sign.
    """

    var magnitude: BigUInt
    """The magnitude of the BigInt."""
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
        self.magnitude = BigUInt()
        self.sign = False

    fn __init__(out self, empty: Bool, sign: Bool):
        """Initializes an empty BigInt.

        Args:
            empty: A Bool value indicating whether the BigInt is empty.
                If True, the BigInt is empty.
                If False, the BigInt is intialized with value 0.
            sign: The sign of the BigInt.
        """
        self.magnitude = BigUInt(empty=empty)
        self.sign = sign

    fn __init__(out self, empty: Bool, capacity: Int, sign: Bool):
        """Initializes an empty BigInt with a given capacity.

        Args:
            empty: A Bool value indicating whether the BigInt is empty.
                If True, the BigInt is empty.
                If False, the BigInt is intialized with value 0.
            capacity: The capacity of the BigInt.
            sign: The sign of the BigInt.
        """
        self.magnitude = BigUInt(empty=empty, capacity=capacity)
        self.sign = sign

    fn __init__(out self, magnitude: BigUInt, sign: Bool):
        """Initializes a BigInt from a BigUInt and a sign.

        Args:
            magnitude: The magnitude of the BigInt.
            sign: The sign of the BigInt.
        """

        self.magnitude = magnitude
        self.sign = sign

    fn __init__(out self, owned *words: UInt32, sign: Bool) raises:
        """Initializes a BigInt from raw components.
        See `from_words()` for safer initialization.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt.

        Notes:

        This method does not check whether the words are smaller than
        `999_999_999`.

        Example:
        ```console
        BigInt(123456789, 987654321, sign=False) # 987654321_123456789
        BigInt(123456789, 987654321, sign=True)  # -987654321_123456789
        ```

        End of examples.
        """
        self.sign = sign
        self.magnitude = BigUInt(empty=True, capacity=len(words))
        for word in words:
            self.magnitude.words.append(word[])

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
    # from_words(*words: UInt32, sign: Bool) -> Self
    # from_int(value: Int) -> Self
    # from_uint128(value: UInt128, sign: Bool = False) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_words(*words: UInt32, sign: Bool) raises -> Self:
        """Initializes a BigInt from raw words.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt.

        Notes:

        This method validates whether the words are smaller than `999_999_999`.
        """

        result = Self(empty=True, capacity=len(words), sign=sign)

        # Check if the words are valid
        for word in words:
            if word > Self.MAX_OF_WORD:
                raise Error(
                    "Error in `BigInt.__init__()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                result.magnitude.words.append(word)

        return result^

    @staticmethod
    fn from_int(value: Int) raises -> Self:
        """Creates a BigInt from an integer."""
        if value == 0:
            return Self()

        var result = Self(empty=True, sign=False)
        var remainder: Int
        var quotient: Int
        if value < 0:
            # Handle the case of Int.MIN due to asymmetry of Int.MIN and Int.MAX
            if value == Int.MIN:
                return Self(
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
            result.magnitude.words.append(UInt32(remainder))
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

        var result = Self(empty=True, sign=False)
        result.magnitude = BigUInt.from_uint128(value)
        result.sign = sign

        return result^

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
            return Self(UInt32(0), sign=False)

        var result = Self(empty=True, sign=False)
        result.magnitude = BigUInt.from_string(value, ignore_sign=True)
        result.sign = sign

        return result^

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

        if len(self.magnitude.words) > 3:
            raise Error(
                "Error in `BigInt.to_int()`: The number exceeds the size of Int"
            )

        var value: Int128 = 0
        for i in range(len(self.magnitude.words)):
            value += (
                Int128(self.magnitude.words[i]) * Int128(1_000_000_000) ** i
            )

        value = -value if self.sign else value

        if value < Int128(Int.MIN) or value > Int128(Int.MAX):
            raise Error(
                "Error in `BigInt.to_int()`: The number exceeds the size of Int"
            )

        return Int(value)

    fn to_str(self) -> String:
        """Returns string representation of the BigInt."""

        if self.magnitude.is_unitialized():
            return String("Unitilialized BigInt")

        if self.is_zero():
            return String("0")

        var result = String("-") if self.sign else String("")
        result += self.magnitude.to_str()

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

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.floor_divide(self, other)

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.floor_modulo(self, other)

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

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.floor_divide(self, other)

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.floor_modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn compare_absolute(self, other: Self) -> Int8:
        """Compares the absolute values of two BigInts.
        See `compare_absolute()` for more information.
        """
        return decimojo.bigint.comparison.compare_absolute(self, other)

    @always_inline
    fn floor_divide(self, other: Self) raises -> Self:
        """Performs a floor division of two BigInts.
        See `floor_divide()` for more information.
        """
        return decimojo.bigint.arithmetics.floor_divide(self, other)

    @always_inline
    fn truncate_divide(self, other: Self) raises -> Self:
        """Performs a truncated division of two BigInts.
        See `truncate_divide()` for more information.
        """
        return decimojo.bigint.arithmetics.truncate_divide(self, other)

    @always_inline
    fn floor_modulo(self, other: Self) raises -> Self:
        """Performs a floor modulo of two BigInts.
        See `floor_modulo()` for more information.
        """
        return decimojo.bigint.arithmetics.floor_modulo(self, other)

    @always_inline
    fn truncate_modulo(self, other: Self) raises -> Self:
        """Performs a truncated modulo of two BigInts.
        See `truncate_modulo()` for more information.
        """
        return decimojo.bigint.arithmetics.truncate_modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this BigInt represents zero."""
        return self.magnitude.is_zero()

    @always_inline
    fn is_one_or_minus_one(self) -> Bool:
        """Returns True if this BigInt represents one or negative one."""
        return self.magnitude.is_one()

    @always_inline
    fn is_negative(self) -> Bool:
        """Returns True if this BigInt is negative."""
        return self.sign

    fn is_abs_power_of_10(x: BigInt) -> Bool:
        """Check if abs(x) is a power of 10."""
        return x.magnitude.is_power_of_10()

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
        for i in range(len(value.magnitude.words)):
            print(
                "word",
                i,
                ":       ",
                String(value.magnitude.words[i]).rjust(width=9, fillchar="0"),
            )
        print("--------------------------------")
