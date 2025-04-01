from bench_bigdecimal_add import main as bench_add
from bench_bigdecimal_subtract import main as bench_sub
from bench_bigdecimal_multiply import main as bench_multiply
from bench_bigdecimal_divide import main as bench_divide
from bench_bigdecimal_sqrt import main as bench_sqrt
from bench_bigdecimal_exp import main as bench_exp
from bench_bigdecimal_scale_up_by_power_of_10 import main as bench_scale_up


fn main() raises:
    print(
        """
=========================================
This is the BigInt Benchmarks
=========================================
add:         Add
sub:         Subtract
mul:         Multiply
div:         Divide (true divide)
sqrt:        Square root
exp:         Exponential
all:         Run all benchmarks
q:           Exit
=========================================
scaleup:     Scale up by power of 10
=========================================
"""
    )
    var command = input("Type name of bench you want to run: ")
    if command == "add":
        bench_add()
    elif command == "sub":
        bench_sub()
    elif command == "mul":
        bench_multiply()
    elif command == "div":
        bench_divide()
    elif command == "sqrt":
        bench_sqrt()
    elif command == "exp":
        bench_exp()
    elif command == "all":
        bench_add()
        bench_sub()
        bench_multiply()
        bench_divide()
        bench_sqrt()
        bench_exp()
    elif command == "q":
        return
    elif command == "scaleup":
        bench_scale_up()
    else:
        print("Invalid input")
        main()
