"""
Comprehensive benchmarks for BigUInt multiplication.
Compares performance against Python's built-in int with 30 diverse test cases.
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
    var log_filename = log_dir + "/benchmark_biguint_multiply_" + timestamp + ".log"

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
    value1: String,
    value2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigUInt multiplication with Python int multiplication.

    Args:
        name: Name of the benchmark case.
        value1: String representation of first operand.
        value2: String representation of second operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("First operand:   " + value1, log_file)
    log_print("Second operand:  " + value2, log_file)

    # Set up Mojo and Python values
    var mojo_value1 = BigUInt(value1)
    var mojo_value2 = BigUInt(value2)
    var py = Python.import_module("builtins")
    var py_value1 = py.int(value1)
    var py_value2 = py.int(value2)

    # Execute the operations once to verify correctness
    var mojo_result = mojo_value1 * mojo_value2
    var py_result = py_value1 * py_value2

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = mojo_value1 * mojo_value2
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_value1 * py_value2
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo multiplication:   " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python multiplication: " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigUInt Multiplication Benchmark ===", log_file)
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

    # Use fewer iterations for multiplication as it's more compute-intensive
    var iterations = 100

    # Define benchmark cases
    log_print(
        "\nRunning multiplication benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Small integer multiplication
    run_benchmark_multiply(
        "Small integer multiplication",
        "42",
        "58",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Medium integer multiplication
    run_benchmark_multiply(
        "Medium integer multiplication",
        "12345",
        "67890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Multiplication by zero
    run_benchmark_multiply(
        "Multiplication by zero",
        "9876543210",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Multiplication by one
    run_benchmark_multiply(
        "Multiplication by one",
        "9876543210",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Powers of ten (10^5 * 10^5)
    run_benchmark_multiply(
        "Powers of ten (10^5 * 10^5)",
        "100000",
        "100000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Medium-large multiplication
    run_benchmark_multiply(
        "Medium-large multiplication",
        "9999999999",  # 10 digits
        "8888888888",  # 10 digits
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Large base multiplication
    run_benchmark_multiply(
        "Large base multiplication",
        "999999999",  # Largest base-10^9 digit
        "999999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Fibonacci numbers multiplication
    run_benchmark_multiply(
        "Fibonacci numbers multiplication",
        "10946",  # Fib(21)
        "17711",  # Fib(22)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Prime numbers multiplication
    run_benchmark_multiply(
        "Prime numbers multiplication",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "2305843009213693951",  # Mersenne prime (2^61 - 1)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Square of a large number
    run_benchmark_multiply(
        "Square of a large number",
        "123456789012345",
        "123456789012345",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Power-of-2 numbers
    run_benchmark_multiply(
        "Power-of-2 numbers",
        "4294967296",  # 2^32
        "4294967296",  # 2^32
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Large * Small
    run_benchmark_multiply(
        "Large * Small",
        "9" * 50,  # 50-digit number
        "9",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Decimal shift multiplication (multiple of 10)
    run_benchmark_multiply(
        "Decimal shift multiplication",
        "12345",
        "10000",  # 10^4
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Near word boundary
    run_benchmark_multiply(
        "Near word boundary multiplication",
        "999999998",
        "999999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Cross word boundary
    run_benchmark_multiply(
        "Cross word boundary multiplication",
        "999999999",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Factorial-like numbers
    run_benchmark_multiply(
        "Factorial-like numbers",
        "3628800",  # 10!
        "479001600",  # 12!
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Multiplication with repeating digits
    run_benchmark_multiply(
        "Multiplication with repeating digits",
        "9" * 20,  # 20 nines
        "9" * 20,  # 20 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Uneven length multiplication (10:1 ratio)
    run_benchmark_multiply(
        "Uneven length multiplication",
        "1" * 50,  # 50 ones
        "1" * 5,  # 5 ones
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Cryptographic size numbers
    run_benchmark_multiply(
        "Cryptographic size numbers",
        "115792089237316195423570985008687907853269984665640564039457584007908834671663",  # ECDSA curve order for secp256k1
        "65537",  # Common RSA exponent
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Karatsuba algorithm threshold test
    run_benchmark_multiply(
        "Karatsuba threshold test",
        "1" * 25,  # 25-digit number
        "9" * 25,  # 25-digit number
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Large product resulting in carries
    run_benchmark_multiply(
        "Large product with carries",
        "9" * 30,  # 30 nines
        "9" * 30,  # 30 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Very large number * small number
    run_benchmark_multiply(
        "Very large number * small number",
        "1" + "0" * 100,  # 10^100
        "42",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Very large numbers multiplication
    run_benchmark_multiply(
        "Very large numbers multiplication",
        "9" * 100,  # 100 nines
        "9" * 100,  # 100 nines
        iterations // 2,  # Reduce iterations for very large numbers
        log_file,
        speedup_factors,
    )

    # Case 24: BigUInt with exact number of words
    run_benchmark_multiply(
        "Exact word-sized multiplication",
        "9" * 9,  # 9 nines - exactly one word
        "9" * 9,  # 9 nines - exactly one word
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Binary-like values (powers of 2)
    run_benchmark_multiply(
        "Binary-like values",
        "2" * 40,  # 40 twos
        "2" * 40,  # 40 twos
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: Perfect squares
    run_benchmark_multiply(
        "Perfect square calculation",
        "12345678901234567890",
        "12345678901234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Product near UInt32.MAX
    run_benchmark_multiply(
        "Product near UInt32 limit",
        "65535",  # 2^16 - 1
        "65537",  # 2^16 + 1
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Product of different bases
    run_benchmark_multiply(
        "Product of different bases",
        "1" + "0" * 40,  # 10^40
        "16" + "0" * 20,  # 16 * 10^20
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Common mathematical constants
    run_benchmark_multiply(
        "Mathematical constants product",
        "31415926535897932384626433832795",  # π * 10^30
        "27182818284590452353602874713527",  # e * 10^30
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Extreme large numbers multiplication
    run_benchmark_multiply(
        "Extreme large numbers multiplication (1800 digits * 1800 digits)",
        "123456789" * 200,  # 1800 digits
        "987654321" * 200,  # 1800 digits
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
    log_print("\n=== BigUInt Multiplication Benchmark Summary ===", log_file)
    log_print("Benchmarked:      30 different multiplication cases", log_file)
    log_print(
        "Each case ran:    "
        + String(iterations)
        + " iterations (reduced for large numbers)",
        log_file,
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
