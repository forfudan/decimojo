# Big Binary Integer plan

## 大整數的 limb 大小

| 項目              | limb 大小    | 存儲類型    | 原因                                          |
| ----------------- | ------------ | ----------- | --------------------------------------------- |
| **CPython**       | **2^30**     | `uint32_t`  | schoolbook 乘法要在 `uint64_t` 裡累加多個乘積 |
| GMP               | 2^32 或 2^64 | native word | 手寫匯編直接用硬件 `mul` 指令取 hi/lo         |
| Java BigInteger   | 2^32         | `int[]`     | 用 `long` (64-bit) 做中間運算                 |
| Rust `num-bigint` | 2^32 或 2^64 | native word | 同 GMP                                        |
| Go `math/big`     | 2^32 或 2^64 | native word | 同 GMP                                        |
| OpenSSL BIGNUM    | 2^32 或 2^64 | native word | 同 GMP                                        |

## 命名

目前情況：

| type         | alias             | information                          | base |
| ------------ | ----------------- | ------------------------------------ | ---- |
| `BigUInt`    | `BUInt`           | arbitrary-precision unsigned integer | 10^9 |
| `BigInt`     | `BInt`            | arbitrary-precision integer          | 10^9 |
| `BigDecimal` | `BDec`, `Decimal` | arbitrary-precision decimal          | 10^9 |
| `Decimal128` | `Dec128`          | 128-bit fixed-precision decimal      | -    |

將來：

| type            | alias             | information                        | internal representation |
| --------------- | ----------------- | ---------------------------------- | ----------------------- |
| `BigInt`        | `BInt`            | 二進制，作為核心整數類型           | 2^32                    |
| `BigUInt`       | `BigUInt`         | 十進制，作為`BigDecimal`的基礎類型 | 10^9                    |
| `BigDecimalInt` | `BDInt`           | 十進制，逐漸不對用戶暴露           | 10^9                    |
| `BigDecimal`    | `BDec`, `Decimal` | 十進制，任意精度                   | 10^9                    |
| `Decimal128`    | `Dec128`          | 十進制，128-bit固定精度            | -                       |

當前的 `BigInt` 和 `BigUInt` 是 10^9 基底的十進制實現。`BigUInt` 將繼續作為 `BigDecimal` 的基礎類型。

同時，我們將開發一個新的二進制實現的 `BigBinaryInt`，作為核心整數類型。

一旦 `BigBinaryInt` 穩定並且性能優越，我們將進行更名：

- `BigInt` 將改為 `BigDecimalInt`
- `BigBinaryInt` 將改為 `BigInt`

然後 `BigDecimalInt` 將逐漸不對用戶暴露，最終只保留 `BigInt` (二進制實現) 和 `BigDecimal` (十進制實現)。
