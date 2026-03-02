#!/bin/bash
set -e

bash ./tests/test_decimo.sh
bash ./tests/test_toml.sh
bash ./tests/test_cli.sh
