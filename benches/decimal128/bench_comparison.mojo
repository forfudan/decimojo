"""Benchmarks for Decimal128 comparison operators. Compares against Python decimal.

This file uses manual tomllib loading because the TOML cases have an extra
`op` field (==, <, >, <=, >=, !=) not handled by the standard BenchCase loader.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
from decimojo.bench_utils import (
    open_log_file,
    log_print,
    print_header,
    print_summary,
)
from python import Python, PythonObject
from time import perf_counter_ns
from collections import List


fn main() raises:
    var log_file = open_log_file("benchmark_comparison")
    print_header("DeciMojo Decimal128 Comparison Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    # --- manual TOML load for 'op' field ---
    var tomllib = Python.import_module("tomllib")
    var py_builtins = Python.import_module("builtins")
    var f = py_builtins.open("bench_data/comparison.toml", "rb")
    var data = tomllib.load(f)
    f.close()

    var cases = data["cases"]
    var iterations = 10000
    var sf = List[Float64]()
    var n = atol(String(py_builtins.len(cases)))

    log_print(
        "\nRunning "
        + String(n)
        + " benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for i in range(n):
        var c = cases[i]
        var name = String(c["name"])
        var a_str = String(c["a"])
        var b_str = String(c["b"])
        var op = String(c["op"])

        log_print("\nBenchmark:       " + name, log_file)
        log_print("Left operand:    " + a_str, log_file)
        log_print("Right operand:   " + b_str, log_file)
        log_print("Operator:        " + op, log_file)

        var m_a = Decimal128(a_str)
        var m_b = Decimal128(b_str)
        var pa = pydecimal.Decimal(a_str)
        var pb = pydecimal.Decimal(b_str)

        try:
            # --- Mojo benchmark ---
            var t0 = perf_counter_ns()
            if op == "==":
                for _ in range(iterations):
                    _ = m_a == m_b
            elif op == "<":
                for _ in range(iterations):
                    _ = m_a < m_b
            elif op == ">":
                for _ in range(iterations):
                    _ = m_a > m_b
            elif op == "<=":
                for _ in range(iterations):
                    _ = m_a <= m_b
            elif op == ">=":
                for _ in range(iterations):
                    _ = m_a >= m_b
            elif op == "!=":
                for _ in range(iterations):
                    _ = m_a != m_b
            var tm = (perf_counter_ns() - t0) / iterations
            if tm == 0:
                tm = 1

            # --- Python benchmark ---
            t0 = perf_counter_ns()
            if op == "==":
                for _ in range(iterations):
                    _ = pa == pb
            elif op == "<":
                for _ in range(iterations):
                    _ = pa < pb
            elif op == ">":
                for _ in range(iterations):
                    _ = pa > pb
            elif op == "<=":
                for _ in range(iterations):
                    _ = pa <= pb
            elif op == ">=":
                for _ in range(iterations):
                    _ = pa >= pb
            elif op == "!=":
                for _ in range(iterations):
                    _ = pa != pb
            var tp = (perf_counter_ns() - t0) / iterations

            var s = Float64(tp) / Float64(tm)
            sf.append(s)

            log_print("Decimal128:      " + String(tm) + " ns/iter", log_file)
            log_print("Python decimal:  " + String(tp) + " ns/iter", log_file)
            log_print("Speedup:         " + String(s) + "×", log_file)
        except e:
            log_print("Error: " + String(e), log_file)
            log_print("Skipping this case", log_file)

    print_summary(
        "Decimal128 Comparison Benchmark Summary",
        sf,
        "Decimal128",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
