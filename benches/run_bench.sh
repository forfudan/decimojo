#!/bin/bash
# CLI dispatch for DeciMojo benchmarks
# Usage: pixi run bench <type> [operation]
#
# Types: bigint10 (bint), biguint (buint), decimal128 (dec), bigdecimal (bdec)
# Operations: add, multiply, subtract, floor_divide, truncate_divide, etc.
#             (varies by type — omit to get interactive menu)
#
# Examples:
#   pixi run bench bigint10 add
#   pixi run bench dec sqrt
#   pixi run bench biguint          # interactive menu
#   pixi run bench                  # show help

set -e

TYPE="$1"
OP="$2"

# --- Help ---
if [[ -z "$TYPE" ]]; then
    echo "Usage: pixi run bench <type> [operation]"
    echo ""
    echo "Types:"
    echo "  bigint10 (bint)    BigInt10 benchmarks (3-way: BigInt10 vs BigInt2 vs Python int)"
    echo "  bigint2  (bint2)   BigInt2-specific benchmarks (power, sqrt, shift, string)"
    echo "  biguint  (buint)   BigUInt benchmarks (BigUInt vs Python int)"
    echo "  decimal128 (dec)   Decimal128 benchmarks (Decimal128 vs Python decimal)"
    echo "  bigdecimal (bdec)  BigDecimal benchmarks (BigDecimal vs Python decimal)"
    echo ""
    echo "Omit operation to get interactive menu for that type."
    echo ""
    echo "Examples:"
    echo "  pixi run bench bigint10 add"
    echo "  pixi run bench dec sqrt"
    echo "  pixi run bench biguint"
    exit 0
fi

# --- Map short names ---
case "$TYPE" in
    bint)  TYPE="bigint10" ;;
    bint2) TYPE="bigint2" ;;
    buint) TYPE="biguint" ;;
    dec)   TYPE="decimal128" ;;
    bdec)  TYPE="bigdecimal" ;;
esac

DIR="benches/$TYPE"

if [[ ! -d "$DIR" ]]; then
    echo "Error: Unknown type '$TYPE'"
    echo "Available: bigint10 (bint), biguint (buint), decimal128 (dec), bigdecimal (bdec)"
    exit 1
fi

# --- Interactive mode (no operation specified) ---
if [[ -z "$OP" ]]; then
    cd "$DIR"
    pixi run mojo run -I ../ bench.mojo
    exit 0
fi

# --- Direct operation mode ---
cd "$DIR"

# Find a .mojo file matching the operation name
# Try patterns: bench_<type>_<op>.mojo, bench_<op>.mojo
FILE=""
for pattern in "bench_${TYPE}_${OP}.mojo" "bench_${OP}.mojo"; do
    if [[ -f "$pattern" ]]; then
        FILE="$pattern"
        break
    fi
done

if [[ -z "$FILE" ]]; then
    echo "Error: No bench file found for type='$TYPE', operation='$OP'"
    echo ""
    echo "Available operations in $TYPE/:"
    ls bench_*.mojo 2>/dev/null | grep -v '^bench\.mojo$' | sed "s/bench_${TYPE}_//;s/bench_//;s/\.mojo$//" | sort
    exit 1
fi

echo "Running: $FILE"
pixi run mojo run -I ../ "$FILE"
