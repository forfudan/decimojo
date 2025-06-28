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
Implement structs and functions for tests.
"""

import tomlmojo


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

    fn __moveinit__(out self, owned other: Self):
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


fn load_test_cases(
    file_path: String, table_name: String, has_expected_value: Bool = True
) raises -> List[TestCase]:
    """Load test cases from a TOML file for a specific table."""
    var toml = tomlmojo.parse_file(file_path)
    var test_cases = List[TestCase]()

    # Get array of test cases
    var cases_array = toml.get_array_of_tables(table_name)

    for i in range(len(cases_array)):
        var case_table = cases_array[i]
        var expected_value = case_table[
            "expected"
        ].as_string() if has_expected_value else String("")
        test_cases.append(
            TestCase(
                case_table["a"].as_string(),
                case_table["b"].as_string(),
                expected_value,
                case_table["description"].as_string(),
            )
        )

    return test_cases


fn load_test_cases(
    toml: tomlmojo.parser.TOMLDocument, table_name: String
) raises -> List[TestCase]:
    """Load test cases from a TOMLDocument."""
    # Get array of test cases
    var cases_array = toml.get_array_of_tables(table_name)

    var test_cases = List[TestCase]()
    for case_table in cases_array:
        test_cases.append(
            TestCase(
                case_table["a"].as_string(),
                case_table["b"].as_string(),
                case_table["expected"].as_string(),
                case_table["description"].as_string(),
            )
        )

    return test_cases
