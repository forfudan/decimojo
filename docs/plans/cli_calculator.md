# Decimo CLI Calculator (`decimo`)

> A native arbitrary-precision command-line calculator powered by Decimo and ArgMojo.

## Motivation

Decimo provides arbitrary-precision decimal arithmetic in Mojo, but currently lacks a quick way for users to interact with it outside of writing Mojo programs. A CLI calculator would:

- Serve as the primary demo/showcase for Decimo's capabilities.
- Provide a practical tool that outperforms `bc` (limited precision) and `python3 -c` (slow startup) for ad-hoc calculations.
- Act as a real-world integration test for both [Decimo](https://github.com/forfudan/decimo) and [ArgMojo](https://github.com/forfudan/argmojo).
- Compile to a single native binary with zero dependencies.

## Feature Comparison

Rows are sorted by implementation priority for `decimo` (top = implement first).

| #   | Core feature               | decimo | bc  | dc  | qalc | calc (apcalc) | python3 -c | expr | octave-cli | Phase |
| --- | -------------------------- | ------ | --- | --- | ---- | ------------- | ---------- | ---- | ---------- | ----- |
| 1   | Basic arithmetic           | ✓      | ✓   | ✓   | ✓    | ✓             | ✓          | ✓    | ✓          | 1     |
| 2   | High-precision decimals    | ✓      | ✓   | ✓   | ✓    | ✓             | ✗          | ✗    | ✗          | 1     |
| 3   | Large integers (arbitrary) | ✓      | ✓   | ✓   | ✓    | ✓             | ✓          | ✗    | ✗          | 1     |
| 4   | Pipeline/Batch scripting   | ✓      | ✓   | ✓   | ✓    | ✓             | ✓          | ✓    | ✓          | 1     |
| 5   | Built-in math functions    | ✓      | ✓   | ✗   | ✓    | ✓             | ✓          | ✗    | ✓          | 2     |
| 6   | Interactive REPL           | ✓      | ✓   | ✓   | ✓    | ✓             | ✗          | ✗    | ✓          | 3     |
| 7   | Variables/State            | ✓      | ✓   | ✓   | ✓    | ✓             | ✓          | ✗    | ✓          | 3     |
| 8   | Unit conversion            | ✗      | ✗   | ✗   | ✓    | ✗             | ✗          | ✗    | ✗          | 4     |
| 9   | Matrix/Linear algebra      | ✗      | ✗   | ✗   | ✗    | ✓             | ✗          | ✗    | ✓          | 4     |
| 10  | Symbolic computation       | ✗      | ✗   | ✗   | △    | ✗             | ✗          | ✗    | ✗          | 4     |

**Priority rationale:**

1. **Basic arithmetic + High-precision + Large integers + Pipeline** (Phase 1) — These are the raison d'être of `decimo`. Decimo already provides arbitrary-precision `BigDecimal`; wiring up tokenizer → parser → evaluator gives immediate value. Pipeline/batch is nearly free once one-shot works (just loop over stdin lines).
2. **Built-in math functions** (Phase 2) — `sqrt`, `ln`, `exp`, `sin`, `cos`, `tan`, `root` already exist in the Decimo API. Adding them mostly means extending the tokenizer/parser to recognize function names.
3. **Interactive REPL + Variables/State** (Phase 3) — Valuable for exploration, but requires a read-eval-print loop, `ans` tracking, named variable storage and session-level precision management. More engineering effort, less urgency.
4. **Unit conversion / Matrix / Symbolic** (Phase 4) — Out of scope. `decimo` is a numerical calculator, not a CAS or unit library. These can be revisited if there is demand.

## Usage Design

`decimo` supports two modes of operation:

### Mode 1: One-Shot (Expression Mode)

Pass the expression as a single quoted string. This avoids shell interpretation of `*`, `(`, `)`, etc. All other arguments are flags or options parsed by ArgMojo.

```bash
# Basic arithmetic
decimo "100 * 12 - 23/17"
# → 1198.647058823529411764705882352941176470588235294118

# Control precision
decimo "sqrt(2)" --precision 100
decimo "1/3" -p 200

# Output formatting
decimo "pi" --sci                    # Scientific notation
decimo "1/7" --eng                   # Engineering notation
decimo "1.5" --pad-to-precision      # Pad trailing zeros

# Functions
decimo "ln(2) + exp(1)"
decimo "sin(pi/4)"
decimo "2 ^ 256"
decimo "root(27, 3)"                 # Cube root

# Built-in constants
decimo "pi" -p 1000
decimo "e" -p 500

# Help
decimo --help
decimo --version
```

Best for: quick one-off calculations from the command line.

### Mode 2: Pipe and File Input

Read expressions from stdin or a file — one expression per line, one result per line.

```bash
# Pipe a single expression
echo "1+2" | decimo
# → 3

# Pipe multiple expressions
printf "1/3\nsqrt(2)\npi" | decimo -p 50
# → 0.33333333333333333333333333333333333333333333333333
# → 1.4142135623730950488016887242096980785696718753769
# → 3.1415926535897932384626433832795028841971693993751

# Read from a file (one expression per line)
cat expressions.txt | decimo
decimo < expressions.txt

# Evaluate a script file (.dm)
decimo file.dm
```

Example `expressions.dm`:

```bash
# Compute some constants
pi
e
sqrt(2)

# Some arithmetic
100 * 12 - 23/17
2 ^ 256
```

Features:

- Lines starting with `#` are treated as comments and ignored.
- Blank lines are skipped.
- Each line is evaluated independently; results are printed one per line.
- Flags like `--precision` apply to all expressions.

Best for: scripting, piping, batch calculations, reproducible computation files.

### Mode 3: Interactive REPL

Run `decimo` with no expression (or with `-i`) to enter an interactive session. Type an expression, press Enter, get the result, and continue.

```bash
$ decimo
decimo> 1 + cos(3.43)
0.05738090582281618981744744369505543455
decimo> sqrt(2)
1.41421356237309504880168872420969807857
decimo> ans * 2
2.82842712474619009760337744841939615714
decimo> x = 100 / 7
14.28571428571428571428571428571428571429
decimo> x ^ 2
204.08163265306122448979591836734693877551
decimo> exit
```

Features:

- `ans` — automatically holds the previous result.
- Variable assignment — `x = <expr>` stores a named value for later use.
- Precision — set once with `decimo -p 100` or change mid-session with `:precision 100`.
- Quit — `exit`, `quit`, or Ctrl-D.

Best for: interactive exploration, multi-step calculations, experimenting with precision.

## Architecture

```txt
┌─────────────┐     ┌──────────┐     ┌────────────┐     ┌──────────┐     ┌──────────┐
│    Shell    │---->│ ArgMojo  │---->│ Tokenizer  │---->│  Parser  │---->│ Evaluator│
│   (argv)    │     │ (CLI)    │     │            │     │ (Shunt.) │     │ (Decimo) │
└─────────────┘     └──────────┘     └────────────┘     └──────────┘     └──────────┘
       │                  │                │                  │                │
  "100*2+1"         extract expr      [100,*,2,+,1]    RPN: [100,2,*,1,+]  BigDecimal
  --precision 50    + flags/options                                          → "201"
```

### Layer 1: ArgMojo — CLI Argument Parsing

ArgMojo handles the outer CLI structure. No modifications to ArgMojo are needed.

```mojo
var cmd = Command("decimo", "Arbitrary-precision CLI calculator.", version="0.1.0")
cmd.add_arg(Arg("expr", help="Math expression").positional().required())
cmd.add_arg(Arg("precision", help="Decimal precision").long("precision").short("p").default("50"))
cmd.add_arg(Arg("sci", help="Scientific notation").long("sci").flag())
cmd.add_arg(Arg("eng", help="Engineering notation").long("eng").flag())
cmd.add_arg(Arg("pad", help="Pad trailing zeros to precision").long("pad-to-precision").flag())
```

### Layer 2: Tokenizer — Lexical Analysis

Convert the expression string into a stream of tokens.

Token types:

- **Number**: integer or decimal literal (`123`, `3.14`, `.5`, `1e10`)
- **Operator**: `+`, `-`, `*`, `/`, `^` (or `**`)
- **Left paren / Right paren**: `(`, `)`
- **Function**: `sqrt`, `ln`, `log`, `exp`, `sin`, `cos`, `tan`, `root`, `abs`
- **Constant**: `pi`, `e`
- **Comma**: `,` (for multi-argument functions like `root(x, n)`)

Edge cases to handle:

- Unary minus: `-3`, `(-5+2)`, `2*-3`
- Implicit multiplication (future): `2pi`, `3(4+5)`

### Layer 3: Parser — Shunting-Yard Algorithm

Convert infix tokens to Reverse Polish Notation (RPN) using Dijkstra's shunting-yard algorithm.

Operator precedence and associativity:

| Precedence | Operators | Associativity |
| :--------: | --------- | :-----------: |
|  1 (low)   | `+`, `-`  |     Left      |
|     2      | `*`, `/`  |     Left      |
|     3      | `^`       |     Right     |
|  4 (high)  | unary `-` |     Right     |

Functions are pushed onto the operator stack and popped when their closing `)` is encountered.

### Layer 4: Evaluator — Decimo Computation

Walk the RPN queue with a `BigDecimal` stack:

- **Number token** → push `BigDecimal(token_str)` onto stack.
- **Constant token** → push precomputed value (e.g., `compute_pi(precision)`).
- **Binary operator** → pop two operands, compute, push result.
- **Unary operator** → pop one operand, compute, push result.
- **Function** → pop argument(s), call corresponding Decimo function, push result.

Mapping to Decimo API:

| Expression  | Decimo call                       |
| ----------- | --------------------------------- |
| `a + b`     | `a + b`                           |
| `a - b`     | `a - b`                           |
| `a * b`     | `a * b`                           |
| `a / b`     | `a.true_divide(b, precision)`     |
| `a ^ b`     | `power(a, b, precision)`          |
| `sqrt(a)`   | `sqrt(a, precision)`              |
| `root(a,n)` | `root(a, n, precision)`           |
| `ln(a)`     | `ln(a, precision)`                |
| `log(a)`    | `log10(a, precision)`             |
| `exp(a)`    | `exp(a, precision)`               |
| `sin(a)`    | `sin(a, precision)`               |
| `cos(a)`    | `cos(a, precision)`               |
| `tan(a)`    | `tan(a, precision)`               |
| `abs(a)`    | `abs(a)`                          |
| `pi`        | `compute_pi(precision)`           |
| `e`         | `exp(BigDecimal("1"), precision)` |

### Layer 5: Output Formatting

Format the final `BigDecimal` result based on CLI flags:

- Default: plain decimal string (strip trailing zeros).
- `--sci`: scientific notation (`1.23E+10`).
- `--eng`: engineering notation (exponent is multiple of 3).
- `--pad-to-precision`: keep trailing zeros up to the specified precision.

## Implementation Steps

### Phase 1: MVP — Four Operations

1. Set up project structure (new repo or subdirectory under Decimo).
2. Implement the tokenizer for numbers and `+ - * /` operators.
3. Implement the shunting-yard parser with parentheses support.
4. Implement the RPN evaluator using `BigDecimal`.
5. Wire up ArgMojo for `expr`, `--precision`, and `--help`.
6. Handle unary minus.
7. Test with basic expressions.

### Phase 2: Power and Functions

1. Add `^` operator with right associativity.
2. Add function call parsing (`sqrt(...)`, `ln(...)`, etc.).
3. Add multi-argument function support (`root(x, n)`).
4. Add built-in constants (`pi`, `e`).
5. Add output formatting flags (`--sci`, `--eng`, `--pad-to-precision`).

### Phase 3: Polish

1. Error messages: clear diagnostics for malformed expressions (e.g., "Unexpected token '*' at position 5").
2. Edge cases: division by zero, negative sqrt, overflow, empty expression.
3. Performance: ensure the tokenizer/parser overhead is negligible compared to BigDecimal computation.
4. Documentation and examples in README.
5. Build and distribute as a single binary.

### Phase 4: Interactive REPL

1. Read-eval-print loop: read a line from stdin, evaluate, print result, repeat.
2. Custom prompt (`decimo>`).
3. `ans` variable to reference the previous result.
4. Variable assignment: `x = sqrt(2)`, usable in subsequent expressions.
5. Session-level precision: settable via `decimo -p 100` at launch or `:precision 100` command mid-session.
6. Graceful exit: `exit`, `quit`, `Ctrl-D`.
7. Clear error messages without crashing the session (e.g., "Error: division by zero", then continue).
8. History (if Mojo gets readline-like support).

```bash
$ decimo
decimo> 100 * 12
1200
decimo> ans - 23/17
1198.647058823529411764705882352941176470588235294118
decimo> x = sqrt(2)
1.41421356237309504880168872420969807856967187537694
decimo> x ^ 2
2
decimo> 1/0
Error: division by zero
decimo> exit
```

### Phase 5: Future Enhancements

1. Detect full-width digits/operators for CJK users while parsing.

## Design Decisions

### All Numbers Are `BigDecimal`

All numeric literals and computation results are stored as `BigDecimal`, not integers. This means:

- `1 + 2` → `BigDecimal("3")`, displayed as `3` (no trailing `.0`).
- `1 / 3` → `BigDecimal` with full precision, not integer `0`.
- `2 ^ 256` → exact integer result stored as `BigDecimal` with scale 0.

This is the natural choice for a calculator: users expect `7 / 2` to be `3.5`, not `3`. Integer-only results are displayed without a decimal point (scale 0 values are printed as plain integers), so the experience is seamless.

### Mode Detection

`decimo` automatically detects its mode based on how it is invoked:

| Invocation                            | Mode                                  |
| ------------------------------------- | ------------------------------------- |
| `decimo "expr"`                       | One-shot: evaluate and exit           |
| `echo "expr" \| decimo`               | Pipe: read stdin line by line         |
| `decimo file.dm`                      | File: read and evaluate each line     |
| `decimo` (no args, terminal is a TTY) | REPL: interactive session             |
| `decimo -i`                           | REPL: force interactive even if piped |

## Notes

- In one-shot mode, the expression is a single quoted string to prevent shell globbing and special character issues.
- Division uses `true_divide` (not integer division) by default, matching calculator user expectations.
- Precision applies to intermediate computations as well (via `working_precision`), not just the final display.
- File and pipe modes evaluate each line independently. Use the REPL for stateful multi-line sessions with variables.
