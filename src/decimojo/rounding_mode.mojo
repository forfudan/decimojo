# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #


struct RoundingMode:
    """
    Represents different rounding modes for decimal operations.

    Available modes:
    - DOWN: Truncate (toward zero)
    - HALF_UP: Round away from zero if >= 0.5
    - HALF_EVEN: Round to nearest even digit if equidistant (banker's rounding)
    - UP: Round away from zero
    """

    # alias
    alias ROUND_DOWN = Self.DOWN()
    alias ROUND_HALF_UP = Self.HALF_UP()
    alias ROUND_HALF_EVEN = Self.HALF_EVEN()
    alias ROUND_UP = Self.UP()

    # Internal value
    var value: Int
    """Internal value representing the rounding mode."""

    # Static constants for each rounding mode
    @staticmethod
    fn DOWN() -> Self:
        """Truncate (toward zero)."""
        return Self(0)

    @staticmethod
    fn HALF_UP() -> Self:
        """Round away from zero if >= 0.5."""
        return Self(1)

    @staticmethod
    fn HALF_EVEN() -> Self:
        """Round to nearest even digit if equidistant (banker's rounding)."""
        return Self(2)

    @staticmethod
    fn UP() -> Self:
        """Round away from zero."""
        return Self(3)

    fn __init__(out self, value: Int):
        self.value = value

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __eq__(self, other: String) -> Bool:
        return String(self) == other

    fn __str__(self) -> String:
        if self == Self.DOWN():
            return "ROUND_DOWN"
        elif self == Self.HALF_UP():
            return "ROUND_HALF_UP"
        elif self == Self.HALF_EVEN():
            return "ROUND_HALF_EVEN"
        elif self == Self.UP():
            return "ROUND_UP"
        else:
            return "UNKNOWN_ROUNDING_MODE"
