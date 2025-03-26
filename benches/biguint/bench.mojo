from bench_biguint_add import main as bench_add
from bench_biguint_multiply import main as bench_multiply
from bench_biguint_truncate_divide import main as bench_truncate_divide


fn main() raises:
    print(
        """
=========================================
This is the BigUInt Benchmarks
=========================================
add:         Add
mul:         Multiply
trunc:       Truncate divide (//)
all:         Run all benchmarks
q:           Exit
=========================================
"""
    )
    var command = input("Type the number of bench you want to run: ")
    if command == "add":
        bench_add()
    elif command == "mul":
        bench_multiply()
    elif command == "trunc":
        bench_truncate_divide()
    elif command == "all":
        bench_add()
        bench_multiply()
        bench_truncate_divide()
    elif command == "q":
        return
    else:
        print("Invalid input")
        main()
