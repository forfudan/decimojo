#!/bin/bash
set -e  # Exit immediately if any command fails

for dir in biguint bigint10 bigdecimal bigint decimal128; do
    for f in tests/$dir/*.mojo; do
        pixi run mojo run -I src -D ASSERT=all "$f"
    done
done

# CLI calculator tests (need both src and cli on the include path)
for f in tests/cli/*.mojo; do
    pixi run mojo run -I src -I src/cli -D ASSERT=all "$f"
done