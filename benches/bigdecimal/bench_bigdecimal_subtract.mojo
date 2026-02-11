"""
Comprehensive benchmarks for BigDecimal subtraction.
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
    var log_filename = (
        log_dir + "/benchmark_bigdecimal_subtract_" + timestamp + ".log"
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


fn run_benchmark_subtract(
    name: String,
    value1: String,
    value2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal subtraction with Python Decimal subtraction.

    Args:
        name: Name of the benchmark case.
        value1: String representation of minuend (value to subtract from).
        value2: String representation of subtrahend (value to subtract).
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Minuend:        " + value1, log_file)
    log_print("Subtrahend:     " + value2, log_file)

    # Set up Mojo and Python values
    var mojo_value1 = BigDecimal(value1)
    var mojo_value2 = BigDecimal(value2)
    var pydecimal = Python.import_module("decimal")
    var py_value1 = pydecimal.Decimal(value1)
    var py_value2 = pydecimal.Decimal(value2)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_value1 - mojo_value2
        var py_result = py_value1 - py_value2

        # Display results for verification
        log_print("Mojo result:     " + String(mojo_result), log_file)
        log_print("Python result:   " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_value1 - mojo_value2
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value1 - py_value2
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo subtraction:   " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python subtraction: " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigDecimal Subtraction Benchmark ===", log_file)
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
        "\nRunning decimal subtraction benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC DECIMAL SUBTRACTION TESTS ===

    # Case 1: Simple integer subtraction
    run_benchmark_subtract(
        "Simple integer subtraction",
        "100",
        "42",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Simple decimal subtraction
    run_benchmark_subtract(
        "Simple decimal subtraction",
        "5.85",
        "2.71",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Subtraction with different scales (precision alignment)
    run_benchmark_subtract(
        "Subtraction with different scales",
        "10.2345",
        "5.67",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Subtraction with very different scales
    run_benchmark_subtract(
        "Subtraction with very different scales",
        "5.23456789012345678901234567",
        "1.6",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Subtraction with zero
    run_benchmark_subtract(
        "Subtraction with zero (a - 0)",
        "123.456",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCALE AND PRECISION TESTS ===

    # Case 6: Precision at decimal limit
    run_benchmark_subtract(
        "Precision at decimal limit",
        "9.8765432109876543210987654321",
        "1.2345678901234567890123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Subtraction causing scale reduction
    run_benchmark_subtract(
        "Subtraction causing scale reduction",
        "1000000.000000",
        "0.000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Subtraction with high precision, repeating pattern
    run_benchmark_subtract(
        "Subtraction with high precision, repeating pattern",
        "1.00000000000000000000000000",
        "0.33333333333333333333333333",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Subtraction resulting in exact 0.0
    run_benchmark_subtract(
        "Subtraction resulting in exact 0.0",
        "0.33333333333333333333333333",
        "0.33333333333333333333333333",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Subtraction with scientific notation
    run_benchmark_subtract(
        "Subtraction with scientific notation",
        "1.23e5",
        "4.56e4",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SIGN COMBINATION TESTS ===

    # Case 11: Positive - Negative (becomes addition)
    run_benchmark_subtract(
        "Positive - Negative (becomes addition)",
        "10",
        "-3.14",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Negative - Positive (becomes addition with sign change)
    run_benchmark_subtract(
        "Negative - Positive (becomes addition with sign change)",
        "-10",
        "3.14",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Negative - Negative
    run_benchmark_subtract(
        "Negative - Negative",
        "-5.75",
        "-10.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Subtraction resulting in sign change
    run_benchmark_subtract(
        "Subtraction resulting in sign change",
        "50",
        "60.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Subtraction near zero (small difference)
    run_benchmark_subtract(
        "Subtraction near zero (small difference)",
        "0.0000001",
        "0.00000005",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE NUMBER TESTS ===

    # Case 16: Large integer subtraction
    run_benchmark_subtract(
        "Large integer subtraction",
        "10000000000000000000000000000",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Large negative - positive
    run_benchmark_subtract(
        "Large negative - positive",
        "-9999999999999999999999999999",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Very large decimal subtraction with borrow
    run_benchmark_subtract(
        "Very large decimal subtraction with borrow",
        "100000000000000000000.00000000",
        "0.00000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Very large - very small
    run_benchmark_subtract(
        "Very large - very small",
        "1" + "0" * 25,
        "0." + "0" * 25 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Extreme scales (large positive exponent)
    run_benchmark_subtract(
        "Extreme scales (large positive exponent)",
        "1.23e20",
        "4.56e19",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SMALL NUMBER TESTS ===

    # Case 21: Very small positive values
    run_benchmark_subtract(
        "Very small positive values",
        "0." + "0" * 25 + "3",
        "0." + "0" * 25 + "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Very small negative values
    run_benchmark_subtract(
        "Very small negative values",
        "-0." + "0" * 25 + "3",
        "-0." + "0" * 25 + "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Small values with different scales
    run_benchmark_subtract(
        "Small values with different scales",
        "0." + "0" * 10 + "3",
        "0." + "0" * 20 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Extreme scales (large negative exponent)
    run_benchmark_subtract(
        "Extreme scales (large negative exponent)",
        "1.23e-15",
        "4.56e-20",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Subtraction that requires significant rescaling
    run_benchmark_subtract(
        "Subtraction that requires significant rescaling",
        "4.56e10",
        "1.23e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUE TESTS ===

    # Case 26: Subtraction of exact mathematical constants
    run_benchmark_subtract(
        "Subtraction of exact mathematical constants (PI - E)",
        "3.14159265358979323846264338328",
        "2.71828182845904523536028747135",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Subtraction of famous constants (Phi - sqrt(2))
    run_benchmark_subtract(
        "Subtraction of famous constants (Phi - sqrt(2))",
        "1.61803398874989484820458683437",
        "1.41421356237309504880168872421",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Subtraction with repeating patterns
    run_benchmark_subtract(
        "Subtraction with repeating patterns",
        "5.67896789567895678956789567896",
        "1.23451234512345123451234512345",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Financial numbers (dollars and cents)
    run_benchmark_subtract(
        "Financial numbers (dollars and cents)",
        "10542.75",
        "3621.50",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Statistical data (deviations)
    run_benchmark_subtract(
        "Statistical data (deviations)",
        "98.76543",
        "87.65432",
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRECISION TESTS ===

    # Case 31: Binary-friendly decimals
    run_benchmark_subtract(
        "Binary-friendly decimals",
        "0.5",
        "0.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Decimal-unfriendly fractions
    run_benchmark_subtract(
        "Decimal-unfriendly fractions",
        "0.66666666666666666666666666",
        "0.33333333333333333333333333",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: Subtraction with many borrows
    run_benchmark_subtract(
        "Subtraction with many borrows",
        "10.00000000000000000000000000",
        "9.99999999999999999999999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Subtraction with trailing zeros
    run_benchmark_subtract(
        "Subtraction with trailing zeros",
        "3.3000000000000000000000000",
        "2.2000000000000000000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Subtraction requiring precision increase
    run_benchmark_subtract(
        "Subtraction requiring precision increase",
        "1000000000000000000.0000000",
        "0.0000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # === APPLICATION-SPECIFIC TESTS ===

    # Case 36: Scientific measurement (physics)
    run_benchmark_subtract(
        "Scientific measurement (physics)",
        "299792458.0",  # Speed of light in m/s
        "0.000000000000000000160217663",  # Planck constant in Js
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 37: Astronomical distances
    run_benchmark_subtract(
        "Astronomical distances",
        "1.496e11",  # Earth-Sun distance in meters
        "3.844e8",  # Earth-Moon distance in meters
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 38: Chemical concentrations
    run_benchmark_subtract(
        "Chemical concentrations",
        "0.00005678",  # mol/L
        "0.00001234",  # mol/L
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 39: Financial market price changes
    run_benchmark_subtract(
        "Financial market price changes",
        "3914.75",  # Current price
        "3914.70",  # Previous price
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: Interest rate calculations
    run_benchmark_subtract(
        "Interest rate calculations",
        "0.0440",  # 4.40% interest rate
        "0.0015",  # 0.15% decrease
        iterations,
        log_file,
        speedup_factors,
    )

    # === EDGE CASES AND EXTREME VALUES ===

    # Case 41: Subtraction with maximum precision
    run_benchmark_subtract(
        "Subtraction with maximum precision",
        "1." + "0" * 28,
        "0." + "9" * 28,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 42: Subtraction with extreme exponents difference
    run_benchmark_subtract(
        "Subtraction with extreme exponents difference",
        "1e20",
        "1e-20",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 43: Subtraction at precision boundary
    run_benchmark_subtract(
        "Subtraction at precision boundary",
        "9" * 28 + "." + "9" * 28,
        "0." + "0" * 27 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: Subtraction of exact fractions
    run_benchmark_subtract(
        "Subtraction of exact fractions",
        "0.125",  # 1/8
        "0.0625",  # 1/16
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 45: Subtraction of recurring decimals
    run_benchmark_subtract(
        "Subtraction of recurring decimals",
        "0.142857142857142857142857",  # 1/7
        "0.076923076923076923076923",  # 1/13
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRACTICAL APPLICATION TESTS ===

    # Case 46: GPS coordinates subtraction
    run_benchmark_subtract(
        "GPS coordinates subtraction",
        "37.7749",  # Current latitude
        "37.7748",  # Previous latitude
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: Temperature difference calculation
    run_benchmark_subtract(
        "Temperature difference calculation",
        "98.6",  # Fahrenheit temperature
        "37.0",  # Celsius equivalent
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 48: Bank balance calculation
    run_benchmark_subtract(
        "Bank balance calculation",
        "1000.50",  # Initial balance
        "243.22",  # Withdrawal
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: Subtraction across wide range of magnitudes
    run_benchmark_subtract(
        "Subtraction across wide range of magnitudes",
        "987654321987654321.987654321",
        "0.000000000000000000000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: Subtraction resulting in negative zero
    run_benchmark_subtract(
        "Subtraction resulting in negative zero",
        "0.0",
        "0.0",
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
            "\n=== BigDecimal Subtraction Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different subtraction cases",
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
