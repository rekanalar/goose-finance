// An example for the finance package: money, rounding and formatting.
//
// Run with: goose run examples/money.goose
import std;
import finance from "..";

fn main() {
    let price, _ = finance::money(123457, "USD");
    var out: u8[>..] = [];
    finance::money_format(out, price, "en_US");
    print("en_US: ", out[..], "\n");
    var fr: u8[>..] = [];
    finance::money_format(fr, price, "fr_FR");
    print("fr_FR: ", fr[..], "\n");
    var inr: u8[>..] = [];
    let rupees, _ = finance::money(12345678901, "INR");
    finance::money_format(inr, rupees, "hi_IN");
    print("hi_IN: ", inr[..], "\n");

    // Split 1.00 USD in three parts. The parts sum to the amount.
    let dollar, _ = finance::money(100, "USD");
    let parts, ok = finance::money_split(dollar, 3);
    assert(ok);
    var i: i64 = 0;
    while i < parts.len {
        print("part ", i, ": ", parts[i].minor, "\n");
        i += 1;
    }

    // Parse a text. A text with too many decimal places is an error
    // unless the caller names a rounding mode.
    let _, strict = finance::money_parse("$1.005", "en_US", "USD", finance::ROUND_UNNECESSARY);
    print("strict parse ok: ", strict, "\n");
    let rounded, ok2 = finance::money_parse("$1.005", "en_US", "USD", finance::ROUND_HALF_EVEN);
    print("rounded parse: ", rounded.minor, " ok: ", ok2, "\n");
    return 0;
}
