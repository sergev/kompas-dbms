# KOMPAS DBMS

KOMPAS is a network (CODASYL) database management system, built at the Computing Centre of the USSR Academy of Sciences in the 1980s. This project re-implements it as command line tools for Linux and macOS, in Free Pascal.

The control languages stay Russian, as in the original: the schema language (DDL), the data manipulation language (DML) embedded in Pascal, the loader decks of GEN and the queries of MAD.

## Tools

| Tool | Does |
|---|---|
| `servis` | creates the areas of a database |
| `ttc` | loads a schema written in DDL |
| `gen` | loads data by formats |
| `mad` | queries and reports |
| `predt` | turns a Pascal program with `&&…&&` DML and Russian names into plain Free Pascal |
| `kpc` | `predt`, then `fpc`: makes a program |

A database is a directory, given by `MARS_DIR`.

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
| `doc/tutorial.md` | how to use KOMPAS, step by step |
| `doc/engine.md` | how the engine and the tools work, and what is tested |
| `doc/open-questions.md` | what is a guess |

See `NOTICE.md` on the third-party material in `tests/`.
