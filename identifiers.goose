// The instrument identifiers of the finance package.
//
// The package holds the ISIN, the CUSIP, the FIGI and the LEI. Each
// function checks the length first, then the bytes, then the check
// digits. A text that holds a byte that is not an ASCII letter or an
// ASCII digit is invalid.
//
// The algorithms follow the python-stdnum package of Python. The Luhn
// check expands a letter to the value of its place in the alphabet
// plus 9. The value of the letter A is 10, and the value of the letter
// Z is 35.
namespace finance;

import std;

// isin is the parts of an ISIN. The country holds two letters. The
// number holds nine letters and digits. The check holds one digit.
struct Isin {
    country: u8[..2],
    number: u8[..9],
    check: u8[..1],
}

// cusip is the parts of a CUSIP. The number holds eight characters.
// The check holds one character.
struct Cusip {
    number: u8[..8],
    check: u8[..1],
}

// lei is the parts of an LEI. The number holds 18 letters and digits.
// The check holds two digits.
struct Lei {
    number: u8[..18],
    check: u8[..2],
}

// base36_value gives the value of a byte in the alphabet of the base
// 36. The digit holds its own value. The letter holds the value of its
// place plus 9. The flag tells whether the byte is in the alphabet.
fn base36_value(b: u8) -> i64, bool {
    if b >= 48 && b <= 57 {
        return b - 48, true;
    }
    if b >= 65 && b <= 90 {
        return b - 65 + 10, true;
    }
    return 0, false;
}

// digits_of writes the digits of the value into the buffer. The digits
// hold the decimal form of the value.
fn digits_of(out: u8[>..]&, value: i64) {
    if value < 10 {
        out.push((48 + value) as u8);
        return;
    }
    // The values 10 to 35 hold two digits.
    out.push((48 + value / 10) as u8);
    out.push((48 + value % 10) as u8);
}

// luhn_valid tells whether the text holds a valid Luhn check digit.
// The letters of the text expand to the digits of their value first.
// The check reads the digits from the right. The value of a digit
// counts twice at every second place from the right, and the digits of
// the doubled value add together. A value of more than 9 loses 9.
fn luhn_valid(text: const u8[:]) -> bool {
    // The text expands to decimal digits.
    var digits: u8[>..] = [];
    var i: i64 = 0;
    while i < text.len {
        let value, ok = base36_value(text[i]);
        if !ok { return false; }
        digits_of(digits, value);
        i += 1;
    }
    var sum: i64 = 0;
    // The check digit sits at the right, so its place does not count
    // twice.
    var double = false;
    i = digits.len - 1;
    while i >= 0 {
        var value = digits[i] - 48;
        if double {
            value *= 2;
            if value > 9 { value -= 9; }
        }
        sum += value;
        double = !double;
        i -= 1;
    }
    return sum % 10 == 0;
}

// luhn_check_digit gives the check digit that a text needs. The text
// holds the part before the check digit. The value -1 comes back when
// the text holds a byte that is not an ASCII letter or an ASCII digit.
fn luhn_check_digit(text: const u8[:]) -> i64 {
    var digits: u8[>..] = [];
    var i: i64 = 0;
    while i < text.len {
        let value, ok = base36_value(text[i]);
        if !ok { return -1; }
        digits_of(digits, value);
        i += 1;
    }
    // The check digit sits at the right, so its place counts twice.
    var sum: i64 = 0;
    var double = true;
    i = digits.len - 1;
    while i >= 0 {
        var value = digits[i] - 48;
        if double {
            value *= 2;
            if value > 9 { value -= 9; }
        }
        sum += value;
        double = !double;
        i -= 1;
    }
    return (10 - sum % 10) % 10;
}

// isin_parts gives the parts of the ISIN. It gives false when the text
// is not a valid ISIN.
fn isin_parts(text: const u8[:]) -> Isin, bool {
    // The length of an ISIN is 12 bytes.
    if text.len != 12 {
        return Isin { country: "", number: "", check: "" }, false;
    }
    // Every byte must be an ASCII letter or an ASCII digit. The first
    // two bytes must be letters, because they hold the country.
    var i: i64 = 0;
    while i < 12 {
        let value, ok = base36_value(text[i]);
        if !ok { return Isin { country: "", number: "", check: "" }, false; }
        if i < 2 {
            if text[i] < 65 || text[i] > 90 { return Isin { country: "", number: "", check: "" }, false; }
        }
        i += 1;
    }
    if !luhn_valid(text) {
        return Isin { country: "", number: "", check: "" }, false;
    }
    return Isin {
        country: text[..2],
        number: text[2..11],
        check: text[11..],
    }, true;
}

// isin_valid tells whether the text is a valid ISIN.
fn isin_valid(text: const u8[:]) -> bool {
    let _, ok = isin_parts(text);
    return ok;
}

// isin_from_natid writes the ISIN of a country and a national number
// into the buffer. The number must hold nine letters and digits. The
// check digit comes from the Luhn check over the expanded text.
fn isin_from_natid(out: u8[>..]&, country: const u8[:], number: const u8[:]) -> bool {
    if country.len != 2 || number.len != 9 {
        return false;
    }
    var i: i64 = 0;
    while i < 2 {
        if country[i] < 65 || country[i] > 90 { return false; }
        i += 1;
    }
    i = 0;
    while i < 9 {
        let _, ok = base36_value(number[i]);
        if !ok { return false; }
        i += 1;
    }
    out.append(country);
    out.append(number);
    let check = luhn_check_digit(out[..]);
    if check < 0 { return false; }
    out.push((48 + check) as u8);
    return true;
}

// cusip_parts gives the parts of the CUSIP. It gives false when the
// text is not a valid CUSIP.
fn cusip_parts(text: const u8[:]) -> Cusip, bool {
    // The length of a CUSIP is 9 bytes.
    if text.len != 9 {
        return Cusip { number: "", check: "" }, false;
    }
    // The alphabet of a CUSIP holds the digits, the letters and the
    // three marks @ # *.
    var i: i64 = 0;
    while i < 9 {
        let b = text[i];
        if b >= 48 && b <= 57 { i += 1; continue; }
        if b >= 65 && b <= 90 { i += 1; continue; }
        if b == 64 || b == 35 || b == 42 { i += 1; continue; }
        return Cusip { number: "", check: "" }, false;
    }
    // The check reads the first eight characters from the left. The
    // value of a place counts twice at every second place from the
    // left, and the digits of the doubled value add together.
    var sum: i64 = 0;
    var i: i64 = 0;
    while i < 8 {
        let b = text[i];
        var value: i64 = 0;
        if b >= 48 && b <= 57 {
            value = b - 48;
        } else if b >= 65 && b <= 90 {
            value = b - 65 + 10;
        } else {
            // The mark @ holds the value 26, the mark # holds 27 and
            // the mark * holds 28.
            if b == 64 { value = 26; }
            if b == 35 { value = 27; }
            if b == 42 { value = 28; }
        }
        if i % 2 == 1 {
            value *= 2;
        }
        sum += value / 10 + value % 10;
        i += 1;
    }
    // The check character must be a digit.
    if text[8] < 48 || text[8] > 57 {
        return Cusip { number: "", check: "" }, false;
    }
    if (10 - sum % 10) % 10 != text[8] - 48 {
        return Cusip { number: "", check: "" }, false;
    }
    return Cusip {
        number: text[..8],
        check: text[8..],
    }, true;
}

// cusip_valid tells whether the text is a valid CUSIP.
fn cusip_valid(text: const u8[:]) -> bool {
    let _, ok = cusip_parts(text);
    return ok;
}

// figi_valid tells whether the text is a valid FIGI. The length of a
// FIGI is 12 bytes. The first two bytes hold the prefix. The third
// byte holds the letter G. The alphabet of a FIGI holds no letters
// that a reader may confuse with a digit.
fn figi_valid(text: const u8[:]) -> bool {
    // The length of a FIGI is 12 bytes.
    if text.len != 12 {
        return false;
    }
    // The alphabet holds the digits and the letters without I and O.
    var i: i64 = 0;
    while i < 12 {
        let b = text[i];
        if b < 48 || b > 90 { return false; }
        if b > 57 && (b == 73 || b == 79) { return false; }
        i += 1;
    }
    // The first two bytes hold the prefix. A prefix of digits has no
    // meaning.
    if text[0] >= 48 && text[0] <= 57 { return false; }
    if text[1] >= 48 && text[1] <= 57 { return false; }
    // The prefixes BS, BM, GG, GB and VG name other kinds of
    // identifiers.
    if text[0] == 66 && (text[1] == 83 || text[1] == 77) { return false; }
    if text[0] == 71 && (text[1] == 71 || text[1] == 66) { return false; }
    if text[0] == 86 && text[1] == 71 { return false; }
    // The third byte holds the letter G.
    if text[2] != 71 { return false; }
    // The check reads the text from the left. The value of a place
    // counts twice at every second place from the left, and the digits
    // of the doubled value add together.
    var sum: i64 = 0;
    var double = true;
    i = 0;
    while i < 12 {
        let value, _ = base36_value(text[i]);
        var part = value;
        if double {
            part = value * 2;
        }
        sum += part / 10 + part % 10;
        double = !double;
        i += 1;
    }
    return (10 - sum % 10) % 10 == text[11] - 48;
}

// lei_parts gives the parts of the LEI. It gives false when the text is
// not a valid LEI.
fn lei_parts(text: const u8[:]) -> Lei, bool {
    // The length of an LEI is 20 bytes.
    if text.len != 20 {
        return Lei { number: "", check: "" }, false;
    }
    // Every byte must be an ASCII letter or an ASCII digit.
    var i: i64 = 0;
    while i < 20 {
        let _, ok = base36_value(text[i]);
        if !ok { return Lei { number: "", check: "" }, false; }
        i += 1;
    }
    if !mod_97_10_valid(text) {
        return Lei { number: "", check: "" }, false;
    }
    return Lei {
        number: text[..18],
        check: text[18..],
    }, true;
}

// lei_valid tells whether the text is a valid LEI.
fn lei_valid(text: const u8[:]) -> bool {
    let _, ok = lei_parts(text);
    return ok;
}

// mod_97_10_valid tells whether the text passes the check of the
// standard ISO 7064 MOD 97-10. The value of every byte is a number of
// the base 36. The digits of these values join into one decimal
// number, and that number must hold a remainder of 1 at the division
// by 97.
//
// The whole number does not fit in an i64, so the remainder builds up
// one digit at a time. The remainder of a number that grows by one
// digit holds the remainder of the old number times 10 plus the digit.
fn mod_97_10_valid(text: const u8[:]) -> bool {
    var remainder: i64 = 0;
    var i: i64 = 0;
    while i < text.len {
        let value, ok = base36_value(text[i]);
        if !ok { return false; }
        // A value of 10 and above holds two digits. The high digit
        // enters the remainder first.
        if value >= 10 {
            remainder = (remainder * 10 + value / 10) % 97;
        }
        remainder = (remainder * 10 + value % 10) % 97;
        i += 1;
    }
    return remainder == 1;
}
