# TODO

This is a to-do list for Yuhao's personal use.

- [x] (#31) The `exp()` function performs slower than Python's counterpart in specific cases. Detailed investigation reveals the bottleneck stems from multiplication operations between decimals with significant fractional components. These operations currently rely on UInt256 arithmetic, which introduces performance overhead. Optimization of the `multiply()` function is required to address these performance bottlenecks, particularly for high-precision decimal multiplication with many digits after the decimal point.
- [ ] When Mojo supports global variables, implement a global variable for the `BigDecimal` class to store the precision of the decimal number. This will allow users to set the precision globally, rather than having to set it for each function of the `BigDecimal` class.
- [ ] Implement different methods for augmented arithmetic assignments to improve memeory-efficiency and performance.
- [ ] Implement different methods for adding decimojo types with `Int` types so that an implicit conversion is not required.
- [ ] Implement a method `remove_trailing_zeros` for `BigUInt`.
