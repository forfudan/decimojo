"""
Comprehensive tests for string-based decimal operations.
Tests addition and subtraction functions with 50 test cases each.
"""
from decimojo import Decimal
from decimojo.mathematics import addition_string_based as addition
from decimojo.mathematics import subtraction_string_based as subtraction
import testing


fn test_addition_function() raises:
    print("Testing string-based addition function...")

    # Array to store all test cases
    var test_cases = List[Tuple[Decimal, Decimal, String]]()

    # Category 1: Basic addition with simple positive numbers
    test_cases.append((Decimal(String("1")), Decimal(String("2")), String("3")))
    test_cases.append(
        (Decimal(String("10")), Decimal(String("20")), String("30"))
    )
    test_cases.append(
        (Decimal(String("123.45")), Decimal(String("67.89")), String("191.34"))
    )
    test_cases.append(
        (Decimal(String("999")), Decimal(String("1")), String("1000"))
    )
    test_cases.append(
        (Decimal(String("0.5")), Decimal(String("0.5")), String("1.0"))
    )

    # Category 2: Addition with negative numbers
    test_cases.append(
        (Decimal(String("-1")), Decimal(String("2")), String("1"))
    )
    test_cases.append(
        (Decimal(String("1")), Decimal(String("-2")), String("-1"))
    )
    test_cases.append(
        (Decimal(String("-10")), Decimal(String("-20")), String("-30"))
    )
    test_cases.append(
        (
            Decimal(String("-123.45")),
            Decimal(String("-67.89")),
            String("-191.34"),
        )
    )
    test_cases.append(
        (Decimal(String("-0.5")), Decimal(String("0.5")), String("0.0"))
    )

    # Category 3: Addition with zeros
    test_cases.append((Decimal(String("0")), Decimal(String("0")), String("0")))
    test_cases.append(
        (Decimal(String("0")), Decimal(String("123.45")), String("123.45"))
    )
    test_cases.append(
        (Decimal(String("123.45")), Decimal(String("0")), String("123.45"))
    )
    test_cases.append(
        (Decimal(String("0")), Decimal(String("-123.45")), String("-123.45"))
    )
    test_cases.append(
        (Decimal(String("-123.45")), Decimal(String("0")), String("-123.45"))
    )

    # Category 4: Addition with different scales/decimal places
    test_cases.append(
        (Decimal(String("1.23")), Decimal(String("4.567")), String("5.797"))
    )
    test_cases.append(
        (Decimal(String("10.1")), Decimal(String("0.01")), String("10.11"))
    )
    test_cases.append(
        (Decimal(String("0.001")), Decimal(String("0.002")), String("0.003"))
    )
    test_cases.append(
        (Decimal(String("123.4")), Decimal(String("5.67")), String("129.07"))
    )
    test_cases.append(
        (Decimal(String("1.000")), Decimal(String("2.00")), String("3.000"))
    )

    # Category 5: Addition with very large numbers
    test_cases.append(
        (
            Decimal(String("1000000000")),
            Decimal(String("2000000000")),
            String("3000000000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("9") * 20),
            Decimal(String("1")),
            String("1") + String("0") * 20,
        )
    )
    test_cases.append(
        (
            Decimal(String("999999999999")),
            Decimal(String("1")),
            String("1000000000000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("9999999999")),
            Decimal(String("9999999999")),
            String("19999999998"),
        )
    )
    test_cases.append(
        (
            Decimal(String("123456789012345")),
            Decimal(String("987654321098765")),
            String("1111111110111110"),
        )
    )

    # Category 6: Addition with very small numbers
    test_cases.append(
        (
            Decimal(String("0.000000001")),
            Decimal(String("0.000000002")),
            String("0.000000003"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.") + String("0") * 20 + String("1")),
            Decimal(String("0.") + String("0") * 20 + String("2")),
            String("0.") + String("0") * 20 + String("3"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.000000001")),
            Decimal(String("1")),
            String("1.000000001"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.") + String("0") * 27 + String("1")),
            Decimal(String("0.") + String("0") * 27 + String("9")),
            String("0.0000000000000000000000000010"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.") + String("0") * 10 + String("1")),
            Decimal(String("0.") + String("0") * 15 + String("1")),
            String("0.0000000000100001"),
        )
    )

    # Category 7: Addition with numbers that have many digits
    test_cases.append(
        (
            Decimal(String("1.23456789")),
            Decimal(String("9.87654321")),
            String("11.11111110"),
        )
    )
    test_cases.append(
        (
            Decimal(String("1.111111111111111")),
            Decimal(String("2.222222222222222")),
            String("3.333333333333333"),
        )
    )
    test_cases.append(
        (
            Decimal(String("3.14159265358979323846")),
            Decimal(String("2.71828182845904523536")),
            String("5.85987448204883847382"),
        )
    )
    test_cases.append(
        (
            Decimal(String("1.234567890123456789")),
            Decimal(String("9.876543210987654321")),
            String("11.111111101111111110"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.1234567890123456789")),
            Decimal(String("0.9876543210987654321")),
            String("1.1111111101111111110"),
        )
    )

    # Category 8: Addition where results require carries
    test_cases.append(
        (Decimal(String("9.9")), Decimal(String("0.1")), String("10.0"))
    )
    test_cases.append(
        (Decimal(String("9.99")), Decimal(String("0.01")), String("10.00"))
    )
    test_cases.append(
        (
            Decimal(String("9") * 10),
            Decimal(String("1")),
            String("10000000000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("9.99999")),
            Decimal(String("0.00001")),
            String("10.00000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("999.999")),
            Decimal(String("0.001")),
            String("1000.000"),
        )
    )

    # Category 9: Edge cases and boundary values
    test_cases.append(
        (
            Decimal(String("0.0000000000000000000000000001")),
            Decimal(String("0.0000000000000000000000000009")),
            String("0.0000000000000000000000000010"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.49999999")),
            Decimal(String("0.50000001")),
            String("1.00000000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("1") + String("0") * 20),
            Decimal(String("0.") + String("0") * 20 + String("1")),
            String("1")
            + String("0") * 20
            + String(".")
            + String("0") * 20
            + String("1"),
        )
    )
    test_cases.append(
        (
            Decimal(String("9") * 10 + String(".") + String("9") * 10),
            Decimal(String("0.") + String("0") * 9 + String("1")),
            String("10000000000.0000000000"),
        )
    )

    # Category 10: Addition where sign changes
    test_cases.append(
        (Decimal(String("-1")), Decimal(String("1")), String("0"))
    )
    test_cases.append(
        (Decimal(String("-10")), Decimal(String("20")), String("10"))
    )
    test_cases.append(
        (Decimal(String("-100")), Decimal(String("50")), String("-50"))
    )
    test_cases.append(
        (Decimal(String("-0.001")), Decimal(String("0.002")), String("0.001"))
    )
    test_cases.append(
        (Decimal(String("-9.99")), Decimal(String("10")), String("0.01"))
    )

    # Execute all test cases
    var passed_count = 0
    var failed_count = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = test_case[0]
        var b = test_case[1]
        var expected = test_case[2]
        var result = addition(a, b)

        try:
            if result == expected:
                passed_count += 1
            else:
                failed_count += 1
                print(String("❌ Addition test case {} failed:").format(i + 1))
                print(a, " + ", b)
                print(String("   Expected: {}").format(expected))
                print(String("   Got:      {}").format(result))
        except e:
            failed_count += 1
            print(
                String(
                    "❌ Addition test case {} raised an exception: {}"
                ).format(i + 1, e)
            )

    print(
        String("Addition tests: {} passed, {} failed").format(
            passed_count, failed_count
        )
    )
    testing.assert_equal(
        failed_count, 0, String("All addition tests should pass")
    )


fn test_subtraction_function() raises:
    print(String("Testing string-based subtraction function..."))

    # Array to store all test cases
    var test_cases = List[Tuple[Decimal, Decimal, String]]()

    # Category 1: Basic subtraction with simple positive numbers
    test_cases.append((Decimal(String("3")), Decimal(String("2")), String("1")))
    test_cases.append(
        (Decimal(String("10")), Decimal(String("5")), String("5"))
    )
    test_cases.append(
        (Decimal(String("123.45")), Decimal(String("23.45")), String("100.00"))
    )
    test_cases.append(
        (Decimal(String("1000")), Decimal(String("1")), String("999"))
    )
    test_cases.append(
        (Decimal(String("5.5")), Decimal(String("0.5")), String("5.0"))
    )

    # Category 2: Subtraction with negative numbers
    test_cases.append(
        (Decimal(String("-1")), Decimal(String("2")), String("-3"))
    )
    test_cases.append(
        (Decimal(String("1")), Decimal(String("-2")), String("3"))
    )
    test_cases.append(
        (Decimal(String("-10")), Decimal(String("-5")), String("-5"))
    )
    test_cases.append(
        (Decimal(String("-10")), Decimal(String("-20")), String("10"))
    )
    test_cases.append(
        (Decimal(String("-100")), Decimal(String("-50")), String("-50"))
    )

    # Category 3: Subtraction with zeros
    test_cases.append((Decimal(String("0")), Decimal(String("0")), String("0")))
    test_cases.append(
        (Decimal(String("0")), Decimal(String("123.45")), String("-123.45"))
    )
    test_cases.append(
        (Decimal(String("123.45")), Decimal(String("0")), String("123.45"))
    )
    test_cases.append(
        (Decimal(String("0")), Decimal(String("-123.45")), String("123.45"))
    )
    test_cases.append(
        (Decimal(String("-123.45")), Decimal(String("0")), String("-123.45"))
    )

    # Category 4: Subtraction with different scales/decimal places
    test_cases.append(
        (Decimal(String("5.67")), Decimal(String("1.2")), String("4.47"))
    )
    test_cases.append(
        (Decimal(String("10.1")), Decimal(String("0.01")), String("10.09"))
    )
    test_cases.append(
        (Decimal(String("0.003")), Decimal(String("0.002")), String("0.001"))
    )
    test_cases.append(
        (Decimal(String("123.4")), Decimal(String("0.4")), String("123.0"))
    )
    test_cases.append(
        (Decimal(String("1.000")), Decimal(String("0.999")), String("0.001"))
    )

    # Category 5: Subtraction with very large numbers
    test_cases.append(
        (
            Decimal(String("3000000000")),
            Decimal(String("1000000000")),
            String("2000000000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("1") + String("0") * 20),
            Decimal(String("1")),
            String("9") * 19 + String("9"),
        )
    )
    test_cases.append(
        (
            Decimal(String("10000000000")),
            Decimal(String("1")),
            String("9999999999"),
        )
    )
    test_cases.append(
        (
            Decimal(String("19999999998")),
            Decimal(String("9999999999")),
            String("9999999999"),
        )
    )
    test_cases.append(
        (
            Decimal(String("10000000000")),
            Decimal(String("1")),
            String("9999999999"),
        )
    )

    # Category 6: Subtraction with very small numbers
    test_cases.append(
        (
            Decimal(String("0.000000003")),
            Decimal(String("0.000000001")),
            String("0.000000002"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.") + String("0") * 20 + String("3")),
            Decimal(String("0.") + String("0") * 20 + String("1")),
            String("0.") + String("0") * 20 + String("2"),
        )
    )
    test_cases.append(
        (
            Decimal(String("1.000000001")),
            Decimal(String("0.000000001")),
            String("1.000000000"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.") + String("0") * 27 + String("9")),
            Decimal(String("0.") + String("0") * 27 + String("1")),
            String("0.") + String("0") * 27 + String("8"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.") + String("0") * 10 + String("5")),
            Decimal(String("0.") + String("0") * 15 + String("1")),
            String("0.0000000000499999"),
        )
    )

    # Category 7: Subtraction where results require borrows
    test_cases.append(
        (Decimal(String("10")), Decimal(String("0.1")), String("9.9"))
    )
    test_cases.append(
        (Decimal(String("10")), Decimal(String("0.01")), String("9.99"))
    )
    test_cases.append(
        (
            Decimal(String("1") + String("0") * 10),
            Decimal(String("1")),
            String("9999999999"),
        )
    )
    test_cases.append(
        (Decimal(String("10")), Decimal(String("0.00001")), String("9.99999"))
    )
    test_cases.append(
        (Decimal(String("1000")), Decimal(String("0.001")), String("999.999"))
    )

    # Category 8: Cases where the result changes sign
    test_cases.append(
        (Decimal(String("1")), Decimal(String("2")), String("-1"))
    )
    test_cases.append(
        (Decimal(String("0.5")), Decimal(String("1.5")), String("-1.0"))
    )
    test_cases.append(
        (Decimal(String("100")), Decimal(String("200")), String("-100"))
    )
    test_cases.append(
        (Decimal(String("0.001")), Decimal(String("0.002")), String("-0.001"))
    )
    test_cases.append(
        (Decimal(String("9.99")), Decimal(String("10")), String("-0.01"))
    )

    # Category 9: Edge cases and boundary values
    test_cases.append(
        (
            Decimal(String("0.0000000000000000000000000009")),
            Decimal(String("0.0000000000000000000000000001")),
            String("0.0000000000000000000000000008"),
        )
    )
    test_cases.append(
        (
            Decimal(String("1.00000000")),
            Decimal(String("0.49999999")),
            String("0.50000001"),
        )
    )
    test_cases.append(
        (
            Decimal(
                String("1")
                + String("0") * 20
                + String(".")
                + String("0") * 20
                + String("1")
            ),
            Decimal(String("0.") + String("0") * 20 + String("1")),
            String("99999999999999999999.999999999999999999999"),
        )
    )
    test_cases.append(
        (
            Decimal(
                String("1")
                + String("0") * 9
                + String(".")
                + String("0") * 9
                + String("1")
            ),
            Decimal(String("0.") + String("0") * 9 + String("1")),
            String("1000000000.0000000000"),
        )
    )

    # Category 10: Subtracting nearly equal numbers
    test_cases.append((Decimal(String("1")), Decimal(String("1")), String("0")))
    test_cases.append(
        (Decimal(String("1.0001")), Decimal(String("1")), String("0.0001"))
    )
    test_cases.append(
        (
            Decimal(String("1.0000001")),
            Decimal(String("1")),
            String("0.0000001"),
        )
    )
    test_cases.append(
        (
            Decimal(String("123456789.000000001")),
            Decimal(String("123456789")),
            String("0.000000001"),
        )
    )
    test_cases.append(
        (
            Decimal(String("0.000000002")),
            Decimal(String("0.000000001")),
            String("0.000000001"),
        )
    )

    # Execute all test cases
    var passed_count = 0
    var failed_count = 0

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        var a = test_case[0]
        var b = test_case[1]
        var expected = test_case[2]
        var result = subtraction(a, b)

        try:
            if result == expected:
                passed_count += 1
            else:
                failed_count += 1
                print(
                    String("❌ Subtraction test case {} failed:").format(i + 1)
                )
                print(a, " - ", b)
                print(String("   Expected: {}").format(expected))
                print(String("   Got:      {}").format(result))
        except e:
            failed_count += 1
            print(
                String(
                    "❌ Subtraction test case {} raised an exception: {}".format(
                        i + 1, e
                    )
                )
            )

    print(
        String(
            "Subtraction tests: {} passed, {} failed".format(
                passed_count, failed_count
            )
        )
    )
    testing.assert_equal(
        failed_count, 0, String("All subtraction tests should pass")
    )


fn main() raises:
    print(
        String(
            "Running comprehensive tests for string-based decimal operations"
        )
    )
    print(
        String(
            "=============================================================\n"
        )
    )

    test_addition_function()
    print(String("\n"))
    test_subtraction_function()

    print(
        String(
            "\n============================================================="
        )
    )
    print(String("All tests completed!"))
