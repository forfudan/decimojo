from bench_biguint_add import main as bench_add
from bench_biguint_multiply import main as bench_multiply
from bench_biguint_truncate_divide import main as bench_truncate_divide


fn main() raises:
    bench_add()
    bench_multiply()
    bench_truncate_divide()
