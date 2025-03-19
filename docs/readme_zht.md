# DeciMojo

由 [Mojo 程序設計語言 🔥](https://www.modular.com/mojo) 實現的定點數運算庫。

## 概述

DeciMojo 爲 Mojo 提供了一個定點數類型 (Decimal) 實現，專爲處理金融計算、工程計算、以及其他需要避免浮點數捨入誤差的場景而設計。

## 安裝

您可以直接通過在 Modular CLI 中輸入 `magic add decimojo` 將 DeciMojo 添加到您的項目環境中。此命令會獲取最新版本的 DeciMojo，並使您在 Mojo 項目中導入之。

要使用 DeciMojo，請從 `decimojo.prelude` 模塊導入必要的組件。該模塊提供對最常用類和函數的便捷訪問，包括 `dm`（`decimojo` 模塊本身的別名）、`Decimal` 和 `RoundingMode`。

```mojo
from decimojo.prelude import dm, Decimal, RoundingMode

fn main() raises:
    # 計算標準轎車車輪面積 (平方釐米)
    var r = Decimal("33.958")      # 釐米半徑
    var pi = Decimal("3.1415926")  # 圓周率
    var area = pi * r * r          # 圓面積
    print(area)                    # 3622.7141989037464
```

此項目的 Github 倉庫位於 [https://github.com/forfudan/decimojo](https://github.com/forfudan/decimojo)。

## 示例

`Decimal` 類型可以表示最多 29 位有效數字，小數點後最多 28 位數字的值。當數值超過最大可表示值（`2^96 - 1`）時，DeciMojo 會拋出錯誤或將數值捨入以符合這些約束。例如，`8.8888888888888888888888888888`（總共 29 個 8，小數點後 28 位）的有效數字超過了最大可表示值（`2^96 - 1`），會自動捨入爲 `8.888888888888888888888888889`（總共 28 個 8，小數點後 27 位）。

以下是 8 個關鍵示例，突出展示了 `Decimal` 類型當前狀態下的最重要特性：

### 1. 財務計算中的定點數

```mojo
from decimojo import dm, Decimal

# 經典的浮點數問題
print(0.1 + 0.2)  # 0.30000000000000004（不完全是 0.3）

# Decimal 通過精確表示解決了這個問題
var d1 = Decimal("0.1")
var d2 = Decimal("0.2")
var sum = d1 + d2
print(sum)  # 精確的 0.3

# 財務計算示例 - 計算税款
var price = Decimal("19.99")
var tax_rate = Decimal("0.0725")
var tax = price * tax_rate  # 精確的 1.449275
var total = price + tax     # 精確的 21.439275
```

### 2. 四則運算與銀行家捨入

```mojo
# 不同精度的加法
var a = Decimal("123.45")
var b = Decimal("67.8")
print(a + b)  # 191.25（保留最高精度）

# 減法與負結果
var c = Decimal("50")
var d = Decimal("75.25")
print(c - d)  # -25.25

# 乘法與銀行家捨入（捨入到偶數）
var e = Decimal("12.345")
var f = Decimal("5.67")
print(round(e * f, 2))  # 69.96（捨入到最接近的偶數）

# 除法與銀行家捨入
var g = Decimal("10")
var h = Decimal("3")
print(round(g / h, 2))  # 3.33（按銀行家方式捨入）
```

### 3. 比例與精度管理

```mojo
# 比例 (scale) 是指小數位數
var d1 = Decimal("123.45")
print(d1.scale())  # 2

# 通過顯式捨入控制精度
var d2 = Decimal("123.456")
print(d2.round_to_scale(1))  # 123.5（銀行家捨入）

# 保留高精度（最多28位小數）
var precise = Decimal("0.1234567890123456789012345678")
print(precise)  # 0.1234567890123456789012345678
```

### 4. 正負號與絶對值

```mojo
# 取反運算符
var pos = Decimal("123.45")
var neg = -pos
print(neg)  # -123.45

# 絶對值
var abs_val = abs(Decimal("-987.65"))
print(abs_val)  # 987.65

# 正負號檢查
print(Decimal("-123.45").is_negative())  # True
print(Decimal("0").is_negative())        # False

# 乘法中的符號保留
print(Decimal("-5") * Decimal("3"))      # -15 
print(Decimal("-5") * Decimal("-3"))     # 15
```

### 5. 高級數學運算

```mojo
# 高精度平方根實現
var root2 = Decimal("2").sqrt()
print(root2)  # 1.4142135623730950488016887242

# 非完全平方數的平方根
var root_15_9999 = Decimal("15.9999").sqrt()
print(root_15_9999)  # 3.9999874999804686889646053305

# 整數冪運算，使用快速二進制冪
var cubed = Decimal("3") ** 3
print(cubed)  # 27

# 負冪（倒數）
var recip = Decimal("2") ** (-1)
print(recip)  # 0.5
```

### 6. 穩健的邊緣情況處理

```mojo
# 除零錯誤被正確捕獲
try:
    var result = Decimal("10") / Decimal("0")
except:
    print("正確檢測到除以零")

# 零的負冪
try:
    var invalid = Decimal("0") ** (-1)
except:
    print("正確檢測到零的負冪")
    
# 溢出檢測與預防
var max_val = Decimal.MAX()
try:
    var overflow = max_val * Decimal("2")
except:
    print("正確檢測到溢出")
```

### 7. 比較大小

```mojo
# 具有不同小數位數的相等值
var a = Decimal("123.4500")
var b = Decimal("123.45")
print(a == b)  # True（數值相等）

# 比較運算符
var c = Decimal("100")
var d = Decimal("200")
print(c < d)   # True
print(c <= d)  # True
print(c > d)   # False
print(c >= d)  # False
print(c != d)  # True
```

### 8. 真實世界財經案例

```mojo
# 等額還貸下的月供計算
var principal = Decimal("200000")  # $200,000 貸款
var annual_rate = Decimal("0.05")  # 5% 利率
var monthly_rate = annual_rate / Decimal("12")
var num_payments = Decimal("360")  # 30年

# 月供公式: P * r(1+r)^n/((1+r)^n-1)
var numerator = monthly_rate * (Decimal("1") + monthly_rate) ** 360
var denominator = (Decimal("1") + monthly_rate) ** 360 - Decimal("1")
var payment = principal * (numerator / denominator)
print("月供: $" + String(round(payment, 2)))  # $1,073.64
```

## 優勢

DeciMojo 提供了卓越的計算精度，同時不犧牲性能。在複雜計算中，它保持準確度，而浮點數或其他小數實現可能會引入微妙的誤差。

考慮 `15.9999` 的平方根。比較 DeciMojo 的實現與 Python 的 decimal 模塊（兩者都捨入到 16 位小數）：

- DeciMojo 計算結果：`3.9999874999804687`
- Python 的 decimal 返回：`3.9999874999804685`

數學上正確的值（50+ 位數）是：
`3.9999874999804686889646053303778122644631365491812...`

當捨入到 16 位小數時，正確結果是 `3.9999874999804687`，證實 DeciMojo 在這種情況下産生了更精確的結果。

```log
函數：                     sqrt()
Decimal 值：               15.9999
DeciMojo 結果：            3.9999874999804686889646053305
Python decimal 結果：      3.9999874999804685
```

這種精度優勢在金融、科學和工程計算中變得越來越重要，因爲小的捨入誤差可能累積成顯著的差異。

## 目標

金融計算和數據分析需要精確的小數算術，而浮點數無法可靠地提供這種精確性。作爲一名從事金融學研究和信用風險模型驗證工作的人員，在將個人項目從 Python 遷移到 Mojo 時，我需要一個可靠的、能够正確捨入的、固定精度的數值類型。

由於 Mojo 目前在其標準庫中缺乏原生的 Decimal 類型，我決定創建自己的實現來填補這一空白。

本項目從多個已建立的小數實現和文檔中汲取靈感，例如 [Python 内置的 `Decimal` 類型](https://docs.python.org/3/library/decimal.html)，[Rust 的 `rust_decimal` crate](https://docs.rs/rust_decimal/latest/rust_decimal/index.html)，[Microsoft 的 `Decimal` 實現](https://learn.microsoft.com/en-us/dotnet/api/system.decimal.getbits?view=net-9.0&redirectedfrom=MSDN#System_Decimal_GetBits_System_Decimal_)，[通用小數算術規範](https://speleotrove.com/decimal/decarith.html) 等。非常感謝前輩們的貢獻及其對開放知識共享的促進。

## 命名

DeciMojo 結合了 "Decimal" 和 "Mojo" 兩詞，反映了其目的（小數算術）和其實現所用的程序設計語言。該名稱强調了本項目旨在將精確小數計算引入 Mojo 生態系統。

爲簡潔起見，您可以將其稱爲"deci"（源自拉丁詞根"decimus"，意爲"十分之一"）。

它的中文名爲「得此魔咒」。

> 得此魔咒者，即脱凡相，識天數，斬三尸，二十七日飛升。
> —— 《太上靈通感應二十七章經》

## 狀態

羅馬不是一日建成的。DeciMojo 目前正在積極開發中，處於**"讓它工作"**和**"讓它正確"**階段之間，更偏重於後者。歡迎錯誤報告和功能請求！如果您遇到問題，請[在此提交](https://github.com/forfudan/decimojo/issues)。

### 讓它工作 ✅（基本完成）

- 核心小數實現已存在並運作
- 已實現基本算術運算（+, -, *, /）
- 各類型間的轉換能正常工作
- 字符串表示和解析功能正常
- 支持從不同來源（字符串、數字）構造

### 讓它正確 🔄（進行中）

- 正在處理邊緣情況（除以零、零的負冪）
- 精度和比例管理表現出複雜性
- 財務計算展示了正確的捨入
- 實現了高精度支持（最多28位小數）
- 示例展示了對各種場景的穩健處理

### 讓它快速 ⏳（進行中 & 未來工作）

- 核心算術運算（+, -, *, /）已針對性能進行了優化，並提供了與 Python 内置 decimal 模塊進行比較的全面基準測試報告（[PR#16](https://github.com/forfudan/decimojo/pull/16)、[PR#20](https://github.com/forfudan/decimojo/pull/20)、[PR#21](https://github.com/forfudan/decimojo/pull/21)）。
- 定期對比 Python 的 `decimal` 模塊進行基準測試（見 `bench/` 文件夾）
- 其他函數的性能優化正緩步進行，但不是當前優先事項

## 測試與基準

在將倉庫克隆到本地磁盤後，您可以：

- 使用 `magic run test`（或 `maigic run t`）運行測試。
- 使用 `magic run bench`（或 `magic run b`）生成對比 `python.decimal` 模塊的基準測試日誌。日誌文件保存在 `benches/logs/` 中。

## 引用

如果您發現 DeciMojo 對您的研究有用，請考慮將它加入您的引用中。

```tex
@software{Zhu.2025,
    author       = {Zhu, Yuhao},
    year         = {2025},
    title        = {DeciMojo: A fixed-point decimal arithmetic library in Mojo},
    url          = {https://github.com/forfudan/decimojo},
    version      = {0.1.0},
    note         = {Computer Software}
}
```

## 許可證

本倉庫及其所有貢獻内容均採用 Apache 許可證 2.0 版本授權。
