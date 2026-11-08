// Tests for the finance package. Run with: goose run test/run.goose
//
// The tests hold the vectors of the reference libraries, the fault
// cases, and round trips of the formatting and the parsing.

import std;
import math;
import finance from "..";

fn d(y: i64, m: i64, dd: i64) -> finance::Date {
    return finance::Date { year: y, month: m, day: dd };
}

fn notb(v: bool) -> i64 {
    if v { return 0; }
    return 1;
}

fn b(v: bool) -> i64 {
    if v { return 1; }
    return 0;
}

fn test_date() {
    assert(finance::is_leap_year(2024));
    assert(!finance::is_leap_year(2023));
    assert(finance::is_leap_year(2000));
    assert(!finance::is_leap_year(1900));
    assert(finance::days_in_month(2026, 2) == 28);
    assert(finance::days_in_month(2024, 2) == 29);
    assert(finance::days_in_month(2026, 4) == 30);
    assert(finance::date_ok(2026, 11, 8));
    assert(!finance::date_ok(2026, 2, 29));
    assert(!finance::date_ok(10000, 1, 1));
    // The day number of the epoch is 0.
    assert(finance::day_of_date(d(1970, 1, 1)) == 0);
    assert(finance::day_of_date(d(1970, 1, 2)) == 1);
    assert(finance::day_of_date(d(1969, 12, 31)) == -1);
    // The round trip holds for dates on both sides of the epoch.
    var z: i64 = -10000;
    while z <= 10000 {
        let y, m, dd = finance::civil_from_days(z);
        assert(finance::days_from_civil(y, m, dd) == z);
        z += 977;
    }
    // The weekday of the epoch is a Thursday.
    assert(finance::weekday(0) == 4);
    assert(finance::weekday_of_date(d(2026, 11, 8)) == 0);
    assert(finance::date_compare(d(2026, 1, 1), d(2027, 1, 1)) < 0);
    assert(finance::date_compare(d(2026, 5, 5), d(2026, 5, 5)) == 0);
}

fn test_currency() {
    let c, ok = finance::currency("USD");
    assert(ok);
    assert(c.number == "840");
    assert(c.exponent == 2);
    let j, ok2 = finance::currency("JPY");
    assert(ok2);
    assert(j.exponent == 0);
    let n, ok3 = finance::currency("NOPE");
    assert(!ok3);
    // The numeric codes find the currency too.
    let u, ok4 = finance::currency_by_number("840");
    assert(ok4);
    assert(u.code == "USD");
    // The table holds the currencies without a minor unit.
    let x, ok5 = finance::currency("XAU");
    assert(ok5);
    assert(x.exponent == -1);
    // The table holds historic currencies.
    let dem, ok6 = finance::currency("DEM");
    assert(ok6);
    assert(dem.exponent == 2);
    // The count of the table matches the count of the sources.
    let all = finance::currencies();
    assert(all.len == 307);
    assert(finance::currency_name("USD") == "US Dollar");
    assert(finance::currency_exponent("EUR") == 2);
}

fn test_money_arithmetic() {
    let a, ok = finance::money(1050, "USD");
    assert(ok);
    let b2, ok2 = finance::money(200, "USD");
    assert(ok2);
    let sum, ok3 = finance::money_add(a, b2);
    assert(ok3);
    assert(sum.minor == 1250);
    let diff, ok4 = finance::money_sub(a, b2);
    assert(ok4);
    assert(diff.minor == 850);
    assert(finance::money_negate(a).minor == -1050);
    assert(finance::money_abs(finance::money_negate(a)).minor == 1050);
    // The currencies must match.
    let e, ok5 = finance::money(100, "EUR");
    assert(ok5);
    let _, bad = finance::money_add(a, e);
    assert(!bad);
    // The order holds.
    let order, ok6 = finance::money_compare(a, b2);
    assert(ok6 && order > 0);
    let lo, ok7 = finance::money_min(a, b2);
    assert(ok7 && lo.minor == 200);
    let hi, ok8 = finance::money_max(a, b2);
    assert(ok8 && hi.minor == 1050);
    // The count of the minor units never overflows. The sum of the two
    // counts gives an error, not a wrong number.
    let big, _ = finance::money(9223372036854775807, "USD");
    let _, bad2 = finance::money_add(big, big);
    assert(!bad2);
    let n, ok9 = finance::money(-9223372036854775807 - 1, "USD");
    assert(ok9);
    let _, bad3 = finance::money_sub(n, big);
    assert(!bad3);
}

fn test_money_rounding() {
    // The modes at the half way point. The value 10.50 rounds to a
    // whole unit.
    let half_up, _ = finance::money(1050, "USD");
    let r1, ok1 = finance::money_round(half_up, 0, finance::ROUND_HALF_UP);
    assert(ok1 && r1.minor == 1100);
    let r2, ok2 = finance::money_round(half_up, 0, finance::ROUND_HALF_DOWN);
    assert(ok2 && r2.minor == 1000);
    let r3, ok3 = finance::money_round(half_up, 0, finance::ROUND_HALF_EVEN);
    assert(ok3 && r3.minor == 1000);
    let half_odd, _ = finance::money(1055, "USD");
    let r4, ok4 = finance::money_round(half_odd, 0, finance::ROUND_HALF_EVEN);
    assert(ok4 && r4.minor == 1100);
    // A tie that holds an odd neighbour. The value 9.50 rounds to 9.
    let tie, _ = finance::money(950, "USD");
    let r5, ok5 = finance::money_round(tie, 0, finance::ROUND_HALF_ODD);
    assert(ok5 && r5.minor == 900);
    let r5b, ok5b = finance::money_round(tie, 0, finance::ROUND_HALF_EVEN);
    assert(ok5b && r5b.minor == 1000);
    let r6, ok6 = finance::money_round(half_odd, 0, finance::ROUND_UP);
    assert(ok6 && r6.minor == 1100);
    let r7, ok7 = finance::money_round(half_odd, 0, finance::ROUND_DOWN);
    assert(ok7 && r7.minor == 1000);
    let r8, ok8 = finance::money_round(half_odd, 0, finance::ROUND_CEILING);
    assert(ok8 && r8.minor == 1100);
    let r9, ok9 = finance::money_round(half_odd, 0, finance::ROUND_FLOOR);
    assert(ok9 && r9.minor == 1000);
    // The modes on a value below zero. The value -10.55 rounds to a
    // whole unit.
    let neg, _ = finance::money(-1055, "USD");
    let r10, ok10 = finance::money_round(neg, 0, finance::ROUND_CEILING);
    assert(ok10 && r10.minor == -1000);
    let r11, ok11 = finance::money_round(neg, 0, finance::ROUND_FLOOR);
    assert(ok11 && r11.minor == -1100);
    let r12, ok12 = finance::money_round(neg, 0, finance::ROUND_UP);
    assert(ok12 && r12.minor == -1100);
    let r13, ok13 = finance::money_round(neg, 0, finance::ROUND_DOWN);
    assert(ok13 && r13.minor == -1000);
    // The mode UNNECESSARY rejects a value that needs a rounding.
    let _, bad = finance::money_round(half_odd, 0, finance::ROUND_UNNECESSARY);
    assert(!bad);
    // A count of places above the exponent of the currency is an error.
    let _, bad2 = finance::money_round(half_odd, 3, finance::ROUND_DOWN);
    assert(!bad2);
    // The value that needs no rounding stays.
    let whole, _ = finance::money(1100, "USD");
    let r14, ok14 = finance::money_round(whole, 0, finance::ROUND_UNNECESSARY);
    assert(ok14 && r14.minor == 1100);
}

fn test_money_rates() {
    // The multiplication by a fraction.
    let a, _ = finance::money(1005, "USD");
    let r1, ok1 = finance::money_mul_ratio(a, 1, 2, finance::ROUND_HALF_EVEN);
    assert(ok1 && r1.minor == 502);
    // The product may exceed the range of an i64. The error comes back
    // rather than a wrong number.
    let big, _ = finance::money(9223372036854775807, "USD");
    let _, bad = finance::money_mul_ratio(big, 3, 2, finance::ROUND_HALF_EVEN);
    assert(!bad);
    // A denominator of zero is an error.
    let _, bad2 = finance::money_mul_ratio(a, 1, 0, finance::ROUND_DOWN);
    assert(!bad2);
    // The rate of 105 percent of 7 yen with no minor unit.
    let j, _ = finance::money(7, "JPY");
    let r2, ok2 = finance::money_mul_ratio(j, 105, 100, finance::ROUND_DOWN);
    assert(ok2 && r2.minor == 7);
    // The percentage of the amount. The value 25 gives one quarter.
    let r3, ok3 = finance::money_mul_percent(a, 25, 1, finance::ROUND_HALF_EVEN);
    assert(ok3 && r3.minor == 251);
    // The value 125/10 is 12.5 percent. Of 1000 it gives 125.
    let k, _ = finance::money(1000, "USD");
    let r3b, ok3b = finance::money_mul_percent(k, 125, 10, finance::ROUND_HALF_EVEN);
    assert(ok3b && r3b.minor == 125);
    // The allocation of 100 into three parts.
    let m, _ = finance::money(100, "USD");
    var ratios: i64[>..] = [];
    ratios.push(1);
    ratios.push(1);
    ratios.push(1);
    let parts, ok4 = finance::money_allocate(m, ratios[..]);
    assert(ok4 && parts.len == 3);
    assert(parts[0].minor == 34 && parts[1].minor == 33 && parts[2].minor == 33);
    // The parts sum to the amount.
    var total: i64 = 0;
    var i: i64 = 0;
    while i < parts.len {
        total += parts[i].minor;
        i += 1;
    }
    assert(total == 100);
    // The allocation holds the sign of the amount.
    let neg, _ = finance::money(-100, "USD");
    let nparts, ok5 = finance::money_allocate(neg, ratios[..]);
    assert(ok5 && nparts[0].minor == -34 && nparts[1].minor == -33);
    // A ratio below zero is an error.
    var bad_ratio: i64[>..] = [];
    bad_ratio.push(-1);
    let _, bad3 = finance::money_allocate(m, bad_ratio[..]);
    assert(!bad3);
    // The split into equal parts.
    let s, _ = finance::money(5, "USD");
    let sparts, ok6 = finance::money_split(s, 2);
    assert(ok6 && sparts[0].minor == 3 && sparts[1].minor == 2);
    let _, bad4 = finance::money_split(s, 0);
    assert(!bad4);
    let _, bad5 = finance::money_split(s, 100001);
    assert(!bad5);
}

fn test_format_parse() {
    let m, _ = finance::money(123457, "USD");
    var out: u8[>..] = [];
    let ok = finance::money_format(out, m, "en_US");
    assert(ok);
    assert(out[..] == "$1,234.57");
    var out2: u8[>..] = [];
    finance::money_format(out2, m, "fr_FR");
    assert(out2[..] == "1 234,57 $US");
    var out3: u8[>..] = [];
    finance::money_format(out3, m, "de_CH");
    assert(out3[..] == "$ 1’234.57");
    // The groups of the locale of India hold three digits, then two.
    let inr, _ = finance::money(12345678901, "INR");
    var out4: u8[>..] = [];
    finance::money_format(out4, inr, "hi_IN");
    assert(out4[..] == "₹12,34,56,789.01");
    // A currency with no minor unit holds no decimal part.
    let j, _ = finance::money(-1235, "JPY");
    var out5: u8[>..] = [];
    finance::money_format(out5, j, "ja_JP");
    assert(out5[..] == "-￥1,235");
    // The code takes the place of the symbol.
    var out6: u8[>..] = [];
    finance::money_format_code(out6, m, "de_DE");
    assert(out6[..] == "1.234,57 USD");
    // The unknown locale is an error.
    var out7: u8[>..] = [];
    let bad = finance::money_format(out7, m, "xx_XX");
    assert(!bad);
    // The round trip holds for every form.
    let p1, ok1 = finance::money_parse(out[..], "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(ok1 && p1.minor == 123457);
    let p2, ok2 = finance::money_parse(out2[..], "fr_FR", "USD", finance::ROUND_UNNECESSARY);
    assert(ok2 && p2.minor == 123457);
    let p3, ok3 = finance::money_parse(out4[..], "hi_IN", "INR", finance::ROUND_UNNECESSARY);
    assert(ok3 && p3.minor == 12345678901);
    let p4, ok4 = finance::money_parse(out5[..], "ja_JP", "JPY", finance::ROUND_UNNECESSARY);
    assert(ok4 && p4.minor == -1235);
    let p5, ok5 = finance::money_parse(out6[..], "de_DE", "USD", finance::ROUND_UNNECESSARY);
    assert(ok5 && p5.minor == 123457);
    // The bare form holds the sign at the front.
    let p6, ok6 = finance::money_parse("-1234.57", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(ok6 && p6.minor == -123457);
    // The parser is strict.
    let _, bad2 = finance::money_parse("$1,234.567", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad2);
    let p7, ok7 = finance::money_parse("$1,234.567", "en_US", "USD", finance::ROUND_HALF_EVEN);
    assert(ok7 && p7.minor == 123457);
    let _, bad3 = finance::money_parse("1,2345.67", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad3);
    let _, bad4 = finance::money_parse("$-1,234.57", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad4);
    let _, bad5 = finance::money_parse("12345678901234567890.00", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad5);
    let _, bad6 = finance::money_parse("$1,234.57x", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad6);
    let _, bad7 = finance::money_parse("", "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad7);
    let _, bad8 = finance::money_parse("$1,234.57", "en_US", "NOPE", finance::ROUND_UNNECESSARY);
    assert(!bad8);
    // A text of 65 bytes is an error, a text of 64 bytes is not.
    var long: u8[>..] = [];
    var i: i64 = 0;
    while i < 70 {
        long.push(49);
        i += 1;
    }
    let _, bad9 = finance::money_parse(long[..], "en_US", "USD", finance::ROUND_UNNECESSARY);
    assert(!bad9);
}

fn test_locale() {
    let l, ok = finance::locale("en_US");
    assert(ok);
    assert(l.decimal == ".");
    assert(finance::locale_symbol(l, "USD") == "$");
    let l2, ok2 = finance::locale("de_CH");
    assert(ok2);
    // A currency with no symbol in the table gives an empty text. The
    // formatter then writes the code of the currency.
    assert(finance::locale_symbol(l2, "CHF") == "");
    let chf, _ = finance::money(5000, "CHF");
    var chf_out: u8[>..] = [];
    finance::money_format(chf_out, chf, "de_CH");
    assert(chf_out[..] == "CHF 50.00");
    let _, bad = finance::locale("xx_XX");
    assert(!bad);
}

fn test_tvm() {
    // The vectors of the numpy-financial package.
    assert_close("fv", finance::fv(0.075 / 12, 120, -100, -1000, 0), 19905.098831171737);
    assert_close("fv begin", finance::fv(0.075 / 12, 120, -100, -1000, 1), 20016.305294884514);
    assert_close("pv", finance::pv(0.07, 20, 1200, 0, 0), -12712.817094619397);
    assert_close("pmt", finance::pmt(0.075 / 12, 180, 200000, 0, 0), -1854.0247200054619);
    assert_close("nper", finance::nper(0.075 / 12, -2000, 0, 100000, 0), 43.64522014383663);
    assert_close("rate", finance::rate(20, -2000, 100000, 0, 0), -0.07490204366863248);
    assert_close("ipmt", finance::ipmt(0.075 / 12, 5, 180, 200000, 0, 0), -1234.7572229165526);
    assert_close("ppmt", finance::ppmt(0.075 / 12, 5, 180, 200000, 0, 0), -619.2674970889093);
    var vals: f64[>..] = [];
    vals.push(-100);
    vals.push(39);
    vals.push(59);
    vals.push(55);
    vals.push(20);
    assert_close("npv", finance::npv(0.281, vals[..]), -0.00847859163845488);
    // The rule of Excel discounts the first value by one period.
    assert_close("npv excel", finance::npv_excel(0.281, vals[..]), finance::npv(0.281, vals[..]) / 1.281);
    var cf: f64[>..] = [];
    cf.push(-150000);
    cf.push(15000);
    cf.push(25000);
    cf.push(35000);
    cf.push(45000);
    cf.push(60000);
    assert_close("irr", finance::irr(cf[..]), 0.052432888859412996);
    var mv: f64[>..] = [];
    mv.push(100);
    mv.push(200);
    mv.push(-50);
    mv.push(300);
    mv.push(-200);
    mv.push(500);
    assert_close("mirr", finance::mirr(mv[..], 0.10, 0.12), 0.5035667038518481);
    var xv: f64[>..] = [];
    xv.push(-10000);
    xv.push(6000);
    xv.push(4500);
    xv.push(3500);
    xv.push(2000);
    var xd: i64[>..] = [];
    xd.push(19772);
    xd.push(19830);
    xd.push(19899);
    xd.push(19964);
    xd.push(20373);
    assert_close("xnpv", finance::xnpv(0.09, xv[..], xd[..]), 5365.766443949571);
    assert_close("xirr", finance::xirr(xv[..], xd[..]), 2.3836813115219506);
    // A schedule that pays off the loan.
    var periods: i64[>..] = [];
    var pays: f64[>..] = [];
    var ints: f64[>..] = [];
    var prins: f64[>..] = [];
    var bals: f64[>..] = [];
    let ok = finance::amortisation(0.05, 10, 100000, periods, pays, ints, prins, bals);
    assert(ok);
    assert(periods.len == 10);
    assert(abs(bals[9]) < 0.000001);
    // The parts of every payment sum to the payment.
    var i: i64 = 0;
    while i < 10 {
        assert_close("part", pays[i] + ints[i] + prins[i], 0);
        i += 1;
    }
    // A count of periods below one is an error.
    var empty: i64[>..] = [];
    var e1: f64[>..] = [];
    var e2: f64[>..] = [];
    var e3: f64[>..] = [];
    var e4: f64[>..] = [];
    let bad = finance::amortisation(0.05, 0, 100000, empty, e1, e2, e3, e4);
    assert(!bad);
    let bad2 = finance::amortisation(0.05, 100001, 100000, empty, e1, e2, e3, e4);
    assert(!bad2);
}

fn assert_close(name: const u8[:], got: f64, want: f64) {
    var diff = got - want;
    if diff < 0 { diff = -diff; }
    if diff > 0.0001 {
        print("FAIL ", name, " got ", got, " want ", want, "\n");
        assert(false);
    }
}

fn test_daycount() {
    // The rule of 30/360 of the United States. Both dates hold a day
    // of 31, so the days count like two months of 30 days.
    assert_close("30/360 US", finance::year_fraction(finance::THIRTY_360_US, d(2026, 1, 31), d(2026, 3, 31)), 60.0 / 360.0);
    assert_close("30E", finance::year_fraction(finance::THIRTY_E_360, d(2026, 1, 31), d(2026, 3, 31)), 60.0 / 360.0);
    assert_close("ACT/360", finance::year_fraction(finance::ACT_360, d(2026, 1, 1), d(2026, 7, 1)), 181.0 / 360.0);
    assert_close("ACT/365", finance::year_fraction(finance::ACT_365_FIXED, d(2026, 1, 1), d(2026, 7, 1)), 181.0 / 365.0);
    // A year that holds a day of February 29 holds 366 days.
    assert_close("ACT/ACT leap", finance::year_fraction(finance::ACT_ACT_ISDA, d(2024, 1, 1), d(2024, 3, 1)), 60.0 / 366.0);
    assert_close("ACT/ACT cross", finance::year_fraction(finance::ACT_ACT_ISDA, d(2023, 12, 1), d(2024, 1, 1)), 31.0 / 365.0);
    // The growth factors.
    assert_close("simple", finance::growth_factor(finance::SIMPLE, 0.05, 2.0, 1), 1.1);
    assert_close("annual", finance::growth_factor(finance::ANNUAL, 0.05, 2.0, 1), 1.1025);
    assert_close("periodic", finance::growth_factor(finance::PERIODIC, 0.05, 1.0, 12), pow(1.0 + 0.05 / 12, 12.0));
    assert_close("continuous", finance::growth_factor(finance::CONTINUOUS, 0.05, 2.0, 1), pow(2.718281828459045, 0.1));
    // The discount factor is the inverse of the growth factor.
    assert_close("discount", finance::discount_factor(finance::ANNUAL, 0.05, 2.0, 1), 1.0 / 1.1025);
}

fn test_calendar() {
    // The Easter Sunday of the computus.
    let e1 = finance::easter(2024);
    assert(e1.month == 3 && e1.day == 31);
    let e2 = finance::easter(2025);
    assert(e2.month == 4 && e2.day == 20);
    let e3 = finance::easter(2026);
    assert(e3.month == 4 && e3.day == 5);
    let us, ok = finance::calendar_of(finance::CALENDAR_US_FEDERAL);
    assert(ok);
    // The day of July 4 of the year 2026 is a Saturday. The holiday
    // moves to the Friday before it.
    assert(notb(finance::is_business_day(us, d(2026, 7, 3))) == 1);
    assert(notb(finance::is_business_day(us, d(2026, 7, 4))) == 1);
    // The Thanksgiving of the year 2026 is the fourth Thursday.
    assert(notb(finance::is_business_day(us, d(2026, 11, 26))) == 1);
    assert(notb(finance::is_business_day(us, d(2026, 11, 14))) == 1);
    assert(b(finance::is_business_day(us, d(2026, 11, 10))) == 1);
    // The count of the business days skips the holiday and the
    // weekend.
    assert(finance::business_days_between(us, d(2026, 11, 10), d(2026, 11, 13)) == 2);
    let moved, mok = finance::add_business_days(us, d(2026, 11, 10), 3);
    assert(mok);
    assert(moved.year == 2026 && moved.month == 11 && moved.day == 16);
    // The roll conventions.
    let roll1 = finance::roll_date(d(2026, 10, 31), finance::FOLLOWING, us);
    assert(roll1.month == 11 && roll1.day == 2);
    let roll2 = finance::roll_date(d(2026, 10, 31), finance::MODIFIED_FOLLOWING, us);
    assert(roll2.month == 10 && roll2.day == 30);
    let roll3 = finance::roll_date(d(2026, 11, 10), finance::FOLLOWING, us);
    assert(roll3.day == 10);
    // The calendars of the other markets.
    let tg, ok2 = finance::calendar_of(finance::CALENDAR_TARGET);
    assert(ok2);
    assert(notb(finance::is_business_day(tg, d(2026, 4, 3))) == 1);
    assert(notb(finance::is_business_day(tg, d(2026, 4, 6))) == 1);
    let de, ok3 = finance::calendar_of(finance::CALENDAR_GERMANY);
    assert(ok3);
    assert(notb(finance::is_business_day(de, d(2026, 10, 3))) == 1);
    let uk, ok4 = finance::calendar_of(finance::CALENDAR_UK);
    assert(ok4);
    assert(notb(finance::is_business_day(uk, d(2026, 4, 3))) == 1);
    let ny, ok5 = finance::calendar_of(finance::CALENDAR_NYSE);
    assert(ok5);
    assert(notb(finance::is_business_day(ny, d(2026, 4, 3))) == 1);
    let _, bad = finance::calendar_of(-1);
    assert(!bad);
    // A count of more than 100000 business days is an error.
    let _, far = finance::add_business_days(us, d(2026, 11, 10), 100001);
    assert(!far);
    let _, far2 = finance::add_business_days(us, d(2026, 11, 10), -100001);
    assert(!far2);
    // A calendar whose seven days are all weekend is an error. Its
    // searches would never end.
    var all_days: i64[>..] = [];
    var wd: i64 = 0;
    while wd < 7 {
        all_days.push(wd);
        wd += 1;
    }
    var no_hol: i64[>..] = [];
    let _, full = finance::calendar_from_dates(no_hol[..], all_days[..]);
    assert(!full);
    // More than 400 dates is an error.
    var many: i64[>..] = [];
    var k: i64 = 0;
    while k < 401 {
        many.push(k);
        k += 1;
    }
    var wk: i64[>..] = [];
    wk.push(0);
    let _, toomany = finance::calendar_from_dates(many[..], wk[..]);
    assert(!toomany);
    // The explicit calendar holds its own dates.
    var weekend: i64[>..] = [];
    weekend.push(0);
    weekend.push(6);
    var hol: i64[>..] = [];
    hol.push(finance::day_of_date(d(2026, 12, 24)));
    let ex, ok6 = finance::calendar_from_dates(hol[..], weekend[..]);
    assert(ok6);
    assert(notb(finance::is_business_day(ex, d(2026, 12, 24))) == 1);
    assert(b(finance::is_business_day(ex, d(2026, 12, 23))) == 1);
}

fn test_identifiers() {
    // The vectors of the python-stdnum package.
    assert(finance::isin_valid("US0378331005"));
    assert(finance::isin_valid("US5949181045"));
    assert(finance::isin_valid("GB0002634946"));
    assert(finance::isin_valid("AU0000XVGZA3"));
    assert(!finance::isin_valid("US0378331004"));
    // The length and the bytes come first.
    assert(!finance::isin_valid("US03783310"));
    assert(!finance::isin_valid("us0378331005"));
    assert(!finance::isin_valid("U10378331005"));
    let p, ok = finance::isin_parts("US0378331005");
    assert(ok);
    assert(p.country == "US");
    assert(p.number == "037833100");
    assert(p.check == "5");
    assert(finance::cusip_valid("037833100"));
    assert(finance::cusip_valid("38259P508"));
    assert(!finance::cusip_valid("037833101"));
    let cp, ok2 = finance::cusip_parts("037833100");
    assert(ok2);
    assert(cp.number == "03783310");
    assert(cp.check == "0");
    assert(!finance::cusip_valid("03783310#"));
    assert(!finance::cusip_valid("03783310*"));
    assert(!finance::cusip_valid("03783310@"));
    assert(finance::figi_valid("BBG000BLNQ16"));
    assert(!finance::figi_valid("BBG000BLNQ14"));
    assert(!finance::figi_valid("BBG000BLNQ1"));
    assert(!finance::figi_valid("03G000BLNQ16"));
    assert(finance::lei_valid("213800KUD8LAJWSQ9D15"));
    assert(finance::lei_valid("5493000IBP32UQZ0KL24"));
    assert(!finance::lei_valid("213800KUD8LAJWSQ9D16"));
    let lp, ok3 = finance::lei_parts("213800KUD8LAJWSQ9D15");
    assert(ok3);
    assert(lp.number == "213800KUD8LAJWSQ9D");
    assert(lp.check == "15");
    // The Luhn check stands on its own.
    var out: u8[>..] = [];
    let ok4 = finance::isin_from_natid(out, "US", "91324PAE2");
    assert(ok4);
    assert(out[..] == "US91324PAE25");
    // The check digit of the expanded text.
    assert(finance::luhn_check_digit("US91324PAE2") == 5);
}

fn main() {
    test_date();
    test_currency();
    test_money_arithmetic();
    test_money_rounding();
    test_money_rates();
    test_format_parse();
    test_locale();
    test_tvm();
    test_daycount();
    test_calendar();
    test_identifiers();
    print("all finance tests pass\n");
    return 0;
}
