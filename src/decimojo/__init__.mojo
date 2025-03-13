# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimal/blob/main/LICENSE
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

from .maths import (
    add,
    subtract,
    multiply,
    true_divide,
    power,
    sqrt,
    round,
    absolute,
)

from .comparison import (
    greater,
    greater_equal,
    less,
    less_equal,
    equal,
    not_equal,
)
