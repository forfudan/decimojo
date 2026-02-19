# 大整數的 limb 大小

| 項目              | limb 大小    | 存儲類型    | 原因                                          |
| ----------------- | ------------ | ----------- | --------------------------------------------- |
| **CPython**       | **2^30**     | `uint32_t`  | schoolbook 乘法要在 `uint64_t` 裡累加多個乘積 |
| GMP               | 2^32 或 2^64 | native word | 手寫匯編直接用硬件 `mul` 指令取 hi/lo         |
| Java BigInteger   | 2^32         | `int[]`     | 用 `long` (64-bit) 做中間運算                 |
| Rust `num-bigint` | 2^32 或 2^64 | native word | 同 GMP                                        |
| Go `math/big`     | 2^32 或 2^64 | native word | 同 GMP                                        |
| OpenSSL BIGNUM    | 2^32 或 2^64 | native word | 同 GMP                                        |
