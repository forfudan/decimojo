"""Benchmarks for BigUInt scale_up_by_power_of_10 function."""

from decimojo.biguint.biguint import BigUInt
import decimojo.biguint.arithmetics
from time import perf_counter_ns
import time
import os
from collections import List
from python import Python, PythonObject


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
        log_dir + "/benchmark_biguint_scale_up_" + timestamp + ".log"
    )

    print("Saving benchmark results to:", log_filename)
    return python.open(log_filename, "w")


fn log_print(msg: String, log_file: PythonObject) raises:
    """Prints a message to both the console and the log file."""
    print(msg)
    log_file.write(msg + "\n")
    log_file.flush()  # Ensure the message is written immediately


fn run_benchmark_scale_up(
    name: String,
    value: String,
    power: Int,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark for Mojo BigUInt scale_up_by_power_of_10 function.

    Args:
        name: Name of the benchmark case.
        value: String representation of the BigUInt.
        power: The power of 10 to scale up by.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store benchmark times.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("BigUInt value:   " + value, log_file)
    log_print("Power of 10:     " + String(power), log_file)

    # Set up Mojo value
    var mojo_value = BigUInt(value)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = decimojo.biguint.arithmetics.scale_up_by_power_of_10(
            mojo_value, power
        )
    var mojo_time = (perf_counter_ns() - t0) / iterations

    # Print results
    log_print(
        "Mojo scale_up:   " + String(mojo_time) + " ns per iteration", log_file
    )
    speedup_factors.append(Float64(mojo_time))


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create a Mojo List to store benchmark times
    var speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print(
        "=== DeciMojo BigUInt scale_up_by_power_of_10 Benchmark ===", log_file
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

    var iterations = 1000

    # Define benchmark cases
    log_print(
        "\nRunning scale_up_by_power_of_10 benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Small power
    run_benchmark_scale_up(
        "Small power", "12345", 5, iterations, log_file, speedup_factors
    )

    # Case 2: Medium power
    run_benchmark_scale_up(
        "Medium power", "12345", 20, iterations, log_file, speedup_factors
    )

    # Case 3: Large power
    run_benchmark_scale_up(
        "Large power", "12345", 50, iterations, log_file, speedup_factors
    )

    # Case 4: Very large power
    run_benchmark_scale_up(
        "Very large power", "12345", 100, iterations, log_file, speedup_factors
    )

    # Case 5: Small number, small power
    run_benchmark_scale_up(
        "Small number, small power",
        "1",
        5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Large number, small power
    run_benchmark_scale_up(
        "Large number, small power",
        "9" * 50,
        5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Small number, large power
    run_benchmark_scale_up(
        "Small number, large power",
        "1",
        50,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Large number, large power
    run_benchmark_scale_up(
        "Large number, large power",
        "9" * 50,
        50,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Power of 10
    run_benchmark_scale_up(
        "Power of 10", "1", 10, iterations, log_file, speedup_factors
    )

    # Case 10: Power of 10, large number
    run_benchmark_scale_up(
        "Power of 10, large number",
        "1234567890",
        10,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Zero value
    run_benchmark_scale_up(
        "Zero value", "0", 10, iterations, log_file, speedup_factors
    )

    # Case 12: Zero power
    run_benchmark_scale_up(
        "Zero power", "12345", 0, iterations, log_file, speedup_factors
    )

    # Case 13: Large number, zero power
    run_benchmark_scale_up(
        "Large number, zero power",
        "9" * 50,
        0,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Number with many digits, small power
    run_benchmark_scale_up(
        "Number with many digits, small power",
        "1" * 100,
        5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Number with many digits, large power
    run_benchmark_scale_up(
        "Number with many digits, large power",
        "1" * 100,
        50,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Number with repeating digits, small power
    run_benchmark_scale_up(
        "Number with repeating digits, small power",
        "12345" * 20,
        5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Number with repeating digits, large power
    run_benchmark_scale_up(
        "Number with repeating digits, large power",
        "12345" * 20,
        50,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Number close to max UInt32, small power
    run_benchmark_scale_up(
        "Number close to max UInt32, small power",
        "4294967295",
        5,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Number close to max UInt32, large power
    run_benchmark_scale_up(
        "Number close to max UInt32, large power",
        "4294967295",
        50,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Large power, large number
    run_benchmark_scale_up(
        "Large power, large number",
        "12345678901234567890",
        100,
        iterations,
        log_file,
        speedup_factors,
    )

    # Calculate average benchmark time
    var sum_time: Float64 = 0.0
    for i in range(len(speedup_factors)):
        sum_time += speedup_factors[i]
    var average_time = sum_time / Float64(len(speedup_factors))

    # Display summary
    log_print(
        "\n=== BigUInt scale_up_by_power_of_10 Benchmark Summary ===", log_file
    )
    log_print(
        "Benchmarked:      "
        + String(len(speedup_factors))
        + " different scaling cases",
        log_file,
    )
    log_print(
        "Each case ran:    " + String(iterations) + " iterations", log_file
    )
    log_print("Average time:  " + String(average_time) + " ns", log_file)

    # List all benchmark times
    log_print("\nIndividual benchmark times:", log_file)
    for i in range(len(speedup_factors)):
        log_print(
            String("Case {}: {} ns").format(
                i + 1, round(speedup_factors[i], 2)
            ),
            log_file,
        )

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
