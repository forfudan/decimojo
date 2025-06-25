# DeciMojo

由 [Mojo 程序設計語言 🔥](https://www.modular.com/mojo) 實現的定點數和整數運算庫。

**[GitHub 倉庫»](https://github.com/forfudan/decimojo)**

## 概述

DeciMojo 爲 Mojo 提供了全面的定點數和整數運算庫，專爲處理金融計算、工程計算、以及其他需要避免浮點數捨入誤差的場景而設計。

核心類型包括:

- 128 位定點數 (`Decimal`)，支持最多 29 位有效數字，小數點後最多 28 位數字[^fixed]。
- 任意精度定點數 (`BigDecimal`) ，允許進行無限位數和小數位的計算。
- 基於 10 進制的任意精度有符號整數 (`BigInt`) 和任意精度無符號整數 (`BigUInt`)[^integer]，支持無限位數。它具有全面的算術運算、比較功能，並能高效支持超大整數計算。

## 安裝

DeciMojo 可在 [modular-community](https://repo.prefix.dev/modular-community) 包倉庫中獲取。您可以使用以下任一方法進行安裝：

從 `pixi` CLI，只需運行 ```pixi add decimojo```。這會獲取最新版本並使其立即可用於導入。

對於帶有 `mojoproject.toml` 文件的項目，添加依賴 ```decimojo = "==0.4.0"```。然後運行 `pixi install` 來下載並安裝包。

如需最新的開發版本，請克隆 [GitHub 倉庫](https://github.com/forfudan/decimojo) 並在本地構建包。

| `decimojo` | `mojo`        | 包管理 |
| ---------- | ------------- | ------ |
| v0.1.0     | >=25.1        | magic  |
| v0.2.0     | >=25.2        | magic  |
| v0.3.0     | >=25.2        | magic  |
| v0.3.1     | >=25.2, <25.4 | pixi   |
| v0.4.0     | ==25.4        | pixi   |

## 快速入門

以下是展示 `Decimal` 類型每個主要功能的全面快速入門指南。

```mojo
from decimojo import Decimal, RoundingMode

fn main() raises:
    # === 構造 ===
    var a = Decimal("123.45")                        # 從字符串
    var b = Decimal(123)                             # 從整數
    var c = Decimal(123, 2)                          # 帶比例的整數 (1.23)
    var d = Decimal.from_float(3.14159)              # 從浮點數
    
    # === 基本算術 ===
    print(a + b)                                     # 加法: 246.45
    print(a - b)                                     # 減法: 0.45
    print(a * b)                                     # 乘法: 15184.35
    print(a / b)                                     # 除法: 1.0036585365853658536585365854
    
    # === 捨入與精度 ===
    print(a.round(1))                                # 捨入到1位小數: 123.5
    print(a.quantize(Decimal("0.01")))               # 格式化到2位小數: 123.45
    print(a.round(0, RoundingMode.ROUND_DOWN))       # 向下捨入到整數: 123
    
    # === 比較 ===
    print(a > b)                                     # 大於: True
    print(a == Decimal("123.45"))                    # 等於: True
    print(a.is_zero())                               # 檢查是否爲零: False
    print(Decimal("0").is_zero())                    # 檢查是否爲零: True
    
    # === 類型轉換 ===
    print(Float64(a))                                # 轉爲浮點數: 123.45
    print(a.to_int())                                # 轉爲整數: 123
    print(a.to_str())                                # 轉爲字符串: "123.45"
    print(a.coefficient())                           # 獲取係數: 12345
    print(a.scale())                                 # 獲取比例: 2
    
    # === 數學函數 ===
    print(Decimal("2").sqrt())                       # 平方根: 1.4142135623730950488016887242
    print(Decimal("100").root(3))                    # 立方根: 4.641588833612778892410076351
    print(Decimal("2.71828").ln())                   # 自然對數: 0.9999993273472820031578910056
    print(Decimal("10").log10())                     # 10爲底的對數: 1
    print(Decimal("16").log(Decimal("2")))           # 以2爲底的對數: 3.9999999999999999999999999999
    print(Decimal("10").exp())                       # e^10: 22026.465794806716516957900645
    print(Decimal("2").power(10))                    # 冪: 1024
    
    # === 符號處理 ===
    print(-a)                                        # 取反: -123.45
    print(abs(Decimal("-123.45")))                   # 絕對值: 123.45
    print(Decimal("123.45").is_negative())           # 檢查是否爲負: False
    
    # === 特殊值 ===
    print(Decimal.PI())                              # π常數: 3.1415926535897932384626433833
    print(Decimal.E())                               # e常數: 2.7182818284590452353602874714
    print(Decimal.ONE())                             # 值1: 1
    print(Decimal.ZERO())                            # 值0: 0
    print(Decimal.MAX())                             # 最大值: 79228162514264337593543950335
    
    # === 便捷方法 ===
    print(Decimal("123.400").is_integer())           # 檢查是否爲整數: False
    print(a.number_of_significant_digits())          # 計算有效數字: 5
    print(Decimal("12.34").to_str_scientific())      # 科學計數法: 1.234E+1
```

以下是展示 `BigInt` 類型每個主要功能的全面快速入門指南。

```mojo
from decimojo import BigInt

fn main() raises:
    # === 構造 ===
    var a = BigInt("12345678901234567890")         # 從字符串構造
    var b = BigInt(12345)                          # 從整數構造
    
    # === 基本算術 ===
    print(a + b)                                   # 加法: 12345678901234580235
    print(a - b)                                   # 減法: 12345678901234555545
    print(a * b)                                   # 乘法: 152415787814108380241050
    
    # === 除法運算 ===
    print(a // b)                                  # 向下整除: 999650944609516
    print(a.truncate_divide(b))                    # 截斷除法: 999650944609516
    print(a % b)                                   # 取模: 9615
    
    # === 冪運算 ===
    print(BigInt(2).power(10))                     # 冪: 1024
    print(BigInt(2) ** 10)                         # 冪 (使用 ** 運算符): 1024
    
    # === 比較 ===
    print(a > b)                                   # 大於: True
    print(a == BigInt("12345678901234567890"))     # 等於: True
    print(a.is_zero())                             # 檢查是否爲零: False
    
    # === 類型轉換 ===
    print(a.to_str())                              # 轉爲字符串: "12345678901234567890"
    
    # === 符號處理 ===
    print(-a)                                      # 取反: -12345678901234567890
    print(abs(BigInt("-12345678901234567890")))    # 絕對值: 12345678901234567890
    print(a.is_negative())                         # 檢查是否爲負: False

    # === 超大數值計算 ===
    # 3600 位數 // 1800 位數
    print(BigInt("123456789" * 400) // BigInt("987654321" * 200))
```

## 目標

金融計算和數據分析需要精確的小數算術，而浮點數無法可靠地提供這種精確性。作爲一名從事金融學研究和信用風險模型驗證工作的人員，在將個人項目從 Python 遷移到 Mojo 時，我需要一個可靠的、能够正確捨入的、固定精度的數值類型。

由於 Mojo 目前在其標準庫中缺乏原生的 Decimal 類型，我決定創建自己的實現來填補這一空白。

本項目從多個已建立的小數實現和文檔中汲取靈感，例如 [Python 内置的 `Decimal` 類型](https://docs.python.org/3/library/decimal.html)，[Rust 的 `rust_decimal` crate](https://docs.rs/rust_decimal/latest/rust_decimal/index.html)，[Microsoft 的 `Decimal` 實現](https://learn.microsoft.com/en-us/dotnet/api/system.decimal.getbits?view=net-9.0&redirectedfrom=MSDN#System_Decimal_GetBits_System_Decimal_)，[通用小數算術規範](https://speleotrove.com/decimal/decarith.html) 等。非常感謝前輩們的貢獻及其對開放知識共享的促進。

## 命名

> 得此魔咒者，即脱凡相，識天數，斬三尸，二十七日飛升。
> —— 《太上靈通感應二十七章經》

DeciMojo 結合了 "Deci" 和 "Mojo" 兩詞，反映了其目的和實現語言。"Deci"（源自拉丁詞根"decimus"，意爲"十分之一"）強調了我們對人類自然用於計數和計算的十進制數字系統的關注。

雖然名稱強調了帶小數部分的十進制數，但 DeciMojo 涵蓋了十進制數學的全部範圍。我們的 `BigInt` 類型雖然只處理整數，但專爲十進制數字系統設計，採用以 10 爲基數的内部表示。這種方法在保持人類可讀的十進制語義的同時提供最佳性能，與專注於二進制的庫形成對比。此外，`BigInt` 作爲我們 `BigDecimal` 實現的基礎，使得在整數和小數領域都能進行任意精度的計算。

這個名稱最終強調了我們的使命：爲 Mojo 生態系統帶來精確、可靠的十進制計算，滿足浮點表示無法提供的精確算術的基本需求。

## 狀態

羅馬不是一日建成的。DeciMojo 目前正在積極開發中。對於 128 位的 `Decimal` 類型，它已成功通過 **"讓它工作"** 階段，並已深入 **"讓它正確"** 階段，同時已實施多項優化。歡迎錯誤報告和功能請求！如果您遇到問題，請[在此提交](https://github.com/forfudan/decimojo/issues)。

### 讓它工作 ✅（已完成）

- 核心小數實現採用穩健的 128 位表示（96 位係數 + 32 位標誌）
- 全面的算術運算（+, -, *, /, %, **）並正確處理溢出
- 各類型間的轉換（字符串、整數、浮點數等）
- 特殊值（NaN、無限）的適當表示
- 具有正確十進制語義的完整比較運算符集

### 讓它正確 🔄（大部分完成）

- 重組的代碼庫具有模塊化結構（小數、算術、比較、指數等）
- 處理所有運算的邊緣情況（除以零、零的負冪等）
- 精度和比例管理表現出複雜性
- 財務計算展示了正確的捨入（ROUND_HALF_EVEN）
- 高精度高級數學函數（開方、根源、對數、指數等）
- 正確實現特徵（可取絶對值、可比較、可轉爲浮點、可捨入等）
- **BigInt 和 BigUInt** 實現提供完整的算術運算、正確的除法語義（向下整除和截斷除法），以及支持任意精度計算

### 讓它快速 ⚡（顯著進展）

DeciMojo 相較於 Python 的 `decimal` 模塊提供了卓越的性能，同時保持計算精確度。這一性能差異源於基本設計選擇：

- **DeciMojo**：使用固定的 128 位表示（96 位係數 + 32 位標誌），最多支持 28 位小數，針對現代硬件和 Mojo 的性能能力進行了優化。
- **Python decimal**：實現任意精度，可表示具有無限有效位數的數字，但需要動態内存分配和更複雜的算法。

此架構差異解釋了我們的基準測試結果：

- 核心算術運算（+, -, *, /）比 Python 的 decimal 模塊快 100-3500 倍。
- 特殊情況處理（0 的冪、1 的冪等）顯示出高達 3500 倍的性能提升。
- 高級數學函數（sqrt、ln、exp）展示了 5-600 倍的更好性能。
- 只有特定的邊緣情況（例如計算 10^(1/100)）偶爾在 Python 中表現更好，這是由於其任意精度算法。

`bench/` 文件夾中提供了與 Python 的 `decimal` 模塊的定期基準測試，記錄了性能優勢以及需要不同方法的少數特定操作。

### 未來擴展 🚀（計劃中）

- **BigDecimal**：🔄 **進行中** - 具有可配置精度的任意精度小數類型[^arbitrary]。
- **BigComplex**：📝 **計劃中** - 基於 BigDecimal 構建的任意精度複數類型。

## 測試與基準

在將倉庫克隆到本地磁盤後，您可以：

- 使用 `pixi run test`（或 `pixi run t`）運行測試。
- 使用 `pixi run bench`（或 `pixi run b`）生成對比 `python.decimal` 模塊的基準測試日誌。日誌文件保存在 `benches/logs/` 中。

## 引用

如果您發現 DeciMojo 對您的研究有用，請考慮將它加入您的引用中。

```tex
@software{Zhu.2025,
    author       = {Zhu, Yuhao},
    year         = {2025},
    title        = {DeciMojo: A fixed-point decimal arithmetic library in Mojo},
    url          = {https://github.com/forfudan/decimojo},
    version      = {0.4.0},
    note         = {Computer Software}
}
```

## 許可證

本倉庫及其所有貢獻内容均採用 Apache 許可證 2.0 版本授權。

[^fixed]: Decimal 類型可以表示最多 29 位有效數字，小數點後最多 28 位數字的值。當數值超過最大可表示值（2^96 - 1）時，DeciMojo 會拋出錯誤或將數值捨入以符合這些約束。例如，8.8888888888888888888888888888（總共 29 個 8，小數點後 28 位）的有效數字超過了最大可表示值（2^96 - 1），會自動捨入爲 8.888888888888888888888888889（總共 28 個 8，小數點後 27 位）。DeciMojo 的 Decimal 類型類似於 System.Decimal（C#/.NET）、Rust 中的 rust_decimal、SQL Server 中的 DECIMAL/NUMERIC 等。

[^integer]: BigInt 實現使用基於 10 的表示進行高效存儲和計算，支持對具有無限精度的整數進行操作。它提供了向下整除（向負無窮舍入）和截斷除法（向零舍入）語義，無論操作數符號如何，都能確保除法操作處理具有正確的數學行爲。

[^arbitrary]: 基於已完成的 BigInt 實現構建，BigDecimal 將支持整數和小數部分的任意精度，類似於 Python 中的 decimal 和 mpmath、Java 中的 java.math.BigDecimal 等。
