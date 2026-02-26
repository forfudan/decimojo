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
        Arg("expr", help="Math expression to evaluate (e.g. '100*12-23/17')")
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

    var result = cmd.parse()
    var expr = result.get_string("expr")
    var precision = result.get_int("precision")

    print(evaluate(expr, precision))
