from decimojo.prelude import *
import time
import math


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
    var a2a1: BigUInt
    if a2.is_zero():
        a2a1 = a1
    else:
        a2a1 = a2
        decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
            a2a1, n
        )
        a2a1 += a1
    var q, c = divide_two_by_one(a2a1, b1, n)
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


fn divide_two_by_one(
    a: BigUInt, b: BigUInt, n: Int
) raises -> Tuple[BigUInt, BigUInt]:
    """Divides a BigUInt by another BigUInt using a recursive approach.
    The divisor has n words and the dividend has 2n words.

    Args:
        a: The dividend as a BigUInt.
        b: The divisor as a BigUInt.
        n: The number of words in the divisor.
    """
    if (n & 1) != 0 or n <= 2:  # n can be 16 or 32
        return (a // b, a % b)

    if b.words[-1] < 500_000_000:
        raise Error("b[-1] must be at least 500_000_000")

    # b_modified = b
    # decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
    #     b_modified, n
    # )
    # if a.compare(b_modified) >= 0:
    #     raise Error("a must be less than b * 10^18")

    else:
        a0 = BigUInt(a.words[0 : n // 2])
        a1 = BigUInt(a.words[n // 2 : n])
        a2 = BigUInt(a.words[n : n + n // 2])
        a3 = BigUInt(a.words[n + n // 2 : n + n])

        b0 = BigUInt(b.words[0 : n // 2])
        b1 = BigUInt(b.words[n // 2 : n])

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


fn divide_burnikel_ziegler(a: BigUInt, b: BigUInt) raises -> BigUInt:
    """Divides BigUInt using the Burnikel-Ziegler algorithm."""

    # Yuhao Zhu:
    # This implementation is based on the research report
    # "Fast Recursive Division" by Christoph Burnikel and Joachim Ziegler.
    # MPI-I-98-1-022, October 1998.

    alias BLOCK_SIZE_OF_WORDS = 2

    # STEP 1:
    # Normalize the divisor b to n words so that
    # (1) it is of the form j*2^k and
    # (2) the most significant word is at least 500_000_000.

    var normalized_b = b
    var normalized_a = a
    var normalization_factor: Int

    if normalized_b.words[-1] == 0:
        normalized_b.remove_leading_empty_words()
    if normalized_b.words[-1] < 500_000_000:
        normalization_factor = (
            decimojo.biguint.arithmetics.calculate_normalization_factor(
                normalized_b.words[-1]
            )
        )
    else:
        normalization_factor = 0

    # The targeted number of blocks should be the smallest 2^k such that
    # 2^k >= number of words in normalized_b ceil divided by BLOCK_SIZE_OF_WORDS.
    # k is the depth of the recursion.
    # n is the final number of words in the normalized b.
    var n_blocks_divisor = math.ceildiv(
        len(normalized_b.words), BLOCK_SIZE_OF_WORDS
    )
    var depth = Int(math.ceil(math.log2(Float64(n_blocks_divisor))))
    n_blocks_divisor = 2**depth
    var n = n_blocks_divisor * BLOCK_SIZE_OF_WORDS

    var n_digits_to_scale_up = (
        n - len(normalized_b.words)
    ) * 9 + normalization_factor

    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_ten(
        normalized_b, n_digits_to_scale_up
    )
    decimojo.biguint.arithmetics.multiply_inplace_by_power_of_ten(
        normalized_a, n_digits_to_scale_up
    )

    # The normalized_b is now 9 digits, but may still be smaller than 500_000_000.
    var gap_ratio = BUInt.BASE // normalized_b.words[-1]
    if gap_ratio > 2:
        decimojo.biguint.arithmetics.multiply_inplace_by_uint32(
            normalized_b, gap_ratio
        )
        decimojo.biguint.arithmetics.multiply_inplace_by_uint32(
            normalized_a, gap_ratio
        )

    # STEP 2: Split the normalized a into blocks of size n.
    # t is the number of blocks in the dividend.
    var t = math.ceildiv(len(normalized_a.words), n)
    if len(a.words) == t * n:
        # If the number of words in a is already a multiple of n
        # We check if the most significant word is >= 500_000_000.
        # If it is, we need to add one more block to the dividend.
        # This ensures that the most significant word of the dividend
        # is smaller than 500_000_000.
        if normalized_a.words[-1] >= 500_000_000:
            t += 1

    var z = BigUInt(normalized_a.words[(t - 2) * n : t * n])
    var q = BigUInt()
    for i in range(t - 2, -1, -1):
        var q_i, r = divide_two_by_one(z, normalized_b, n)
        # print(z, "//", normalized_b, "=", q_i, "mod", r)
        if i == t - 2:
            q = q_i
        else:
            decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
                q, n
            )
            q += q_i
        if i > 0:
            decimojo.biguint.arithmetics.multiply_inplace_by_power_of_billion(
                r, n
            )
            z = r + BigUInt(normalized_a.words[(i - 1) * n : i * n])

    return q


fn main() raises:
    n = 2**14
    var a = BUInt(String("987_654_321" * 3 * n))
    var b = BUInt(String("3_141_592" * n))
    # var a = BigUInt(
    #     "123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789000000"
    # )
    # var b = BigUInt("678678678678000000")

    var result1 = List[BigUInt]()
    t0 = time.perf_counter_ns()
    for _ in range(1):
        q = divide_burnikel_ziegler(a, b)
        result1.append(q)
    print("time taken: ", time.perf_counter_ns() - t0, " ns")

    var result2 = List[BigUInt]()
    t0 = time.perf_counter_ns()
    for _ in range(1):
        p = a // b
        result2.append(p)
    print("time taken: ", time.perf_counter_ns() - t0, " ns")

    # print("result1: ", result1[0])
    # print("result2: ", result2[0])
    print("result1 == result2: ", result1[0] == result2[0])
