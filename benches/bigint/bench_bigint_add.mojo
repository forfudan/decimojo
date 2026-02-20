"""
Comprehensive benchmarks for BigInt addition.
Compares performance against Python's built-in int with 20 diverse test cases.
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
    var log_filename = log_dir + "/benchmark_bigint_add_" + timestamp + ".log"

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


fn run_benchmark_add(
    name: String,
    value1: String,
    value2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
    mut bigint2_speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigInt, BigInt2, and Python int addition.

    Args:
        name: Name of the benchmark case.
        value1: String representation of first operand.
        value2: String representation of second operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store BigInt speedup factors.
        bigint2_speedup_factors: Mojo List to store BigInt2 speedup factors.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("First operand:   " + value1, log_file)
    log_print("Second operand:  " + value2, log_file)

    # Set up Mojo BigInt, BigInt2, and Python values
    var mojo_value1 = BigInt(value1)
    var mojo_value2 = BigInt(value2)
    var mojo2_value1 = BigInt2(value1)
    var mojo2_value2 = BigInt2(value2)
    var py = Python.import_module("builtins")
    var py_value1 = py.int(value1)
    var py_value2 = py.int(value2)

    # Execute the operations once to verify correctness
    var mojo_result = mojo_value1 + mojo_value2
    var mojo2_result = mojo2_value1 + mojo2_value2
    var py_result = py_value1 + py_value2

    # Display results for verification
    log_print("BigInt result:   " + String(mojo_result), log_file)
    log_print("BigInt2 result:  " + String(mojo2_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark BigInt implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = mojo_value1 + mojo_value2
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark BigInt2 implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = mojo2_value1 + mojo2_value2
    var mojo2_time = (perf_counter_ns() - t0) / iterations
    if mojo2_time == 0:
        mojo2_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_value1 + py_value2
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factors (Python / Mojo)
    var speedup = Float64(python_time) / Float64(mojo_time)
    var speedup2 = Float64(python_time) / Float64(mojo2_time)
    speedup_factors.append(Float64(speedup))
    bigint2_speedup_factors.append(Float64(speedup2))

    # Print results with speedup comparison
    log_print(
        "BigInt addition:  " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "BigInt2 addition: " + String(mojo2_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python addition:  " + String(python_time) + " ns per iteration",
        log_file,
    )
    log_print("BigInt speedup:   " + String(speedup) + "×", log_file)
    log_print("BigInt2 speedup:  " + String(speedup2) + "×", log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create Mojo Lists to store speedup factors for averaging later
    var speedup_factors = List[Float64]()
    var bigint2_speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo BigInt Addition Benchmark ===", log_file)
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
        "\nRunning addition benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Small integer addition
    run_benchmark_add(
        "Small integer addition",
        "42",
        "58",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 2: Medium integer addition
    run_benchmark_add(
        "Medium integer addition",
        "12345",
        "67890",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 3: Large integer addition
    run_benchmark_add(
        "Large integer addition",
        "9999999999",  # 10 billion
        "1234567890",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 4: Very large integer addition
    run_benchmark_add(
        "Very large integer addition",
        "9" * 50,  # 50-digit number
        "1" + "0" * 49,  # 10^49
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 5: Negative number addition
    run_benchmark_add(
        "Negative number addition",
        "-12345",
        "-67890",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 6: Mixed sign addition (positive + negative)
    run_benchmark_add(
        "Mixed sign addition (positive + negative)",
        "12345",
        "-6789",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 7: Mixed sign addition (negative + positive)
    run_benchmark_add(
        "Mixed sign addition (negative + positive)",
        "-12345",
        "67890",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 8: Addition with zero
    run_benchmark_add(
        "Addition with zero",
        "123456789",
        "0",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 9: Addition resulting in zero (a + (-a))
    run_benchmark_add(
        "Addition resulting in zero",
        "987654321",
        "-987654321",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 10: Power-of-10 addition
    run_benchmark_add(
        "Power-of-10 addition",
        "1" + "0" * 20,  # 10^20
        "1" + "0" * 15,  # 10^15
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 11: Fibonacci numbers addition
    run_benchmark_add(
        "Fibonacci numbers addition",
        "10946",  # Fib(21)
        "17711",  # Fib(22)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 12: Extreme large integer addition
    run_benchmark_add(
        "Extreme large integer addition",
        "9" * 100,  # 100-digit number
        "1" + "0" * 99,  # 10^99
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 13: Addition with uneven length numbers
    run_benchmark_add(
        "Addition with uneven length numbers",
        "1" + "0" * 30,  # 10^30
        "9" * 10,  # 10-digit number
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 14: Addition with uneven length numbers (reversed)
    run_benchmark_add(
        "Addition with uneven length numbers (reversed)",
        "9" * 10,  # 10-digit number
        "1" + "0" * 30,  # 10^30
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 15: Addition with many carries
    run_benchmark_add(
        "Addition with many carries",
        "9" * 25,  # 25 nines
        "1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 16: Prime number addition
    run_benchmark_add(
        "Prime number addition",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "2305843009213693951",  # Mersenne prime (2^61 - 1)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 17: Addition of numbers near Int64 limit
    run_benchmark_add(
        "Addition near Int64 limit",
        "9223372036854775807",  # Int64.MAX
        "9223372036854775807",  # Int64.MAX
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 18: Addition of numbers near UInt64 limit
    run_benchmark_add(
        "Addition near UInt64 limit",
        "18446744073709551615",  # UInt64.MAX
        "1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 19: Addition of repeated digits
    run_benchmark_add(
        "Addition of repeated digits",
        "1" * 40,  # 40 ones
        "9" * 40,  # 40 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 20: Addition of powers of two
    run_benchmark_add(
        "Addition of powers of two",
        "340282366920938463463374607431768211456",  # 2^128
        "115792089237316195423570985008687907853269984665640564039457584007913129639936",  # 2^256
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Calculate average speedup factors
    var sum_speedup: Float64 = 0.0
    for i in range(len(speedup_factors)):
        sum_speedup += speedup_factors[i]
    var average_speedup = sum_speedup / Float64(len(speedup_factors))

    var sum_speedup2: Float64 = 0.0
    for i in range(len(bigint2_speedup_factors)):
        sum_speedup2 += bigint2_speedup_factors[i]
    var average_speedup2 = sum_speedup2 / Float64(len(bigint2_speedup_factors))

    # Display summary
    log_print("\n=== BigInt Addition Benchmark Summary ===", log_file)
    log_print("Benchmarked:              20 different addition cases", log_file)
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

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
