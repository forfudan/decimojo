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
Implement error handling for DeciMojo.
"""


struct DeciError:
    var error_type: String
    var message: String
    var function: String
    var file: String
    var line: Int

    fn __init__(
        out self,
        error_type: String,
        message: String,
        function: String,
        file: String,
        line: Int,
    ):
        self.error_type = error_type
        self.message = message
        self.function = function
        self.file = file
        self.line = line

    fn __str__(self) -> String:
        return (
            "Traceback (most recent call last):\n"
            + '  File "'
            + String(self.file)
            + '", line '
            + String(self.line)
            + " in "
            + String(self.function)
            + "\n"
            + String(self.error_type)
            + ": "
            + String(self.message)
            + '"'
        )
