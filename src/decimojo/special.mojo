# ===----------------------------------------------------------------------=== #
#
# DeciMojo: A fixed-point decimal arithmetic library in Mojo
# https://github.com/forFudan/DeciMojo
#
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
#
# ===----------------------------------------------------------------------=== #
#
# Implements special functions for the Decimal type
#
# ===----------------------------------------------------------------------=== #

"""Implements functions for special operations on Decimal objects."""


fn factorial(n: Int) raises -> Decimal:
    """Calculates the factorial of a non-negative integer.

    Args:
        n: The non-negative integer to calculate the factorial of.

    Returns:
        The factorial of n.

    Notes:

    27! is the largest factorial that can be represented by Decimal.
    An error will be raised if n is greater than 27.
    """

    if n < 0:
        raise Error("Factorial is not defined for negative numbers")

    if n > 27:
        raise Error("{}! is too large to be represented by Decimal".format(n))

    # Directly return the factorial for n = 0 to 27
    if n == 0 or n == 1:
        return Decimal.from_words(1, 0, 0, 0)  # 1
    elif n == 2:
        return Decimal.from_words(2, 0, 0, 0)  # 2
    elif n == 3:
        return Decimal.from_words(6, 0, 0, 0)  # 6
    elif n == 4:
        return Decimal.from_words(24, 0, 0, 0)  # 24
    elif n == 5:
        return Decimal.from_words(120, 0, 0, 0)  # 120
    elif n == 6:
        return Decimal.from_words(720, 0, 0, 0)  # 720
    elif n == 7:
        return Decimal.from_words(5040, 0, 0, 0)  # 5040
    elif n == 8:
        return Decimal.from_words(40320, 0, 0, 0)  # 40320
    elif n == 9:
        return Decimal.from_words(362880, 0, 0, 0)  # 362880
    elif n == 10:
        return Decimal.from_words(3628800, 0, 0, 0)  # 3628800
    elif n == 11:
        return Decimal.from_words(39916800, 0, 0, 0)  # 39916800
    elif n == 12:
        return Decimal.from_words(479001600, 0, 0, 0)  # 479001600
    elif n == 13:
        return Decimal.from_words(1932053504, 1, 0, 0)  # 6227020800
    elif n == 14:
        return Decimal.from_words(1278945280, 20, 0, 0)  # 87178291200
    elif n == 15:
        return Decimal.from_words(2004310016, 304, 0, 0)  # 1307674368000
    elif n == 16:
        return Decimal.from_words(2004189184, 4871, 0, 0)  # 20922789888000
    elif n == 17:
        return Decimal.from_words(4006445056, 82814, 0, 0)  # 355687428096000
    elif n == 18:
        return Decimal.from_words(3396534272, 1490668, 0, 0)  # 6402373705728000
    elif n == 19:
        return Decimal.from_words(
            109641728, 28322707, 0, 0
        )  # 121645100408832000
    elif n == 20:
        return Decimal.from_words(
            2192834560, 566454140, 0, 0
        )  # 2432902008176640000
    elif n == 21:
        return Decimal.from_words(
            3099852800, 3305602358, 2, 0
        )  # 51090942171709440000
    elif n == 22:
        return Decimal.from_words(
            3772252160, 4003775155, 60, 0
        )  # 1124000727777607680000
    elif n == 23:
        return Decimal.from_words(
            862453760, 1892515369, 1401, 0
        )  # 25852016738884976640000
    elif n == 24:
        return Decimal.from_words(
            3519021056, 2470695900, 33634, 0
        )  # 620448401733239439360000
    elif n == 25:
        return Decimal.from_words(
            2076180480, 1637855376, 840864, 0
        )  # 15511210043330985984000000
    elif n == 26:
        return Decimal.from_words(
            2441084928, 3929534124, 21862473, 0
        )  # 403291461126605650322784000
    else:
        return Decimal.from_words(
            1484783616, 3018206259, 590286795, 0
        )  # 10888869450418352160768000000
