# KOMPAS DBMS

KOMPAS is a network (CODASYL) database management system, built at the Computing Centre of the USSR Academy of Sciences in the 1980s. This project re-implements it as command line tools for Linux and macOS, in Free Pascal.

The control languages stay Russian, as in the original: the schema language (DDL), the data manipulation language (DML) embedded in Pascal, the loader decks of GEN and the queries of MAD.

## Tools

| Tool | Does |
|---|---|
| `servis` | creates the database and its areas; clears them, replays the journal |
| `ttc` | loads a schema written in DDL |
| `gen` | loads data by formats |
| `mad` | queries and reports |
| `predt` | turns a Pascal program with `&&…&&` DML and Russian names into plain Free Pascal |
| `kpc` | `predt`, then `fpc`: makes a program |

A database is one file, given by `MARS_DB`: a B+tree holding named areas of records. Every DML statement is a transaction, so a crash leaves the database as after the last statement. A journal of changes can rebuild cleared areas.

## Text

All text is UTF-8: decks, queries, programs, input and output, whatever the locale. The original worked in the 8-bit GOST code, with upper case only; here data are kept exactly as written, in any alphabet and case, and ordered sets go by Unicode code points. A `char` in a KOMPAS Pascal program holds one letter of any alphabet.

Names and keywords are matched as in the original: case does not matter, and Latin and Cyrillic letters that look alike are one letter (`SY-АРТ` with a Latin or a Cyrillic `А`).

The tools write their messages in Russian, in sentence case: `Ошибка в строке 3: нет набора X`, `gen: строка 7, формат ДИСК: дубликат ключа`.

## Build and test

Free Pascal 3.2 (`fpc`) is required; the tests also need Python 3.

```sh
make          # tools into build/bin, units for programs into build/lib
make test     # tests/: tool cases and the Severov programs
export PATH=$PWD/build/bin:$PATH
```

## Layout

| Path | What |
|---|---|
| `src/` | the engine `kdb`, the tools, the runtime units (`src/rt`) |
| `tests/` | cases with expected output (`tests/run.py`), Severov's programs (`tests/severov`) |
| `doc/tutorial.md` | how to use KOMPAS: a CD collection built step by step |
| `doc/engine.md` | how the engine works, from the file up; the tools; what is tested |
| `doc/open-questions.md` | what is a guess |

See `NOTICE.md` on the third-party material in `tests/`.
