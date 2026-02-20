"""Benchmarks for BigInt addition. Compares BigInt, BigInt2, and Python int."""

from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
from decimojo.bigint2.bigint2 import BigInt2
import decimojo.bigint2.arithmetics
from decimojo.tests import (
    BenchCase,
    load_bench_cases,
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
    log_print("a: " + bc.a[:80], log_file)
    log_print("b: " + bc.b[:80], log_file)

    var m1a = BigInt(bc.a)
    var m1b = BigInt(bc.b)
    var m2a = BigInt2(bc.a)
    var m2b = BigInt2(bc.b)
    var py = Python.import_module("builtins")
    var pa = py.int(bc.a)
    var pb = py.int(bc.b)

    try:
        var r1 = m1a + m1b
        var r2 = m2a + m2b
        var rp = pa + pb

        log_print("BigInt result:   " + String(r1), log_file)
        log_print("BigInt2 result:  " + String(r2), log_file)
        log_print("Python result:   " + String(rp), log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m1a + m1b
        var t1 = (perf_counter_ns() - t0) / iterations
        if t1 == 0:
            t1 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m2a + m2b
        var t2 = (perf_counter_ns() - t0) / iterations
        if t2 == 0:
            t2 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa + pb
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
    var log_file = open_log_file("benchmark_bigint_add")
    print_header("DeciMojo BigInt Addition Benchmark", log_file)

    var cases = load_bench_cases("bench_data/add.toml")
    var iterations = 1000
    var sf1 = List[Float64]()
    var sf2 = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " addition benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, log_file, sf1, sf2)

    print_summary_dual(
        "BigInt Addition Benchmark Summary",
        sf1,
        "BigInt",
        sf2,
        "BigInt2",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
