# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements miscellaneous mathematical functions for the Decimal type
#
# ===----------------------------------------------------------------------=== #


fn absolute(x: Decimal) raises -> Decimal:
    """
    Returns the absolute value of a Decimal number.

    Args:
        x: The Decimal value to compute the absolute value of.

    Returns:
        A new Decimal containing the absolute value of x.
    """
    if x.is_negative():
        return -x
    return x
