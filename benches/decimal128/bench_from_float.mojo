"""
Comprehensive benchmarks for Decimal128(Float64) constructor operations.
Compares performance against Python's decimal module with 10 diverse test cases.
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
    var log_filename = log_dir + "/benchmark_from_float_" + timestamp + ".log"

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
    value: Float64,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Dec128(Float64) with Python decimal(float).

    Args:
        name: Name of the benchmark case.
        value: Float64 value to convert.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Float64 value:   " + String(value), log_file)

    # Get Python decimal module
    var pydecimal = Python.import_module("decimal")

    # Execute the operations once to verify correctness
    var mojo_result = Decimal128.from_float(value)
    var py_value = Python.evaluate("float(" + String(value) + ")")
    var py_result = pydecimal.Decimal128(py_value)

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = Decimal128.from_float(value)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = pydecimal.Decimal128(py_value)
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo decimal:    " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python decimal:  " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo Float64 Constructor Benchmark ===", log_file)
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

    var iterations = 10000
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
        "\nRunning Float64 constructor benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Simple integer
    run_benchmark(
        "Simple integer",
        123.0,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Simple decimal with few places
    run_benchmark(
        "Simple decimal with few places",
        123.45,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Negative number
    run_benchmark(
        "Negative number",
        -123.45,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Very small decimal (close to zero)
    run_benchmark(
        "Very small decimal",
        1e-15,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Very large decimal (close to Float64 limits)
    run_benchmark(
        "Very large decimal",
        1e20,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Value with many decimal places
    run_benchmark(
        "Value with many decimal places",
        3.141592653589793,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Value requiring binary to decimal conversion
    run_benchmark(
        "Value requiring binary to decimal conversion",
        0.1 + 0.2,  # 0.30000000000000004 in binary
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Value that has repeating pattern in decimal
    run_benchmark(
        "Value with repeating pattern in decimal",
        1.0 / 3.0,  # 0.3333...
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Value with exact decimal representation
    run_benchmark(
        "Value with exact decimal representation",
        0.5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Value at boundary of precision
    run_benchmark(
        "Value at boundary of precision",
        9007199254740991.0,  # Maximum exact integer in Float64
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
    log_print("\n=== Float64 Constructor Benchmark Summary ===", log_file)
    log_print(
        "Benchmarked:      10 different Float64 constructor cases", log_file
    )
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
