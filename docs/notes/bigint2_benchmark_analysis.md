# BigInt2 Benchmark Results & Optimization Roadmap

## Benchmark Summary (2026-02-20, macOS arm64, Apple Silicon)

All benchmarks compare **BigInt2** (base-2^32) against **BigInt10/BigUInt** (base-10^9)
and **Python int** (CPython 3.13, GMP-backed). Speedup = Python time / Mojo time.
Values >1× mean faster than Python; <1× mean slower than Python.

**Key optimizations applied:**

- ✅ **PR0**: Fixed sqrt correctness bug (Newton converges from above + precision-doubling algorithm)
- ✅ **PR1**: Karatsuba multiplication (O(n^1.585)) with pointer-based inner loops and offset-based assembly

### Overall Results (Average Across All Cases)

| Operation        | BigInt2 vs Python | BigInt10/BigUInt vs Python | BigInt2 vs BigInt10 |
| ---------------- | :---------------: | :------------------------: | :-----------------: |
| **Addition**     |     **4.30×**     |           2.36×            |    ~1.8× faster     |
| **Multiply**     |     **3.98×**     |           1.93×            |    ~2.1× faster     |
| **Floor Divide** |       1.24×       |           1.95×            |    ~0.6× slower     |
| **Trunc Divide** |       1.50×       |           2.32×            |    ~0.6× slower     |
| **Left Shift**   |     **4.97×**     |            N/A             |         N/A         |
| **Power**        |   **11.17×** ★    |           0.58×            |    ~19.3× faster    |
| **Sqrt**         |     **1.39×**     |      1.29× (BigUInt)       |    ~1.1× faster     |
| **from_string**  |     **2.21×**     |           1.48×            |    ~1.5× faster     |
| **to_string**    |       0.97×       |         **9.74×**          |    ~0.1× slower     |

★ Power average dominated by 2^N shift fast path (up to 140×). General cases: 0.65–0.94×.

### Key Findings

1. **Multiplication is now fast at ALL sizes.** With Karatsuba (O(n^1.585)) and
   pointer-based inner loops, BigInt2 beats Python even at 10000×10000 digits
   (1.34×). Previously 0.36× with schoolbook-only. The Karatsuba threshold is
   48 words (~460 digits), with three asymmetric cases handling unequal operand sizes.

2. **Power has a 2^N fast path.** Base-2 powers use left_shift instead of
   multiply, giving 5–140× speedup. For 2^32768 (~9864 digits): BigInt2 340 ns
   vs Python 47580 ns = **140× faster**. General non-2^N cases: 0.65–0.94×,
   limited by per-operation overhead in the square-and-multiply loop.

3. **Sqrt is now correct AND competitive at scale.** The correctness bug (wrong
   results at 1000+ digits) is fixed. A hybrid algorithm is used:
   - Hardware sqrt for ≤2 words (5–6.5× Python)
   - Newton's method for 3–54 words (~520 digits)
   - CPython-style precision-doubling for >54 words (O(M(n)) total work)
   At 10000 digits: 1.27× Python. Medium sizes (20–500 digits) remain 0.12–0.24×
   due to per-operation overhead of BigInt2 divisions.

4. **Division remains the primary bottleneck.** Still schoolbook O(n²). This
   limits sqrt, power, and to_string performance at medium sizes. BigInt2's
   division (~1.24×) is barely faster than Python. Knuth Algorithm D or
   Burnikel-Ziegler would be the next major win.

5. **to_string is still BigInt10's killer feature.** BigInt10 (base-10^9) achieves
   31.5× at 10000 digits — trivial conversion. BigInt2 requires repeated
   division by 10^9 and is 0.37× at 10000 digits. Divide-and-conquer base
   conversion would close this gap.

6. **from_string is competitive.** 7× at small, stays above 1× through 5000
   digits. Only drops to 0.89× at 10000 digits. BigInt10 overtakes at ~5000+
   digits due to its native base-10^9 parsing advantage.

7. **Shift is excellent.** Average 4.97× across all sizes. Degrades at extreme
   sizes (0.49× for 1 << 100000) due to memory allocation overhead.

---

### Detailed Per-Case Observations

**Addition by size** (unchanged from initial benchmark):

| Size            | BigInt2 vs Python | BigInt10 vs Python |
| --------------- | :---------------: | :----------------: |
| Small (<20 dig) |       5–8×        |       2.5–4×       |
| 500 digits      |       3.71×       |       1.59×        |
| 1000 digits     |       2.45×       |       1.43×        |
| 5000 digits     |       1.59×       |       1.27×        |
| 10000 digits    |       1.54×       |       1.91×        |

At 10000 digits, BigInt10 overtakes BigInt2 in addition. This is because BigUInt
(underlying BigInt10) uses SIMD vectorization for addition at large sizes.

**Multiplication by size** (post-Karatsuba):

| Size              | BigInt2 (ns) | Python (ns) | BigInt2 vs Python | BigInt10 vs Python |
| ----------------- | -----------: | ----------: | :---------------: | :----------------: |
| Small (<20 dig)   |        40–50 |     230–310 |     4.6–7.8×      |       2.6–6×       |
| 50 × 50 dig       |          100 |         300 |       3.0×        |       1.88×        |
| 100 × 100 dig     |          160 |         530 |       3.3×        |       1.10×        |
| 200 × 200 dig     |          540 |       1,000 |       1.85×       |       0.74×        |
| 300 × 300 dig     |          680 |       1,050 |       1.55×       |       0.54×        |
| 500 × 500 dig     |        1,320 |       1,940 |       1.47×       |       0.46×        |
| 600 × 600 dig     |        1,720 |       2,810 |       1.63×       |       0.55×        |
| 700 × 700 dig     |        2,130 |       2,790 |       1.31×       |       0.45×        |
| 1000 × 1000 dig   |        4,660 |       5,650 |       1.21×       |       0.43×        |
| 2000 × 2000 dig   |       15,160 |      16,740 |       1.10×       |       0.41×        |
| 5000 × 5000 dig   |       63,580 |      84,910 |       1.34×       |       0.57×        |
| 10000 × 10000 dig |      194,720 |     261,370 |       1.34×       |       0.57×        |

**Critical improvement:** BigInt2 is now faster than Python at **every** size.
Previously, 2000+ digit multiplication was 0.36–0.57× Python. Karatsuba brought
10000-digit multiply from 745 µs → 195 µs (3.8× internal speedup).

**Floor Division by size** (unchanged, not yet optimized):

| Size              | BigInt2 vs Python | BigInt10 vs Python |
| ----------------- | :---------------: | :----------------: |
| Small (<20 dig)   |     1.5–2.0×      |        2–4×        |
| 5000/2500 digits  |       1.47×       |       0.42×        |
| 10000/5000 digits |       0.88×       |       0.39×        |

BigInt2 division scales better than BigInt10's at large sizes, but both lag Python.

**Power by case** (post-optimization):

| Case                  | Result digits | BigInt2 (ns) | Python (ns) | BigInt2 vs Python |
| --------------------- | :-----------: | -----------: | ----------: | :---------------: |
| 2^10                  |       4       |          100 |         340 |       3.4×        |
| 2^64                  |      20       |           80 |         280 |       3.5×        |
| 2^256                 |      78       |           80 |         360 |       4.5×        |
| 2^1024                |      309      |          100 |         500 |       5.0×        |
| 2^2048                |      617      |          100 |         840 |       8.4×        |
| 2^8192                |     2467      |          160 |       8,460 |     **52.9×**     |
| 2^32768               |     9865      |          340 |      47,580 |    **140.0×**     |
| 10^20                 |      21       |          340 |         300 |       0.88×       |
| 10^100                |      101      |          520 |         480 |       0.92×       |
| 10^500                |      501      |        1,200 |         820 |       0.68×       |
| 10^2000               |     2001      |        8,020 |       6,420 |       0.80×       |
| 10^5000               |     5001      |       38,960 |      29,000 |       0.74×       |
| 3^100                 |      48       |          460 |         400 |       0.87×       |
| 7^50                  |      43       |          420 |         380 |       0.90×       |
| 99^50                 |      100      |          460 |         360 |       0.78×       |
| 99^500                |      998      |        3,140 |       2,080 |       0.66×       |
| 99^2500               |     4990      |       43,660 |      28,360 |       0.65×       |
| 1000^100              |      301      |          640 |         600 |       0.94×       |
| Large base, small exp |      81       |          340 |         300 |       0.88×       |
| (-2)^100              |      31       |           80 |         320 |       4.0×        |
| (-2)^101              |      32       |          100 |         320 |       3.2×        |

**Key observations:**

- 2^N cases: 3.4–140× (uses left_shift, O(1) per bit instead of multiplies)
- Small general (result <200 digits): 0.78–0.94× (competitive with Python)
- Large general (result >1000 digits): 0.65–0.80× (per-multiply overhead accumulates)
- Eliminating the wasted final squaring gave a modest boost across all cases
- BigInt2 always beats BigInt10 for power (BigInt10 averages 0.58×)

**Sqrt by size** (post-precision-doubling fix):

| Size               | BigInt2 (ns) | Python (ns) | BigInt2 vs Python | BigUInt vs Python |
| ------------------ | -----------: | ----------: | :---------------: | :---------------: |
| Small (≤7 dig)     |        40–60 |     260–300 |     5.0–6.5×      |     4.3–5.0×      |
| 20 digits          |        2,840 |         340 |       0.12×       |       0.33×       |
| 50 digits          |        2,020 |         480 |       0.24×       |       0.23×       |
| 100 digits         |        3,440 |         560 |       0.16×       |       0.11×       |
| 200 digits         |        4,680 |         880 |       0.19×       |       0.06×       |
| 500 digits         |        8,860 |       1,880 |       0.21×       |       0.06×       |
| **1000 digits** ✅  |        7,400 |       4,340 |     **0.59×**     |       0.04×       |
| **2000 digits** ✅  |       15,520 |      14,540 |     **0.94×**     |       0.03×       |
| **5000 digits** ✅  |       62,840 |      74,980 |     **1.19×**     |       0.05×       |
| **10000 digits** ✅ |      204,140 |     259,280 |     **1.27×**     |       0.05×       |

✅ All results are now **correct** (verified `sqrt(n)^2 <= n < (sqrt(n)+1)^2`).

**Key observations:**

- Small (≤2 words): Hardware sqrt, 5–6.5× Python
- Medium (20–500 digits): Newton's method, 0.12–0.24× (division overhead dominates each iteration)
- Large (1000+ digits): Precision-doubling algorithm, approaching and surpassing Python
- The crossover to beating Python is at ~2000 digits
- BigUInt is extremely slow at all sizes >50 digits (schoolbook division in its Newton iterations)
- Fixing division (PR2) would dramatically improve the medium-size sqrt performance

**from_string by size:**

| Size         | BigInt2 vs Python | BigInt10 vs Python |
| ------------ | :---------------: | :----------------: |
| 2 digits     |       7.0×        |       1.47×        |
| 9 digits     |       5.6×        |       1.16×        |
| 20 digits    |       3.1×        |       1.00×        |
| 50 digits    |       1.6×        |       0.73×        |
| 100 digits   |       1.3×        |       0.57×        |
| 200 digits   |       1.1×        |       0.50×        |
| 500 digits   |       1.4×        |       0.66×        |
| 1000 digits  |       1.2×        |       0.91×        |
| 2000 digits  |       1.1×        |       1.42×        |
| 5000 digits  |       1.1×        |       3.28×        |
| 10000 digits |       0.9×        |       5.51×        |

BigInt2's O(n²) `multiply+add` loop for from_string degrades at scale, crossing
below Python at 10000 digits. BigInt10 is faster at 5000+ digits because parsing
into base-10^9 chunks is nearly free. Divide-and-conquer from_string (PR4)
would use `left_half * 10^(n/2) + right_half` to achieve O(n·log²n).

**to_string by size:**

| Size         | BigInt2 vs Python | BigInt10 vs Python |
| ------------ | :---------------: | :----------------: |
| 2 digits     |       3.3×        |       21.0×        |
| 9 digits     |       2.2×        |       18.7×        |
| 20 digits    |       1.2×        |        3.6×        |
| 50 digits    |       0.7×        |        1.3×        |
| 100 digits   |       0.5×        |        0.9×        |
| 200 digits   |       0.5×        |        1.0×        |
| 500 digits   |       0.5×        |        1.8×        |
| 1000 digits  |       0.6×        |        3.6×        |
| 2000 digits  |       0.6×        |        8.6×        |
| 5000 digits  |       0.6×        |       24.1×        |
| 10000 digits |       0.4×        |       31.5×        |

BigInt10's to_string advantage grows with size (trivial in base-10^9). BigInt2
requires O(n²) repeated division by 10^9. Divide-and-conquer base conversion
(PR3) would bring this to O(n·log²n).

**Left Shift by size:**

| Case               | BigInt2 vs Python |
| ------------------ | :---------------: |
| 1 << 1             |       6.6×        |
| 1 << 32            |       5.4×        |
| 1 << 64            |       6.6×        |
| 1 << 256           |       6.5×        |
| 1 << 1024          |       5.9×        |
| 100-digit << 100   |       6.2×        |
| 200-digit << 256   |       5.8×        |
| 1000-digit << 1000 |       4.3×        |
| 5000-digit << 5000 |       1.8×        |
| 10000-dig << 10000 |       1.4×        |
| 1 << 100000        |       0.5×        |
| 1000-dig << 32768  |       1.2×        |

Shift is fast for typical sizes (4–7×). Degrades at extreme sizes due to
memory allocation overhead for very large result buffers.

---

## Resolved Bugs

### ✅ BigInt2 sqrt correctness bug at 1000+ digits (FIXED)

**Symptom:** sqrt(10^999) returned 975387... instead of the correct 999...9.
Newton's method converged to the wrong answer because the initial guess was an
underestimate, allowing convergence to the wrong quadratic residue.

**Fix:** Two-part solution:

1. **Newton's method (≤54 words):** Changed initial guess to always be an
   **overestimate** using hardware sqrt of the top 1–2 words with ceiling
   rounding. Newton's method then converges monotonically from above.
2. **Precision-doubling (>54 words):** Implemented CPython's precision-doubling
   algorithm that starts with a 1-bit seed and doubles precision each iteration.
   Each iteration at precision p does a division of size 2p, so total work is
   O(M(n)) instead of O(M(n) * log n).

**Verification:** All 16 sqrt benchmark cases produce correct results. Separately
tested correctness up to 5000 digits with `sqrt(n)^2 <= n < (sqrt(n)+1)^2`.

---

## Optimization Roadmap

### ✅ PR 0 (BUGFIX): Fix BigInt2 sqrt correctness — DONE

Fixed with overestimate-based Newton's method + CPython precision-doubling algorithm.
See "Resolved Bugs" section above.

### ✅ PR 1: Karatsuba Multiplication — DONE

Implemented Karatsuba O(n^1.585) in `_multiply_magnitudes_karatsuba()` with:

- **Threshold:** CUTOFF_KARATSUBA = 48 words (~460 digits)
- **Three Karatsuba cases:** normal (balanced), asymmetric Case 1 (a shorter), and
  asymmetric Case 2 (b shorter)
- **Pointer-based inner loops:** `_data` pointer access in schoolbook avoids bounds checking
- **Offset-based assembly:** `_add_at_offset_inplace(a, b, offset)` replaces the
  expensive `shift_left_words + add` pattern, eliminating O(n) memory copies
- **Slice-based sub-operations:** `_multiply_magnitudes_school(a, a_start, a_end, b, b_start, b_end)`
  avoids creating sub-lists for Karatsuba's recursive calls

**Result:** 10000-digit multiply: 745 µs → 195 µs (**3.8× internal speedup**).
BigInt2 now beats Python at ALL multiplication sizes.

---

### PR 2: Fast Division (Knuth Algorithm D / Burnikel-Ziegler)

**Priority: HIGHEST** — The most impactful remaining optimization

**Current:** `_divmod_magnitudes()` uses basic schoolbook division.
BigInt2 is barely faster than Python at medium sizes and slower at 10000 digits (0.88×).
Division is the bottleneck for:

- **Sqrt medium sizes** (20–500 digits): per-iteration division overhead makes BigInt2
  0.12–0.24× Python despite correct algorithm
- **Power at scale** (99^2500 = 0.65×): many multiplies done correctly, but the
  occasional division in Newton's method slows sqrt
- **to_string** (O(n²) repeated division by 10^9)

**Target:** Implement Knuth Algorithm D (normalized multi-word division) for
general case, plus Burnikel-Ziegler for large dividend/divisor ratios.

**Expected Impact:**

- Sqrt at 500 digits: from 0.21× to ~1.5–3× Python (fewer expensive Newton iterations)
- Floor divide at 10000 digits: from 0.88× to 3–5× Python
- to_string benefits cascading from faster division

**Tasks:**

1. Implement Knuth Algorithm D with proper trial divisor estimation
2. Implement Burnikel-Ziegler recursive division for large numbers
3. Tune crossover thresholds
4. Add regression tests for edge cases

---

### PR 3: Optimized to_string (Divide-and-Conquer Base Conversion)

**Priority: HIGH** — BigInt2's biggest weakness vs BigInt10 (31.5× gap at 10000 digits)

**Current:** `to_decimal_string()` converts to BigInt10 (base-10^9) first by
repeated division. This is O(n²). At 10000 digits, BigInt2 is 0.37× vs Python
while BigInt10 is 31.5×.

**Target:** Divide-and-conquer base conversion:

1. Split the number in half by dividing by 10^(n/2)
2. Recursively convert each half
3. Concatenate results

This gives O(n·log²n) with Karatsuba multiplication.

**Expected Impact:**

- to_string at 5000 digits: from 0.58× to 3–6× vs Python
- to_string at 10000 digits: from 0.37× to 2–5× vs Python

**Prerequisite:** PR 2 (fast division) for the divide-by-power-of-10 step.

---

### PR 4: Optimized from_string (Divide-and-Conquer)

**Priority: MEDIUM** — Already 2.21× avg but degrades to 0.89× at 10000 digits

**Current:** `from_string()` processes 9 digits at a time: `result = result *
10^9 + chunk`. This is O(n²). BigInt10 is faster at 5000+ digits (3.28× vs 1.11×).

**Target:** Divide-and-conquer: split digit string in half, convert each half
recursively, then `left_half * 10^(n/2) + right_half`.

**Expected Impact:**

- from_string at 5000 digits: from 1.11× to 5–8× vs Python
- from_string at 10000 digits: from 0.89× to 4–7× vs Python

**Prerequisite:** PR 1 (Karatsuba — already done) for the multiply step.

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

---

### PR 7: Reassign BInt alias from BigInt10 → BigInt2

**Priority: LOW** — Wait until BigInt2 is clearly better across the board

**Prerequisite:** PRs 2–3 complete, BigInt2 faster than BigInt10 in most operations.

---

### PR 8: Toom-Cook 3 / NTT Multiplication

**Priority: LOW** — Only valuable for very large numbers (10000+ digits)

**Prerequisite:** PR 1 (Karatsuba — done)

**Current status:** With Karatsuba, BigInt2 is already 1.34× Python at 10000
digits. Toom-Cook 3 (O(n^1.465)) would help at 50000+ digits. NTT for extreme
sizes (100000+).

---

## Summary: Priority Order

| PR  | Title                         | Status     | Priority | Impact                     |
| --- | ----------------------------- | ---------- | -------- | -------------------------- |
| PR0 | Fix sqrt correctness bug      | ✅ **DONE** | CRITICAL | correctness (fixed)        |
| PR1 | Karatsuba Multiplication      | ✅ **DONE** | HIGHEST  | mul 3.8× faster at scale   |
| PR2 | Fast Division (Knuth D + B-Z) | TODO       | HIGHEST  | div, sqrt, to_string       |
| PR3 | D&C to_string                 | TODO       | HIGH     | to_string (31× gap!)       |
| PR4 | D&C from_string               | TODO       | MEDIUM   | from_string at scale       |
| PR5 | Bitwise AND/OR/XOR/NOT        | TODO       | MEDIUM   | API completeness           |
| PR6 | GCD + Modular Arithmetic      | TODO       | MEDIUM   | applications               |
| PR7 | Reassign BInt → BigInt2       | TODO       | LOW      | ergonomics                 |
| PR8 | Toom-Cook / NTT               | TODO       | LOW      | extreme sizes (50000+ dig) |
