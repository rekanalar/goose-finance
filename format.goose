// The formatting and the parsing of money of the finance package.
//
// The tables of the locales sit in the file locale_data.goose. The data
// comes from CLDR 47 through the babel package of Python.
//
// The package writes a plain space where CLDR writes a no-break space.
// The parser accepts the plain space only.
namespace finance;

import std;

// Locale holds the rules of one locale. The fields hold the marks of
// the numbers, the sizes of the groups and the place of the symbol.
struct Locale {
    name: const u8[:],
    decimal: const u8[:],
    group: const u8[:],
    sizes_at: i64,
    size_count: i64,
    symbol_first: bool,
    has_pad: bool,
    symbols_at: i64,
    symbol_count: i64,
}

// locale gives the rules of the locale. It gives false for a name that
// the table does not hold.
fn locale(name: const u8[:]) -> Locale, bool {
    var i: i64 = 0;
    while i < LOCALE_COUNT {
        if LOCALE_NAMES[i] == name {
            var symbols_at: i64 = 0;
            var j: i64 = 0;
            while j < i {
                symbols_at += LOCALE_SYMBOL_COUNTS[j];
                j += 1;
            }
            var sizes_at: i64 = 0;
            j = 0;
            while j < i {
                sizes_at += LOCALE_GROUP_SIZE_COUNTS[j];
                j += 1;
            }
            return Locale {
                name: LOCALE_NAMES[i],
                decimal: LOCALE_DECIMALS[i],
                group: LOCALE_GROUPS[i],
                sizes_at: sizes_at,
                size_count: LOCALE_GROUP_SIZE_COUNTS[i],
                symbol_first: LOCALE_SYMBOL_FIRST[i] == 1,
                has_pad: LOCALE_HAS_PAD[i] == 1,
                symbols_at: symbols_at,
                symbol_count: LOCALE_SYMBOL_COUNTS[i],
            }, true;
        }
        i += 1;
    }
    return Locale {
        name: "",
        decimal: "",
        group: "",
        sizes_at: 0,
        size_count: 0,
        symbol_first: true,
        has_pad: false,
        symbols_at: 0,
        symbol_count: 0,
    }, false;
}

// locale_symbol gives the symbol of the currency in the locale. The
// table of the locale holds the symbols that differ from the base. A
// currency that the table of the locale does not hold uses the symbol of
// the base locale. The base holds no symbol for a code with no symbol,
// so the text comes back empty then.
fn locale_symbol(at: Locale, code: const u8[:]) -> const u8[:] {
    var i: i64 = 0;
    while i < at.symbol_count {
        if LOCALE_SYMBOL_CODES[at.symbols_at + i] == code {
            return LOCALE_SYMBOL_TEXTS[at.symbols_at + i];
        }
        i += 1;
    }
    // The table of the base is sorted, so a binary search finds the
    // place of the code.
    var low: i64 = 0;
    var high: i64 = BASE_SYMBOL_CODES.len - 1;
    while low <= high {
        let mid = (low + high) / 2;
        let order = compare_bytes(BASE_SYMBOL_CODES[mid], code);
        if order == 0 { return BASE_SYMBOL_TEXTS[mid]; }
        if order < 0 {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return "";
}

// emit_uint writes the digits of the value. The value holds a
// magnitude, so the sign never enters the text here.
fn emit_uint(out: u8[>..]&, value: u64) {
    var digits: u8[20];
    var n: i64 = 0;
    var rest = value;
    while true {
        digits[n] = (48 + (rest % 10)) as u8;
        n += 1;
        rest /= 10;
        if rest == 0 { break; }
    }
    var i: i64 = n - 1;
    while i >= 0 {
        out.push(digits[i]);
        i -= 1;
    }
}

// emit_groups writes the digits of the value with the group marks of
// the locale. The value holds a magnitude.
fn emit_groups(out: u8[>..]&, at: Locale, value: u64) {
    // The digits go into a buffer, so that the groups can be cut from
    // the right.
    var digits: u8[20];
    var n: i64 = 0;
    var rest = value;
    while true {
        digits[n] = (48 + (rest % 10)) as u8;
        n += 1;
        rest /= 10;
        if rest == 0 { break; }
    }
    // The places of the marks count the digits from the right. The
    // places grow by the sizes of the locale. The last size holds for
    // the groups beyond the table. The digits go out from the left, so
    // the marks fire in the order from the highest place down.
    var places: i64[8];
    var mark_count: i64 = 0;
    var place: i64 = LOCALE_GROUP_SIZES[at.sizes_at];
    var pstep: i64 = 1;
    while place < n && mark_count < 8 {
        places[mark_count] = place;
        mark_count += 1;
        var add: i64 = LOCALE_GROUP_SIZES[at.sizes_at + at.size_count - 1];
        if pstep < at.size_count {
            add = LOCALE_GROUP_SIZES[at.sizes_at + pstep];
        }
        place += add;
        pstep += 1;
    }
    var at_mark = mark_count - 1;
    var i: i64 = n - 1;
    while i >= 0 {
        out.push(digits[i]);
        if at_mark >= 0 && i == places[at_mark] {
            var g: i64 = 0;
            while g < at.group.len {
                out.push(at.group[g]);
                g += 1;
            }
            at_mark -= 1;
        }
        i -= 1;
    }
}

// money_format writes the text of the amount. The text holds the sign,
// the symbol of the locale, the group marks and the decimal mark.
fn money_format(out: u8[>..]&, a: Money, name: const u8[:]) -> bool {
    return money_emit(out, a, name, true);
}

// money_format_code writes the text of the amount. The text holds the
// code of the currency in place of the symbol.
fn money_format_code(out: u8[>..]&, a: Money, name: const u8[:]) -> bool {
    return money_emit(out, a, name, false);
}

// money_emit writes the text of the amount. The flag use_symbol picks
// the symbol or the code of the currency.
fn money_emit(out: u8[>..]&, a: Money, name: const u8[:], use_symbol: bool) -> bool {
    let at, ok = locale(name);
    if !ok { return false; }
    var exponent: i64 = currency_exponent(a.code);
    if exponent < 0 { exponent = 0; }
    let amount, negative = magnitude(a.minor);
    if negative { out.push('-'); }
    // The token holds the symbol or the code of the currency.
    let symbol = locale_symbol(at, a.code);
    let token: const u8[:] = if use_symbol && symbol.len > 0 { symbol } else { a.code[..] };
    if at.symbol_first {
        out.append(token);
        if at.has_pad { out.push(' '); }
        emit_parts(out, at, amount, exponent);
    } else {
        emit_parts(out, at, amount, exponent);
        if at.has_pad { out.push(' '); }
        out.append(token);
    }
    return true;
}

// emit_parts writes the digits of the amount. The digits hold the
// groups of the integer part, the decimal mark and the minor part.
fn emit_parts(out: u8[>..]&, at: Locale, amount: u64, exponent: i64) {
    // The factor of the minor units.
    var factor: u64 = 1;
    var i: i64 = 0;
    while i < exponent {
        factor *= 10;
        i += 1;
    }
    let whole = amount / factor;
    let minors = amount % factor;
    emit_groups(out, at, whole);
    if exponent > 0 {
        out.append(at.decimal);
        // The minor part holds one digit for each place of the
        // exponent, from the highest place.
        var digits: u8[8];
        var j: i64 = exponent - 1;
        var rest = minors;
        while j >= 0 {
            digits[j] = (48 + (rest % 10)) as u8;
            rest /= 10;
            j -= 1;
        }
        i = 0;
        while i < exponent {
            out.push(digits[i]);
            i += 1;
        }
    }
}

// money_parse gives the amount of the text. The text may hold the sign,
// the symbol or the code, the group marks and the decimal mark.
//
// The parser is strict. It rejects a text whose marks differ from the
// marks of the locale. It rejects a sign that stands in another place
// than the front. It rejects a text whose digits hold a mark that the
// locale does not use. The mode UNNECESSARY rejects a text with more
// decimal places than the currency holds. Every other mode rounds.
fn money_parse(text: const u8[:], name: const u8[:], code: const u8[:], mode: i32) -> Money, bool {
    if text.len < 1 || text.len > MAX_PARSE_BYTES { return Money { minor: 0, code: "" }, false; }
    let at, ok = locale(name);
    if !ok { return Money { minor: 0, code: "" }, false; }
    if currency_index(code) < 0 { return Money { minor: 0, code: "" }, false; }
    var exponent: i64 = currency_exponent(code);
    if exponent < 0 { exponent = 0; }
    // The sign holds only at the front.
    var negative = false;
    var body = text;
    if body[0] == '-' {
        negative = true;
        body = body[1..];
        if body.len < 1 { return Money { minor: 0, code: "" }, false; }
    }
    // The token of the currency goes away. The parser tries the symbol
    // and the code at both ends.
    let symbol = locale_symbol(at, code);
    body = strip_token(body, symbol);
    body = strip_token(body, code[..]);
    // A sign that stands after the token is a misplaced sign.
    if body.len > 0 && body[0] == '-' { return Money { minor: 0, code: "" }, false; }
    // The digits and the marks stay. Every other byte is hostile.
    let cut = split_mark(body, at.decimal);
    if !cut { return Money { minor: 0, code: "" }, false; }
    return parse_body(body, at, code, negative, exponent, mode);
}

// strip_token takes the token away from the text. The token may stand
// at the front or at the end. One plain space may stand next to the
// token. The parser takes it away too.
fn strip_token(text: const u8[:], token: const u8[:]) -> const u8[:] {
    if token.len > 0 && text.len >= token.len {
        if text[..token.len] == token {
            var rest = text[token.len..];
            if rest.len > 0 && rest[0] == ' ' { rest = rest[1..]; }
            return rest;
        }
        let tail = text.len - token.len;
        if text[tail..] == token {
            var rest = text[..tail];
            if rest.len > 0 && rest[rest.len - 1] == ' ' { rest = rest[..rest.len - 1]; }
            return rest;
        }
    }
    return text;
}

// split_mark tells whether the body splits at the mark. The function
// does not change the body. The parser uses the check before it reads
// the parts.
fn split_mark(body: const u8[:], mark: const u8[:]) -> bool {
    var count: i64 = 0;
    var i: i64 = 0;
    while i < body.len {
        var j: i64 = 0;
        var hit = true;
        while j < mark.len {
            if i + j >= body.len || body[i + j] != mark[j] {
                hit = false;
                break;
            }
            j += 1;
        }
        if hit {
            count += 1;
            i += mark.len;
        } else {
            i += 1;
        }
    }
    return count <= 1;
}

// parse_body reads the integer part and the minor part of the body. The
// arithmetic runs on the magnitude. The sign comes back at the end.
fn parse_body(body: const u8[:], at: Locale, code: const u8[:], negative: bool, exponent: i64, mode: i32) -> Money, bool {
    // The body splits at the decimal mark into the integer part and the
    // minor part.
    var whole_text = body;
    var minor_text = body[0..0];
    var i: i64 = 0;
    while i < body.len {
        if body[i..i + at.decimal.len] == at.decimal {
            whole_text = body[..i];
            minor_text = body[i + at.decimal.len..];
            break;
        }
        i += 1;
    }
    if whole_text.len < 1 { return Money { minor: 0, code: "" }, false; }
    // The integer part holds the digits and the group marks.
    if !digits_ok(whole_text, at) { return Money { minor: 0, code: "" }, false; }
    // The minor part holds digits only.
    i = 0;
    while i < minor_text.len {
        if minor_text[i] < 48 || minor_text[i] > 57 {
            return Money { minor: 0, code: "" }, false;
        }
        i += 1;
    }
    // The value of the integer part. The arithmetic is checked, so an
    // overflow gives an error rather than a wrong number.
    var whole: u64 = 0;
    i = 0;
    while i < whole_text.len {
        let b = whole_text[i];
        if b >= 48 && b <= 57 {
            let digit: u64 = b - 48;
            if whole > (9223372036854775807 - digit) / 10 {
                return Money { minor: 0, code: "" }, false;
            }
            whole = whole * 10 + digit;
        }
        i += 1;
    }
    // The factor of the minor units.
    var factor: u64 = 1;
    i = 0;
    while i < exponent {
        if factor > 9223372036854775807 / 10 {
            return Money { minor: 0, code: "" }, false;
        }
        factor *= 10;
        i += 1;
    }
    if whole > 9223372036854775807 / factor {
        return Money { minor: 0, code: "" }, false;
    }
    var total = whole * factor;
    // The minor part holds at most the places of the exponent. The
    // places beyond the exponent round by the mode.
    var tail: u64 = 0;
    var tail_scale: u64 = 1;
    i = 0;
    while i < minor_text.len {
        let digit = (minor_text[i] - 48) as u64;
        if i < exponent {
            total += digit * (factor / powers_of_ten(i + 1));
        } else {
            if tail_scale > 9223372036854775807 / 10 {
                return Money { minor: 0, code: "" }, false;
            }
            tail = tail * 10 + digit;
            tail_scale *= 10;
        }
        i += 1;
    }
    // The places beyond the exponent.
    if tail_scale > 1 {
        if mode == ROUND_UNNECESSARY { return Money { minor: 0, code: "" }, false; }
        // The modes that round toward a side change their meaning on a
        // value below zero.
        var step_mode = mode;
        if mode == ROUND_CEILING {
            step_mode = if negative { ROUND_DOWN } else { ROUND_UP };
        } else if mode == ROUND_FLOOR {
            step_mode = if negative { ROUND_UP } else { ROUND_DOWN };
        }
        // The tail holds less than one step, so the rounding decides
        // between nothing and one step. At the half way point, the
        // even modes look at the parity of the total.
        var up = false;
        if step_mode == ROUND_UP {
            up = true;
        } else if step_mode == ROUND_DOWN {
            up = false;
        } else if tail * 2 > tail_scale {
            up = true;
        } else if tail * 2 == tail_scale {
            if step_mode == ROUND_HALF_EVEN {
                up = total % 2 != 0;
            } else if step_mode == ROUND_HALF_UP {
                up = true;
            } else if step_mode == ROUND_HALF_DOWN {
                up = false;
            } else {
                up = total % 2 == 0;
            }
        } else {
            up = false;
        }
        if up {
            if total == 9223372036854775807 {
                return Money { minor: 0, code: "" }, false;
            }
            total += 1;
        }
    }
    if total > 9223372036854775807 {
        return Money { minor: 0, code: "" }, false;
    }
    var minor = total as i64;
    if negative { minor = -minor; }
    return Money { minor: minor, code: code[..3] }, true;
}

// powers_of_ten gives 10 to the power of the count.
fn powers_of_ten(count: i64) -> u64 {
    var out: u64 = 1;
    var i: i64 = 0;
    while i < count {
        out *= 10;
        i += 1;
    }
    return out;
}

// digits_ok tells whether the integer part holds the digits and the
// group marks of the locale in the order of the locale. A mark may hold
// more than one byte, so the parts split by the whole mark.
fn digits_ok(text: const u8[:], at: Locale) -> bool {
    var parts: const u8[:][>..] = [];
    var start: i64 = 0;
    var i: i64 = 0;
    while i < text.len {
        var hit = false;
        if at.group.len > 0 && i + at.group.len <= text.len {
            if text[i..i + at.group.len] == at.group {
                parts.push(text[start..i]);
                i += at.group.len;
                start = i;
                hit = true;
            }
        }
        if !hit {
            if text[i] < 48 || text[i] > 57 { return false; }
            i += 1;
        }
    }
    parts.push(text[start..]);
    if parts.len == 1 { return true; }
    // The parts read from the right. The size of the part must hold the
    // size of the group at its place.
    var step: i64 = 0;
    var index = parts.len - 1;
    while index >= 0 {
        var size: i64 = 3;
        if step < at.size_count { size = LOCALE_GROUP_SIZES[at.sizes_at + step]; }
        if parts[index].len < 1 || parts[index].len > size { return false; }
        step += 1;
        if step >= at.size_count { step = at.size_count - 1; }
        index -= 1;
    }
    return true;
}
