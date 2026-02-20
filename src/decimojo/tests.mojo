# ===----------------------------------------------------------------------=== #
# Copyright 2025 Yuhao Zhu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

"""
Shared infrastructure for DeciMojo tests and benchmarks.

Provides:
- Test case and benchmark case loading from TOML files (via tomlmojo)
- Pattern expansion: {C,N} repeats string C exactly N times
- Log file management and formatted output (console + log)
- Summary statistics reporting for benchmarks

TOML format for test cases:
    [[table_name]]
    a = "42"
    b = "58"                    # omitted for unary operations
    expected = "100"
    description = "Simple addition"

TOML format for benchmark cases:
    [config]
    iterations = 1000           # optional, default 1000

    [[cases]]
    name = "Small addition"
    a = "42"
    b = "58"                    # optional for unary operations

Pattern expansion in string values:
    {C,N}  — repeat string C exactly N times
    Examples:
        "42"            → "42"
        "{9,100}"       → "999...9" (100 nines)
        "1{0,28}"       → "10000000000000000000000000000"
        "-{9,50}"       → "-999...9"
        "{9,999}1"      → "999...91"
        "{123456789,5}" → "123456789" repeated 5 times
"""

import tomlmojo
from python import Python, PythonObject
from collections import List
import os


# ===----------------------------------------------------------------------=== #
# TestCase
# ===----------------------------------------------------------------------=== #


struct TestCase(Copyable, Movable, Stringable, Writable):
    """Structure to hold test case data.

    Attributes:
        a: The first input value as numeric string.
        b: The second input value as numeric string.
        expected: The expected output value as numeric string.
        description: A description of the test case.
    """

    var a: String
    var b: String
    var expected: String
    var description: String

    fn __init__(
        out self, a: String, b: String, expected: String, description: String
    ):
        self.a = a
        self.b = b
        self.expected = expected
        self.description = (
            description + " (a = " + self.a + ", b = " + self.b + ")"
        )

    fn __copyinit__(out self, other: Self):
        self.a = other.a
        self.b = other.b
        self.expected = other.expected
        self.description = other.description

    fn __moveinit__(out self, deinit other: Self):
        self.a = other.a^
        self.b = other.b^
        self.expected = other.expected^
        self.description = other.description^

    fn __str__(self) -> String:
        return (
            "TestCase(a: "
            + self.a
            + ", b: "
            + self.b
            + ", expected: "
            + self.expected
            + ", description: "
            + self.description
            + ")"
        )

    fn write_to[T: Writer](self, mut writer: T):
        writer.write("TestCase:\n")
        writer.write("  a: " + self.a + "\n")
        writer.write("  b: " + self.b + "\n")
        writer.write("  expected: " + self.expected + "\n")
        writer.write("  description: " + self.description + "\n")


# ===----------------------------------------------------------------------=== #
# BenchCase
# ===----------------------------------------------------------------------=== #


struct BenchCase(Copyable, Movable, Stringable, Writable):
    """A benchmark case with a name and one or two operands."""

    var name: String
    var a: String
    var b: String

    fn __init__(out self, name: String, a: String, b: String = ""):
        self.name = name
        self.a = a
        self.b = b

    fn __copyinit__(out self, other: Self):
        self.name = other.name
        self.a = other.a
        self.b = other.b

    fn __moveinit__(out self, deinit other: Self):
        self.name = other.name^
        self.a = other.a^
        self.b = other.b^

    fn __str__(self) -> String:
        return (
            "BenchCase(name='"
            + self.name
            + "', a='"
            + self.a
            + "', b='"
            + self.b
            + "')"
        )

    fn write_to[T: Writer](self, mut writer: T):
        writer.write(self.__str__())


# ===----------------------------------------------------------------------=== #
# Pattern expansion
# ===----------------------------------------------------------------------=== #


fn expand_value(s: String) raises -> String:
    """Expand {C,N} repeat patterns in a string.

    Scans the string for `{C,N}` patterns where C is the string to repeat
    and N is the repeat count. Everything outside braces is kept as literal
    text.

    Args:
        s: The input string, possibly containing {C,N} patterns.

    Returns:
        The expanded string with all patterns resolved.

    Examples:
        "42"            → "42"
        "{9,100}"       → "999...9" (100 nines)
        "1{2,49}"       → "122...2" (1 followed by 49 twos)
        "-{9,50}"       → "-999...9"
        "{9,999}1"      → "999...91"
        "{12345,3}"     → "123451234512345".
    """
    # Fast path: no braces means no pattern
    var brace_pos = s.find("{")
    if brace_pos == -1:
        return s

    var result = String()
    var i = 0
    var s_bytes = s.as_bytes()
    var slen = len(s)

    while i < slen:
        var ch = chr(Int(s_bytes[i]))
        if ch == "{":
            # Find closing brace
            var close = s.find("}", i)
            if close == -1:
                # No closing brace, treat as literal
                result += ch
                i += 1
                continue

            # Extract inner content between braces
            var inner = String(s[i + 1 : close])

            # Find the LAST comma (to handle multi-char repeat strings)
            var comma_pos = -1
            var inner_bytes = inner.as_bytes()
            var inner_len = len(inner)
            var k = inner_len - 1
            while k >= 0:
                if chr(Int(inner_bytes[k])) == ",":
                    comma_pos = k
                    break
                k -= 1

            if comma_pos == -1:
                # No comma found, treat as literal
                result += "{" + inner + "}"
                i = close + 1
                continue

            var pattern = String(inner[:comma_pos])
            var count_str = String(inner[comma_pos + 1 :])
            var count = atol(count_str)

            for _ in range(count):
                result += pattern
            i = close + 1
        else:
            result += ch
            i += 1

    return result


# ===----------------------------------------------------------------------=== #
# TOML loading
# ===----------------------------------------------------------------------=== #


fn parse_file(file_path: String) raises -> tomlmojo.parser.TOMLDocument:
    """Parse a TOML file and return the TOMLDocument."""
    try:
        return tomlmojo.parse_file(file_path)
    except e:
        raise Error(
            "tests.parse_file(): Failed to parse TOML file:",
            file_path,
            "\nTraceback:",
            e,
        )


fn load_test_cases[
    unary: Bool = False
](toml: tomlmojo.parser.TOMLDocument, table_name: String) raises -> List[
    TestCase
]:
    """Load test cases from a TOMLDocument.

    String values are expanded using the {C,N} pattern syntax.

    Parameters:
        unary: Whether the test cases are unary (single operand) or binary.

    Args:
        toml: The TOMLDocument containing the test cases.
        table_name: The name of the table in the TOMLDocument.

    Returns:
        A list of TestCase objects containing the test cases.
    """
    var cases_array = toml.get_array_of_tables(table_name)
    var test_cases = List[TestCase]()

    if unary:
        for case_table in cases_array:
            test_cases.append(
                TestCase(
                    expand_value(case_table["a"].as_string()),
                    "",
                    expand_value(case_table["expected"].as_string()),
                    case_table["description"].as_string(),
                )
            )
    else:
        for case_table in cases_array:
            test_cases.append(
                TestCase(
                    expand_value(case_table["a"].as_string()),
                    expand_value(case_table["b"].as_string()),
                    expand_value(case_table["expected"].as_string()),
                    case_table["description"].as_string(),
                )
            )

    return test_cases^


fn load_bench_cases(toml_path: String) raises -> List[BenchCase]:
    """Load benchmark cases from a TOML file.

    Uses tomlmojo to parse the TOML file. Operand values are expanded
    using the {C,N} pattern syntax.

    Args:
        toml_path: Path to the TOML file (relative to CWD).

    Returns:
        A list of BenchCase objects.
    """
    var doc = parse_file(toml_path)
    var cases_array = doc.get_array_of_tables("cases")
    var cases = List[BenchCase]()

    for case_table in cases_array:
        var name = case_table["name"].as_string()
        var a = expand_value(case_table["a"].as_string())

        # b is optional for unary operations
        var b = String("")
        if "b" in case_table:
            b = expand_value(case_table["b"].as_string())

        cases.append(BenchCase(name, a, b))

    return cases^


fn load_bench_iterations(toml_path: String) raises -> Int:
    """Load the iterations count from TOML config section.

    Args:
        toml_path: Path to the TOML file.

    Returns:
        The iterations count, defaulting to 1000.
    """
    var doc = parse_file(toml_path)
    try:
        var config = doc.get_table("config")
        if "iterations" in config:
            return config["iterations"].as_int()
    except:
        pass
    return 1000


# ===----------------------------------------------------------------------=== #
# Logging
# ===----------------------------------------------------------------------=== #


fn open_log_file(prefix: String) raises -> PythonObject:
    """Create and open a timestamped log file.

    Creates a `./logs/` directory if it doesn't exist, then opens a log
    file with the given prefix and current timestamp.

    Args:
        prefix: Filename prefix (e.g. "benchmark_bigint_add").

    Returns:
        A Python file object opened for writing.
    """
    var python = Python.import_module("builtins")
    var datetime = Python.import_module("datetime")

    # Create logs directory if it doesn't exist
    var log_dir = "./logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Generate timestamped filename
    var timestamp = String(datetime.datetime.now().isoformat())
    var log_filename = log_dir + "/" + prefix + "_" + timestamp + ".log"

    print("Saving benchmark results to:", log_filename)
    return python.open(log_filename, "w")


fn log_print(msg: String, log_file: PythonObject) raises:
    """Print a message to both console and log file.

    Args:
        msg: The message to print.
        log_file: The Python file object to write to.
    """
    print(msg)
    log_file.write(msg + "\n")
    log_file.flush()


# ===----------------------------------------------------------------------=== #
# Header and summary
# ===----------------------------------------------------------------------=== #


fn print_header(title: String, log_file: PythonObject) raises:
    """Print a benchmark header with title and system information.

    Args:
        title: The benchmark title.
        log_file: The Python file object.
    """
    var datetime = Python.import_module("datetime")
    log_print("=== " + title + " ===", log_file)
    log_print("Time: " + String(datetime.datetime.now().isoformat()), log_file)

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


fn print_summary(
    title: String,
    speedup_factors: List[Float64],
    label: String,
    iterations: Int,
    log_file: PythonObject,
) raises:
    """Print benchmark summary with average and per-case speedup factors.

    For benchmarks with a single Mojo implementation vs Python.

    Args:
        title: Summary section title.
        speedup_factors: List of per-case speedup factors.
        label: Label for the Mojo implementation (e.g. "BigUInt").
        iterations: Iterations per case.
        log_file: The Python file object.
    """
    if len(speedup_factors) == 0:
        log_print("\nNo valid benchmark cases were completed", log_file)
        return

    var total: Float64 = 0.0
    for i in range(len(speedup_factors)):
        total += speedup_factors[i]
    var avg = total / Float64(len(speedup_factors))

    log_print("\n=== " + title + " ===", log_file)
    log_print(
        "Benchmarked:         " + String(len(speedup_factors)) + " cases",
        log_file,
    )
    log_print(
        "Iterations per case: " + String(iterations),
        log_file,
    )
    log_print(
        label + " avg speedup: " + String(avg) + "×",
        log_file,
    )

    log_print("\nIndividual speedup factors:", log_file)
    for i in range(len(speedup_factors)):
        log_print(
            String("Case {}: {} {}×").format(
                i + 1, label, round(speedup_factors[i], 2)
            ),
            log_file,
        )


fn print_summary_dual(
    title: String,
    sf1: List[Float64],
    label1: String,
    sf2: List[Float64],
    label2: String,
    iterations: Int,
    log_file: PythonObject,
) raises:
    """Print benchmark summary for two Mojo implementations vs Python.

    For benchmarks comparing two Mojo types (e.g. BigInt + BigInt2).

    Args:
        title: Summary section title.
        sf1: Speedup factors for the first implementation.
        label1: Label for the first implementation (e.g. "BigInt").
        sf2: Speedup factors for the second implementation.
        label2: Label for the second implementation (e.g. "BigInt2").
        iterations: Iterations per case.
        log_file: The Python file object.
    """
    if len(sf1) == 0:
        log_print("\nNo valid benchmark cases were completed", log_file)
        return

    var total1: Float64 = 0.0
    for i in range(len(sf1)):
        total1 += sf1[i]
    var avg1 = total1 / Float64(len(sf1))

    var total2: Float64 = 0.0
    for i in range(len(sf2)):
        total2 += sf2[i]
    var avg2 = total2 / Float64(len(sf2))

    log_print("\n=== " + title + " ===", log_file)
    log_print(
        "Benchmarked:             " + String(len(sf1)) + " cases",
        log_file,
    )
    log_print(
        "Iterations per case:     " + String(iterations),
        log_file,
    )
    log_print(
        label1 + " avg speedup:  " + String(avg1) + "×",
        log_file,
    )
    log_print(
        label2 + " avg speedup: " + String(avg2) + "×",
        log_file,
    )

    log_print("\nIndividual speedup factors:", log_file)
    for i in range(len(sf1)):
        log_print(
            String("Case {}: {} {}× | {} {}×").format(
                i + 1,
                label1,
                round(sf1[i], 2),
                label2,
                round(sf2[i], 2),
            ),
            log_file,
        )
