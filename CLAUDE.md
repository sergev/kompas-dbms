# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

KOMPAS is a CODASYL (network) DBMS of the 1980s (USSR Academy of Sciences), re-implemented in Free Pascal as Linux/macOS command line tools. The original engine and tools are lost; they are rebuilt from surviving 1988-89 schemas, loader decks, queries and application programs by Pavel Severov (in `tests/`). There is no reference output, so correctness means the original decks and programs agree with each other. The control languages (DDL, DML, GEN decks, MAD queries) stay Russian.

## Build and test

Needs `fpc` 3.2 and Python 3.

```sh
make                          # tools -> build/bin, units for user programs -> build/lib
make test                     # = python3 tests/run.py
python3 tests/run.py -v cd    # one case, print diff on failure
python3 tests/run.py -u NAME  # rewrite expected output (review the git diff)
python3 tests/run.py severov  # all Severov programs (build + sessions)
python3 tests/run.py SKLMON   # one Severov program
```

- A case is `tests/<case>/` with a `steps` file; each step of a case runs on one database, `build/test/<case>/kompas.db`, made fresh for the case and output is compared with `expected.txt`. Step forms: `servis|ttc|gen|mad FILE` (FILE on stdin), `prog FILE.pas [INPUT]` (via `kpc`), `native FILE.pas` (plain fpc against `kdb`).
- Severov programs (`tests/severov/*.pas`) compile and run against the database left by the matching `gold-*` case in `build/test/` (`PROGRAMS` map in `tests/run.py`), so run the gold case first or together. `SETUP` there lists sessions that must run first to create data.
- A database is one file named by `MARS_DB` (fallback `$MARS_DIR/mars.db`, then `./mars.db`; `MarsPath` in `mars.pas`). Only `servis` creates a missing file (`MarsCreate`); other tools get error 8 and make nothing. Tests run with `MARS_SYNC=0` (no fsync).

## Architecture

- `src/kdb.pas` — the engine: schema loaded from the areas `CXHD`/`CXFL`/`CXAT` (written by `ttc`), records, CODASYL set chains (owner first/last; member next/prior/owner), currency per run unit/record type/set, DML, journal. `KCheck` verifies chain integrity (used by `tests/engine/kdbtest.pas`).
- `src/rt/mars.pas` — MARS keyed storage under the engine. API: `newd`/`opend`/`cleard`/`dropd` on named areas (`opend` makes one the open area, used by the other calls), `putd`/`getd`/`modd`/`deld` of byte-keyed entries, `firstd`/`lastd`/`nextd`/`prevd` scans (the key is passed explicitly, no hidden cursor), error of the last call in `MErr` (0, 3 no entry, 8 no area/open area/database file, 9 exists). All areas share one name space; there are no BESM-6 catalogues, info words, `BDVECT`/`pasbd` microprograms or entry handles — don't bring them back. Areas are key ranges of one B+tree (`src/rt/mtree.pas`; keys `#0 name` → area id, `#1 id key` → datum, `#2` → next id) on copy-on-write pages (`src/rt/mpage.pas`: two meta pages, freelist, per-transaction `flock`); `doc/engine.md` §6a has the file layout. Every MARS call is a transaction unless `MarsBegin`/`MarsCommit` wraps several; `kdb` wraps each changing DML statement, `servis`/`ttc` a whole run, the `gen` loader every 1000 records. `tests/mars-api` pins the API; `mars-tree`/`-txn`/`-crash`/`-lock`/`engine-crash` test the store.
- Records in MARS: a DB-key is `area index << 40 | sequence` (area index = order the schema's records name areas); its tree key is 6 bytes (index + 1, then 5 bytes of sequence, big-endian); the value is the record's words. DB-key 1 is the anchor holding the next sequence number, `SYSTEM`, singular `SY-*` sets and per-record-type chains.
- `src/kutf.pas` — text is UTF-8 outside and `WideChar` inside (program chars, char fields stored as UTF-16, schema rows). Names and keywords are folded (upper case, Latin look-alikes as Cyrillic, `Ё` as `Е`); data never. MARS keys are bytes: names as UTF-8, DB-keys binary.
- `src/rt/krt.pas` — runtime for KOMPAS Pascal programs (`integer` is 64-bit, `alfa`, write formats; `RT_T` gives a name without trailing blanks, for messages).
- `src/predt.pas` — front end of "KOMPAS Pascal": Free Pascal plus Russian identifiers and `&&…&&` DML. Translates to plain FPC: `&&ПОДСХЕ X&&` generates record types/vars from the schema in `$MARS_DB` (so the database must exist at compile time); non-ASCII names map to ASCII with Latin/Cyrillic homoglyphs and case folded together; `char` becomes `WideChar`, `string[n]` `UnicodeString`, literals stay UTF-8 under `{$codepage utf8}`; write/read of char arrays go through `RT_S`/`RT_Rd`; `packed array[1..N] of char` becomes named type `ZZC<N>`; default mode `{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}` and `uses krt, kio, kdb`.
- `src/kpc` — shell script: `predt` then `fpc` against `build/lib`.
- `src/servis.pas`, `src/ttc.pas` are themselves KOMPAS Pascal: the Makefile builds them through `predt` (so `predt` and the units must build first). `servis` keeps its area descriptors in the MARS area `SERVIS`; `ОЧИСТИ` = `cleard`, `ВОССТА` = `KREPLAY` of the after-image journal that `kdb` writes in `WriteW`/`DeleteW` once `KOPEN` names a journal.
- `src/gen.pas` + `src/kgenrt.pas` — `gen` generates a loader program from a deck (formats become procedures), runs it through `predt`/`fpc`, then executes it; `-k` keeps the work dir. `servis` statements before the data run through `servis` first; `ЖУРНАЛ x СБРОСИ` among them makes the load journaled into `x`.
- `src/mad.pas` — query interpreter; `ВЫДАТЬ` prints in GEN's data format so an unload can be reloaded (gold tests check loader/unload round-trips).
- `src/sevlib.pas` — native stand-ins for the lost library used by Severov's programs.

## Docs

- `doc/engine.md` — engine/tool internals, supported DML forms, what each test proves, known gaps. Keep its test tables in sync when adding cases.
- `doc/tutorial.md` — user walkthrough; `tests/cd` is its example and must match it.
- `doc/open-questions.md` — guesses about the original (e.g. `СОСТ`/`KSTAT` status codes). Record new guesses here.
- `NOTICE.md` — provenance of third-party material in `tests/`.
