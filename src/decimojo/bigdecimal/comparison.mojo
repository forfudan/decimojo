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
Implements functions for comparison operations on BigDecimal objects.
"""

from decimojo.bigdecimal.bigdecimal import BigDecimal


fn compare_absolute(x1: BigDecimal, x2: BigDecimal) -> Int8:
    """Compares the absolute values of two numbers.

    Args:
        x1: First number.
        x2: Second number.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if |x1| > |x2|.
        (2)  0 if |x1| = |x2|.
        (3) -1 if |x1| < |x2|.
    """
    # Handle zero cases
    if x1.coefficient.is_zero() and x2.coefficient.is_zero():
        return 0
    if x1.coefficient.is_zero():
        return -1
    if x2.coefficient.is_zero():
        return 1

    # If scales are equal, compare coefficients directly
    if x1.scale == x2.scale:
        # Use existing BigUInt comparison
        return x1.coefficient.compare(x2.coefficient)

    # Compare number of digits before the decimal point (integer part)
    var x1_int_digits = x1.coefficient.number_of_digits() - x1.scale
    var x2_int_digits = x2.coefficient.number_of_digits() - x2.scale

    # If integer parts have different lengths, larger integer part wins
    if x1_int_digits > x2_int_digits:
        return 1
    if x1_int_digits < x2_int_digits:
        return -1

    # Integer parts have same length, need to compare digit by digit
    # Scale up the number with smaller scale to match the other's scale
    var scale_diff = x1.scale - x2.scale

    if scale_diff > 0:
        # x1 has larger scale (more decimal places)
        var scaled_x2 = x2.coefficient.multiply_by_power_of_ten(scale_diff)
        return x1.coefficient.compare(scaled_x2^)
    else:
        # x2 has larger scale (more decimal places)
        var scaled_x1 = x1.coefficient.multiply_by_power_of_ten(-scale_diff)
        return scaled_x1.compare(x2.coefficient)


fn compare(x1: BigDecimal, x2: BigDecimal) -> Int8:
    """Compares two BigDecimal numbers.

    Args:
        x1: First number.
        x2: Second number.

    Returns:
        Terinary value indicating the comparison result:
        (1)  1 if x1 > x2.
        (2)  0 if x1 = x2.
        (3) -1 if x1 < x2.
    """
    # Handle zero cases first
    if x1.coefficient.is_zero() and x2.coefficient.is_zero():
        return 0

    # If one is zero, handle specially
    if x1.coefficient.is_zero():
        return 1 if x2.sign else -1  # 0 > negative, 0 < positive
    if x2.coefficient.is_zero():
        return -1 if x1.sign else 1  # negative < 0, positive > 0

    # If signs differ, the positive one is greater
    if not x1.sign and x2.sign:  # x1 is positive, x2 is negative
        return 1
    if x1.sign and not x2.sign:  # x1 is negative, x2 is positive
        return -1

    # Same sign - compare absolute values
    var abs_comparison = compare_absolute(x1, x2)

    # For negative numbers, reverse the comparison result
    if x1.sign:  # Both are negative
        return -abs_comparison  # Negate the result for negative numbers
    else:  # Both are positive
        return abs_comparison


fn equals(x1: BigDecimal, x2: BigDecimal) -> Bool:
    """Returns whether x1 equals x2."""
    return compare(x1, x2) == 0


fn not_equals(x1: BigDecimal, x2: BigDecimal) -> Bool:
    """Returns whether x1 does not equal x2."""
    return compare(x1, x2) != 0


fn less_than(x1: BigDecimal, x2: BigDecimal) -> Bool:
    """Returns whether x1 is less than x2."""
    return compare(x1, x2) < 0


fn less_than_or_equal(x1: BigDecimal, x2: BigDecimal) -> Bool:
    """Returns whether x1 is less than or equal to x2."""
    return compare(x1, x2) <= 0


fn greater_than(x1: BigDecimal, x2: BigDecimal) -> Bool:
    """Returns whether x1 is greater than x2."""
    return compare(x1, x2) > 0


fn greater_than_or_equal(x1: BigDecimal, x2: BigDecimal) -> Bool:
    """Returns whether x1 is greater than or equal to x2."""
    return compare(x1, x2) >= 0


fn max(x1: BigDecimal, x2: BigDecimal) -> BigDecimal:
    """Returns the maximum of x1 and x2."""
    if compare(x1, x2) >= 0:
        return x1
    return x2


fn min(x1: BigDecimal, x2: BigDecimal) -> BigDecimal:
    """Returns the minimum of x1 and x2."""
    if compare(x1, x2) <= 0:
        return x1
    return x2
