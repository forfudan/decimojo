"""Verify BigDecimal round-trip through Mojo-Python bindings."""

import sys
from pathlib import Path

# Add python/ directory to sys.path so `import decimo` resolves to decimo.py
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from decimo import Decimal, BigDecimal

print("=== decimo mojo4py Phase 0 ===")
print()

# --- Alias test ---
assert Decimal is BigDecimal, "Decimal should be BigDecimal"
print("[PASS] Decimal is BigDecimal")

# --- Construction from string ---
d = Decimal("3.14159265358979323846")
print(f"[PASS] str  = {d}")
print(f"[PASS] repr = {repr(d)}")
print()

# --- Round-trip ---
s = "123456789.987654321"
d2 = Decimal(s)
assert str(d2) == s, f"Round-trip failed: expected {s!r}, got {str(d2)!r}"
print(f"[PASS] Round-trip: str(Decimal({s!r})) == {s!r}")

# --- Arithmetic ---
a = Decimal("1.5")
b = Decimal("2.3")
print(f"[PASS] {a} + {b} = {a + b}")
print(f"[PASS] {a} - {b} = {a - b}")
print(f"[PASS] {a} * {b} = {a * b}")
print(f"[PASS] -{a} = {-a}")
print(f"[PASS] abs({-a}) = {abs(-a)}")
print()

# --- Comparison ---
assert Decimal("1.5") == Decimal("1.5"), "equality failed"
assert Decimal("1.5") < Decimal("2.3"), "less-than failed"
assert Decimal("2.3") > Decimal("1.5"), "greater-than failed"
assert Decimal("1.5") <= Decimal("1.5"), "less-equal failed"
assert Decimal("1.5") >= Decimal("1.5"), "greater-equal failed"
assert Decimal("1.5") != Decimal("2.3"), "not-equal failed"
print("[PASS] All comparisons")

# --- Integer input ---
d3 = Decimal("42")
assert str(d3) == "42", f"Int input failed: got {str(d3)!r}"
print(f"[PASS] Decimal('42') = {d3}")

# --- Large number ---
big = Decimal("99999999999999999999999999999999999999.123456789")
print(f"[PASS] Large number: {big}")
print()

# --- Mixed arithmetic with auto-convert ---
result = Decimal("10") + Decimal("5")
assert str(result) == "15", f"Mixed arith failed: got {str(result)!r}"
print(f"[PASS] Decimal('10') + Decimal('5') = {result}")
print()

print("=== All Phase 0 tests passed! ===")
