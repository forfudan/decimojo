from bench_bigint_add import main as bench_add
from bench_bigint_truncate_divide import main as bench_truncate_divide
from bench_bigint_floor_divide import main as bench_floor_divide


fn main() raises:
    print(
        """
=========================================
This is the BigInt Benchmarks
=========================================
1:       Add
2:       Truncate Divide
3:       Floor Divide
4:       Run all benchmarks
5:       Exit
=========================================
"""
    )
    var command = input("Type the number of the bench you want to run: ")
    if command == "1":
        bench_add()
    elif command == "2":
        bench_truncate_divide()
    elif command == "3":
        bench_floor_divide()
    elif command == "4":
        bench_add()
        bench_truncate_divide()
        bench_floor_divide()
    elif command == "5":
        return
    else:
        print("Invalid input")
        main()
