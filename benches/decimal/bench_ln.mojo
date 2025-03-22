"""
Comprehensive benchmarks for Decimal natural logarithm function (ln).
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
    var log_filename = log_dir + "/benchmark_ln_" + timestamp + ".log"

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
    Run a benchmark comparing Mojo Decimal ln with Python Decimal ln.

    Args:
        name: Name of the benchmark case.
        input_value: String representation of value for ln(x).
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

    # Execute the operations once to verify correctness
    var mojo_result = dm.decimal.exponential.ln(mojo_decimal)
    var py_result = py_decimal.ln()

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = dm.decimal.exponential.ln(mojo_decimal)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_decimal.ln()
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo ln():     " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python ln():   " + String(python_time) + " ns per iteration",
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
    log_print(
        "=== DeciMojo Natural Logarithm Function (ln) Benchmark ===", log_file
    )
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
        "\nRunning natural logarithm function benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: ln(1) = 0
    run_benchmark(
        "ln(1) = 0",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: ln(e) ≈ 1
    run_benchmark(
        "ln(e) ≈ 1",
        "2.718281828459045235360287471",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: ln(2)
    run_benchmark(
        "ln(2)",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: ln(10)
    run_benchmark(
        "ln(10)",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: ln(0.5)
    run_benchmark(
        "ln(0.5)",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: ln(5)
    run_benchmark(
        "ln(5)",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: ln with small positive value
    run_benchmark(
        "Small positive value",
        "1.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: ln with very small positive value
    run_benchmark(
        "Very small positive value",
        "1.000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: ln with value slightly less than 1
    run_benchmark(
        "Value slightly less than 1",
        "0.9999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: ln with value slightly greater than 1
    run_benchmark(
        "Value slightly greater than 1",
        "1.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: ln with moderate value
    run_benchmark(
        "Moderate value",
        "7.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: ln with large value
    run_benchmark(
        "Large value",
        "1000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: ln with very large value
    run_benchmark(
        "Very large value",
        "1000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: ln with high precision input
    run_benchmark(
        "High precision input",
        "2.718281828459045235360287471",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: ln with fractional value
    run_benchmark(
        "Fractional value",
        "0.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: ln with fractional value of many digits
    run_benchmark(
        "Fractional value with many digits",
        "0.12345678901234567890123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: ln with approximate e value
    run_benchmark(
        "Approximate e value",
        "2.718",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: ln with larger value
    run_benchmark(
        "Larger value",
        "150",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: ln with value between 0 and 1
    run_benchmark(
        "Value between 0 and 1",
        "0.75",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: ln with value close to zero
    run_benchmark(
        "Value close to zero",
        "0.00001",
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
    log_print(
        "\n=== Natural Logarithm Function Benchmark Summary ===", log_file
    )
    log_print("Benchmarked:      20 different ln() cases", log_file)
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
