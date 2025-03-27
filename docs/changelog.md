# DeciMojo released changelog

This is a list of RELEASED changes for the DeciMojo Package.

## 01/04/2025 (v0.2.0)

Version 0.2.0 marks a significant expansion of DeciMojo with the introduction of BigInt and BigUInt types, providing unlimited precision integer arithmetic to complement the existing fixed-precision Decimal type. Core arithmetic functions for the Decimal type have been completely rewritten using Mojo 25.2's UInt128, delivering substantial performance improvements. This release also extends mathematical capabilities with advanced operations including logarithms, exponentials, square roots, and n-th roots for the Decimal type. The codebase has been reorganized into a more modular structure, enhancing maintainability and extensibility. With comprehensive test coverage, improved documentation in multiple languages, and optimized memory management, v0.2.0 represents a major advancement in both functionality and performance for numerical computing in Mojo.

DeciMojo division performance compared with Python's `decimal` module across versions:

| Division Operation                | v0.1.0 vs Python | v0.2.0 vs Python | Improvement |
| --------------------------------- | ---------------- | ---------------- | ----------- |
| Integer division (no remainder)   | 0.15× (slower)   | 485.88× faster   | 3239×       |
| Simple decimal division           | 0.13× (slower)   | 185.77× faster   | 1429×       |
| Division with repeating decimal   | 0.04× (slower)   | 12.46× faster    | 311×        |
| Division by one                   | 0.15× (slower)   | 738.60× faster   | 4924×       |
| Division of zero                  | 1820.50× faster  | 1866.50× faster  | 1.03×       |
| Division with negative numbers    | 0.11× (slower)   | 159.32× faster   | 1448×       |
| Division by very small number     | 0.21× (slower)   | 452.75× faster   | 2156×       |
| High precision division           | 0.005× (slower)  | 15.19× faster    | 3038×       |
| Division resulting in power of 10 | 0.21× (slower)   | 619.00× faster   | 2948×       |
| Division of very large numbers    | 0.06× (slower)   | 582.86× faster   | 9714×       |

_Note: Benchmarks performed on Darwin 24.3.0, arm processor with Python 3.12.9. The dramatic performance improvements in v0.2.0 come from completely rewriting the division algorithm using Mojo 25.2's UInt128 implementation. While v0.1.0 was generally slower than Python for division operations (except for division of zero), v0.2.0 achieves speedups of 12-1866× depending on the specific scenario._

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
