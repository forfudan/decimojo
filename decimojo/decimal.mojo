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
    Each decimal uses a 256-bit on memory, where (for right-to-left):
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

                # Multiply existing coefficient by 10 and add new digit
                # Handling potential overflow across all three 32-bit parts

                # First, multiply low by 10
                var temp_low = low * 10

                # Check for overflow from low to mid
                var overflow_low_to_mid = low > 0xFFFFFFFF // 10

                # Add the digit to low
                var new_low = temp_low + digit

                # Check if adding the digit caused additional overflow
                var digit_overflow = new_low < temp_low

                # Update mid: mid*10 + any overflow from low
                var temp_mid = mid * 10
                if overflow_low_to_mid:
                    temp_mid += 1

                # Check for overflow from mid to high
                var overflow_mid_to_high = mid > 0xFFFFFFFF // 10

                # Update mid with any digit overflow from low
                var new_mid = temp_mid
                if digit_overflow:
                    new_mid += 1

                # Check if incrementing mid caused additional overflow
                var mid_carry = new_mid < temp_mid

                # Update high: high*10 + any overflow from mid
                var new_high = high * 10
                if overflow_mid_to_high:
                    new_high += 1
                if mid_carry:
                    new_high += 1

                # Check for overflow in high part (means number is too large)
                if high > 0xFFFFFFFF // 10:
                    raise Error("Decimal value too large")

                # Update our values
                low = new_low
                mid = new_mid
                high = new_high

                # Update scale if we are after the decimal point
                if is_decimal_point:
                    scale += 1
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

        Notes:
        Since `Float64` can only represent integers exactly up to 2^53,
        the `high` field will always be 0.
        """
        var flags: UInt32 = 0
        var low: UInt32 = 0
        var mid: UInt32 = 0
        var high: UInt32 = 0
        var scale = 0

        var float_value = f
        if float_value < 0:
            flags |= Self.SIGN_MASK
            float_value = -float_value

        # Extract integral and fractional parts
        var integral_part = Int64(float_value)
        var fractional_part = float_value - Float64(integral_part)

        # Handle integral part
        # Float64 can only represent integers exactly up to 2^53
        # it cannot accurately represent values that need the high 32 bits
        # Thus, the high 32 bits is set to 0
        low = UInt32(integral_part & 0xFFFFFFFF)
        mid = UInt32((integral_part >> 32) & 0xFFFFFFFF)
        high = 0

        # Process fractional part
        while (fractional_part > 1e-10) and (scale < Self.MAX_PRECISION):
            fractional_part = fractional_part * 10
            integral_part = Int64(fractional_part)
            fractional_part -= Float64(integral_part)

            # Calculate if multiplying by 10 would overflow
            var overflow = (0xFFFFFFFF - UInt32(integral_part)) / 10 < low

            # Multiply low by 10 and add the new digit
            low = low * 10 + UInt32(integral_part)

            # Handle overflow
            if overflow:
                # Increment mid, checking for overflow to high
                mid += 1
                if mid == 0:  # Mid overflowed
                    high += 1
                    if high == 0:  # High overflowed
                        raise Error("Decimal value too large")

            scale += 1

        # Set the flags
        flags |= UInt32((scale << Self.SCALE_SHIFT) & Self.SCALE_MASK)

        self = Decimal(low, mid, high, flags)

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

        var coef = self.coefficient()
        var scale = self.scale()
        var is_neg = self.is_negative()

        # Start with the coefficient
        var result = coef

        # Insert decimal point if needed
        if scale > 0:
            var len_result = len(result)
            if len_result <= scale:
                # Need to pad with zeros
                var padding = scale - len_result + 1
                result = "0." + "0" * (padding - 1) + result
            else:
                # Insert decimal point
                var decimal_pos = len_result - scale
                result = result[:decimal_pos] + "." + result[decimal_pos:]

        # Add negative sign if needed
        if is_neg and result != "0":
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
        """
        if self.low == 0 and self.mid == 0 and self.high == 0:
            return "0"

        # First convert high, mid, low to String separately
        var high_str = String(self.high) if self.high > 0 else ""
        var mid_str = String(self.mid)
        var low_str = String(self.low)

        # Pad with zeros where necessary
        if self.high > 0:
            # If high is non-zero, mid and low need to be exactly 10 digits (32 bits)
            if self.mid > 0:
                # Ensure mid is properly padded
                while len(mid_str) < 10:
                    mid_str = "0" + mid_str
            else:
                mid_str = "0000000000"  # 10 zeros

            # Ensure low is properly padded
            while len(low_str) < 10:
                low_str = "0" + low_str

        elif self.mid > 0:
            # Only mid and low are non-zero
            # Ensure low is properly padded
            while len(low_str) < 10:
                low_str = "0" + low_str

        # Combine the parts
        if self.high > 0:
            return high_str + mid_str + low_str
        elif self.mid > 0:
            return mid_str + low_str
        else:
            return low_str

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
            if result.high > 0xFFFFFFFF // 10:
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
