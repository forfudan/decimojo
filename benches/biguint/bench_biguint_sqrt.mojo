"""Benchmarks for BigUInt sqrt. Compares BigUInt and Python math.isqrt."""

from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.exponential
from decimojo.bench_utils import (
    BenchCase,
    load_bench_cases,
    load_bench_iterations,
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
    log_file: PythonObject,
    mut sf: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80], log_file)

    var m_a = BigUInt(bc.a)
    var py = Python.import_module("builtins")
    var math = Python.import_module("math")
    var pa = py.int(bc.a)

    try:
        var rm = decimojo.biguint.exponential.sqrt(m_a)
        var rp = math.isqrt(pa)

        log_print("BigUInt result:  " + String(rm)[:120], log_file)
        log_print("Python result:   " + String(rp)[:120], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = String(decimojo.biguint.exponential.sqrt(m_a))
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py.str(math.isqrt(pa))
        var tp = (perf_counter_ns() - t0) / iterations

        var s = Float64(tp) / Float64(tm)
        sf.append(s)

        log_print("BigUInt:         " + String(tm) + " ns/iter", log_file)
        log_print("Python:          " + String(tp) + " ns/iter", log_file)
        log_print("Speedup:         " + String(s) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(10000000)

    var toml_path = "bench_data/sqrt.toml"
    var log_file = open_log_file("benchmark_biguint_sqrt")
    print_header("DeciMojo BigUInt Square Root Benchmark", log_file)

    var cases = load_bench_cases(toml_path)
    var iterations = load_bench_iterations(toml_path)
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
        run_case(cases[i], iterations, log_file, sf)

    print_summary(
        "BigUInt Square Root Benchmark Summary",
        sf,
        "BigUInt",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
