from bench_bigdecimal_add import main as bench_add
from bench_bigdecimal_subtract import main as bench_sub
from bench_bigdecimal_multiply import main as bench_multiply
from bench_bigdecimal_divide import main as bench_divide


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
all:         Run all benchmarks
q:           Exit
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
    elif command == "all":
        bench_add()
        bench_sub()
        bench_multiply()
        bench_divide()
    elif command == "q":
        return
    else:
        print("Invalid input")
        main()
