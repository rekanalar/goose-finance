#!/usr/bin/env python3
"""Make the tables of the currencies of the finance package.

The script reads the ISO 4217 list one file of the SIX Group. That file
gives the current currencies. It reads the ISO 4217 list three file of the
same group. That file gives the historic currencies.

It writes the file currency_data.goose. The file holds the tables of the
codes, the numeric codes, the names and the minor-unit exponents.

The sources of the data are:
  https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml
  https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-three.xml

Usage:
  python3 test/make_currency_data.py <list-one.xml> <list-three.xml> <joda-currency.csv>
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# The exponent of a currency with no minor unit. Joda-Money holds the same
# value for such a currency.
NO_MINOR_UNIT = -1


def parse_xml(path):
    """Read the XML file and give its root.

    The file must not hold a DOCTYPE. A DOCTYPE can declare entities
    that make the parser expand a billion laughs or read a local file.
    The source of the data is a trusted file, and the script refuses the
    risk anyway.
    """
    text = Path(path).read_text(encoding="utf-8", errors="replace")
    if "<!DOCTYPE" in text.upper():
        raise ValueError(f"{path} holds a DOCTYPE")
    return ET.fromstring(text)


def read_list_one(path):
    """Read the current currencies. The list holds one entry per country.

    A currency of several countries appears once per country. The first
    entry of a code wins. It holds the exponent of the currency.
    """
    root = parse_xml(path)
    table = {}
    for entry in root.iter("CcyNtry"):
        code = (entry.findtext("Ccy") or "").strip()
        if not code or code in table:
            continue
        number = (entry.findtext("CcyNbr") or "").strip()
        name = (entry.findtext("CcyNm") or "").strip()
        minor = (entry.findtext("CcyMnrUnts") or "").strip()
        if minor == "N.A." or minor == "":
            exponent = NO_MINOR_UNIT
        else:
            exponent = int(minor)
        table[code] = (number, name, exponent)
    return table


def read_list_three(path):
    """Read the historic currencies. The list holds no minor unit.

    The exponent of a historic currency comes from the Joda-Money table.
    The script holds that table below.
    """
    root = parse_xml(path)
    table = {}
    for entry in root.iter("HstrcCcyNtry"):
        code = (entry.findtext("Ccy") or "").strip()
        if not code or code in table:
            continue
        number = (entry.findtext("CcyNbr") or "").strip()
        name = (entry.findtext("CcyNm") or "").strip()
        table[code] = (number, name)
    return table


def joda_exponents(path):
    """The minor-unit exponent of each currency.

    The values come from the CurrencyData.csv file of Joda-Money. The
    file holds the decimal places of each currency. A line holds the
    code, the numeric code and the decimal places. A line may hold a
    comment after the mark #.
    """
    table = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split("#")[0].split(",")
        if len(fields) < 3:
            continue
        code = fields[0].strip()
        try:
            places = int(fields[2].strip())
        except ValueError:
            continue
        table[code] = places
    return table


def goose_string(text):
    """Give a Go string literal for the text."""
    out = '"'
    for ch in text:
        if ch == '"':
            out += '\\"'
        elif ch == "\\":
            out += "\\\\"
        else:
            out += ch
    return out + '"'


def main():
    if len(sys.argv) != 4:
        sys.stderr.write(__doc__)
        return 2
    current = read_list_one(sys.argv[1])
    historic = read_list_three(sys.argv[2])
    exponents = joda_exponents(sys.argv[3])

    table = {}
    for code, (number, name, exponent) in current.items():
        table[code] = (number, name, exponent)
    for code, (number, name) in historic.items():
        if code in table:
            continue
        table[code] = (number, name, exponents.get(code, NO_MINOR_UNIT))

    codes = sorted(table.keys())
    lines = []
    lines.append("// The tables of the currencies of the finance package.")
    lines.append("//")
    lines.append("// Made by test/make_currency_data.py. Do not edit.")
    lines.append("// The source is the ISO 4217 list one file of 2026-09-17 and")
    lines.append("// the ISO 4217 list three file of 2026-01-01 of the SIX Group.")
    lines.append("// The exponent of a historic currency comes from the")
    lines.append("// CurrencyData.csv file of Joda-Money.")
    lines.append("namespace finance;")
    lines.append("")
    lines.append(f"// The number of currencies in the table.")
    lines.append(f"const CURRENCY_COUNT: i64 = {len(codes)};")
    lines.append("")
    lines.append("// The ISO 4217 code of each currency.")
    lines.append("const CURRENCY_CODES: const u8[:][] = [")
    for i in range(0, len(codes), 12):
        chunk = codes[i:i + 12]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The ISO 4217 numeric code of each currency.")
    lines.append("const CURRENCY_NUMBERS: const u8[:][] = [")
    for i in range(0, len(codes), 12):
        chunk = [table[c][0] for c in codes[i:i + 12]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The name of each currency.")
    lines.append("const CURRENCY_NAMES: const u8[:][] = [")
    for i in range(0, len(codes), 6):
        chunk = [table[c][1] for c in codes[i:i + 6]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The minor-unit exponent of each currency.")
    lines.append("// The value -1 stands for a currency with no minor unit.")
    lines.append("const CURRENCY_EXPONENTS: i32[] = [")
    for i in range(0, len(codes), 16):
        chunk = [str(table[c][2]) for c in codes[i:i + 16]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")

    out = Path(__file__).resolve().parent.parent / "currency_data.goose"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {out} with {len(codes)} currencies")
    return 0


if __name__ == "__main__":
    sys.exit(main())
