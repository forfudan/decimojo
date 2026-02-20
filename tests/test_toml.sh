#!/bin/bash
set -e  # Exit immediately if any command fails

for f in tests/tomlmojo/*.mojo; do
    pixi run mojo run -I src -D ASSERT=all "$f"
done
