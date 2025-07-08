from decimojo.prelude import *
import time


fn divide_three_words_by_two(
    a2: UInt32, a1: UInt32, a0: UInt32, b1: UInt32, b0: UInt32
) raises -> Tuple[UInt32, UInt32, UInt32]:
    """Divides a 3-word number by a 2-word number.
    b1 must be at least 500_000_000.

    Args:
        a2: The most significant word of the dividend.
        a1: The middle word of the dividend.
        a0: The least significant word of the dividend.
        b1: The most significant word of the divisor.
        b0: The least significant word of the divisor.

    Returns:
        A tuple containing
        (1) the quotient (as UInt32)
        (2) the most significant word of the remainder (as UInt32)
        (3) the least significant word of the remainder (as UInt32).

    Notes:
        a = a2 * BASE^2 + a1 * BASE + a0.
        b = b1 * BASE + b0.
    """
    if b1 < 500_000_000:
        raise Error("b1 must be at least 500_000_000")

    var a2a1 = UInt64(a2) * 1_000_000_000 + UInt64(a1)

    var q: UInt64 = UInt64(a2a1) // UInt64(b1)
    var c = a2a1 - q * UInt64(b1)
    var d: UInt64 = q * UInt64(b0)
    var r = UInt64(c * 1_000_000_000) + UInt64(a0)

    if r < UInt64(d):
        var b = UInt64(b1) * 1_000_000_000 + UInt64(b0)
        q -= 1
        r += b
        if r < UInt64(d):
            q -= 1
            r += b

    r -= d
    var r1: UInt32 = UInt32(r // 1_000_000_000)
    var r0: UInt32 = UInt32(r % 1_000_000_000)

    return (UInt32(q), r1, r0)


fn divide_four_words_by_two(
    a3: UInt32,
    a2: UInt32,
    a1: UInt32,
    a0: UInt32,
    b1: UInt32,
    b0: UInt32,
) raises -> Tuple[UInt32, UInt32, UInt32, UInt32]:
    """Divides a 4-word number by a 2-word number.

    Args:
        a3: The most significant word of the dividend.
        a2: The second most significant word of the dividend.
        a1: The second least significant word of the dividend.
        a0: The least significant word of the dividend.
        b1: The most significant word of the divisor.
        b0: The least significant word of the divisor.

    Returns:
        A tuple containing
        (1) the most significant word of the quotient (as UInt32)
        (2) the least significant word of the quotient (as UInt32)
        (3) the most significant word of the remainder (as UInt32)
        (4) the least significant word of the remainder (as UInt32).
    """

    if b1 < 500_000_000:
        raise Error("b1 must be at least 500_000_000")
    if a3 > b1:
        raise Error("a must be less than b * 10^18")
    elif a3 == b1:
        if a2 > b0:
            raise Error("a must be less than b * 10^18")
        elif a2 == b0:
            if a1 > 0:
                raise Error("a must be less than b * 10^18")
            elif a1 == 0:
                if a0 >= 0:
                    raise Error("a must be less than b * 10^18")

    var q1, r1, r0 = divide_three_words_by_two(a3, a2, a1, b1, b0)
    var q0, s1, s0 = divide_three_words_by_two(r1, r0, a0, b1, b0)
    return (q1, q0, s1, s0)


fn divide_three_by_two(
    a2: BigUInt, a1: BigUInt, a0: BigUInt, b1: BigUInt, b0: BigUInt, n: Int
) raises -> Tuple[BigUInt, BigUInt]:
    if b1.words[-1] < 500_000_000:
        raise Error("b[-1] must be at least 500_000_000")

    var a2a1: BigUInt
    if a2.is_zero():
        a2a1 = a1
    else:
        a2a1 = a2
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            a2a1, n
        )
        a2a1 += a1
    var q, c = divide_recursive(a2a1, b1, n)
    var d = q * b0
    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(c, n)
    var r = c + a0

    if r < d:
        var b = b1
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(b, n)
        b += b0
        q -= BigUInt.ONE
        r += b
        if r < d:
            q -= BigUInt.ONE
            r += b

    r -= d
    return (q, r)


fn divide_recursive(
    a: BigUInt, b: BigUInt, n: Int
) raises -> Tuple[BigUInt, BigUInt]:
    if (n & 1) != 0 or n <= 2:
        return (a // b, a % b)

    else:
        a0 = BigUInt(a.words[0 : n // 2])
        a1 = BigUInt(a.words[n // 2 : n])
        a2 = BigUInt(a.words[n : n + n // 2])
        a3 = BigUInt(a.words[n + n // 2 : n + n])

        b0 = BigUInt(b.words[0 : n // 2])
        b1 = BigUInt(b.words[n // 2 : n])

        print("b:", b1, b0)
        q1, r = divide_three_by_two(a3, a2, a1, b1, b0, n // 2)
        r0 = BigUInt(r.words[0 : n // 2])
        r1 = BigUInt(r.words[n // 2 : n])
        q0, s = divide_three_by_two(r1, r0, a0, b1, b0, n // 2)

        q = q1
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            q, n // 2
        )
        q += q0

    return (q, s)


fn main() raises:
    n = 2**4

    var a = BUInt("123_456_789" * 2 * n)
    var b = BUInt("987654321" + "000000000" * (n - 1))

    var result1 = List[BigUInt]()
    t0 = time.perf_counter_ns()
    for _ in range(1):
        q = divide_recursive(a, b, n)
        result1.append(q[0])
    print("time taken: ", time.perf_counter_ns() - t0, " ns")

    var result2 = List[BigUInt]()
    t0 = time.perf_counter_ns()
    for _ in range(1):
        p = a // b
        result2.append(p)
    print("time taken: ", time.perf_counter_ns() - t0, " ns")

    print("result1 == result2: ", result1[0] == result2[0])
