# How KOMPAS works

The original KOMPAS of the 1980s is lost. Its engine and tools are written here anew in Free Pascal, following the texts of 1988-89 that survived: schemas, loader decks, queries and application programs by Pavel Severov (`tests/`). No output of the old system survived either, so the test is agreement: a loader deck of 1988 and a query of 1988 must give the same data, and the application programs must run.

Section 1 shows the parts, sections 2-4 the engine from the bottom up, section 5 the tools, sections 6-7 the tests.

## 1. The parts

```
 servis   ttc   gen   mad   your program
    \      |     |     |     /
     kdb: records, sets, current records, DML      src/kdb.pas
      |
     MARS: named areas of keyed entries            src/rt/mars.pas
      |
     B+tree: sorted keys on pages                  src/rt/mtree.pas
      |
     pages: transactions, locking                  src/rt/mpage.pas
      |
     one file, $MARS_DB
```

| File | What |
|---|---|
| `src/kdb.pas` | the engine |
| `src/rt/mars.pas`, `mtree.pas`, `mpage.pas` | the storage |
| `src/kutf.pas` | text: UTF-8 outside, 16-bit characters inside; folding of names |
| `src/predt.pas`, `src/kpc` | programs with DML: translator and compile script |
| `src/rt/krt.pas`, `kio.pas` | runtime of such programs |
| `src/servis.pas`, `ttc.pas`, `gen.pas` + `kgenrt.pas`, `mad.pas` | the tools |
| `src/sevlib.pas` | parts of the lost library of Severov's programs |

`make` puts the tools into `build/bin` and the units for programs into `build/lib`.

## 2. The file

The database is one file: `$MARS_DB`, else `$MARS_DIR/mars.db`, else `mars.db`. Only `servis` creates it.

**Pages.** The file is a row of 4 KB pages. Pages 0 and 1 are *meta pages*: they say which page is the root of the tree, where the list of free pages starts, and the number of the last commit. All other pages belong to the tree, to long values, or to the free list. Every page carries a checksum, so a page spoiled on disk is reported (`page N damaged`) instead of being read as data.

**The B+tree** is a sorted dictionary on pages: byte keys (up to 255 bytes) with byte values. Leaf pages hold keys and values in order; branch pages above them say which page holds which range of keys. Finding a key reads one page per level, three or four pages even for a large database. A value over 1 KB is stored in a chain of overflow pages.

**Areas.** KOMPAS keeps data in named *areas*. Here an area is just a range of keys in the one tree:

| Key | Value | Meaning |
|---|---|---|
| `#0` + name | area id (4 bytes) | the area exists |
| `#1` + id + key | the data | an entry of the area |
| `#2` | next free id | |

All entries of an area share the prefix `#1`+id, so they lie together in key order. Clearing an area deletes that range. An area has no fixed size; the pages of all areas are mixed in the file.

**Transactions.** A change never overwrites a page in use. Changed pages are written to free places, then the file is synced, then the *other* meta page is written with the new root and a higher commit number, and synced again. On opening, the valid meta page with the higher number wins. So if the machine stops at any moment, the file shows either the old state or the new one, never a mix. Pages left unused by a commit go to the free list and are reused, so the file stops growing when the data do.

`MARS_SYNC=0` skips the syncs: faster (the tests use it), still safe if a program is killed, but a power failure may lose the last commits. A sync costs a disk write, so bulk work goes in one transaction: a `servis` run, a `ttc` run, and every 1000 records of a `gen` load.

**Locking.** A transaction locks the whole file: shared for reading, exclusive for writing. Many tools can use one database at once; a reader that sees another process's commit drops its cached pages.

**The MARS calls** (`mars.pas`) keep the names of the original:

| Call | Does |
|---|---|
| `newd`, `opend`, `cleard`, `dropd` | create, open, empty, delete an area; the other calls work on the open area |
| `putd`, `modd`, `getd`, `deld` | add, add or replace, read, delete an entry |
| `firstd`, `lastd`, `nextd`, `prevd` | walk the entries in key order |
| `MarsBegin`, `MarsCommit`, `MarsAbort` | group calls into one transaction; otherwise each call is one |
| `MarsCheck` | read the whole file and check the tree, the chains of pages and the free list |

The error of the last call is in `MErr`: 0 ok, 3 no such entry, 8 no such area (or no file), 9 already exists.

## 3. Records and sets

**The schema.** `ttc` stores it as text rows in the areas `CXHD`, `CXFL`, `CXAT`. `kdb` reads them when a program starts and keeps, for each record type, its fields and area, and for each set, its owner, member, key, and options.

**A record** is an array of 8-byte words:

```
[type] [next, prior in the list of its type]
[first, last] for each set it owns
[next, prior, owner] for each set it belongs to
[fields...]
```

A field `ЦЕЛОЕ` is one word, `ДЕЙСТВ` one word (a double), `СИМВОЛ n` n 16-bit characters rounded up to words. Links are DB-keys; 0 means none.

**The DB-key** is the number of a record: the index of its area in the top byte, a serial number below. The tree key of a record is the area index + 1 and the serial number, so a record is found in one tree lookup. Record 1 is the *anchor*: it holds the next serial number, the DB-key of the record `SYSTEM`, and first/last of every set owned by the system and of the list of every record type.

**A set** is a doubly linked chain. Example from `tests/cd`, the set `АР-ДИС` (artist owns discs, ordered by year):

```
 Кино: first ─────────────┐           last ──────────────┐
                          v                              v
               1001 Группа крови  ── next ──>  1002 Звезда по имени Солнце
                 prior: 0          <─ prior ──    next: 0
                 owner: Кино                      owner: Кино
```

- **Storing** (`ПОСТАВ`) puts the new record into every set it is a member of, under the *current* owner of that set, unless the set is `ВКЛЮЧЕ ВРУЧНУ` (then the program uses `ВКЛЮЧИ`). In an ordered set the engine walks the chain from the first member to the first one with a greater key and links the record before it. An equal key is refused unless `ДУБЛИК РАЗРЕШ`. If one set refuses, the record is not stored at all.
- **Finding by key** (`НАЙТИ ПО-КЛЮ`) also walks the chain from the first member. There is no index: a long set means a long walk.
- **Changing a key** (`ЗАМЕНИ`) unlinks the record and links it again at its new place.
- **Erasing** (`УБРАТЬ`) unlinks the record from its sets; its own members are disconnected, not erased.
- **`ВЫБОР s ИСПОЛЬЗ R.F`** makes `ВКЛЮЧИ` choose the owner by key: the owner is the member of set `s` whose key equals `R.F`.

**Current records** are what a program "stands on". The engine keeps one for the program as a whole, one per record type, and one per set. Finding a record makes it current for the program, for its type, and for every set it belongs to or owns. So after `НАЙТИ ПО-КЛЮ 1002 В SY-ДИС` the disc is current in `АР-ДИС` and `ДИ-ТРЕ` too: `НАЙТИ ВЛАДЕЛ В АР-ДИС` goes to its artist, `НАЙТИ ПЕРВУЮ В ДИ-ТРЕ` to its first track. `НАЙТИ СЛЕДУЮ В s` moves from the current of `s` along its chain.

**Status.** Every DML statement sets `СОСТ` (`KSTAT`): 0 ok, 1 end of set, 2 not found, 3 duplicate key, 4 no current record, 5 already (not) in the set, 6 bad name, 7 storage error, 8 no schema. The numbers are a guess (`doc/guesses.md`).

**Each changing statement is one transaction** (`ПОСТАВ`, `ЗАМЕНИ`, `УБРАТЬ`, `ВКЛЮЧИ`, `ИСКЛЮЧ`): the record, its neighbours in the chains, its owners and the journal entry change together or not at all.

**The journal.** After `ЖУРНАЛ x` (`KOPEN`), every record written or erased is also logged in area `x`: under key `J` + a serial number, the area, the record's key and its new words (or "erased"). `KREPLAY(x, area)` writes these images back in order; `servis ВОССТА` uses it to rebuild an area that was cleared. Replaying twice gives the same result.

**`KCheck`** walks every chain and checks that next/prior/owner agree; the engine tests call it after every step.

## 4. Programs with DML

A program is Free Pascal with Russian names and DML between `&&` and `&&`. `predt` turns it into plain Free Pascal; `kpc` runs `predt`, then `fpc`.

- `&&ПОДСХЕ X&&` reads the schema from `$MARS_DB` and declares a variable for each record type, the status `СОСТ`, and code that copies fields between the variables and the engine. So the database must exist when a program is compiled.
- Each DML statement becomes calls of `kdb` (`KFINDKEY`, `KSTORE`, …) followed by `СОСТ := KSTAT`.
- Russian names become ASCII names. Case does not matter, and Latin and Cyrillic letters that look alike (`C`/`С`) give the same name, as on the original machine, where they were one code.
- A `char` is a 16-bit character, so one element of a char array holds one letter of any alphabet. Strings and files are UTF-8. Writing and reading char arrays goes through `RT_S`/`RT_Rd` of `krt`.
- Without its own `{$mode}` a program is compiled as Turbo Pascal, with 64-bit `integer`.

All DML forms of the 1988 texts are supported: every `НАЙТИ`, `ВЗЯТЬ`, `ПОСТАВ`, `ЗАМЕНИ`, `УБРАТЬ`, `ВКЛЮЧИ`, `ИСКЛЮЧ`, `ВЗЯТЬ`/`ЗАМЕНИ БД-КЛЮ`, `ЖУРНАЛ`, `КОМПАС`, `ЗАВЕРШ`. Not supported: `ЯЗЫК`, `@var`, `*n`, `buf;oper`, `ЗАПРОС`.

## 5. The tools

- **`servis`** creates the file and the areas, and maintains them: `ОСВОБО` (release), `ОЧИСТИ` (empty: `cleard`), `ЖУРНАЛ x СБРОСИ` (empty a journal), `ВОССТА` (replay the journals), `УБРАТЬ ОБЛАСТЬ` (delete: `dropd`). It keeps a description of each area in its own area `SERVIS`, so a later run knows them. `ДЛИНА` (a size on the old machine) is stored and ignored. The administrator is recorded in area `ADA`.
- **`ttc`** reads a schema and stores it (section 3).
- **`gen`** loads data as the original GEN did: it turns the formats of a deck into a Pascal program, compiles it with `predt` and `fpc`, and runs it on the data (`kgenrt` reads the data lines). `-k` keeps that program. The `servis` statements found before the data run first; if one of them empties a journal, the load writes to that journal, so `ВОССТА` can repeat it.
- **`mad`** runs a query: finds, labels, branches, `ВЫДАТЬ`. `ВЫДАТЬ` prints in the data format of GEN, so a query can unload data that `gen` loads back.

**Messages** are Russian in sentence case (the original had upper case only). A message about the input starts with the tool and the line: `gen: строка 7, формат ДИСК: дубликат ключа`. Other lines start with a capital: `Ошибка в строке 3: нет набора X`, `Область ДА-ДИС очищена`. Names and keywords keep their form. `servis`, `ttc` and `gen` end with `Ошибок: N`.

## 6. Tests

`make test` runs every case of `tests/`. A case is a list of steps on a fresh database, and its output must equal `expected.txt`.

| Case | Shows |
|---|---|
| `engine` | sets: order, duplicates, owners, key change, DB-keys, connect, disconnect, erase; `KCheck` after each step |
| `cd` | the example of `doc/tutorial.md` |
| `gold-ck0` | the 1988 warehouse: loader deck 6, then query deck 3 prints exactly the loaded data; after `ОЧИСТИ` it is empty, after `ВОССТА` the same again |
| `gold-am0` | the 1988 depreciation system: loader deck 7 |
| `gold-zt0` | the 1988 cost system: loader deck 11, and query deck 9 prints its data back |
| `servis-maint` | a second `servis` run, journaled changes, clearing, replay twice; the data after replay equal the data before |
| `utf8` | data in many alphabets and cases; names typed with Latin look-alikes |
| `mars-api` | every MARS call and error |
| `mars-tree` | 135 000 random operations on the tree, compared with a simple sorted list |
| `mars-txn`, `mars-lock` | nested and aborted transactions; several processes writing and reading at once |
| `mars-crash`, `engine-crash` | a commit killed at every write: always the old or the new state, chains sound |

The decks were typed in from texts in the old code, where Latin `A` and Cyrillic `А` were one letter, and mix the two at random. Their data were folded once into one form (Cyrillic, upper case), as the old system saw them. Their Pascal parts were converted once to Free Pascal (`_(` `_)` → `BEGIN` `END`, `&` → `AND`, and so on).

Two things the decks need, beyond the obvious:
- `ВЫБОР ТЕ-ИСП ИСПОЛЬЗ ЦЕЛ.ЗН` (deck 10) must choose the owner by key; otherwise the co-executors of deck 11 do not get into `ИС-ИСП`, and deck 9 does not print them.
- A Pascal set stored into an element `ЦЕЛОЕ` is kept as 32 bits (`ЗАМЕНИ ЦЕЛ.ЗН НА ФЛАГИ` in deck 11, `SYSTEM.РЕЖИМЫ:=ФЛАГИ` in deck 6).

## 7. Severov's programs

`tests/severov` holds 16 application programs of 1988-89: warehouse (`SKL*`), depreciation (`AMO*`), costs (`ZAT*`). They were converted once to KOMPAS Pascal, with their DML unchanged. Their lost library modules were rebuilt from how the programs call them; most are inlined in the programs, the rest is `src/sevlib.pas`.

Each program runs a session: answers from `<PROG>.in` against the database of its `gold-*` case, output compared with `<PROG>.out`. Some sessions first need data made by others (`SETUP` in `tests/run.py`). `python3 tests/run.py severov` runs them all.

Notes for reading their output:
- `write` without a width uses the formats of 1988: integer in 10 columns, real in 14 (`    1.4000Е-01`), boolean in 8, an enumeration as its name in 8 (`RT_W`, `RT_EnW` in `krt`). New programs use the formats of Free Pascal.
- Two bugs of 1988 show. `ZATTAB` changes the record `ДЕЙ` without assigning it the value of the parameter, so the coefficients `ZKПРОЧ`, `ZKНАКЛ`, `ZKЗАРН` stay 0.0. `ZATCOF` stores a new coefficient without its name, so it is listed blank, and `ИСК` then erases the list itself.
- `ZATTAB` prints a trace of its calculation: its source sets `PRINTCALC:=TRUE`.
- `SKLCAR` checks a unit of measure by writing it to `OUT` and reading it back; it goes through a scratch file (`FCOPY`), as `ШАПКА` of `SKLOTC` does.
- The guesses behind the rebuilt library modules are in `doc/guesses.md`.

## 8. Not done

- Query deck 8 needs the subschema `CXE-AM`, which did not survive.
- The write format `X:9:22` prints 22 decimals; what it meant in 1988 is not known.
- `КОНСИМ` of a text element is taken as a plain string; its meaning is not known.
- A `gen` load that does not empty a journal is not journaled, so `ВОССТА` cannot repeat it.
- Only Linux was tested; macOS should work (the build needs only `fpc` and `/bin/sh`).
