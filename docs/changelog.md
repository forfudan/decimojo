# DeciMojo changelog

This is a list of RELEASED changes for the DeciMojo Package.

## 01/08/2025 (v0.5.0)

DeciMojo v0.5.0 introduces significant enhancements to the `BigDecimal` and `BigUInt` types, including new mathematical functions and performance optimizations. The release adds **trigonometric functions** for `BigDecimal`, implements the **Chudnovsky algorithm** for computing π, implements the **Karatsuba multiplication algorithm** and **Burnikel-Ziegler fast division algorithm** for `BigUInt`. In-place subtraction is now supported for `BigUInt`, and SIMD is utilized for arithmetic operations. The release also includes improved error handling, optimized type conversions, and comprehensive documentation updates.

### ⭐️ New

1. Introduce trigonometric functions for `BigDecimal`: `sin()`, `cos()`, `tan()`, `cot()`, `csc()`, `sec()`. These functions compute the corresponding trigonometric values of a given angle in radians with arbitrary precision (#96, #99).
1. Introduce the function `pi()` for `BigDecimal` to compute the value of π (pi) with arbitrary precision with the Chudnovsky algorithm with binary splitting (#95).

### 🦋 Changed

1. Refine the `BigUInt` multiplication with the **Karatsuba algorithm**. The time complexity of maltiplication is reduced from $O(n^2)$ to $O(n^{ln(3/2)})$ for large integers, which significantly improves performance for big numbers. Doubling the size of the numbers will only increase the time taken by a factor of about 3, instead of 4 as in the previous implementation (#97).
1. Refine the `BigUInt` division with the **Burnikel-Ziegler fast recursive division algorithm**. The time complexity of division is also reduced from $O(n^2)$ to $O(n^{ln(3/2)})$ for large integers (#103).
1. Refine the fall-back **schoolbook division** of `BigUInt` to improve performance. The fallback division is used when the divisor is small enough (#98, #100).
1. Implement auxiliary functions for arithmetic operations of `BigUInt` to handle **special cases** more efficiently, e.g., when the second operand is one-word long or is a `UInt32` value (#98, #104).
1. Implement in-place subtraction for `BigUInt`. The `__isub__` method of `BigUInt` will now conduct in-place subtraction. `x -= y` will not lead to memory allocation, but will modify the original `BigUInt` object `x` directly (#98).
1. Use SIMD for `BigUInt` addition and subtraction operations. This allows the addition and subtraction of two `BigUInt` objects to be performed in parallel, significantly improving performance for large numbers (#101, #102).
1. Add `to_uint64()` and `to_uint128()` methods to `BigUInt` to for fast type conversion (#91).
1. Improve error messages and remove unnecessary `raises` keywords for all functions (#92).

### 🛠️ Fixed

- Fix a bug for `BigUInt` comparison: When there are leading zero words, the comparison returns incorrect results (#97).
- Fix the `is_zero()`, `is_one()`, and `is_two()` methods for `BigUInt` to correctly handle the case when there are leading zero words (#97).

### 📚 Documentation and testing

Refactor the test files for `BigDecimal` (PR #93).

## 01/07/2025 (v0.4.1)

Version 0.4.1 of DeciMojo introduces implicit type conversion between built-in integral types and arbitrary-precision types.

### ⭐️ New

Now DeciMojo supports implicit type conversion between built-in integeral types (`Int`, `UInt`, `Int8`, `UInt8`, `Int16`, `UInt16`, `Int32`, `UInt32`, `Int64`, `UInt64`, `Int128`,`UInt128`, `Int256`, and `UInt256`) and the arbitrary-precision types (`BigUInt`, `BigInt`, and `BigDecimal`). This allows you to use these built-in types directly in arithmetic operations with `BigInt` and `BigUInt` without explicit conversion. The merged type will always be the most compatible one (PR #89, PR #90).

For example, you can now do the following:

```mojo
from decimojo.prelude import *

fn main() raises:
    var a = BInt(Int256(-1234567890))
    var b = BigUInt(31415926)
    var c = BDec("3.14159265358979323")

    print("a =", a)
    print("b =", b)
    print("c =", c)

    print(a * b)  # Merged to BInt
    print(a + c)  # Merged to BDec
    print(b + c)  # Merged to BDec
    print(a * Int(-128))  # Merged to BInt
    print(b * UInt(8))  # Merged to BUInt
    print(c * Int256(987654321123456789))  # Merged to BDec

    var lst = [a, b, c, UInt8(255), Int64(22222), UInt256(1234567890)]
    # The list is of the type `List[BigDecimal]`
    for i in lst:
        print(i, end=", ")
```

Running the code will give your the following results:

```console
a = -1234567890
b = 31415926
c = 3.14159265358979323
-38785093474216140
-1234567886.85840734641020677
31415929.14159265358979323
158024689920
251327408
3102807559527666386.46423202534973847
-1234567890, 31415926, 3.14159265358979323, 255, 22222, 1234567890,
```

### 🦋 Changed

Optimize the case when you increase the value of a `BigInt` object in-place by 1, *i.e.*, `i += 1`. This allows you to iterate faster (PR #89). For example, we can compute the time taken to iterate from `0` to `1_000_000` using `BigInt` and compare it with the built-in `Int` type:

```mojo
from decimojo.prelude import *

fn main() raises:
    i = BigInt(0)
    end = BigInt(1_000_000)
    while i < end:
        print(i)
        i += 1
```

| scenario        | Time taken |
| --------------- | ---------- |
| v0.4.0 `BigInt` | 1.102s     |
| v0.4.1 `BigInt` | 0.912s     |
| Built-in `Int`  | 0.893s     |

### 🛠️ Fixed

Fix a bug in `BigDecimal` where it cannot create a correct value from a integral scalar, e.g., `BDec(UInt16(0))` returns an unitialized `BigDecimal` object (PR #89).

### 📚 Documentation and testing

Update the `tests` module and refactor the test files for `BigUInt` (PR #88).

## 25/06/2025 (v0.4.0)

DeciMojo v0.4.0 updates the codebase to Mojo v25.4. This release enables you to use DeciMojo with the latest Mojo features.

## 06/06/2025 (v0.3.1)

DeciMojo v0.3.1 updates the codebase to Mojo v25.3 and replaces the `magic` package manager with `pixi`. This release enables you to use DeciMojo with the latest Mojo features and the new package manager.

## 15/04/2025 (v0.3.0)

DeciMojo v0.3.0 introduces the arbitrary-precision `BigDecimal` type with comprehensive arithmetic operations, comparisons, and mathematical functions (`sqrt`, `root`, `log`, `exp`, `power`). A new `tomlmojo` package supports test refactoring. Improvements include refined `BigUInt` constructors, enhanced `scale_up_by_power_of_10()` functionality, and a critical multiplication bug fix.

### ⭐️ New

- Implement the `BigDecimal` type with unlimited precision arithmetic.
  - Implement basic arithmetic operations for `BigDecimal`: addition, subtraction, multiplication, division, and modulo.
  - Implement comparison operations for `BigDecimal`: less than, greater than, equal to, and not equal to.
  - Implement string representation and parsing for `BigDecimal`.
  - Implement mathematical operations for `BigDecimal`: `sqrt`, `nroot`, `log`, `exp`, and `power` functions.
  - Iimplement rounding functions.
- Implement a simple TOML parser as package `tomlmojo` to refactor tests (PR #63).

### 🦋 Changed

- Refine the constructors of `BigUInt` (PR #64).
- Improve the method `BigUInt.scale_up_by_power_of_10()` (PR #72).

### 🛠️ Fixed

- Fix a bug in `BigUInt` multiplication where the calcualtion of carry is mistakenly skipped if a word of x2 is zero (PR #70).

## 01/04/2025 (v0.2.0)

Version 0.2.0 marks a significant expansion of DeciMojo with the introduction of `BigInt` and `BigUInt` types, providing unlimited precision integer arithmetic to complement the existing fixed-precision `Decimal` type. Core arithmetic functions for the `Decimal` type have been completely rewritten using Mojo 25.2's `UInt128`, delivering substantial performance improvements. This release also extends mathematical capabilities with advanced operations including logarithms, exponentials, square roots, and n-th roots for the `Decimal` type. The codebase has been reorganized into a more modular structure, enhancing maintainability and extensibility. With comprehensive test coverage, improved documentation in multiple languages, and optimized memory management, v0.2.0 represents a major advancement in both functionality and performance for numerical computing in Mojo.

### ⭐️ New

- Add comprehensive `BigInt` and `BigUInt` implementation with unlimited precision integer arithmetic.
- Implement full arithmetic operations for `BigInt` and `BigUInt`: addition, subtraction, multiplication, division, modulo and power operations.
- Support both floor division (round toward negative infinity) and truncate division (round toward zero) semantics for mathematical correctness.
- Add complete comparison operations for `BigInt` with proper handling of negative values.
- Implement efficient string representation and parsing for `BigInt` and `BigUInt`.
- Add advanced mathematical operations for `Decimal`: square root and n-th root.
- Add logarithm functions for `Decimal`: natural logarithm, base-10 logarithm, and logarithm with arbitrary base.
- Add exponential function and power function with arbitrary exponents for `Decimal`.

### 🦋 Changed

- Completely re-write the core arithmetic functions for `Decimal` type using `UInt128` introduced in Mojo 25.2. This significantly improves the performance of `Decimal` operations.
- Improve memory management system to reduce allocations during calculations.
- Reorganize codebase with modular structure (decimal, arithmetics, comparison, exponential).
- Enhance `Decimal` comparison operators for better handling of edge cases.
- Update internal representation of `Decimal` for better precision handling.

### ❌ Removed

- Remove deprecated legacy string formatting methods.
- Remove redundant conversion functions that were replaced with a more unified API.

### 🛠️ Fixed

- Fix edge cases in division operations with zero and one.
- Correct sign handling in mixed-sign operations for both `Decimal`.
- Fix precision loss in repeated addition/subtraction operations.
- Correct rounding behavior in edge cases for financial calculations.
- Address inconsistencies between operator methods and named functions.

### 📚 Documentation and testing

- Add comprehensive test suite for `BigInt` and `BigUInt` with over 200 test cases covering all operations and edge cases.
- Create detailed API documentation for both `Decimal` and `BigInt`.
- Add performance comparison benchmarks between DeciMojo and Python's decimal/int implementation.
- Update multi-language documentation to include all new functionality (English and Chinese).
- Include clear explanations of division semantics and other potentially confusing numerical concepts.
