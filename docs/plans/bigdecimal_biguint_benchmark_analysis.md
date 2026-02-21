# BigDecimal and BigUInt Benchmark Results & Optimization Roadmap

2026-02-21

> **Benchmark location:** `benches/bigdecimal/` (BigDecimal vs Python `decimal`).
> BigUInt-only benchmarks are in `benches/biguint/`.
> Run with `pixi run bdec` (interactive) or `pixi run bench bigdecimal <op>`.

## Architecture Overview

```txt
BigDecimal  (coefficient: BigUInt, scale: Int, sign: Bool)
    ↓ delegates ALL integer arithmetic to
BigUInt     (words: List[UInt32], base-10^9, little-endian)
```

**Value formula:** $(-1)^{\text{sign}} \times \text{coefficient} \times 10^{-\text{scale}}$

BigDecimal is a **thin wrapper** around BigUInt. Its performance is almost
entirely determined by BigUInt's performance, because:

- Addition/subtraction: align scales via `multiply_by_power_of_ten` → add/subtract BigUInt coefficients
- Multiplication: multiply BigUInt coefficients → add scales
- Division: scale up dividend's BigUInt → integer divide → adjust scale
- Sqrt: extend coefficient by $10^{2t-s}$ → `BigUInt.sqrt()` → adjust scale
- Exp/ln/trig: iterative algorithms (Taylor series, Newton) composed from the above

**BigUInt internals:** base-$10^9$, each limb is `UInt32 ∈ [0, 999_999_999]`,
SIMD-vectorized addition/subtraction (width=4), Karatsuba multiplication
(cutoff=64 words), Burnikel-Ziegler division (cutoff=32 words).

---

## Benchmark Summary (latest results, macOS arm64, Apple Silicon)

All benchmarks compare **DeciMojo BigDecimal** against **Python `decimal.Decimal`**
(CPython 3.13, backed by `libmpdec`). Speedup = Python time / Mojo time.
Values >1× mean Mojo is faster; <1× mean Python is faster.

### Overall Results by Operation

| Operation          | Avg Speedup vs Python | Precision | Key Observation                                             |
| ------------------ | :-------------------: | :-------: | ----------------------------------------------------------- |
| **Addition**       |       **2.22×**       |    28     | Consistent ~2.4× for ≤28 digits; degrades >1000 digits      |
| **Subtraction**    |       **9.79×**       |    28     | Consistently ~9× across all small cases                     |
| **Multiplication** |       **3.44×**       |    28     | 2–7× across all tested sizes                                |
| **Division**       |       **6.29×**       |   4096    | Up to 28× for large balanced; **0.11× for asymmetric**      |
| **Sqrt**           |        0.66×*         |   5000    | Perfect squares ~200×; irrational results **0.55–0.72×**    |
| **Exp**            |         0.34×         |    28     | Python 2–4× faster consistently                             |
| **Root (nth)**     |        6.57×*         |    28     | Fast for √ and trivial; **0.18–0.33× for general nth root** |
| **Rounding**       |      **105.80×**      |    28     | Overwhelmingly faster (simple word truncation)              |

\* Averages heavily skewed by fast-path cases (perfect squares, identity roots).
For the general non-trivial cases, sqrt ≈ 0.66× and root ≈ 0.33×.

---

## Detailed Per-Operation Analysis

### Addition (60 cases, precision=28)

| Size               | Mojo (ns) | Python (ns) |  Speedup  |
| ------------------ | --------: | ----------: | :-------: |
| Small (≤28 digits) |   100–160 |     250–300 | 2.0–6.3×  |
| 1000 digits        |       208 |         319 |   1.53×   |
| 1500 digits        |       229 |         374 |   1.63×   |
| 2000 digits        |       257 |         328 |   1.28×   |
| 2500 digits        |       580 |         546 | **0.94×** |
| 3000+ digits       |       819 |         626 | **0.76×** |

**Analysis:** Addition is 2.0–2.5× faster for typical-precision decimals (≤28 digits).
The SIMD-vectorized BigUInt addition gives an edge. At 2500+ digits, Python overtakes
because `libmpdec` uses assembly-optimized routines for large coefficient arithmetic.

**Bottleneck:** Scale alignment via `multiply_by_power_of_ten` can be expensive if
scales differ greatly, triggering large word-array expansions before the actual add.

---

### Subtraction (50 cases, precision=28)

| Size            | Mojo (ns) | Python (ns) | Speedup |
| --------------- | --------: | ----------: | :-----: |
| Typical (≤28 d) |   130–230 | 1,400–1,800 |  7–11×  |
| Zero result     |       141 |       1,585 |  11.2×  |
| Subtract 0      |        58 |       1,669 |  28.8×  |

**Analysis:** Subtraction is surprisingly fast — **~10× Python** on average. The gap
vs addition speedup (2.2×) is noteworthy. This likely reflects Python `decimal`'s
overhead for subtraction's sign handling and normalization, which `libmpdec` does
not fast-path as well as addition.

---

### Multiplication (50 cases, precision=28)

| Size               | Mojo (ns) | Python (ns) | Speedup  |
| ------------------ | --------: | ----------: | :------: |
| Zero/one operand   |    36–100 |     258–264 | 2.6–7.2× |
| Small (≤28 digits) |    70–130 |     258–318 | 2.0–4.4× |
| Typical (28-digit) |    80–110 |     274–304 | 2.8–3.8× |

**Analysis:** Multiplication is consistently 3–4× faster for typical precision. This
is excellent. The Karatsuba-accelerated BigUInt multiplication pays off even at small
sizes because there's no overhead for scale handling (just add scales, XOR sign).

**Missing:** No benchmarks for very large multiplication (1000+ digit coefficients).
This would be important for operations like `exp` at high precision, which need many
large-coefficient multiplications internally.

---

### Division (64 cases, precision=4096)

**Balanced division (equal-size operands):**

| Size (words)      |  Mojo (ns) | Python (ns) |  Speedup  |
| ----------------- | ---------: | ----------: | :-------: |
| Small (≤28 d)     |    310–680 |   730–2,710 | 2.0–8.0×  |
| 1024w / 1024w     |     31,440 |     513,560 | **16.3×** |
| 2048w / 2048w     |     68,920 |   1,037,740 | **15.1×** |
| 4096w / 4096w     |    130,040 |   3,652,110 | **28.1×** |
| 8192w / 8192w     |    292,390 |   6,848,600 | **23.4×** |
| 16384w / 16384w   |    613,040 |  13,254,220 | **21.6×** |
| 32768w / 32768w   |  1,301,410 |  25,958,660 | **20.0×** |
| 65536w / 65536w   |  2,712,610 |  51,848,670 | **19.1×** |
| 262144w / 262144w | 12,126,666 | 205,680,333 | **17.0×** |

**Asymmetric division (unbalanced operands):**

| Size            |   Mojo (ns) | Python (ns) |   Speedup   |
| --------------- | ----------: | ----------: | :---------: |
| 65536w / 32768w | 444,571,666 |  50,058,333 | **0.11×** ✗ |
| 65536w / 16384w | 146,761,000 |  24,933,000 | **0.17×** ✗ |
| 65536w / 8192w  |  47,861,000 |  12,604,333 | **0.26×** ✗ |
| 65536w / 4096w  |  15,804,000 |   6,376,666 | **0.40×** ✗ |
| 65536w / 2048w  |   5,099,000 |   3,180,333 | **0.62×** ✗ |
| 65536w / 1024w  |   1,776,333 |     805,333 | **0.45×** ✗ |

**Key findings:**

1. **Balanced division is outstanding** — 15–28× faster than Python at large sizes.
   Burnikel-Ziegler is very effective when both operands are similar size.
2. **Asymmetric division is catastrophically slow** — 0.11–0.62× Python. The current
   B-Z implementation pads the divisor to match the dividend's block structure, causing
   massive waste when divisor << dividend. This is the #1 performance regression.
3. The regression between run 1 (optimized, avg 6.29×) and run 2 (earlier, avg 3.34×)
   shows that recent optimizations helped balanced cases, but asymmetric regression
   worsened.

---

### Square Root (70 cases, precision=5000)

| Input type               |           Mojo (ns) |         Python (ns) |    Speedup     |
| ------------------------ | ------------------: | ------------------: | :------------: |
| Perfect squares (√4, √9) |       25,000–28,000 | 5,135,000–5,520,000 |  **185–215×**  |
| Trivial scale (√0.0001)  |               6,550 |           5,478,790 |    **836×**    |
| Irrational (√2, √3, √5)  | 7,550,000–7,670,000 | 4,500,000–5,500,000 | **0.55–0.72×** |
| 100-word coefficient     |           7,668,330 |           5,478,220 |   **0.71×**    |
| 1000-word coefficient    |           7,600,870 |           5,161,650 |   **0.68×**    |
| 5000-word coefficient    |           7,712,970 |           5,088,320 |   **0.66×**    |

**Critical observation:** Mojo sqrt time is **nearly constant** (~7.6ms) regardless
of input coefficient size (100 to 5000 words). This is because the precision is fixed
at 5000, and the algorithm extends the coefficient to 5000-digit precision before
calling `BigUInt.sqrt()`. The BigUInt.sqrt() cost is dominated by the Newton iterations
at this fixed precision.

**Python's advantage:** Python `decimal` at precision=5000 takes 4.5–5.5ms. It uses
`libmpdec`'s optimized sqrt which employs:

- Assembly-optimized Number Theoretic Transform (NTT) for multiplication
- Reciprocal sqrt via Newton's method (avoids division entirely)
- Precise initial guess from hardware sqrt

**Mojo's bottleneck:** BigUInt Newton's method uses schoolbook/Karatsuba multiplication
and Burnikel-Ziegler division. At 5000-digit precision, each Newton iteration requires
one division (the bottleneck). The ~7.6ms constant time suggests ~15–20 Newton
iterations, each costing ~400µs (dominated by one ~556-word division).

---

### Exp (50 cases, precision=28)

| Input        | Mojo (ns) | Python (ns) | Speedup |
| ------------ | --------: | ----------: | :-----: |
| exp(0)       |        60 |       1,510 |  25.2×  |
| exp(1)       |    16,250 |       6,410 |  0.39×  |
| exp(0.01)    |    11,750 |       4,030 |  0.34×  |
| exp(0.1)     |    14,480 |       6,270 |  0.43×  |
| exp(10)      |    17,740 |       7,710 |  0.43×  |
| exp(100)     |    17,830 |       7,650 |  0.43×  |
| exp(-1)      |    21,630 |       6,760 |  0.31×  |
| exp(-100)    |    19,390 |       6,040 |  0.31×  |
| exp(1e-10)   |     3,840 |       1,670 |  0.43×  |
| exp(1000000) |    20,800 |      11,240 |  0.54×  |

Average: 0.34× (Python is ~3× faster)

**Analysis:** This is the weakest operation. The Taylor series implementation
(`exp_taylor_series`) converges in ~$2.5p$ iterations, each requiring:

- 1 BigDecimal multiplication (~100ns at 28 digits)
- 1 BigDecimal division (~2000ns at 28 digits)

So ~70 iterations × ~2100ns/iteration ≈ 147µs, but observed time is ~17µs.
The actual bottleneck is likely the range reduction (`exp(x/2^k)` then squaring $k$
times), plus the reciprocal computation for negative arguments ($e^{-x} = 1/e^x$).

**Python `libmpdec`'s advantage:** Uses the following optimizations:

- Correct rounding arithmetic via Ziv's method (compute at higher precision, retry if needed)
- NTT-based multiplication for all internal arithmetic
- Optimized reduction algorithm (argument reduction by $\ln(10)$, not $\ln(2)$)
- Cache of precomputed constants ($\ln(10)$ at various precisions)

---

### Root (50 cases, precision=28)

| Input                | Mojo (ns) | Python (ns) | Speedup |
| -------------------- | --------: | ----------: | :-----: |
| √64 (perfect square) |     1,750 |      47,420 |  27.1×  |
| √2 (irrational)      |     7,640 |      46,530 |  6.1×   |
| ∛27 (perfect cube)   |   171,430 |      50,030 |  0.29×  |
| ∛10 (non-perfect)    |    85,080 |      17,340 |  0.20×  |
| ⁵√32                 |   175,460 |      47,870 |  0.27×  |
| ∛e                   |   291,100 |      51,200 |  0.18×  |
| 100th root of 2      |    15,450 |      40,130 |  2.6×   |

**Analysis:** For non-square roots, the implementation delegates to
`exp(ln(x)/n)`, requiring both `ln()` and `exp()`. Since both `ln()` and `exp()`
are slow (Taylor series with many iterations of expensive BigDecimal arithmetic),
the compound cost is 0.18–0.33× Python.

**Python `libmpdec`** computes nth root directly via Newton's method
($x_{k+1} = ((n-1)x_k + a/x_k^{n-1})/n$), avoiding the `exp(ln(x)/n)` detour.

---

### Rounding (25 cases, precision=28)

Avg 105.8×. This is dominated by the overhead of Python's `decimal.quantize()` vs
Mojo's direct word-level truncation. Not a concern for optimization.

---

## Root Cause Analysis: Where Performance Is Lost

### 1. **Division (asymmetric case): 0.11–0.62× Python** — PR1 target

The Burnikel-Ziegler algorithm pads the divisor up to match the dividend's block
structure. When a 65536-word dividend is divided by a 1024-word divisor, the
algorithm still processes as if both are 65536 words. `libmpdec` uses GMP-style
asymmetric division that handles m >> n efficiently.

### 2. **Exp function: 0.31–0.43× Python** — PR3/PR4 targets

The Taylor series requires ~$2.5p$ iterations, each with one full-precision
BigDecimal division. At precision=28, this means ~70 divisions. The per-division cost
(~2µs at 28 digits) accumulates. `libmpdec` avoids explicit division in the Taylor
series by using reciprocals and NTT-multiplied accumulation.

### 3. **Ln function: not benchmarked but expected ~0.3× Python**

Same issue as exp. Additionally, `ln(2)` and `ln(1.25)` are recomputed on **every
call** because Mojo doesn't support mutable global variable caching yet.

### 4. **Sqrt (irrational, high precision): 0.55–0.72× Python**

Newton's method for sqrt requires one division per iteration. At precision=5000,
each division is on ~556-word numbers. The `BigUInt.sqrt()` converges in ~15–20
iterations. `libmpdec` uses reciprocal sqrt (no division) and NTT multiplication.

### 5. **Addition at very large sizes: 0.76× Python at 3000+ digits**

BigUInt's SIMD vectorized addition (width=4) is fast but scale alignment
(`multiply_by_power_of_ten`) for large scale differences creates oversized
intermediate arrays.

---

## Literature Review: How Major Decimal Libraries Are Designed

### 1. Python `decimal` → `libmpdec` (Stefan Krah)

**Internal representation:** base-$10^9$ (`uint32_t` limbs), optionally base-$10^{19}$
(`uint64_t`) on 64-bit platforms. Sign + exponent + coefficient (similar to DeciMojo).

**Key algorithms:**

- **Multiplication:** Schoolbook for small, Karatsuba for medium, **Number Theoretic
  Transform (NTT)** for large (>1024 limbs). NTT is in-place, uses three primes
  (MPD_PRIMES) enabling Chinese Remainder Theorem reconstruction for exact results.
  $O(n \log n)$ — this is the primary advantage over DeciMojo's $O(n^{1.585})$ Karatsuba.
- **Division:** Schoolbook for small, then balanced division via Newton's method for
  the reciprocal (`1/y`), computed using **NTT-multiplied** Newton iterations:
  $r_{k+1} = r_k(2 - yr_k)$. This avoids explicit long division entirely for large
  operands. $O(M(n))$ where $M(n)$ is the cost of multiplication.
- **Sqrt:** Reciprocal square root via Newton ($r_{k+1} = r_k(3 - yr_k^2)/2$) then
  multiply ($\sqrt{y} = y \cdot r$). Again uses NTT multiplication, never divides.
- **Exp/Ln:** Correct rounding via Ziv's method. Range reduction + Taylor/Maclaurin
  series, with all multiplications done via NTT at large precision.

**Why it's fast:** NTT gives $O(n \log n)$ multiplication for all sizes above ~1000
digits. Since division and sqrt are reduced to multiplication, all operations benefit.

**Source:** `Modules/_decimal/libmpdec/` in CPython source.

### 2. GMP / MPFR (GNU Multi-Precision)

**Internal representation:** base-$2^{64}$ (or $2^{32}$). Binary, not decimal.

**Key algorithms:**

- **Multiplication:** Schoolbook → Karatsuba → Toom-3 → Toom-4 → Toom-6.5 →
  Toom-8.5 → **FFT** (Schönhage-Strassen). Seven levels of algorithms, carefully
  tuned with machine-specific thresholds. The FFT is $O(n \log n \log \log n)$.
- **Division:** $O(M(n))$ via Newton (reciprocal iteration) using fast multiplication.
- **Sqrt:** $O(M(n))$ via reciprocal sqrt Newton.

**Note:** MPFR is a **binary** floating-point library. It provides exact rounding
for mathematical functions (exp, ln, sin, etc.) using Ziv's method. Not directly
comparable to decimal arithmetic, but the algorithms translate.

**DeciMojo relevance:** GMP's chain Schoolbook → Karatsuba → Toom-3 → FFT
suggests DeciMojo should implement Toom-3 as the next multiplication tier before
considering NTT.

### 3. mpdecimal (Rust) / `rust_decimal`

**`rust_decimal`:** Fixed 96-bit coefficient (28 significant digits max). Not
comparable to arbitrary precision.

**`bigdecimal` (Rust):** base-$10^9$ limbs via `num-bigint`. Uses the same
Schoolbook → Karatsuba → Toom-3 progression from `num-bigint`. No NTT.
Performance is typically 2–5× slower than Python `decimal` for very large
numbers due to lack of NTT.

### 4. Java `BigDecimal` (OpenJDK)

**Internal representation:** Unscaled `BigInteger` + 32-bit scale. Binary internally.

**Key algorithms:**

- `BigInteger` multiplication: Schoolbook → Karatsuba (≥80 ints/2560 bits) → Toom-3
  (≥240 ints/7680 bits) → **Parallel Schönhage** (≥10240 ints). Uses fork-join for
  parallel multiplication.
- Division: Burnikel-Ziegler for large divisions, delegated to Knuth's Algorithm D
  at the base case.
- Sqrt: Newton's method with binary integer arithmetic.

**Note:** Java `BigDecimal` stores the coefficient in **binary** (as a `BigInteger`),
not base-10^9. All base-10 formatting is done at I/O time. This gives Java the full
benefit of binary arithmetic speed for internal computation.

### 5. Intel® Decimal Floating-Point Math Library (BID)

**Internal representation:** Binary Integer Decimal (BID) — coefficient is stored as a
binary integer, exponent is power-of-10. This is IEEE 754-2008 decimal.

**Key insight:** By storing the coefficient in binary, BID gets fast binary arithmetic
for +, -, *, and only pays the decimal conversion cost at I/O boundaries.

### 6. `mpd` — Mike Cowlishaw's General Decimal Arithmetic

The **specification** that Python `decimal` implements. Not a library per se, but
defines the semantics. All conforming implementations share the same behavior.

---

## Design Question: Should BigDecimal Use BigUInt (10^9) or BigInt2 (2^32)?

### Current Design: base-$10^9$ (BigUInt)

**Advantages:**

- ✅ **Trivial I/O:** `to_string()` is $O(n)$ — just print each 9-digit word with
  zero padding. No expensive base conversion. This matters hugely for financial apps.
- ✅ **Exact scale arithmetic:** Adding trailing zeros or shifting decimal point =
  insert/remove whole words of zeros. No multiplication by powers of 10 needed.
- ✅ **Natural precision control:** Truncating to $p$ significant digits = keeping
  $\lceil p/9 \rceil$ words. Rounding operates on decimal digit boundaries.
- ✅ **Simple debugging:** Internal state is human-readable.
- ✅ **No representation error:** "0.1" is stored exactly.

**Disadvantages:**

- ✗ **Wasted bits:** Each 32-bit word stores $\log_2(10^9) ≈ 29.9$ bits of information
  out of 32 bits — 6.5% waste. Not critical but adds up in memory and cache.
- ✗ **Complex carry/borrow:** Carries are at $10^9$ boundary, requiring UInt64
  intermediate products and modulo/division. Binary carry is a single bit shift.
- ✗ **Sqrt/Newton division less efficient:** Per-iteration cost is higher than binary
  because each BigUInt division involves more complex quotient estimation.
- ✗ **No NTT:** NTT requires prime-modular arithmetic on binary words. Doing NTT in
  base-$10^9$ is possible (`libmpdec` does it) but the primes must be carefully chosen.

### Alternative: base-$2^{32}$ (BigInt2)

**Advantages:**

- ✅ **Maximum bit density:** Every bit used.
- ✅ **Simpler carry:** Single-bit carry propagation, pipeline-friendly.
- ✅ **Standard algorithms apply directly:** Karatsuba, Toom, NTT all work naturally.
- ✅ **Hardware-aligned:** SIMD, popcount, clz all work directly on limbs.
- ✅ **Better benchmark performance:** BigInt2 is 4.3× Python for addition vs
  BigUInt's 2.4×; 4× for multiplication vs 1.9×.

**Disadvantages:**

- ✗ **Expensive base conversion:** `to_string()` is $O(n^2)$ naïvely,
  $O(M(n) \log n)$ with D&C. The BigInt2 analysis shows to_string is only 1.17× Python
  at 10000 digits vs BigUInt's 34.5×.
- ✗ **Scale arithmetic is expensive:** Multiplying/dividing by $10^k$ requires actual
  multiplication, not word insertion.
- ✗ **Precision control is hard:** Truncating to $p$ decimal digits requires computing
  how many binary words correspond to $p$ digits, then base-converting.

### What libmpdec Does (and Why)

**`libmpdec` uses base-$10^9$ on 32-bit platforms and base-$10^{19}$ on 64-bit
platforms.** It implements NTT directly on the decimal limbs. The NTT primes are
specifically chosen so that the transform operates on numbers in $[0, 10^9)$ or
$[0, 10^{19})$.

This is the strongest evidence that **staying with base-$10^9$ is correct** for a
decimal library. The key insight is:

> The O(n log n) multiplication advantage of NTT/FFT can be obtained in ANY base.
> But the O(1) I/O advantage of decimal base is unique to decimal.

### What Java BigDecimal Does (and Why)

Java stores the coefficient as a **binary** `BigInteger` internally, paying the
conversion cost at construction and `toString()`. This gives fast arithmetic but slow
I/O. For computation-heavy uses (scientific computing), this is a good tradeoff.

### Recommendation

**Stay with base-$10^9$, but implement NTT for large multiplication.**

The reasoning:

1. **For a decimal library**, I/O speed matters. Financial and engineering users
   frequently create decimals from strings and print them. A 34× advantage on
   `to_string()` at 10000 digits is significant.

2. The current performance gap vs Python is **not because of the base**. It's because
   `libmpdec` has NTT and DeciMojo doesn't. Once NTT is implemented (PR5), the
   multiplication gap closes.

3. Division and sqrt performance will improve dramatically once they're reformulated
   to use reciprocal-Newton methods (avoiding explicit division), which requires fast
   multiplication (NTT) to be worthwhile.

4. For specific operations where binary arithmetic is vastly superior (e.g., integer
   sqrt at intermediate precision), it's possible to **use BigInt2 as a transit format**:
   convert to BigInt2, compute, convert back. But this should be the exception, not
   the default.

### Hybrid Strategy (Selective BigInt2 Transit)

For operations where BigInt2 is clearly faster and the conversion overhead is amortized:

| Operation              | Use BigInt2 transit? | Rationale                                                     |
| ---------------------- | :------------------: | ------------------------------------------------------------- |
| Addition / Subtraction |          No          | BigUInt is already fast enough                                |
| Multiplication         |          No          | NTT in base-10^9 is the right answer                          |
| Division               |          No          | Reciprocal-Newton will use multiplication                     |
| Sqrt                   |      **Maybe**       | If precision-doubling Newton in BigInt2 is much faster        |
| Power                  |      **Maybe**       | Binary exponentiation benefits from BigInt2's shift fast path |
| Exp / Ln / Trig        |          No          | These compose from multiply/divide, which BigUInt handles     |

The transit overhead is roughly `O(n)` for conversion each way, so it's only worth it
if the operation itself saves more than `O(n)` in total.

---

## Optimization Roadmap

### PR 1: Fix Asymmetric Division Performance

**Priority: CRITICAL** — Current 0.11× Python is the worst regression

**Problem:** Burnikel-Ziegler pads divisor up to dividend's block structure. When
dividing 65536 words by 1024 words, the algorithm wastes 98% of work.

**Solution:** Implement **GMP-style recursive unbalanced division**:

1. If dividend has $m$ words and divisor has $n$ words with $m > 2n$:
   - Divide the top $2n$ words of dividend by the $n$-word divisor
   - Use the quotient to reduce the problem
   - Recurse on the remainder concatenated with the next block
2. This gives $O(M(n) \cdot m/n)$ instead of $O(M(m))$.

**Expected gain:**

- 65536w / 1024w: from 0.45× → ~5× Python (based on BigInt2's slice-based B-Z results)
- 65536w / 32768w: from 0.11× → ~10× Python

**Impact:** Directly fixes asymmetric division. Also speeds up `to_string()` at
medium sizes (which does repeated division by $10^9$, an extremely asymmetric case).

---

### PR 2: Reciprocal-Newton Division (Avoids Explicit Long Division)

**Priority: HIGH** — Reduces division to multiplication at large sizes

**Algorithm:** Instead of directly computing $q = a / b$:

1. Compute $r \approx 1/b$ using Newton's iteration: $r_{k+1} = r_k(2 - br_k)$
2. Then $q = a \times r$ (one multiplication)
3. Adjust by at most ±1 using a correction step

**Key requirement:** The Newton iteration uses only multiplication (no division),
so this is $O(M(n))$ where $M(n)$ is multiplication cost. With NTT (PR5), this
becomes $O(n \log n)$.

**Without NTT (i.e., with Karatsuba only):** $O(n^{1.585})$ — still better than
schoolbook division's $O(n^2)$, and avoids the B-Z recursion overhead.

**Expected gain at precision=5000:**

- Current (B-Z + schoolbook base): division ≈ 400µs per 556-word division
- With reciprocal-Newton + Karatsuba: ≈ 150µs (estimated from 2× multiply cost)
- This directly speeds sqrt by ~2× (each Newton iteration has one division)

---

### PR 3: Optimized Exp/Ln (Reduce Iteration Count and Per-Iteration Cost)

**Priority: HIGH** — Currently 0.31–0.43× Python

**Sub-optimizations:**

#### PR 3a: Cache `ln(2)` and `ln(1.25)`

**Current:** Recomputed on every `ln()` call. At precision=28, this wastes ~5µs per call.

**Fix:** Use a module-level variable (when Mojo supports it), or pass a context/cache
object. As a workaround, precompute up to 1024 digits at compile time (already done
for π) and check if precision ≤ 1024 before recomputing.

#### PR 3b: Replace Division in Taylor Series with Multiplication by Reciprocal

**Current:** Each Taylor term computes `term = term * x / n`. The division by $n$
(a small integer) is a BigDecimal division, which is overkill.

**Fix:** For small integer divisors $n$, use `BigUInt.floor_divide_by_uint32(n)` directly
on the coefficient, avoiding BigDecimal division overhead entirely. This is already
implemented in BigUInt — just not used by the Taylor series.

**Expected gain:** Each iteration drops from ~2000ns to ~200ns (division by small
integer is 10× cheaper than general division). For 70 iterations, saves ~126µs.

#### PR 3c: Binary Splitting for Exp/Ln Series

**Current:** Sequential Taylor series, one term at a time. Each term depends on the
previous term.

**Fix:** Use binary splitting to evaluate $\sum \frac{x^k}{k!}$ as a single rational
$p/q$ with exact `BigUInt` arithmetic (same approach used for π Chudnovsky), then do
a single final division.

**Benefit:** Reduces $O(p)$ BigDecimal divisions to $O(1)$ final division + $O(p \log p)$
BigUInt multiplications. At large precision, this is dramatically faster.

**Note:** This is how `libmpdec` internally handles the series. It's the main reason
Python exp is 3× faster.

#### PR 3d: Better Range Reduction for Exp

**Current:** Halving strategy — divide by $2^k$ until $x < 1$, then square $k$ times.
Each squaring is a full-precision multiplication.

**Better:** Reduce $x$ modulo $\ln(10)$ so the reduced argument is much smaller,
requiring fewer Taylor terms. Then reconstruct using $e^{k\ln 10} = 10^k$ (trivial
in base-$10^9$).

---

### PR 4: Optimized Sqrt (Reciprocal Square Root, Avoid Division)

**Priority: HIGH** — Currently 0.55–0.72× Python at precision=5000

**Algorithm (libmpdec-style):**

1. Compute $r \approx 1/\sqrt{x}$ using Newton: $r_{k+1} = r_k(3 - xr_k^2)/2$
   - This uses only multiplication, no division!
2. Then $\sqrt{x} = x \times r$
3. Correct by at most ±1 ulp

**Each Newton iteration cost:** 2 multiplications + 1 subtraction + 1 right-shift
(vs current: 1 division + 1 addition + 1 right-shift)

**With Karatsuba (current):**

- Division: $O(n^{1.585})$ via B-Z + Karatsuba
- 2 multiplications: $2 \times O(n^{1.585})$ ← same asymptotic, but ~2× constant
  factor better because no B-Z recursion overhead

**With NTT (PR5):**

- Current (with div): $O(n \log n)$ per iteration via NTT division
- Reciprocal sqrt: $2 \times O(n \log n)$ per iteration, no division at all

**Expected gain:** ~1.5× improvement immediately (Karatsuba-based), ~3× with NTT.
At precision=5000, this means sqrt goes from 7.6ms to ~2.5ms, beating Python's ~5ms.

**Additional optimization — Precision doubling:**
Newton's method has quadratic convergence. Start with low precision and double each
iteration:

- Iteration 1: 8 digits precision (hardware arithmetic)
- Iteration 2: 16 digits
- Iteration 3: 32 digits
- ...
- Iteration k: 5000 digits

Total work ≈ $2 \times$ cost of the final iteration, instead of $k \times$ full cost.
This optimization is already used in BigInt2's sqrt — adapt it for BigUInt.

---

### PR 5: Number Theoretic Transform (NTT) for Large Multiplication

**Priority: HIGHEST LONG-TERM** — The single most impactful optimization

**What it is:** NTT is the integer analogue of FFT. It computes multiplication in
$O(n \log n)$ by:

1. Transform both operands into NTT domain (modular evaluation at roots of unity)
2. Pointwise multiply in NTT domain
3. Inverse transform back

**For base-$10^9$:** Choose NTT primes $p$ such that:

- $p > 2 \times 10^{18}$ (to avoid overflow of pointwise products)
- $p$ has a large power-of-2 factor (for radix-2 NTT)
- Use 2–3 primes with CRT reconstruction (Chinese Remainder Theorem)

**`libmpdec` primes (reference):**

- $p_1 = 2^{64} - 2^{32} + 1$ (Fermat-style, if fits)
- Three 64-bit primes with large $2^k$ factors for the transform length

**Implementation path:**

1. Implement forward/inverse NTT with a single prime
2. Implement CRT for multi-prime NTT
3. Integrate into `BigUInt.multiply()` with a cutoff (e.g., 512+ words)
4. Verify correctness for all carry patterns

**Expected gain:**

- 10000-digit multiply: Karatsuba $O(n^{1.585})$ → NTT $O(n \log n)$ ≈ 2–3× faster
- 100000-digit multiply: ~10× faster
- All operations that depend on multiplication (division, sqrt, exp, ln) improve transitively

**This is what closes the gap with `libmpdec` for large numbers.**

---

### PR 6: Toom-3 Multiplication (Intermediate Step Before NTT)

**Priority: MEDIUM** — Useful if NTT implementation is delayed

**Algorithm:** Toom-3 splits each operand into 3 parts instead of Karatsuba's 2.
Requires 5 recursive multiplications instead of Karatsuba's 3, but reduces the
sub-problem size to $n/3$ instead of $n/2$.

**Complexity:** $O(n^{\log_3 5}) = O(n^{1.465})$, better than Karatsuba's $O(n^{1.585})$.

**Integration:**

- Current: Schoolbook → Karatsuba (cutoff=64 words)
- After: Schoolbook → Karatsuba (cutoff=64) → Toom-3 (cutoff=256) → NTT (cutoff=1024)

**Expected gain:** ~1.5× at 10000 digits over Karatsuba alone.

---

### PR 7: Nth Root via Newton's Method (Avoid exp(ln(x)/n))

**Priority: MEDIUM** — Currently 0.18–0.33× Python for general nth root

**Current:** `root(x, n)` = `exp(ln(x) / n)`, requiring two expensive transcendental
function evaluations.

**Better:** Direct Newton's method for $x^{1/n}$:
$$r_{k+1} = \frac{1}{n}\left((n-1)r_k + \frac{x}{r_k^{n-1}}\right)$$

This requires only one division and one `power(r, n-1)` per iteration. For small $n$
(2, 3, 4, 5), unroll the power manually.

**Even better (after PR 2):** Reciprocal-Newton for $r = x^{-1/n}$:
$$r_{k+1} = r_k \cdot \frac{n+1 - x \cdot r_k^n}{n}$$

Then $x^{1/n} = x \cdot r$. Uses only multiplications (no division).

---

### PR 8: In-Place Arithmetic for BigUInt (Reduce Allocations)

**Priority: MEDIUM** — Broad 10–30% improvement across all operations

Many BigUInt operations currently allocate new word lists unnecessarily:

- Addition: `add_slices_simd` allocates a result then assigns to `self`
- Multiplication in Taylor series: each `term *= x` creates a new BigUInt
- Scale alignment: `multiply_by_power_of_ten` always allocates new

**Fix:** Implement true in-place operations (similar to BigInt2's PR5):

- `add_inplace(mut self, other)` with capacity pre-check
- `multiply_inplace_by_uint32(mut self, v)` operating on existing buffer
- `multiply_by_power_of_ten_inplace(mut self, n)` extending existing buffer

---

### PR 9: SIMD-Optimized BigUInt Multiplication

**Priority: LOW-MEDIUM** — Constant factor improvement for schoolbook

**Current:** Schoolbook multiplication uses UInt64 products with sequential carry.

**Optimization:** Use SIMD to process 4 limb products in parallel, accumulate in
UInt64 SIMD vectors, then normalize carries. On Apple Silicon M-series:

- `SIMD[DType.uint32, 4]` for load/store
- `SIMD[DType.uint64, 4]` for products
- Horizontal add + carry propagation

**Expected gain:** 1.5–2× for schoolbook kernel, which is the base case for both
Karatsuba and Toom-3.

---

## Optimization Priority Matrix

| PR      | Operation(s) Improved     | Current vs Python |    Expected After    |   Effort   |
| ------- | ------------------------- | :---------------: | :------------------: | :--------: |
| **PR1** | Asymmetric division       |    0.11–0.62×     |        3–10×         |   Medium   |
| **PR2** | Division, sqrt, exp, ln   |      varies       |     1.5–2× gain      |    High    |
| **PR3** | Exp, ln                   |    0.31–0.43×     |       1.0–2.0×       |   Medium   |
| **PR4** | Sqrt                      |    0.55–0.72×     |       1.5–3.0×       |   Medium   |
| **PR5** | ALL large operations      |      varies       |      2–10× gain      | Very High  |
| **PR6** | Large multiplication      |        N/A        | ~1.5× over Karatsuba |   Medium   |
| **PR7** | Nth root                  |    0.18–0.33×     |       1.0–2.0×       | Low-Medium |
| **PR8** | All (allocation overhead) |         —         |        10–30%        |   Medium   |
| **PR9** | Schoolbook multiply base  |         —         |        1.5–2×        |    Low     |

### Suggested Execution Order

1. **PR1** (asymmetric division fix) — immediate win, unblocks other work
2. **PR3a+3b** (exp/ln quick wins) — cache constants + cheap integer division
3. **PR4** (reciprocal sqrt) — standalone, high impact
4. **PR7** (direct nth root) — low effort, high impact for root()
5. **PR8** (in-place operations) — broad improvement
6. **PR2** (reciprocal-Newton division) — requires careful implementation
7. **PR6** (Toom-3) — medium complexity, medium gain
8. **PR3c** (binary splitting for series) — complex but transformative
9. **PR5** (NTT) — the end-game, makes everything fast at large sizes
10. **PR9** (SIMD multiply) — polish

---

## Appendix: Comparison with Python `libmpdec` Architecture

| Feature              |     DeciMojo BigDecimal      |            Python `libmpdec`             |                 Gap                  |
| -------------------- | :--------------------------: | :--------------------------------------: | :----------------------------------: |
| Base                 |       $10^9$ (UInt32)        | $10^9$ (uint32_t) / $10^{19}$ (uint64_t) | Minor — 64-bit limbs give 2× density |
| Small multiply       |          Schoolbook          |                Schoolbook                |                Parity                |
| Medium multiply      |    Karatsuba (cutoff=64w)    |                Karatsuba                 |                Parity                |
| Large multiply       |          Karatsuba           |           **NTT** $O(n\log n)$           |            **Major gap**             |
| Small division       | Specialized (UInt64/128/256) |                Schoolbook                |             Mojo faster              |
| Large balanced div   |       Burnikel-Ziegler       |          **Reciprocal-Newton**           |           Significant gap            |
| Large asymmetric div |   B-Z (broken for m >> n)    |           GMP-style recursive            |           **Critical gap**           |
| Sqrt                 |    Newton (with division)    |    **Reciprocal sqrt** (no division)     |           Significant gap            |
| Exp                  |  Taylor series (sequential)  |      Taylor + **binary splitting**       |              Major gap               |
| Ln                   |  Taylor series (sequential)  |        Similar + cached constants        |             Moderate gap             |
| I/O (to/from string) |        $O(n)$ trivial        |              $O(n)$ trivial              |                Parity                |
| Rounding             |    Word-level truncation     |                 Similar                  |           Mojo 100× faster           |

**Bottom line:** The performance gap is not about the base representation. It's about
the algorithm tier for large numbers: NTT multiplication, reciprocal-based division
and sqrt, and binary splitting for series evaluation. These are all implementable in
base-$10^9$.
