// An example for the finance package: instrument identifiers.
//
// Run with: goose run examples/identifiers.goose
import std;
import finance from "..";

fn main() {
    print("ISIN US0378331005: ", finance::isin_valid("US0378331005"), "\n");
    print("ISIN US0378331004: ", finance::isin_valid("US0378331004"), "\n");
    print("CUSIP 037833100: ", finance::cusip_valid("037833100"), "\n");
    print("FIGI BBG000BLNQ16: ", finance::figi_valid("BBG000BLNQ16"), "\n");
    print("LEI 213800KUD8LAJWSQ9D15: ", finance::lei_valid("213800KUD8LAJWSQ9D15"), "\n");
    var isin: u8[>..] = [];
    let ok = finance::isin_from_natid(isin, "US", "91324PAE2");
    print("made ISIN: ", isin[..], " ok: ", ok, "\n");
    return 0;
}
