"""Unified BigInt benchmark runner. Compares BigInt10 vs BigInt vs Python int."""

from bench_add import main as bench_add
from bench_multiply import main as bench_multiply
from bench_floor_divide import main as bench_floor_divide
from bench_truncate_divide import main as bench_truncate_divide
from bench_sqrt import main as bench_sqrt
from bench_power import main as bench_power
from bench_from_string import main as bench_from_string
from bench_to_string import main as bench_to_string
from bench_shift import main as bench_shift


fn main() raises:
    while True:
        print(
            """
=========================================
  BigInt Benchmarks (BigInt10 vs BigInt)
=========================================
add:       Addition
mul:       Multiplication
fdiv:      Floor Division
tdiv:      Truncate Division
sqrt:      Integer Square Root (BigUInt vs BigInt)
power:     Power / Exponentiation
fromstr:   String → BigInt construction
tostr:     BigInt → String conversion
shift:     Left Shift (BigInt only)
all:       Run all benchmarks
q:         Exit
=========================================
"""
        )
        var command = input("Type name of bench you want to run: ")
        if command == "add":
            bench_add()
        elif command == "mul":
            bench_multiply()
        elif command == "fdiv":
            bench_floor_divide()
        elif command == "tdiv":
            bench_truncate_divide()
        elif command == "sqrt":
            bench_sqrt()
        elif command == "power":
            bench_power()
        elif command == "fromstr":
            bench_from_string()
        elif command == "tostr":
            bench_to_string()
        elif command == "shift":
            bench_shift()
        elif command == "all":
            bench_add()
            bench_multiply()
            bench_floor_divide()
            bench_truncate_divide()
            bench_sqrt()
            bench_power()
            bench_from_string()
            bench_to_string()
            bench_shift()
        elif command == "q":
            return
        else:
            print("Invalid input")
