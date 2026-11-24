# Hypotheses and open questions

The engine and the tools are written anew; the original sources are lost. Each statement below is marked:
- **FACT**: observed in the materials;
- **HYPOTHESIS**: chosen to make the materials consistent;
- **UNKNOWN**.

A new guess goes here first and is checked afterwards.

## Engine

- **HYPOTHESIS**: status codes `СОСТ`:
  - 0 success, 1 end of set, 2 no record, 3 duplicate key;
  - 4 no current record, 5 membership error, 6 bad name, 7 storage error, 8 no schema.

  The original codes of KOMPAS are not known. The Severov programs test only `СОСТ=0`, `МОЖНО`, `ПУСТО`.
- **HYPOTHESIS**: `РАЗМЕР` is a digit pattern: nines are integer digits, trailing zeros are decimals (`99900` is 999.00).
  - For `ЦЕЛОЕ` the decimal digits are a scale: `ИНВНОМ ЦЕЛОЕ РАЗМЕР 99999000` stores 2004000 and prints `2004.000`.
  - Basis, from deck 6 (`tests/gold-ck0`): `ВЕЩЬ.НОМЕР:=ROUND(CYMMA.ЦЕНА*1000)` with data `2004.000`; prices `0.20` and `44.00`; stock `67.000`.
  - The unload by deck 3 reproduces the data of deck 6.
- **HYPOTHESIS**: `НАЙТИ ПО-КЛЮ` in a set with duplicates finds the last of the equal records. Basis: deck 7, format `ПРИБОР`, finds by key and then walks `ПРЕДЫД`.
- **HYPOTHESIS**: `УБРАТЬ` of an owner disconnects its members without erasing them. The Severov programs erase the members beforehand with `УНАР(&&НАБ …&&)`.
- **HYPOTHESIS**: `ПРОИЗВ`, and no `УПОРЯД`, mean insertion at the end.
- **HYPOTHESIS**: `НАЙТИ ПЕРВУЮ В s` from a record of the owner type takes the occurrence it owns, and `НАЙТИ СЛЕДУЮ` from a member takes the next member. For the recursive set `ИС-ИСП` this gives the tree walk of deck 9.
- **FACT**: `ВЫБОР TE-ИСП ИСПОЛЬЗ ЦЕЛ.ЗН` (deck 10) needs the owner to be chosen by key. Without it the co-executors of deck 11 do not get into `ИС-ИСП` and deck 9 does not print them (`tests/gold-zt0`).
- **FACT**: a set stored into an element `ЦЕЛОЕ` is kept as 32 bits (`ЗАМЕНИ ЦЕЛ.ЗН НА ФЛАГИ`, deck 11; `SYSTEM.РЕЖИМЫ:=ФЛАГИ`, deck 6).
- **UNKNOWN**:
  - the meaning of a subschema (`ПОДСХЕ`): the engine works with the whole schema;
  - the journal format and recovery from it;
  - the meaning of `КОНСИМ`, taken as a plain string.
- **HYPOTHESIS**: `ADDKEY` of a key already in the area fails with error 9 (exists); the first MARS here inserted a second entry. The decks guard it with `NOMATCH` anyway.
- **HYPOTHESIS**: `deld` on an area whose descriptor (`BDVECT[24]`) was spoiled fails with error 8, like the other calls.
- **HYPOTHESIS**: the DB-key of the first record of a new area is `6000₈`; this is the only value observed. The step for the next records is not known; 64 is used.
- **HYPOTHESIS**: the original ordered keys by the bytes of the GOST internal code, where Cyrillic look-alikes of Latin letters sorted with Latin (`С` before `З`). We order by Unicode code points (`З` before `С`), so ordered sets and the answers of the Severov sessions that follow them differ from 1988.

## Output formats of programs

- **FACT**: default `write` widths: integer 10, `real` 14, `boolean` 8.
  - A real without width prints as `    1.4000Е-01`: field 14, 4 decimals, two-digit exponent.
  - An enumeration value prints as its name, right-justified in 8.
  - These are the formats of the 1988 programs, kept in `krt` as `RT_W`/`RT_EnW` for `tests/severov`. New programs use the formats of Free Pascal.
- **UNKNOWN**: the report format `X:9:22` prints 22 decimals; what it meant in 1988 is not known.

## Severov's programs (`tests/severov`)

- **HYPOTHESIS**: the lost library modules are rebuilt from how the programs use them.
  - `ROTД` reads a department name and finds it in `SY-ОТД`; otherwise `ИСК` in `SKLOTD` removes the wrong department.
  - `FCOPY(F,OUT)` moves the unfinished output line into the scratch file `F`, and `ШАПКА` centres the title by it. `FWRITE(OUT)` ends the line.
  - `ЖУРНАЛ(A,P)` and `КОНЕЦ(P)` receive the procedure `ПРЕДЗАК` and call it.
  - `КУДА` starts as `НАЧАЛО`; in 1988 the calling program set it.
- **HYPOTHESIS**: the module `LIST` (parameter cards of `ZATZAT`, `ZATNAK`, `ZATRTE`) takes its list from the database.
  - The `ПАР` of a list (`СП-ЗАТ`, `СП-НАК`, `СП-ТЕМ`, deck 11) owns its parameters through `ПА-ПАР`. A parameter has a `ТИП` and attributes `АТР`.
  - `ПЕРЕД t Н question`: ask the question before the parameter, and on the answer `НЕТ` go to `t`. `ПОСЛЕ`: the same after it. `УХОД t`: after it go to `t`.
  - A name outside the list (`ЭТОВСЕ`) is the end.
  - Column 8 of the value (`Н`) is taken as the answer that leads to the jump.
  - This gives the order of the questions of `ZATRTE` for deck 11: executor, co-executors, sub-executors, stages with repetition.
- **HYPOTHESIS**: in `CONTENT` of `LIST` the fields `Ц` and `Д` hold one number.
  - `ZATNAK` reads `Ц!` of parameters of type `ДЕЙ` in `ПОСТАВ` (`ПРОЧ:=Ц!`), so the fraction is lost there: 1500.50 is stored as 1500.
  - In 1988 `Ц` and `Д` were probably variants of one pointer, and such a read would give garbage.
- **HYPOTHESIS**: a month (`МЕС`) is stored as YYMM (`ЧИСМЕС`) and printed `MM.YY` (`WMEC`; the heading of `ZATTAB`: `XX.XX`). So months in the sets `ПО-ЭЛЕ MEC` are in time order.
  - A quarter is YYQ (`ЧИСКВА`, `WKBA`).
  - `WREAL(X,N)` prints N decimals.
- **HYPOTHESIS**: `OUT` in 1988 was a line buffer, and `PUTT` printed it. Here `sevlib` keeps the unfinished output line (`ZZTLEN`, `ZZTCH`, `ZZTCLR`):
  - `REWRITE(OUT)` drops it, and `FCOPY(F,OUT)` moves it into a file.
  - `TPUT` prints it as a table row: cells up to `!`, `^` breaks a line inside a cell, widths come from `TABLE[j].S`, `ВСЕ` is the end.
  - The alignment `TABLE[j].F` is not known. It was chosen by the look of the table: `Ц` centre, `П` right (the line `ИТОГО`), otherwise left.
  - `REWRITE(INP);WRITE(INP,X);INPUTCON` (`ZATZAT`) is replaced by `INPUTCON(X)`, because the input line is not modelled as a buffer.
- **FACT**: in `ZATTAB`, `BЫЧKOЭФ` calls `ЗАМЕНИ` of the record `ДЕЙ` without assigning it the value of parameter `I` (`PДEЙ`). So the coefficients `ZKПРОЧ`, `ZKНАКЛ` and `ZKЗАРН` stay 0.0 from deck 11.
- **FACT**: in `ZATCOF`, `НОВ` stores the record `АЛФ` of the list `ИМ-КОЭ` without assigning `АЛФ.ЗН:=ПАР.ИМЯ` (deck 11 assigns it, format `ПА--АЛ`). So the new coefficient is listed under a blank name, and `ИСК` does not find it in `ПА-АЛФ`: its `УБРАТЬ` then erases the current record, the `ПАР` `ИМ-КОЭ`, and the list is lost.
- **FACT**: `SKLCAR` checks the unit of measure by writing the units to `OUT`, then `RESET(OUT)` and `READ(OUT,ЕДИЗМ)`. It is converted like `ШАПКА` of `SKLOTC`: the line goes to a scratch file by `FCOPY`.
- **HYPOTHESIS**: `FCBЯ(S1,S2,R)` (`SKLCAR`, module lost) finds among the members of the current occurrence of `S1` the one whose owner in `S2` is the current record of type `R`, makes it current and sets `СОСТ=0`; otherwise `СОСТ<>0`. Basis: its calls `FCBЯ(МА-СУМ,ОТ-СУМ,ОТДЕЛ)` and `FCBЯ(ВЕ-ВЗЯ,СУ-ВЗЯ,СУММА)`, followed by `IF МОЖНО THEN ВЗЯТЬ ВЗЯЛ` and `ПОСТАВИТЬ ВЗЯЛ`.
- **FACT**: `ZATTAB` prints a trace of its calculation, because `INITTAB` sets `PRINTCALC:=TRUE`. Two parts of the trace depend on the rebuilt modules: the format `R:0:23`, and `CLF` as a line break in `HEADING`.

## Tools

- **FACT**: the original `servis` and `ttc` erased the catalogue at start (`PASACD`). Here they do not, otherwise each tool would destroy the work of the one before.
- **UNKNOWN**: how the original `servis` found the areas of an earlier run. Here their descriptions are kept in the MARS area `SERVIS`.
- **HYPOTHESIS**: `ОСВОБО` releases an area (clears the flag `servis` requires before `УБРАТЬ ОБЛАСТЬ` and `ЖУРНАЛ … ЗАКРЕПИ`); it does not erase data. Basis: the reload decks 6, 7, 11 give `ОСВОБО` of all areas, then `ОЧИСТИ` of the same areas, then `ЖУРНАЛ … СБРОСИ`.
- **HYPOTHESIS**: `ОЧИСТИ` erases the data of an area; `ЖУРНАЛ … СБРОСИ` empties the journal. `ОЧИСТИ` does not require `ОСВОБО` before it, although the decks always give it.
- **HYPOTHESIS**: the `servis` statements in a GEN deck (between the job cards `*С` and `*CALL`) were a job step of their own before the loader; `gen` runs them. A load after `ЖУРНАЛ x СБРОСИ` writes journal `x`, so that the journal covers the areas from empty.
- **HYPOTHESIS**: `ВОССТА` rolls the areas forward from the journal. Here the journal holds after-images of records (not the 1988 format, which is not known), and `ВОССТА` replays those of the areas named.
