# DeciMojo

A correctly-rounded, fixed-point decimal arithmetic library for the [Mojo programming language 🔥](https://www.modular.com/mojo).

## Overview

DeciMojo provides a Decimal type implementation for Mojo with fixed-precision arithmetic, designed to handle financial calculations and other scenarios where floating-point rounding errors are problematic.

## Objective

Financial calculations and data analysis require precise decimal arithmetic that floating-point numbers cannot reliably provide. As someone working in finance and credit risk model validation, I needed a dependable fixed-precision numeric type when migrating my personal projects from Python to Mojo.

Since Mojo currently lacks a native Decimal type in its standard library, I decided to create my own implementation to fill that gap.

This project draws inspiration from several established decimal implementations and documentation, e.g., [Python built-in `Decimal` type](https://docs.python.org/3/library/decimal.html), [Rust `rust_decimal` crate](https://docs.rs/rust_decimal/latest/rust_decimal/index.html), [Microsoft's `Decimal` implementation](https://learn.microsoft.com/en-us/dotnet/api/system.decimal.getbits?view=net-9.0&redirectedfrom=MSDN#System_Decimal_GetBits_System_Decimal_), [General Decimal Arithmetic Specification](https://speleotrove.com/decimal/decarith.html), etc. Many thanks to these predecessors for their contributions and their commitment to open knowledge sharing.

## Issues

Rome is not built in one day. DeciMojo is currently under active development. Contributions, bug reports, and feature requests are welcome! If you encounter issues, please [file them here](https://github.com/forFudan/decimojo/issues).

## Examples

Here presents 10 key examples of how to use the `Decimal` type with the most common operations.

### 1. Creating Decimals from Strings

```mojo
from decimojo import Decimal

# Creating decimals from various string formats
var d1 = Decimal("123.45")           # Regular decimal
var d2 = Decimal("-67.89")           # Negative decimal
var d3 = Decimal("1.23e5")           # Scientific notation (123000)
var d4 = Decimal("1_000_000.00")     # Readable format with underscores
```

### 2. Basic Arithmetic Operations

```mojo
# Addition
var sum = Decimal("123.45") + Decimal("67.89")  # 191.34

# Subtraction
var diff = Decimal("123.45") - Decimal("67.89")  # 55.56

# Multiplication
var prod = Decimal("12.34") * Decimal("5.67")  # 69.9678

# Negation
var neg = -Decimal("123.45")  # -123.45
```

### 3. Rounding with Different Modes

```mojo
from decimojo import Decimal
from decimojo.rounding_mode import RoundingMode

var num = Decimal("123.456789")

# Using different rounding modes (at 2 decimal places)
var default_round = num.round(2)                      # 123.46 (HALF_EVEN)
var down = num.round(2, RoundingMode.DOWN())          # 123.45
var up = num.round(2, RoundingMode.UP())              # 123.46
var half_up = num.round(2, RoundingMode.HALF_UP())    # 123.46
```

### 4. Working with Scale

```mojo
var d = Decimal("123.45")        # Scale is 2
print(d.scale())                 # Prints: 2

# Changing scale through rounding
var more_precise = d.round(4)    # 123.4500
print(more_precise.scale())      # Prints: 4

var less_precise = d.round(1)    # 123.4 (Banker's round)
print(less_precise.scale())      # Prints: 1
```

### 5. Zero and Special Values

```mojo
# Different ways to represent zero
var z1 = Decimal("0")                # 0
var z2 = Decimal("0.00")             # 0.00
print(z1.is_zero(), z2.is_zero())    # Both print: True

# Special values
var max_val = Decimal.MAX()          # 79228162514264337593543950335
var min_val = Decimal.MIN()          # -79228162514264337593543950335
var one = Decimal.ONE()              # 1
```

### 6. Handling Very Small and Large Numbers

```mojo
# Very small number (1 at 28th decimal place)
var small = Decimal("0." + "0" * 27 + "1")
print(small)  # 0.0000000000000000000000000001

# Large number close to max
var large = Decimal("79228162514264337593543950334")  # MAX() - 1
print(large)  # 79228162514264337593543950334
```

### 7. Creating from Integer and Float

```mojo
# From integer
var d1 = Decimal(123)                # 123

# From float
var d2 = Decimal(123.45)             # Approximately 123.45
var d3 = Decimal(123.45, max_precision=True)  # Maximum precision conversion
```

### 8. Examining Internal Representation

```mojo
var d = Decimal("123.456")

# Get internal components
print("Value:", d)                  # 123.456
print("Coefficient:", d.coefficient())  # 123456 (without scale/sign)
print("Scale:", d.scale())          # 3
print("Is negative:", d.is_negative())  # False
```

### 9. Addition with Different Scales

```mojo
var a = Decimal("123.4")     # Scale 1
var b = Decimal("67.89")     # Scale 2
var result = a + b
print(result)                # 191.29
print(result.scale())        # Scale 2 (takes the larger scale)
```

### 10. Error Handling with Overflow

```mojo
try:
    # This should cause overflow as it exceeds maximum value
    var max_value = Decimal.MAX()
    var overflow_attempt = max_value + Decimal("1")
    print("This shouldn't print")
except:
    print("Correctly detected overflow")
```

## Related Projects

I am also working on NuMojo, a library for numerical computing in Mojo 🔥 similar to NumPy, SciPy in Python. If you are also interested, you can [check it out here](https://github.com/Mojo-Numerics-and-Algorithms-group/NuMojo).

## License

Distributed under the Apache 2.0 License. See [LICENSE](https://github.com/forFudan/decimojo/blob/main/LICENSE) for details.

## Acknowledgements

Built with the [Mojo programming language 🔥](https://www.modular.com/mojo) created by [Modular](https://www.modular.com/).
