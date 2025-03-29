from bench_bigdecimal_add import main as bench_add
from bench_bigdecimal_subtract import main as bench_sub


fn main() raises:
    print(
        """
=========================================
This is the BigInt Benchmarks
=========================================
add:         Add
sub:         Subtract
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
    elif command == "all":
        bench_add()
        bench_sub()
    elif command == "q":
        return
    else:
        print("Invalid input")
        main()
