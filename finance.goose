// finance - money, the time value of money, business-day calendars and
// instrument identifiers for Goose.
//
// The package holds a money value. The value is an integer count of minor
// units and a currency. It never uses a float.
//
// The package holds the ISO 4217 table of the currencies. The table is a
// snapshot of one date. The README names the date.
//
// The package holds the calls of the time value of money. The calls
// follow the numpy-financial package of Python and the Excel functions.
//
// The package holds the calendars of five markets. A calendar holds
// rules, not a list of dates.
//
// The package holds the ISIN, CUSIP, FIGI and LEI identifiers.
namespace finance;

import std;
import math;
import currency_data;
import locale_data;
import date;
import currency;
import money;
import format;
import tvm;
import daycount;
import calendar;
import identifiers;
