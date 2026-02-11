"""
Comprehensive benchmarks for BigUInt addition.
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
    var pysys = Python.import_module("sys")
    pysys.set_int_max_str_digits(1000000)

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/benchmark_biguint_add_" + timestamp + ".log"

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
) raises:
    """
    Run a benchmark comparing Mojo BigUInt addition with Python int addition.

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
    var mojo_result = mojo_value1 + mojo_value2
    var py_result = py_value1 + py_value2

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = mojo_value1 + mojo_value2
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_value1 + py_value2
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = Float64(python_time) / Float64(mojo_time)
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo addition:   " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python addition: " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigUInt Addition Benchmark ===", log_file)
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
    )

    # Case 2: Medium integer addition
    run_benchmark_add(
        "Medium integer addition",
        "12345",
        "67890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Large integer addition
    run_benchmark_add(
        "Large integer addition",
        "9999999999",  # 10 billion
        "1234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Very large integer addition
    run_benchmark_add(
        "Very large integer addition",
        "9" * 50,  # 50-digit number
        "1" + "0" * 49,  # 10^49
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Addition with zero
    run_benchmark_add(
        "Addition with zero",
        "123456789",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Zero with addition
    run_benchmark_add(
        "Zero with addition",
        "0",
        "987654321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Power-of-10 addition
    run_benchmark_add(
        "Power-of-10 addition",
        "1" + "0" * 20,  # 10^20
        "1" + "0" * 15,  # 10^15
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Fibonacci numbers addition
    run_benchmark_add(
        "Fibonacci numbers addition",
        "10946",  # Fib(21)
        "17711",  # Fib(22)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Extreme large integer addition
    run_benchmark_add(
        "Extreme large integer addition",
        "9" * 100,  # 100-digit number
        "1" + "0" * 99,  # 10^99
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Addition with uneven length numbers
    run_benchmark_add(
        "Addition with uneven length numbers",
        "1" + "0" * 30,  # 10^30
        "9" * 10,  # 10-digit number
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Addition with uneven length numbers (reversed)
    run_benchmark_add(
        "Addition with uneven length numbers (reversed)",
        "9" * 10,  # 10-digit number
        "1" + "0" * 30,  # 10^30
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Addition with many carries
    run_benchmark_add(
        "Addition with many carries",
        "9" * 25,  # 25 nines
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Prime number addition
    run_benchmark_add(
        "Prime number addition",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "2305843009213693951",  # Mersenne prime (2^61 - 1)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Addition of numbers near UInt32 limit
    run_benchmark_add(
        "Addition near UInt32 limit",
        "4294967295",  # UInt32.MAX
        "4294967295",  # UInt32.MAX
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Addition of numbers near UInt64 limit
    run_benchmark_add(
        "Addition near UInt64 limit",
        "18446744073709551615",  # UInt64.MAX
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Addition of repeated digits
    run_benchmark_add(
        "Addition of repeated digits",
        "1" * 40,  # 40 ones
        "9" * 40,  # 40 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Addition of powers of two
    run_benchmark_add(
        "Addition of powers of two",
        "340282366920938463463374607431768211456",  # 2^128
        "115792089237316195423570985008687907853269984665640564039457584007913129639936",  # 2^256
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Addition with exact base-10^9 boundary
    run_benchmark_add(
        "Addition at base-10^9 boundary",
        "999999999",  # Base-10^9 max - 1
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Addition with consecutive 9's
    run_benchmark_add(
        "Addition with consecutive 9's",
        "9" * 200,  # 200 nines
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Addition of numbers with all digits the same
    run_benchmark_add(
        "Addition of numbers with all digits the same",
        "8" * 50,  # 50 eights
        "8" * 50,  # 50 eights
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Addition of numbers with complementary patterns
    run_benchmark_add(
        "Addition of complementary patterns",
        "123456789" * 10,  # Repeated pattern
        "987654321" * 10,  # Inverted pattern
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Addition of very different magnitudes
    run_benchmark_add(
        "Addition of very different magnitudes",
        "1" + "0" * 500,  # 10^500
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Addition of two very large numbers
    run_benchmark_add(
        "Addition of two very large numbers",
        "9" * 1000,  # 1000-digit number
        "9" * 1000,  # 1000-digit number
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Addition of sparse numbers (many zeros)
    run_benchmark_add(
        "Addition of sparse numbers",
        "1" + "0" * 100 + "1" + "0" * 100 + "1",
        "1" + "0" * 200 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Addition at word boundaries
    run_benchmark_add(
        "Addition at word boundaries",
        "999999999" + "0" * 18,  # 10^9-1 followed by 18 zeros
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: Addition of repeating number patterns
    run_benchmark_add(
        "Addition of repeating number patterns",
        "123456789" * 30,  # Repeating pattern
        "123456789" * 30,  # Repeating pattern
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Addition of factorial numbers
    run_benchmark_add(
        "Addition of factorial numbers",
        "2432902008176640000",  # 20!
        "6402373705728000",  # 18!
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Addition of exponential growth numbers
    run_benchmark_add(
        "Addition of exponential growth numbers",
        "2" * 100,  # 100 twos
        "3" * 120,  # 120 threes
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Addition with perfect powers
    run_benchmark_add(
        "Addition of perfect powers",
        "10000000000000000000000000000000000000000",  # 10^40
        "8589934592",  # 2^33
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Addition with cryptographic numbers
    run_benchmark_add(
        "Addition with cryptographic numbers",
        "115792089237316195423570985008687907853269984665640564039457584007908834671663",  # ECDSA curve order for secp256k1
        "115792089237316195423570985008687907852837564279074904382605163141518161494337",  # secp256k1 field size
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: Addition with 64 words + 32 words
    run_benchmark_add(
        "Addition with 64 words + 32 words",
        "123456789" * 64,
        "987654321" * 32,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Addition with 256 words + 128 words
    run_benchmark_add(
        "Addition with 256 words + 128 words",
        "123456789" * 256,
        "987654321" * 128,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: Addition with 1024 words + 512 words
    run_benchmark_add(
        "Addition with 1024 words + 512 words",
        "123456789" * 1024,
        "987654321" * 512,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Addition with 4096 words + 2048 words
    run_benchmark_add(
        "Addition with 4096 words + 2048 words",
        "123456789" * 4096,
        "987654321" * 2048,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Addition with 16384 words + 8192 words
    run_benchmark_add(
        "Addition with 16384 words + 8192 words",
        "123456789" * 16384,
        "987654321" * 8192,
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
    log_print("\n=== BigUInt Addition Benchmark Summary ===", log_file)
    log_print("Benchmarked:      30 different addition cases", log_file)
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
