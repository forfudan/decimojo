from bench_bigdecimal_add import main as bench_add
from bench_bigdecimal_subtract import main as bench_subtract
from bench_bigdecimal_multiply import main as bench_multiply
from bench_bigdecimal_divide import main as bench_divide
from bench_bigdecimal_sqrt import main as bench_sqrt
from bench_bigdecimal_exp import main as bench_exp
from bench_bigdecimal_ln import main as bench_ln
from bench_bigdecimal_root import main as bench_root
from bench_bigdecimal_round import main as bench_round


fn main() raises:
    print(
        """
=========================================
This is the BigDecimal Benchmarks
=========================================
add:         Add
sub:         Subtract
mul:         Multiply
div:         Divide
sqrt:        Square root
exp:         Exponential
ln:          Natural logarithm
root:        Nth root
round:       Rounding
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
    elif command == "sqrt":
        bench_sqrt()
    elif command == "exp":
        bench_exp()
    elif command == "ln":
        bench_ln()
    elif command == "root":
        bench_root()
    elif command == "round":
        bench_round()
    elif command == "all":
        bench_add()
        bench_subtract()
        bench_multiply()
        bench_divide()
        bench_sqrt()
        bench_exp()
        bench_ln()
        bench_root()
        bench_round()
    elif command == "q":
        return
    else:
        print("Invalid input")
        main()
