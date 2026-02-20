"""Benchmarks for BigDecimal round. Compares against Python decimal."""

from decimojo.bigdecimal.bigdecimal import BigDecimal
import decimojo.bigdecimal.arithmetics
from decimojo.rounding_mode import RoundingMode
from decimojo.tests import (
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


fn parse_rounding_mode(mode_str: String) raises -> RoundingMode:
    """Parse a rounding mode string to RoundingMode enum."""
    if mode_str == "ROUND_DOWN":
        return RoundingMode.ROUND_DOWN
    elif mode_str == "ROUND_UP":
        return RoundingMode.ROUND_UP
    elif mode_str == "ROUND_HALF_UP":
        return RoundingMode.ROUND_HALF_UP
    elif mode_str == "ROUND_HALF_EVEN":
        return RoundingMode.ROUND_HALF_EVEN
    else:
        raise Error("Unknown rounding mode: " + mode_str)


fn run_case(
    bc: BenchCase,
    iterations: Int,
    pydecimal: PythonObject,
    log_file: PythonObject,
    mut sf: List[Float64],
) raises:
    log_print("\nBenchmark:       " + bc.name, log_file)
    log_print("a: " + bc.a[:80], log_file)
    log_print("b: " + bc.b, log_file)

    # Parse b field: "ndigits|ROUNDING_MODE"
    var idx = bc.b.find("|")
    if idx < 0:
        log_print("Error: Invalid round param format: " + bc.b, log_file)
        return
    var ndigits = atol(String(bc.b[:idx]))
    var mode_str = String(bc.b[idx + 1 :])
    var mode = parse_rounding_mode(mode_str)

    var m_a = BigDecimal(bc.a)
    var pa = pydecimal.Decimal(bc.a)

    # Map to Python rounding mode
    var py_mode: PythonObject
    if mode_str == "ROUND_DOWN":
        py_mode = pydecimal.ROUND_DOWN
    elif mode_str == "ROUND_UP":
        py_mode = pydecimal.ROUND_UP
    elif mode_str == "ROUND_HALF_UP":
        py_mode = pydecimal.ROUND_HALF_UP
    else:
        py_mode = pydecimal.ROUND_HALF_EVEN

    # Set Python rounding mode in context
    pydecimal.getcontext().rounding = py_mode

    try:
        var rm = m_a.round(ndigits, mode)
        var rp = pa.__round__(ndigits)

        log_print("BigDecimal result: " + String(rm)[:100], log_file)
        log_print("Python result:     " + String(rp)[:100], log_file)

        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = m_a.round(ndigits, mode)
        var tm = (perf_counter_ns() - t0) / iterations
        if tm == 0:
            tm = 1

        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = pa.__round__(ndigits)
        var tp = (perf_counter_ns() - t0) / iterations

        var s = Float64(tp) / Float64(tm)
        sf.append(s)

        log_print("BigDecimal:      " + String(tm) + " ns/iter", log_file)
        log_print("Python decimal:  " + String(tp) + " ns/iter", log_file)
        log_print("Speedup:         " + String(s) + "×", log_file)
    except e:
        log_print("Error: " + String(e), log_file)
        log_print("Skipping this case", log_file)


fn main() raises:
    var log_file = open_log_file("benchmark_bigdecimal_round")
    print_header("DeciMojo BigDecimal Rounding Benchmark", log_file)

    var pydecimal = Python.import_module("decimal")
    pydecimal.getcontext().prec = 10000

    var cases = load_bench_cases("bench_data/round.toml")
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
        "BigDecimal Rounding Benchmark Summary",
        sf,
        "BigDecimal",
        iterations,
        log_file,
    )
    log_file.close()
    print("Benchmark completed. Log file closed.")
