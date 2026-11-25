# KOMPAS: a tutorial

This tutorial builds a small database from scratch, a collection of music CDs, and uses it to show every part of KOMPAS. All its files are in `tests/cd`, with their output in `tests/cd/expected.txt`.

## 1. What KOMPAS is

KOMPAS is a database management system built at the Computing Centre of the USSR Academy of Sciences in the 1980s. This is a re-implementation of it as command line tools for Linux and macOS. The original programs are lost; the tools were rebuilt from schemas, decks, queries and programs of 1988-89 that survived (section 11).

KOMPAS is a network DBMS (the CODASYL model): records are linked into chains called sets, and a program moves from record to record along them. Its languages are Russian: keywords and names are Russian words. The examples keep them, with an explanation in English.

## 2. Setting up

Free Pascal 3.2 (`fpc`) must be installed; `gen` and `kpc` use it to compile programs. Build and install the tools once:

```sh
make
make install          # into ~/.local/bin; PREFIX=/usr/local for another place
```

`~/.local/bin` must be on your `PATH`. Without installing, use `export PATH=$PWD/build/bin:$PATH`.

| Tool | Reads | Does |
|---|---|---|
| `servis` | area statements | creates the database and its areas; clears, recovers (sections 4, 9) |
| `ttc` | a schema in DDL | stores the schema (section 5) |
| `gen` | a loader deck: formats and data | loads data (section 6) |
| `mad` | a query | prints reports, without programming (section 7) |
| `kpc` | a Pascal program with DML | compiles it (section 8) |

Each tool reads standard input and writes standard output. All of them work on one database: the file named by `MARS_DB` (without it, `mars.db` in the current directory). Only `servis` creates the file; the others report a missing one. Several tools may work on the same file at the same time.

For this tutorial:

```sh
mkdir -p ~/cd && cd ~/cd
export MARS_DB=~/cd/cd.db
```

## 3. The design

A database holds **records**. Records of one **type** have the same **elements** (fields). We need three types:

| Record type | Elements |
|---|---|
| `АРТИСТ` (artist) | `ИМЯ` name, `СТРАНА` country |
| `ДИСК` (disc) | `НОМЕР` catalogue number, `НАЗВ` title, `ГОД` year, `ЦЕНА` price |
| `ТРЕК` (track) | `НОМЕР` track number, `НАЗВ` title, `ДЛИТ` length in seconds |

Records are linked by **sets**. A set links an **owner** record with its **member** records, kept in the order of a **key** element, so they can be walked forward and backward. A set whose owner is the system (`SY-…`) holds all records of a type: it is where a search starts. We need four sets:

| Set | Owner | Member | Order | Used for |
|---|---|---|---|---|
| `SY-АРТ` | system | `АРТИСТ` | by name | the list of artists |
| `SY-ДИС` | system | `ДИСК` | by number | the list of discs, a disc by its number |
| `АР-ДИС` | `АРТИСТ` | `ДИСК` | by year | the discs of an artist |
| `ДИ-ТРЕ` | `ДИСК` | `ТРЕК` | by number | the tracks of a disc |

```
SY-АРТ ──> АРТИСТ ──АР-ДИС──> ДИСК ──ДИ-ТРЕ──> ТРЕК
                                ^
SY-ДИС ─────────────────────────┘
```

The **schema** describes the types and sets. Records live in **areas**, named parts of the database: we use `ДА-ДИС` for the records, `ИН-ДИС` for the sets, `СХ-ДИС` for the schema and `ЖУ-ДИС` for the **journal**, a log of changes used for recovery.

Names of records, elements and areas have at most 6 characters; a longer name is cut. A set name has the form `XX-XXX`.

## 4. Areas: `servis`

File `areas.srv`:

```
ОБЛАСТЬ СХ-ДИС:ВАРИАНТ SSCXEM,
ОБЛАСТЬ ЖУ-ДИС:ВИД ЖУРНАЛ,
ОБЛАСТЬ ИН-ДИС:РЕЖИМ 0,
ОБЛАСТЬ ДА-ДИС:РЕЖИМ 0;
КОНЕЦ.
```

`ОБЛАСТЬ` (area) names an area; `ВИД ЖУРНАЛ` makes it a journal. Statements are separated by `,` or `;`, and `КОНЕЦ.` ends the input. An area has no size: it grows as needed.

```sh
servis < areas.srv
```

```
Servis 15.1
Пользователь ADMIN зарегистрирован
Создана область СХ-ДИС
Создана область ЖУ-ДИС
Создана область ИН-ДИС
Создана область ДА-ДИС
Ошибок: 0
```

One line per area. An error is reported as `Ошибка n: …`, and the last line counts them. The file `cd.db` now exists.

## 5. The schema: `ttc`

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

- `ЗАМЕНИ СХЕМА` (replace the schema): you may run `ttc` again after a fix. `ОБЛАСТЬ ДА-ДИС` is the area of the records that follow.
- `ЗАПИСЬ` is a record type, `ЭЛ` an element. Element types: `СИМВОЛ n` (n characters), `ЦЕЛОЕ` (integer), `ДЕЙСТВ` (real). `ТИП` defines a type of your own.
- `РАЗМЕР` gives the digits of a number: nines are integer digits, trailing zeros are decimals. `ДЕЙСТВ РАЗМЕР 99900` is printed as `14.00`.
- `НАБОР` is a set: `ВЛАДЕЛ` its owner (none: the system), `ЧЛЕН` its member, `УПОРЯД ПО-ЭЛЕ` its key. `ДУБЛИК РАЗРЕШ` allows two members with one key (two discs of one year); without it a second one is refused.
- A new member joins its sets by itself, under the current owner: a new `ТРЕК` goes into the `ДИ-ТРЕ` of the current `ДИСК`. With `ВКЛЮЧЕ ВРУЧНУ` in a set you connect members yourself (`ВКЛЮЧИ`, section 8), and `ВЫБОР s ИСПОЛЬЗ R.F` picks the owner by the key in `R.F`, looked up in set `s`.
- `?*…*` is a comment.

```sh
ttc < cd.ddl
```

`ttc` prints the schema as it understood it and ends with:

```
Сохранено объектов: 9
Ошибок: 0
```

Check the counts at the top of each part: `Типы: 2`, `Записи: 3`, `Наборы: 4`. Set names are printed with a Cyrillic `У`, `SУ-АРТ` (section 10).

## 6. Loading data: `gen`

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
АРТИСТ [Кино_Россия*]
ДИСК   [1001_1988_12.50_Группа крови*]
ТРЕК   [1_286_Группа крови*
        2_255_Закрой за мной дверь*
        3_245_Война*]
ДИСК   [1002_1989_14.00_Звезда по имени Солнце*]
ТРЕК   [1_225_Звезда по имени Солнце*
        2_230_Песня без слов*
        3_268_Пачка сигарет*]
АРТИСТ [Аквариум_Россия*]
ДИСК   [1003_1983_10.00_Радио Африка*]
ТРЕК   [1_240_Радио Африка*
        2_205_Твердый знак*]
```

- `ФОРМАТ ДИСК` lists the elements of a data line in order; `_` separates them and `*` ends the line.
- `ПАСКАЛ "…"` is what to do with each line: Pascal with DML (section 8). Here `ПОСТАВ` stores a new record. A format may also set variables, call procedures and find owners first.
- `ДИСК [ … ]` is a block of data lines for format `ДИСК`; a line break inside it is a blank.
- The order matters: a disc goes under the last artist, a track under the last disc, the current owners (section 5).
- The track lengths are sample values.

```sh
gen < load.gen
```

```
АРТИСТ      2
ДИСК        3
ТРЕК        8
Ошибок: 0
```

One line per format, with its count of data lines. `gen` writes a loader program, compiles it and runs it, as the original GEN did, so it takes a few seconds; `gen -k` keeps the program and prints where. A bad line is reported as `gen: строка <n>, формат <format>: <reason>`, and the other lines are stored. So after errors, fix the deck, remove `cd.db` and repeat sections 4-6, or the good lines are stored twice.

## 7. Queries: `mad`

File `discs.mad`, all discs:

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

```
1001 1988 12.50 Группа крови
1002 1989 14.00 Звезда по имени Солнце
1003 1983 10.00 Радио Африка
```

- `НАЙТИ ПЕРВУЮ В SY-ДИС` finds the first disc of the set; `НАЙТИ СЛЕДУЮ` the next one.
- `ВЗЯТЬ` reads the record found.
- `ВЫДАТЬ` prints one line: `'text'`, `.ЭЛ` (an element of the record read), `REC.ЭЛ` (of the current record of type `REC`), `/` (a line break). A text element is printed at its full width.
- `СОС` is the status of the last statement: `0` found, otherwise the set has ended. `ЕСЛИ СОС=0 ТО НА А` goes back to label `А`.
- The first line and `СБРОСИ;ЗАВЕРШ` open and close the work as in the original; they may be left out.

File `tracks.mad`, one disc with its artist and tracks:

```
РЕЖИМ 2;ЖУРНАЛ ЖУ-ДИС;ПОДСХЕ СХ-ДИС;
НАЙТИ ПО-КЛЮ 1002 В SY-ДИС;
ВЗЯТЬ;ВЫДАТЬ .НАЗВ;
НАЙТИ ВЛАДЕЛ В АР-ДИС;ВЗЯТЬ;ВЫДАТЬ .ИМЯ;
НАЙТИ ПЕРВУЮ В ДИ-ТРЕ;
Т:ВЗЯТЬ;ВЫДАТЬ .НОМЕР,' ',.ДЛИТ,' ',.НАЗВ;
  НАЙТИ СЛЕДУЮ В ДИ-ТРЕ;ЕСЛИ СОС=0 ТО НА Т;
СБРОСИ;ЗАВЕРШ;КОНЕЦ
```

```
Звезда по имени Солнце
Кино
1 225 Звезда по имени Солнце
2 230 Песня без слов
3 268 Пачка сигарет
```

- `НАЙТИ ПО-КЛЮ 1002 В SY-ДИС` finds a disc by its key.
- `НАЙТИ ВЛАДЕЛ В АР-ДИС` goes up to its owner, the artist.
- `НАЙТИ ПЕРВУЮ В ДИ-ТРЕ` finds the first track of the disc. KOMPAS keeps a current record for each set, so the disc is still current in `ДИ-ТРЕ` after the move to the artist.

File `artists.mad`, nested walks and a branch:

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

```
Аквариум                                 (Россия)
   1983 Радио Африка
Кино                                     (Россия)
   1988 Группа крови
   1989 Звезда по имени Солнце
```

`ЕСЛИ … ТО_( … _)ИНАЧЕ …` is a branch with a block. `НАЙТИ ПОСЛЕД` (last) and `НАЙТИ ПРЕДЫД` (previous) walk a set backward. A mistake in a query is reported as `Ошибка в строке n: …`, and nothing is run.

## 8. Programs: DML in Pascal

For computing and dialog, write a Free Pascal program with DML statements between `&&` and `&&`. File `cdtime.pas` reads a disc number and prints the artist, the title and the total playing time:

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

- `&& ПОДСХЕ СХ-ДИС &&` declares a variable for each record type of the schema (`АРТИСТ`, `ДИСК`, `ТРЕК`) and the status `СОСТ`.
- `ВЗЯТЬ` copies the current record into its variable; `ПОСТАВ` and `ЗАМЕНИ` copy the variable into the database.
- To find by key, put the key into the variable (`ДИСК.НОМЕР := N`) and call `НАЙТИ ПО-КЛЮ`, or give the key: `НАЙТИ ПО-КЛЮ N В SY-ДИС`.
- `ЖУРНАЛ ЖУ-ДИС` writes the changes of the program to the journal (section 9).
- `СОСТ` is the status of the last DML statement, `0` on success (the codes are in section 12).
- Names may be Russian, like those of the schema. Without a `{$mode}` directive the program is compiled in Turbo Pascal mode, with 64-bit `INTEGER`.

```sh
kpc cdtime.pas
echo 1002 | ./cdtime
```

```
Кино
Звезда по имени Солнце
ВСЕГО 12 МИН 3 СЕК
```

With a number not in the database, `echo 1777 | ./cdtime` prints `НЕТ ДИСКА 1777`.

`kpc` runs `predt`, which turns the DML and the Russian names into plain Free Pascal, then `fpc`. `predt` reads the schema from `MARS_DB`, so the database must exist when you compile.

To add a track to disc 1002:

```
ДИСК.НОМЕР := 1002;
&&НАЙТИ ПО-КЛЮ В SY-ДИС&&
ТРЕК.НОМЕР := 4; ТРЕК.ДЛИТ := 250; ТРЕК.НАЗВ := 'Кино';
&&ПОСТАВ ТРЕК&&
IF СОСТ <> 0 THEN WRITELN('ОШИБКА ', СОСТ:1);
```

The disc found is the current owner of `ДИ-ТРЕ`, so the track joins it, in order of `НОМЕР`.

The DML statements, with their KOMPAS operation codes:

| Code | Statement | Does |
|---|---|---|
| 01 | `ПОСТАВ R` | store a new record of type R |
| 02 | `НАЙТИ ПО-КЛЮ В s` | find by key |
| 04 | `НАЙТИ ПЕРВУЮ В s` | first member of a set |
| 05 | `НАЙТИ ВЛАДЕЛ В s` | owner in a set |
| 06 | `ВКЛЮЧИ В s` | connect the current record into a set |
| 07 | `УБРАТЬ` | erase the current record; its members are disconnected |
| 08 | `ИСКЛЮЧ ИЗ s` | disconnect from a set |
| 11 | `НАЙТИ ПОСЛЕД В s` | last member |
| 12 | `НАЙТИ СЛЕДУЮ` | next member |
| 13 | `НАЙТИ ПРЕДЫД` | previous member |
| 15 | `ЗАМЕНИ R`, `ЗАМЕНИ R.ЭЛ НА v` | change the current record; its sets are reordered if a key changed |
| 16 | `ВЗЯТЬ` | read the current record |
| | `ВЗЯТЬ БД-КЛЮ R НА K`, `ЗАМЕНИ БД-КЛЮ R НА K` | keep the address (DB-key) of the current record in `K`; make it current again later |

## 9. Keeping the database

**Safety.** Each statement that changes data is done whole or not at all, so a crash, even a power failure, leaves the database as after the last statement. A `gen` load commits every 1000 records and at the end. A disk that spoils the file is reported as `page N damaged`.

**Backup.** Copy the file while no tool is running:

```sh
cp ~/cd/cd.db ~/cd-$(date +%F).db     # back up
cp ~/cd-2026-11-20.db ~/cd/cd.db      # restore
```

**Reload and schema changes.** To start again, remove the file and repeat sections 4-6. To change the schema (say, a new element `ЖАНР`), unload the data with a query that prints them in the format of a loader deck (as `tests/gold-zt0/deck9.mad` does), fix `cd.ddl`, and reload.

**The journal.** A program or query that names a journal (`ЖУРНАЛ ЖУ-ДИС`) writes there the new image of every record it changes. `servis` can replay the journal into areas:

```
ОСВОБО ИН-ДИС,ДА-ДИС;
ОЧИСТИ ИН-ДИС,ДА-ДИС;
ВОССТА ИН-ДИС,ДА-ДИС;
КОНЕЦ.
```

This rebuilds the areas only if the journal holds everything since they were empty. So clear the journal (`ЖУРНАЛ ЖУ-ДИС СБРОСИ.`) right after clearing the areas, and make every later change through programs and queries that name it. A loader deck can do that itself: put `ОСВОБО`, `ОЧИСТИ` and `ЖУРНАЛ … СБРОСИ` before the data, as the decks of section 11 do, and `gen` runs them through `servis` and journals the load. A deck without them, like `load.gen`, is not journaled, so keep the deck and a backup.

The `servis` statements for existing areas:

| Statement | Does |
|---|---|
| `ОСВОБО ДА-ДИС;` | release an area (required by `УБРАТЬ ОБЛАСТЬ` and `ЖУРНАЛ … ЗАКРЕПИ`) |
| `ОЧИСТИ ДА-ДИС;` | erase the records of an area, keep the area |
| `ЖУРНАЛ ЖУ-ДИС СБРОСИ.` | empty a journal |
| `ВОССТА ИН-ДИС,ДА-ДИС;` | replay the journals into the areas |
| `УБРАТЬ ОБЛАСТЬ ДА-ДИС;` | delete an area |

## 10. Letters and case

All text is UTF-8: schemas, decks, queries, programs, input and output. The original KOMPAS had upper case only, and a Latin `A` and a Cyrillic `А` were one code. Here names and data follow different rules.

**Names and keywords are folded, as in the original.** Case does not matter, `Ё` is `Е`, and Latin letters that look like Cyrillic ones (`A B C E H K M O P T X Y`) are those Cyrillic letters. These are one name:

```
СЛОВО.ИМЯ    слово.имя    CЛOBO.ИMЯ
```

The last one is typed partly in Latin, as old texts often are. KOMPAS prints a name in one form, upper case with Cyrillic look-alikes: `SY-АРТ` is printed `SУ-АРТ`.

**Data are kept exactly as written**, in any alphabet and case. `tests/utf8` loads these words:

```
ФОРМАТ CЛOBO
CЛOBO.ИMЯ_cлoвo.ЗHAЧ_СЛОВО.БУКВА*
ПАСКАЛ "&&ПОСТАВ CЛOBO&&"
КОНЕЦ
СЛОВО [ёлка_новогодняя ель_ё*
        Ёж_колючий зверь_Ё*
        ЕЖ_ПРОПИСНЫМИ_Е*
        жук_насекомое_ж*
        Жук_с прописной_Ж*
        über_über alles_ü*
        Zebra_латиница_Z*
        apple_яблоко_a*
        Ωμέγα_омега_Ω*
        АБВ_кириллица_А*
        ABB_латиница, похожая_A*]
```

A query walks the set ordered by `ИМЯ`, then looks for the keys `Ёж` and `ёж`:

```
ABB         |латиница, похожая       |A|
Zebra       |латиница                |Z|
apple       |яблоко                  |a|
über        |über alles              |ü|
Ωμέγα       |омега                   |Ω|
Ёж          |колючий зверь           |Ё|
АБВ         |кириллица               |А|
ЕЖ          |ПРОПИСНЫМИ              |Е|
Жук         |с прописной             |Ж|
жук         |насекомое               |ж|
ёлка        |новогодняя ель          |ё|
НАЙДЕНО: колючий зверь
НЕТ ёж
```

- **Order** is by Unicode code: Latin upper case, Latin lower case, other alphabets, Cyrillic. In Cyrillic, upper case comes before lower case, `Ё` before `А`, and `ё` after `я`. `ABB` (Latin) and `АБВ` (Cyrillic) are different keys.
- **Keys are exact.** `НАЙТИ ПО-КЛЮ 'Ёж'` finds the record, `'ёж'` does not. To find a key whatever its case, store it in one case.
- **Length counts letters.** `СИМВОЛ 12` holds 12 letters of any alphabet, and columns line up.

In a program a `CHAR` holds one letter of any alphabet, and so does each element of a `PACKED ARRAY OF CHAR`; `READ` and `WRITELN` work as usual, and `ORD` gives the Unicode code (`ORD('ü')` is 252):

```
IF СЛОВО.БУКВА = 'ж' THEN WRITELN('СТРОЧНАЯ ж')
ELSE IF СЛОВО.БУКВА = 'Ж' THEN WRITELN('ПРОПИСНАЯ Ж')
ELSE WRITELN('БУКВА ', СЛОВО.БУКВА, ' КОД ', ORD(СЛОВО.БУКВА):1);
```

## 11. The decks of 1988

The tests hold the schemas, loader decks and queries of an accounting system of 1988-89 by Pavel Severov: a warehouse (`tests/gold-ck0`), depreciation (`tests/gold-am0`) and the costs of research topics (`tests/gold-zt0`); its application programs, converted to Free Pascal, are in `tests/severov`. They run unchanged and read like the example, with a few things of their time:

- Areas have a size, `ДЛИНА`, in zones of 1024 words of the BESM-6. It is accepted and ignored:

  ```
  ОБЛАСТЬ CХ-CK0:ДЛИНА 2 ВАРИАНТ SSCXEM,
  ОБЛАСТЬ ЖУ-CK0:ДЛИНА 6 ВИД ЖУРНАЛ,
  ```

- Names mix the alphabets: `CХ-CK0` starts with a Latin `C` (section 10).
- A loader deck is a whole job. After the formats come job cards (`*…`, skipped) and the `servis` statements that clear the areas and the journal before the reload (section 9):

  ```
  *С
  ОСВОБО ЖУ-СК0,ИН-СК0,ДА-СК0,ВР-СК0;
  ОЧИСТИ ЖУ-СК0,ИН-СК0,ДА-СК0,ВР-СК0;
  ЖУРНАЛ ЖУ-СК0 СБРОСИ.
  ```

- Formats call procedures of the deck (`ПРОЦЕДУРЫ "…"`) and find owners before `ПОСТАВ` (`tests/gold-ck0/deck6.gen`).

## 12. When something goes wrong

| Symptom | Cause |
|---|---|
| `СОСТ` or `СОС` is not 0 | 1 end of set (not an error), 2 no such record, 3 duplicate key, 4 no current record, 5 already (not) in the set, 6 bad name, 7 storage error, 8 no schema |
| `gen: …: дубликат ключа` | the key is already in an ordered set without `ДУБЛИК РАЗРЕШ` |
| `gen: …: нет текущей` | no current owner for a set: load the owner first |
| `нет схемы` | `servis` and `ttc` were not run on this `MARS_DB`: the file printed does not exist, or has no schema |
| The database is empty in a later step | `MARS_DB` names another file, or is not set in this shell |
| `ошибка памяти` | the area named in the schema was not made by `servis` |
| `predt: нет набора X` | the name is not in the schema; names are cut to 6 characters |
| `…: page N damaged` | the disk spoiled the file: restore a backup (section 9) |
| `mars: … areas of the old format` | `MARS_DIR` names a database of an older version (one file per area): rebuild it |
| Loading is slow | each commit waits for the disk; for a scratch database, `export MARS_SYNC=0` (safe if a program is killed, not on a power failure) |

## 13. Further reading

- `doc/engine.md`: how the engine and the tools work, and what in them is a guess.
- `doc/open-questions.md`: where the original is not known, the choices made.
- `tests/`: every example with its output.
