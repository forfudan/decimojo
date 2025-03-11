# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements basic object methods for the Decimal type
# which supports correctly-rounded, fixed-point arithmetic.
#
# ===----------------------------------------------------------------------=== #
#
# Organization of methods:
# - Constructors and life time methods
# - Constructing methods that are not dunders
# - Output dunders, type-transfer dunders, and other type-transfer methods
# - Basic unary arithmetic operation dunders
# - Basic binary arithmetic operation dunders
# - Basic binary logic operation dunders
# - Other dunders that implements traits
# - Mathematical methods that do not implement a trait (not a dunder)
# - Other methods
# - Internal methods
#
# ===----------------------------------------------------------------------=== #
# Docstring style:
# 1. Description
# 2. Parameters
# 3. Args
# 4. Constraints
# 4) Returns
# 5) Raises
# 9) Examples
# ===----------------------------------------------------------------------=== #

"""
Implements basic object methods for working with decimal numbers.
"""

from .rounding_mode import RoundingMode


@register_passable
struct Decimal(
    Absable,
    Comparable,
    Floatable,
    Intable,
    Roundable,
    Writable,
):
    """
    Correctly-rounded fixed-precision number.

    Internal Representation
    -----------------------
    Each decimal uses a 128-bit on memory, where:
    - 96 bits for the coefficient (mantissa), which is 96-bit unsigned integers
    stored as three 32 bit integer (little-endian).
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

    Reference
    ---------
    - General Decimal Arithmetic Specification Version 1.70 – 7 Apr 2009 (https://speleotrove.com/decimal/decarith.html)
    - https://learn.microsoft.com/en-us/dotnet/api/system.decimal.getbits?view=net-9.0&redirectedfrom=MSDN#System_Decimal_GetBits_System_Decimal_
    """

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
    Bits 16 to 23 must contain an exponent between 0 and 28."""
    alias SCALE_SHIFT = UInt32(16)
    """Bits 16 to 23 must contain an exponent between 0 and 28."""
    alias INFINITY_MASK = UInt32(0x00000001)
    """Infinity mask. `0b0000_0000_0000_0000_0000_0000_0000_0001`."""
    alias NAN_MASK = UInt32(0x00000002)
    """Not a Number mask. `0b0000_0000_0000_0000_0000_0000_0000_0010`."""

    # Special values
    @staticmethod
    fn INFINITY() -> Decimal:
        """
        Returns a Decimal representing positive infinity.
        Internal representation: `0b0000_0000_0000_0000_0000_0000_0001`.
        """
        return Decimal.from_raw_words(0, 0, 0, 0x00000001)

    @staticmethod
    fn NEGATIVE_INFINITY() -> Decimal:
        """
        Returns a Decimal representing negative infinity.
        Internal representation: `0b1000_0000_0000_0000_0000_0000_0001`.
        """
        return Decimal.from_raw_words(0, 0, 0, 0x80000001)

    @staticmethod
    fn NAN() -> Decimal:
        """
        Returns a Decimal representing Not a Number (NaN).
        Internal representation: `0b0000_0000_0000_0000_0000_0000_0010`.
        """
        return Decimal.from_raw_words(0, 0, 0, 0x00000010)

    @staticmethod
    fn NEGATIVE_NAN() -> Decimal:
        """
        Returns a Decimal representing negative Not a Number.
        Internal representation: `0b1000_0000_0000_0000_0000_0000_0010`.
        """
        return Decimal.from_raw_words(0, 0, 0, 0x80000010)

    @staticmethod
    fn ZERO() -> Decimal:
        """
        Returns a Decimal representing 0.
        """
        return Decimal.from_raw_words(0, 0, 0, 0)

    @staticmethod
    fn ONE() -> Decimal:
        """
        Returns a Decimal representing 1.
        """
        return Decimal.from_raw_words(1, 0, 0, 0)

    @staticmethod
    fn NEGATIVE_ONE() -> Decimal:
        """
        Returns a Decimal representing -1.
        """
        return Decimal.from_raw_words(1, 0, 0, Decimal.SIGN_MASK)

    @staticmethod
    fn MAX() -> Decimal:
        """
        Returns the maximum possible Decimal value.
        This is equivalent to 79228162514264337593543950335.
        """
        return Decimal.from_raw_words(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0)

    @staticmethod
    fn MIN() -> Decimal:
        """Returns the minimum possible Decimal value (negative of MAX).
        This is equivalent to -79228162514264337593543950335.
        """
        return Decimal.from_raw_words(
            0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, Decimal.SIGN_MASK
        )

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """
        Initializes a decimal instance with value 0.
        """
        self.low = 0x00000000
        self.mid = 0x00000000
        self.high = 0x00000000
        self.flags = 0x00000000

    fn __init__(
        out self,
        low: UInt32,
        mid: UInt32,
        high: UInt32,
        scale: UInt32,
        sign: Bool,
    ) raises:
        """
        Initializes a Decimal with five components.
        If the scale is greater than MAX_SCALE, it is set to MAX_SCALE.

        Args:
            low: Least significant 32 bits of coefficient.
            mid: Middle 32 bits of coefficient.
            high: Most significant 32 bits of coefficient.
            scale: Number of decimal places (0-28).
            sign: True if the number is negative.
        """

        if scale > Self.MAX_SCALE:
            raise Error(
                String(
                    "Error in Decimal constructor with five components: Scale"
                    " must be between 0 and 28, but got {}"
                ).format(scale)
            )

        self.low = low
        self.mid = mid
        self.high = high

        # First set the flags without capping to initialize properly
        var flags: UInt32 = 0

        # Set the initial scale (may be higher than MAX_SCALE)
        flags |= (scale << Self.SCALE_SHIFT) & Self.SCALE_MASK

        # Set the sign bit if negative
        if sign:
            flags |= Self.SIGN_MASK

        self.flags = flags

    fn __init__(out self, integer: Int):
        """
        Initializes a Decimal from an integer.

        Notes:
        Since Int is a 64-bit type in Mojo, this constructor can only
        handle values up to 64 bits. The `high` field will always be 0.
        """
        self.flags = 0

        if integer == 0:
            self.low = 0
            self.mid = 0
            self.high = 0
            return

        if integer < 0:
            # Set sign bit for negative integers
            self.flags = Self.SIGN_MASK

            # Handle negative value by taking absolute value first
            abs_value = UInt64(-integer)

            # Set the coefficient fields
            # `high` will always be 0 because Int is 64-bit
            self.low = UInt32(abs_value & 0xFFFFFFFF)
            self.mid = UInt32((abs_value >> 32) & 0xFFFFFFFF)
            self.high = 0
        else:
            # Positive integer
            self.low = UInt32(integer & 0xFFFFFFFF)
            self.mid = UInt32((integer >> 32) & 0xFFFFFFFF)
            self.high = 0

    fn __init__(out self, integer: Int128):
        """
        Initializes a Decimal from an Int128 value.
        ***WARNING***: This constructor can only handle values up to 96 bits.
        """
        self.flags = 0

        if integer == 0:
            self.low = 0
            self.mid = 0
            self.high = 0
            return

        if integer < 0:
            # Set sign bit for negative integers
            self.flags = Self.SIGN_MASK

            # Handle negative value by taking absolute value first
            var abs_value = -integer

            # Set the coefficient fields
            # `high` will always be 0 because Int is 64-bit
            self.low = UInt32(abs_value & 0xFFFFFFFF)
            self.mid = UInt32((abs_value >> 32) & 0xFFFFFFFF)
            self.high = UInt32((abs_value >> 64) & 0xFFFFFFFF)
        else:
            # Positive integer
            print(integer)
            self.low = UInt32(integer & 0xFFFFFFFF)
            self.mid = UInt32((integer >> 32) & 0xFFFFFFFF)
            self.high = UInt32((integer >> 64) & 0xFFFFFFFF)

    # TODO: Add arguments to specify the scale and sign
    fn __init__(out self, integer: UInt64):
        """
        Initializes a Decimal from an UInt64 value.
        The `high` word will always be 0.
        """
        self.low = UInt32(integer & 0xFFFFFFFF)
        self.mid = UInt32((integer >> 32) & 0xFFFFFFFF)
        self.high = 0
        self.flags = 0

    # TODO: Add arguments to specify the scale and sign for all integer constructors
    fn __init__(
        out self, integer: UInt128, scale: UInt32 = 0, sign: Bool = False
    ) raises:
        """
        Initializes a Decimal from an UInt128 value.
        ***WARNING***: This constructor can only handle values up to 96 bits.
        """
        var low = UInt32(integer & 0xFFFFFFFF)
        var mid = UInt32((integer >> 32) & 0xFFFFFFFF)
        var high = UInt32((integer >> 64) & 0xFFFFFFFF)

        try:
            self = Decimal(low, mid, high, scale, sign)
        except e:
            raise Error(
                "Error in Decimal constructor with UInt128, scale, and sign: ",
                e,
            )

    fn __init__(
        out self, integer: UInt256, scale: UInt32 = 0, sign: Bool = False
    ) raises:
        """
        Initializes a Decimal from an UInt256 value.
        ***WARNING***: This constructor can only handle values up to 96 bits.
        """
        var low = UInt32(integer & 0xFFFFFFFF)
        var mid = UInt32((integer >> 32) & 0xFFFFFFFF)
        var high = UInt32((integer >> 64) & 0xFFFFFFFF)

        try:
            self = Decimal(low, mid, high, scale, sign)
        except e:
            raise Error(
                "Error in Decimal constructor with UInt256, scale, and sign: ",
                e,
            )
        self = Decimal(low, mid, high, scale, sign)

    fn __init__(out self, s: String) raises:
        """
        Initializes a Decimal from a string representation.
        Supports standard decimal notation and scientific notation.

        Args:
            s: String representation of a decimal number (e.g., "1234.5678" or "1.23e5").

        Notes
        -----
        The logic I used to implement this method is as follows:

        First, loop the string input (also differentiate the scientific notation and normal notation) and:
        - Judge whether it is negative.
        - Get the scale.
        - Extract the all the significant digits as a new string `string_of_coefficient`

        Next, check overflow:
        - If integral part of `string_of_coefficient` is larger than the max possible value of a Decimal (Decimal.MAX_AS_STRING), then raise an error that decimal is too big (first compare number of digit then compare the string).
        - Else, truncate the first 29 digits of the `string_of_coefficient` (also do rounding). Check whether his new sub-string exceeds the `MAX_AS_STRING`. Yes, it exceeds the `MAX_AS_STRING`, then truncate the first 28 digits of the `string_of_coefficient` with rounding.

        Finally, transfer the string into low, mid, and high. Construct the `flag`. Use `Decimal(low, mid, high, flags)` return the decimal.
        """
        # Initialize fields to zero
        self.low = 0
        self.mid = 0
        self.high = 0
        self.flags = 0

        # Check for empty string
        if len(s) == 0:
            return

        # Check for scientific notation
        var scientific_notation = False
        var exp_position = -1
        var exponent = 0

        # Look for 'e' or 'E' in the string to determine scientific notation
        for i in range(len(s)):
            if s[i] == String("e") or s[i] == String("E"):
                scientific_notation = True
                exp_position = i
                break

        # Parse the string based on whether it's scientific notation or not
        var parsing_str = s

        # Handle scientific notation
        if scientific_notation:
            # Extract the mantissa and exponent
            var mantissa_str = s[:exp_position]
            var exp_str = s[exp_position + 1 :]

            # Check if exponent is negative
            var exp_negative = False
            if len(exp_str) > 0 and exp_str[0] == String("-"):
                exp_negative = True
                exp_str = exp_str[1:]
            elif len(exp_str) > 0 and exp_str[0] == String("+"):
                exp_str = exp_str[1:]

            # Parse the exponent
            for i in range(len(exp_str)):
                var c = exp_str[i]
                if c >= String("0") and c <= String("9"):
                    exponent = exponent * 10 + (ord(c) - ord(String("0")))
                else:
                    raise Error("Invalid character in exponent: " + c)

            if exp_negative:
                exponent = -exponent

            # Adjust the mantissa based on the exponent
            parsing_str = mantissa_str

        # STEP 1: Determine sign and extract significant digits
        var is_negative = len(parsing_str) > 0 and parsing_str[0] == String("-")
        var start_pos = 1 if is_negative else 0
        var decimal_pos = parsing_str.find(String("."))
        var has_decimal = decimal_pos >= 0

        # Extract significant digits and calculate scale
        var string_of_coefficient = String("")
        var scale = 0
        var found_significant = False

        for i in range(start_pos, len(parsing_str)):
            var c = parsing_str[i]

            if c == String("."):
                continue  # Skip decimal point
            elif c == String(",") or c == String("_"):
                continue  # Skip separators
            elif c >= String("0") and c <= String("9"):
                # Count digits after decimal point for scale
                if has_decimal and i > decimal_pos:
                    scale += 1

                # Skip leading zeros for the coefficient
                if c != String("0") or found_significant:
                    found_significant = True
                    string_of_coefficient += c
            else:
                raise Error("Invalid character in decimal string: " + c)

        # If no significant digits found, result is zero
        if len(string_of_coefficient) == 0:
            # Set the flags for scale and sign
            self.flags = UInt32((scale << Self.SCALE_SHIFT) & Self.SCALE_MASK)
            if is_negative:
                self.flags |= Self.SIGN_MASK
            return  # Already initialized to zero

        # Adjust scale for scientific notation
        if scientific_notation:
            if exponent > 0:
                # Move decimal point right
                if scale <= exponent:
                    # Append zeros if needed
                    string_of_coefficient += String("0") * (exponent - scale)
                    scale = 0
                else:
                    scale -= exponent
            else:
                # Move decimal point left (increase scale)
                scale += -exponent

        # STEP 2: If scale  > MAX_SCALE,
        # round the coefficient string after truncating
        # and re-calculate the scale
        if scale > Self.MAX_SCALE:
            var diff_scale = scale - Self.MAX_SCALE
            var kept_digits = len(string_of_coefficient) - diff_scale

            # Truncate the coefficient string to 29 digits
            if kept_digits < 0:
                string_of_coefficient = String("0")
            else:
                string_of_coefficient = string_of_coefficient[:kept_digits]

            # Apply rounding if needed
            if kept_digits < len(string_of_coefficient):
                if string_of_coefficient[kept_digits] >= String("5"):
                    # Same rounding logic as above
                    var carry = 1
                    var result_chars = List[String]()

                    for i in range(len(string_of_coefficient)):
                        result_chars.append(string_of_coefficient[i])

                    var pos = Self.MAX_SCALE
                    while pos >= 0 and carry > 0:
                        var digit = ord(result_chars[pos]) - ord(String("0"))
                        digit += carry

                        if digit < 10:
                            result_chars[pos] = chr(digit + ord(String("0")))
                            carry = 0
                        else:
                            result_chars[pos] = String("0")
                            carry = 1
                        pos -= 1

                    if carry > 0:
                        result_chars.insert(0, String("1"))

                    string_of_coefficient = String("")
                    for ch in result_chars:
                        string_of_coefficient += ch[]

            scale = Self.MAX_SCALE

        # STEP 2: Check for overflow
        # Check if the integral part of the coefficient is too large
        var string_of_integral_part: String
        if len(string_of_coefficient) > scale:
            string_of_integral_part = string_of_coefficient[
                : len(string_of_coefficient) - scale
            ]
        else:
            string_of_integral_part = String("0")

        if (len(string_of_integral_part) > Decimal.MAX_NUM_DIGITS) or (
            len(string_of_integral_part) == Decimal.MAX_NUM_DIGITS
            and (string_of_integral_part > Self.MAX_AS_STRING)
        ):
            raise Error(
                "\nError in init from string: Integral part of the Decimal"
                " value too large: "
                + s
            )

        # Check if the coefficient is too large
        # Recursively re-calculate the coefficient string after truncating and rounding
        # until it fits within the Decimal limits
        while (len(string_of_coefficient) > Decimal.MAX_NUM_DIGITS) or (
            len(string_of_coefficient) == Decimal.MAX_NUM_DIGITS
            and (string_of_coefficient > Self.MAX_AS_STRING)
        ):
            var raw_length_of_coefficient = len(string_of_coefficient)

            # If string_of_coefficient has more than 29 digits, truncate it to 29.
            # If string_of_coefficient has 29 digits and larger than MAX_AS_STRING, truncate it to 28.
            var rounding_digit = string_of_coefficient[
                min(Decimal.MAX_NUM_DIGITS, len(string_of_coefficient) - 1)
            ]
            string_of_coefficient = string_of_coefficient[
                : min(Decimal.MAX_NUM_DIGITS, len(string_of_coefficient) - 1)
            ]

            scale = scale - (
                raw_length_of_coefficient - len(string_of_coefficient)
            )

            # Apply rounding if needed
            if rounding_digit >= String("5"):
                # Same rounding logic as above
                var carry = 1
                var result_chars = List[String]()

                for i in range(len(string_of_coefficient)):
                    result_chars.append(string_of_coefficient[i])

                var pos = len(result_chars) - 1
                while pos >= 0 and carry > 0:
                    var digit = ord(result_chars[pos]) - ord(String("0"))
                    digit += carry

                    if digit < 10:
                        result_chars[pos] = chr(digit + ord(String("0")))
                        carry = 0
                    else:
                        result_chars[pos] = String("0")
                        carry = 1
                    pos -= 1

                if carry > 0:
                    result_chars.insert(0, String("1"))

                    # If adding a digit would exceed max length, drop the last digit and reduce scale
                    if len(result_chars) > Decimal.MAX_NUM_DIGITS:
                        result_chars = result_chars[: Decimal.MAX_NUM_DIGITS]
                        if scale > 0:
                            scale -= 1

                string_of_coefficient = String("")
                for ch in result_chars:
                    string_of_coefficient += ch[]

        # Check if the coefficient exceeds MAX_AS_STRING
        if len(string_of_coefficient) == len(Self.MAX_AS_STRING):
            var is_greater = False
            for i in range(len(string_of_coefficient)):
                if string_of_coefficient[i] > Self.MAX_AS_STRING[i]:
                    is_greater = True
                    break
                elif string_of_coefficient[i] < Self.MAX_AS_STRING[i]:
                    break

            if is_greater:
                raise Error(
                    "\nError in init from string: Decimal value too large: " + s
                )
        elif len(string_of_coefficient) > len(Self.MAX_AS_STRING):
            raise Error(
                "\nError in init from string: Decimal value too large: " + s
            )

        # Step 3: Convert the coefficient string to low/mid/high parts
        var low: UInt32 = 0
        var mid: UInt32 = 0
        var high: UInt32 = 0

        for i in range(len(string_of_coefficient)):
            var digit = UInt32(ord(string_of_coefficient[i]) - ord(String("0")))

            # Multiply current value by 10 and add the new digit
            # Use 64-bit arithmetic for the calculation
            var low64 = UInt64(low) * 10 + UInt64(digit)
            var mid64 = UInt64(mid) * 10 + (low64 >> 32)
            var high64 = UInt64(high) * 10 + (mid64 >> 32)

            # Extract 32-bit parts
            low = UInt32(low64 & 0xFFFFFFFF)
            mid = UInt32(mid64 & 0xFFFFFFFF)
            high = UInt32(high64 & 0xFFFFFFFF)

        # Step 4: Set the final result
        self.low = low
        self.mid = mid
        self.high = high

        # Set the flags for scale and sign
        self.flags = UInt32((scale << Self.SCALE_SHIFT) & Self.SCALE_MASK)
        if is_negative:
            self.flags |= Self.SIGN_MASK

    # TODO: Use generic floating-point type if possible.
    fn __init__(out self, f: Float64, *, MAX_SCALE: Bool = True) raises:
        """
        Initializes a Decimal from a floating-point value.
        You may lose precision because float representation is inexact.
        """
        var float_str: String

        if MAX_SCALE:
            # Use maximum precision
            # Convert float to string ith high precision to capture all significant digits
            # The format ensures we get up to MAX_SCALE decimal places
            float_str = decimojo.str._float_to_decimal_str(f, Self.MAX_SCALE)
        else:
            # Use default string representation
            # Convert float to string with Mojo's default precision
            float_str = String(f)

        # Use the string constructor which already handles overflow correctly
        self = Decimal(float_str)

    fn __copyinit__(out self, other: Self):
        """
        Initializes a Decimal by copying another Decimal.
        """
        self.low = other.low
        self.mid = other.mid
        self.high = other.high
        self.flags = other.flags

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_raw_words(
        low: UInt32, mid: UInt32, high: UInt32, flags: UInt32
    ) -> Self:
        """
        Initializes a Decimal with internal representation fields.
        We do not check whether the scale is within the valid range.
        """

        var result = Decimal()
        result.low = low
        result.mid = mid
        result.high = high
        result.flags = flags

        return result

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders, and other type-transfer methods
    # ===------------------------------------------------------------------=== #

    fn __float__(self) -> Float64:
        """
        Converts this Decimal to a floating-point value.
        Because Decimal is fixed-point, this may lose precision.

        Returns:
            The floating-point representation of this Decimal.
        """

        var result = Float64(self.coefficient()) / (10 ** self.scale())
        result = -result if self.is_negative() else result

        return result

    fn __int__(self) -> Int:
        """
        Converts this Decimal to an Int value.
        ***WARNING***: If the Decimal is too large to fit in an Int,
        this will become the maximum or minimum Int value.

        Returns:
            The Int representation of this Decimal.
        """

        var res = Int(self.to_uint128())

        return -res if self.is_negative() else res

    fn __str__(self) -> String:
        """
        Returns string representation of the Decimal.
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

    fn __repr__(self) -> String:
        """
        Returns a string representation of the Decimal.
        """
        return 'Decimal("' + self.__str__() + '")'

    fn to_int128(self) -> Int128:
        """
        Returns the signed integral part of the Decimal.
        Compared to `__int__` method, the returned value will not be truncated.
        """

        var res = Int128(self.to_uint128())

        return -res if self.is_negative() else res

    fn to_uint128(self) -> UInt128:
        """
        Returns the unsigned integral part of the Decimal.
        Compared to `__int__` method, the returned value will not be truncated.
        """

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
            res = self.coefficient() // 10 ** UInt128(self.scale())

        return res

    fn write_to[W: Writer](self, mut writer: W):
        """
        Writes the Decimal to a writer.
        """
        writer.write(String(self))

    # ===------------------------------------------------------------------=== #
    # Basic unary operation dunders
    # neg
    # ===------------------------------------------------------------------=== #

    fn __abs__(self) -> Self:
        """
        Returns the absolute value of this Decimal.

        Returns:
            The absolute value of this Decimal.
        """
        var result = Decimal.from_raw_words(
            self.low, self.mid, self.high, self.flags
        )
        result.flags &= ~Self.SIGN_MASK  # Clear sign bit

        return result

    fn __neg__(self) -> Self:
        """Unary negation operator."""
        # Special case for negative zero
        if self.is_zero():
            return Decimal.ZERO()

        var result = Decimal.from_raw_words(
            self.low, self.mid, self.high, self.flags
        )
        result.flags ^= Self.SIGN_MASK  # Flip sign bit
        return result

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # add, sub, mul, truediv, pow
    # ===------------------------------------------------------------------=== #
    fn __add__(self, other: Decimal) raises -> Self:
        """
        Adds two Decimal values and returns a new Decimal containing the sum.

        Args:
            other: The Decimal to add to this Decimal.

        Returns:
            A new Decimal containing the sum.

        Raises:
            Error: If an error occurs during the addition, forward the error.
        """

        try:
            return decimojo.add(self, other)
        except e:
            raise Error("Error in `__add__()`; ", e)

    fn __add__(self, other: Float64) raises -> Self:
        return decimojo.add(self, Decimal(other))

    fn __add__(self, other: Int) raises -> Self:
        return decimojo.add(self, Decimal(other))

    fn __radd__(self, other: Float64) raises -> Self:
        return decimojo.add(Decimal(other), self)

    fn __radd__(self, other: Int) raises -> Self:
        return decimojo.add(Decimal(other), self)

    fn __sub__(self, other: Decimal) raises -> Self:
        """
        Subtracts the other Decimal from self and returns a new Decimal.

        Args:
            other: The Decimal to subtract from this Decimal.

        Returns:
            A new Decimal containing the difference

        Notes:
        This method is implemented using the existing `__add__()` and `__neg__()` methods.

        Examples:
        ```console
        var a = Decimal("10.5")
        var b = Decimal("3.2")
        var result = a - b  # Returns 7.3
        ```
        .
        """

        try:
            return decimojo.subtract(self, other)
        except e:
            raise Error("Error in `__sub__()`; ", e)

    fn __sub__(self, other: Float64) raises -> Self:
        return decimojo.subtract(self, Decimal(other))

    fn __sub__(self, other: Int) raises -> Self:
        return decimojo.subtract(self, Decimal(other))

    fn __rsub__(self, other: Float64) raises -> Self:
        return decimojo.subtract(Decimal(other), self)

    fn __rsub__(self, other: Int) raises -> Self:
        return decimojo.subtract(Decimal(other), self)

    fn __mul__(self, other: Decimal) raises -> Self:
        """
        Multiplies two Decimal values and returns a new Decimal containing the product.
        """

        return decimojo.multiply(self, other)

    fn __mul__(self, other: Float64) raises -> Self:
        return decimojo.multiply(self, Decimal(other))

    fn __mul__(self, other: Int) raises -> Self:
        return decimojo.multiply(self, Decimal(other))

    fn __truediv__(self, other: Decimal) raises -> Self:
        """
        Divides this Decimal by another Decimal and returns a new Decimal containing the result.
        """
        return decimojo.true_divide(self, other)

    fn __truediv__(self, other: Float64) raises -> Self:
        return decimojo.true_divide(self, Decimal(other))

    fn __truediv__(self, other: Int) raises -> Self:
        return decimojo.true_divide(self, Decimal(other))

    fn __rtruediv__(self, other: Float64) raises -> Self:
        return decimojo.true_divide(Decimal(other), self)

    fn __rtruediv__(self, other: Int) raises -> Self:
        return decimojo.true_divide(Decimal(other), self)

    fn __pow__(self, exponent: Decimal) raises -> Self:
        """
        Raises self to the power of exponent and returns a new Decimal.

        Currently supports integer exponents only.

        Args:
            exponent: The power to raise self to.
                It must be an integer or effectively an integer (e.g., 2.0).

        Returns:
            A new Decimal containing the result of self^exponent

        Raises:
            Error: If exponent is not an integer or if the operation would overflow.
        """

        return decimal.power(self, exponent)

    fn __pow__(self, exponent: Int) raises -> Self:
        return decimal.power(self, exponent)

    fn __pow__(self, exponent: Float64) raises -> Self:
        return decimal.power(self, Decimal(exponent))

    # ===------------------------------------------------------------------=== #
    # Basic binary logic operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    fn __gt__(self, other: Decimal) -> Bool:
        """
        Greater than comparison operator.

        Args:
            other: The Decimal to compare with.

        Returns:
            True if self is greater than other, False otherwise.
        """
        return decimojo.greater(self, other)

    fn __ge__(self, other: Decimal) -> Bool:
        """
        Greater than or equal comparison operator.

        Args:
            other: The Decimal to compare with.

        Returns:
            True if self is greater than or equal to other, False otherwise.
        """
        return decimojo.greater_equal(self, other)

    fn __lt__(self, other: Decimal) -> Bool:
        """
        Less than comparison operator.

        Args:
            other: The Decimal to compare with.

        Returns:
            True if self is less than other, False otherwise.
        """
        return decimojo.less(self, other)

    fn __le__(self, other: Decimal) -> Bool:
        """
        Less than or equal comparison operator.

        Args:
            other: The Decimal to compare with.

        Returns:
            True if self is less than or equal to other, False otherwise.
        """
        return decimojo.less_equal(self, other)

    fn __eq__(self, other: Decimal) -> Bool:
        """
        Equality comparison operator.

        Args:
            other: The Decimal to compare with.

        Returns:
            True if self is equal to other, False otherwise.
        """
        return decimojo.equal(self, other)

    fn __ne__(self, other: Decimal) -> Bool:
        """
        Inequality comparison operator.

        Args:
            other: The Decimal to compare with.

        Returns:
            True if self is not equal to other, False otherwise.
        """
        return decimojo.not_equal(self, other)

    # ===------------------------------------------------------------------=== #
    # Other dunders that implements traits
    # round
    # ===------------------------------------------------------------------=== #

    fn __round__(self, ndigits: Int) -> Self:
        """
        Rounds this Decimal to the specified number of decimal places.
        If `ndigits` is not given, rounds to 0 decimal places.
        If rounding causes overflow, returns the value itself.

        raises:
            Error: Calling `round()` failed.
        """

        try:
            return decimojo.round(
                self, ndigits=ndigits, rounding_mode=RoundingMode.HALF_EVEN()
            )
        except e:
            return self

    fn __round__(self) -> Self:
        """**OVERLOAD**."""

        return self.__round__(ndigits=0)

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # round, sqrt
    # ===------------------------------------------------------------------=== #

    fn round(
        self,
        ndigits: Int = 0,
        rounding_mode: RoundingMode = RoundingMode.ROUND_HALF_EVEN,
    ) raises -> Self:
        """
        Rounds this Decimal to the specified number of decimal places.
        Compared to `__round__`, this method:
        (1) Allows specifying the rounding mode.
        (2) Raises an error if the operation would result in overflow.

        Args:
            ndigits: The number of decimal places to round to.
                Default is 0.
            rounding_mode: The rounding mode to use.
                Default is RoundingMode.ROUND_HALF_EVEN.

        Returns:
            The rounded Decimal value.

        Raises:
            Error: If calling `round()` failed.
        """

        try:
            return decimojo.round(
                self, ndigits=ndigits, rounding_mode=rounding_mode
            )
        except e:
            raise Error("Error in `Decimal.round()`; ", e)

    fn sqrt(self) raises -> Self:
        """
        Calculates the square root of this Decimal.

        Returns:
            The square root of this Decimal.

        Raises:
            Error: If the operation would result in overflow.
        """

        return decimojo.sqrt(self)

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #

    fn coefficient(self) -> UInt128:
        """
        Returns the unscaled integer coefficient as an UInt128 value.
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

    fn is_integer(self) -> Bool:
        """
        Determines whether this Decimal value represents an integer.
        A Decimal represents an integer when it has no fractional part
        (i.e., all digits after the decimal point are zero).

        Returns:
            True if this Decimal represents an integer value, False otherwise.
        """

        # If scale is 0, it's already an integer
        if self.scale() == 0:
            return True

        # If value is zero, it's an integer regardless of scale
        if self.is_zero():
            return True

        # For a value to be an integer, it must be divisible by 10^scale
        # If coefficient % 10^scale == 0, then all decimal places are zeros
        # If it divides evenly, it's an integer
        return (
            self.coefficient() % (UInt128(10) ** UInt128(self.scale()))
        ) == 0

    fn is_negative(self) -> Bool:
        """Returns True if this Decimal is negative."""
        return (self.flags & Self.SIGN_MASK) != 0

    fn is_one(self) -> Bool:
        """
        Returns True if this Decimal represents the value 1.
        If 10^scale == coefficient, then it's one.
        `1` and `1.00` are considered ones.
        """
        if self.is_negative():
            return False

        var scale = self.scale()
        var coef = self.coefficient()

        if scale == 0 and coef == 1:
            return True

        if UInt128(10) ** scale == coef:
            return True

        return False

    fn is_zero(self) -> Bool:
        """
        Returns True if this Decimal represents zero.
        A decimal is zero when all coefficient parts (low, mid, high) are zero,
        regardless of its sign or scale.
        """
        return self.low == 0 and self.mid == 0 and self.high == 0

    fn is_infinity(self) -> Bool:
        """Returns True if this Decimal is positive or negative infinity."""
        return (self.flags & Self.INFINITY_MASK) != 0

    fn is_nan(self) -> Bool:
        """Returns True if this Decimal is NaN (Not a Number)."""
        return (self.flags & Self.NAN_MASK) != 0

    fn scale(self) -> Int:
        """Returns the scale (number of decimal places) of this Decimal."""
        return Int((self.flags & Self.SCALE_MASK) >> Self.SCALE_SHIFT)

    fn scientific_exponent(self) -> Int:
        """
        Calculates the exponent for scientific notation representation of a Decimal.
        The exponent is the power of 10 needed to represent the value in scientific notation.
        """

        return self.number_of_significant_digits() - 1 - self.scale()

    fn number_of_significant_digits(self) -> Int:
        """
        Returns the number of significant digits in this Decimal.
        The number of significant digits is the total number of digits in the coefficient,
        excluding leading and trailing zeros.
        """

        # Special case for zero
        if self.coefficient() == 0:
            return 0  # Zero has zero significant digit

        # Count digits using integer division
        var digit_count = 0
        var temp = self.coefficient()

        while temp > 0:
            temp //= 10
            digit_count += 1

        return digit_count

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn _abs_compare(self, other: Decimal) raises -> Int:
        """
        Compares absolute values of two Decimal numbers, ignoring signs.

        Returns:
        - Positive value if |self| > |other|
        - Zero if |self| = |other|
        - Negative value if |self| < |other|
        """
        var abs_self = decimojo.absolute(self)
        var abs_other = decimojo.absolute(other)

        if abs_self > abs_other:
            return 1
        elif abs_self < abs_other:
            return -1
        else:
            return 0

    fn internal_representation(value: Decimal):
        # Show internal representation details
        print("\nInternal Representation Details:")
        print("--------------------------------")
        print("Decimal:       ", value)
        print("coefficient:   ", value.coefficient())
        print("scale:         ", value.scale())
        print("is negative:   ", value.is_negative())
        print("is zero:       ", value.is_zero())
        print("low:           ", value.low)
        print("mid:           ", value.mid)
        print("high:          ", value.high)
        print("low byte:      ", hex(value.low))
        print("mid byte:      ", hex(value.mid))
        print("high byte:     ", hex(value.high))
        print("flags byte:    ", hex(value.flags))
        print("--------------------------------")

    fn _scale_down(
        self,
        owned scale_diff: Int,
        rounding_mode: RoundingMode = RoundingMode.HALF_EVEN(),
    ) -> Decimal:
        """
        Internal method to scale down a decimal by dividing by 10^scale_diff.

        Args:
            scale_diff: Number of decimal places to scale down by
            rounding_mode: Rounding mode to use

        Returns:
            A new Decimal with the scaled down value
        """
        var result = self

        # Early return if no scaling needed
        if scale_diff <= 0:
            return result

        # Update the scale in the flags
        var new_scale = self.scale() - scale_diff
        if new_scale < 0:
            # Cannot scale below zero, limit the scaling
            scale_diff = self.scale()
            new_scale = 0

        # With UInt128, we can represent the coefficient as a single value
        var coefficient = UInt128(self.high) << 64 | UInt128(
            self.mid
        ) << 32 | UInt128(self.low)

        # Collect all digits that will be removed for rounding decision
        var removed_digits = List[UInt8]()

        # Calculate coefficient / 10^scale_diff and collect remainder digits
        for _ in range(scale_diff):
            var last_digit = UInt8(coefficient % 10)
            coefficient //= 10
            removed_digits.append(last_digit)

        # After collecting digits, reverse the list for correct rounding
        var reversed_digits = List[UInt8]()
        for i in range(len(removed_digits) - 1, -1, -1):
            reversed_digits.append(removed_digits[i])
        removed_digits = reversed_digits

        # Now we have all the digits to be removed, apply proper rounding
        var should_round_up = False

        if rounding_mode == RoundingMode.DOWN():
            # Truncate (do nothing)
            should_round_up = False
        elif rounding_mode == RoundingMode.UP():
            # Always round up if any non-zero digit was removed
            for digit in removed_digits:
                if digit[] != 0:
                    should_round_up = True
                    break
        elif rounding_mode == RoundingMode.HALF_UP():
            # Round up if first removed digit >= 5
            if len(removed_digits) > 0 and removed_digits[0] >= 5:
                should_round_up = True
        elif rounding_mode == RoundingMode.HALF_EVEN():
            # Apply banker's rounding
            if len(removed_digits) > 0:
                var first_digit = removed_digits[0]
                if first_digit > 5:
                    # Round up
                    should_round_up = True
                elif first_digit == 5:
                    # For banker's rounding:
                    # 1. If there are other non-zero digits after 5, round up
                    # 2. Otherwise, round to nearest even (round up if odd)
                    var has_non_zero_after = False
                    for i in range(1, len(removed_digits)):
                        if removed_digits[i] != 0:
                            has_non_zero_after = True
                            break

                    if has_non_zero_after:
                        should_round_up = True
                    else:
                        # Round to even - check if the low digit is odd
                        should_round_up = (coefficient & 1) == 1

        # Apply rounding if needed
        if should_round_up:
            coefficient += 1

        # Extract the 32-bit components from the UInt128
        result.low = UInt32(coefficient & 0xFFFFFFFF)
        result.mid = UInt32((coefficient >> 32) & 0xFFFFFFFF)
        result.high = UInt32((coefficient >> 64) & 0xFFFFFFFF)

        # Set the new scale
        result.flags = (self.flags & ~Self.SCALE_MASK) | (
            UInt32(new_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        )

        return result
