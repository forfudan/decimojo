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

import decimojo.bigint.arithmetics
import decimojo.bigint.comparison
from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.biguint.biguint import BigUInt
from decimojo.errors import DeciMojoError
import decimojo.str

# Type aliases
alias BInt = BigInt


struct BigInt(
    Absable,
    AnyType,
    Comparable,
    Copyable,
    IntableRaising,
    Movable,
    Representable,
    Stringable,
    Writable,
):
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

    @implicit
    fn __init__(out self, magnitude: BigUInt):
        """Constructs a BigInt from a BigUInt object."""
        self.magnitude = magnitude.copy()
        self.sign = False

    fn __init__(out self, magnitude: BigUInt, sign: Bool):
        """Initializes a BigInt from a BigUInt and a sign.

        Args:
            magnitude: The magnitude of the BigInt.
            sign: The sign of the BigInt.
        """

        self.magnitude = magnitude.copy()
        self.sign = sign

    fn __init__(out self, words: List[UInt32], sign: Bool):
        """***UNSAFE!*** Initializes a BigInt from a List of UInt32 and a sign.
        It does not check whether the list is empty or the words are invalid.
        See `from_list()` for safer initialization.

        Args:
            words: The magnitude of the BigInt.
            sign: The sign of the BigInt.

        Notes:

        This method does not check whether
        (1) the list is empty.
        (2) the words are smaller than `999_999_999`.
        """

        self.magnitude = BigUInt(words.copy())
        self.sign = sign

    fn __init__(out self, var *words: UInt32, sign: Bool) raises:
        """***UNSAFE!*** Initializes a BigInt from raw components.
        It does not check whether the words are invalid.
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
        self.magnitude = BigUInt(List[UInt32](elements=words^))
        self.sign = sign

    fn __init__(out self, value: String) raises:
        """Initializes a BigInt from a string representation.
        See `from_string()` for more information.
        """
        try:
            self = Self.from_string(value)
        except e:
            raise Error("Error in `BigInt.__init__()` with String: ", e)

    @implicit
    fn __init__(out self, value: Int):
        """Initializes a BigInt from an `Int` object.
        See `from_int()` for more information.
        """
        self = Self.from_int(value)

    @implicit
    fn __init__(out self, value: UInt):
        """Initializes a BigInt from an `UInt` object.
        See `from_uint()` for more information.
        """
        self = Self.from_uint(value)

    @implicit
    fn __init__(out self, value: Scalar):
        """Constructs a BigInt from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype of the scalar must be integral.
        """
        self = Self.from_integral_scalar(value)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    #
    # from_words(*words: UInt32, sign: Bool) -> Self
    # from_int(value: Int) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_list(var words: List[UInt32], sign: Bool) raises -> Self:
        """Initializes a BigInt from a list of UInt32 words safely.
        If the list is empty, the BigInt is initialized with value 0.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt.

        Returns:
            The BigInt representation of the list of UInt32 words.
        """
        # Return 0 if the list is empty
        if len(words) == 0:
            return Self()

        return Self(BigUInt(words^), sign)

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

        var list_of_words = List[UInt32](capacity=len(words))

        # Check if the words are valid
        for word in words:
            if word > UInt32(999_999_999):
                raise Error(
                    "Error in `BigInt.__init__()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                list_of_words.append(word)

        return Self(BigUInt(list_of_words^), sign)

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Creates a BigInt from an integer."""
        if value == 0:
            return Self()

        var words = List[UInt32](capacity=2)
        var sign: Bool
        var remainder: Int
        var quotient: Int
        var is_min: Bool = False
        if value < 0:
            sign = True
            # Handle the case of Int.MIN due to asymmetry of Int.MIN and Int.MAX
            if value == Int.MIN:
                is_min = True
                remainder = Int.MAX
            else:
                remainder = -value
        else:
            sign = False
            remainder = value

        while remainder != 0:
            quotient = remainder // 1_000_000_000
            remainder = remainder % 1_000_000_000
            words.append(UInt32(remainder))
            remainder = quotient

        if is_min:
            words[0] += 1

        return Self(BigUInt(words^), sign)

    @staticmethod
    fn from_uint(value: UInt) -> Self:
        """Creates a BigInt from an unsignd integer."""
        return Self(magnitude=BigUInt.from_uint(value), sign=False)

    @staticmethod
    fn from_integral_scalar[dtype: DType, //](value: SIMD[dtype, 1]) -> Self:
        """Initializes a BigInt from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype must be integral.

        Args:
            value: The Scalar value to be converted to BigInt.

        Returns:
            The BigInt representation of the Scalar value.
        """

        constrained[dtype.is_integral(), "dtype must be integral."]()

        if value == 0:
            return Self()

        return Self(
            magnitude=BigUInt.from_absolute_integral_scalar(value),
            sign=True if value < 0 else False,
        )

    @staticmethod
    fn from_string(value: String) raises -> Self:
        """Initializes a BigInt from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigInt.

        Returns:
            The BigInt representation of the string.
        """
        _tuple = decimojo.str.parse_numeric_string(value)
        var ref coef: List[UInt8] = _tuple[0]
        var sign: Bool = _tuple[2]

        # Check if the number is zero
        if len(coef) == 1 and coef[0] == UInt8(0):
            return Self(UInt32(0), sign=False)

        magnitude = BigUInt.from_string(value, ignore_sign=True)

        return Self(magnitude^, sign)

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
        See `to_string()` for more information.
        """
        return self.to_string()

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

    fn to_string(self, line_width: Int = 0) -> String:
        """Returns string representation of the BigInt.

        Args:
            line_width: The maximum line width for the string representation.
                Default is 0, which means no line width limit.

        Returns:
            The string representation of the BigInt.
        """

        if self.magnitude.is_unitialized():
            return String("Unitilialized BigInt")

        if self.is_zero():
            return String("0")

        var result = String("-") if self.sign else String("")
        result += self.magnitude.to_string()

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
        """Returns string representation of the BigInt with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigInt with separators.
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
    fn __add__(self, other: Self) -> Self:
        return decimojo.bigint.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        return decimojo.bigint.arithmetics.subtract(self, other)

    @always_inline
    fn __mul__(self, other: Self) -> Self:
        return decimojo.bigint.arithmetics.multiply(self, other)

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        try:
            return decimojo.bigint.arithmetics.floor_divide(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    message=None,
                    function="BigInt.__floordiv__()",
                    file="src/decimojo/bigint/bigint.mojo",
                    previous_error=e,
                )
            )

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        try:
            return decimojo.bigint.arithmetics.floor_modulo(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    message=None,
                    function="BigInt.__mod__()",
                    file="src/decimojo/bigint/bigint.mojo",
                    previous_error=e,
                )
            )

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        return self.power(exponent)

    # ===------------------------------------------------------------------=== #
    # Basic binary right-side arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __radd__(self, other: Self) -> Self:
        return decimojo.bigint.arithmetics.add(self, other)

    @always_inline
    fn __rsub__(self, other: Self) -> Self:
        return decimojo.bigint.arithmetics.subtract(other, self)

    @always_inline
    fn __rmul__(self, other: Self) -> Self:
        return decimojo.bigint.arithmetics.multiply(self, other)

    @always_inline
    fn __rfloordiv__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.floor_divide(other, self)

    @always_inline
    fn __rmod__(self, other: Self) raises -> Self:
        return decimojo.bigint.arithmetics.floor_modulo(other, self)

    @always_inline
    fn __rpow__(self, base: Self) raises -> Self:
        return base.power(self)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self):
        decimojo.bigint.arithmetics.add_inplace(self, other)

    @always_inline
    fn __iadd__(mut self, other: Int):
        # Optimize the case `i += 1`
        if (self >= 0) and (other >= 0) and (other <= 999_999_999):
            decimojo.biguint.arithmetics.add_inplace_by_uint32(
                self.magnitude, UInt32(other)
            )
        else:
            decimojo.bigint.arithmetics.add_inplace(self, other)

    @always_inline
    fn __isub__(mut self, other: Self):
        self = decimojo.bigint.arithmetics.subtract(self, other)

    @always_inline
    fn __imul__(mut self, other: Self):
        self = decimojo.bigint.arithmetics.multiply(self, other)

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.floor_divide(self, other)

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        self = decimojo.bigint.arithmetics.floor_modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Returns True if self > other."""
        return decimojo.bigint.comparison.greater(self, other)

    @always_inline
    fn __gt__(self, other: Int) -> Bool:
        """Returns True if self > other."""
        return decimojo.bigint.comparison.greater(self, Self.from_int(other))

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Returns True if self >= other."""
        return decimojo.bigint.comparison.greater_equal(self, other)

    @always_inline
    fn __ge__(self, other: Int) -> Bool:
        """Returns True if self >= other."""
        return decimojo.bigint.comparison.greater_equal(
            self, Self.from_int(other)
        )

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Returns True if self < other."""
        return decimojo.bigint.comparison.less(self, other)

    @always_inline
    fn __lt__(self, other: Int) -> Bool:
        """Returns True if self < other."""
        return decimojo.bigint.comparison.less(self, Self.from_int(other))

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Returns True if self <= other."""
        return decimojo.bigint.comparison.less_equal(self, other)

    @always_inline
    fn __le__(self, other: Int) -> Bool:
        """Returns True if self <= other."""
        return decimojo.bigint.comparison.less_equal(self, Self.from_int(other))

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self == other."""
        return decimojo.bigint.comparison.equal(self, other)

    @always_inline
    fn __eq__(self, other: Int) -> Bool:
        """Returns True if self == other."""
        return decimojo.bigint.comparison.equal(self, Self.from_int(other))

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns True if self != other."""
        return decimojo.bigint.comparison.not_equal(self, other)

    @always_inline
    fn __ne__(self, other: Int) -> Bool:
        """Returns True if self != other."""
        return decimojo.bigint.comparison.not_equal(self, Self.from_int(other))

    # ===------------------------------------------------------------------=== #
    # Other dunders
    # ===------------------------------------------------------------------=== #

    fn __merge_with__[other_type: type_of(BigDecimal)](self) -> BigDecimal:
        "Merges this BigInt with a BigDecimal into a BigDecimal."
        return BigDecimal(self)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

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

    fn power(self, exponent: Int) raises -> Self:
        """Raises the BigInt to the power of an integer exponent.
        See `power()` for more information.
        """
        var magnitude = self.magnitude.power(exponent)
        var sign = False
        if self.sign:
            sign = exponent % 2 == 1
        return Self(magnitude^, sign)

    fn power(self, exponent: Self) raises -> Self:
        """Raises the BigInt to the power of another BigInt.
        See `power()` for more information.
        """
        if exponent > Self(BigUInt(UInt32(0), UInt32(1)), sign=False):
            raise Error("Error in `BigUInt.power()`: The exponent is too large")
        var exponent_as_int = exponent.to_int()
        return self.power(exponent_as_int)

    @always_inline
    fn compare_magnitudes(self, other: Self) -> Int8:
        """Compares the magnitudes of two BigInts.
        See `compare_magnitudes()` for more information.
        """
        return decimojo.bigint.comparison.compare_magnitudes(self, other)

    @always_inline
    fn compare(self, other: Self) -> Int8:
        """Compares two BigInts.
        See `compare()` for more information.
        """
        return decimojo.bigint.comparison.compare(self, other)

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

    @always_inline
    fn number_of_words(self) -> Int:
        """Returns the number of words in the BigInt."""
        return len(self.magnitude.words)

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn print_internal_representation(self) raises:
        """Prints the internal representation details of a BigInt."""
        var string_of_number = self.to_string(line_width=30).split("\n")
        print("\nInternal Representation Details of BigInt")
        print("----------------------------------------------")
        print("number:         ", end="")
        for i in range(0, len(string_of_number)):
            if i > 0:
                print(" " * 16, end="")
            print(string_of_number[i])
        for i in range(len(self.magnitude.words)):
            var ndigits = 1
            if i < 10:
                pass
            elif i < 100:
                ndigits = 2
            else:
                ndigits = 3
            print(
                String("word {}:{}{}")
                .format(
                    i, " " * (10 - ndigits), String(self.magnitude.words[i])
                )
                .rjust(9, fillchar="0")
            )
        print("----------------------------------------------")
