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

alias PI_1024 = BigDecimal(
    coefficient=BigUInt(
        words=List[UInt32](
            858632789,
            572010654,
            989380952,
            92164201,
            766111959,
            130019278,
            712268066,
            577805321,
            519577818,
            537875937,
            628638823,
            687311595,
            904287554,
            35982534,
            776691473,
            814206171,
            875332083,
            387528865,
            100031378,
            311881710,
            850352619,
            82533446,
            26425223,
            553469083,
            950244594,
            160963185,
            597317328,
            780499510,
            999983729,
            72113499,
            99605187,
            297747713,
            181598136,
            608640344,
            121290219,
            420199561,
            892589235,
            507922796,
            495853710,
            534301465,
            409012249,
            787214684,
            91736371,
            427577896,
            277857713,
            452635608,
            5681271,
            694051320,
            748184676,
            767523846,
            171762931,
            27705392,
            798609437,
            371907021,
            463952247,
            860213949,
            406566430,
            336733624,
            119491298,
            279381830,
            527248912,
            673518857,
            799627495,
            480744623,
            931051185,
            819326117,
            921861173,
            595919530,
            572703657,
            116094330,
            469519415,
            665213841,
            305488204,
            600113305,
            678925903,
            917153643,
            628292540,
            815209209,
            155881748,
            870066063,
            412737245,
            72602491,
            482133936,
            104543266,
            234603486,
            456485669,
            712019091,
            867831652,
            756482337,
            334461284,
            109756659,
            819644288,
            489549303,
            596446229,
            385211055,
            841027019,
            811174502,
            594081284,
            822317253,
            446095505,
            66470938,
            865132823,
            679821480,
            253421170,
            986280348,
            62862089,
            923078164,
            209749445,
            993751058,
            841971693,
            832795028,
            384626433,
            535897932,
            31415926,
        ),
    ),
    scale=1024,
    sign=False,
)
"""Pi to 1024 digits of precision."""


# TODO: When Mojo support global variables,
# we save the value of π to a certain precision in the global scope.
# This will allow us to use it everywhere without recalculating it
# if the required precision is the same or lower.
fn pi(precision: Int) raises -> BigDecimal:
    """Calculates π using Machin's formula.
    π/4 = 4*arctan(1/5) - arctan(1/239).

    Notes:
        Time complexity is O(n^3) ~ O(n^4) for precision n.
        Every time you double the precision, the time taken increases by a
        factor of 8 ~ 16.
    """

    if precision < 0:
        raise Error("Precision must be non-negative")
    # For precision up to 1024, we can use the precomputed value of π.
    # Since π is also input to other functions.
    # TODO: Everytime when user calls pi(precision),
    # we check whether the precision is higher than the current precision.
    # If yes, then we save it into the global scope.
    if precision <= 1024:
        return PI_1024.round(precision, RoundingMode.ROUND_HALF_EVEN)

    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = precision + BUFFER_DIGITS

    var bdec_1 = BigDecimal.from_raw_components(UInt32(1))
    var bdec_4 = BigDecimal.from_raw_components(UInt32(4))
    var bdec_5 = BigDecimal.from_raw_components(UInt32(5))
    var bdec_239 = BigDecimal.from_raw_components(UInt32(239))

    # Calculate 4 * arctan(1/5)
    var one_fifth = bdec_1.true_divide(bdec_5, working_precision)
    var term1 = bdec_4 * decimojo.bigdecimal.trigonometric.arctan_taylor_series(
        one_fifth, working_precision
    )

    # Calculate arctan(1/239)
    var one_239 = bdec_1.true_divide(bdec_239, working_precision)
    var term2 = decimojo.bigdecimal.trigonometric.arctan_taylor_series(
        one_239, working_precision
    )

    # π/4 = 4*arctan(1/5) - arctan(1/239)
    var pi_over_4 = term1 - term2

    # π = 4 * (π/4)
    var result = bdec_4 * pi_over_4

    return result.round(precision, RoundingMode.ROUND_HALF_EVEN)
