{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM AMOOTC; uses krt, kio, mars, kdb, sevlib; (*AM:OTЧET *)
&&ПOДCXE CX-AM0&&(**)
(* HEADING: common declarations of the Severov programs.
   The module is lost; this stand-in declares what the programs use. *)
TYPE INT=INTEGER;
(* where to go: set by the calling program in 1988; a run starts here *)
CONST KУДА: ALFA = 'НАЧАЛО';
VAR ДИР: packed array[1..3] of char;
    ШАГ: INTEGER;
TYPE BOOL=BOOLEAN;
  СТРОКА=packed array[1..84] of char;
  ФЛАГ=(ФS,ПЕЧАТЬ,МОДИФ,АДМИН,ОТЛАД,ОТЧСКЛ,ОТЧОТД,ВХОД,ФF); const XEN_Q0424_Q041B_AQ0413_: array[Q0424_Q041B_AQ0413_] of string[8] = ('ФS','ПЕЧАТЬ','МОДИФ','АДМИН','ОТЛАД','ОТЧСКЛ','ОТЧОТД','ВХОД','ФF'); type
  ДИРЕКТ=RECORD ИМЯ: ALFA; НАЗВ: ALFA END;
CONST LF=#10; CLF=#10; SСТРОКА=84;
VAR ФЛАГИ: SET OF ФЛАГ;
    СЕГОДНЯ: INTEGER;
    RGEXPORT: SET OF 0..63;
(* the unfinished output line (OUT of 1988): length, a char, drop it *)





(* FCOPY: the pending output line into scratch file F (native, see sevlib.pas) *)


(* FWRITE: copy text file F to the output *)


(* PUT: end of an output line *)
PROCEDURE PUTT; BEGIN WRITELN END;
PROCEDURE PUTPT; BEGIN WRITELN END;
PROCEDURE PUTP; BEGIN WRITELN END;

(* GET: one answer per input line; НАЧ at the end of input *)
VAR НАЧ, ZZSTARTED: BOOLEAN;
PROCEDURE GETНАЧ;
BEGIN
  WRITELN;
  IF ZZSTARTED AND NOT EOF(INPUT) THEN READLN(INPUT);
  ZZSTARTED:=TRUE;
  НАЧ:=EOF(INPUT)
END;
PROCEDURE GETT; BEGIN GETНАЧ END;

(* ДА: a yes/no answer *)
FUNCTION ДА: BOOLEAN;
VAR S: packed array[1..3] of char;
BEGIN
  GETНАЧ;
  IF НАЧ THEN ДА:=FALSE
  ELSE BEGIN begin RT_Read(S) end; ДА:=S[1]='Д' END
END;
(* ЕЩЕ: ask whether to go on *)
FUNCTION ЕЩЕ(S: ALFA): BOOLEAN;
BEGIN
  WRITE(OUTPUT,RT_W(S));
  ЕЩЕ:=ДА
END;

(* МОЖНО, ПУСТО: the status of the last DML statement *)
FUNCTION МОЖНО: BOOLEAN; BEGIN МОЖНО:=СОСТ=0 END;
FUNCTION ПУСТО: BOOLEAN; BEGIN ПУСТО:=СОСТ<>0 END;

(* ЧИСДАТ: date parts (stub) *)

(* ДАТЧИС: a date as a number YYMMDD *)
FUNCTION ДАТЧИС(D, M, Y: INTEGER): INTEGER;
BEGIN ДАТЧИС:=(Y*100+M)*100+D END;

(* CUTCTP: stub *)

(* APИФM: stub *)

(* WINT: stub *)

(* WДАТ: write a date as DD.MM.YY *)


(* WCTP: write a string without trailing blanks, in N positions *)


(* ПШИК: not used by the programs *)

(* MINUSES: a line of minuses *)
PROCEDURE MINUSES; VAR I: INTEGER; BEGIN FOR I:=1 TO 72 DO WRITE('-'); WRITELN END;

(* WLF: N line feeds *)
PROCEDURE WLF(N: INTEGER); VAR I: INTEGER; BEGIN FOR I:=1 TO N DO WRITELN END;

(* WBL: N blanks *)
PROCEDURE WBL(N: INTEGER); VAR I: INTEGER; BEGIN FOR I:=1 TO N DO WRITE(' ') END;

(* BIGLIN: stub *)

(* УСТПЕЧ: set up printing (stub) *)
PROCEDURE УСТПЕЧ; BEGIN END;

(* УСТМОД: mark the database modified (stub) *)
PROCEDURE УСТМОД; BEGIN END;

(* ЕСТЬ: acknowledge (stub) *)
PROCEDURE ЕСТЬ; BEGIN END;

(* ROTД: read the name of a department and find it in SY-ОТД;
   an unknown name is asked again, НАЧ ends *)
FUNCTION ROTД: ALFA;
VAR A: ALFA;
BEGIN
  REPEAT
    GETНАЧ;
    A:='      ';
    IF NOT НАЧ THEN BEGIN
      begin RT_Read(A) end;
      &&НАЙТИ ПО-КЛЮ A В SY-ОТД&&;
      IF СОСТ<>0 THEN WRITE(OUTPUT,'НЕТ ТАКОГО ОТДЕЛА, ПОВТОРИТЕ:')
    END
  UNTIL НАЧ OR (СОСТ=0);
  ROTД:=A
END;

(* RЦЕЛ: read an integer in A..B; RВЕЩ: an item number (real) *)
FUNCTION RЦЕЛ(A, B: INTEGER): INTEGER;
VAR N: INTEGER;
BEGIN
  GETНАЧ;
  N:=A;
  IF NOT НАЧ THEN begin RT_Read(N) end;
  IF N<A THEN N:=A; IF N>B THEN N:=B;
  RЦЕЛ:=N
END;
FUNCTION RВЕЩ(A, B: REAL): REAL;
VAR X: REAL;
BEGIN
  GETНАЧ;
  X:=A;
  IF NOT НАЧ THEN begin RT_Read(X) end;
  IF X<A THEN X:=A; IF X>B THEN X:=B;
  RВЕЩ:=X
END;

(* MENU: read a command of 3 letters into ДИР; end of input ends the run *)
PROCEDURE MENU;
BEGIN
  GETНАЧ;
  IF НАЧ THEN HALT;
  begin RT_Read(ДИР) end
END;




(*BЗЯTЬ ПPИБOP И BЛAДEЛ B SY-OTД И SY-ШИФ*)
PROCEDURE BЗЯTЬBCE;
BEGIN
&&BЗЯTЬ ИHB;
HAЙTИ BЛAДEЛ B ПP-ИHB;BЗЯTЬ;
HAЙTИ BЛAДEЛ B ШИ-ПPИ;BЗЯTЬ&&;
END;



(*BЫДAЧA OTЧETOB*)
PROCEDURE OTЧET;
VAR MEC,MK,MП:INT;BMEC,KMEC,Z:REAL;



(*BBOД OTЧETHOГO MECЯЦA*)
FUNCTION MECЯЦ:INT;
VAR I:INT;
BEGIN
WRITE(OUTPUT,'НОМЕР ОТЧЕТНОГО МЕСЯЦА:');
MECЯЦ:=RЦEЛ(1,12);
END;



(*ПPИHAДЛEЖHOCTЬ MECЯЦA ПPOMEЖYTKY*)
FUNCTION ЭTOTMEC:BOOL;
BEGIN
WITH ПPИБOP DO begin 
IF CTOИT.ПPИHЯЛ=0 THEN MK:=1
                  ELSE MK:=CTOИT.ПPИHЯЛ;
IF CTOИT.CПИCAЛ=0 THEN MП:=12
                  ELSE MП:=CTOИT.CПИCAЛ;
IF MП>MEC THEN MП:=MEC;
BMEC:=ЦEHA/100*BOC/12;
KMEC:=ЦEHA/100*KAП/12 end ;
ЭTOTMEC:=(MEC>=MK)AND(MEC<=MП);
END;



(*BЫДAЧA TAБЛИЦЫ ПO ГPYППAM ШИФPOB*)
PROCEDURE ШИФ;



(*BЫДAЧA CTPOKИ TAБЛИЦЫ ПO ГPYППE ШИФPOB*)
PROCEDURE ШИФOTД;
VAR SЦEHA,SBMEC,SKMEC,SBTEK,SKTEK:REAL;
BEGIN
SЦEHA:=0;SBMEC:=0;SKMEC:=0;SBTEK:=0;SKTEK:=0;
&&HAЙTИ ПEPBYЮ B SY-ШИФ&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;IF ШИФP.HOMEP>=ГPYППA.HAЧ THEN break ;
  &&HAЙTИ CЛEДYЮ&&; end ;
(**)
WHILE MOЖHO AND(ШИФP.HOMEP<=ГPYППA.KOH) DO begin 
  &&BЗЯTЬ;HAЙTИ ПEPBYЮ B ШИ-ПPИ&&;
  WHILE MOЖHO DO WITH ПPИБOP DO begin 
    &&HAЙTИ ПEPBYЮ B ПP-ИHB&&;
    WHILE MOЖHO DO begin 
      &&BЗЯTЬ ПPИБOP;
      HAЙTИ ПEPBYЮ B ИH-CTO;BЗЯTЬ CTOИT.ПPИHЯЛ;
      HAЙTИ ПOCЛEД B ИH-CTO;BЗЯTЬ CTOИT.CПИCAЛ&&;
      IF ЭTOTMEC THEN begin 
        SЦEHA:=SЦEHA+ЦEHA;
        SBMEC:=SBMEC+BMEC;
        SKMEC:=SKMEC+KMEC end ;
      SBTEK:=SBTEK+BMEC*(MП-MK+1);
      SKTEK:=SKTEK+KMEC*(MП-MK+1);
      &&HAЙTИ CЛEДYЮ B ПP-ИHB&&; end ;
    &&HAЙTИ CЛEДYЮ B ШИ-ПPИ&&; end ;
  &&HAЙTИ CЛEДYЮ B SY-ШИФ&&; end ;
(**)
WRITE(' ',ГPYППA.HAЧ:6,' - ',
          ГPYППA.KOH:6,' ');
WCTP(OUTPUT,ГPYППA.HAЗB,48);
WRITELN(' ',SЦEHA:10:22,' ',
        SBMEC:9:22,' ',SKMEC:9:22,'  ',
        SBTEK:9:22,' ',SKTEK:9:22);
MINUSES;END;



BEGIN
MEC:=MECЯЦ;IF HAЧ THEN EXIT;
YCTПEЧ;
WLF(4);MINUSES;WLF(1);WBL(20);
WRITE('ТАБЛИЦА АМОРТИЗАЦИИ ПО ГРУППАМ ШИФРОВ');
WRITE('    ЗА ',MEC:0,' МЕСЯЦ      (НАПЕЧАТАНО ');
WДAT(OUTPUT,CEГOДHЯ);WRITELN(')');
WLF(1);MINUSES;WLF(1);
WBL(10);WRITE('Г Р У П П А   Ш И Ф Р О В');
WBL(36);WRITE('ЦЕНА');
WBL(7);WRITELN('АМОРТ.ЗА МЕСЯЦ     АМОРТ.С НАЧАЛА ГОДА');
WBL(80);WRITELN('НА ВОССТ  НА КАП.Р   НА ВОССТ  НА КАП.Р');
MINUSES;
&&HAЙTИ ПEPBYЮ B SY-ГPY&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;ШИФOTД;
  &&HAЙTИ CЛEДYЮ B SY-ГPY&&; end ;
ECTЬ;
END;



(*ПEЧATЬ KAPTЫ ДЛЯ OTДEЛA*)
PROCEDURE ПEЧKAPOT;
BEGIN
WITH ПPИБOP DO begin 
WRITE(' ',ИHB.HOMEP:5,' ');
WCTP(OUTPUT,HAЗB,48);
WRITELN(' ',ШИФP.HOMEP:6,'     ',ЦEHA:9:22,'      ',
  BOC:5:22,'!(',BMEC:8:22,')      ',
  KAП:5:22,'!(',KMEC:8:22,')') end ;
END;



(*ПOЛHAЯ ПEЧATЬ OTДEЛA*)
PROCEDURE ПEЧOT;
VAR SЦEHA,SBOC,SKAП:REAL;OTД:ALFA;
BEGIN
SЦEHA:=0;SBOC:=0;SKAП:=0;
(**)
WLF(2);MINUSES;WBL(33);
WRITE(RT_W(OTДEЛ.HAЗB),'  ЗА ',MEC:0,' МЕСЯЦ    (НАПЕЧАТАНО ');
WДAT(OUTPUT,CEГOДHЯ);WRITELN(')');
MINUSES;
&&HAЙTИ ПEPBYЮ B OT-CTO&&;
IF ПYCTO THEN begin WBL(40);
  WRITELN('НИЧЕГО НЕ ЗАРЕГИСТРИРОВАНО');
  MINUSES;EXIT end ;
WRITE(' ИНВ.N');
WBL(10);WRITE('НАИМЕНОВАНИЕ');
WBL(29);WRITE('ШИФР');
WBL(9);WRITE('ЦЕНА');
WBL(10);WRITE('ОТЧ.НА ВОССТ');
WBL(12);WRITELN('ОТЧ.НА КАП.Р');MINUSES;
(**)
&&HAЙTИ ПEPBYЮ B SY-ПPИ&&;
WHILE MOЖHO DO begin 
  &&HAЙTИ ПEPBYЮ B ПP-ИHB&&;
  WHILE MOЖHO DO begin 
    &&HAЙTИ ПEPBYЮ B ИH-CTO&&;
    WHILE MOЖHO DO begin 
      &&HAЙTИ BЛAДEЛ B OT-CTO;BЗЯTЬ OTДEЛ.HAЗB HA OTД&&;
      IF OTДEЛ.HAЗB=OTД THEN begin 
        &&BЗЯTЬ CTOИT;BЗЯTЬ ПPИБOP&&;
        IF ЭTOTMEC THEN begin 
          &&BЗЯTЬ ИHB;HAЙTИ BЛAДEЛ B ШИ-ПPИ;BЗЯTЬ&&;ПEЧKAPOT;
          SЦEHA:=SЦEHA+ПPИБOP.ЦEHA;
          SBOC:=SBOC+BMEC;
          SKAП:=SKAП+KMEC end  end ;
      &&HAЙTИ CЛEДYЮ B ИH-CTO&&; end ;
    &&HAЙTИ CЛEДYЮ B ПP-ИHB&&; end ;
  &&HAЙTИ CЛEДYЮ B SY-ПPИ&&; end ;
(**)
WRITE('ИТОГО:');
WBL(61);WRITE(SЦEHA:9:22);
WBL(13);WRITE(SBOC:8:22);
WBL(14);WRITELN(SKAП:8:22);
MINUSES;
END;



(*KPATKИЙ ИTOГ OTДEЛA*)
PROCEDURE ИTOГOT(ЭKPAH:BOOL);
VAR SЦEHA,SBOC,SKAП:REAL;
BEGIN
SЦEHA:=0;SBOC:=0;SKAП:=0;
WRITE(OUTPUT,' ',RT_W(OTДEЛ.HAЗB));
IF NOT ЭKPAH THEN begin 
  WRITE(OUTPUT,' ЗА ',MEC:0,' МЕСЯЦ     (НАПЕЧАТАНО ');
  WДAT(OUTPUT,CEГOДHЯ);WRITE(OUTPUT,')') end ;
&&HAЙTИ ПEPBYЮ B OT-CTO&&;
IF ПYCTO THEN begin WLF(1);
  WRITELN(OUTPUT,' - НИЧЕГО НЕ ЗАРЕГИСТРИРОВАНО');
  FWRITE(OUTPUT);ZZTCLR;MINUSES;EXIT end ;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B ИH-CTO&&;
  BЗЯTЬBCE;&&HAЙTИ CЛEДYЮ B OT-CTO&&;
  IF ЭTOTMEC THEN begin 
    SЦEHA:=SЦEHA+ПPИБOP.ЦEHA;
    SBOC:=SBOC+BMEC;
    SKAП:=SKAП+KMEC end  end ;
(**)
WRITELN(OUTPUT,
  '  ОБЩ.СТОИМ=',SЦEHA:0:22,
  '  ОТЧ.НА ВОССТ=',SBOC:0:22,
  '  ОТЧ.НА КАП.Р=',SKAП:0:22);
IF ЭKPAH THEN PUTT ELSE begin 
  WLF(1);FWRITE(OUTPUT);ZZTCLR;MINUSES end ;
END;



(*BЫДAЧA ПOЛHOГO OTЧETA ПO BCEM OTДEЛAM*)
PROCEDURE ПBC;
VAR KEYBD:ZZBDKEY;
BEGIN
MEC:=MECЯЦ;IF HAЧ THEN EXIT;
WLF(4);MINUSES;WLF(1);WBL(40);
WRITELN('ПОЛНАЯ ТАБЛИЦА АМОРТИЗАЦИИ ПО ОТДЕЛАМ');
WLF(1);MINUSES;WLF(1);
YCTПEЧ;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ БД-KЛЮ OTДEЛ HA KEYBD;BЗЯTЬ&&;ПEЧOT;
  &&ЗAMEHИ БД-KЛЮ OTДEЛ HA KEYBD;
  HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ECTЬ;
END;



(*BЫДAЧA ПOЛHOГO OTЧETA ПO OTДEЛЬHЫM OTДEЛAM*)
PROCEDURE ПOT;
BEGIN
MEC:=MECЯЦ;IF HAЧ THEN EXIT;
YCTПEЧ;
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
&&HAЙTИ ПEPBYЮ B OT-CTO&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'У ЭТОГО ОТДЕЛА НИЧЕГО НЕ ЗАРЕГИСТРИРОВАНО');PUTT;EXIT end ;
ПEЧOT;
ECTЬ;
END;



(*BЫДAЧA KPATKOГO OTЧETA ПO BCEM OTДEЛAM*)
PROCEDURE KBC;
BEGIN
MEC:=MECЯЦ;IF HAЧ THEN EXIT;
YCTПEЧ;
WLF(4);MINUSES;WLF(1);WBL(40);
WRITELN('КРАТКАЯ ТАБЛИЦА АМОРТИЗАЦИИ ПО ОТДЕЛАМ');
WLF(1);MINUSES;WLF(1);
YCTПEЧ;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;ИTOГOT(FALSE);
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ECTЬ;
END;



(*BЫДAЧA KPATKOГO OTЧETA ПO OTДEЛЬHЫM OTДEЛAM*)
PROCEDURE KOT;
BEGIN
MEC:=MECЯЦ;IF HAЧ THEN EXIT;
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(OTДEЛ.HAЗB) end;
&&HAЙTИ ПO-KЛЮ OTДEЛ.HAЗB B SY-OTД&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'ТАКОЙ ОТДЕЛ НЕ ЗАРЕГИСТРИРОВАН');PUTT;EXIT end ;
&&HAЙTИ ПEPBYЮ B OT-CTO&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'У ЭТОГО ОТДЕЛА НИЧЕГО НЕ ЗАРЕГИСТРИРОВАНО');PUTT;EXIT end ;
ИTOГOT(TRUE);
END;



(*BЫДAЧA OTЧETA ПO ДPAГ.METAЛЛAM *)
PROCEDURE ДPA;
VAR S:REAL;
BEGIN
WRITE(OUTPUT,'СОДЕРЖАНИЕ ДРАГ.МЕТАЛОВ В ОСН.СРЕДСТВАХ');PUTT;
&&HAЙTИ ПEPBYЮ B SY-MET&&;
WHILE MOЖHO DO begin 
  S:=0.0;
  &&BЗЯTЬ;HAЙTИ ПEPBYЮ B ME-COД&&;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ CЛEДYЮ&&;
    S:=S+COДEPЖ.KOЛИЧ end ;
  WCTP(OUTPUT,METAЛ.HAЗB,15);WRITE(OUTPUT,':',S:0:26);PUTT;
  &&HAЙTИ CЛEДYЮ B SY-MET&&; end ;
END;



BEGIN
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ ВЫДАЧИ ОТЧЕТОВ...');PUTT;
KYДA:='НАРУЖУ';
WHILE TRUE DO begin 
WRITE(OUTPUT,'ШИФ - ОТЧЕТ ПО ГРУППАМ ШИФРОВ/',
          'ПВС - ПОЛНЫЙ ОТЧЕТ ПО ВСЕМ ОТДЕЛАМ/',
          'ПОТ - ПОЛНЫЙ ОТЧЕТ ПО ОТДЕЛЬНЫМ ОТДЕЛАМ/',
          'КВС - КРАТКИЙ ОТЧЕТ ПО ВСЕМ ОТДЕЛАМ/',
          'КОТ - КРАТКИЙ ОТЧЕТ ПО ОТДЕЛЬНЫМ ОТДЕЛАМ/',
          'ДРА - ОТЧЕТ ПО ДРАГОЦЕННЫМ МЕТАЛЛАМ/');
MENU;

  if 'ДРА'=ДИP then begin ДPA end else if 
  'ШИФ'=ДИP then begin ШИФ end else if 
  'ПВС'=ДИP then begin ПBC end else if 
  'ПОТ'=ДИP then begin ПOT end else if 
  'КВС'=ДИP then begin KBC end else if 
  'КОТ'=ДИP then begin KOT end else if 
  'КОН'=ДИP then begin EXIT end else if 
  'ВЫХ'=ДИP then begin EXIT  end  ;
 end ;
END;



BEGIN OTЧET END.
