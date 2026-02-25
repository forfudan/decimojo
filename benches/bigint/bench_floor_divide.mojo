"""Benchmarks for BigInt floor division. Compares BigInt10, BigInt, and Python int."""

from decimo.bigint10.bigint10 import BigInt10
import decimo.bigint10.arithmetics
from decimo.bigint.bigint import BigInt
import decimo.bigint.arithmetics
from decimo.tests import (
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
    mut sf_bigint10: List[Float64],
    mut sf_bigint: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80], log_file)
    log_print("b: " + bc.b[:80], log_file)

    var m1a = BigInt10(bc.a)
    var m1b = BigInt10(bc.b)
    var m2a = BigInt(bc.a)
    var m2b = BigInt(bc.b)
    var py = Python.import_module("builtins")
    var pa = py.int(bc.a)
    var pb = py.int(bc.b)

    try:
        var r1 = decimo.bigint10.arithmetics.floor_divide(m1a, m1b)
        var r2 = decimo.bigint.arithmetics.floor_divide(m2a, m2b)
        var rp = pa // pb

        var r1_str = String(r1)
        var r2_str = String(r2)
        var rp_str = String(rp)

        # Correctness check: string match
        if r1_str != rp_str or r2_str != rp_str:
            log_print("*** WARNING: String mismatch detected! ***", log_file)
            log_print("BigInt10 result: " + r1_str[:80], log_file)
            log_print("BigInt result:  " + r2_str[:80], log_file)
            log_print("Python result:   " + rp_str[:80], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = decimo.bigint10.arithmetics.floor_divide(m1a, m1b)
        var t1 = (perf_counter_ns() - t0) / iterations
        if t1 == 0:
            t1 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = decimo.bigint.arithmetics.floor_divide(m2a, m2b)
        var t2 = (perf_counter_ns() - t0) / iterations
        if t2 == 0:
            t2 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa // pb
        var tp = (perf_counter_ns() - t0) / iterations

        var s1 = Float64(tp) / Float64(t1)
        var s2 = Float64(tp) / Float64(t2)
        sf_bigint10.append(s1)
        sf_bigint.append(s2)

        log_print("BigInt10:        " + String(t1) + " ns/iter", log_file)
        log_print("BigInt:         " + String(t2) + " ns/iter", log_file)
        log_print("Python:          " + String(tp) + " ns/iter", log_file)
        log_print("BigInt10 speedup:" + String(s1) + "×", log_file)
        log_print("BigInt speedup: " + String(s2) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(10000000)

    var log_file = open_log_file("benchmark_bigint_floor_divide")
    print_header("Decimo BigInt Floor Division Benchmark", log_file)

    var cases = load_bench_cases("bench_data/floor_divide.toml")
    var iterations = load_bench_iterations("bench_data/floor_divide.toml")
    var sf1 = List[Float64]()
    var sf2 = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " floor division benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, log_file, sf1, sf2)

    print_summary_dual(
        "BigInt Floor Division Benchmark Summary",
        sf1,
        "BigInt10",
        sf2,
        "BigInt",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
