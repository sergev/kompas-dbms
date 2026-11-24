# The KOMPAS engine and tools

KOMPAS is a CODASYL (network) DBMS. The original sources of the engine and of its tools GEN, MAD and PREDT are lost. They are written here anew in Free Pascal. The language descriptions they follow are the original texts of 1988-89 by Pavel Severov: schemas, loader decks, queries and application programs (see `tests/`).

No historical outputs survive. So the check is consistency and review by hand, not comparison with a reference: a loader of 1988 and a query of 1988 must agree with each other, and the application programs must run their sessions.

## 1. Layout

| File | What |
|---|---|
| `src/kdb.pas` | the engine: schema, records, sets, currency, DML |
| `src/kgost.pas` | the internal 8-bit code (GOST 10859) and UTF-8 |
| `src/rt/mars.pas` | MARS: keyed storage of areas, one file per area in `$MARS_DIR` |
| `src/rt/krt.pas` | runtime of KOMPAS Pascal programs: `integer` = 64 bits, `alfa`, write formats |
| `src/rt/kio.pas` | standard input and output of KOMPAS Pascal programs in UTF-8 |
| `src/servis.pas` | `servis`: areas, journals |
| `src/ttc.pas` | `ttc`: the schema (DDL) into catalogue 270000 (`CXHD`/`CXFL`/`CXAT`) |
| `src/gen.pas`, `src/kgenrt.pas` | `gen`: the loader generator and the runtime of its loaders |
| `src/mad.pas` | `mad`: the query language |
| `src/predt.pas` | `predt`: the front end of KOMPAS Pascal |
| `src/kpc` | `predt` + `fpc` in one command |
| `src/sevlib.pas` | native parts of the lost library of the Severov programs |

`make` builds the tools into `build/bin` and the units for user programs into `build/lib`.

## 2. KOMPAS Pascal

Programs with DML are Free Pascal with two additions: Russian identifiers, and DML statements between `&&` and `&&`. `predt` turns such a program into plain Free Pascal:

- `&&ПОДСХЕ X&&` declares the records of the schema in `$MARS_DIR`: types `ZZ<record>`, variables named as the records, `ZZBDKEY`, `СОСТ`, and procedures that move fields between the variables and the engine.
- Every statement fragment becomes `begin … СОСТ:=KSTAT end` with its own `;` (except before `ELSE`). `НАБ s` and `ЗП r` become the numbers of a set and of a record.
- Names with non-ASCII letters become ASCII names. Latin and Cyrillic homoglyphs give the same name (`С` and `C`), and so do lower and upper case.
- String literals become the internal code. Programs work in that code; `kio` converts standard input from UTF-8 and output to UTF-8.
- Each `packed array[1..N] of char` becomes one named type `ZZC<N>` (`alfa` for 6). In Turbo Pascal mode two arrays of the same shape are otherwise incompatible.
- Without `{$mode}` the program gets `{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}`, and it uses `krt`, `kio`, `kdb` (added to its own `uses` clause if it has one).

DML forms supported (all those of the 1988 decks):

- `НАЙТИ` of every kind, with the key from a literal, a variable or a field;
- `ВЗЯТЬ [rec][.fld] [НА x]`, `ВЗЯТЬ`/`ЗАМЕНИ БД-КЛЮ`;
- `ПОСТАВ[ИТЬ]`, `ВКЛЮЧИ`, `ИСКЛЮЧ[И]`, `УБРАТЬ`, `ЗАМЕНИ[ТЬ] [rec][.fld НА v]`;
- `ЖУРНАЛ`, `КОМПАС`, `ЗАВЕРШ`.

Not supported: `ЯЗЫК`, `@var`, `*n`, `buf;oper`, `ЗАПРОС`.

## 3. The engine

- **Schema.** It is read from catalogue 270000, where `ttc` writes it: records `NUM`, `Tnnn`, `Rnnn`, `Frrrff`, `Snnn`, `Asssaa`. What is kept:
  - the length of `СИМВОЛ n` and all digits of `РАЗМЕР`;
  - the area of each record;
  - the set attributes, including `ВЫБОР … ИСПОЛЬЗ`.
- **Records.** They live in the MARS containers of their areas, which `servis` creates. The MARS key of a record is its DB-key.
- **Sets.** They are CODASYL chains:
  - an owner keeps first and last;
  - a member keeps next, prior and owner.

  Singular sets `SY-*` hang on an anchor (DB-key 1). The anchor also holds the chain of every record type (`НАЙТИ ПЕРВУЮ <record>`) and the record `SYSTEM`.
- **Sets in detail:**
  - ordering `ПО-ЭЛЕ` with a duplicate check (`ДУБЛИК РАЗРЕШ`);
  - automatic membership on `ПОСТАВ`, except `ВКЛЮЧЕ ВРУЧНУ`;
  - reordering when `ЗАМЕНИ` changes the key;
  - recursive sets;
  - choice of the owner by `ВЫБОР t ИСПОЛЬЗ r.f`.
- **Currency.** It is kept for the run unit, for each record type and for each set.
  - `НАЙТИ ПЕРВУЮ` takes the occurrence the current record owns, if that record is of the owner type.
  - `НАЙТИ СЛЕДУЮ` goes to the next member. This is how a tree is walked in `tests/gold-zt0/deck9.mad`.
- **Journal.** Every change is written to the area named by `ЖУРНАЛ`. There is no recovery from the journal.
- **Status.** `СОСТ` (`KSTAT`) codes are a hypothesis (`doc/open-questions.md`):
  - 0 ok, 1 end of set, 2 not found, 3 duplicate key;
  - 4 no current record, 5 membership error, 6 bad name, 7 storage error, 8 no schema.
- **Integrity test.** `tests/engine` (`kdbtest`) checks the integrity of the chains after every step (`KCheck`).

## 4. The tools

- **`servis`.** It creates areas in `$MARS_DIR`.
- **`ttc`.** It reads a schema in DDL and stores it.
- **`gen`.** It works as the original GEN: it builds a loader program (formats become procedures; `kgenrt` reads the data), passes it through `predt` and `fpc`, and runs it.
  - Job cards (`*…`) and editor labels (`? …`) are skipped.
  - Inside a block a line may start with `*`.
  - `-k` keeps the work directory.
- **`mad`.** It runs a query text: labels, `ЕСЛИ … ТО_( … _)ИНАЧЕ`, `ВЫДАТЬ`/`ВВ`. `ВЫДАТЬ` prints a line in the data format of GEN, so an unload can be fed back to `gen`.
- **`predt` and `kpc`.** They make programs (section 2).

## 5. Tests (`make test`)

| Case | What | Result |
|---|---|---|
| `engine` | `kdbtest`: order, duplicates, owner, key, `ЗАМЕНИ` of a key, DB-key, `ИСКЛЮЧ`/`ВКЛЮЧИ`, erase | `ALL OK` |
| `cd` | the example of `doc/tutorial.md`: `servis`, `ttc`, `gen`, three MAD queries, the program `cdtime` | as in the tutorial |
| `gold-ck0` | schema CX-CK0, loader deck 6, query deck 3 | 23 records, 0 errors; the unload equals the data of deck 6 |
| `gold-am0` | schema CX-AM0, loader deck 7 | 38 records, 0 errors |
| `gold-zt0` | schema CX-ЗТ0, loader deck 11, query deck 9 | 108 records, 0 errors; topics and co-executors equal the data of deck 11 |

Queries 3 and 9 return exactly what decks 6 and 11 loaded, in the data format of GEN: the original loader and the original unload query of 1988 close on each other.

The Pascal parts of the gold decks (`ПАСКАЛ "…"`, `ПРОЦЕДУРЫ`) were converted once from the dialect of 1988 to Free Pascal:
- `_(`/`_)` became `BEGIN`/`END`;
- `&` became `AND`;
- `EXIT label` became `BREAK`;
- a set stored into an integer element became `LONGINT(set)`;
- `'_377'` became `#255`.

## 6. Severov's application programs

`tests/severov/<PROG>.pas` are the 16 application programs of 1988-89 for the warehouse (`SKL*`), depreciation (`AMO*`) and cost (`ZAT*`) systems. They were converted once from the Pascal dialect of 1988 to KOMPAS Pascal, and their DML fragments are kept as they were.
- Their lost library modules (`!INCLU:X`) were rebuilt from how the programs use them, as simple stand-ins, and are inlined in each program.
- What is written in Free Pascal is in `src/sevlib.pas`:
  - `FCOPY`, `FWRITE`, `ЖУРНАЛ`, `КОНЕЦ`, `УНАР`, `COUNT`;
  - the pending output line used by `TPUT`.
- Input is one line per answer; the end of input ends the program.
- Two modules were rebuilt from their use in `ZATZAT`, `ZATNAK`, `ZATRTE` and `ZATTAB`:
  - `LIST`: parameter cards. The list and its questions come from the records `ПАР`/`ТИП`/`АТР` of deck 11.
  - `TPUT`: a table row built from the cells of the unfinished output line.
- `FCBЯ` (`SKLCAR`) was rebuilt from its two calls: it finds the link record of two owners (`СУММА` of a material and a department, `ВЗЯЛ` of an item and a `СУММА`).

All 16 build, and each has a session. The sessions `tests/severov/*.in` run on a copy of the database loaded by the original loader, and their output is compared with `*.out`. Some run on the database after the sessions that give them data (`SETUP` in `tests/run.py`): deck 11 has no costs, months or stages, and deck 7 has no devices or code groups.

| Program | Session | Result |
|---|---|---|
| `SKLMON` | administrator login with the password `СТАКАН` of deck 6, date, `КОН` | greeting, data from `SYSTEM`, common block |
| `SKLOTD` | list, add `ОТД-7`, rename it to `ОТД-8`, remove `ППО` | the department lists show each change |
| `SKLOTC` | `ИТО` - the current total of the warehouse | stock of `СПЕЦ.ОДЕЖДА` 2948 = 44.00 × 67 (curtains of deck 6) |
| `SKLCAR` | list; `НОВ` card 2020 without a price; `ЦЕН`, `ПРИ`; `РАС` to `ППО` twice and to `ЭИО`; `ОТД`; `ИСК` | the issues of each department: `ППО` 15+5=20, `ЭИО` 7 |
| `AMOMON` | administrator login, system block (password `0909` of deck 7), flag `ОТЛАД` on and off, `ЗАК`, `КОН` | menus and flags |
| `AMOCAR` | `НОВ` - device 1001 with precious metals, `ПРО` | the metals pass through the file `ДР` into the database and back |
| `AMOOTD` | after `AMOCAR`: add `ОТД-9`, add `ЭИО` again, rename to `ОТД-10`, remove `ОГИ`, remove `ОТД-10` | `ЭИО` is refused; `ОГИ` keeps its device 1001 |
| `AMOGRU` | add groups 20000-29999 and 30000-39999, remove the second | the lists show each change |
| `AMOOTC` | after `AMOCAR`, `AMOGRU`: all six reports for month 3 | device 1001: 1200 × 10% / 12 = 10 and 1200 × 5% / 12 = 5; metals 1.5 and 0.25 |
| `ZATMON`, `ZATOTD` | login, list | menu and the first department |
| `ZATCOF` | list the coefficients of deck 11; `НОВ` `ZКПРЕМ`; `ЗАМ`; `ИСК` | a bug of 1988 (`doc/open-questions.md`): the new coefficient is not in the list, and `ИСК` erases the list |
| `ZATNAK` | `НОВ` - invoices for 01.89, `ПРО` | the card is read from `SY-НАК` |
| `ZATRTE` | `НОВ` - topic 1300189: executor `ОГИ`, co-executor `ЭИО`, stages 1 and 2; `ПРО` of it and of topic 1021889 | questions by `АТР`; topic 1021889 is `НМОЭИ` with co-executors `ОМАТИ`, `ОГПС`, as in deck 11 |
| `ZATZAT` | `НОВ` - costs of topic 1300189, stage 1, 01.89, `ПРО` | the card is found through `ЭТ-ЗАТ` |
| `ZATTAB` | report for the last month | table: total salary 2300 = 2000+300, insurance 322 = 0.14×2300, cost 4542 |

`ZATTAB` prints a trace of its calculation: the 1988 source sets `PRINTCALC:=TRUE` in `INITTAB`.

## 7. Not done

- Deck 8 (MAD) is written for the subschema `CXE-AM`, which is not among the materials (the sets `ИМ-ПРИ`, `ПР-СТО` are not in CX-AM0).
- The report format `X:9:22` prints 22 decimals. What it meant in 1988 is not known.
- `servis` does not see areas made by an earlier run (its list of areas is only in memory). So `ОЧИСТИ`/`ОСВОБО`/`ВОССТА` do not work on an existing database; the database is not erased either.
- Only Linux was tested. The build uses only `fpc`, `/bin/sh` and `TProcess`, so macOS is expected to work.
