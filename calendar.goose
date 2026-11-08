// The business-day calendars of the finance package.
//
// A calendar holds the weekend days and the rules of the holidays. The
// holidays follow the public holidays of the named calendars. The
// rules cover the years from 1970 to 2100. Beyond that range, the
// rules of some holidays are not set, so no rule holds there.
//
// The rule kinds follow the kinds that the reference libraries of the
// calendars hold: a fixed day of the year, the n-th weekday of a
// month, the last weekday of a month, a day relative to Easter, a
// fixed day that moves to the next weekday, and a fixed day that moves
// to the weekday nearest to it. The last kind holds the rule of the
// United States, where a holiday on a Saturday moves to the Friday
// before it, and a holiday on a Sunday moves to the Monday after it.
namespace finance;

import std;
import math;

// The roll conventions.
const FOLLOWING: i32 = 0;
const MODIFIED_FOLLOWING: i32 = 1;
const PRECEDING: i32 = 2;
const MODIFIED_PRECEDING: i32 = 3;

// The kinds of the rules of the holidays.
const RULE_FIXED: i32 = 0;
const RULE_NTH_WEEKDAY: i32 = 1;
const RULE_LAST_WEEKDAY: i32 = 2;
const RULE_EASTER_OFFSET: i32 = 3;
const RULE_FIXED_ROLL: i32 = 4;
const RULE_NEAREST_WEEKDAY: i32 = 5;

// The calendars that the package holds.
const CALENDAR_US_FEDERAL: i32 = 0;
const CALENDAR_NYSE: i32 = 1;
const CALENDAR_TARGET: i32 = 2;
const CALENDAR_UK: i32 = 3;
const CALENDAR_GERMANY: i32 = 4;

// The most dates that an explicit calendar may hold. The bound keeps a
// hostile list from costing much memory.
const MAX_EXPLICIT_DATES: i64 = 400;

// The most business days that a call may step over. The search runs one
// day at a time, so the bound keeps a hostile count from costing much
// time.
const MAX_BUSINESS_STEP: i64 = 100000;

// The tables of the rules. Each entry of a table holds one field of
// one rule. The rules of a calendar sit next to each other. The place
// of a calendar comes from the table of the offsets.
//
// US_FEDERAL: New Year, MLK, Washington, Memorial, Juneteenth,
// Independence, Labor, Columbus, Veterans, Thanksgiving, Christmas.
// NYSE: New Year, MLK, Washington, Good Friday, Memorial, Juneteenth,
// Independence, Labor, Thanksgiving, Christmas.
// TARGET: New Year, Good Friday, Easter Monday, Labour, Christmas,
// Boxing.
// UK: New Year, Good Friday, Easter Monday, Early May, Spring, Summer,
// Christmas, Boxing.
// GERMANY: New Year, Good Friday, Easter Monday, Labour, Ascension,
// Whit Monday, Unity, Christmas, Boxing.
const RULE_OFFSETS: i64[] = [0, 11, 21, 27, 35, 44];
const RULE_KINDS: i32[] = [
    5, 1, 1, 2, 5, 5, 1, 1, 5, 1, 5,
    5, 1, 1, 3, 2, 5, 5, 1, 1, 5,
    5, 3, 3, 5, 5, 5,
    5, 3, 3, 1, 2, 2, 5, 5,
    5, 3, 3, 5, 3, 3, 5, 5, 5,
];
const RULE_MONTHS: i64[] = [
    1, 1, 2, 5, 6, 7, 9, 10, 11, 11, 12,
    1, 1, 2, 0, 5, 6, 7, 9, 11, 12,
    1, 0, 0, 5, 12, 12,
    1, 0, 0, 5, 5, 8, 12, 12,
    1, 0, 0, 5, 0, 0, 10, 12, 12,
];
const RULE_DAYS: i64[] = [
    1, 0, 0, 0, 19, 4, 0, 0, 11, 0, 25,
    1, 0, 0, 0, 0, 19, 4, 0, 0, 25,
    1, 0, 0, 1, 25, 26,
    1, 0, 0, 0, 0, 0, 25, 26,
    1, 0, 0, 1, 0, 0, 3, 25, 26,
];
const RULE_WEEKDAYS: i64[] = [
    0, 1, 1, 1, 0, 0, 1, 1, 0, 4, 0,
    0, 1, 1, 0, 1, 0, 0, 1, 4, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0,
];
const RULE_COUNTS: i64[] = [
    0, 3, 3, 0, 0, 0, 1, 2, 0, 4, 0,
    0, 3, 3, 0, 0, 0, 0, 1, 4, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0,
];
const RULE_EASTER_DAYS: i64[] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, -2, 0, 0, 0, 0, 0, 0,
    0, -2, 1, 0, 0, 0,
    0, -2, 1, 0, 0, 0, 0, 0,
    0, -2, 1, 0, 39, 50, 0, 0, 0,
];

// Calendar holds the weekend days and the rules of the holidays. The
// days of the weekend hold the values 0 to 6, where the value 0 is a
// Sunday. An explicit calendar holds its holidays in the dates. The
// dates hold day numbers, so that the search runs over numbers.
struct Calendar {
    // The mask of the weekend. The bit at the place of the weekday
    // holds a 1 when the weekday is a day of the weekend. The value 0
    // is a Sunday.
    weekend_mask: u8,
    rules_at: i64,
    rule_count: i64,
    dates: const i64[:],
    explicit: bool,
}

// easter gives the date of the Easter Sunday of the year. The
// algorithm is the one of the anonymous Gregorian computus. The rule
// covers every year of the Gregorian calendar.
fn easter(year: i64) -> Date {
    let a = year % 19;
    let b = year / 100;
    let c = year % 100;
    let d = b / 4;
    let e = b % 4;
    let f = (b + 8) / 25;
    let g = (b - f + 1) / 3;
    let h = (19 * a + b - d - g + 15) % 30;
    let i = c / 4;
    let k = c % 4;
    let l = (32 + 2 * e + 2 * i - h - k) % 7;
    let m = (a + 11 * h + 22 * l) / 451;
    let month = (h + l - 7 * m + 114) / 31;
    let day = ((h + l - 7 * m + 114) % 31) + 1;
    return Date { year: year, month: month, day: day };
}

// rule_date gives the date of the rule in the year. The flag ok tells
// whether the rule holds a date in the year.
fn rule_date(rule_kind: i32, rule_month: i64, rule_day: i64, rule_weekday: i64, rule_count: i64, rule_easter: i64, year: i64) -> Date, bool {
    if year < 1970 || year > 2100 { return Date { year: 0, month: 0, day: 0 }, false; }
    if rule_kind == RULE_FIXED || rule_kind == RULE_FIXED_ROLL {
        if rule_day > days_in_month(year, rule_month) { return Date { year: 0, month: 0, day: 0 }, false; }
        return Date { year: year, month: rule_month, day: rule_day }, true;
    }
    if rule_kind == RULE_NEAREST_WEEKDAY {
        if rule_day > days_in_month(year, rule_month) { return Date { year: 0, month: 0, day: 0 }, false; }
        let date = Date { year: year, month: rule_month, day: rule_day };
        let w = weekday_of_date(date);
        // A holiday on a Saturday moves to the Friday before it. A
        // holiday on a Sunday moves to the Monday after it.
        if w == 6 { return add_days(date, -1), true; }
        if w == 0 { return add_days(date, 1), true; }
        return date, true;
    }
    if rule_kind == RULE_EASTER_OFFSET {
        return add_days(easter(year), rule_easter), true;
    }
    if rule_kind == RULE_NTH_WEEKDAY {
        if rule_count < 1 || rule_count > 5 { return Date { year: 0, month: 0, day: 0 }, false; }
        let first = Date { year: year, month: rule_month, day: 1 };
        let first_w = weekday_of_date(first);
        let ahead = (rule_weekday - first_w + 7) % 7 + (rule_count - 1) * 7;
        let date = add_days(first, ahead);
        if date.month != rule_month { return Date { year: 0, month: 0, day: 0 }, false; }
        return date, true;
    }
    // The last weekday of the month. The search runs from the last day
    // of the month down to the named weekday.
    let last_day = days_in_month(year, rule_month);
    var date = Date { year: year, month: rule_month, day: last_day };
    while weekday_of_date(date) != rule_weekday {
        date = add_days(date, -1);
    }
    return date, true;
}

// roll_date gives the date that the convention rolls to. A date on a
// weekend moves out of the weekend. The conventions that hold the
// modified name move back into the month when the roll left it.
fn roll_date(date: Date, mode: i32, cal: Calendar) -> Date {
    var out = date;
    if mode == PRECEDING || mode == MODIFIED_PRECEDING {
        while !is_business_day(cal, out) {
            out = add_days(out, -1);
        }
        if mode == MODIFIED_PRECEDING {
            if out.month != date.month {
                out = date;
                while !is_business_day(cal, out) {
                    out = add_days(out, 1);
                }
            }
        }
        return out;
    }
    while !is_business_day(cal, out) {
        out = add_days(out, 1);
    }
    if mode == MODIFIED_FOLLOWING {
        if out.month != date.month {
            out = date;
            while !is_business_day(cal, out) {
                out = add_days(out, -1);
            }
        }
    }
    return out;
}

// calendar_of gives the calendar of the name. The days of the weekend
// are the Saturday and the Sunday for every calendar of the package.
fn calendar_of(name: i32) -> Calendar, bool {
    // The bit 0 is a Sunday and the bit 6 is a Saturday. Every
    // calendar of the package holds the weekend of two days.
    const mask: u8 = 1 | 64;
    if name < 0 || name > 4 { return Calendar { weekend_mask: 0, rules_at: 0, rule_count: 0, dates: NO_DATES[..], explicit: false }, false; }
    return Calendar {
        weekend_mask: mask,
        rules_at: RULE_OFFSETS[name],
        rule_count: RULE_OFFSETS[name + 1] - RULE_OFFSETS[name],
        dates: NO_DATES[..],
        explicit: false,
    }, true;
}

// is_weekend tells whether the date lies on a day of the weekend.
fn is_weekend(cal: Calendar, date: Date) -> bool {
    let w = weekday_of_date(date);
    return (cal.weekend_mask >> w) & 1 == 1;
}

// is_business_day tells whether the date is a business day. The date
// must lie outside a weekend and outside a holiday. A date outside the
// years of the rules holds no holiday.
fn is_business_day(cal: Calendar, date: Date) -> bool {
    if is_weekend(cal, date) { return false; }
    if cal.explicit {
        // The dates hold day numbers, so the search runs over numbers.
        let day = day_of_date(date);
        var i: i64 = 0;
        while i < cal.dates.len {
            if cal.dates[i] == day { return false; }
            i += 1;
        }
        return true;
    }
    if date.year < 1970 || date.year > 2100 { return true; }
    var i: i64 = 0;
    while i < cal.rule_count {
        let at = cal.rules_at + i;
        let holiday, ok = rule_date(RULE_KINDS[at], RULE_MONTHS[at], RULE_DAYS[at], RULE_WEEKDAYS[at], RULE_COUNTS[at], RULE_EASTER_DAYS[at], date.year);
        if ok && date_compare(holiday, date) == 0 { return false; }
        i += 1;
    }
    return true;
}

// add_business_days gives the date that lies the count of the business
// days after the date. A count that is below zero moves back. The
// search runs one day at a time, so the cost grows with the count. It
// gives false for a count of more than 100000 days either way.
fn add_business_days(cal: Calendar, date: Date, count: i64) -> Date, bool {
    if count > MAX_BUSINESS_STEP || count < -MAX_BUSINESS_STEP { return date, false; }
    var out = date;
    var left = count;
    let step = if count < 0 { -1 } else { 1 };
    while left != 0 {
        out = add_days(out, step);
        if is_business_day(cal, out) {
            left -= step;
        }
    }
    return out, true;
}

// business_days_between gives the count of the business days that lie
// between the two dates. The date of the start does not count. The
// date of the end counts when it lies after the date of the start.
fn business_days_between(cal: Calendar, a: Date, b: Date) -> i64 {
    var count: i64 = 0;
    if date_compare(a, b) >= 0 { return 0; }
    var day = add_days(a, 1);
    while date_compare(day, b) <= 0 {
        if is_business_day(cal, day) { count += 1; }
        day = add_days(day, 1);
    }
    return count;
}

// calendar_from_dates gives a calendar that holds the dates of the
// list as its holidays. The days of the weekend hold the values 0 to
// 6, where the value 0 is a Sunday. The caller keeps the storage of
// the two lists alive while the calendar is in use.
fn calendar_from_dates(dates: const i64[:], weekend: i64[:]) -> Calendar, bool {
    if dates.len > MAX_EXPLICIT_DATES { return Calendar { weekend_mask: 0, rules_at: 0, rule_count: 0, dates: NO_DATES[..], explicit: false }, false; }
    var mask: u8 = 0;
    var i: i64 = 0;
    while i < weekend.len {
        if weekend[i] < 0 || weekend[i] > 6 { return Calendar { weekend_mask: 0, rules_at: 0, rule_count: 0, dates: NO_DATES[..], explicit: false }, false; }
        mask |= (1 << weekend[i]) as u8;
        i += 1;
    }
    // A calendar whose seven days are all weekend holds no business
    // day, so every search for one would never end.
    if mask == 127 { return Calendar { weekend_mask: 0, rules_at: 0, rule_count: 0, dates: NO_DATES[..], explicit: false }, false; }
    return Calendar {
        weekend_mask: mask,
        rules_at: 0,
        rule_count: 0,
        dates: dates,
        explicit: true,
    }, true;
}

// The empty table of the dates of an explicit calendar. A calendar of
// rules holds no explicit dates, so it holds this table.
const NO_DATES: i64[] = [];
