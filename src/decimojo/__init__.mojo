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
DeciMojo: A fixed-point decimal arithmetic library in Mojo.

You can import a list of useful objects in one line, e.g., 

```mojo
from decimojo.prelude import dm, Decimal, RoundingMode
```
"""

from .decimal import Decimal

from .rounding_mode import RoundingMode

from .arithmetics import (
    add,
    subtract,
    absolute,
    negative,
    multiply,
    true_divide,
)

from .comparison import (
    greater,
    greater_equal,
    less,
    less_equal,
    equal,
    not_equal,
)

from .exponential import power, root, sqrt, exp, ln

from .rounding import round

from .special import (
    factorial,
)
