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

Here are 10 key examples demonstrating the current functionality of the `Decimal` type.

### 1. Creating and Displaying Decimals

```mojo
from decimojo import Decimal

# From string literals with various formats
var d1 = Decimal("123.45")           # Regular decimal
var d2 = Decimal("-67.89")           # Negative decimal
var d3 = Decimal("0.0012345678901234567890123456")  # High precision decimal

# String representation 
print(d1)                # Displays: 123.45
print(repr(d1))          # Display internal representation

# From numeric types
var d4 = Decimal(123)    # From integer
var d5 = Decimal(123.45) # From float (approximation)
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

# Division with repeating decimal
var repeating = Decimal("1") / Decimal("3")  # 0.3333333333333333333333333333
```

### 3. Sign Operations

```mojo
# Negation
var a = Decimal("123.45")
var neg_a = -a           # -123.45

# Double negation
var pos_a = -(-a)        # 123.45

# Absolute value
var b = Decimal("-67.89")
var abs_b = abs(b)       # 67.89

# Sign checking
var is_neg = b.is_negative()  # True
var is_pos = a.is_negative()  # False
```

### 4. Type Conversions

```mojo
var d = Decimal("123.456")

# String conversion
var str_val = String(d)  # "123.456"

# Integer conversion
var int_val = Int(d)     # 123 (truncates toward zero)
var neg_int = Int(Decimal("-123.456"))  # -123

# Float conversion
var float_val = Float64(d)  # 123.456

# Zero checking
var is_zero = Decimal("0").is_zero()        # True
var scale_zero = Decimal("0.00").is_zero()  # True
```

### 5. Working with Scale and Precision

```mojo
# Get the scale (number of decimal places)
var d1 = Decimal("123.45")
print(d1.scale())  # 2

var d2 = Decimal("123.4500")
print(d2.scale())  # 4

# Scale after operations
var sum = d1 + d2             # Scale is max(2, 4) = 4
print(sum)                    # 246.9000

var product = d1 * d2         # Scale is 2 + 4 = 6
print(product)                # 15240.270000
```

### 6. Power Operations

```mojo
# Integer exponents
var base = Decimal("2")
var squared = base ** 2    # 4
var cubed = base ** 3      # 8
var raised = base ** 10    # 1024

# Negative exponents
var half = base ** (-1)      # 0.5
var quarter = base ** (-2)   # 0.25
var eighth = base ** (-3)    # 0.125

# Special cases
var any_to_zero = Decimal("123.45") ** 0  # 1
var one_to_any = Decimal("1") ** 100      # 1
var zero_to_pos = Decimal("0") ** 5       # 0
```

### 7. Edge Cases Handling

```mojo
# Division by zero
try:
    var result = Decimal("123.45") / Decimal("0")
    print("This won't print")
except:
    print("Division by zero detected")

# Zero raised to negative power
try:
    var result = Decimal("0") ** (-1)
    print("This won't print")
except:
    print("Zero raised to negative power detected")

# Very small numbers
var small = Decimal("0." + "0" * 27 + "1")  # Smallest possible positive decimal
print(small)  # 0.0000000000000000000000000001
```

### 8. Exact Decimal Representation

```mojo
# Floating-point issue
var float_sum = 0.1 + 0.2
print(float_sum)  # 0.30000000000000004 (not exactly 0.3)

# Decimal solves this
var dec_sum = Decimal("0.1") + Decimal("0.2")
print(dec_sum)    # Exactly 0.3

# Division with accurate representation of repeating decimals
var third = Decimal("1") / Decimal("3")
print(third)      # 0.3333333333333333333333333333 (to precision limit)
```

### 9. High Precision Calculations

```mojo
# High precision decimal
var high_prec = Decimal("0.123456789012345678901234567")
print(high_prec)  # Full 27 decimal places preserved

# Square root with high precision
from decimojo.mathematics import sqrt
var root2 = sqrt(Decimal("2"))
print(root2)      # 1.414213562373095048801688724 (to precision limit)

# Financial calculations maintaining exact cents
var item1 = Decimal("9.99")
var item2 = Decimal("19.99")
var tax_rate = Decimal("0.0725")
var subtotal = item1 + item2           # 29.98
var tax = subtotal * tax_rate          # 2.17355
var total = subtotal + tax             # 32.15355
print(total.round(2))                  # 32.15 (properly rounded)
```

### 10. Performance Comparison

```mojo
import time
from decimojo import Decimal
import math

# Benchmark division
var dec_val = Decimal("123.456789")
var float_val = 123.456789

# Decimal calculation
var t0 = time.perf_counter_ns()
var dec_result = Decimal("2") / dec_val
var dec_time = time.perf_counter_ns() - t0

# Float calculation
t0 = time.perf_counter_ns()
var float_result = 2.0 / float_val
var float_time = time.perf_counter_ns() - t0

print("Decimal result:", dec_result)
print("Decimal time:", dec_time, "ns")
print("Float result:", float_result) 
print("Float time:", float_time, "ns")
print("Decimal/Float time ratio:", dec_time/float_time)
```

## Related Projects

I am also working on NuMojo, a library for numerical computing in Mojo 🔥 similar to NumPy, SciPy in Python. If you are also interested, you can [check it out here](https://github.com/Mojo-Numerics-and-Algorithms-group/NuMojo).

## License

Distributed under the Apache 2.0 License. See [LICENSE](https://github.com/forFudan/decimojo/blob/main/LICENSE) for details.

## Acknowledgements

Built with the [Mojo programming language 🔥](https://www.modular.com/mojo) created by [Modular](https://www.modular.com/).
