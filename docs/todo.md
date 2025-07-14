# TODO

This is a to-do list for DeciMojo.

- [ ] When Mojo supports global variables, implement a global variable for the `BigDecimal` class to store the precision of the decimal number. This will allow users to set the precision globally, rather than having to set it for each function of the `BigDecimal` class.
- [ ] Implement different methods for adding decimojo types with `Int` types so that an implicit conversion is not required.
- [ ] Use debug mode to check for unnecessary zero words before all arithmetic operations. This will help ensure that there are no zero words, which can simplify the speed of checking for zero because we only need to check the first word.

- [x] (#31) The `exp()` function performs slower than Python's counterpart in specific cases. Detailed investigation reveals the bottleneck stems from multiplication operations between decimals with significant fractional components. These operations currently rely on UInt256 arithmetic, which introduces performance overhead. Optimization of the `multiply()` function is required to address these performance bottlenecks, particularly for high-precision decimal multiplication with many digits after the decimal point.
- [x] Implement different methods for augmented arithmetic assignments to improve memeory-efficiency and performance.
- [x] Implement a method `remove_leading_zeros` for `BigUInt`, which removes the zero words from the most significant end of the number.
- [x] Use debug mode to check for uninitialized `BigUInt` before all arithmetic operations. This will help ensure that there are no uninitialized `BigUInt`.
