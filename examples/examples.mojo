"""
Examples demonstrating the usage of Decimojo's Decimal type.
"""
from decimojo import Decimal
from decimojo.rounding_mode import RoundingMode


fn print_section(title: String):
    """Helper function to print section headers."""
    print("\n" + "=" * 50)
    print(title)
    print("=" * 50)


fn creating_decimal_values() raises:
    print_section("CREATING DECIMAL VALUES")

    print("\nFrom String:")
    # Basic decimal values
    var d1 = Decimal("123.45")
    var d2 = Decimal("-67.89")
    var d3 = Decimal("0.0001234")
    var d4 = Decimal("1234567890")
    var d5 = Decimal("0")

    print("d1 (123.45):", d1)
    print("d2 (-67.89):", d2)
    print("d3 (0.0001234):", d3)
    print("d4 (1234567890):", d4)
    print("d5 (0):", d5)

    # Scientific notation
    var s1 = Decimal("1.23e5")
    var s2 = Decimal("4.56e-3")
    print("\nScientific notation:")
    print("s1 (1.23e5):", s1)
    print("s2 (4.56e-3):", s2)

    # String formatting variations
    var f1 = Decimal("1_000_000.00")
    var f2 = Decimal("   123.45   ")
    print("\nFormatting variations:")
    print("f1 (1_000_000.00):", f1)
    print("f2 ('   123.45   '):", f2)

    print("\nFrom Integer:")
    var i1 = Decimal(123)
    var i2 = Decimal(-456)
    var i3 = Decimal(0)
    print("i1 (123):", i1)
    print("i2 (-456):", i2)
    print("i3 (0):", i3)

    print("\nFrom Float:")
    var float1 = Decimal(123.45)
    var float2 = Decimal(-67.89)
    var float3 = Decimal(0.0001234)
    print("float1 (123.45):", float1)
    print("float2 (-67.89):", float2)
    print("float3 (0.0001234):", float3)

    print("\nWith max_precision parameter:")
    var p1 = Decimal(123.45, max_precision=True)
    var p2 = Decimal(123.45, max_precision=False)
    print("p1 (max_precision=True):", p1)
    print("p2 (max_precision=False):", p2)

    print("\nUsing Static Constants:")
    var zero = Decimal.ZERO()
    var one = Decimal.ONE()
    var neg_one = Decimal.NEGATIVE_ONE()
    var max_val = Decimal.MAX()
    var min_val = Decimal.MIN()
    print("ZERO():", zero)
    print("ONE():", one)
    print("NEGATIVE_ONE():", neg_one)
    print("MAX():", max_val)
    print("MIN():", min_val)


fn arithmetic_operations() raises:
    print_section("ARITHMETIC OPERATIONS")

    print("\nAddition:")
    var a = Decimal("123.45")
    var b = Decimal("67.89")
    var result = a + b
    print("123.45 + 67.89 =", result)

    # Adding with different scales
    var c = Decimal("123.4")
    var d = Decimal("67.89")
    var result2 = c + d
    print("123.4 + 67.89 =", result2)

    # Adding with negative numbers
    var e = Decimal("123.45")
    var f = Decimal("-67.89")
    var result3 = e + f
    print("123.45 + (-67.89) =", result3)

    # Adding zero
    var g = Decimal("123.45")
    var h = Decimal("0")
    var result4 = g + h
    print("123.45 + 0 =", result4)

    print("\nSubtraction:")
    var a_sub = Decimal("123.45")
    var b_sub = Decimal("67.89")
    var result_sub = a_sub - b_sub
    print("123.45 - 67.89 =", result_sub)

    # Subtraction resulting in negative
    var c_sub = Decimal("67.89")
    var d_sub = Decimal("123.45")
    var result_sub2 = c_sub - d_sub
    print("67.89 - 123.45 =", result_sub2)

    # Subtracting with different scales
    var e_sub = Decimal("123.4")
    var f_sub = Decimal("67.89")
    var result_sub3 = e_sub - f_sub
    print("123.4 - 67.89 =", result_sub3)

    # Subtracting to zero
    var g_sub = Decimal("123.45")
    var h_sub = Decimal("123.45")
    var result_sub4 = g_sub - h_sub
    print("123.45 - 123.45 =", result_sub4)

    print("\nMultiplication:")
    var a_mul = Decimal("12.34")
    var b_mul = Decimal("5.67")
    var result_mul = a_mul * b_mul
    print("12.34 * 5.67 =", result_mul)

    # Multiplying with negative numbers
    var c_mul = Decimal("12.34")
    var d_mul = Decimal("-5.67")
    var result_mul2 = c_mul * d_mul
    print("12.34 * (-5.67) =", result_mul2)

    # Multiplying by zero
    var e_mul = Decimal("12.34")
    var f_mul = Decimal("0")
    var result_mul3 = e_mul * f_mul
    print("12.34 * 0 =", result_mul3)

    # Multiplying by one
    var g_mul = Decimal("12.34")
    var h_mul = Decimal("1")
    var result_mul4 = g_mul * h_mul
    print("12.34 * 1 =", result_mul4)

    # Multiplying large numbers
    var i_mul = Decimal("1234567.89")
    var j_mul = Decimal("9876543.21")
    var result_mul5 = i_mul * j_mul
    print("1234567.89 * 9876543.21 =", result_mul5)

    print("\nNegation:")
    var a_neg = Decimal("123.45")
    var result_neg = -a_neg
    print("-123.45 =", result_neg)

    var b_neg = Decimal("-67.89")
    var result_neg2 = -b_neg
    print("-(-67.89) =", result_neg2)

    var c_neg = Decimal("0")
    var result_neg3 = -c_neg
    print("-0 =", result_neg3)


fn rounding_and_precision() raises:
    print_section("ROUNDING AND PRECISION")

    print("\nRounding to Specific Decimal Places:")
    var d = Decimal("123.456789")
    print("Original value:", d)

    # Default rounding (HALF_EVEN/banker's rounding)
    var r1 = d.round(2)
    var r2 = d.round(4)
    var r3 = d.round(0)
    print("Rounded to 2 places (default):", r1)
    print("Rounded to 4 places (default):", r2)
    print("Rounded to 0 places (default):", r3)

    # Using different rounding modes
    var down = d.round(2, RoundingMode.DOWN())
    var up = d.round(2, RoundingMode.UP())
    var half_up = d.round(2, RoundingMode.HALF_UP())
    var half_even = d.round(2, RoundingMode.HALF_EVEN())
    print("\nRounding 123.456789 to 2 places with different modes:")
    print("DOWN():", down)
    print("UP():", up)
    print("HALF_UP():", half_up)
    print("HALF_EVEN():", half_even)

    # Rounding special cases
    var half_val = Decimal("123.5")
    var half_rounded = half_val.round(0, RoundingMode.HALF_EVEN())
    var val = Decimal("124.5")
    var even_rounded = val.round(0, RoundingMode.HALF_EVEN())
    print("\nRounding special cases (banker's rounding):")
    print("123.5 rounded to 0 places:", half_rounded)
    print("124.5 rounded to 0 places:", even_rounded)

    print("\nWorking with Scale:")
    var d_scale = Decimal("123.45")
    print("Value:", d_scale, "- Scale:", d_scale.scale())

    # Round to different scales
    var rounded = d_scale.round(3)
    print("Rounded to 3 places:", rounded, "- New scale:", rounded.scale())

    # Scale after arithmetic operations
    var a_scale = Decimal("123.45")  # scale 2
    var b_scale = Decimal("67.890")  # scale 3
    var sum_scale = a_scale + b_scale
    print("\nAddition with different scales:")
    print(
        a_scale,
        "(scale",
        a_scale.scale(),
        ") +",
        b_scale,
        "(scale",
        b_scale.scale(),
        ") =",
    )
    print(sum_scale, "(scale", sum_scale.scale(), ")")


fn string_conversion_and_printing() raises:
    print_section("STRING CONVERSION AND PRINTING")

    var d = Decimal("123.45")
    print("Decimal value:", d)

    # Convert to string using String()
    var str_val = String(d)
    print("As string:", str_val)

    # Preserving trailing zeros
    var d2 = Decimal("123.4500")
    print("With trailing zeros:", d2)

    # Printing very small numbers
    var small = Decimal("0.0000001234")
    print("Very small number:", small)

    # Printing integer values
    var int_val = Decimal("1000")
    print("Integer value:", int_val)


fn display_decimal_details(d: Decimal):
    """Function to display internal representation."""
    print("Value:          ", d)
    print("Coefficient:    ", d.coefficient())
    print("Scale:          ", d.scale())
    print("Is negative:    ", d.is_negative())
    print("Is zero:        ", d.is_zero())
    print("Internal fields:")
    print("  - low:        ", d.low)
    print("  - mid:        ", d.mid)
    print("  - high:       ", d.high)
    print("  - flags:      ", d.flags)
    print("-------------------------")


fn examining_internal_representation() raises:
    print_section("EXAMINING INTERNAL REPRESENTATION")

    var d1 = Decimal("123.45")
    print("Regular decimal (123.45):")
    display_decimal_details(d1)

    var d2 = Decimal("-0.0001")
    print("\nSmall negative decimal (-0.0001):")
    display_decimal_details(d2)

    var d3 = Decimal("79228162514264337593543950335")  # MAX
    print("\nMaximum value:")
    display_decimal_details(d3)


fn working_with_edge_cases() raises:
    print_section("WORKING WITH EDGE CASES")

    # Maximum value
    var max_value = Decimal.MAX()
    print("Maximum value:", max_value)

    # Minimum value
    var min_value = Decimal.MIN()
    print("Minimum value:", min_value)

    # Very small numbers
    var small = Decimal("0." + "0" * 27 + "1")  # 1 at 28th decimal place
    print("Very small number (1 at 28th decimal place):", small)

    # Very precise numbers
    var precise = Decimal("0." + "1" * 28)  # 28 decimal places
    print("Very precise number (28 decimal places of 1s):", precise)

    print("\nZero Values with Different Scales:")
    var z1 = Decimal("0")
    var z2 = Decimal("0.0")
    var z3 = Decimal("0.00")
    var z4 = Decimal("0.000000")

    print("z1 (scale", z1.scale(), "):", z1)
    print("z2 (scale", z2.scale(), "):", z2)
    print("z3 (scale", z3.scale(), "):", z3)
    print("z4 (scale", z4.scale(), "):", z4)

    print("\nAre they all zero?")
    print("z1.is_zero():", z1.is_zero())
    print("z2.is_zero():", z2.is_zero())
    print("z3.is_zero():", z3.is_zero())
    print("z4.is_zero():", z4.is_zero())

    print("\nMaximum Precision Handling:")
    var max_prec = Decimal("0.1234567890123456789012345678")
    print("Max precision (28 places):", max_prec)

    var too_precise = Decimal("0.12345678901234567890123456789")
    print("Beyond max precision (29 places, will be rounded):", too_precise)


fn main() raises:
    print("DECIMOJO EXAMPLES")
    print("=================\n")

    creating_decimal_values()
    arithmetic_operations()
    rounding_and_precision()
    string_conversion_and_printing()
    examining_internal_representation()
    working_with_edge_cases()

    print("\n" + "=" * 50)
    print("END OF EXAMPLES")
    print("=" * 50)
