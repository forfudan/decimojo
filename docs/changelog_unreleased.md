# DeciMojo unreleased changelog

This is a list of UNRELEASED changes for the DeciMojo Package. For the released changes, please refer to **[changelog](https://zhuyuhao.com/decimojo/docs/changelog.html)**.

### ⭐️ New

- Add comprehensive `BigDecimal` implementation with unlimited precision arithmetic.

### 🛠️ Fixed

- Fix a bug in `BigUInt` multiplication where the calcualtion of carry is mistakenly skipped if a word of x2 is zero (PR #70).
