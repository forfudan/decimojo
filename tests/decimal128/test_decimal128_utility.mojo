"""
Tests for utility functions: number_of_digits, truncate_to_max,
round_to_keep_first_n_digits, and bitcast.
"""

import testing
from testing import assert_equal, assert_true

from decimojo.prelude import dm, Decimal128, RoundingMode
from decimojo.decimal128.utility import (
    truncate_to_max,
    number_of_digits,
    round_to_keep_first_n_digits,
    bitcast,
)


fn test_number_of_digits() raises:
    """Tests for number_of_digits function."""
    # UInt128
    assert_equal(number_of_digits(UInt128(0)), 0)
    assert_equal(number_of_digits(UInt128(1)), 1)
    assert_equal(number_of_digits(UInt128(9)), 1)
    assert_equal(number_of_digits(UInt128(10)), 2)
    assert_equal(number_of_digits(UInt128(123)), 3)
    assert_equal(number_of_digits(UInt128(9999)), 4)
    assert_equal(number_of_digits(UInt128(10**6)), 7)
    assert_equal(number_of_digits(UInt128(10**12)), 13)
    assert_equal(number_of_digits(UInt128(Decimal128.MAX_AS_UINT128)), 29)

    # UInt256
    assert_equal(number_of_digits(UInt256(0)), 0)
    assert_equal(number_of_digits(UInt256(123456789)), 9)
    assert_equal(number_of_digits(UInt256(10) ** 20), 21)
    assert_equal(
        number_of_digits(UInt256(Decimal128.MAX_AS_UINT128) * UInt256(10)), 30
    )


fn test_truncate_to_max_below() raises:
    """Truncate_to_max with values at or below MAX — should be unchanged."""
    assert_equal(truncate_to_max(UInt128(123456)), UInt128(123456))
    assert_equal(truncate_to_max(UInt256(7654321)), UInt256(7654321))
    assert_equal(
        truncate_to_max(UInt128(Decimal128.MAX_AS_UINT128)),
        UInt128(Decimal128.MAX_AS_UINT128),
    )
    assert_equal(
        truncate_to_max(UInt256(Decimal128.MAX_AS_UINT128)),
        UInt256(Decimal128.MAX_AS_UINT128),
    )


fn test_truncate_to_max_above() raises:
    """Truncate_to_max with values above MAX — should be truncated."""
    # MAX + 1
    var max_plus_1 = UInt256(Decimal128.MAX_AS_UINT128) + UInt256(1)
    assert_true(
        truncate_to_max(max_plus_1) <= UInt256(Decimal128.MAX_AS_UINT128)
    )

    # Round down (last truncated digit < 5)
    assert_equal(
        truncate_to_max(UInt256(79228162514264337593543950354)),
        UInt256(7922816251426433759354395035),
    )

    # Round up (last truncated digit >= 6)
    assert_equal(
        truncate_to_max(UInt256(79228162514264337593543950356)),
        UInt256(7922816251426433759354395036),
    )

    # Banker's rounding: MAX + 20 (trailing 5, preceding digit even → round up)
    assert_equal(
        truncate_to_max(UInt256(Decimal128.MAX_AS_UINT128) + UInt256(20)),
        UInt256(7922816251426433759354395036),
    )

    # Banker's rounding: constructed trailing 5 with preceding even
    var base = UInt256(79228162514264337593543950330)
    var banker = base * UInt256(10) + UInt256(5)
    assert_equal(truncate_to_max(banker), base + UInt256(0))

    # Much larger value (truncate multiple digits)
    var much_larger = UInt256(Decimal128.MAX_AS_UINT128) * UInt256(
        1000
    ) + UInt256(555)
    assert_true(
        truncate_to_max(much_larger) <= UInt256(Decimal128.MAX_AS_UINT128)
    )


fn test_truncate_banker_rounding() raises:
    """Banker's rounding edge cases in truncate_to_max."""
    # Round down to even (5 as rounding digit, preceding even)
    assert_equal(
        truncate_to_max(UInt256(7922816251426433759354395033250)),
        UInt256(79228162514264337593543950332),
    )

    # Round up to even (5 as rounding digit, preceding odd)
    assert_equal(
        truncate_to_max(UInt256(7922816251426433759354395033150)),
        UInt256(79228162514264337593543950332),
    )

    # Round up: 5 followed by non-zero (preceding even)
    assert_equal(
        truncate_to_max(UInt256(79228162514264337593543950332501)),
        UInt256(79228162514264337593543950333),
    )

    # Round up: 5 followed by non-zero (preceding odd)
    assert_equal(
        truncate_to_max(UInt256(79228162514264337593543950331501)),
        UInt256(79228162514264337593543950332),
    )

    # Rounding digit > 5
    assert_equal(
        truncate_to_max(UInt256(7922816251426433759354395033207)),
        UInt256(79228162514264337593543950332),
    )

    # Rounding digit < 5
    assert_equal(
        truncate_to_max(UInt256(7922816251426433759354395033204)),
        UInt256(79228162514264337593543950332),
    )


fn test_round_to_keep_first_n_digits() raises:
    """Tests for round_to_keep_first_n_digits."""
    # Keep 0 digits (round to nearest power of 10)
    assert_equal(round_to_keep_first_n_digits(UInt128(997), 0), UInt128(1))

    # Truncate one digit
    assert_equal(
        round_to_keep_first_n_digits(UInt128(234567), 5), UInt128(23457)
    )

    # Fewer digits than n → unchanged
    assert_equal(
        round_to_keep_first_n_digits(UInt128(234567), 29), UInt128(234567)
    )

    # Banker's rounding: trailing 5 with even preceding digit
    assert_equal(round_to_keep_first_n_digits(UInt128(12345), 4), UInt128(1234))

    # Banker's rounding: trailing 5 with odd preceding digit → round up
    assert_equal(round_to_keep_first_n_digits(UInt128(23455), 4), UInt128(2346))

    # Round down (< 5)
    assert_equal(round_to_keep_first_n_digits(UInt128(12342), 4), UInt128(1234))

    # Round up (> 5)
    assert_equal(round_to_keep_first_n_digits(UInt128(12347), 4), UInt128(1235))

    # Zero input
    assert_equal(round_to_keep_first_n_digits(UInt128(0), 5), UInt128(0))

    # Single digit
    assert_equal(round_to_keep_first_n_digits(UInt128(7), 1), UInt128(7))
    assert_equal(round_to_keep_first_n_digits(UInt128(7), 0), UInt128(1))

    # Large UInt256
    assert_equal(
        round_to_keep_first_n_digits(UInt256(9876543210987654321), 18),
        UInt256(987654321098765432),
    )


fn test_bitcast() raises:
    """Test bitcast returns coefficient bits."""

    fn _check(d: Decimal128) raises:
        assert_equal(d.coefficient(), bitcast[DType.uint128](d))

    _check(Decimal128("123.456"))
    _check(Decimal128(0))
    _check(Decimal128.MAX())
    _check(Decimal128("-987.654321"))
    _check(Decimal128("0.000000000123456789"))
    _check(Decimal128(12345, 67890, 0xABCDEF, 0x55))


fn main() raises:
    testing.TestSuite.discover_tests[__functions_in_module()]().run()
