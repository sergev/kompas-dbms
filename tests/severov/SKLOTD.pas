{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM SKLOTD; uses krt, kio, mars, kdb, sevlib; (*CK:OTДEЛЫ *)
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

(* УСТМОД: mark the database modified (stub) *)
PROCEDURE УСТМОД; BEGIN END;

(* ЕСТЬ: acknowledge (stub) *)
PROCEDURE ЕСТЬ; BEGIN END;

(* ПШИК: not used by the programs *)

(* MENU: read a command of 3 letters into ДИР; end of input ends the run *)
PROCEDURE MENU;
BEGIN
  GETНАЧ;
  IF НАЧ THEN HALT;
  begin RT_Read(ДИР) end
END;

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

(* STPUT: end of a listed line; true would stop the listing *)
FUNCTION STPUT: BOOLEAN; BEGIN WRITELN; STPUT:=FALSE END;




PROCEDURE ПPO;
VAR I:INT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'HET OTДEЛOB');PUTT;EXIT end ;
I:=0;ШAГ:=1;
REPEAT
  I:=I+1;&&BЗЯTЬ&&;
  WRITE(OUTPUT,I:3,') ',RT_W(OTДEЛ.HAЗB));
  &&HAЙTИ CЛEДYЮ B SY-OTД&&;
UNTIL STPUT OR ПYCTO;
END;



PROCEDURE HOB;
BEGIN
REPEAT
  WRITE(OUTPUT,'HAЗBAHИE OTДEЛA:');GETHAЧ;
  IF HAЧ THEN EXIT;
  begin RT_Read(OTДEЛ.HAЗB) end;
  &&HAЙTИ ПO-KЛЮ OTДEЛ.HAЗB B SY-OTД&&;
  IF ПYCTO THEN begin 
    &&ПOCTAB OTДEЛ;HAЙTИ ПEPBYЮ B SY-MAT&&;
    WHILE MOЖHO DO begin 
      CYMMA.ЦEHA:=0;
      &&ПOCTABИTЬ CYMMA;HAЙTИ CЛEДYЮ B SY-MAT&&; end ;
    YCTMOД end 
  ELSE begin WRITE(OUTPUT,'TAKOЙ OTДEЛ YЖE ЗAPEГИCTPИPOBAH');PUTT end ;
UNTIL NOT EЩE('EЩE!  ');
END;



PROCEDURE ЗAM;
VAR CTOT:ZZOTДEЛ;
BEGIN
WRITE(OUTPUT,'CTAPOE HAЗBAHИE OTДEЛA:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(CTOT.HAЗB) end;
&&HAЙTИ ПO-KЛЮ CTOT.HAЗB B SY-OTД&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'TAKOЙ OTДEЛ HE ЗAPEГИCTPИPOBAH');PUTT;EXIT end ;
WRITE(OUTPUT,'HOBOE HAЗBAHИE OTДEЛA:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(OTДEЛ.HAЗB) end;
&&HAЙTИ ПO-KЛЮ OTДEЛ.HAЗB B SY-OTД&&;IF COCT=0 THEN begin 
  WRITE(OUTPUT,'TAKOЙ OTДEЛ YЖE ЗAPEГИCTPИPOBAH');PUTT;EXIT end ;
&&HAЙTИ ПO-KЛЮ CTOT.HAЗB B SY-OTД&&;
&&ЗAMEHИTЬ&&;YCTMOД;ECTЬ;
END;



PROCEDURE ИCK;

BEGIN
WRITE(OUTPUT,'HAЗBAHИE OTДEЛA:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
WRITE(OUTPUT,'OTДEЛ ИCKЛЮЧAETCЯ BMECTE CO BCEЙ ИHФOPMAЦИEЙ O HEM');PUTT;
WRITE(OUTPUT,'ПOДTBEPДИTE ИCKЛЮЧEHИE');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ИCKЛЮЧEHИE OTMEHЯETCЯ');PUTT;EXIT end ;
YHAP(&&HAБ OT-CYM&&);
&&YБPATЬ OTДEЛ&&;YCTMOД;ECTЬ;
END;



BEGIN
WRITE(OUTPUT,'      ...BЫ B БЛOKE PEГИCTPAЦИИ OTДEЛOB...');PUTT;
KYДA:='HAPYЖY';
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПPO - ПPOCMOTP ЗAPEГИCTPИPOBAHHЫX OTДEЛOB/',
          'HOB - PEГИCTPAЦИЯ HOBЫX OTДEЛOB/',
          'ЗAM - ЗAMEHA HAЗBAHИЯ OTДEЛA/',
          'ИCK - ИCKЛЮЧEHИE OTДEЛA/');
MENU;

  if 'ПPO'=ДИP then begin ПPO end else if 
  'HOB'=ДИP then begin HOB end else if 
  'ЗAM'=ДИP then begin ЗAM end else if 
  'ИCK'=ДИP then begin ИCK end else if 
  'KOH'=ДИP then begin EXIT end else if 
  'BЫX'=ДИP then begin EXIT  end  ;
 end ;
END.
