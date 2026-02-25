"""Benchmarks for BigDecimal ln. Compares against Python decimal.

Multi-precision benchmark: runs each case at multiple precision levels
(50, 100, 200, 500, 1000) to show how performance scales with precision.
"""

from decimo.bigdecimal.bigdecimal import BigDecimal
import decimo.bigdecimal.arithmetics
import decimo.bigdecimal.exponential
from decimo.tests import (
    BenchCase,
    PrecisionLevel,
    load_bench_cases,
    load_bench_precision_levels,
    open_log_file,
    log_print,
    print_header,
    print_summary,
)
from python import Python, PythonObject
from time import perf_counter_ns
from collections import List


fn run_case(
    bc: BenchCase,
    iterations: Int,
    precision: Int,
    pydecimal: PythonObject,
    log_file: PythonObject,
    mut sf: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80], log_file)

    var m_a = BigDecimal(bc.a)
    var pa = pydecimal.Decimal(bc.a)

    try:
        var rm = m_a.ln(precision)
        var rp = pa.ln()

        var rm_str = rm.to_string()
        var rp_str = String(rp)

        # Correctness check: exact string match with Python
        if rm_str != rp_str:
            log_print("*** WARNING: String mismatch detected! ***", log_file)
            log_print("Decimo result:   " + rm_str[:100], log_file)
            log_print("Python result:     " + rp_str[:100], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m_a.ln(precision)
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa.ln()
        var tp = (perf_counter_ns() - t0) / iterations

        var s = Float64(tp) / Float64(tm)
        sf.append(s)

        log_print("BigDecimal:      " + String(tm) + " ns/iter", log_file)
        log_print("Python decimal:  " + String(tp) + " ns/iter", log_file)
        log_print("Speedup:         " + String(s) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var log_file = open_log_file("benchmark_bigdecimal_ln")
    print_header(
        "Decimo BigDecimal Logarithm (ln) Multi-Precision Benchmark", log_file
    )

    var pydecimal = Python.import_module("decimal")
    var toml_path = "bench_data/ln.toml"
    var cases = load_bench_cases(toml_path)
    var levels = load_bench_precision_levels(toml_path)

    log_print(
        "\nMulti-precision benchmark: "
        + String(len(cases))
        + " cases × "
        + String(len(levels))
        + " precision levels",
        log_file,
    )

    for level_idx in range(len(levels)):
        var precision = levels[level_idx].precision
        var iterations = levels[level_idx].iterations

        pydecimal.getcontext().prec = precision

        log_print("\n" + String("=" * 70), log_file)
        log_print(
            "=== Precision Level: "
            + String(precision)
            + " ("
            + String(iterations)
            + " iterations) ===",
            log_file,
        )
        log_print(String("=" * 70), log_file)

        var sf = List[Float64]()

        for i in range(len(cases)):
            run_case(cases[i], iterations, precision, pydecimal, log_file, sf)

        print_summary(
            "Ln Summary (precision=" + String(precision) + ")",
            sf,
            "BigDecimal",
            iterations,
            log_file,
        )

    log_file.close()
    print("Benchmark completed. Log file closed.")
