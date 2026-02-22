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

"""Implements basic object methods for the BigDecimal type.

This module contains the basic object methods for the BigDecimal type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer
from python import PythonObject
import testing

from decimojo.errors import DeciMojoError
from decimojo.rounding_mode import RoundingMode
from decimojo.bigdecimal.rounding import round_to_precision
from decimojo.bigint10.bigint10 import BigInt10

comptime BDec = BigDecimal
"""Short alias for `BigDecimal`."""
comptime Decimal = BigDecimal
"""Python-like alias for `BigDecimal`."""

comptime PRECISION = 36
"""Default precision for BigDecimal operations.
This will be configurable in future when Mojo supports global variables.
"""


struct BigDecimal(
    Absable,
    AnyType,
    Comparable,
    Copyable,
    FloatableRaising,
    IntableRaising,
    Movable,
    Representable,
    Roundable,
    Stringable,
    Writable,
):
    """Represents a arbitrary-precision decimal.

    Notes:

    Internal Representation:

    - A base-10 unsigned integer (BigUInt) for coefficient.
    - A Int value for the scale
    - A Bool value for the sign.

    Final value:
    (-1)**sign * coefficient * 10^(-scale)
    """

    # ===------------------------------------------------------------------=== #
    # Organization of fields and methods:
    # - Internal representation fields
    # - Constants (aliases)
    # - Special values (methods)
    # - Constructors and life time methods
    # - Constructing methods that are not dunders
    # - Output dunders, type-transfer dunders, and other type-transfer methods
    # - Basic unary arithmetic operation dunders
    # - Basic binary arithmetic operation dunders
    # - Basic binary arithmetic operation dunders with reflected operands
    # - Basic binary augmented arithmetic operation dunders
    # - Basic comparison operation dunders
    # - Other dunders that implements traits
    # - Mathematical methods that do not implement a trait (not a dunder)
    # - Other methods
    # - Internal methods
    # ===------------------------------------------------------------------=== #

    # Internal representation fields
    var coefficient: BigUInt
    """The coefficient of the BigDecimal."""
    var scale: Int
    """The scale of the BigDecimal."""
    var sign: Bool
    """Sign information."""

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes to zero by default."""
        self.coefficient = BigUInt()
        self.scale = 0
        self.sign = False

    @implicit
    fn __init__(out self, coefficient: BigUInt):
        """Constructs a BigDecimal from a BigUInt object."""
        self.coefficient = coefficient.copy()
        self.scale = 0
        self.sign = False

    fn __init__(out self, coefficient: BigUInt, scale: Int, sign: Bool):
        """Constructs a BigDecimal from its components."""
        self.coefficient = coefficient.copy()
        self.scale = scale
        self.sign = sign

    @implicit
    fn __init__(out self, value: BigInt10):
        """Constructs a BigDecimal from a big integer."""
        self.coefficient = value.magnitude.copy()
        self.scale = 0
        self.sign = value.sign

    fn __init__(out self, value: String) raises:
        """Constructs a BigDecimal from a string representation."""
        # The string is normalized with `deciomojo.str.parse_numeric_string()`.
        self = Self.from_string(value)

    @implicit
    fn __init__(out self, value: Int):
        """Constructs a BigDecimal from an `Int` object.
        See `from_int()` for more information.
        """
        self = Self.from_int(value)

    @implicit
    fn __init__(out self, value: UInt):
        """Constructs a BigDecimal from an `UInt` object.
        See `from_uint()` for more information.
        """
        self = Self.from_uint(value)

    @implicit
    fn __init__[dtype: DType, //](out self, value: SIMD[dtype, 1]):
        """Constructs a BigDecimal from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype of the scalar must be integral.
        """
        constrained[
            dtype.is_integral(),
            (
                "\n***********************************************************\n"
                "BigDecimal does not allow floating-point numbers as input to"
                " avoid unintentional loss of precision. If you want to create"
                " a BigDecimal from a floating-point number, please consider"
                " wrapping it with quotation marks or using the"
                " `BigDecimal.from_float()` (or `BDec.from_float()`) method"
                " instead."
                "\n***********************************************************"
            ),
        ]()

        self = Self.from_integral_scalar(value)

    fn __init__(out self, *, py: PythonObject) raises:
        """Constructs a BigDecimal from a Python Decimal object."""
        self = Self.from_python_decimal(py)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # from_int(value: Int) -> Self
    # from_scalar(value: Scalar) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_raw_components(
        var words: List[UInt32], scale: Int = 0, sign: Bool = False
    ) -> Self:
        """**UNSAFE** Creates a BigDecimal from its raw components.
        The raw components are words, scale, and sign.

        Args:
            words: The raw words of the coefficient.
            scale: The scale of the BigDecimal.
            sign: The sign of the BigDecimal.

        Returns:
            A BigDecimal object constructed from the raw components.

        Notes:

        This method is unsafe because it does not check the validity of the
        words. It is the caller's responsibility to ensure that the words
        represent a valid BigUInt.
        """
        var coefficient = BigUInt(raw_words=words^)
        return Self(coefficient=coefficient^, scale=scale, sign=sign)

    @staticmethod
    fn from_raw_components(
        word: UInt32, scale: Int = 0, sign: Bool = False
    ) -> Self:
        """**UNSAFE** Creates a BigDecimal from its raw components.
        The raw components are a single word, scale, and sign.
        """
        return Self(BigUInt(raw_words=[word]), scale, sign)

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Creates a BigDecimal from an integer."""
        if value == 0:
            return Self(coefficient=BigUInt.zero(), scale=0, sign=False)

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

        return Self(coefficient=BigUInt(raw_words=words^), scale=0, sign=sign)

    # TODO: This method is no longer needed as UInt is now an alias for SIMD.
    @staticmethod
    fn from_uint(value: UInt) -> Self:
        """Creates a BigDecimal from an unsigned integer."""
        return Self(
            coefficient=BigUInt.from_unsigned_integral_scalar(value),
            scale=0,
            sign=False,
        )

    @staticmethod
    fn from_integral_scalar[dtype: DType, //](value: SIMD[dtype, 1]) -> Self:
        """Initializes a BigDecimal from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Args:
            value: The Scalar value to be converted to BigDecimal.

        Returns:
            The BigDecimal representation of the Scalar value.
        """

        constrained[dtype.is_integral(), "dtype must be integral."]()

        if value == 0:
            return Self(coefficient=BigUInt.zero(), scale=0, sign=False)

        return Self(
            coefficient=BigUInt.from_absolute_integral_scalar(value),
            scale=0,
            sign=True if value < 0 else False,
        )

    @staticmethod
    fn from_float[dtype: DType, //](value: Scalar[dtype]) raises -> Self:
        """Initializes a BigDecimal from a floating-point scalar.

        Args:
            value: The Scalar value to be converted to BigDecimal.

        Returns:
            The BigDecimal representation of the Scalar value.

        Notes:

        If the value is a floating-point number, it is converted to a string
        with full precision before converting to BigDecimal.
        """

        constrained[
            dtype.is_floating_point(), "dtype must be floating-point."
        ]()

        if value == 0:
            return Self(coefficient=BigUInt.zero(), scale=0, sign=False)

        if value != value:  # Check for NaN
            raise Error("`from_scalar()`: Cannot convert NaN to BigUInt")
        # Convert to string with full precision
        try:
            return Self.from_string(String(value))
        except e:
            raise Error(
                "`from_scalar()`: Cannot get decimal from string\nTrace back: "
                + String(e),
            )

    @staticmethod
    fn from_string(value: String) raises -> Self:
        """Initializes a BigDecimal from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigDecimal.

        Returns:
            The BigDecimal representation of the string.
        """
        _tuple = decimojo.str.parse_numeric_string(value)
        var ref coef: List[UInt8] = _tuple[0]
        var scale: Int = _tuple[1]
        var sign: Bool = _tuple[2]

        var number_of_digits = len(coef)
        var number_of_words = number_of_digits // 9
        if number_of_digits % 9 != 0:
            number_of_words += 1

        coefficient_words = List[UInt32](capacity=number_of_words)

        var end: Int = number_of_digits
        var start: Int
        while end >= 9:
            start = end - 9
            var word: UInt32 = 0
            for digit in coef[start:end]:
                word = word * 10 + UInt32(digit)
            coefficient_words.append(word)
            end = start
        if end > 0:
            var word: UInt32 = 0
            for digit in coef[0:end]:
                word = word * 10 + UInt32(digit)
            coefficient_words.append(word)

        coefficient = BigUInt(raw_words=coefficient_words^)

        return Self(coefficient=coefficient^, scale=scale, sign=sign)

    @staticmethod
    fn from_python_decimal(value: PythonObject) raises -> Self:
        """Initializes a BigDecimal from a Python Decimal object.
        Only finite Decimal values are supported for conversion.

        Args:
            value: A Python Decimal object (from decimal module).

        Returns:
            The BigDecimal representation of the Python Decimal.

        Raises:
            Error: If the conversion from Python Decimal fails, or if
                the as_tuple() method returns invalid data.

        Examples:
        ```mojo
        from python import Python
        from decimojo.prelude import *

        fn main() raises:
            var decimal = Python.import_module("decimal")
            var py_dec = decimal.Decimal("123.456")
            var mojo_dec = BigDecimal.from_python_decimal(py_dec)
            print(mojo_dec)  # 123.456
        ```
        End of examples.

        Notes:

        This method uses Python's `as_tuple()` API to extract the decimal's
        components: (sign, digits, exponent). The digits are individual
        base-10 digits (0-9), not the internal limb representation.

        Why use as_tuple() instead of direct memory copy?

        Python's decimal module (libmpdec) uses a base-10^9 representation
        on 64-bit systems (base 10^4 on 32-bit), which matches BigDecimal's
        internal representation. Theoretically, we could directly memcpy the
        internal limbs for better performance.

        However, this approach is NOT used because:

        1. No API for direct access: Python's PythonObject doesn't expose
           the internal mpd_t pointer. Accessing it would require unsafe
           pointer manipulation, breaking abstraction boundaries.
        2. Platform dependency: 32-bit systems use base 10^4, requiring
           platform-specific code paths and runtime detection.
        3. Maintenance burden: Direct memory access depends on CPython
           internal implementation details that may change between versions.
        4. Safety concerns: Unsafe pointer operations risk memory safety
           violations, GC issues, and data races.
        5. Marginal performance gain: The time complexity of as_tuple() is still
           O(n) compared to O(n) for direct memory copy.

        The as_tuple() API provides:
        - Safe, stable interface across Python versions.
        - Portable across all platforms (32/64-bit, CPython/PyPy).
        - Clean, maintainable code.
        - Adequate performance for real-world use cases.
        """
        try:
            # Get DecimalTuple: (sign, digits, exponent)
            var tuple_repr = value.as_tuple()

            # Extract components
            # Convert PythonObject to Int via String
            var sign_int = Int(py=tuple_repr[0])
            var sign = True if sign_int == 1 else False
            var digits_tuple = tuple_repr[1]
            # When Python's Decimal.as_tuple() is called on these special
            # values, the exponent field is a string ('F' for infinity,
            # 'n' for NaN) rather than an integer.
            # Thus, only finite decimal values are supported for conversion.
            var exponent = Int(py=tuple_repr[2])

            # Convert digits tuple to coefficient string
            # digits are individual base-10 digits (0-9)
            var num_digits = len(digits_tuple)

            # Handle special case: zero
            if num_digits == 1 and Int(py=digits_tuple[0]) == 0:
                return Self(coefficient=BigUInt.zero(), scale=0, sign=False)

            # Build coefficient from digits
            var number_of_words = num_digits // 9
            if num_digits % 9 != 0:
                number_of_words += 1

            var coefficient_words = List[UInt32](capacity=number_of_words)

            # Process digits from right to left, grouping into 9-digit words
            var end = num_digits
            var start: Int
            while end >= 9:
                start = end - 9
                var word: UInt32 = 0
                for i in range(start, end):
                    var digit = Int(py=digits_tuple[i])
                    word = word * 10 + UInt32(digit)
                coefficient_words.append(word)
                end = start

            # Handle remaining digits
            if end > 0:
                var word: UInt32 = 0
                for i in range(0, end):
                    var digit = Int(py=digits_tuple[i])
                    word = word * 10 + UInt32(digit)
                coefficient_words.append(word)

            var coefficient = BigUInt(raw_words=coefficient_words^)

            # In Python's Decimal.as_tuple():
            # - exponent is the power of 10 to multiply by
            # - In BigDecimal, scale is the number of decimal places
            # - So scale = -exponent
            var scale = -exponent

            return Self(coefficient=coefficient^, scale=scale, sign=sign)

        except e:
            raise Error(
                DeciMojoError(
                    file="src/decimojo/bigdecimal/bigdecimal.mojo",
                    function="from_python_decimal()",
                    message="Failed to convert Python Decimal to BigDecimal: "
                    + "as_tuple() returned invalid data or conversion failed.",
                    previous_error=e^,
                ),
            )

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # __str__()
    # __repr__()
    # __int__()
    # __float__()
    # ===------------------------------------------------------------------=== #

    fn __str__(self) -> String:
        """Returns string representation of the BigDecimal.
        See `to_string()` for more information.
        """
        return self.to_string()

    fn __repr__(self) -> String:
        """Returns a string representation of the BigDecimal."""
        return 'BigDecimal("' + self.__str__() + '")'

    fn __int__(self) raises -> Int:
        """Converts the BigDecimal to an integer."""
        return Int(String(self))

    fn __float__(self) raises -> Float64:
        """Converts the BigDecimal to a floating-point number."""
        return Float64(String(self))

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn to_string(
        self,
        precision: Int = 28,
        scientific_notation: Bool = False,
        line_width: Int = 0,
    ) -> String:
        """Returns string representation of the number.

        Args:
            precision: The threshold for scientific notation.
                If the digits to display is greater than this value,
                the number is represented in scientific notation.
            scientific_notation: If True, the number is always represented in
                scientific notation. If False, the format is determined by the
                `precision` argument.
            line_width: The maximum line width for the string representation.
                If 0, the string is returned as a single line.
                If greater than 0, the string is split into multiple lines.

        Returns:
            A string representation of the number.

        Notes:

        In follwing cases, scientific notation is used:
        1. `scientific_notation` is True.
        2. exponent >= `precision`.
        3. There 6 or more leading zeros after decimal and before significand.
        4. The scale is negative.
        """

        if self.coefficient.is_unitialized():
            return String("Unitilialized maginitude of BigDecimal")

        var result = String("-") if self.sign else String("")
        var coefficient_string = self.coefficient.to_string()

        # Check whether scientific notation is needed
        # CPython rule: scientific when exp > 0 (scale < 0) OR
        #               adjusted_exponent < -6 (i.e., 7+ leading zeros)
        # The `precision` threshold provides an additional DeciMojo-specific
        # trigger for very large exponents (default 28).
        var exponent = self.coefficient.number_of_digits() - 1 - self.scale
        var exponent_ge_precision = exponent >= precision
        var leading_zeros_too_many = exponent < Int(-6)
        var negative_scale = self.scale < 0

        if (
            scientific_notation
            or exponent_ge_precision
            or leading_zeros_too_many
            or negative_scale
        ):
            # Use scientific notation
            var exponent_string = String(exponent)
            result += coefficient_string[byte=0]
            if len(coefficient_string) > 1:
                result += "."
                result += coefficient_string[1:]
            result += "E"
            if exponent > 0:
                result += "+"
            result += exponent_string

        else:
            # Normal notation
            if self.scale == 0:
                result += coefficient_string

            elif self.scale > 0:
                if self.scale < len(coefficient_string):
                    # Example: 123_456 with scale 3 -> 123.456
                    result += coefficient_string[
                        : len(coefficient_string) - self.scale
                    ]
                    result += "."
                    result += coefficient_string[
                        len(coefficient_string) - self.scale :
                    ]
                else:
                    # Example: 123_456 with scale 6 -> 0.123_456
                    # Example: 123_456 with scale 7 -> 0.012_345_6
                    result += "0."
                    result += "0" * (self.scale - len(coefficient_string))
                    result += coefficient_string

            else:
                # scale < 0
                # Example: 12_345 with scale -3 -> 12_345_000
                result += coefficient_string
                result += "0" * (-self.scale)

        # Split the result in multiple lines if line_width > 0
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

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the BigDecimal to a writer.
        This implement the `write` method of the `Writer` trait.
        """
        writer.write(String(self))

    # ===------------------------------------------------------------------=== #
    # Basic unary operation dunders
    # neg
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __abs__(self) -> Self:
        """Returns the absolute value of this number.
        See `absolute()` for more information.
        """
        return Self(
            coefficient=self.coefficient,
            scale=self.scale,
            sign=False,
        )

    @always_inline
    fn __neg__(self) -> Self:
        """Returns the negation of this number.
        See `negative()` for more information.
        """
        return Self(
            coefficient=self.coefficient,
            scale=self.scale,
            sign=not self.sign,
        )

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.subtract(self, other)

    @always_inline
    fn __mul__(self, other: Self) -> Self:
        return decimojo.bigdecimal.arithmetics.multiply(self, other)

    @always_inline
    fn __truediv__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.true_divide(
            self, other, precision=PRECISION
        )

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        """Returns the result of floor division.
        See `arithmetics.truncate_divide()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.truncate_divide(self, other)

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        """Returns the result of modulo operation.
        See `arithmetics.truncate_modulo()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.truncate_modulo(
            self, other, precision=PRECISION
        )

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        """Returns the result of exponentiation."""
        return decimojo.bigdecimal.exponential.power(
            self, exponent, precision=PRECISION
        )

    # ===------------------------------------------------------------------=== #
    # Basic binary right-side arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __radd__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.add(self, other)

    @always_inline
    fn __rsub__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.subtract(other, self)

    @always_inline
    fn __rmul__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.multiply(self, other)

    @always_inline
    fn __rfloordiv__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.truncate_divide(other, self)

    @always_inline
    fn __rmod__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.truncate_modulo(
            other, self, precision=PRECISION
        )

    @always_inline
    fn __rpow__(self, base: Self) raises -> Self:
        return decimojo.bigdecimal.exponential.power(
            base, self, precision=PRECISION
        )

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self) raises:
        decimojo.bigdecimal.arithmetics.add_inplace(self, other)

    @always_inline
    fn __isub__(mut self, other: Self) raises:
        decimojo.bigdecimal.arithmetics.subtract_inplace(self, other)

    @always_inline
    fn __imul__(mut self, other: Self) raises:
        decimojo.bigdecimal.arithmetics.multiply_inplace(self, other)

    @always_inline
    fn __itruediv__(mut self, other: Self) raises:
        self = decimojo.bigdecimal.arithmetics.true_divide(
            self, other, precision=PRECISION
        )

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Returns whether self is greater than other."""
        return decimojo.bigdecimal.comparison.compare(self, other) > 0

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Returns whether self is greater than or equal to other."""
        return decimojo.bigdecimal.comparison.compare(self, other) >= 0

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Returns whether self is less than other."""
        return decimojo.bigdecimal.comparison.compare(self, other) < 0

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Returns whether self is less than or equal to other."""
        return decimojo.bigdecimal.comparison.compare(self, other) <= 0

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns whether self equals other."""
        return decimojo.bigdecimal.comparison.compare(self, other) == 0

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns whether self does not equal other."""
        return decimojo.bigdecimal.comparison.compare(self, other) != 0

    # ===------------------------------------------------------------------=== #
    # Other dunders that implements traits
    # round
    # ===------------------------------------------------------------------=== #

    fn __round__(self, ndigits: Int) -> Self:
        """Rounds the number to the specified number of decimal places.
        If `ndigits` is not given, rounds to 0 decimal places.
        If rounding causes errors, returns the value itself.
        """
        try:
            return decimojo.bigdecimal.rounding.round(
                self,
                ndigits=ndigits,
                rounding_mode=RoundingMode.half_even(),
            )
        except e:
            return self.copy()

    fn __round__(self) -> Self:
        """Rounds the number to the specified number of decimal places.
        If `ndigits` is not given, rounds to 0 decimal places.
        If rounding causes errors, returns the value itself.
        """
        try:
            return decimojo.bigdecimal.rounding.round(
                self, ndigits=0, rounding_mode=RoundingMode.half_even()
            )
        except e:
            return self.copy()

    # ===------------------------------------------------------------------=== #
    # Other dunders
    # ===------------------------------------------------------------------=== #

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    # === Comparisons === #

    @always_inline
    fn compare(self, other: Self) raises -> Int8:
        """Compares two BigDecimal numbers.
        See `comparison.compare()` for more information.
        """
        return decimojo.bigdecimal.comparison.compare(self, other)

    @always_inline
    fn compare_absolute(self, other: Self) raises -> Int8:
        """Compares two BigDecimal numbers by absolute value.
        See `comparison.compare_absolute()` for more information.
        """
        return decimojo.bigdecimal.comparison.compare_absolute(self, other)

    # === Extrema === #

    @always_inline
    fn max(self, other: Self) raises -> Self:
        """Returns the maximum of two BigDecimal numbers."""
        return decimojo.bigdecimal.comparison.max(self, other)

    @always_inline
    fn min(self, other: Self) raises -> Self:
        """Returns the minimum of two BigDecimal numbers."""
        return decimojo.bigdecimal.comparison.min(self, other)

    # === Constants === #

    @always_inline
    @staticmethod
    fn pi(precision: Int) raises -> Self:
        """Returns the mathematical constant pi to the specified precision."""
        return decimojo.bigdecimal.constants.pi(precision=precision)

    @always_inline
    @staticmethod
    fn e(precision: Int) raises -> Self:
        """Returns the mathematical constant e to the specified precision."""
        return decimojo.bigdecimal.exponential.exp(
            x=Self(BigUInt.one()), precision=precision
        )

    # === Exponentional operations === #

    @always_inline
    fn exp(self, precision: Int = PRECISION) raises -> Self:
        """Returns the exponential of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.exp(self, precision)

    @always_inline
    fn ln(self, precision: Int = PRECISION) raises -> Self:
        """Returns the natural logarithm of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.ln(self, precision)

    @always_inline
    fn ln(
        self,
        precision: Int,
        mut cache: decimojo.bigdecimal.exponential.MathCache,
    ) raises -> Self:
        """Returns the natural logarithm using a cache for ln(2)/ln(1.25)."""
        return decimojo.bigdecimal.exponential.ln(self, precision, cache)

    @always_inline
    fn log(self, base: Self, precision: Int = PRECISION) raises -> Self:
        """Returns the logarithm of the BigDecimal number with the given base.
        """
        return decimojo.bigdecimal.exponential.log(self, base, precision)

    @always_inline
    fn log10(self, precision: Int = PRECISION) raises -> Self:
        """Returns the base-10 logarithm of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.log10(self, precision)

    @always_inline
    fn root(self, root: Self, precision: Int = PRECISION) raises -> Self:
        """Returns the root of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.root(self, root, precision)

    @always_inline
    fn sqrt(self, precision: Int = PRECISION) raises -> Self:
        """Returns the square root of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.sqrt(self, precision)

    @always_inline
    fn cbrt(self, precision: Int = PRECISION) raises -> Self:
        """Returns the cube root of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.cbrt(self, precision)

    @always_inline
    fn power(self, exponent: Self, precision: Int = PRECISION) raises -> Self:
        """Returns the result of exponentiation with the given precision.
        See `exponential.power()` for more information.
        """
        return decimojo.bigdecimal.exponential.power(self, exponent, precision)

    # === Trigonometric operations === #
    @always_inline
    fn sin(self, precision: Int = PRECISION) raises -> Self:
        """Returns the sine of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.sin(self, precision)

    @always_inline
    fn cos(self, precision: Int = PRECISION) raises -> Self:
        """Returns the cosine of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.cos(self, precision)

    @always_inline
    fn tan(self, precision: Int = PRECISION) raises -> Self:
        """Returns the tangent of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.tan(self, precision)

    @always_inline
    fn cot(self, precision: Int = PRECISION) raises -> Self:
        """Returns the cotangent of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.cot(self, precision)

    @always_inline
    fn csc(self, precision: Int = PRECISION) raises -> Self:
        """Returns the cosecant of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.csc(self, precision)

    @always_inline
    fn sec(self, precision: Int = PRECISION) raises -> Self:
        """Returns the secant of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.sec(self, precision)

    @always_inline
    fn arctan(self, precision: Int = PRECISION) raises -> Self:
        """Returns the arctangent of the BigDecimal number."""
        return decimojo.bigdecimal.trigonometric.arctan(self, precision)

    # === Arithmetic operations === #

    @always_inline
    fn true_divide(
        self, other: Self, precision: Int = PRECISION
    ) raises -> Self:
        """Returns the result of true division of two BigDecimal numbers.
        See `arithmetics.true_divide()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.true_divide(
            self, other, precision
        )

    @always_inline
    fn true_divide_inexact(
        self, other: Self, number_of_significant_digits: Int
    ) raises -> Self:
        """Returns the result of true division with inexact precision.
        See `arithmetics.true_divide_inexact()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.true_divide_inexact(
            self, other, number_of_significant_digits
        )

    @always_inline
    fn true_divide_inexact_by_uint32(
        self, y: UInt32, number_of_significant_digits: Int
    ) raises -> Self:
        """Returns the result of division by a small UInt32 integer.
        See `arithmetics.true_divide_inexact_by_uint32()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.true_divide_inexact_by_uint32(
            self, y, number_of_significant_digits
        )

    @always_inline
    fn truncate_divide(self, other: Self) raises -> Self:
        """Returns the result of truncating division of two BigDecimal numbers.
        See `arithmetics.truncate_divide()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.truncate_divide(self, other)

    # === Rounding operations === #

    @always_inline
    fn round(
        self,
        ndigits: Int,
        rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
    ) raises -> Self:
        """Rounds the number to the specified number of decimal places.

        Args:
            ndigits: Number of decimal places to round to.
            rounding_mode: Rounding mode to use. Default is `ROUND_HALF_EVEN`.
                RoundingMode.ROUND_DOWN: Round down.
                RoundingMode.ROUND_UP: Round up.
                RoundingMode.ROUND_HALF_UP: Round half up.
                RoundingMode.ROUND_HALF_EVEN: Round half even.

        Notes:
            If `ndigits` is negative, the last `ndigits` digits of the integer part of
            the number will be dropped and the scale will be `ndigits`.
            Examples:
                round(123.456, 2) -> 123.46
                round(123.456, -1) -> 12E+1
                round(123.456, -2) -> 1E+2
                round(123.456, -3) -> 0E+3
                round(678.890, -3) -> 1E+3
        """
        return decimojo.bigdecimal.rounding.round(self, ndigits, rounding_mode)

    @always_inline
    fn round_to_precision(
        mut self,
        precision: Int,
        rounding_mode: RoundingMode,
        remove_extra_digit_due_to_rounding: Bool,
        fill_zeros_to_precision: Bool,
    ) raises:
        """Rounds the number to the specified precision in-place.

        Notes:

        Note that precision is the number of significant digits,
        not the number of decimal places. If you want to round to a
        specific number of decimal places, use `round()` instead.

        See `rounding.round_to_precision()` for more information.
        """
        decimojo.bigdecimal.rounding.round_to_precision(
            self,
            precision,
            rounding_mode,
            remove_extra_digit_due_to_rounding,
            fill_zeros_to_precision,
        )

    @always_inline
    fn quantize(
        self,
        exp: Self,
        rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
    ) raises -> Self:
        """Rounds this BigDecimal according to the scale of another BigDecimal.

        This method adjusts the scale (exponent) of this number to match the
        scale of `exp`, performing rounding if necessary. Unlike `round()`,
        which specifies the number of decimal places, `quantize()` uses the
        scale of another decimal as a template.

        Args:
            exp: A BigDecimal whose scale will be used as the target scale.
                The actual value of `exp` is ignored; only its scale matters.
            rounding_mode: The rounding mode to use. Default is ROUND_HALF_EVEN.

        Returns:
            A new BigDecimal with the same value (subject to rounding) and
            the same scale as `exp`.

        Examples:

        ```mojo
        from decimojo import BigDecimal

        var x = BigDecimal("1.2345")

        # Use different scale templates
        print(x.quantize(BigDecimal("0.01")))   # "1.23" (scale=2)
        print(x.quantize(BigDecimal("0.1")))    # "1.2"  (scale=1)
        print(x.quantize(BigDecimal("1")))      # "1"    (scale=0)

        # Important: \"100\" and \"1E+2\" have different scales!
        print(x.quantize(BigDecimal("100")))    # "1"    (scale=0, same as above)
        print(x.quantize(BigDecimal("1E+2")))   # "0"    (scale=-2, rounds to hundreds)

        # Align currency amounts
        var price = BigDecimal("19.999")
        var cent = BigDecimal("0.01")
        print(price.quantize(cent))  # "20.00" (rounded to cents)
        ```

        Notes:
            See `decimojo.bigdecimal.rounding.quantize()` for detailed examples
            and technical information.
        """
        return decimojo.bigdecimal.rounding.quantize(self, exp, rounding_mode)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    fn exponent(self) -> Int:
        """Returns the exponent of the number in scientific notation.

        Notes:

        123.45 (coefficient = 12345, scale = 2) is represented as 1.2345E+2.
        0.00123 (coefficient = 123, scale = 5) is represented as 1.23E-3.
        123000 (coefficient = 123, scale = -3) is represented as 1.23E+5.
        """
        return self.coefficient.number_of_digits() - 1 - self.scale

    fn extend_precision(self, precision_diff: Int) -> Self:
        """Returns a number with additional decimal places (trailing zeros).
        This multiplies the coefficient by 10^precision_diff and increases
        the scale accordingly, preserving the numeric value.
        If `precision_diff` is negative, nothing is done and the
        original number is returned.

        Args:
            precision_diff: The number of decimal places to add, which must be
                non-negative.

        Returns:
            A new BigDecimal with increased precision.

        Notes:

        In debug mode, negative `precision_diff` raises an assertion error.

        Examples:

        ```
        print(BigDecimal("123.456").extend_precision(5))  # Output: 123.45600000
        print(BigDecimal("123456").extend_precision(3))  # Output: 123456.000
        print(BigDecimal("123456").extend_precision(-1))  # Output: 123456 (no change)
        ```
        """
        debug_assert(
            precision_diff >= 0,
            "bigdecimal.BigDecimal.extend_precision(): ",
            "precision_diff must be non-negative, got: ",
            precision_diff,
        )

        if precision_diff <= 0:
            return self.copy()

        return Self(
            decimojo.biguint.arithmetics.multiply_by_power_of_ten(
                self.coefficient, precision_diff
            ),
            self.scale + precision_diff,
            self.sign,
        )

    fn extend_precision_inplace(mut self, precision_diff: Int):
        """Add additional decimal places (trailing zeros) in-place.
        This multiplies the coefficient by 10^precision_diff and increases
        the scale accordingly, preserving the numeric value.
        If `precision_diff` is negative, nothing is done and the
        original number is returned.

        Args:
            precision_diff: The number of decimal places to add, which must be
                non-negative.

        Notes:

        In debug mode, negative `precision_diff` raises an assertion error.

        Examples:
        ```
        BigDecimal("123.456).extend_precision_inplace(5)  # Output: 123.45600000
        BigDecimal("123456").extend_precision_inplace(3)  # Output: 123456.000
        BigDecimal("123456").extend_precision_inplace(-1)  # Output: 123456 (no change)
        ```
        """
        debug_assert(
            precision_diff >= 0,
            "bigdecimal.BigDecimal.extend_precision(): ",
            "precision_diff must be non-negative, got: ",
            precision_diff,
        )

        if precision_diff <= 0:
            return

        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_ten(
            self.coefficient, precision_diff
        )
        self.scale += precision_diff

    fn print_internal_representation(self):
        """Prints the internal representation of the BigDecimal."""
        var line_width = 30
        var string_of_number = self.to_string(line_width=line_width).split("\n")
        var string_of_coefficient = self.coefficient.to_string(
            line_width=line_width
        ).split("\n")
        print("\nInternal Representation Details of BigDecimal")
        print("----------------------------------------------")
        print("number:         ", end="")
        for i in range(0, len(string_of_number)):
            if i > 0:
                print(" " * 16, end="")
            print(string_of_number[i])
        print("coefficient:    ", end="")
        for i in range(0, len(string_of_coefficient)):
            if i > 0:
                print(" " * 16, end="")
            print(String(string_of_coefficient[i]))
        print("negative:      ", self.sign)
        print("scale:         ", self.scale)
        for i in range(len(self.coefficient.words)):
            var ndigits = 1
            if i < 10:
                pass
            elif i < 100:
                ndigits = 2
            else:
                ndigits = 3
            print(
                String(
                    "word ",
                    i,
                    ":",
                    " " * (10 - ndigits),
                    self.coefficient.words[i],
                ).rjust(9, fillchar="0")
            )
        print("----------------------------------------------")

    fn print_representation_as_components(self):
        """Prints the representation of the BigDecimal as components."""
        print(
            (
                "BigDecimal(\n    coefficient=BigUInt(\n       "
                " words=List[UInt32](\n            "
            ),
            end="",
        )
        ref words = self.coefficient.words
        for i in range(len(words)):
            if i != len(words) - 1:
                print(words[i], end=",\n            ")
            else:
                print(words[i], end=",\n        ),\n    ),\n")
        print(
            "    scale=",
            self.scale,
            ",\n    sign=",
            self.sign,
            ")",
            sep="",
        )

    fn is_integer(self) -> Bool:
        """Returns True if this number represents an integer value."""
        var number_of_trailing_zeros = self.number_of_trailing_zeros()
        if number_of_trailing_zeros >= self.scale:
            return True
        else:
            return False

    @always_inline
    fn is_negative(self) -> Bool:
        """Returns True if this number represents a negative value."""
        return self.sign

    fn is_odd(self) raises -> Bool:
        """Returns True if this number represents an odd value."""
        if self.scale < 0:
            return False

        var cutoff_digit = self.coefficient.ith_digit(self.scale)
        if cutoff_digit % 2 == 0:
            return False
        else:
            return True

    fn is_one(self) raises -> Bool:
        """Returns True if this number represents one."""
        if self.sign:
            return False
        if self.scale < 0:
            return False
        var number_of_digits = self.coefficient.number_of_digits()
        if number_of_digits - self.scale != 1:
            return False
        if number_of_digits - self.number_of_trailing_zeros() != 1:
            return False
        if self.coefficient.ith_digit(self.scale) != 1:
            return False
        return True

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this number represents zero."""
        return self.coefficient.is_zero()

    fn normalize(self) raises -> Self:
        """Removes trailing zeros from coefficient while adjusting scale.

        For example,
        1.2345000 (coefficient = 123450000, scale = 7) is normalized to
        1.2345 (coefficient = 12345, scale = 4).

        Notes:

        Only call it when necessary. Do not normalize after every operation.
        The information conveyed by trailing zeros in the coefficient may be
        useful for some applications, as it indicates the precision of the
        number. Normalization may cause loss of this information.
        """
        if self.coefficient.is_zero():
            return Self(BigUInt(raw_words=[0]), 0, False)

        var number_of_digits_to_remove = self.number_of_trailing_zeros()

        var number_of_words_to_remove = number_of_digits_to_remove // 9
        var number_of_remaining_digits_to_remove = (
            number_of_digits_to_remove % 9
        )

        words = List[UInt32](self.coefficient.words[number_of_words_to_remove:])
        var coefficient = BigUInt(raw_words=words^)

        if number_of_remaining_digits_to_remove == 0:
            pass
        elif number_of_remaining_digits_to_remove == 1:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(10)])
        elif number_of_remaining_digits_to_remove == 2:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(100)])
        elif number_of_remaining_digits_to_remove == 3:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(1_000)])
        elif number_of_remaining_digits_to_remove == 4:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(10_000)])
        elif number_of_remaining_digits_to_remove == 5:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(100_000)])
        elif number_of_remaining_digits_to_remove == 6:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(1_000_000)])
        elif number_of_remaining_digits_to_remove == 7:
            coefficient = coefficient // BigUInt(raw_words=[UInt32(10_000_000)])
        else:  # number_of_remaining_digits_to_remove == 8
            coefficient = coefficient // BigUInt(
                raw_words=[UInt32(100_000_000)]
            )

        return Self(
            coefficient,
            self.scale - number_of_digits_to_remove,
            self.sign,
        )

    fn number_of_trailing_zeros(self) -> Int:
        """Returns the number of trailing zeros in the coefficient."""
        if self.coefficient.is_zero():
            return 0

        # Count trailing zero words
        var number_of_zero_words = 0
        while self.coefficient.words[number_of_zero_words] == UInt32(0):
            number_of_zero_words += 1

        # Count trailing zeros in the last non-zero word
        var number_of_trailing_zeros = 0
        var last_non_zero_word = self.coefficient.words[number_of_zero_words]
        while (last_non_zero_word % UInt32(10)) == 0:
            last_non_zero_word = last_non_zero_word // UInt32(10)
            number_of_trailing_zeros += 1

        return number_of_zero_words * 9 + number_of_trailing_zeros
