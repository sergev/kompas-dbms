# Guesses

Where the surviving materials do not fix the behaviour of the original, this re-implementation made a choice. Each choice is listed here with its basis, so it can be checked if a manual or an old printout turns up. A new guess goes here.

## Engine

- **Status codes** `СОСТ`: 0 success, 1 end of set, 2 no record, 3 duplicate key, 4 no current record, 5 membership error, 6 bad name, 7 storage error, 8 no schema. Invented: the programs test only `СОСТ=0`, `МОЖНО`, `ПУСТО`.
- **`РАЗМЕР`** is a digit pattern: nines are integer digits, trailing zeros decimals (`99900` is 999.00). For `ЦЕЛОЕ` the decimals are a scale: `РАЗМЕР 99999000` stores 2004000 and prints `2004.000`. Basis: deck 6 sets `ВЕЩЬ.НОМЕР:=ROUND(CYMMA.ЦЕНА*1000)` for data `2004.000`, and query deck 3 prints the data of deck 6 back.
- **`НАЙТИ ПО-КЛЮ`** with duplicate keys finds the last of the equal members. Basis: deck 7, format `ПРИБОР`, finds by key and then walks `ПРЕДЫД`.
- **`УБРАТЬ` of an owner** disconnects its members, does not erase them. Basis: the programs erase the members first (`УНАР(&&НАБ …&&)`).
- **`ПРОИЗВ`**, or no `УПОРЯД`, inserts at the end.
- **Currency in a set.** `НАЙТИ ПЕРВУЮ В s` from a record of the owner type takes the members it owns; `НАЙТИ СЛЕДУЮ` from a member takes the next member. For the recursive set `ИС-ИСП` this gives the tree walk of deck 9.
- **Key order.** The original compared keys by bytes of the GOST code, where Cyrillic look-alikes of Latin letters sorted with Latin (`С` before `З`). Here keys are in Unicode order (`З` before `С`), so some ordered sets, and the Severov sessions that walk them, differ from 1988.

## Tools

- **`ОСВОБО`** releases an area (a flag that `УБРАТЬ ОБЛАСТЬ` and `ЖУРНАЛ … ЗАКРЕПИ` require) and keeps its data. Basis: the reload decks 6, 7, 11 give `ОСВОБО`, then `ОЧИСТИ` of the same areas, then `ЖУРНАЛ … СБРОСИ`.
- **`ОЧИСТИ`** erases the data of an area, without needing `ОСВОБО` first; `ЖУРНАЛ … СБРОСИ` empties a journal.
- **`servis` statements in a GEN deck** (between the job cards `*С` and `*CALL`) were a job step before the loader; `gen` runs them. A load after `ЖУРНАЛ x СБРОСИ` is journaled into `x`, so the journal covers the areas from empty.
- **`ВОССТА`** rolls areas forward from the journals. The 1988 journal format is not known; here a journal holds after-images of records.

## Severov's programs

- **Lost library modules** are rebuilt from how the programs call them:
  - `ROTД` reads a department name and finds it in `SY-ОТД` (otherwise `ИСК` of `SKLOTD` removes the wrong department).
  - `FCOPY(F,OUT)` moves the unfinished output line into file `F` (`ШАПКА` centres a title by it); `FWRITE(OUT)` ends the line.
  - `ЖУРНАЛ(A,P)` and `КОНЕЦ(P)` call the procedure `ПРЕДЗАК` they receive.
  - `КУДА` starts as `НАЧАЛО`; in 1988 the calling program set it.
  - `FCBЯ(S1,S2,R)` finds among the members of the current occurrence of `S1` the one whose owner in `S2` is the current `R`, and makes it current (`СОСТ=0`), else `СОСТ<>0`. Basis: its calls in `SKLCAR`, followed by `IF МОЖНО THEN ВЗЯТЬ ВЗЯЛ` and `ПОСТАВИТЬ ВЗЯЛ`.
- **`LIST`** (parameter cards of `ZATZAT`, `ZATNAK`, `ZATRTE`) takes its list from the database: the `ПАР` of a list (`СП-ЗАТ`, `СП-НАК`, `СП-ТЕМ`, deck 11) owns its parameters through `ПА-ПАР`, each with a `ТИП` and attributes `АТР`.
  - `ПЕРЕД t Н question`: ask before the parameter, and on the answer `НЕТ` go to `t`; `ПОСЛЕ`: the same after it; `УХОД t`: afterwards go to `t`. Column 8 of the value (`Н`) is the answer that jumps.
  - A name outside the list (`ЭТОВСЕ`) ends it.
  - This gives the order of questions of `ZATRTE` for deck 11: executor, co-executors, sub-executors, stages with repetition.
- **`Ц` and `Д`** in `CONTENT` of `LIST` hold one number. `ZATNAK` reads `Ц!` of a `ДЕЙ` parameter, so 1500.50 is stored as 1500; in 1988 this probably gave garbage.
- **Months** (`МЕС`) are stored as YYMM (`ЧИСМЕС`) and printed `MM.YY` (`WMEC`), so sets ordered by month are in time order. A quarter is YYQ (`ЧИСКВА`, `WKBA`). `WREAL(X,N)` prints N decimals.
- **`OUT` was a line buffer** printed by `PUTT`. Here `sevlib` keeps the unfinished output line:
  - `REWRITE(OUT)` drops it; `FCOPY(F,OUT)` moves it into a file.
  - `TPUT` prints it as a table row: cells up to `!`, `^` breaks a line inside a cell, widths from `TABLE[j].S`, `ВСЕ` ends the row.
  - The alignment `TABLE[j].F` was chosen by the look of the table: `Ц` centre, `П` right, else left.
  - `REWRITE(INP);WRITE(INP,X);INPUTCON` (`ZATZAT`) became `INPUTCON(X)`.
