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

"""Implements the RoundingMode for different rounding modes.
"""

comptime ROUND_DOWN = RoundingMode.ROUND_DOWN
"""Rounding mode: Truncate (toward zero)."""
comptime ROUND_HALF_UP = RoundingMode.ROUND_HALF_UP
"""Rounding mode: Round away from zero if >= 0.5."""
comptime ROUND_HALF_EVEN = RoundingMode.ROUND_HALF_EVEN
"""Rounding mode: Round to nearest even digit if equidistant (banker's rounding)."""
comptime ROUND_UP = RoundingMode.ROUND_UP
"""Rounding mode: Round away from zero."""
comptime ROUND_CEILING = RoundingMode.ROUND_CEILING
"""Rounding mode: Round toward positive infinity."""
comptime ROUND_FLOOR = RoundingMode.ROUND_FLOOR
"""Rounding mode: Round toward negative infinity."""


struct RoundingMode(Copyable, ImplicitlyCopyable, Movable, Stringable):
    """
    Represents different rounding modes for decimal operations.

    Available modes:
    - DOWN: Truncate (toward zero)
    - HALF_UP: Round away from zero if >= 0.5
    - HALF_EVEN: Round to nearest even digit if equidistant (banker's rounding)
    - UP: Round away from zero
    - CEILING: Round toward positive infinity
    - FLOOR: Round toward negative infinity

    Notes:

    Currently, enum is not available in Mojo. This module provides a workaround
    to define a custom enum-like class for rounding modes.
    """

    # alias
    comptime ROUND_DOWN = Self.down()
    comptime ROUND_HALF_UP = Self.half_up()
    comptime ROUND_HALF_EVEN = Self.half_even()
    comptime ROUND_UP = Self.up()
    comptime ROUND_CEILING = Self.ceiling()
    comptime ROUND_FLOOR = Self.floor()

    # Internal value
    var value: Int
    """Internal value representing the rounding mode."""

    # Static constants for each rounding mode
    @staticmethod
    fn down() -> Self:
        """Truncate (toward zero)."""
        return Self(0)

    @staticmethod
    fn half_up() -> Self:
        """Round away from zero if >= 0.5."""
        return Self(1)

    @staticmethod
    fn half_even() -> Self:
        """Round to nearest even digit if equidistant (banker's rounding)."""
        return Self(2)

    @staticmethod
    fn up() -> Self:
        """Round away from zero."""
        return Self(3)

    @staticmethod
    fn ceiling() -> Self:
        """Round toward positive infinity."""
        return Self(4)

    @staticmethod
    fn floor() -> Self:
        """Round toward negative infinity."""
        return Self(5)

    fn __init__(out self, value: Int):
        self.value = value

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __eq__(self, other: String) -> Bool:
        return String(self) == other

    fn __str__(self) -> String:
        if self == Self.down():
            return "ROUND_DOWN"
        elif self == Self.half_up():
            return "ROUND_HALF_UP"
        elif self == Self.half_even():
            return "ROUND_HALF_EVEN"
        elif self == Self.up():
            return "ROUND_UP"
        elif self == Self.ceiling():
            return "ROUND_CEILING"
        elif self == Self.floor():
            return "ROUND_FLOOR"
        else:
            return "UNKNOWN_ROUNDING_MODE"
