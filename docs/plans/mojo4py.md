# mojo4py: Exposing decimo to Python via Mojo Bindings

> I use "mojo4py" as the name of this document - it refers to a package *written in Mojo* that is callable *from Python*. The inverse ("py4mojo") would be calling Python from Mojo, which decimo already does in some places.
>
> This name is pretty concise and descriptive. I will use the same "mojo4py" for Mojo Miji when discussing the Mojo-Python inter-operability.

---

## 1. Summary

Modular has introduced a beta mechanism that allows Mojo code to be exposed as a standard CPython extension module (`.so` / `.dylib`). This means a Python user can write `import decimo` and get access to Mojo-native `Decimal128`, `BigDecimal`, `BigInt`, and `BigUint` types at near-native speed, without rewriting anything in Python.

**Feasibility verdict: Possible but non-trivial.** The main (no surprise) blocker is that decimo is a *packaged* Mojo library (`.mojopkg`), not a single `.mojo` file. The Mojo importer hook (the easy dev-time path) does not support custom import paths for non-stdlib Mojo packages. The `.so` build path (the distribution path) works fine. This means the developer workflow is slightly more manual, but distribution is fully viable.

---

## 2. How the Mechanism Works (State of the Art)

### 2.1 The Two Paths

| Path                   | How                                                                                                               | When to Use                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| **Source import hook** | `import mojo.importer` in Python, then `import mojo_module` (auto-compiles `.mojo` → `.so` into `__mojocache__/`) | Dev prototyping with single-file modules only |
| **Pre-built `.so`**    | `mojo build mojo_module.mojo --emit shared-lib -o mojo_module.so`                                                 | Production, packages with dependencies, CI/CD |

For decimo, **only the pre-built `.so` path is viable** because the binding code will `import decimo` (the `.mojopkg`), and the importer hook cannot resolve that path.

### 2.2 The Binding Pattern

Every exposed module needs a `PyInit_<module_name>()` entry point:

```mojo
from python import PythonObject
from python.bindings import PythonModuleBuilder
from os import abort

@export
fn PyInit_decimo() -> PythonObject:
    try:
        var m = PythonModuleBuilder("decimo")
        m.def_function[some_fn]("some_fn", docstring="...")
        _ = m.add_type[BigDecimal]("BigDecimal")
              .def_py_init[BigDecimal.py_init]()
              .def_method[BigDecimal.py_add]("__add__")
              # ...etc
        return m.finalize()
    except e:
        abort(String("error creating decimo Python module: ", e))
```

### 2.3 Type Binding Requirements

For a Mojo struct to be bindable:

| Feature                       | Required Trait                                                                  |
| ----------------------------- | ------------------------------------------------------------------------------- |
| Bind the type at all          | `Representable`                                                                 |
| Custom `__init__` from Python | `Movable` + `def_py_init`                                                       |
| Default (no-arg) `__init__`   | `Defaultable + Movable` + `def_init_defaultable`                                |
| Methods                       | `@staticmethod` with `py_self: PythonObject` or `self_ptr: UnsafePointer[Self]` |
| Static methods                | `@staticmethod` with normal `PythonObject` args                                 |
| Return Mojo value to Python   | `PythonObject(alloc=value^)` (type must be registered first)                    |
| Accept Mojo value from Python | `py_obj.downcast_value_ptr[T]()`                                                |

### 2.4 Known Limitations (as of MAX 26.1)

These are hard constraints today, expected to improve over time:

1. **Max 6 `PythonObject` arguments** per bound function (use `def_py_function` workaround for variadic).
2. **No keyword-only arguments** (`fn foo(*, x: Int)` is unsupported).
3. **No native `*args`/`**kwargs`** syntax — must use `OwnedKwargsDict[PythonObject]` and `def_py_function` respectively.
4. **No computed properties** (getter/setter via `@property`).
5. **Non-stdlib Mojo package deps** are not resolvable by the importer hook — must build manually.
6. **Many stdlib types** do not yet implement `ConvertibleFromPython`, requiring manual conversion boilerplate.
7. **Methods must use non-standard self** (`py_self: PythonObject` or `UnsafePointer[Self]`) instead of normal `self`.
8. This is **Beta** — API will change. Do not stabilize the Python API until Modular marks this stable.

---

## 3. Impact Analysis for decimo Types

### 3.1 `BigDecimal` ★ Primary target

- Arbitrary precision decimal — the most compelling type to expose to Python, directly competing with (and outperforming) Python's `decimal.Decimal`.
- Key operations to expose: `__init__`, `__add__`, `__sub__`, `__mul__`, `__truediv__`, `__mod__`, `__pow__`, `__neg__`, `__abs__`, `__repr__`, `__str__`, `__eq__`, `__lt__`, `__le__`, `__gt__`, `__ge__`, `sqrt`, `exp`, `ln`, `log10`, `round`.
- Constructors from Python `int`, `float`, `str` need manual dispatch in `py_init`.
- Requires `RoundingMode` to also be bound (see Section 3.4).
- **Complexity: Medium-High.** ~25-35 method bindings.

### 3.2 `Decimal128`

- Already `Stringable`, `Representable`, likely `Movable` — binding traits are probably satisfied.
- Fixed-precision (IEEE 754 decimal128) — useful as a faster, lower-memory alternative to `BigDecimal` when the precision fits.
- Exposes a nearly identical API surface to `BigDecimal`, so can share the same Python-side `.pyi` stub pattern.
- **Complexity: Medium.** Type is self-contained; ~20-30 method bindings.

### 3.3 `BigInt` / `BigUint`

- Heavy use of parameterized types internally; the public API surface is simpler.
- Python's `int` is arbitrary precision, so these directly compete with Python's native type — positioning matters.
- **Complexity: Medium.**

### 3.4 Shared Infrastructure

- `RoundingMode` enum-like struct needs to be either exposed as a Python class or mapped to Python string constants.
- Error types: Mojo `raises` becomes Python `Exception` automatically via the binding layer.
- `PythonObject` conversions: `String(py_obj)`, `Int(py=py_obj)` are supported for stdlib types.

---

## 4. File Structure

The binding code lives under a new `src/decimo/python/` sub-package, separate from the core implementation. This keeps concerns clean and the core library free of Python-specific boilerplate.

```txt
src/
└── decimo/
    ├── __init__.mojo          (existing)
    ├── decimal128/            (existing)
    ├── bigdecimal/            (existing)
    ├── bigint/                (existing)
    ├── biguint/               (existing)
    ├── errors.mojo            (existing)
    ├── prelude.mojo           (existing)
    ├── rounding_mode.mojo     (existing)
    └── python/                ← NEW sub-package
        ├── __init__.mojo      ← top-level PyInit_decimo() entry point
        ├── bind_decimal128.mojo
        ├── bind_bigdecimal.mojo
        ├── bind_bigint.mojo
        ├── bind_biguint.mojo
        └── helpers.mojo       ← shared conversion helpers (PythonObject ↔ RoundingMode, etc.)
```

The `python/__init__.mojo` contains the single `@export fn PyInit_decimo()` that calls each `bind_*` file's registration function, then calls `m.finalize()`.

Alternatively, for initial simplicity, expose each type as its own module:

```txt
src/decimo/python/
    ├── decimal128_module.mojo   → builds to decimal128.so
    ├── bigdecimal_module.mojo   → builds to bigdecimal.so
    ├── bigint_module.mojo       → builds to bigint.so
    └── biguint_module.mojo      → builds to biguint.so
```

**Recommendation:** Start with separate modules per type (easier to iterate, easier to test in isolation), then merge into a single `decimo` module once the API stabilizes.

### 4.1 Python-side Wrapper Package (`python/decimo/`)

A thin Python wrapper package provides:

- Type stubs (`.pyi` files) for IDE autocomplete and mypy/pyright support
- Pythonic re-exports and documentation
- The canonical `Decimal` alias (see below)
- Optional pure-Python fallback for platforms where the `.so` is unavailable

```txt
python/
└── decimo/                    ← Python package (installable via pip/conda)
    ├── __init__.py            ← imports the .so, re-exports, and sets Decimal alias
    ├── bigdecimal.pyi         ← type stubs
    ├── decimal128.pyi
    ├── bigint.pyi
    ├── biguint.pyi
    └── py.typed               ← PEP 561 marker
```

### 4.2 The `Decimal` Alias

Set the alias in the Python wrapper `__init__.py`, not in the Mojo binding layer:

```python
# python/decimo/__init__.py
from ._decimo import BigDecimal, Decimal128, BigInt, BigUint  # .so symbols

# Expose Decimal as a friendly alias for BigDecimal.
# Because it's assignment, not subclassing, both names refer to the
# *exact same type object*: isinstance(d, Decimal) == isinstance(d, BigDecimal).
Decimal = BigDecimal

__all__ = ["Decimal", "BigDecimal", "Decimal128", "BigInt", "BigUint"]
```

Python users can then use either name interchangeably:

```python
from decimo import Decimal          # preferred, familiar name
from decimo import BigDecimal       # also works, same object

d = Decimal("1.23456789")
print(isinstance(d, BigDecimal))    # True — same type
```

**Stub file:** The `.pyi` stub should document both names:

```python
# python/decimo/bigdecimal.pyi
class BigDecimal:
    def __init__(self, value: int | float | str) -> None: ...
    def __add__(self, other: BigDecimal) -> BigDecimal: ...
    # ...

Decimal = BigDecimal   # alias
```

---

## 5. Build System Integration (pixi.toml)

New tasks to add to `pixi.toml`:

```toml
# Build Python extension modules (.so files)
py_build_bigdecimal = """
    pixi run mojo build src/decimo/python/bigdecimal_module.mojo \
    --emit shared-lib \
    -I src \
    -o python/decimo/_decimo_bigdecimal.so
"""
py_build_decimal128 = """
    pixi run mojo build src/decimo/python/decimal128_module.mojo \
    --emit shared-lib \
    -I src \
    -o python/decimo/_decimo_decimal128.so
"""
py_build_bigint = """
    pixi run mojo build src/decimo/python/bigint_module.mojo \
    --emit shared-lib \
    -I src \
    -o python/decimo/_decimo_bigint.so
"""
py_build = "pixi run py_build_bigdecimal && pixi run py_build_decimal128 && pixi run py_build_bigint"

# Run Python tests
py_test = "pixi run py_build && python -m pytest tests/python/ -v"

# Build + install locally for interactive testing
py_install = "pixi run py_build && pip install -e python/ --no-build-isolation"
```

Key point: the `-I src` flag ensures `import decimo` in the binding Mojo file resolves to `src/decimo/`. I do **not** need to pre-package `decimo.mojopkg` for the binding build — the source directory import works directly with `mojo build`.

---

## 6. Testing Strategy

### 6.1 Test Layout

```txt
tests/
├── python/                    ← NEW
│   ├── test_bigdecimal.py     ← primary
│   ├── test_decimal128.py
│   ├── test_bigint.py
│   ├── test_biguint.py
│   ├── test_aliases.py        ← verifies Decimal is BigDecimal
│   └── conftest.py            ← shared fixtures, e.g. pre-built .so path
└── test_all.sh                (existing, Mojo-native tests)
```

### 6.2 Test Approach

**Unit tests (pytest):**

```python
# tests/python/test_bigdecimal.py
import pytest
from decimo import Decimal, BigDecimal

def test_addition():
    a = Decimal("1.5")
    b = Decimal("2.3")
    assert str(a + b) == "3.8"

def test_division_by_zero():
    with pytest.raises(Exception):
        Decimal("1") / Decimal("0")

def test_high_precision():
    a = Decimal("1") / Decimal("3")   # 1/3 to full precision
    assert str(a).startswith("0.333333")
```

**Alias tests:**

```python
# tests/python/test_aliases.py
from decimo import Decimal, BigDecimal

def test_decimal_is_bigdecimal():
    assert Decimal is BigDecimal

def test_isinstance_works_both_ways():
    d = Decimal("1.5")
    assert isinstance(d, Decimal)
    assert isinstance(d, BigDecimal)  # same type object
```

**Parity tests:** For each operation already tested in the Mojo test suite (e.g., `tests/bigdecimal/`), write a corresponding Python test with the same inputs/outputs. This double-checks that the binding layer doesn't silently change behavior.

**Type and interop tests:** Verify that Python `int`, `float`, `str` arguments are accepted and correctly converted:

```python
d = Decimal(42)        # from Python int
d = Decimal(3.14)      # from Python float
d = Decimal("1.23e5")  # from Python str
```

**Exception propagation tests:** Verify that Mojo `raises` correctly surfaces as Python exceptions with meaningful messages.

**Benchmark parity:** After the Python-callable layer is working, run a comparison of `decimo.Decimal` vs Python's `decimal.Decimal` to validate the performance proposition.

### 6.3 CI Integration

Add to the CI pipeline (if one exists) or to `test_all.sh`:

```bash
# In tests/test_all.sh or a new tests/test_python.sh
pixi run py_build
python -m pytest tests/python/ -v --tb=short
```

---

## 7. Distribution (Publishing)

### 7.1 Distribution Formats

| Format                  | How                                         | Audience                 |
| ----------------------- | ------------------------------------------- | ------------------------ |
| **conda package**       | pixi/conda-forge, ships `.so` per platform  | Mojo/MAX ecosystem users |
| **PyPI wheel**          | `python -m build`, platform-specific wheels | General Python users     |
| **Source distribution** | Requires Mojo toolchain to build            | Advanced / contributors  |

For PyPI, build platform-specific wheels. Since decimo currently targets `osx-arm64` and `linux-64`, this matches standard wheel tags: `cp313-cp313-macosx_11_0_arm64` and `cp313-cp313-linux_x86_64`.

### 7.2 PyPI Wheel Build Process

Use `scikit-build-core` or `meson-python` to integrate `mojo build` as the build backend step, or write a custom `build.py` script:

```txt
python/
├── pyproject.toml
├── build.py              ← custom build step: invokes `mojo build --emit shared-lib`
├── MANIFEST.in
└── decimo/
    ├── __init__.py
    ├── *.so              ← built artifacts
    └── *.pyi             ← stubs
```

Example `pyproject.toml`:

```toml
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.backends.legacy:build"

[project]
name = "decimo"
version = "0.8.0"
description = "Arbitrary-precision decimal and integer types for Python, powered by Mojo"
requires-python = ">=3.13"
license = {text = "Apache-2.0"}

[tool.setuptools.package-data]
decimo = ["*.so", "*.pyi", "py.typed"]
```

### 7.3 GitHub Actions CI/CD Sketch

```yaml
# .github/workflows/python-wheel.yml
jobs:
  build-wheels:
    strategy:
      matrix:
        os: [macos-14, ubuntu-24.04]   # arm64 mac, x86_64 linux
    steps:
      - uses: actions/checkout@v4
      - name: Install pixi
        run: curl -fsSL https://pixi.sh/install.sh | sh
      - name: Install dependencies
        run: pixi install
      - name: Build .so files
        run: pixi run py_build
      - name: Build wheel
        run: cd python && pip wheel . -w dist/
      - uses: actions/upload-artifact@v4
        with:
          path: python/dist/*.whl
  publish:
    needs: build-wheels
    steps:
      - uses: pypa/gh-action-pypi-publish@v1
```

---

## 8. Roadmap

### Phase 0 — Proof of Concept

- [ ] Write binding for a single function: `BigDecimal.__init__(str)` and `BigDecimal.__str__`.
- [ ] Manually build the `.so` with `mojo build --emit shared-lib -I src`.
- [ ] Import from Python, confirm round-trip: `str(BigDecimal("1.23")) == "1.23"`.
- [ ] Identify trait gaps (`Representable`, `Movable`, etc., should be fine).

### Phase 1 — BigDecimal Full Binding

- [ ] Expose `RoundingMode` as Python constants or a Python enum.
- [ ] Expose all arithmetic operators: `__add__`, `__sub__`, `__mul__`, `__truediv__`, `__mod__`, `__pow__`, `__neg__`, `__abs__`.
- [ ] Expose comparison: `__eq__`, `__ne__`, `__lt__`, `__le__`, `__gt__`, `__ge__`.
- [ ] Expose constructors from `int`, `float`, `str`.
- [ ] Expose transcendentals: `sqrt`, `exp`, `ln`, `log10`.
- [ ] Expose `round(d, ndigits)` via `__round__`.
- [ ] Write Python test suite for `BigDecimal` (parity with `tests/bigdecimal/`).
- [ ] Add `pixi run py_build_bigdecimal` task.
- [ ] Write `.pyi` stub for `BigDecimal`.
- [ ] Set `Decimal = BigDecimal` alias in `python/decimo/__init__.py`.
- [ ] Add `test_aliases.py` to verify `Decimal is BigDecimal`.

### Phase 2 — Decimal128 Binding

- [ ] Expose `Decimal128`: same API surface as `BigDecimal` but fixed precision.
- [ ] Write `.pyi` stub for `Decimal128` (can largely mirror `bigdecimal.pyi`).
- [ ] Python tests with parity checks against `tests/decimal128/`.

### Phase 3 — BigInt / BigUint Binding

- [ ] Expose `BigInt`: arithmetic, comparison, `__int__`, `__str__`, `__hash__` (if feasible).
- [ ] Expose `BigUint` similarly.
- [ ] Handle `Int` ↔ `PythonObject` conversion for large Python integers (requires manual conversion logic since Python `int` is arbitrary precision).
- [ ] Python tests with parity checks.

### Phase 4 — Packaging + Distribution

- [ ] Create `python/` directory with `pyproject.toml` and `__init__.py`.
- [ ] Write `.pyi` stubs for all types.
- [ ] Add `py.typed` marker (PEP 561).
- [ ] Test `pip install` of the built wheel locally.
- [ ] Set up GitHub Actions for wheel builds (macOS arm64, Linux x86_64).
- [ ] Publish to PyPI (or TestPyPI first).

### Phase 5 — Ergonomics + Stabilization

- [ ] Add `__hash__` for use in dicts/sets.
- [ ] Add `__copy__` / `__deepcopy__`.
- [ ] Add `__reduce__` / `__reduce_ex__` for pickling.
- [ ] Handle `math.floor`, `math.ceil`, `math.trunc` via `__floor__`, `__ceil__`, `__trunc__`.
- [ ] Add `numbers.Number` ABC registration (soft-codes into Python's numeric tower).
- [ ] Implement `__format__` for f-string formatting.
- [ ] Benchmark against `decimal.Decimal` and publish results.
- [ ] Wait for Modular to stabilize the bindings API before final API freeze.

---

## 9. Open Questions & Risks

| Risk                                    | Severity | Notes                                                                                                                 |
| --------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------- |
| Beta API changes                        | High     | Modular explicitly warns the bindings API will change. Pin to a specific MAX version until stable.                    |
| Mojo package deps in importer hook      | Medium   | Fully worked around via the manual `--emit shared-lib` build. No blocker.                                             |
| Python `int` → Mojo `BigInt` conversion | Medium   | Python's `int` is arbitrary-size. Need custom `ConvertibleFromPython` implementation or `def_py_function` workaround. |
| 6-argument limit                        | Low      | Most arithmetic ops take ≤2 args. Might be hit by some `BigDecimal` rounding APIs.                                    |
| No property support                     | Low      | Use getter methods (`get_precision()`) as a workaround until properties land.                                         |
| Platform support                        | Medium   | Currently only `osx-arm64` and `linux-64`. Windows is not yet a Mojo target.                                          |
| ABI compatibility                       | Medium   | The `.so` is linked against a specific MAX/Python version. Wheels must be version-specific.                           |

---

## 10. Quick-Start Skeleton

To start the proof of concept, create `src/decimo/python/bigdecimal_module.mojo`:

```mojo
from python import PythonObject
from python.bindings import PythonModuleBuilder
from os import abort
from decimo.bigdecimal import BigDecimal

@export
fn PyInit_bigdecimal() -> PythonObject:
    try:
        var m = PythonModuleBuilder("bigdecimal")
        _ = m.add_type[BigDecimal]("BigDecimal")
              .def_py_init[BigDecimal.py_init]()
              .def_method[BigDecimal.py_add]("__add__")
              .def_method[BigDecimal.py_sub]("__sub__")
              .def_method[BigDecimal.py_mul]("__mul__")
              .def_method[BigDecimal.py_truediv]("__truediv__")
              .def_method[BigDecimal.py_str]("__str__")
              .def_method[BigDecimal.py_repr]("__repr__")
        return m.finalize()
    except e:
        abort(String("error creating bigdecimal Python module: ", e))
```

Then build it:

```bash
mojo build src/decimo/python/bigdecimal_module.mojo \
    --emit shared-lib \
    -I src \
    -o bigdecimal.so
```

Then in Python:

```python
import bigdecimal
d = bigdecimal.BigDecimal("3.14159265358979323846")
print(d)  # 3.14159265358979323846
print(d + bigdecimal.BigDecimal("1"))  # 4.14159265358979323846
```

Once wrapped by the `python/decimo/` package with the alias:

```python
from decimo import Decimal
d = Decimal("1") / Decimal("3")   # prints 0.333333...
assert isinstance(d, Decimal)     # True
```

The Mojo side will require adding `py_init`, `py_add`, `py_str` etc. as `@staticmethod` methods on `BigDecimal` (or as free functions), following the binding pattern described in Section 2.3.
