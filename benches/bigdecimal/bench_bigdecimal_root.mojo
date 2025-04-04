"""
Comprehensive benchmarks for BigDecimal root function (nth root).
Compares performance against Python's decimal module with 50 diverse test cases.
"""

from decimojo import BigDecimal, RoundingMode
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
    var log_filename = log_dir + "/benchmark_bigdecimal_root_" + timestamp + ".log"

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


fn run_benchmark_root(
    name: String,
    value: String,
    nth_root: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal root with Python Decimal power(1/n).

    Args:
        name: Name of the benchmark case.
        value: String representation of the number to calculate the root of.
        nth_root: String representation of the root value (n in "nth root").
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:          " + name, log_file)
    log_print("Value:              " + value, log_file)
    log_print("Root (n):           " + nth_root, log_file)

    # Set up Mojo and Python values
    var mojo_value = BigDecimal(value)
    var mojo_n = BigDecimal(nth_root)
    var pydecimal = Python.import_module("decimal")
    var py_value = pydecimal.Decimal(value)
    var py_n = pydecimal.Decimal(nth_root)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_value.root(mojo_n, 28)

        # Python doesn't have a direct root function, use power(1/n) instead
        var py_one = pydecimal.Decimal("1")
        var py_reciprocal_n = py_one / py_n
        var py_result = py_value**py_reciprocal_n

        # Display results for verification
        log_print("Mojo result:        " + String(mojo_result), log_file)
        log_print("Python result:      " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_value.root(mojo_n, 28)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value**py_reciprocal_n
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = python_time / mojo_time
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo root:           " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python root:         " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("Speedup factor:     " + String(speedup), log_file)
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
    log_print("=== DeciMojo BigDecimal Root Function Benchmark ===", log_file)
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
    log_print("Mojo decimal precision: 28", log_file)

    # Define benchmark cases
    log_print(
        "\nRunning decimal root benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC ROOT TESTS ===

    # Case 1: Square root of a perfect square
    run_benchmark_root(
        "Square root of perfect square",
        "64",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Cube root of a perfect cube
    run_benchmark_root(
        "Cube root of perfect cube",
        "27",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: 4th root of a perfect 4th power
    run_benchmark_root(
        "4th root of perfect power",
        "16",
        "4",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: 5th root of a perfect 5th power
    run_benchmark_root(
        "5th root of perfect power",
        "32",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: 10th root of a perfect 10th power
    run_benchmark_root(
        "10th root of perfect power",
        "1024",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === FRACTIONAL ROOTS ===

    # Case 6: 0.5th root (square)
    run_benchmark_root(
        "0.5th root (square)",
        "16",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: 0.25th root (4th power)
    run_benchmark_root(
        "0.25th root (4th power)",
        "16",
        "0.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: 1.5th root
    run_benchmark_root(
        "1.5th root",
        "64",
        "1.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: 2.5th root
    run_benchmark_root(
        "2.5th root",
        "32",
        "2.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: 0.33333rd root (~ cube)
    run_benchmark_root(
        "0.33333rd root (~ cube)",
        "64",
        "0.33333",
        iterations,
        log_file,
        speedup_factors,
    )

    # === IMPERFECT ROOTS ===

    # Case 11: Square root of a non-perfect square
    run_benchmark_root(
        "Square root of non-perfect square",
        "2",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Cube root of a non-perfect cube
    run_benchmark_root(
        "Cube root of non-perfect cube",
        "10",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: 4th root of a non-perfect 4th power
    run_benchmark_root(
        "4th root of non-perfect power",
        "20",
        "4",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: 5th root of a non-perfect 5th power
    run_benchmark_root(
        "5th root of non-perfect power",
        "100",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: 10th root of a non-perfect 10th power
    run_benchmark_root(
        "10th root of non-perfect power",
        "1000",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === DECIMAL INPUTS ===

    # Case 16: Square root of decimal
    run_benchmark_root(
        "Square root of decimal",
        "2.25",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Cube root of decimal
    run_benchmark_root(
        "Cube root of decimal",
        "8.125",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: 4th root of decimal
    run_benchmark_root(
        "4th root of decimal",
        "0.0625",
        "4",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Root of a number < 1
    run_benchmark_root(
        "Root of number < 1",
        "0.25",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Root of a very small number
    run_benchmark_root(
        "Root of very small number",
        "0.000001",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # === NEGATIVE INPUTS (for odd roots) ===

    # Case 21: Cube root of negative number
    run_benchmark_root(
        "Cube root of negative number",
        "-27",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: 5th root of negative number
    run_benchmark_root(
        "5th root of negative number",
        "-32",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Negative fractional root
    run_benchmark_root(
        "Negative root",
        "16",
        "-2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Negative fractional root of negative number
    run_benchmark_root(
        "Negative odd root of negative number",
        "-27",
        "-3",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE NUMBERS ===

    # Case 25: Root of a large number
    run_benchmark_root(
        "Root of large number",
        "1000000",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: Large root of moderate number
    run_benchmark_root(
        "Large root value",
        "2",
        "100",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Root of a very large number
    run_benchmark_root(
        "Root of very large number",
        "1" + "0" * 20,
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Large root of small number
    run_benchmark_root(
        "Large root of small number",
        "1.5",
        "50",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Root of large decimal number
    run_benchmark_root(
        "Root of large decimal",
        "123456789.123456789",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Root with decimal places
    run_benchmark_root(
        "Root with decimal places",
        "12345",
        "2.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL CASES ===

    # Case 31: Root of 1
    run_benchmark_root(
        "Root of 1",
        "1",
        "42",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: 1st root (identity)
    run_benchmark_root(
        "1st root (identity)",
        "123.456",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: Root of 0
    run_benchmark_root(
        "Root of 0",
        "0",
        "7",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Root of Pi (irrational)
    run_benchmark_root(
        "Root of Pi",
        "3.14159265358979323846264338328",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Root of E (irrational)
    run_benchmark_root(
        "Root of E",
        "2.71828182845904523536028747135",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRECISION TESTS ===

    # Case 36: High precision root
    run_benchmark_root(
        "High precision root",
        "12345.6789",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 37: Root close to 1
    run_benchmark_root(
        "Root close to 1",
        "1.0001",
        "10000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 38: Root close to original value
    run_benchmark_root(
        "Root close to original value",
        "1.5",
        "1.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # === MATHEMATICAL CONSTANTS ===

    # Case 39: Square root of 2
    run_benchmark_root(
        "Square root of 2",
        "2",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: Cube root of 3
    run_benchmark_root(
        "Cube root of 3",
        "3",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 41: 4th root of 4
    run_benchmark_root(
        "4th root of 4",
        "4",
        "4",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 42: 5th root of 5
    run_benchmark_root(
        "5th root of 5",
        "5",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 43: 6th root of 6
    run_benchmark_root(
        "6th root of 6",
        "6",
        "6",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: 7th root of 7
    run_benchmark_root(
        "7th root of 7",
        "7",
        "7",
        iterations,
        log_file,
        speedup_factors,
    )

    # === APPLICATION CASES ===

    # Case 45: Financial compound interest (n periods)
    run_benchmark_root(
        "Compound interest root",
        "2",  # Final value is 2x the principal
        "10",  # 10 periods
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 46: Geometric mean of 5 numbers
    run_benchmark_root(
        "Geometric mean (5th root)",
        "120",  # Product of 2*3*4*5
        "5",  # 5th root
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: Sound pressure level conversion
    run_benchmark_root(
        "Sound pressure level (10th root)",
        "10000000000",  # 10^10
        "10",  # 10th root
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 48: Volume scaling (cube root)
    run_benchmark_root(
        "Volume scaling (cube root)",
        "8",  # Volume increase by factor of 8
        "3",  # Cube root for linear scaling
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: Population growth rate (nth root)
    run_benchmark_root(
        "Population growth rate",
        "1.5",  # Population grew by 50%
        "5",  # Over 5 years
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: Market return calculation
    run_benchmark_root(
        "Market return calculation",
        "2.5",  # 150% return over period
        "10",  # 10 years
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
        log_print(
            "\n=== BigDecimal Root Function Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:        "
            + String(len(speedup_factors))
            + " different root cases",
            log_file,
        )
        log_print(
            "Each case ran:      " + String(iterations) + " iterations",
            log_file,
        )
        log_print(
            "Average speedup:    " + String(average_speedup) + "×", log_file
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
