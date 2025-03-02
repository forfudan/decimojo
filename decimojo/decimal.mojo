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
# Docstring style:
# 1. Description
# 2. Parameters
# 3. Args
# 4. Constraints
# 4) Returns
# 5) Raises
# 9) Examples
# ===----------------------------------------------------------------------=== #
#
# ===----------------------------------------------------------------------=== #
# TODO: Implement basic arithmetics for decimals.
# ===----------------------------------------------------------------------=== #

"""
Implements basic object methods for working with decimal numbers.
"""


struct Decimal(Writable):
    """
    Correctly-rounded fixed-precision number.

    Internal Representation
    -----------------------
    Each decimal uses a 128-bit on memory, where (for right-to-left):
    - 96 bits for the coefficient (mantissa), which is 96-bit unsigned integers
      stored as three 32 bit integer (low, mid, high).
      The value of the coefficient is: high * 2**64 + mid * 2**32 + low
    - 32 bits for the flags, which contain the sign and scale information.
      - Bits 0 to 15 are unused and must be zero.
      - Bits 16 to 23 must contain an scale (exponent) between 0 and 28.
      - Bits 24 to 30 are unused and must be zero.
      - Bit 31 contains the sign: 0 mean positive, and 1 means negative.

    The final value is: (-1)**sign * coefficient * 10**(-scale)

    Reference
    ---------
    - General Decimal Arithmetic Specification Version 1.70 – 7 Apr 2009 (https://speleotrove.com/decimal/decarith.html)
    - https://learn.microsoft.com/en-us/dotnet/api/system.decimal.getbits?view=net-9.0&redirectedfrom=MSDN#System_Decimal_GetBits_System_Decimal_
    """

    # Internal representation fields
    var low: UInt32  # Least significant 32 bits of coefficient
    var mid: UInt32  # Middle 32 bits of coefficient
    var high: UInt32  # Most significant 32 bits of coefficient
    var flags: UInt32  # Scale information and the sign

    # Constants
    alias MAX_PRECISION = 28
    alias SIGN_MASK = UInt32(0x80000000)
    """
    Sign mask.
    `0b1000_0000_0000_0000_0000_0000_0000_0000`.
    1 bit for sign (0 is positive and 1 is negative).
    """
    alias SCALE_MASK = UInt32(0x00FF0000)
    """
    `0b0000_0000_1111_1111_0000_0000_0000_0000`.
    Bits 0 to 15 are unused and must be zero.
    Bits 16 to 23 must contain an exponent between 0 and 28.
    Bits 24 to 30 are unused and must be zero."""
    alias SCALE_SHIFT = UInt32(16)
    """
    Bits 16 to 23 must contain an exponent between 0 and 28.
    """

    # Special values
    @staticmethod
    fn ZERO() -> Decimal:
        """Returns a Decimal representing 0."""
        return Decimal(0, 0, 0, 0)

    @staticmethod
    fn ONE() -> Decimal:
        """Returns a Decimal representing 1."""
        return Decimal(1, 0, 0, 0)

    @staticmethod
    fn NEGATIVE_ONE() -> Decimal:
        """Returns a Decimal representing -1."""
        return Decimal(1, 0, 0, Decimal.SIGN_MASK)

    @staticmethod
    fn MAX() -> Decimal:
        """
        Returns the maximum possible Decimal value.
        This is equivalent to 79228162514264337593543950335.
        """
        return Decimal(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0)

    @staticmethod
    fn MIN() -> Decimal:
        """Returns the minimum possible Decimal value (negative of MAX).
        This is equivalent to -79228162514264337593543950335.
        """
        return Decimal(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, Decimal.SIGN_MASK)

    # ===------------------------------------------------------------------=== #
    # Constructors and life time methods
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
        out self, low: UInt32, mid: UInt32, high: UInt32, flags: UInt32
    ):
        """
        Initializes a Decimal with internal representation fields.
        """
        self.low = low
        self.mid = mid
        self.high = high
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

    # TODO Improve it to handle more cases and formats, e.g., _ and space.
    fn __init__(out self, s: String) raises:
        """
        Initializes a Decimal from a string representation.

        Args:
            s: String representation of a decimal number (e.g., "1234.5678").

        Returns:
            A new Decimal instance.

        Examples:
        ```console
        > Decimal("123.456")                  # Returns 123.456
        > Decimal("-0.789")                   # Returns -0.789
        ```

        Notes:
        Since Int is a 64-bit type in Mojo, this constructor can only
        handle values up to 64 bits. The `high` field will always be 0.
        """
        var bytes_of_string = s.as_bytes()
        var is_negative: Bool = False
        var is_decimal_point = False
        var scale: UInt32 = 0

        var low: UInt32 = 0
        var mid: UInt32 = 0
        var high: UInt32 = 0

        for i in range(len(bytes_of_string)):
            var c = bytes_of_string[i]

            if i == 0 and c == ord("-"):
                is_negative = True
            elif c == ord("."):
                is_decimal_point = True
            elif (c >= ord("0")) and (c <= ord("9")):
                # Extract the digit
                var digit = UInt32(c - ord("0"))

                # STEP 1: Multiply existing coefficient by 10
                # Use 64-bit arithmetic for the calculation
                var low64 = UInt64(low) * 10
                var mid64 = UInt64(mid) * 10 + (low64 >> 32)
                var high64 = UInt64(high) * 10 + (mid64 >> 32)

                # Check for overflow in high part
                if high64 > 0xFFFFFFFF:
                    raise Error("Decimal value too large")

                # Extract 32-bit values
                low = UInt32(low64 & 0xFFFFFFFF)
                mid = UInt32(mid64 & 0xFFFFFFFF)
                high = UInt32(high64 & 0xFFFFFFFF)

                # STEP 2: Add the digit
                # Use 64-bit arithmetic for the addition
                var sum64 = UInt64(low) + UInt64(digit)
                low = UInt32(sum64 & 0xFFFFFFFF)

                # Handle carry to mid if needed
                if sum64 > 0xFFFFFFFF:
                    mid64 = UInt64(mid) + 1
                    mid = UInt32(mid64 & 0xFFFFFFFF)

                    # Handle carry to high if needed
                    if mid64 > 0xFFFFFFFF:
                        high += 1
                        if high == 0:  # Overflow check
                            raise Error("Decimal value too large")

                # Update scale if we are after the decimal point
                if is_decimal_point:
                    scale += 1
            elif c == ord(" ") or c == ord("_"):
                # Allow spaces and underscores for readability
                continue
            else:
                raise Error("Invalid character in decimal string")

        # Set the flags
        var flags = UInt32((scale << Self.SCALE_SHIFT) & Self.SCALE_MASK)
        if is_negative:
            flags |= Self.SIGN_MASK

        self = Decimal(low, mid, high, flags)

    # TODO: Use generic floating-point type.
    fn __init__(out self, f: Float64) raises:
        """
        Initializes a Decimal from a floating-point value.
        You may lose precision because float representation is inexact.
        """
        # Handle sign first
        var is_negative = f < 0
        var abs_value = abs(f)

        # Convert to string with high precision to capture all significant digits
        # The format ensures we get up to MAX_PRECISION decimal places
        var float_str = _float_to_decimal_str(abs_value, Self.MAX_PRECISION)

        # Remove trailing zeros after decimal point
        var decimal_pos = float_str.find(".")
        if decimal_pos >= 0:
            var i = len(float_str) - 1
            while i > decimal_pos and float_str[i] == "0":
                i -= 1

            # If only the decimal point is left, remove it too
            if i == decimal_pos:
                float_str = float_str[:decimal_pos]
            else:
                float_str = float_str[: i + 1]

        # Add negative sign if needed
        if is_negative:
            float_str = "-" + float_str

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

    fn __moveinit__(out self, owned other: Self):
        """
        Initializes a Decimal by moving from another Decimal.
        """
        self.low = other.low
        self.mid = other.mid
        self.high = other.high
        self.flags = other.flags

    # ===------------------------------------------------------------------=== #
    # Output dunders and other methods
    # ===------------------------------------------------------------------=== #

    fn __str__(self) -> String:
        """
        Returns string representation of the Decimal.

        Examples:
        ```console
        > str(Decimal.from_string("123.456")) == "123.456"
        > str(Decimal.from_string("-0.789")) == "-0.789"
        ```
        """
        # Get the coefficient as a string (absolute value)
        var coef = self.coefficient()
        var scale = self.scale()

        # Handle zero as a special case
        if coef == "0":
            if scale > 0:
                return "0." + "0" * scale
            else:
                return "0"

        # For non-zero values, format according to scale
        var result: String

        if scale == 0:
            # No decimal places needed
            result = coef
        elif scale >= len(coef):
            # Need leading zeros after decimal point
            result = "0." + "0" * (scale - len(coef)) + coef
        else:
            # Insert decimal point at appropriate position
            var insert_pos = len(coef) - scale
            result = coef[:insert_pos] + "." + coef[insert_pos:]

        # Add negative sign if needed
        if self.is_negative() and result != "0":
            result = "-" + result

        return result

    fn write_to[W: Writer](self, mut writer: W):
        """
        Writes the Decimal to a writer.
        """
        writer.write(String(self))

    # ===------------------------------------------------------------------=== #
    # Basic operation dunders
    # ===------------------------------------------------------------------=== #

    # TODO Align scales and handle overflows.
    fn __add__(self, other: Decimal) -> Decimal:
        """
        Add two Decimal values.
        """
        if self.scale() == other.scale():
            var result = Decimal()
            result.flags = (
                self.flags & ~Self.SIGN_MASK
            )  # Copy scale but clear sign

            if self.is_negative() == other.is_negative():
                # Same sign: add coefficients and keep sign
                if self.is_negative():
                    result.flags |= Self.SIGN_MASK

                # Add with carry
                var carry: UInt32 = 0

                # Add low parts
                var sum = UInt64(self.low) + UInt64(other.low)
                result.low = UInt32(sum & 0xFFFFFFFF)
                carry = UInt32(sum >> 32)

                # Add mid parts with carry
                sum = UInt64(self.mid) + UInt64(other.mid) + UInt64(carry)
                result.mid = UInt32(sum & 0xFFFFFFFF)
                carry = UInt32(sum >> 32)

                # Add high parts with carry
                sum = UInt64(self.high) + UInt64(other.high) + UInt64(carry)
                result.high = UInt32(sum & 0xFFFFFFFF)
                # If there's still carry, we have overflow - not handled here

            else:
                # Different signs: subtract smaller absolute value from larger
                # First determine which has larger absolute value
                var self_larger = False

                # Compare high parts first
                if self.high > other.high:
                    self_larger = True
                elif self.high < other.high:
                    self_larger = False
                # If high parts equal, compare mid parts
                elif self.mid > other.mid:
                    self_larger = True
                elif self.mid < other.mid:
                    self_larger = False
                # If mid parts equal, compare low parts
                elif self.low >= other.low:
                    self_larger = True
                else:
                    self_larger = False

                # Perform subtraction (larger - smaller)
                var a: Decimal
                var b: Decimal

                if self_larger:
                    a = self
                    b = other
                    # Result takes sign of self (the larger value)
                    if self.is_negative():
                        result.flags |= Self.SIGN_MASK
                else:
                    a = other
                    b = self
                    # Result takes sign of other (the larger value)
                    if other.is_negative():
                        result.flags |= Self.SIGN_MASK

                # Subtract b from a with borrow
                var borrow: UInt32 = 0

                # Subtract low parts
                if a.low >= b.low + borrow:
                    result.low = a.low - b.low - borrow
                    borrow = 0
                else:
                    result.low = UInt32(0x100000000 + a.low - b.low - borrow)
                    borrow = 1

                # Subtract mid parts with borrow
                if a.mid >= b.mid + borrow:
                    result.mid = a.mid - b.mid - borrow
                    borrow = 0
                else:
                    result.mid = UInt32(0x100000000 + a.mid - b.mid - borrow)
                    borrow = 1

                # Subtract high parts with borrow
                result.high = a.high - b.high - borrow

            return result
        else:
            # Different scales: need to align before adding
            var result = Decimal()
            var self_copy = self
            var other_copy = other

            # Determine which decimal has larger scale (more decimal places)
            var self_scale = self.scale()
            var other_scale = other.scale()
            var target_scale = max(self_scale, other_scale)

            # Set the result scale to the target scale
            result.flags = UInt32(
                (target_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
            )

            # Scale up the decimal with smaller scale
            if self_scale < other_scale:
                # Scale up self
                var scale_diff = other_scale - self_scale
                self_copy = self_copy._scale_up(scale_diff)
            elif other_scale < self_scale:
                # Scale up other
                var scale_diff = self_scale - other_scale
                other_copy = other_copy._scale_up(scale_diff)

            # Now both have the same scale, perform addition
            if self_copy.is_negative() == other_copy.is_negative():
                # Same sign: add coefficients and keep sign
                if self_copy.is_negative():
                    result.flags |= Self.SIGN_MASK

                # Add with carry
                var carry: UInt32 = 0

                # Add low parts
                var sum = UInt64(self_copy.low) + UInt64(other_copy.low)
                result.low = UInt32(sum & 0xFFFFFFFF)
                carry = UInt32(sum >> 32)

                # Add mid parts with carry
                sum = (
                    UInt64(self_copy.mid)
                    + UInt64(other_copy.mid)
                    + UInt64(carry)
                )
                result.mid = UInt32(sum & 0xFFFFFFFF)
                carry = UInt32(sum >> 32)

                # Add high parts with carry
                sum = (
                    UInt64(self_copy.high)
                    + UInt64(other_copy.high)
                    + UInt64(carry)
                )
                result.high = UInt32(sum & 0xFFFFFFFF)
                # If there's still carry, we have overflow - not handling here

            else:
                # Different signs: subtract smaller absolute value from larger
                # First determine which has larger absolute value
                var self_larger = False

                # Compare high parts first
                if self_copy.high > other_copy.high:
                    self_larger = True
                elif self_copy.high < other_copy.high:
                    self_larger = False
                # If high parts equal, compare mid parts
                elif self_copy.mid > other_copy.mid:
                    self_larger = True
                elif self_copy.mid < other_copy.mid:
                    self_larger = False
                # If mid parts equal, compare low parts
                elif self_copy.low >= other_copy.low:
                    self_larger = True
                else:
                    self_larger = False

                # Perform subtraction (larger - smaller)
                var a: Decimal
                var b: Decimal

                if self_larger:
                    a = self_copy
                    b = other_copy
                    # Result takes sign of self (the larger value)
                    if self_copy.is_negative():
                        result.flags |= Self.SIGN_MASK
                else:
                    a = other_copy
                    b = self_copy
                    # Result takes sign of other (the larger value)
                    if other_copy.is_negative():
                        result.flags |= Self.SIGN_MASK

                # Subtract b from a with borrow
                var borrow: UInt32 = 0

                # Subtract low parts
                if a.low >= b.low + borrow:
                    result.low = a.low - b.low - borrow
                    borrow = 0
                else:
                    result.low = UInt32(0x100000000 + a.low - b.low - borrow)
                    borrow = 1

                # Subtract mid parts with borrow
                if a.mid >= b.mid + borrow:
                    result.mid = a.mid - b.mid - borrow
                    borrow = 0
                else:
                    result.mid = UInt32(0x100000000 + a.mid - b.mid - borrow)
                    borrow = 1

                # Subtract high parts with borrow
                result.high = a.high - b.high - borrow

            return result

    fn __neg__(self) -> Decimal:
        """Unary negation operator."""
        var result = Decimal(self.low, self.mid, self.high, self.flags)
        result.flags ^= Self.SIGN_MASK  # Flip sign bit
        return result

    # ===------------------------------------------------------------------=== #
    # Other methods
    # ===------------------------------------------------------------------=== #
    fn coefficient(self) -> String:
        """
        Returns the unscaled integer coefficient.
        This is the absolute value of the decimal digits without considering the scale or sign.
        We need to combine the three 32-bit parts into a single value.
        Since we might exceed built-in integer limits, we build the string directly.
        The value of the coefficient is: high * 2**64 + mid * 2**32 + low.
        """
        if self.low == 0 and self.mid == 0 and self.high == 0:
            return "0"

        # We need to build the decimal representation of the 96-bit integer
        # by repeatedly dividing by 10 and collecting remainders
        var result = String("")
        var h = UInt64(self.high)
        var m = UInt64(self.mid)
        var l = UInt64(self.low)

        while h > 0 or m > 0 or l > 0:
            # Perform division by 10 across all three parts
            var remainder: UInt64 = 0
            var new_h: UInt64 = 0
            var new_m: UInt64 = 0
            var new_l: UInt64 = 0

            # Process high part
            if h > 0:
                new_h = h // 10
                remainder = h % 10
                # Propagate remainder to mid
                m += remainder << 32  # equivalent to remainder * 2^32

            # Process mid part
            if m > 0:
                new_m = m // 10
                remainder = m % 10
                # Propagate remainder to low
                l += remainder << 32  # equivalent to remainder * 2^32

            # Process low part
            if l > 0:
                new_l = l // 10
                remainder = l % 10

            # Append remainder to result (in reverse order)
            result = String(remainder) + String(result)

            # Update values for next iteration
            h = new_h
            m = new_m
            l = new_l

        return result

    fn is_negative(self) -> Bool:
        """Returns True if this Decimal is negative."""
        return (self.flags & Self.SIGN_MASK) != 0

    fn scale(self) -> Int:
        """Returns the scale (number of decimal places) of this Decimal."""
        return Int((self.flags & Self.SCALE_MASK) >> Self.SCALE_SHIFT)

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn _internal_representation(value: Decimal):
        # Show internal representation details
        print("\nInternal Representation Details:")
        print("--------------------------------")
        print("Decimal:       ", value)
        print("low:           ", value.low)
        print("mid:           ", value.mid)
        print("high:          ", value.high)
        print("coefficient:   ", value.coefficient())
        print("scale:         ", value.scale())
        print("is negative:   ", value.is_negative())
        print("--------------------------------")

    fn _scale_up(self, owned scale_diff: Int) -> Decimal:
        """
        Internal method to scale up a decimal by multiplying by 10^scale_diff.

        Args:
            scale_diff: Number of decimal places to scale up by

        Returns:
            A new Decimal with the scaled up value
        """
        var result = self

        # Early return if no scaling needed
        if scale_diff <= 0:
            return result

        # Update the scale in the flags
        var new_scale = self.scale() + scale_diff
        if new_scale > Self.MAX_PRECISION:
            # Cannot scale beyond max precision, limit the scaling
            scale_diff = Self.MAX_PRECISION - self.scale()
            new_scale = Self.MAX_PRECISION

        result.flags = (result.flags & ~Self.SCALE_MASK) | (
            UInt32(new_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        )

        # Scale up by multiplying by powers of 10
        for _ in range(scale_diff):
            # Check for potential overflow before multiplying
            if result.high > 0xFFFFFFFF // 10 or (
                result.high == 0xFFFFFFFF // 10 and result.low > 0xFFFFFFFF % 10
            ):
                # Overflow would occur, cannot scale further
                break

            # Multiply by 10
            var overflow_low_to_mid: UInt64 = 0
            var overflow_mid_to_high: UInt64 = 0

            # Calculate products and overflows
            var new_low = result.low * 10
            overflow_low_to_mid = UInt64(result.low) * 10 >> 32

            var new_mid_temp = UInt64(result.mid) * 10 + overflow_low_to_mid
            var new_mid = UInt32(new_mid_temp & 0xFFFFFFFF)
            overflow_mid_to_high = new_mid_temp >> 32

            var new_high = result.high * 10 + UInt32(overflow_mid_to_high)

            # Update result
            result.low = new_low
            result.mid = new_mid
            result.high = new_high

        return result


fn _float_to_decimal_str(value: Float64, precision: Int) -> String:
    """
    Converts float to string with specified precision.
    """
    var int_part = Int64(value)
    var frac_part = value - Float64(int_part)

    # Convert integer part to string
    var result = String(int_part)

    # Handle fractional part if needed
    if frac_part > 0:
        result += "."

        # Extract decimal digits one by one
        for _ in range(precision):
            frac_part *= 10
            var digit = Int8(frac_part)
            result += String(digit)
            frac_part -= Float64(digit)

            # Stop if we've reached the end of precision
            if frac_part < 1e-17:
                break

    return result
