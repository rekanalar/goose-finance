// The day counts and the compounding of the finance package.
//
// A day count gives the fraction of a year that lies between two
// dates. The rules follow the conventions of the bond markets. The
// names follow the names of the reference libraries.
//
// The compounding gives the growth factor of an amount at a rate over
// a fraction of a year, and the discount factor that goes with it.
namespace finance;

import std;
import math;

// The day counts.
const THIRTY_360_US: i32 = 0;
const THIRTY_E_360: i32 = 1;
const ACT_360: i32 = 2;
const ACT_365_FIXED: i32 = 3;
const ACT_ACT_ISDA: i32 = 4;

// The compounding rules.
const SIMPLE: i32 = 0;
const ANNUAL: i32 = 1;
const PERIODIC: i32 = 2;
const CONTINUOUS: i32 = 3;

// thirty_360_days gives the count of the days of the rule of the 30
// day months. The rule treats every month like a month of 30 days.
fn thirty_360_days(y1: i64, m1: i64, d1: i64, y2: i64, m2: i64, d2: i64, us: bool) -> i64 {
    var dd1 = d1;
    var dd2 = d2;
    if us {
        // The rule of the United States. The day of the first date
        // never holds a 31 when the rule moves it. The day of the
        // second date moves to 30 when the first date moved too.
        if dd1 == 31 { dd1 = 30; }
        if dd2 == 31 && dd1 == 30 { dd2 = 30; }
    } else {
        // The rule of Europe. The day 31 moves to 30 on both sides.
        if dd1 == 31 { dd1 = 30; }
        if dd2 == 31 { dd2 = 30; }
    }
    return (y2 - y1) * 360 + (m2 - m1) * 30 + (dd2 - dd1);
}

// year_fraction gives the fraction of a year between the two dates. The
// date before must not lie after the date after.
fn year_fraction(count: i32, before: Date, after: Date) -> f64 {
    if count == THIRTY_360_US {
        return thirty_360_days(before.year, before.month, before.day, after.year, after.month, after.day, true) as f64 / 360;
    }
    if count == THIRTY_E_360 {
        return thirty_360_days(before.year, before.month, before.day, after.year, after.month, after.day, false) as f64 / 360;
    }
    let days = day_of_date(after) - day_of_date(before);
    if count == ACT_360 {
        return days as f64 / 360;
    }
    if count == ACT_365_FIXED {
        return days as f64 / 365;
    }
    // The rule of the ISDA. The rule of the reference library runs in
    // three parts. The years between the two years count as whole
    // years. The part of the start year counts the days from the start
    // date to the first of January of the next year. The part of the
    // end year counts the days from the first of January of the end
    // year to the end date. A year that holds a day of February 29
    // holds 366 days.
    if before.year == after.year {
        let dib = if is_leap_year(before.year) { 366 } else { 365 };
        return (day_of_date(after) - day_of_date(before)) as f64 / dib;
    }
    var sum = (after.year - before.year - 1) as f64;
    let dib1 = if is_leap_year(before.year) { 366 } else { 365 };
    let dib2 = if is_leap_year(after.year) { 366 } else { 365 };
    let jan_next = days_from_civil(before.year + 1, 1, 1);
    sum += (jan_next - day_of_date(before)) as f64 / dib1;
    let jan_end = days_from_civil(after.year, 1, 1);
    sum += (day_of_date(after) - jan_end) as f64 / dib2;
    return sum;
}

// growth_factor gives the factor that an amount grows by at the rate
// over the fraction of the year. The rule PERIODIC compounds at the
// count of the periods of a year.
fn growth_factor(rule: i32, rate: f64, years: f64, periods_per_year: i64) -> f64 {
    if rule == SIMPLE {
        return 1 + rate * years;
    }
    if rule == ANNUAL {
        return pow(1 + rate, years);
    }
    if rule == PERIODIC {
        return pow(1 + rate / (periods_per_year), periods_per_year * years);
    }
    return exp(rate * years);
}

// discount_factor gives the factor that an amount of the future loses
// to come back to the start. The factor is the inverse of the growth
// factor. A factor that is not above zero has no inverse, so the value
// NaN comes back then.
fn discount_factor(rule: i32, rate: f64, years: f64, periods_per_year: i64) -> f64 {
    let g = growth_factor(rule, rate, years, periods_per_year);
    if g == 0 { return NAN_VALUE; }
    return 1 / g;
}
