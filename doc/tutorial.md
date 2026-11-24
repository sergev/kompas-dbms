# KOMPAS: a tutorial

## 1. What it is

KOMPAS is a database management system (DBMS). It was built at the Computing Centre of the USSR Academy of Sciences in the 1980s. This is a re-implementation of it as command line tools for Linux and macOS.

A DBMS stores information and finds it on request. Example: a warehouse. There are departments, materials, and issues of materials to departments. You want to know what is in stock, who took what, and for how much.

KOMPAS is a network DBMS (the CODASYL model). Data are records linked into chains called sets. From a record you can move to the records linked to it.

The language of KOMPAS is Russian: commands, keywords and names are Russian words. Examples below keep them as they are, with an English explanation.

## 2. Basic notions

| Notion | Meaning | Warehouse example |
|---|---|---|
| Record | one card of data | the material "nails" |
| Record type | a kind of card | `ВЕЩЬ` (item), `ОТДЕЛ` (department), `МАТЕР` (material group) |
| Element | a field of a card | `НАЗВ` (name), `ЦЕНА` (price), `ОСТАТ` (in stock) |
| Set | an owner - members link | a department owns its issues |
| Key | the value you search by | item number |
| Schema | description of all record types and sets | schema `CX-CK0` of the warehouse |
| Area | a place on disk for data | `ДА-CK0`, warehouse data |
| Journal | a log of changes, for recovery | `ЖУ-CK0` |
| DB-key | internal address of a record | a number such as `3072` |

The set is the central idea. Set `SY-ОТД` holds all departments in alphabetic order. Set `ОТ-СУМ` links a department with its amounts. A set is ordered by a key, so you can walk it forward and backward.

## 3. How it is organized

```
   your program            MAD query
         |                     |
   DML (commands to find and change data)
         |
       KOMPAS (schema, sets, current records)
         |
       MARS (stores records by key)
         |
   files on disk
```

Tools:

| Tool | Purpose |
|---|---|
| SERVIS | create, clear, release areas; journals; recovery |
| TTC | load a schema written in the data description language (DDL) |
| GEN | load data by formats |
| MAD | query the database without programming |
| DML in Pascal | your own Free Pascal programs that read and change the database |

## 4. How to run

Every tool is a command line program. It reads statements from standard input and prints results to standard output.

| Command | Input | Does |
|---|---|---|
| `servis` | SERVIS statements | creates, clears, releases areas; journals; recovery |
| `ttc` | a schema in DDL | loads the schema into the database |
| `gen` | formats and data | loads data |
| `mad` | a MAD query | queries and reports |
| `predt` | Pascal with `&&...&&` DML | turns it into plain Free Pascal |
| `kpc` | Pascal with `&&...&&` DML | `predt`, then `fpc`: makes a program |

Free Pascal (`fpc`) must be installed. Build the tools once and put them on your `PATH`:

```sh
make
export PATH=$PWD/build/bin:$PATH
```

The database is a directory, given by `MARS_DIR`. Each area is a file inside it. All tools work on the same database:

```sh
export MARS_DIR=~/store/db
mkdir -p $MARS_DIR
servis < areas.srv
```

To back up a database, copy the directory.

The examples of sections 5 and 6 are in `tests/` (`gold-ck0`, `cd`), with their output; `make test` runs them all.

## 5. Step by step: a warehouse database

The example comes from a real accounting system of 1988-89 by Pavel Severov (`tests/gold-ck0`).

### Step 1. Allocate areas (SERVIS)

A database needs room: an area for the schema, for the journal, for indexes, for data. Put the statements in a file `areas.srv` and run `servis < areas.srv`.

```
ОБЛАСТЬ CХ-CK0:ДЛИНА 2 ВАРИАНТ SSCXEM,
ОБЛАСТЬ ЖУ-CK0:ДЛИНА 6 ВИД ЖУРНАЛ,
ОБЛАСТЬ ИН-CK0:ДЛИНА 14 РЕЖИМ 0,
ОБЛАСТЬ ДА-CK0:ДЛИНА 14 РЕЖИМ 0;
КОНЕЦ.
```

- `ОБЛАСТЬ` - area; `ДЛИНА` - size in zones.
- `ВАРИАНТ SSCXEM` - an area for the schema.
- `ВИД ЖУРНАЛ` - a journal.
- `КОНЕЦ.` - end.

SERVIS answers with a line per area, for example `NEW AREA N = 1`.

### Step 2. Describe the schema (TTC)

The schema says which records exist and how they are linked. Put it in `store.ddl` and run `ttc < store.ddl`.

```
ЗАМЕНИ СХЕМА CX-CK0:РЕЖИМ 0;
ОБЛАСТЬ ДА-CK0;

ТИП СТРОКА СИМВОЛ 84;

ЗАПИСЬ ОТДЕЛ:
       ЭЛ НАЗВ  СИМВОЛ 6;

ЗАПИСЬ ВЕЩЬ:
       ЭЛ НАЗВ  СТРОКА КОНСИМ,
       ЭЛ НОМЕР ЦЕЛОЕ,
       ЭЛ ЕД    СИМВОЛ 6,
       ЭЛ ЦЕНА  ДЕЙСТВ РАЗМЕР 99900,
       ЭЛ ОСТАТ ДЕЙСТВ РАЗМЕР 99999000;

НАБОР SY-ОТД:
       ЧЛЕН ОТДЕЛ, ПРИВЯЗ ИН-CK0,
       УПОРЯД ПО-ЭЛЕ НАЗВ;

НАБОР SY-ВЕЩ:
       ЧЛЕН ВЕЩЬ, ПРИВЯЗ ИН-CK0,
       УПОРЯД ПО-ЭЛЕ НОМЕР;

КОНЕЦ.
```

How to read it:

- `ЗАПИСЬ ВЕЩЬ` - record type "item" with five elements (`ЭЛ`): name, number, unit, price, stock.
- Element types: `СИМВОЛ 6` - 6 characters, `ЦЕЛОЕ` - integer, `ДЕЙСТВ` - real; `ТИП` defines your own type.
- `НАБОР SY-ВЕЩ` - set of all items; `ЧЛЕН` - member record; `УПОРЯД ПО-ЭЛЕ НОМЕР` - ordered by number.
- A set with no owner (`ВЛАДЕЛ`) belongs to the system: it is an entry point into the database.
- `НАБОР ВЕ-ВЗЯ: ВЛАДЕЛ ВЕЩЬ, ЧЛЕН ВЗЯЛ` would link an item (owner) with its issues (members).

TTC prints the parsed schema: types, records, sets.

### Step 3. Load data (GEN)

Formats and data go into one file, `load.gen`; run `gen < load.gen`. First a format: which fields are in a data line and what to do with them.

```
ФОРМАТ ОТДЕЛ
  ОТДЕЛ.НАЗВ*
  ПАСКАЛ "&&ПОСТАВ ОТДЕЛ&&"
```

Then the data, one record between `[` and `*`:

```
ОТДЕЛ [ ОТД-1*
        ОТД-2*
        СКЛАД*]
```

`ПОСТАВ` (store) writes a new record into the database. `_` separates fields, `*` ends a record.

### Step 4. Query the database (MAD)

MAD is a query language. Put the query in a file and run `mad < report.mad`. Example: print all departments, then all items.

```
РЕЖИМ 2;ЖУРНАЛ ЖУ-CK0;ПОДСХЕ CX-CK0;

НАЙТИ ПЕРВУЮ В SY-ОТД;
Б:ВЗЯТЬ;ВЫДАТЬ .НАЗВ,'*';НАЙТИ СЛЕДУЮ;ЕСЛИ СОС=0 ТО НА Б;

НАЙТИ ПЕРВУЮ В SY-ВЕЩ;
А:ВЗЯТЬ;
  ВЫДАТЬ .НОМЕР,'_',.ЕД,'_',.ЦЕНА,'_',.ОСТАТ;
  НАЙТИ СЛЕДУЮ В SY-ВЕЩ;ЕСЛИ СОС=0 ТО НА А;
СБРОСИ;ЗАВЕРШ;КОНЕЦ
```

How to read it:

- `НАЙТИ ПЕРВУЮ В SY-ОТД` - find the first department.
- `ВЗЯТЬ` - get (read) the record.
- `ВЫДАТЬ .НАЗВ` - print the field.
- `НАЙТИ СЛЕДУЮ` - find the next one.
- `СОС` - status: `0` means found, otherwise the set has ended.
- `ЕСЛИ СОС=0 ТО НА Б` - if found, go to label `Б` again.
- `СБРОСИ;ЗАВЕРШ` - finish the work with the database.

More MAD commands:

| Command | Meaning |
|---|---|
| `НАЙТИ ПО-КЛЮ 'АС0001' В SY-ТЕМ` | find a record by key |
| `НАЙТИ ПРЕДЫД`, `НАЙТИ ПОСЛЕД` | previous record, last record |
| `НАЙТИ ВЛАДЕЛ В ВЕ-ВЗЯ` | go to the owner in a set |
| `ВЗЯТЬ БД-КЛЮ`, `ЗАМЕНИ БД-КЛЮ` | read or change the DB-key |

### Step 5. Your own program (DML in Pascal)

DML commands are written right inside a Free Pascal program, between `&&` and `&&`. Names in the program may be Russian, like the names of the schema; `predt` turns them into ASCII names, string literals into the internal code of KOMPAS, and the DML into calls of the engine. Without a `{$mode}` directive the program is compiled in Turbo Pascal mode, with 64-bit `INTEGER`:

```
&&НАЙТИ ПО-КЛЮ В SY-ОТД&&
WHILE (COCT=0) AND NOT НАШЛИ DO BEGIN
  &&ВЗЯТЬ&&
  IF НАЗВ=НН THEN НАШЛИ:=TRUE;
  &&НАЙТИ СЛЕДУЮ В SY-ОТД&&
END;
```

Main DML commands (the number is the KOMPAS operation code):

| Code | Command | Meaning |
|---|---|---|
| 01 | `ПОСТАВ` | store a new record |
| 02 | `НАЙТИ ПО-КЛЮ` | find by key |
| 04 | `НАЙТИ ПЕРВУЮ` | first in a set |
| 05 | `НАЙТИ ВЛАДЕЛ` | owner in a set |
| 06 | `ВКЛЮЧИ` | connect a record into a set |
| 07 | `УБРАТЬ` | erase a record |
| 08 | `ИСКЛЮЧИ` | disconnect from a set |
| 11 | `НАЙТИ ПОСЛЕД` | last in a set |
| 12 | `НАЙТИ СЛЕДУЮ` | next |
| 13 | `НАЙТИ ПРЕДЫД` | previous |
| 15 | `ЗАМЕНИ` | modify a record |
| 16 | `ВЗЯТЬ` | get a record |

After each command check the status `СОСТ`: `0` means success. Section 6, step 5, shows how to build and run such a program.

### Step 6. Maintenance (SERVIS)

These statements are also fed to `servis`.

| Statement | Meaning |
|---|---|
| `ОЧИСТИ ДА-CK0;` | clear the data of an area, keep the space |
| `ОСВОБО ДА-CK0;` | release the space of an area |
| `ЖУРНАЛ ЖУ-CK0 СБРОСИ.` | restart a journal |
| `ВОССТА ИНД-CK,ДАН-CK;` | restore areas from the journal |

In the 1988 decks these statements stand before the data of a GEN deck, to clear the areas before a reload; `gen` skips them. Here they work only on areas made in the same `servis` run; see section 6, step 6.

## 6. Example: a CD collection

Here we build a new database from scratch: a home collection of music CDs. We keep artists, their discs, and the tracks of each disc. All files of this example are in `tests/cd/`.

Make a working directory and point `MARS_DIR` at it:

```sh
mkdir -p ~/cd && cd ~/cd
export MARS_DIR=~/cd/db
```

Every step is one input file and one command.

### The design

Three record types:

| Record | Elements |
|---|---|
| `АРТИСТ` (artist) | `ИМЯ` name, `СТРАНА` country |
| `ДИСК` (disc) | `НОМЕР` catalogue number, `НАЗВ` title, `ГОД` year, `ЦЕНА` price |
| `ТРЕК` (track) | `НОМЕР` track number, `НАЗВ` title, `ДЛИТ` length in seconds |

Four sets:

| Set | Owner | Member | Order | Used for |
|---|---|---|---|---|
| `SY-АРТ` | system | `АРТИСТ` | by name | list of all artists |
| `SY-ДИС` | system | `ДИСК` | by number | list of discs, find a disc by number |
| `АР-ДИС` | `АРТИСТ` | `ДИСК` | by year | the discs of an artist |
| `ДИ-ТРЕ` | `ДИСК` | `ТРЕК` | by number | the tracks of a disc |

```
SY-АРТ ──> АРТИСТ ──АР-ДИС──> ДИСК ──ДИ-ТРЕ──> ТРЕК
                                ^
SY-ДИС ─────────────────────────┘
```

Four areas: `СХ-ДИС` (schema), `ЖУ-ДИС` (journal), `ИН-ДИС` (indexes), `ДА-ДИС` (data). The records go into the area named by `ОБЛАСТЬ` in the schema.

Names of records, elements and areas have at most 6 characters. A set name has the form `XX-XXX`.

### Step 1. Allocate areas

File `areas.srv`:

```
ОБЛАСТЬ СХ-ДИС:ДЛИНА 2 ВАРИАНТ SSCXEM,
ОБЛАСТЬ ЖУ-ДИС:ДЛИНА 4 ВИД ЖУРНАЛ,
ОБЛАСТЬ ИН-ДИС:ДЛИНА 4 РЕЖИМ 0,
ОБЛАСТЬ ДА-ДИС:ДЛИНА 8 РЕЖИМ 0;
КОНЕЦ.
```

`ДЛИНА` is the size in zones of 1024 words.

```sh
servis < areas.srv
```

Output:

```
SЕRVIS РRОСЕSSОR 15.1
АDМIN: ПОЛЬЗОВАТЕЛЬ АDМIN ЗАРЕГИСТРИРОВАН
NЕW АRЕА N =          1 INFО=    618561
NЕW АRЕА N =          2 INFО=   1142913
NЕW АRЕА N =          3 INFО=   1142977
NЕW АRЕА N =          4 INFО=   2191617
ЕХN=         0
```

One line per area; `ЕХN= 0` means no errors. Latin and Cyrillic letters that look alike are one letter for KOMPAS, so the output mixes them.

### Step 2. Describe the schema

File `cd.ddl`:

```
ЗАМЕНИ СХЕМА СХ-ДИС:РЕЖИМ 0;
ОБЛАСТЬ ДА-ДИС;

ТИП СТРОКА СИМВОЛ 40;
ТИП СЕКУНД ЦЕЛОЕ РАЗМЕР 9999;

ЗАПИСЬ АРТИСТ:            ?*ИСПОЛНИТЕЛЬ*
       ЭЛ ИМЯ    СТРОКА КОНСИМ,
       ЭЛ СТРАНА СИМВОЛ 6;

ЗАПИСЬ ДИСК:              ?*КОМПАКТ-ДИСК*
       ЭЛ НОМЕР  ЦЕЛОЕ,
       ЭЛ НАЗВ   СТРОКА КОНСИМ,
       ЭЛ ГОД    ЦЕЛОЕ РАЗМЕР 9999,
       ЭЛ ЦЕНА   ДЕЙСТВ РАЗМЕР 99900;

ЗАПИСЬ ТРЕК:              ?*ДОРОЖКА НА ДИСКЕ*
       ЭЛ НОМЕР  ЦЕЛОЕ РАЗМЕР 99,
       ЭЛ НАЗВ   СТРОКА КОНСИМ,
       ЭЛ ДЛИТ   СЕКУНД;

НАБОР SY-АРТ:
       ЧЛЕН АРТИСТ, ПРИВЯЗ ИН-ДИС,
       УПОРЯД ПО-ЭЛЕ ИМЯ;

НАБОР SY-ДИС:
       ЧЛЕН ДИСК, ПРИВЯЗ ИН-ДИС,
       УПОРЯД ПО-ЭЛЕ НОМЕР;

НАБОР АР-ДИС:
       ВЛАДЕЛ АРТИСТ, ЧЛЕН ДИСК, ПРИВЯЗ ИН-ДИС,
       УПОРЯД ПО-ЭЛЕ ГОД, ДУБЛИК РАЗРЕШ;

НАБОР ДИ-ТРЕ:
       ВЛАДЕЛ ДИСК, ЧЛЕН ТРЕК, ПРИВЯЗ ИН-ДИС,
       УПОРЯД ПО-ЭЛЕ НОМЕР;

КОНЕЦ.
```

Notes:

- `ТИП` - your own types: a text of 40 characters, a number of seconds up to 9999.
- `РАЗМЕР` gives the digits of a number: nines are integer digits, trailing zeros are decimals. `ЦЕНА ДЕЙСТВ РАЗМЕР 99900` is printed as `14.00`.
- `?*...*` - a comment.
- `ДУБЛИК РАЗРЕШ` - duplicates allowed: an artist may release two discs in one year. Without it a second record with the same key is refused.
- A set with `ВЛАДЕЛ` links an owner with its members. A new member joins automatically: a new `ТРЕК` goes into the `ДИ-ТРЕ` of the current `ДИСК`. With `ВКЛЮЧЕ ВРУЧНУ` you connect members yourself with `ВКЛЮЧИ`.
- `ВЫБОР s ИСПОЛЬЗ R.F` (not used here) picks the owner for `ВКЛЮЧИ` by the key in `R.F`, looked up in set `s`.

```sh
ttc < cd.ddl
```

Output (shortened):

```
ТТС15
=== ТУРЕS          2 ===
 СТРОКА ВАSЕ=СИМВОЛ SZ=
 СЕКУНД ВАSЕ=ЦЕЛОЕ  SZ=9999
=== RЕСОRDS          3 ===
 АРТИСТ FIЕLDS=         2
   ИМЯ    СТРОКА        КОНСИМ
   СТРАНА СИМВОЛ
 ДИСК   FIЕLDS=         4
 ...
=== SЕТS          4 ===
 ...
 ДИ-ТРЕ МЕМВЕR=ПО-ЭЛЕ ОWNЕR=ДИСК   АТТ=         5
   ВЛАДЕЛ ДИСК
   ЧЛЕН   ТРЕК
   ПРИВЯЗ ИН-ДИС
   УПОРЯД ПО-ЭЛЕ
   ПОЛЕ   НОМЕР
SАVЕD=         9 МАRSЕRR=         0
ЕХN=         0
```

Check the counts: 2 types, 3 records, 4 sets. `ЗАМЕНИ СХЕМА` replaces the old schema, so you may run `ttc` again after a fix.

### Step 3. Load data

File `load.gen` has formats, `КОНЕЦ`, then the data:

```
ФОРМАТ АРТИСТ
АРТИСТ.ИМЯ_АРТИСТ.СТРАНА*
ПАСКАЛ "&&ПОСТАВ АРТИСТ&&"
ФОРМАТ ДИСК
ДИСК.НОМЕР_ДИСК.ГОД_ДИСК.ЦЕНА_ДИСК.НАЗВ*
ПАСКАЛ "&&ПОСТАВ ДИСК&&"
ФОРМАТ ТРЕК
ТРЕК.НОМЕР_ТРЕК.ДЛИТ_ТРЕК.НАЗВ*
ПАСКАЛ "&&ПОСТАВ ТРЕК&&"
КОНЕЦ
АРТИСТ [КИНО_РОССИЯ*]
ДИСК   [1001_1988_12.50_ГРУППА КРОВИ*]
ТРЕК   [1_286_ГРУППА КРОВИ*
        2_255_ЗАКРОЙ ЗА МНОЙ ДВЕРЬ*
        3_245_ВОЙНА*]
ДИСК   [1002_1989_14.00_ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ*]
ТРЕК   [1_225_ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ*
        2_230_ПЕСНЯ БЕЗ СЛОВ*
        3_268_ПАЧКА СИГАРЕТ*]
АРТИСТ [АКВАРИУМ_РОССИЯ*]
ДИСК   [1003_1983_10.00_РАДИО АФРИКА*]
ТРЕК   [1_240_РАДИО АФРИКА*
        2_205_ТВЕРДЫЙ ЗНАК*]
```

How to read it:

- `ФОРМАТ ДИСК` - a format named `ДИСК`; then the fields of a data line, in order. `_` separates fields, `*` ends a line.
- `ПАСКАЛ "..."` - what to do with each line: Pascal text with DML. Here: store a new record. A format may also set variables, call procedures, find owners first (see `tests/gold-ck0/deck6.gen`).
- `ДИСК [ ... ]` - data lines for the format `ДИСК`. Line breaks inside a block are blanks.
- The order matters. A disc goes under the last artist, a track under the last disc: they are the current owners of `АР-ДИС` and `ДИ-ТРЕ`.
- The track lengths are sample values.

```sh
gen < load.gen
```

As the original GEN did, `gen` writes a loader program, passes it through `predt` and `fpc`, and runs it on the data. This takes a few seconds. Output:

```
АРТИСТ      2
ДИСК        3
ТРЕК        8
ОШИБОК: 0
```

One line per format: the number of data lines. A failed line is reported as `ГЕН: ОШИБКА <reason>: <format> СТРОКА <n>`, for example `ДУБЛИКАТ КЛЮЧА`. `gen -k` keeps the loader in a work directory and prints its name.

If `gen` stops with errors, delete the database and repeat steps 1-3: otherwise the good lines are stored twice.

### Step 4. Query the database

A list of all discs. File `discs.mad`:

```
РЕЖИМ 2;ЖУРНАЛ ЖУ-ДИС;ПОДСХЕ СХ-ДИС;
НАЙТИ ПЕРВУЮ В SY-ДИС;
А:ВЗЯТЬ;
  ВЫДАТЬ .НОМЕР,' ',.ГОД,' ',.ЦЕНА,' ',.НАЗВ;
  НАЙТИ СЛЕДУЮ В SY-ДИС;ЕСЛИ СОС=0 ТО НА А;
СБРОСИ;ЗАВЕРШ;КОНЕЦ
```

```sh
mad < discs.mad
```

Output:

```
1001 1988 12.50 ГРУППА КРОВИ
1002 1989 14.00 ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ
1003 1983 10.00 РАДИО АФРИКА
```

- `ВЫДАТЬ` prints one line: `'text'`, `.FIELD` of the current record, `REC.FIELD` of the current record of type `REC`, and `/` for a line break.
- `РЕЖИМ`, `ЖУРНАЛ`, `ПОДСХЕ`, `СБРОСИ`, `ЗАВЕРШ` are accepted; the database is the one in `MARS_DIR`.

One disc with its artist and tracks. File `tracks.mad`:

```
НАЙТИ ПО-КЛЮ 1002 В SY-ДИС;
ВЗЯТЬ;ВЫДАТЬ .НАЗВ;
НАЙТИ ВЛАДЕЛ В АР-ДИС;ВЗЯТЬ;ВЫДАТЬ .ИМЯ;
НАЙТИ ПЕРВУЮ В ДИ-ТРЕ;
Т:ВЗЯТЬ;ВЫДАТЬ .НОМЕР,' ',.ДЛИТ,' ',.НАЗВ;
  НАЙТИ СЛЕДУЮ В ДИ-ТРЕ;ЕСЛИ СОС=0 ТО НА Т;
КОНЕЦ
```

- `НАЙТИ ПО-КЛЮ 1002 В SY-ДИС` - find the disc by its number.
- `НАЙТИ ВЛАДЕЛ В АР-ДИС` - go up to the artist who owns the disc.
- `НАЙТИ ПЕРВУЮ В ДИ-ТРЕ` - the first track of the disc. KOMPAS remembers the current record of each set, so the disc is still current in `ДИ-ТРЕ`.

Output of `mad < tracks.mad`:

```
ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ
КИНО
1 225 ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ
2 230 ПЕСНЯ БЕЗ СЛОВ
3 268 ПАЧКА СИГАРЕТ
```

Nested walks and branches. File `artists.mad`:

```
?* ВСЕ ИСПОЛНИТЕЛИ И ИХ ДИСКИ ПО ГОДАМ *
НАЙТИ ПЕРВУЮ В SY-АРТ;
А:ВЗЯТЬ;ВЫДАТЬ .ИМЯ,' (',.СТРАНА,')';
  НАЙТИ ПЕРВУЮ В АР-ДИС;
  ЕСЛИ СОС=0 ТО_(
    Д:ВЗЯТЬ;ВЫДАТЬ '   ',.ГОД,' ',.НАЗВ;
      НАЙТИ СЛЕДУЮ В АР-ДИС;ЕСЛИ СОС=0 ТО НА Д_)
  ИНАЧЕ ВЫДАТЬ '   НЕТ ДИСКОВ';
  НАЙТИ СЛЕДУЮ В SY-АРТ;ЕСЛИ СОС=0 ТО НА А;
КОНЕЦ
```

Output:

```
АКВАРИУМ                                 (РОССИЯ)
   1983 РАДИО АФРИКА
КИНО                                     (РОССИЯ)
   1988 ГРУППА КРОВИ
   1989 ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ
```

`ЕСЛИ СОС=0 ТО_( ... _)ИНАЧЕ ...` - a branch; `СОС` is the status of the last `НАЙТИ`. A text field is printed at its full width. A mistake in the query is reported as `ОШИБКА В СТРОКЕ n: ...` and nothing is run.

### Step 5. Write a program

MAD is enough for reports. For computations and dialogs, write a Pascal program with DML. File `cdtime.pas`: read a disc number, print the artist, the title and the total playing time.

```
PROGRAM CDTIME(INPUT,OUTPUT);
&& ПОДСХЕ СХ-ДИС &&
VAR N, S: INTEGER;
BEGIN
  READ(N);
  &&ЖУРНАЛ ЖУ-ДИС&&
  ДИСК.НОМЕР := N;
  &&НАЙТИ ПО-КЛЮ В SY-ДИС&&
  IF СОСТ <> 0 THEN WRITELN('НЕТ ДИСКА ', N:1)
  ELSE BEGIN
    &&ВЗЯТЬ; НАЙТИ ВЛАДЕЛ В АР-ДИС; ВЗЯТЬ&&
    WRITELN(АРТИСТ.ИМЯ);
    WRITELN(ДИСК.НАЗВ);
    S := 0;
    &&НАЙТИ ПЕРВУЮ В ДИ-ТРЕ&&
    WHILE СОСТ = 0 DO BEGIN
      &&ВЗЯТЬ&&
      S := S + ТРЕК.ДЛИТ;
      &&НАЙТИ СЛЕДУЮ В ДИ-ТРЕ&&
    END;
    WRITELN('ВСЕГО ', S DIV 60:1, ' МИН ', S MOD 60:1, ' СЕК')
  END;
  &&ЗАВЕРШ&&
END.
```

- `&& ПОДСХЕ СХ-ДИС &&` - declares the records of the schema as Pascal variables `АРТИСТ`, `ДИСК`, `ТРЕК` (types `ZZАРТИСТ` ...), and the status `СОСТ`.
- `ВЗЯТЬ` copies the current record into its variable; `ПОСТАВ` and `ЗАМЕНИ` copy the variable into the database.
- To find by key, put the key into the record variable (`ДИСК.НОМЕР := N`) and call `НАЙТИ ПО-КЛЮ`. Or give the key: `НАЙТИ ПО-КЛЮ N В SY-ДИС`.
- `СОСТ` - status of the last DML statement, `0` means success.

Build and run it:

```sh
kpc cdtime.pas
echo 1002 | ./cdtime
```

`kpc` is a short way to run the two steps (`$KOMPAS` is the directory of this repository):

```sh
predt cdtime.pas cdtime_fpc.pas         # DML and Russian names -> plain Free Pascal
fpc -Fu$KOMPAS/build/lib -ocdtime cdtime_fpc.pas
```

`predt` reads the schema from `MARS_DIR`, so the database must exist. Output:

```
КИНО
ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ
ВСЕГО 12 МИН 3 СЕК
```

With a wrong number, `echo 1777 | ./cdtime` prints `НЕТ ДИСКА 1777`.

Adding a track to disc 1002:

```
ДИСК.НОМЕР := 1002;
&&НАЙТИ ПО-КЛЮ В SY-ДИС&&
ТРЕК.НОМЕР := 4; ТРЕК.ДЛИТ := 250; ТРЕК.НАЗВ := 'КИНО';
&&ПОСТАВ ТРЕК&&
IF СОСТ <> 0 THEN WRITELN('ОШИБКА ', СОСТ:1);
```

The disc found by key is the current owner, so the new track joins its `ДИ-ТРЕ` in order of `НОМЕР`. Changes are written to the journal named by `ЖУРНАЛ`.

### Step 6. Maintenance

The database is the directory `MARS_DIR`. Back up and restore it as files, when no tool is running:

```sh
tar czf ~/cd-$(date +%F).tgz -C ~/cd db                 # back up
rm -rf ~/cd/db && tar xzf ~/cd-2026-11-20.tgz -C ~/cd   # restore
```

To reload from scratch: remove the directory and repeat steps 1-3. To change the schema (for example a new element `ЖАНР`): unload the data with a MAD query in GEN format (as `tests/gold-zt0/deck9.mad` does), fix `cd.ddl`, and reload.

`servis` statements on areas made by an earlier run (`ОЧИСТИ`, `ОСВОБО`, `ВОССТА`) are not available yet: `servis` keeps its list of areas only while it runs, and answers `ОБЛАСТЬ НЕ ОПРЕДЕЛЕНА`. The database itself is not touched.

A simple routine:

| When | What |
|---|---|
| after each load or big change | `mad < discs.mad` to check |
| weekly | back up the directory |
| after a failure | restore the last backup, repeat the changes since |

### Step 7. Typical tasks

| Task | Tool | How |
|---|---|---|
| Add an artist with discs | `gen` | a `load.gen` with the formats and only the new data blocks |
| Add one track | program | `НАЙТИ ПО-КЛЮ` the disc, `ПОСТАВ ТРЕК` (step 5) |
| List the discs of an artist | `mad` | `НАЙТИ ПО-КЛЮ 'КИНО' В SY-АРТ;`, then walk `АР-ДИС` |
| List all artists | `mad` | walk `SY-АРТ`: they come in order of `ИМЯ` |
| Change a price | program | `НАЙТИ ПО-КЛЮ`, `ЗАМЕНИ ДИСК.ЦЕНА НА 15.00` |
| Renumber a disc | program | `ВЗЯТЬ`, change `ДИСК.НОМЕР`, `ЗАМЕНИ ДИСК`: `SY-ДИС` is reordered |
| Delete a disc | program | erase its tracks (`УБРАТЬ` each), then `УБРАТЬ ДИСК`; members left are disconnected |
| Move a disc to another artist | program | `ИСКЛЮЧ ИЗ АР-ДИС`, find the new artist, `ВКЛЮЧИ В АР-ДИС` |
| Total time of a disc | program | `cdtime` (step 5) |
| Remember a place and come back | program | `ВЗЯТЬ БД-КЛЮ ДИСК НА K`, later `ЗАМЕНИ БД-КЛЮ ДИСК НА K` |

## 7. Typical tasks

| Task | What to do |
|---|---|
| Create a new database | steps 1, 2, 3 with the same `MARS_DIR` |
| Get a report | a MAD query (step 4) |
| Find one record | `НАЙТИ ПО-КЛЮ` |
| Walk linked records | `НАЙТИ ПЕРВУЮ В <set>`, then `НАЙТИ СЛЕДУЮ` |
| Find who owns a record | `НАЙТИ ВЛАДЕЛ В <set>` |
| Change a field | `ВЗЯТЬ`, change the field, `ЗАМЕНИ` |
| Delete a record | `НАЙТИ ...`, then `УБРАТЬ` |
| Data damaged after a failure | restore the backup of `MARS_DIR` (section 6, step 6) |

## 8. When something goes wrong

| Symptom | Cause |
|---|---|
| `СОСТ` is not 0 | 1 end of set, 2 no such record, 3 duplicate key, 4 no current record, 5 already (not) in the set, 6 bad name, 7 storage error, 8 no schema |
| `ГЕН: ОШИБКА ДУБЛИКАТ КЛЮЧА` | the key is already in an ordered set without `ДУБЛИК РАЗРЕШ` |
| `ГЕН: ОШИБКА НЕТ ТЕКУЩЕЙ` | no current owner for an automatic set: load the owner first |
| `НЕТ СХЕМЫ` | no `ttc` run in this `MARS_DIR` |
| `ОШИБКА ПАМЯТИ` | the area named in the schema was not made by `servis` (step 1) |
| `predt: нет набора X` | the name is not in the schema; a name is cut to 6 characters |
| `СОС` is not 0 after `НАЙТИ СЛЕДУЮ` | end of the set, not an error |
| The database is empty in a later step | `MARS_DIR` points to another directory |

Latin and Cyrillic letters that look alike (`A` and `А`, `C` and `С`) are the same for KOMPAS. Lower-case letters are read as upper case.

## 9. Further reading

- `doc/engine.md` - the engine and the tools; what is a guess.
- `doc/open-questions.md` - hypotheses and open questions.
- `tests/` - the examples with their output, including the original 1988 decks and the application programs of Pavel Severov (`tests/severov`).
