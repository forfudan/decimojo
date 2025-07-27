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
Implements error handling for DeciMojo.
"""

alias OverflowError = DeciMojoError[error_type="OverflowError"]
"""Type for overflow errors in DeciMojo.

Fields:

file: The file where the error occurred.\\
function: The function where the error occurred.\\
message: An optional message describing the error.\\
previous_error: An optional previous error that caused this error.
"""

alias IndexError = DeciMojoError[error_type="IndexError"]
"""Type for index errors in DeciMojo.

Fields:

file: The file where the error occurred.\\
function: The function where the error occurred.\\
message: An optional message describing the error.\\
previous_error: An optional previous error that caused this error.
"""

alias KeyError = DeciMojoError[error_type="KeyError"]
"""Type for key errors in DeciMojo.

Fields:

file: The file where the error occurred.\\
function: The function where the error occurred.\\
message: An optional message describing the error.\\
previous_error: An optional previous error that caused this error.
"""

alias ZeroDivisionError = DeciMojoError[error_type="ZeroDivisionError"]

"""Type for divided-by-zero errors in DeciMojo.

Fields:

file: The file where the error occurred.\\
function: The function where the error occurred.\\
message: An optional message describing the error.\\
previous_error: An optional previous error that caused this error.
"""

alias ConversionError = DeciMojoError[error_type="ConversionError"]

"""Type for conversion errors in DeciMojo.

Fields:

file: The file where the error occurred.\\
function: The function where the error occurred.\\
message: An optional message describing the error.\\
previous_error: An optional previous error that caused this error.
"""

alias HEADER_OF_ERROR_MESSAGE = """
---------------------------------------------------------------------------
DeciMojoError                             Traceback (most recent call last)
"""


struct DeciMojoError[error_type: String = "DeciMojoError"](
    Stringable, Writable
):
    """Base type for all DeciMojo errors.

    Parameters:
        error_type: The type of the error, e.g., "OverflowError", "IndexError".

    Fields:

    file: The file where the error occurred.\\
    function: The function where the error occurred.\\
    message: An optional message describing the error.\\
    previous_error: An optional previous error that caused this error.
    """

    var file: String
    var function: String
    var message: Optional[String]
    var previous_error: Optional[String]

    fn __init__(
        out self,
        file: String,
        function: String,
        message: Optional[String],
        previous_error: Optional[Error],
    ):
        self.file = file
        self.function = function
        self.message = message
        if previous_error is None:
            self.previous_error = None
        else:
            self.previous_error = "\n".join(
                previous_error.value().as_string_slice().split("\n")[3:]
            )

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
        writer.write("\n")
        writer.write(("-" * 75))
        writer.write("\n")
        writer.write(error_type.ljust(42, " "))
        writer.write("Traceback (most recent call last)\n")
        writer.write('File "')
        writer.write(self.file)
        writer.write('"')
        writer.write(" in ")
        writer.write(self.function)
        if self.message is None:
            writer.write("\n")
        else:
            writer.write("\n\n")
            writer.write(error_type)
            writer.write(": ")
            writer.write(self.message.value())
            writer.write("\n")
        if self.previous_error is not None:
            writer.write("\n")
            writer.write(self.previous_error.value())
