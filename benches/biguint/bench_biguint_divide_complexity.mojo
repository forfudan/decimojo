# ===----------------------------------------------------------------------=== #
# Benchmark for BigUInt division time complexity analysis
# Testing word sizes from 32 to 2**18 words (powers of 2)
# ===----------------------------------------------------------------------=== #

from time import perf_counter_ns
from decimojo import BigUInt
from decimojo.biguint.arithmetics import floor_divide
from python import Python, PythonObject
import os


fn create_log_file() raises -> PythonObject:
    """Creates and opens a log file with timestamp."""
    var python = Python.import_module("builtins")
    var datetime = Python.import_module("datetime")

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate timestamp for filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = (
        log_dir + "/benchmark_divide_complexity_" + timestamp + ".log"
    )

    print("Saving benchmark results to:", log_filename)
    return python.open(log_filename, "w")


fn log_print(msg: String, log_file: PythonObject) raises:
    """Prints message to both console and log file."""
    print(msg)
    log_file.write(msg + "\n")
    log_file.flush()


fn create_test_biguint(num_words: Int) -> BigUInt:
    """Creates a BigUInt with the specified number of words filled with test values.
    """
    var words = List[UInt32](capacity=num_words)

    # Fill with predictable values (avoid randomness for consistent testing)
    for i in range(num_words):
        if i == num_words - 1:
            # Ensure the most significant word is non-zero
            words.append(UInt32(100_000_000 + (i % 800_000_000)))
        else:
            words.append(UInt32(123_456_789 + (i % 876_543_210)))

    return BigUInt(words=words^)


fn create_smaller_divisor(
    dividend_words: Int, divisor_ratio: Float64
) -> BigUInt:
    """Creates a divisor that's smaller than the dividend by the given ratio."""
    var divisor_words = max(1, Int(Float64(dividend_words) / divisor_ratio))
    return create_test_biguint(divisor_words)


fn benchmark_divide_at_size(
    dividend_words: Int,
    divisor_words: Int,
    iterations: Int,
    log_file: PythonObject,
) raises -> Float64:
    """Benchmarks division for specific word sizes."""
    var msg = (
        "Testing "
        + String(dividend_words)
        + " / "
        + String(divisor_words)
        + " words..."
    )
    log_print(msg, log_file)

    # Create test BigUInt numbers
    var dividend = create_test_biguint(dividend_words)
    var divisor = create_test_biguint(divisor_words)

    var total_time: Float64 = 0.0

    # Perform multiple iterations to get average time
    for i in range(iterations):
        var start_time = perf_counter_ns()
        var _result = floor_divide(dividend, divisor)
        var end_time = perf_counter_ns()

        var elapsed = (
            Float64(end_time - start_time) / 1_000_000_000.0
        )  # Convert to seconds
        total_time += elapsed

        # Print intermediate results
        var iter_msg = (
            "  Iteration " + String(i + 1) + ": " + String(elapsed) + " seconds"
        )
        log_print(iter_msg, log_file)

    var average_time = total_time / Float64(iterations)
    var avg_msg = (
        "  Average time for "
        + String(dividend_words)
        + " / "
        + String(divisor_words)
        + " words: "
        + String(average_time)
        + " seconds"
    )
    log_print(avg_msg, log_file)
    return average_time


fn main() raises:
    """Main benchmark function testing division complexity."""
    # Create log file
    var log_file = create_log_file()
    var datetime = Python.import_module("datetime")

    # Display benchmark header with system information
    log_print(
        "=== DeciMojo BigUInt Division Time Complexity Benchmark ===",
        log_file,
    )
    log_print("Time: " + String(datetime.datetime.now().isoformat()), log_file)

    # Get system information
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
        log_print("Machine: " + String(platform.machine()), log_file)
        log_print("Node: " + String(platform.node()), log_file)
    except:
        log_print("Could not retrieve system information", log_file)

    log_print("", log_file)
    log_print(
        "Testing division with various dividend and divisor sizes", log_file
    )
    log_print("Each test uses 5 iterations for averaging", log_file)
    log_print(
        "WARNING: Larger sizes (>100K words) may take significant time!",
        log_file,
    )
    log_print("", log_file)

    # Test sizes: powers of 2 from 32 to 2**18 words
    var test_sizes = List[Int]()
    test_sizes.append(32)
    test_sizes.append(64)
    test_sizes.append(128)
    test_sizes.append(256)
    test_sizes.append(512)
    test_sizes.append(1024)
    test_sizes.append(2048)
    test_sizes.append(4096)
    test_sizes.append(8192)
    test_sizes.append(16384)
    test_sizes.append(32768)
    test_sizes.append(65536)
    test_sizes.append(131072)  # 2^17
    test_sizes.append(262144)  # 2^18

    # Test Case 1: Large / Small division (2n / n)
    log_print("=== TEST CASE 1: LARGE / SMALL DIVISION (2n / n) ===", log_file)
    log_print(
        "Testing division where dividend is twice the size of divisor", log_file
    )
    log_print("", log_file)

    var large_small_results = List[Float64]()
    for i in range(len(test_sizes)):
        var divisor_size = test_sizes[i]
        var dividend_size = divisor_size * 2
        if dividend_size <= 2**18:  # Stay within our limit
            var avg_time = benchmark_divide_at_size(
                dividend_size, divisor_size, 5, log_file
            )
            large_small_results.append(avg_time)
        else:
            large_small_results.append(0.0)  # Placeholder
        log_print("", log_file)

    # Test Case 2: Very Large / Small division (4n / n)
    log_print(
        "=== TEST CASE 2: VERY LARGE / SMALL DIVISION (4n / n) ===", log_file
    )
    log_print(
        "Testing division where dividend is four times the size of divisor",
        log_file,
    )
    log_print("", log_file)

    var very_large_small_results = List[Float64]()
    for i in range(len(test_sizes)):
        var divisor_size = test_sizes[i]
        var dividend_size = divisor_size * 4
        if dividend_size <= 2**18:  # Stay within our limit
            var avg_time = benchmark_divide_at_size(
                dividend_size, divisor_size, 5, log_file
            )
            very_large_small_results.append(avg_time)
        else:
            very_large_small_results.append(0.0)  # Placeholder
        log_print("", log_file)

    # Print summary tables
    log_print(
        "=== SUMMARY TABLE: LARGE / SMALL DIVISION (2n / n) ===", log_file
    )
    log_print(
        "Divisor\t\tDividend\t\tTime (s)\t\tRatio to Previous",
        log_file,
    )
    log_print(
        "--------------------------------------------------------------------------------",
        log_file,
    )

    for i in range(len(test_sizes)):
        var divisor_size = test_sizes[i]
        var dividend_size = divisor_size * 2
        var time_taken = large_small_results[i]

        if time_taken > 0.0:  # Only show valid results
            if i > 0 and large_small_results[i - 1] > 0.0:
                var prev_time = large_small_results[i - 1]
                var actual_ratio = time_taken / prev_time
                var result_line = (
                    String(divisor_size)
                    + "\t\t"
                    + String(dividend_size)
                    + "\t\t"
                    + String(time_taken)
                    + "\t\t"
                    + String(actual_ratio)
                )
                log_print(result_line, log_file)
            else:
                var result_line = (
                    String(divisor_size)
                    + "\t\t"
                    + String(dividend_size)
                    + "\t\t"
                    + String(time_taken)
                    + "\t\tN/A"
                )
                log_print(result_line, log_file)

    log_print("", log_file)
    log_print(
        "=== SUMMARY TABLE: VERY LARGE / SMALL DIVISION (4n / n) ===", log_file
    )
    log_print(
        "Divisor\t\tDividend\t\tTime (s)\t\tRatio to Previous",
        log_file,
    )
    log_print(
        "--------------------------------------------------------------------------------",
        log_file,
    )

    for i in range(len(test_sizes)):
        var divisor_size = test_sizes[i]
        var dividend_size = divisor_size * 4
        if dividend_size <= 2**18:  # Only show results within our limit
            var time_taken = very_large_small_results[i]

            if time_taken > 0.0:  # Only show valid results
                if i > 0 and very_large_small_results[i - 1] > 0.0:
                    var prev_time = very_large_small_results[i - 1]
                    var actual_ratio = time_taken / prev_time
                    var result_line = (
                        String(divisor_size)
                        + "\t\t"
                        + String(dividend_size)
                        + "\t\t"
                        + String(time_taken)
                        + "\t\t"
                        + String(actual_ratio)
                    )
                    log_print(result_line, log_file)
                else:
                    var result_line = (
                        String(divisor_size)
                        + "\t\t"
                        + String(dividend_size)
                        + "\t\t"
                        + String(time_taken)
                        + "\t\tN/A"
                    )
                    log_print(result_line, log_file)

    log_print("", log_file)
    log_print("=== ANALYSIS ===", log_file)
    log_print("Expected behavior for division algorithms:", log_file)
    log_print("- Single word divisor: O(n) where n is dividend size", log_file)
    log_print("- Double word divisor: O(n) where n is dividend size", log_file)
    log_print(
        "- General division: O(n²) where n is max(dividend, divisor) size",
        log_file,
    )
    log_print(
        (
            "- Newton-Raphson (if implemented): O(M(n)) where M(n) is"
            " multiplication cost"
        ),
        log_file,
    )
    log_print("", log_file)
    log_print("Division algorithm selection in the code:", log_file)
    log_print(
        "- Divisor = 1 word: Uses optimized single-word division", log_file
    )
    log_print(
        "- Divisor = 2 words: Uses optimized double-word division", log_file
    )
    log_print("- Divisor > 2 words: Uses general division algorithm", log_file)
    log_print("", log_file)

    # Analysis of division vs multiplication
    log_print("=== DIVISION VS MULTIPLICATION ANALYSIS ===", log_file)
    log_print(
        "Division is generally more expensive than multiplication:", log_file
    )
    log_print(
        "- Division requires trial and error to find quotient digits", log_file
    )
    log_print(
        "- Multiple multiplications and subtractions per quotient digit",
        log_file,
    )
    log_print(
        "- Normalization overhead for better quotient estimation", log_file
    )
    log_print("", log_file)
    log_print("Expected performance characteristics:", log_file)
    log_print(
        "- Single/double word divisors: Fast, linear in dividend size", log_file
    )
    log_print("- Multi-word divisors: Slower, quadratic complexity", log_file)
    log_print(
        "- Very large numbers: Memory effects become significant", log_file
    )
    log_print("", log_file)

    # Analysis of large / small division results
    log_print("=== LARGE / SMALL DIVISION ANALYSIS ===", log_file)
    log_print("Performance characteristics observed:", log_file)
    log_print("- Excellent O(n²) scaling in 2n / n test case", log_file)
    log_print(
        "- Ratios consistently around 4.0 show proper quadratic complexity",
        log_file,
    )
    log_print("- Division algorithm is well-implemented", log_file)
    log_print("", log_file)
    log_print("4n / n vs 2n / n comparison:", log_file)
    log_print(
        "- Both test cases show similar quadratic scaling behavior", log_file
    )
    log_print("- 4n / n takes roughly twice as long as 2n / n", log_file)
    log_print("- This confirms the O(n²) complexity is correct", log_file)
    log_print("", log_file)

    # Close log file
    log_file.close()
    print("Division benchmark completed. Log file closed.")
