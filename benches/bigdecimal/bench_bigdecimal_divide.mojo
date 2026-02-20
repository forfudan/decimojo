"""Benchmarks for BigDecimal division. Compares against Python decimal."""

from decimojo.bigdecimal.bigdecimal import BigDecimal
import decimojo.bigdecimal.arithmetics
from decimojo.bench_utils import (
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

comptime PRECISION = 4096
comptime ITERATIONS = 100
comptime ITERATIONS_LARGE = 3
comptime LARGE_CASE_THRESHOLD = 50  # Cases index >= this use fewer iterations


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
        var rm = m_a / m_b
        var rp = pa / pb

        log_print("BigDecimal result: " + String(rm)[:100], log_file)
        log_print("Python result:     " + String(rp)[:100], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m_a / m_b
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa / pb
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
    var log_file = open_log_file("benchmark_bigdecimal_divide")
    print_header("DeciMojo BigDecimal Division Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = PRECISION
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(10000000)

    var cases = load_bench_cases("bench_data/divide.toml")
    var sf = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " benchmarks"
        + " (standard: "
        + String(ITERATIONS)
        + " iter,"
        + " large: "
        + String(ITERATIONS_LARGE)
        + " iter)",
        log_file,
    )

    for i in range(len(cases)):
        # Use fewer iterations for very large number cases
        var iters = ITERATIONS
        if i >= LARGE_CASE_THRESHOLD and len(cases[i].a) > 10000:
            iters = ITERATIONS_LARGE
        run_case(cases[i], iters, pydecimal, log_file, sf)

    print_summary(
        "BigDecimal Division Benchmark Summary",
        sf,
        "BigDecimal",
        ITERATIONS,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
