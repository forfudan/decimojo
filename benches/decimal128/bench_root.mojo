"""Benchmarks for Decimal128 nth root function. Compares against Python decimal."""

from decimojo.prelude import dm, Decimal128, RoundingMode
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


fn run_case(
    bc: BenchCase,
    iterations: Int,
    pydecimal: PythonObject,
    log_file: PythonObject,
    mut sf: List[Float64],
) raises:
    var nth_root = atol(bc.b)
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("Value:           " + bc.a, log_file)
    log_print("Root:            " + String(nth_root), log_file)

    var m_a = Decimal128(bc.a)
    var py_val = pydecimal.Decimal(bc.a)
    var py_root = pydecimal.Decimal(String(nth_root))
    var py_frac = pydecimal.Decimal(1) / py_root

    var is_negative_odd_root = bc.a.startswith("-") and nth_root % 2 == 1

    try:
        var rm = dm.decimal128.exponential.root(m_a, nth_root)
        log_print("Mojo result:     " + String(rm), log_file)

        var rp: PythonObject
        if is_negative_odd_root:
            var abs_py = py_val.copy_abs()
            rp = -(abs_py**py_frac)
            log_print(
                "Note: Python workaround for odd root of negative number.",
                log_file,
            )
        else:
            rp = py_val**py_frac
        log_print("Python result:   " + String(rp), log_file)

        # Benchmark Mojo
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = dm.decimal128.exponential.root(m_a, nth_root)
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        # Benchmark Python
        t0 = perf_counter_ns()
        if is_negative_odd_root:
            var abs_py = py_val.copy_abs()
            for _ in range(iterations):
                _ = -(abs_py**py_frac)
        else:
            for _ in range(iterations):
                _ = py_val**py_frac
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
    var log_file = open_log_file("benchmark_root")
    print_header("DeciMojo Decimal128 Root Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    var cases = load_bench_cases("bench_data/root.toml")
    var iterations = 100
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
        "Decimal128 Root Benchmark Summary",
        sf,
        "Decimal128",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
