// The tables of the locales of the finance package.
//
// Made by test/make_locale_data.py. Do not edit.
// The source is CLDR 47 through the Python babel package
// of version 2.17. The base of the symbols is the locale
// of the United States.
namespace finance;

// The number of locales in the table.
const LOCALE_COUNT: i64 = 49;

// The name of each locale.
const LOCALE_NAMES: const u8[:][] = [
    "ar_EG", "bg_BG", "ca_ES", "cs_CZ", "da_DK", "de_AT", "de_CH", "de_DE",
    "el_GR", "en_AU", "en_GB", "en_IN", "en_US", "es_ES", "es_MX", "et_EE",
    "fi_FI", "fr_CA", "fr_FR", "he_IL", "hi_IN", "hr_HR", "hu_HU", "id_ID",
    "is_IS", "it_IT", "ja_JP", "ko_KR", "lt_LT", "lv_LV", "nb_NO", "nl_BE",
    "nl_NL", "pl_PL", "pt_BR", "pt_PT", "ro_RO", "ru_RU", "sk_SK", "sl_SI",
    "sq_AL", "sr_RS", "sv_SE", "sw_KE", "th_TH", "tr_TR", "uk_UA", "vi_VN",
    "zh_CN",
];

// The decimal mark of each locale.
const LOCALE_DECIMALS: const u8[:][] = [
    ".", ",", ",", ",", ",", ",", ".", ",",
    ",", ".", ".", ".", ".", ",", ".", ",",
    ",", ",", ",", ".", ".", ",", ",", ",",
    ",", ",", ".", ".", ",", ",", ",", ",",
    ",", ",", ",", ",", ",", ",", ",", ",",
    ",", ",", ",", ".", ".", ",", ",", ",",
    ".",
];

// The group mark of each locale.
const LOCALE_GROUPS: const u8[:][] = [
    ",", " ", ".", " ", ".", ".", "’", ".",
    ".", ",", ",", ",", ",", ".", ",", " ",
    " ", " ", " ", ",", ",", ".", " ", ".",
    ".", ".", ",", ",", " ", " ", " ", ".",
    ".", " ", ".", " ", ".", " ", " ", ".",
    " ", ".", " ", ",", ",", ".", " ", ".",
    ",",
];

// The count of the sizes of the groups of each locale.
// The sizes follow in one flat table, from the right.
const LOCALE_GROUP_SIZE_COUNTS: i32[] = [
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2,
];

// The sizes of the groups of digits. The table holds the
// size of the group at the right first. The locales of
// India hold the value 3, then the value 2.
const LOCALE_GROUP_SIZES: i32[] = [
    3, 2, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 3, 3, 3, 1,
    3, 1, 3, 2, 3, 2, 3, 2, 3, 2, 3, 1, 3, 2, 3, 1,
    3, 1, 3, 1, 3, 1, 3, 2, 3, 2, 3, 1, 3, 1, 3, 2,
    3, 1, 3, 1, 3, 2, 3, 2, 3, 1, 3, 1, 3, 1, 3, 3,
    3, 3, 3, 1, 3, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1,
    3, 1, 3, 1, 3, 1, 3, 3, 3, 2, 3, 2, 3, 1, 3, 1,
    3, 2,
];

// The value 1 holds for a locale whose symbol stands
// before the amount. The value 0 holds for a locale whose
// symbol stands after the amount.
const LOCALE_SYMBOL_FIRST: i32[] = [
    0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0,
    0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1,
    1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0,
    1,
];

// The value 1 holds for a locale whose pattern holds a
// pad of space between the symbol and the amount.
const LOCALE_HAS_PAD: i32[] = [
    1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1,
    1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1,
    0,
];

// The number of symbols of each locale that differ from
// the base. The symbols follow in one flat table.
const LOCALE_SYMBOL_COUNTS: i32[] = [
    26, 18, 10, 11, 6, 4, 5, 4, 4, 22, 2, 1, 0, 20, 23, 4,
    17, 41, 38, 4, 3, 19, 18, 8, 15, 10, 3, 4, 20, 4, 19, 9,
    9, 16, 6, 6, 18, 6, 15, 9, 6, 7, 24, 6, 4, 4, 19, 4,
    7,
];

// The symbols that differ from the base. Each entry holds
// the index of the locale, the code of the currency and the
// symbol. The entries of a locale sit next to each other.
const LOCALE_SYMBOL_COUNT: i64 = 558;
const LOCALE_SYMBOL_LOCALES: i32[] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5,
    5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7,
    8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9,
    9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    9, 9, 10, 10, 11, 13, 13, 13, 13, 13, 13, 13,
    13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
    13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16,
    16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17,
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
    18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
    18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
    18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 21,
    21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
    21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22,
    22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
    23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24,
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25,
    25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26,
    27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28,
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    29, 29, 29, 29, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 31,
    31, 31, 31, 31, 31, 31, 31, 31, 32, 32, 32, 32,
    32, 32, 32, 32, 32, 33, 33, 33, 33, 33, 33, 33,
    33, 33, 33, 33, 33, 33, 33, 33, 33, 34, 34, 34,
    34, 34, 34, 35, 35, 35, 35, 35, 35, 36, 36, 36,
    36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36,
    36, 36, 36, 37, 37, 37, 37, 37, 37, 38, 38, 38,
    38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38,
    39, 39, 39, 39, 39, 39, 39, 39, 39, 40, 40, 40,
    40, 40, 40, 41, 41, 41, 41, 41, 41, 41, 42, 42,
    42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42,
    42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 43, 43,
    43, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 45,
    46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
    46, 46, 46, 46, 46, 46, 46, 47, 47, 47, 47, 48,
    48, 48, 48, 48, 48, 48,
];

const LOCALE_SYMBOL_CODES: const u8[:][] = [
    "AED", "AUD", "BHD", "DZD", "EGP", "GBP", "IQD", "IRR", "JOD", "JPY", "KWD", "LBP",
    "LYD", "MAD", "MRU", "OMR", "PHP", "QAR", "SAR", "SDD", "SDG", "SYP", "THB", "TND",
    "USD", "YER", "AUD", "BGN", "BRL", "CAD", "CNY", "GBP", "HKD", "ILS", "INR", "JPY",
    "KRW", "MXN", "NZD", "PHP", "TWD", "USD", "VND", "XCD", "AUD", "BRL", "CAD", "CNY",
    "ESP", "MXN", "PHP", "THB", "USD", "XCD", "AUD", "CSK", "CZK", "ILS", "INR", "JPY",
    "PHP", "USD", "VND", "XEU", "XXX", "AUD", "DKK", "JPY", "PHP", "THB", "USD", "ATS",
    "AUD", "PHP", "THB", "ATS", "AUD", "EUR", "PHP", "THB", "ATS", "AUD", "PHP", "THB",
    "GRD", "JPY", "PHP", "THB", "AUD", "BRL", "CAD", "CNY", "EUR", "GBP", "HKD", "ILS",
    "INR", "JPY", "KRW", "MXN", "NZD", "PHP", "SCR", "TWD", "USD", "VND", "XAF", "XCD",
    "XOF", "XPF", "JPY", "USD", "JPY", "AUD", "BRL", "CAD", "CNY", "ESP", "GBP", "HKD",
    "ILS", "INR", "JPY", "KRW", "MXN", "NZD", "PHP", "THB", "TWD", "USD", "XAF", "XCD",
    "XOF", "AUD", "BRL", "CAD", "CNY", "ESP", "EUR", "GBP", "HKD", "ILS", "INR", "JPY",
    "KRW", "MRU", "MXN", "NZD", "PHP", "THB", "TWD", "USD", "VND", "XAF", "XCD", "XOF",
    "AUD", "EEK", "PHP", "THB", "AUD", "BRL", "CAD", "CNY", "FIM", "HKD", "ILS", "INR",
    "KRW", "MXN", "NZD", "PHP", "TWD", "VND", "XCD", "XPF", "XXX", "ARS", "AUD", "BEF",
    "BMD", "BND", "BZD", "CAD", "CLP", "COP", "CYP", "FJD", "FKP", "FRF", "GIP", "HKD",
    "IEP", "ILP", "ILS", "INR", "ITL", "KRW", "LBP", "MTP", "MXN", "NAD", "NZD", "PHP",
    "RHD", "SBD", "SGD", "SRD", "TTD", "TWD", "USD", "UYU", "VND", "WST", "XAF", "XCD",
    "XOF", "XPF", "ARS", "AUD", "BEF", "BMD", "BND", "BZD", "CAD", "CLP", "CNY", "COP",
    "CYP", "FJD", "FKP", "FRF", "GBP", "GIP", "HKD", "IEP", "ILP", "ITL", "JPY", "LBP",
    "MTP", "MXN", "NAD", "NZD", "PHP", "RHD", "SBD", "SGD", "SRD", "TTD", "TWD", "USD",
    "UYU", "WST", "XCD", "XPF", "CNY", "ILP", "PHP", "THB", "JPY", "PHP", "THB", "AUD",
    "BRL", "CAD", "CNY", "GBP", "HKD", "HRK", "ILS", "INR", "JPY", "KRW", "MXN", "NZD",
    "PHP", "TWD", "USD", "VND", "XCD", "XPF", "AUD", "BRL", "CAD", "CNY", "EUR", "GBP",
    "HKD", "HUF", "ILS", "INR", "KRW", "MXN", "NZD", "PHP", "TWD", "USD", "VND", "XCD",
    "AUD", "IDR", "INR", "JPY", "PHP", "THB", "USD", "XXX", "AUD", "BRL", "CAD", "EUR",
    "GBP", "INR", "ISK", "JPY", "KRW", "MXN", "NZD", "PHP", "TWD", "USD", "VND", "BRL",
    "HKD", "INR", "JPY", "KRW", "MXN", "THB", "TWD", "USD", "VND", "CNY", "JPY", "PHP",
    "AUD", "JPY", "PHP", "USD", "AUD", "BRL", "CAD", "CNY", "GBP", "HKD", "ILS", "INR",
    "JPY", "KRW", "MXN", "NZD", "PHP", "TWD", "USD", "VND", "XAF", "XCD", "XOF", "XPF",
    "AUD", "LVL", "PHP", "THB", "AUD", "BRL", "CAD", "CNY", "HKD", "ILS", "INR", "JPY",
    "KRW", "MXN", "NOK", "NZD", "PHP", "TWD", "USD", "VND", "XAF", "XCD", "XPF", "AUD",
    "CAD", "FJD", "JPY", "PHP", "SBD", "THB", "USD", "XPF", "AUD", "CAD", "FJD", "JPY",
    "PHP", "SBD", "THB", "USD", "XPF", "AUD", "CAD", "CNY", "GBP", "HKD", "ILS", "INR",
    "JPY", "KRW", "MXN", "NZD", "PHP", "PLN", "TWD", "USD", "VND", "AUD", "JPY", "PHP",
    "PTE", "THB", "USD", "AUD", "JPY", "PHP", "PTE", "THB", "USD", "AUD", "BRL", "CAD",
    "CNY", "EUR", "GBP", "HKD", "ILS", "INR", "JPY", "KRW", "MXN", "NZD", "PHP", "TWD",
    "USD", "VND", "XCD", "PHP", "RUB", "RUR", "THB", "TMT", "UAH", "AUD", "BRL", "CAD",
    "CNY", "GBP", "HKD", "ILS", "INR", "JPY", "KRW", "NZD", "PHP", "TWD", "USD", "VND",
    "AUD", "BRL", "CAD", "GBP", "MXN", "NZD", "PHP", "TWD", "XCD", "ALL", "BRL", "JPY",
    "PHP", "THB", "USD", "AUD", "BAM", "KRW", "NZD", "PHP", "USD", "VND", "AUD", "BBD",
    "BMD", "BRL", "BSD", "BZD", "CNY", "DKK", "DOP", "EGP", "GBP", "HKD", "INR", "ISK",
    "JMD", "JPY", "KRW", "NOK", "NZD", "PHP", "SEK", "TWD", "USD", "VND", "JPY", "KES",
    "PHP", "THB", "TZS", "USD", "AUD", "PHP", "THB", "USD", "AUD", "PHP", "THB", "TRY",
    "AUD", "BRL", "CAD", "CNY", "EUR", "GBP", "HKD", "ILS", "INR", "KRW", "MXN", "NZD",
    "PHP", "TWD", "UAH", "UAK", "USD", "VND", "XCD", "AUD", "PHP", "THB", "USD", "AUD",
    "CNY", "ILR", "JPY", "PHP", "USD", "XXX",
];

const LOCALE_SYMBOL_TEXTS: const u8[:][] = [
    "د.إ.‏", "AU$", "د.ب.‏", "د.ج.‏", "ج.م.‏", "UK£", "د.ع.‏", "ر.إ.",
    "د.أ.‏", "JP¥", "د.ك.‏", "ل.ل.‏", "د.ل.‏", "د.م.‏", "أ.م.", "ر.ع.‏",
    "PHP", "ر.ق.‏", "ر.س.‏", "د.س.‏", "ج.س.", "ل.س.‏", "฿", "د.ت.‏",
    "US$", "ر.ي.‏", "AUD", "лв.", "BRL", "CAD", "CNY", "GBP",
    "HKD", "ILS", "INR", "JPY", "KRW", "MXN", "NZD", "PHP",
    "TWD", "щ.д.", "VND", "XCD", "AU$", "BRL", "CAD", "CNY",
    "₧", "MXN", "PHP", "฿", "USD", "XCD", "AU$", "Kčs",
    "Kč", "ILS", "INR", "JP¥", "PHP", "US$", "VND", "ECU",
    "XXX", "AU$", "kr.", "JP¥", "PHP", "฿", "US$", "öS",
    "AU$", "PHP", "฿", "öS", "AU$", "EUR", "PHP", "฿",
    "öS", "AU$", "PHP", "฿", "Δρχ", "JP¥", "PHP", "฿",
    "$", "BRL", "CAD", "CNY", "EUR", "GBP", "HKD", "ILS",
    "INR", "JPY", "KRW", "MXN", "NZD", "PHP", "Rs", "TWD",
    "USD", "VND", "XAF", "XCD", "XOF", "CFP", "JP¥", "US$",
    "JP¥", "AUD", "BRL", "CAD", "CNY", "₧", "GBP", "HKD",
    "ILS", "INR", "JPY", "KRW", "MXN", "NZD", "PHP", "฿",
    "TWD", "US$", "XAF", "XCD", "XOF", "AUD", "BRL", "CAD",
    "CNY", "₧", "EUR", "GBP", "HKD", "ILS", "INR", "JPY",
    "KRW", "UM", "$", "NZD", "PHP", "THB", "TWD", "USD",
    "VND", "XAF", "XCD", "XOF", "AU$", "kr", "PHP", "฿",
    "AUD", "BRL", "CAD", "CNY", "mk", "HKD", "ILS", "INR",
    "KRW", "MXN", "NZD", "PHP", "TWD", "VND", "XCD", "XPF",
    "XXX", "ARS", "$ AU", "FB", "BMD", "BND", "BZD", "$",
    "CLP", "COP", "£CY", "FJD", "FKP", "F", "GIP", "$ HK",
    "£IE", "£IL", "ILS", "INR", "₤IT", "KRW", "LBP", "£MT",
    "MXN", "NAD", "$ NZ", "PHP", "$RH", "SBD", "$ SG", "SRD",
    "TTD", "TWD", "$ US", "UYU", "VND", "WST", "XAF", "XCD",
    "XOF", "XPF", "$AR", "$AU", "FB", "$BM", "$BN", "$BZ",
    "$CA", "$CL", "CNY", "$CO", "£CY", "$FJ", "£FK", "F",
    "£GB", "£GI", "HKD", "£IE", "£IL", "₤IT", "JPY", "£LB",
    "£MT", "$MX", "$NA", "$NZ", "PHP", "$RH", "$SB", "$SG",
    "$SR", "$TT", "TWD", "$US", "$UY", "$WS", "XCD", "FCFP",
    "‎CN¥‎", "ל״י", "PHP", "฿", "JP¥", "PHP", "฿", "AUD",
    "BRL", "CAD", "CNY", "GBP", "HKD", "kn", "ILS", "INR",
    "JPY", "KRW", "MXN", "NZD", "PHP", "TWD", "USD", "VND",
    "XCD", "XPF", "AUD", "BRL", "CAD", "CNY", "EUR", "GBP",
    "HKD", "Ft", "ILS", "INR", "KRW", "MXN", "NZD", "PHP",
    "TWD", "USD", "VND", "XCD", "AU$", "Rp", "Rs", "JP¥",
    "PHP", "฿", "US$", "XXX", "AUD", "BRL", "CAD", "EUR",
    "GBP", "INR", "kr.", "JP¥", "KRW", "MXN", "NZD", "PHP",
    "TWD", "USD", "VND", "BRL", "HKD", "INR", "JPY", "KRW",
    "MXN", "฿", "TWD", "USD", "VND", "元", "￥", "PHP",
    "AU$", "JP¥", "PHP", "US$", "AUD", "BRL", "CAD", "CNY",
    "GBP", "HKD", "ILS", "INR", "JPY", "KRW", "MXN", "NZD",
    "PHP", "TWD", "USD", "VND", "XAF", "XCD", "XOF", "XPF",
    "AU$", "Ls", "PHP", "฿", "AUD", "BRL", "CAD", "CNY",
    "HKD", "ILS", "INR", "JPY", "KRW", "MXN", "kr", "NZD",
    "PHP", "TWD", "USD", "VND", "XAF", "XCD", "XPF", "AU$",
    "C$", "FJ$", "JP¥", "PHP", "SI$", "฿", "US$", "XPF",
    "AU$", "C$", "FJ$", "JP¥", "PHP", "SI$", "฿", "US$",
    "XPF", "AUD", "CAD", "CNY", "GBP", "HKD", "ILS", "INR",
    "JPY", "KRW", "MXN", "NZD", "PHP", "zł", "TWD", "USD",
    "VND", "AU$", "JP¥", "PHP", "Esc.", "฿", "US$", "AU$",
    "JP¥", "PHP", "​", "฿", "US$", "AUD", "BRL", "CAD",
    "CNY", "EUR", "GBP", "HKD", "ILS", "INR", "JPY", "KRW",
    "MXN", "NZD", "PHP", "TWD", "USD", "VND", "XCD", "PHP",
    "₽", "р.", "฿", "ТМТ", "₴", "AUD", "BRL", "CAD",
    "CNY", "GBP", "HKD", "NIS", "INR", "JPY", "KRW", "NZD",
    "PHP", "TWD", "USD", "VND", "AUD", "BRL", "CAD", "GBP",
    "MXN", "NZD", "PHP", "TWD", "XCD", "Lekë", "BRL", "JP¥",
    "PHP", "฿", "US$", "AUD", "КМ", "KRW", "NZD", "PHP",
    "US$", "VND", "AUD", "Bds$", "BM$", "BR$", "BS$", "BZ$",
    "CNY", "Dkr", "RD$", "EG£", "GBP", "HKD", "INR", "Ikr",
    "JM$", "JPY", "KRW", "Nkr", "NZD", "PHP", "kr", "TWD",
    "US$", "VND", "JP¥", "Ksh", "PHP", "฿", "TSh", "US$",
    "AU$", "PHP", "฿", "US$", "AU$", "PHP", "฿", "₺",
    "AUD", "BRL", "CAD", "CNY", "EUR", "GBP", "HKD", "ILS",
    "INR", "KRW", "MXN", "NZD", "PHP", "TWD", "₴", "крб.",
    "USD", "VND", "XCD", "AU$", "PHP", "฿", "US$", "AU$",
    "¥", "ILS", "JP¥", "PHP", "US$", "XXX",
];

// The symbol of each currency of the base locale.
const BASE_SYMBOL_CODES: const u8[:][] = [
    "AUD", "BRL", "CAD", "CNY", "EUR", "GBP", "HKD", "ILS", "INR", "JPY", "KRW", "MXN",
    "NZD", "PHP", "TWD", "USD", "VND", "XAF", "XCD", "XCG", "XOF", "XPF", "XXX",
];

const BASE_SYMBOL_TEXTS: const u8[:][] = [
    "A$", "R$", "CA$", "CN¥", "€", "£", "HK$", "₪",
    "₹", "¥", "₩", "MX$", "NZ$", "₱", "NT$", "$",
    "₫", "FCFA", "EC$", "Cg.", "F CFA", "CFPF", "¤",
];
