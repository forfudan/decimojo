"""
Comprehensive benchmarks for BigDecimal square root.
Compares performance against Python's decimal module with 50 diverse test cases.
"""

from decimojo import BigDecimal, RoundingMode
from python import Python, PythonObject
from time import perf_counter_ns
import time
import os
from collections import List

comptime PRECISION = 5000


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
        log_dir + "/benchmark_bigdecimal_sqrt_" + timestamp + ".log"
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


fn run_benchmark_sqrt(
    name: String,
    value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal square root with Python Decimal square root.

    Args:
        name: Name of the benchmark case.
        value: String representation of the number to calculate the square root of.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Value:           " + value, log_file)

    # Set up Mojo and Python values
    var mojo_value = BigDecimal(value)
    var pydecimal = Python.import_module("decimal")
    var py_value = pydecimal.Decimal(value)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_value.sqrt(precision=PRECISION)
        var py_result = py_value.sqrt()

        # Display results for verification
        log_print("Mojo result:       " + String(mojo_result), log_file)
        log_print("Python result:     " + String(py_result), log_file)

        # Check if results match
        var mojo_str = String(mojo_result)
        var py_str = String(py_result)
        var results_match = mojo_str == py_str

        if results_match:
            log_print(
                "✓ Results MATCH",
                log_file,
            )
        else:
            log_print("✗ Results DIFFER!", log_file)
            log_print(
                "  Mojo: " + mojo_str,
                log_file,
            )
            log_print(
                "  Python: " + py_str,
                log_file,
            )

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_value.sqrt(precision=PRECISION)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value.sqrt()
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo square root:   " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python square root: " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigDecimal Square Root Benchmark ===", log_file)
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
    var pydecimal = Python().import_module("decimal")

    # Set Python decimal precision to match Mojo's
    pydecimal.getcontext().prec = PRECISION
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print("Mojo decimal precision: PRECISION", log_file)

    # Define benchmark cases
    log_print(
        "\nRunning decimal square root benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC SQUARE ROOT TESTS ===

    # Case 1: Simple integer square root
    run_benchmark_sqrt(
        "Simple integer square root",
        "9",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Simple decimal square root
    run_benchmark_sqrt(
        "Simple decimal square root",
        "2.25",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Square root with different scales
    run_benchmark_sqrt(
        "Square root with different scales",
        "1.5625",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Square root with very different scales
    run_benchmark_sqrt(
        "Square root with very different scales",
        "0.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Square root of one
    run_benchmark_sqrt(
        "Square root of one",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCALE AND PRECISION TESTS ===

    # Case 6: Precision at decimal limit
    run_benchmark_sqrt(
        "Precision at decimal limit",
        "2.0000000000000000000000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Square root resulting in scale increase
    run_benchmark_sqrt(
        "Square root resulting in scale increase",
        "0.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Square root with high precision
    run_benchmark_sqrt(
        "Square root with high precision",
        "0.1111111111111111111111111111",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Square root resulting in exact integer
    run_benchmark_sqrt(
        "Square root resulting in exact integer",
        "4",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Square root with scientific notation
    run_benchmark_sqrt(
        "Square root with scientific notation",
        "1.44e2",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE NUMBER TESTS ===

    # Case 11: Large integer square root
    run_benchmark_sqrt(
        "Large integer square root",
        "9999999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Large decimal square root
    run_benchmark_sqrt(
        "Large decimal square root",
        "12345.6789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Very large square root
    run_benchmark_sqrt(
        "Very large square root",
        "1" + "0" * 20,  # 10^20
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Extreme scales (large positive exponents)
    run_benchmark_sqrt(
        "Extreme scales (large positive exponents)",
        "1.44e10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SMALL NUMBER TESTS ===

    # Case 15: Very small positive values
    run_benchmark_sqrt(
        "Very small positive values",
        "0." + "0" * 15 + "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Extreme scales (large negative exponents)
    run_benchmark_sqrt(
        "Extreme scales (large negative exponents)",
        "1.44e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUE TESTS ===

    # Case 17: Square root of exact mathematical constants
    run_benchmark_sqrt(
        "Square root of exact mathematical constants (PI)",
        "3.14159265358979323846264338328",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Square root of 2
    run_benchmark_sqrt(
        "Square root of 2",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Square root of 3
    run_benchmark_sqrt(
        "Square root of 3",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Square root of 5
    run_benchmark_sqrt(
        "Square root of 5",
        "5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Square root of 7
    run_benchmark_sqrt(
        "Square root of 7",
        "7",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Square root of 11
    run_benchmark_sqrt(
        "Square root of 11",
        "11",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Square root of 13
    run_benchmark_sqrt(
        "Square root of 13",
        "13",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Square root of 17
    run_benchmark_sqrt(
        "Square root of 17",
        "17",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Square root of 19
    run_benchmark_sqrt(
        "Square root of 19",
        "19",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: Square root of 23
    run_benchmark_sqrt(
        "Square root of 23",
        "23",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Square root of 29
    run_benchmark_sqrt(
        "Square root of 29",
        "29",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Square root of 31
    run_benchmark_sqrt(
        "Square root of 31",
        "31",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Square root of 37
    run_benchmark_sqrt(
        "Square root of 37",
        "37",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Square root of 41
    run_benchmark_sqrt(
        "Square root of 41",
        "41",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: Square root of 43
    run_benchmark_sqrt(
        "Square root of 43",
        "43",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Square root of 47
    run_benchmark_sqrt(
        "Square root of 47",
        "47",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: Square root of 53
    run_benchmark_sqrt(
        "Square root of 53",
        "53",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: Square root of 59
    run_benchmark_sqrt(
        "Square root of 59",
        "59",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: Square root of 61
    run_benchmark_sqrt(
        "Square root of 61",
        "61",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 36: Square root of 67
    run_benchmark_sqrt(
        "Square root of 67",
        "67",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 37: Square root of 71
    run_benchmark_sqrt(
        "Square root of 71",
        "71",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 38: Square root of 73
    run_benchmark_sqrt(
        "Square root of 73",
        "73",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 39: Square root of 79
    run_benchmark_sqrt(
        "Square root of 79",
        "79",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: Square root of 83
    run_benchmark_sqrt(
        "Square root of 83",
        "83",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 41: Square root of 89
    run_benchmark_sqrt(
        "Square root of 89",
        "89",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 42: Square root of 97
    run_benchmark_sqrt(
        "Square root of 97",
        "97",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 43: Square root of 101
    run_benchmark_sqrt(
        "Square root of 101",
        "101",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: Square root of 103
    run_benchmark_sqrt(
        "Square root of 103",
        "103",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 45: Square root of 107
    run_benchmark_sqrt(
        "Square root of 107",
        "107",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 46: Square root of 109
    run_benchmark_sqrt(
        "Square root of 109",
        "109",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: Square root of 113
    run_benchmark_sqrt(
        "Square root of 113",
        "113",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 48: Square root of 127
    run_benchmark_sqrt(
        "Square root of 127",
        "127",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: Square root of 131
    run_benchmark_sqrt(
        "Square root of 131",
        "131",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: Square root of 137
    run_benchmark_sqrt(
        "Square root of 137",
        "137",
        iterations,
        log_file,
        speedup_factors,
    )

    # === VERY LARGE DECIMAL TESTS ===

    # Case 51: 100-word decimal (approximately 900 digits)
    run_benchmark_sqrt(
        "100-word decimal square root",
        "123456789." + "123456789" * 100,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 52: 200-word decimal (approximately 1800 digits)
    run_benchmark_sqrt(
        "200-word decimal square root",
        "987654321." + "987654321" * 200,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 53: 300-word decimal (approximately 2700 digits)
    run_benchmark_sqrt(
        "300-word decimal square root",
        "555666777." + "555666777" * 300,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 54: 400-word decimal (approximately 3600 digits)
    run_benchmark_sqrt(
        "400-word decimal square root",
        "111222333." + "111222333" * 400,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 55: 500-word decimal (approximately 4500 digits)
    run_benchmark_sqrt(
        "500-word decimal square root",
        "999888777." + "999888777" * 500,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 56: 750-word decimal (approximately 6750 digits)
    run_benchmark_sqrt(
        "750-word decimal square root",
        "147258369." + "147258369" * 750,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 57: 1000-word decimal (approximately 9000 digits)
    run_benchmark_sqrt(
        "1000-word decimal square root",
        "369258147." + "369258147" * 1000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 58: 1250-word decimal (approximately 11250 digits)
    run_benchmark_sqrt(
        "1250-word decimal square root",
        "789456123." + "789456123" * 1250,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 59: 1500-word decimal (approximately 13500 digits)
    run_benchmark_sqrt(
        "1500-word decimal square root",
        "456789123." + "456789123" * 1500,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 60: 1750-word decimal (approximately 15750 digits)
    run_benchmark_sqrt(
        "1750-word decimal square root",
        "321654987." + "321654987" * 1750,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 61: 2000-word decimal (approximately 18000 digits)
    run_benchmark_sqrt(
        "2000-word decimal square root",
        "654987321." + "654987321" * 2000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 62: 2250-word decimal (approximately 20250 digits)
    run_benchmark_sqrt(
        "2250-word decimal square root",
        "852741963." + "852741963" * 2250,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 63: 2500-word decimal (approximately 22500 digits)
    run_benchmark_sqrt(
        "2500-word decimal square root",
        "741852963." + "741852963" * 2500,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 64: 2750-word decimal (approximately 24750 digits)
    run_benchmark_sqrt(
        "2750-word decimal square root",
        "123456789" * 1000 + "963852741." + "963852741" * 2750,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 65: 3000-word decimal (approximately 27000 digits)
    run_benchmark_sqrt(
        "3000-word decimal square root",
        "159357426." + "159357426" * 3000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 66: 3500-word decimal (approximately 31500 digits)
    run_benchmark_sqrt(
        "3500-word decimal square root",
        "426159357." + "426159357" * 3500,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 67: 4000-word decimal (approximately 36000 digits)
    run_benchmark_sqrt(
        "4000-word decimal square root",
        "357426159." + "357426159" * 4000,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 68: 4250-word decimal (approximately 38250 digits)
    run_benchmark_sqrt(
        "4250-word decimal square root",
        "624813579." + "624813579" * 4250,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 69: 4750-word decimal (approximately 42750 digits)
    run_benchmark_sqrt(
        "4750-word decimal square root",
        "813579624." + "813579624" * 4750,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 70: 5000-word decimal (approximately 45000 digits)
    run_benchmark_sqrt(
        "5000-word decimal square root",
        "0." + "000000000579624813" * 5000,
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
            "\n=== BigDecimal Square Root Benchmark Summary ===", log_file
        )
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
