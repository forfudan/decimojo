# DeciMojo

A fixed-point decimal arithmetic library implemented in [the Mojo programming language 🔥](https://www.modular.com/mojo).

## Overview

DeciMojo provides a Decimal type implementation for Mojo with fixed-precision arithmetic, designed to handle financial calculations and other scenarios where floating-point rounding errors are problematic.

Repo: [https://github.com/forFudan/DeciMojo](https://github.com/forFudan/DeciMojo)

## Objective

Financial calculations and data analysis require precise decimal arithmetic that floating-point numbers cannot reliably provide. As someone working in finance and credit risk model validation, I needed a dependable correctly-rounded, fixed-precision numeric type when migrating my personal projects from Python to Mojo.

Since Mojo currently lacks a native Decimal type in its standard library, I decided to create my own implementation to fill that gap.

This project draws inspiration from several established decimal implementations and documentation, e.g., [Python built-in `Decimal` type](https://docs.python.org/3/library/decimal.html), [Rust `rust_decimal` crate](https://docs.rs/rust_decimal/latest/rust_decimal/index.html), [Microsoft's `Decimal` implementation](https://learn.microsoft.com/en-us/dotnet/api/system.decimal.getbits?view=net-9.0&redirectedfrom=MSDN#System_Decimal_GetBits_System_Decimal_), [General Decimal Arithmetic Specification](https://speleotrove.com/decimal/decarith.html), etc. Many thanks to these predecessors for their contributions and their commitment to open knowledge sharing.

## Nomenclature

DeciMojo combines "Decimal" and "Mojo" - reflecting both its purpose (decimal arithmetic) and the programming language it's implemented in. The name emphasizes the project's focus on bringing precise decimal calculations to the Mojo ecosystem.

For brevity, you can refer to it as "deci" (derived from the Latin root "decimus" meaning "tenth").

When you add `from decimojo.prelude import *` at the top of your script, this imports the `decimojo` module into your namespace with the shorter alias `dm` and directly imports the `Decimal` type. This is equivalent to:

```mojo
import decimojo
import decimojo as dm
from decimojo import Decimal
```

## Advantages

DeciMojo provides exceptional computational precision without sacrificing performance. It maintains accuracy throughout complex calculations where floating-point or other decimal implementations might introduce subtle errors.

Consider the square root of `15.9999`. When comparing DeciMojo's implementation with Python's decimal module (both rounded to 16 decimal places):

- DeciMojo calculates: `3.9999874999804687`
- Python's decimal returns: `3.9999874999804685`

The mathematically correct value (to 50+ digits) is:
`3.9999874999804686889646053303778122644631365491812...`

When rounded to 16 decimal places, the correct result is `3.9999874999804687`, confirming that DeciMojo produces the more accurate result in this case.

```log
Function:                   sqrt()
Decimal value:              15.9999
DeciMojo result:            3.9999874999804686889646053305
Python's decimal result:    3.9999874999804685
```

This precision advantage becomes increasingly important in financial, scientific, and engineering calculations where small rounding errors can compound into significant discrepancies.

## Status

Rome wasn't built in a day. DeciMojo is currently under active development, positioned between the **"make it work"** and **"make it right"** phases, with a stronger emphasis on the latter. Bug reports and feature requests are welcome! If you encounter issues, please [file them here](https://github.com/forFudan/decimojo/issues).

### Make it Work ✅ (MOSTLY COMPLETED)

- Core decimal implementation exists and functions
- Basic arithmetic operations (+, -, *, /) are implemented
- Type conversions to/from various formats work
- String representation and parsing are functional
- Construction from different sources (strings, numbers) is supported

### Make it Right 🔄 (IN PROGRESS)

- Edge case handling is being addressed (division by zero, zero to negative power)
- Scale and precision management shows sophistication
- Financial calculations demonstrate proper rounding
- High precision support is implemented (up to 28 decimal places)
- The examples show robust handling of various scenarios

### Make it Fast ⏳ (IN PROGRESS & FUTURE WORK)

- Performance optimization on basic operations (+ - * /) is mostly finished ([PR#16](https://github.com/forFudan/DeciMojo/pull/16), [PR#20](https://github.com/forFudan/DeciMojo/pull/20), [PR#21](https://github.com/forFudan/DeciMojo/pull/21)).
- Regular benchmarking against Python's `decimal` module (see `bench/` folder)
- Performance optimization on other functions are acknowleged but not currently prioritized

## Examples

The `Decimal` type can represent values with up to 29 significant digits and a maximum of 28 digits after the decimal point. When a value exceeds the maximum representable value (`2^96 - 1`), DeciMojo either raises an error or rounds the value to fit within these constraints. For example, the significant digits of `8.8888888888888888888888888888` (29 eights total with 28 after the decimal point) exceeds the maximum representable value (`2^96 - 1`) and is automatically rounded to `8.888888888888888888888888888` (28 eights total with 27 after the decimal point).

Here are 8 key examples highlighting the most important features of the `Decimal` type in its current state:

### 1. Fixed-Point Precision for Financial Calculations

```mojo
from decimojo.prelude import *

# The classic floating-point problem
print(0.1 + 0.2)  # 0.30000000000000004 (not exactly 0.3)

# Decimal solves this with exact representation
var d1 = Decimal("0.1")
var d2 = Decimal("0.2")
var sum = d1 + d2
print(sum)  # Exactly 0.3

# Financial calculation example - computing tax
var price = Decimal("19.99")
var tax_rate = Decimal("0.0725")
var tax = price * tax_rate  # Exactly 1.449275
var total = price + tax     # Exactly 21.439275
```

### 2. Basic Arithmetic with Proper Banker's Rounding

```mojo
# Addition with different scales
var a = Decimal("123.45")
var b = Decimal("67.8")
print(a + b)  # 191.25 (preserves highest precision)

# Subtraction with negative result
var c = Decimal("50")
var d = Decimal("75.25")
print(c - d)  # -25.25

# Multiplication with banker's rounding (round to even)
var e = Decimal("12.345")
var f = Decimal("5.67")
print(round(e * f, 2))  # 69.96 (rounds to nearest even)

# Division with banker's rounding
var g = Decimal("10")
var h = Decimal("3")
print(round(g / h, 2))  # 3.33 (rounded banker's style)
```

### 3. Scale and Precision Management

```mojo
# Scale refers to number of decimal places
var d1 = Decimal("123.45")
print(d1.scale())  # 2

# Precision control with explicit rounding
var d2 = Decimal("123.456")
print(d2.round_to_scale(1))  # 123.5 (banker's rounding)

# High precision is preserved (up to 28 decimal places)
var precise = Decimal("0.1234567890123456789012345678")
print(precise)  # 0.1234567890123456789012345678

# Truncation to specific number of digits
var large_num = Decimal("123456.789")
print(truncate_to_digits(large_num, 4))  # 1235 (banker's rounded)
```

### 4. Sign Handling and Absolute Value

```mojo
# Negation operator
var pos = Decimal("123.45")
var neg = -pos
print(neg)  # -123.45

# Absolute value
var abs_val = abs(Decimal("-987.65"))
print(abs_val)  # 987.65

# Sign checking
print(Decimal("-123.45").is_negative())  # True
print(Decimal("0").is_negative())        # False

# Sign preservation in multiplication
print(Decimal("-5") * Decimal("3"))      # -15 
print(Decimal("-5") * Decimal("-3"))     # 15
```

### 5. Advanced Mathematical Operations

```mojo
from decimojo.mathematics import sqrt

# Highly accurate square root implementation
var root2 = sqrt(Decimal("2"))
print(root2)  # 1.4142135623730950488016887242...

# Square root of imperfect squares
var root_15_9999 = sqrt(Decimal("15.9999"))
print(root_15_9999)  # 3.9999874999804686889646053305...

# Integer powers with fast binary exponentiation
var cubed = Decimal("3") ** 3
print(cubed)  # 27

# Negative powers (reciprocals)
var recip = Decimal("2") ** (-1)
print(recip)  # 0.5
```

### 6. Robust Edge Case Handling

```mojo
# Division by zero is properly caught
try:
    var result = Decimal("10") / Decimal("0")
except:
    print("Division by zero properly detected")

# Zero raised to negative power
try:
    var invalid = Decimal("0") ** (-1)
except:
    print("Zero to negative power properly detected")
    
# Overflow detection and prevention
var max_val = Decimal.MAX()
try:
    var overflow = max_val * Decimal("2")
except:
    print("Overflow correctly detected")
```

### 7. Equality and Comparison Operations

```mojo
# Equal values with different scales
var a = Decimal("123.4500")
var b = Decimal("123.45")
print(a == b)  # True (numeric value equality)

# Comparison operators
var c = Decimal("100")
var d = Decimal("200")
print(c < d)   # True
print(c <= d)  # True
print(c > d)   # False
print(c >= d)  # False
print(c != d)  # True
```

### 8. Real World Financial Examples

```mojo
# Monthly loan payment calculation with precise interest
var principal = Decimal("200000")  # $200,000 loan
var annual_rate = Decimal("0.05")  # 5% interest rate
var monthly_rate = annual_rate / Decimal("12")
var num_payments = Decimal("360")  # 30 years

# Monthly payment formula: P * r(1+r)^n/((1+r)^n-1)
var numerator = monthly_rate * (Decimal("1") + monthly_rate) ** 360
var denominator = (Decimal("1") + monthly_rate) ** 360 - Decimal("1")
var payment = principal * (numerator / denominator)
print("Monthly payment: $" + String(round(payment, 2)))  # $1,073.64
```

## Tests and benches

After cloning the repo onto your local disk, you can:

- Use `magic run test` (or `maigic run t`) to run tests.
- Use `magic run bench` (or `magic run b`) to generate logs for benchmarking tests agains `python.decimal` module. The log files are saved in `benches/logs/`.

## Citation

If you find DeciMojo useful for your research, consider listing it in your citations 😀.

```tex
@software{Zhu.2025,
    author       = {Zhu, Yuhao},
    year         = {2025},
    title        = {DeciMojo: A fixed-point decimal arithmetic library in Mojo},
    url          = {https://github.com/forFudan/DeciMojo},
    version      = {0.1.0},
    note         = {Computer Software}
}
```

## License

Copyright 2025 Yuhao Zhu

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
