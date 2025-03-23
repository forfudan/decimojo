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

"""String manipulation functions."""

import time


fn parse_numeric_string(
    value: String,
) raises -> Tuple[List[UInt8], Int, Bool]:
    """Parse the string of a number into normalized parts.

    Args:
        value: The string representation of a number.

    Returns:
        A tuple of:
        - Normalized coefficient as List[UInt8] which represents an integer.
        - Scale of the number.
        - Sign of the number.

    Notes:

    Only the following characters are allowed in the input string:
    - Digits 0-9.
    - Decimal point ".". It can only appear once.
    - Negative sign "-". It can only appear before the first digit.
    - Positive sign "+". It can only appear before the first digit or after
        exponent "e" or "E".
    - Exponential notation "e" or "E". It can only appear once after the
        digits.
    - Space " ". It can appear anywhere in the string it is ignored.
    - Comma ",". It can appear anywhere between digits it is ignored.
    - Underscore "_". It can appear anywhere between digits it is ignored.

    Examples:
    ```console
    parse_string("123")             -> (123, 0, False)
    parse_string("123.456")         -> (123456, 3, False)
    parse_string("123.456e3")       -> (123456, 0, False)
    parse_string("123.456e-3")      -> (123456, 6, False)
    parse_string("123.456e+10")     -> (123456, -7, False)
    parse_string("0.00123456")      -> (123456, 8, False)
    parse_string("-123")            -> (123, 0, True)
    ```
    End of examples.
    """

    var value_string_slice = value.as_string_slice()
    var value_bytes = value_string_slice.as_bytes()
    var value_bytes_len = len(value_bytes)

    if value_bytes_len == 0:
        raise Error("Error in `parse_numeric_string`: Empty string.")

    if value_bytes_len != value_string_slice.char_length():
        raise Error(
            "There are invalid characters in the string of the number: {}"
            .format(value)
        )

    # Yuhao's notes:
    # We scan each char in the string input.
    var mantissa_sign_read = False
    var mantissa_start = False
    var mantissa_significant_start = False
    var decimal_point_read = False
    var exponent_notation_read = False
    var exponent_sign_read = False
    var exponent_start = False
    var unexpected_end_char = False

    var mantissa_sign: Bool = False  # True if negative
    var exponent_sign: Bool = False  # True if negative
    var coef: List[UInt8] = List[UInt8](capacity=value_bytes_len)
    var scale: Int = 0
    var raw_exponent: Int = 0

    for code_ptr in value_bytes:
        var code = code_ptr[]
        # If the char is " ", skip it
        if code == 32:
            pass
        # If the char is "," or "_", skip it
        elif code == 44 or code == 95:
            unexpected_end_char = True
        # If the char is "-"
        elif code == 45:
            unexpected_end_char = True
            if exponent_sign_read:
                raise Error("Minus sign cannot appear twice in exponent.")
            elif exponent_notation_read:
                exponent_sign = True
                exponent_sign_read = True
            elif mantissa_sign_read:
                raise Error("Minus sign can only appear once at the begining.")
            else:
                mantissa_sign = True
                mantissa_sign_read = True
        # If the char is "+"
        elif code == 43:
            unexpected_end_char = True
            if exponent_sign_read:
                raise Error("Plus sign cannot appear twice in exponent.")
            elif exponent_notation_read:
                exponent_sign_read = True
            elif mantissa_sign_read:
                raise Error("Plus sign can only appear once at the begining.")
            else:
                mantissa_sign_read = True
        # If the char is "."
        elif code == 46:
            unexpected_end_char = False
            if decimal_point_read:
                raise Error("Decimal point can only appear once.")
            else:
                decimal_point_read = True
                mantissa_sign_read = True
        # If the char is "e" or "E"
        elif code == 101 or code == 69:
            unexpected_end_char = True
            if exponent_notation_read:
                raise Error("Exponential notation can only appear once.")
            if not mantissa_start:
                raise Error("Exponential notation must follow a number.")
            else:
                exponent_notation_read = True

        # If the char is a digit 0
        elif code == 48:
            unexpected_end_char = False

            # Exponent part
            if exponent_notation_read:
                exponent_sign_read = True
                exponent_start = True
                raw_exponent = raw_exponent * 10

            # Mantissa part
            else:
                mantissa_sign_read = True
                mantissa_start = True

                if mantissa_significant_start:
                    coef.append(0)

                if decimal_point_read:
                    scale += 1

        # If the char is a digit 1 - 9
        elif code >= 49 and code <= 57:
            unexpected_end_char = False

            # Exponent part
            if exponent_notation_read:
                exponent_start = True
                raw_exponent = raw_exponent * 10 + Int(code - 48)

            # Mantissa part
            else:
                mantissa_significant_start = True
                mantissa_start = True
                coef.append(code - 48)
                if decimal_point_read:
                    scale += 1

        else:
            raise Error(
                "Invalid character in the string of the number: {}".format(
                    chr(Int(code))
                )
            )

    if unexpected_end_char:
        raise Error("Unexpected end character in the string of the number.")

    if len(coef) == 0:
        # For example, "0000."
        if mantissa_start:
            coef.append(0)
        else:
            raise Error("No digits found in the string of the number.")

    if raw_exponent != 0:
        if exponent_sign:
            # If exponent is negative, increase the scale
            scale += raw_exponent
        else:
            # If exponent is positive, decrease the scale
            # If scale is larger than exponent
            # 1.23456789e4 -> 12345.6789 -> 123456789 and scale = 4
            # If scale is smaller than exponent
            # 1.234e8 -> 1234e5 -> 1234 and scale = -5
            scale -= raw_exponent

    return Tuple(coef, scale, mantissa_sign)
