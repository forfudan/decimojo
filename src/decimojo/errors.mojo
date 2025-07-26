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

alias OverflowError = DeciMojoError[error_type="OverflowError"]
alias IndexError = DeciMojoError[error_type="IndexError"]
alias KeyError = DeciMojoError[error_type="KeyError"]
alias ZeroDivisionError = DeciMojoError[error_type="ZeroDivisionError"]

alias HEADER_OF_ERROR_MESSAGE = """
---------------------------------------------------------------------------
DeciMojoError                             Traceback (most recent call last)
"""


struct DeciMojoError[error_type: String](Stringable, Writable):
    var file: String
    var function: String
    var message: Optional[String]

    fn __init__(
        out self,
        file: String,
        function: String,
        message: Optional[String],
    ):
        self.file = file
        self.function = function
        self.message = message

    fn __str__(self) -> String:
        if self.message is None:
            return (
                "Traceback (most recent call last):\n"
                + '  File "'
                + self.file
                + '"'
                + " in "
                + self.function
                + "\n\n"
            )

        else:
            return (
                "Traceback (most recent call last):\n"
                + '  File "'
                + self.file
                + '"'
                + " in "
                + self.function
                + "\n\n"
                + String(error_type)
                + ": "
                + self.message.value()
                + "\n"
            )

    fn write_to[W: Writer](self, mut writer: W):
        writer.write('File "')
        writer.write(self.file)
        writer.write('"')
        writer.write(" in ")
        writer.write(self.function)
        if self.message is None:
            writer.write("\n\n")
        else:
            writer.write("\n\n")
            writer.write(error_type)
            writer.write(": ")
            writer.write(self.message.value())
            writer.write('"')
            writer.write("\n")
