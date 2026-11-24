{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM ZATCOF; uses krt, kio, mars, kdb, sevlib; (*ЗT:PEГИC.KOЭФФ*)
&&ПOДCXE CX-ЗT0&&(**)
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

(* CUTCTP: stub *)

(* WCTP: write a string without trailing blanks, in N positions *)


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

(* RCTP: ask for a string; the program reads it *)
PROCEDURE RCTP; BEGIN GETНАЧ END;

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

(* FПАР: find the parameter A of the system *)
PROCEDURE FПАР(A: ALFA);
BEGIN &&НАЙТИ ПО-КЛЮ A В SY-ПАР&&; END;

(* STEP: end of a listed line; true would stop the listing *)
FUNCTION STEP: BOOLEAN; BEGIN WRITELN; STEP:=FALSE END;

(* ТОЛЬКОСИ: system block only (stub: no) *)
FUNCTION ТОЛЬКОСИ: BOOLEAN; BEGIN ТОЛЬКОСИ:=FALSE END;




(*PEГИCTPAЦИЯ KOЭФФИЦИEHTOB И OTДEЛЬHЫX ПAPAMETPOB*)
PROCEDURE PEKOЭФ;
VAR Д:ДИPEKT;



(*ПEЧATЬ KOЭФФИЦИEHTA*)
PROCEDURE ПEЧKOЭФ;
BEGIN
WRITE(OUTPUT,RT_W(ПAP.ИMЯ),':');WCTP(OUTPUT,ПAP.HAЗB,32);
WRITE(OUTPUT,' = ',ДEЙ.ЗH:8:23);
PUTT;
END;



PROCEDURE ПPO;
VAR I,J:INT;A:ARRAY [1..100 ] OF ALFA;
BEGIN
FПAP('ИM-KOЭ');&&HAЙTИ ПEPBYЮ B ПA-AЛФ&&;
IF ПYCTO THEN begin WRITE(OUTPUT,'HET KAPT');PUTT;EXIT end ;
I:=0;WHILE MOЖHO DO begin I:=I+1;&&BЗЯTЬ AЛФ.ЗH HA A[I];HAЙTИ CЛEДYЮ&&; end ;
J:=1;ШAГ:=1;
REPEAT
  FПAP(A[J]);&&HAЙTИ ПEPBYЮ B ПA-ДEЙ;
  BЗЯTЬ ПAP;BЗЯTЬ ДEЙ&&;ПEЧKOЭФ;J:=J+1;
UNTIL STEP OR (J>I);
END;



PROCEDURE HOB;
VAR I:INT;
BEGIN
IF TOЛЬKOCИ THEN EXIT;
REPEAT
REPEAT
  WRITE(OUTPUT,'COKPAЩEHHOE HAЗBAHИE:');GETHAЧ;
  IF HAЧ THEN EXIT;
  begin RT_Read(ПAP.ИMЯ) end;FПAP(ПAP.ИMЯ);
  IF MOЖHO THEN begin WRITE(OUTPUT,'ЭTO HAЗBAHИE YЖE ЗAPEГИCTPИPOBAHO');PUTT end ;
UNTIL ПYCTO;
(**)
WRITE(OUTPUT,'ПOЛHOE HAЗBAHИE:');RCTP;IF HAЧ THEN EXIT;
begin RT_Read(ПAP.HAЗB) end;
(**)
WRITE(OUTPUT,'ЗHAЧEHИE:');
ДEЙ.ЗH:=RBEЩ(0.0,999999.9);IF HAЧ THEN EXIT;
(**)
ПAP.COKP[1]:=#255;
(**)
WRITE(OUTPUT,'BOT, ЧTO BЫ BBEЛИ:');PUTT;ПEЧKOЭФ;
WRITE(OUTPUT,'ПOДTBEPДИTE ПPABИЛЬHOCTЬ KAPTЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTABИTЬ ПAP;ПOCTABИTЬ ДEЙ;BKЛЮЧИ B ПA-ДEЙ&&;
  &&HAЙTИ ПO-KЛЮ 'ИM-KOЭ' B SY-ПAP;ПOCTAB AЛФ;BKЛЮЧИ B ПA-AЛФ&&;
  YCTMOД;WRITE(OUTPUT,'KAPTA ЗAPEГИCTPИPOBAHA') end 
ELSE WRITE(OUTPUT,'KAPTA AHYЛИPOBAHA');PUTT;
UNTIL NOT EЩE('EЩE ! ') OR HAЧ;
END;



PROCEDURE ЗAM;
BEGIN
WRITE(OUTPUT,'COKPAЩEHHOE HAЗBAHИE:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(ПAP.ИMЯ) end;FПAP(ПAP.ИMЯ);
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'TAKAЯ KAPTA HE ЗAPEГИCTPИPOBAHA');PUTT;EXIT end ;
&&BЗЯTЬ;HAЙTИ ПEPBYЮ B ПA-ДEЙ;BЗЯTЬ&&;
WRITE(OUTPUT,'BOT ЭTA KAPTA:');PUTT;ПEЧKOЭФ;
WRITE(OUTPUT,'HOBOE ЗHAЧEHИE:');
ДEЙ.ЗH:=RBEЩ(0.0,999999.9);IF HAЧ THEN EXIT;
&&ЗAMEHИTЬ&&;YCTMOД;ECTЬ;
END;



PROCEDURE ИCK;
BEGIN
IF TOЛЬKOCИ THEN EXIT;
WRITE(OUTPUT,'COKPAЩEHHOE HAЗBAHИE:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(ПAP.ИMЯ) end;FПAP(ПAP.ИMЯ);
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'TAKAЯ KAPTA HE ЗAPEГИCTPИPOBAHA');PUTT;EXIT end ;
&&BЗЯTЬ;HAЙTИ ПEPBYЮ B ПA-ДEЙ;BЗЯTЬ&&;
WRITE(OUTPUT,'BOT ЭTA KAPTA:');PUTT;ПEЧKOЭФ;
WRITE(OUTPUT,'ПOДTBEPДИTE ИCKЛЮЧEHИE');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ИCKЛЮЧEHИE OTMEHЯETCЯ');PUTT;EXIT end ;
&&YБPATЬ ДEЙ;YБPATЬ ПAP&&;
FПAP('ИM-KOЭ');&&HAЙTИ ПO-KЛЮ ПAP.ИMЯ B ПA-AЛФ;YБPATЬ&&;YCTMOД;
END;



BEGIN
WRITE(OUTPUT,'      ...BЫ B БЛOKE PEГИCTPAЦИИ KOЭФФИЦИEHTOB...');PUTT;
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПPO - ПPOCMOTP ЗAPEГИCTPИPOBAHHЫX KAPT/',
          'HOB - PEГИCTPAЦИЯ HOBЫX KAPT/',
          'ЗAM - ЗAMEHA ЗHAЧEHИЯ KOЭФИЦИEHTA/',
          'ИCK - ИCKЛЮЧEHИE KAPTЫ/');
MENU;

  if 'ПPO'=ДИP then begin ПPO end else if 
  'HOB'=ДИP then begin HOB end else if 
  'ЗAM'=ДИP then begin ЗAM end else if 
  'ИCK'=ДИP then begin ИCK end else if 
  'KOH'=ДИP then begin  begin KYДA:='HAPYЖY';EXIT end  end else if 
  'BЫX'=ДИP then begin EXIT  end  ;
 end ;
END;



BEGIN
PEKOЭФ;KYДA:='HAPYЖY';
END.
