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


@value
struct BigDecimal:
    """Represents a arbitrary-precision decimal.

    Notes:

    Internal Representation:

    - A base-10 unsigned integer (BigUInt) for magnitude.
    - A Int value for the scale
    - A Bool value for the sign.

    Final value:
    (-1)**sign * magnitude * 10^(-scale)
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
    var magnitude: BigUInt
    """The magnitude of the BigDecimal."""
    var scale: Int
    """The scale of the BigDecimal."""
    var sign: Bool
    """Sign information."""

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self, magnitude: BigUInt, scale: Int, sign: Bool) raises:
        """Constructs a BigDecimal from its components."""
        self.magnitude = magnitude
        self.scale = scale
        self.sign = sign

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # from_string(value: String) -> Self
    # ===------------------------------------------------------------------=== #

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

        magnitude = BigUInt.from_string(value, ignore_sign=True)

        return Self(magnitude^, scale, sign)

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __str__(self) -> String:
        """Returns string representation of the BigDecimal.
        See `to_string()` for more information.
        """
        return self.to_string()

    fn __repr__(self) -> String:
        """Returns a string representation of the BigDecimal."""
        return 'BigDecimal("' + self.__str__() + '")'

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn to_string(self) -> String:
        """Returns string representation of the number."""

        if self.magnitude.is_unitialized():
            return String("Unitilialized maginitude of BigDecimal")

        var result = String("-") if self.sign else String("")

        var magnitude_string = self.magnitude.to_string()

        if self.scale == 0:
            result += magnitude_string

        elif self.scale > 0:
            if self.scale < len(magnitude_string):
                # Example: 123_456 with scale 3 -> 123.456
                result += magnitude_string[: len(magnitude_string) - self.scale]
                result += "."
                result += magnitude_string[len(magnitude_string) - self.scale :]
            else:
                # Example: 123_456 with scale 6 -> 0.123_456
                # Example: 123_456 with scale 7 -> 0.012_345_6
                result += "0."
                result += "0" * (self.scale - len(magnitude_string))
                result += magnitude_string

        else:
            # scale < 0
            # Example: 12_345 with scale -3 -> 12_345_000
            result += magnitude_string
            result += "0" * (-self.scale)

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
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this number represents zero."""
        return self.magnitude.is_zero()
