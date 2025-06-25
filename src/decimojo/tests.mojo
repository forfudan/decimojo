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


struct TestCase(Copyable, Movable):
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
        self.description = description + "\nx1 = " + self.a + "\nx2 = " + self.b

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
