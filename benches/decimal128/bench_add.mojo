"""Benchmarks for Decimal128 addition. Compares against Python decimal."""

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
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a, log_file)
    log_print("b: " + bc.b, log_file)

    var m_a = Decimal128(bc.a)
    var m_b = Decimal128(bc.b)
    var pa = pydecimal.Decimal(bc.a)
    var pb = pydecimal.Decimal(bc.b)

    try:
        var rm = m_a + m_b
        var rp = pa + pb

        log_print("Mojo result:     " + String(rm), log_file)
        log_print("Python result:   " + String(rp), log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m_a + m_b
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa + pb
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
    var log_file = open_log_file("benchmark_add")
    print_header("DeciMojo Decimal128 Addition Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    var cases = load_bench_cases("bench_data/add.toml")
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
        run_case(cases[i], iterations, pydecimal, log_file, sf)

    print_summary(
        "Decimal128 Addition Benchmark Summary",
        sf,
        "Decimal128",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
