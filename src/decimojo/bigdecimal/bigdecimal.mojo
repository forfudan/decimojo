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
import testing

from decimojo.rounding_mode import RoundingMode
from decimojo.bigdecimal.rounding import round_to_precision

alias BigDec = BigDecimal
alias BDec = BigDecimal


@value
struct BigDecimal(
    Absable, Comparable, IntableRaising, Roundable, Stringable, Writable
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

    fn __init__(out self, coefficient: BigUInt, scale: Int, sign: Bool):
        """Constructs a BigDecimal from its components."""
        self.coefficient = coefficient
        self.scale = scale
        self.sign = sign

    @implicit
    fn __init__(out self, value: BigInt):
        """Constructs a BigDecimal from a big interger."""
        self.coefficient = value.magnitude
        self.scale = 0
        self.sign = value.sign

    fn __init__(out self, value: String) raises:
        """Constructs a BigDecimal from a string representation."""
        # The string is normalized with `deciomojo.str.parse_numeric_string()`.
        self = Self.from_string(value)

    @implicit
    fn __init__(out self, value: Int):
        """Constructs a BigDecimal from an integer."""
        self = Self.from_int(value)

    fn __init__(out self, value: Scalar) raises:
        """Constructs a BigDecimal from a Mojo Scalar."""
        self = Self.from_scalar(value)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # from_int(value: Int) -> Self
    # from_scalar(value: Scalar) -> Self
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_raw_components(
        coefficient: BigUInt, scale: Int = 0, sign: Bool = False
    ) -> Self:
        """Creates a BigDecimal from its raw components."""
        return Self(coefficient, scale, sign)

    @staticmethod
    fn from_raw_components(
        coefficient: UInt32, scale: Int = 0, sign: Bool = False
    ) -> Self:
        """Creates a BigDecimal from its raw components."""
        return Self(BigUInt(List[UInt32](coefficient)), scale, sign)

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Creates a BigDecimal from an integer."""
        if value == 0:
            return Self(coefficient=BigUInt.ZERO, scale=0, sign=False)

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

        return Self(coefficient=BigUInt(words^), scale=0, sign=sign)

    @staticmethod
    fn from_scalar[dtype: DType, //](value: Scalar[dtype]) raises -> Self:
        """Initializes a BigDecimal from a Mojo Scalar.

        Args:
            value: The Scalar value to be converted to BigDecimal.

        Returns:
            The BigDecimal representation of the Scalar value.

        Notes:

        If the value is a floating-point number, it is converted to a string
        with full precision before converting to BigDecimal.
        """
        var sign = True if value < 0 else False

        @parameter
        if dtype.is_integral():
            var list_of_words = List[UInt32]()
            var remainder: Scalar[dtype] = value
            var quotient: Scalar[dtype]
            var is_min = False

            if sign:
                var min_value: Scalar[dtype]
                var max_value: Scalar[dtype]

                # TODO: Currently Int256 is not supported due to the limitation
                # of Mojo's standard library. The following part can be removed
                # if `mojo/stdlib/src/utils/numerics.mojo` is updated.
                @parameter
                if dtype == DType.int128:
                    min_value = Scalar[dtype](
                        -170141183460469231731687303715884105728
                    )
                    max_value = Scalar[dtype](
                        170141183460469231731687303715884105727
                    )
                elif dtype == DType.int64:
                    min_value = Scalar[dtype].MIN
                    max_value = Scalar[dtype].MAX
                elif dtype == DType.int32:
                    min_value = Scalar[dtype].MIN
                    max_value = Scalar[dtype].MAX
                elif dtype == DType.int16:
                    min_value = Scalar[dtype].MIN
                    max_value = Scalar[dtype].MAX
                elif dtype == DType.int8:
                    min_value = Scalar[dtype].MIN
                    max_value = Scalar[dtype].MAX
                else:
                    raise Error(
                        "Error in `from_scalar()`: Unsupported integral type"
                    )

                if value == min_value:
                    remainder = max_value
                    is_min = True
                else:
                    remainder = -value

            while remainder != 0:
                quotient = remainder // 1_000_000_000
                remainder = remainder % 1_000_000_000
                list_of_words.append(UInt32(remainder))
                remainder = quotient

            if is_min:
                list_of_words[0] += 1

            return Self(coefficient=BigUInt(list_of_words^), scale=0, sign=sign)

        else:  # floating-point
            if value != value:  # Check for NaN
                raise Error(
                    "Error in `from_scalar()`: Cannot convert NaN to BigUInt"
                )
            # Convert to string with full precision
            try:
                return Self.from_string(String(value))
            except e:
                raise Error("Error in `from_scalar()`: ", e)

        return Self(
            coefficient=BigUInt(UInt32(0)), scale=0, sign=sign
        )  # Default case

    @staticmethod
    fn from_string(value: String) raises -> Self:
        """Initializes a BigDecimal from a string representation.
        The string is normalized with `deciomojo.str.parse_numeric_string()`.

        Args:
            value: The string representation of the BigDecimal.

        Returns:
            The BigDecimal representation of the string.
        """
        var coef: List[UInt8]
        var scale: Int
        var sign: Bool
        coef, scale, sign = decimojo.str.parse_numeric_string(value)

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

        coefficient = BigUInt(coefficient_words^)

        return Self(coefficient^, scale, sign)

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
        var exponent = self.coefficient.number_of_digits() - 1 - self.scale
        var exponent_ge_precision = exponent >= precision
        var leading_zeros_too_many = exponent <= Int(-6)
        var negative_scale = self.scale < 0

        if (
            scientific_notation
            or exponent_ge_precision
            or leading_zeros_too_many
            or negative_scale
        ):
            # Use scientific notation
            var exponent_string = String(exponent)
            result += coefficient_string[0]
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
                lines.append(result[start:end])
                start = end
                end += line_width
            lines.append(result[start:])
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
    fn __mul__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.multiply(self, other)

    @always_inline
    fn __truediv__(self, other: Self) raises -> Self:
        return decimojo.bigdecimal.arithmetics.true_divide(
            self, other, precision=28
        )

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        """Returns the result of floor division.
        See `arithmetics.truncate_divide()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.truncate_divide(self, other)

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        """Returns the result of exponentiation."""
        return decimojo.bigdecimal.exponential.power(
            self, exponent, precision=28
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
            other, self, precision=28
        )

    @always_inline
    fn __rpow__(self, base: Self) raises -> Self:
        return decimojo.bigdecimal.exponential.power(base, self, precision=28)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self) raises:
        self = decimojo.bigdecimal.arithmetics.add(self, other)

    @always_inline
    fn __isub__(mut self, other: Self) raises:
        self = decimojo.bigdecimal.arithmetics.subtract(self, other)

    @always_inline
    fn __imul__(mut self, other: Self) raises:
        self = decimojo.bigdecimal.arithmetics.multiply(self, other)

    @always_inline
    fn __itruediv__(mut self, other: Self) raises:
        self = decimojo.bigdecimal.arithmetics.true_divide(
            self, other, precision=28
        )

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: BigDecimal) -> Bool:
        """Returns whether self is greater than other."""
        return decimojo.bigdecimal.comparison.compare(self, other) > 0

    @always_inline
    fn __ge__(self, other: BigDecimal) -> Bool:
        """Returns whether self is greater than or equal to other."""
        return decimojo.bigdecimal.comparison.compare(self, other) >= 0

    @always_inline
    fn __lt__(self, other: BigDecimal) -> Bool:
        """Returns whether self is less than other."""
        return decimojo.bigdecimal.comparison.compare(self, other) < 0

    @always_inline
    fn __le__(self, other: BigDecimal) -> Bool:
        """Returns whether self is less than or equal to other."""
        return decimojo.bigdecimal.comparison.compare(self, other) <= 0

    @always_inline
    fn __eq__(self, other: BigDecimal) -> Bool:
        """Returns whether self equals other."""
        return decimojo.bigdecimal.comparison.compare(self, other) == 0

    @always_inline
    fn __ne__(self, other: BigDecimal) -> Bool:
        """Returns whether self does not equal other."""
        return decimojo.bigdecimal.comparison.compare(self, other) != 0

    # ===------------------------------------------------------------------=== #
    # Other dunders that implements traits
    # round
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __round__(self, ndigits: Int) -> Self:
        """Rounds the number to the specified number of decimal places.
        If `ndigits` is not given, rounds to 0 decimal places.
        If rounding causes errors, returns the value itself.
        """
        try:
            return decimojo.bigdecimal.rounding.round(
                self,
                ndigits=ndigits,
                rounding_mode=RoundingMode.ROUND_HALF_EVEN,
            )
        except e:
            return self

    @always_inline
    fn __round__(self) -> Self:
        """Rounds the number to the specified number of decimal places.
        If `ndigits` is not given, rounds to 0 decimal places.
        If rounding causes errors, returns the value itself.
        """
        try:
            return decimojo.bigdecimal.rounding.round(
                self, ndigits=0, rounding_mode=RoundingMode.ROUND_HALF_EVEN
            )
        except e:
            return self

    # ===------------------------------------------------------------------=== #
    # Other dunders
    # ===------------------------------------------------------------------=== #

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

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

    @always_inline
    fn exp(self, precision: Int = 28) raises -> Self:
        """Returns the exponential of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.exp(self, precision)

    @always_inline
    fn ln(self, precision: Int = 28) raises -> Self:
        """Returns the natural logarithm of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.ln(self, precision)

    @always_inline
    fn log(self, base: Self, precision: Int = 28) raises -> Self:
        """Returns the logarithm of the BigDecimal number with the given base.
        """
        return decimojo.bigdecimal.exponential.log(self, base, precision)

    @always_inline
    fn log10(self, precision: Int = 28) raises -> Self:
        """Returns the base-10 logarithm of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.log10(self, precision)

    @always_inline
    fn max(self, other: Self) raises -> Self:
        """Returns the maximum of two BigDecimal numbers."""
        return decimojo.bigdecimal.comparison.max(self, other)

    @always_inline
    fn min(self, other: Self) raises -> Self:
        """Returns the minimum of two BigDecimal numbers."""
        return decimojo.bigdecimal.comparison.min(self, other)

    @always_inline
    fn root(self, root: Self, precision: Int = 28) raises -> Self:
        """Returns the root of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.root(self, root, precision)

    @always_inline
    fn sqrt(self, precision: Int = 28) raises -> Self:
        """Returns the square root of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.sqrt(self, precision)

    @always_inline
    fn cbrt(self, precision: Int = 28) raises -> Self:
        """Returns the cube root of the BigDecimal number."""
        return decimojo.bigdecimal.exponential.cbrt(self, precision)

    @always_inline
    fn true_divide(self, other: Self, precision: Int) raises -> Self:
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
    fn truncate_divide(self, other: Self) raises -> Self:
        """Returns the result of truncating division of two BigDecimal numbers.
        See `arithmetics.truncate_divide()` for more information.
        """
        return decimojo.bigdecimal.arithmetics.truncate_divide(self, other)

    @always_inline
    fn power(self, exponent: Self, precision: Int) raises -> Self:
        """Returns the result of exponentiation with the given precision.
        See `exponential.power()` for more information.
        """
        return decimojo.bigdecimal.exponential.power(self, exponent, precision)

    @always_inline
    fn round(self, ndigits: Int, rounding_mode: RoundingMode) raises -> Self:
        """Rounds the number to the specified precision.
        See `bigdecimal.rounding.round()` for more information.
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
        See `rounding.round_to_precision()` for more information.
        """
        decimojo.bigdecimal.rounding.round_to_precision(
            self,
            precision,
            rounding_mode,
            remove_extra_digit_due_to_rounding,
            fill_zeros_to_precision,
        )

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

    fn extend_precision(self, precision_diff: Int) raises -> BigDecimal:
        """Returns a number with additional decimal places (trailing zeros).
        This multiplies the coefficient by 10^precision_diff and increases
        the scale accordingly, preserving the numeric value.

        Args:
            precision_diff: The number of decimal places to add.

        Returns:
            A new BigDecimal with increased precision.

        Examples:
        ```
        print(BigDecimal("123.456).scale_up(5))  # Output: 123.45600000
        print(BigDecimal("123456").scale_up(3))  # Output: 123456.000
        print(BigDecimal("123456").scale_up(-1))  # Error!
        ```
        End of examples.
        """
        if precision_diff < 0:
            raise Error(
                "Error in `extend_precision()`: "
                "Cannot extend precision with negative value"
            )

        if precision_diff == 0:
            return self

        var number_of_words_to_add = precision_diff // 9
        var number_of_remaining_digits_to_add = precision_diff % 9

        var coefficient = self.coefficient

        if number_of_remaining_digits_to_add == 0:
            pass
        elif number_of_remaining_digits_to_add == 1:
            coefficient = coefficient * BigUInt(UInt32(10))
        elif number_of_remaining_digits_to_add == 2:
            coefficient = coefficient * BigUInt(UInt32(100))
        elif number_of_remaining_digits_to_add == 3:
            coefficient = coefficient * BigUInt(UInt32(1_000))
        elif number_of_remaining_digits_to_add == 4:
            coefficient = coefficient * BigUInt(UInt32(10_000))
        elif number_of_remaining_digits_to_add == 5:
            coefficient = coefficient * BigUInt(UInt32(100_000))
        elif number_of_remaining_digits_to_add == 6:
            coefficient = coefficient * BigUInt(UInt32(1_000_000))
        elif number_of_remaining_digits_to_add == 7:
            coefficient = coefficient * BigUInt(UInt32(10_000_000))
        else:  # number_of_remaining_digits_to_add == 8
            coefficient = coefficient * BigUInt(UInt32(100_000_000))

        var words: List[UInt32] = List[UInt32]()
        for _ in range(number_of_words_to_add):
            words.append(UInt32(0))
        words.extend(coefficient.words)

        return BigDecimal(
            BigUInt(words^),
            self.scale + precision_diff,
            self.sign,
        )

    @always_inline
    fn internal_representation(self) raises:
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
                String("word {}:{}{}")
                .format(
                    i, " " * (10 - ndigits), String(self.coefficient.words[i])
                )
                .rjust(9, fillchar="0")
            )
        print("----------------------------------------------")

    @always_inline
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

    @always_inline
    fn is_odd(self) raises -> Bool:
        """Returns True if this number represents an odd value."""
        if self.scale < 0:
            return False

        var cutoff_digit = self.coefficient.ith_digit(self.scale)
        if cutoff_digit % 2 == 0:
            return False
        else:
            return True

    @always_inline
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

    fn normalize(self) raises -> BigDecimal:
        """Removes trailing zeros from coefficient while adjusting scale.

        Notes:

        Only call it when necessary. Do not normalize after every operation.
        """
        if self.coefficient.is_zero():
            return BigDecimal(BigUInt(UInt32(0)), 0, False)

        var number_of_digits_to_remove = self.number_of_trailing_zeros()

        var number_of_words_to_remove = number_of_digits_to_remove // 9
        var number_of_remaining_digits_to_remove = (
            number_of_digits_to_remove % 9
        )

        words = self.coefficient.words[number_of_words_to_remove:]
        var coefficient = BigUInt(words^)

        if number_of_remaining_digits_to_remove == 0:
            pass
        elif number_of_remaining_digits_to_remove == 1:
            coefficient = coefficient // BigUInt(UInt32(10))
        elif number_of_remaining_digits_to_remove == 2:
            coefficient = coefficient // BigUInt(UInt32(100))
        elif number_of_remaining_digits_to_remove == 3:
            coefficient = coefficient // BigUInt(UInt32(1_000))
        elif number_of_remaining_digits_to_remove == 4:
            coefficient = coefficient // BigUInt(UInt32(10_000))
        elif number_of_remaining_digits_to_remove == 5:
            coefficient = coefficient // BigUInt(UInt32(100_000))
        elif number_of_remaining_digits_to_remove == 6:
            coefficient = coefficient // BigUInt(UInt32(1_000_000))
        elif number_of_remaining_digits_to_remove == 7:
            coefficient = coefficient // BigUInt(UInt32(10_000_000))
        else:  # number_of_remaining_digits_to_remove == 8
            coefficient = coefficient // BigUInt(UInt32(100_000_000))

        return BigDecimal(
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
