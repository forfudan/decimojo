"""
Comprehensive benchmarks for Decimal power function.
Compares performance against Python's decimal module.
"""

from decimojo.prelude import dm, Decimal, RoundingMode
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
    var log_filename = log_dir + "/benchmark_power_" + timestamp + ".log"

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


fn run_benchmark(
    name: String,
    base_value: String,
    exponent_value: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Decimal power with Python Decimal power.

    Args:
        name: Name of the benchmark case.
        base_value: String representation of the base Decimal.
        exponent_value: String representation of the exponent Decimal.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Base:            " + base_value, log_file)
    log_print("Exponent:        " + exponent_value, log_file)

    # Set up Mojo and Python values
    var mojo_base = Decimal(base_value)
    var mojo_exponent = Decimal(exponent_value)
    var pydecimal = Python.import_module("decimal")
    var py_base = pydecimal.Decimal(base_value)
    var py_exponent = pydecimal.Decimal(exponent_value)

    # Execute the operations once to verify correctness
    var mojo_result = dm.decimal.exponential.power(mojo_base, mojo_exponent)
    var py_result = py_base**py_exponent

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = dm.decimal.exponential.power(mojo_base, mojo_exponent)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py_base**py_exponent
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo power():     " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python power():   " + String(python_time) + " ns per iteration",
        log_file,
    )
    log_print("Speedup factor:  " + String(speedup), log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create a Mojo List to store speedup factors for averaging later
    var speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo Power Function Benchmark ===", log_file)
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
    log_print("Mojo decimal precision: " + String(Decimal.MAX_SCALE), log_file)

    # Define benchmark cases
    log_print(
        "\nRunning power function benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Integer base and exponent
    run_benchmark(
        "Integer base and exponent",
        "2",
        "3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Decimal base and integer exponent
    run_benchmark(
        "Decimal base and integer exponent",
        "2.5",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Integer base and decimal exponent
    run_benchmark(
        "Integer base and decimal exponent",
        "9",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Decimal base and exponent
    run_benchmark(
        "Decimal base and exponent",
        "2.0",
        "1.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Negative exponent
    run_benchmark(
        "Negative exponent",
        "4",
        "-0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Large base and exponent
    run_benchmark(
        "Large base and exponent",
        "12345",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Small base and exponent
    run_benchmark(
        "Small base and exponent",
        "0.5",
        "0.5",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: High precision base and exponent
    run_benchmark(
        "High precision base and exponent",
        "1.234567890123456789",
        "2.345678901234567890",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Base close to 1
    run_benchmark(
        "Base close to 1",
        "1.000000001",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Exponent close to 1
    run_benchmark(
        "Exponent close to 1",
        "2",
        "1.000000001",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Zero base and positive exponent
    run_benchmark(
        "Zero base and positive exponent",
        "0",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: One base and any exponent
    run_benchmark(
        "One base and any exponent",
        "1",
        "3.14",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Large base and small exponent
    run_benchmark(
        "Large base and small exponent",
        "1000000",
        "0.1",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Small base and large exponent
    run_benchmark(
        "Small base and large exponent",
        "0.00001",
        "10",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Base greater than 1 and negative exponent
    run_benchmark(
        "Base greater than 1 and negative exponent",
        "2",
        "-3",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Base less than 1 and negative exponent
    run_benchmark(
        "Base less than 1 and negative exponent",
        "0.5",
        "-2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Base with many digits and exponent with few digits
    run_benchmark(
        "Base with many digits and exponent with few digits",
        "1.234567890123456789",
        "2",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Base with few digits and exponent with many digits
    run_benchmark(
        "Base with few digits and exponent with many digits",
        "2",
        "1.234567890123456789",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Base and exponent with alternating digits
    run_benchmark(
        "Base and exponent with alternating digits",
        "1.01010101",
        "2.02020202",
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Base and exponent with specific pattern
    run_benchmark(
        "Base and exponent with specific pattern",
        "3.14159",
        "2.71828",
        iterations,
        log_file,
        speedup_factors,
    )

    # Calculate average speedup factor
    var sum_speedup: Float64 = 0.0
    for i in range(len(speedup_factors)):
        sum_speedup += speedup_factors[i]
    var average_speedup = sum_speedup / Float64(len(speedup_factors))

    # Display summary
    log_print("\n=== Power Function Benchmark Summary ===", log_file)
    log_print("Benchmarked:      20 different power() cases", log_file)
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )
    log_print("Average speedup:  " + String(average_speedup) + "×", log_file)

    # List all speedup factors
    log_print("\nIndividual speedup factors:", log_file)
    for i in range(len(speedup_factors)):
        log_print(
            String("Case {}: {}×").format(i + 1, round(speedup_factors[i], 2)),
            log_file,
        )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
