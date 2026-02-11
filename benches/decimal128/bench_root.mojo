"""
Comprehensive benchmarks for Decimal128 nth root function (root).
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
    var log_filename = log_dir + "/benchmark_root_" + timestamp + ".log"

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
    value: String,
    nth_root: Int,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Dec128 root with Python decimal power(1/n).

    Args:
        name: Name of the benchmark case.
        value: String representation of the number to find the nth root of.
        nth_root: The root value (2 for square root, 3 for cube root, etc.).
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Value:           " + value, log_file)
    log_print("Root:            " + String(nth_root), log_file)

    # Set up Mojo and Python values
    var mojo_decimal = Decimal128(value)
    var pydecimal = Python.import_module("decimal")
    var py_decimal = pydecimal.Decimal128(value)
    var py_root = pydecimal.Decimal128(String(nth_root))
    var py_frac = pydecimal.Decimal128(1) / py_root

    # Special case: Python can't directly compute odd root of negative number
    var is_negative_odd_root = value.startswith("-") and nth_root % 2 == 1
    var py_result: PythonObject

    # Execute the operations once to verify correctness
    var mojo_result = dm.decimal128.exponential.root(mojo_decimal, nth_root)

    # Handle Python calculation, accounting for negative odd root limitation
    if is_negative_odd_root:
        # For negative numbers with odd roots in Python, we need to:
        # 1. Take absolute value
        # 2. Compute the root
        # 3. Negate the result
        var abs_py_decimal = py_decimal.copy_abs()
        py_result = -(abs_py_decimal**py_frac)
        log_print(
            (
                "Note: Python doesn't directly support odd roots of negative"
                " numbers."
            ),
            log_file,
        )
        log_print(
            "      Using abs() and then negating the result for comparison.",
            log_file,
        )
    else:
        try:
            py_result = py_decimal**py_frac
        except:
            log_print(
                "Python cannot compute this root. Skipping Python benchmark.",
                log_file,
            )
            py_result = Python.evaluate(
                "None"
            )  # Correct way to get Python's None

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    if not (
        py_result is Python.evaluate("None")
    ):  # Correct way to check for None
        log_print("Python result:   " + String(py_result), log_file)
    else:
        log_print("Python result:   ERROR - cannot compute", log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = dm.decimal128.exponential.root(mojo_decimal, nth_root)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation (if possible)
    var python_time: Float64
    if not is_negative_odd_root and not (
        py_result is Python.evaluate("None")
    ):  # Correct way to check for None
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_decimal**py_frac
        python_time = (perf_counter_ns() - t0) / iterations
    elif is_negative_odd_root:
        # For negative numbers with odd roots, benchmark our workaround
        var abs_py_decimal = py_decimal.copy_abs()
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = -(abs_py_decimal**py_frac)
        python_time = (perf_counter_ns() - t0) / iterations
    else:
        log_print("Python benchmark skipped", log_file)
        python_time = 0

    # Calculate speedup factor (if Python benchmark ran)
    if python_time > 0:
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo root():     " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python root():   " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("Speedup factor:  " + String(speedup), log_file)
    else:
        log_print(
            "Mojo root():     " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print("Python root():   N/A", log_file)
        log_print("Speedup factor:  N/A", log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create a Mojo List to store speedup factors for averaging later
    var speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo Root Function Benchmark ===", log_file)
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
    log_print(
        "Mojo decimal precision: " + String(Decimal128.MAX_SCALE), log_file
    )

    # Define benchmark cases
    log_print(
        "\nRunning root function benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Square root of perfect square
    run_benchmark(
        "Square root of perfect square",
        "9",
        2,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Square root of non-perfect square
    run_benchmark(
        "Square root of non-perfect square",
        "2",
        2,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Cube root of perfect cube
    run_benchmark(
        "Cube root of perfect cube",
        "8",
        3,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Cube root of non-perfect cube
    run_benchmark(
        "Cube root of non-perfect cube",
        "10",
        3,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Fourth root of perfect power
    run_benchmark(
        "Fourth root of perfect power",
        "16",
        4,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Fifth root of perfect power
    run_benchmark(
        "Fifth root of perfect power",
        "32",
        5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Root of decimal < 1
    run_benchmark(
        "Root of decimal < 1",
        "0.25",
        2,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Root of decimal < 1
    run_benchmark(
        "Root of small decimal",
        "0.0625",
        4,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: High precision decimal
    run_benchmark(
        "High precision decimal",
        "2.7182818284590452353602874",
        2,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Large integer
    run_benchmark(
        "Large integer",
        "1000000",
        2,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Large root
    run_benchmark(
        "Large root",
        "10",
        100,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Odd root of negative number
    run_benchmark(
        "Odd root of negative number",
        "-27",
        3,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Root of 1 (any root)
    run_benchmark(
        "Root of 1 (any root)",
        "1",
        7,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Root of 0
    run_benchmark(
        "Root of 0",
        "0",
        3,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Custom decimal
    run_benchmark(
        "Custom decimal",
        "123.456",
        2,
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
    log_print("\n=== Root Function Benchmark Summary ===", log_file)
    log_print("Benchmarked:      15 different root() cases", log_file)
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
