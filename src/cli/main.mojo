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
    # Mutually exclusive: scientific, engineering
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
    cmd.mutually_exclusive(["scientific", "engineering"])
    cmd.add_arg(
        Arg(
            "pad",
            help="Pad trailing zeros to the specified precision",
        )
        .long("pad")
        .short("P")
        .flag()
    )
    cmd.add_arg(
        Arg(
            "delimiter",
            help=(
                "Digit-group separator inserted every 3 digits"
                " (e.g. '_' gives 1_234.567_89)"
            ),
        )
        .long("delimiter")
        .short("d")
        .default("")
    )

    var result = cmd.parse()
    var expr = result.get_string("expr")
    var precision = result.get_int("precision")
    var scientific = result.get_flag("scientific")
    var engineering = result.get_flag("engineering")
    var pad = result.get_flag("pad")
    var delimiter = result.get_string("delimiter")

    var value = evaluate(expr, precision)

    if scientific:
        print(value.to_string(scientific=True, delimiter=delimiter))
    elif engineering:
        print(value.to_string(engineering=True, delimiter=delimiter))
    elif pad:
        print(_pad_to_precision(value.to_string(force_plain=True), precision))
    else:
        print(value.to_string(delimiter=delimiter))


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
