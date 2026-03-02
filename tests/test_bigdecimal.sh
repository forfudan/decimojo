#!/bin/bash
set -e

for f in tests/bigdecimal/*.mojo; do
    pixi run mojo run -I src -D ASSERT=all "$f"
done
