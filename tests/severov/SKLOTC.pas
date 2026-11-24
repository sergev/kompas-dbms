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
  ФЛАГ=(ФS,ПЕЧАТЬ,МОДИФ,АДМИН,ОТЛАД,ОТЧСКЛ,ОТЧОТД,ВХОД,ФF); const XEN_Q64_Q53_AQ43_: array[Q64_Q53_AQ43_] of string[8] = ('ФS','ПЕЧАТЬ','МОДИФ','АДМИН','ОТЛАД','ОТЧСКЛ','ОТЧОТД','ВХОД','ФF'); type
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
WBL(50);WRITE('HAПEЧATAHO ');WДAT(OUTPUT,CEГOДHЯ);WRITELN;
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
    WRITE(OUTPUT,'HE OЦEHEHЫ CЛEДYЮЩИE HOMEPA:');PUTT end ;
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
WRITE(RT_W(OTДEЛ.HAЗB),'   OTЧET C ');WДAT(OUTPUT,KN_SYSTEM.ДATЧИC);
WRITE(' ПO ');WДAT(OUTPUT,CEГOДHЯ);WRITELN;MINUSES;
(**)
S:=0.0;
&&HAЙTИ ПEPBYЮ B OT-CYM&&;
 WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-CYM;BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
  SM:=CYMMA.ЦEHA;
  WCTP(OUTPUT,MATEP.HAЗB,15);
  WRITE(': C HAЧAЛA ГOДA ДO OTЧETHOГO ПEPИOДA',
        ' BЗЯTO HA CYMMY=',CYMMA.ЦEHA:8:22);
  IF ПYCTO THEN begin 
    WRITELN(', B OTЧETHЫЙ ПEPИOД HИЧEГO HE БPAЛИ');
    MINUSES end 
  ELSE begin 
    WLF(2);
    WRITE(' HOMEP');
    WBL(13);WRITE('HAИMEHOBAHИE');
    WBL(25);WRITE('EД.ИЗM.');
    WBL(4);WRITE('ЦEHA');
    WBL(4);WRITE('KOЛ-BO');
    WBL(4);WRITELN('CYMMA');WLF(1);
    (**)
    WHILE MOЖHO DO begin 
      &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ;HAЙTИ CЛEДYЮ B CY-BЗЯ&&;
      SM:=SM+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ;ПEЧKAPOT end ;
    WLF(1);WRITE(' ИTOГO:');
    WBL(74);WRITELN(SM:9:22);MINUSES end ;
  S:=S+SM;
  &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
WRITE(' ИTOГ ПO BCEM MATEPИAЛAM');WBL(57);WRITELN(S:9:22);MINUSES;
END;



(*KPATKИЙ ИTOГ OTДEЛA*)
PROCEDURE ИTOГOT;
VAR S,SM:REAL;
BEGIN
WLF(2);MINUSES;WBL(33);
WRITE(RT_W(OTДEЛ.HAЗB),'   OTЧET C ');WДAT(OUTPUT,KN_SYSTEM.ДATЧИC);
WRITE(' ПO ');WДAT(OUTPUT,CEГOДHЯ);WLF(2);
(**)
S:=0.0;
&&HAЙTИ ПEPBYЮ B OT-CYM&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-CYM;BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
  WCTP(OUTPUT,MATEP.HAЗB,15);
  WRITE(': C HAЧAЛA ГOДA ДO OTЧETHOГO ПEPИOДA',
        ' BЗЯTO HA ',CYMMA.ЦEHA:8:22);
  SM:=0.0;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ;HAЙTИ CЛEДYЮ B CY-BЗЯ&&;
    SM:=SM+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ end ;
  WRITE(' B OTЧETHЫЙ ПEPИOД BЗЯTO HA ',SM:9:22);
  WRITELN(' ИTOГO:',SM+CYMMA.ЦEHA:9:22);S:=S+SM+CYMMA.ЦEHA;
  &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
WLF(1);WRITE(' OБЩИЙ ИTOГ:');WBL(101);WRITELN(S:9:22);MINUSES;
END;



(*KPATKИЙ ИTOГ OTДEЛA HA ЭKPAH*)
PROCEDURE ИTOГOTЭ;
VAR S,SM:REAL;
BEGIN
WRITE(OUTPUT,'   ',RT_W(OTДEЛ.HAЗB),'   OTЧET C ');WДAT(OUTPUT,KN_SYSTEM.ДATЧИC);
WRITE(OUTPUT,' ПO ');WДAT(OUTPUT,CEГOДHЯ);PUTT;
(**)
S:=0.0;
&&HAЙTИ ПEPBYЮ B OT-CYM&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-CYM;BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
  WCTP(OUTPUT,MATEP.HAЗB,13);
  WRITE(OUTPUT,':ДO ЧИCTKИ=',CYMMA.ЦEHA:8:22);
  SM:=0.0;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ;HAЙTИ CЛEДYЮ B CY-BЗЯ&&;
    SM:=SM+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ end ;
  WRITE(OUTPUT,'   ПOCЛE ЧИCTKИ=',SM:8:22);
  WRITELN(OUTPUT,'   ИTOГO=',SM+CYMMA.ЦEHA:9:22);PUTT;S:=S+SM+CYMMA.ЦEHA;
  &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
WRITE(OUTPUT,'   OБЩИЙ ИTOГ:                                ',
          '                    ',S:8:22);PUTT;
END;



(*BЫДAЧA ПOЛHOГO OTЧETA ПO BCEM OTДEЛAM*)
PROCEDURE ПBC;
BEGIN
WRITE(OUTPUT,'ПOЛHAЯ TAБЛИЦA MATEPИAЛOB ПO OTДEЛAM');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;ПEЧOT;
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ФЛAГИ:=ФЛAГИ+[OTЧOTД];YCTMOД;ECTЬ;
END;



(*BЫДAЧA ПOЛHOГO OTЧETA ПO OTДEЛЬHЫM OTДEЛAM*)
PROCEDURE ПOT;
BEGIN
WRITE(OUTPUT,'HAЗBAHИE OTДEЛA:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
YCTПEЧ;
ПEЧOT;ECTЬ;
END;



(*BЫДAЧA KPATKOГO OTЧETA ПO BCEM OTДEЛAM*)
PROCEDURE KBC;
BEGIN
YCTПEЧ;
WRITE(OUTPUT,'KPATKAЯ TAБЛИЦA MATEPИAЛOB ПO OTДEЛAM');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;ИTOГOT;
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ФЛAГИ:=ФЛAГИ+[OTЧOTД];YCTMOД;ECTЬ;
END;



(*BЫДAЧA KPATKOГO OTЧETA ПO OTДEЛЬHЫM OTДEЛAM*)
PROCEDURE KOT;
BEGIN
WRITE(OUTPUT,'HAЗBAHИE OTДEЛA:');OTДEЛ.HAЗB:=ROTД;
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
WRITE(OUTPUT,'TAБЛИЦA MATEPИAЛOB ПO CKЛAДY (ДBИЖEHИE)');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-ДBИ&&;
IF ПYCTO THEN begin WBL(55);WRITELN('HET KAPT');EXIT end ;
    WRITE(' HOMEP');
    WBL(13);WRITE('HAИMEHOBAHИE');
    WBL(11);WRITE('EД.ИЗM.');
    WBL(1);WRITE('ЦEHA');
    WBL(7);WRITE('ПPИXOД');
    WBL(14);WRITE('PACXOД');
    WBL(15);WRITE('OCTATOK');
    WBL(11);WRITELN('BИД');MINUSES;
REPEAT
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;ПEЧKAPДB;
  &&HAЙTИ CЛEДYЮ B SY-ДBИ&&;
UNTIL ПYCTO;
(**)
WLF(3);MINUSES;WBL(43);
WRITELN('TAБЛИЦA "ЧTO БPAЛИ OTДEЛЫ"');
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
WRITE(OUTPUT,'ПOЛHAЯ TAБЛИЦA MATEPИAЛOB ПO CKЛAДY');ШAПKA;
&&HAЙTИ ПEPBYЮ B SY-BEЩ&&;
IF ПYCTO THEN begin WBL(55);WRITELN('HET KAPT');EXIT end ;
    WRITE(' HOMEP');
    WBL(13);WRITE('HAИMEHOBAHИE');
    WBL(11);WRITE('EД.ИЗM.');
    WBL(1);WRITE('ЦEHA');
    WBL(7);WRITE('ПPИXOД');
    WBL(14);WRITE('PACXOД');
    WBL(15);WRITE('OCTATOK');
    WBL(11);WRITELN('BИД');MINUSES;
REPEAT
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;ПEЧKAPДB;
  &&HAЙTИ CЛEДYЮ B SY-BEЩ&&;
UNTIL ПYCTO;
(**)
WLF(3);MINUSES;WBL(43);
WRITELN('TAБЛИЦA "ЧTO БPAЛИ OTДEЛЫ"');
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
WRITE(OUTPUT,'И T O Г    П O    C K Л A Д Y');ШAПKA;
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
  WRITE(OUTPUT,'  ПPИXOД=',SПM:9:22,
            '  PACXOД=',SPM:9:22,
            '  OCTATOK=',SOM:9:22);
  FWRITE(OUTPUT);MINUSES;PUTT;
  SП:=SП+SПM;
  SP:=SP+SPM;
  SO:=SO+SOM;
  &&HAЙTИ CЛEДYЮ B SY-MAT&&; end ;
WRITE(OUTPUT,'   OБЩИЙ ИTOГ:',
          '  ПPИXOД=',SП:9:22,
          '  PACXOД=',SP:9:22,
          '  OCTATOK=',SO:9:22);
FWRITE(OUTPUT);MINUSES;PUTT;
END;



BEGIN
WRITE(OUTPUT,'      ...BЫ B БЛOKE BЫДAЧИ OTЧETOB...');PUTT;
KYДA:='HAPYЖY';
IF NOT OЦEHEHO THEN begin 
  WRITE(OUTPUT,'OTЧETЫ БYДYT HE BEPHЫ ???');
  PUTT;PUTT; end ;
WHILE TRUE DO begin 
WRITE(OUTPUT,'ДBИ - OTЧET ПO ДBИЖEHИЮ HA CKЛAДE/',
          'BCE - ПOЛHЫЙ OTЧET ПO CKЛAДY/',
          'ИTO - TEKYЩИЙ ИTOГ ПO CKЛAДY/',
          'ПBC - ПOЛHЫЙ OTЧET ПO BCEM OTДEЛAM/',
          'ПOT - ПOЛHЫЙ OTЧET ПO OTДEЛЬHЫM OTДEЛAM/',
          'KBC - KPATKИЙ OTЧET ПO BCEM OTДEЛAM/',
          'KOT - KPATKИЙ OTЧET ПO OTДEЛЬHЫM OTДEЛAM/');
MENU;

  if 'ИTO'=ДИP then begin ИTO end else if 
  'BCE'=ДИP then begin BCEBCE end else if 
  'ДBИ'=ДИP then begin ДBИ end else if 
  'ПBC'=ДИP then begin ПBC end else if 
  'ПOT'=ДИP then begin ПOT end else if 
  'KBC'=ДИP then begin KBC end else if 
  'KOT'=ДИP then begin KOT end else if 
  'KOH'=ДИP then begin EXIT end else if 
  'BЫX'=ДИP then begin EXIT  end  ;
 end ;
END.
.
DRUM
ШИФP 410900 ЗMП^OЗY 32^TPA 88^BPE 1000^ЛEH 31(2)41(2)^EEB1A3
