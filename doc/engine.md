# The KOMPAS engine and tools

KOMPAS is a CODASYL (network) DBMS. The original sources of the engine and of its tools GEN, MAD and PREDT are lost. They are written here anew in Free Pascal. The language descriptions they follow are the original texts of 1988-89 by Pavel Severov: schemas, loader decks, queries and application programs (see `tests/`).

No historical outputs survive. So the check is consistency and review by hand, not comparison with a reference: a loader of 1988 and a query of 1988 must agree with each other, and the application programs must run their sessions.

## 1. Layout

| File | What |
|---|---|
| `src/kdb.pas` | the engine: schema, records, sets, currency, DML |
| `src/kutf.pas` | text: UTF-8 outside, WideChar inside; folding of names |
| `src/rt/mars.pas` | MARS: keyed storage of areas, all in one file `$MARS_DB` |
| `src/rt/mtree.pas` | the B+tree under MARS: byte keys, cursors, structural check |
| `src/rt/mpage.pas` | pages of `mars.db`: copy-on-write transactions, freelist, locking |
| `src/rt/krt.pas` | runtime of KOMPAS Pascal programs: `integer` = 64 bits, `alfa`, write formats |
| `src/rt/kio.pas` | standard output of KOMPAS Pascal programs past its buffer (`sevlib`) |
| `src/servis.pas` | `servis`: areas, journals |
| `src/ttc.pas` | `ttc`: the schema (DDL) into the areas `CXHD`/`CXFL`/`CXAT` |
| `src/gen.pas`, `src/kgenrt.pas` | `gen`: the loader generator and the runtime of its loaders |
| `src/mad.pas` | `mad`: the query language |
| `src/predt.pas` | `predt`: the front end of KOMPAS Pascal |
| `src/kpc` | `predt` + `fpc` in one command |
| `src/sevlib.pas` | native parts of the lost library of the Severov programs |

`make` builds the tools into `build/bin` and the units for user programs into `build/lib`.

## 2. KOMPAS Pascal

Programs with DML are Free Pascal with two additions: Russian identifiers, and DML statements between `&&` and `&&`. `predt` turns such a program into plain Free Pascal:

- `&&ПОДСХЕ X&&` declares the records of the schema in `$MARS_DB`: types `ZZ<record>`, variables named as the records, `ZZBDKEY`, `СОСТ`, and procedures that move fields between the variables and the engine.
- Every statement fragment becomes `begin … СОСТ:=KSTAT end` with its own `;` (except before `ELSE`). `НАБ s` and `ЗП r` become the numbers of a set and of a record.
- Names with non-ASCII letters become ASCII names. Latin and Cyrillic homoglyphs give the same name (`С` and `C`), and so do lower and upper case: Cyrillic look-alikes become Latin letters, other letters `Q<hex code>_` (`ФЛАГ` is `Q0424_Q041B_AQ0413_`).
- A `char` is a `WideChar`: one element of `alfa` or of a char array is one letter, whatever the alphabet. `chr` becomes `WideChar`, `string[n]` becomes `UnicodeString`.
- String literals stay as written; the program is compiled with `{$codepage utf8}`. Text files, standard input and output are UTF-8 (`kutf`).
- FPC cannot write or read an array of `WideChar`. An argument of `write`/`writeln` that is a char array becomes `RT_S(…)`, and a `read`/`readln` with one reads it with `RT_Rd`. Char arrays are found by the names declared with such types; `RT_S` passes numbers through unchanged.
- Each `packed array[1..N] of char` becomes one named type `ZZC<N>` (`alfa` for 6). In Turbo Pascal mode two arrays of the same shape are otherwise incompatible.
- Without `{$mode}` the program gets `{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}`, and it uses `krt`, `kio`, `kdb` (added to its own `uses` clause if it has one).

DML forms supported (all those of the 1988 decks):

- `НАЙТИ` of every kind, with the key from a literal, a variable or a field;
- `ВЗЯТЬ [rec][.fld] [НА x]`, `ВЗЯТЬ`/`ЗАМЕНИ БД-КЛЮ`;
- `ПОСТАВ[ИТЬ]`, `ВКЛЮЧИ`, `ИСКЛЮЧ[И]`, `УБРАТЬ`, `ЗАМЕНИ[ТЬ] [rec][.fld НА v]`;
- `ЖУРНАЛ`, `КОМПАС`, `ЗАВЕРШ`.

Not supported: `ЯЗЫК`, `@var`, `*n`, `buf;oper`, `ЗАПРОС`.

## 3. The engine

- **Schema.** It is read from the areas `CXHD`/`CXFL`/`CXAT`, where `ttc` writes it: records `NUM`, `Tnnn`, `Rnnn`, `Frrrff`, `Snnn`, `Asssaa`. What is kept:
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
- **Journal.** Once a program or query names it (`ЖУРНАЛ`, `KOPEN`), every record written or erased is logged there as an after-image: area, MARS key, new words (or erased), under key `J` + sequence, in the same transaction as the change. The sequence goes on from the last entry, across runs. `KREPLAY(journal, area)` applies the images of one area in order; `servis` `ВОССТА` uses it. Replaying is idempotent.
- **Transactions.** Each changing statement (`ПОСТАВ`, `ЗАМЕНИ`, `УБРАТЬ`, `ВКЛЮЧИ`, `ИСКЛЮЧ`, erasing the members of an occurrence) is one MARS transaction: after a crash the record, its owners, its neighbours in the chains and the journal entry are all changed or none.
- **Status.** `СОСТ` (`KSTAT`) codes are a hypothesis (`doc/open-questions.md`):
  - 0 ok, 1 end of set, 2 not found, 3 duplicate key;
  - 4 no current record, 5 membership error, 6 bad name, 7 storage error, 8 no schema.
- **Integrity test.** `tests/engine` (`kdbtest`) checks the integrity of the chains after every step (`KCheck`).

## 4. The tools

- **`servis`.** It creates areas in `$MARS_DB`, and the file if it is missing; the other tools do not create it (`MarsCreate`). A run is one transaction. The descriptions of its areas are kept in the MARS area `SERVIS` (`#NCNT`, `#NMS`, one record per area), so every run knows the areas of the earlier ones.
  - `ОСВОБО` releases an area (the flag that `УБРАТЬ ОБЛАСТЬ` and `ЖУРНАЛ … ЗАКРЕПИ` require).
  - `ОЧИСТИ` erases the data of an area (`cleard`); `ЖУРНАЛ … СБРОСИ` empties the journal.
  - `ВОССТА` replays the journals (areas `ВИД ЖУРНАЛ`) into the areas named.
  - `УБРАТЬ ОБЛАСТЬ` deletes the MARS area too (`dropd`).
- **`ttc`.** It reads a schema in DDL and stores it. A run is one transaction.
- **`gen`.** It works as the original GEN: it builds a loader program (formats become procedures; `kgenrt` reads the data), passes it through `predt` and `fpc`, and runs it.
  - Job cards (`*…`) and editor labels (`? …`) are skipped.
  - Inside a block a line may start with `*`.
  - `-k` keeps the work directory.
  - The loader commits every 1000 data records and at the end: after a crash, a load is kept up to its last commit.
  - `servis` statements before the data (`ОСВОБО`, `ОЧИСТИ`, `ЖУРНАЛ`, `ВОССТА`; in the 1988 decks a job step between `*С` and `*CALL` the loader) are run by `servis` before the loader. Later ones are reported as skipped.
  - If the deck resets a journal (`ЖУРНАЛ x СБРОСИ`), the loader writes that journal (`&&ЖУРНАЛ x&&`), so the load can be replayed by `ВОССТА`. Other loads are not journaled.
- **`mad`.** It runs a query text: labels, `ЕСЛИ … ТО_( … _)ИНАЧЕ`, `ВЫДАТЬ`/`ВВ`. `ВЫДАТЬ` prints a line in the data format of GEN, so an unload can be fed back to `gen`.
- **`predt` and `kpc`.** They make programs (section 2).

## 5. Tests (`make test`)

| Case | What | Result |
|---|---|---|
| `engine` | `kdbtest`: order, duplicates, owner, key, `ЗАМЕНИ` of a key, DB-key, `ИСКЛЮЧ`/`ВКЛЮЧИ`, erase | `ALL OK` |
| `cd` | the example of `doc/tutorial.md`: `servis`, `ttc`, `gen`, three MAD queries, the program `cdtime` | as in the tutorial |
| `gold-ck0` | schema CX-CK0, loader deck 6 (its `servis` statements run, the load journaled), query deck 3; then `ОСВОБО`/`ОЧИСТИ` of the data areas, query 3, `ВОССТА`, query 3 | 23 records, 0 errors; the unload equals the data of deck 6; empty after `ОЧИСТИ`; after `ВОССТА` equal to the first again |
| `gold-am0` | schema CX-AM0, loader deck 7 | 38 records, 0 errors |
| `gold-zt0` | schema CX-ЗТ0, loader deck 11, query deck 9 | 108 records, 0 errors; topics and co-executors equal the data of deck 11 |
| `mars-api` | every MARS call: areas, entries, scans in both directions, error codes, clear and drop; a second process sees the same; without a database file every call fails and none makes it | as recorded |
| `mars-tree` | the B+tree against a sorted-array model: 135 000 random puts, deletes, gets and seeks; sequential, reverse, random, long-prefix and 255-byte keys; values up to 6 KB (overflow pages); emptying the tree; repeated fill and empty | `TCheck` sound after every 20 commits; the file stops growing |
| `mars-txn` | nesting, abort, empty transactions, writes refused in a read transaction, a reader waiting for a writer and the other way, another process's commit, reopen | as expected |
| `mars-crash` | a commit killed before each of its writes and syncs, or with each page write torn in half, with fsync on and off; a damaged newest meta page, root page, both meta pages | always exactly the old or the new state; damage reported |
| `mars-lock` | 4 writer and 2 reader processes on one file | no update lost, no reader sees a half transaction |
| `engine-crash` | six DML statements killed at each write of their commit | `KCheck` sound; the old or the new data |
| `servis-maint` | a second `servis` run knows the areas; journaled stores, key change, move, erase; `ОСВОБО`/`ОЧИСТИ` empty the areas; `ВОССТА` (twice) rebuilds them; `УБРАТЬ ОБЛАСТЬ` needs `ОСВОБО`, no journal → error 70 | the dump after `ВОССТА` equals the dump after the load (MD5), `KCheck` sound |
| `utf8` | lower case, `Ё`, Latin, German, Greek data through `gen`, `mad` and a program; names written with Latin look-alikes | data as written, sets in code order, exact keys |

The decks and the Severov programs are transcriptions of 1988 texts in the GOST code, where Latin `A` and Cyrillic `А` were one letter. The transcriptions mix the two alphabets at random. Since data are now kept as written, their data and string literals were folded once into one form (Cyrillic look-alikes, upper case), the form the old system saw.

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

## 6a. MARS storage

The original MARS is lost; this one keeps the names of its calls (`newd`, `opend`, `putd`, `getd`, `modd`, `deld`, `cleard`, `dropd`), with `firstd`, `lastd`, `nextd`, `prevd` for scans and `MErr` for the error of the last call. There are no catalogues, info words, `BDVECT` microprograms or entry handles of the BESM-6 MARS. It is built on a design like LMDB, cut down.

### The file

A database is one file: `$MARS_DB`, without it `$MARS_DIR/mars.db` (the name of earlier versions), else `mars.db`. It is a sequence of 4 KB pages; page N starts at byte N × 4096. Integers in pages are in the byte order of the machine (little-endian on x86-64 and ARM64); keys are compared as bytes.

Every page starts with a header of 20 bytes:

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | CRC-32 of bytes 4…4095 |
| 4 | 2 | type: 1 meta, 2 branch, 3 leaf, 4 overflow, 5 freelist |
| 6 | 2 | count: cells, bytes or page numbers, by type |
| 8 | 4 | the page's own number |
| 12 | 4 | next: the leftmost child (branch) or the next page of a chain (overflow, freelist) |
| 16 | 4 | spare |

- **Pages 0 and 1** are the meta pages: after the header, magic `KMARS1`, format version, page size, `txnid` (8 bytes), the root page of the tree, the first freelist page, the number of pages in the file. Commits write them in turn; the valid one with the higher `txnid` is current.
- **Branch and leaf pages** hold the B+tree (`mtree.pas`). After the header come 2-byte offsets of the cells in key order; the cells are packed from the end of the page. A leaf cell is key length (1 byte), flag (1 byte), value length (4 bytes), key, then the value, or the first overflow page when the flag is 1. A branch cell is key length, child page, key: the child holds the keys from this key up to the next cell's.
- **Overflow pages** hold a value longer than 1024 bytes, as a chain.
- **Freelist pages** list free page numbers (4 bytes each), as a chain.

Where a page lies in the file says nothing: copy-on-write gives every changed page a new number, and freed pages are reused. The pages of all areas are mixed.

### The tree

Keys are at most 255 bytes. The first byte says what a key is:

| Key | Value | |
|---|---|---|
| `#0` name | area id: 4 bytes, big-endian | an area (`newd`) |
| `#1` id key | the datum | an entry of area id |
| `#2` | the next area id: 4 bytes, big-endian | |

The id is big-endian, so the entries of an area are one run of keys in key order. `cleard` deletes that run, `dropd` also the `#0` key, and `firstd` … `prevd` walk it. An area has no size: `ДЛИНА` of `servis` is only kept in the area's descriptor. As all areas are in one tree, one transaction can change several of them.

### A KOMPAS database

| Area | Written by | Entries |
|---|---|---|
| `ADA` | `servis` | `ADMIN`: the administrator |
| `SERVIS` | `servis` | `#NCNT` (count of areas, last code), `#NMS` (their names), one descriptor (11 words) per area |
| `CXHD`, `CXFL`, `CXAT` | `ttc` | the schema: `NUM`, `Tnnn`, `Rnnn`, `Snnn`; `Frrrff`; `Asssaa`. Each is 48 characters |
| data areas (`ОБЛАСТЬ` of `servis`, named by the records of the schema) | `kdb` | records |
| journal areas (`ВИД ЖУРНАЛ`) | `kdb` | after-images |

- **Records.** A DB-key is `area index × 2⁴⁰ + sequence number`. The area index is the order in which the records of the schema first name the areas (from 0); a record without an area goes to the first one. The sequence number comes from one counter for the whole database. In the tree, a record's key is 6 bytes: area index + 1, then the sequence number in 5 bytes, big-endian; its value is the record's words (8 bytes each): type, next and prior in the chain of its type, first and last of each set it owns, next, prior and owner of each set it is a member of, then the fields (`СИМВОЛ n` as n UTF-16 characters, padded to words).
- **The anchor** is DB-key 1, in area 0: the next sequence number, the DB-key of the record `SYSTEM`, first and last of every singular set and of the chain of every record type.
- **Journal entries.** Key `J` + sequence number (5 bytes, big-endian), so key order is the order of writing. Value: `W` (written) or `D` (erased), length and name of the area (UTF-8), length and bytes of the tree key of the record, datum length (4 bytes), datum.

### Transactions and checks

- **Copy-on-write.** A transaction never writes over a page the last commit can reach; changed pages get new numbers. Commit: write the pages, `fsync`, write the other of the two meta pages (`txnid`, root, freelist), `fsync`. The valid meta page with the higher `txnid` is current, so a crash at any point leaves the last commit. Every page has a CRC: a damaged page is reported (`page N damaged`), never used.
- **Freelist.** Pages freed by a commit are reused by the next transactions, so the file stops growing when the data stop growing.
- **Locking.** `flock` on the file, per transaction: shared for reading, exclusive for writing. Readers and the writer exclude each other, so freed pages can be reused at once; a reader re-reads the meta pages and drops its cache when another process has committed.
- **Transactions.** Each MARS call is one, unless `MarsBegin` … `MarsCommit` (or `MarsAbort`) opens a longer one; nested ones join the outermost. `MARS_SYNC=0` leaves out the `fsync`s: a killed process still loses nothing committed, a power failure may lose the last commits. The tests run so.
- **Check.** `MarsCheck` (`TCheck`) reads the whole file and checks key order, separators, fill, leaf depth, overflow lengths, and that every page is used exactly once (tree, overflow, freelist).

Timing (`tests/bench/marsbench.pas`, 8-byte keys, 80-byte data, `MARS_SYNC=0`):

| | old MARS | new MARS |
|---|---|---|
| 5 000 `putd` | 34 s | 0.18 s |
| 100 000 `putd`, a transaction each | — | 4.2 s |
| 100 000 `putd` in one transaction | — | 0.30 s |
| 100 000 random `getd` | — | 0.20 s |
| scan of 100 000 (`nextd`) | — | 0.17 s |

With `fsync`, a commit costs what the disk takes for two `fsync`s (60 ms on the machine of these numbers), so batch work belongs in one transaction: `servis`, `ttc` and the `gen` loader do so.

## 7. Not done

- Deck 8 (MAD) is written for the subschema `CXE-AM`, which is not among the materials (the sets `ИМ-ПРИ`, `ПР-СТО` are not in CX-AM0).
- The report format `X:9:22` prints 22 decimals. What it meant in 1988 is not known.
- A `gen` load from a deck that does not reset a journal (an addition to a database) is not journaled, so `ВОССТА` cannot restore it.
- Only Linux was tested. The build uses only `fpc`, `/bin/sh` and `TProcess`, so macOS is expected to work.
