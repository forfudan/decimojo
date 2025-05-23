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

# Type aliases
alias BUInt = BigUInt


@value
struct BigUInt(Absable, IntableRaising, Writable):
    """Represents a base-10 arbitrary-precision unsigned integer.

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

    alias ZERO = Self.zero()
    alias ONE = Self.one()

    @always_inline
    @staticmethod
    fn zero() -> Self:
        """Returns a BigUInt with value 0."""
        return Self(words=List[UInt32](UInt32(0)))

    @always_inline
    @staticmethod
    fn one() -> Self:
        """Returns a BigUInt with value 1."""
        return Self(words=List[UInt32](UInt32(1)))

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

    fn __init__(out self, owned words: List[UInt32]):
        """Initializes a BigUInt from a list of UInt32 words.
        It does not check whether the list is empty or the words are invalid.
        See `from_list()` for safer initialization.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Notes:

        This method does not check whether
        (1) the list is empty.
        (2) the words are smaller than `999_999_999`.
        """
        self.words = words^

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

    fn __init__(out self, value: Scalar) raises:
        """Initializes a BigUInt from a Mojo Scalar.
        See `from_scalar()` for more information.
        """
        self = Self.from_scalar(value)

    fn __init__(out self, value: String, ignore_sign: Bool = False) raises:
        """Initializes a BigUInt from a string representation.
        See `from_string()` for more information.
        """
        self = Self.from_string(value, ignore_sign=ignore_sign)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    #
    # from_list(owned words: List[UInt32]) -> Self
    # from_words(*words: UInt32) -> Self
    # from_int(value: Int) -> Self
    # from_scalar[dtype: DType](value: Scalar[dtype]) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_list(owned words: List[UInt32]) raises -> Self:
        """Initializes a BigUInt from a list of UInt32 words safely.
        If the list is empty, the BigUInt is initialized with value 0.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.

        Returns:
            The BigUInt representation of the list of UInt32 words.
        """
        # Return 0 if the list is empty
        if len(words) == 0:
            return Self()

        # Check if the words are valid
        for word in words:
            if word[] > UInt32(999_999_999):
                raise Error(
                    "Error in `BigUInt.from_list()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )

        return Self(words^)

    @staticmethod
    fn from_words(*words: UInt32) raises -> Self:
        """Initializes a BigUInt from raw words safely.

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

        var list_of_words = List[UInt32](capacity=len(words))

        # Check if the words are valid
        for word in words:
            if word > UInt32(999_999_999):
                raise Error(
                    "Error in `BigUInt.__init__()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                list_of_words.append(word)

        return Self(list_of_words^)

    @staticmethod
    fn from_int(value: Int) raises -> Self:
        """Creates a BigUInt from an integer."""
        if value == 0:
            return Self()

        if value < 0:
            raise Error("Error in `BigUInt.from_int()`: The value is negative")

        var list_of_words = List[UInt32]()
        var remainder: Int = value
        var quotient: Int

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            list_of_words.append(UInt32(remainder))
            remainder = quotient

        return Self(list_of_words^)

    @staticmethod
    fn from_scalar[dtype: DType, //](value: Scalar[dtype]) raises -> Self:
        """Initializes a BigUInt from a Mojo Scalar.

        Args:
            value: The Scalar value to be converted to BigUInt.

        Returns:
            The BigUInt representation of the Scalar value.

        Notes:
            If the value is a floating-point number, it is converted to a string
            with full precision before converting to BigUInt.
            If the fractional part is not zero, an error is raised.
        """
        if value < 0:
            raise Error("Error in `from_scalar()`: The value is negative")

        if value == 0:
            return Self()

        @parameter
        if dtype.is_integral():
            var list_of_words = List[UInt32]()
            var remainder: Scalar[dtype] = value
            var quotient: Scalar[dtype]
            while remainder != 0:
                quotient = remainder // 1_000_000_000
                remainder = remainder % 1_000_000_000
                list_of_words.append(UInt32(remainder))
                remainder = quotient
            return Self(list_of_words^)

        else:
            if value != value:  # Check for NaN
                raise Error(
                    "Error in `BigUInt.from_scalar()`: Cannot convert NaN to"
                    " BigUInt"
                )
            # Convert to string with full precision
            try:
                return Self.from_string(String(value))
            except e:
                raise Error("Error in `BigUInt.from_scalar()`: ", e)

        return Self()

    @staticmethod
    fn from_string(value: String, ignore_sign: Bool = False) raises -> BigUInt:
        """Initializes a BigUInt from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigUInt.
            ignore_sign: A Bool value indicating whether to ignore the sign.
                If True, the sign is ignored.
                If False, the sign is considered.

        Returns:
            The BigUInt representation of the string.
        """
        var coef: List[UInt8]
        var scale: Int
        var sign: Bool
        coef, scale, sign = decimojo.str.parse_numeric_string(value)

        if (not ignore_sign) and sign:
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
            coef.resize(len(coef) - scale, UInt8(0))
            scale = 0

        var number_of_digits = len(coef) - scale
        var number_of_words = number_of_digits // 9
        if number_of_digits % 9 != 0:
            number_of_words += 1

        var result_words = List[UInt32](capacity=number_of_words)

        if scale == 0:
            # This is a true integer
            var end: Int = number_of_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for digit in coef[start:end]:
                    word = word * 10 + UInt32(digit[])
                result_words.append(word)
                end = start
            if end > 0:
                var word: UInt32 = 0
                for digit in coef[0:end]:
                    word = word * 10 + UInt32(digit[])
                result_words.append(word)

            return Self(result_words^)

        else:  # scale < 0
            # This is a true integer with postive exponent
            var number_of_trailing_zero_words = -scale // 9
            var remaining_trailing_zero_digits = -scale % 9

            for _ in range(number_of_trailing_zero_words):
                result_words.append(UInt32(0))

            for _ in range(remaining_trailing_zero_digits):
                coef.append(UInt8(0))

            var end: Int = number_of_digits + scale + remaining_trailing_zero_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for digit in coef[start:end]:
                    word = word * 10 + UInt32(digit[])
                result_words.append(word)
                end = start
            if end > 0:
                var word: UInt32 = 0
                for digit in coef[0:end]:
                    word = word * 10 + UInt32(digit[])
                result_words.append(word)

            return Self(result_words^)

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
        See `to_string()` for more information.
        """
        return self.to_string()

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
            value += Int128(self.words[i]) * Int128(1_000_000_000) ** i

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
            value += UInt128(self.words[i]) * UInt128(1_000_000_000) ** i

        if value > UInt128(UInt64.MAX):
            raise Error(
                "Error in `BigUInt.to_uint64()`: The number exceeds the size"
                " of UInt64"
            )

        return UInt64(value)

    fn to_string(self, line_width: Int = 0) -> String:
        """Returns string representation of the BigUInt.

        Args:
            line_width: The width of each line. Default is 0, which means no
                line width.

        Returns:
            The string representation of the BigUInt.
        """

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

        if line_width > 0:
            var start = 0
            var end = line_width
            var lines = List[String](capacity=len(result) // line_width + 1)
            while end < len(result):
                lines.append(result[start:end])
                start = end
                end += line_width
            lines.append(result[start:])
            result = String("\n").join(lines^)

        return result^

    fn to_string_with_separators(self, separator: String = "_") -> String:
        """Returns string representation of the BigUInt with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigUInt with separators.
        """

        var result = self.to_string()
        var end = len(result)
        var start = end - 3
        var blocks = List[String](capacity=len(result) // 3 + 1)
        while start > 0:
            blocks.append(result[start:end])
            end = start
            start = end - 3
        blocks.append(result[0:end])
        blocks.reverse()
        result = separator.join(blocks)

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
        return decimojo.biguint.arithmetics.floor_modulo(self, other)

    @always_inline
    fn __divmod__(self, other: Self) raises -> Tuple[Self, Self]:
        return decimojo.biguint.arithmetics.divmod(self, other)

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        return self.power(exponent)

    @always_inline
    fn __pow__(self, exponent: Int) raises -> Self:
        return self.power(exponent)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self) raises:
        """Adds `other` to `self` in place.
        See `add_inplace()` for more information.
        """
        decimojo.biguint.arithmetics.add_inplace(self, other)

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
        self = decimojo.biguint.arithmetics.floor_modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Returns True if self > other."""
        return decimojo.biguint.comparison.greater(self, other)

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Returns True if self >= other."""
        return decimojo.biguint.comparison.greater_equal(self, other)

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Returns True if self < other."""
        return decimojo.biguint.comparison.less(self, other)

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Returns True if self <= other."""
        return decimojo.biguint.comparison.less_equal(self, other)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self == other."""
        return decimojo.biguint.comparison.equal(self, other)

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns True if self != other."""
        return decimojo.biguint.comparison.not_equal(self, other)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn add_inplace_by_1(mut self) raises:
        """Adds 1 to this number in place.
        It is equal to `self += 1`.
        See `add_inplace_by_1()` for more information.
        """
        decimojo.biguint.arithmetics.add_inplace_by_1(self)

    @always_inline
    fn floor_divide(self, other: Self) raises -> Self:
        """Returns the result of floor dividing this number by `other`.
        It is equal to `self // other`.
        See `floor_divide()` for more information.
        """
        return decimojo.biguint.arithmetics.floor_divide(self, other)

    @always_inline
    fn truncate_divide(self, other: Self) raises -> Self:
        """Returns the result of truncate dividing this number by `other`.
        It is equal to `self // other`.
        See `truncate_divide()` for more information.
        """
        return decimojo.biguint.arithmetics.truncate_divide(self, other)

    @always_inline
    fn ceil_divide(self, other: Self) raises -> Self:
        """Returns the result of ceil dividing this number by `other`.
        See `ceil_divide()` for more information.
        """
        return decimojo.biguint.arithmetics.ceil_divide(self, other)

    @always_inline
    fn floor_modulo(self, other: Self) raises -> Self:
        """Returns the result of floor modulo this number by `other`.
        See `floor_modulo()` for more information.
        """
        return decimojo.biguint.arithmetics.floor_modulo(self, other)

    @always_inline
    fn truncate_modulo(self, other: Self) raises -> Self:
        """Returns the result of truncate modulo this number by `other`.
        See `truncate_modulo()` for more information.
        """
        return decimojo.biguint.arithmetics.truncate_modulo(self, other)

    @always_inline
    fn ceil_modulo(self, other: Self) raises -> Self:
        """Returns the result of ceil modulo this number by `other`.
        See `ceil_modulo()` for more information.
        """
        return decimojo.biguint.arithmetics.ceil_modulo(self, other)

    @always_inline
    fn divmod(self, other: Self) raises -> Tuple[Self, Self]:
        """Returns the result of divmod this number by `other`.
        See `divmod()` for more information.
        """
        return decimojo.biguint.arithmetics.divmod(self, other)

    @always_inline
    fn floor_divide_inplace_by_2(mut self) raises:
        """Divides this number by 2 in place.
        See `floor_divide_inplace_by_2()` for more information.
        """
        decimojo.biguint.arithmetics.floor_divide_inplace_by_2(self)

    @always_inline
    fn scale_up_by_power_of_10(self, n: Int) -> Self:
        """Returns the result of multiplying this number by 10^n (n>=0).
        See `scale_up_by_power_of_10()` for more information.
        """
        return decimojo.biguint.arithmetics.scale_up_by_power_of_10(self, n)

    @always_inline
    fn scale_down_by_power_of_10(self, n: Int) raises -> Self:
        """Returns the result of floored dividing this number by 10^n (n>=0).
        It is equal to removing the last n digits of the number.
        See `scale_down_by_power_of_10()` for more information.
        """
        return decimojo.biguint.arithmetics.scale_down_by_power_of_10(self, n)

    fn power(self, exponent: Int) raises -> Self:
        """Returns the result of raising this number to the power of `exponent`.

        Args:
            exponent: The exponent to raise the number to.

        Returns:
            The result of raising this number to the power of `exponent`.

        Raises:
            Error: If the exponent is negative.
            Error: If the exponent is too large, e.g., larger than 1_000_000_000.
        """
        if exponent < 0:
            raise Error("Error in `BigUInt.power()`: The exponent is negative")

        if exponent == 0:
            return Self(1)

        if exponent > 1_000_000_000:
            raise Error("Error in `BigUInt.power()`: The exponent is too large")

        var result = Self(1)
        var base = self
        var exp = exponent
        while exp > 0:
            if exp % 2 == 1:
                result = result * base
            base = base * base
            exp //= 2

        return result

    fn power(self, exponent: Self) raises -> Self:
        """Returns the result of raising this number to the power of `exponent`.
        """
        if exponent > BigUInt(UInt32(0), UInt32(1)):
            raise Error("Error in `BigUInt.power()`: The exponent is too large")
        var exponent_as_int = exponent.to_int()
        return self.power(exponent_as_int)

    @always_inline
    fn compare(self, other: Self) -> Int8:
        """Compares the magnitudes of two BigUInts.
        See `compare()` for more information.
        """
        return decimojo.biguint.comparison.compare(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    fn internal_representation(self) raises:
        """Prints the internal representation details of a BigUInt."""
        var string_of_number = self.to_string(line_width=30).split("\n")
        print("\nInternal Representation Details of BigUInt")
        print("----------------------------------------------")
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
                String("word {}:{}{}")
                .format(i, " " * (10 - ndigits), String(self.words[i]))
                .rjust(9, fillchar="0")
            )
        print("----------------------------------------------")

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

    @always_inline
    fn is_power_of_10(x: BigUInt) -> Bool:
        """Check if x is a power of 10."""
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

    @always_inline
    fn is_unitialized(self) -> Bool:
        """Returns True if the BigUInt is uninitialized."""
        return len(self.words) == 0

    @always_inline
    fn ith_digit(self, i: Int) raises -> UInt8:
        """Returns the ith least significant digit of the BigUInt.

        Args:
            i: The index of the digit to return. The least significant digit
                is at index 0.

        Returns:
            The ith least significant digit of the BigUInt.

        Raises:
            Error: If the index is negative or larger than the number of digits
                in the BigUInt.
        """
        if i < 0:
            raise Error("Error in `ith_digit()`: The index is negative")
        if i >= len(self.words) * 9:
            return 0
        var word_index = i // 9
        var digit_index = i % 9
        if word_index >= len(self.words):
            return 0
        var word = self.words[word_index]
        for _ in range(digit_index):
            word = word // 10
        var digit = word % 10
        return UInt8(digit)

    @always_inline
    fn number_of_digits(self) -> Int:
        """Returns the number of digits in the BigUInt.

        Notes:

        Zero has 1 digit.
        """
        if self.is_zero():
            return 1

        var result: Int = (len(self.words) - 1) * 9
        var last_word = self.words[len(self.words) - 1]
        while last_word > 0:
            result += 1
            last_word = last_word // 10
        return result

    @always_inline
    fn number_of_words(self) -> Int:
        """Returns the number of words in the BigInt."""
        return len(self.words)

    @always_inline
    fn number_of_trailing_zeros(self) -> Int:
        """Returns the number of trailing zeros in the BigUInt."""
        var result: Int = 0
        for i in range(len(self.words)):
            if self.words[i] == 0:
                result += 9
            else:
                var word = self.words[i]
                while word % 10 == 0:
                    result += 1
                    word = word // 10
                break
        return result

    @always_inline
    fn remove_leading_empty_words(mut self):
        """Removes leading words of 0 from BigUInt's internal representation."""
        while len(self.words) > 1 and self.words[-1] == 0:
            self.words.resize(len(self.words) - 1, UInt32(0))

    @always_inline
    fn remove_trailing_digits_with_rounding(
        self,
        ndigits: Int,
        rounding_mode: RoundingMode,
        remove_extra_digit_due_to_rounding: Bool,
    ) raises -> Self:
        """Removes trailing digits from the BigUInt.

        Args:
            ndigits: The number of digits to remove.
            rounding_mode: The rounding mode to use.
                RoundingMode.ROUND_DOWN: Round down.
                RoundingMode.ROUND_UP: Round up.
                RoundingMode.ROUND_HALF_UP: Round half up.
                RoundingMode.ROUND_HALF_EVEN: Round half even.
            remove_extra_digit_due_to_rounding: If True, remove an trailing
                digit if the rounding mode result in an extra digit.

        Returns:
            The BigUInt with the trailing digits removed.

        Notes:

        Rounding can result in an extra digit. Exmaple: remove last 1 digit of
        999 with rounding up results in 100. If
        `remove_extra_digit_due_to_rounding` is True, the result will be 10.
        """
        if ndigits < 0:
            raise Error(
                "Error in `remove_trailing_digits()`: The number of digits to"
                " remove is negative"
            )
        if ndigits == 0:
            return self
        if ndigits > self.number_of_digits():
            raise Error(
                "Error in `remove_trailing_digits()`: The number of digits to"
                " remove is larger than the number of digits in the BigUInt"
            )

        # scale_down_by_power_of_10 is the same as removing the last n digits
        var result = self.scale_down_by_power_of_10(ndigits)
        var round_up: Bool = False

        if rounding_mode == RoundingMode.ROUND_DOWN:
            pass
        elif rounding_mode == RoundingMode.ROUND_UP:
            if self.number_of_trailing_zeros() < ndigits:
                round_up = True
        elif rounding_mode == RoundingMode.ROUND_HALF_UP:
            if self.ith_digit(ndigits - 1) >= 5:
                round_up = True
        elif rounding_mode == RoundingMode.ROUND_HALF_EVEN:
            var cut_off_digit = self.ith_digit(ndigits - 1)
            if cut_off_digit > 5:
                round_up = True
            elif cut_off_digit < 5:
                pass
            else:  # cut_off_digit == 5
                if self.number_of_trailing_zeros() < ndigits - 1:
                    round_up = True
                else:
                    round_up = self.ith_digit(ndigits) % 2 == 1
        else:
            raise Error(
                "Error in `remove_trailing_digits()`: Unknown rounding mode"
            )

        if round_up:
            result.add_inplace_by_1()
            # Check whether rounding results in extra digit
            if result.is_power_of_10():
                if remove_extra_digit_due_to_rounding:
                    result = result.scale_down_by_power_of_10(
                        1,
                    )
        return result^

    @always_inline
    fn shift_words_left(self, position: Int) -> Self:
        """Shifts the words of the BigUInt to the left by `position` bits.
        See `arithmetics.shift_words_left()` for more information.
        """
        return decimojo.biguint.arithmetics.shift_words_left(self, position)
