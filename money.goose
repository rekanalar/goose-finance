// The money value of the finance package.
//
// A money value holds an integer count of minor units and a currency.
// The count never uses a float. The count is an i64.
//
// The rounding modes follow the union of the reference libraries. The
// table of the modes is in the README.
//
// The multiplication by a rate uses a fraction. The package computes the
// product in a wide value of 128 bits, so that a product that does not
// fit in an i64 gives an error rather than a wrong number.
namespace finance;

import std;

// The rounding modes. Each mode rounds a value at the half way point in
// the way that its name says.
const ROUND_HALF_EVEN: i32 = 0;
const ROUND_HALF_UP: i32 = 1;
const ROUND_HALF_DOWN: i32 = 2;
const ROUND_HALF_ODD: i32 = 3;
const ROUND_UP: i32 = 4;
const ROUND_DOWN: i32 = 5;
const ROUND_CEILING: i32 = 6;
const ROUND_FLOOR: i32 = 7;
const ROUND_UNNECESSARY: i32 = 8;

// The most bytes that a text of a parse may hold. The bound keeps a
// hostile text from costing much time.
const MAX_PARSE_BYTES: i64 = 64;

// The most parts that an allocation may give. The bound keeps a hostile
// count from costing much memory.
const MAX_PARTS: i64 = 100000;

// Money is an amount of a currency. The count holds the minor units of
// the currency.
struct Money {
    minor: i64,
    code: u8[..3],
}

// Wide is a value of 128 bits. It holds the magnitude of a product that
// does not fit in an i64. The count of the high half holds the bits
// above the 64th bit.
struct Wide {
    hi: u64,
    lo: u64,
}

// checked_add gives the sum of two values. It gives false when the sum
// does not fit in an i64.
fn checked_add(a: i64, b: i64) -> i64, bool {
    if b > 0 && a > 9223372036854775807 - b { return 0, false; }
    if b < 0 && a < -9223372036854775807 - 1 - b { return 0, false; }
    return a + b, true;
}

// checked_sub gives the difference of two values. It gives false when
// the difference does not fit in an i64.
fn checked_sub(a: i64, b: i64) -> i64, bool {
    // The negation of the least value of an i64 does not fit in an i64,
    // so the case holds its own branch.
    if b == -9223372036854775807 - 1 {
        if a < 0 { return a - b, true; }
        return 0, false;
    }
    return checked_add(a, -b);
}

// checked_mul gives the product of two values. It gives false when the
// product does not fit in an i64.
fn checked_mul(a: i64, b: i64) -> i64, bool {
    if a == 0 || b == 0 { return 0, true; }
    if a > 0 {
        if b > 0 {
            if a > 9223372036854775807 / b { return 0, false; }
        } else {
            if b < -9223372036854775807 / a { return 0, false; }
        }
    } else {
        if b > 0 {
            if a < -9223372036854775807 / b { return 0, false; }
        } else {
            if a < 9223372036854775807 / b { return 0, false; }
        }
    }
    return a * b, true;
}

// wide_mul gives the product of two magnitudes. The product is a wide
// value.
fn wide_mul(a: u64, b: u64) -> Wide {
    // The halves of 32 bits make the products fit in a u64.
    let a_lo = a & 4294967295;
    let a_hi = a >> 32;
    let b_lo = b & 4294967295;
    let b_hi = b >> 32;
    let p0 = a_lo * b_lo;
    let p1 = a_lo * b_hi;
    let p2 = a_hi * b_lo;
    let p3 = a_hi * b_hi;
    // The middle part holds the carry of the low halves.
    let middle = (p0 >> 32) + (p1 & 4294967295) + (p2 & 4294967295);
    let lo = (p0 & 4294967295) | ((middle & 4294967295) << 32);
    let hi = p3 + (p1 >> 32) + (p2 >> 32) + (middle >> 32);
    return Wide { hi: hi, lo: lo };
}

// wide_shl1 gives the wide value moved one bit to the left.
fn wide_shl1(a: Wide) -> Wide {
    return Wide { hi: a.hi << 1, lo: (a.lo << 1) | (a.hi >> 63) };
}

// wide_divmod gives the quotient and the remainder of the division of a
// wide value by a divisor. The divisor must be above zero. The
// remainder is below the divisor.
//
// The division runs one bit at a time. The remainder stays below the
// divisor, so the shift of the remainder never overflows.
fn wide_divmod(num: Wide, divisor: u64) -> Wide, u64 {
    var quotient = Wide { hi: 0, lo: 0 };
    var remainder: u64 = 0;
    var at: i64 = 127;
    while at >= 0 {
        // The bit of the dividend at the place.
        var bit: u64 = 0;
        if at >= 64 {
            bit = (num.hi >> (at - 64)) & 1;
        } else {
            bit = (num.lo >> at) & 1;
        }
        // The remainder moves one bit to the left and takes the bit.
        remainder = (remainder << 1) | bit;
        // The quotient moves one bit to the left.
        quotient = wide_shl1(quotient);
        if remainder >= divisor {
            remainder -= divisor;
            quotient.lo |= 1;
        }
        at -= 1;
    }
    return quotient, remainder;
}

// wide_fits_u64 tells whether the wide value fits in a u64.
fn wide_fits_u64(a: Wide) -> bool {
    return a.hi == 0;
}

// wide_to_u64 gives the value of the wide value. The value must fit in
// a u64.
fn wide_to_u64(a: Wide) -> u64 {
    return a.lo;
}

// magnitude gives the magnitude of a value and its sign. The sign is
// true when the value is below zero.
fn magnitude(value: i64) -> u64, bool {
    if value < 0 { return 0 - (value as u64), true; }
    return value as u64, false;
}

// wide_round_div gives the quotient of the division of a magnitude by a
// divisor, rounded by the mode. The divisor must be above zero.
//
// The negative flag tells whether the value was below zero. The mode
// uses it for the modes that round toward a side.
fn wide_round_div(num: Wide, divisor: u64, mode: i32, negative: bool) -> i64, bool {
    if divisor == 0 { return 0, false; }
    let quotient, remainder = wide_divmod(num, divisor);
    if remainder == 0 {
        if !wide_fits_u64(quotient) { return 0, false; }
        let value = wide_to_u64(quotient);
        if value > 9223372036854775807 { return 0, false; }
        if negative { return -(value as i64), true; }
        return value as i64, true;
    }
    if mode == ROUND_UNNECESSARY { return 0, false; }
    // The rounding goes up when the remainder is over the half of the
    // divisor, or when it is at the half and the mode says so.
    let twice = remainder * 2;
    var up = false;
    if mode == ROUND_HALF_EVEN || mode == ROUND_HALF_UP || mode == ROUND_HALF_DOWN || mode == ROUND_HALF_ODD {
        if twice > divisor {
            up = true;
        } else if twice < divisor {
            up = false;
        } else if mode == ROUND_HALF_EVEN {
            // The half goes to the even neighbour.
            up = quotient.lo % 2 != 0;
        } else if mode == ROUND_HALF_UP {
            // The half goes away from zero.
            up = true;
        } else if mode == ROUND_HALF_DOWN {
            // The half goes toward zero.
            up = false;
        } else {
            // The half goes to the odd neighbour.
            up = quotient.lo % 2 == 0;
        }
    } else if mode == ROUND_UP {
        // The value moves away from zero.
        up = true;
    } else if mode == ROUND_DOWN {
        // The value moves toward zero.
        up = false;
    } else if mode == ROUND_CEILING {
        // The value moves toward the positive side.
        up = !negative;
    } else {
        // The value moves toward the negative side.
        up = negative;
    }
    // The quotient grows by one when the rounding goes up.
    var value = quotient;
    if up {
        value = wide_add_one(quotient);
    }
    if !wide_fits_u64(value) { return 0, false; }
    let result = wide_to_u64(value);
    if result > 9223372036854775807 { return 0, false; }
    if negative { return -(result as i64), true; }
    return result as i64, true;
}

// wide_add_one gives the wide value plus one.
fn wide_add_one(a: Wide) -> Wide {
    return Wide { hi: a.hi + (a.lo >> 63), lo: a.lo + 1 };
}

// money gives a money value. It gives false for a code that the table
// of the currencies does not hold.
fn money(minor: i64, code: const u8[:]) -> Money, bool {
    if currency_index(code) < 0 {
        return Money { minor: 0, code: "" }, false;
    }
    return Money { minor: minor, code: code[..3] }, true;
}

// money_same tells whether the two amounts hold the same currency.
fn money_same(a: Money, b: Money) -> bool {
    return a.code == b.code;
}

// money_add gives the sum of the two amounts. It gives false when the
// two currencies differ, or when the sum does not fit in an i64.
fn money_add(a: Money, b: Money) -> Money, bool {
    if !money_same(a, b) { return Money { minor: 0, code: "" }, false; }
    let sum, ok = checked_add(a.minor, b.minor);
    if !ok { return Money { minor: 0, code: "" }, false; }
    return Money { minor: sum, code: a.code }, true;
}

// money_sub gives the difference of the two amounts. It gives false when
// the two currencies differ, or when the difference does not fit in an
// i64.
fn money_sub(a: Money, b: Money) -> Money, bool {
    if !money_same(a, b) { return Money { minor: 0, code: "" }, false; }
    let diff, ok = checked_sub(a.minor, b.minor);
    if !ok { return Money { minor: 0, code: "" }, false; }
    return Money { minor: diff, code: a.code }, true;
}

// money_negate gives the amount with the opposite sign.
fn money_negate(a: Money) -> Money {
    return Money { minor: -a.minor, code: a.code };
}

// money_abs gives the amount with the sign removed.
fn money_abs(a: Money) -> Money {
    if a.minor < 0 { return money_negate(a); }
    return a;
}

// money_compare gives -1, 0 or 1. The value is the order of the two
// amounts. It gives false when the two currencies differ.
fn money_compare(a: Money, b: Money) -> i64, bool {
    if !money_same(a, b) { return 0, false; }
    if a.minor < b.minor { return -1, true; }
    if a.minor > b.minor { return 1, true; }
    return 0, true;
}

// money_min gives the least of the two amounts. It gives false when the
// two currencies differ.
fn money_min(a: Money, b: Money) -> Money, bool {
    let order, ok = money_compare(a, b);
    if !ok { return Money { minor: 0, code: "" }, false; }
    if order <= 0 { return a, true; }
    return b, true;
}

// money_max gives the largest of the two amounts. It gives false when
// the two currencies differ.
fn money_max(a: Money, b: Money) -> Money, bool {
    let order, ok = money_compare(a, b);
    if !ok { return Money { minor: 0, code: "" }, false; }
    if order >= 0 { return a, true; }
    return b, true;
}

// money_mul_ratio gives the amount multiplied by the fraction num/den.
// The count of the result never overflows. It gives false on an
// overflow or a denominator below one.
fn money_mul_ratio(a: Money, num: i64, den: i64, mode: i32) -> Money, bool {
    if den <= 0 { return Money { minor: 0, code: "" }, false; }
    // The product of the count and the numerator may not fit in an i64,
    // so it is computed in a wide value.
    let amount, amount_neg = magnitude(a.minor);
    let factor, factor_neg = magnitude(num);
    let product = wide_mul(amount, factor);
    // The sign of the product.
    let negative = amount_neg != factor_neg;
    let divisor = den as u64;
    let result, ok = wide_round_div(product, divisor, mode, negative);
    if !ok { return Money { minor: 0, code: "" }, false; }
    return Money { minor: result, code: a.code }, true;
}

// money_mul_rate gives the amount multiplied by the rate num/den. It
// gives false on an overflow or a denominator below one.
fn money_mul_rate(a: Money, num: i64, den: i64, mode: i32) -> Money, bool {
    return money_mul_ratio(a, num, den, mode);
}

// money_mul_percent gives the percentage num/den of the amount. The
// value 125/10 gives 12.5 percent. It gives false on an overflow or a
// denominator below one.
fn money_mul_percent(a: Money, num: i64, den: i64, mode: i32) -> Money, bool {
    let scaled, ok = checked_mul(den, 100);
    if !ok { return Money { minor: 0, code: "" }, false; }
    return money_mul_ratio(a, num, scaled, mode);
}

// money_round gives the amount rounded to a count of decimal places of
// the major unit. The count of the places must not be above the exponent
// of the currency. A count of zero rounds to a whole unit.
//
// The mode UNNECESSARY gives an error when the amount needs a rounding.
fn money_round(a: Money, places: i64, mode: i32) -> Money, bool {
    let exponent = currency_exponent(a.code);
    if exponent < 0 { return a, true; }
    if places < 0 || places > exponent { return Money { minor: 0, code: "" }, false; }
    // The factor holds the count of the minor units of one step of the
    // places. The count of the places 1 of a currency of exponent 2
    // holds the factor 10.
    var factor: i64 = 1;
    var i: i64 = exponent;
    while i > places {
        factor *= 10;
        i -= 1;
    }
    // The arithmetic runs on the magnitude. The sign comes back at the
    // end. The modes that round toward a side change their meaning on a
    // value below zero, so they map to a mode of the magnitude.
    let negative = a.minor < 0;
    var amount = a.minor;
    if negative { amount = -amount; }
    var step_mode = mode;
    if mode == ROUND_CEILING {
        step_mode = if negative { ROUND_DOWN } else { ROUND_UP };
    } else if mode == ROUND_FLOOR {
        step_mode = if negative { ROUND_UP } else { ROUND_DOWN };
    }
    // The step holds the units of the places. The rest holds what the
    // step dropped.
    let step = amount / factor;
    let rest = amount % factor;
    if rest == 0 { return a, true; }
    if mode == ROUND_UNNECESSARY { return Money { minor: 0, code: "" }, false; }
    // The rest holds less than one step, so the rounding decides
    // between the step and the step plus one. At the half way point,
    // the even modes look at the parity of the step.
    var up = false;
    if step_mode == ROUND_UP {
        up = true;
    } else if step_mode == ROUND_DOWN {
        up = false;
    } else if rest * 2 > factor {
        up = true;
    } else if rest * 2 == factor {
        if step_mode == ROUND_HALF_EVEN {
            up = step % 2 != 0;
        } else if step_mode == ROUND_HALF_UP {
            up = true;
        } else if step_mode == ROUND_HALF_DOWN {
            up = false;
        } else {
            up = step % 2 == 0;
        }
    } else {
        up = false;
    }
    var rounded: i64 = 0;
    if up { rounded = 1; }
    var moved, ok = checked_add(step * factor, rounded * factor);
    if !ok { return Money { minor: 0, code: "" }, false; }
    if negative { moved = -moved; }
    return Money { minor: moved, code: a.code }, true;
}


// money_allocate gives the parts of the amount by the ratios. The parts
// sum to the amount. The ratios must not be negative. The sum of the
// ratios must not be zero.
//
// The units that the truncation lost go one at a time to the parts. The
// order runs from the first part with a share to the last. This is the
// order of the bojanz/currency package of Go.
fn money_allocate(a: Money, ratios: i64[:]) -> Money[>..], bool {
    var out: Money[>..] = [];
    if ratios.len == 0 || ratios.len > MAX_PARTS { return out, false; }
    // The total of the ratios.
    var total: i64 = 0;
    var i: i64 = 0;
    while i < ratios.len {
        if ratios[i] < 0 { return out, false; }
        total += ratios[i];
        i += 1;
    }
    if total == 0 { return out, false; }
    // The least value of an i64 has no magnitude in an i64, so the
    // package refuses it.
    if a.minor == -9223372036854775807 - 1 { return out, false; }
    // The count of the units is of the magnitude. The sign comes back at
    // the end.
    let negative = a.minor < 0;
    var amount = a.minor;
    if negative { amount = -amount; }
    // The share of each part and the units that the truncation lost.
    var sum_shares: i64 = 0;
    i = 0;
    while i < ratios.len {
        let share = share_of(amount, ratios[i], total);
        out.push(Money { minor: share, code: a.code });
        sum_shares += share;
        i += 1;
    }
    // The units that the truncation lost.
    var lost = amount - sum_shares;
    // The lost units go one at a time to the parts that have a share.
    while lost > 0 {
        var gave = false;
        i = 0;
        while i < out.len {
            if ratios[i] > 0 {
                out[i].minor += 1;
                lost -= 1;
                gave = true;
                if lost == 0 { break; }
            }
            i += 1;
        }
        if !gave { break; }
    }
    // The sign comes back.
    if negative {
        i = 0;
        while i < out.len {
            out[i].minor = -out[i].minor;
            i += 1;
        }
    }
    return out, true;
}

// share_of gives the truncated share of the amount by the ratio. The
// total holds the sum of the ratios. The count never overflows.
fn share_of(amount: i64, ratio: i64, total: i64) -> i64 {
    // The product of the amount and the ratio may not fit in an i64, so
    // it is computed in a wide value.
    let product = wide_mul(amount as u64, ratio as u64);
    let quotient, _ = wide_divmod(product, total as u64);
    if !wide_fits_u64(quotient) { return 0; }
    return wide_to_u64(quotient) as i64;
}

// money_split gives the parts of the amount into n equal parts. The
// parts sum to the amount. It gives false when n is below one or above
// 100000.
fn money_split(a: Money, n: i64) -> Money[>..], bool {
    var ratios: i64[>..] = [];
    if n > MAX_PARTS {
        return ratios_none(), false;
    }
    var i: i64 = 0;
    while i < n {
        ratios.push(1);
        i += 1;
    }
    let out, ok = money_allocate(a, ratios[..]);
    return out, ok;
}

// ratios_none gives an empty list of parts.
fn ratios_none() -> Money[>..] {
    var out: Money[>..] = [];
    return out;
}
