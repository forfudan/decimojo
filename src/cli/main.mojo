# ===----------------------------------------------------------------------=== #
# Decimo CLI Calculator
#
# A native arbitrary-precision command-line calculator powered by
# Decimo (BigDecimal) and ArgMojo (CLI parsing).
#
# Usage:
#   mojo run -I src -I src/cli src/cli/main.mojo "100 * 12 - 23/17" -p 50
#   ./decimo "100 * 12 - 23/17" -p 50
# ===----------------------------------------------------------------------=== #

from argmojo import Arg, Command
from calculator import evaluate


fn main() raises:
    var cmd = Command(
        "decimo",
        "Arbitrary-precision CLI calculator powered by Decimo.",
        version="0.1.0",
    )

    # Positional: the math expression
    cmd.add_arg(
        Arg(
            "expr",
            help=(
                "Math expression to evaluate (e.g. 'sqrt(abs(1.1*-12-23/17))')"
            ),
        )
        .positional()
        .required()
    )

    # Named option: decimal precision
    cmd.add_arg(
        Arg("precision", help="Decimal precision for division (default: 50)")
        .long("precision")
        .short("p")
        .default("50")
    )

    # Output formatting flags
    cmd.add_arg(
        Arg("scientific", help="Output in scientific notation (e.g. 1.23E+10)")
        .long("scientific")
        .short("s")
        .flag()
    )
    cmd.add_arg(
        Arg(
            "engineering",
            help="Output in engineering notation (exponent multiple of 3)",
        )
        .long("engineering")
        .short("e")
        .flag()
    )
    cmd.add_arg(
        Arg(
            "pad",
            help="Pad trailing zeros to the specified precision",
        )
        .long("pad")
        .short("P")
        .flag()
    )

    var result = cmd.parse()
    var expr = result.get_string("expr")
    var precision = result.get_int("precision")
    var scientific = result.get_flag("scientific")
    var engineering = result.get_flag("engineering")
    var pad = result.get_flag("pad")

    var value = evaluate(expr, precision)

    if scientific:
        print(value.to_string(scientific_notation=True))
    elif engineering:
        print(_format_engineering(String(value)))
    elif pad:
        print(_pad_to_precision(String(value), precision))
    else:
        print(value)


fn _format_engineering(plain: String) -> String:
    """Format a plain decimal string in engineering notation.

    Engineering notation is like scientific notation, but the exponent
    is always a multiple of 3 (e.g. 1.23E+6, 123.456E-9).
    """
    # Handle sign
    var s = plain
    var sign = String("")
    if len(s) > 0 and s[byte=0] == "-":
        sign = "-"
        s = String(s[1:])

    # Separate integer and fractional parts
    var dot_pos = -1
    for i in range(len(s)):
        if s[byte=i] == ".":
            dot_pos = i
            break

    var integer_part: String
    var frac_part: String
    if dot_pos >= 0:
        integer_part = String(s[:dot_pos])
        frac_part = String(s[dot_pos + 1 :])
    else:
        integer_part = s
        frac_part = String("")

    # Build full digit string (without dot) and determine decimal position
    var digits = integer_part + frac_part
    var num_int_digits = len(integer_part)

    # Strip leading zeros to find effective position
    var first_nonzero = -1
    for i in range(len(digits)):
        if digits[byte=i] != "0":
            first_nonzero = i
            break

    if first_nonzero == -1:
        return "0"

    # adjusted exponent = position of first significant digit from left
    var exponent = num_int_digits - first_nonzero - 1

    # Adjust exponent to be a multiple of 3
    var eng_exp: Int
    if exponent >= 0:
        eng_exp = (exponent // 3) * 3
    else:
        eng_exp = -((-exponent + 2) // 3) * 3
    var lead_digits = exponent - eng_exp + 1  # digits before decimal point

    # Extract significant digits (from first_nonzero onward)
    var sig = String(digits[first_nonzero:])
    if len(sig) <= lead_digits:
        # No fractional part needed
        var result = sign + sig
        if eng_exp != 0:
            result += "E"
            if eng_exp > 0:
                result += "+"
            result += String(eng_exp)
        return result^
    else:
        var result = (
            sign + String(sig[:lead_digits]) + "." + String(sig[lead_digits:])
        )
        if eng_exp != 0:
            result += "E"
            if eng_exp > 0:
                result += "+"
            result += String(eng_exp)
        return result^


fn _pad_to_precision(plain: String, precision: Int) -> String:
    """Pad (or add) trailing zeros so the fractional part has exactly
    `precision` digits.
    """
    if precision <= 0:
        return plain

    var dot_pos = -1
    for i in range(len(plain)):
        if plain[byte=i] == ".":
            dot_pos = i
            break

    if dot_pos < 0:
        # No decimal point — add one with `precision` zeros
        return plain + "." + "0" * precision

    var frac_len = len(plain) - dot_pos - 1
    if frac_len >= precision:
        return plain

    return plain + "0" * (precision - frac_len)
