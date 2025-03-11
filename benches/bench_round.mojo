"""
Comprehensive benchmarks for Decimal rounding operations.
Compares performance against Python's decimal module across 32 diverse test cases.
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
    var log_filename = log_dir + "/benchmark_round_" + timestamp + ".log"

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
    d_mojo: Decimal,
    places: Int,
    d_py: PythonObject,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Decimal round with Python Decimal quantize.

    Args:
        name: Name of the benchmark case.
        d_mojo: Mojo Decimal operand.
        places: Number of decimal places to round to.
        d_py: Python Decimal operand.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Decimal:         " + String(d_mojo), log_file)
    log_print("Round to:        " + String(places) + " places", log_file)

    # Get Python decimal module for quantize operation
    var py = Python.import_module("builtins")

    # Execute the operations once to verify correctness
    var mojo_result = round(d_mojo, places)
    var py_result = py.round(d_py, ndigits=places)

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = round(d_mojo, places)
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Prevent division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        _ = py.round(d_py, ndigits=places)
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = python_time / mojo_time
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo Decimal:    " + String(mojo_time) + " ns per iteration",
        log_file,
    )
    log_print(
        "Python Decimal:  " + String(python_time) + " ns per iteration",
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
    log_print("=== DeciMojo Rounding Benchmark ===", log_file)
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
    log_print("Mojo decimal precision: " + String(Decimal.MAX_SCALE), log_file)

    # Define benchmark cases
    log_print(
        "\nRunning rounding benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Case 1: Standard rounding to 2 decimal places
    var case1_mojo = Decimal("123.456789")
    var case1_py = pydecimal.Decimal("123.456789")
    run_benchmark(
        "Standard rounding to 2 places",
        case1_mojo,
        2,
        case1_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 2: Banker's rounding (round half to even) for .5 with even preceding digit
    var case2_mojo = Decimal("10.125")
    var case2_py = pydecimal.Decimal("10.125")
    run_benchmark(
        "Banker's rounding with even preceding digit",
        case2_mojo,
        2,
        case2_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 3: Banker's rounding (round half to even) for .5 with odd preceding digit
    var case3_mojo = Decimal("10.135")
    var case3_py = pydecimal.Decimal("10.135")
    run_benchmark(
        "Banker's rounding with odd preceding digit",
        case3_mojo,
        2,
        case3_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 4: Rounding with less than half (<0.5)
    var case4_mojo = Decimal("10.124")
    var case4_py = pydecimal.Decimal("10.124")
    run_benchmark(
        "Rounding with less than half",
        case4_mojo,
        2,
        case4_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 5: Rounding with more than half (>0.5)
    var case5_mojo = Decimal("10.126")
    var case5_py = pydecimal.Decimal("10.126")
    run_benchmark(
        "Rounding with more than half",
        case5_mojo,
        2,
        case5_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 6: Rounding to 0 decimal places (whole number)
    var case6_mojo = Decimal("123.456")
    var case6_py = pydecimal.Decimal("123.456")
    run_benchmark(
        "Rounding to whole number",
        case6_mojo,
        0,
        case6_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 7: Rounding a negative number
    var case7_mojo = Decimal("-123.456")
    var case7_py = pydecimal.Decimal("-123.456")
    run_benchmark(
        "Rounding negative number",
        case7_mojo,
        2,
        case7_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 8: Rounding to negative places (tens)
    var case8_mojo = Decimal("123.456")
    var case8_py = pydecimal.Decimal("123.456")
    run_benchmark(
        "Rounding to tens (negative places)",
        case8_mojo,
        -1,
        case8_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 9: Rounding to negative places (hundreds)
    var case9_mojo = Decimal("1234.56")
    var case9_py = pydecimal.Decimal("1234.56")
    run_benchmark(
        "Rounding to hundreds (negative places)",
        case9_mojo,
        -2,
        case9_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 10: Rounding a very small number
    var case10_mojo = Decimal("0.0000001234")
    var case10_py = pydecimal.Decimal("0.0000001234")
    run_benchmark(
        "Rounding very small number",
        case10_mojo,
        10,
        case10_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 11: Rounding already rounded number (no change)
    var case11_mojo = Decimal("123.45")
    var case11_py = pydecimal.Decimal("123.45")
    run_benchmark(
        "Rounding already rounded number",
        case11_mojo,
        2,
        case11_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 12: Rounding to high precision (20 places)
    var case12_mojo = Decimal("0.12345678901234567890123")
    var case12_py = pydecimal.Decimal("0.12345678901234567890123")
    run_benchmark(
        "Rounding to high precision (20 places)",
        case12_mojo,
        20,
        case12_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 13: Rounding to more places than input has
    var case13_mojo = Decimal("123.456")
    var case13_py = pydecimal.Decimal("123.456")
    run_benchmark(
        "Rounding to more places than input (10)",
        case13_mojo,
        10,
        case13_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 14: Rounding number with trailing 9's
    var case14_mojo = Decimal("9.999")
    var case14_py = pydecimal.Decimal("9.999")
    run_benchmark(
        "Rounding number with trailing 9's",
        case14_mojo,
        2,
        case14_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 15: Rounding requiring carry propagation (9.99 -> 10.0)
    var case15_mojo = Decimal("9.99")
    var case15_py = pydecimal.Decimal("9.99")
    run_benchmark(
        "Rounding requiring carry propagation",
        case15_mojo,
        1,
        case15_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 16: Rounding exactly half with even preceding digit
    var case16_mojo = Decimal("2.5")
    var case16_py = pydecimal.Decimal("2.5")
    run_benchmark(
        "Rounding exactly half with even preceding digit",
        case16_mojo,
        0,
        case16_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 17: Rounding exactly half with odd preceding digit
    var case17_mojo = Decimal("3.5")
    var case17_py = pydecimal.Decimal("3.5")
    run_benchmark(
        "Rounding exactly half with odd preceding digit",
        case17_mojo,
        0,
        case17_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 18: Rounding value close to MAX
    var case18_mojo = Decimal("12345678901234567890") - Decimal("0.12345")
    var case18_py = pydecimal.Decimal(String(case18_mojo))
    run_benchmark(
        "Rounding value close to MAX",
        case18_mojo,
        2,
        case18_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 19: Rounding minimum positive value
    var case19_mojo = Decimal(
        "0." + "0" * 27 + "1"
    )  # Smallest positive decimal
    var case19_py = pydecimal.Decimal(String(case19_mojo))
    run_benchmark(
        "Rounding minimum positive value",
        case19_mojo,
        28,
        case19_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 20: Rounding perfectly formatted engineering value
    var case20_mojo = Decimal("123456.789e-3")  # 123.456789
    var case20_py = pydecimal.Decimal("123456.789e-3")
    run_benchmark(
        "Rounding engineering notation value",
        case20_mojo,
        4,
        case20_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 21: Rounding a number with long integer part
    var case21_mojo = Decimal("12345678901234567.8901")
    var case21_py = pydecimal.Decimal("12345678901234567.8901")
    run_benchmark(
        "Rounding number with long integer part",
        case21_mojo,
        2,
        case21_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 22: Rounding a number that's just below half
    var case22_mojo = Decimal("10.12499999999999999")
    var case22_py = pydecimal.Decimal("10.12499999999999999")
    run_benchmark(
        "Rounding number just below half",
        case22_mojo,
        2,
        case22_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 23: Rounding a number that's just above half
    var case23_mojo = Decimal("10.12500000000000001")
    var case23_py = pydecimal.Decimal("10.12500000000000001")
    run_benchmark(
        "Rounding number just above half",
        case23_mojo,
        2,
        case23_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 24: Rounding to max precision (28 places)
    var case24_mojo = Decimal("0." + "1" * 29)  # More digits than max precision
    var case24_py = pydecimal.Decimal(String(case24_mojo))
    run_benchmark(
        "Rounding to maximum precision (28)",
        case24_mojo,
        28,
        case24_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 25: Rounding zero
    var case25_mojo = Decimal("0")
    var case25_py = pydecimal.Decimal("0")
    run_benchmark(
        "Rounding zero",
        case25_mojo,
        10,
        case25_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 26: Rounding a series of mixed digits
    var case26_mojo = Decimal("3.141592653589793238462643383")
    var case26_py = pydecimal.Decimal("3.141592653589793238462643383")
    run_benchmark(
        "Rounding Pi to various places",
        case26_mojo,
        15,
        case26_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 27: Rounding negative number requiring carry propagation
    var case27_mojo = Decimal("-9.99")
    var case27_py = pydecimal.Decimal("-9.99")
    run_benchmark(
        "Rounding negative with carry propagation",
        case27_mojo,
        1,
        case27_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 28: Rounding with exact .5 and zeros after
    var case28_mojo = Decimal("1.5000000000000000000")
    var case28_py = pydecimal.Decimal("1.5000000000000000000")
    run_benchmark(
        "Rounding with exact .5 and zeros after",
        case28_mojo,
        0,
        case28_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 29: Rounding with exact .5 and non-zeros after
    var case29_mojo = Decimal("1.50000000000000000001")
    var case29_py = pydecimal.Decimal("1.50000000000000000001")
    run_benchmark(
        "Rounding with exact .5 and non-zeros after",
        case29_mojo,
        0,
        case29_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 30: Rounding extremely close to MAX value
    var case30_mojo = Decimal("123456789012345678") - Decimal("0.000000001")
    var case30_py = pydecimal.Decimal(String(case30_mojo))
    run_benchmark(
        "Rounding extremely close to MAX",
        case30_mojo,
        8,
        case30_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 31: Random decimal with various digits after decimal
    var case31_mojo = Decimal("7.389465718934026719043")
    var case31_py = pydecimal.Decimal("7.389465718934026719043")
    run_benchmark(
        "Random decimal with various digits",
        case31_mojo,
        12,
        case31_py,
        iterations,
        log_file,
        speedup_factors,
    )

    # Case 32: Number with alternating digits
    var case32_mojo = Decimal("1.010101010101010101010101")
    var case32_py = pydecimal.Decimal("1.010101010101010101010101")
    run_benchmark(
        "Number with alternating digits",
        case32_mojo,
        18,
        case32_py,
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
    log_print("\n=== Rounding Benchmark Summary ===", log_file)
    log_print("Benchmarked:      32 different rounding cases", log_file)
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
