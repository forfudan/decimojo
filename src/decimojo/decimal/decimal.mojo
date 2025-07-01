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

"""Implements basic object methods for the Decimal type.

This module contains the basic object methods for the Decimal type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer
import testing

import decimojo.decimal.arithmetics
import decimojo.decimal.comparison
import decimojo.decimal.constants
import decimojo.decimal.exponential
import decimojo.decimal.rounding
from decimojo.rounding_mode import RoundingMode
import decimojo.utility

alias Dec = Decimal


@register_passable("trivial")
struct Decimal(
    Absable,
    Comparable,
    Floatable,
    IntableRaising,
    Representable,
    Roundable,
    Stringable,
    Writable,
):
    """Represents a 128-bit fixed-point decimal number.

    Notes:

    Internal Representation:

    Each decimal uses a 128-bit on memory, where:
    - 96 bits for the coefficient (significand), which is 96-bit unsigned
    integers stored as three 32 bit integer (little-endian).
        - Bit 0 to 31 are stored in the low field: least significant bits.
        - Bit 32 to 63 are stored in the mid field: middle bits.
        - Bit 64 to 95 are stored in the high field: most significant bits.
    - 32 bits for the flags, which contain the sign and scale information.
        - Bit 0 contains the infinity flag: 1 means infinity, 0 means finite.
        - Bit 1 contains the NaN flag: 1 means NaN, 0 means not NaN.
        - Bits 2 to 15 are unused and must be zero.
        - Bits 16 to 23 must contain an scale (exponent) between 0 and 28.
        - Bits 24 to 30 are unused and must be zero.
        - Bit 31 contains the sign: 0 mean positive, and 1 means negative.

    The value of the coefficient is: `high * 2**64 + mid * 2**32 + low`
    The final value is: `(-1)**sign * coefficient * 10**(-scale)`
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
    var low: UInt32
    """Least significant 32 bits of coefficient."""
    var mid: UInt32
    """Middle 32 bits of coefficient."""
    var high: UInt32
    """Most significant 32 bits of coefficient."""
    var flags: UInt32
    """Scale information and the sign."""

    # Constants
    alias MAX_SCALE: Int = 28
    alias MAX_AS_UINT128 = UInt128(79228162514264337593543950335)
    alias MAX_AS_INT128 = Int128(79228162514264337593543950335)
    alias MAX_AS_UINT256 = UInt256(79228162514264337593543950335)
    alias MAX_AS_INT256 = Int256(79228162514264337593543950335)
    alias MAX_AS_STRING = String("79228162514264337593543950335")
    """Maximum value as a string."""
    alias MAX_NUM_DIGITS = 29
    """Number of digits of the max value 79228162514264337593543950335."""
    alias SIGN_MASK = UInt32(0x80000000)
    """Sign mask. `0b1000_0000_0000_0000_0000_0000_0000_0000`.
    1 bit for sign (0 is positive and 1 is negative)."""
    alias SCALE_MASK = UInt32(0x00FF0000)
    """Scale mask. `0b0000_0000_1111_1111_0000_0000_0000_0000`.
    Bits 16 to 23 must contain an scale between 0 and 28."""
    alias SCALE_SHIFT = UInt32(16)
    """Bits 16 to 23 must contain an scale between 0 and 28."""
    alias INFINITY_MASK = UInt32(0x00000001)
    """Infinity mask. `0b0000_0000_0000_0000_0000_0000_0000_0001`."""
    alias NAN_MASK = UInt32(0x00000002)
    """Not a Number mask. `0b0000_0000_0000_0000_0000_0000_0000_0010`."""

    # TODO: Move these special values to top of the module
    # when Mojo support global variables in the future.

    # Special values
    @always_inline
    @staticmethod
    fn INFINITY() -> Decimal:
        """Returns a Decimal representing positive infinity.
        Internal representation: `0b0000_0000_0000_0000_0000_0000_0001`.
        """
        return Decimal(0, 0, 0, 0x00000001)

    @always_inline
    @staticmethod
    fn NEGATIVE_INFINITY() -> Decimal:
        """Returns a Decimal representing negative infinity.
        Internal representation: `0b1000_0000_0000_0000_0000_0000_0001`.
        """
        return Decimal(0, 0, 0, 0x80000001)

    @always_inline
    @staticmethod
    fn NAN() -> Decimal:
        """Returns a Decimal representing Not a Number (NaN).
        Internal representation: `0b0000_0000_0000_0000_0000_0000_0010`.
        """
        return Decimal(0, 0, 0, 0x00000010)

    @always_inline
    @staticmethod
    fn NEGATIVE_NAN() -> Decimal:
        """Returns a Decimal representing negative Not a Number.
        Internal representation: `0b1000_0000_0000_0000_0000_0000_0010`.
        """
        return Decimal(0, 0, 0, 0x80000010)

    @always_inline
    @staticmethod
    fn ZERO() -> Decimal:
        """Returns a Decimal representing 0."""
        return Decimal(0, 0, 0, 0)

    @always_inline
    @staticmethod
    fn ONE() -> Decimal:
        """Returns a Decimal representing 1."""
        return Decimal(1, 0, 0, 0)

    @always_inline
    @staticmethod
    fn MAX() -> Decimal:
        """
        Returns the maximum possible Decimal value.
        This is equivalent to 79228162514264337593543950335.
        """
        return Decimal(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0)

    @always_inline
    @staticmethod
    fn MIN() -> Decimal:
        """Returns the minimum possible Decimal value (negative of MAX).
        This is equivalent to -79228162514264337593543950335.
        """
        return Decimal(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, Decimal.SIGN_MASK)

    @always_inline
    @staticmethod
    fn PI() -> Decimal:
        """Returns the value of pi (π) as a Decimal."""
        return decimojo.decimal.constants.PI()

    @always_inline
    @staticmethod
    fn E() -> Decimal:
        """Returns the value of Euler's number (e) as a Decimal."""
        return decimojo.decimal.constants.E()

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a decimal instance with value 0."""
        self.low = 0x00000000
        self.mid = 0x00000000
        self.high = 0x00000000
        self.flags = 0x00000000

    fn __init__(
        out self, low: UInt32, mid: UInt32, high: UInt32, flags: UInt32
    ):
        """Initializes a Decimal with four raw words of internal representation.
        ***WARNING***: This method does not check the flags.
        If you are not sure about the flags, use `Decimal.from_words()` instead.
        """

        self.low = low
        self.mid = mid
        self.high = high
        self.flags = flags

    fn __init__(
        out self,
        low: UInt32,
        mid: UInt32,
        high: UInt32,
        scale: UInt32,
        sign: Bool,
    ) raises:
        """Initializes a Decimal with five components.
        See `Decimal.from_components()` for more information.
        """

        try:
            self = Decimal.from_components(low, mid, high, scale, sign)
        except e:
            raise Error(
                "Error in `Decimal.__init__()` with five components: ", e
            )

    fn __init__(out self, value: Int):
        """Initializes a Decimal from an integer.
        See `from_int()` for more information.
        """
        self = Decimal.from_int(value)

    fn __init__(out self, value: Int, scale: UInt32) raises:
        """Initializes a Decimal from an integer.
        See `from_int()` for more information.
        """
        try:
            self = Decimal.from_int(value, scale)
        except e:
            raise Error("Error in `Decimal.__init__()` with Int: ", e)

    fn __init__(out self, value: String) raises:
        """Initializes a Decimal from a string representation.
        See `from_string()` for more information.
        """
        try:
            self = Decimal.from_string(value)
        except e:
            raise Error("Error in `Decimal__init__()` with String: ", e)

    fn __init__(out self, value: Float64) raises:
        """Initializes a Decimal from a floating-point value.
        See `from_float` for more information.
        """

        try:
            self = Decimal.from_float(value)
        except e:
            raise Error("Error in `Decimal__init__()` with Float64: ", e)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_components(
        low: UInt32,
        mid: UInt32,
        high: UInt32,
        scale: UInt32,
        sign: Bool,
    ) raises -> Self:
        """Initializes a Decimal with five components.

        Args:
            low: Least significant 32 bits of coefficient.
            mid: Middle 32 bits of coefficient.
            high: Most significant 32 bits of coefficient.
            scale: Number of decimal places (0-28).
            sign: True if the number is negative.

        Returns:
            A Decimal instance with the given components.

        Raises:
            Error: If the scale is greater than MAX_SCALE.
        """

        if scale > Self.MAX_SCALE:
            raise Error(
                String(
                    "Error in Decimal constructor with five components: Scale"
                    " must be between 0 and 28, but got {}"
                ).format(scale)
            )

        var flags: UInt32 = 0
        flags |= (scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        flags |= sign << 31

        return Decimal(low, mid, high, flags)

    @staticmethod
    fn from_words(
        low: UInt32, mid: UInt32, high: UInt32, flags: UInt32
    ) raises -> Self:
        """Initializes a Decimal with four raw words of internal representation.
        Compared to `__init__()` with four words, this method checks the flags.

        Args:
            low: Least significant 32 bits of coefficient.
            mid: Middle 32 bits of coefficient.
            high: Most significant 32 bits of coefficient.
            flags: Scale information and the sign.

        Returns:
            A Decimal instance with the given words.

        Raises:
            Error: If the `flags` word is invalid.
            Error: If the scale is greater than MAX_SCALE.
        """

        # Check whether the `flags` word is valid.
        testing.assert_true(
            (flags & 0b0111_1111_0000_0000_1111_1111_1111_1111) == 0,
            String(
                "Error in Decimal constructor with four words: Flags must"
                " have bits 0-15 and 24-30 set to zero, but got {}"
            ).format(flags),
        )
        testing.assert_true(
            ((flags & 0x00FF0000) >> Self.SCALE_SHIFT) <= Self.MAX_SCALE,
            String(
                "Error in Decimal constructor with four words: Scale must"
                " be between 0 and 28, but got {}"
            ).format((flags & 0x00FF0000) >> Self.SCALE_SHIFT),
        )

        return Decimal(low, mid, high, flags)

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Initializes a Decimal from an integer.

        Args:
            value: The integer value to convert to Decimal.

        Returns:
            The Decimal representation of the integer.

        Notes:

        Since Int is a 64-bit type in Mojo, the `high` field will always be 0.

        Examples:
        ```mojo
        from decimojo import Decimal
        var dec1 = Decimal.from_int(-123) # -123
        var dec2 = Decimal.from_int(1) # 1
        ```
        End of examples.
        """

        var low: UInt32
        var mid: UInt32
        var flags: UInt32

        if value >= 0:
            flags = 0
            low = UInt32(value & 0xFFFFFFFF)
            mid = UInt32((value >> 32) & 0xFFFFFFFF)
        else:
            var abs_value = -value
            flags = Self.SIGN_MASK
            low = UInt32(abs_value & 0xFFFFFFFF)
            mid = UInt32((abs_value >> 32) & 0xFFFFFFFF)

        return Decimal(low, mid, 0, flags)

    @staticmethod
    fn from_int(value: Int, scale: UInt32) raises -> Self:
        """Initializes a Decimal from an integer and a scale.

        Args:
            value: The integer value to convert to Decimal.
            scale: The number of decimal places (0-28).

        Returns:
            The Decimal representation of the integer.

        Raises:
            Error: If the scale is greater than MAX_SCALE.

        Notes:

        Since Int is a 64-bit type in Mojo, the `high` field will always be 0.

        Examples:
        ```mojo
        from decimojo import Decimal
        var dec1 = Decimal.from_int(-123, scale=2) # -1.23
        var dec2 = Decimal.from_int(1, scale=5) # 0.00001
        ```
        End of examples.
        """

        var low: UInt32
        var mid: UInt32
        var flags: UInt32

        if scale > Self.MAX_SCALE:
            raise Error(
                String(
                    "Error in Decimal constructor with Int: Scale must be"
                    " between 0 and 28, but got {}"
                ).format(scale)
            )

        if value >= 0:
            flags = 0
            low = UInt32(value & 0xFFFFFFFF)
            mid = UInt32((value >> 32) & 0xFFFFFFFF)

        else:
            var abs_value = -value
            flags = Self.SIGN_MASK
            low = UInt32(abs_value & 0xFFFFFFFF)
            mid = UInt32((abs_value >> 32) & 0xFFFFFFFF)

        flags |= (scale << Self.SCALE_SHIFT) & Self.SCALE_MASK

        return Decimal(low, mid, 0, flags)

    @staticmethod
    fn from_uint128(
        value: UInt128, scale: UInt32 = 0, sign: Bool = False
    ) raises -> Decimal:
        """Initializes a Decimal from a UInt128 value.

        Args:
            value: The UInt128 value to convert to Decimal.
            scale: The number of decimal places (0-28).
            sign: True if the number is negative.

        Returns:
            The Decimal representation of the UInt128 value.

        Raises:
            Error: If the most significant word of the UInt128 is not zero.
            Error: If the scale is greater than MAX_SCALE.
        """

        if value >> 96 != 0:
            raise Error(
                String(
                    "Error in Decimal constructor with UInt128: Value must"
                    " fit in 96 bits, but got {}"
                ).format(value)
            )

        if scale > Self.MAX_SCALE:
            raise Error(
                String(
                    "Error in Decimal constructor with five components: Scale"
                    " must be between 0 and 28, but got {}"
                ).format(scale)
            )

        var result = UnsafePointer(to=value).bitcast[Decimal]()[]
        result.flags |= (scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        result.flags |= sign << 31

        return result

    @staticmethod
    fn from_string(value: String) raises -> Decimal:
        """Initializes a Decimal from a string representation.

        Args:
            value: The string representation of the Decimal.

        Returns:
            The Decimal representation of the string.

        Raises:
            Error: If an error occurs during the conversion, forward the error.

        Notes:

        Only the following characters are allowed in the input string:
        - Digits 0-9.
        - Decimal point ".". It can only appear once.
        - Negative sign "-". It can only appear before the first digit.
        - Positive sign "+". It can only appear before the first digit or after
            exponent "e" or "E".
        - Exponential notation "e" or "E". It can only appear once after the
            digits.
        - Space " ". It can appear anywhere in the string it is ignored.
        - Comma ",". It can appear anywhere between digits it is ignored.
        - Underscore "_". It can appear anywhere between digits it is ignored.
        """

        var value_string_slice = value.as_string_slice()
        var value_bytes = value_string_slice.as_bytes()
        var value_bytes_len = len(value_bytes)

        if value_bytes_len == 0:
            return Decimal.ZERO()

        if value_bytes_len != value_string_slice.char_length():
            raise Error(
                String(
                    "There are invalid characters in decimal string: {}"
                ).format(value)
            )

        # Yuhao's notes:
        # We scan each char in the string input.
        var mantissa_sign_read = False
        var mantissa_start = False
        var mantissa_significant_start = False
        var decimal_point_read = False
        var exponent_notation_read = False
        var exponent_sign_read = False
        # var exponent_start = False
        var unexpected_end_char = False

        var mantissa_sign: Bool = False  # True if negative
        var exponent_sign: Bool = False  # True if negative
        var coef: UInt128 = 0
        var scale: UInt32 = 0
        var raw_exponent: UInt32 = 0
        var num_mantissa_digits: UInt32 = 0

        for code in value_bytes:
            # If the char is " ", skip it
            if code == 32:
                pass
            # If the char is "," or "_", skip it
            elif code == 44 or code == 95:
                unexpected_end_char = True
            # If the char is "-"
            elif code == 45:
                unexpected_end_char = True
                if exponent_sign_read:
                    raise Error("Minus sign cannot appear twice in exponent.")
                elif exponent_notation_read:
                    exponent_sign = True
                    exponent_sign_read = True
                elif mantissa_sign_read:
                    raise Error(
                        "Minus sign can only appear once at the begining."
                    )
                else:
                    mantissa_sign = True
                    mantissa_sign_read = True
            # If the char is "+"
            elif code == 43:
                unexpected_end_char = True
                if exponent_sign_read:
                    raise Error("Plus sign cannot appear twice in exponent.")
                elif exponent_notation_read:
                    exponent_sign_read = True
                elif mantissa_sign_read:
                    raise Error(
                        "Plus sign can only appear once at the begining."
                    )
                else:
                    mantissa_sign_read = True
            # If the char is "."
            elif code == 46:
                unexpected_end_char = False
                if decimal_point_read:
                    raise Error("Decimal point can only appear once.")
                else:
                    decimal_point_read = True
                    mantissa_sign_read = True
            # If the char is "e" or "E"
            elif code == 101 or code == 69:
                unexpected_end_char = True
                if exponent_notation_read:
                    raise Error("Exponential notation can only appear once.")
                if not mantissa_start:
                    raise Error("Exponential notation must follow a number.")
                else:
                    exponent_notation_read = True
            # If the char is a digit 0
            elif code == 48:
                unexpected_end_char = False

                # Exponent part
                if exponent_notation_read:
                    exponent_sign_read = True
                    # exponent_start = True
                    raw_exponent = raw_exponent * 10

                # Mantissa part
                else:
                    # Skip the digit if mantissa is too long
                    if num_mantissa_digits > Decimal.MAX_NUM_DIGITS + 8:  # 37
                        continue

                    mantissa_sign_read = True
                    mantissa_start = True

                    if mantissa_significant_start:
                        num_mantissa_digits += 1
                        coef = coef * 10

                    if decimal_point_read:
                        scale += 1

            # If the char is a digit 1 - 9
            elif code >= 49 and code <= 57:
                unexpected_end_char = False

                # Exponent part
                if exponent_notation_read:
                    # Raise an error if the exponent part is too large
                    if (not exponent_sign) and (
                        raw_exponent > Decimal.MAX_NUM_DIGITS * 2
                    ):
                        raise Error(
                            String("Exponent part is too large: {}").format(
                                raw_exponent
                            )
                        )

                    # Skip the digit if exponent is negatively too large
                    elif (exponent_sign) and (
                        raw_exponent > Decimal.MAX_NUM_DIGITS * 2
                    ):
                        continue

                    else:
                        # exponent_start = True
                        raw_exponent = raw_exponent * 10 + UInt32(code - 48)

                # Mantissa part
                else:
                    # Skip the digit if mantissa is too long
                    if num_mantissa_digits > Decimal.MAX_NUM_DIGITS + 8:  # 37
                        continue

                    mantissa_significant_start = True
                    mantissa_start = True

                    num_mantissa_digits += 1
                    coef = coef * 10 + UInt128(code - 48)

                    if decimal_point_read:
                        scale += 1

            else:
                raise Error(
                    String("Invalid character in decimal string: {}").format(
                        chr(Int(code))
                    )
                )

        if unexpected_end_char:
            raise Error("Unexpected end character in decimal string.")

        # print("DEBUG: coef = ", coef)
        # print("DEBUG: scale = ", scale)
        # print("DEBUG: raw_exponent = ", raw_exponent)
        # print("DEBUG: exponent_sign = ", exponent_sign)

        if raw_exponent != 0:
            # If exponent is negative, increase the scale
            if exponent_sign:
                scale = scale + raw_exponent
            # If exponent is positive, decrease the scale until 0
            # then increase the coefficient
            else:
                if scale >= raw_exponent:
                    scale = scale - raw_exponent
                else:
                    coef = coef * (UInt128(10) ** UInt128(raw_exponent - scale))
                    scale = 0

        # print("DEBUG: coef = ", coef)
        # print("DEBUG: scale = ", scale)

        # TODO: The following part can be written into a function
        # because it is used in many cases
        if coef <= Decimal.MAX_AS_UINT128:
            if scale > Decimal.MAX_SCALE:
                coef = decimojo.utility.round_to_keep_first_n_digits(
                    coef,
                    Int(num_mantissa_digits) - Int(scale - Decimal.MAX_SCALE),
                )
                # print("DEBUG: coef = ", coef)
                # print(
                #     "DEBUG: kept digits =",
                #     Int(num_mantissa_digits) - Int(scale - Decimal.MAX_SCALE),
                # )
                scale = Decimal.MAX_SCALE

            return Decimal.from_uint128(coef, scale, mantissa_sign)

        else:
            var ndigits_coef = decimojo.utility.number_of_digits(coef)
            var ndigits_quot_int_part = ndigits_coef - scale

            var truncated_coef = decimojo.utility.round_to_keep_first_n_digits(
                coef, Decimal.MAX_NUM_DIGITS
            )
            var scale_of_truncated_coef = (
                Decimal.MAX_NUM_DIGITS - ndigits_quot_int_part
            )

            if truncated_coef > Decimal.MAX_AS_UINT128:
                truncated_coef = decimojo.utility.round_to_keep_first_n_digits(
                    coef, Decimal.MAX_NUM_DIGITS - 1
                )
                scale_of_truncated_coef -= 1

            if scale_of_truncated_coef > Decimal.MAX_SCALE:
                var num_digits_truncated_coef = (
                    decimojo.utility.number_of_digits(truncated_coef)
                )
                truncated_coef = decimojo.utility.round_to_keep_first_n_digits(
                    truncated_coef,
                    num_digits_truncated_coef
                    - Int(scale_of_truncated_coef - Decimal.MAX_SCALE),
                )
                scale_of_truncated_coef = Decimal.MAX_SCALE

            return Decimal.from_uint128(
                truncated_coef, scale_of_truncated_coef, mantissa_sign
            )

    @staticmethod
    fn from_float(value: Float64) raises -> Decimal:
        """Initializes a Decimal from a floating-point value.
        The reliability of this method is limited by the precision of Float64.
        Float64 is reliable up to 15 significant digits and marginally
        reliable up to 16 siginficant digits. Be careful when using this method.

        Args:
            value: The floating-point value to convert to Decimal.

        Returns:
            The Decimal representation of the floating-point value.

        Raises:
            Error: If the input is too large to be transformed into Decimal.
            Error: If the input is infinity or NaN.

        Example:
        ```mojo
        from decimojo import Decimal
        print(Decimal.from_float(Float64(3.1415926535897932383279502)))
        # 3.1415926535897932 (17 significant digits)
        print(Decimal.from_float(12345678901234567890.12345678901234567890))
        # 12345678901234567168 (20 significant digits, but only 15 are reliable)
        ```
        .
        """

        # CASE: Zero
        if value == Float64(0):
            return Decimal.ZERO()

        # Get the positive value of the input
        var abs_value: Float64
        var is_negative: Bool = value < 0
        if is_negative:
            abs_value = -value
        else:
            abs_value = value

        # Early exit if the value is too large
        if UInt128(abs_value) > Decimal.MAX_AS_UINT128:
            raise Error(
                String(
                    "Error in `from_float`: The float value {} is too"
                    " large (>=2^96) to be transformed into Decimal"
                ).format(value)
            )

        # Extract binary exponent using IEEE 754 bit manipulation
        var bits: UInt64 = UnsafePointer(to=abs_value).bitcast[UInt64]().load()
        var biased_exponent: Int = Int((bits >> 52) & 0x7FF)

        # print("DEBUG: biased_exponent = ", biased_exponent)

        # CASE: Denormalized number that is very close to zero
        if biased_exponent == 0:
            return Decimal(0, 0, 0, Decimal.MAX_SCALE, is_negative)

        # CASE: Infinity or NaN
        if biased_exponent == 0x7FF:
            raise Error("Cannot convert infinity or NaN to Decimal")

        # Get unbias exponent
        var binary_exp: Int = biased_exponent - 1023
        # print("DEBUG: binary_exp = ", binary_exp)

        # Convert binary exponent to approximate decimal exponent
        # log10(2^exp) = exp * log10(2)
        var decimal_exp: Int = Int(Float64(binary_exp) * 0.301029995663981)
        # print("DEBUG: decimal_exp = ", decimal_exp)

        # Fine-tune decimal exponent
        var power_check: Float64 = abs_value / Float64(10) ** decimal_exp
        if power_check >= 10.0:
            decimal_exp += 1
        elif power_check < 1.0:
            decimal_exp -= 1

        # print("DEBUG: decimal_exp = ", decimal_exp)

        var coefficient: UInt128 = UInt128(abs_value)
        var remainder = abs(abs_value - Float64(coefficient))
        # print("DEBUG: integer_part = ", coefficient)
        # print("DEBUG: remainder = ", remainder)

        var scale = 0
        var temp_coef: UInt128
        var num_trailing_zeros: Int = 0
        while scale < Decimal.MAX_SCALE:
            remainder *= 10
            var int_part = UInt128(remainder)
            remainder = abs(remainder - Float64(int_part))
            temp_coef = coefficient * 10 + int_part
            if temp_coef > Decimal.MAX_AS_UINT128:
                break
            coefficient = temp_coef
            scale += 1
            if int_part == 0:
                num_trailing_zeros += 1
            else:
                num_trailing_zeros = 0
            # print("DEBUG: coefficient = ", coefficient)
            # print("DEBUG: scale = ", scale)
            # print("DEBUG: remainder = ", remainder)

        coefficient = coefficient // UInt128(10) ** num_trailing_zeros
        scale -= num_trailing_zeros

        var low = UInt32(coefficient & 0xFFFFFFFF)
        var mid = UInt32((coefficient >> 32) & 0xFFFFFFFF)
        var high = UInt32((coefficient >> 64) & 0xFFFFFFFF)

        # Return both the significant digits and the scale
        return Decimal(low, mid, high, scale, is_negative)

    @always_inline
    fn copy(self) -> Self:
        """Returns a copy of the Decimal."""
        return Decimal(self.low, self.mid, self.high, self.flags)

    @always_inline
    fn clone(self) -> Self:
        """Returns a copy of the Decimal."""
        return Decimal(self.low, self.mid, self.high, self.flags)

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __float__(self) -> Float64:
        """Converts this Decimal to a floating-point value.
        Because Decimal is fixed-point, this may lose precision.

        Returns:
            The floating-point representation of this Decimal.
        """

        var result = Float64(self.coefficient()) / (Float64(10) ** self.scale())
        result = -result if self.is_negative() else result

        return result

    fn __int__(self) raises -> Int:
        """Returns the integral part of the Decimal as Int.
        See `to_int()` for more information.
        """
        return self.to_int()

    fn __str__(self) -> String:
        """Returns string representation of the Decimal.
        See `to_str()` for more information.
        """
        return self.to_str()

    fn __repr__(self) -> String:
        """Returns a string representation of the Decimal."""
        return 'Decimal("' + self.__str__() + '")'

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the Decimal to a writer.
        This implement the `write` method of the `Writer` trait.
        """
        writer.write(String(self))

    fn repr_words(self) -> String:
        """Returns a string representation of the Decimal's internal words.
        `Decimal.from_words(low, mid, high, flags)`.
        """
        return (
            "Decimal("
            + hex(self.low)
            + ", "
            + hex(self.mid)
            + ", "
            + hex(self.high)
            + ", "
            + hex(self.flags)
            + ")"
        )

    fn repr_components(self) -> String:
        """Returns a string representation of the Decimal's five components.
        `Decimal.from_components(low, mid, high, scale, sign)`.
        """
        var scale = UInt8((self.flags & Self.SCALE_MASK) >> Self.SCALE_SHIFT)
        var sign = Bool((self.flags & Self.SIGN_MASK) == Self.SIGN_MASK)
        return (
            "Decimal(low="
            + hex(self.low)
            + ", mid="
            + hex(self.mid)
            + ", high="
            + hex(self.high)
            + ", scale="
            + String(scale)
            + ", sign="
            + String(sign)
            + ")"
        )

    fn to_int(self) raises -> Int:
        """Returns the integral part of the Decimal as Int.
        If the Decimal is too large to fit in Int, an error is raised.

        Returns:
            The signed integral part of the Decimal.

        Raises:
            Error: If the Decimal is too large to fit in Int.
        """
        try:
            return Int(self.to_int64())
        except e:
            raise Error("Error in `to_int()`: ", e)

    fn to_int64(self) raises -> Int64:
        """Returns the integral part of the Decimal as Int64.
        If the Decimal is too large to fit in Int64, an error is raised.

        Returns:
            The signed integral part of the Decimal.

        Raises:
            Error: If the Decimal is too large to fit in Int64.
        """
        var result = self.to_int128()

        if result > Int128(Int64.MAX):
            raise Error("Decimal is too large to fit in Int64")

        if result < Int128(Int64.MIN):
            raise Error("Decimal is too small to fit in Int64")

        return Int64(result & 0xFFFF_FFFF_FFFF_FFFF)

    fn to_int128(self) -> Int128:
        """Returns the signed integral part of the Decimal."""

        var res = Int128(self.to_uint128())

        return -res if self.is_negative() else res

    fn to_uint128(self) -> UInt128:
        """Returns the absolute integral part of the Decimal as UInt128."""
        var res: UInt128

        if self.is_zero():
            res = 0

        # If scale is 0, the number is already an integer
        elif self.scale() == 0:
            res = self.coefficient()

        # If scale is not 0, check whether integer part is 0
        elif self.number_of_significant_digits() <= self.scale():
            # Value is less than 1, so integer part is 0
            res = 0

        # Otherwise, get the integer part by dividing by 10^scale
        else:
            res = self.coefficient() // UInt128(10) ** UInt128(self.scale())

        return res

    fn to_str(self) -> String:
        """Returns string representation of the Decimal.
        Preserves trailing zeros after decimal point to match the scale.
        """
        # Get the coefficient as a string (absolute value)
        var coef = String(self.coefficient())
        var scale = self.scale()
        var result: String

        # Handle zero as a special case
        if coef == "0":
            if scale == 0:
                result = "0"
            else:
                result = "0." + "0" * scale

        # For non-zero values, format according to scale
        elif scale == 0:
            # No decimal places needed
            result = coef
        elif scale >= len(coef):
            # Need leading zeros after decimal point
            result = "0." + "0" * (scale - len(coef)) + coef
        else:
            # Insert decimal point at appropriate position
            var insert_pos = len(coef) - scale
            result = coef[:insert_pos] + "." + coef[insert_pos:]

            # Ensure we have exactly 'scale' digits after decimal point
            var decimal_point_pos = result.find(".")
            var current_decimals = len(result) - decimal_point_pos - 1

            if current_decimals < scale:
                # Add trailing zeros if needed
                result += "0" * (scale - current_decimals)

        # Add negative sign if needed
        if self.is_negative():
            result = "-" + result

        return result

    fn to_str_scientific(self) raises -> String:
        """Returns a string representation of this Decimal in scientific notation.

        Returns:
            A string representation of this Decimal in scientific notation.

        Raises:
            Error: If significant_digits is not between 1 and 28.

        Notes:

        Scientific notation format: M.NNNNe±XX where:
        - M is the first significant digit.
        - NNNN is the remaining significant digits.
        - ±XX is the exponent.
        """
        var scale: Int = self.scale()
        var coef = self.coefficient()

        # Special case: zero
        if self.is_zero():
            if scale == 0:
                return String("0")
            else:
                return String("0E-") + String("0") * self.scale()

        while coef % 10 == 0:
            coef = coef // 10
            scale -= 1

        # 0.00100: coef=100, scale=5
        # => 0.001: coef=1, scale=3, ndigits_fractional_part=0
        # => 1.0e-3: coef=1, exponent=-3
        var ndigits_coef = decimojo.utility.number_of_digits(coef)
        var ndigits_fractional_part = ndigits_coef - 1
        var exponent = ndigits_fractional_part - scale

        # Format in scientific notation:
        # sign, first digit, decimal point, remaining digits
        var coef_str = String(coef)
        var result: String = String("-") if self.is_negative() else String("")
        if len(coef_str) == 1:
            result = result + coef_str + String(".0")
        else:
            result = result + coef_str[0] + String(".") + coef_str[1:]

        # Add exponent (E+XX or E-XX)
        if exponent >= 0:
            result += "E+" + String(exponent)
        else:
            result += "E" + String(exponent)

        return result

    fn as_tuple(self) -> Tuple[Bool, UInt128, Int]:
        """Returns a tuple representation of the number.
        Tuple(sign, signficand, exponent).

        Returns:
            A tuple representation of the number.
        """
        return Tuple[Bool, UInt128, Int](
            self.is_negative(), self.coefficient(), self.scale()
        )

    # ===------------------------------------------------------------------=== #
    # Basic unary operation dunders
    # neg
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __abs__(self) -> Self:
        """Returns the absolute value of this Decimal.
        See `absolute()` for more information.
        """
        return decimojo.decimal.arithmetics.absolute(self)

    @always_inline
    fn __neg__(self) -> Self:
        """Returns the negation of this Decimal.
        See `negative()` for more information.
        """
        return decimojo.decimal.arithmetics.negative(self)

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) raises -> Self:
        return decimojo.decimal.arithmetics.add(self, other)

    @always_inline
    fn __add__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.add(self, Decimal(other))

    @always_inline
    fn __sub__(self, other: Self) raises -> Self:
        return decimojo.decimal.arithmetics.subtract(self, other)

    @always_inline
    fn __sub__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.subtract(self, Decimal(other))

    @always_inline
    fn __mul__(self, other: Self) raises -> Self:
        return decimojo.decimal.arithmetics.multiply(self, other)

    @always_inline
    fn __mul__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.multiply(self, Decimal(other))

    @always_inline
    fn __truediv__(self, other: Self) raises -> Self:
        return decimojo.decimal.arithmetics.divide(self, other)

    @always_inline
    fn __truediv__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.divide(self, Decimal(other))

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        """Performs truncate division with // operator."""
        return decimojo.decimal.arithmetics.truncate_divide(self, other)

    @always_inline
    fn __floordiv__(self, other: Int) raises -> Self:
        """Performs truncate division with // operator."""
        return decimojo.decimal.arithmetics.truncate_divide(
            self, Decimal(other)
        )

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        """Performs truncate modulo."""
        return decimojo.decimal.arithmetics.modulo(self, other)

    @always_inline
    fn __mod__(self, other: Int) raises -> Self:
        """Performs truncate modulo."""
        return decimojo.decimal.arithmetics.modulo(self, Decimal(other))

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        return decimal.power(self, exponent)

    @always_inline
    fn __pow__(self, exponent: Int) raises -> Self:
        return decimal.power(self, exponent)

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders with reflected operands
    # These methods are called to implement the binary arithmetic operations
    # with reflected operands
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __radd__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.add(Decimal(other), self)

    @always_inline
    fn __rsub__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.subtract(Decimal(other), self)

    @always_inline
    fn __rmul__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.multiply(Decimal(other), self)

    @always_inline
    fn __rtruediv__(self, other: Int) raises -> Self:
        return decimojo.decimal.arithmetics.divide(Decimal(other), self)

    @always_inline
    fn __rfloordiv__(self, other: Int) raises -> Self:
        """Performs truncate division with // operator."""
        return decimojo.decimal.arithmetics.truncate_divide(
            Decimal(other), self
        )

    @always_inline
    fn __rmod__(self, other: Int) raises -> Self:
        """Performs truncate modulo."""
        return decimojo.decimal.arithmetics.modulo(Decimal(other), self)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # These methods are called to implement the binary augmented arithmetic
    # assignments
    # (+=, -=, *=, @=, /=, //=, %=, **=, <<=, >>=, &=, ^=, |=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self) raises:
        self = decimojo.decimal.arithmetics.add(self, other)

    @always_inline
    fn __iadd__(mut self, other: Int) raises:
        self = decimojo.decimal.arithmetics.add(self, Decimal(other))

    @always_inline
    fn __isub__(mut self, other: Self) raises:
        self = decimojo.decimal.arithmetics.subtract(self, other)

    @always_inline
    fn __isub__(mut self, other: Int) raises:
        self = decimojo.decimal.arithmetics.subtract(self, Decimal(other))

    @always_inline
    fn __imul__(mut self, other: Self) raises:
        self = decimojo.decimal.arithmetics.multiply(self, other)

    @always_inline
    fn __imul__(mut self, other: Int) raises:
        self = decimojo.decimal.arithmetics.multiply(self, Decimal(other))

    @always_inline
    fn __itruediv__(mut self, other: Self) raises:
        self = decimojo.decimal.arithmetics.divide(self, other)

    @always_inline
    fn __itruediv__(mut self, other: Int) raises:
        self = decimojo.decimal.arithmetics.divide(self, Decimal(other))

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        """Performs truncate division with // operator."""
        self = decimojo.decimal.arithmetics.truncate_divide(self, other)

    @always_inline
    fn __ifloordiv__(mut self, other: Int) raises:
        """Performs truncate division with // operator."""
        self = decimojo.decimal.arithmetics.truncate_divide(
            self, Decimal(other)
        )

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        """Performs truncate modulo."""
        self = decimojo.decimal.arithmetics.modulo(self, other)

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Decimal) -> Bool:
        """Greater than comparison operator.
        See `greater()` for more information.
        """
        return decimojo.decimal.comparison.greater(self, other)

    @always_inline
    fn __lt__(self, other: Decimal) -> Bool:
        """Less than comparison operator.
        See `less()` for more information.
        """
        return decimojo.decimal.comparison.less(self, other)

    @always_inline
    fn __ge__(self, other: Decimal) -> Bool:
        """Greater than or equal comparison operator.
        See `greater_equal()` for more information.
        """
        return decimojo.decimal.comparison.greater_equal(self, other)

    @always_inline
    fn __le__(self, other: Decimal) -> Bool:
        """Less than or equal comparison operator.
        See `less_equal()` for more information.
        """
        return decimojo.decimal.comparison.less_equal(self, other)

    @always_inline
    fn __eq__(self, other: Decimal) -> Bool:
        """Equality comparison operator.
        See `equal()` for more information.
        """
        return decimojo.decimal.comparison.equal(self, other)

    @always_inline
    fn __ne__(self, other: Decimal) -> Bool:
        """Inequality comparison operator.
        See `not_equal()` for more information.
        """
        return decimojo.decimal.comparison.not_equal(self, other)

    # ===------------------------------------------------------------------=== #
    # Other dunders that implements traits
    # round
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __round__(self, ndigits: Int) -> Self:
        """Rounds this Decimal to the specified number of decimal places.
        If `ndigits` is not given, rounds to 0 decimal places.
        If rounding causes overflow, returns the value itself.

        raises:
            Error: Calling `round()` failed.
        """
        try:
            return decimojo.decimal.rounding.round(
                self,
                ndigits=ndigits,
                rounding_mode=RoundingMode.ROUND_HALF_EVEN,
            )
        except e:
            return self

    @always_inline
    fn __round__(self) -> Self:
        """**OVERLOAD**."""
        try:
            return decimojo.decimal.rounding.round(
                self, ndigits=0, rounding_mode=RoundingMode.ROUND_HALF_EVEN
            )
        except e:
            return self

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # exp, ln, round, sqrt
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn round(
        self,
        ndigits: Int = 0,
        rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
    ) raises -> Self:
        """Rounds this Decimal to the specified number of decimal places.
        Compared to `__round__`, this method:
        (1) Allows specifying the rounding mode.
        (2) Raises an error if the operation would result in overflow.
        See `round()` for more information.
        """
        return decimojo.decimal.rounding.round(
            self, ndigits=ndigits, rounding_mode=rounding_mode
        )

    @always_inline
    fn quantize(
        self,
        exp: Decimal,
        rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
    ) raises -> Self:
        """Quantizes this Decimal to the specified exponent.
        See `quantize()` for more information.
        """
        return decimojo.decimal.rounding.quantize(self, exp, rounding_mode)

    @always_inline
    fn exp(self) raises -> Self:
        """Calculates the exponential of this Decimal.
        See `exp()` for more information.
        """
        return decimojo.decimal.exponential.exp(self)

    @always_inline
    fn ln(self) raises -> Self:
        """Calculates the natural logarithm of this Decimal.
        See `ln()` for more information.
        """
        return decimojo.decimal.exponential.ln(self)

    @always_inline
    fn log10(self) raises -> Decimal:
        """Computes the base-10 logarithm of this Decimal."""
        return decimojo.decimal.exponential.log10(self)

    @always_inline
    fn log(self, base: Decimal) raises -> Decimal:
        """Computes the logarithm of this Decimal with an arbitrary base."""
        return decimojo.decimal.exponential.log(self, base)

    @always_inline
    fn power(self, exponent: Int) raises -> Decimal:
        """Raises this Decimal to the power of an integer."""
        return decimojo.decimal.exponential.power(self, Decimal(exponent))

    @always_inline
    fn power(self, exponent: Decimal) raises -> Decimal:
        """Raises this Decimal to the power of another Decimal."""
        return decimojo.decimal.exponential.power(self, exponent)

    @always_inline
    fn root(self, n: Int) raises -> Self:
        """Calculates the n-th root of this Decimal.
        See `root()` for more information.
        """
        return decimojo.decimal.exponential.root(self, n)

    @always_inline
    fn sqrt(self) raises -> Self:
        """Calculates the square root of this Decimal.
        See `sqrt()` for more information.
        """
        return decimojo.decimal.exponential.sqrt(self)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn coefficient(self) -> UInt128:
        """Returns the unscaled integer coefficient as an UInt128 value.
        This is the absolute value of the decimal digits without considering
        the scale.
        The value of the coefficient is: `high * 2**64 + mid * 2**32 + low`.

        Returns:
            Int128: The coefficient as a unsigned 128-bit signed integer.
        """

        # Fast implementation using bitcast
        # Use bitcast to directly convert the three 32-bit parts to a UInt128
        # UInt128 must little-endian on memory
        return decimojo.utility.bitcast[DType.uint128](self)

        # Alternative implementation using arithmetic
        # Combine the three 32-bit parts into a single Int128
        # return (
        #     UInt128(self.high) << 64
        #     | UInt128(self.mid) << 32
        #     | UInt128(self.low)
        # )

    fn extend_precision(self, owned precision_diff: Int) raises -> Decimal:
        """Returns a number with additional decimal places (trailing zeros).
        This multiplies the coefficient by 10^precision_diff and increases
        the scale accordingly, preserving the numeric value.

        Args:
            precision_diff: The number of decimal places to add.

        Returns:
            A new Decimal with increased precision.

        Raises:
            Error: If the level is less than 0.

        Examples:
        ```mojo
        from decimojo import Decimal
        var d1 = Decimal("5")            # 5
        var d2 = d1.extend_precision(2)  # Result: 5.00 (same value, different representation)
        print(d1)                        # 5
        print(d2)                        # 5.00
        print(d2.scale())                # 2

        var d3 = Decimal("123.456")      # 123.456
        var d4 = d3.extend_precision(3)  # Result: 123.456000
        print(d3)                        # 123.456
        print(d4)                        # 123.456000
        print(d4.scale())                # 6
        ```
        End of examples.
        """
        if precision_diff < 0:
            raise Error(
                "Error in `scale_up()`: precision_diff must be greater than 0"
            )

        if precision_diff == 0:
            return self

        var result = self

        # Update the scale in the flags
        var new_scale = self.scale() + precision_diff

        # TODO: Check if multiplication by 10^level would cause overflow
        # If yes, then raise an error
        if new_scale > Decimal.MAX_SCALE + 1:
            # Cannot scale beyond max precision, limit the scaling
            precision_diff = Decimal.MAX_SCALE + 1 - self.scale()
            new_scale = Decimal.MAX_SCALE + 1

        # With UInt128, we can represent the coefficient as a single value
        var coefficient = (
            UInt128(self.high) << 64
            | UInt128(self.mid) << 32
            | UInt128(self.low)
        )

        # TODO: Check if multiplication by 10^level would cause overflow
        # If yes, then raise an error
        var max_coefficient = ~UInt128(0) / UInt128(10) ** precision_diff
        if coefficient > max_coefficient:
            # Handle overflow case - limit to maximum value or raise error
            coefficient = ~UInt128(0)
        else:
            # No overflow - safe to multiply
            coefficient *= UInt128(10**precision_diff)

        # Extract the 32-bit components from the UInt128
        result.low = UInt32(coefficient & 0xFFFFFFFF)
        result.mid = UInt32((coefficient >> 32) & 0xFFFFFFFF)
        result.high = UInt32((coefficient >> 64) & 0xFFFFFFFF)

        # Set the new scale
        result.flags = (self.flags & ~Decimal.SCALE_MASK) | (
            UInt32(new_scale << Decimal.SCALE_SHIFT) & Decimal.SCALE_MASK
        )

        return result

    fn print_internal_representation(self):
        """Prints the internal representation details of a Decimal."""
        print("\nInternal Representation Details:")
        print("--------------------------------")
        print("Decimal:       ", self)
        print("coefficient:   ", self.coefficient())
        print("scale:         ", self.scale())
        print("is negative:   ", self.is_negative())
        print("is zero:       ", self.is_zero())
        print("low:           ", self.low)
        print("mid:           ", self.mid)
        print("high:          ", self.high)
        print("low byte:      ", hex(self.low))
        print("mid byte:      ", hex(self.mid))
        print("high byte:     ", hex(self.high))
        print("flags byte:    ", hex(self.flags))
        print("--------------------------------")

    @always_inline
    fn is_integer(self) -> Bool:
        """Determines whether this Decimal value represents an integer.
        A Decimal represents an integer when it has no fractional part
        (i.e., all digits after the decimal point are zero).

        Returns:
            True if this Decimal represents an integer value, False otherwise.
        """

        # If value is zero, it's an integer regardless of scale
        if self.is_zero():
            return True

        var scale = self.scale()

        # If scale is 0, it's already an integer
        if scale == 0:
            return True

        # For a value to be an integer, it must be divisible by 10^scale
        # If coefficient % 10^scale == 0, then all decimal places are zeros
        # If it divides evenly, it's an integer
        return (
            self.coefficient()
            % decimojo.utility.power_of_10[DType.uint128](scale)
        ) == 0

    @always_inline
    fn is_negative(self) -> Bool:
        """Returns True if this Decimal is negative."""
        return (self.flags & Self.SIGN_MASK) != 0

    @always_inline
    fn is_one(self) -> Bool:
        """Returns True if this Decimal represents the value 1.
        If 10^scale == coefficient, then it's one.
        `1` and `1.00` are considered ones.
        """
        if self.is_negative():
            return False

        var scale = self.scale()
        var coef = self.coefficient()

        if scale == 0 and coef == 1:
            return True

        if coef == decimojo.utility.power_of_10[DType.uint128](scale):
            return True

        return False

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if this Decimal represents zero.
        A decimal is zero when all coefficient parts (low, mid, high) are zero,
        regardless of its sign or scale.
        """
        return self.low == 0 and self.mid == 0 and self.high == 0

    @always_inline
    fn is_infinity(self) -> Bool:
        """Returns True if this Decimal is positive or negative infinity."""
        return (self.flags & Self.INFINITY_MASK) != 0

    @always_inline
    fn is_nan(self) -> Bool:
        """Returns True if this Decimal is NaN (Not a Number)."""
        return (self.flags & Self.NAN_MASK) != 0

    @always_inline
    fn scale(self) -> Int:
        """Returns the scale (number of decimal places) of this Decimal."""
        return Int((self.flags & Self.SCALE_MASK) >> Self.SCALE_SHIFT)

    @always_inline
    fn number_of_significant_digits(self) -> Int:
        """Returns the number of significant digits in the Decimal.
        The number of significant digits is the total number of digits in the
        coefficient, excluding leading zeros but including trailing zeros.

        Returns:
            The number of significant digits in the Decimal.

        Example:

        ```mojo
        from decimojo import Decimal
        print(Decimal("123.4500").number_of_significant_digits())
        # 7
        print(Decimal("0.0001234500").number_of_significant_digits())
        # 7
        ```
        End of example.
        """

        var coef = self.coefficient()

        # Special case for zero
        if coef == 0:
            return 0  # Zero has zero significant digit
        else:
            return decimojo.utility.number_of_digits(coef)
