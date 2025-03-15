"""
Comprehensive benchmarks for Decimal exponential function (exp).
Compares performance against Python's decimal module with 20 diverse test cases.
"""

from decimojo.prelude import dm, Decimal, RoundingMode
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
    var log_filename = log_dir + "/benchmark_exp_" + timestamp + ".log"

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
    input_value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Decimal exp with Python Decimal exp.

    Args:
        name: Name of the benchmark case.
        input_value: String representation of value for exp(x).
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Input value:     " + input_value, log_file)

    # Set up Mojo and Python values
    var mojo_decimal = Decimal(input_value)
    var pydecimal = Python.import_module("decimal")
    var py_decimal = pydecimal.Decimal(input_value)
    var _py_math = Python.import_module("math")

    # Execute the operations once to verify correctness
    var mojo_result = dm.exponential.exp(mojo_decimal)
    var py_result = py_decimal.exp()

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = dm.exponential.exp(mojo_decimal)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_decimal.exp()
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo exp():     " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python exp():   " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo Exponential Function (exp) Benchmark ===", log_file)
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
        "\nRunning exponential function benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: exp(0) = 1
    run_benchmark(
        "exp(0) = 1",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: exp(1) ≈ e
    run_benchmark(
        "exp(1) ≈ e",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: exp(2) ≈ 7.389...
    run_benchmark(
        "exp(2)",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: exp(-1) = 1/e
    run_benchmark(
        "exp(-1) = 1/e",
        "-1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: exp(0.5) ≈ sqrt(e)
    run_benchmark(
        "exp(0.5) ≈ sqrt(e)",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: exp(-0.5) ≈ 1/sqrt(e)
    run_benchmark(
        "exp(-0.5) ≈ 1/sqrt(e)",
        "-0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: exp with small positive value
    run_benchmark(
        "Small positive value",
        "0.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: exp with very small positive value
    run_benchmark(
        "Very small positive value",
        "0.000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: exp with small negative value
    run_benchmark(
        "Small negative value",
        "-0.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: exp with very small negative value
    run_benchmark(
        "Very small negative value",
        "-0.000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: exp with moderate value (e^3)
    run_benchmark(
        "Moderate value (e^3)",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: exp with moderate negative value (e^-3)
    run_benchmark(
        "Moderate negative value (e^-3)",
        "-3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: exp with large value (e^10)
    run_benchmark(
        "Large value (e^10)",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: exp with large negative value (e^-10)
    run_benchmark(
        "Large negative value (e^-10)",
        "-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: exp with Pi
    run_benchmark(
        "exp(π)",
        "3.14159265358979323846",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: exp with high precision input
    run_benchmark(
        "High precision input",
        "1.234567890123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: exp with fractional value
    run_benchmark(
        "Fractional value (e^1.5)",
        "1.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: exp with negative fractional value
    run_benchmark(
        "Negative fractional value (e^-1.5)",
        "-1.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: exp with approximate e value
    run_benchmark(
        "Approximate e value",
        "2.718281828459045",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: exp with larger value (e^15)
    run_benchmark(
        "Larger value (e^15)",
        "15",
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
    log_print("\n=== Exponential Function Benchmark Summary ===", log_file)
    log_print("Benchmarked:      20 different exp() cases", log_file)
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
