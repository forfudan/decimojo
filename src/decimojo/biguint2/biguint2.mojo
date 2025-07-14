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

"""Implements basic object methods for the binary BigUInt type.

This module contains the basic object methods for the binary BigUInt type.
These methods include constructors, life time methods, output dunders,
type-transfer dunders, basic arithmetic operation dunders, comparison
operation dunders, and other dunders that implement traits, as well as
mathematical methods that do not implement a trait.
"""

from memory import UnsafePointer, memcpy

from decimojo.biguint.biguint import BigUInt

# Type aliases
alias BUInt2 = BigUInt2


@value
struct BigUInt2:
    """Represents a arbitrary-precision binary unsigned integer.

    Notes:

    Internal Representation:

    Use base-2^30 representation for the unsigned integer.
    BigUInt2 uses a dynamic structure in memory, which contains:
    An pointer to an array of UInt32 words for the coefficient on the heap,
    which can be of arbitrary length stored in little-endian order.
    Each UInt32 word represents values ranging from 0 to 2^30 - 1.

    The value of the BigUInt2 is calculated as follows:

    x = x[0] * (2^30)^0 + x[1] * (2^30)^1 + x[2] * (2^30)^2 + ... x[n] * (2^30)^n

    You can think of the BigUInt2 as a list of base-2^30 digits, where each
    digit is ranging from 0 to 1073741823. Depending on the context, the
    following terms are used interchangeably:
    (1) words,
    (2) limbs,
    (3) base-2^30 digits.
    """

    var words: List[UInt32]
    """A list of UInt32 words representing the coefficient."""

    # ===------------------------------------------------------------------=== #
    # Constants
    # ===------------------------------------------------------------------=== #

    alias BASE = 1 << 30  # 2^30 = 1073741824
    """The base used for the BigUInt2 representation."""
    alias BASE_MAX = (1 << 30) - 1  # 2^30 - 1 = 1073741823
    """The maximum value of a single word in the BigUInt2 representation."""
    alias BASE_HALF = 1 << 29  # 2^29 = 536870912
    """Half of the base used for the BigUInt2 representation."""
    alias VECTOR_WIDTH = 4
    """The width of the SIMD vector used for arithmetic operations (128-bit)."""

    alias ZERO = Self.zero()
    alias ONE = Self.one()
    alias MAX_UINT64 = (1 << 64) - 1
    alias MAX_UINT128 = (1 << 128) - 1

    @always_inline
    @staticmethod
    fn zero() -> Self:
        """Returns a BigUInt with value 0."""
        return Self()

    @always_inline
    @staticmethod
    fn one() -> Self:
        """Returns a BigUInt with value 1."""
        return Self(words=List[UInt32](UInt32(1)))

    # ===------------------------------------------------------------------=== #
    # Constructors and life time dunder methods
    # ===------------------------------------------------------------------=== #

    fn __init__(out self):
        """Initializes a BigUInt2 with value 0."""
        self.words = List[UInt32](UInt32(0))

    fn __init__(out self, *, uninitialized_capacity: Int):
        """Creates an uninitialized BigUInt2 with a given capacity."""
        self.words = List[UInt32](capacity=uninitialized_capacity)

    fn __init__(out self, owned words: List[UInt32]):
        """Initializes a BigUInt2 from a list of UInt32 words.
        It does not verify whether the words are within the valid range.
        See `from_list()` for safer initialization.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents values ranging from 0 to 2^30 - 1.
                The words are stored in little-endian order.

        Notes:
            This method does not check whether the words are smaller than 2^30 - 1.
        """
        if len(words) == 0:
            self.words = List[UInt32](UInt32(0))
        else:
            self.words = words^

    fn __init__(out self, owned *words: UInt32):
        """Initializes a BigUInt2 from raw words without validating the words.
        See `from_words()` for safer initialization.

        Args:
            words: The UInt32 words representing the coefficient.
                Each UInt32 word represents values ranging from 0 to 2^30 - 1.
                The words are stored in little-endian order.

        Notes:
            This method does not check whether the words are smaller than 2^30 - 1.
        """
        self.words = List[UInt32](elements=words^)

    # ===------------------------------------------------------------------=== #
    # Constructing methods that are not dunders
    # ===------------------------------------------------------------------=== #

    @staticmethod
    fn from_list(owned words: List[UInt32]) raises -> Self:
        """Initializes a BigUInt2 from a list of UInt32 words safely.
        If the list is empty, the BigUInt2 is initialized with value 0.
        The words are validated to ensure they are smaller than 2^30.

        Args:
            words: A list of UInt32 words representing the coefficient.
                Each UInt32 word represents values ranging from 0 to 2^30 - 1.
                The words are stored in little-endian order.

        Returns:
            The BigUInt2 representation of the list of UInt32 words.
        """
        # Return 0 if the list is empty
        if len(words) == 0:
            return Self()

        # Check if the words are valid
        for word in words:
            if word >= Self.BASE:
                raise Error(
                    "Error in `BigUInt2.from_list()`: Word value exceeds"
                    " maximum value of 2^30 - 1"
                )

        return Self(words^)
