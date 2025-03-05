# ===----------------------------------------------------------------------=== #
# Distributed under the Apache 2.0 License with LLVM Exceptions.
# See LICENSE and the LLVM License for more information.
# https://github.com/forFudan/decimal/blob/main/LICENSE
# ===----------------------------------------------------------------------=== #

"""
DeciMojo - Correctly-rounded, fixed-point Decimal library for Mojo.
"""

from .decimal import Decimal
from .rounding_mode import RoundingMode
from .maths import add, subtract, true_divide, power, sqrt, round, absolute
from .logic import greater, greater_equal, less, less_equal, equal, not_equal
