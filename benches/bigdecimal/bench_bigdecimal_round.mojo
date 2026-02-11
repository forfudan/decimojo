"""
Comprehensive benchmarks for BigDecimal rounding functions.
Compares performance against Python's decimal module with various rounding modes and test cases.
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
        log_dir + "/benchmark_bigdecimal_round_" + timestamp + ".log"
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


fn run_benchmark_round(
    name: String,
    value: String,
    decimal_places: Int,
    rounding_mode_mojo: RoundingMode,
    rounding_mode_python: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigDecimal round with Python Decimal quantize.

    Args:
        name: Name of the benchmark case.
        value: String representation of the number to round.
        decimal_places: Number of decimal places to round to.
        rounding_mode_mojo: Rounding mode to use for Mojo BigDecimal.
        rounding_mode_python: Rounding mode string to use for Python Decimal.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:          " + name, log_file)
    log_print("Value:              " + value, log_file)
    log_print("Decimal places:     " + String(decimal_places), log_file)
    log_print("Rounding mode:      " + String(rounding_mode_mojo), log_file)

    # Set up Mojo and Python values
    var mojo_value = BigDecimal(value)
    var pydecimal = Python.import_module("decimal")
    var py_value = pydecimal.Decimal(value)

    # Create Python rounding context
    pydecimal.setcontext(pydecimal.Context(rounding=pydecimal.ROUND_HALF_EVEN))
    if rounding_mode_python == "ROUND_DOWN":
        pydecimal.setcontext(pydecimal.Context(rounding=pydecimal.ROUND_DOWN))
    elif rounding_mode_python == "ROUND_UP":
        pydecimal.setcontext(pydecimal.Context(rounding=pydecimal.ROUND_UP))
    elif rounding_mode_python == "ROUND_HALF_UP":
        pydecimal.setcontext(
            pydecimal.Context(rounding=pydecimal.ROUND_HALF_UP)
        )
    elif rounding_mode_python == "ROUND_HALF_EVEN":
        pydecimal.setcontext(
            pydecimal.Context(rounding=pydecimal.ROUND_HALF_EVEN)
        )

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_value.round(decimal_places, rounding_mode_mojo)
        var py_result = py_value.__round__(decimal_places)

        # Display results for verification
        log_print("Mojo result:        " + String(mojo_result), log_file)
        log_print("Python result:      " + String(py_result), log_file)

        # Benchmark Mojo implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_value.round(decimal_places, rounding_mode_mojo)
        var mojo_time = (perf_counter_ns() - t0) / UInt(iterations)
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_value.__round__(decimal_places)
        var python_time = (perf_counter_ns() - t0) / UInt(iterations)

        # Calculate speedup factor
        var speedup = Float64(python_time) / Float64(mojo_time)
        speedup_factors.append(Float64(speedup))

        # Print results with speedup comparison
        log_print(
            "Mojo round:         " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python round:       " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo BigDecimal Round Function Benchmark ===", log_file)
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
        "\nRunning decimal round benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === ROUND_DOWN MODE TESTS ===

    # Case 1: Round down to integer
    run_benchmark_round(
        "Round down to integer",
        "12.345",
        0,
        materialize[RoundingMode.ROUND_DOWN](),
        "ROUND_DOWN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Round down to 1 decimal place
    run_benchmark_round(
        "Round down to 1 decimal place",
        "12.345",
        1,
        materialize[RoundingMode.ROUND_DOWN](),
        "ROUND_DOWN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Round down negative to integer
    run_benchmark_round(
        "Round down negative to integer",
        "-12.345",
        0,
        materialize[RoundingMode.ROUND_DOWN](),
        "ROUND_DOWN",
        iterations,
        log_file,
        speedup_factors,
    )

    # === ROUND_UP MODE TESTS ===

    # Case 4: Round up to integer
    run_benchmark_round(
        "Round up to integer",
        "12.345",
        0,
        materialize[RoundingMode.ROUND_UP](),
        "ROUND_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Round up to 1 decimal place
    run_benchmark_round(
        "Round up to 1 decimal place",
        "12.345",
        1,
        materialize[RoundingMode.ROUND_UP](),
        "ROUND_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Round up negative to integer
    run_benchmark_round(
        "Round up negative to integer",
        "-12.345",
        0,
        materialize[RoundingMode.ROUND_UP](),
        "ROUND_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    # === ROUND_HALF_UP MODE TESTS ===

    # Case 7: Round half up to integer (0.5 -> 1)
    run_benchmark_round(
        "Round half up to integer (0.5 -> 1)",
        "12.5",
        0,
        materialize[RoundingMode.ROUND_HALF_UP](),
        "ROUND_HALF_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Round half up to 1 decimal place (0.05 -> 0.1)
    run_benchmark_round(
        "Round half up to 1 decimal place (0.05 -> 0.1)",
        "12.05",
        1,
        materialize[RoundingMode.ROUND_HALF_UP](),
        "ROUND_HALF_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Round half up negative to integer (-0.5 -> -1)
    run_benchmark_round(
        "Round half up negative to integer (-0.5 -> -1)",
        "-12.5",
        0,
        materialize[RoundingMode.ROUND_HALF_UP](),
        "ROUND_HALF_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    # === ROUND_HALF_EVEN (BANKER'S ROUNDING) MODE TESTS ===

    # Case 10: Round half even to integer (0.5 -> 0 with even digit)
    run_benchmark_round(
        "Round half even to integer (even digit)",
        "12.5",
        0,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Round half even to integer (0.5 -> 1 with odd digit)
    run_benchmark_round(
        "Round half even to integer (odd digit)",
        "13.5",
        0,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Round half even to 1 decimal place (0.05 -> 0.0 with even digit)
    run_benchmark_round(
        "Round half even to 1 decimal place (even digit)",
        "12.25",
        1,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # === DECIMAL PLACES VARIATIONS ===

    # Case 13: Round to higher precision (add zeros)
    run_benchmark_round(
        "Round to higher precision (add zeros)",
        "12.345",
        5,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Negative decimal places (round to tens)
    run_benchmark_round(
        "Negative decimal places (round to tens)",
        "123.456",
        -1,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Negative decimal places (round to hundreds)
    run_benchmark_round(
        "Negative decimal places (round to hundreds)",
        "123.456",
        -2,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SPECIAL VALUES AND EDGE CASES ===

    # Case 16: Round zero
    run_benchmark_round(
        "Round zero",
        "0",
        2,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Round very small number
    run_benchmark_round(
        "Round very small number",
        "0.0000000000000000000000001",
        10,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Round very large number
    run_benchmark_round(
        "Round very large number",
        "9999999999.99999",
        2,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Round with carry over (9.9999 -> 10)
    run_benchmark_round(
        "Round with carry over (9.9999 -> 10)",
        "9.9999",
        0,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Round exactly half with alternate modes
    run_benchmark_round(
        "Round exactly half (down)",
        "10.5",
        0,
        materialize[RoundingMode.ROUND_DOWN](),
        "ROUND_DOWN",
        iterations,
        log_file,
        speedup_factors,
    )

    run_benchmark_round(
        "Round exactly half (up)",
        "10.5",
        0,
        materialize[RoundingMode.ROUND_UP](),
        "ROUND_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    run_benchmark_round(
        "Round exactly half (half up)",
        "10.5",
        0,
        materialize[RoundingMode.ROUND_HALF_UP](),
        "ROUND_HALF_UP",
        iterations,
        log_file,
        speedup_factors,
    )

    run_benchmark_round(
        "Round exactly half (half even)",
        "10.5",
        0,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # === SCIENTIFIC NOTATION INPUTS ===

    # Case 24: Round scientific notation value
    run_benchmark_round(
        "Round scientific notation value",
        "1.2345e5",
        2,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Round small scientific notation value
    run_benchmark_round(
        "Round small scientific notation value",
        "1.2345e-5",
        8,
        materialize[RoundingMode.ROUND_HALF_EVEN](),
        "ROUND_HALF_EVEN",
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
            "\n=== BigDecimal Round Function Benchmark Summary ===", log_file
        )
        log_print(
            "Benchmarked:        "
            + String(len(speedup_factors))
            + " different rounding cases",
            log_file,
        )
        log_print(
            "Each case ran:      " + String(iterations) + " iterations",
            log_file,
        )
        log_print(
            "Average speedup:    " + String(average_speedup) + "×", log_file
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
