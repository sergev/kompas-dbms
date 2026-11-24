{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM SKLOTC; uses krt, kio, mars, kdb, sevlib; (*CK:OTЧET *)
&&ПOДCXE CX-CK0&&(**)
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

(* STPUT: end of a listed line; true would stop the listing *)
FUNCTION STPUT: BOOLEAN; BEGIN WRITELN; STPUT:=FALSE END;

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

(* MENU: read a command of 3 letters into ДИР; end of input ends the run *)
PROCEDURE MENU;
BEGIN
  GETНАЧ;
  IF НАЧ THEN HALT;
  begin RT_Read(ДИР) end
END;




(*ИHB.HOM. INT --> REAL *)
FUNCTION ЦB(I:INT):REAL;
BEGIN ЦB:=I/1000 END;

(*ИHB.HOM. REAL --> INT *)
FUNCTION BЦ(R:REAL):INT;
BEGIN BЦ:=ROUND(R*1000) END;



(*BЫBOД ШAПKИ*)
PROCEDURE ШAПKA;
VAR I:INT;F:TEXT;
BEGIN
FCOPY(F,OUTPUT);begin if RT_First(@F) then assign(F, RT_TmpName); RESET(F) end;ZZTCLR;I:=0;
WHILE NOT EOF(F) DO begin I:=I+1;RT_GetC(F) end ;
I:=(128-I) DIV 2;
YCTПEЧ;WLF(4);MINUSES;WLF(1);WBL(I);FWRITE(F);
WLF(2);MINUSES;
WBL(50);WRITE('НАПЕЧАТАНО ');WДAT(OUTPUT,CEГOДHЯ);WRITELN;
MINUSES;WLF(1);
END;



FUNCTION OЦEHEHO:BOOL;
VAR HAШЛИ:BOOL;I:INT;
BEGIN
I:=0;HAШЛИ:=FALSE;OЦEHEHO:=TRUE;ШAГ:=1;
&&HAЙTИ ПEPBYЮ B SY-БEЗ&&;
 WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ CЛEДYЮ&&;
  IF NOT HAШЛИ THEN begin 
    OЦEHEHO:=FALSE;HAШЛИ:=TRUE;
    WRITE(OUTPUT,'НЕ ОЦЕНЕНЫ СЛЕДУЮЩИЕ НОМЕРА:');PUTT end ;
  WRITE(OUTPUT,' ',ЦB(BEЩЬ.HOMEP):9:23);I:=I+1;
  IF (I MOD 13)=0 THEN IF STPUT THEN break  end ;
IF (I MOD 13)<>0 THEN PUTT;
END;



(*ПEЧATЬ KAPTЫ ДЛЯ OTДEЛA*)
PROCEDURE ПEЧKAPOT;
BEGIN
WITH BEЩЬ DO begin 
WRITE(' ',ЦB(HOMEP):9:23,'   ');
WCTP(OUTPUT,BEЩЬ.HAЗB,44);
WRITE(' ',RT_W(EД[1]),RT_W(EД[2]),'      ');
IF ЦEHA>0.0001 THEN WRITE(ЦEHA:5:22)
               ELSE WRITE('!!!!!');
WRITELN('   ',BЗЯЛ.KOЛИЧ:9:23,'   ',ЦEHA*BЗЯЛ.KOЛИЧ:8:22) end ;
END;



(*ПOЛHAЯ ПEЧATЬ OTДEЛA*)
PROCEDURE ПEЧOT;
VAR S,SM:REAL;
BEGIN
WLF(2);MINUSES;WBL(33);
WRITE(RT_W(OTДEЛ.HAЗB),'   ОТЧЕТ С ');WДAT(OUTPUT,KN_SYSTEM.ДATЧИC);
WRITE(' ПО ');WДAT(OUTPUT,CEГOДHЯ);WRITELN;MINUSES;
(**)
S:=0.0;
&&HAЙTИ ПEPBYЮ B OT-CYM&&;
 WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-CYM;BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
  SM:=CYMMA.ЦEHA;
  WCTP(OUTPUT,MATEP.HAЗB,15);
  WRITE(': С НАЧАЛА ГОДА ДО ОТЧЕТНОГО ПЕРИОДА',
        ' ВЗЯТО НА СУММУ=',CYMMA.ЦEHA:8:22);
  IF ПYCTO THEN begin 
    WRITELN(', В ОТЧЕТНЫЙ ПЕРИОД НИЧЕГО НЕ БРАЛИ');
    MINUSES end 
  ELSE begin 
    WLF(2);
    WRITE(' НОМЕР');
    WBL(13);WRITE('НАИМЕНОВАНИЕ');
    WBL(25);WRITE('ЕД.ИЗМ.');
    WBL(4);WRITE('ЦЕНА');
    WBL(4);WRITE('КОЛ-ВО');
    WBL(4);WRITELN('СУММА');WLF(1);
    (**)
    WHILE MOЖHO DO begin 
      &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ;HAЙTИ CЛEДYЮ B CY-BЗЯ&&;
      SM:=SM+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ;ПEЧKAPOT end ;
    WLF(1);WRITE(' ИТОГО:');
    WBL(74);WRITELN(SM:9:22);MINUSES end ;
  S:=S+SM;
  &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
WRITE(' ИТОГ ПО ВСЕМ МАТЕРИАЛАМ');WBL(57);WRITELN(S:9:22);MINUSES;
END;



(*KPATKИЙ ИTOГ OTДEЛA*)
PROCEDURE ИTOГOT;
VAR S,SM:REAL;
BEGIN
WLF(2);MINUSES;WBL(33);
WRITE(RT_W(OTДEЛ.HAЗB),'   ОТЧЕТ С ');WДAT(OUTPUT,KN_SYSTEM.ДATЧИC);
WRITE(' ПО ');WДAT(OUTPUT,CEГOДHЯ);WLF(2);
(**)
S:=0.0;
&&HAЙTИ ПEPBYЮ B OT-CYM&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-CYM;BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
  WCTP(OUTPUT,MATEP.HAЗB,15);
  WRITE(': С НАЧАЛА ГОДА ДО ОТЧЕТНОГО ПЕРИОДА',
        ' ВЗЯТО НА ',CYMMA.ЦEHA:8:22);
  SM:=0.0;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ;HAЙTИ CЛEДYЮ B CY-BЗЯ&&;
    SM:=SM+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ end ;
  WRITE(' В ОТЧЕТНЫЙ ПЕРИОД ВЗЯТО НА ',SM:9:22);
  WRITELN(' ИТОГО:',SM+CYMMA.ЦEHA:9:22);S:=S+SM+CYMMA.ЦEHA;
  &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
WLF(1);WRITE(' ОБЩИЙ ИТОГ:');WBL(101);WRITELN(S:9:22);MINUSES;
END;



(*KPATKИЙ ИTOГ OTДEЛA HA ЭKPAH*)
PROCEDURE ИTOГOTЭ;
VAR S,SM:REAL;
BEGIN
WRITE(OUTPUT,'   ',RT_W(OTДEЛ.HAЗB),'   ОТЧЕТ С ');WДAT(OUTPUT,KN_SYSTEM.ДATЧИC);
WRITE(OUTPUT,' ПО ');WДAT(OUTPUT,CEГOДHЯ);PUTT;
(**)
S:=0.0;
&&HAЙTИ ПEPBYЮ B OT-CYM&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-CYM;BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
  WCTP(OUTPUT,MATEP.HAЗB,13);
  WRITE(OUTPUT,':ДО ЧИСТКИ=',CYMMA.ЦEHA:8:22);
  SM:=0.0;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ;HAЙTИ CЛEДYЮ B CY-BЗЯ&&;
    SM:=SM+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ end ;
  WRITE(OUTPUT,'   ПОСЛЕ ЧИСТКИ=',SM:8:22);
  WRITELN(OUTPUT,'   ИТОГО=',SM+CYMMA.ЦEHA:9:22);PUTT;S:=S+SM+CYMMA.ЦEHA;
  &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
WRITE(OUTPUT,'   ОБЩИЙ ИТОГ:                                ',
          '                    ',S:8:22);PUTT;
END;



(*BЫДAЧA ПOЛHOГO OTЧETA ПO BCEM OTДEЛAM*)
PROCEDURE ПBC;
BEGIN
WRITE(OUTPUT,'ПОЛНАЯ ТАБЛИЦА МАТЕРИАЛОВ ПО ОТДЕЛАМ');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;ПEЧOT;
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ФЛAГИ:=ФЛAГИ+[OTЧOTД];YCTMOД;ECTЬ;
END;



(*BЫДAЧA ПOЛHOГO OTЧETA ПO OTДEЛЬHЫM OTДEЛAM*)
PROCEDURE ПOT;
BEGIN
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
YCTПEЧ;
ПEЧOT;ECTЬ;
END;



(*BЫДAЧA KPATKOГO OTЧETA ПO BCEM OTДEЛAM*)
PROCEDURE KBC;
BEGIN
YCTПEЧ;
WRITE(OUTPUT,'КРАТКАЯ ТАБЛИЦА МАТЕРИАЛОВ ПО ОТДЕЛАМ');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;ИTOГOT;
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ФЛAГИ:=ФЛAГИ+[OTЧOTД];YCTMOД;ECTЬ;
END;



(*BЫДAЧA KPATKOГO OTЧETA ПO OTДEЛЬHЫM OTДEЛAM*)
PROCEDURE KOT;
BEGIN
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');OTДEЛ.HAЗB:=ROTД;
IF HAЧ THEN EXIT;
ИTOГOTЭ;
END;



(*ПEЧATЬ ДBИГABШИXCЯ KAPT*)
PROCEDURE ПEЧKAPДB;
BEGIN
WITH BEЩЬ DO begin 
WRITE(' ',ЦB(HOMEP):9:23,') ');WCTP(OUTPUT,HAЗB,32);
WRITE(' ',RT_W(EД[1]),RT_W(EД[2]),'  ');
IF ЦEHA>0.0001 THEN WRITE(ЦEHA:5:22)
               ELSE WRITE('!!!!!');
WRITE('   ',ПPИXOД:9:23,'/',ПPИXOД*ЦEHA:8:22,
      '   ',PACXOД:9:23,'/',PACXOД*ЦEHA:8:22,
      '   ',OCTAT :9:23,'/',OCTAT *ЦEHA:8:22,' ');
WCTP(OUTPUT,MATEP.HAЗB,5) end ;WRITELN;
END;



PROCEDURE ПEЧPACX;
VAR I:INT;
BEGIN
I:=0;
&&BЗЯTЬ BEЩЬ&&;
WRITE(' ',ЦB(BEЩЬ.HOMEP):9:23,') ');
WHILE MOЖHO DO begin 
  I:=I+1;IF (((I-1) MOD 5)=0) AND (I>1) THEN WBL(7);
  &&BЗЯTЬ BЗЯЛ;HAЙTИ BЛAДEЛ B CY-BЗЯ;HAЙTИ BЛAДEЛ B OT-CYM;BЗЯTЬ&&;
  WRITE('   ',RT_W(OTДEЛ.HAЗB),'=',BЗЯЛ.KOЛИЧ:0:23,'/');
  IF BEЩЬ.ЦEHA<0.01 THEN WRITE('!!!!!')
          ELSE WRITE(BЗЯЛ.KOЛИЧ*BEЩЬ.ЦEHA:0:22);
  IF (I MOD 5)=0 THEN WRITELN;
  &&HAЙTИ CЛEДYЮ B BE-BЗЯ&&; end ;
IF (I MOD 5)<>0 THEN WRITELN;
END;



PROCEDURE ДBИ;
BEGIN
WRITE(OUTPUT,'ТАБЛИЦА МАТЕРИАЛОВ ПО СКЛАДУ (ДВИЖЕНИЕ)');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-ДBИ&&;
IF ПYCTO THEN begin WBL(55);WRITELN('НЕТ КАРТ');EXIT end ;
    WRITE(' НОМЕР');
    WBL(13);WRITE('НАИМЕНОВАНИЕ');
    WBL(11);WRITE('ЕД.ИЗМ.');
    WBL(1);WRITE('ЦЕНА');
    WBL(7);WRITE('ПРИХОД');
    WBL(14);WRITE('РАСХОД');
    WBL(15);WRITE('ОСТАТОК');
    WBL(11);WRITELN('ВИД');MINUSES;
REPEAT
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;ПEЧKAPДB;
  &&HAЙTИ CЛEДYЮ B SY-ДBИ&&;
UNTIL ПYCTO;
(**)
WLF(3);MINUSES;WBL(43);
WRITELN('ТАБЛИЦА "ЧТО БРАЛИ ОТДЕЛЫ"');
MINUSES;WLF(1);
&&HAЙTИ ПEPBYЮ B SY-ДBИ&&;
REPEAT
  &&HAЙTИ ПEPBYЮ B BE-BЗЯ&&;
  IF MOЖHO THEN ПEЧPACX;
  &&HAЙTИ CЛEДYЮ B SY-ДBИ&&;
UNTIL ПYCTO;
ФЛAГИ:=ФЛAГИ+[OTЧCKЛ];YCTMOД;ECTЬ;
END;



PROCEDURE BCEBCE;
BEGIN
WRITE(OUTPUT,'ПОЛНАЯ ТАБЛИЦА МАТЕРИАЛОВ ПО СКЛАДУ');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-BEЩ&&;
IF ПYCTO THEN begin WBL(55);WRITELN('НЕТ КАРТ');EXIT end ;
    WRITE(' НОМЕР');
    WBL(13);WRITE('НАИМЕНОВАНИЕ');
    WBL(11);WRITE('ЕД.ИЗМ.');
    WBL(1);WRITE('ЦЕНА');
    WBL(7);WRITE('ПРИХОД');
    WBL(14);WRITE('РАСХОД');
    WBL(15);WRITE('ОСТАТОК');
    WBL(11);WRITELN('ВИД');MINUSES;
REPEAT
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;ПEЧKAPДB;
  &&HAЙTИ CЛEДYЮ B SY-BEЩ&&;
UNTIL ПYCTO;
(**)
WLF(3);MINUSES;WBL(43);
WRITELN('ТАБЛИЦА "ЧТО БРАЛИ ОТДЕЛЫ"');
MINUSES;WLF(1);
&&HAЙTИ ПEPBYЮ B SY-ДBИ&&;
REPEAT
  &&HAЙTИ ПEPBYЮ B BE-BЗЯ&&;
  IF MOЖHO THEN ПEЧPACX;
  &&HAЙTИ CЛEДYЮ B SY-ДBИ&&;
UNTIL ПYCTO;
ФЛAГИ:=ФЛAГИ+[OTЧCKЛ];YCTMOД;ECTЬ;
END;



(*KPATKИЙ ИTOГ ПO CKЛAДY HA ЭKPAH*)
PROCEDURE ИTO;
 VAR SП,SP,SO,SПM,SPM,SOM:REAL;
BEGIN
WRITE(OUTPUT,'И Т О Г    П О    С К Л А Д У');ШAПKA;
SП:=0.0;SP:=0.0;SO:=0.0;
&&HAЙTИ ПEPBYЮ B SY-MAT&&;
WHILE MOЖHO DO begin 
SПM:=0.0;SPM:=0.0;SOM:=0.0;
  &&BЗЯTЬ;HAЙTИ ПEPBYЮ B MA-BEЩ&&;
  WCTP(OUTPUT,MATEP.HAЗB,13);WRITE(OUTPUT,':');
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ CЛEДYЮ B MA-BEЩ&&;
    SПM:=SПM+BEЩЬ.ЦEHA*BEЩЬ.ПPИXOД;
    SPM:=SPM+BEЩЬ.ЦEHA*BEЩЬ.PACXOД;
    SOM:=SOM+BEЩЬ.ЦEHA*BEЩЬ.OCTAT end ;
  WRITE(OUTPUT,'  ПРИХОД=',SПM:9:22,
            '  РАСХОД=',SPM:9:22,
            '  ОСТАТОК=',SOM:9:22);
  FWRITE(OUTPUT);MINUSES;PUTT;
  SП:=SП+SПM;
  SP:=SP+SPM;
  SO:=SO+SOM;
  &&HAЙTИ CЛEДYЮ B SY-MAT&&; end ;
WRITE(OUTPUT,'   ОБЩИЙ ИТОГ:',
          '  ПРИХОД=',SП:9:22,
          '  РАСХОД=',SP:9:22,
          '  ОСТАТОК=',SO:9:22);
FWRITE(OUTPUT);MINUSES;PUTT;
END;



BEGIN
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ ВЫДАЧИ ОТЧЕТОВ...');PUTT;
KYДA:='НАРУЖУ';
IF NOT OЦEHEHO THEN begin 
  WRITE(OUTPUT,'ОТЧЕТЫ БУДУТ НЕ ВЕРНЫ ???');
  PUTT;PUTT; end ;
WHILE TRUE DO begin 
WRITE(OUTPUT,'ДВИ - ОТЧЕТ ПО ДВИЖЕНИЮ НА СКЛАДЕ/',
          'ВСЕ - ПОЛНЫЙ ОТЧЕТ ПО СКЛАДУ/',
          'ИТО - ТЕКУЩИЙ ИТОГ ПО СКЛАДУ/',
          'ПВС - ПОЛНЫЙ ОТЧЕТ ПО ВСЕМ ОТДЕЛАМ/',
          'ПОТ - ПОЛНЫЙ ОТЧЕТ ПО ОТДЕЛЬНЫМ ОТДЕЛАМ/',
          'КВС - КРАТКИЙ ОТЧЕТ ПО ВСЕМ ОТДЕЛАМ/',
          'КОТ - КРАТКИЙ ОТЧЕТ ПО ОТДЕЛЬНЫМ ОТДЕЛАМ/');
MENU;

  if 'ИТО'=ДИP then begin ИTO end else if 
  'ВСЕ'=ДИP then begin BCEBCE end else if 
  'ДВИ'=ДИP then begin ДBИ end else if 
  'ПВС'=ДИP then begin ПBC end else if 
  'ПОТ'=ДИP then begin ПOT end else if 
  'КВС'=ДИP then begin KBC end else if 
  'КОТ'=ДИP then begin KOT end else if 
  'КОН'=ДИP then begin EXIT end else if 
  'ВЫХ'=ДИP then begin EXIT  end  ;
 end ;
END.
.
DRUM
ШИФP 410900 ЗMП^OЗY 32^TPA 88^BPE 1000^ЛEH 31(2)41(2)^EEB1A3
