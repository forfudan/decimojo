for dir in bigdecimal bigint biguint decimal128; do
    for f in tests/$dir/*.mojo; do
        pixi run mojo run -I src -D ASSERT=all "$f"
    done
done