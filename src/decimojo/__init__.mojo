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
DeciMojo: A comprehensive decimal mathematics library for Mojo.

You can import a list of useful objects in one line, e.g., 

```mojo
from decimojo import Decimal, BigInt10, RoundingMode
```
"""

# Core types
from .decimal128.decimal128 import Decimal128, Dec128
from .bigint10.bigint10 import BigInt10, BInt
from .biguint.biguint import BigUInt, BUInt
from .bigdecimal.bigdecimal import BigDecimal, BDec, Decimal
from .rounding_mode import (
    RoundingMode,
    ROUND_DOWN,
    ROUND_HALF_UP,
    ROUND_HALF_EVEN,
    ROUND_UP,
)

# Core functions
from .bigint2.number_theory import gcd, lcm, extended_gcd, mod_inverse, mod_pow
