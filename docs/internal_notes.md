# Internal Notes

## Values and results

- For power functionality: `BigDecimal.power()`, Python's decimal, WolframAlpha give the same result, but `mpmath` gives a different result. Eample: `0.123456789 ** 1000`, `1234523894766789 ** 1098.1209848`.

## Time complexity

- #94. Implementing pi() with Machin's formula. Time taken for precision 2048: 33.580649 seconds.
- #95. Implementing pi() with Chudnovsky algorithm (binary splitting). Time taken for precision 2048: 1.771954 seconds.
