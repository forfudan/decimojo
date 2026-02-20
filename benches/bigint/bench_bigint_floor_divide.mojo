"""
Comprehensive benchmarks for BigInt floor_divide operation.
Compares performance against Python's built-in int floor division with 50 diverse test cases.
"""

from decimojo.bigint.bigint import BigInt
import decimojo.bigint.arithmetics
from decimojo.bigint2.bigint2 import BigInt2
import decimojo.bigint2.arithmetics
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
        log_dir + "/benchmark_bigint_floor_divide_" + timestamp + ".log"
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


fn run_benchmark_floor_divide(
    name: String,
    dividend: String,
    divisor: String,
    iterations: Int,
    log_file: PythonObject,
    mut speedup_factors: List[Float64],
    mut bigint2_speedup_factors: List[Float64],
) raises:
    """
    Run a benchmark comparing Mojo BigInt, BigInt2, and Python int floor division.

    Args:
        name: Name of the benchmark case.
        dividend: String representation of the dividend.
        divisor: String representation of the divisor.
        iterations: Number of iterations to run.
        log_file: File object for logging results.
        speedup_factors: Mojo List to store BigInt speedup factors.
        bigint2_speedup_factors: Mojo List to store BigInt2 speedup factors.
    """
    log_print("\nBenchmark:       " + name, log_file)
    log_print("Dividend:        " + dividend, log_file)
    log_print("Divisor:         " + divisor, log_file)

    # Set up Mojo BigInt, BigInt2, and Python values
    var mojo_dividend = BigInt(dividend)
    var mojo_divisor = BigInt(divisor)
    var mojo2_dividend = BigInt2(dividend)
    var mojo2_divisor = BigInt2(divisor)
    var py = Python.import_module("builtins")
    var py_dividend = py.int(dividend)
    var py_divisor = py.int(divisor)

    # Execute the operations once to verify correctness
    try:
        var mojo_result = mojo_dividend // mojo_divisor
        var mojo2_result = mojo2_dividend // mojo2_divisor
        var py_result = py_dividend // py_divisor

        # Display results for verification
        log_print("BigInt result:   " + String(mojo_result), log_file)
        log_print("BigInt2 result:  " + String(mojo2_result), log_file)
        log_print("Python result:   " + String(py_result), log_file)

        # Benchmark BigInt implementation
        var t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo_dividend // mojo_divisor
        var mojo_time = (perf_counter_ns() - t0) / iterations
        if mojo_time == 0:
            mojo_time = 1  # Prevent division by zero

        # Benchmark BigInt2 implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = mojo2_dividend // mojo2_divisor
        var mojo2_time = (perf_counter_ns() - t0) / iterations
        if mojo2_time == 0:
            mojo2_time = 1  # Prevent division by zero

        # Benchmark Python implementation
        t0 = perf_counter_ns()
        for _ in range(iterations):
            _ = py_dividend // py_divisor
        var python_time = (perf_counter_ns() - t0) / iterations

        # Calculate speedup factors (Python / Mojo)
        var speedup = Float64(python_time) / Float64(mojo_time)
        var speedup2 = Float64(python_time) / Float64(mojo2_time)
        speedup_factors.append(Float64(speedup))
        bigint2_speedup_factors.append(Float64(speedup2))

        # Print results with speedup comparison
        log_print(
            "BigInt division:  " + String(mojo_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "BigInt2 division: " + String(mojo2_time) + " ns per iteration",
            log_file,
        )
        log_print(
            "Python division:  " + String(python_time) + " ns per iteration",
            log_file,
        )
        log_print("BigInt speedup:   " + String(speedup) + "×", log_file)
        log_print("BigInt2 speedup:  " + String(speedup2) + "×", log_file)
    except e:
        log_print("Error occurred during benchmark: " + String(e), log_file)
        log_print("Skipping this benchmark case", log_file)


fn main() raises:
    # Open log file
    var log_file = open_log_file()
    var datetime = Python.import_module("datetime")

    # Create Mojo Lists to store speedup factors for averaging later
    var speedup_factors = List[Float64]()
    var bigint2_speedup_factors = List[Float64]()

    # Display benchmark header with system information
    log_print("=== DeciMojo BigInt Floor Division Benchmark ===", log_file)
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

    # Define benchmark cases
    log_print(
        "\nRunning floor division benchmarks with "
        + String(iterations)
        + " iterations each",
        log_file,
    )

    # === BASIC TESTS ===

    # Case 1: Simple division with no remainder (positive/positive)
    run_benchmark_floor_divide(
        "Simple division with no remainder (positive/positive)",
        "100",
        "10",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 2: Division with remainder (positive/positive)
    run_benchmark_floor_divide(
        "Division with remainder (positive/positive)",
        "10",
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 3: Division resulting in zero (positive/positive)
    run_benchmark_floor_divide(
        "Division resulting in zero (positive/positive)",
        "5",
        "10",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 4: Division by one (positive/positive)
    run_benchmark_floor_divide(
        "Division by one (positive/positive)",
        "12345",
        "1",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === SIGN COMBINATION TESTS ===

    # Case 5: Negative dividend, positive divisor
    run_benchmark_floor_divide(
        "Negative dividend, positive divisor",
        "-10",
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 6: Negative dividend with remainder, positive divisor
    run_benchmark_floor_divide(
        "Negative dividend with remainder, positive divisor",
        "-11",
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 7: Positive dividend, negative divisor
    run_benchmark_floor_divide(
        "Positive dividend, negative divisor",
        "10",
        "-3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 8: Positive dividend with remainder, negative divisor
    run_benchmark_floor_divide(
        "Positive dividend with remainder, negative divisor",
        "11",
        "-3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 9: Negative dividend, negative divisor
    run_benchmark_floor_divide(
        "Negative dividend, negative divisor",
        "-10",
        "-3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 10: Negative dividend with remainder, negative divisor
    run_benchmark_floor_divide(
        "Negative dividend with remainder, negative divisor",
        "-11",
        "-3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === ZERO TESTS ===

    # Case 11: Zero dividend, positive divisor
    run_benchmark_floor_divide(
        "Zero dividend, positive divisor",
        "0",
        "5",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 12: Zero dividend, negative divisor
    run_benchmark_floor_divide(
        "Zero dividend, negative divisor",
        "0",
        "-5",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === LARGE NUMBER TESTS ===

    # Case 13: Large number division (positive/positive)
    run_benchmark_floor_divide(
        "Large number division (positive/positive)",
        "9999999999",  # 10 billion
        "333",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 14: Large number division (negative/positive)
    run_benchmark_floor_divide(
        "Large number division (negative/positive)",
        "-9999999999",  # -10 billion
        "333",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 15: Large number division (positive/negative)
    run_benchmark_floor_divide(
        "Large number division (positive/negative)",
        "9999999999",  # 10 billion
        "-333",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 16: Large number division (negative/negative)
    run_benchmark_floor_divide(
        "Large number division (negative/negative)",
        "-9999999999",  # -10 billion
        "-333",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === VERY LARGE NUMBER TESTS ===

    # Case 17: Very large number division (positive/positive)
    run_benchmark_floor_divide(
        "Very large number division (positive/positive)",
        "1" + "0" * 50,  # 10^50
        "7",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 18: Very large number division (negative/positive)
    run_benchmark_floor_divide(
        "Very large number division (negative/positive)",
        "-" + "1" + "0" * 50,  # -10^50
        "7",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 19: Very large number division (positive/negative)
    run_benchmark_floor_divide(
        "Very large number division (positive/negative)",
        "1" + "0" * 50,  # 10^50
        "-7",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 20: Very large number division (negative/negative)
    run_benchmark_floor_divide(
        "Very large number division (negative/negative)",
        "-" + "1" + "0" * 50,  # -10^50
        "-7",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === EXACT DIVISION WITH LARGE NUMBERS ===

    # Case 21: Exact large division (positive/positive)
    run_benchmark_floor_divide(
        "Exact large division (positive/positive)",
        "1" + "0" * 30,  # 10^30
        "1" + "0" * 10,  # 10^10
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 22: Exact large division (negative/positive)
    run_benchmark_floor_divide(
        "Exact large division (negative/positive)",
        "-" + "1" + "0" * 30,  # -10^30
        "1" + "0" * 10,  # 10^10
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 23: Exact large division (positive/negative)
    run_benchmark_floor_divide(
        "Exact large division (positive/negative)",
        "1" + "0" * 30,  # 10^30
        "-" + "1" + "0" * 10,  # -10^10
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 24: Exact large division (negative/negative)
    run_benchmark_floor_divide(
        "Exact large division (negative/negative)",
        "-" + "1" + "0" * 30,  # -10^30
        "-" + "1" + "0" * 10,  # -10^10
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === SPECIAL CASES ===

    # Case 25: Small dividend, very large divisor
    run_benchmark_floor_divide(
        "Small dividend, very large divisor",
        "12345",
        "9" * 20,  # 20 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 26: Small negative dividend, very large divisor
    run_benchmark_floor_divide(
        "Small negative dividend, very large divisor",
        "-12345",
        "9" * 20,  # 20 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 27: Fibonacci number division
    run_benchmark_floor_divide(
        "Fibonacci number division",
        "6765",  # Fib(20)
        "4181",  # Fib(19)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 28: Prime number division
    run_benchmark_floor_divide(
        "Prime number division",
        "2147483647",  # Mersenne prime (2^31 - 1)
        "997",  # Prime
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 29: Division near Int64 limit
    run_benchmark_floor_divide(
        "Division near Int64 limit",
        "9223372036854775807",  # Int64.MAX
        "2",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 30: Division near negative Int64 limit
    run_benchmark_floor_divide(
        "Division near negative Int64 limit",
        "-9223372036854775807",  # Near Int64.MIN
        "2",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === CASES WITH SPECIFIC REMAINDERS (FLOOR VS TRUNCATE DIFFERENCES) ===

    # Case 31: Division where floor differs from truncate (negative/positive)
    run_benchmark_floor_divide(
        "Division where floor differs from truncate (negative/positive)",
        "-10",
        "3",  # -10 ÷ 3 = -3.33... => -4 (floor) vs -3 (truncate)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 32: Division where floor differs from truncate (positive/negative)
    run_benchmark_floor_divide(
        "Division where floor differs from truncate (positive/negative)",
        "10",
        "-3",  # 10 ÷ -3 = -3.33... => -4 (floor) vs -3 (truncate)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 33: Large division where floor differs from truncate
    run_benchmark_floor_divide(
        "Large division where floor differs from truncate",
        "-" + "9" * 50,
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === BOUNDARY CASES ===

    # Case 34: Division with divisor just below dividend
    run_benchmark_floor_divide(
        "Division with divisor just below dividend",
        "1000",
        "999",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 35: Division with negative divisor just below negative dividend
    run_benchmark_floor_divide(
        "Division with negative divisor just below negative dividend",
        "-1000",
        "-999",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 36: Division where dividend is one less than divisor multiple
    run_benchmark_floor_divide(
        "Division where dividend is one less than divisor multiple",
        "11",  # 11 = 3*4 - 1
        "3",  # 11 ÷ 3 = 3.67 => 3 (floor)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 37: Division where negative dividend is one more than divisor multiple
    run_benchmark_floor_divide(
        "Division where negative dividend is one more than divisor multiple",
        "-11",  # -11 = -3*4 + 1
        "3",  # -11 ÷ 3 = -3.67 => -4 (floor)
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === POWERS AND PATTERNS ===

    # Case 38: Division with exact powers of 10
    run_benchmark_floor_divide(
        "Division with exact powers of 10",
        "1" + "0" * 20,  # 10^20
        "1" + "0" * 5,  # 10^5
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 39: Division of repeated digits (positive)
    run_benchmark_floor_divide(
        "Division of repeated digits (positive)",
        "9" * 30,  # 30 nines
        "9" * 15,  # 15 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 40: Division of repeated digits (negative dividend)
    run_benchmark_floor_divide(
        "Division of repeated digits (negative dividend)",
        "-" + "9" * 30,  # -30 nines
        "9" * 15,  # 15 nines
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 41: Division with extremely large dividend and small divisor
    run_benchmark_floor_divide(
        "Extreme large dividend and small divisor",
        "9" * 100,  # 100 nines
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 42: Division with extremely large negative dividend and small divisor
    run_benchmark_floor_divide(
        (
            "Extreme large negative dividend and small divisor (100 digits vs 1"
            " digit)"
        ),
        "-" + "9" * 100,  # -100 nines
        "3",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 43: Division with powers of 2
    run_benchmark_floor_divide(
        "Division with powers of 2",
        "1" + "0" * 50,  # 10^50
        "256",  # 2^8
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # === MORE COMPLEX CASES ===

    # Case 44: Division yielding a single-digit result
    run_benchmark_floor_divide(
        "Division yielding a single-digit result",
        "123456789",
        "123456780",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 45: Division with random large numbers
    run_benchmark_floor_divide(
        "Division with random large numbers (52 digits vs 20 digits)",
        "8675309123456789098765432112345678909876543211234567",
        "12345678901234567890",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 46: Division of very large numbers with different signs
    run_benchmark_floor_divide(
        (
            "Division of very large numbers with different signs (52 digits vs"
            " 20 digits)"
        ),
        "-8675309123456789098765432112345678909876543211234567",
        "12345678901234567890",
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 47: Division with around 50 digits and divisor just below dividend
    run_benchmark_floor_divide(
        (
            "Division with around 50 digits divisor just below dividend (50"
            " digits vs 48 digits)"
        ),
        "12345" * 10,
        "6789" * 12,
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 48: Division of very large repeated digits
    run_benchmark_floor_divide(
        "Division of very large repeated digits (300 digits vs 200 digits)",
        "990132857498314692374162398217" * 10,  # 30 * 10 = 300 digits
        "85172390413429847239" * 10,  # 20 * 10 = 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 49: Division of large numbers with different signs
    run_benchmark_floor_divide(
        (
            "Division of large numbers with different signs (270 digits vs 135"
            " digits)"
        ),
        "-" + "123456789" * 30,
        "987654321" * 15,
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 50: Division of very large numbers with different signs
    run_benchmark_floor_divide(
        (
            "Division of very large numbers with different signs (2250 digits"
            " vs 900 digits)"
        ),
        "123456789" * 250,
        "-" + "987654321" * 100,
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 51: Division with 500-digit dividend and 200-digit divisor (positive/positive)
    run_benchmark_floor_divide(
        (
            "Division with 500-digit dividend and 200-digit divisor"
            " (positive/positive)"
        ),
        "1" + "7" * 499,  # 500 digits
        "9" + "8" * 199,  # 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 52: Division with 500-digit dividend and 200-digit divisor (negative/positive)
    run_benchmark_floor_divide(
        (
            "Division with 500-digit dividend and 200-digit divisor"
            " (negative/positive)"
        ),
        "-" + "1" + "7" * 499,  # 500 digits
        "9" + "8" * 199,  # 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 53: Division with 500-digit dividend and 200-digit divisor (positive/negative)
    run_benchmark_floor_divide(
        (
            "Division with 500-digit dividend and 200-digit divisor"
            " (positive/negative)"
        ),
        "1" + "7" * 499,  # 500 digits
        "-" + "9" + "8" * 199,  # 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 54: Division with 500-digit dividend and 200-digit divisor (negative/negative)
    run_benchmark_floor_divide(
        (
            "Division with 500-digit dividend and 200-digit divisor"
            " (negative/negative)"
        ),
        "-" + "1" + "7" * 499,  # 500 digits
        "-" + "9" + "8" * 199,  # 200 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 55: Division with alternating pattern (600 digits / 300 digits)
    run_benchmark_floor_divide(
        "Division with alternating pattern (600 digits / 300 digits)",
        "1010101010" * 60,  # Alternating 1s and 0s, 600 digits
        "9090909090" * 30,  # Alternating 9s and 0s, 300 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 56: Division with repeating pattern of primes (700 digits / 350 digits)
    run_benchmark_floor_divide(
        "Division with repeating pattern of primes (700 digits / 350 digits)",
        "2357111317" * 70,  # Primes pattern, 700 digits
        "1931374143" * 35,  # Another primes pattern, 350 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 57: Division with random-like 800-digit number by 400-digit number (negative)
    run_benchmark_floor_divide(
        "Division with random-like 800-digit by 400-digit number (negative)",
        (  # 800 digits, π & e digits
            "-314159265358979323846264338327950288419716939937510"
            "582097494459230781640628620899862803482534211706798214808651"
            "328230664709384460955058223172535940812848111745028410270193"
            "852110555964462294895493038196442881097566593344612847564823"
            "378678316527120190914564856692346034861045432664821339360726"
            "024914127372458700660631558817488152092096282925409171536436"
            "789259036001133053054882046652138414695194151160943305727036"
            "575959195309218611738193261179310511854807446237996274956735"
            "188575272489122793818301194912983367336244065664308602139494"
            "639522473719070217986094370277053921717629317675238467481846"
            "766940513200056812714526356082778577134275778960917363717872"
            "146844090122495343014654958537105079227968925892354201995611"
        ),
        (  # 400 digits, e digits
            "271828182845904523536028747135266249775724709369995"
            "95749669676277240766303535475945713821785251664274"
            "27466391932003059921817413596629043572900334295260"
            "59563073813232862794349076323382988075319525101901"
            "15738341879307021540891499348841675092447614606680"
            "82264800168477411853742345442437107539077744992069"
            "55170276183860626133138458300075204493382656029760"
            "67371132007093287091274437470472306969772093101416"
            "92836819025515108657463772111252389784425056953696"
            "77078544996996794686445490598793163688923009879312"
            "77361782154249992295763514822082698951936680331825"
            "28869398496465105820939239829488793320362509443117"
        ),
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 58: Division with 1000-digit dividend near power of 10 and 300-digit divisor
    run_benchmark_floor_divide(
        (
            "Division with 1000-digit dividend near power of 10 and 300-digit"
            " divisor"
        ),
        "9" * 999 + "1",  # 10^1000 - 9...9 + 1 (1000 digits)
        "3" * 300,  # 300 threes
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 59: Division with 1200-digit by 400-digit (exact division, power of 2)
    run_benchmark_floor_divide(
        "Division with 1200-digit by 400-digit (exact division, power of 2)",
        "2" * 1200,  # 1200 twos
        "2" * 400,  # 400 twos
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Case 60: Division with extremely large 1500-digit number by large 500-digit number
    run_benchmark_floor_divide(
        "Division with extremely large 1500-digit by large 500-digit number",
        "7" + "3" * 1499,  # 1500 digits
        "5" + "7" * 499,  # 500 digits
        iterations,
        log_file,
        speedup_factors,
        bigint2_speedup_factors,
    )

    # Calculate average speedup factors (ignoring any cases that might have failed)
    if len(speedup_factors) > 0:
        var sum_speedup: Float64 = 0.0
        for i in range(len(speedup_factors)):
            sum_speedup += speedup_factors[i]
        var average_speedup = sum_speedup / Float64(len(speedup_factors))

        var sum_speedup2: Float64 = 0.0
        for i in range(len(bigint2_speedup_factors)):
            sum_speedup2 += bigint2_speedup_factors[i]
        var average_speedup2 = sum_speedup2 / Float64(
            len(bigint2_speedup_factors)
        )

        # Display summary
        log_print("\n=== BigInt Floor Division Benchmark Summary ===", log_file)
        log_print(
            "Benchmarked:              "
            + String(len(speedup_factors))
            + " different division cases",
            log_file,
        )
        log_print(
            "Each case ran:            " + String(iterations) + " iterations",
            log_file,
        )
        log_print(
            "BigInt avg speedup:       " + String(average_speedup) + "×",
            log_file,
        )
        log_print(
            "BigInt2 avg speedup:      " + String(average_speedup2) + "×",
            log_file,
        )

        # List all speedup factors
        log_print("\nIndividual speedup factors:", log_file)
        for i in range(len(speedup_factors)):
            log_print(
                String("Case {}: BigInt {}× | BigInt2 {}×").format(
                    i + 1,
                    round(speedup_factors[i], 2),
                    round(bigint2_speedup_factors[i], 2),
                ),
                log_file,
            )
    else:
        log_print("\nNo valid benchmark cases were completed", log_file)

    # Close the log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
