// The currencies of the finance package.
//
// The table holds the ISO 4217 code, the numeric code, the name and the
// minor-unit exponent of each currency. The tables sit in the file
// currency_data.goose.
//
// The minor-unit exponent gives the count of the digits that the
// currency holds after the decimal mark. The value 2 means that a
// currency has hundredths. The value -1 means that the currency has no
// minor unit. Joda-Money holds the same value.
namespace finance;

import std;

// Currency is one entry of the table of the currencies.
//
// The code and the number are small strings inside the struct. The name
// is a view of the text of the table.
struct Currency {
    code: u8[..3],
    number: u8[..3],
    name: const u8[:],
    exponent: i32,
}

// The currency with no minor unit. Its code is a fund code or a special
// code of the ISO 4217 list.
const CURRENCY_NO_MINOR_UNIT: i32 = -1;

// compare_bytes gives -1, 0 or 1. The value is the order of the two
// texts. A shorter text comes first when it is a prefix of the longer
// one.
fn compare_bytes(a: const u8[:], b: const u8[:]) -> i64 {
    let n = if a.len < b.len { a.len } else { b.len };
    var i: i64 = 0;
    while i < n {
        if a[i] != b[i] {
            if a[i] < b[i] { return -1; }
            return 1;
        }
        i += 1;
    }
    if a.len < b.len { return -1; }
    if a.len > b.len { return 1; }
    return 0;
}

// currency_index gives the place of the code in the table. It gives -1
// for a code that the table does not hold.
fn currency_index(code: const u8[:]) -> i64 {
    // The table is sorted by the code, so a binary search finds the
    // place of the code.
    var low: i64 = 0;
    var high: i64 = CURRENCY_COUNT - 1;
    while low <= high {
        let mid = (low + high) / 2;
        let order = compare_bytes(CURRENCY_CODES[mid], code);
        if order == 0 { return mid; }
        if order < 0 {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return -1;
}

// take3 gives the first three bytes of the text. A shorter text comes
// back whole. Some historic currencies hold no numeric code, so the
// entry is shorter or empty.
fn take3(text: const u8[:]) -> u8[..3] {
    if text.len < 3 { return text[..]; }
    return text[..3];
}

// currency gives the entry of the table. It gives false for a code that
// the table does not hold.
fn currency(code: const u8[:]) -> Currency, bool {
    let index = currency_index(code);
    if index < 0 { return Currency { code: "", number: "", name: "", exponent: 0 }, false; }
    return Currency {
        code: take3(CURRENCY_CODES[index]),
        number: take3(CURRENCY_NUMBERS[index]),
        name: CURRENCY_NAMES[index],
        exponent: CURRENCY_EXPONENTS[index],
    }, true;
}

// currencies gives every entry of the table.
fn currencies() -> Currency[>..] {
    var out: Currency[>..] = [];
    var i: i64 = 0;
    while i < CURRENCY_COUNT {
        out.push(Currency {
            code: take3(CURRENCY_CODES[i]),
            number: take3(CURRENCY_NUMBERS[i]),
            name: CURRENCY_NAMES[i],
            exponent: CURRENCY_EXPONENTS[i],
        });
        i += 1;
    }
    return out;
}

// currency_exponent gives the minor-unit exponent of the currency. It
// gives -1 for a code that the table does not hold. It also gives -1 for
// a currency with no minor unit.
fn currency_exponent(code: const u8[:]) -> i32 {
    let index = currency_index(code);
    if index < 0 { return -1; }
    return CURRENCY_EXPONENTS[index];
}

// currency_by_number gives the entry of the table. It gives false for a
// numeric code that the table does not hold.
fn currency_by_number(number: const u8[:]) -> Currency, bool {
    var i: i64 = 0;
    while i < CURRENCY_COUNT {
        if CURRENCY_NUMBERS[i] == number {
            return Currency {
                code: take3(CURRENCY_CODES[i]),
                number: take3(CURRENCY_NUMBERS[i]),
                name: CURRENCY_NAMES[i],
                exponent: CURRENCY_EXPONENTS[i],
            }, true;
        }
        i += 1;
    }
    return Currency { code: "", number: "", name: "", exponent: 0 }, false;
}

// currency_name gives the name of the currency. It gives an empty text
// for a code that the table does not hold.
fn currency_name(code: const u8[:]) -> u8[:] {
    let index = currency_index(code);
    if index < 0 { return ""; }
    return CURRENCY_NAMES[index];
}
