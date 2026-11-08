# goose-finance

[![ci](https://github.com/rekanalar/goose-finance/actions/workflows/ci.yml/badge.svg)](https://github.com/rekanalar/goose-finance/actions/workflows/ci.yml)

Money, currency, time value of money, business-day calendars and instrument identifiers for the [Goose](https://github.com/aardappel/goose) programming language.

## Install

Put this line in the root file of your program:

```goose
import finance from "rekanalar/goose-finance@v0.1.0";
```

The CI runs the gate on Linux, macOS and Windows. It uses Goose v2026.4 and v2026.3 on each.
The package is pure Goose. It depends on the standard library only.

## Reference libraries

| Area | Reference |
|---|---|
| Money and rounding | py-moneyed, Joda-Money, rust_decimal, dinero.js, bojanz/currency |
| Formatting and locales | Python babel (CLDR 47) |
| Time value of money | numpy-financial, Excel |
| Day counts, rolls | QuantLib |
| Holidays | Python `holidays`, Go `rickar/cal` |
| Identifiers | python-stdnum |

## Features

- **Currency table.** All 307 ISO 4217 codes, current and historic, with number, name and minor-unit exponent.
- **Money.** An `i64` count of minor units and a currency. No float ever touches an amount.
- **Rounding.** Nine modes: `HALF_EVEN`, `HALF_UP`, `HALF_DOWN`, `HALF_ODD`, `UP`, `DOWN`, `CEILING`, `FLOOR`, `UNNECESSARY`.
- **Allocation.** `money_allocate` and `money_split` give parts that sum to the amount.
- **Format and parse.** 49 locales, with the symbol, the group marks and the decimal mark of each.
- **Time value of money.** `fv`, `pv`, `pmt`, `nper`, `rate`, `ipmt`, `ppmt`, `npv`, `npv_excel`, `irr`, `mirr`, `xnpv`, `xirr`, `amortisation`.
- **Day counts.** 30/360 US, 30E/360, ACT/360, ACT/365F and ACT/ACT ISDA.
- **Compounding.** Simple, annual, periodic and continuous.
- **Calendars.** US federal, NYSE, TARGET, UK and Germany. Four roll conventions. A calendar from your own dates.
- **Identifiers.** ISIN, CUSIP, FIGI and LEI with their check digits.

## API

| Name | What it does |
|---|---|
| `currency(code)` | Entry of the table, or `false` |
| `currency_by_number(number)` | Entry by numeric code |
| `currency_exponent(code)` | Minor-unit exponent, `-1` for none |
| `money(minor, code)` | Build an amount |
| `money_add`, `money_sub` | Checked sum and difference |
| `money_compare`, `money_min`, `money_max` | Order of two amounts |
| `money_mul_ratio(a, num, den, mode)` | Multiply by a fraction |
| `money_mul_percent(a, num, den, mode)` | Percentage `num/den` of an amount |
| `money_round(a, places, mode)` | Round to a number of places |
| `money_allocate(a, ratios)`, `money_split(a, n)` | Parts that sum to the amount |
| `locale(name)` | Rules of one locale |
| `money_format(out, a, locale)` | Text with the symbol |
| `money_format_code(out, a, locale)` | Text with the code |
| `money_parse(text, locale, code, mode)` | Strict parse |
| `fv`, `pv`, `pmt`, `nper`, `rate` | Annuity functions |
| `ipmt`, `ppmt` | Interest and principal part |
| `npv`, `npv_excel` | Net present value, two conventions |
| `irr`, `mirr`, `xnpv`, `xirr` | Return functions |
| `amortisation(...)` | Loan schedule |
| `year_fraction(count, a, b)` | Day count |
| `growth_factor`, `discount_factor` | Compounding |
| `calendar_of(name)`, `calendar_from_dates` | Build a calendar |
| `is_business_day`, `add_business_days`, `business_days_between` | Business days (`add_business_days` also gives a flag) |
| `roll_date(date, mode, cal)` | Roll convention |
| `easter(year)` | Easter Sunday |
| `isin_valid`, `isin_parts`, `isin_from_natid` | ISIN |
| `cusip_valid`, `cusip_parts` | CUSIP |
| `figi_valid` | FIGI |
| `lei_valid`, `lei_parts` | LEI |
| `luhn_valid`, `luhn_check_digit` | Luhn check |

## Example

```goose
import std;
import finance from "rekanalar/goose-finance@v0.1.0";

fn main() {
    let price, _ = finance::money(123457, "USD");
    var out: u8[>..] = [];
    finance::money_format(out, price, "en_US");
    print(out[..], "\n");   // $1,234.57
    return 0;
}
```

## Security

The package parses text from people you do not know. It adds these protections beyond the reference libraries.

- **No float in money.** An amount is an integer count of minor units. No amount rounds by accident.
- **Overflow is an error.** Every sum, difference, product and parse returns `false` on overflow. It never wraps. The product of an amount and a fraction runs in 128 bits.
- **Strict parse.** `money_parse` rejects a misplaced sign, bad group sizes, a second decimal mark and trailing bytes.
- **No silent rounding in parse.** A text with too many places is an error unless you name a rounding mode.
- **Bounded input.** `money_parse` rejects a text of more than 64 bytes.
- **Identifiers take ASCII only.** Each check tests the length first, then the bytes, then the check digit.
- **Bounded work.** A calendar from dates holds at most 400 dates. A calendar with seven weekend days is an error, because its searches would never end.
- **Bounded counts.** `add_business_days` stops at 100000 days. `money_split`, `money_allocate` and `amortisation` stop at 100000 parts or periods.

Risks that stay: the solvers `rate`, `irr` and `xirr` use `f64` and can return `NaN`. Check the result before you convert it to money.

## Limits

These are the places where this package differs from a reference, or does less.

- **Exponents follow ISO 4217.** CLDR and ISO 4217 disagree on 16 currencies. Python babel follows CLDR.
  CLDR gives 0 digits to AFN, ALL, IRR, KPW, LAK, LBP, MGA, MMK, MRO, RSD, SLL, SOS, STD, SYP, YER. ISO gives 2.
  CLDR gives 2 to IQD. ISO gives 3.
- **`npv` and `npv_excel` differ.** numpy-financial does not discount the first value. Excel discounts it by one period. No standard fixes it. Both exist.
- **One date for the table.** The currency table is a snapshot of ISO 4217 from 2026-09-17. It does not follow later amendments.
- **No historic money.** The money type does not check the withdrawal date of a currency.
- **Solvers use `f64`.** `rate`, `irr`, `mirr` and `xirr` are not exact decimals.
- **49 locales.** The table is a subset of CLDR. The spaces of CLDR (no-break and narrow no-break) are kept in group marks. The pad between symbol and amount is a plain space.
- **Holidays from 1970 to 2100.** Outside that range a calendar holds no holiday.
- **No ACT/ACT ICMA.** The day count needs the coupon schedule.
- **No composite FIGI.** Only the 12-byte FIGI is checked.
- **One currency per amount.** The sum of two currencies is an error. There is no exchange rate.
- **No time zone.** A date is a civil date.
- **`luhn_valid` is the ISIN form.** It expands each letter to two decimal digits first, as python-stdnum does. The Luhn mod N of goose-payment-identifier works over one alphabet instead.

## License

MIT
