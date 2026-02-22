"""Benchmarks for BigDecimal ln. Compares against Python decimal."""

from decimojo.bigdecimal.bigdecimal import BigDecimal
import decimojo.bigdecimal.arithmetics
import decimojo.bigdecimal.exponential
from decimojo.tests import (
    BenchCase,
    load_bench_cases,
    load_bench_precision,
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

        var rm_str = rm.to_string(precision=100000)
        var rp_str = String(rp)
        log_print("BigDecimal result: " + rm_str[:100], log_file)
        log_print("Python result:     " + rp_str[:100], log_file)

        # Correctness check
        try:
            var py_bdec = BigDecimal(rp_str)
            var diff = rm - py_bdec
            var diff_str = diff.to_string(precision=100000)[:80]
            log_print("Difference:        " + diff_str, log_file)
            if not diff.is_zero():
                log_print(
                    "*** WARNING: Non-zero difference detected! ***", log_file
                )
        except:
            log_print("Difference:        (comparison failed)", log_file)

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
    print_header("DeciMojo BigDecimal Logarithm (ln) Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    var toml_path = "bench_data/ln.toml"
    var cases = load_bench_cases(toml_path)
    var precision = load_bench_precision(toml_path)
    var iterations = 100
    var sf = List[Float64]()

    pydecimal.getcontext().prec = precision

    log_print(
        "\nRunning "
        + String(len(cases))
        + " benchmarks with "
        + String(iterations)
        + " iterations each"
        + " (precision="
        + String(precision)
        + ")",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, precision, pydecimal, log_file, sf)

    print_summary(
        "BigDecimal Logarithm (ln) Benchmark Summary",
        sf,
        "BigDecimal",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
