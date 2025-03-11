# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimal/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #

"""
DeciMojo: A fixed-point decimal arithmetic library in Mojo.

You can import a list of useful objects in one line, e.g., 

```mojo
from decimojo import decimojo, dm, Decimal, D
```

where `decimojo` is the module itself, `dm` is an alias for the module, 
`Decimal` is the `Decimal` type, and `D` is an alias for the `Decimal` type.
"""

import decimojo
import decimojo as dm

from .decimal import Decimal
from .decimal import Decimal as D

from .rounding_mode import RoundingMode

alias ROUND_DOWN = RoundingMode.DOWN
alias ROUND_HALF_UP = RoundingMode.HALF_UP
alias ROUND_HALF_EVEN = RoundingMode.HALF_EVEN
alias ROUND_UP = RoundingMode.UP

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
from .logic import greater, greater_equal, less, less_equal, equal, not_equal
