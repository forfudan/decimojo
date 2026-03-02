#!/bin/bash
set -e

bash ./tests/test_bigdecimal.sh
bash ./tests/test_bigint.sh
bash ./tests/test_biguint.sh
bash ./tests/test_bigint10.sh
bash ./tests/test_decimal128.sh
