from bench_biguint_add import main as bench_add
from bench_biguint_multiply import main as bench_multiply
from bench_biguint_truncate_divide import main as bench_truncate_divide


fn main() raises:
    print(
        """
=========================================
This is the BigUInt Benchmarks
=========================================
1. add:         Add
2. multiply:    Multiply
2. truncdiv:    Truncate Divide
4. all:         Run all benchmarks
5. quit:        Exit
=========================================
"""
    )
    var command = input("Type the bench you want to run:")
    if command == "add":
        bench_add()
    elif command == "multiply":
        bench_multiply()
    elif command == "truncdiv":
        bench_truncate_divide()
    elif command == "all":
        bench_add()
        bench_multiply()
        bench_truncate_divide()
    elif command == "quit":
        return
    else:
        print("Invalid input")
        main()
