from bench_biguint_add import main as bench_add
from bench_biguint_multiply import main as bench_multiply
from bench_biguint_truncate_divide import main as bench_truncate_divide


fn main() raises:
    print(
        """
=========================================
This is the BigUInt Benchmarks
=========================================
1:      Add
2:      Multiply
3:      Truncate Divide
4:      Run all benchmarks
5:      Exit
=========================================
"""
    )
    var command = input("Type the number of bench you want to run: ")
    if command == "1":
        bench_add()
    elif command == "2":
        bench_multiply()
    elif command == "3":
        bench_truncate_divide()
    elif command == "4":
        bench_add()
        bench_multiply()
        bench_truncate_divide()
    elif command == "5":
        return
    else:
        print("Invalid input")
        main()
