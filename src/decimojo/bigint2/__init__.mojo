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

"""Sub-package for binary base-2^32 big integer type.

BigInt2 is a signed arbitrary-precision integer that uses base-2^32
representation internally. This is the binary counterpart to BigInt (base-10^9).

Once BigInt2 is stable and performant, the naming plan is:
- BigInt2 → BigInt (the primary big integer type)
- Current BigInt → BigInt10 (kept for decimal-friendly use cases)

Modules:
- bigint2: Core struct with constructors, conversions, dunders
- arithmetics: add, subtract, multiply, divide, modulo, power, shifts
- comparison: compare, greater, less, equal
- exponential: sqrt, isqrt
"""
