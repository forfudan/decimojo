from bench_bigint_add import main as bench_add
from bench_bigint_truncate_divide import main as bench_truncate_divide
from bench_bigint_floor_divide import main as bench_floor_divide


fn main() raises:
    print(
        """
=========================================
This is the BigInt Benchmarks
=========================================
1. add:         Add
2. truncdiv:    Truncate Divide
3. floordiv:    Floor Divide
4. all:         Run all benchmarks
5. quit:        Exit
=========================================
"""
    )
    var command = input("Type the bench you want to run:")
    if command == "add":
        bench_add()
    elif command == "truncdiv":
        bench_truncate_divide()
    elif command == "floordiv":
        bench_floor_divide()
    elif command == "all":
        bench_add()
        bench_truncate_divide()
        bench_floor_divide()
    elif command == "quit":
        return
    else:
        print("Invalid input")
        main()
