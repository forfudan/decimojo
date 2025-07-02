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

# ===----------------------------------------------------------------------=== #
# Trigonometric functions for BigDecimal
# ===----------------------------------------------------------------------=== #

import time

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode
import decimojo.utility


fn sin(x: BigDecimal, precision: Int) raises:
    ...


fn arctan_taylor_series(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculates arctan(x) using Taylor series.
    arctan(x) = x - x³/3 + x⁵/5 - x⁷/7 + ...

    Notes:
        Time complexity is O(n^4) for precision n.
        Every time you double the precision, the time taken increases by a
        factor of 16.
    """

    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = precision + BUFFER_DIGITS

    if x.is_zero():
        return BigDecimal(0)

    var term = x  # x^n
    var result = x
    var x_squared = x * x
    var n = 1
    var sign = -1
    var term_divided: BigDecimal

    # Continue until term is smaller than desired precision
    var epsilon = BigDecimal(BigUInt.ONE, scale=working_precision, sign=False)

    while term.compare_absolute(epsilon) > 0:
        n += 2
        term = term * x_squared  # x^n = x^(n-2) * x^2
        term_divided = term.true_divide(
            BigDecimal(n), precision=working_precision
        )  # x^n / n
        if sign == 1:
            result += term_divided
        else:
            result -= term_divided
        sign *= -1

    return result^
