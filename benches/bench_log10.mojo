"""
Comprehensive benchmarks for Decimal log10() function.
Compares performance against Python's decimal module with diverse test cases.
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
    var log_filename = log_dir + "/benchmark_log10_" + timestamp + ".log"

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


fn run_benchmark_log10(
    name: String,
    input_value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Decimal.log10 with Python Decimal.log10.

    Args:
        name: Name of the benchmark case.
        input_value: String representation of the value to compute log10 of.
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
    var mojo_result = mojo_decimal.log10()
    var py_result = py_decimal.log10()

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = mojo_decimal.log10()
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_decimal.log10()
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo log10():   " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python log10(): " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo log10() Function Benchmark ===", log_file)
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
        "\nRunning log10() function benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Exact power of 10 (10^0)
    run_benchmark_log10(
        "Power of 10 (10^0)", "1", iterations, log_file, speedup_factors
    )

    # Case 2: Exact power of 10 (10^1)
    run_benchmark_log10(
        "Power of 10 (10^1)", "10", iterations, log_file, speedup_factors
    )

    # Case 3: Exact power of 10 (10^2)
    run_benchmark_log10(
        "Power of 10 (10^2)", "100", iterations, log_file, speedup_factors
    )

    # Case 4: Exact power of 10 (10^-1)
    run_benchmark_log10(
        "Power of 10 (10^-1)", "0.1", iterations, log_file, speedup_factors
    )

    # Case 5: Exact power of 10 (10^-2)
    run_benchmark_log10(
        "Power of 10 (10^-2)", "0.01", iterations, log_file, speedup_factors
    )

    # Case 6: Number between powers of 10 (middle)
    run_benchmark_log10(
        "Between powers - middle", "5", iterations, log_file, speedup_factors
    )

    # Case 7: Number between powers of 10 (closer to lower)
    run_benchmark_log10(
        "Between powers - closer to lower",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Number between powers of 10 (closer to upper)
    run_benchmark_log10(
        "Between powers - closer to upper",
        "9",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Decimal number with many digits
    run_benchmark_log10(
        "Decimal with many digits",
        "3.1415926535897932384626433832795",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Small number (close to 0)
    run_benchmark_log10(
        "Small number close to 0",
        "0.0000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Large number
    run_benchmark_log10(
        "Large number", "1000000000000", iterations, log_file, speedup_factors
    )

    # Case 12: Number close to 1 (slightly above)
    run_benchmark_log10(
        "Close to 1 (above)",
        "1.00000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Number close to 1 (slightly below)
    run_benchmark_log10(
        "Close to 1 (below)",
        "0.99999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Non-integer power of 10 (10^1.5)
    run_benchmark_log10(
        "Non-integer power of 10 (10^1.5)",
        "31.62277660168",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Repeating pattern number
    run_benchmark_log10(
        "Repeating pattern",
        "1.234567890123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Very precise input requiring full precision
    run_benchmark_log10(
        "Very precise input",
        "2.718281828459045235360287471352662",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Integer with many digits
    run_benchmark_log10(
        "Integer with many digits",
        "123456789012345678901234",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: The square root of 10
    run_benchmark_log10(
        "Square root of 10",
        "3.16227766017",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Scientific calculation value
    run_benchmark_log10(
        "Scientific calculation value",
        "299792458",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Random decimal value
    run_benchmark_log10(
        "Random decimal value",
        "4.2857142857",
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
    log_print("\n=== log10() Function Benchmark Summary ===", log_file)
    log_print("Benchmarked:      20 different log10() cases", log_file)
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
