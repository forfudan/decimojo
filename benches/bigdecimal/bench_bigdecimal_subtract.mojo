"""Benchmarks for BigDecimal subtraction. Compares against Python decimal."""

from decimojo.bigdecimal.bigdecimal import BigDecimal
import decimojo.bigdecimal.arithmetics
from decimojo.tests import (
    BenchCase,
    load_bench_cases,
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
    pydecimal: PythonObject,
    log_file: PythonObject,
    mut sf: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80], log_file)
    log_print("b: " + bc.b[:80], log_file)

    var m_a = BigDecimal(bc.a)
    var m_b = BigDecimal(bc.b)
    var pa = pydecimal.Decimal(bc.a)
    var pb = pydecimal.Decimal(bc.b)

    try:
        var rm = m_a - m_b
        var rp = pa - pb

        var rm_str = rm.to_string()
        var rp_str = String(rp)

        # Correctness check: exact string match with Python
        if rm_str != rp_str:
            log_print("*** WARNING: String mismatch detected! ***", log_file)
            log_print("DeciMojo result:   " + rm_str[:100], log_file)
            log_print("Python result:     " + rp_str[:100], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m_a - m_b
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa - pb
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
    var log_file = open_log_file("benchmark_bigdecimal_subtract")
    print_header("DeciMojo BigDecimal Subtraction Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 10000

    var cases = load_bench_cases("bench_data/subtract.toml")
    var iterations = 1000
    var sf = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, pydecimal, log_file, sf)

    print_summary(
        "BigDecimal Subtraction Benchmark Summary",
        sf,
        "BigDecimal",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
