#!/usr/bin/env python3
"""Make the tables of the locales of the finance package.

The script reads the locale data of the Python `babel` package. It writes
the file locale_data.goose. The file holds the decimal mark, the group
mark, the group size and the currency symbols of each locale.

The source of the data is CLDR 47 through the `babel` package of version
2.17.

Usage:
  python3 test/make_locale_data.py
"""

import sys
from pathlib import Path

try:
    from babel import Locale
except ImportError:
    sys.stderr.write("the Python package babel is not installed\n")
    raise

# The locales of the package. The set is a named subset of CLDR.
LOCALES = [
    "ar_EG", "bg_BG", "ca_ES", "cs_CZ", "da_DK", "de_AT", "de_CH", "de_DE",
    "el_GR", "en_AU", "en_GB", "en_IN", "en_US", "es_ES", "es_MX",
    "et_EE", "fi_FI", "fr_CA", "fr_FR", "he_IL", "hi_IN", "hr_HR",
    "hu_HU", "id_ID", "is_IS", "it_IT", "ja_JP", "ko_KR", "lt_LT",
    "lv_LV", "nb_NO", "nl_BE", "nl_NL", "pl_PL", "pt_BR", "pt_PT",
    "ro_RO", "ru_RU", "sk_SK", "sl_SI", "sq_AL", "sr_RS", "sv_SE",
    "sw_KE", "th_TH", "tr_TR", "uk_UA", "vi_VN", "zh_CN",
]

# The base of the symbols. The base is the locale of the United States.
# A locale that has no symbol of its own for a currency uses the symbol of
# the base. This is the rule of CLDR and of the babel package.
BASE_LOCALE = "en_US"


def group_sizes(locale):
    """Give the sizes of the groups of digits, from the right.

    Most locales use one group of three digits. The locales of India use
    a group of three digits, then groups of two digits. The count comes
    from the commas of the pattern.
    """
    pattern = locale.currency_formats["standard"].pattern
    text = pattern.split(";")[0]
    integer = text.split(".")[0]
    segments = integer.split(",")
    if len(segments) < 2:
        return [3]
    sizes = [len(segments[-1])]
    for segment in reversed(segments[:-1]):
        count = len(segment)
        if count > 0:
            sizes.append(count)
    return sizes[:2]


def pattern_info(locale):
    """Tell whether the symbol of the pattern sits before the amount.

    Also tell whether the pattern holds a pad of space between the symbol
    and the amount. The pad of CLDR is a no-break space. This package
    writes a plain space instead.
    """
    pattern = locale.currency_formats["standard"].pattern
    head = pattern.split(";")[0]
    place = head.find("¤")
    first = head.startswith("¤")
    pad = False
    if place > 0 and head[place - 1].isspace():
        pad = True
    if place + 1 < len(head) and head[place + 1].isspace():
        pad = True
    return first, pad


def goose_string(text):
    """Give a Goose string literal for the text."""
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
    base = Locale.parse(BASE_LOCALE)
    base_symbols = dict(base.currency_symbols)

    rows = []
    for name in LOCALES:
        locale = Locale.parse(name)
        symbols = locale.number_symbols["latn"]
        decimal = symbols["decimal"]
        group = symbols["group"]
        sizes = group_sizes(locale)
        first, pad = pattern_info(locale)
        own = {
            code: symbol
            for code, symbol in locale.currency_symbols.items()
            if base_symbols.get(code) != symbol
        }
        rows.append((name, decimal, group, sizes, first, pad, own))

    # The base symbols of every currency of the base locale.
    base_codes = sorted(base_symbols.keys())

    lines = []
    lines.append("// The tables of the locales of the finance package.")
    lines.append("//")
    lines.append("// Made by test/make_locale_data.py. Do not edit.")
    lines.append("// The source is CLDR 47 through the Python babel package")
    lines.append("// of version 2.17. The base of the symbols is the locale")
    lines.append("// of the United States.")
    lines.append("namespace finance;")
    lines.append("")
    lines.append("// The number of locales in the table.")
    lines.append(f"const LOCALE_COUNT: i64 = {len(rows)};")
    lines.append("")
    lines.append("// The name of each locale.")
    lines.append("const LOCALE_NAMES: const u8[:][] = [")
    for i in range(0, len(rows), 8):
        chunk = [r[0] for r in rows[i:i + 8]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The decimal mark of each locale.")
    lines.append("const LOCALE_DECIMALS: const u8[:][] = [")
    for i in range(0, len(rows), 8):
        chunk = [r[1] for r in rows[i:i + 8]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The group mark of each locale.")
    lines.append("const LOCALE_GROUPS: const u8[:][] = [")
    for i in range(0, len(rows), 8):
        chunk = [r[2] for r in rows[i:i + 8]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The count of the sizes of the groups of each locale.")
    lines.append("// The sizes follow in one flat table, from the right.")
    lines.append("const LOCALE_GROUP_SIZE_COUNTS: i32[] = [")
    for i in range(0, len(rows), 16):
        chunk = [str(len(r[3])) for r in rows[i:i + 16]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")
    flat_sizes = []
    for row in rows:
        flat_sizes.extend(row[3])
    lines.append("// The sizes of the groups of digits. The table holds the")
    lines.append("// size of the group at the right first. The locales of")
    lines.append("// India hold the value 3, then the value 2.")
    lines.append("const LOCALE_GROUP_SIZES: i32[] = [")
    for i in range(0, len(flat_sizes), 16):
        chunk = [str(v) for v in flat_sizes[i:i + 16]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The value 1 holds for a locale whose symbol stands")
    lines.append("// before the amount. The value 0 holds for a locale whose")
    lines.append("// symbol stands after the amount.")
    lines.append("const LOCALE_SYMBOL_FIRST: i32[] = [")
    for i in range(0, len(rows), 16):
        chunk = ["1" if r[4] else "0" for r in rows[i:i + 16]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The value 1 holds for a locale whose pattern holds a")
    lines.append("// pad of space between the symbol and the amount.")
    lines.append("const LOCALE_HAS_PAD: i32[] = [")
    for i in range(0, len(rows), 16):
        chunk = ["1" if r[5] else "0" for r in rows[i:i + 16]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("// The number of symbols of each locale that differ from")
    lines.append("// the base. The symbols follow in one flat table.")
    lines.append("const LOCALE_SYMBOL_COUNTS: i32[] = [")
    for i in range(0, len(rows), 16):
        chunk = [str(len(r[6])) for r in rows[i:i + 16]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")

    # The flat table of the symbols that differ from the base. Each entry
    # holds the index of the locale, the code of the currency and the
    # symbol.
    flat = []
    for index, row in enumerate(rows):
        for code in sorted(row[6].keys()):
            flat.append((index, code, row[6][code]))
    lines.append("// The symbols that differ from the base. Each entry holds")
    lines.append("// the index of the locale, the code of the currency and the")
    lines.append("// symbol. The entries of a locale sit next to each other.")
    lines.append("const LOCALE_SYMBOL_COUNT: i64 = "
                 f"{len(flat)};")
    lines.append("const LOCALE_SYMBOL_LOCALES: i32[] = [")
    for i in range(0, len(flat), 12):
        chunk = [str(f[0]) for f in flat[i:i + 12]]
        lines.append("    " + ", ".join(chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("const LOCALE_SYMBOL_CODES: const u8[:][] = [")
    for i in range(0, len(flat), 12):
        chunk = [f[1] for f in flat[i:i + 12]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("const LOCALE_SYMBOL_TEXTS: const u8[:][] = [")
    for i in range(0, len(flat), 8):
        chunk = [f[2] for f in flat[i:i + 8]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")

    lines.append("// The symbol of each currency of the base locale.")
    lines.append("const BASE_SYMBOL_CODES: const u8[:][] = [")
    for i in range(0, len(base_codes), 12):
        chunk = base_codes[i:i + 12]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("const BASE_SYMBOL_TEXTS: const u8[:][] = [")
    for i in range(0, len(base_codes), 8):
        chunk = [base_symbols[c] for c in base_codes[i:i + 8]]
        lines.append("    " + ", ".join(goose_string(c) for c in chunk) + ",")
    lines.append("];")
    lines.append("")

    out = Path(__file__).resolve().parent.parent / "locale_data.goose"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {out} with {len(rows)} locales and {len(flat)} symbols")
    return 0


if __name__ == "__main__":
    sys.exit(main())
