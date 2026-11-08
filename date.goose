// The civil date arithmetic of the finance package.
//
// A date is a year, a month and a day. The package also uses the day
// number of a date. The day number counts the days since the epoch
// 1970-01-01.
//
// The algorithm is the one of Howard Hinnant. It is public domain.
//
// The package holds no time and no time zone. A caller that needs them
// uses another package.
namespace finance;

import std;

// The most days that a date may be away from the epoch. The bound keeps
// the arithmetic of the year inside the range of an i64.
const MAX_DAY_NUMBER: i64 = 3652059;

// The most years that a date may hold. The bound keeps the arithmetic of
// the leap year rule inside the range of an i64.
const MAX_YEAR: i64 = 9999;

// Date is a civil date. The year holds a value from 0 to 9999.
struct Date {
    year: i64,
    month: i64,
    day: i64,
}

// is_leap_year tells whether the year has a day of February 29.
fn is_leap_year(year: i64) -> bool {
    if year % 4 != 0 { return false; }
    if year % 100 != 0 { return true; }
    return year % 400 == 0;
}

// days_in_month gives the count of the days of the month of the year. It
// gives 0 for a month outside the range of 1 to 12.
fn days_in_month(year: i64, month: i64) -> i64 {
    if month < 1 || month > 12 { return 0; }
    if month == 2 {
        if is_leap_year(year) { return 29; }
        return 28;
    }
    if month == 4 || month == 6 || month == 9 || month == 11 { return 30; }
    return 31;
}

// date_ok tells whether the year, the month and the day make a date that
// exists. The year must be from 0 to 9999.
fn date_ok(year: i64, month: i64, day: i64) -> bool {
    if year < 0 || year > MAX_YEAR { return false; }
    if month < 1 || month > 12 { return false; }
    if day < 1 { return false; }
    return day <= days_in_month(year, month);
}

// floor_div gives the quotient of a division that rounds down. The
// denominator must be above zero. The remainder of Goose is the
// Euclidean one, so the quotient of the remainder is the one that
// rounds down.
fn floor_div(a: i64, b: i64) -> i64 {
    return (a - a % b) / b;
}

// days_from_civil gives the day number of the date. The day number of
// 1970-01-01 is 0. The function gives the day number of a date before
// the epoch too. The value is negative then.
fn days_from_civil(year: i64, month: i64, day: i64) -> i64 {
    // The year moves to March, so that the day of the year runs from 0
    // at the start of March.
    var y = year;
    if month <= 2 { y -= 1; }
    // The era counts the years of 400 years. The year of an era runs
    // from 0 to 399.
    let era = floor_div(y, 400);
    let yoe = y - era * 400;
    // The month of a year that starts in March.
    let mp = if month > 2 { month - 3 } else { month + 9 };
    let doy = (153 * mp + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

// civil_from_days gives the year, the month and the day of the day
// number. It is the inverse of days_from_civil.
fn civil_from_days(days: i64) -> i64, i64, i64 {
    // The day number moves to March, so that the day of the year runs
    // from 0 at the start of March.
    let z = days + 719468;
    let era = floor_div(z, 146097);
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    return y, m, d;
}

// date_of_day gives the date of the day number.
fn date_of_day(days: i64) -> Date {
    let y, m, d = civil_from_days(days);
    return Date { year: y, month: m, day: d };
}

// day_of_date gives the day number of the date.
fn day_of_date(date: Date) -> i64 {
    return days_from_civil(date.year, date.month, date.day);
}

// weekday gives the day of the week of the day number. The value 0 is a
// Sunday and the value 6 is a Saturday.
fn weekday(days: i64) -> i64 {
    // The epoch 1970-01-01 was a Thursday.
    let w = (days + 4) % 7;
    if w < 0 { return w + 7; }
    return w;
}

// weekday_of_date gives the day of the week of the date. The value 0 is
// a Sunday and the value 6 is a Saturday.
fn weekday_of_date(date: Date) -> i64 {
    return weekday(day_of_date(date));
}

// add_days gives the date that lies the count of days after the date.
fn add_days(date: Date, count: i64) -> Date {
    return date_of_day(day_of_date(date) + count);
}

// date_compare gives -1, 0 or 1. The value is the order of the two
// dates.
fn date_compare(a: Date, b: Date) -> i64 {
    if a.year != b.year {
        if a.year < b.year { return -1; }
        return 1;
    }
    if a.month != b.month {
        if a.month < b.month { return -1; }
        return 1;
    }
    if a.day != b.day {
        if a.day < b.day { return -1; }
        return 1;
    }
    return 0;
}
