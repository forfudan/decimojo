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

"""Implements basic object methods for the BigInt2 type.

This module contains the basic object methods for the BigInt2 type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.

BigInt2 is the core binary-represented arbitrary-precision signed integer
for the DeciMojo library. It uses base-2^32 representation with UInt32 words
in little-endian order, and a separate sign bit.

Once BigInt2 is stable and performant, the current BigInt (base-10^9)
will be renamed to BigInt10, and BigInt2 will be renamed to BigInt.
"""

from memory import UnsafePointer, memcpy

import decimojo.bigint2.arithmetics
import decimojo.bigint2.comparison
import decimojo.bigint2.exponential
from decimojo.bigint.bigint import BigInt
from decimojo.biguint.biguint import BigUInt
from decimojo.errors import DeciMojoError

# Type aliases
comptime BInt2 = BigInt2
"""A shorter comptime for BigInt2."""


struct BigInt2(
    Absable,
    Comparable,
    Copyable,
    IntableRaising,
    Movable,
    Representable,
    Stringable,
    Writable,
):
    """Represents an arbitrary-precision binary signed integer.

    Notes:

    Internal Representation:

    Uses base-2^32 representation for the integer magnitude.
    BigInt2 uses a dynamic structure in memory, which contains:
    - A List[UInt32] of words for the magnitude stored in little-endian order.
      Each UInt32 word uses the full 32-bit range [0, 2^32 - 1].
    - A Bool for the sign (True = negative, False = non-negative).

    The absolute value is calculated as:

    |x| = words[0] + words[1] * 2^32 + words[2] * 2^64 + ... + words[n] * 2^(32n)

    The actual value is: (-1)^sign * |x|.

    This is analogous to GMP and most modern bigint libraries that use
    native-word-sized limbs with a separate sign.

    Arithmetic intermediate results use UInt64 for single products
    (UInt32 * UInt32 → UInt64) and UInt128 for accumulation, which allows
    efficient schoolbook and Karatsuba multiplication on 64-bit hardware.
    """

    var words: List[UInt32]
    """A list of UInt32 words representing the magnitude in little-endian order.
    Each word uses the full [0, 2^32 - 1] range."""

    var sign: Bool
    """True if the number is negative, False if zero or positive."""

    # ===------------------------------------------------------------------=== #
    # Constants
    # ===------------------------------------------------------------------=== #

    comptime BITS_PER_WORD = 32
    """Number of bits per word."""
    comptime BASE: UInt64 = 1 << 32  # 4294967296
    """The base used for the BigInt2 representation (2^32)."""
    comptime WORD_MAX: UInt32 = ~UInt32(0)  # 0xFFFF_FFFF = 4294967295
    """The maximum value of a single word (2^32 - 1)."""
    comptime WORD_MASK: UInt64 = (1 << 32) - 1
    """Mask to extract the lower 32 bits from a UInt64."""

    comptime ZERO = Self.zero()
    """The value 0."""
    comptime ONE = Self.one()
    """The value 1."""

    @always_inline
    @staticmethod
    fn zero() -> Self:
        """Returns a BigInt2 with value 0."""
        return Self()

    @always_inline
    @staticmethod
    fn one() -> Self:
        """Returns a BigInt2 with value 1."""
        return Self(raw_words=[UInt32(1)], sign=False)

    @always_inline
    @staticmethod
    fn negative_one() -> Self:
        """Returns a BigInt2 with value -1."""
        return Self(raw_words=[UInt32(1)], sign=True)

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigInt2 with value 0."""
        self.words = [UInt32(0)]
        self.sign = False

    fn __init__(out self, *, uninitialized_capacity: Int):
        """Creates an uninitialized BigInt2 with a given word capacity.
        The words list is empty; caller must append words before use.

        Args:
            uninitialized_capacity: The initial capacity for the words list.
        """
        self.words = List[UInt32](capacity=uninitialized_capacity)
        self.sign = False

    fn __init__(out self, *, var raw_words: List[UInt32], sign: Bool):
        """Initializes a BigInt2 from a list of raw words without
        validation. The caller must ensure words are in valid little-endian
        form with no unnecessary leading zeros.

        Args:
            raw_words: A list of UInt32 words in little-endian order.
            sign: True if negative, False if non-negative.

        Notes:
            **UNSAFE**: Does not strip leading zeros or check for -0.
            Always ensures at least one word exists.
        """
        if len(raw_words) == 0:
            self.words = [UInt32(0)]
            self.sign = False
        else:
            self.words = raw_words^
            self.sign = sign

    @implicit
    fn __init__(out self, value: Int):
        """Initializes a BigInt2 from an Int.

        Args:
            value: The integer value.
        """
        self = Self.from_int(value)

    fn __init__(out self, value: String) raises:
        """Initializes a BigInt2 from a decimal string representation.

        Args:
            value: The string representation of the integer.
        """
        self = Self.from_string(value)

    @implicit
    fn __init__(out self, value: Scalar):
        """Constructs a BigInt2 from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype of the scalar must be integral.
        """
        self = Self.from_integral_scalar(value)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_int(value: Int) -> Self:
        """Creates a BigInt2 from a Mojo Int.

        Args:
            value: The integer value.

        Returns:
            The BigInt2 representation.
        """
        if value == 0:
            return Self()

        var sign: Bool
        var magnitude: UInt

        if value < 0:
            sign = True
            # Handle Int.MIN (two's complement asymmetry)
            if value == Int.MIN:
                # |Int.MIN| = Int.MAX + 1
                magnitude = UInt(Int.MAX) + 1
            else:
                magnitude = UInt(-value)
        else:
            sign = False
            magnitude = UInt(value)

        # Split the magnitude into 32-bit words
        # On 64-bit platforms, Int is 64 bits → at most 2 words
        var words = List[UInt32](capacity=2)
        while magnitude != 0:
            words.append(UInt32(magnitude & 0xFFFF_FFFF))
            magnitude >>= 32

        return Self(raw_words=words^, sign=sign)

    @staticmethod
    fn from_uint64(value: UInt64) -> Self:
        """Creates a BigInt2 from a UInt64.

        Args:
            value: The unsigned 64-bit integer value.

        Returns:
            The BigInt2 representation.
        """
        if value == 0:
            return Self()

        var words = List[UInt32](capacity=2)
        var lo = UInt32(value & 0xFFFF_FFFF)
        var hi = UInt32(value >> 32)
        words.append(lo)
        if hi != 0:
            words.append(hi)

        return Self(raw_words=words^, sign=False)

    @staticmethod
    fn from_uint128(value: UInt128) -> Self:
        """Creates a BigInt2 from a UInt128.

        Args:
            value: The unsigned 128-bit integer value.

        Returns:
            The BigInt2 representation.
        """
        if value == 0:
            return Self()

        var words = List[UInt32](capacity=4)
        var remaining = value
        while remaining != 0:
            words.append(UInt32(remaining & 0xFFFF_FFFF))
            remaining >>= 32

        return Self(raw_words=words^, sign=False)

    @staticmethod
    fn from_integral_scalar[dtype: DType, //](value: SIMD[dtype, 1]) -> Self:
        """Initializes a BigInt2 from an integral scalar.
        This includes all SIMD integral types, such as Int8, Int16, UInt32, etc.

        Constraints:
            The dtype must be integral.

        Args:
            value: The Scalar value to be converted to BigInt2.

        Returns:
            The BigInt2 representation of the Scalar value.
        """

        constrained[dtype.is_integral(), "dtype must be integral."]()

        if value == 0:
            return Self()

        var sign: Bool
        var magnitude: UInt64

        @parameter
        if dtype.is_unsigned():
            sign = False
            magnitude = UInt64(value)
        else:
            if value < 0:
                sign = True
                # Handle minimum values by converting through Int
                magnitude = UInt64(-Int64(value))
            else:
                sign = False
                magnitude = UInt64(value)

        var words = List[UInt32](capacity=2)
        var lo = UInt32(magnitude & 0xFFFF_FFFF)
        var hi = UInt32(magnitude >> 32)
        words.append(lo)
        if hi != 0:
            words.append(hi)

        return Self(raw_words=words^, sign=sign)

    @staticmethod
    fn from_string(value: String) raises -> Self:
        """Creates a BigInt2 from a decimal string representation.
        Supports optional leading '-' or '+' sign.

        Args:
            value: The decimal string (e.g. "12345", "-98765").

        Returns:
            The BigInt2 representation.

        Raises:
            Error: If the string is empty or contains non-digit characters.
        """
        var s = value.strip()
        var bytes = s.as_bytes()
        var n = len(bytes)

        if n == 0:
            raise Error("BigInt2.from_string(): Empty string")

        var sign = False
        var start = 0
        # Check for sign character: '-' = 45, '+' = 43
        if bytes[0] == 45:  # '-'
            sign = True
            start = 1
        elif bytes[0] == 43:  # '+'
            start = 1

        if start >= n:
            raise Error("BigInt2.from_string(): No digits after sign")

        # Skip leading zeros (48 = '0')
        while start < n - 1 and bytes[start] == 48:
            start += 1

        # Check for zero
        if start == n - 1 and bytes[start] == 48:
            return Self()

        # Parse the decimal string by processing groups of 9 digits at a time,
        # building up the binary representation using multiply-and-add.
        # This converts from base-10 to base-2^32.
        #
        # Algorithm: for each decimal digit d, result = result * 10 + d
        # We process 9 digits at a time: result = result * 10^9 + (9-digit chunk)
        var result = Self()
        var i = start
        while i < n:
            # Determine chunk size (up to 9 digits)
            var chunk_size = min(9, n - i)

            # Parse the chunk to an integer from byte codes
            var chunk_val: UInt32 = 0
            for j in range(chunk_size):
                var code = bytes[i + j]
                if code < 48 or code > 57:  # '0' = 48, '9' = 57
                    raise Error("BigInt2.from_string(): Invalid character")
                chunk_val = chunk_val * 10 + UInt32(code - 48)

            # Compute the multiplier: 10^chunk_size
            var multiplier: UInt32 = 1
            for _ in range(chunk_size):
                multiplier *= 10

            # result = result * multiplier + chunk_val
            _multiply_inplace_by_uint32(result, multiplier)
            _add_inplace_by_uint32(result, chunk_val)

            i += chunk_size

        result.sign = sign
        return result^

    @staticmethod
    fn from_bigint(value: BigInt) -> Self:
        """Converts a base-10^9 BigInt to a base-2^32 BigInt2.

        Args:
            value: The BigInt (base-10^9) to convert.

        Returns:
            The BigInt2 (base-2^32) representation.
        """
        if value.is_zero():
            return Self()

        # Convert from base 10^9 to base 2^32 using repeated division
        # Work on the magnitude words (base-10^9)
        var div_words = List[UInt32](capacity=len(value.magnitude.words))
        for word in value.magnitude.words:
            div_words.append(word)
        var result = Self(uninitialized_capacity=len(value.magnitude.words))

        var all_zero = False
        while not all_zero:
            var remainder: UInt64 = 0
            for i in range(len(div_words) - 1, -1, -1):
                var temp = remainder * UInt64(BigUInt.BASE) + UInt64(
                    div_words[i]
                )
                div_words[i] = UInt32(temp >> 32)
                remainder = temp & 0xFFFF_FFFF

            # Remove leading zeros from dividend
            while len(div_words) > 1 and div_words[-1] == 0:
                div_words.shrink(len(div_words) - 1)

            result.words.append(UInt32(remainder))

            # Check if dividend is zero
            all_zero = True
            for word in div_words:
                if word != 0:
                    all_zero = False
                    break

        result.sign = value.sign
        return result^

    # ===------------------------------------------------------------------=== #
    # Output dunders, type-transfer dunders
    # ===------------------------------------------------------------------=== #

    fn __int__(self) raises -> Int:
        """Returns the number as Int.
        See `to_int()` for more information.
        """
        return self.to_int()

    fn __str__(self) -> String:
        """Returns a decimal string representation of the BigInt2."""
        return self.to_decimal_string()

    fn __repr__(self) -> String:
        """Returns a debug representation of the BigInt2."""
        return 'BigInt2("' + self.to_decimal_string() + '")'

    fn write_to[W: Writer](self, mut writer: W):
        """Writes the decimal string representation to a writer."""
        writer.write(self.to_decimal_string())

    # ===------------------------------------------------------------------=== #
    # Type-transfer or output methods that are not dunders
    # ===------------------------------------------------------------------=== #

    fn to_int(self) raises -> Int:
        """Returns the number as Int.

        Returns:
            The number as Int.

        Raises:
            Error: If the number is too large or too small to fit in Int.
        """
        # Int is 64-bit, so we need at most 2 words to represent it.
        # Int.MAX = 9_223_372_036_854_775_807 = 0x7FFF_FFFF_FFFF_FFFF
        if len(self.words) > 2:
            raise Error("BigInt2.to_int(): The number exceeds the size of Int")

        var magnitude: UInt64 = UInt64(self.words[0])
        if len(self.words) == 2:
            magnitude += UInt64(self.words[1]) << 32

        if self.sign:
            # Negative: check against Int.MIN magnitude (2^63)
            if magnitude > UInt64(9_223_372_036_854_775_808):
                raise Error(
                    "BigInt2.to_int(): The number exceeds the size of Int"
                )
            if magnitude == UInt64(9_223_372_036_854_775_808):
                return Int.MIN
            return -Int(magnitude)
        else:
            # Positive: check against Int.MAX (2^63 - 1)
            if magnitude > UInt64(9_223_372_036_854_775_807):
                raise Error(
                    "BigInt2.to_int(): The number exceeds the size of Int"
                )
            return Int(magnitude)

    fn to_bigint(self) -> BigInt:
        """Converts the BigInt2 to a base-10^9 BigInt.

        Returns:
            The BigInt (base-10^9) representation with the same value.
        """
        if self.is_zero():
            return BigInt()

        # Convert from base 2^32 to base 10^9 using repeated division
        var dividend = self.copy()
        var decimal_words = List[UInt32]()

        while not dividend.is_zero():
            var remainder: UInt64 = 0
            for i in range(len(dividend.words) - 1, -1, -1):
                var temp = (remainder << 32) + UInt64(dividend.words[i])
                dividend.words[i] = UInt32(temp // BigUInt.BASE)
                remainder = temp % BigUInt.BASE

            # Remove leading zeros from dividend
            while len(dividend.words) > 1 and dividend.words[-1] == 0:
                dividend.words.shrink(len(dividend.words) - 1)

            decimal_words.append(UInt32(remainder))

        return BigInt(raw_words=decimal_words^, sign=self.sign)

    fn to_decimal_string(self, line_width: Int = 0) -> String:
        """Returns the decimal string representation of the BigInt2.

        Converts to BigInt (base-10^9) and leverages its string formatting.

        Args:
            line_width: The maximum line width for the string representation.
                Default is 0, which means no line width limit.

        Returns:
            The decimal string (e.g. "-12345").
        """
        var result = String(self.to_bigint())

        if line_width > 0:
            var start = 0
            var end = line_width
            var lines = List[String](capacity=len(result) // line_width + 1)
            while end < len(result):
                lines.append(String(result[start:end]))
                start = end
                end += line_width
            lines.append(String(result[start:]))
            result = String("\n").join(lines^)

        return result^

    fn to_string_with_separators(self, separator: String = "_") -> String:
        """Returns string representation of the BigInt2 with separators.

        Args:
            separator: The separator string. Default is "_".

        Returns:
            The string representation of the BigInt2 with separators.
        """

        var result = self.to_decimal_string()
        var start_idx = 0
        if self.sign:
            start_idx = 1  # Skip the minus sign

        var digits_part = String(result[start_idx:])
        var end = len(digits_part)
        var start = end - 3
        var blocks = List[String](capacity=len(digits_part) // 3 + 1)
        while start > 0:
            blocks.append(String(digits_part[start:end]))
            end = start
            start = end - 3
        blocks.append(String(digits_part[0:end]))
        blocks.reverse()
        var formatted = separator.join(blocks)

        if self.sign:
            return String("-") + formatted
        return formatted^

    fn to_hex_string(self) -> String:
        """Returns a hexadecimal string representation of the BigInt2.

        Returns:
            The hexadecimal string (e.g. "0x1A2B3C").
        """
        if self.is_zero():
            return "0x0"

        var result = String()
        if self.sign:
            result += "-"
        result += "0x"

        var first_word = True
        for i in range(len(self.words) - 1, -1, -1):
            var word = self.words[i]
            if first_word:
                if word != 0:
                    result += hex(word)[2:]
                    first_word = False
            else:
                var h = hex(word)[2:]
                for _ in range(8 - len(h)):
                    result += "0"
                result += h

        if first_word:
            result += "0"

        return result

    fn to_binary_string(self) -> String:
        """Returns a binary string representation of the BigInt2.

        Returns:
            The binary string (e.g. "0b110101").
        """
        if self.is_zero():
            return "0b0"

        var result = String()
        if self.sign:
            result += "-"
        result += "0b"

        var first_word = True
        for i in range(len(self.words) - 1, -1, -1):
            var word = self.words[i]
            if first_word:
                if word != 0:
                    result += bin(word)[2:]
                    first_word = False
            else:
                var b = bin(word)[2:]
                for _ in range(32 - len(b)):
                    result += "0"
                result += b

        if first_word:
            result += "0"

        return result

    # ===------------------------------------------------------------------=== #
    # Unary arithmetic dunders
    # ===------------------------------------------------------------------=== #

    fn __neg__(self) -> Self:
        """Returns the negation of the BigInt2."""
        if self.is_zero():
            return Self()
        return Self(raw_words=self.words.copy(), sign=not self.sign)

    fn __abs__(self) -> Self:
        """Returns the absolute value of the BigInt2."""
        return Self(raw_words=self.words.copy(), sign=False)

    # ===------------------------------------------------------------------=== #
    # Basic binary arithmetic operation dunders
    # These methods are called to implement the binary arithmetic operations
    # (+, -, *, @, /, //, %, divmod(), pow(), **, <<, >>, &, ^, |)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __add__(self, other: Self) -> Self:
        return decimojo.bigint2.arithmetics.add(self, other)

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        return decimojo.bigint2.arithmetics.subtract(self, other)

    @always_inline
    fn __mul__(self, other: Self) -> Self:
        return decimojo.bigint2.arithmetics.multiply(self, other)

    @always_inline
    fn __floordiv__(self, other: Self) raises -> Self:
        try:
            return decimojo.bigint2.arithmetics.floor_divide(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    message=None,
                    function="BigInt2.__floordiv__()",
                    file="src/decimojo/bigint2/bigint2.mojo",
                    previous_error=e^,
                )
            )

    @always_inline
    fn __mod__(self, other: Self) raises -> Self:
        try:
            return decimojo.bigint2.arithmetics.floor_modulo(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    message=None,
                    function="BigInt2.__mod__()",
                    file="src/decimojo/bigint2/bigint2.mojo",
                    previous_error=e^,
                )
            )

    @always_inline
    fn __divmod__(self, other: Self) raises -> Tuple[Self, Self]:
        try:
            return decimojo.bigint2.arithmetics.floor_divmod(self, other)
        except e:
            raise Error(
                DeciMojoError(
                    message=None,
                    function="BigInt2.__divmod__()",
                    file="src/decimojo/bigint2/bigint2.mojo",
                    previous_error=e^,
                )
            )

    @always_inline
    fn __pow__(self, exponent: Self) raises -> Self:
        return self.power(exponent)

    @always_inline
    fn __pow__(self, exponent: Int) raises -> Self:
        return self.power(exponent)

    @always_inline
    fn __lshift__(self, shift: Int) -> Self:
        """Returns self << shift (multiply by 2^shift)."""
        return decimojo.bigint2.arithmetics.left_shift(self, shift)

    @always_inline
    fn __rshift__(self, shift: Int) -> Self:
        """Returns self >> shift (floor divide by 2^shift)."""
        return decimojo.bigint2.arithmetics.right_shift(self, shift)

    # ===------------------------------------------------------------------=== #
    # Basic binary right-side arithmetic operation dunders
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __radd__(self, other: Self) -> Self:
        return decimojo.bigint2.arithmetics.add(self, other)

    @always_inline
    fn __rsub__(self, other: Self) -> Self:
        return decimojo.bigint2.arithmetics.subtract(other, self)

    @always_inline
    fn __rmul__(self, other: Self) -> Self:
        return decimojo.bigint2.arithmetics.multiply(self, other)

    @always_inline
    fn __rfloordiv__(self, other: Self) raises -> Self:
        return decimojo.bigint2.arithmetics.floor_divide(other, self)

    @always_inline
    fn __rmod__(self, other: Self) raises -> Self:
        return decimojo.bigint2.arithmetics.floor_modulo(other, self)

    @always_inline
    fn __rdivmod__(self, other: Self) raises -> Tuple[Self, Self]:
        return decimojo.bigint2.arithmetics.floor_divmod(other, self)

    @always_inline
    fn __rpow__(self, base: Self) raises -> Self:
        return base.power(self)

    # ===------------------------------------------------------------------=== #
    # Basic binary augmented arithmetic assignments dunders
    # (+=, -=, *=, //=, %=)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __iadd__(mut self, other: Self):
        self = decimojo.bigint2.arithmetics.add(self, other)

    @always_inline
    fn __iadd__(mut self, other: Int):
        """Optimized in-place addition with Int."""
        self = decimojo.bigint2.arithmetics.add(self, Self.from_int(other))

    @always_inline
    fn __isub__(mut self, other: Self):
        self = decimojo.bigint2.arithmetics.subtract(self, other)

    @always_inline
    fn __imul__(mut self, other: Self):
        self = decimojo.bigint2.arithmetics.multiply(self, other)

    @always_inline
    fn __ifloordiv__(mut self, other: Self) raises:
        self = decimojo.bigint2.arithmetics.floor_divide(self, other)

    @always_inline
    fn __imod__(mut self, other: Self) raises:
        self = decimojo.bigint2.arithmetics.floor_modulo(self, other)

    @always_inline
    fn __ilshift__(mut self, shift: Int):
        self = decimojo.bigint2.arithmetics.left_shift(self, shift)

    @always_inline
    fn __irshift__(mut self, shift: Int):
        self = decimojo.bigint2.arithmetics.right_shift(self, shift)

    # ===------------------------------------------------------------------=== #
    # Basic binary comparison operation dunders
    # __gt__, __ge__, __lt__, __le__, __eq__, __ne__
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn __gt__(self, other: Self) -> Bool:
        """Returns True if self > other."""
        return decimojo.bigint2.comparison.greater(self, other)

    @always_inline
    fn __gt__(self, other: Int) -> Bool:
        """Returns True if self > other."""
        return decimojo.bigint2.comparison.greater(self, Self.from_int(other))

    @always_inline
    fn __ge__(self, other: Self) -> Bool:
        """Returns True if self >= other."""
        return decimojo.bigint2.comparison.greater_equal(self, other)

    @always_inline
    fn __ge__(self, other: Int) -> Bool:
        """Returns True if self >= other."""
        return decimojo.bigint2.comparison.greater_equal(
            self, Self.from_int(other)
        )

    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        """Returns True if self < other."""
        return decimojo.bigint2.comparison.less(self, other)

    @always_inline
    fn __lt__(self, other: Int) -> Bool:
        """Returns True if self < other."""
        return decimojo.bigint2.comparison.less(self, Self.from_int(other))

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        """Returns True if self <= other."""
        return decimojo.bigint2.comparison.less_equal(self, other)

    @always_inline
    fn __le__(self, other: Int) -> Bool:
        """Returns True if self <= other."""
        return decimojo.bigint2.comparison.less_equal(
            self, Self.from_int(other)
        )

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self == other."""
        return decimojo.bigint2.comparison.equal(self, other)

    @always_inline
    fn __eq__(self, other: Int) -> Bool:
        """Returns True if self == other."""
        return decimojo.bigint2.comparison.equal(self, Self.from_int(other))

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Returns True if self != other."""
        return decimojo.bigint2.comparison.not_equal(self, other)

    @always_inline
    fn __ne__(self, other: Int) -> Bool:
        """Returns True if self != other."""
        return decimojo.bigint2.comparison.not_equal(self, Self.from_int(other))

    # ===------------------------------------------------------------------=== #
    # Mathematical methods that do not implement a trait (not a dunder)
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn truncate_divide(self, other: Self) raises -> Self:
        """Performs a truncated division of two BigInt2 numbers.
        See `truncate_divide()` for more information.
        """
        return decimojo.bigint2.arithmetics.truncate_divide(self, other)

    @always_inline
    fn floor_modulo(self, other: Self) raises -> Self:
        """Performs a floor modulo of two BigInt2 numbers.
        See `floor_modulo()` for more information.
        """
        return decimojo.bigint2.arithmetics.floor_modulo(self, other)

    @always_inline
    fn truncate_modulo(self, other: Self) raises -> Self:
        """Performs a truncated modulo of two BigInt2 numbers.
        See `truncate_modulo()` for more information.
        """
        return decimojo.bigint2.arithmetics.truncate_modulo(self, other)

    fn power(self, exponent: Int) raises -> Self:
        """Raises the BigInt2 to the power of an integer exponent.

        Args:
            exponent: The non-negative exponent.

        Returns:
            The result of self raised to the given exponent.

        Raises:
            Error: If the exponent is negative.
        """
        return decimojo.bigint2.arithmetics.power(self, exponent)

    fn power(self, exponent: Self) raises -> Self:
        """Raises the BigInt2 to the power of another BigInt2.

        Args:
            exponent: The exponent (must be non-negative and fit in Int).

        Returns:
            The result of self raised to the given exponent.

        Raises:
            Error: If the exponent is negative or too large.
        """
        if exponent.is_negative():
            raise Error("BigInt2.power(): Exponent must be non-negative")
        var exp_int = exponent.to_int()
        return self.power(exp_int)

    fn sqrt(self) raises -> Self:
        """Returns the integer square root of this BigInt2.

        The result is the largest integer y such that y * y <= |self|.
        Only defined for non-negative values.

        Returns:
            The integer square root.

        Raises:
            Error: If the value is negative.
        """
        return decimojo.bigint2.exponential.sqrt(self)

    fn isqrt(self) raises -> Self:
        """Returns the integer square root of this BigInt2.
        It is equal to `sqrt()`.

        Returns:
            The integer square root.

        Raises:
            Error: If the value is negative.
        """
        return decimojo.bigint2.exponential.sqrt(self)

    @always_inline
    fn compare_magnitudes(self, other: Self) -> Int8:
        """Compares the magnitudes (absolute values) of two BigInt2 numbers.
        See `compare_magnitudes()` for more information.
        """
        return decimojo.bigint2.comparison.compare_magnitudes(self, other)

    @always_inline
    fn compare(self, other: Self) -> Int8:
        """Compares two BigInt2 numbers.
        See `compare()` for more information.
        """
        return decimojo.bigint2.comparison.compare(self, other)

    # ===------------------------------------------------------------------=== #
    # Bitwise operations — implemented via __lshift__/__rshift__ dunders above.
    # Full bitwise AND/OR/XOR/NOT are planned for a future phase.
    # ===------------------------------------------------------------------=== #

    # TODO: Phase 4 — Implement in bitwise.mojo
    # fn __and__(self, other: Self) -> Self
    # fn __or__(self, other: Self) -> Self
    # fn __xor__(self, other: Self) -> Self
    # fn __invert__(self) -> Self

    # ===------------------------------------------------------------------=== #
    # Instance query methods
    # ===------------------------------------------------------------------=== #

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns True if the value is zero."""
        if len(self.words) == 1 and self.words[0] == 0:
            return True
        for word in self.words:
            if word != 0:
                return False
        return True

    @always_inline
    fn is_negative(self) -> Bool:
        """Returns True if the value is strictly negative."""
        return self.sign and not self.is_zero()

    @always_inline
    fn is_positive(self) -> Bool:
        """Returns True if the value is strictly positive."""
        return not self.sign and not self.is_zero()

    fn is_one(self) -> Bool:
        """Returns True if the value is exactly 1."""
        return not self.sign and len(self.words) == 1 and self.words[0] == 1

    fn is_one_or_minus_one(self) -> Bool:
        """Returns True if the value is 1 or -1."""
        return len(self.words) == 1 and self.words[0] == 1

    fn bit_length(self) -> Int:
        """Returns the number of bits needed to represent the magnitude,
        excluding leading zeros.

        Returns:
            The position of the highest set bit, or 0 if the value is zero.
        """
        if self.is_zero():
            return 0

        var n_words = len(self.words)
        var msw = self.words[n_words - 1]

        # Count bits in the most significant word
        var bits_in_msw = 32
        var probe: UInt32 = 1 << 31
        while probe != 0 and (msw & probe) == 0:
            bits_in_msw -= 1
            probe >>= 1

        return (n_words - 1) * 32 + bits_in_msw

    fn number_of_words(self) -> Int:
        """Returns the number of words in the magnitude."""
        return len(self.words)

    fn number_of_digits(self) -> Int:
        """Returns the number of decimal digits in the magnitude.

        Notes:
            Zero has 1 digit.
        """
        if self.is_zero():
            return 1

        # Convert to BigInt and use its digit counting
        return self.to_bigint().magnitude.number_of_digits()

    # ===------------------------------------------------------------------=== #
    # Internal utility methods
    # ===------------------------------------------------------------------=== #

    fn copy(self) -> Self:
        """Returns a deep copy of this BigInt2."""
        var new_words = List[UInt32](capacity=len(self.words))
        for word in self.words:
            new_words.append(word)
        return Self(raw_words=new_words^, sign=self.sign)

    fn _normalize(mut self):
        """Strips leading zero words and normalizes -0 to +0."""
        while len(self.words) > 1 and self.words[-1] == 0:
            self.words.shrink(len(self.words) - 1)

        # Normalize -0 to +0
        if self.is_zero():
            self.sign = False

    fn print_internal_representation(self):
        """Prints the internal representation details."""
        print("\nInternal Representation Details of BigInt2")
        print("------------------------------------------------")
        print("decimal:        " + self.to_decimal_string())
        print("hex:            " + self.to_hex_string())
        print(
            "sign:           "
            + String("negative" if self.sign else "non-negative")
        )
        print("words:          " + String(len(self.words)))
        for i in range(len(self.words)):
            var ndigits = 1
            if i >= 100:
                ndigits = 3
            elif i >= 10:
                ndigits = 2
            print(
                "  word ",
                i,
                ":",
                " " * (6 - ndigits),
                "0x",
                hex(self.words[i])[2:].rjust(8, fillchar="0"),
                "  (",
                self.words[i],
                ")",
                sep="",
            )
        print("------------------------------------------------")


# ===----------------------------------------------------------------------=== #
# Module-level private helpers for from_string
# These operate on the magnitude words only (sign is handled by caller).
# ===----------------------------------------------------------------------=== #


fn _multiply_inplace_by_uint32(mut x: BigInt2, y: UInt32):
    """Multiplies a BigInt2 magnitude by a UInt32 scalar in-place.

    This is used internally by from_string() during base conversion.

    Args:
        x: The BigInt2 to multiply (modified in-place).
        y: The UInt32 scalar multiplier.
    """
    if y == 0:
        x.words = [UInt32(0)]
        x.sign = False
        return
    if y == 1:
        return

    var carry: UInt64 = 0
    for i in range(len(x.words)):
        var product = UInt64(x.words[i]) * UInt64(y) + carry
        x.words[i] = UInt32(product & 0xFFFF_FFFF)
        carry = product >> 32

    if carry > 0:
        x.words.append(UInt32(carry))


fn _add_inplace_by_uint32(mut x: BigInt2, y: UInt32):
    """Adds a UInt32 value to a BigInt2 magnitude in-place.

    This is used internally by from_string() during base conversion.

    Args:
        x: The BigInt2 to add to (modified in-place).
        y: The UInt32 value to add.
    """
    if y == 0:
        return

    var carry: UInt64 = UInt64(y)
    for i in range(len(x.words)):
        if carry == 0:
            break
        var sum = UInt64(x.words[i]) + carry
        x.words[i] = UInt32(sum & 0xFFFF_FFFF)
        carry = sum >> 32

    if carry > 0:
        x.words.append(UInt32(carry))
