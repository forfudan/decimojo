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

from sys import exit

from argmojo import Arg, Command
from calculator.tokenizer import tokenize
from calculator.parser import parse_to_rpn
from calculator.evaluator import evaluate_rpn
from calculator.display import print_error


fn main():
    try:
        _run()
    except e:
        # Should not reach here — _run() handles all expected errors.
        # This is a last-resort safety net that still avoids the ugly
        # "Unhandled exception caught during execution:" message.
        print_error(String(e))
        exit(1)


fn _run() raises:
    var cmd = Command(
        "decimo",
        (
            "Arbitrary-precision CLI calculator powered by Decimo.\n"
            "\n"
            "Note: if your expression contains *, ( or ), your shell may\n"
            "intercept them before decimo runs. Use quotes or noglob:\n"
            '  decimo "2 * (3 + 4)"         # with quotes\n'
            "  noglob decimo 2*(3+4)        # with noglob\n"
            "  alias decimo='noglob decimo' # add to ~/.zshrc"
        ),
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

    # ── Phase 1: Tokenize & parse ──────────────────────────────────────────
    try:
        var tokens = tokenize(expr)
        var rpn = parse_to_rpn(tokens^)

        # ── Phase 2: Evaluate ────────────────────────────────────────────
        # Syntax was fine — any error here is a math error (division by
        # zero, negative sqrt, …).  No glob hint needed.
        try:
            var value = evaluate_rpn(rpn^, precision)

            if scientific:
                print(value.to_string(scientific=True, delimiter=delimiter))
            elif engineering:
                print(value.to_string(engineering=True, delimiter=delimiter))
            elif pad:
                print(
                    _pad_to_precision(
                        value.to_string(force_plain=True), precision
                    )
                )
            else:
                print(value.to_string(delimiter=delimiter))
        except eval_err:
            _display_calc_error(String(eval_err), expr)
            exit(1)

    except parse_err:
        _display_calc_error(String(parse_err), expr)
        exit(1)


fn _display_calc_error(error_msg: String, expr: String):
    """Parse a calculator error message and display it with colours
    and a caret indicator.

    The calculator engine produces errors in two forms:

    1. ``Error at position N: <description>``  — with position info.
    2. ``<description>``  — without position info.

    This function detects form (1), extracts the position, and calls
    `print_error(description, expr, position)` so the user sees a
    visual caret under the offending column.  For form (2) it falls
    back to a plain coloured error.
    """
    comptime PREFIX = "Error at position "

    if error_msg.startswith(PREFIX):
        # Find the colon after the position number.
        var after_prefix = len(PREFIX)
        var colon_pos = -1
        for i in range(after_prefix, len(error_msg)):
            if error_msg[byte=i] == ":":
                colon_pos = i
                break

        if colon_pos > after_prefix:
            # Extract position number and description.
            var pos_str = String(error_msg[after_prefix:colon_pos])
            var description = String(error_msg[colon_pos + 2 :])  # skip ": "

            try:
                var pos = Int(pos_str)
                print_error(description, expr, pos)
                return
            except:
                pass  # fall through to plain display

    # Fallback: no position info — just show the message.
    print_error(error_msg)


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
