# ===----------------------------------------------------------------------=== #
# Benchmark for BigUInt multiplication time complexity analysis
# Testing word sizes from 32 to 16384 words (powers of 2)
# ===----------------------------------------------------------------------=== #

from time import perf_counter_ns
from decimojo import BigUInt
from decimojo.biguint.arithmetics import multiply
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
        log_dir + "/benchmark_multiply_complexity_" + timestamp + ".log"
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


fn benchmark_multiply_at_size(
    num_words: Int, iterations: Int, log_file: PythonObject
) raises -> Float64:
    """Benchmarks multiplication for a specific word size."""
    var msg = "Testing " + String(num_words) + " words..."
    log_print(msg, log_file)

    # Create two test BigUInt numbers with the specified number of words
    var x = create_test_biguint(num_words)
    var y = create_test_biguint(num_words)

    var total_time: Float64 = 0.0

    # Perform multiple iterations to get average time
    for i in range(iterations):
        var start_time = perf_counter_ns()
        var _result = multiply(x, y)
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
        + String(num_words)
        + " words: "
        + String(average_time)
        + " seconds"
    )
    log_print(avg_msg, log_file)
    return average_time


fn main() raises:
    """Main benchmark function testing multiplication complexity."""
    # Create log file
    var log_file = create_log_file()
    var datetime = Python.import_module("datetime")

    # Display benchmark header with system information
    log_print(
        "=== DeciMojo BigUInt Multiplication Time Complexity Benchmark ===",
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
        "Testing word sizes from 32 to 262144 words (powers of 2)", log_file
    )
    log_print("Each test uses 5 iterations for averaging", log_file)
    log_print(
        "WARNING: Larger sizes (>100K words) may take significant time!",
        log_file,
    )
    log_print("", log_file)

    # Test sizes: powers of 2 from 32 to 262144
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
    test_sizes.append(131072)
    test_sizes.append(262144)

    var results = List[Float64]()

    # Run benchmarks for each size
    for i in range(len(test_sizes)):
        var size = test_sizes[i]
        var avg_time = benchmark_multiply_at_size(size, 5, log_file)
        results.append(avg_time)
        log_print("", log_file)

    # Print summary table
    log_print("=== SUMMARY TABLE ===", log_file)
    log_print(
        "Words\t\tTime (s)\t\tRatio to Previous\tTheoretical O(n^1.585)",
        log_file,
    )
    log_print(
        "--------------------------------------------------------------------------------",
        log_file,
    )

    for i in range(len(test_sizes)):
        var size = test_sizes[i]
        var time_taken = results[i]

        if i > 0:
            var prev_time = results[i - 1]
            var actual_ratio = time_taken / prev_time

            # Calculate theoretical ratio for Karatsuba (O(n^1.585))
            var size_ratio = Float64(size) / Float64(test_sizes[i - 1])
            var theoretical_ratio = size_ratio**1.585

            var result_line = (
                String(size)
                + "\t\t"
                + String(time_taken)
                + "\t\t"
                + String(actual_ratio)
                + "\t\t"
                + String(theoretical_ratio)
            )
            log_print(result_line, log_file)
        else:
            var result_line = (
                String(size) + "\t\t" + String(time_taken) + "\t\tN/A\t\t\tN/A"
            )
            log_print(result_line, log_file)

    log_print("", log_file)
    log_print("=== ANALYSIS ===", log_file)
    log_print("Expected behavior:", log_file)
    log_print("- For sizes <= 64 words: School multiplication O(n²)", log_file)
    log_print(
        "- For sizes > 64 words: Karatsuba multiplication O(n^1.585)", log_file
    )
    log_print("", log_file)
    log_print(
        "If ratios are close to 4.0, it suggests O(n²) complexity", log_file
    )
    log_print(
        "If ratios are close to 3.0, it suggests O(n^1.585) complexity",
        log_file,
    )
    log_print(
        "If ratios are much larger, there may be memory/cache effects", log_file
    )
    log_print("", log_file)

    # Additional analysis
    log_print("=== DETAILED ANALYSIS ===", log_file)
    log_print(
        "The multiplication function uses the following threshold:", log_file
    )
    log_print("- CUTOFF_KARATSUBA: 64 words", log_file)
    log_print("", log_file)
    log_print("Expected algorithm usage by size:", log_file)
    log_print("- 32-64 words: School multiplication O(n²)", log_file)
    log_print("- 64+ words: Karatsuba multiplication O(n^1.585)", log_file)
    log_print("", log_file)

    # Calculate some statistics
    var max_ratio: Float64 = 0.0
    var min_ratio: Float64 = 1000.0
    var avg_ratio: Float64 = 0.0
    var count: Int = 0

    for i in range(1, len(results)):
        var ratio = results[i] / results[i - 1]
        if ratio > max_ratio:
            max_ratio = ratio
        if ratio < min_ratio:
            min_ratio = ratio
        avg_ratio += ratio
        count += 1

    avg_ratio = avg_ratio / Float64(count)

    log_print("Performance statistics:", log_file)
    log_print("- Maximum ratio: " + String(max_ratio), log_file)
    log_print("- Minimum ratio: " + String(min_ratio), log_file)
    log_print("- Average ratio: " + String(avg_ratio), log_file)
    log_print("", log_file)

    # Analysis of very large sizes
    log_print("=== LARGE SIZE ANALYSIS ===", log_file)
    if len(results) > 10:  # If we have results for 32768+ words
        log_print("Performance for very large sizes (32768+ words):", log_file)
        for i in range(10, len(results)):
            var size = test_sizes[i]
            var time_taken = results[i]
            var ratio = results[i] / results[i - 1]
            log_print(
                "- "
                + String(size)
                + " words: "
                + String(time_taken)
                + "s (ratio: "
                + String(ratio)
                + ")",
                log_file,
            )
        log_print("", log_file)
        log_print("Notes for very large sizes:", log_file)
        log_print(
            (
                "- Ratios significantly > 3.0 may indicate memory/cache"
                " bottlenecks"
            ),
            log_file,
        )
        log_print(
            "- Consider FFT-based algorithms for sizes > 100K words", log_file
        )
        log_print("- Memory allocation becomes a significant factor", log_file)
    log_print("", log_file)

    # Close log file
    log_file.close()
    print("Benchmark completed. Log file closed.")
