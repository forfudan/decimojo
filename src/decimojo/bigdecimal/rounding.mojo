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
Implements functions for mathematical operations on Decimal objects.
"""

from decimojo.bigdecimal.bigdecimal import BigDecimal

# ===------------------------------------------------------------------------===#
# Rounding
# ===------------------------------------------------------------------------===#


fn round_to_precision(
    mut number: BigDecimal,
    precision: Int,
    rounding_mode: RoundingMode,
    remove_extra_digit_due_to_rounding: Bool,
    fill_zeros_to_precision: Bool,
) raises:
    """Rounds the number to the specified precision in-place.

    Args:
        number: The number to round.
        precision: Number of precision digits to round to.
            Defaults to 28.
        rounding_mode: Rounding mode to use.
            RoundingMode.ROUND_DOWN: Round down.
            RoundingMode.ROUND_UP: Round up.
            RoundingMode.ROUND_HALF_UP: Round half up.
            RoundingMode.ROUND_HALF_EVEN: Round half even.
        remove_extra_digit_due_to_rounding: If True, remove an trailing.
            digit if the rounding mode result in an extra digit.
        fill_zeros_to_precision: If True, fill zeros to the precision.
    """

    var ndigits_coefficient = number.coefficient.number_of_digits()
    var ndigits_to_remove = ndigits_coefficient - precision

    if ndigits_to_remove == 0:
        return

    if ndigits_to_remove < 0:
        if fill_zeros_to_precision:
            number = number.extend_precision(precision_diff=-ndigits_to_remove)
            return
        else:
            return

    number.coefficient = (
        number.coefficient.remove_trailing_digits_with_rounding(
            ndigits=ndigits_to_remove,
            rounding_mode=rounding_mode,
            remove_extra_digit_due_to_rounding=False,
        )
    )
    number.scale -= ndigits_to_remove

    if remove_extra_digit_due_to_rounding and (
        number.coefficient.number_of_digits() > precision
    ):
        number.coefficient = (
            number.coefficient.remove_trailing_digits_with_rounding(
                ndigits=1,
                rounding_mode=RoundingMode.ROUND_DOWN,
                remove_extra_digit_due_to_rounding=False,
            )
        )
        number.scale -= 1
