# ===----------------------------------------------------------------------=== #
# decimo-python
# Mojo bindings for Python, exposing the BigDecimal type and basic operations.
# Because the Mojo-Python interop is still in early stages, this module is
# mainly an experiment to test the capabilities and ergonomics of the bindings,
# and to give me some experience writing Mojo Miji (https://mojo-lang.com/miji).
#
# I followed the official guide for writing a Mojo module for Python:
# https://docs.modular.com/mojo/manual/python/mojo-from-python
# ===----------------------------------------------------------------------=== #

from python import PythonObject
from python.bindings import PythonModuleBuilder
from os import abort

from decimo import BigDecimal


# ===----------------------------------------------------------------------=== #
# PyInit entry point
# ===----------------------------------------------------------------------=== #


@export
fn PyInit__decimo() -> PythonObject:
    try:
        var m = PythonModuleBuilder("_decimo")
        _ = (
            m.add_type[BigDecimal]("BigDecimal")
            .def_py_init[bigdecimal_py_init]()
            .def_method[bigdecimal_to_string]("to_string")
            .def_method[bigdecimal_to_repr]("to_repr")
            .def_method[bigdecimal_add]("add")
            .def_method[bigdecimal_sub]("sub")
            .def_method[bigdecimal_mul]("mul")
            .def_method[bigdecimal_div]("div")
            .def_method[bigdecimal_neg]("neg")
            .def_method[bigdecimal_abs]("abs_")
            .def_method[bigdecimal_eq]("eq")
            .def_method[bigdecimal_lt]("lt")
            .def_method[bigdecimal_le]("le")
        )
        return m.finalize()
    except e:
        abort(String("error creating _decimo Python module: ", e))


# ===----------------------------------------------------------------------=== #
# Binding functions
# ===----------------------------------------------------------------------=== #


fn bigdecimal_py_init(
    out self: BigDecimal, args: PythonObject, kwargs: PythonObject
) raises:
    """Construct a BigDecimal from a single argument (string, int, or float).

    Usage from Python:
        Decimal("3.14")
        Decimal(42)
        Decimal(3.14)   # via str() conversion
    """
    if len(args) != 1:
        raise Error(
            "Decimal() takes exactly 1 argument ("
            + String(len(args))
            + " given)"
        )
    # Convert any Python object to its string representation, then construct.
    # This handles str, int, and float gracefully.
    var s = String(args[0])
    self = BigDecimal(s)


fn bigdecimal_to_string(py_self: PythonObject) raises -> PythonObject:
    """Return the decimal as a plain string, e.g. '3.14'."""
    var ptr = py_self.downcast_value_ptr[BigDecimal]()
    return PythonObject(ptr[].__str__())


fn bigdecimal_to_repr(py_self: PythonObject) raises -> PythonObject:
    """Return the repr string, e.g. 'Decimal(\"3.14\")'."""
    var ptr = py_self.downcast_value_ptr[BigDecimal]()
    return PythonObject('Decimal("' + ptr[].__str__() + '")')


fn bigdecimal_add(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self + other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    var result = self_ptr[] + other_ptr[]
    return PythonObject(alloc=result^)


fn bigdecimal_sub(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self - other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    var result = self_ptr[] - other_ptr[]
    return PythonObject(alloc=result^)


fn bigdecimal_mul(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self * other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    var result = self_ptr[] * other_ptr[]
    return PythonObject(alloc=result^)


fn bigdecimal_div(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self / other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    var result = self_ptr[] / other_ptr[]
    return PythonObject(alloc=result^)


fn bigdecimal_neg(py_self: PythonObject) raises -> PythonObject:
    """Return -self."""
    var ptr = py_self.downcast_value_ptr[BigDecimal]()
    var result = -(ptr[])
    return PythonObject(alloc=result^)


fn bigdecimal_abs(py_self: PythonObject) raises -> PythonObject:
    """Return abs(self)."""
    var ptr = py_self.downcast_value_ptr[BigDecimal]()
    var result = abs(ptr[])
    return PythonObject(alloc=result^)


fn bigdecimal_eq(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self == other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    return PythonObject(self_ptr[] == other_ptr[])


fn bigdecimal_lt(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self < other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    return PythonObject(self_ptr[] < other_ptr[])


fn bigdecimal_le(
    py_self: PythonObject, other: PythonObject
) raises -> PythonObject:
    """Return self <= other."""
    var self_ptr = py_self.downcast_value_ptr[BigDecimal]()
    var other_ptr = other.downcast_value_ptr[BigDecimal]()
    return PythonObject(self_ptr[] <= other_ptr[])
