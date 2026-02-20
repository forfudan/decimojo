"""
Comprehensive benchmarks for BigInt truncate_divide operation.
Compares performance against Python's built-in int division with 20 diverse test cases.
"""

from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
from decimojo.bigint2.bigint2 import BigInt2
import decimojo.bigint2.arithmetics
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
    var log_filename = (
        log_dir + "/benchmark_bigint_truncate_divide_" + timestamp + ".log"
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


fn run_benchmark_truncate_divide(
    name: String,
    dividend: String,
    divisor: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
    mut bigint2_speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigInt, BigInt2, and Python int truncate division.

    Args:
        name: Name of the benchmark case.
        dividend: String representation of the dividend.
        divisor: String representation of the divisor.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store BigInt speedup factors.
        bigint2_speedup_factors: Mojo List to store BigInt2 speedup factors.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Dividend:        " + dividend, log_file)
    log_print("Divisor:         " + divisor, log_file)

    # Set up Mojo BigInt, BigInt2, and Python values
    var mojo_dividend = BigInt(dividend)
    var mojo_divisor = BigInt(divisor)
    var mojo2_dividend = BigInt2(dividend)
    var mojo2_divisor = BigInt2(divisor)
    var py = Python.import_module("builtins")
    var py_dividend = py.int(dividend)
    var py_divisor = py.int(divisor)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_dividend.truncate_divide(mojo_divisor)
        var mojo2_result = mojo2_dividend.truncate_divide(mojo2_divisor)
        var py_result = py_dividend // py_divisor

        # Display results for verification
        log_print("BigInt result:   " + String(mojo_result), log_file)
        log_print("BigInt2 result:  " + String(mojo2_result), log_file)
        log_print("Python result:   " + String(py_result), log_file)

        # Benchmark BigInt implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_dividend.truncate_divide(mojo_divisor)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark BigInt2 implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo2_dividend.truncate_divide(mojo2_divisor)
        var mojo2_time = (perf_counter_ns() - t0) / iterations
        if mojo2_time == 0:
            mojo2_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_dividend // py_divisor
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factors (Python / Mojo)
        var speedup = Float64(python_time) / Float64(mojo_time)
        var speedup2 = Float64(python_time) / Float64(mojo2_time)
        speedup_factors.append(Float64(speedup))
        bigint2_speedup_factors.append(Float64(speedup2))

        # Print results with speedup comparison
        log_print(
            "BigInt division:  " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "BigInt2 division: " + String(mojo2_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python division:  " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("BigInt speedup:   " + String(speedup) + "×", log_file)
        log_print("BigInt2 speedup:  " + String(speedup2) + "×", log_file)
    except e:
        log_print("Error occurred during benchmark: " + String(e), log_file)
        log_print("Skipping this benchmark case", log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create Mojo Lists to store speedup factors for averaging later
    var speedup_factors = List[Float64]()
    var bigint2_speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo BigInt Truncate Division Benchmark ===", log_file)
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

    # Define benchmark cases
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
        bigint2_speedup_factors,
    )

    # Case 2: Division with remainder
    run_benchmark_truncate_divide(
        "Division with remainder",
        "10",
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 3: Division of small numbers
    run_benchmark_truncate_divide(
        "Division of small numbers",
        "7",
        "2",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 4: Division resulting in zero
    run_benchmark_truncate_divide(
        "Division resulting in zero",
        "5",
        "10",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 5: Division by one
    run_benchmark_truncate_divide(
        "Division by one",
        "12345",
        "1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 6: Negative dividend, positive divisor
    run_benchmark_truncate_divide(
        "Negative dividend, positive divisor",
        "-10",
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 7: Positive dividend, negative divisor
    run_benchmark_truncate_divide(
        "Positive dividend, negative divisor",
        "10",
        "-3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 8: Negative dividend, negative divisor
    run_benchmark_truncate_divide(
        "Negative dividend, negative divisor",
        "-10",
        "-3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 9: Zero dividend
    run_benchmark_truncate_divide(
        "Zero dividend",
        "0",
        "5",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 10: Large number division
    run_benchmark_truncate_divide(
        "Large number division",
        "9999999999",  # 10 billion
        "333",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 11: Very large number division
    run_benchmark_truncate_divide(
        "Very large number division",
        "1" + "0" * 50,  # 10^50
        "7",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 12: Division of large numbers with exact result
    run_benchmark_truncate_divide(
        "Division of large numbers with exact result",
        "1" + "0" * 30,  # 10^30
        "1" + "0" * 10,  # 10^10
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 13: Division by large number
    run_benchmark_truncate_divide(
        "Division by large number",
        "12345",
        "9" * 20,  # 20 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 14: Fibonacci number division
    run_benchmark_truncate_divide(
        "Fibonacci number division",
        "6765",  # Fib(20)
        "4181",  # Fib(19)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 15: Prime number division
    run_benchmark_truncate_divide(
        "Prime number division",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "997",  # Prime
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 16: Division of numbers near Int64 limit
    run_benchmark_truncate_divide(
        "Division near Int64 limit",
        "9223372036854775807",  # Int64.MAX
        "2",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 17: Division with around 50 digits and with divisor just below dividend
    run_benchmark_truncate_divide(
        "Division with around 50 digits divisor just below dividend",
        "12345" * 10,
        "6789" * 12,
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 18: Division with exact powers of 10
    run_benchmark_truncate_divide(
        "Division with exact powers of 10",
        "1" + "0" * 20,  # 10^20
        "1" + "0" * 5,  # 10^5
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 19: Division of repeated digits
    run_benchmark_truncate_divide(
        "Division of repeated digits",
        "990132857498314692374162398217" * 10,  # 30 * 10 = 300 digits
        "85172390413429847239" * 10,  # 20 * 10 = 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 20: Division with extremely large dividend and small divisor
    run_benchmark_truncate_divide(
        "Extreme large dividend and small divisor",
        "9" * 100,  # 100 nines
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Calculate average speedup factors (ignoring any cases that might have failed)
    if len(speedup_factors) > 0:
        var sum_speedup: Float64 = 0.0
        for i in range(len(speedup_factors)):
            sum_speedup += speedup_factors[i]
        var average_speedup = sum_speedup / Float64(len(speedup_factors))

        var sum_speedup2: Float64 = 0.0
        for i in range(len(bigint2_speedup_factors)):
            sum_speedup2 += bigint2_speedup_factors[i]
        var average_speedup2 = sum_speedup2 / Float64(
            len(bigint2_speedup_factors)
        )

        # Display summary
        log_print(
            "\n=== BigInt Truncate Division Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:              "
            + String(len(speedup_factors))
            + " different division cases",
            log_file,
        )
        log_print(
            "Each case ran:            " + String(iterations) + " iterations",
            log_file,
        )
        log_print(
            "BigInt avg speedup:       " + String(average_speedup) + "×",
            log_file,
        )
        log_print(
            "BigInt2 avg speedup:      " + String(average_speedup2) + "×",
            log_file,
        )

        # List all speedup factors
        log_print("\nIndividual speedup factors:", log_file)
        for i in range(len(speedup_factors)):
            log_print(
                String("Case {}: BigInt {}× | BigInt2 {}×").format(
                    i + 1,
                    round(speedup_factors[i], 2),
                    round(bigint2_speedup_factors[i], 2),
                ),
                log_file,
            )
    else:
        log_print("\nNo valid benchmark cases were completed", log_file)

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
