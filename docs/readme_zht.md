# DeciMojo

由 [Mojo 程序設計語言 🔥](https://www.modular.com/mojo) 實現的定點數和整數運算庫。

**[GitHub 倉庫»](https://github.com/forfudan/decimojo)**

## 概述

DeciMojo 爲 Mojo 提供了全面的定點數和整數運算庫，專爲處理金融計算、工程計算、以及其他需要避免浮點數捨入誤差的場景而設計。

核心類型包括:

- 128 位定點數 (`Decimal128`)，支持最多 29 位有效數字，小數點後最多 28 位數字[^fixed]。
- 任意精度定點數 (`BigDecimal`) ，允許進行無限位數和小數位的計算。
- 基於 10 進制的任意精度有符號整數 (`BigInt`) 和任意精度無符號整數 (`BigUInt`)[^integer]，支持無限位數。它具有全面的算術運算、比較功能，並能高效支持超大整數計算。

## 安裝

DeciMojo 可在 [modular-community](https://repo.prefix.dev/modular-community) 包倉庫中獲取。您可以使用以下任一方法進行安裝：

從 `pixi` CLI，只需運行 ```pixi add decimojo```。這會獲取最新版本並使其立即可用於導入。

對於帶有 `mojoproject.toml` 文件的項目，添加依賴 ```decimojo = "==0.4.1"```。然後運行 `pixi install` 來下載並安裝包。

如需最新的開發版本，請克隆 [GitHub 倉庫](https://github.com/forfudan/decimojo) 並在本地構建包。

| `decimojo` | `mojo`        | 包管理 |
| ---------- | ------------- | ------ |
| v0.1.0     | >=25.1        | magic  |
| v0.2.0     | >=25.2        | magic  |
| v0.3.0     | >=25.2        | magic  |
| v0.3.1     | >=25.2, <25.4 | pixi   |
| v0.4.x     | ==25.4        | pixi   |

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

羅馬不是一日建成的。DeciMojo 目前正在積極開發中。它已成功通過 **"讓它工作"** 階段，並已深入 **"讓它正確"** 階段，同時已實施多項優化。歡迎錯誤報告和功能請求！如果您遇到問題，請[在此提交](https://github.com/forfudan/decimojo/issues)。

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
    version      = {0.4.1},
    note         = {Computer Software}
}
```

## 許可證

本倉庫及其所有貢獻内容均採用 Apache 許可證 2.0 版本授權。

[^fixed]: Decimal128 類型可以表示最多 29 位有效數字，小數點後最多 28 位數字的值。當數值超過最大可表示值（2^96 - 1）時，DeciMojo 會拋出錯誤或將數值捨入以符合這些約束。例如，8.8888888888888888888888888888（總共 29 個 8，小數點後 28 位）的有效數字超過了最大可表示值（2^96 - 1），會自動捨入爲 8.888888888888888888888888889（總共 28 個 8，小數點後 27 位）。DeciMojo 的 Decimal128 類型類似於 System.Decimal（C#/.NET）、Rust 中的 rust_decimal、SQL Server 中的 DECIMAL/NUMERIC 等。

[^integer]: BigInt 實現使用基於 10 的表示進行高效存儲和計算，支持對具有無限精度的整數進行操作。它提供了向下整除（向負無窮舍入）和截斷除法（向零舍入）語義，無論操作數符號如何，都能確保除法操作處理具有正確的數學行爲。
