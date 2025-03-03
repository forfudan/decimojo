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

from .rounding_mode import RoundingMode


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
    var low: UInt32
    """Least significant 32 bits of coefficient."""
    var mid: UInt32
    """Middle 32 bits of coefficient."""
    var high: UInt32
    """Most significant 32 bits of coefficient."""
    var flags: UInt32
    """Scale information and the sign."""

    # Constants
    alias MAX_PRECISION = 28
    alias MAX_AS_STRING = String("79228162514264337593543950335")
    """Maximum value as a string of a 128-bit Decimal."""
    alias LEN_OF_MAX_VALUE = 29
    """Length of the max value as a string. For 128-bit Decimal, it is 29 digits"""
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
        """
        Returns a Decimal representing 0.
        """
        return Decimal(0, 0, 0, 0)

    @staticmethod
    fn ONE() -> Decimal:
        """
        Returns a Decimal representing 1.
        """
        return Decimal(1, 0, 0, 0)

    @staticmethod
    fn NEGATIVE_ONE() -> Decimal:
        """
        Returns a Decimal representing -1.
        """
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

        # STEP 2: Check for overflow
        # Check if the integral part of the coefficient is too large
        var string_of_integral_part: String
        if len(string_of_coefficient) > scale:
            string_of_integral_part = string_of_coefficient[
                : len(string_of_coefficient) - scale
            ]
        else:
            string_of_integral_part = String("0")

        if len(string_of_integral_part) > Decimal.LEN_OF_MAX_VALUE:
            raise Error("Decimal value too large: " + s)
        elif len(string_of_integral_part) == Decimal.LEN_OF_MAX_VALUE and (
            string_of_integral_part > Self.MAX_AS_STRING
        ):
            raise Error("Decimal value too large: " + s)

        # Check if the coefficient is too large
        var raw_length_of_coefficient = len(string_of_coefficient)
        if raw_length_of_coefficient > Decimal.LEN_OF_MAX_VALUE:
            # Need to truncate to Decimal.LEN_OF_MAX_VALUE digits
            var rounding_digit = string_of_coefficient[Decimal.LEN_OF_MAX_VALUE]
            string_of_coefficient = string_of_coefficient[
                : Decimal.LEN_OF_MAX_VALUE
            ]
            scale = scale - (
                raw_length_of_coefficient - Decimal.LEN_OF_MAX_VALUE
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
                    if len(result_chars) > Decimal.LEN_OF_MAX_VALUE:
                        result_chars = result_chars[: Decimal.LEN_OF_MAX_VALUE]
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
                raise Error("Decimal value too large: " + s)
        elif len(string_of_coefficient) > len(Self.MAX_AS_STRING):
            raise Error("Decimal value too large: " + s)

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

    # TODO: Use generic floating-point type.
    fn __init__(out self, f: Float64, *, max_precision: Bool = True) raises:
        """
        Initializes a Decimal from a floating-point value.
        You may lose precision because float representation is inexact.
        """
        var float_str: String

        if max_precision:
            # Use maximum precision
            # Convert float to string ith high precision to capture all significant digits
            # The format ensures we get up to MAX_PRECISION decimal places
            float_str = _float_to_decimal_str(f, Self.MAX_PRECISION)
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
        Preserves trailing zeros after decimal point to match the scale.
        """
        # Get the coefficient as a string (absolute value)
        var coef = self.coefficient()
        var scale = self.scale()

        # Handle zero as a special case
        if coef == "0":
            if scale == 0:
                return "0"
            else:
                return "0." + "0" * scale

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

            # Ensure we have exactly 'scale' digits after decimal point
            var decimal_point_pos = result.find(".")
            var current_decimals = len(result) - decimal_point_pos - 1

            if current_decimals < scale:
                # Add trailing zeros if needed
                result += "0" * (scale - current_decimals)

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
    fn __add__(self, other: Decimal) raises -> Decimal:
        """
        Adds two Decimal values and returns a new Decimal containing the sum.
        """
        ############################################################
        # Special case for zero
        ############################################################
        if self.is_zero():
            return other
        if other.is_zero():
            return self

        ############################################################
        # Integer addition with same scale
        ############################################################
        if self.scale() == other.scale():
            var result = Decimal()
            result.flags = UInt32(
                (self.scale() << Self.SCALE_SHIFT) & Self.SCALE_MASK
            )

            # Same sign: add absolute values and keep the sign
            if self.is_negative() == other.is_negative():
                if self.is_negative():
                    result.flags |= Self.SIGN_MASK

                # Add with carry
                var carry: UInt32 = 0

                # Add low parts
                var sum_low = UInt64(self.low) + UInt64(other.low)
                result.low = UInt32(sum_low & 0xFFFFFFFF)
                carry = UInt32(sum_low >> 32)

                # Add mid parts with carry
                var sum_mid = UInt64(self.mid) + UInt64(other.mid) + UInt64(
                    carry
                )
                result.mid = UInt32(sum_mid & 0xFFFFFFFF)
                carry = UInt32(sum_mid >> 32)

                # Add high parts with carry
                var sum_high = UInt64(self.high) + UInt64(other.high) + UInt64(
                    carry
                )
                result.high = UInt32(sum_high & 0xFFFFFFFF)

                # Check for overflow
                if (sum_high >> 32) > 0:
                    raise Error("Decimal overflow in addition")

                return result

        ############################################################
        # Float addition which may be with different scales
        ############################################################

        # Determine which decimal has larger absolute value
        var larger_decimal: Decimal
        var smaller_decimal: Decimal
        var larger_scale: Int
        var smaller_scale: Int

        if self._abs_compare(other) >= 0:
            larger_decimal = self
            smaller_decimal = other
            larger_scale = self.scale()
            smaller_scale = other.scale()
        else:
            larger_decimal = other
            smaller_decimal = self
            larger_scale = other.scale()
            smaller_scale = self.scale()

        # Calculate how much we can safely scale up the larger number
        var larger_coef = larger_decimal.coefficient()
        var significant_digits = len(larger_coef)
        var max_safe_scale_increase = Self.MAX_PRECISION - significant_digits

        # If the scales are too different, we need special handling
        if smaller_scale > larger_scale + max_safe_scale_increase:
            # We need to determine the effective position where the smaller number would contribute
            var scale_diff = smaller_scale - larger_scale

            # If beyond our max safe scale, we need to round
            if scale_diff > max_safe_scale_increase:
                # Get smallest significant digit position in the smaller number
                var smaller_coef = smaller_decimal.coefficient()

                # Find first non-zero digit in the smaller number
                var first_digit_pos = 0
                for i in range(len(smaller_coef)):
                    if smaller_coef[i] != "0":
                        first_digit_pos = i
                        break

                # Calculate total effective position
                var effective_pos = scale_diff + first_digit_pos

                # If still beyond max safe scale, determine if rounding is needed
                if effective_pos > max_safe_scale_increase:
                    # If way beyond precision limit, just return the larger number
                    if effective_pos > max_safe_scale_increase + 1:
                        return larger_decimal

                    # If exactly at rounding boundary, use first digit to determine rounding
                    var first_digit = ord(smaller_coef[first_digit_pos]) - ord(
                        "0"
                    )

                    # Round up if 5 or greater (using half-up rounding)
                    if first_digit >= 5:
                        # Create a small decimal for rounding adjustment
                        var round_value = Decimal(
                            "0." + "0" * max_safe_scale_increase + "1"
                        )

                        # Apply rounding based on signs
                        if (
                            smaller_decimal.is_negative()
                            != larger_decimal.is_negative()
                        ):
                            return larger_decimal + -round_value
                        else:
                            return larger_decimal + round_value
                    else:
                        # Round down - just return larger number
                        return larger_decimal

                # If we get here, we can align to max safe scale
                var safe_scale = larger_scale + max_safe_scale_increase
                var scale_reduction = smaller_scale - safe_scale
                smaller_decimal = smaller_decimal._scale_down(
                    scale_reduction, RoundingMode.HALF_EVEN()
                )

        # Standard addition with aligned scales
        var result = Decimal()
        var target_scale = max(larger_scale, smaller_decimal.scale())

        # Scale up if needed
        var larger_copy = larger_decimal
        var smaller_copy = smaller_decimal

        if larger_scale < target_scale:
            larger_copy = larger_decimal._scale_up(target_scale - larger_scale)
        if smaller_decimal.scale() < target_scale:
            smaller_copy = smaller_decimal._scale_up(
                target_scale - smaller_decimal.scale()
            )

        # Set result scale
        result.flags = UInt32(
            (target_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        )

        # Now perform the actual addition
        if larger_copy.is_negative() == smaller_copy.is_negative():
            # Same sign: add absolute values and keep the sign
            if larger_copy.is_negative():
                result.flags |= Self.SIGN_MASK

            # Add with carry
            var carry: UInt32 = 0

            # Add low parts
            var sum_low = UInt64(larger_copy.low) + UInt64(smaller_copy.low)
            result.low = UInt32(sum_low & 0xFFFFFFFF)
            carry = UInt32(sum_low >> 32)

            # Add mid parts with carry
            var sum_mid = UInt64(larger_copy.mid) + UInt64(
                smaller_copy.mid
            ) + UInt64(carry)
            result.mid = UInt32(sum_mid & 0xFFFFFFFF)
            carry = UInt32(sum_mid >> 32)

            # Add high parts with carry
            var sum_high = UInt64(larger_copy.high) + UInt64(
                smaller_copy.high
            ) + UInt64(carry)
            result.high = UInt32(sum_high & 0xFFFFFFFF)

            # Check for overflow
            if (sum_high >> 32) > 0:
                raise Error("Decimal overflow in addition")
        else:
            # Different signs: subtract smaller absolute value from larger
            # We already know larger_copy has larger absolute value
            var borrow: UInt32 = 0

            # Subtract low parts with borrow
            if larger_copy.low >= smaller_copy.low:
                result.low = larger_copy.low - smaller_copy.low
                borrow = 0
            else:
                result.low = UInt32(
                    0x100000000 + larger_copy.low - smaller_copy.low
                )
                borrow = 1

            # Subtract mid parts with borrow
            if larger_copy.mid >= smaller_copy.mid + borrow:
                result.mid = larger_copy.mid - smaller_copy.mid - borrow
                borrow = 0
            else:
                result.mid = UInt32(
                    0x100000000 + larger_copy.mid - smaller_copy.mid - borrow
                )
                borrow = 1

            # Subtract high parts with borrow
            result.high = larger_copy.high - smaller_copy.high - borrow

            # Set sign based on which had larger absolute value
            if larger_copy.is_negative():
                result.flags |= Self.SIGN_MASK

        return result

    fn __mul__(self, other: Decimal) raises -> Decimal:
        """
        Multiplies two Decimal values and returns a new Decimal containing the product.

        Args:
            other: The Decimal to multiply with this Decimal.

        Returns:
            A new Decimal containing the product

        Examples:
        ```
        var a = Decimal("12.34")
        var b = Decimal("5.6")
        var result = a * b  # Returns 69.104
        ```
        .
        """
        # Special cases for zero
        if self.is_zero() or other.is_zero():
            # For zero, we need to preserve the scale (sum of both scales)
            var result = Decimal.ZERO()
            var result_scale = min(
                self.scale() + other.scale(), Self.MAX_PRECISION
            )

            # Set the scale in the flags
            result.flags = UInt32(
                (result_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
            )

            return result

        # Calculate the result scale (sum of scales)
        var result_scale = self.scale() + other.scale()
        if result_scale > Self.MAX_PRECISION:
            result_scale = Self.MAX_PRECISION

        # Determine the sign of the result (XOR of signs)
        var result_is_negative = self.is_negative() != other.is_negative()

        # Extract the components for multiplication
        var a_low = UInt64(self.low)
        var a_mid = UInt64(self.mid)
        var a_high = UInt64(self.high)

        var b_low = UInt64(other.low)
        var b_mid = UInt64(other.mid)
        var b_high = UInt64(other.high)

        # Perform 96-bit by 96-bit multiplication
        # This requires 9 multiplications and carrying

        # Multiply: low x low (first 32 bits)
        var r0 = a_low * b_low

        # Multiply: low x mid
        var r1_a = a_low * b_mid

        # Multiply: mid x low
        var r1_b = a_mid * b_low

        # Multiply: low x high
        var r2_a = a_low * b_high

        # Multiply: mid x mid
        var r2_b = a_mid * b_mid

        # Multiply: high x low
        var r2_c = a_high * b_low

        # Multiply: mid x high
        var r3_a = a_mid * b_high

        # Multiply: high x mid
        var r3_b = a_high * b_mid

        # Multiply: high x high
        var r4 = a_high * b_high

        # Check if we have an overflow in the high part
        if r4 > 0:
            raise Error("Decimal overflow in multiplication")

        # Accumulate results with carries
        var c0 = r0 & 0xFFFFFFFF
        var c1 = (r0 >> 32) + (r1_a & 0xFFFFFFFF) + (r1_b & 0xFFFFFFFF)
        var c2 = (r1_a >> 32) + (r1_b >> 32) + (r2_a & 0xFFFFFFFF) + (
            r2_b & 0xFFFFFFFF
        ) + (r2_c & 0xFFFFFFFF) + (c1 >> 32)
        var c3 = (r2_a >> 32) + (r2_b >> 32) + (r2_c >> 32) + (
            r3_a & 0xFFFFFFFF
        ) + (r3_b & 0xFFFFFFFF) + (c2 >> 32)
        var c4 = (r3_a >> 32) + (r3_b >> 32) + (c3 >> 32)

        # Check for overflow in the result
        if c4 > 0:
            raise Error("Decimal overflow in multiplication")

        # Extract 32-bit parts for the result
        var result_low = UInt32(c0 & 0xFFFFFFFF)
        var result_mid = UInt32(c1 & 0xFFFFFFFF)
        var result_high = UInt32(c2 & 0xFFFFFFFF)

        # Create the result with proper scale
        var result = Decimal(result_low, result_mid, result_high, 0)

        # Set the flags for scale and sign
        result.flags = UInt32(
            (result_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        )
        if result_is_negative:
            result.flags |= Self.SIGN_MASK

        # If we have more than MAX_PRECISION decimal places, round the result
        if self.scale() + other.scale() > Self.MAX_PRECISION:
            var scale_diff = self.scale() + other.scale() - Self.MAX_PRECISION
            result = result._scale_down(scale_diff, RoundingMode.HALF_EVEN())
            # Check if the result would round to zero - both numbers are very small
            if result.coefficient() == "0" or (
                len(result.coefficient()) <= scale_diff
                and result.coefficient()[0] < "5"
            ):
                # Result will underflow to zero, set scale to MAX_PRECISION
                var zero_result = Decimal.ZERO()
                zero_result.flags = UInt32(
                    (Self.MAX_PRECISION << Self.SCALE_SHIFT) & Self.SCALE_MASK
                )
                return zero_result

            result = result._scale_down(scale_diff, RoundingMode.HALF_EVEN())

        return result

    fn __neg__(self) -> Decimal:
        """Unary negation operator."""
        var result = Decimal(self.low, self.mid, self.high, self.flags)
        result.flags ^= Self.SIGN_MASK  # Flip sign bit
        return result

    fn __sub__(self, other: Decimal) raises -> Decimal:
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
        # Implementation using the existing `__add__()` and `__neg__()` methods
        return self + (-other)

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

    fn is_zero(self) -> Bool:
        """
        Returns True if this Decimal represents zero.
        A decimal is zero when all coefficient parts (low, mid, high) are zero,
        regardless of its sign or scale.
        """
        return self.low == 0 and self.mid == 0 and self.high == 0

    fn scale(self) -> Int:
        """Returns the scale (number of decimal places) of this Decimal."""
        return Int((self.flags & Self.SCALE_MASK) >> Self.SCALE_SHIFT)

    fn round(
        self,
        decimal_places: Int,
        rounding_mode: RoundingMode = RoundingMode.HALF_EVEN(),
    ) -> Decimal:
        """
        Rounds the Decimal to the specified number of decimal places.

        Args:
            decimal_places: Number of decimal places to round to.
            rounding_mode: Rounding mode to use (defaults to HALF_EVEN/banker's rounding).

        Returns:
            A new Decimal rounded to the specified number of decimal places

        Examples:
        ```
        var d = Decimal("123.456789")
        var rounded = d.round(2)  # Returns 123.46 (using banker's rounding)
        var down = d.round(3, RoundingMode.DOWN())  # Returns 123.456 (truncated)
        var up = d.round(1, RoundingMode.UP())  # Returns 123.5 (rounded up)
        ```
        .
        """
        var current_scale = self.scale()

        # If already at the desired scale, return a copy
        if current_scale == decimal_places:
            return self

        # If we need more decimal places, scale up
        if decimal_places > current_scale:
            return self._scale_up(decimal_places - current_scale)

        # Otherwise, scale down with the specified rounding mode
        return self._scale_down(current_scale - decimal_places, rounding_mode)

    # ===------------------------------------------------------------------=== #
    # Internal methods
    # ===------------------------------------------------------------------=== #

    fn _abs_compare(self, other: Decimal) -> Int:
        """
        Compares absolute values of two Decimal numbers, ignoring signs.

        Returns:
        - Positive value if |self| > |other|
        - Zero if |self| = |other|
        - Negative value if |self| < |other|
        """
        # Create temporary copies with same scale for comparison
        var self_copy = self
        var other_copy = other

        # Get scales
        var self_scale = self.scale()
        var other_scale = other.scale()

        # Scale up the one with smaller scale to match
        if self_scale < other_scale:
            self_copy = self_copy._scale_up(other_scale - self_scale)
        elif other_scale < self_scale:
            other_copy = other_copy._scale_up(self_scale - other_scale)

        # Now both have the same scale, compare coefficients
        # Start with highest significance (high)
        if self_copy.high > other_copy.high:
            return 1
        if self_copy.high < other_copy.high:
            return -1

        # High parts equal, compare mid parts
        if self_copy.mid > other_copy.mid:
            return 1
        if self_copy.mid < other_copy.mid:
            return -1

        # Mid parts equal, compare low parts
        if self_copy.low > other_copy.low:
            return 1
        if self_copy.low < other_copy.low:
            return -1

        # All parts equal, numbers are equal
        return 0

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

        # First collect all digits that will be removed for rounding decision
        var removed_digits = String("")
        var temp = result

        # Collect the digits to be removed (we need all of them for proper rounding)
        for i in range(scale_diff):
            var last_digit = temp.low % 10
            removed_digits = String(last_digit) + removed_digits

            # Divide by 10 without any rounding at this stage
            var high64 = UInt64(temp.high)
            var mid64 = UInt64(temp.mid)
            var low64 = UInt64(temp.low)

            # Divide high part and propagate remainder
            var new_high = high64 // 10
            var remainder_h = high64 % 10

            # Calculate mid with remainder from high
            var mid_with_remainder = mid64 + (remainder_h << 32)
            var new_mid = mid_with_remainder // 10
            var remainder_m = mid_with_remainder % 10

            # Calculate low with remainder from mid
            var low_with_remainder = low64 + (remainder_m << 32)
            var new_low = low_with_remainder // 10

            # Update temp values
            temp.low = UInt32(new_low)
            temp.mid = UInt32(new_mid)
            temp.high = UInt32(new_high)

        # Now we have all the digits to be removed, apply proper rounding
        var should_round_up = False

        if rounding_mode == RoundingMode.DOWN():
            # Truncate (do nothing)
            should_round_up = False
        elif rounding_mode == RoundingMode.UP():
            # Always round up if any non-zero digit was removed
            for i in range(len(removed_digits)):
                if removed_digits[i] != "0":
                    should_round_up = True
                    break
        elif rounding_mode == RoundingMode.HALF_UP():
            # Round up if first digit >= 5
            if len(removed_digits) > 0 and ord(removed_digits[0]) >= ord("5"):
                should_round_up = True
        elif rounding_mode == RoundingMode.HALF_EVEN():
            # Apply banker's rounding
            if len(removed_digits) > 0:
                var first_digit = ord(removed_digits[0]) - ord("0")
                if first_digit > 5:
                    # Round up
                    should_round_up = True
                elif first_digit == 5:
                    # For banker's rounding we need to check:
                    # 1. If there are other non-zero digits after 5, round up
                    # 2. Otherwise, round to nearest even (round up if odd)
                    var has_non_zero_after = False
                    for i in range(1, len(removed_digits)):
                        if removed_digits[i] != "0":
                            has_non_zero_after = True
                            break

                    if has_non_zero_after:
                        should_round_up = True
                    else:
                        # Round to even - check if the low digit is odd
                        should_round_up = temp.low % 2 == 1

        # Set the new scale
        result = temp
        result.flags = (self.flags & ~Self.SCALE_MASK) | (
            UInt32(new_scale << Self.SCALE_SHIFT) & Self.SCALE_MASK
        )

        # Apply rounding if needed
        if should_round_up:
            # Increment and handle carry
            var new_low = UInt64(result.low) + 1
            if new_low > 0xFFFFFFFF:
                result.low = 0
                var new_mid = UInt64(result.mid) + 1
                if new_mid > 0xFFFFFFFF:
                    result.mid = 0
                    result.high += 1
                else:
                    result.mid = UInt32(new_mid)
            else:
                result.low = UInt32(new_low)

        return result

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
    Properly handles negative values.
    """
    # Handle sign separately
    var is_negative = value < 0
    var abs_value = abs(value)

    # Extract integer and fractional parts from absolute value
    var int_part = Int64(abs_value)
    var frac_part = abs_value - Float64(int_part)

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

    # Add negative sign if needed
    if is_negative:
        result = "-" + result

    return result
