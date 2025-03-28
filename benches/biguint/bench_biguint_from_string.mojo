"""
Comprehensive benchmarks for BigUInt from_string constructor.
Compares performance against Python's built-in int() constructor with 20 diverse test cases.
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
    var log_filename = log_dir + "/benchmark_biguint_from_string_" + timestamp + ".log"

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


fn run_benchmark_from_string(
    name: String,
    value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigUInt from_string constructor with Python int constructor.

    Args:
        name: Name of the benchmark case.
        value: String representation of the integer to parse.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("String value:    " + value, log_file)

    # Get Python's built-in module
    var py = Python.import_module("builtins")

    # Execute the operations once to verify correctness
    try:
        var mojo_result = BigUInt(value)
        var py_result = py.int(value)

        # Display results for verification
        log_print("Mojo parsed value:   " + String(mojo_result), log_file)
        log_print("Python parsed value: " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = BigUInt(value)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py.int(value)
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = python_time / mojo_time
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo from_string:   " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python int():       " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("Speedup factor:      " + String(speedup), log_file)
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
    log_print("=== DeciMojo BigUInt from_string Benchmark ===", log_file)
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
        "\nRunning from_string benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Small integer (1-3 digits)
    run_benchmark_from_string(
        "Small integer (1-3 digits)",
        "42",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Medium integer (10 digits)
    run_benchmark_from_string(
        "Medium integer (10 digits)",
        "1234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Large integer (50 digits)
    run_benchmark_from_string(
        "Large integer (50 digits)",
        "12345678901234567890123456789012345678901234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Very large integer (100 digits)
    run_benchmark_from_string(
        "Very large integer (100 digits)",
        "1" + "0" * 99,  # 10^99
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Power of 2 (100 digits)
    run_benchmark_from_string(
        "Power of 2 (2^256)",
        "115792089237316195423570985008687907853269984665640564039457584007913129639936",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Large number with repeating pattern
    run_benchmark_from_string(
        "Large number with repeating pattern (50 digits)",
        "12345" * 10,  # Pattern repeats 10 times
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Number with all 9s (stress test)
    run_benchmark_from_string(
        "Number with all 9s (100 digits)",
        "9" * 100,  # 100 nines
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Number with all 1s
    run_benchmark_from_string(
        "Number with all 1s (100 digits)",
        "1" * 100,  # 100 ones
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Number with alternating digits
    run_benchmark_from_string(
        "Number with alternating digits (100 digits)",
        "10" * 50,  # Alternating 1s and 0s
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Prime number
    run_benchmark_from_string(
        "Large prime number",
        "170141183460469231731687303715884105727",  # Mersenne prime 2^127 - 1
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Factorial value
    run_benchmark_from_string(
        "Factorial value (25! = ~25 digits)",
        "15511210043330985984000000",  # 25!
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: String with leading zeros
    run_benchmark_from_string(
        "String with leading zeros",
        "000123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Very large fibonacci number
    run_benchmark_from_string(
        "Large Fibonacci number (Fib(1000), ~209 digits)",
        "43466557686937456435688527675040625802564660517371780402481729089536555417949051890403879840079255169295922593080322634775209689623239873322471161642996440906533187938298969649928516003704476137795166849228875",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: String representation of a power of ten
    run_benchmark_from_string(
        "Power of ten (10^100)",
        "1" + "0" * 100,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: String representation of a number just below a power of ten
    run_benchmark_from_string(
        "Just below power of ten (10^50 - 1)",
        "1" + "0" * 49 + "0" * 49 + "9",  # 10^50 - 1
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Pi digits
    run_benchmark_from_string(
        "Pi digits (100 digits)",
        "31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Very large number (500 digits)
    run_benchmark_from_string(
        "Very large number (500 digits)",
        "1" + "0" * 499,  # 10^499
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Very large number with complex pattern
    run_benchmark_from_string(
        "Complex pattern (200 digits)",
        "123456789" * 22
        + "1234",  # 9 digits repeated 22 times + 4 extra digits
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Extremely large number (1000 digits)
    run_benchmark_from_string(
        "Extremely large number (1000 digits)",
        "1" + "0" * 999,  # 10^999
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Maximum UInt64 value
    run_benchmark_from_string(
        "Maximum UInt64 value",
        "18446744073709551615",  # 2^64 - 1
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
        log_print("\n=== BigUInt from_string Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different string parsing cases",
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
