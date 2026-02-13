#!/bin/bash
set -e  # Exit immediately if any command fails

for dir in biguint bigint bigdecimal decimal128; do
    for f in tests/$dir/*.mojo; do
        pixi run mojo run -I src -D ASSERT=all "$f"
    done
done