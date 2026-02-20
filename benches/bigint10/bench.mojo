from bench_bigint10_add import main as bench_add
from bench_bigint10_multiply import main as bench_multiply
from bench_bigint10_truncate_divide import main as bench_truncate_divide
from bench_bigint10_floor_divide import main as bench_floor_divide


fn main() raises:
    while True:
        print(
            """
=========================================
This is the BigInt10 Benchmarks
=========================================
add:         Add
mul:         Multiply
trunc:       Truncate divide
floor:       Floor divide (//)
all:         Run all benchmarks
q:           Exit
=========================================
"""
        )
        var command = input("Type name of bench you want to run: ")
        if command == "add":
            bench_add()
        elif command == "mul":
            bench_multiply()
        elif command == "trunc":
            bench_truncate_divide()
        elif command == "floor":
            bench_floor_divide()
        elif command == "all":
            bench_add()
            bench_multiply()
            bench_truncate_divide()
            bench_floor_divide()
        elif command == "q":
            return
        else:
            print("Invalid input")
