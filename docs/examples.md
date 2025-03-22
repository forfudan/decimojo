# Examples on Decimal

Here are 8 key examples highlighting the most important features of the `Decimal` type in its current state:

## 1. Fixed-Point Precision for Financial Calculations

```mojo
from decimojo import dm, Decimal

# The classic floating-point problem
print(0.1 + 0.2)  # 0.30000000000000004 (not exactly 0.3)

# Decimal solves this with exact representation
var d1 = Decimal("0.1")
var d2 = Decimal("0.2")
var sum = d1 + d2
print(sum)  # Exactly 0.3

# Financial calculation example - computing tax
var price = Decimal("19.99")
var tax_rate = Decimal("0.0725")
var tax = price * tax_rate  # Exactly 1.449275
var total = price + tax     # Exactly 21.439275
```

## 2. Basic Arithmetic with Proper Banker's Rounding

```mojo
# Addition with different scales
var a = Decimal("123.45")
var b = Decimal("67.8")
print(a + b)  # 191.25 (preserves highest precision)

# Subtraction with negative result
var c = Decimal("50")
var d = Decimal("75.25")
print(c - d)  # -25.25

# Multiplication with banker's rounding (round to even)
var e = Decimal("12.345")
var f = Decimal("5.67")
print(round(e * f, 2))  # 69.96 (rounds to nearest even)

# Division with banker's rounding
var g = Decimal("10")
var h = Decimal("3")
print(round(g / h, 2))  # 3.33 (rounded banker's style)
```

## 3. Scale and Precision Management

```mojo
# Scale refers to number of decimal places
var d1 = Decimal("123.45")
print(d1.scale())  # 2

# Precision control with explicit rounding
var d2 = Decimal("123.456")
print(d2.round_to_scale(1))  # 123.5 (banker's rounding)

# High precision is preserved (up to 28 decimal places)
var precise = Decimal("0.1234567890123456789012345678")
print(precise)  # 0.1234567890123456789012345678
```

## 4. Sign Handling and Absolute Value

```mojo
# Negation operator
var pos = Decimal("123.45")
var neg = -pos
print(neg)  # -123.45

# Absolute value
var abs_val = abs(Decimal("-987.65"))
print(abs_val)  # 987.65

# Sign checking
print(Decimal("-123.45").is_negative())  # True
print(Decimal("0").is_negative())        # False

# Sign preservation in multiplication
print(Decimal("-5") * Decimal("3"))      # -15 
print(Decimal("-5") * Decimal("-3"))     # 15
```

## 5. Advanced Mathematical Operations

```mojo
# Highly accurate square root implementation
var root2 = Decimal("2").sqrt()
print(root2)  # 1.4142135623730950488016887242

# Square root of imperfect squares
var root_15_9999 = Decimal("15.9999").sqrt()
print(root_15_9999)  # 3.9999874999804686889646053305

# Integer powers with fast binary exponentiation
var cubed = Decimal("3") ** 3
print(cubed)  # 27

# Negative powers (reciprocals)
var recip = Decimal("2") ** (-1)
print(recip)  # 0.5
```

## 6. Robust Edge Case Handling

```mojo
# Division by zero is properly caught
try:
    var result = Decimal("10") / Decimal("0")
except:
    print("Division by zero properly detected")

# Zero raised to negative power
try:
    var invalid = Decimal("0") ** (-1)
except:
    print("Zero to negative power properly detected")
    
# Overflow detection and prevention
var max_val = Decimal.MAX()
try:
    var overflow = max_val * Decimal("2")
except:
    print("Overflow correctly detected")
```

## 7. Equality and Comparison Operations

```mojo
# Equal values with different scales
var a = Decimal("123.4500")
var b = Decimal("123.45")
print(a == b)  # True (numeric value equality)

# Comparison operators
var c = Decimal("100")
var d = Decimal("200")
print(c < d)   # True
print(c <= d)  # True
print(c > d)   # False
print(c >= d)  # False
print(c != d)  # True
```

## 8. Real World Financial Examples

```mojo
# Monthly loan payment calculation with precise interest
var principal = Decimal("200000")  # $200,000 loan
var annual_rate = Decimal("0.05")  # 5% interest rate
var monthly_rate = annual_rate / Decimal("12")
var num_payments = Decimal("360")  # 30 years

# Monthly payment formula: P * r(1+r)^n/((1+r)^n-1)
var numerator = monthly_rate * (Decimal("1") + monthly_rate) ** 360
var denominator = (Decimal("1") + monthly_rate) ** 360 - Decimal("1")
var payment = principal * (numerator / denominator)
print("Monthly payment: $" + String(round(payment, 2)))  # $1,073.64
```
