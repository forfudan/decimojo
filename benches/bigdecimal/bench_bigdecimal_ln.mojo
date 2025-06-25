"""
Comprehensive benchmarks for BigDecimal logarithm function (ln).
Compares performance against Python's decimal module with diverse test cases.
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
        log_dir + "/benchmark_bigdecimal_ln_" + timestamp + ".log"
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


fn run_benchmark_ln(
    name: String,
    value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal ln with Python Decimal ln.

    Args:
        name: Name of the benchmark case.
        value: String representation of the number to calculate the ln of.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:          " + name, log_file)
    log_print("Value:              " + value, log_file)

    # Set up Mojo and Python values
    var mojo_value = BigDecimal(value)
    var pydecimal = Python.import_module("decimal")
    var py_value = pydecimal.Decimal(value)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_value.ln()
        var py_result = py_value.ln()

        # Display results for verification
        log_print("Mojo result:        " + String(mojo_result), log_file)
        log_print("Python result:      " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_value.ln()
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value.ln()
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = python_time / mojo_time
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo ln:            " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python ln:          " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("Speedup factor:     " + String(speedup), log_file)
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
    log_print("=== DeciMojo BigDecimal Logarithm (ln) Benchmark ===", log_file)
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
    pydecimal.getcontext().prec = 28
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print("Mojo decimal precision: 28", log_file)

    # Define benchmark cases
    log_print(
        "\nRunning decimal ln benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC LOGARITHM TESTS ===

    # Case 1: ln(1) = 0
    run_benchmark_ln(
        "ln(1)",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: ln(e) = 1
    run_benchmark_ln(
        "ln(e)",
        "2.71828182845904523536028747135",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: ln(2)
    run_benchmark_ln(
        "ln(2)",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: ln(10)
    run_benchmark_ln(
        "ln(10)",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: ln(0.5)
    run_benchmark_ln(
        "ln(0.5)",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # === VALUES CLOSE TO 1 (CHALLENGING FOR PRECISION) ===

    # Case 6: ln(0.9)
    run_benchmark_ln(
        "ln(0.9)",
        "0.9",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: ln(0.99)
    run_benchmark_ln(
        "ln(0.99)",
        "0.99",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: ln(0.999)
    run_benchmark_ln(
        "ln(0.999)",
        "0.999",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: ln(1.001)
    run_benchmark_ln(
        "ln(1.001)",
        "1.001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: ln(1.01)
    run_benchmark_ln(
        "ln(1.01)",
        "1.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: ln(1.1)
    run_benchmark_ln(
        "ln(1.1)",
        "1.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SMALL VALUE TESTS ===

    # Case 12: ln(0.1)
    run_benchmark_ln(
        "ln(0.1)",
        "0.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: ln(0.01)
    run_benchmark_ln(
        "ln(0.01)",
        "0.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: ln(0.001)
    run_benchmark_ln(
        "ln(0.001)",
        "0.001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: ln(0.0001)
    run_benchmark_ln(
        "ln(0.0001)",
        "0.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: ln(1e-10)
    run_benchmark_ln(
        "ln(1e-10)",
        "1e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: ln(1e-20)
    run_benchmark_ln(
        "ln(1e-20)",
        "1e-20",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE VALUE TESTS ===

    # Case 18: ln(100)
    run_benchmark_ln(
        "ln(100)",
        "100",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: ln(1000)
    run_benchmark_ln(
        "ln(1000)",
        "1000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: ln(10000)
    run_benchmark_ln(
        "ln(10000)",
        "10000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: ln(1e10)
    run_benchmark_ln(
        "ln(1e10)",
        "1e10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: ln(1e20)
    run_benchmark_ln(
        "ln(1e20)",
        "1e20",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: ln(1e50)
    run_benchmark_ln(
        "ln(1e50)",
        "1e50",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: ln(1e100)
    run_benchmark_ln(
        "ln(1e100)",
        "1e100",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCIENTIFIC NOTATION TESTS ===

    # Case 25: ln(1.234e-5)
    run_benchmark_ln(
        "ln(1.234e-5)",
        "1.234e-5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: ln(5.678e12)
    run_benchmark_ln(
        "ln(5.678e12)",
        "5.678e12",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: ln(9.876e-10)
    run_benchmark_ln(
        "ln(9.876e-10)",
        "9.876e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: ln(3.14159e20)
    run_benchmark_ln(
        "ln(3.14159e20)",
        "3.14159e20",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUE TESTS ===

    # Case 29: ln(PI)
    run_benchmark_ln(
        "ln(PI)",
        "3.14159265358979323846264338328",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: ln(e^2) = 2
    run_benchmark_ln(
        "ln(e^2)",
        "7.3890560989306502272304274606",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: ln(sqrt(2))
    run_benchmark_ln(
        "ln(sqrt(2))",
        "1.4142135623730950488016887242",
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRECISE DECIMAL TESTS ===

    # Case 32: ln(1.5)
    run_benchmark_ln(
        "ln(1.5)",
        "1.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: ln(2.5)
    run_benchmark_ln(
        "ln(2.5)",
        "2.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: ln(3.75)
    run_benchmark_ln(
        "ln(3.75)",
        "3.75",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: ln(12.34567890)
    run_benchmark_ln(
        "ln(12.34567890)",
        "12.34567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 36: ln(0.1234567890)
    run_benchmark_ln(
        "ln(0.1234567890)",
        "0.1234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # === POWERS OF 2 ===

    # Case 37: ln(4) = ln(2^2)
    run_benchmark_ln(
        "ln(4)",
        "4",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 38: ln(8) = ln(2^3)
    run_benchmark_ln(
        "ln(8)",
        "8",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 39: ln(16) = ln(2^4)
    run_benchmark_ln(
        "ln(16)",
        "16",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: ln(32) = ln(2^5)
    run_benchmark_ln(
        "ln(32)",
        "32",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 41: ln(64) = ln(2^6)
    run_benchmark_ln(
        "ln(64)",
        "64",
        iterations,
        log_file,
        speedup_factors,
    )

    # === EXTREME VALUES ===

    # Case 42: ln(1e200)
    run_benchmark_ln(
        "ln(1e200)",
        "1e200",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 43: ln(1e-200)
    run_benchmark_ln(
        "ln(1e-200)",
        "1e-200",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: ln(1.797693e308) - near max double
    run_benchmark_ln(
        "ln(1.797693e308)",
        "1.797693e308",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 45: ln(4.940656e-324) - near min double
    run_benchmark_ln(
        "ln(4.940656e-324)",
        "4.940656e-324",
        iterations,
        log_file,
        speedup_factors,
    )

    # === PRECISE SPECIAL CASES ===

    # Case 46: ln(2.718281828459045) - ln(e) to high precision
    run_benchmark_ln(
        "ln(e precise)",
        "2.718281828459045",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: ln(1.414213562373095) - ln(√2) to high precision
    run_benchmark_ln(
        "ln(sqrt(2) precise)",
        "1.414213562373095",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 48: ln(1.1892071150027210667174999705...) - ln(2^(1/4))
    run_benchmark_ln(
        "ln(2^(1/4))",
        "1.189207115002721",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: ln(1.0000000000000000000000001) - very close to 1
    run_benchmark_ln(
        "ln(1.0000000000000000000000001)",
        "1.0000000000000000000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: ln(123456789.123456789)
    run_benchmark_ln(
        "ln(123456789.123456789)",
        "123456789.123456789",
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
            "\n=== BigDecimal Logarithm (ln) Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:        "
            + String(len(speedup_factors))
            + " different ln cases",
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
