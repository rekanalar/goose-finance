// An example for the finance package: a loan schedule.
//
// Run with: goose run examples/loan.goose
import std;
import finance from "..";

fn main() {
    // 10000 at 6 percent a year, paid in 12 monthly payments.
    var periods: i64[>..] = [];
    var pays: f64[>..] = [];
    var ints: f64[>..] = [];
    var prins: f64[>..] = [];
    var bals: f64[>..] = [];
    let ok = finance::amortisation(0.06 / 12, 12, 10000, periods, pays, ints, prins, bals);
    assert(ok);
    var i: i64 = 0;
    while i < periods.len {
        print(periods[i], " pay ", pays[i], " interest ", ints[i], " balance ", bals[i], "\n");
        i += 1;
    }
    print("monthly payment: ", finance::pmt(0.06 / 12, 12, 10000, 0, 0), "\n");
    return 0;
}
