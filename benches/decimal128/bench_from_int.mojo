"""Benchmarks for Decimal128 from-int construction. Compares against Python decimal."""

from decimo import Decimal128
from decimo.tests import (
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
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("Input value:     " + bc.a, log_file)

    var int_val = atol(bc.a)
    var py_int = py_builtins.int(bc.a)

    try:
        var rm = Decimal128(int_val)
        var rp = pydecimal.Decimal(py_int)

        log_print("Mojo result:     " + String(rm), log_file)
        log_print("Python result:   " + String(rp), log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = Decimal128(int_val)
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pydecimal.Decimal(py_int)
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
    var log_file = open_log_file("benchmark_from_int")
    print_header("Decimo Decimal128 From-Int Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28
    var py_builtins = Python.import_module("builtins")

    var cases = load_bench_cases("bench_data/from_int.toml")
    var iterations = 10000
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
        "Decimal128 From-Int Benchmark Summary",
        sf,
        "Decimal128",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
