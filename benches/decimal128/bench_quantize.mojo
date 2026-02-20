"""Benchmarks for Decimal128 quantize() function. Compares against Python decimal.

This file loads TOML cases with an extra `rounding` field not handled by the
standard BenchCase loader.
"""

from decimojo.prelude import Decimal128, RoundingMode
from decimojo.tests import (
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


fn get_mojo_rounding(mode_str: String) -> RoundingMode:
    """Map a TOML rounding string to a Mojo RoundingMode enum value."""
    if mode_str == "ROUND_HALF_UP":
        return RoundingMode.ROUND_HALF_UP
    elif mode_str == "ROUND_DOWN":
        return RoundingMode.ROUND_DOWN
    elif mode_str == "ROUND_UP":
        return RoundingMode.ROUND_UP
    else:
        return RoundingMode.ROUND_HALF_EVEN


fn get_py_rounding(
    mode_str: String, pydecimal: PythonObject
) raises -> PythonObject:
    """Map a TOML rounding string to a Python decimal rounding constant."""
    if mode_str == "ROUND_HALF_UP":
        return pydecimal.ROUND_HALF_UP
    elif mode_str == "ROUND_DOWN":
        return pydecimal.ROUND_DOWN
    elif mode_str == "ROUND_UP":
        return pydecimal.ROUND_UP
    else:
        return pydecimal.ROUND_HALF_EVEN


fn main() raises:
    var log_file = open_log_file("benchmark_quantize")
    print_header("DeciMojo Decimal128 Quantize Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 28

    # --- TOML load via tomlmojo for 'rounding' field ---
    var doc = parse_file("bench_data/quantize.toml")
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
        var rounding_str = c["rounding"].as_string()

        log_print("\nBenchmark:       " + name, log_file)
        log_print("Input value:     " + a_str, log_file)
        log_print("Quantize to:     " + b_str, log_file)
        log_print("Rounding:        " + rounding_str, log_file)

        var m_a = Decimal128(a_str)
        var m_quant = Decimal128(b_str)
        var pa = pydecimal.Decimal(a_str)
        var py_quant = pydecimal.Decimal(b_str)

        var mojo_rm = get_mojo_rounding(rounding_str)
        var py_rm = get_py_rounding(rounding_str, pydecimal)

        try:
            var rm = m_a.quantize(m_quant, mojo_rm)
            var rp = pa.quantize(py_quant, rounding=py_rm)

            log_print("Mojo result:     " + String(rm), log_file)
            log_print("Python result:   " + String(rp), log_file)

            var t0 = perf_counter_ns()
            for _ in range(iterations):
                _ = m_a.quantize(m_quant, mojo_rm)
            var tm = (perf_counter_ns() - t0) / iterations
            if tm == 0:
                tm = 1

            t0 = perf_counter_ns()
            for _ in range(iterations):
                _ = pa.quantize(py_quant, rounding=py_rm)
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
        "Decimal128 Quantize Benchmark Summary",
        sf,
        "Decimal128",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
