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

"""Implements exponential functions for the BigDecimal type."""

from decimojo.bigdecimal.bigdecimal import BigDecimal
from decimojo.rounding_mode import RoundingMode
import decimojo.utility

# ===----------------------------------------------------------------------=== #
# List of functions in this module:
# - power(base: BigDecimal, exponent: BigDecimal, precision: Int) -> BigDecimal
# - integer_power(base: BigDecimal, exponent: BigDecimal, precision: Int) -> BigDecimal
# - root(x: BigDecimal, n: BigDecimal, precision: Int) -> BigDecimal
# - integer_root(x: BigDecimal, n: BigDecimal, precision: Int) -> BigDecimal
# - is_integer_reciprocal_and_return(n: BigDecimal) -> Tuple[Bool, BigDecimal]
# - is_odd_reciprocal(n: BigDecimal) -> Bool
# - sqrt(x: BigDecimal, precision: Int) -> BigDecimal
# - exp(x: BigDecimal, precision: Int) -> BigDecimal
# - exp_taylor_series(x: BigDecimal, minimum_precision: Int) -> BigDecimal
# - ln(x: BigDecimal, precision: Int) -> BigDecimal
# - log(x: BigDecimal, precision: Int) -> BigDecimal
# - log10(x: BigDecimal, precision: Int) -> BigDecimal
# - ln_series_expansion(x: BigDecimal, precision: Int) -> BigDecimal
# - compute_ln2(precision: Int) -> BigDecimal
# - compute_ln1d25(precision: Int) -> BigDecimal
# ===----------------------------------------------------------------------=== #

# ===----------------------------------------------------------------------=== #
# Power and root functions
# power(base, exponent, precision)
# integer_power(base, exponent, precision)
# ===----------------------------------------------------------------------=== #


fn power(
    base: BigDecimal, exponent: BigDecimal, precision: Int = 28
) raises -> BigDecimal:
    """Raises a BigDecimal base to an arbitrary BigDecimal exponent power.

    Args:
        base: The base value to be raised to a power.
        exponent: The exponent to raise the base to.
        precision: Desired precision in significant digits.

    Returns:
        The result of base^exponent.

    Raises:
        Error: If base is negative and exponent is not an integer.
        Error: If base is zero and exponent is negative or zero.

    Notes:

    This function handles both integer and non-integer exponents using the
    identity x^y = e^(y * ln(x)) for the general case, with optimizations
    for integer exponents.
    """
    alias BUFFER_DIGITS = 9
    var working_precision = precision + BUFFER_DIGITS

    # Special cases
    if base.coefficient.is_zero():
        if exponent.coefficient.is_zero():
            raise Error("Error in power: 0^0 is undefined")
        elif exponent.sign:
            raise Error(
                "Error in power: Division by zero (negative exponent with zero"
                " base)"
            )
        else:
            return BigDecimal(BigUInt.ZERO, 0, False)

    if exponent.coefficient.is_zero():
        return BigDecimal(BigUInt.ONE, 0, False)  # x^0 = 1

    if base == BigDecimal(BigUInt.ONE, 0, False):
        return BigDecimal(BigUInt.ONE, 0, False)  # 1^y = 1

    if exponent == BigDecimal(BigUInt.ONE, 0, False):
        # return base  # x^1 = x
        var result = base
        result.round_to_precision(
            precision,
            rounding_mode=RoundingMode.ROUND_HALF_EVEN,
            remove_extra_digit_due_to_rounding=True,
            fill_zeros_to_precision=False,
        )
        return result^

    # Check for negative base with non-integer exponent
    if base.sign and not exponent.is_integer():
        raise Error(
            "Error in power: Negative base with non-integer exponent would"
            " produce a complex result"
        )

    # Optimization for integer exponents
    if exponent.is_integer() and exponent.coefficient.number_of_digits() <= 9:
        return integer_power(base, exponent, precision)

    # General case using x^y = e^(y*ln(x))
    # Need to be careful with negative base
    var abs_base = abs(base)
    var ln_result = ln(abs_base, working_precision)
    var product = ln_result * exponent
    var exp_result = exp(product, working_precision)

    # Handle sign for negative base with odd integer exponents
    if base.sign and exponent.is_integer() and exponent.is_odd():
        exp_result.sign = True

    exp_result.round_to_precision(
        precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )
    return exp_result^


fn integer_power(
    base: BigDecimal, exponent: BigDecimal, precision: Int
) raises -> BigDecimal:
    """Raises a base to integer exponents using binary exponentiation.

    Args:
        base: The base value.
        exponent: The integer exponent.
        precision: Desired precision.

    Returns:
        The result of base^exponent.
    """
    var working_precision = precision + 9  # Add buffer digits
    var abs_exp = abs(exponent)
    var exp_value: BigUInt
    if abs_exp.scale > 0:
        exp_value = abs_exp.coefficient.floor_divide_by_power_of_ten(
            abs_exp.scale
        )
    elif abs_exp.scale == 0:
        exp_value = abs_exp.coefficient
    else:
        exp_value = abs_exp.coefficient.multiply_by_power_of_ten(-abs_exp.scale)

    var result = BigDecimal(BigUInt.ONE, 0, False)
    var current_power = base

    # Handle negative exponent: result will be 1/positive_power
    var is_negative_exponent = exponent.sign

    # Binary exponentiation algorithm: x^n = (x^2)^(n/2) if n is even
    while exp_value > BigUInt.ZERO:
        if exp_value.words[0] % 2 == 1:
            # If current bit is set, multiply result by current power
            result = result * current_power
            # Round to avoid coefficient explosion
            result.round_to_precision(
                working_precision,
                rounding_mode=RoundingMode.ROUND_DOWN,
                remove_extra_digit_due_to_rounding=False,
                fill_zeros_to_precision=False,
            )

        current_power = current_power * current_power
        # Round to avoid coefficient explosion
        current_power.round_to_precision(
            working_precision,
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )

        decimojo.biguint.arithmetics.floor_divide_inplace_by_2(exp_value)

    # For negative exponents, compute reciprocal
    if is_negative_exponent:
        result = BigDecimal(BigUInt.ONE, 0, False).true_divide(
            result, working_precision
        )

    result.round_to_precision(
        precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=False,
        fill_zeros_to_precision=False,
    )
    return result^


fn root(x: BigDecimal, n: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculate the nth root of a BigDecimal number.

    Args:
        x: The number to calculate the root of.
        n: The root value.
        precision: The precision (number of significant digits) of the result.

    Returns:
        The nth root of x with the specified precision.

    Raises:
        Error: If x is negative and n is not an odd integer.
        Error: If n is zero.

    Notes:
        Uses the identity x^(1/n) = exp(ln(|x|)/n) for calculation.
        For integer roots, calls the specialized integer_root function.
    """
    alias BUFFER_DIGITS = 9
    var working_precision = precision + BUFFER_DIGITS

    # Check for n = 0
    if n.coefficient.is_zero():
        raise Error("Error in `root`: Cannot compute zeroth root")

    # Special case for integer roots - use more efficient implementation
    if not n.sign:
        if n.is_integer():
            return integer_root(x, n, precision)
        var is_integer_reciprocal: Bool
        var integer_reciprocal: BigDecimal
        is_integer_reciprocal, integer_reciprocal = (
            is_integer_reciprocal_and_return(n)
        )
        if is_integer_reciprocal:
            # If m = 1/n is an integer, use integer_root
            return integer_power(x, integer_reciprocal, precision)

    # Handle negative n as 1/(x^(1/|n|))
    if n.sign:
        var positive_root = root(x, -n, working_precision)
        var result = BigDecimal(BigUInt.ONE, 0, False).true_divide(
            positive_root, precision
        )
        return result^

    # Handle special cases for x
    if x.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, 0, False)

    if x.is_one():
        return BigDecimal(BigUInt.ONE, 0, False)

    # Check if x is negative - only odd integer roots of negative numbers are defined
    if x.sign:
        var n_is_integer = n.is_integer()
        var n_is_odd_reciprocal = is_odd_reciprocal(n)
        if not n_is_integer and not n_is_odd_reciprocal:
            raise Error(
                "Error in `root`: Cannot compute non-odd-integer root of a"
                " negative number"
            )
        elif n_is_integer:
            return integer_root(x, n, precision)

    # Compute root using the identity: x^(1/n) = exp(ln(|x|)/n)
    var abs_x = abs(x)
    var ln_x = ln(abs_x, working_precision)
    var ln_divided = ln_x.true_divide(n, working_precision)
    var result = exp(ln_divided, working_precision)

    # Handle sign for negative inputs (only possible with odd integer roots)
    if x.sign:
        result.sign = True

    result.round_to_precision(
        precision=precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=True,
    )

    return result^


fn integer_root(
    x: BigDecimal, n: BigDecimal, precision: Int
) raises -> BigDecimal:
    """Calculate the nth integer root of a BigDecimal number.

    Args:
        x: The number to calculate the root of.
        n: The root value (must be a positive integer).
        precision: The precision (number of significant digits) of the result.

    Returns:
        The nth root of x with the specified precision.

    Raises:
        Error: If x is negative and n is even.
        Error: If n is not a positive integer.
        Error: If n is zero.

    Notes:
        Uses the identity x^(1/n) = exp(ln(|x|)/n) for calculation.
        Optimizes for special cases including n=1 and n=2.
    """
    alias BUFFER_DIGITS = 9
    var working_precision = precision + BUFFER_DIGITS

    # Handle special case: n must be a positive integer
    if n.sign:
        raise Error("Error in `root`: Root value must be positive")

    if not n.is_integer():
        raise Error("Error in `root`: Root value must be an integer")

    if n.coefficient.is_zero():
        raise Error("Error in `root`: Cannot compute zeroth root")

    # Special case: n = 1 (1st root is just the number itself)
    if n.is_one():
        var result = x
        result.round_to_precision(
            precision,
            rounding_mode=RoundingMode.ROUND_HALF_EVEN,
            remove_extra_digit_due_to_rounding=True,
            fill_zeros_to_precision=False,
        )
        return result^

    # Special case: n = 2 (use dedicated sqrt function for better performance)
    if n == BigDecimal(BigUInt(2), 0, False):
        return sqrt(x, precision)

    # Handle special cases for x
    if x.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, 0, False)

    # For x = 1, the result is always 1
    if x.is_one():
        return BigDecimal(BigUInt.ONE, 0, False)

    var result_sign = False
    # Check if x is negative
    if x.sign:
        # Convert n to integer to check odd/even
        var n_uint: BigUInt
        if n.scale > 0:
            n_uint = n.coefficient.floor_divide_by_power_of_ten(n.scale)
        else:  # n.scale <= 0
            n_uint = n.coefficient

        if n_uint.words[0] % 2 == 1:  # Odd root
            result_sign = True
        else:  # n_uint.words[0] % 2 == 0:  # Even root
            raise Error(
                "Error in `root`: Cannot compute even root of a negative number"
            )

    # Compute root using the identity: x^(1/n) = exp(ln(|x|)/n)
    var abs_x = abs(x)
    var ln_x = ln(abs_x, working_precision)
    var ln_divided = ln_x.true_divide(n, working_precision)
    var result = exp(ln_divided, working_precision)
    result.sign = result_sign

    result.round_to_precision(
        precision=precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )

    return result^


fn is_integer_reciprocal_and_return(
    n: BigDecimal,
) raises -> Tuple[Bool, BigDecimal]:
    """Check if 1/n (n != 1) represents an odd integer and return the result.

    Args:
        n: The value to check.

    Returns:
        True if 1/n is an odd integer, False otherwise.
        The integer reciprocal of n.
    """
    var m = BigDecimal(BigUInt.ONE, 0, False).true_divide(
        n, precision=n.coefficient.number_of_digits() + 9
    )

    return Tuple(m.is_integer(), m)


fn is_odd_reciprocal(n: BigDecimal) raises -> Bool:
    """Check if 1/n (n != 1) represents an odd integer.

    Args:
        n: The value to check.

    Returns:
        True if 1/n is an odd integer, False otherwise.

    Notes:

    Numbers with infinite decimal places cannot be represented as BigDecimal.
    If integer m ends with 3, n=1/m cannot be exactly represented as input.
    Same applies to 1 (execpt exact 1), 7, 9.
    """
    # If n is of form 1/m where m is an odd integer, then 1/n = m is odd
    # This is true when n = 1/m for odd integer m

    var m = BigDecimal(BigUInt.ONE, 0, False).true_divide(
        n, precision=n.coefficient.number_of_digits() + 9
    )

    if m.is_integer():
        # Check if m is odd
        if m.coefficient.ith_digit(-m.scale) % 2 == 1:
            return True
        else:
            return False
    else:
        return False


# ===----------------------------------------------------------------------=== #
# Square root functions
#
# Yuhao ZHU:
# In DeciMojo v0.3.0, `sqrt` is implemented by using the BigDecimal objects to
# store the intermediate results. While this is more direct, it is not very
# efficient because it requires a lot of calculations to ensure that the scales
# and the precisions in the intermediate results are correct. It is also error-
# prone when scales are negative or there are two many significant digits.
# In DeciMojo v0.5.0, `sqrt` is re-implemented by using the BigUInt.sqrt()
# function. It first calculates the square root of the coefficient of x, and
# then adjust the scale based on the input scale, which is more efficient and
# error-free.
# The old implementation is still available as `sqrt_decimal_approach`.
# ===----------------------------------------------------------------------=== #


fn sqrt_decimal_approach(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculate the square root of a BigDecimal number.

    Args:
        x: The number to calculate the square root of.
        precision: The desired precision (number of significant digits) of the
            result.

    Returns:
        The square root of x with the specified precision.

    Raises:
        Error: If x is negative.

    Notes:

    This function uses Newton's method to iteratively approximate the square
    root. The intermediate calculations are done with BigDecimal objects.
    An other approach is to use the BigUInt.sqrt() function to calculate the
    square root of the coefficient of x, and then adjust the scale based on the
    input scale.
    """
    alias BUFFER_DIGITS = 9

    # Handle special cases
    if x.sign:
        raise Error(
            "Error in `sqrt`: Cannot compute square root of negative number"
        )

    if x.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, (x.scale + 1) // 2, False)

    # Initial guess
    # A decimal has coefficient and scale
    # Example 1:
    # 123456789012345678901234567890.12345 (sqrt ~= 351364182882014.4253111222382)
    # coef = 12345678_901234567_890123456_789012345, scale = 5
    # first three words = 12345678_901234567_890123456
    # number of integral digits = 30
    # Because it is even, no need to scale up by 10
    # not scale up by 10 => 12345678901234567890123456
    # sqrt(12345678901234567890123456) = 3513641828820
    # number of integral digits of the sqrt = (30 + 1) // 2 = 15
    # coef = 3513641828820, 13 digits, so scale = 13 - 15
    #
    # Example 2:
    # 12345678901.234567890123456789012345 (sqrt ~= 111111.1106111111099361111058)
    # coef = 12345678_901234567_890123456_789012345, scale = 24
    # first three words = 12345678_901234567_890123456
    # remaining number of words = 11
    # Because it is odd, need to scale up by 10
    # scale up by 10 => 123456789012345678901234560
    # sqrt(123456789012345678901234560) = 11111111061111
    # number of integral digits of the sqrt = (11 + 1) // 2 = 6
    # coef = 11111111061111, 14 digits, so scale = 14 - 6 => (111111.11061111)

    var guess: BigDecimal
    var ndigits_coef = x.coefficient.number_of_digits()
    var ndigits_int_part = x.coefficient.number_of_digits() - x.scale
    var ndigits_int_part_sqrt = (ndigits_int_part + 1) // 2
    var odd_ndigits_frac_part = x.scale % 2 == 1

    var value: UInt128
    if ndigits_coef <= 9:
        value = UInt128(x.coefficient.words[0]) * UInt128(
            1_000_000_000_000_000_000
        )
    elif ndigits_coef <= 18:
        value = (
            UInt128(x.coefficient.words[-1])
            * UInt128(1_000_000_000_000_000_000)
        ) + (UInt128(x.coefficient.words[-2]) * UInt128(1_000_000_000))
    else:  # ndigits_coef > 18
        value = (
            (
                UInt128(x.coefficient.words[-1])
                * UInt128(1_000_000_000_000_000_000)
            )
            + UInt128(x.coefficient.words[-2]) * UInt128(1_000_000_000)
            + UInt128(x.coefficient.words[-3])
        )
    if odd_ndigits_frac_part:
        value = value * UInt128(10)
    var sqrt_value = decimojo.utility.sqrt(value)
    var sqrt_value_biguint = BigUInt.from_unsigned_integral_scalar(sqrt_value)
    guess = BigDecimal(
        sqrt_value_biguint,
        sqrt_value_biguint.number_of_digits() - ndigits_int_part_sqrt,
        False,
    )

    # For Newton's method, we need extra precision during calculations
    # to ensure the final result has the desired precision
    var working_precision = precision + BUFFER_DIGITS

    # Newton's method iterations
    # x_{n+1} = (x_n + N/x_n) / 2
    var prev_guess = BigDecimal(BigUInt.ZERO, 0, False)
    var iteration_count = 0

    while guess != prev_guess and iteration_count < 100:
        prev_guess = guess
        var quotient = x.true_divide_inexact(guess, working_precision)
        var sum = guess + quotient
        guess = sum.true_divide(BigDecimal(BigUInt(2), 0, 0), working_precision)
        iteration_count += 1

    # Round to the desired precision
    var ndigits_to_remove = guess.coefficient.number_of_digits() - precision
    if ndigits_to_remove > 0:
        var coefficient = guess.coefficient
        coefficient = coefficient.remove_trailing_digits_with_rounding(
            ndigits_to_remove,
            rounding_mode=RoundingMode.ROUND_HALF_UP,
            remove_extra_digit_due_to_rounding=True,
        )
        guess.coefficient = coefficient^
        guess.scale -= ndigits_to_remove

    # Remove trailing zeros for exact results
    # TODO: This can be done even earlier in the process
    # TODO: Implement a method that remove trailing zeros
    if guess.coefficient.ith_digit(0) == 0:
        var guess_coefficient_without_trailing_zeros = (
            guess.coefficient.remove_trailing_digits_with_rounding(
                guess.coefficient.number_of_trailing_zeros(),
                rounding_mode=RoundingMode.ROUND_DOWN,
                remove_extra_digit_due_to_rounding=False,
            )
        )
        var x_coefficient_without_trailing_zeros = (
            x.coefficient.remove_trailing_digits_with_rounding(
                x.coefficient.number_of_trailing_zeros(),
                rounding_mode=RoundingMode.ROUND_DOWN,
                remove_extra_digit_due_to_rounding=False,
            )
        )
        if (
            guess_coefficient_without_trailing_zeros
            * guess_coefficient_without_trailing_zeros
        ) == x_coefficient_without_trailing_zeros:
            var expected_ndigits_of_result = (
                x.coefficient.number_of_digits() + 1
            ) // 2
            guess.round_to_precision(
                precision=expected_ndigits_of_result,
                rounding_mode=RoundingMode.ROUND_DOWN,
                remove_extra_digit_due_to_rounding=False,
                fill_zeros_to_precision=False,
            )
            guess.scale = (x.scale + 1) // 2

    return guess^


fn sqrt(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculate the square root of a BigDecimal number.

    Args:
        x: The number to calculate the square root of.
        precision: The desired precision (number of significant digits) of the
            result.

    Returns:
        The square root of x with the specified precision.

    Raises:
        Error: If x is negative.

    Notes:
        This function uses BigUInt.sqrt() to calculate the square root of the
        coefficient of x, and then adjusts the scale based on the input scale.
    """

    # Yuhao ZHU:
    # I am using the following tricks to ensure that the scales are correct
    # during scale up and scale down operations.
    # A BigDecimal has a coefficient (c) and a scale (s) -> c*10^(-s).
    # Let the final targeted scale to be t. So the result should have
    # (c*10^(-s))^(1/2) = (c*10^(2t-s)*10^(-2t+s)*10^(-s))^(1/2)
    #                   = (c*10^(2t-s))^(1/2) * 10^(-t)
    #                   = c_0 * 10^(-t)
    # where c_0 is the new coefficient after taking the square root and
    # t is the new scale.
    # So we first need to extend the coefficient by 10^(2t-s) to ensure
    # the square root has enough precision. Let's denote the precision as p.
    # Thus, the number of digits of c*10^(2t-s) should be at least 2p.
    # That is t > p + (s - d(c)) // 2

    # Handle special cases
    if x.sign:
        raise Error(
            "Error in `sqrt`: Cannot compute square root of negative number"
        )

    if x.coefficient.is_zero():
        return BigDecimal(BigUInt.ZERO, (x.scale + 1) // 2, False)

    # STEP 1: Extend the coefficient by 10^(2p-s)
    var working_precision = precision + 9  # p
    var n_digits_coef = x.coefficient.number_of_digits()  # d(c)
    var new_scale = working_precision + (x.scale - n_digits_coef) // 2 + 1  # t
    var n_digits_to_extend = new_scale * 2 - x.scale  # 2t - s
    var half_n_digits_to_extend = n_digits_to_extend // 2
    var extended_coefficient: BigUInt
    if n_digits_to_extend > 0:
        extended_coefficient = (
            decimojo.biguint.arithmetics.multiply_by_power_of_ten(
                x.coefficient, n_digits_to_extend
            )
        )
    elif n_digits_to_extend == 0:
        extended_coefficient = x.coefficient
    else:  # n_digits_to_extend < 0
        debug_assert(
            -n_digits_to_extend >= 0,
            "n_digits_to_extend should not be negative",
        )
        extended_coefficient = (
            decimojo.biguint.arithmetics.floor_divide_by_power_of_ten(
                x.coefficient, -n_digits_to_extend
            )
        )

    # STEP 2: Calculate the square root of the extended coefficient
    var sqrt_coefficient = decimojo.biguint.exponential.sqrt(
        extended_coefficient
    )

    # If the last p digits of the coefficient are zeros, this means that
    # we have a perfect square, so we can scale down the coefficient
    # and the scale.
    if sqrt_coefficient.number_of_trailing_zeros() >= half_n_digits_to_extend:
        debug_assert(
            -half_n_digits_to_extend >= 0,
            "half_n_digits_to_extend should not be negative",
        )
        sqrt_coefficient = (
            decimojo.biguint.arithmetics.floor_divide_by_power_of_ten(
                sqrt_coefficient, half_n_digits_to_extend
            )
        )
        new_scale -= half_n_digits_to_extend

    var result = BigDecimal(
        sqrt_coefficient^,
        new_scale,
        False,
    )
    result.round_to_precision(
        precision=precision,
        rounding_mode=RoundingMode.ROUND_HALF_UP,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )
    return result^


fn cbrt(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculate the cube root of a BigDecimal number.

    Args:
        x: The number to calculate the cube root of.
        precision: The desired precision (number of significant digits) of the result.

    Returns:
        The cube root of x with the specified precision.

    Raises:
        Error: If x is negative.
    """

    result = integer_root(
        x,
        BigDecimal(coefficient=BigUInt(List[UInt32](3)), scale=0, sign=False),
        precision,
    )
    return result^


# ===----------------------------------------------------------------------=== #
# Exponential functions
# ===----------------------------------------------------------------------=== #


fn exp(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculate the natural exponential of x (e^x) to the specified precision.

    Args:
        x: The exponent value.
        precision: Desired precision in significant digits.

    Returns:
        The natural exponential of x (e^x) to the specified precision.

    Notes:
        Uses optimized algorithm combining:
        - Range reduction.
        - Taylor series.
        - Precision tracking.
    """
    # Extra working precision to ensure final result accuracy
    alias BUFFER_DIGITS = 9
    var working_precision = precision + BUFFER_DIGITS

    # Handle special cases
    if x.coefficient.is_zero():
        return BigDecimal(
            BigUInt.ONE, x.scale, x.sign
        )  # e^0 = 1, return with same scale and sign

    # For very large positive values, result will overflow BigDecimal capacity
    # Calculate rough estimate to detect overflow early
    # TODO: Use BigInt as scale can avoid overflow in this case
    if not x.sign and x.exponent() >= 20:  # x > 10^20
        raise Error("Error in `exp`: Result too large to represent")

    # For very large negative values, result will be effectively zero
    if x.sign and x.exponent() >= 20:  # x < -10^20
        return BigDecimal(BigUInt.ZERO, precision, False)

    # Handle negative x using identity: exp(-x) = 1/exp(x)
    if x.sign:
        var pos_result = exp(-x, precision + 2)
        return BigDecimal(BigUInt.ONE, 0, False).true_divide(
            pos_result, precision
        )

    # Range reduction for faster convergence
    # If x >= 0.1, use exp(x) = exp(x/2)²
    if x >= BigDecimal(BigUInt.ONE, 1, False):
        # var t_before_range_reduction = time.perf_counter_ns()
        var k = 0
        var threshold = BigDecimal(BigUInt.ONE, 0, False)
        while threshold.exponent() <= x.exponent() + 1:
            threshold.coefficient = (
                threshold.coefficient + threshold.coefficient
            )  # Multiply by 2
            k += 1

        # Calculate exp(x/2^k)
        var reduced_x = x.true_divide_inexact(threshold, working_precision)

        # var t_after_range_reduction = time.perf_counter_ns()

        var result = exp_taylor_series(reduced_x, working_precision)

        # var t_after_taylor_series = time.perf_counter_ns()

        # Square result k times: exp(x) = exp(x/2^k)^(2^k)
        for _ in range(k):
            result = result * result
            result.round_to_precision(
                precision=working_precision,
                rounding_mode=RoundingMode.ROUND_HALF_UP,
                remove_extra_digit_due_to_rounding=False,
                fill_zeros_to_precision=False,
            )

        result.round_to_precision(
            precision=precision,
            rounding_mode=RoundingMode.ROUND_HALF_EVEN,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )

        # var t_after_scale_up = time.perf_counter_ns()

        # print(
        #     "TIME: range reduction: {}ns".format(
        #         t_after_range_reduction - t_before_range_reduction
        #     )
        # )
        # print(
        #     "TIME: taylor series: {}ns".format(
        #         t_after_taylor_series - t_after_range_reduction
        #     )
        # )
        # print(
        #     "TIME: scale up: {}ns".format(
        #         t_after_scale_up - t_after_taylor_series
        #     )
        # )

        return result^

    # For small values, use Taylor series directly
    var result = exp_taylor_series(x, working_precision)

    result.round_to_precision(
        precision=precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )

    return result^


fn exp_taylor_series(
    x: BigDecimal, minimum_precision: Int
) raises -> BigDecimal:
    """Calculate exp(x) using Taylor series for |x| <= 1.

    Args:
        x: The exponent value.
        minimum_precision: Minimum precision in significant digits.

    Returns:
        The natural exponential of x (e^x) to the specified precision with some
        extra digits to ensure accuracy.
    """
    # Theoretical number of terms needed based on precision
    # For |x| ≤ 1, error after n terms is approximately |x|^(n+1)/(n+1)!
    # We need |x|^(n+1)/(n+1)! < 10^(-precision)
    # For x=1, we need approximately n ≈ precision * ln(10) ≈ precision * 2.3
    #
    # ZHU: About complexity:
    # In each loop, there are 2 mul (2 x 100ns) and 1 div (2000ns)
    # There are intotal 2.3 * precision iterations

    # print("DEBUG: exp_taylor_series")
    # print("DEBUG: x =", x)

    var max_number_of_terms = Int(minimum_precision * 2.5) + 1
    var result = BigDecimal(BigUInt.ONE, 0, False)
    var term = BigDecimal(BigUInt.ONE, 0, False)
    var n = BigUInt.ONE

    # Calculate Taylor series: 1 + x + x²/2! + x³/3! + ...
    for _ in range(1, max_number_of_terms):
        # Calculate next term: x^i/i! = x^{i-1} * x/i
        # We can use the previous term to calculate the next one
        var add_on = x.true_divide_inexact(
            BigDecimal(n, 0, False), minimum_precision
        )
        term = term * add_on
        term.round_to_precision(
            precision=minimum_precision,
            rounding_mode=RoundingMode.ROUND_HALF_UP,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )
        n += BigUInt.ONE

        # Add term to result
        result += term

        # print("DEUBG: round {}, term {}, result {}".format(n, term, result))

        # Check if we've reached desired precision
        if term.exponent() < -minimum_precision:
            break

    result.round_to_precision(
        precision=minimum_precision,
        rounding_mode=RoundingMode.ROUND_HALF_UP,
        remove_extra_digit_due_to_rounding=False,
        fill_zeros_to_precision=False,
    )
    # print("DEBUG: final result", result)

    return result^


# ===----------------------------------------------------------------------=== #
# Logarithmic functions
# ===----------------------------------------------------------------------=== #


fn ln(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculate the natural logarithm of x to the specified precision.

    Args:
        x: The input value.
        precision: Desired precision in significant digits.

    Returns:
        The natural logarithm of x to the specified precision.

    Raises:
        Error: If x is negative or zero.
    """
    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = precision + BUFFER_DIGITS

    # Handle special cases
    if x.sign:
        raise Error(
            "Error in `ln`: Cannot compute logarithm of negative number"
        )
    if x.coefficient.is_zero():
        raise Error("Error in `ln`: Cannot compute logarithm of zero")
    if x == BigDecimal(BigUInt.ONE, 0, False):
        return BigDecimal(BigUInt.ZERO, 0, False)  # ln(1) = 0

    # Range reduction to improve convergence
    # ln(x) = ln(m * 2^a * 5^b) =
    #   = ln(m) + a*ln(2) + b*ln(5)
    #   = ln(m) + a*ln(2) + b*(ln(5/4) + ln(4))
    #   = ln(m) + a*ln(2) + b*(ln(1.25) + 2*ln(2))
    #   = ln(m) + (a+b*2)*ln(2) + b*ln(1.25)
    #   where 0.5 <= m < 1.5
    # Use Taylor series for ln(m) = ln(1+z)
    var m = x
    var power_of_2: Int = 0
    var power_of_5: Int = 0
    # First, scale down to [0.1, 1)
    var power_of_10 = m.exponent() + 1
    m.scale += power_of_10
    # Second, scale to [0.5, 1.5)
    if m < BigDecimal(BigUInt(List[UInt32](135)), 3, False):
        # [0.1, 0.135) * 10 -> [1, 1.35)
        power_of_10 -= 1
        m.scale -= 1
    elif m < BigDecimal(BigUInt(List[UInt32](275)), 3, False):
        # [0.135, 0.275) * 5 -> [0.675, 1.375)]
        power_of_5 -= 1
        m = m * BigDecimal(BigUInt(List[UInt32](5)), 0, False)
    elif m < BigDecimal(BigUInt(List[UInt32](65)), 2, False):
        # [0.275, 0.65) * 2 -> [0.55, 1.3)]
        power_of_2 -= 1
        m = m * BigDecimal(BigUInt(List[UInt32](2)), 0, False)
    else:  # [0.65, 1) -> no change
        pass
    # Replace 10 with 5 and 2
    power_of_5 += power_of_10
    power_of_2 += power_of_10

    # print("Input: {} = {} * 2^{} * 5^{}".format(x, m, power_of_2, power_of_5))

    # Use series expansion for ln(m) = ln(1+z) = z - z²/2 + z³/3 - ...
    var result = ln_series_expansion(
        m - BigDecimal(BigUInt.ONE, 0, False), working_precision
    )

    # print("Result after series expansion:", result)

    # Apply range reduction adjustments
    # ln(m) + (a+b*2)*ln(2) + b*ln(1.25)
    # TODO: Use precomputed ln(2) for better performance
    # It is only calculated once and saved in the cache (global variable)
    # Need Mojo to support global variables
    if power_of_2 + power_of_5 * 2 != 0:
        # if len(decimojo.cache_ln2.coefficient.words) != 0:
        #     var ln2 = decimojo.cache_ln2
        var ln2 = compute_ln2(working_precision)
        result += ln2 * BigDecimal.from_int(power_of_2 + power_of_5 * 2)
    if power_of_5 != 0:
        # if len(decimojo.cache_ln5.coefficient.words) != 0:
        #     var ln1d25 = decimojo.cache_ln1d25
        var ln1d25 = compute_ln1d25(working_precision)
        result += ln1d25 * BigDecimal.from_int(power_of_5)

    # Round to final precision
    result.round_to_precision(
        precision=precision,
        rounding_mode=RoundingMode.ROUND_HALF_EVEN,
        remove_extra_digit_due_to_rounding=True,
        fill_zeros_to_precision=False,
    )

    return result^


fn log(x: BigDecimal, base: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculates the logarithm of x with respect to an arbitrary base.

    Args:
        x: The value to compute the logarithm.
        base: The base of the logarithm.
        precision: Desired precision in decimal digits.

    Returns:
        The logarithm of x with respect to base.

    Raises:
        Error: If x is negative or zero.
        Error: If base is negative, zero, or one.
    """
    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = precision + BUFFER_DIGITS

    # Special cases
    if x.sign:
        raise Error(
            "Error in log(): Cannot compute logarithm of a negative number"
        )
    if x.coefficient.is_zero():
        raise Error("Error in log(): Cannot compute logarithm of zero")

    # Base validation
    if base.sign:
        raise Error("Error in log(): Cannot use a negative base")
    if base.coefficient.is_zero():
        raise Error("Error in log(): Cannot use zero as a base")
    if (
        base.coefficient.number_of_digits() == base.scale + 1
        and base.coefficient.words[-1] == 1
    ):
        raise Error("Error in log(): Cannot use base 1 for logarithm")

    # Special cases
    if (
        x.coefficient.number_of_digits() == x.scale + 1
        and x.coefficient.words[-1] == 1
    ):
        return BigDecimal(BigUInt.ZERO, 0, False)  # log_base(1) = 0

    if x == base:
        return BigDecimal(BigUInt.ONE, 0, False)  # log_base(base) = 1

    # Optimization for base 10
    if (
        base.scale == 0
        and base.coefficient.number_of_digits() == 2
        and base.coefficient.words[-1] == 10
    ):
        return log10(x, precision)

    # Use the identity: log_base(x) = ln(x) / ln(base)
    var ln_x = ln(x, working_precision)
    var ln_base = ln(base, working_precision)

    var result = ln_x.true_divide(ln_base, precision)
    return result^


fn log10(x: BigDecimal, precision: Int) raises -> BigDecimal:
    """Calculates the base-10 logarithm of a BigDecimal value.

    Args:
        x: The value to compute log10.
        precision: Desired precision in decimal digits.

    Returns:
        The base-10 logarithm of x.

    Raises:
        Error: If x is negative or zero.
    """
    alias BUFFER_DIGITS = 9  # word-length, easy to append and trim
    var working_precision = precision + BUFFER_DIGITS

    # Special cases
    if x.sign:
        raise Error(
            "Error in log10(): Cannot compute logarithm of a negative number"
        )
    if x.coefficient.is_zero():
        raise Error("Error in log10(): Cannot compute logarithm of zero")

    # Fast path: Powers of 10 are handled directly
    if x.coefficient.is_power_of_10():
        # If x = 10^n, return n
        var power = x.coefficient.number_of_trailing_zeros() - x.scale
        return BigDecimal.from_int(power)

    # Special case for x = 1
    if (
        x.coefficient.number_of_digits() == x.scale + 1
        and x.coefficient.words[-1] == 1
    ):
        return BigDecimal(BigUInt.ZERO, 0, False)  # log10(1) = 0

    # Use the identity: log10(x) = ln(x) / ln(10)
    var ln_result = ln(x, working_precision)
    var result = ln_result.true_divide(
        ln(BigDecimal(BigUInt(List[UInt32](10)), 0, False), working_precision),
        precision,
    )

    return result^


fn ln_series_expansion(
    z: BigDecimal, working_precision: Int
) raises -> BigDecimal:
    """Calculate ln(1+z) using optimized series expansion.

    Args:
        z: The input value, should be |z| < 1 for fast convergence.
        working_precision: Desired working precision in significant digits.

    Returns:
        The ln(1+z) computed to the specified working precision.

    Notes:

    The last few digits of result are not accurate as there is no buffer for
    precision. You need to use a larger precision to get the last few digits
    accurate. The precision is only used to determine the number of terms in
    the series expansion, not for the final result.
    """

    # print("DEBUG: ln_series_expansion for z =", z)

    if z.is_zero():
        return BigDecimal(BigUInt.ZERO, 0, False)

    var max_terms = Int(working_precision * 2.5) + 1
    var result = BigDecimal(BigUInt.ZERO, working_precision, False)
    var term = z
    var k = BigUInt.ONE

    # Use the series ln(1+z) = z - z²/2 + z³/3 - z⁴/4 + ...
    result += term  # First term is just x
    # print("DEBUG: term =", term, "result =", result)
    # print("DEBUG: k =", k, "max_terms =", max_terms)

    for _ in range(2, max_terms):
        # Update for next iteration - multiply by z and divide by k
        term = term * z  # z^k
        k += BigUInt.ONE

        # Alternate sign: -1^(k+1) = -1 when k is even, 1 when k is odd
        var sign = k % BigUInt(2) == BigUInt.ZERO
        var next_term = term.true_divide_inexact(
            BigDecimal(k, 0, False), working_precision
        )

        if sign:
            result -= next_term
        else:
            result += next_term

        # print("DEBUG: k =", k, "max_terms =", max_terms)
        # print("DEBUG: term =", term, "next_term =", next_term)
        # print("DEBUG: result =", result)

        # Check for convergence
        if next_term.exponent() < -working_precision:
            break

    # print("DEBUG: ln_series_expansion result:", result)
    result.round_to_precision(
        precision=working_precision,
        rounding_mode=RoundingMode.ROUND_DOWN,
        remove_extra_digit_due_to_rounding=False,
        fill_zeros_to_precision=False,
    )
    return result^


fn compute_ln2(working_precision: Int) raises -> BigDecimal:
    """Compute ln(2) to the specified working precision.

    Args:
        working_precision: Desired precision in significant digits.

    Returns:
        The ln(2) computed to the specified precision.

    Notes:

    The last few digits of result are not accurate as there is no buffer for
    precision. You need to use a larger precision to get the last few digits
    accurate. The precision is only used to determine the number of terms in
    the series expansion, not for the final result.
    """
    # Directly using Taylor series expansion for ln(2) is not efficient
    # Instead, we can use the identity:
    # ln((1+x)/(1-x)) = 2*arcth(x) = 2*(x + x³/3 + x⁵/5 + ...)
    # For x = 1/3:
    # ln(2) = 2*(1/3 + (1/3)³/3 + (1/3)⁵/5 + ...)

    if working_precision <= 90:
        # Use precomputed value for ln(2) for lower precision
        var result = BigDecimal(
            BigUInt(
                List[UInt32](
                    605863326,
                    969694715,
                    493393621,
                    120680009,
                    360255254,
                    75500134,
                    458176568,
                    417232121,
                    559945309,
                    693147180,
                )
            ),
            90,
            False,
        )
        result.round_to_precision(
            precision=working_precision,
            rounding_mode=RoundingMode.ROUND_DOWN,
            remove_extra_digit_due_to_rounding=False,
            fill_zeros_to_precision=False,
        )
        return result^

    var max_terms = Int(working_precision * 2.5) + 1

    var number_of_words = working_precision // 9 + 1
    var words = List[UInt32](capacity=number_of_words)
    for _ in range(number_of_words):
        words.append(UInt32(333_333_333))
    var x = BigDecimal(BigUInt(words), number_of_words * 9, False)  # x = 1/3

    var result = BigDecimal(BigUInt.ZERO, 0, False)
    var term = x * BigDecimal(BigUInt(2), 0, False)  # First term: 2*(1/3)
    var k = BigDecimal(BigUInt.ONE, 0, False)

    # Add terms: 2*(x + x³/3 + x⁵/5 + ...)
    for _ in range(1, max_terms):
        result += term
        var new_k = k + BigDecimal(BigUInt(List[UInt32](2)), 0, False)
        term = (term * x * x * k).true_divide_inexact(new_k, working_precision)
        k = new_k^
        if term.exponent() < -working_precision:
            break

    result.round_to_precision(
        precision=working_precision,
        rounding_mode=RoundingMode.ROUND_DOWN,
        remove_extra_digit_due_to_rounding=False,
        fill_zeros_to_precision=False,
    )
    return result^


fn compute_ln1d25(precision: Int) raises -> BigDecimal:
    """Compute ln(1.25) to the specified precision.

    Args:
        precision: Desired precision in significant digits.

    Returns:
        The ln(1.25) computed to the specified precision.
    """
    var z = BigDecimal(BigUInt(List[UInt32](25)), 2, False)
    var result = ln_series_expansion(z^, precision)
    return result^
