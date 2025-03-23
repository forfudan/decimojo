# TODO

This is a to-do list for Yuhao's personal use.

- [x] (#31) The `exp()` function performs slower than Python's counterpart in specific cases. Detailed investigation reveals the bottleneck stems from multiplication operations between decimals with significant fractional components. These operations currently rely on UInt256 arithmetic, which introduces performance overhead. Optimization of the `multiply()` function is required to address these performance bottlenecks, particularly for high-precision decimal multiplication with many digits after the decimal point.
- [ ] Implement different methods for augmented arithmetic assignments to improve memeory-efficiency and performance.