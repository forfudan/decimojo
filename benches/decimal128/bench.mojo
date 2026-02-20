"""DeciMojo Decimal128 Benchmark Suite — dispatches to all individual benchmarks."""

from bench_add import main as bench_add
from bench_subtract import main as bench_subtract
from bench_multiply import main as bench_multiply
from bench_divide import main as bench_divide
from bench_modulo import main as bench_modulo
from bench_truncate_divide import main as bench_truncate_divide
from bench_power import main as bench_power
from bench_root import main as bench_root
from bench_exp import main as bench_exp
from bench_ln import main as bench_ln
from bench_log10 import main as bench_log10
from bench_sqrt import main as bench_sqrt
from bench_from_string import main as bench_from_string
from bench_from_int import main as bench_from_int
from bench_from_float import main as bench_from_float
from bench_comparison import main as bench_comparison
from bench_quantize import main as bench_quantize
from bench_round import main as bench_round


fn main() raises:
    while True:
        print(
            """
=========================================
This is the Decimal128 Benchmarks
=========================================
add:         Addition
sub:         Subtraction
mul:         Multiplication
div:         Division
mod:         Modulo
trunc:       Truncate divide
pow:         Power
root:        Root
exp:         Exponential
ln:          Natural log
log10:       Log base 10
sqrt:        Square root
fstr:        From string
fint:        From int
fflt:        From float
cmp:         Comparison
quan:        Quantize
rnd:         Round
all:         Run all benchmarks
q:           Exit
=========================================
"""
        )
        var command = input("Type name of bench you want to run: ")
        if command == "add":
            bench_add()
        elif command == "sub":
            bench_subtract()
        elif command == "mul":
            bench_multiply()
        elif command == "div":
            bench_divide()
        elif command == "mod":
            bench_modulo()
        elif command == "trunc":
            bench_truncate_divide()
        elif command == "pow":
            bench_power()
        elif command == "root":
            bench_root()
        elif command == "exp":
            bench_exp()
        elif command == "ln":
            bench_ln()
        elif command == "log10":
            bench_log10()
        elif command == "sqrt":
            bench_sqrt()
        elif command == "fstr":
            bench_from_string()
        elif command == "fint":
            bench_from_int()
        elif command == "fflt":
            bench_from_float()
        elif command == "cmp":
            bench_comparison()
        elif command == "quan":
            bench_quantize()
        elif command == "rnd":
            bench_round()
        elif command == "all":
            bench_add()
            bench_subtract()
            bench_multiply()
            bench_divide()
            bench_modulo()
            bench_truncate_divide()
            bench_power()
            bench_root()
            bench_exp()
            bench_ln()
            bench_log10()
            bench_sqrt()
            bench_from_string()
            bench_from_int()
            bench_from_float()
            bench_comparison()
            bench_quantize()
            bench_round()
        elif command == "q":
            return
        else:
            print("Invalid input")
