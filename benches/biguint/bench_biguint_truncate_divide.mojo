"""
Comprehensive benchmarks for BigUInt truncate_divide operation.
Compares performance against Python's built-in int division with 20 diverse test cases.
BigUInt is an unsigned integer type, so all test cases use positive numbers only.
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

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/benchmark_biguint_truncate_divide_" + timestamp + ".log"

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


fn run_benchmark_truncate_divide(
    name: String,
    dividend: String,
    divisor: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigUInt truncate_divide with Python int division.

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
    var mojo_dividend = BigUInt(dividend)
    var mojo_divisor = BigUInt(divisor)
    var py = Python.import_module("builtins")
    var py_dividend = py.int(dividend)
    var py_divisor = py.int(divisor)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_dividend.truncate_divide(mojo_divisor)
        var py_result = py_dividend // py_divisor

        # Display results for verification
        log_print("Mojo result:     " + String(mojo_result), log_file)
        log_print("Python result:   " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_dividend.truncate_divide(mojo_divisor)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_dividend // py_divisor
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = python_time / mojo_time
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo division:   " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python division: " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigUInt Truncate Division Benchmark ===", log_file)
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

    # Define benchmark cases (all positive numbers for BigUInt)
    log_print(
        "\nRunning truncate division benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Simple division with no remainder
    run_benchmark_truncate_divide(
        "Simple division, no remainder",
        "100",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Division with remainder
    run_benchmark_truncate_divide(
        "Division with remainder",
        "10",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Division of small numbers
    run_benchmark_truncate_divide(
        "Division of small numbers",
        "7",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Division resulting in zero
    run_benchmark_truncate_divide(
        "Division resulting in zero",
        "5",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Division by one
    run_benchmark_truncate_divide(
        "Division by one",
        "12345",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Zero dividend
    run_benchmark_truncate_divide(
        "Zero dividend",
        "0",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Large number division
    run_benchmark_truncate_divide(
        "Large number division",
        "9999999999",  # 10 billion
        "333",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Very large number division
    run_benchmark_truncate_divide(
        "Very large number division",
        "1" + "0" * 50,  # 10^50
        "7",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Division of large numbers with exact result
    run_benchmark_truncate_divide(
        "Division of large numbers with exact result",
        "1" + "0" * 30,  # 10^30
        "1" + "0" * 10,  # 10^10
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Division by large number
    run_benchmark_truncate_divide(
        "Division by large number",
        "12345",
        "9" * 20,  # 20 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Fibonacci number division
    run_benchmark_truncate_divide(
        "Fibonacci number division",
        "6765",  # Fib(20)
        "4181",  # Fib(19)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Prime number division
    run_benchmark_truncate_divide(
        "Prime number division",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "997",  # Prime
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Division of numbers near UInt64 limit
    run_benchmark_truncate_divide(
        "Division near UInt64 limit",
        "18446744073709551615",  # UInt64.MAX
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Division with divisor just below dividend
    run_benchmark_truncate_divide(
        "Division with divisor just below dividend",
        "1000",
        "999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Division with exact powers of 10
    run_benchmark_truncate_divide(
        "Division with exact powers of 10",
        "1" + "0" * 20,  # 10^20
        "1" + "0" * 5,  # 10^5
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Division of repeated digits
    run_benchmark_truncate_divide(
        "Division of repeated digits",
        "9" * 30,  # 30 nines
        "9" * 15,  # 15 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Division with extremely large dividend and small divisor
    run_benchmark_truncate_divide(
        "Extreme large dividend and small divisor",
        "9" * 100,  # 100 nines
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Division with powers of 2
    run_benchmark_truncate_divide(
        "Division with powers of 2",
        "1" + "0" * 50,  # 10^50
        "256",  # 2^8
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Division yielding a single-digit result
    run_benchmark_truncate_divide(
        "Division yielding a single-digit result",
        "123456789",
        "123456780",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Division with random large numbers
    run_benchmark_truncate_divide(
        "Division with random large numbers",
        "8675309123456789098765432112345678909876543211234567",
        "12345678901234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Division with around 50 digits and with divisor just below dividend
    run_benchmark_truncate_divide(
        "Division with around 50 digits divisor just below dividend",
        "12345" * 10,
        "6789" * 12,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Division of very large repeated digits
    run_benchmark_truncate_divide(
        "Division of repeated digits",
        "990132857498314692374162398217" * 10,  # 30 * 10 = 300 digits
        "85172390413429847239" * 10,  # 20 * 10 = 200 digits
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
            "\n=== BigUInt Truncate Division Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different division cases",
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
