"""
Comprehensive benchmarks for BigDecimal addition.
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
        log_dir + "/benchmark_bigdecimal_add_" + timestamp + ".log"
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


fn run_benchmark_add(
    name: String,
    value1: String,
    value2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal addition with Python Decimal addition.

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
    var mojo_value1 = BigDecimal(value1)
    var mojo_value2 = BigDecimal(value2)
    var pydecimal = Python.import_module("decimal")
    var py_value1 = pydecimal.Decimal(value1)
    var py_value2 = pydecimal.Decimal(value2)

    # Execute the operations once to verify correctness
    try:
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
        var speedup = python_time / mojo_time
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
    log_print("=== DeciMojo BigDecimal Addition Benchmark ===", log_file)
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
        "\nRunning decimal addition benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC DECIMAL ADDITION TESTS ===

    # Case 1: Simple integer addition
    run_benchmark_add(
        "Simple integer addition",
        "42",
        "58",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Simple decimal addition
    run_benchmark_add(
        "Simple decimal addition",
        "3.14",
        "2.71",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Addition with different scales (precision alignment)
    run_benchmark_add(
        "Addition with different scales",
        "1.2345",
        "5.67",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Addition with very different scales
    run_benchmark_add(
        "Addition with very different scales",
        "1.23456789012345678901234567",
        "5.6",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Addition with zero
    run_benchmark_add(
        "Addition with zero",
        "123.456",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCALE AND PRECISION TESTS ===

    # Case 6: Precision at decimal limit
    run_benchmark_add(
        "Precision at decimal limit",
        "1.2345678901234567890123456789",
        "9.8765432109876543210987654321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Addition causing scale reduction
    run_benchmark_add(
        "Addition causing scale reduction",
        "999999.999999",
        "0.000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Addition with high precision, repeating pattern
    run_benchmark_add(
        "Addition with high precision, repeating pattern",
        "0.33333333333333333333333333",
        "0.66666666666666666666666667",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Addition resulting in exact 1.0
    run_benchmark_add(
        "Addition resulting in exact 1.0",
        "0.33333333333333333333333333",
        "0.66666666666666666666666667",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Addition with scientific notation
    run_benchmark_add(
        "Addition with scientific notation",
        "1.23e5",
        "4.56e4",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SIGN COMBINATION TESTS ===

    # Case 11: Negative + Positive (negative smaller)
    run_benchmark_add(
        "Negative + Positive (negative smaller)",
        "-3.14",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Negative + Positive (negative larger)
    run_benchmark_add(
        "Negative + Positive (negative larger)",
        "-10",
        "3.14",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Negative + Negative
    run_benchmark_add(
        "Negative + Negative",
        "-5.75",
        "-10.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Addition resulting in zero (pos + neg)
    run_benchmark_add(
        "Addition resulting in zero (pos + neg)",
        "123.456",
        "-123.456",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Addition near zero (small difference)
    run_benchmark_add(
        "Addition near zero (small difference)",
        "0.0000001",
        "-0.00000005",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE NUMBER TESTS ===

    # Case 16: Large integer addition
    run_benchmark_add(
        "Large integer addition",
        "9999999999999999999999999999",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Large negative + positive
    run_benchmark_add(
        "Large negative + positive",
        "-9999999999999999999999999999",
        "9999999999999999999999999998",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Very large decimal addition
    run_benchmark_add(
        "Very large decimal addition",
        "9" * 20 + "." + "9" * 8,
        "1" + "0" * 19 + "." + "0" * 7 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Very large + very small
    run_benchmark_add(
        "Very large + very small",
        "1" + "0" * 25,
        "0." + "0" * 25 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Extreme scales (large positive exponent)
    run_benchmark_add(
        "Extreme scales (large positive exponent)",
        "1.23e20",
        "4.56e19",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SMALL NUMBER TESTS ===

    # Case 21: Very small positive values
    run_benchmark_add(
        "Very small positive values",
        "0." + "0" * 25 + "1",
        "0." + "0" * 25 + "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Very small negative values
    run_benchmark_add(
        "Very small negative values",
        "-0." + "0" * 25 + "1",
        "-0." + "0" * 25 + "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Small values with different scales
    run_benchmark_add(
        "Small values with different scales",
        "0." + "0" * 10 + "1",
        "0." + "0" * 20 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Extreme scales (large negative exponent)
    run_benchmark_add(
        "Extreme scales (large negative exponent)",
        "1.23e-15",
        "4.56e-20",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Addition that requires significant rescaling
    run_benchmark_add(
        "Addition that requires significant rescaling",
        "1.23e-10",
        "4.56e10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUE TESTS ===

    # Case 26: Addition of exact mathematical constants
    run_benchmark_add(
        "Addition of exact mathematical constants (PI + E)",
        "3.14159265358979323846264338328",
        "2.71828182845904523536028747135",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Addition of famous constants (Phi + sqrt(2))
    run_benchmark_add(
        "Addition of famous constants (Phi + sqrt(2))",
        "1.61803398874989484820458683437",
        "1.41421356237309504880168872421",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Addition with repeating patterns
    run_benchmark_add(
        "Addition with repeating patterns",
        "1.23451234512345123451234512345",
        "5.67896789567895678956789567896",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Financial numbers (dollars and cents)
    run_benchmark_add(
        "Financial numbers (dollars and cents)",
        "10542.75",
        "3621.50",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Statistical data (means)
    run_benchmark_add(
        "Statistical data (means)",
        "98.76543",
        "87.65432",
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRECISION TESTS ===

    # Case 31: Binary-friendly decimals
    run_benchmark_add(
        "Binary-friendly decimals",
        "0.5",
        "0.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Decimal-unfriendly fractions
    run_benchmark_add(
        "Decimal-unfriendly fractions",
        "0.33333333333333333333333333",
        "0.33333333333333333333333333",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: Addition with many carries
    run_benchmark_add(
        "Addition with many carries",
        "9.99999999999999999999999999",
        "0.00000000000000000000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Addition with trailing zeros
    run_benchmark_add(
        "Addition with trailing zeros",
        "1.1000000000000000000000000",
        "2.2000000000000000000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Addition requiring precision increase
    run_benchmark_add(
        "Addition requiring precision increase",
        "999999999999999999.9999999",
        "0.0000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # === APPLICATION-SPECIFIC TESTS ===

    # Case 36: Scientific measurement (physics)
    run_benchmark_add(
        "Scientific measurement (physics)",
        "299792458.0",  # Speed of light in m/s
        "0.000000000000000000160217663",  # Planck constant in Js
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 37: Astronomical distances
    run_benchmark_add(
        "Astronomical distances",
        "1.496e11",  # Earth-Sun distance in meters
        "3.844e8",  # Earth-Moon distance in meters
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 38: Chemical concentrations
    run_benchmark_add(
        "Chemical concentrations",
        "0.00001234",  # mol/L
        "0.00005678",  # mol/L
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 39: Financial market prices
    run_benchmark_add(
        "Financial market prices",
        "3914.75",  # Stock price
        "0.05",  # Price change
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: Interest rate calculations
    run_benchmark_add(
        "Interest rate calculations",
        "0.0425",  # 4.25% interest rate
        "0.0015",  # 0.15% increase
        iterations,
        log_file,
        speedup_factors,
    )

    # === EDGE CASES AND EXTREME VALUES ===

    # Case 41: Addition with maximum precision
    run_benchmark_add(
        "Addition with maximum precision",
        "0." + "1" * 28,
        "0." + "9" * 28,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 42: Addition with extreme exponents difference
    run_benchmark_add(
        "Addition with extreme exponents difference",
        "1e20",
        "1e-20",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 43: Addition at precision boundary
    run_benchmark_add(
        "Addition at precision boundary",
        "9" * 28 + "." + "9" * 28,
        "0." + "0" * 27 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: Addition of exact fractions
    run_benchmark_add(
        "Addition of exact fractions",
        "0.125",  # 1/8
        "0.0625",  # 1/16
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 45: Addition of recurring decimals
    run_benchmark_add(
        "Addition of recurring decimals",
        "0.142857142857142857142857",  # 1/7
        "0.076923076923076923076923",  # 1/13
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRACTICAL APPLICATION TESTS ===

    # Case 46: GPS coordinates addition
    run_benchmark_add(
        "GPS coordinates addition",
        "37.7749",  # San Francisco latitude
        "0.0001",  # Small delta
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: Temperature conversion factors
    run_benchmark_add(
        "Temperature conversion factors",
        "273.15",  # Kelvin offset
        "32.0",  # Fahrenheit offset
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 48: Transaction amounts addition
    run_benchmark_add(
        "Transaction amounts addition",
        "156.78",  # First transaction
        "243.22",  # Second transaction
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: Addition across wide range of magnitudes
    run_benchmark_add(
        "Addition across wide range of magnitudes",
        "987654321987654321.987654321",
        "0.000000000000000000000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: Equal but opposite values
    run_benchmark_add(
        "Equal but opposite values",
        "12345678901234567890.1234567890",
        "-12345678901234567890.1234567890",
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
        log_print("\n=== BigDecimal Addition Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different addition cases",
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
