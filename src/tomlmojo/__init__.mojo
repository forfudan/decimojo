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
A TOML parser for Mojo, implementing the core TOML v1.0 specification.

Supports:
- Basic and literal strings (single-line and multi-line)
- String escape sequences (\\n, \\t, \\r, \\\\, \\", etc.)
- Integers (decimal, hex 0x, octal 0o, binary 0b, underscores)
- Floats (decimal, scientific notation, inf, nan, underscores)
- Signed numbers (+42, -3.14, +inf, -inf)
- Booleans (true, false)
- Arrays ([...])
- Tables ([name]) and arrays of tables ([[name]])
- Comments (#)
"""

from .parser import (
    parse_file,
    parse_string,
    TOMLValue,
    TOMLValueType,
    TOMLDocument,
)
