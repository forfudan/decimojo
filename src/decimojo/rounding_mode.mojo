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

alias RM = RoundingMode


struct RoundingMode(Stringable):
    """
    Represents different rounding modes for decimal operations.

    Available modes:
    - DOWN: Truncate (toward zero)
    - HALF_UP: Round away from zero if >= 0.5
    - HALF_EVEN: Round to nearest even digit if equidistant (banker's rounding)
    - UP: Round away from zero

    Notes:

    Currently, enum is not available in Mojo. This module provides a workaround
    to define a custom enum-like class for rounding modes.
    """

    # alias
    alias ROUND_DOWN = Self.down()
    alias ROUND_HALF_UP = Self.half_up()
    alias ROUND_HALF_EVEN = Self.half_even()
    alias ROUND_UP = Self.up()

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

    fn __init__(out self, value: Int):
        self.value = value

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __eq__(self, other: String) -> Bool:
        return String(self) == other

    fn __str__(self) -> String:
        if self == Self.ROUND_DOWN:
            return "ROUND_DOWN"
        elif self == Self.ROUND_HALF_UP:
            return "ROUND_HALF_UP"
        elif self == Self.ROUND_HALF_EVEN:
            return "ROUND_HALF_EVEN"
        elif self == Self.ROUND_UP:
            return "ROUND_UP"
        else:
            return "UNKNOWN_ROUNDING_MODE"
