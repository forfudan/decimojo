# BigDecimal and BigUInt Benchmark Results & Optimization Roadmap

Frist version: 2026-02-21  
Yuhao Zhu

> [!IMPORTANT]
> **Key discovery (2026-02-22):** Multi-precision benchmarks show Mojo exp is **1.09× Python at p=1000** and ln near-1 is **4.24× Python at p=1000**. The primary remaining gap is:
> (1) ln far-from-1 (0.0002× due to missing `ln(10)` cache — fixable with Task 3c), and
> (2) exp/ln at small precision p<200 (0.3–0.6× due to constant-factor overhead).
> For v0.8.0, Tasks [1✓, 3a✓, 3b, 3c, 7, 8] are the priority to be competitive at all sizes.

## Optimization priority and planning

| Task       | Operation(s) Improved     |     Current vs Python      |         Expected After          |   Effort   | Priority     |
| ---------- | ------------------------- | :------------------------: | :-----------------------------: | :--------: | ------------ |
| **Task 1** | Asymmetric division       |        ✓ **31–79×**        |           ✓ COMPLETED           |    Done    | High         |
| **Task 2** | Division, sqrt, exp, ln   |           varies           |           1.5–2× gain           |    High    | Medium       |
| **Task 3** | Exp, ln                   | Exp: 0.48×@p50→1.09×@p1000 | 3a ✓ (cache ln2); 3b+3c pending |   Medium   | **Critical** |
| **Task 4** | Sqrt                      |         0.55–0.72×         |            1.5–3.0×             |   Medium   | Medium       |
| **Task 5** | ALL large operations      |           varies           |           2–10× gain            | Very High  | Low          |
| **Task 6** | Large multiplication      |            N/A             |      ~1.5× over Karatsuba       |   Medium   | Medium       |
| **Task 7** | Nth root                  |         0.14–0.49×         |            1.0–2.0×             | Low-Medium | Medium       |
| **Task 8** | All (allocation overhead) |             —              |             10–30%              |   Medium   | High         |
| **Task 9** | Schoolbook multiply base  |             —              |             1.5–2×              |    Low     | Medium       |

### Planned Execution Order

1. ~~**Task 1** (asymmetric division fix) — immediate win, unblocks other work~~ ✓ DONE
1. ~~**Task 3a** (cache ln(2)/ln(1.25) via MathCache struct)~~ ✓ DONE
1. **Task 3b** (exp/ln cheap integer division) — helps exp at p<200 (0.3–0.6× → ~0.7–1.0×)
1. **Task 3c** (cache `ln(10)` in MathCache) — **highest ROI**: fixes ln(10)/ln(100)/ln(0.001) catastrophe (0.0002× → ~1×). Low effort.
1. **Task 7** (direct nth root) — low effort, removes exp+ln bottleneck for root()
1. **Task 8** (in-place operations) — broad improvement
1. **Task 4** (reciprocal sqrt) — less urgent (Mojo sqrt already fast-pathed via BigUInt.sqrt())
1. **Task 2** (reciprocal-Newton division) — requires careful implementation
1. **Task 6** (Toom-3) — medium complexity, medium gain
1. **Task 3c** (binary splitting for series) — complex but transformative
1. **Task 5** (NTT) — less urgent than thought; Karatsuba competitive up to p=1000
1. **Task 9** (SIMD multiply) — polish

## Benchmarks

**Benchmark location:** `benches/bigdecimal/` (BigDecimal vs Python `decimal`).  
BigUInt-only benchmarks are in `benches/biguint/`.  
Run with `pixi run bdec` (interactive) or `pixi run bench bigdecimal <op>`.

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

**BigUInt internals:** base-$10^9$, each limb is `UInt32 ∈ [0, 999_999_999]`, SIMD-vectorized addition/subtraction (width=4), Karatsuba multiplication (cutoff=64 words), Burnikel-Ziegler division (cutoff=32 words).

---

## Benchmark Summary (latest results, macOS arm64, Apple Silicon)

All benchmarks compare **DeciMojo BigDecimal** against **Python `decimal.Decimal`** (CPython 3.13, backed by `libmpdec`). Speedup = Python time / Mojo time. Values >1× mean Mojo is faster; <1× mean Python is faster.

### Overall Results by Operation

| Operation          | Avg Speedup vs Python | Precision | Key Observation                                                  |
| ------------------ | :-------------------: | :-------: | ---------------------------------------------------------------- |
| **Addition**       |       **2.22×**       |    28     | Consistent ~2.4× for ≤28 digits; degrades >1000 digits           |
| **Subtraction**    |       **9.79×**       |    28     | Consistently ~9× across all small cases                          |
| **Multiplication** |       **3.44×**       |    28     | 2–7× across all tested sizes                                     |
| **Division**       |       **6.29×**       |    50     | Up to 28× for large balanced; **31–79× asymmetric** (Task 1 fix) |
| **Sqrt**           |        0.66×*         |   5000    | Perfect squares ~200×; irrational results **0.55–0.72×**         |
| **Exp**            |        0.55×†         |    50     | ↑ from 0.34× at p=28; Python still ~2× faster consistently       |
| **Ln**             |        0.18×†         |    50     | 0.78× near 1; Python has cached ln(10) for power-of-10 args      |
| **Root (nth)**     |        0.25×†         |    50     | √ fast; general nth root **0.14–0.49×** (exp(ln(x)/n) costly)    |
| **Rounding**       |      **105.80×**      |    28     | Overwhelmingly faster (simple word truncation)                   |

\* Averages heavily skewed by fast-path cases (perfect squares, identity roots).  
† New results with precision = 50 (Mojo and Python at same precision). Previous results at mismatched precision (Mojo default 28–36 vs Python 10000) were not comparable.

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

**Analysis:** Addition is 2.0–2.5× faster for typical-precision decimals (≤28 digits). The SIMD-vectorized BigUInt addition gives an edge. At 2500+ digits, Python overtakes because `libmpdec` uses assembly-optimized routines for large coefficient arithmetic.

**Bottleneck:** Scale alignment via `multiply_by_power_of_ten` can be expensive if scales differ greatly, triggering large word-array expansions before the actual add.

---

### Subtraction (50 cases, precision=28)

| Size            | Mojo (ns) | Python (ns) | Speedup |
| --------------- | --------: | ----------: | :-----: |
| Typical (≤28 d) |   130–230 | 1,400–1,800 |  7–11×  |
| Zero result     |       141 |       1,585 |  11.2×  |
| Subtract 0      |        58 |       1,669 |  28.8×  |

**Analysis:** Subtraction is surprisingly fast — **~10× Python** on average. The gap vs addition speedup (2.2×) is noteworthy. This likely reflects Python `decimal`'s overhead for subtraction's sign handling and normalization, which `libmpdec` does not fast-path as well as addition.

---

### Multiplication (50 cases, precision=28)

| Size               | Mojo (ns) | Python (ns) | Speedup  |
| ------------------ | --------: | ----------: | :------: |
| Zero/one operand   |    36–100 |     258–264 | 2.6–7.2× |
| Small (≤28 digits) |    70–130 |     258–318 | 2.0–4.4× |
| Typical (28-digit) |    80–110 |     274–304 | 2.8–3.8× |

**Analysis:** Multiplication is consistently 3–4× faster for typical precision. This is excellent. The Karatsuba-accelerated BigUInt multiplication pays off even at small sizes because there's no overhead for scale handling (just add scales, XOR sign).

**Missing:** No benchmarks for very large multiplication (1000+ digit coefficients). This would be important for operations like `exp` at high precision, which need many large-coefficient multiplications internally.

---

### Division (64 cases, precision=50)

> **Update (2026-02-22):** Precision unified to 50 via TOML config. Both Mojo
> (`true_divide_general(a, b, precision)`) and Python (`getcontext().prec = 50`)
> now compute the same number of significant digits. Previous benchmarks used
> `comptime PRECISION = 4096` for Mojo and `prec = 4096` for Python.

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

**Asymmetric division (unbalanced operands) — BEFORE Task 1 FIX:**

| Size            |   Mojo (ns) | Python (ns) |   Speedup   |
| --------------- | ----------: | ----------: | :---------: |
| 65536w / 32768w | 444,571,666 |  50,058,333 | **0.11×** ✗ |
| 65536w / 16384w | 146,761,000 |  24,933,000 | **0.17×** ✗ |
| 65536w / 8192w  |  47,861,000 |  12,604,333 | **0.26×** ✗ |
| 65536w / 4096w  |  15,804,000 |   6,376,666 | **0.40×** ✗ |
| 65536w / 2048w  |   5,099,000 |   3,180,333 | **0.62×** ✗ |
| 65536w / 1024w  |   1,776,333 |     805,333 | **0.45×** ✗ |

**Asymmetric division — AFTER Task 1 FIX (2025-02-21):**

| Size            | Mojo (ns) | Python (ns) |  Speedup  |
| --------------- | --------: | ----------: | :-------: |
| 65536w / 32768w |   614,000 |  46,727,333 | **76.1×** |
| 65536w / 16384w |   299,333 |  23,327,666 | **77.9×** |
| 65536w / 8192w  |   149,000 |  11,748,000 | **78.8×** |
| 65536w / 4096w  |    89,000 |   5,974,666 | **67.1×** |
| 65536w / 2048w  |    42,666 |   3,079,000 | **72.2×** |
| 65536w / 1024w  |    24,000 |     749,333 | **31.2×** |

**Key findings:**

1. **Balanced division is outstanding** — 15–28× faster than Python at large sizes.
   Burnikel-Ziegler is very effective when both operands are similar size.
2. ~~**Asymmetric division is catastrophically slow**~~ **FIXED in Task 1.**
   Root cause was BigDecimal.true_divide_general computing full quotient then discarding.
   Now 31–79× faster than Python.
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

### Exp (50 cases)

#### BEFORE precision matching (Mojo default=36, Python prec=10000) — NOT comparable

These earlier results were invalid benchmarks: Mojo computed only 36 significant digits
while Python computed 10000. The speedup figures were misleading.

| Input        | Mojo (ns) | Python (ns) | Speedup | Note                  |
| ------------ | --------: | ----------: | :-----: | --------------------- |
| exp(0)       |        60 |       1,510 |  25.2×  | Fast-path (trivial)   |
| exp(1)       |    16,250 |       6,410 |  0.39×  | Mojo=36 vs Python=10K |
| exp(0.01)    |    11,750 |       4,030 |  0.34×  | ← unfair comparison   |
| exp(0.1)     |    14,480 |       6,270 |  0.43×  | ← unfair comparison   |
| exp(10)      |    17,740 |       7,710 |  0.43×  | ← unfair comparison   |
| exp(-1)      |    21,630 |       6,760 |  0.31×  | ← unfair comparison   |
| exp(1e-10)   |     3,840 |       1,670 |  0.43×  | ← unfair comparison   |
| exp(1000000) |    20,800 |      11,240 |  0.54×  | ← unfair comparison   |

Previous average: 0.34× (Python appeared ~3× faster)

#### AFTER precision matching (both precision=50, 2026-02-22)

All computations now produce identical results at 50 significant digits.
Zero correctness warnings except for extreme edge cases (`exp(-10000000)` etc. where
Python underflows to zero due to exponent range limits).

| Input       | Mojo (ns) | Python (ns) | Speedup  | Difference |
| ----------- | --------: | ----------: | :------: | :--------: |
| exp(0)      |       120 |         320 | **2.7×** |     0      |
| exp(1)      |   105,290 |      68,190 |  0.65×   |   0E-50    |
| exp(-1)     |   110,490 |      66,280 |  0.60×   |   0E-50    |
| exp(2)      |   106,350 |      67,730 |  0.64×   |   0E-50    |
| exp(0.1)    |    94,530 |      66,100 |  0.70×   |   0E-50    |
| exp(0.01)   |    90,420 |      42,280 |  0.47×   |   0E-50    |
| exp(0.5)    |   111,650 |      64,580 |  0.58×   |   0E-50    |
| exp(10)     |   106,420 |      65,860 |  0.62×   |   0E-49    |
| exp(100)    |   110,440 |      71,840 |  0.65×   |   0E-48    |
| exp(0.0001) |    58,200 |      25,590 |  0.44×   |   0E-50    |
| exp(1e-10)  |    27,960 |       9,850 |  0.35×   |   0E-50    |

**New average: ~0.55× (Python ~1.8× faster)**

**Analysis (updated):** With matched precision=50, Mojo's exp is **less slow than
previously reported** (0.55× vs the misleading 0.34×). The per-call cost is higher
because Mojo now computes 50 digits instead of 36, but the comparison is fair.
Python is still ~1.8× faster due to:

- `libmpdec`'s NTT-based multiplication for internal Taylor series arithmetic
- Optimized range reduction (reduction by `ln(10)`, not `ln(2)`)
- Correct rounding via Ziv's method (compute at slightly higher precision, retry if needed)

**Key insight:** The previous 0.34× figure was artificially deflated by Python
doing 278× more work (10000 vs 36 digits). The true gap is ~1.8×, which is
much more tractable for optimization via Task 3b–3d.

---

### Ln (50 cases)

> **Note (2026-02-22):** Ln was not benchmarked with matched precision before this
> update. Previous estimates came from the root cause analysis section (estimated
> ~0.3× Python at precision=28 based on exp performance). These are the first
> properly matched benchmarks.

#### Ln results with precision matching (both precision=50, 2026-02-22)

All computations produce identical results at 50 significant digits.
Zero correctness warnings (all differences are 0 or 0E-xxx with zero coefficient).

| Input     | Mojo (ns) | Python (ns) | Speedup  | Difference |
| --------- | --------: | ----------: | :------: | :--------: |
| ln(1)     |       300 |         300 | **1.0×** |     0      |
| ln(e)     | 6,607,540 |     120,050 |  0.02×   |   0E-200   |
| ln(2)     |   677,110 |     118,700 |  0.18×   |   0E-200   |
| ln(10)    | 1,007,810 |       1,130 |  0.001×  |   0E-199   |
| ln(0.5)   |   672,140 |     124,260 |  0.18×   |   0E-200   |
| ln(0.9)   |   162,430 |     126,330 |  0.78×   |   0E-200   |
| ln(0.99)  |    83,710 |      76,420 |  0.91×   |   0E-201   |
| ln(0.999) |    56,390 |      54,520 |  0.97×   |   0E-202   |
| ln(1.001) |    55,340 |      44,180 |  0.80×   |   0E-203   |
| ln(1.01)  |    80,630 |      55,160 |  0.68×   |   0E-202   |
| ln(1.1)   |   162,240 |      76,580 |  0.47×   |   0E-201   |
| ln(0.1)   |   994,350 |         770 |  0.001×  |   0E-199   |
| ln(100)   |   998,260 |       1,020 |  0.001×  |   0E-199   |
| ln(1e-10) |   993,000 |         710 |  0.001×  |   0E-198   |

**Key observations:**

1. **Values near 1 are competitive:** `ln(0.9)` = 0.78×, `ln(0.99)` = 0.91×, `ln(0.999)` = 0.97× — the Taylor series converges very fast for small arguments.
2. **Powers of 10 are catastrophically slow:** `ln(10)`, `ln(0.1)`, `ln(100)` show Mojo 1000× slower. Python's `libmpdec` caches `ln(10)` and computes `ln(10^k)` = `k × ln(10)` in O(1). Mojo must compute from scratch each time.
3. **ln(e)** is surprisingly slow (~6.6ms) because `e` = 2.718… is far from 1.0 and requires full range reduction + series evaluation.
4. **ln(2)** = 677µs vs Python's 119µs → 0.18×. This is the constant that `MathCache` optimizes for repeated calls.

**Analysis:** The ln performance landscape has two distinct regimes:

- **Near 1 (|x-1| < 0.1):** Mojo is 0.68–0.97× Python (nearly competitive)
- **Far from 1:** Mojo is 0.001–0.18× Python (extremely slow)

The far-from-1 case is dominated by range reduction to $x = m \times 2^k \times 1.25^j$, which requires computing `ln(2)` and `ln(1.25)` each time (unless cached via `MathCache`). The `MathCache` from Task 3a helps with repeated calls but can't eliminate the first-call cost.

**Python `libmpdec`'s advantage for ln:**

- Cached `ln(10)` at various precisions with sub-microsecond lookup
- Range reduction modulo `ln(10)` instead of `ln(2)` (more efficient for decimal base)
- NTT-based multiplication in the Taylor series
- Ziv's method for correct rounding

---

### Root (50 cases)

#### BEFORE precision matching (Mojo hardcoded=28, Python prec=10000) — NOT comparable

| Input                | Mojo (ns) | Python (ns) | Speedup | Note                  |
| -------------------- | --------: | ----------: | :-----: | --------------------- |
| √64 (perfect square) |     1,750 |      47,420 |  27.1×  | Fast-path             |
| √2 (irrational)      |     7,640 |      46,530 |  6.1×   | Mojo=28 vs Python=10K |
| ∛27 (perfect cube)   |   171,430 |      50,030 |  0.29×  | ← unfair comparison   |
| ∛10 (non-perfect)    |    85,080 |      17,340 |  0.20×  | ← unfair comparison   |
| ⁵√32                 |   175,460 |      47,870 |  0.27×  | ← unfair comparison   |
| ∛e                   |   291,100 |      51,200 |  0.18×  | ← unfair comparison   |
| 100th root of 2      |    15,450 |      40,130 |  2.6×   | ← unfair comparison   |

#### AFTER precision matching (both precision=50, 2026-02-22)

All computations produce identical results at 50 significant digits (4 edge cases
with 1–3 ULP last-digit difference, expected for compound `exp(ln(x)/n)`).

| Input                    | Mojo (ns) | Python (ns) |  Speedup  | Difference |
| ------------------------ | --------: | ----------: | :-------: | :--------: |
| √64 (perfect square)     |     1,500 |      60,730 | **40.5×** |   0E-49    |
| √(non-perfect)           |     7,250 |      74,510 | **10.3×** |   0E-49    |
| ∛27 (perfect cube)       |   243,570 |      58,390 |   0.24×   |   0E-49    |
| ∛10 (non-perfect)        |   145,880 |      20,440 |   0.14×   |   0E-49    |
| ⁴√16 (perfect power)     |   200,000 |      60,830 |   0.30×   |   0E-49    |
| ⁵√32 (perfect power)     |   242,190 |      62,390 |   0.26×   |   0E-49    |
| ¹⁰√1024 (perfect power)  |   149,830 |      37,660 |   0.25×   |   0E-49    |
| ∛(non-perfect, 4th root) |   129,020 |      63,560 |   0.49×   |   0E-49    |
| ¹⁰⁰√2                    |   116,780 |      20,170 |   0.17×   |   0E-49    |
| ⅓ root (0.333…)          |   241,970 |     100,710 |   0.42×   |   0E-49    |

**Before vs After comparison for Root:**

| Input         | Before Speedup | After Speedup | Change                                            |
| ------------- | :------------: | :-----------: | ------------------------------------------------- |
| √64           |     27.1×      |   **40.5×**   | ↑ Faster (precision=50 vs 28)                     |
| √2 (non-perf) |      6.1×      |   **10.3×**   | ↑ Faster (new sqrt case)                          |
| ∛27           |     0.29×      |     0.24×     | ≈ Same (fair comparison now)                      |
| ∛10           |     0.20×      |     0.14×     | ↓ Slightly worse (Python was undercounted before) |
| ⁵√32          |     0.27×      |     0.26×     | ≈ Same                                            |

**Analysis (updated):** Square roots are fast-pathed via `BigUInt.sqrt()` and show excellent speedups (10–40×). Non-square roots (cube, 5th, etc.) delegate to `exp(ln(x)/n)`, which requires two expensive transcendental function evaluations. At precision=50, general nth root is **0.14–0.49× Python**, confirming that Task 7 (direct Newton for nth root) is important.

**Python `libmpdec`** computes nth root directly via Newton's method ($x_{k+1} = ((n-1)x_k + a/x_k^{n-1})/n$), avoiding the `exp(ln(x)/n)` detour.

---

### Rounding (25 cases, precision=28)

Avg 105.8×. This is dominated by the overhead of Python's `decimal.quantize()` vs Mojo's direct word-level truncation. Not a concern for optimization.

---

## Multi-Precision Scaling Analysis (2026-02-22)

> **Why multi-precision?** A single precision level (e.g., p=50) only tests small-sized
> computation. Precision determines problem size for transcendental functions — at p=50,
> BigUInt coefficients are ~6 words; at p=1000, they're ~112 words. Scaling behavior
> reveals where algorithmic complexity differences dominate.

### Exp — Multi-Precision Scaling (p=50 to 1000)

Benchmarked 12 representative cases at 5 precision levels. Iterations decrease with
precision to keep total bench time manageable (50→20→5→2→1).

**Summary table (excluding trivial exp(0)):**

| Case        |  p=50 | p=100 | p=200 | p=500 | p=1000 |
| ----------- | ----: | ----: | ----: | ----: | -----: |
| exp(1)      | 0.48× | 0.43× | 0.63× | 1.07× |  1.09× |
| exp(-1)     | 0.44× | 0.37× | 0.62× | 1.16× |  1.17× |
| exp(2)      | 0.52× | 0.42× | 0.65× | 1.07× |  1.02× |
| exp(0.5)    | 0.52× | 0.34× | 0.63× | 1.08× |  0.95× |
| exp(-0.5)   | 0.40× | 0.35× | 0.55× | 0.96× |  1.02× |
| exp(0.01)   | 0.26× | 0.30× | 0.50× | 0.80× |  0.88× |
| exp(0.1)    | 0.45× | 0.44× | 0.80× | 1.15× |  1.13× |
| exp(10)     | 0.58× | 0.40× | 0.60× | 1.04× |  1.09× |
| exp(-10)    | 0.45× | 0.33× | 0.53× | 0.94× |  1.03× |
| exp(100)    | 0.57× | 0.41× | 0.63× | 1.13× |  1.10× |
| exp(0.0001) | 0.21× | 0.23× | 0.41× | 0.65× |  0.75× |

**Key findings:**

1. **Mojo exp catches up to Python at high precision.** At p=500, Mojo is roughly **1.0× Python** for most inputs. At p=1000, Mojo is **slightly faster** (1.02–1.17×) for standard inputs.
2. **At p=50, Mojo is 0.21–0.58×** — Python's constant-factor advantages (optimized C, NTT at small sizes) dominate.
3. **The crossover happens around p=200–500.** This suggests Mojo's Karatsuba (which kicks in at ~8 words ≈ 72 digits) is competitive with libmpdec's NTT for medium-sized operands, and Mojo's Taylor series implementation has acceptable overhead.
4. **exp(0.0001) and exp(0.01) are consistently the slowest relative to Python.** These involve very small arguments where Python's fast-path optimizations (fewer Taylor terms, early truncation) are more effective.

**Absolute timing growth (exp(1)):**

| Precision | Mojo (ns) | Python (ns) | Ratio |
| --------: | --------: | ----------: | ----: |
|        50 |    19,260 |       9,280 | 0.48× |
|       100 |    34,850 |      15,150 | 0.43× |
|       200 |   104,600 |      66,000 | 0.63× |
|       500 |   824,000 |     879,500 | 1.07× |
|     1,000 | 4,168,000 |   4,553,000 | 1.09× |

Mojo scales at roughly $O(p^{2.3})$ while Python scales at $O(p^{2.5})$ — Mojo's per-step cost is higher at small sizes but grows slower, leading to the crossover.

---

### Ln — Multi-Precision Scaling (p=50 to 1000)

Benchmarked 12 representative cases at 5 precision levels.

**Summary table (excluding trivial ln(1)):**

| Case      |   p=50 |  p=100 |  p=200 |   p=500 |  p=1000 |
| --------- | -----: | -----: | -----: | ------: | ------: |
| ln(2)     | 16.13× |  0.21× |  0.17× |   0.14× |   0.11× |
| ln(e)     |  0.05× |  0.02× |  0.02× |   0.02× |   0.03× |
| ln(10)    | 0.008× | 0.003× | 0.001× | 0.0004× | 0.0002× |
| ln(0.5)   | 13.55× |  0.23× |  0.18× |   0.15× |   0.11× |
| ln(0.9)   |  0.57× |  0.46× |  0.76× |   1.78× |   3.57× |
| ln(0.99)  |  0.56× |  0.53× |  0.87× |   2.41× |   4.24× |
| ln(1.01)  |  0.44× |  0.41× |  0.62× |   1.30× |   3.83× |
| ln(1.1)   |  0.28× |  0.28× |  0.46× |   1.19× |   2.45× |
| ln(100)   | 0.007× |   0.0× | 0.001× | 0.0003× | 0.0002× |
| ln(0.001) | 0.010× |   0.0× | 0.002× | 0.0003× | 0.0002× |
| ln(PI)    |  0.04× |  0.02× |  0.02× |   0.02× |   0.03× |

**Key findings:**

1. **Near-1 inputs show dramatic improvement with precision.** `ln(0.99)` goes from 0.56× at p=50 to **4.24×** at p=1000! `ln(0.9)` goes from 0.57× to **3.57×**. This means Mojo's AGM-like convergence for near-1 arguments scales much better than Python at high precision.
2. **ln(2) anomaly at p=50:** Shows 16× speedup because at p=50 both Mojo and Python are very fast (1.3µs vs 21.9µs), likely a caching hit or fast-path in Mojo. At p=100+, the relationship normalizes to 0.11–0.21×.
3. **Powers-of-10 get catastrophically WORSE with precision.** `ln(10)` goes from 0.008× to 0.0002× — Mojo scales $O(p^2)$ while Python returns cached `ln(10)` in $O(1)$.
4. **ln(e) and ln(PI) remain consistently slow (0.02–0.05×)** because they require full argument reduction + series evaluation, while Python benefits from NTT multiplication in the series.
5. **The near-1 crossover happens around p=200–500**, similar to exp. This confirms the pattern: Mojo's Karatsuba becomes competitive with libmpdec's NTT at ~100+ digits.

**Two distinct scaling regimes in ln:**

| Regime     |    p=50     |    p=1000    | Scaling             |
| :--------- | :---------: | :----------: | :------------------ |
| Near-1 (   |     x-1     |    <0.1)     | 0.44–0.57×          | 2.45–4.24× | **Mojo wins big** |
| Far-from-1 | 0.005–0.18× | 0.0002–0.11× | **Mojo loses more** |

**Why the split?** Near-1 inputs use a Taylor series that converges in few terms with small coefficients — multiplication cost dominates, and Karatsuba scales well. Far-from-1 inputs require: (a) computing `ln(2)` and `ln(1.25)` from scratch (Python caches `ln(10)`), (b) many more series terms, (c) full-precision arithmetic on larger intermediate values.

**Absolute timing growth (ln(0.99), near-1 case):**

| Precision | Mojo (ns) | Python (ns) | Ratio |
| --------: | --------: | ----------: | ----: |
|        50 |    21,000 |      11,760 | 0.56× |
|       100 |    41,450 |      21,800 | 0.53× |
|       200 |    86,800 |      75,400 | 0.87× |
|       500 |   295,000 |     712,000 | 2.41× |
|     1,000 | 1,012,000 |   4,287,000 | 4.24× |

Mojo scales at $O(p^{1.8})$ while Python scales at $O(p^{2.8})$ for this near-1 case — a dramatic difference that explains the crossover.

**Absolute timing growth (ln(10), far-from-1 case):**

| Precision |  Mojo (ns) | Python (ns) |   Ratio |
| --------: | ---------: | ----------: | ------: |
|        50 |     75,120 |         600 |  0.008× |
|       100 |    368,750 |       1,050 |  0.003× |
|       200 |    988,600 |         800 |  0.001× |
|       500 |  9,316,000 |       4,000 | 0.0004× |
|     1,000 | 53,970,000 |      13,000 | 0.0002× |

Python's `ln(10)` time is essentially $O(1)$ (sub-microsecond at all precisions due to caching). Mojo's time grows as $O(p^{2.5})$ — pure algorithmic mismatch.

---

### Implications for Task Priorities

The multi-precision data reveals that **the optimization landscape depends heavily on the target precision range**:

**For p ≤ 100 (most common use cases):**

- Exp is 0.3–0.6× Python → needs Task 3b (cheap integer division) and constant-factor improvements
- Ln near-1 is 0.4–0.6× → same as exp
- Ln far-from-1 is 0.001–0.2× → needs cached `ln(10)` (Task 3 variant)

**For p = 200–500 (medium precision):**

- Exp is at parity or slightly ahead → **no action needed!**
- Ln near-1 is catching up → will be ahead by p=500
- Ln far-from-1 still poor → `ln(10)` caching critical

**For p ≥ 1000 (high precision):**

- Exp is **1.0–1.2× Python** → Mojo already wins! 🎉
- Ln near-1 is **2.5–4.2× Python** → Mojo dominates here
- Ln far-from-1 is **0.0002× Python** → catastrophic, but caused by single factor (cached `ln(10)`)

**Revised task priorities based on multi-precision data:**

1. **Cache `ln(10)` in MathCache** (new Task 3c) — this single change would fix the catastrophic ln(10)/ln(100)/ln(0.001) cases across ALL precision levels. Extremely high ROI.
2. **Task 3b** (cheap integer division) — still valuable for p<200 where exp is 0.3–0.6×
3. **Task 7** (direct nth root) — still important (avoids exp+ln, which is the bottleneck)
4. **Task 4** (reciprocal sqrt) — less critical now that we know Mojo catches up at high precision
5. **Task 5** (NTT) — less urgent than thought; Karatsuba is competitive up to p=1000

---

## Root Cause Analysis: Where Performance Is Lost

### 1. **Division (asymmetric case): ~~0.11–0.62× Python~~ → 31–79× Python** — Task 1 ✓ FIXED

~~The Burnikel-Ziegler algorithm pads the divisor up to match the dividend's block structure.~~ **Actual root cause:** `BigDecimal.true_divide_general()` computed full quotient coefficients regardless of the needed precision, then discarded excess digits via rounding. For 65536w/32768w at precision=4096, this meant a 65994-word / 32768-word integer division when only a ~458-word quotient was needed. Fix: compute
`extra_words = ceil(P/9) + 2 - diff_n_words` and truncate the dividend when negative.

### 2. **Exp function: ~~0.35–0.65×~~ → 0.48× at p=50, **1.09× at p=1000** — Task 3 targets (partially resolved at high precision)

Previous estimate (0.31–0.43×) was based on mismatched precision (Mojo=36, Python=10000).
Multi-precision analysis reveals the gap is **precision-dependent**: at p=50 Mojo is ~0.48×,
but at p=500+ Mojo catches up to parity and at p=1000 **slightly exceeds Python** (1.09×).
The primary remaining gap is at small precisions (p<200) where Python's constant-factor
advantages (optimized C codepath, efficient small-number handling) dominate.

### 3. **Ln function: two radically different regimes (confirmed across all precision levels)**

Multi-precision analysis confirms ln has two fundamentally different performance profiles:

- **Near 1 (|x-1| < 0.1):** Mojo scales as $O(p^{1.8})$ vs Python's $O(p^{2.8})$.
  Mojo is 0.56× at p=50 but **4.24× at p=1000**. Major win at high precision.
- **Far from 1 (powers of 10):** Mojo scales as $O(p^{2.5})$ vs Python's $O(1)$ (cached).
  The gap widens from 0.008× at p=50 to **0.0002× at p=1000**. Root cause: Python caches
  `ln(10)` at various precisions; Mojo computes from scratch.

**Fix:** Add `get_ln10(precision)` to `MathCache` — eliminates the far-from-1 catastrophe.

### 4. **Sqrt (irrational, high precision): 0.55–0.72× Python**

Newton's method for sqrt requires one division per iteration. At precision=5000, each division is on ~556-word numbers. The `BigUInt.sqrt()` converges in ~15–20 iterations. `libmpdec` uses reciprocal sqrt (no division) and NTT multiplication.

### 5. **Addition at very large sizes: 0.76× Python at 3000+ digits**

BigUInt's SIMD vectorized addition (width=4) is fast but scale alignment (`multiply_by_power_of_ten`) for large scale differences creates oversized intermediate arrays.

---

## Literature Review: How Major Decimal Libraries Are Designed

### 1. Python `decimal` → `libmpdec` (Stefan Krah)

**Internal representation:** base-$10^9$ (`uint32_t` limbs), optionally base-$10^{19}$ (`uint64_t`) on 64-bit platforms. Sign + exponent + coefficient (similar to DeciMojo).

**Key algorithms:**

- **Multiplication:** Schoolbook for small, Karatsuba for medium, **Number Theoretic   Transform (NTT)** for large (>1024 limbs). NTT is in-place, uses three primes   (MPD_PRIMES) enabling Chinese Remainder Theorem reconstruction for exact results. $O(n \log n)$ — this is the primary advantage over DeciMojo's $O(n^{1.585})$ Karatsuba.
- **Division:** Schoolbook for small, then balanced division via Newton's method for the reciprocal (`1/y`), computed using *NTT-multiplied** Newton iterations: $r_{k+1} = r_k(2 - yr_k)$. This avoids explicit long division entirely for large operands. $O(M(n))$ where $M(n)$ is the cost of multiplication.
- **Sqrt:** Reciprocal square root via Newton ($r_{k+1} = r_k(3 - yr_k^2)/2$) then multiply ($\sqrt{y} = y \cdot r$). Again uses NTT multiplication, never divides.
- **Exp/Ln:** Correct rounding via Ziv's method. Range reduction + Taylor/Maclaurin series, with all multiplications done via NTT at large precision.

**Why it's fast:** NTT gives $O(n \log n)$ multiplication for all sizes above ~1000 digits. Since division and sqrt are reduced to multiplication, all operations benefit.

**Source:** `Modules/_decimal/libmpdec/` in CPython source.

### 2. GMP / MPFR (GNU Multi-Precision)

**Internal representation:** base-$2^{64}$ (or $2^{32}$). Binary, not decimal.

**Key algorithms:**

- **Multiplication:** Schoolbook → Karatsuba → Toom-3 → Toom-4 → Toom-6.5 → Toom-8.5 → **FFT** (Schönhage-Strassen). Seven levels of algorithms, carefully tuned with machine-specific thresholds. The FFT is $O(n \log n \log \log n)$.
- **Division:** $O(M(n))$ via Newton (reciprocal iteration) using fast multiplication.
- **Sqrt:** $O(M(n))$ via reciprocal sqrt Newton.

**Note:** MPFR is a **binary** floating-point library. It provides exact rounding for mathematical functions (exp, ln, sin, etc.) using Ziv's method. Not directly comparable to decimal arithmetic, but the algorithms translate.

**DeciMojo relevance:** GMP's chain Schoolbook → Karatsuba → Toom-3 → FFT suggests DeciMojo should implement Toom-3 as the next multiplication tier before
considering NTT.

### 3. mpdecimal (Rust) / `rust_decimal`

**`rust_decimal`:** Fixed 96-bit coefficient (28 significant digits max). Not comparable to arbitrary precision.

**`bigdecimal` (Rust):** base-$10^9$ limbs via `num-bigint`. Uses the same Schoolbook → Karatsuba → Toom-3 progression from `num-bigint`. No NTT. Performance is typically 2–5× slower than Python `decimal` for very large numbers due to lack of NTT.

### 4. Java `BigDecimal` (OpenJDK)

**Internal representation:** Unscaled `BigInteger` + 32-bit scale. Binary internally.

**Key algorithms:**

- `BigInteger` multiplication: Schoolbook → Karatsuba (≥80 ints/2560 bits) → Toom-3 (≥240 ints/7680 bits) → **Parallel Schönhage** (≥10240 ints). Uses fork-join for parallel multiplication.
- Division: Burnikel-Ziegler for large divisions, delegated to Knuth's Algorithm D at the base case.
- Sqrt: Newton's method with binary integer arithmetic.

**Note:** Java `BigDecimal` stores the coefficient in **binary** (as a `BigInteger`), not base-10^9. All base-10 formatting is done at I/O time. This gives Java the full benefit of binary arithmetic speed for internal computation.

### 5. Intel® Decimal Floating-Point Math Library (BID)

**Internal representation:** Binary Integer Decimal (BID) — coefficient is stored as a binary integer, exponent is power-of-10. This is IEEE 754-2008 decimal.

**Key insight:** By storing the coefficient in binary, BID gets fast binary arithmetic for +, -, *, and only pays the decimal conversion cost at I/O boundaries.

### 6. `mpd` — Mike Cowlishaw's General Decimal Arithmetic

The **specification** that Python `decimal` implements. Not a library per se, but defines the semantics. All conforming implementations share the same behavior.

---

## Design Question: Should BigDecimal Use BigUInt (10^9) or BigInt2 (2^32)?

### Current Design: base-$10^9$ (BigUInt)

**Advantages:**

- ✓ **Trivial I/O:** `to_string()` is $O(n)$ — just print each 9-digit word with   zero padding. No expensive base conversion. This matters hugely for financial apps.
- ✓ **Exact scale arithmetic:** Adding trailing zeros or shifting decimal point = insert/remove whole words of zeros. No multiplication by powers of 10 needed.
- ✓ **Natural precision control:** Truncating to $p$ significant digits = keeping $\lceil p/9 \rceil$ words. Rounding operates on decimal digit boundaries.
- ✓ **Simple debugging:** Internal state is human-readable.
- ✓ **No representation error:** "0.1" is stored exactly.

**Disadvantages:**

- ✗ **Wasted bits:** Each 32-bit word stores $\log_2(10^9) ≈ 29.9$ bits of information out of 32 bits — 6.5% waste. Not critical but adds up in memory and cache.
- ✗ **Complex carry/borrow:** Carries are at $10^9$ boundary, requiring UInt64 intermediate products and modulo/division. Binary carry is a single bit shift.
- ✗ **Sqrt/Newton division less efficient:** Per-iteration cost is higher than binary because each BigUInt division involves more complex quotient estimation.
- ✗ **No NTT:** NTT requires prime-modular arithmetic on binary words. Doing NTT in base-$10^9$ is possible (`libmpdec` does it) but the primes must be carefully chosen.

### Alternative: base-$2^{32}$ (BigInt2)

**Advantages:**

- ✓ **Maximum bit density:** Every bit used.
- ✓ **Simpler carry:** Single-bit carry propagation, pipeline-friendly.
- ✓ **Standard algorithms apply directly:** Karatsuba, Toom, NTT all work naturally.
- ✓ **Hardware-aligned:** SIMD, popcount, clz all work directly on limbs.
- ✓ **Better benchmark performance:** BigInt2 is 4.3× Python for addition vs
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
   `libmpdec` has NTT and DeciMojo doesn't. Once NTT is implemented (Task 5), the
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

### Task 1: Fix Asymmetric Division Performance ✓ COMPLETED

**Priority: CRITICAL** — Was 0.11× Python, now **31–79× Python**

**Root cause:** The real bottleneck was NOT in B-Z itself, but in
`BigDecimal.true_divide_general()`. When dividend has $d$ more coefficient words
than divisor, the function always padded by `ceil(P/9) + 2` extra words WITHOUT
subtracting the existing surplus $d$. For 65536w/32768w at precision=4096:
the integer division was **65994w / 32768w → ~33226-word quotient**, but only
**~458 words** were needed. The **32768 excess quotient words** were computed
and immediately discarded by rounding. The exact-check multiplication
(`q × b == a_scaled`) on these oversized operands compounded the waste.

**Fix (2 lines changed in `arithmetics.mojo`):**

```python
# Before (BUG): extra_words = ceil(P/9) + 2  ← ignores positive diff_n_words
# After  (FIX): extra_words = ceil(P/9) + 2 - diff_n_words
```

When `extra_words < 0`, the dividend is truncated via
`floor_divide_by_power_of_billion()` to eliminate unnecessary low-order
words, and the exact-division check is skipped (truncation discards the
information needed for that check; exactness is vanishingly unlikely
for large asymmetric operands anyway).

Also fixed a bug in `true_divide_fast()`: was passing `-extra_words * 9`
(9× too many words) to `floor_divide_by_power_of_billion()`.

**Actual benchmark results (2025-02-21):**

| Size            | Before (ns) | Before | After (ns) |     After | Improvement |
| --------------- | ----------: | -----: | ---------: | --------: | ----------: |
| 65536w / 32768w | 444,571,666 |  0.11× |    614,000 | **76.1×** |    **724×** |
| 65536w / 16384w | 146,761,000 |  0.17× |    299,333 | **77.9×** |    **490×** |
| 65536w / 8192w  |  47,861,000 |  0.26× |    149,000 | **78.8×** |    **321×** |
| 65536w / 4096w  |  15,804,000 |  0.40× |     89,000 | **67.1×** |    **178×** |
| 65536w / 2048w  |   5,099,000 |  0.62× |     42,666 | **72.2×** |    **119×** |
| 65536w / 1024w  |   1,776,333 |  0.45× |     24,000 | **31.2×** |     **74×** |

Balanced cases unchanged (15–24× Python). Overall average speedup: **12.4× Python**.

---

### Task 2: Reciprocal-Newton Division (Avoids Explicit Long Division)

**Priority: HIGH** — Reduces division to multiplication at large sizes

**Algorithm:** Instead of directly computing $q = a / b$:

1. Compute $r \approx 1/b$ using Newton's iteration: $r_{k+1} = r_k(2 - br_k)$
2. Then $q = a \times r$ (one multiplication)
3. Adjust by at most ±1 using a correction step

**Key requirement:** The Newton iteration uses only multiplication (no division), so this is $O(M(n))$ where $M(n)$ is multiplication cost. With NTT (Task 5), this becomes $O(n \log n)$.

**Without NTT (i.e., with Karatsuba only):** $O(n^{1.585})$ — still better than schoolbook division's $O(n^2)$, and avoids the B-Z recursion overhead.

**Expected gain at precision=5000:**

- Current (B-Z + schoolbook base): division ≈ 400µs per 556-word division
- With reciprocal-Newton + Karatsuba: ≈ 150µs (estimated from 2× multiply cost)
- This directly speeds sqrt by ~2× (each Newton iteration has one division)

---

### Task 3: Optimized Exp/Ln (Reduce Iteration Count and Per-Iteration Cost)

**Priority: HIGH** — Currently 0.31–0.43× Python

**Sub-optimizations:**

#### Task 3a: Cache `ln(2)` and `ln(1.25)` — ✓ COMPLETED (2026-02-22)

**Problem:** `ln(2)` and `ln(1.25)` were recomputed on every `ln()` call. At precision=28, this wastes ~5µs per call. Functions like `log()` that call `ln()` twice internally pay this cost doubly.

**Solution:** Implemented `MathCache` struct in `exponential.mojo` — a user-passable cache that stores computed values of `ln(2)` and `ln(1.25)` with their precision levels. Auto-handles precision upgrades (if cached at P1, requesting P2 > P1 recomputes and re-caches).

**Implementation details:**

- Added `struct MathCache` with `get_ln2(precision)` / `get_ln1d25(precision)` methods
- Added overloaded `fn ln(x, precision, mut cache: MathCache)` as the primary implementation
- Original `fn ln(x, precision)` delegates to cached version with a local cache (100% backward compatible)
- `log()` and `log10()` now create a local `MathCache` so their 2 internal `ln()` calls share cached constants
- Added `BigDecimal.ln(precision, cache)` method overload
- Exported `MathCache` from `decimojo` top-level

**Measured speedup (10× ln() calls at same precision, with shared MathCache):**

- precision=100: **~3× faster** (4ms → 1ms)
- precision=500: **~4.5× faster** (103ms → 23ms)

**Limitation (documented compromise):** Mojo doesn't support module-level mutable variables, so each standalone `ln()` call still creates a fresh `MathCache`. The full benefit requires: (a) internal callers like `log()` sharing a local cache, or (b) users manually passing a cache across multiple `ln()` calls. When Mojo adds global variables, a single global `MathCache` will eliminate all redundant computation automatically.

#### Task 3b: Replace Division in Taylor Series with Multiplication by Reciprocal

**Current:** Each Taylor term computes `term = term * x / n`. The division by $n$ (a small integer) is a BigDecimal division, which is overkill.

**Fix:** For small integer divisors $n$, use `BigUInt.floor_divide_by_uint32(n)` directly on the coefficient, avoiding BigDecimal division overhead entirely. This is already implemented in BigUInt — just not used by the Taylor series.

**Expected gain:** Each iteration drops from ~2000ns to ~200ns (division by small integer is 10× cheaper than general division). For 70 iterations, saves ~126µs.

#### Task 3c: Binary Splitting for Exp/Ln Series

**Current:** Sequential Taylor series, one term at a time. Each term depends on the previous term.

**Fix:** Use binary splitting to evaluate $\sum \frac{x^k}{k!}$ as a single rational $p/q$ with exact `BigUInt` arithmetic (same approach used for π Chudnovsky), then do a single final division.

**Benefit:** Reduces $O(p)$ BigDecimal divisions to $O(1)$ final division + $O(p \log p)$ BigUInt multiplications. At large precision, this is dramatically faster.

**Note:** This is how `libmpdec` internally handles the series. It's the main reason Python exp is 3× faster.

#### Task 3d: Better Range Reduction for Exp

**Current:** Halving strategy — divide by $2^k$ until $x < 1$, then square $k$ times. Each squaring is a full-precision multiplication.

**Better:** Reduce $x$ modulo $\ln(10)$ so the reduced argument is much smaller, requiring fewer Taylor terms. Then reconstruct using $e^{k\ln 10} = 10^k$ (trivial in base-$10^9$).

---

### Task 4: Optimized Sqrt (Reciprocal Square Root, Avoid Division)

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

**With NTT (Task 5):**

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

### Task 5: Number Theoretic Transform (NTT) for Large Multiplication

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

### Task 6: Toom-3 Multiplication (Intermediate Step Before NTT)

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

### Task 7: Nth Root via Newton's Method (Avoid exp(ln(x)/n))

**Priority: MEDIUM** — Currently 0.18–0.33× Python for general nth root

**Current:** `root(x, n)` = `exp(ln(x) / n)`, requiring two expensive transcendental
function evaluations.

**Better:** Direct Newton's method for $x^{1/n}$:
$$r_{k+1} = \frac{1}{n}\left((n-1)r_k + \frac{x}{r_k^{n-1}}\right)$$

This requires only one division and one `power(r, n-1)` per iteration. For small $n$
(2, 3, 4, 5), unroll the power manually.

**Even better (after Task 2):** Reciprocal-Newton for $r = x^{-1/n}$:
$$r_{k+1} = r_k \cdot \frac{n+1 - x \cdot r_k^n}{n}$$

Then $x^{1/n} = x \cdot r$. Uses only multiplications (no division).

---

### Task 8: In-Place Arithmetic for BigUInt (Reduce Allocations)

**Priority: MEDIUM** — Broad 10–30% improvement across all operations

Many BigUInt operations currently allocate new word lists unnecessarily:

- Addition: `add_slices_simd` allocates a result then assigns to `self`
- Multiplication in Taylor series: each `term *= x` creates a new BigUInt
- Scale alignment: `multiply_by_power_of_ten` always allocates new

**Fix:** Implement true in-place operations (similar to BigInt2's Task 5):

- `add_inplace(mut self, other)` with capacity pre-check
- `multiply_inplace_by_uint32(mut self, v)` operating on existing buffer
- `multiply_by_power_of_ten_inplace(mut self, n)` extending existing buffer

---

### Task 9: SIMD-Optimized BigUInt Multiplication

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
| Ln                   |  Taylor series (sequential)  |    Taylor + cached `ln(10)` + **NTT**    |  Major gap (3a partially mitigates)  |
| I/O (to/from string) |        $O(n)$ trivial        |              $O(n)$ trivial              |                Parity                |
| Rounding             |    Word-level truncation     |                 Similar                  |           Mojo 100× faster           |

**Bottom line:** The performance gap is not about the base representation. It's about
the algorithm tier for large numbers: NTT multiplication, reciprocal-based division
and sqrt, and binary splitting for series evaluation. These are all implementable in
base-$10^9$.

---

## Before vs After Optimization Summary (All Operations)

> **Date:** 2026-02-22. All benchmarks run on macOS arm64 Apple Silicon (M-series).
> All "After" results use precision-matched benchmarks via TOML config (`precision` field).

### Completed Optimizations

#### Task 1: Fix Asymmetric Division (2026-02-21)

| Case            | BEFORE (ns) | BEFORE vs Python | AFTER (ns) | AFTER vs Python | Improvement |
| --------------- | ----------: | :--------------: | ---------: | :-------------: | ----------: |
| 65536w / 32768w | 444,571,666 |      0.11×       |    614,000 |    **76.1×**    |    **724×** |
| 65536w / 16384w | 146,761,000 |      0.17×       |    299,333 |    **77.9×**    |    **490×** |
| 65536w / 8192w  |  47,861,000 |      0.26×       |    149,000 |    **78.8×**    |    **321×** |
| 65536w / 4096w  |  15,804,000 |      0.40×       |     89,000 |    **67.1×**    |    **178×** |
| 65536w / 2048w  |   5,099,000 |      0.62×       |     42,666 |    **72.2×**    |    **119×** |
| 65536w / 1024w  |   1,776,333 |      0.45×       |     24,000 |    **31.2×**    |     **74×** |

**Root cause:** `true_divide_general()` computed full quotient regardless of needed precision.
**Fix:** `extra_words = ceil(P/9) + 2 - diff_n_words` + truncate dividend when excess.

#### Task 3a: MathCache for ln(2)/ln(1.25) (2026-02-22)

| Scenario                              | BEFORE |  AFTER |  Speedup |
| ------------------------------------- | -----: | -----: | -------: |
| 10× ln() calls, precision=100, cached |   4 ms |   1 ms |   **3×** |
| 10× ln() calls, precision=500, cached | 103 ms |  23 ms | **4.5×** |
| log(x) — 2 internal ln() calls shared |  2× ln | ~1× ln |   **2×** |

**Root cause:** `ln(2)` and `ln(1.25)` recomputed on every `ln()` call.
**Fix:** `MathCache` struct caches computed constants with precision-aware invalidation.

#### Benchmark Infrastructure: Precision Unification (2026-02-22)

| Bench File | BEFORE (Mojo prec / Python prec) | AFTER                    |
| ---------- | :------------------------------: | :----------------------- |
| ln         |       36 / 10000 ← UNFAIR        | **50 / 50** via TOML     |
| exp        |       36 / 10000 ← UNFAIR        | **50 / 50** via TOML     |
| root       | 28 (hardcoded) / 10000 ← UNFAIR  | **50 / 50** via TOML     |
| sqrt       |       5000 / 5000 (was OK)       | **5000 / 5000** via TOML |
| divide     | 4096 (comptime) / 4096 (was OK)  | **50 / 50** via TOML     |

All bench files now:

- Read `precision` from TOML `[config]` section
- Pass it to both Mojo's BigDecimal methods and Python's `getcontext().prec`
- Flag non-zero differences via `diff.is_zero()` with `*** WARNING ***` message

### Updated Performance Scorecard

| Operation       | Before Optimization | After Optimization | Change                                   |
| --------------- | :-----------------: | :----------------: | ---------------------------------------- |
| Addition        |        2.22×        |       2.22×        | (no change)                              |
| Subtraction     |        9.79×        |       9.79×        | (no change)                              |
| Multiplication  |        3.44×        |       3.44×        | (no change)                              |
| Division (sym)  |       15–28×        |       15–28×       | (no change)                              |
| Division (asym) |     0.11–0.62×      |     **31–79×**     | ↑ **Task 1** — 74–724× raw improvement   |
| Sqrt (irrat)    |     0.55–0.72×      |     0.55–0.72×     | (no change, sqrt bench was already fair) |
| **Exp**         |       ~0.34×*       |     **~0.55×**     | ↑ **Precision fix** — was unfair before  |
| **Ln (near 1)** |      (no data)      |   **0.68–0.97×**   | ✱ NEW — first fair benchmark             |
| **Ln (far)**    |      (no data)      |  **0.001–0.18×**   | ✱ NEW — reveals ln(10) caching gap       |
| **Root (nth)**  |     0.18–0.33×*     |   **0.14–0.49×**   | ↑ **Precision fix** — was unfair before  |
| Root (√)        |        27.1×        |     **40.5×**      | ↑ Better with matched precision          |
| Rounding        |       105.8×        |       105.8×       | (no change)                              |

\* Previous values were measured with mismatched precision (Mojo 28–36 digits vs Python 10000 digits) and were not valid benchmarks. The "Before" column shows the originally reported numbers for historical reference.

### What Changed and Why

1. **Division asymmetric: 0.11× → 76×** — Algorithmic fix in `true_divide_general()`.
   The biggest single improvement. Two-line fix eliminated 99.8% of wasted computation.

2. **Exp: 0.34× → 0.55×** — Not an algorithmic improvement; the 0.34× was an artifact
   of Python computing 278× more digits. The true gap is ~1.8× (Python faster), much
   more tractable for future optimization (Task 3b–3d).

3. **Ln: first real data** — Reveals two regimes. Near 1: nearly competitive (0.97×).
   Far from 1: Python's cached `ln(10)` is game-changing. `MathCache` (Task 3a) helps
   with repeated calls but can't eliminate first-call cost without global variables.

4. **Root: 0.18× → 0.14× (corrected)** — The previous 0.18× was actually optimistic
   because Python was doing 357× more precision. With fair comparison, nth root is
   0.14–0.49× Python. Task 7 (direct Newton) is the fix.

### Remaining Targets

| Priority  | Task    |     Current     |   Target    | Approach                                            |
| --------- | ------- | :-------------: | :---------: | --------------------------------------------------- |
| HIGH      | Task 3b |    0.55× exp    |  0.8–1.0×   | Replace Taylor division with multiply-by-reciprocal |
| HIGH      | Task 4  | 0.55–0.72× sqrt |  1.5–2.0×   | Reciprocal sqrt Newton (no division)                |
| HIGH      | Task 7  | 0.14–0.49× root |  1.0–2.0×   | Direct Newton for nth root                          |
| HIGH      | Task 8  |        —        | +10–30% all | In-place BigUInt operations                         |
| MEDIUM    | Task 2  |   15–28× div    |   30–50×    | Reciprocal-Newton division                          |
| LONG-TERM | Task 5  |        —        | 2–10× large | NTT multiplication                                  |
