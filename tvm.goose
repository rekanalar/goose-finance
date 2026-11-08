// The time value of money of the finance package.
//
// The formulas follow the numpy-financial package of Python. The
// solvers run on the f64 numbers. A result that has no answer comes
// back as the value NaN.
//
// The count of the periods holds the value 0 for a payment at the end
// of each period and the value 1 for a payment at the start.
namespace finance;

// The value NaN. The math module of the version 2026.3 holds no such
// constant.
let NAN_VALUE = 0.0 / 0.0;

import std;
import math;

// The most runs of the solver of the rate. The value matches the
// numpy-financial package and the Excel function RATE.
const RATE_MAX_ITER: i64 = 100;
const RATE_TOL: f64 = 0.000001;

// The most periods that a schedule may hold. The bound keeps a hostile
// count from costing much memory.
const MAX_SCHEDULE: i64 = 100000;

// fv gives the future value. The rate holds the rate of one
// period. The payment and the present value hold the usual signs: a
// payment out of the holder is below zero.
fn fv(rate: f64, nper: f64, pmt: f64, pv: f64, when: i64) -> f64 {
    if rate == 0 {
        return -(pv + pmt * nper);
    }
    let t = pow(1 + rate, nper);
    return -pv * t - pmt * (1 + rate * when) / rate * (t - 1);
}

// pv gives the present value. It solves the formula of the future
// value for the present value.
fn pv(rate: f64, nper: f64, pmt: f64, fv: f64, when: i64) -> f64 {
    if rate == 0 {
        return -fv - pmt * nper;
    }
    let t = pow(1 + rate, nper);
    return (-fv - pmt * (1 + rate * when) / rate * (t - 1)) / t;
}

// pmt gives the payment of one period.
fn pmt(rate: f64, nper: f64, pv: f64, fv: f64, when: i64) -> f64 {
    if nper == 0 {
        return NAN_VALUE;
    }
    if rate == 0 {
        return -(fv + pv) / nper;
    }
    let t = pow(1 + rate, nper);
    let fact = (1 + rate * when) * (t - 1) / rate;
    return -(fv + pv * t) / fact;
}

// nper gives the count of the periods.
fn nper(rate: f64, pmt: f64, pv: f64, fv: f64, when: i64) -> f64 {
    if rate == 0 {
        if pmt == 0 { return NAN_VALUE; }
        return -(fv + pv) / pmt;
    }
    let z = pmt * (1 + rate * when) / rate;
    let top = -fv + z;
    let bottom = pv + z;
    if bottom == 0 || top / bottom <= 0 {
        return NAN_VALUE;
    }
    return log(top / bottom) / log(1 + rate);
}

// rate gives the rate of one period. The solver runs the rule of
// Newton from the guess 0.1. The solver stops when a run moves the
// value by less than the tolerance, or at the last run. The value NaN
// comes back when the solver finds no rate.
fn rate(nper: f64, pmt: f64, pv: f64, fv: f64, when: i64) -> f64 {
    let w = when as f64;
    var r: f64 = 0.1;
    var run: i64 = 0;
    while run < RATE_MAX_ITER {
        let t1 = pow(r + 1, nper);
        let t2 = pow(r + 1, nper - 1);
        let g = fv + t1 * pv + pmt * (t1 - 1) * (r * w + 1) / r;
        let gp = nper * t2 * pv
            - pmt * (t1 - 1) * (r * w + 1) / (r * r)
            + nper * pmt * t2 * (r * w + 1) / r
            + pmt * (t1 - 1) * w / r;
        if gp == 0 { return NAN_VALUE; }
        let step = g / gp;
        r -= step;
        if abs(step) < RATE_TOL {
            return r;
        }
        run += 1;
    }
    return NAN_VALUE;
}

// ipmt gives the part of the payment of the period that holds the
// interest. The period counts from 1.
fn ipmt(rate: f64, per: f64, nper: f64, pv: f64, future: f64, when: i64) -> f64 {
    if per < 1 || per > nper { return NAN_VALUE; }
    let payment = pmt(rate, nper, pv, future, when);
    // The balance that rests after the period before this one.
    let balance = fv(rate, per - 1, payment, pv, when);
    var interest = balance * rate;
    if when == 1 {
        if per == 1 {
            return 0;
        }
        interest /= 1 + rate;
    }
    return interest;
}

// ppmt gives the part of the payment of the period that pays off
// the present value. The period counts from 1.
fn ppmt(rate: f64, per: f64, nper: f64, pv: f64, fv: f64, when: i64) -> f64 {
    let payment = pmt(rate, nper, pv, fv, when);
    let interest = ipmt(rate, per, nper, pv, fv, when);
    return payment - interest;
}

// npv_excel gives the net present value. The first value of the table
// sits at the end of the first period, so it holds a discount of one
// period. This is the rule of Excel.
fn npv_excel(rate: f64, values: f64[:]) -> f64 {
    var out: f64 = 0;
    var t: i64 = 0;
    while t < values.len {
        out += values[t] / pow(1 + rate, (t + 1));
        t += 1;
    }
    return out;
}

// npv gives the net present value. The first value of the
// table sits at the start, so it holds no discount. This is the rule of
// the numpy-financial package of Python. The two rules differ, and no
// standard fixes the difference.
fn npv(rate: f64, values: f64[:]) -> f64 {
    var out: f64 = 0;
    var t: i64 = 0;
    while t < values.len {
        out += values[t] / pow(1 + rate, t);
        t += 1;
    }
    return out;
}

// irr gives the internal rate of return. The rate holds the rate
// where the net present value of the values is zero. The solver runs
// the rule of Newton from the guess 0.1. When the rule of Newton finds
// no rate, the solver runs a search between two rates that hold values
// of opposite signs. The value NaN comes back when no rate exists
// between the bounds.
fn irr(values: f64[:]) -> f64 {
    if values.len < 2 { return NAN_VALUE; }
    var r: f64 = 0.1;
    var run: i64 = 0;
    while run < RATE_MAX_ITER {
        let f = npv(r, values);
        // The numeric derivative of the value at the rate.
        let h = 0.0000001;
        let df = (npv(r + h, values) - f) / h;
        if df == 0 { break; }
        let step = f / df;
        r -= step;
        if r <= -1 { r = -0.9999999; }
        if abs(step) < RATE_TOL {
            return r;
        }
        run += 1;
    }
    // The search between two bounds. The value of the rate -1 has no
    // meaning, so the low bound stays above it.
    var low: f64 = -0.9999999;
    var high: f64 = 10;
    var f_low = npv(low, values);
    var f_high = npv(high, values);
    if f_low * f_high > 0 { return NAN_VALUE; }
    var tries: i64 = 0;
    while tries < 200 {
        let mid = (low + high) / 2;
        let f_mid = npv(mid, values);
        if abs(f_mid) < RATE_TOL { return mid; }
        if f_low * f_mid < 0 {
            high = mid;
            f_high = f_mid;
        } else {
            low = mid;
            f_low = f_mid;
        }
        tries += 1;
    }
    return (low + high) / 2;
}

// mirr gives the modified internal rate of return. The values
// below zero count at the rate of finance. The values from zero up
// count at the rate of reinvest.
fn mirr(values: f64[:], finance_rate: f64, reinvest_rate: f64) -> f64 {
    if values.len < 2 { return NAN_VALUE; }
    // The values of one sign hold a zero in the place of the other
    // sign, so that the place of every value in time stays.
    var positives: f64[>..] = [];
    var negatives: f64[>..] = [];
    var has_pos = false;
    var has_neg = false;
    var i: i64 = 0;
    while i < values.len {
        if values[i] < 0 {
            positives.push(0);
            negatives.push(values[i]);
            has_neg = true;
        } else {
            positives.push(values[i]);
            negatives.push(0);
            has_pos = true;
        }
        i += 1;
    }
    if !has_pos || !has_neg { return NAN_VALUE; }
    let top = abs(npv(reinvest_rate, positives[..]));
    let bottom = abs(npv(finance_rate, negatives[..]));
    if bottom == 0 { return NAN_VALUE; }
    let n = values.len as f64;
    return pow(top / bottom, 1 / (n - 1)) * (1 + reinvest_rate) - 1;
}

// xnpv gives the net present value of the values at the dates. The
// dates hold day numbers. The year of the discount holds 365 days.
// This is the rule of Excel.
fn xnpv(rate: f64, values: f64[:], dates: i64[:]) -> f64 {
    if values.len != dates.len || values.len < 1 { return NAN_VALUE; }
    let start = dates[0];
    var out: f64 = 0;
    var i: i64 = 0;
    while i < values.len {
        let years = (dates[i] - start) as f64 / 365;
        out += values[i] / pow(1 + rate, years);
        i += 1;
    }
    return out;
}

// xirr gives the internal rate of return of the values at the
// dates. The solver runs the rule of Newton from the guess 0.1. When
// the rule of Newton finds no rate, the solver runs a search between
// two bounds. The value NaN comes back when no rate exists.
fn xirr(values: f64[:], dates: i64[:]) -> f64 {
    if values.len != dates.len || values.len < 2 { return NAN_VALUE; }
    var r: f64 = 0.1;
    var run: i64 = 0;
    while run < RATE_MAX_ITER {
        let f = xnpv(r, values, dates);
        let h = 0.0000001;
        let df = (xnpv(r + h, values, dates) - f) / h;
        if df == 0 { break; }
        let step = f / df;
        r -= step;
        if r <= -1 { r = -0.9999999; }
        if abs(step) < RATE_TOL {
            return r;
        }
        run += 1;
    }
    var low: f64 = -0.9999999;
    var high: f64 = 10;
    var f_low = xnpv(low, values, dates);
    var f_high = xnpv(high, values, dates);
    if f_low * f_high > 0 { return NAN_VALUE; }
    var tries: i64 = 0;
    while tries < 200 {
        let mid = (low + high) / 2;
        let f_mid = xnpv(mid, values, dates);
        if abs(f_mid) < RATE_TOL { return mid; }
        if f_low * f_mid < 0 {
            high = mid;
            f_high = f_mid;
        } else {
            low = mid;
            f_low = f_mid;
        }
        tries += 1;
    }
    return (low + high) / 2;
}

// amortisation writes the schedule of a loan. The tables hold the
// number of the period, the payment, the interest, the part that pays
// off the loan and the balance that rests. The period counts from 1.
// The payment of the last period adjusts, so that the balance ends at
// zero.
fn amortisation(rate: f64, nper: i64, pv: f64, periods: i64[>..]&, payments: f64[>..]&, interests: f64[>..]&, principals: f64[>..]&, balances: f64[>..]&) -> bool {
    if nper < 1 || nper > MAX_SCHEDULE { return false; }
    let payment = pmt(rate, nper, pv, 0, 0);
    if is_nan(payment) { return false; }
    var balance = pv;
    var i: i64 = 0;
    while i < nper {
        // The interest adds to the balance. The payment takes it away.
        // The principal holds the part of the payment that lowers the
        // balance. The sign of the payment follows the sign of the
        // present value.
        let interest = balance * rate;
        var pay = payment;
        // The last period pays off the balance that rests.
        if i == nper - 1 {
            pay = -(balance + interest);
        }
        let principal = -interest - pay;
        balance += interest + pay;
        periods.push(i + 1);
        payments.push(pay);
        interests.push(interest);
        principals.push(principal);
        balances.push(balance);
        i += 1;
    }
    return true;
}
