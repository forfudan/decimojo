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

"""
Implements functions for mathematical operations on Decimal objects.
"""

from decimojo.decimal import Decimal


fn power(base: Decimal, exponent: Decimal) raises -> Decimal:
    """
    Raises base to the power of exponent and returns a new Decimal.

    Currently supports integer exponents only.

    Args:
        base: The base value.
        exponent: The power to raise base to.
            It must be an integer or effectively an integer (e.g., 2.0).

    Returns:
        A new Decimal containing the result of base^exponent

    Raises:
        Error: If exponent is not an integer or if the operation would overflow.
    """
    print("\n===== POWER OPERATION DEBUG =====")
    print("Base:", String(base), "scale:", String(base.scale()))
    print("Exponent:", String(exponent), "scale:", String(exponent.scale()))

    # Check if exponent is an integer
    if not exponent.is_integer():
        raise Error("Power operation is only supported for integer exponents")

    # Convert exponent to integer
    var exp_value = Int(exponent)
    print("Exponent as integer:", String(exp_value))

    # Special cases
    if exp_value == 0:
        # x^0 = 1 (including 0^0 = 1 by convention)
        print("Special case: x^0 = 1")
        return Decimal.ONE()

    if exp_value == 1:
        # x^1 = x
        print("Special case: x^1 = x")
        return base

    if base.is_zero():
        # 0^n = 0 for n > 0
        if exp_value > 0:
            print("Special case: 0^(positive) = 0")
            return Decimal.ZERO()
        else:
            # 0^n is undefined for n < 0
            raise Error("Zero cannot be raised to a negative power")

    if base.coefficient() == "1" and base.scale() == 0:
        # 1^n = 1 for any n
        print("Special case: 1^n = 1")
        return Decimal.ONE()

    # Handle negative exponents: x^(-n) = 1/(x^n)
    var negative_exponent = exp_value < 0
    if negative_exponent:
        exp_value = -exp_value
        print("Negative exponent, will compute 1/(x^|n|)")

    # Binary exponentiation for efficiency
    var result = Decimal.ONE()
    var current_base = base

    while exp_value > 0:
        if exp_value & 1:  # exp_value is odd
            result = result * current_base
            print("Intermediate result:", String(result))

        exp_value >>= 1  # exp_value = exp_value / 2

        if exp_value > 0:
            current_base = current_base * current_base
            print("Intermediate base:", String(current_base))

    # For negative exponents, take the reciprocal
    if negative_exponent:
        # For 1/x, use division
        print("Taking reciprocal for negative exponent")
        result = Decimal.ONE() / result

    print("Final result:", String(result))
    print("===== END POWER OPERATION DEBUG =====\n")

    return result


fn power(base: Decimal, exponent: Int) raises -> Decimal:
    """
    Convenience method to raise base to an integer power.

    Args:
        base: The base value.
        exponent: The integer power to raise base to.

    Returns:
        A new Decimal containing the result.
    """
    return power(base, Decimal(exponent))


fn pow(base: Decimal, exponent: Decimal) raises -> Decimal:
    """
    Alias for power() function. Raises base to the power of exponent.
    """
    return power(base, exponent)


fn pow(base: Decimal, exponent: Int) raises -> Decimal:
    """
    Alias for power() function. Raises base to an integer power.
    """
    return power(base, exponent)
