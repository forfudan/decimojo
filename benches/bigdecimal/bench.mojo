from bench_bigdecimal_add import main as bench_add


fn main() raises:
    print(
        """
=========================================
This is the BigInt Benchmarks
=========================================
add:         Add
all:         Run all benchmarks
q:           Exit
=========================================
"""
    )
    var command = input("Type name of bench you want to run: ")
    if command == "add":
        bench_add()
    elif command == "all":
        bench_add()
    elif command == "q":
        return
    else:
        print("Invalid input")
        main()
