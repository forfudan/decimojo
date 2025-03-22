"""
Comprehensive benchmarks for Decimal square root operations.
Compares performance against Python's decimal module with 20 diverse test cases.
"""

from decimojo.prelude import dm, Decimal, RoundingMode
from python import Python, PythonObject
from time import perf_counter_ns
import time
import os


fn open_log_file() raises -> PythonObject:
    """
    Creates and opens a log file with a timestamp in the filename.

    Returns:
        A file object opened for writing.
    """
    var python = Python.import_module("builtins")
    var datetime = Python.import_module("datetime")

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/benchmark_sqrt_" + timestamp + ".log"

    print("Saving benchmark results to:", log_filename)
    return python.open(log_filename, "w")


fn log_print(msg: String, log_file: PythonObject) raises:
    """
    Prints a message to both the console and the log file.

    Args:
        msg: The message to print.
        log_file: The file object to write to.
    """
    print(msg)
    log_file.write(msg + "\n")
    log_file.flush()  # Ensure the message is written immediately


fn run_benchmark(
    name: String,
    d_mojo: Decimal,
    d_py: PythonObject,
    iterations: Int,
    log_file: PythonObject,
) raises:
    """
    Run a benchmark comparing Mojo Decimal sqrt with Python Decimal sqrt.

    Args:
        name: Name of the benchmark case.
        d_mojo: Mojo Decimal operand.
        d_py: Python Decimal operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Decimal:         " + String(d_mojo), log_file)

    # Verify correctness - import math module for Python's sqrt
    var math = Python.import_module("math")
    var mojo_result = decimojo.sqrt(d_mojo)
    var py_result = math.sqrt(d_py)
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = decimojo.sqrt(d_mojo)
    var mojo_time = (perf_counter_ns() - t0) / iterations

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = math.sqrt(d_py)
    var python_time = (perf_counter_ns() - t0) / iterations

    # Print results with speedup comparison
    log_print(
        "Mojo Decimal:    " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python Decimal:  " + String(python_time) + " ns per iteration",
        log_file,
    )
    log_print("Speedup factor:  " + String(python_time / mojo_time), log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Display benchmark header with system information
    log_print("=== DeciMojo Square Root Benchmark ===", log_file)
    log_print("Time: " + String(datetime.datetime.now().isoformat()), log_file)

    # Try to get system info
    try:
        var platform = Python.import_module("platform")
        log_print(
            "System: "
            + String(platform.system())
            + " "
            + String(platform.release()),
            log_file,
        )
        log_print("Processor: " + String(platform.processor()), log_file)
        log_print(
            "Python version: " + String(platform.python_version()), log_file
        )
    except:
        log_print("Could not retrieve system information", log_file)

    var iterations = 100
    var pydecimal = Python().import_module("decimal")

    # Set Python decimal precision to match Mojo's
    pydecimal.getcontext().prec = 28
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print("Mojo decimal precision: " + String(Decimal.MAX_SCALE), log_file)

    # Define benchmark cases
    log_print(
        "\nRunning square root benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Perfect square (small)
    var case1_mojo = Decimal("16")
    var case1_py = pydecimal.Decimal("16")
    run_benchmark(
        "Perfect square (small)",
        case1_mojo,
        case1_py,
        iterations,
        log_file,
    )

    # Case 2: Perfect square (large)
    var case2_mojo = Decimal("1000000")  # 1000^2
    var case2_py = pydecimal.Decimal("1000000")
    run_benchmark(
        "Perfect square (large)",
        case2_mojo,
        case2_py,
        iterations,
        log_file,
    )

    # Case 3: Non-perfect square (small irrational)
    var case3_mojo = Decimal("2")  # sqrt(2) is irrational
    var case3_py = pydecimal.Decimal("2")
    run_benchmark(
        "Non-perfect square (small irrational)",
        case3_mojo,
        case3_py,
        iterations,
        log_file,
    )

    # Case 4: Non-perfect square (medium)
    var case4_mojo = Decimal("123.456")
    var case4_py = pydecimal.Decimal("123.456")
    run_benchmark(
        "Non-perfect square (medium)",
        case4_mojo,
        case4_py,
        iterations,
        log_file,
    )

    # Case 5: Very small number
    var case5_mojo = Decimal("0.0000001")
    var case5_py = pydecimal.Decimal("0.0000001")
    run_benchmark(
        "Very small number",
        case5_mojo,
        case5_py,
        iterations,
        log_file,
    )

    # Case 6: Very large number
    var case6_mojo = Decimal("1" + "0" * 20)  # 10^20
    var case6_py = pydecimal.Decimal("1" + "0" * 20)
    run_benchmark(
        "Very large number",
        case6_mojo,
        case6_py,
        iterations,
        log_file,
    )

    # Case 7: Number just above 1
    var case7_mojo = Decimal("1.0000001")
    var case7_py = pydecimal.Decimal("1.0000001")
    run_benchmark(
        "Number just above 1",
        case7_mojo,
        case7_py,
        iterations,
        log_file,
    )

    # Case 8: Number just below 1
    var case8_mojo = Decimal("0.9999999")
    var case8_py = pydecimal.Decimal("0.9999999")
    run_benchmark(
        "Number just below 1",
        case8_mojo,
        case8_py,
        iterations,
        log_file,
    )

    # Case 9: High precision value
    var case9_mojo = Decimal("1.23456789012345678901234567")
    var case9_py = pydecimal.Decimal("1.23456789012345678901234567")
    run_benchmark(
        "High precision value",
        case9_mojo,
        case9_py,
        iterations,
        log_file,
    )

    # Case 10: Number with exact square root in decimal
    var case10_mojo = Decimal("0.04")  # sqrt = 0.2
    var case10_py = pydecimal.Decimal("0.04")
    run_benchmark(
        "Number with exact square root",
        case10_mojo,
        case10_py,
        iterations,
        log_file,
    )

    # Case 11: Number close to a perfect square
    var case11_mojo = Decimal("99.99")  # Close to 10²
    var case11_py = pydecimal.Decimal("99.99")
    run_benchmark(
        "Number close to a perfect square",
        case11_mojo,
        case11_py,
        iterations,
        log_file,
    )

    # Case 12: Even larger perfect square
    var case12_mojo = Decimal("1000000000")  # 31622.78...^2
    var case12_py = pydecimal.Decimal("1000000000")
    run_benchmark(
        "Very large perfect square",
        case12_mojo,
        case12_py,
        iterations,
        log_file,
    )

    # Case 13: Number with repeating pattern in result
    var case13_mojo = Decimal("3")  # sqrt(3) has repeating pattern
    var case13_py = pydecimal.Decimal("3")
    run_benchmark(
        "Number with repeating pattern in result",
        case13_mojo,
        case13_py,
        iterations,
        log_file,
    )

    # Case 14: Number with trailing zeros (exact square)
    var case14_mojo = Decimal("144.0000")
    var case14_py = pydecimal.Decimal("144.0000")
    run_benchmark(
        "Number with trailing zeros",
        case14_mojo,
        case14_py,
        iterations,
        log_file,
    )

    # Case 15: Number slightly larger than a perfect square
    var case15_mojo = Decimal("4.0001")
    var case15_py = pydecimal.Decimal("4.0001")
    run_benchmark(
        "Slightly larger than perfect square",
        case15_mojo,
        case15_py,
        iterations,
        log_file,
    )

    # Case 16: Number slightly smaller than a perfect square
    var case16_mojo = Decimal("15.9999")
    var case16_py = pydecimal.Decimal("15.9999")
    run_benchmark(
        "Slightly smaller than perfect square",
        case16_mojo,
        case16_py,
        iterations,
        log_file,
    )

    # Case 17: Number with many decimal places
    var case17_mojo = Decimal("0.12345678901234567890")
    var case17_py = pydecimal.Decimal("0.12345678901234567890")
    run_benchmark(
        "Number with many decimal places",
        case17_mojo,
        case17_py,
        iterations,
        log_file,
    )

    # Case 18: Number close to maximum representable value
    var case18_mojo = Decimal.MAX() - Decimal("1")
    var case18_py = pydecimal.Decimal(String(case18_mojo))
    run_benchmark(
        "Number close to maximum value",
        case18_mojo,
        case18_py,
        iterations,
        log_file,
    )

    # Case 19: Very tiny number (close to minimum positive value)
    var case19_mojo = Decimal(
        "0." + "0" * 27 + "1"
    )  # Smallest positive decimal
    var case19_py = pydecimal.Decimal(String(case19_mojo))
    run_benchmark(
        "Very tiny positive number",
        case19_mojo,
        case19_py,
        iterations,
        log_file,
    )

    # Case 20: Number requiring many Newton-Raphson iterations
    var case20_mojo = Decimal("987654321.123456789")
    var case20_py = pydecimal.Decimal("987654321.123456789")
    run_benchmark(
        "Number requiring many iterations",
        case20_mojo,
        case20_py,
        iterations,
        log_file,
    )

    # Display summary
    log_print("\n=== Square Root Benchmark Summary ===", log_file)
    log_print("Benchmarked:      20 different square root cases", log_file)
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )
    log_print(
        "Performance:      See detailed results above for each case", log_file
    )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
