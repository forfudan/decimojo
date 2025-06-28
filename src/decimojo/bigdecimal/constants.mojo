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
"""
# Implements functions for calculating common constants.
"""

import math as builtin_math

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode


fn pi(precision: Int) raises -> BigDecimal:
    """Calculates the value of pi using the Gauss-Legendre algorithm.

    This algorithm converges quadratically, making it very efficient
    for high-precision calculations.

    Args:
        precision: The number of significant digits to calculate.

    Returns:
        A BigDecimal object representing the value of pi with the specified
        precision.
    """
    # Add extra precision for intermediate calculations
    alias BUFFER_DIGITS = 9
    var working_precision = precision + BUFFER_DIGITS

    # Initialize values for Gauss-Legendre algorithm
    var a = BigDecimal.from_raw_components(UInt32(1))
    var b = BigDecimal.from_raw_components(
        UInt32(1)
    ) / BigDecimal.from_raw_components(UInt32(2)).sqrt(
        precision=working_precision
    )
    var t = BigDecimal.from_raw_components(UInt32(25), scale=2)  # 1/4
    var p = BigDecimal.from_raw_components(UInt32(1))

    # Gauss-Legendre converges quadratically, so we need very few iterations
    # log2(precision) + a few extra iterations should be sufficient
    var iterations = Int(builtin_math.log2(Float64(working_precision))) + 5

    # Perform the iterations
    for _ in range(iterations):
        # Store the current value of a for later use
        var a_prev = a

        # Calculate new values
        a = (a + b).true_divide(
            BigDecimal.from_raw_components(UInt32(2)),
            precision=working_precision,
        )
        b = (a_prev * b).sqrt(precision=working_precision)
        t = t - p * (a_prev - a).power(
            BigDecimal.from_raw_components(UInt32(2)),
            precision=working_precision,
        )
        p = p * BigDecimal.from_raw_components(UInt32(2))

    # Calculate the final value of pi
    var pi_value = (
        (a + b)
        .power(
            BigDecimal.from_raw_components(UInt32(2)),
            precision=working_precision,
        )
        .true_divide(
            BigDecimal.from_raw_components(UInt32(4)) * t,
            precision=working_precision,
        )
    )

    # Return the value with the requested precision
    return pi_value.round(
        ndigits=precision - 1, rounding_mode=RoundingMode.ROUND_HALF_EVEN
    )
