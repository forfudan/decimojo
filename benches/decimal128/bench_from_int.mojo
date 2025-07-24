"""
Comprehensive benchmarks for Decimal128.from_int() constructor.
Compares performance against Python's decimal module with 20 diverse test cases.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
from python import Python, PythonObject
from time import perf_counter_ns
import time
import os
from collections import List


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
    var log_filename = log_dir + "/benchmark_from_int_" + timestamp + ".log"

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
    input_value: Int,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Dec128.from_int with Python decimal constructor.

    Args:
        name: Name of the benchmark case.
        input_value: Integer value to convert.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Input value:     " + String(input_value), log_file)

    # Execute the operations once to verify correctness
    var mojo_result = Decimal128.from_int(input_value)
    var pydecimal = Python.import_module("decimal")
    var py_result = pydecimal.Decimal128(input_value)

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = Decimal128.from_int(input_value)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = pydecimal.Decimal128(input_value)
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo from_int():  " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python decimal(): " + String(python_time) + " ns per iteration",
        log_file,
    )
    log_print("Speedup factor:  " + String(speedup), log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create a Mojo List to store speedup factors for averaging later
    var speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo from_int() Constructor Benchmark ===", log_file)
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

    var iterations = 10000  # More iterations since this is a fast operation
    var pydecimal = Python().import_module("decimal")

    # Set Python decimal precision to match Mojo's
    pydecimal.getcontext().prec = 28
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print(
        "Mojo decimal precision: " + String(Decimal128.MAX_SCALE), log_file
    )

    # Define benchmark cases
    log_print(
        "\nRunning from_int() constructor benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Zero
    run_benchmark(
        "Zero",
        0,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Small positive integer
    run_benchmark(
        "Small positive integer",
        1,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Medium positive integer
    run_benchmark(
        "Medium positive integer",
        1000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Large positive integer
    run_benchmark(
        "Large positive integer",
        1000000000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Small negative integer
    run_benchmark(
        "Small negative integer",
        -1,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Medium negative integer
    run_benchmark(
        "Medium negative integer",
        -1000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Large negative integer
    run_benchmark(
        "Large negative integer",
        -1000000000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Power of 10 (small)
    run_benchmark(
        "Power of 10 (small)",
        10,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Power of 10 (medium)
    run_benchmark(
        "Power of 10 (medium)",
        100000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Power of 10 (large)
    run_benchmark(
        "Power of 10 (large)",
        1000000000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Power of 2 (small)
    run_benchmark(
        "Power of 2 (small)",
        1024,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Power of 2 (medium)
    run_benchmark(
        "Power of 2 (medium)",
        65536,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Integer with repeating digits (9s)
    run_benchmark(
        "Integer with repeating 9s",
        9999999,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Integer with repeating digits (8s)
    run_benchmark(
        "Integer with repeating 8s",
        88888888,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Integer with alternating digits (1s and 2s)
    run_benchmark(
        "Integer with alternating 1s and 2s",
        12121212,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Integer with alternating digits (9s and 0s)
    run_benchmark(
        "Integer with alternating 9s and 0s",
        9090909,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Close to INT32_MAX
    run_benchmark(
        "Close to INT32_MAX",
        2147483647,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Close to INT32_MIN
    run_benchmark(
        "Close to INT32_MIN",
        -2147483648,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Very large positive integer (close to INT64_MAX)
    run_benchmark(
        "Very large positive integer",
        9223372036854775807,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Very large negative integer (close to INT64_MIN)
    run_benchmark(
        "Very large negative integer",
        -9223372036854775807,
        iterations,
        log_file,
        speedup_factors,
    )

    # Calculate average speedup factor
    var sum_speedup: Float64 = 0.0
    for i in range(len(speedup_factors)):
        sum_speedup += speedup_factors[i]
    var average_speedup = sum_speedup / Float64(len(speedup_factors))

    # Display summary
    log_print("\n=== from_int() Constructor Benchmark Summary ===", log_file)
    log_print("Benchmarked:      20 different from_int() cases", log_file)
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )
    log_print("Average speedup:  " + String(average_speedup) + "×", log_file)

    # List all speedup factors
    log_print("\nIndividual speedup factors:", log_file)
    for i in range(len(speedup_factors)):
        log_print(
            String("Case {}: {}×").format(i + 1, round(speedup_factors[i], 2)),
            log_file,
        )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
