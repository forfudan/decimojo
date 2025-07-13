"""
Comprehensive benchmarks for BigUInt sqrt operation.
Compares performance against Python's math.isqrt() with diverse test cases.
BigUInt is an unsigned integer type, so all test cases use positive numbers only.
"""

from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.exponential
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
    pysys.set_int_max_str_digits(10000000)

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate a timestamp for the filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/benchmark_biguint_sqrt_" + timestamp + ".log"

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


fn run_benchmark_sqrt(
    name: String,
    number: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigUInt sqrt with Python math.isqrt.

    Args:
        name: Name of the benchmark case.
        number: String representation of the number to take square root of.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Number:          " + number[:1024] + "...", log_file)

    # Set up Mojo and Python values
    var mojo_number = BigUInt(number)
    var py = Python.import_module("builtins")
    var math = Python.import_module("math")
    var py_number = py.int(number)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = decimojo.biguint.exponential.sqrt(mojo_number)
        var py_result = math.isqrt(py_number)

        if String(mojo_result) != String(py_result):
            log_print(
                "Error: Mojo and Python results do not match!",
                log_file,
            )
            log_print(
                "Mojo result:     "
                + String(mojo_result)[:1024]
                + String("..."),
                log_file,
            )
            log_print(
                "Python result:   " + String(py_result)[:1024] + String("..."),
                log_file,
            )
            return  # Skip this benchmark case if results don't match

        # Display results for verification
        log_print("Mojo result:     " + String(mojo_result)[:1024], log_file)
        log_print("Python result:   " + String(py_result)[:1024], log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = decimojo.biguint.exponential.sqrt(mojo_number)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = math.isqrt(py_number)
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = python_time / mojo_time
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo sqrt:       " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python isqrt:    " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigUInt Square Root Benchmark ===", log_file)
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
    var iterations_large_numbers = 10

    # Define benchmark cases (all positive numbers for BigUInt)
    log_print(
        "\nRunning square root benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Perfect squares - small numbers
    run_benchmark_sqrt(
        "Perfect square - small",
        "16",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Perfect squares - medium numbers
    run_benchmark_sqrt(
        "Perfect square - medium",
        "10000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Non-perfect square - small
    run_benchmark_sqrt(
        "Non-perfect square - small",
        "15",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Non-perfect square - medium
    run_benchmark_sqrt(
        "Non-perfect square - medium",
        "9999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Single digit
    run_benchmark_sqrt(
        "Single digit",
        "7",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Zero
    run_benchmark_sqrt(
        "Zero",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: One
    run_benchmark_sqrt(
        "One",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Large perfect square
    run_benchmark_sqrt(
        "Large perfect square",
        "1000000000000000000000000000000",  # 10^30
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Large non-perfect square
    run_benchmark_sqrt(
        "Large non-perfect square",
        "999999999999999999999999999999",  # 10^30 - 1
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Mersenne-like number
    run_benchmark_sqrt(
        "Mersenne-like number",
        "2147483647",  # 2^31 - 1
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Power of 2
    run_benchmark_sqrt(
        "Power of 2",
        "1048576",  # 2^20
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Factorial-like large number
    run_benchmark_sqrt(
        "Factorial-like large number",
        "1307674368000",  # 15!
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Near UInt64 MAX
    run_benchmark_sqrt(
        "Near UInt64 MAX",
        "18446744073709551615",  # UInt64.MAX
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Fibonacci number
    run_benchmark_sqrt(
        "Fibonacci number",
        "1134903170",  # Fib(45)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Repeated digits
    run_benchmark_sqrt(
        "Repeated digits",
        "777777777777777777777777777777",  # 30 sevens
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Powers of 10
    run_benchmark_sqrt(
        "Power of 10",
        "1" + "0" * 50,  # 10^50
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Almost perfect square
    run_benchmark_sqrt(
        "Almost perfect square",
        "9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",  # 100 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Prime-like large number
    run_benchmark_sqrt(
        "Prime-like large number",
        "1000000000000000000000000000057",  # Large number ending in prime
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Number with pattern
    run_benchmark_sqrt(
        "Number with pattern",
        "123456789123456789123456789123456789123456789123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Very large number - 100 digits
    run_benchmark_sqrt(
        "Very large number - 100 digits",
        "1" * 100,  # 100 ones
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Very large number - 200 digits
    run_benchmark_sqrt(
        "Very large number - 200 digits",
        "314159265358979323846264338327950288419716939937510" * 4,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Very large number - 500 digits
    run_benchmark_sqrt(
        "Very large number - 500 digits",
        "9" * 500,  # 500 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Extremely large number - 1000 digits
    run_benchmark_sqrt(
        "Extremely large number - 1000 digits",
        "123456789" * 111 + "123456",  # ~1000 digits
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Huge number - 2000 digits
    run_benchmark_sqrt(
        "Huge number - 2000 digits",
        "987654321" * 222 + "9876543",  # ~2000 digits
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Massive number - 5000 digits
    run_benchmark_sqrt(
        "Massive number - 5000 digits",
        "1234567890" * 500,  # 5000 digits
        iterations_large_numbers,
        log_file,
        speedup_factors,
    )

    # Case 26: Gigantic number - 10000 digits
    run_benchmark_sqrt(
        "Gigantic number - 10000 digits",
        "9876543210" * 1000,  # 10000 digits
        iterations_large_numbers,
        log_file,
        speedup_factors,
    )

    # Case 27: Mathematical constants - Pi digits
    run_benchmark_sqrt(
        "Mathematical constant - Pi approximation",
        "314159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Mathematical constants - e approximation
    run_benchmark_sqrt(
        "Mathematical constant - e approximation",
        "271828182845904523536028747135266249775724709369995957496696762772407663035354759457138217852516642742746639193200305992181741359662904357290033429526059563073813232862794349076323382988075319525101901",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Powers of small primes
    run_benchmark_sqrt(
        "Power of small prime",
        "3" + "0" * 100,  # 3 * 10^100
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Random large number
    run_benchmark_sqrt(
        "Random large number",
        "8675309192837465019283746501928374650192837465019283746501928374650192837465019283746501928374650192837465019283746501928374650192837465019283746501928374650192837465019283746501928374650",
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
        log_print("\n=== BigUInt Square Root Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different square root cases",
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
