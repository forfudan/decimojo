"""
Comprehensive benchmarks for Decimal128 modulo (%) operation.
Compares performance against Python's decimal module with diverse test cases.
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
    var log_filename = log_dir + "/benchmark_modulo_" + timestamp + ".log"

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


fn run_benchmark_modulo(
    name: String,
    dividend: String,
    divisor: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Dec128 modulo with Python decimal modulo.

    Args:
        name: Name of the benchmark case.
        dividend: String representation of the dividend.
        divisor: String representation of the divisor.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Dividend:        " + dividend, log_file)
    log_print("Divisor:         " + divisor, log_file)

    # Set up Mojo and Python values
    var mojo_dividend = Decimal128(dividend)
    var mojo_divisor = Decimal128(divisor)
    var pydecimal = Python.import_module("decimal")
    var py_dividend = pydecimal.Decimal128(dividend)
    var py_divisor = pydecimal.Decimal128(divisor)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_dividend % mojo_divisor
        var py_result = py_dividend % py_divisor

        # Display results for verification
        log_print("Mojo result:     " + String(mojo_result), log_file)
        log_print("Python result:   " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_dividend % mojo_divisor
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_dividend % py_divisor
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo %:          " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python %:        " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("Speedup factor:  " + String(speedup), log_file)
    except e:
        log_print("Error occurred during benchmark: " + String(e), log_file)
        log_print("Skipping this benchmark case", log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create a Mojo List to store speedup factors for averaging later
    var speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo Modulo (%) Benchmark ===", log_file)
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

    var iterations = 10000  # Higher iterations as this operation should be fast
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
        "\nRunning modulo (%) benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Simple modulo with remainder
    run_benchmark_modulo(
        "Simple modulo with remainder",
        "10",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Modulo with no remainder
    run_benchmark_modulo(
        "Modulo with no remainder",
        "10",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Modulo with decimal values
    run_benchmark_modulo(
        "Decimal128 values (even division)",
        "10.5",
        "3.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Modulo with different decimal places
    run_benchmark_modulo(
        "Different decimal places",
        "10.75",
        "2.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Modulo with modulus > dividend
    run_benchmark_modulo(
        "Modulus > dividend",
        "3",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Negative dividend, positive divisor
    run_benchmark_modulo(
        "Negative dividend, positive divisor",
        "-10",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Positive dividend, negative divisor
    run_benchmark_modulo(
        "Positive dividend, negative divisor",
        "10",
        "-3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Negative dividend, negative divisor
    run_benchmark_modulo(
        "Negative dividend, negative divisor",
        "-10",
        "-3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Decimal128 values, negative dividend
    run_benchmark_modulo(
        "Decimal128 values, negative dividend",
        "-10.5",
        "3.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Decimal128 values with remainder, negative dividend
    run_benchmark_modulo(
        "Decimal128 with remainder, negative dividend",
        "-10.5",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Modulo by 1
    run_benchmark_modulo(
        "Modulo by 1",
        "10",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Zero dividend
    run_benchmark_modulo(
        "Zero dividend",
        "0",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Modulo with a decimal < 1
    run_benchmark_modulo(
        "Divisor < 1",
        "10",
        "0.3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Large number modulo
    run_benchmark_modulo(
        "Large number modulo",
        "1000000007",
        "13",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Small number modulo
    run_benchmark_modulo(
        "Small number modulo",
        "0.0000023",
        "0.0000007",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Equal values
    run_benchmark_modulo(
        "Equal values",
        "7.5",
        "7.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: High precision values
    run_benchmark_modulo(
        "High precision values",
        "3.14159265358979323846",
        "1.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Values close to exact multiple
    run_benchmark_modulo(
        "Values close to exact multiple",
        "9.999999",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Large integers modulo
    run_benchmark_modulo(
        "Large integers modulo",
        "12345678901234567890",
        "9876543210",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Values that generate cyclic patterns
    run_benchmark_modulo(
        "Values generating repeating patterns",
        "1",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Calculate average speedup factor (ignoring any cases that might have failed)
    if len(speedup_factors) > 0:
        var sum_speedup: Float64 = 0.0
        for i in range(len(speedup_factors)):
            sum_speedup += speedup_factors[i]
        var average_speedup = sum_speedup / Float64(len(speedup_factors))

        # Display summary
        log_print("\n=== Modulo (%) Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different modulo cases",
            log_file,
        )
        log_print(
            "Each case ran:    " + String(iterations) + " iterations", log_file
        )
        log_print(
            "Average speedup:  " + String(average_speedup) + "×", log_file
        )

        # List all speedup factors
        log_print("\nIndividual speedup factors:", log_file)
        for i in range(len(speedup_factors)):
            log_print(
                String("Case {}: {}×").format(
                    i + 1, round(speedup_factors[i], 2)
                ),
                log_file,
            )
    else:
        log_print("\nNo valid benchmark cases were completed", log_file)

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
