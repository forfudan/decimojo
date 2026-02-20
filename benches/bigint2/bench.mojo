from bench_bigint2_power import main as bench_power
from bench_bigint2_sqrt import main as bench_sqrt
from bench_bigint2_shift import main as bench_shift
from bench_bigint2_from_string import main as bench_from_string
from bench_bigint2_to_string import main as bench_to_string


fn main() raises:
    while True:
        print(
            """
=========================================
This is the BigInt2 Benchmarks
=========================================
power:       Power / Exponentiation
sqrt:        Integer Square Root
shift:       Left Shift
from_string: String → BigInt2 construction
to_string:   BigInt2 → String conversion
all:         Run all benchmarks
q:           Exit
=========================================
"""
        )
        var command = input("Type name of bench you want to run: ")
        if command == "power":
            bench_power()
        elif command == "sqrt":
            bench_sqrt()
        elif command == "shift":
            bench_shift()
        elif command == "from_string":
            bench_from_string()
        elif command == "to_string":
            bench_to_string()
        elif command == "all":
            bench_power()
            bench_sqrt()
            bench_shift()
            bench_from_string()
            bench_to_string()
        elif command == "q":
            return
        else:
            print("Invalid input")
