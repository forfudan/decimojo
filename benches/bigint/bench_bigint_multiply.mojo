"""
Comprehensive benchmarks for BigInt multiplication.
Compares performance against Python's built-in int multiplication with 60 diverse test cases.
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
        log_dir + "/benchmark_bigint_multiply_" + timestamp + ".log"
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


fn run_benchmark_multiply(
    name: String,
    factor1: String,
    factor2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
    mut bigint2_speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigInt, BigInt2, and Python int multiplication.

    Args:
        name: Name of the benchmark case.
        factor1: String representation of the first factor.
        factor2: String representation of the second factor.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store BigInt speedup factors.
        bigint2_speedup_factors: Mojo List to store BigInt2 speedup factors.
    """
    log_print("\nBenchmark:     " + name, log_file)
    log_print("First factor:  " + factor1, log_file)
    log_print("Second factor: " + factor2, log_file)

    # Set up Mojo BigInt, BigInt2, and Python values
    var mojo_factor1 = BigInt(factor1)
    var mojo_factor2 = BigInt(factor2)
    var mojo2_factor1 = BigInt2(factor1)
    var mojo2_factor2 = BigInt2(factor2)
    var py = Python.import_module("builtins")
    var py_factor1 = py.int(factor1)
    var py_factor2 = py.int(factor2)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_factor1 * mojo_factor2
        var mojo2_result = mojo2_factor1 * mojo2_factor2
        var py_result = py_factor1 * py_factor2

        # Display results for verification
        log_print("BigInt result:  " + String(mojo_result), log_file)
        log_print("BigInt2 result: " + String(mojo2_result), log_file)
        log_print("Python result:  " + String(py_result), log_file)

        # Benchmark BigInt implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_factor1 * mojo_factor2
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark BigInt2 implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo2_factor1 * mojo2_factor2
        var mojo2_time = (perf_counter_ns() - t0) / iterations
        if mojo2_time == 0:
            mojo2_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_factor1 * py_factor2
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factors (Python / Mojo)
        var speedup = Float64(python_time) / Float64(mojo_time)
        var speedup2 = Float64(python_time) / Float64(mojo2_time)
        speedup_factors.append(Float64(speedup))
        bigint2_speedup_factors.append(Float64(speedup2))

        # Print results with speedup comparison
        log_print(
            "BigInt multiply:  " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "BigInt2 multiply: " + String(mojo2_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python multiply:  " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigInt Multiplication Benchmark ===", log_file)
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
        "\nRunning multiplication benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC MULTIPLICATION TESTS ===

    # Case 1: Simple small positive multiplication
    run_benchmark_multiply(
        "Simple small positive multiplication",
        "123",
        "456",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 2: Simple small multiplication (negative × positive)
    run_benchmark_multiply(
        "Simple small multiplication (negative × positive)",
        "-123",
        "456",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 3: Simple small multiplication (positive × negative)
    run_benchmark_multiply(
        "Simple small multiplication (positive × negative)",
        "123",
        "-456",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 4: Simple small multiplication (negative × negative)
    run_benchmark_multiply(
        "Simple small multiplication (negative × negative)",
        "-123",
        "-456",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === MULTIPLICATION BY SPECIAL VALUES ===

    # Case 5: Multiplication by zero (positive)
    run_benchmark_multiply(
        "Multiplication by zero (positive)",
        "12345678",
        "0",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 6: Multiplication by zero (negative)
    run_benchmark_multiply(
        "Multiplication by zero (negative)",
        "-12345678",
        "0",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 7: Multiplication by one (positive)
    run_benchmark_multiply(
        "Multiplication by one (positive)",
        "9876543210",
        "1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 8: Multiplication by one (negative)
    run_benchmark_multiply(
        "Multiplication by one (negative)",
        "-9876543210",
        "1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 9: Multiplication by negative one (positive)
    run_benchmark_multiply(
        "Multiplication by negative one (positive)",
        "9876543210",
        "-1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 10: Multiplication by negative one (negative)
    run_benchmark_multiply(
        "Multiplication by negative one (negative)",
        "-9876543210",
        "-1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === MEDIUM-SIZED NUMBER MULTIPLICATION ===

    # Case 11: Medium number multiplication (positive × positive)
    run_benchmark_multiply(
        "Medium number multiplication (positive × positive)",
        "123456789",
        "987654321",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 12: Medium number multiplication (negative × positive)
    run_benchmark_multiply(
        "Medium number multiplication (negative × positive)",
        "-123456789",
        "987654321",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 13: Medium number multiplication (positive × negative)
    run_benchmark_multiply(
        "Medium number multiplication (positive × negative)",
        "123456789",
        "-987654321",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 14: Medium number multiplication (negative × negative)
    run_benchmark_multiply(
        "Medium number multiplication (negative × negative)",
        "-123456789",
        "-987654321",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === MULTIPLICATION BY POWERS OF 10 ===

    # Case 15: Multiplication by power of 10 (positive)
    run_benchmark_multiply(
        "Multiplication by power of 10 (positive)",
        "12345",
        "1000",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 16: Multiplication by power of 10 (negative × positive)
    run_benchmark_multiply(
        "Multiplication by power of 10 (negative × positive)",
        "-12345",
        "1000",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 17: Multiplication by power of 10 (positive × negative)
    run_benchmark_multiply(
        "Multiplication by power of 10 (positive × negative)",
        "12345",
        "-1000",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 18: Multiplication by power of 10 (large)
    run_benchmark_multiply(
        "Multiplication by power of 10 (large)",
        "12345678901234567890",
        "10000000000",  # 10^10
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === ASYMMETRIC MULTIPLICATION ===

    # Case 19: Asymmetric multiplication (very large × small)
    run_benchmark_multiply(
        "Asymmetric multiplication (very large × small)",
        "9" * 100,  # 100 nines
        "42",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 20: Asymmetric multiplication (small × very large)
    run_benchmark_multiply(
        "Asymmetric multiplication (small × very large)",
        "42",
        "9" * 100,  # 100 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 21: Asymmetric multiplication (medium × very large)
    run_benchmark_multiply(
        "Asymmetric multiplication (medium × very large)",
        "123456789",
        "9" * 50,  # 50 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 22: Asymmetric multiplication (very large × medium)
    run_benchmark_multiply(
        "Asymmetric multiplication (very large × medium)",
        "9" * 50,  # 50 nines
        "123456789",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === LARGE NUMBER MULTIPLICATION ===

    # Case 23: Large number multiplication (50 digits × 50 digits)
    run_benchmark_multiply(
        "Large number multiplication (50 digits × 50 digits)",
        "1" + "2" * 49,  # 50 digits
        "9" + "8" * 49,  # 50 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 24: Large number multiplication (negative 50 digits × 50 digits)
    run_benchmark_multiply(
        "Large number multiplication (negative 50 digits × 50 digits)",
        "-" + "1" + "2" * 49,  # 50 digits
        "9" + "8" * 49,  # 50 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 25: Large number multiplication (50 digits × negative 50 digits)
    run_benchmark_multiply(
        "Large number multiplication (50 digits × negative 50 digits)",
        "1" + "2" * 49,  # 50 digits
        "-" + "9" + "8" * 49,  # 50 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 26: Large number multiplication (negative 50 digits × negative 50 digits)
    run_benchmark_multiply(
        "Large number multiplication (negative 50 digits × negative 50 digits)",
        "-" + "1" + "2" * 49,  # 50 digits
        "-" + "9" + "8" * 49,  # 50 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === VERY LARGE NUMBER MULTIPLICATION ===

    # Case 27: Very large number multiplication (100 digits × 100 digits)
    run_benchmark_multiply(
        "Very large number multiplication (100 digits × 100 digits)",
        "1" + "2" * 99,  # 100 digits
        "9" + "8" * 99,  # 100 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 28: Very large number multiplication (negative 100 digits × 100 digits)
    run_benchmark_multiply(
        "Very large number multiplication (negative 100 digits × 100 digits)",
        "-" + "1" + "2" * 99,  # 100 digits
        "9" + "8" * 99,  # 100 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 29: Very large number multiplication (100 digits × negative 100 digits)
    run_benchmark_multiply(
        "Very large number multiplication (100 digits × negative 100 digits)",
        "1" + "2" * 99,  # 100 digits
        "-" + "9" + "8" * 99,  # 100 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 30: Very large number multiplication (negative 100 digits × negative 100 digits)
    run_benchmark_multiply(
        (
            "Very large number multiplication (negative 100 digits × negative"
            " 100 digits)"
        ),
        "-" + "1" + "2" * 99,  # 100 digits
        "-" + "9" + "8" * 99,  # 100 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === EXTREME LARGE NUMBER MULTIPLICATION ===

    # Case 31: Extreme large number multiplication (200 digits × 200 digits)
    run_benchmark_multiply(
        "Extreme large number multiplication (200 digits × 200 digits)",
        "1" + "2" * 199,  # 200 digits
        "9" + "8" * 199,  # 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 32: Extreme large number multiplication (400 digits × 400 digits)
    run_benchmark_multiply(
        "Extreme large number multiplication (400 digits × 400 digits)",
        "1" + "2" * 399,  # 400 digits
        "9" + "8" * 399,  # 400 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 33: Extreme large number multiplication (500 digits × 500 digits)
    run_benchmark_multiply(
        "Extreme large number multiplication (500 digits × 500 digits)",
        "7" + "3" * 499,  # 500 digits
        "5" + "2" * 499,  # 500 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === FIBONACCI NUMBER MULTIPLICATION ===

    # Case 34: Fibonacci number multiplication (medium)
    run_benchmark_multiply(
        "Fibonacci number multiplication (medium)",
        "6765",  # Fib(20)
        "4181",  # Fib(19)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 35: Fibonacci number multiplication (larger)
    run_benchmark_multiply(
        "Fibonacci number multiplication (larger)",
        "1597",  # Fib(17)
        "10946",  # Fib(21)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 36: Fibonacci number multiplication (negative)
    run_benchmark_multiply(
        "Fibonacci number multiplication (negative)",
        "-6765",  # -Fib(20)
        "4181",  # Fib(19)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === PRIME NUMBER MULTIPLICATION ===

    # Case 37: Prime number multiplication
    run_benchmark_multiply(
        "Prime number multiplication",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "997",  # Prime
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 38: Large prime number multiplication
    run_benchmark_multiply(
        "Large prime number multiplication",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "2305843009213693951",  # Mersenne prime (2^61 - 1)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === NEAR INTEGER LIMIT MULTIPLICATION ===

    # Case 39: Near Int64 limit multiplication
    run_benchmark_multiply(
        "Near Int64 limit multiplication",
        "9223372036854775807",  # Int64.MAX
        "2",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 40: Near negative Int64 limit multiplication
    run_benchmark_multiply(
        "Near negative Int64 limit multiplication",
        "-9223372036854775807",  # Near Int64.MIN
        "2",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === SPECIAL PATTERNS MULTIPLICATION ===

    # Case 41: Multiplication of repeated digits
    run_benchmark_multiply(
        "Multiplication of repeated digits",
        "9" * 30,  # 30 nines
        "9" * 30,  # 30 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 42: Multiplication of alternating digits
    run_benchmark_multiply(
        "Multiplication of alternating digits",
        "1010101010" * 8,  # Alternating 1s and 0s
        "9090909090" * 8,  # Alternating 9s and 0s
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 43: Multiplication of number near power of 10
    run_benchmark_multiply(
        "Multiplication of number near power of 10",
        "9" * 50 + "1",  # 10^50 - 9...9 + 1
        "9" * 40 + "1",  # 10^40 - 9...9 + 1
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === POWERS OF 2 MULTIPLICATION ===

    # Case 44: Powers of 2 multiplication (small)
    run_benchmark_multiply(
        "Powers of 2 multiplication (small)",
        "256",  # 2^8
        "128",  # 2^7
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 45: Powers of 2 multiplication (medium)
    run_benchmark_multiply(
        "Powers of 2 multiplication (medium)",
        "1" + "0" * 20,  # 10^20
        "256",  # 2^8
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 46: Powers of 2 multiplication (large)
    run_benchmark_multiply(
        "Powers of 2 multiplication (large)",
        "2" * 100,  # 100 twos
        "2" * 100,  # 100 twos
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === DECIMAL AND SCIENTIFIC NOTATIONS ===

    # Case 47: Decimal notation multiplication
    run_benchmark_multiply(
        "Decimal notation multiplication",
        "1" + "0" * 30,  # 10^30
        "1" + "0" * 20,  # 10^20
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 48: Scientific notation-like multiplication
    run_benchmark_multiply(
        "Scientific notation-like multiplication",
        "42" + "0" * 50,  # 42 * 10^50
        "17" + "0" * 30,  # 17 * 10^30
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === RANDOM-LIKE PATTERN MULTIPLICATION ===

    # Case 49: Random-like pattern multiplication (medium)
    run_benchmark_multiply(
        "Random-like pattern multiplication (medium)",
        "8675309123456789",
        "9876543210123456",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 50: Random-like pattern multiplication (large)
    run_benchmark_multiply(
        "Random-like pattern multiplication (large - 100 digits × 100 digits)",
        (  # First 100 digits of π
            "3141592653589793238462643383279502884197169399375105820974944592307"
            "816406286208998628034825342117067"
        ),
        (  # First 100 digits of e
            "2718281828459045235360287471352662497757247093699959574966967627724"
            "076630353547594571382178525166427"
        ),
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 51: Prime factor pattern multiplication
    run_benchmark_multiply(
        "Prime factor pattern multiplication",
        "2357111317" * 10,  # Pattern of primes
        "1931374143" * 10,  # Another pattern of primes
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === VERY LARGE PATTERN MULTIPLICATION ===

    # Case 52: Very large multiplication (300 digits × 300 digits)
    run_benchmark_multiply(
        "Very large multiplication (300 digits × 300 digits)",
        "3" + "1" * 299,  # 300 digits
        "7" + "9" * 299,  # 300 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 53: Very large multiplication with negative (300 digits × negative 300 digits)
    run_benchmark_multiply(
        (
            "Very large multiplication with negative (300 digits × negative 300"
            " digits)"
        ),
        "3" + "1" * 299,  # 300 digits
        "-" + "7" + "9" * 299,  # 300 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 54: Extreme large multiplication (600 digits × 600 digits)
    run_benchmark_multiply(
        "Extreme large multiplication (600 digits × 600 digits)",
        "123456789" * 67,  # 9*67 = ~600 digits
        "987654321" * 67,  # 9*67 = ~600 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 55: Extreme large asymmetric multiplication (600 digits × 300 digits)
    run_benchmark_multiply(
        "Extreme large asymmetric multiplication (600 digits × 300 digits)",
        "123456789" * 67,  # 9*67 = ~600 digits
        "987654321" * 34,  # 9*34 = ~300 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === SPECIAL INTEREST MULTIPLICATION ===

    # Case 56: Factorial-like multiplication
    run_benchmark_multiply(
        "Factorial-like multiplication",
        "3628800",  # 10!
        "39916800",  # 11!
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 57: Large factorial-like multiplication
    run_benchmark_multiply(
        "Large factorial-like multiplication",
        "51090942171709440000",  # 21!
        "1124000727777607680000",  # 22!
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 58: Square number calculation
    run_benchmark_multiply(
        "Square number calculation",
        "12345678901234567890",
        "12345678901234567890",  # Same number (squaring)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 59: Negative square calculation
    run_benchmark_multiply(
        "Negative square calculation",
        "-12345678901234567890",
        "-12345678901234567890",  # Same negative number
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 60: Extreme large square calculation (700 digits × 700 digits)
    run_benchmark_multiply(
        "Extreme large square calculation (700 digits × 700 digits)",
        "7" + "7" * 699,  # 700 digits
        "7" + "7" * 699,  # 700 digits
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
        log_print("\n=== BigInt Multiplication Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:              "
            + String(len(speedup_factors))
            + " different multiplication cases",
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
