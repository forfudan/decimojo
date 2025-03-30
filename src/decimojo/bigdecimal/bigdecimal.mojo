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

alias BDec = BigDecimal


@value
struct BigDecimal:
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

    fn __init__(out self, value: String) raises:
        """Constructs a BigDecimal from a string representation."""
        # The string is normalized with `deciomojo.str.parse_numeric_string()`.
        self = Self.from_string(value)

    fn __init__(out self, value: Int) raises:
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
    fn from_int(value: Int) raises -> Self:
        """Creates a BigDecimal from an integer."""
        if value == 0:
            return Self(coefficient=BigUInt(UInt32(0)), scale=0, sign=False)

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
                word = word * 10 + UInt32(digit[])
            coefficient_words.append(word)
            end = start
        if end > 0:
            var word: UInt32 = 0
            for digit in coef[0:end]:
                word = word * 10 + UInt32(digit[])
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
        self, threshold_scientific: Int = 28, line_width: Int = 0
    ) -> String:
        """Returns string representation of the number.

        Args:
            threshold_scientific: The threshold for scientific notation.
                If the digits to display is greater than this value,
                the number is represented in scientific notation.
            line_width: The maximum line width for the string representation.
                If 0, the string is returned as a single line.
                If greater than 0, the string is split into multiple lines.

        Returns:
            A string representation of the number.
        """

        if self.coefficient.is_unitialized():
            return String("Unitilialized maginitude of BigDecimal")

        var result = String("-") if self.sign else String("")

        var coefficient_string = self.coefficient.to_string()

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
        return decimojo.bigdecimal.arithmetics.true_divide(self, other)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

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
                "word {}:{}{}".format(
                    i, " " * (10 - ndigits), String(self.coefficient.words[i])
                ).rjust(9, fillchar="0")
            )
        print("----------------------------------------------")

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
        var number_of_remaining_digits_to_remove = number_of_digits_to_remove % 9

        var words: List[UInt32] = List[UInt32]()
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
