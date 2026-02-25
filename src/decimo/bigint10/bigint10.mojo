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

"""Implements basic object methods for the BigInt10 type.

This module contains the basic object methods for the BigInt10 type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer
from python import PythonObject

import decimo.bigint10.arithmetics
import decimo.bigint10.comparison
from decimo.bigdecimal.bigdecimal import BigDecimal
from decimo.biguint.biguint import BigUInt
from decimo.errors import DecimoError
import decimo.str


struct BigInt10(
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
    """The magnitude of the BigInt10."""
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
        """Initializes a BigInt10 with value 0."""
        self.magnitude = BigUInt()
        self.sign = False

    @implicit
    fn __init__(out self, magnitude: BigUInt):
        """Constructs a BigInt10 from a BigUInt object."""
        self.magnitude = magnitude.copy()
        self.sign = False

    fn __init__(out self, magnitude: BigUInt, sign: Bool):
        """Initializes a BigInt10 from a BigUInt and a sign.

        Args:
            magnitude: The magnitude of the BigInt10.
            sign: The sign of the BigInt10.
        """
        self.magnitude = magnitude.copy()
        self.sign = sign

    fn __init__(out self, var words: List[UInt32], sign: Bool) raises:
        """Initializes a BigInt10 from a list of UInt32 words and a sign.
        The BigInt10 constructed in this way is guaranteed to be valid.
        If the list is empty, the BigInt10 is initialized with value 0.
        If there are leading zero words, they are removed.
        If there are words greater than `999_999_999`, there is an error.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt10.

        Notes:
            This is equal to `BigInt10.from_list()`.
        """
        try:
            self = Self.from_list(words^, sign=sign)
        except e:
            raise Error(
                DecimoError(
                    file="src/decimo/bigint10/bigint10.mojo",
                    function=(
                        "BigInt10.__init__(var words: List[UInt32], sign: Bool)"
                    ),
                    message=None,
                    previous_error=e^,
                )
            )

    fn __init__(out self, *, var raw_words: List[UInt32], sign: Bool):
        """Initializes a BigInt10 from a list of raw words.

        Args:
            raw_words: A list of UInt32 words representing the coefficient.
                The words are stored in little-endian order.
            sign: The sign of the BigInt10.

        Notes:

        **UNSAFE**

        This way of initialization does not check whether the words are smaller
        than `999_999_999`, nor does it remove leading empty words.

        However, it always initializes a BigInt10 and makes sure that the words
        list is not empty.
        """

        self.magnitude = BigUInt(raw_words=raw_words^)
        self.sign = sign

    fn __init__(out self, value: String) raises:
        """Initializes a BigInt10 from a string representation.
        See `from_string()` for more information.
        """
        try:
            self = Self.from_string(value)
        except e:
            raise Error("Error in `BigInt10.__init__()` with String: ", e)

    # TODO: If Mojo makes Int type an alias of SIMD[DType.index, 1],
    # we can remove this method.
    @implicit
    fn __init__(out self, value: Int):
        """Initializes a BigInt10 from an `Int` object.
        See `from_int()` for more information.
        """
        self = Self.from_int(value)

    @implicit
    fn __init__(out self, value: Scalar):
        """Constructs a BigInt10 from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype of the scalar must be integral.
        """
        self = Self.from_integral_scalar(value)

    fn __init__(out self, *, py: PythonObject) raises:
        """Constructs a BigInt10 from a Python int object."""
        self = Self.from_python_int(py)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    #
    # from_words(*words: UInt32, sign: Bool) -> Self
    # from_int(value: Int) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_list(var words: List[UInt32], sign: Bool) raises -> Self:
        """Initializes a BigInt10 from a list of UInt32 words safely.
        If the list is empty, the BigInt10 is initialized with value 0.
        If there are leading zero words, they are removed.
        The words are validated to ensure they are smaller than `999_999_999`.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt10.

        Raises:
            Error: If any word is larger than `999_999_999`.

        Returns:
            The BigInt10 representation of the list of UInt32 words.
        """
        try:
            return Self(BigUInt.from_list(words^), sign)
        except e:
            raise Error(
                DecimoError(
                    file="src/decimo/bigint10/bigint10.mojo",
                    function=(
                        "BigInt10.from_list(var words: List[UInt32], sign:"
                        " Bool)"
                    ),
                    message=None,
                    previous_error=e^,
                )
            )

    @staticmethod
    fn from_words(*words: UInt32, sign: Bool) raises -> Self:
        """Initializes a BigInt10 from raw words.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents digits ranging from 0 to 10^9 - 1.
                The words are stored in little-endian order.
            sign: The sign of the BigInt10.

        Notes:

        This method validates whether the words are smaller than `999_999_999`.
        """

        var list_of_words = List[UInt32](capacity=len(words))

        # Check if the words are valid
        for word in words:
            if word > UInt32(999_999_999):
                raise Error(
                    "Error in `BigInt10.__init__()`: Word value exceeds maximum"
                    " value of 999_999_999"
                )
            else:
                list_of_words.append(word)

        return Self(BigUInt(raw_words=list_of_words^), sign)

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Creates a BigInt10 from an integer."""
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
            quotient = remainder // BigUInt.BASE
            remainder = remainder % BigUInt.BASE
            words.append(UInt32(remainder))
            remainder = quotient

        if is_min:
            words[0] += 1

        return Self(BigUInt(raw_words=words^), sign)

    @staticmethod
    fn from_integral_scalar[dtype: DType, //](value: SIMD[dtype, 1]) -> Self:
        """Initializes a BigInt10 from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype must be integral.

        Args:
            value: The Scalar value to be converted to BigInt10.

        Returns:
            The BigInt10 representation of the Scalar value.
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
        """Initializes a BigInt10 from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigInt10.

        Returns:
            The BigInt10 representation of the string.
        """
        _tuple = decimo.str.parse_numeric_string(value)
        var ref coef: List[UInt8] = _tuple[0]
        var sign: Bool = _tuple[2]

        # Check if the number is zero
        if len(coef) == 1 and coef[0] == UInt8(0):
            return Self(UInt32(0), sign=False)

        magnitude = BigUInt.from_string(value, ignore_sign=True)

        return Self(magnitude=magnitude^, sign=sign)

    @staticmethod
    fn from_python_int(value: PythonObject) raises -> Self:
        """Initializes a BigInt10 from a Python integer object.

        Args:
            value: A Python integer object (PythonObject).

        Returns:
            The BigInt10 representation of the Python integer.

        Raises:
            Error: If the conversion from Python int to string fails, or if
                the string cannot be parsed as a valid integer.

        Examples:
        ```mojo
        from python import Python
        from decimo.prelude import *

        fn main() raises:
            var py = Python.import_module("builtins")
            var py_int = py.int("123456789012345678901234567890")
            var mojo_bigint = BigInt10.from_python_int(py_int)
            print(mojo_bigint)  # 123456789012345678901234567890
        ```
        End of examples.

        Notes:
        This method converts the Python integer to a string representation
        using Python's `str()` function, then uses `BigInt10.from_string()`
        to parse it. This approach handles arbitrarily large Python integers
        since Python's int type is already arbitrary-precision.
        """
        try:
            # Convert Python int to string using Python's str() function
            var py_str = String(value)
            # Use the existing from_string() method to parse the string
            return Self.from_string(py_str)
        except e:
            raise Error(
                DecimoError(
                    file="src/decimo/bigint10/bigint10.mojo",
                    function="BigInt10.from_python_int(value: PythonObject)",
                    message="Failed to convert Python int to BigInt10.",
                    previous_error=e^,
                )
            )

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __int__(self) raises -> Int:
        """Returns the number as Int.
        See `to_int()` for more information.
        """
        return self.to_int()

    fn __str__(self) -> String:
        """Returns string representation of the BigInt10.
        See `to_string()` for more information.
        """
        return self.to_string()

    fn __repr__(self) -> String:
        """Returns a string representation of the BigInt10."""
        return 'BigInt10("' + self.__str__() + '")'

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the BigInt10 to a writer.
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
                "Error in `BigInt10.to_int()`: The number exceeds the size"
                " of Int"
            )

        var value: Int128 = 0
        for i in range(len(self.magnitude.words)):
            value += (
                Int128(self.magnitude.words[i]) * Int128(1_000_000_000) ** i
            )

        value = -value if self.sign else value

        # Intermediate variables made due to a bug in Mojo compiler, see:
        # https://github.com/modular/modular/issues/5931
        # TODO: Remove these intermediate variables after the bug is fixed.
        var int_min = Int.MIN
        var int_max = Int.MAX
        if value < Int128(int_min) or value > Int128(int_max):
            raise Error(
                "Error in `BigInt10.to_int()`: The number exceeds the size"
                " of Int"
            )
        return Int(value)

    fn to_string(self, line_width: Int = 0) -> String:
        """Returns string representation of the BigInt10.

        Args:
            line_width: The maximum line width for the string representation.
                Default is 0, which means no line width limit.

        Returns:
            The string representation of the BigInt10.
        """

        if self.magnitude.is_unitialized():
            return String("Unitilialized BigInt10")

        if self.is_zero():
            return String("0")

        var result = String("-") if self.sign else String("")
        result += self.magnitude.to_string()

        if line_width > 0:
            var start = 0
            var end = line_width
            var lines = List[String](capacity=len(result) // line_width + 1)
            while end < len(result):
                lines.append(String(result[start:end]))
                start = end
                end += line_width
            lines.append(String(result[start:]))
            result = String("\n").join(lines^)

        return result^

    fn to_string_with_separators(self, separator: String = "_") -> String:
        """Returns string representation of the BigInt10 with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigInt10 with separators.
        """

        var result = self.to_string()
        var end = len(result)
        var start = end - 3
        var blocks = List[String](capacity=len(result) // 3 + 1)
        while start > 0:
            blocks.append(String(result[start:end]))
            end = start
            start = end - 3
        blocks.append(String(result[0:end]))
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
        return decimo.bigint10.arithmetics.absolute(self)

    @always_inline
    fn __neg__(self) -> Self:
        """Returns the negation of this number.
        See `negative()` for more information.
        """
        return decimo.bigint10.arithmetics.negative(self)

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) -> Self:
        return decimo.bigint10.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        return decimo.bigint10.arithmetics.subtract(self, other)

    @always_inline
    fn __mul__(self, other: Self) -> Self:
        return decimo.bigint10.arithmetics.multiply(self, other)

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        try:
            return decimo.bigint10.arithmetics.floor_divide(self, other)
        except e:
            raise Error(
                DecimoError(
                    message=None,
                    function="BigInt10.__floordiv__()",
                    file="src/decimo/bigint10/bigint10.mojo",
                    previous_error=e^,
                )
            )

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        try:
            return decimo.bigint10.arithmetics.floor_modulo(self, other)
        except e:
            raise Error(
                DecimoError(
                    message=None,
                    function="BigInt10.__mod__()",
                    file="src/decimo/bigint10/bigint10.mojo",
                    previous_error=e^,
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
        return decimo.bigint10.arithmetics.add(self, other)

    @always_inline
    fn __rsub__(self, other: Self) -> Self:
        return decimo.bigint10.arithmetics.subtract(other, self)

    @always_inline
    fn __rmul__(self, other: Self) -> Self:
        return decimo.bigint10.arithmetics.multiply(self, other)

    @always_inline
    fn __rfloordiv__(self, other: Self) raises -> Self:
        return decimo.bigint10.arithmetics.floor_divide(other, self)

    @always_inline
    fn __rmod__(self, other: Self) raises -> Self:
        return decimo.bigint10.arithmetics.floor_modulo(other, self)

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
        decimo.bigint10.arithmetics.add_inplace(self, other)

    @always_inline
    fn __iadd__(mut self, other: Int):
        # Optimize the case `i += 1`
        if (self >= 0) and (other >= 0) and (other <= 999_999_999):
            decimo.biguint.arithmetics.add_inplace_by_uint32(
                self.magnitude, UInt32(other)
            )
        else:
            decimo.bigint10.arithmetics.add_inplace(self, Self(other))

    @always_inline
    fn __isub__(mut self, other: Self):
        self = decimo.bigint10.arithmetics.subtract(self, other)

    @always_inline
    fn __imul__(mut self, other: Self):
        self = decimo.bigint10.arithmetics.multiply(self, other)

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        self = decimo.bigint10.arithmetics.floor_divide(self, other)

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        self = decimo.bigint10.arithmetics.floor_modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Returns True if self > other."""
        return decimo.bigint10.comparison.greater(self, other)

    @always_inline
    fn __gt__(self, other: Int) -> Bool:
        """Returns True if self > other."""
        return decimo.bigint10.comparison.greater(self, Self.from_int(other))

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Returns True if self >= other."""
        return decimo.bigint10.comparison.greater_equal(self, other)

    @always_inline
    fn __ge__(self, other: Int) -> Bool:
        """Returns True if self >= other."""
        return decimo.bigint10.comparison.greater_equal(
            self, Self.from_int(other)
        )

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Returns True if self < other."""
        return decimo.bigint10.comparison.less(self, other)

    @always_inline
    fn __lt__(self, other: Int) -> Bool:
        """Returns True if self < other."""
        return decimo.bigint10.comparison.less(self, Self.from_int(other))

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Returns True if self <= other."""
        return decimo.bigint10.comparison.less_equal(self, other)

    @always_inline
    fn __le__(self, other: Int) -> Bool:
        """Returns True if self <= other."""
        return decimo.bigint10.comparison.less_equal(self, Self.from_int(other))

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self == other."""
        return decimo.bigint10.comparison.equal(self, other)

    @always_inline
    fn __eq__(self, other: Int) -> Bool:
        """Returns True if self == other."""
        return decimo.bigint10.comparison.equal(self, Self.from_int(other))

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns True if self != other."""
        return decimo.bigint10.comparison.not_equal(self, other)

    @always_inline
    fn __ne__(self, other: Int) -> Bool:
        """Returns True if self != other."""
        return decimo.bigint10.comparison.not_equal(self, Self.from_int(other))

    # ===------------------------------------------------------------------=== #
    # Other dunders
    # ===------------------------------------------------------------------=== #

    fn __merge_with__[other_type: type_of(BigDecimal)](self) -> BigDecimal:
        "Merges this BigInt10 with a BigDecimal into a BigDecimal."
        return BigDecimal(self)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn floor_divide(self, other: Self) raises -> Self:
        """Performs a floor division of two BigInts.
        See `floor_divide()` for more information.
        """
        return decimo.bigint10.arithmetics.floor_divide(self, other)

    @always_inline
    fn truncate_divide(self, other: Self) raises -> Self:
        """Performs a truncated division of two BigInts.
        See `truncate_divide()` for more information.
        """
        return decimo.bigint10.arithmetics.truncate_divide(self, other)

    @always_inline
    fn floor_modulo(self, other: Self) raises -> Self:
        """Performs a floor modulo of two BigInts.
        See `floor_modulo()` for more information.
        """
        return decimo.bigint10.arithmetics.floor_modulo(self, other)

    @always_inline
    fn truncate_modulo(self, other: Self) raises -> Self:
        """Performs a truncated modulo of two BigInts.
        See `truncate_modulo()` for more information.
        """
        return decimo.bigint10.arithmetics.truncate_modulo(self, other)

    fn power(self, exponent: Int) raises -> Self:
        """Raises the BigInt10 to the power of an integer exponent.
        See `power()` for more information.
        """
        var magnitude = self.magnitude.power(exponent)
        var sign = False
        if self.sign:
            sign = exponent % 2 == 1
        return Self(magnitude^, sign)

    fn power(self, exponent: Self) raises -> Self:
        """Raises the BigInt10 to the power of another BigInt10.
        See `power()` for more information.
        """
        if exponent > Self(BigUInt(raw_words=[0, 1]), sign=False):
            raise Error("Error in `BigUInt.power()`: The exponent is too large")
        var exponent_as_int = exponent.to_int()
        return self.power(exponent_as_int)

    @always_inline
    fn compare_magnitudes(self, other: Self) -> Int8:
        """Compares the magnitudes of two BigInts.
        See `compare_magnitudes()` for more information.
        """
        return decimo.bigint10.comparison.compare_magnitudes(self, other)

    @always_inline
    fn compare(self, other: Self) -> Int8:
        """Compares two BigInts.
        See `compare()` for more information.
        """
        return decimo.bigint10.comparison.compare(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this BigInt10 represents zero."""
        return self.magnitude.is_zero()

    @always_inline
    fn is_one_or_minus_one(self) -> Bool:
        """Returns True if this BigInt10 represents one or negative one."""
        return self.magnitude.is_one()

    @always_inline
    fn is_negative(self) -> Bool:
        """Returns True if this BigInt10 is negative."""
        return self.sign

    @always_inline
    fn number_of_words(self) -> Int:
        """Returns the number of words in the BigInt10."""
        return len(self.magnitude.words)

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn internal_representation(self) raises -> String:
        """Returns the internal representation details as a String."""
        # Collect all labels to find max width
        var max_label_len = len("number:")
        for i in range(len(self.magnitude.words)):
            var label_len = len("word :") + len(String(i))
            if label_len > max_label_len:
                max_label_len = label_len

        var col = max_label_len + 4  # 4 spaces after longest label
        var value_width = 30
        var sep_line = String("-") * (col + value_width)

        var result = String("\nInternal Representation Details of BigInt10\n")
        result += sep_line + "\n"

        # number line
        var string_of_number = self.to_string(line_width=value_width).split(
            "\n"
        )
        result += "number:" + String(" ") * (col - len("number:"))
        for i in range(len(string_of_number)):
            if i > 0:
                result += String(" ") * col
            result += string_of_number[i] + "\n"

        # word lines
        for i in range(len(self.magnitude.words)):
            var label = "word " + String(i) + ":"
            result += label + String(" ") * (col - len(label))
            result += (
                String(self.magnitude.words[i]).rjust(9, fillchar="0") + "\n"
            )

        result += sep_line
        return result^

    fn print_internal_representation(self) raises:
        """Prints the internal representation details of a BigInt10."""
        print(self.internal_representation())
