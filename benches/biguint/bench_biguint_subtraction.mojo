"""
Comprehensive benchmarks for BigUInt subtraction.
Compares performance against Python's built-in int with diverse test cases.
"""

from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.arithmetics
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
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(1000000)

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = (
        log_dir + "/benchmark_biguint_subtraction_" + timestamp + ".log"
    )

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


fn run_benchmark_subtraction(
    name: String,
    value1: String,
    value2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigUInt subtraction with Python int subtraction.

    Args:
        name: Name of the benchmark case.
        value1: String representation of first operand.
        value2: String representation of second operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("First operand:   " + value1, log_file)
    log_print("Second operand:  " + value2, log_file)

    # Set up Mojo and Python values
    var mojo_value1 = BigUInt(value1)
    var mojo_value2 = BigUInt(value2)
    var py = Python.import_module("builtins")
    var py_value1 = py.int(value1)
    var py_value2 = py.int(value2)

    # Execute the operations once to verify correctness
    var mojo_result = mojo_value1 - mojo_value2
    var py_result = py_value1 - py_value2

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = mojo_value1 - mojo_value2
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_value1 - py_value2
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = Float64(python_time) / Float64(mojo_time)
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo subtraction:   " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python subtraction: " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigUInt Subtraction Benchmark ===", log_file)
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

    # Define benchmark cases
    log_print(
        "\nRunning subtraction benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 26: Subtraction with 2 words - 1 word
    run_benchmark_subtraction(
        "Subtraction with 2 words - 1 word",
        "123456789" * 2,
        "987654321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Subtraction with 4 words - 2 words
    run_benchmark_subtraction(
        "Subtraction with 4 words - 2 words",
        "123456789" * 4,
        "987654321" * 2,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Subtraction with 8 words - 4 words
    run_benchmark_subtraction(
        "Subtraction with 8 words - 4 words",
        "123456789" * 8,
        "987654321" * 4,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Subtraction with 16 words - 8 words
    run_benchmark_subtraction(
        "Subtraction with 16 words - 8 words",
        "123456789" * 16,
        "987654321" * 8,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Subtraction with 32 words - 16 words
    run_benchmark_subtraction(
        "Subtraction with 32 words - 16 words",
        "123456789" * 32,
        "987654321" * 16,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: Subtraction with 64 words - 32 words
    run_benchmark_subtraction(
        "Subtraction with 64 words - 32 words",
        "123456789" * 64,
        "987654321" * 32,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Subtraction with 256 words - 128 words
    run_benchmark_subtraction(
        "Subtraction with 256 words - 128 words",
        "123456789" * 256,
        "987654321" * 128,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: Subtraction with 1024 words - 512 words
    run_benchmark_subtraction(
        "Subtraction with 1024 words - 512 words",
        "123456789" * 1024,
        "987654321" * 512,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Subtraction with 4096 words - 2048 words
    run_benchmark_subtraction(
        "Subtraction with 4096 words - 2048 words",
        "123456789" * 4096,
        "987654321" * 2048,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Subtraction with 16384 words - 8192 words
    run_benchmark_subtraction(
        "Subtraction with 16384 words - 8192 words",
        "123456789" * 16384,
        "987654321" * 8192,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 36: Subtraction with 32768 words - 16384 words
    run_benchmark_subtraction(
        "Subtraction with 32768 words - 16384 words",
        "123456789" * 32768,
        "987654321" * 16384,
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
    log_print("\n=== BigUInt Subtraction Benchmark Summary ===", log_file)
    log_print("Benchmarked:      different subtraction cases", log_file)
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
