from bench_add import main as bench_add
from bench_subtract import main as bench_subtract
from bench_multiply import main as bench_multiply
from bench_divide import main as bench_divide
from bench_sqrt import main as bench_sqrt
from bench_from_float import main as bench_from_float
from bench_from_string import main as bench_from_string
from bench_comparison import main as bench_comparison
from bench_exp import main as bench_exp


fn main() raises:
    bench_add()
    bench_subtract()
    bench_multiply()
    bench_divide()
    bench_sqrt()
    bench_from_float()
    bench_from_string()
    bench_comparison()
    bench_exp()
