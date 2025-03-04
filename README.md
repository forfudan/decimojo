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

### 1. Creating Decimals

```mojo
from decimojo import Decimal

# From string with various formats
var d1 = Decimal("123.45")           # Regular decimal
var d2 = Decimal("-67.89")           # Negative decimal
var d3 = Decimal("1.23e5")           # Scientific notation (123000)
var d4 = Decimal("1_000_000.00")     # Readable format with underscores

# From integers and floats
var d5 = Decimal(123)                # Integer
var d6 = Decimal(123.45)             # Float (approximate)
var d7 = Decimal(123.45, max_precision=True)  # Float with maximum precision

# From components
var d8 = Decimal(12345, 0, 0, False, 2)  # 123.45 (coefficient 12345, scale 2)
var d9 = Decimal(12345, 0, 0, True, 2)   # -123.45 (negative flag set)
```

### 2. Basic Arithmetic Operations

```mojo
# Addition
var sum = Decimal("123.45") + Decimal("67.89")  # 191.34

# Subtraction
var diff = Decimal("123.45") - Decimal("67.89")  # 55.56

# Multiplication
var prod = Decimal("12.34") * Decimal("5.67")  # 69.9678

# Division
var quot = Decimal("123.45") / Decimal("2.5")  # 49.38

# Negation
var neg = -Decimal("123.45")  # -123.45

# Power (exponentiation)
var squared = Decimal("2.5") ** 2  # 6.25
var cubed = Decimal("2") ** 3     # 8
var reciprocal = Decimal("2") ** (-1)  # 0.5
```

### 3. Rounding with Different Modes

```mojo
from decimojo import Decimal
from decimojo.rounding_mode import RoundingMode
from decimojo.mathematics import round

var num = Decimal("123.456789")

# Round to various decimal places with different modes
var default_round = round(num, 2)                      # 123.46 (HALF_EVEN)
var down = round(num, 2, RoundingMode.DOWN())          # 123.45 (truncate)
var up = round(num, 2, RoundingMode.UP())              # 123.46 (away from zero)
var half_up = round(num, 2, RoundingMode.HALF_UP())    # 123.46 (≥0.5 rounds up)

# Rounding special cases
var half_value = round(Decimal("123.5"), 0)  # 124 (banker's rounding)
var half_odd = round(Decimal("124.5"), 0)    # 124 (banker's rounding to even)
```

### 4. Working with Scale and Precision

```mojo
var d = Decimal("123.45")        # Scale is 2
print(d.scale())                 # Prints: 2

# Changing scale through rounding
var more_precise = round(d, 4)    # 123.4500
print(more_precise.scale())      # Prints: 4

var less_precise = round(d, 1)    # 123.5 (rounds up)
print(less_precise.scale())      # Prints: 1

# Scale after operations
var a = Decimal("123.45")         # Scale 2
var b = Decimal("67.890")         # Scale 3
print((a + b).scale())            # Prints: 3 (takes the larger scale)
print((a * b).scale())            # Scale becomes 5 (sum of scales)
```

### 5. Zero and Special Values

```mojo
# Different ways to represent zero
var z1 = Decimal("0")                # 0
var z2 = Decimal("0.00")             # 0.00
print(z1.is_zero(), z2.is_zero())    # Both print: True

# Special values from static methods
var max_val = Decimal.MAX()          # 79228162514264337593543950335
var min_val = Decimal.MIN()          # -79228162514264337593543950335
var one = Decimal.ONE()              # 1
var neg_one = Decimal.NEGATIVE_ONE() # -1
var zero = Decimal.ZERO()            # 0
```

### 6. Handling Very Small and Large Numbers

```mojo
# Very small number (1 at 28th decimal place - maximum precision)
var small = Decimal("0." + "0" * 27 + "1")
print(small)  # 0.0000000000000000000000000001

# Large number close to max
var large = Decimal("79228162514264337593543950334")  # MAX() - 1
print(large)  # 79228162514264337593543950334

# Calculations with extreme values
var small_squared = small ** 2  # Even smaller number

# Division resulting in long repeating decimal
var repeating = Decimal("1") / Decimal("3")  # 0.333333... (up to max precision)
print(repeating)  # 0.3333333333333333333333333333
```

### 7. Type Conversions

```mojo
var d = Decimal("123.456")

# String representation
var str_val = String(d)  # "123.456"

# Integer conversion (throws error if has fractional part)
try:
    var int_val = Int(d)  # Error: has non-zero fractional part
    print("This won't print")
except:
    print("Cannot convert to Int with non-zero fraction")

# Integer conversion for whole number with decimal places
var whole = Decimal("100.000")
var int_whole = Int(whole)  # 100 (works because fractional part is zero)
```

### 8. Working with Integer Checking

```mojo
# Check if a Decimal represents an integer (even if it has decimal places)
var d1 = Decimal("123")      # Scale 0
var d2 = Decimal("123.0")    # Scale 1
var d3 = Decimal("123.456")  # Scale 3

print(d1.is_integer())  # True
print(d2.is_integer())  # True - all fractional digits are 0
print(d3.is_integer())  # False - has non-zero fractional digits
```

### 9. Error Handling

```mojo
# Handle division by zero
try:
    var result = Decimal("123.45") / Decimal("0") 
    print("This won't print")
except:
    print("Correctly caught division by zero")

# Handle overflow
try:
    var max_value = Decimal.MAX()
    var overflow_attempt = max_value + Decimal("1")
    print("This won't print")
except:
    print("Correctly caught overflow")

# Handle invalid power operation
try:
    var zero_neg_power = Decimal("0") ** (-1)
    print("This won't print")
except:
    print("Correctly caught zero raised to negative power")
```

### 10. Mathematics Module

```mojo
from decimojo import Decimal
from decimojo.mathematics import power

# Two equivalent ways to compute powers
var result1 = Decimal("2.5") ** 2
var result2 = power(Decimal("2.5"), 2)

print(String(result1) == String(result2))  # True

# More complex power operations
var cube = power(Decimal("2"), 3)   # 8
var reciprocal = power(Decimal("2"), -1)  # 0.5

# Can also pass a Decimal exponent (must be an integer value)
var exp_as_decimal = Decimal("3")
var cubed = power(Decimal("2"), exp_as_decimal)  # 8
```

## Related Projects

I am also working on NuMojo, a library for numerical computing in Mojo 🔥 similar to NumPy, SciPy in Python. If you are also interested, you can [check it out here](https://github.com/Mojo-Numerics-and-Algorithms-group/NuMojo).

## License

Distributed under the Apache 2.0 License. See [LICENSE](https://github.com/forFudan/decimojo/blob/main/LICENSE) for details.

## Acknowledgements

Built with the [Mojo programming language 🔥](https://www.modular.com/mojo) created by [Modular](https://www.modular.com/).
