"""
Comprehensive benchmarks for Decimal128 logical comparison operations.
Compares performance against Python's decimal module across diverse test cases.
Tests all comparison operators: >, >=, ==, <=, <, !=
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
    var log_filename = log_dir + "/benchmark_comparison_" + timestamp + ".log"

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


fn run_comparison_benchmark(
    name: String,
    a_mojo: Decimal128,
    b_mojo: Decimal128,
    a_py: PythonObject,
    b_py: PythonObject,
    op: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo Dec128 comparison with Python decimal comparison.

    Args:
        name: Name of the benchmark case.
        a_mojo: First Mojo Dec128 operand.
        b_mojo: Second Mojo Dec128 operand.
        a_py: First Python decimal operand.
        b_py: Second Python decimal operand.
        op: Comparison operator as string (">", ">=", "==", "<=", "<", "!=").
        iterations: Number of iterations for the benchmark.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store speedup factors for averaging.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Operator:        " + op, log_file)
    log_print(
        "Decimals:        " + String(a_mojo) + " " + op + " " + String(b_mojo),
        log_file,
    )

    # Execute the operations once to verify correctness
    var mojo_result: Bool
    var py_result: PythonObject

    if op == ">":
        mojo_result = a_mojo > b_mojo
        py_result = a_py > b_py
    elif op == ">=":
        mojo_result = a_mojo >= b_mojo
        py_result = a_py >= b_py
    elif op == "==":
        mojo_result = a_mojo == b_mojo
        py_result = a_py == b_py
    elif op == "<=":
        mojo_result = a_mojo <= b_mojo
        py_result = a_py <= b_py
    elif op == "<":
        mojo_result = a_mojo < b_mojo
        py_result = a_py < b_py
    elif op == "!=":
        mojo_result = a_mojo != b_mojo
        py_result = a_py != b_py
    else:
        log_print("Error: Invalid operator '" + op + "'", log_file)
        return

    # Display results for verification
    log_print("Mojo result:     " + String(mojo_result), log_file)
    log_print("Python result:   " + String(py_result), log_file)

    # Benchmark Mojo implementation
    var t0 = perf_counter_ns()
    for _ in range(iterations):
        if op == ">":
            _ = a_mojo > b_mojo
        elif op == ">=":
            _ = a_mojo >= b_mojo
        elif op == "==":
            _ = a_mojo == b_mojo
        elif op == "<=":
            _ = a_mojo <= b_mojo
        elif op == "<":
            _ = a_mojo < b_mojo
        elif op == "!=":
            _ = a_mojo != b_mojo
    var mojo_time = (perf_counter_ns() - t0) / iterations
    if mojo_time == 0:
        mojo_time = 1  # Avoid division by zero

    # Benchmark Python implementation
    t0 = perf_counter_ns()
    for _ in range(iterations):
        if op == ">":
            _ = a_py > b_py
        elif op == ">=":
            _ = a_py >= b_py
        elif op == "==":
            _ = a_py == b_py
        elif op == "<=":
            _ = a_py <= b_py
        elif op == "<":
            _ = a_py < b_py
        elif op == "!=":
            _ = a_py != b_py
    var python_time = (perf_counter_ns() - t0) / iterations

    # Calculate speedup factor
    var speedup = Float64(python_time) / Float64(mojo_time)
    speedup_factors.append(Float64(speedup))

    # Print results with speedup comparison
    log_print(
        "Mojo decimal:    " + String(mojo_time) + " ns per operation",
        log_file,
    )
    log_print(
        "Python decimal:  " + String(python_time) + " ns per operation",
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
    log_print("=== DeciMojo Logical Comparison Benchmark ===", log_file)
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

    var iterations = 10000
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
        "\nRunning logical comparison benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # Test Case 1: Equal integers
    var case1_a_mojo = Decimal128("100")
    var case1_b_mojo = Decimal128("100")
    var case1_a_py = pydecimal.Decimal128("100")
    var case1_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Equal integers",
        case1_a_mojo,
        case1_b_mojo,
        case1_a_py,
        case1_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 2: Different integers
    var case2_a_mojo = Decimal128("100")
    var case2_b_mojo = Decimal128("200")
    var case2_a_py = pydecimal.Decimal128("100")
    var case2_b_py = pydecimal.Decimal128("200")
    run_comparison_benchmark(
        "Different integers (<)",
        case2_a_mojo,
        case2_b_mojo,
        case2_a_py,
        case2_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 3: Different integers (>)
    run_comparison_benchmark(
        "Different integers (>)",
        case2_b_mojo,
        case2_a_mojo,
        case2_b_py,
        case2_a_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 4: Equal decimals with different representations
    var case4_a_mojo = Decimal128("100.00")
    var case4_b_mojo = Decimal128("100")
    var case4_a_py = pydecimal.Decimal128("100.00")
    var case4_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Equal decimal with different scales",
        case4_a_mojo,
        case4_b_mojo,
        case4_a_py,
        case4_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 5: Compare with zero
    var case5_a_mojo = Decimal128("0")
    var case5_b_mojo = Decimal128("-0.00")
    var case5_a_py = pydecimal.Decimal128("0")
    var case5_b_py = pydecimal.Decimal128("-0.00")
    run_comparison_benchmark(
        "Zero comparison (==)",
        case5_a_mojo,
        case5_b_mojo,
        case5_a_py,
        case5_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 6: Very small difference
    var case6_a_mojo = Decimal128("0.0000000000000000000000000001")
    var case6_b_mojo = Decimal128("0.0000000000000000000000000002")
    var case6_a_py = pydecimal.Decimal128("0.0000000000000000000000000001")
    var case6_b_py = pydecimal.Decimal128("0.0000000000000000000000000002")
    run_comparison_benchmark(
        "Very small difference (<)",
        case6_a_mojo,
        case6_b_mojo,
        case6_a_py,
        case6_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 7: Very large numbers
    var case7_a_mojo = Decimal128("9999999999999999999999999999")
    var case7_b_mojo = Decimal128("9999999999999999999999999998")
    var case7_a_py = pydecimal.Decimal128("9999999999999999999999999999")
    var case7_b_py = pydecimal.Decimal128("9999999999999999999999999998")
    run_comparison_benchmark(
        "Very large numbers (>)",
        case7_a_mojo,
        case7_b_mojo,
        case7_a_py,
        case7_b_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 8: Negative numbers
    var case8_a_mojo = Decimal128("-10")
    var case8_b_mojo = Decimal128("-20")
    var case8_a_py = pydecimal.Decimal128("-10")
    var case8_b_py = pydecimal.Decimal128("-20")
    run_comparison_benchmark(
        "Negative numbers (>)",
        case8_a_mojo,
        case8_b_mojo,
        case8_a_py,
        case8_b_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 9: Mixed sign comparison
    var case9_a_mojo = Decimal128("-10")
    var case9_b_mojo = Decimal128("10")
    var case9_a_py = pydecimal.Decimal128("-10")
    var case9_b_py = pydecimal.Decimal128("10")
    run_comparison_benchmark(
        "Mixed signs (<)",
        case9_a_mojo,
        case9_b_mojo,
        case9_a_py,
        case9_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 10: Not equal comparison
    var case10_a_mojo = Decimal128("99.99")
    var case10_b_mojo = Decimal128("100")
    var case10_a_py = pydecimal.Decimal128("99.99")
    var case10_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Not equal (!=)",
        case10_a_mojo,
        case10_b_mojo,
        case10_a_py,
        case10_b_py,
        "!=",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 11: Less than or equal (true because less)
    var case11_a_mojo = Decimal128("50")
    var case11_b_mojo = Decimal128("100")
    var case11_a_py = pydecimal.Decimal128("50")
    var case11_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Less than or equal (<=, true because less)",
        case11_a_mojo,
        case11_b_mojo,
        case11_a_py,
        case11_b_py,
        "<=",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 12: Less than or equal (true because equal)
    var case12_a_mojo = Decimal128("100")
    var case12_b_mojo = Decimal128("100")
    var case12_a_py = pydecimal.Decimal128("100")
    var case12_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Less than or equal (<=, true because equal)",
        case12_a_mojo,
        case12_b_mojo,
        case12_a_py,
        case12_b_py,
        "<=",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 13: Greater than or equal (true because greater)
    var case13_a_mojo = Decimal128("200")
    var case13_b_mojo = Decimal128("100")
    var case13_a_py = pydecimal.Decimal128("200")
    var case13_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Greater than or equal (>=, true because greater)",
        case13_a_mojo,
        case13_b_mojo,
        case13_a_py,
        case13_b_py,
        ">=",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 14: Greater than or equal (true because equal)
    var case14_a_mojo = Decimal128("100")
    var case14_b_mojo = Decimal128("100")
    var case14_a_py = pydecimal.Decimal128("100")
    var case14_b_py = pydecimal.Decimal128("100")
    run_comparison_benchmark(
        "Greater than or equal (>=, true because equal)",
        case14_a_mojo,
        case14_b_mojo,
        case14_a_py,
        case14_b_py,
        ">=",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 15: Equal with high precision after decimal
    var case15_a_mojo = Decimal128("0.12345678901234567890123456789")
    var case15_b_mojo = Decimal128("0.12345678901234567890123456789")
    var case15_a_py = pydecimal.Decimal128("0.12345678901234567890123456789")
    var case15_b_py = pydecimal.Decimal128("0.12345678901234567890123456789")
    run_comparison_benchmark(
        "Equal high precision numbers",
        case15_a_mojo,
        case15_b_mojo,
        case15_a_py,
        case15_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 16: Almost equal high precision
    var case16_a_mojo = Decimal128("0.12345678901234567890123456780")
    var case16_b_mojo = Decimal128("0.12345678901234567890123456789")
    var case16_a_py = pydecimal.Decimal128("0.12345678901234567890123456780")
    var case16_b_py = pydecimal.Decimal128("0.12345678901234567890123456789")
    run_comparison_benchmark(
        "Almost equal high precision (<)",
        case16_a_mojo,
        case16_b_mojo,
        case16_a_py,
        case16_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 17: Equal but different trailing zeros
    var case17_a_mojo = Decimal128("1.10000")
    var case17_b_mojo = Decimal128("1.1")
    var case17_a_py = pydecimal.Decimal128("1.10000")
    var case17_b_py = pydecimal.Decimal128("1.1")
    run_comparison_benchmark(
        "Equal with different trailing zeros",
        case17_a_mojo,
        case17_b_mojo,
        case17_a_py,
        case17_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 18: Not equal with trailing zeros that matter
    var case18_a_mojo = Decimal128("1.10001")
    var case18_b_mojo = Decimal128("1.1")
    var case18_a_py = pydecimal.Decimal128("1.10001")
    var case18_b_py = pydecimal.Decimal128("1.1")
    run_comparison_benchmark(
        "Not equal with significant trailing digits",
        case18_a_mojo,
        case18_b_mojo,
        case18_a_py,
        case18_b_py,
        "!=",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 19: Large positive vs small negative
    var case19_a_mojo = Decimal128("9999999")
    var case19_b_mojo = Decimal128("-0.000001")
    var case19_a_py = pydecimal.Decimal128("9999999")
    var case19_b_py = pydecimal.Decimal128("-0.000001")
    run_comparison_benchmark(
        "Large positive vs small negative (>)",
        case19_a_mojo,
        case19_b_mojo,
        case19_a_py,
        case19_b_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 20: Equal near zero
    var case20_a_mojo = Decimal128("0.000000000000000000000000001")
    var case20_b_mojo = Decimal128("0.000000000000000000000000001")
    var case20_a_py = pydecimal.Decimal128("0.000000000000000000000000001")
    var case20_b_py = pydecimal.Decimal128("0.000000000000000000000000001")
    run_comparison_benchmark(
        "Equal near zero (==)",
        case20_a_mojo,
        case20_b_mojo,
        case20_a_py,
        case20_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 21: Common financial values
    var case21_a_mojo = Decimal128("19.99")
    var case21_b_mojo = Decimal128("20.00")
    var case21_a_py = pydecimal.Decimal128("19.99")
    var case21_b_py = pydecimal.Decimal128("20.00")
    run_comparison_benchmark(
        "Common financial values (<)",
        case21_a_mojo,
        case21_b_mojo,
        case21_a_py,
        case21_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 22: Different sign zeros
    var case22_a_mojo = Decimal128("0")
    var case22_b_mojo = Decimal128("-0")
    var case22_a_py = pydecimal.Decimal128("0")
    var case22_b_py = pydecimal.Decimal128("-0")
    run_comparison_benchmark(
        "Different sign zeros (==)",
        case22_a_mojo,
        case22_b_mojo,
        case22_a_py,
        case22_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 23: Repeated digits comparison
    var case23_a_mojo = Decimal128("9.999999999")
    var case23_b_mojo = Decimal128("10")
    var case23_a_py = pydecimal.Decimal128("9.999999999")
    var case23_b_py = pydecimal.Decimal128("10")
    run_comparison_benchmark(
        "Repeated digits comparison (<)",
        case23_a_mojo,
        case23_b_mojo,
        case23_a_py,
        case23_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 24: Scientific notation equivalent
    var case24_a_mojo = Decimal128("1.23e2")
    var case24_b_mojo = Decimal128("123")
    var case24_a_py = pydecimal.Decimal128("1.23e2")
    var case24_b_py = pydecimal.Decimal128("123")
    run_comparison_benchmark(
        "Scientific notation equivalent (==)",
        case24_a_mojo,
        case24_b_mojo,
        case24_a_py,
        case24_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 25: Same value different format
    var case25_a_mojo = Decimal128("100.00")
    var case25_b_mojo = Decimal128("1.0e2")
    var case25_a_py = pydecimal.Decimal128("100.00")
    var case25_b_py = pydecimal.Decimal128("1.0e2")
    run_comparison_benchmark(
        "Same value different format (==)",
        case25_a_mojo,
        case25_b_mojo,
        case25_a_py,
        case25_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 26: Almost but not quite equal
    var case26_a_mojo = Decimal128("0.999999999999999999999")
    var case26_b_mojo = Decimal128("1.000000000000000000000")
    var case26_a_py = pydecimal.Decimal128("0.999999999999999999999")
    var case26_b_py = pydecimal.Decimal128("1.000000000000000000000")
    run_comparison_benchmark(
        "Almost but not quite equal values (<)",
        case26_a_mojo,
        case26_b_mojo,
        case26_a_py,
        case26_b_py,
        "<",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 27: Greater than comparison (negative numbers)
    var case27_a_mojo = Decimal128("-100")
    var case27_b_mojo = Decimal128("-200")
    var case27_a_py = pydecimal.Decimal128("-100")
    var case27_b_py = pydecimal.Decimal128("-200")
    run_comparison_benchmark(
        "Greater than with negative numbers (>)",
        case27_a_mojo,
        case27_b_mojo,
        case27_a_py,
        case27_b_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 28: Equal negative values
    var case28_a_mojo = Decimal128("-42.5")
    var case28_b_mojo = Decimal128("-42.50")
    var case28_a_py = pydecimal.Decimal128("-42.5")
    var case28_b_py = pydecimal.Decimal128("-42.50")
    run_comparison_benchmark(
        "Equal negative values (==)",
        case28_a_mojo,
        case28_b_mojo,
        case28_a_py,
        case28_b_py,
        "==",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 29: Close to zero comparison
    var case29_a_mojo = Decimal128("0.0000000000000000000000000001")
    var case29_b_mojo = Decimal128("0")
    var case29_a_py = pydecimal.Decimal128("0.0000000000000000000000000001")
    var case29_b_py = pydecimal.Decimal128("0")
    run_comparison_benchmark(
        "Close to zero comparison (>)",
        case29_a_mojo,
        case29_b_mojo,
        case29_a_py,
        case29_b_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Test Case 30: Boundary values
    var case30_a_mojo = Decimal128.MAX()
    var case30_b_mojo = Decimal128.MAX() - 1
    var case30_a_py = pydecimal.Decimal128(String(Decimal128.MAX()))
    var case30_b_py = pydecimal.Decimal128(String(Decimal128.MAX() - 1))
    run_comparison_benchmark(
        "Boundary values (>)",
        case30_a_mojo,
        case30_b_mojo,
        case30_a_py,
        case30_b_py,
        ">",
        iterations,
        log_file,
        speedup_factors,
    )

    # Calculate and report average speedup
    var total_speedup = 0.0
    for i in range(speedup_factors.__len__()):
        total_speedup += speedup_factors[i]
    var avg_speedup = total_speedup / Float64(speedup_factors.__len__())

    log_print("\n===== Summary =====", log_file)
    log_print(
        "Total test cases: " + String(speedup_factors.__len__()), log_file
    )
    log_print("Average speedup factor: " + String(avg_speedup), log_file)

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
