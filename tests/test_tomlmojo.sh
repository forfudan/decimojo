#!/bin/bash
set -e

for f in tests/tomlmojo/*.mojo; do
    pixi run mojo run -I src -D ASSERT=all "$f"
done
