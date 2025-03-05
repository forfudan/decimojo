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

Here are 10 key examples of how to use the `Decimal` type with the most important features.

### 1. Creating Decimals

```mojo
from decimojo.prelude import *

# From string with various formats
var d1 = Decimal("123.45")           # Regular decimal
var d2 = Decimal("-67.89")           # Negative decimal
var d3 = Decimal("1.23e5")           # Scientific notation (123000)
var d4 = Decimal("1_000_000.00")     # Readable format with underscores

# From integers and floats
var d5 = Decimal(123)                # Integer
var d6 = Decimal(123.45)             # Float (approximate)

# Special values
var max_val = Decimal.MAX()          # 79228162514264337593543950335
var min_val = Decimal.MIN()          # -79228162514264337593543950335
var zero = Decimal.ZERO()            # 0
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

# Absolute value
var abs_val = abs(Decimal("-123.45"))  # 123.45
```

### 3. Exponentiation (Power Functions)

```mojo
# Integer exponents
var squared = Decimal("2.5") ** 2    # 6.25
var cubed = Decimal("2") ** 3        # 8
var tenth_power = Decimal("2") ** 10  # 1024

# Negative exponents
var reciprocal = Decimal("2") ** (-1)    # 0.5
var inverse_square = Decimal("2") ** (-2)  # 0.25

# Special cases
var anything_power_zero = Decimal("123.45") ** 0  # 1
var one_power_anything = Decimal("1") ** 100      # 1
var zero_power_positive = Decimal("0") ** 5       # 0
```

### 4. Type Conversions

```mojo
var d = Decimal("123.456")

# String conversion
var str_val = String(d)  # "123.456"

# Integer conversion (truncates toward zero)
var int_val = Int(d)  # 123

# Float conversion
var float_val = Float64(d)  # 123.456

# Check if value can be represented as an integer
var is_int = d.is_integer()  # False
var whole_num = Decimal("100.000")
var is_whole = whole_num.is_integer()  # True
```

### 5. Working with Scale and Precision

```mojo
var d = Decimal("123.45")
var scale_val = d.scale()  # 2 (number of decimal places)

# Operations respect and combine scales appropriately
var a = Decimal("123.45")         # Scale 2
var b = Decimal("67.890")         # Scale 3
var addition = a + b              # Scale 3 (the larger scale)
var multiplication = a * b        # Scale 5 (sum of scales)

# Very high precision values are supported
var high_precision = Decimal("0.123456789012345678901234567")  # 27 decimal places
```

### 6. Edge Cases Handling

```mojo
# Division by zero is detected
try:
    var undefined = Decimal("1") / Decimal("0")
    print("This won't print")
except:
    print("Division by zero detected")

# Overflow is detected
try:
    var max_val = Decimal.MAX()
    var overflow = max_val + Decimal("1")
    print("This won't print")
except:
    print("Overflow detected")

# Zero handling
var zero = Decimal("0")
var is_zero = zero.is_zero()  # True
var zero_with_scale = Decimal("0.00000")
var also_zero = zero_with_scale.is_zero()  # True
```

### 7. Working with Very Small and Large Numbers

```mojo
# Very small number (maximum precision)
var small = Decimal("0." + "0" * 27 + "1")  # 0.0000000000000000000000000001

# Very large number
var large = Decimal("79228162514264337593543950334")  # Near maximum value

# Operations with extreme values
var very_small_sum = small + small  # 0.0000000000000000000000000002
var small_product = small * small   # Might result in underflow to zero due to precision limits
```

### 8. Negative Numbers

```mojo
# Creating negative numbers
var neg1 = Decimal("-123.45")
var neg2 = -Decimal("123.45")  # Same as above

# Sign operations
var is_negative = neg1.is_negative()  # True
var abs_value = abs(neg1)            # 123.45
var negate_again = -neg1             # 123.45

# Arithmetic with mixed signs
var prod_neg_pos = neg1 * Decimal("2")   # -246.90
var prod_neg_neg = neg1 * neg2          # 15240.0025 (positive result)
```

### 9. Equality and Comparison

```mojo
var a = Decimal("123.45")
var b = Decimal("123.450")  # Same value but different scale

# Equality checks the numeric value, not the representation
var equal = (a == b)  # True

# Self-comparisons
var self_equal = (a == a)  # Always True

# Zero comparisons with different scales
var zero1 = Decimal("0")
var zero2 = Decimal("0.000")
var zeros_equal = (zero1 == zero2)  # True
```

### 10. Mathematics Functions

```mojo
from decimojo.mathematics import sqrt

# Square root
var root = sqrt(Decimal("16"))  # 4

# Rounding to specific decimal places
var rounded = round(Decimal("123.456"), 2)  # 123.46

# Absolute value (two equivalent ways)
var abs1 = abs(Decimal("-123.45"))  # 123.45
var abs2 = abs(Decimal("-123.45"))       # 123.45

# Calculating with arbitrary precision
var precise_div = Decimal("1") / Decimal("7")  # 0.1428571428571428571428571429
var precise_sqrt = sqrt(Decimal("2"))          # 1.414213562373095048801688724
```

## Related Projects

I am also working on NuMojo, a library for numerical computing in Mojo 🔥 similar to NumPy, SciPy in Python. If you are also interested, you can [check it out here](https://github.com/Mojo-Numerics-and-Algorithms-group/NuMojo).

## License

Distributed under the Apache 2.0 License. See [LICENSE](https://github.com/forFudan/decimojo/blob/main/LICENSE) for details.

## Acknowledgements

Built with the [Mojo programming language 🔥](https://www.modular.com/mojo) created by [Modular](https://www.modular.com/).
