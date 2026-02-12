"""
Comprehensive benchmarks for Decimal128.quantize() method.
Compares performance against Python's decimal module with diverse test cases.
"""

from decimojo.prelude import dm, Decimal128, RoundingMode
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
    var log_filename = log_dir + "/benchmark_quantize_" + timestamp + ".log"

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


fn run_benchmark_quantize(
    name: String,
    value_str: String,
    quant_str: String,
    rounding_mode: RoundingMode,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Dec128.quantize with Python decimal.quantize.

    Args:
        name: Name of the benchmark case.
        value_str: String representation of the value to quantize.
        quant_str: String representation of the quantizer.
        rounding_mode: The rounding mode to use.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Value:           " + value_str, log_file)
    log_print("Quantizer:       " + quant_str, log_file)
    log_print("Rounding mode:   " + String(rounding_mode), log_file)

    # Set up Mojo and Python values
    var mojo_value = Decimal128(value_str)
    var mojo_quant = Decimal128(quant_str)
    var pydecimal = Python.import_module("decimal")
    var py_value = pydecimal.Decimal128(value_str)
    var py_quant = pydecimal.Decimal128(quant_str)

    # Map Mojo rounding mode to Python rounding mode
    var py_rounding_mode: PythonObject
    if rounding_mode == RoundingMode.ROUND_HALF_EVEN:
        py_rounding_mode = pydecimal.ROUND_HALF_EVEN
    elif rounding_mode == RoundingMode.ROUND_HALF_UP:
        py_rounding_mode = pydecimal.ROUND_HALF_UP
    elif rounding_mode == RoundingMode.ROUND_UP:
        py_rounding_mode = pydecimal.ROUND_UP
    elif rounding_mode == RoundingMode.ROUND_DOWN:
        py_rounding_mode = pydecimal.ROUND_DOWN
    else:
        py_rounding_mode = pydecimal.ROUND_HALF_EVEN  # Default

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_value.quantize(mojo_quant, rounding_mode)
        var py_result = py_value.quantize(py_quant, rounding=py_rounding_mode)

        # Display results for verification
        log_print("Mojo result:     " + String(mojo_result), log_file)
        log_print("Python result:   " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_value.quantize(mojo_quant, rounding_mode)
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value.quantize(py_quant, rounding=py_rounding_mode)
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factor
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo quantize():  " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python quantize():" + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo quantize() Method Benchmark ===", log_file)
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

    var iterations = 10000  # Higher iterations as this operation should be fast
    var pydecimal = Python().import_module("decimal")

    # Set Python decimal precision to match Mojo's
    pydecimal.getcontext().prec = 28
    log_print(
        "Python decimal precision: " + String(pydecimal.getcontext().prec),
        log_file,
    )
    log_print(
        "Mojo decimal precision: " + String(Decimal128.MAX_SCALE), log_file
    )

    # Define benchmark cases
    log_print(
        "\nRunning quantize() method benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Basic quantization - rounding to 2 decimal places
    run_benchmark_quantize(
        "Round to 2 decimal places",
        "3.14159",
        "0.01",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Round to integer
    run_benchmark_quantize(
        "Round to integer",
        "42.7",
        "1",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Increase precision (add trailing zeros)
    run_benchmark_quantize(
        "Increase precision",
        "5.5",
        "0.001",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Decrease precision (round)
    run_benchmark_quantize(
        "Decrease precision",
        "123.456789",
        "0.01",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Different exponent patterns
    run_benchmark_quantize(
        "Different exponent pattern",
        "9.876",
        "1.00",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: ROUND_HALF_UP rounding mode
    run_benchmark_quantize(
        "ROUND_HALF_UP mode",
        "3.5",
        "1",
        RoundingMode.ROUND_HALF_UP,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: ROUND_DOWN rounding mode
    run_benchmark_quantize(
        "ROUND_DOWN mode",
        "3.9",
        "1",
        RoundingMode.ROUND_DOWN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: ROUND_UP rounding mode
    run_benchmark_quantize(
        "ROUND_UP mode",
        "3.1",
        "1",
        RoundingMode.ROUND_UP,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Negative number - ROUND_HALF_EVEN
    run_benchmark_quantize(
        "Negative number - ROUND_HALF_EVEN",
        "-1.5",
        "1",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Quantizing zero
    run_benchmark_quantize(
        "Quantizing zero",
        "0",
        "0.001",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Quantizing to same exponent (no change)
    run_benchmark_quantize(
        "Quantizing to same exponent",
        "123.45",
        "0.01",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Numbers that need significant rounding
    run_benchmark_quantize(
        "Significant rounding",
        "9.9999",
        "1",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Very small number
    run_benchmark_quantize(
        "Very small number",
        "0.0000001",
        "0.001",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Banker's rounding for 2.5
    run_benchmark_quantize(
        "Banker's rounding (2.5)",
        "2.5",
        "1",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Quantizing with negative exponent
    run_benchmark_quantize(
        "Quantizing to tens place",
        "123.456",
        "10",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: High precision
    run_benchmark_quantize(
        "High precision quantizing",
        "3.1415926535",
        "0.000001",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Rounding to hundreds
    run_benchmark_quantize(
        "Rounding to hundreds",
        "750",
        "100",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Value very close to rounding threshold
    run_benchmark_quantize(
        "Value close to threshold",
        "0.9999999",
        "1",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Pi to 2 decimal places
    run_benchmark_quantize(
        "Pi to 2 decimal places",
        "3.14159265358979323",
        "0.01",
        RoundingMode.ROUND_HALF_EVEN,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Zero with trailing zeros
    run_benchmark_quantize(
        "Zero with trailing zeros",
        "0.0",
        "0.0000",
        RoundingMode.ROUND_HALF_EVEN,
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
        log_print("\n=== quantize() Method Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:      "
            + String(len(speedup_factors))
            + " different quantize() cases",
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
