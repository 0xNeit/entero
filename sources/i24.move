module entero::i24 {
  /// The 24-bit signed integer type.
  /// Represented as an underlying u32 value.
  /// Actual value is underlying value minus 2 ^ 24
  /// Max value is 2 ^ 24 - 1, min value is - 2 ^ 24
  struct I24 has copy, drop, store{
    underlying: u32,
  }

  const ERR_OVERFLOW: u64 = 1000;
  const ERR_DIVISION_BY_ZERO: u64 = 1001;

  /// Function for creating I24 from u32
  public fun from(underlying: u32): I24 {
    assert!(underlying < 16777216u32, ERR_OVERFLOW);
    I24 { underlying }
  }

  public fun to(i24: I24): u32 {
    i24.underlying
  }

  public fun eq(a: I24, b: I24): bool {
    a.underlying == b.underlying
  }

  public fun gt(a: I24, b: I24): bool {
    a.underlying > b.underlying && a.underlying < 8388608u32
  }

  public fun lt(a: I24, b: I24): bool {
    a.underlying < b.underlying && a.underlying > 8388608u32
  }

  public fun indent(): u32 {
    // With 24 bits max value that can be expressed is 16,777,215
    // i24 required values are from negative 8,388,608 to positive 8,388,607
    // So zero value must be 8,388,608 to cover the full range
    8388608u32
  }

  public fun new(): I24 {
    I24 {
      underlying: indent()
    }
  }

  public fun abs(x: I24): u32 {
    let is_gt_zero: bool = (x.underlying > indent()) || (x.underlying == indent());
    let abs_pos = x.underlying - indent();
    let abs_neg = indent() + (indent() - x.underlying);
    let abs_value;
    if (is_gt_zero) {
      abs_value = abs_pos
    } else {
      abs_value = abs_neg
    };

    abs_value
  }
    
  /// The smallest value that can be represented by this integer type.
  public fun min(): I24 {
    // Return 0u32 which is actually  negative 8,388,608
    I24 {
      underlying: 0u32,
    }
  }

  /// The largest value that can be represented by this type,
  public fun max(): I24 {
    // Return max 24-bit number which is actually 8,388,607
    I24 {
      underlying: 16777215u32,
    }
  }

  /// The size of this type in bits.
  public fun bits(): u32 {
    24u32
  }
    
  /// Helper function to get a negative value of unsigned numbers
  public fun from_neg(value: u32): I24 {
    I24 {
      underlying: indent() + value,
    }
  }

  /// Helper function to get a positive value from unsigned number
  public fun from_pos(value: u32): I24 {
    // as the minimal value of I24 is 2147483648 (1 << 31) we should add indent() (1 << 31) 
    let underlying: u32 = value;
    assert!(underlying < 8388608u32, ERR_OVERFLOW);
    I24 { underlying }
  }

  public fun from_uint_bool(value: u32, is_neg: bool): I24 {
    // as the minimal value of I24 is 2147483648 (1 << 31) we should add indent() (1 << 31) 
    if (is_neg) {
      return I24 {
        underlying: indent() + value,
      }
    } else {
      let underlying: u32 = value;
      assert!(underlying < 8388608u32, ERR_OVERFLOW);
      return I24 { underlying }
    }
  }

  public fun modulo(a: I24, b: I24): I24 {
    let remainder = abs(a) % abs(b);
    if (a.underlying > indent() && b.underlying > indent()) {
      return from_pos(remainder)
    } else if (a.underlying < indent() && b.underlying < indent()) {
      return from_pos(remainder)
    } else {
      return from_neg(remainder)
    }
  }

  public fun add(a: I24, b: I24): I24 {
    // subtract 1 << 24 to avoid a double move, then from will perform the overflow check
    from(a.underlying - indent() + b.underlying)
  }

  public fun subtract(a: I24, b: I24): I24 {
    let res;
    if (a.underlying > indent()) {
      // add 1 << 31 to avoid loosing the move
      res = from(a.underlying - b.underlying + indent());
    } else {
      // subtract from 1 << 31 as we are getting a negative value
      res = from(indent() - (b.underlying - a.underlying));
    };

    res
  }

  public fun multiply(a: I24, b: I24): I24 {
    let res = new();
    if (a.underlying >= indent() && b.underlying >= indent()) {
      res = from((a.underlying - indent()) * (b.underlying - indent()) + indent());
    } else if (a.underlying < indent() && b.underlying < indent()) {
      res = from((indent() - a.underlying) * (indent() - b.underlying) + indent());
    } else if (a.underlying >= indent() && b.underlying < indent()) {
      res = from(indent() - (a.underlying - indent()) * (indent() - b.underlying));
    } else if (a.underlying < indent() && b.underlying >= indent()) {
      res = from(indent() - (b.underlying - indent()) * (indent() - a.underlying));
    };

    // Overflow protection
    assert!((lt(res, max())) || (eq(res, max())), ERR_OVERFLOW);

    res
  }

  public fun divide(self: I24, divisor: I24): I24 {
    assert!(!eq(divisor, new()), ERR_DIVISION_BY_ZERO);
    let res = new();
    if (self.underlying >= indent() && divisor.underlying > indent()) {
      res = from((self.underlying - indent()) / (divisor.underlying - indent()) + indent());
    } else if (self.underlying < indent() && divisor.underlying < indent()) {
      res = from((indent() - self.underlying) / (indent() - divisor.underlying) + indent());
    } else if (self.underlying >= indent() && divisor.underlying < indent()) {
      res = from(indent() - (self.underlying - indent()) / (indent() - divisor.underlying));
    } else if (self.underlying < indent() && divisor.underlying > indent()) {
      res = from(indent() - (indent() - self.underlying) / (divisor.underlying - indent()));
    };
    
    res
  }
}