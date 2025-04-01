"""
Comprehensive benchmarks for BigDecimal exponential function (exp).
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
    var log_filename = log_dir + "/benchmark_bigdecimal_exp_" + timestamp + ".log"

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


fn run_benchmark_exp(
    name: String,
    value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal exp with Python Decimal exp.

    Args:
        name: Name of the benchmark case.
        value: String representation of the number to calculate the exp of.
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
        var mojo_result = mojo_value.exp()
        var py_result = py_value.exp()

        # Display results for verification
        log_print("Mojo result:        " + String(mojo_result), log_file)
        log_print("Python result:      " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            # _ = mojo_value.exp()
            _ = mojo_value.exp()
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value.exp()
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = python_time / mojo_time
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo exp:           " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python exp:         " + String(python_time) + " ns per iteration",
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
    log_print(
        "=== DeciMojo BigDecimal Exponential (exp) Benchmark ===", log_file
    )
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
        "\nRunning decimal exp benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC EXPONENTIAL TESTS ===

    # Case 1: exp(0)
    run_benchmark_exp(
        "exp(0)",
        "0",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: exp(1)
    run_benchmark_exp(
        "exp(1)",
        "1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: exp(-1)
    run_benchmark_exp(
        "exp(-1)",
        "-1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: exp(2)
    run_benchmark_exp(
        "exp(2)",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: exp(-2)
    run_benchmark_exp(
        "exp(-2)",
        "-2",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCALE AND PRECISION TESTS ===

    # Case 6: exp(0.1)
    run_benchmark_exp(
        "exp(0.1)",
        "0.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: exp(-0.1)
    run_benchmark_exp(
        "exp(-0.1)",
        "-0.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: exp(0.01)
    run_benchmark_exp(
        "exp(0.01)",
        "0.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: exp(-0.01)
    run_benchmark_exp(
        "exp(-0.01)",
        "-0.01",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: exp(0.5)
    run_benchmark_exp(
        "exp(0.5)",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # === LARGE NUMBER TESTS ===

    # Case 11: exp(10)
    run_benchmark_exp(
        "exp(10)",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: exp(-10)
    run_benchmark_exp(
        "exp(-10)",
        "-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: exp(100)
    run_benchmark_exp(
        "exp(100)",
        "100",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: exp(-100)
    run_benchmark_exp(
        "exp(-100)",
        "-100",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SMALL NUMBER TESTS ===

    # Case 15: exp(0.0001)
    run_benchmark_exp(
        "exp(0.0001)",
        "0.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: exp(-0.0001)
    run_benchmark_exp(
        "exp(-0.0001)",
        "-0.0001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: exp(1e-10)
    run_benchmark_exp(
        "exp(1e-10)",
        "1e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: exp(-1e-10)
    run_benchmark_exp(
        "exp(-1e-10)",
        "-1e-10",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCIENTIFIC NOTATION TESTS ===

    # Case 19: exp(1.234e2)
    run_benchmark_exp(
        "exp(1.234e2)",
        "1.234e2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: exp(-1.234e2)
    run_benchmark_exp(
        "exp(-1.234e2)",
        "-1.234e2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: exp(1.234e-2)
    run_benchmark_exp(
        "exp(1.234e-2)",
        "1.234e-2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: exp(-1.234e-2)
    run_benchmark_exp(
        "exp(-1.234e-2)",
        "-1.234e-2",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUE TESTS ===

    # Case 23: exp(PI)
    run_benchmark_exp(
        "exp(PI)",
        "3.14159265358979323846264338328",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: exp(-PI)
    run_benchmark_exp(
        "exp(-PI)",
        "-3.14159265358979323846264338328",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: exp(E)
    run_benchmark_exp(
        "exp(E)",
        "2.71828182845904523536028747135",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: exp(-E)
    run_benchmark_exp(
        "exp(-E)",
        "-2.71828182845904523536028747135",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: exp(0.6931471805599453) # ln(2)
    run_benchmark_exp(
        "exp(ln(2))",
        "0.6931471805599453",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: exp(-0.6931471805599453) # -ln(2)
    run_benchmark_exp(
        "exp(-ln(2))",
        "-0.6931471805599453",
        iterations,
        log_file,
        speedup_factors,
    )

    # === MORE EDGE CASES ===

    # Case 29: exp(very small positive)
    run_benchmark_exp(
        "exp(very small positive)",
        "0.000000000000000000000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: exp(very small negative)
    run_benchmark_exp(
        "exp(very small negative)",
        "-0.000000000000000000000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: exp(large positive)
    run_benchmark_exp(
        "exp(large positive)",
        "50",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: exp(large negative)
    run_benchmark_exp(
        "exp(large negative)",
        "-50",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 33: exp(near max double)
    run_benchmark_exp(
        "exp(near max double)",
        "709",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 34: exp(near min double)
    run_benchmark_exp(
        "exp(near min double)",
        "-709",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 35: exp(1000)
    run_benchmark_exp(
        "exp(1000)",
        "1000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 36: exp(-1000)
    run_benchmark_exp(
        "exp(-1000)",
        "-1000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 37: exp(10000)
    run_benchmark_exp(
        "exp(10000)",
        "10000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 38: exp(-10000)
    run_benchmark_exp(
        "exp(-10000)",
        "-10000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 39: exp(100000)
    run_benchmark_exp(
        "exp(100000)",
        "100000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 40: exp(-100000)
    run_benchmark_exp(
        "exp(-100000)",
        "-100000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 41: exp(1000000)
    run_benchmark_exp(
        "exp(1000000)",
        "1000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 42: exp(-1000000)
    run_benchmark_exp(
        "exp(-1000000)",
        "-1000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 43: exp(10000000)
    run_benchmark_exp(
        "exp(10000000)",
        "10000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 44: exp(-10000000)
    run_benchmark_exp(
        "exp(-10000000)",
        "-10000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 45: exp(100000000)
    run_benchmark_exp(
        "exp(100000000)",
        "100000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 46: exp(-100000000)
    run_benchmark_exp(
        "exp(-100000000)",
        "-100000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 47: exp(1000000000)
    run_benchmark_exp(
        "exp(1000000000)",
        "1000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 48: exp(-1000000000)
    run_benchmark_exp(
        "exp(-1000000000)",
        "-1000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 49: exp(10000000000)
    run_benchmark_exp(
        "exp(10000000000)",
        "10000000000",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 50: exp(-10000000000)
    run_benchmark_exp(
        "exp(-10000000000)",
        "-10000000000",
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
            "\n=== BigDecimal Exponential (exp) Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:        "
            + String(len(speedup_factors))
            + " different exp cases",
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
