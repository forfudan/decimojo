"""
Comprehensive benchmarks for BigDecimal multiplication.
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
        log_dir + "/benchmark_bigdecimal_multiply_" + timestamp + ".log"
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
    value1: String,
    value2: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal multiplication with Python Decimal multiplication.

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
        var mojo_result = mojo_value1 * mojo_value2
        var py_result = py_value1 * py_value2

        # Display results for verification
        log_print("Mojo result:       " + String(mojo_result), log_file)
        log_print("Python result:     " + String(py_result), log_file)

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
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo multiplication:   " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python multiplication: "
            + String(python_time)
            + " ns per iteration",
            log_file,
        )
        log_print("Speedup factor:        " + String(speedup), log_file)
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
    log_print("=== DeciMojo BigDecimal Multiplication Benchmark ===", log_file)
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

    var iterations = 500  # Fewer iterations for multiplication (may be slower)
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
        "\nRunning decimal multiplication benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC DECIMAL MULTIPLICATION TESTS ===

    # Case 1: Simple integer multiplication
    run_benchmark_multiply(
        "Simple integer multiplication",
        "7",
        "6",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Simple decimal multiplication
    run_benchmark_multiply(
        "Simple decimal multiplication",
        "3.5",
        "2.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Multiplication with different scales
    run_benchmark_multiply(
        "Multiplication with different scales",
        "1.5",
        "0.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Multiplication with very different scales
    run_benchmark_multiply(
        "Multiplication with very different scales",
        "1.23456789",
        "0.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Multiplication by zero
    run_benchmark_multiply(
        "Multiplication by zero",
        "123.456",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Multiplication by one
    run_benchmark_multiply(
        "Multiplication by one",
        "123.456",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Multiplication by negative one
    run_benchmark_multiply(
        "Multiplication by negative one",
        "123.456",
        "-1",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCALE AND PRECISION TESTS ===

    # Case 8: Precision at decimal limit
    run_benchmark_multiply(
        "Precision at decimal limit",
        "1.2345678901234567890123456789",
        "9.8765432109876543210987654321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Multiplication resulting in scale increase
    run_benchmark_multiply(
        "Multiplication resulting in scale increase",
        "123.456789",
        "987.654321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Multiplication with high precision
    run_benchmark_multiply(
        "Multiplication with high precision",
        "0.33333333333333333333333333",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Multiplication resulting in exact integer
    run_benchmark_multiply(
        "Multiplication resulting in exact integer",
        "0.5",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Multiplication with scientific notation
    run_benchmark_multiply(
        "Multiplication with scientific notation",
        "1.23e5",
        "4.56e2",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SIGN COMBINATION TESTS ===

    # Case 13: Negative * Positive
    run_benchmark_multiply(
        "Negative * Positive",
        "-3.14",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Positive * Negative
    run_benchmark_multiply(
        "Positive * Negative",
        "10",
        "-3.14",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Negative * Negative
    run_benchmark_multiply(
        "Negative * Negative",
        "-5.75",
        "-10.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Zero * Negative
    run_benchmark_multiply(
        "Zero * Negative",
        "0",
        "-123.456",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Negative * Zero
    run_benchmark_multiply(
        "Negative * Zero",
        "-123.456",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE NUMBER TESTS ===

    # Case 18: Large integer multiplication
    run_benchmark_multiply(
        "Large integer multiplication",
        "9999999",
        "9999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Large negative * positive
    run_benchmark_multiply(
        "Large negative * positive",
        "-9999999999",
        "1234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Large decimal multiplication
    run_benchmark_multiply(
        "Large decimal multiplication",
        "12345.6789",
        "98765.4321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Very large * very small
    run_benchmark_multiply(
        "Very large * very small",
        "1" + "0" * 20,  # 10^20
        "0." + "0" * 20 + "1",  # 10^-21
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Extreme scales (large positive exponents)
    run_benchmark_multiply(
        "Extreme scales (large positive exponents)",
        "1.23e10",
        "4.56e10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SMALL NUMBER TESTS ===

    # Case 23: Very small positive values
    run_benchmark_multiply(
        "Very small positive values",
        "0." + "0" * 15 + "1",
        "0." + "0" * 15 + "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Very small negative values
    run_benchmark_multiply(
        "Very small negative values",
        "-0." + "0" * 15 + "1",
        "-0." + "0" * 15 + "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Small values with different scales
    run_benchmark_multiply(
        "Small values with different scales",
        "0." + "0" * 10 + "1",
        "0." + "0" * 5 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: Extreme scales (large negative exponents)
    run_benchmark_multiply(
        "Extreme scales (large negative exponents)",
        "1.23e-10",
        "4.56e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Multiplication with extreme exponent difference
    run_benchmark_multiply(
        "Multiplication with extreme exponent difference",
        "1.23e-10",
        "4.56e10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUE TESTS ===

    # Case 28: Multiplication of exact mathematical constants
    run_benchmark_multiply(
        "Multiplication of exact mathematical constants (PI * E)",
        "3.14159265358979323846264338328",
        "2.71828182845904523536028747135",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Multiply by 0.1 (recurring binary)
    run_benchmark_multiply(
        "Multiply by 0.1 (recurring binary)",
        "42.5",
        "0.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Multiply by 0.01 (recurring binary)
    run_benchmark_multiply(
        "Multiply by 0.01 (recurring binary)",
        "42.5",
        "0.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: Multiplication with repeating decimals
    run_benchmark_multiply(
        "Multiplication with repeating decimals",
        "0.333333333333333333333333333",
        "0.666666666666666666666666667",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Multiplication by 10 (shift operation)
    run_benchmark_multiply(
        "Multiplication by 10 (shift operation)",
        "123.456",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRECISION BOUNDARY TESTS ===

    # Case 33: Multiplication requiring rounding
    run_benchmark_multiply(
        "Multiplication requiring rounding",
        "9.9999999999999999999999999",
        "9.9999999999999999999999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Multiplication with trailing zeros
    run_benchmark_multiply(
        "Multiplication with trailing zeros",
        "1.5000000000000000000000000",
        "2.0000000000000000000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Binary-friendly multiplication
    run_benchmark_multiply(
        "Binary-friendly multiplication",
        "0.125",  # 1/8
        "8",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 36: Decimal-friendly multiplication
    run_benchmark_multiply(
        "Decimal-friendly multiplication",
        "0.2",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 37: Multiplication at precision boundary
    run_benchmark_multiply(
        "Multiplication at precision boundary",
        "1" + "0" * 14,  # 10^14
        "1" + "0" * 14,  # 10^14
        iterations,
        log_file,
        speedup_factors,
    )

    # === APPLICATION-SPECIFIC TESTS ===

    # Case 38: Financial calculation (price * quantity)
    run_benchmark_multiply(
        "Financial calculation (price * quantity)",
        "19.99",  # Price
        "12",  # Quantity
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 39: Scientific measurement (unit conversion)
    run_benchmark_multiply(
        "Scientific measurement (unit conversion)",
        "299792458",  # Speed of light in m/s
        "0.000000001",  # Convert to km/µs
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: Area calculation (length * width)
    run_benchmark_multiply(
        "Area calculation (length * width)",
        "14.75",  # Length in meters
        "8.25",  # Width in meters
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 41: Financial percentage (principal * rate)
    run_benchmark_multiply(
        "Financial percentage (principal * rate)",
        "10000.00",  # Principal
        "0.0425",  # Interest rate (4.25%)
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 42: Physics calculation (E = mc²)
    run_benchmark_multiply(
        "Physics calculation (E = mc²)",
        "1.5",  # Mass in kg
        "8.98755178736817e16",  # c² in m²/s²
        iterations,
        log_file,
        speedup_factors,
    )

    # === EDGE CASES AND EXTREME VALUES ===

    # Case 43: Multiplication with maximum precision
    run_benchmark_multiply(
        "Multiplication with maximum precision",
        "1." + "1" * 27,  # Lots of 1s after decimal
        "1." + "9" * 27,  # Lots of 9s after decimal
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: Multiplication with extreme scale separation
    run_benchmark_multiply(
        "Multiplication with extreme scale separation",
        "1e+20",
        "1e-20",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 45: Square operation
    run_benchmark_multiply(
        "Square operation",
        "123456789.987654321",
        "123456789.987654321",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 46: Multiplication requiring significant rounding
    run_benchmark_multiply(
        "Multiplication requiring significant rounding",
        "0.333333333333333333333333333",
        "3.333333333333333333333333333",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: Multiplication of near-zero values
    run_benchmark_multiply(
        "Multiplication of near-zero values",
        "0." + "0" * 25 + "1",
        "0." + "0" * 25 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # === REAL-WORLD APPLICATION TESTS ===

    # Case 48: Currency conversion
    run_benchmark_multiply(
        "Currency conversion",
        "1250.75",  # Amount in USD
        "0.92",  # USD to EUR conversion rate
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: Volume calculation (length * width * height)
    run_benchmark_multiply(
        "Volume calculation (partial - length * width)",
        "25.75",  # Length
        "10.5",  # Width
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: Scale calculation (multiplying by factor)
    run_benchmark_multiply(
        "Scale calculation (multiplying by factor)",
        "123.456789",  # Original value
        "1000",  # Scale factor
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
            "\n=== BigDecimal Multiplication Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different multiplication cases",
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
