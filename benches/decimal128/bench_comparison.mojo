"""Benchmarks for Decimal128 comparison operators. Compares against Python decimal.

This file loads TOML cases with an extra `op` field (==, <, >, <=, >=, !=)
not handled by the standard BenchCase loader.
"""

from decimo import Decimal128
from decimo.tests import (
    parse_file,
    expand_value,
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
    print_header("Decimo Decimal128 Comparison Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    # --- TOML load via tomlmojo for 'op' field ---
    var doc = parse_file("bench_data/comparison.toml")
    var cases_array = doc.get_array_of_tables("cases")
    var iterations = 10000
    var sf = List[Float64]()

    log_print(
        "\nRunning "
        + String(len(cases_array))
        + " benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    for c in cases_array:
        var name = c["name"].as_string()
        var a_str = expand_value(c["a"].as_string())
        var b_str = expand_value(c["b"].as_string())
        var op = c["op"].as_string()

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
