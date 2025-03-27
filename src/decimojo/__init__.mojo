# ===----------------------------------------------------------------------=== #
# DeciMojo: A fixed-point decimal arithmetic library in Mojo
# https://github.com/forfudan/decimojo
#
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
from decimojo import Decimal, BigInt, RoundingMode
```
"""

# Core types
from .decimal.decimal import Decimal
from .bigint.bigint import BigInt, BInt
from .biguint.biguint import BigUInt
from .rounding_mode import RoundingMode

# Core functions
from .decimal.arithmetics import (
    add,
    subtract,
    absolute,
    negative,
    multiply,
    divide,
    truncate_divide,
    modulo,
)
from .decimal.comparison import (
    greater,
    greater_equal,
    less,
    less_equal,
    equal,
    not_equal,
)
from .decimal.exponential import power, root, sqrt, exp, ln, log, log10
from .decimal.rounding import round, quantize
from .decimal.special import factorial
