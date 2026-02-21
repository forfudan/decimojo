"""Benchmarks for BigInt integer square root. Compares BigUInt, BigInt, and Python isqrt."""

from decimojo.biguint.biguint import BigUInt
from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
import decimojo.bigint.exponential
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
    mut sf_biguint: List[Float64],
    mut sf_bigint: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80] + (" ..." if len(bc.a) > 80 else ""), log_file)

    var m1a = BigUInt(bc.a)
    var m2a = BigInt(bc.a)
    var py = Python.import_module("builtins")
    var math_mod = Python.import_module("math")
    var pa = py.int(bc.a)

    try:
        var r1 = m1a.sqrt()
        var r2 = m2a.sqrt()
        var rp = math_mod.isqrt(pa)

        var r1_str = String(r1)
        var r2_str = String(r2)
        var rp_str = String(rp)
        log_print(
            "BigUInt result:  "
            + r1_str[:80]
            + (" ..." if len(r1_str) > 80 else ""),
            log_file,
        )
        log_print(
            "BigInt result:  "
            + r2_str[:80]
            + (" ..." if len(r2_str) > 80 else ""),
            log_file,
        )
        log_print(
            "Python result:   "
            + rp_str[:80]
            + (" ..." if len(rp_str) > 80 else ""),
            log_file,
        )

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m1a.sqrt()
        var t1 = (perf_counter_ns() - t0) / iterations
        if t1 == 0:
            t1 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m2a.sqrt()
        var t2 = (perf_counter_ns() - t0) / iterations
        if t2 == 0:
            t2 = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = math_mod.isqrt(pa)
        var tp = (perf_counter_ns() - t0) / iterations

        var s1 = Float64(tp) / Float64(t1)
        var s2 = Float64(tp) / Float64(t2)
        sf_biguint.append(s1)
        sf_bigint.append(s2)

        log_print("BigUInt:         " + String(t1) + " ns/iter", log_file)
        log_print("BigInt:         " + String(t2) + " ns/iter", log_file)
        log_print("Python:          " + String(tp) + " ns/iter", log_file)
        log_print("BigUInt speedup: " + String(s1) + "×", log_file)
        log_print("BigInt speedup: " + String(s2) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(10000000)

    var log_file = open_log_file("benchmark_bigint_sqrt")
    print_header("DeciMojo BigInt Square Root Benchmark", log_file)

    var cases = load_bench_cases("bench_data/sqrt.toml")
    var iterations = load_bench_iterations("bench_data/sqrt.toml")
    var sf1 = List[Float64]()
    var sf2 = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases))
        + " sqrt benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(len(cases)):
        run_case(cases[i], iterations, log_file, sf1, sf2)

    print_summary_dual(
        "BigInt Square Root Benchmark Summary",
        sf1,
        "BigUInt",
        sf2,
        "BigInt",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
