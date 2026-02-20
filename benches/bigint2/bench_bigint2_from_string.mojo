"""Benchmarks for BigInt2 from_string construction. Compares BigInt, BigInt2, and Python int."""

from decimojo.bigint.bigint import BigInt
from decimojo.bigint2.bigint2 import BigInt2
from decimojo.tests import (
    BenchCase,
    load_bench_cases,
    load_bench_iterations,
    open_log_file,
    log_print,
    print_header,
    print_summary_dual,
)
from python import Python, PythonObject
from time import perf_counter_ns
from collections import List


fn run_case(
    bc: BenchCase,
    iterations: Int,
    log_file: PythonObject,
    mut sf_bigint: List[Float64],
    mut sf_bigint2: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80] + (" ..." if len(bc.a) > 80 else ""), log_file)
    log_print("digits:          " + String(len(bc.a)), log_file)

    var py = Python.import_module("builtins")

    try:
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = BigInt(bc.a)
        var t1 = (perf_counter_ns() - t0) / iterations
        if t1 == 0:
            t1 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = BigInt2(bc.a)
        var t2 = (perf_counter_ns() - t0) / iterations
        if t2 == 0:
            t2 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py.int(bc.a)
        var tp = (perf_counter_ns() - t0) / iterations

        var s1 = Float64(tp) / Float64(t1)
        var s2 = Float64(tp) / Float64(t2)
        sf_bigint.append(s1)
        sf_bigint2.append(s2)

        log_print("BigInt:          " + String(t1) + " ns/iter", log_file)
        log_print("BigInt2:         " + String(t2) + " ns/iter", log_file)
        log_print("Python:          " + String(tp) + " ns/iter", log_file)
        log_print("BigInt speedup:  " + String(s1) + "×", log_file)
        log_print("BigInt2 speedup: " + String(s2) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(10000000)

    var log_file = open_log_file("benchmark_bigint2_from_string")
    print_header("DeciMojo BigInt2 from_string Benchmark", log_file)

    var cases = load_bench_cases("bench_data/from_string.toml")
    var iterations = load_bench_iterations("bench_data/from_string.toml")
    var sf1 = List[Float64]()
    var sf2 = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " from_string benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, log_file, sf1, sf2)

    print_summary_dual(
        "BigInt2 from_string Benchmark Summary",
        sf1,
        "BigInt",
        sf2,
        "BigInt2",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
