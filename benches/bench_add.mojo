"""
Comprehensive benchmarks for Decimal addition operations.
Compares performance against Python's decimal module.
"""

from decimojo.prelude import *
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

    # Create logs directory with in /benches if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/benchmark_add_" + timestamp + ".log"

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
    a_mojo: Decimal,
    b_mojo: Decimal,
    a_py: PythonObject,
    b_py: PythonObject,
    iterations: Int,
    log_file: PythonObject,
) raises:
    """
    Run a benchmark comparing Mojo Decimal addition with Python Decimal addition.

    Args:
        name: Name of the benchmark case.
        a_mojo: First Mojo Decimal operand.
        b_mojo: Second Mojo Decimal operand.
        a_py: First Python Decimal operand.
        b_py: Second Python Decimal operand.
        iterations: Number of 1000-iteration runs to average.
        log_file: File object for logging results.
    """
    log_print("\nBenchmark:       " + name, log_file)

    # Verify correctness
    var mojo_result = a_mojo + b_mojo
    var py_result = a_py + b_py
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = a_mojo + b_mojo
    var mojo_time = (perf_counter_ns() - t0) / iterations

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = a_py + b_py
    var python_time = (perf_counter_ns() - t0) / iterations

    # Print results with speedup comparison
    log_print(
        "Mojo Decimal:    " + String(mojo_time) + " ns per iterations",
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
    log_print("=== DeciMojo Addition Benchmark ===", log_file)
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

    var iterations = 1000
    var pydecimal = Python().import_module("decimal")

    # Set Python decimal precision to match Mojo's
    pydecimal.getcontext().prec = 28
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print(
        "Mojo decimal precision: " + String(Decimal.MAX_PRECISION), log_file
    )

    # Define benchmark cases
    log_print(
        "\nRunning addition benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Simple integers
    var case1_a_mojo = Decimal("12345")
    var case1_b_mojo = Decimal("67890")
    var case1_a_py = pydecimal.Decimal("12345")
    var case1_b_py = pydecimal.Decimal("67890")
    run_benchmark(
        "Simple integers",
        case1_a_mojo,
        case1_b_mojo,
        case1_a_py,
        case1_b_py,
        iterations,
        log_file,
    )

    # Case 2: Simple decimals (few decimal places)
    var case2_a_mojo = Decimal("123.45")
    var case2_b_mojo = Decimal("67.89")
    var case2_a_py = pydecimal.Decimal("123.45")
    var case2_b_py = pydecimal.Decimal("67.89")
    run_benchmark(
        "Simple decimals",
        case2_a_mojo,
        case2_b_mojo,
        case2_a_py,
        case2_b_py,
        iterations,
        log_file,
    )

    # Case 3: High-precision decimals
    var case3_a_mojo = Decimal("0.123456789012345678901234567")
    var case3_b_mojo = Decimal("0.987654321098765432109876543")
    var case3_a_py = pydecimal.Decimal("0.123456789012345678901234567")
    var case3_b_py = pydecimal.Decimal("0.987654321098765432109876543")
    run_benchmark(
        "High-precision decimals",
        case3_a_mojo,
        case3_b_mojo,
        case3_a_py,
        case3_b_py,
        iterations,
        log_file,
    )

    # Case 4: Different scales
    var case4_a_mojo = Decimal("123.4")
    var case4_b_mojo = Decimal("67.89")
    var case4_a_py = pydecimal.Decimal("123.4")
    var case4_b_py = pydecimal.Decimal("67.89")
    run_benchmark(
        "Different scales",
        case4_a_mojo,
        case4_b_mojo,
        case4_a_py,
        case4_b_py,
        iterations,
        log_file,
    )

    # Case 5: Numbers requiring carrying
    var case5_a_mojo = Decimal("999.99")
    var case5_b_mojo = Decimal("0.01")
    var case5_a_py = pydecimal.Decimal("999.99")
    var case5_b_py = pydecimal.Decimal("0.01")
    run_benchmark(
        "Numbers requiring carrying",
        case5_a_mojo,
        case5_b_mojo,
        case5_a_py,
        case5_b_py,
        iterations,
        log_file,
    )

    # Case 6: Very large numbers
    var case6_a_mojo = Decimal("79228162514264337593543950334")  # MAX - 1
    var case6_b_mojo = Decimal("1")
    var case6_a_py = pydecimal.Decimal("79228162514264337593543950334")
    var case6_b_py = pydecimal.Decimal("1")
    run_benchmark(
        "Very large numbers",
        case6_a_mojo,
        case6_b_mojo,
        case6_a_py,
        case6_b_py,
        iterations,
        log_file,
    )

    # Case 7: Very small numbers
    var case7_a_mojo = Decimal(
        "0." + "0" * 27 + "1"
    )  # Smallest positive decimal
    var case7_b_mojo = Decimal("0." + "0" * 27 + "2")
    var case7_a_py = pydecimal.Decimal("0." + "0" * 27 + "1")
    var case7_b_py = pydecimal.Decimal("0." + "0" * 27 + "2")
    run_benchmark(
        "Very small numbers",
        case7_a_mojo,
        case7_b_mojo,
        case7_a_py,
        case7_b_py,
        iterations,
        log_file,
    )

    # Case 8: Addition with zero
    var case8_a_mojo = Decimal("123.456")
    var case8_b_mojo = Decimal("0")
    var case8_a_py = pydecimal.Decimal("123.456")
    var case8_b_py = pydecimal.Decimal("0")
    run_benchmark(
        "Addition with zero",
        case8_a_mojo,
        case8_b_mojo,
        case8_a_py,
        case8_b_py,
        iterations,
        log_file,
    )

    # Case 9: Negative numbers
    var case9_a_mojo = Decimal("123.45")
    var case9_b_mojo = Decimal("-67.89")
    var case9_a_py = pydecimal.Decimal("123.45")
    var case9_b_py = pydecimal.Decimal("-67.89")
    run_benchmark(
        "Negative numbers",
        case9_a_mojo,
        case9_b_mojo,
        case9_a_py,
        case9_b_py,
        iterations,
        log_file,
    )

    # Case 10: Addition resulting in zero
    var case10_a_mojo = Decimal("123.45")
    var case10_b_mojo = Decimal("-123.45")
    var case10_a_py = pydecimal.Decimal("123.45")
    var case10_b_py = pydecimal.Decimal("-123.45")
    run_benchmark(
        "Addition resulting in zero",
        case10_a_mojo,
        case10_b_mojo,
        case10_a_py,
        case10_b_py,
        iterations,
        log_file,
    )

    # Display summary
    log_print("\n=== Addition Benchmark Summary ===", log_file)
    log_print("Benchmarked:      10 different addition cases", log_file)
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
