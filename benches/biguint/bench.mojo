from bench_biguint_add import main as bench_add
from bench_biguint_subtraction import main as bench_subtraction
from bench_biguint_multiply import main as bench_multiply
from bench_biguint_truncate_divide import main as bench_truncate_divide
from bench_biguint_from_string import main as bench_from_string


fn main() raises:
    print(
        """
=========================================
This is the BigUInt Benchmarks
=========================================
add:         Add
sub:         Subtract
mul:         Multiply
div:         Truncate divide (//)
fromstr:     From string
all:         Run all benchmarks
q:           Exit
=========================================
"""
    )
    var command = input("Type name of bench you want to run: ")
    if command == "add":
        bench_add()
    elif command == "sub":
        bench_subtraction()
    elif command == "mul":
        bench_multiply()
    elif command == "div":
        bench_truncate_divide()
    elif command == "fromstr":
        bench_from_string()
    elif command == "all":
        bench_add()
        bench_multiply()
        bench_truncate_divide()
        bench_from_string()
    elif command == "q":
        return
    else:
        print("Invalid input")
        main()
