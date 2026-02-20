"""Benchmarks for Decimal128 round() function. Compares against Python round()."""

from decimojo import Decimal128
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
    py_builtins: PythonObject,
    log_file: PythonObject,
    mut sf: List[Float64],
) raises:
    var ndigits = atol(bc.b)

    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("Input value:     " + bc.a, log_file)
    log_print("Decimal places:  " + String(ndigits), log_file)

    var m_a = Decimal128(bc.a)
    var pa = pydecimal.Decimal(bc.a)

    try:
        var rm = round(m_a, ndigits)
        var rp = py_builtins.round(pa, ndigits)

        log_print("Mojo result:     " + String(rm), log_file)
        log_print("Python result:   " + String(rp), log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = round(m_a, ndigits)
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_builtins.round(pa, ndigits)
        var tp = (perf_counter_ns() - t0) / iterations

        var s = Float64(tp) / Float64(tm)
        sf.append(s)

        log_print("Decimal128:      " + String(tm) + " ns/iter", log_file)
        log_print("Python decimal:  " + String(tp) + " ns/iter", log_file)
        log_print("Speedup:         " + String(s) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var log_file = open_log_file("benchmark_round")
    print_header("DeciMojo Decimal128 Round Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28
    var py_builtins = Python.import_module("builtins")

    var cases = load_bench_cases("bench_data/round.toml")
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
        run_case(cases[i], iterations, pydecimal, py_builtins, log_file, sf)

    print_summary(
        "Decimal128 Round Benchmark Summary",
        sf,
        "Decimal128",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
