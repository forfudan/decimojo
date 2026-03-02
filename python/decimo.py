"""decimo: Arbitrary-precision decimal arithmetic for Python, powered by Mojo.

Usage:
    from decimo import Decimal

    a = Decimal("1.5")
    b = Decimal("2.3")
    print(a + b)  # 3.8
"""

from _decimo import BigDecimal as _BigDecimal


class Decimal:
    """Arbitrary-precision decimal number.

    This is a thin Python wrapper around decimo's Mojo-native BigDecimal type.
    All heavy arithmetic is performed in Mojo at near-native speed.
    """

    __slots__ = ("_inner",)

    def __init__(self, value="0"):
        if isinstance(value, Decimal):
            self._inner = value._inner
        elif isinstance(value, _BigDecimal):
            self._inner = value
        else:
            self._inner = _BigDecimal(str(value))

    # --- String ---

    def __str__(self):
        return self._inner.to_string()

    def __repr__(self):
        return self._inner.to_repr()

    # --- Arithmetic ---

    def __add__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        result = Decimal.__new__(Decimal)
        result._inner = self._inner.add(other._inner)
        return result

    def __radd__(self, other):
        return Decimal(other).__add__(self)

    def __sub__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        result = Decimal.__new__(Decimal)
        result._inner = self._inner.sub(other._inner)
        return result

    def __rsub__(self, other):
        return Decimal(other).__sub__(self)

    def __mul__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        result = Decimal.__new__(Decimal)
        result._inner = self._inner.mul(other._inner)
        return result

    def __rmul__(self, other):
        return Decimal(other).__mul__(self)

    def __neg__(self):
        result = Decimal.__new__(Decimal)
        result._inner = self._inner.neg()
        return result

    def __abs__(self):
        result = Decimal.__new__(Decimal)
        result._inner = self._inner.abs_()
        return result

    def __pos__(self):
        return self  # no-op

    # --- Comparison ---

    def __eq__(self, other):
        if not isinstance(other, Decimal):
            try:
                other = Decimal(other)
            except Exception:
                return NotImplemented
        return self._inner.eq(other._inner)

    def __lt__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        return self._inner.lt(other._inner)

    def __le__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        return self._inner.le(other._inner)

    def __gt__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        return not self._inner.le(other._inner)

    def __ge__(self, other):
        if not isinstance(other, Decimal):
            other = Decimal(other)
        return not self._inner.lt(other._inner)

    def __ne__(self, other):
        return not self.__eq__(other)

    def __bool__(self):
        return str(self) != "0"


# Also expose as BigDecimal for users who prefer the full name
BigDecimal = Decimal
