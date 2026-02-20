# BigInt2 Benchmark Results & Optimization Roadmap

## Benchmark Summary (2026-02-20, macOS arm64, Apple Silicon)

All benchmarks compare **BigInt2** (base-2^32) against **BigInt/BigUInt** (base-10^9)
and **Python int** (CPython 3.13, GMP-backed). Speedup = Python time / Mojo time.
Values >1× mean faster than Python; <1× mean slower than Python.

### Overall Results (Average Across All Cases)

| Operation        | BigInt2 vs Python | BigInt/BigUInt vs Python | BigInt2 vs BigInt |
| ---------------- | :---------------: | :----------------------: | :---------------: |
| **Addition**     |     **4.30×**     |          2.36×           |   ~1.8× faster    |
| **Multiply**     |     **4.29×**     |          2.22×           |   ~1.9× faster    |
| **Floor Divide** |       1.24×       |          1.95×           |   ~0.6× slower    |
| **Trunc Divide** |       1.50×       |          2.32×           |   ~0.6× slower    |
| **Left Shift**   |     **4.53×**     |           N/A            |        N/A        |
| **Power**        |       0.49×       |          0.54×           |   ~0.9× similar   |
| **Sqrt**         |       0.75×       |     1.53× (BigUInt)      |   ~0.5× slower    |
| **from_string**  |     **2.43×**     |          1.35×           |   ~1.8× faster    |
| **to_string**    |       0.93×       |        **10.27×**        |   ~0.09× slower   |

### Key Findings

1. **Addition & Multiplication are excellent.** BigInt2's binary representation
   combined with native UInt32 word arithmetic gives 4–5× speedup over
   Python. This is the core strength of the base-2^32 design.

2. **Both Mojo types are slower than Python for power.** BigInt 0.54×, BigInt2
   0.49× — the schoolbook multiplication in the `square-and-multiply` loop is
   the bottleneck for both. Python uses Karatsuba (O(n^1.585)) and Toom-Cook.

3. **Division is a bottleneck for BigInt2.** BigInt2's schoolbook division
   (~1.24×) is barely faster than Python. BigInt benefits from its base-10^9
   representation for division. At 10000-digit scale, BigInt2 division at 0.88×
   is actually slower than Python.

4. **BigInt2 sqrt has a correctness bug at 1000+ digits.** The Newton's method
   implementation produces wrong results for very large numbers. BigUInt's sqrt
   is correct but extremely slow at scale (0.05× at 5000 digits). Both need
   better division to be competitive.

5. **to_string is BigInt's killer feature.** BigInt (base-10^9) achieves 32.5×
   at 10000 digits — trivial conversion. BigInt2 (base-2^32) requires repeated
   division by 10^9 and is 0.36× at 10000 digits. This O(n²) gap will widen.

6. **from_string is BigInt2's advantage.** 8× at small sizes, still 1.3× at
   2000 digits. At 10000 digits both BigInt2 and BigInt's O(n²) algorithms
   struggle, but BigInt is faster there (BigInt: 3.92× vs BigInt2: 0.71×).

7. **Shift is fast but degrades.** 11× at tiny sizes, 4–5× at medium, drops to
   0.59× at extremely large shifts (1 << 100000).

### Detailed Per-Case Observations

**Addition by size:**

| Size            | BigInt2 vs Python | BigInt vs Python |
| --------------- | :---------------: | :--------------: |
| Small (<20 dig) |       5–8×        |      2.5–4×      |
| 500 digits      |       3.71×       |      1.59×       |
| 1000 digits     |       2.45×       |      1.43×       |
| 5000 digits     |       1.59×       |      1.27×       |
| 10000 digits    |       1.54×       |      1.91×       |

At 10000 digits, BigInt overtakes BigInt2 in addition. This is because I used
SIMD vectorization for BigUInt's (which is the underlying type for BigInt)
addition, which gives a big boost at large sizes.

**Multiplication by size:**

| Size              | BigInt2 vs Python | BigInt vs Python |
| ----------------- | :---------------: | :--------------: |
| Small (<20 dig)   |       5–8×        |       2–4×       |
| 700 × 700 dig     |       0.87×       |      0.43×       |
| 1000 × 1000 dig   |       1.06×       |      0.50×       |
| 2000 × 2000 dig   |       0.57×       |      0.40×       |
| 5000 × 5000 dig   |       0.46×       |      0.56×       |
| 10000 × 10000 dig |       0.36×       |      0.57×       |

Critical: At 2000+ digits, **both** Mojo types are slower than Python. BigInt2's O(n²)
schoolbook multiply falls behind Python's Karatsuba/Toom-Cook. **Karatsuba is the
# 1 priority** for BigInt2 to remain competitive at scale. I can implement the
same Karatsuba algorithm for BigInt2 as I did for BigUInt, with minor adjustments.

**Floor Division by size:**

| Size              | BigInt2 vs Python | BigInt vs Python |
| ----------------- | :---------------: | :--------------: |
| Small (<20 dig)   |     1.5–2.0×      |       2–4×       |
| 5000/2500 digits  |       1.47×       |      0.42×       |
| 10000/5000 digits |       0.88×       |      0.39×       |

BigInt2 division actually scales better than BigInt's, which collapses at large sizes.
But both are behind Python for very large numbers. For BigUInt (the underlying type
of BigInt), I used the Burnikel-Ziegler algorithm for large numbers. If I can
implement a similar fast division for BigInt2, it should regain a lot of performance.

| Case                   | BigInt2 vs Python | BigInt vs Python |
| ---------------------- | :---------------: | :--------------: |
| 2^10 (4 digits result) |       1.33×       |      1.09×       |
| 2^256 (78 digits)      |       0.83×       |      0.51×       |
| 2^2048 (617 digits)    |       0.27×       |      0.13×       |
| 2^8192 (2467 digits)   |       0.15×       |      0.10×       |
| 2^32768 (9864 digits)  |       0.05×       |      0.06×       |
| 99^500 (998 digits)    |       0.31×       |      0.13×       |
| 99^2500 (4990 digits)  |       0.15×       |      0.11×       |
| 10^5000 (5001 digits)  |       0.15×       |      2.00×       |

BigInt2 and BigInt are both dramatically slower than Python for large exponents.
Note: BigInt wins for base-10 powers (trivial in base-10^9 representation).

**Sqrt by size:**

| Size           | BigInt2 vs Python | BigUInt vs Python |
| -------------- | :---------------: | :---------------: |
| Small (<7 dig) |     2.6–2.9×      |     5.3–6.7×      |
| 100 digits     |       0.25×       |       0.18×       |
| 500 digits     |       0.16×       |       0.05×       |
| 1000 digits    |    **0.82×** ⚠️    |       0.05×       |
| 2000 digits    |    **0.65×** ⚠️    |       0.03×       |
| 5000 digits    |    **0.51×** ⚠️    |       0.05×       |
| 10000 digits   |    **0.46×** ⚠️    |       0.05×       |

⚠️ BigInt2 results at 1000+ digits are **incorrect** (produces wrong values).
BigUInt is correct but extremely slow due to its O(n²) division in Newton's method.
BigInt2's sqrt appears fast only because it converges to the wrong answer early.
I need to fix the correctness bug first, then optimize the division to make it competitive.

**from_string by size:**

| Size         | BigInt2 vs Python | BigInt vs Python |
| ------------ | :---------------: | :--------------: |
| 2 digits     |       8.0×        |      1.41×       |
| 9 digits     |       6.0×        |      1.09×       |
| 100 digits   |       1.33×       |      0.47×       |
| 1000 digits  |       1.17×       |      0.83×       |
| 2000 digits  |       1.31×       |      1.83×       |
| 5000 digits  |       1.11×       |      3.56×       |
| 10000 digits |       0.71×       |      3.92×       |

BigInt2's O(n²) `multiply+add` loop for from_string degrades at scale, crossing
below Python at 10000 digits. BigInt is faster there because parsing into base-10^9
chunks is nearly free. Maybe I can use SIMD in reading the digits for BigInt2?

**to_string by size:**

| Size         | BigInt2 vs Python | BigInt vs Python |
| ------------ | :---------------: | :--------------: |
| 2 digits     |       2.68×       |      25.0×       |
| 9 digits     |       2.43×       |      17.0×       |
| 100 digits   |       0.63×       |      0.45×       |
| 1000 digits  |       0.57×       |      3.64×       |
| 2000 digits  |       0.57×       |      9.21×       |
| 5000 digits  |       0.59×       |      27.55×      |
| 10000 digits |       0.36×       |      32.52×      |

BigInt's to_string advantage grows quadratically with size. It is naturally
fast due to the base-10^9 representation. However, there is still some
room for optimization in BigInt2 by implementing a divide-and-conquer approach
instead of the current O(n²) repeated division by 10^9.

**Left Shift by size:**

| Case               | BigInt2 vs Python |
| ------------------ | :---------------: |
| 1 << 1             |       11.1×       |
| 1 << 1024          |       4.9×        |
| 100-digit << 100   |       4.8×        |
| 1000-digit << 1000 |       3.5×        |
| 5000-digit << 5000 |       1.6×        |
| 10000-dig << 10000 |       1.3×        |
| 1 << 100000        |       0.59×       |

Shift degrades at very large sizes, likely due to memory allocation overhead.

---

## Bugs Found During Benchmarking

### BigInt2 sqrt correctness bug at 1000+ digits

BigInt2's `sqrt()` returns **wrong results** for numbers with 1000+ digits:

- sqrt(10^999) → 975387... (should be 999...9)
- sqrt(10^1999) → 951380... (should be 999...9)
- sqrt(10^4999) → 882848... (should be 999...9)

This is likely a precision/convergence issue in Newton's method.
**Must be fixed before any performance optimization.**

---

## Optimization Roadmap

### PR 0 (BUGFIX): Fix BigInt2 sqrt correctness for large numbers

**Priority: CRITICAL** — Correctness bug, must fix before any optimization.

BigInt2's `sqrt()` returns wrong results at 1000+ digits. Root cause likely:

- Precision loss during Newton's method initial guess
- Convergence check using division that accumulates errors
- Or integer overflow in intermediate calculations

**Tasks:**

1. Investigate Newton's method initial estimate — may need better seed
2. Verify convergence condition: `|x_{n+1} - x_n| <= 1` may not be sufficient
3. Add correctness tests: `sqrt(n)^2 <= n < (sqrt(n)+1)^2`
4. Compare against BigUInt.sqrt() and Python math.isqrt() for validation

---

### PR 1: Karatsuba Multiplication for BigInt2

**Priority: HIGHEST** — Impacts multiply, power, sqrt, from_string, to_string

**Current:** Schoolbook multiplication O(n²) in `_multiply_magnitudes()`.
At 2000 digits, BigInt2 is already 0.57× vs Python. At 10000 digits, 0.36×.
This is the single most impactful optimization.

**Target:** Karatsuba multiplication O(n^1.585) with crossover at ~32–64 words
(~300–600 digits).

**Expected Impact:**

- 2000-digit multiply: from 0.57× to 2–4× vs Python
- 5000-digit multiply: from 0.46× to 3–6× vs Python
- Power: from 0.49× to 1–3× vs Python (since power = many multiplies)
- Sqrt Newton iterations will be faster
- from_string and to_string both use multiply internally

**Tasks:**

1. Implement Karatsuba in `arithmetics.mojo` with configurable crossover threshold
2. Benchmark crossover point (tune for arm64)
3. Add tests for large number multiplication correctness
4. Run bench_bigint2_multiply to verify improvement

---

### PR 2: Fast Division (Knuth Algorithm D / Burnikel-Ziegler)

**Priority: HIGH** — BigInt2 division degrades at scale (0.88× at 10000 digits)

**Current:** `_divmod_magnitudes()` uses basic schoolbook division.
BigInt2 is still better than BigInt at large-scale division (BigInt collapses
to 0.39× at 10000 digits), but both lag behind Python.

**Target:** Implement Knuth Algorithm D (normalized multi-word division) for
general case, plus Burnikel-Ziegler for large dividend/divisor ratios.

**Expected Impact:**

- Floor divide at 5000 digits: from 1.47× to 4–8× vs Python
- Floor divide at 10000 digits: from 0.88× to 3–5× vs Python
- Sqrt Newton iterations become faster (each iteration = 1 division)
- to_string becomes faster (repeated division by 10^9)

**Tasks:**

1. Implement Knuth Algorithm D with proper trial divisor estimation
2. Implement Burnikel-Ziegler recursive division for large numbers
3. Tune crossover thresholds
4. Add regression tests for edge cases (single-word divisor, nearly-equal, etc.)

---

### PR 3: Optimized to_string (Divide-and-Conquer Base Conversion)

**Priority: HIGH** — BigInt2's biggest weakness vs BigInt (32.5× gap at 10000 digits)

**Current:** `to_decimal_string()` converts to BigInt (base-10^9) first by
repeated division. This is O(n²). At 10000 digits, BigInt2 is 0.36× vs Python
while BigInt is 32.5×. This 90× gap is the primary argument against base-2^32.

**Target:** Divide-and-conquer base conversion:

1. Split the number in half by dividing by 10^(n/2)
2. Recursively convert each half
3. Concatenate results

This gives O(n·log²n) with Karatsuba multiplication.

**Expected Impact:**

- to_string at 5000 digits: from 0.59× to 3–6× vs Python
- to_string at 10000 digits: from 0.36× to 2–5× vs Python

**Tasks:**

1. Precompute powers-of-10 table (10^1, 10^2, 10^4, 10^8, ...)
2. Implement recursive divide-and-conquer to_decimal_string
3. Keep BigInt delegation path as fallback for verification
4. Benchmark at various sizes — especially 5000 and 10000 digits

---

### PR 4: Optimized from_string (Divide-and-Conquer)

**Priority: MEDIUM** — Already 2.4× avg but degrades to 0.71× at 10000 digits

**Current:** `from_string()` processes 9 digits at a time: `result = result *
10^9 + chunk`. This is O(n²). BigInt is faster at 5000+ digits (3.56× vs 1.11×).

**Target:** Divide-and-conquer: split digit string in half, convert each half
recursively, then `left_half * 10^(n/2) + right_half`.

**Expected Impact:**

- from_string at 5000 digits: from 1.11× to 5–8× vs Python
- from_string at 10000 digits: from 0.71× to 4–7× vs Python

**Tasks:**

1. Precompute powers-of-10 table (share with to_string)
2. Recursive from_string with balanced splitting
3. Benchmark at 2000, 5000, 10000 digit inputs

---

### PR 5: Bitwise Operations (AND, OR, XOR, NOT)

**Priority: MEDIUM** — Completes the integer API surface

**Current:** Only shift operations implemented. AND/OR/XOR/NOT are stubbed.

**Target:** Implement full bitwise operations using two's-complement semantics
for negative numbers (Python-compatible).

**Tasks:**

1. Create `bitwise.mojo` module
2. Implement `__and__`, `__or__`, `__xor__`, `__invert__`
3. Handle negative numbers via two's-complement conversion
4. Add comprehensive tests comparing against Python

---

### PR 6: GCD, Extended GCD, and Modular Arithmetic

**Priority: MEDIUM** — Useful for cryptographic and number theory applications

**Target:** Implement:

- `gcd(a, b)` — Binary GCD / Stein's algorithm (natural for base-2^32)
- `extended_gcd(a, b)` → (gcd, x, y) where ax + by = gcd
- `mod_pow(base, exp, mod)` — Modular exponentiation (Montgomery multiplication)

**Expected Impact:**

- Binary GCD is very efficient on base-2^32 (just shift + subtract)
- mod_pow should be much faster than `(base ** exp) % mod`

**Tasks:**

1. Implement binary GCD (Stein's algorithm) — perfect for base-2^32
2. Implement extended GCD
3. Implement mod_pow with Montgomery multiplication
4. Benchmark against Python's `pow(a, b, mod)`

---

### PR 7: Rename BigInt2 → BigInt, BigInt → BigInt10

**Priority: LOW** — Wait until BigInt2 is clearly better across the board

**Prerequisite:** PRs 1–3 complete, BigInt2 faster than BigInt in most operations.

**Target:**

- Rename `BigInt2` to `BigInt` (the default arbitrary precision integer)
- Rename current `BigInt` to `BigInt10` (decimal-optimized variant)
- Update all imports, tests, benchmarks, documentation

**Tasks:**

1. Renaming across the codebase
2. Update `__init__.mojo` exports
3. Update all tests and benchmarks
4. Update documentation and changelog

---

### PR 8: Toom-Cook 3 / NTT Multiplication

**Priority: LOW** — Only needed for very large numbers (5000+ digits)

**Prerequisite:** PR 1 (Karatsuba)

**Target:** Implement Toom-Cook 3-way multiplication O(n^1.465) for numbers
in the 5000–50000 digit range. For very large numbers (50000+), consider
Number Theoretic Transform (NTT).

Benchmark data shows at 10000×10000 digits:

- BigInt2: 745µs (0.36× vs Python)
- BigInt: 471µs (0.57× vs Python)
- Python: 267µs

Even Karatsuba may not close this gap at 10000+ digits. Toom-Cook or NTT
will be needed eventually.

**Tasks:**

1. Implement Toom-Cook 3 in arithmetics.mojo
2. Tune crossover: schoolbook → Karatsuba → Toom-Cook
3. Consider NTT for extreme sizes

---

## Summary: Priority Order

| PR  | Title                         | Priority | Blocked by | Impact                   |
| --- | ----------------------------- | -------- | ---------- | ------------------------ |
| PR0 | Fix sqrt correctness bug      | CRITICAL | —          | correctness              |
| PR1 | Karatsuba Multiplication      | HIGHEST  | —          | mul, pow, sqrt, str conv |
| PR2 | Fast Division (Knuth D + B-Z) | HIGH     | PR1        | div, sqrt, to_string     |
| PR3 | D&C to_string                 | HIGH     | PR2        | to_string (90× gap!)     |
| PR4 | D&C from_string               | MEDIUM   | PR1        | from_string              |
| PR5 | Bitwise AND/OR/XOR/NOT        | MEDIUM   | —          | API completeness         |
| PR6 | GCD + Modular Arithmetic      | MEDIUM   | PR2        | applications             |
| PR7 | Rename BigInt2 → BigInt       | LOW      | PR1–3      | ergonomics               |
| PR8 | Toom-Cook / NTT               | LOW      | PR1        | extreme sizes (10000+ d) |
