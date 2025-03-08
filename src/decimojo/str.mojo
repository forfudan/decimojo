# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimojo/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #
#
# Implements string manipulation functions for the Decimal type
#
# ===----------------------------------------------------------------------=== #


fn _float_to_decimal_str(value: Float64, precision: Int) -> String:
    """
    Converts float to string with specified precision.
    Properly handles negative values.
    """
    # Handle sign separately
    var is_negative = value < 0
    var abs_value = abs(value)

    # Extract integer and fractional parts from absolute value
    var int_part = Int64(abs_value)
    var frac_part = abs_value - Float64(int_part)

    # Convert integer part to string
    var result = String(int_part)

    # Handle fractional part if needed
    if frac_part > 0:
        result += "."

        # Extract decimal digits one by one
        for _ in range(precision):
            frac_part *= 10
            var digit = Int8(frac_part)
            result += String(digit)
            frac_part -= Float64(digit)

    # Add negative sign if needed
    if is_negative:
        result = "-" + result

    return result


fn _remove_leading_zeros(value: String) -> String:
    """Removes leading zeros from a string."""
    var start_idx = 0
    while start_idx < len(value) - 1 and value[start_idx] == "0":
        start_idx += 1

    return value[start_idx:]


fn _remove_trailing_zeros(value: String) -> String:
    """Removes trailing zeros from a string."""
    var end_idx = len(value)
    while end_idx > 0 and value[end_idx - 1] == "0":
        end_idx -= 1

    return value[:end_idx]
