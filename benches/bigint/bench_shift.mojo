"""Benchmarks for BigInt left shift. Compares BigInt vs Python int."""

from decimo.bigint.bigint import BigInt
import decimo.bigint.arithmetics
from decimo.tests import (
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
    log_print("a: " + bc.a[:80] + (" ..." if len(bc.a) > 80 else ""), log_file)
    log_print("shift: " + bc.b, log_file)

    var m2a = BigInt(bc.a)
    var shift = Int(BigInt(bc.b))
    var py = Python.import_module("builtins")
    var pa = py.int(bc.a)
    var pb = py.int(bc.b)

    try:
        var r2 = m2a << shift
        var rp = pa << pb

        var r2_str = String(r2)
        var rp_str = String(rp)

        # Correctness check: string match
        if r2_str != rp_str:
            log_print("*** WARNING: String mismatch detected! ***", log_file)
            log_print("BigInt result:  " + r2_str[:80], log_file)
            log_print("Python result:   " + rp_str[:80], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m2a << shift
        var t2 = (perf_counter_ns() - t0) / iterations
        if t2 == 0:
            t2 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa << pb
        var tp = (perf_counter_ns() - t0) / iterations

        var s2 = Float64(tp) / Float64(t2)
        sf.append(s2)

        log_print("BigInt:         " + String(t2) + " ns/iter", log_file)
        log_print("Python:          " + String(tp) + " ns/iter", log_file)
        log_print("Speedup:         " + String(s2) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(10000000)

    var log_file = open_log_file("benchmark_bigint_shift")
    print_header("Decimo BigInt Left Shift Benchmark", log_file)

    var cases = load_bench_cases("bench_data/shift.toml")
    var iterations = load_bench_iterations("bench_data/shift.toml")
    var sf = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " shift benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, log_file, sf)

    print_summary(
        "BigInt Left Shift Benchmark Summary",
        sf,
        "BigInt",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
