# Decimo CLI Calculator (`deci`)

> A native arbitrary-precision command-line calculator powered by Decimo and ArgMojo.

## Motivation

Decimo provides arbitrary-precision decimal arithmetic in Mojo, but currently lacks a quick way for users to interact with it outside of writing Mojo programs. A CLI calculator would:

- Serve as the primary demo/showcase for Decimo's capabilities.
- Provide a practical tool that outperforms `bc` (limited precision) and `python3 -c` (slow startup) for ad-hoc calculations.
- Act as a real-world integration test for both [Decimo](https://github.com/forfudan/decimo) and [ArgMojo](https://github.com/forfudan/argmojo).
- Compile to a single native binary with zero dependencies.

## Usage Design

The expression is passed as a single quoted string to avoid shell interpretation of `*`, `(`, `)`, etc. All other arguments are flags or options parsed by ArgMojo.

```bash
# Basic arithmetic
deci "100 * 12 - 23/17"
# → 1198.647058823529411764705882352941176470588235294118

# Control precision
deci "sqrt(2)" --precision 100
deci "1/3" -p 200

# Output formatting
deci "pi" --sci                    # Scientific notation
deci "1/7" --eng                   # Engineering notation
deci "1.5" --pad-to-precision      # Pad trailing zeros

# Functions
deci "ln(2) + exp(1)"
deci "sin(pi/4)"
deci "2 ^ 256"
deci "root(27, 3)"                 # Cube root

# Built-in constants
deci "pi" -p 1000
deci "e" -p 500

# Help
deci --help
deci --version
```

## Architecture

```txt
┌─────────────┐     ┌──────────┐     ┌────────────┐     ┌──────────┐     ┌──────────┐
│    Shell    │────▶│ ArgMojo  │────▶│ Tokenizer  │────▶│  Parser  │────▶│ Evaluator│
│   (argv)    │     │ (CLI)    │     │            │     │ (Shunt.) │     │(Decimo)│
└─────────────┘     └──────────┘     └────────────┘     └──────────┘     └──────────┘
       │                  │                │                  │                │
  "100*2+1"         extract expr      [100,*,2,+,1]    RPN: [100,2,*,1,+]  BigDecimal
  --precision 50    + flags/options                                          → "201"
```

### Layer 1: ArgMojo — CLI Argument Parsing

ArgMojo handles the outer CLI structure. No modifications to ArgMojo are needed.

```mojo
var cmd = Command("deci", "Arbitrary-precision CLI calculator.", version="0.1.0")
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

| Expression  | Decimo call                     |
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

### Phase 4 (Optional): Interactive REPL

1. Read-eval-print loop via stdin.
2. `ans` variable to reference the previous result.
3. Variable assignment: `x = sqrt(2)`.
4. History (if Mojo gets readline-like support).

```bash
deci -i
>>> 100 * 12
1200
>>> ans - 23/17
1198.647058823529411764705882352941176470588235294118
>>> x = sqrt(2)
1.41421356237309504880168872420969807856967187537694
>>> x ^ 2
2
```

## Notes

- The expression is always a single quoted string to prevent shell globbing and special character issues. This is the simplest and most robust approach.
- Division uses `true_divide` (not integer division) by default, matching calculator user expectations.
- Precision applies to intermediate computations as well (via `working_precision`), not just the final display.
