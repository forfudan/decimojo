# Big Binary Integer plan

The current `BigInt10` is based on `BigUInt` which uses a decimal representation with a base of 10^9. This design choice is to re-use the same data structure for the buffers of `BigInt10` (as we implemented `BigUInt` initially for `BigDecimal`). However, when users use `BigInt10` for general integer arithmetic, a binary representation with a base of 2^32 (or 2^64) would be more efficient. Thus, it is nice to have a separate binary implementation of `BigInt2` as the core integer type, while keeping the current decimal implementation of `BigInt10` for some special use cases (e.g., as a intermediate type when printing `BigInt2`). The `BigUInt` will continue to serve as the base type for `BigDecimal`.

## Type system and renaming plan

Currently we have:

| type         | alias             | information                          | base |
| ------------ | ----------------- | ------------------------------------ | ---- |
| `BigDecimal` | `BDec`, `Decimal` | arbitrary-precision decimal          | 10^9 |
| `BigInt10`     | `BInt`            | arbitrary-precision integer          | 10^9 |
| `BigUInt`    | `BUInt`           | arbitrary-precision unsigned integer | 10^9 |
| `Decimal128` | `Dec128`          | 128-bit fixed-precision decimal      | -    |

In the future, we will have:

| type         | alias             | information                                               | internal representation |
| ------------ | ----------------- | --------------------------------------------------------- | ----------------------- |
| `BigDecimal` | `BDec`, `Decimal` | Decimal，arbitrary precision                              | 10^9                    |
| `BigInt10`     | `BInt2`           | Binary，as core big int type                              | 2^32                    |
| `BigInt10`   | `BInt10`          | Decimal，gradually hidden from users                      | 10^9                    |
| `BigUInt`    | `BigUInt`         | Decimal，as base type for `BigDecimal`, hidden from users | 10^9                    |
| `Decimal128` | `Dec128`          | Decimal，128-bit fixed precision                          | -                       |

Current `BigInt10` and `BigUInt` are implemented based on 10^9 decimal representation. `BigUInt` will continue to serve as the base type for `BigDecimal`.

At the same time, we will develop a new binary implementation of `BigInt2` as the core integer type.

Once `BigInt2` is stable and performs well, we will proceed with renaming:

- `BigInt10` will be renamed to `BigInt10`
- The alias `BInt` will be assigned to `BigInt2` (binary implementation)

Then `BigInt10` and `BigUInt` will be hidden from users, leaving only `BigInt2` (binary implementation) and `BigDecimal` (decimal implementation) exposed to users.

## 大整數的 limb 大小

| 項目              | limb 大小    | 存儲類型    | 原因                                          |
| ----------------- | ------------ | ----------- | --------------------------------------------- |
| **CPython**       | **2^30**     | `uint32_t`  | schoolbook 乘法要在 `uint64_t` 裡累加多個乘積 |
| GMP               | 2^32 或 2^64 | native word | 手寫匯編直接用硬件 `mul` 指令取 hi/lo         |
| Java BigInteger   | 2^32         | `int[]`     | 用 `long` (64-bit) 做中間運算                 |
| Rust `num-bigint` | 2^32 或 2^64 | native word | 同 GMP                                        |
| Go `math/big`     | 2^32 或 2^64 | native word | 同 GMP                                        |
| OpenSSL BIGNUM    | 2^32 或 2^64 | native word | 同 GMP                                        |
