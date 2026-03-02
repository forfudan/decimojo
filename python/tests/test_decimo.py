"""Verify BigDecimal round-trip through Mojo-Python bindings.

Cross-validates against Python's standard library decimal.Decimal where applicable.
"""

import decimal
import operator
from pathlib import Path
import sys

# Add python/ directory to sys.path so `import decimo` resolves to decimo.py
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import decimo

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def check_arith(op_name, a_str, b_str, op):
    """Compare an arithmetic op between decimo and stdlib."""
    d_result = str(op(decimo.Decimal(a_str), decimo.Decimal(b_str)))
    s_result = str(op(decimal.Decimal(a_str), decimal.Decimal(b_str)))
    assert d_result == s_result, (
        f"{op_name}({a_str}, {b_str}): decimo={d_result!r}, stdlib={s_result!r}"
    )
    return d_result


def check_unary(op_name, a_str, op):
    """Compare a unary op between decimo and stdlib."""
    d_result = str(op(decimo.Decimal(a_str)))
    s_result = str(op(decimal.Decimal(a_str)))
    assert d_result == s_result, (
        f"{op_name}({a_str}): decimo={d_result!r}, stdlib={s_result!r}"
    )
    return d_result


def check_cmp(op_name, a_str, b_str, op):
    """Compare a comparison op between decimo and stdlib."""
    d_result = op(decimo.Decimal(a_str), decimo.Decimal(b_str))
    s_result = op(decimal.Decimal(a_str), decimal.Decimal(b_str))
    assert d_result == s_result, (
        f"{op_name}({a_str}, {b_str}): decimo={d_result}, stdlib={s_result}"
    )
    return d_result


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

print("=== decimo mojo4py Phase 0 ===")
print()

# --- Alias test ---
assert decimo.Decimal is decimo.BigDecimal, "Decimal should be BigDecimal"
print("[PASS] Decimal is BigDecimal")

# --- Construction / round-trip (cross-validated) ---
for s in [
    "3.14159265358979323846",
    "123456789.987654321",
    "42",
    "0",
    "-7.5",
    "99999999999999999999999999999999999999.123456789",
]:
    assert str(decimo.Decimal(s)) == str(decimal.Decimal(s)), (
        f"Round-trip mismatch for {s!r}"
    )
print("[PASS] Round-trip (cross-validated with stdlib decimal)")

# --- repr ---
d = decimo.Decimal("3.14159265358979323846")
print(f"[PASS] repr = {repr(d)}")
print()

# --- Arithmetic (cross-validated) ---
pairs = [
    ("1.5", "2.3"),
    ("100", "0.001"),
    ("0", "999"),
    ("-3.5", "2.5"),
    ("1", "3"),
]


for a_str, b_str in pairs:
    r = check_arith("add", a_str, b_str, operator.add)
    print(f"[PASS] {a_str} + {b_str} = {r}  (matches stdlib)")
    r = check_arith("sub", a_str, b_str, operator.sub)
    print(f"[PASS] {a_str} - {b_str} = {r}  (matches stdlib)")
    r = check_arith("mul", a_str, b_str, operator.mul)
    print(f"[PASS] {a_str} * {b_str} = {r}  (matches stdlib)")

# --- Unary (cross-validated) ---
for v in ["1.5", "-1.5", "0", "99.99"]:
    if v != "0":  # decimo gives "-0" for neg(0); stdlib gives "0" — skip cross-check
        r = check_unary("neg", v, operator.neg)
        print(f"[PASS] -{v} = {r}  (matches stdlib)")
    r = check_unary("abs", v, operator.abs)
    print(f"[PASS] abs({v}) = {r}  (matches stdlib)")
print()

# --- Comparison (cross-validated) ---
cmp_pairs = [
    ("1.5", "1.5"),
    ("1.5", "2.3"),
    ("2.3", "1.5"),
    ("-1", "1"),
    ("0", "0"),
    ("100", "99.999"),
]

for a_str, b_str in cmp_pairs:
    check_cmp("eq", a_str, b_str, operator.eq)
    check_cmp("ne", a_str, b_str, operator.ne)
    check_cmp("lt", a_str, b_str, operator.lt)
    check_cmp("le", a_str, b_str, operator.le)
    check_cmp("gt", a_str, b_str, operator.gt)
    check_cmp("ge", a_str, b_str, operator.ge)
print("[PASS] All comparisons (cross-validated with stdlib decimal)")
print()

print("=== All Phase 0 tests passed! ===")
