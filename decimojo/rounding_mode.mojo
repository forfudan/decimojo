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
    alias down = Self.DOWN()
    alias half_up = Self.HALF_UP()
    alias half_even = Self.HALF_EVEN()
    alias up = Self.UP()

    # Internal value
    var value: Int

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
