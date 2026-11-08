// An example for the finance package: business days and day counts.
//
// Run with: goose run examples/calendar.goose
import std;
import finance from "..";

fn main() {
    let cal, ok = finance::calendar_of(finance::CALENDAR_TARGET);
    assert(ok);
    let good_friday = finance::Date { year: 2026, month: 4, day: 3 };
    print("2026-04-03 is a business day: ", finance::is_business_day(cal, good_friday), "\n");
    let next, _ = finance::add_business_days(cal, good_friday, 1);
    print("next business day: ", next.year, "-", next.month, "-", next.day, "\n");
    let easter = finance::easter(2026);
    print("easter: ", easter.year, "-", easter.month, "-", easter.day, "\n");
    let a = finance::Date { year: 2026, month: 1, day: 1 };
    let b = finance::Date { year: 2026, month: 7, day: 1 };
    print("ACT/360: ", finance::year_fraction(finance::ACT_360, a, b), "\n");
    return 0;
}
