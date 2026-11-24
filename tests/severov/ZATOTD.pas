{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM ZATOTD; uses krt, kio, mars, kdb, sevlib; (*ЗT:PEГИC.OTДEЛOB*)
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
  ФЛАГ=(ФS,ПЕЧАТЬ,МОДИФ,АДМИН,ОТЛАД,ОТЧСКЛ,ОТЧОТД,ВХОД,ФF); const XEN_Q0424_Q041B_AQ0413_: array[Q0424_Q041B_AQ0413_] of string[8] = ('ФS','ПЕЧАТЬ','МОДИФ','АДМИН','ОТЛАД','ОТЧСКЛ','ОТЧОТД','ВХОД','ФF'); type
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




(*БЛOK PEГИCTPAЦИИ KAPT*)
PROCEDURE REGIS;



(*ПEЧATЬ OTДEЛA*)
PROCEDURE ПEЧOTД;
BEGIN
WRITE(OUTPUT,RT_W(OTДEЛ.HAЗB));
END;



PROCEDURE ПPO;
VAR I:INT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'НЕТ ОТДЕЛОВ');PUTT;EXIT end ;
I:=0;ШAГ:=1;
REPEAT
  I:=I+1;&&BЗЯTЬ&&;ПEЧOTД;&&HAЙTИ CЛEДYЮ B SY-OTД&&;
UNTIL ПYCTO OR NOT EЩE('ЕЩЕ ! ') OR HAЧ;
END;



PROCEDURE HOB;
BEGIN
REPEAT
REPEAT
  WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');GETHAЧ;
  IF HAЧ THEN EXIT;
  begin RT_Read(OTДEЛ.HAЗB) end;
  &&HAЙTИ ПO-KЛЮ OTДEЛ.HAЗB B SY-OTД&&;
  IF MOЖHO THEN begin WRITE(OUTPUT,'ТАКОЙ ОТДЕЛ УЖЕ ЗАРЕГИСТРИРОВАН');PUTT end ;
UNTIL ПYCTO;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО ВЫ ВВЕЛИ:');PUTT;ПEЧOTД;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРАВИЛЬНОСТЬ КАРТЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTABИTЬ OTДEЛ&&;YCTMOД;
  WRITE(OUTPUT,'КАРТА ЗАРЕГИСТРИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА');PUTT;
UNTIL NOT EЩE('ЕЩЕ!  ') OR HAЧ;
END;



PROCEDURE ЗAM;
VAR CTOT:ZZOTДEЛ;
BEGIN
WRITE(OUTPUT,'СТАРОЕ НАЗВАНИЕ ОТДЕЛА:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(CTOT.HAЗB) end;
&&HAЙTИ ПO-KЛЮ CTOT.HAЗB B SY-OTД&&;
IF MOЖHO THEN begin &&BЗЯTЬ&&; end  ELSE begin 
  WRITE(OUTPUT,'ТАКОЙ ОТДЕЛ НЕ ЗАРЕГИСТРИРОВАН');PUTT;EXIT end ;
WRITE(OUTPUT,'НОВОЕ НАЗВАНИЕ ОТДЕЛА:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(OTДEЛ.HAЗB) end;
&&HAЙTИ ПO-KЛЮ OTДEЛ.HAЗB B SY-OTД&&;IF COCT=0 THEN begin 
  WRITE(OUTPUT,'ТАКОЙ ОТДЕЛ УЖЕ ЗАРЕГИСТРИРОВАН');PUTT;EXIT end ;
&&HAЙTИ ПO-KЛЮ CTOT.HAЗB B SY-OTД&&;
&&ЗAMEHИTЬ&&;YCTMOД;ECTЬ;
END;



PROCEDURE ИCK;
BEGIN
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');
OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
&&HAЙTИ ПEPBYЮ B OT-ИCП&&;
IF NOT ПYCTO THEN begin 
WRITE(OUTPUT,'ОТДЕЛ НЕЛЬЗЯ ИСКЛЮЧИТЬ ПОКА ОН ЗАРЕГИСТРИРОВАН',RT_W(LF),
          'КАК ИСПОЛНИТЕЛЬ В ТЕМАХ');PUTT;EXIT end ;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ИСКЛЮЧЕНИЕ ОТДЕЛА');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ИСКЛЮЧЕНИЕ ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
&&YБPATЬ OTДEЛ&&;YCTMOД;ECTЬ;
END;



BEGIN
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ РЕГИСТРАЦИИ ОТДЕЛОВ...');PUTT;
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПРО - ПРОСМОТР ЗАРЕГИСТРИРОВАННЫХ ОТДЕЛОВ/',
          'НОВ - РЕГИСТРАЦИЯ НОВЫХ ОТДЕЛОВ/',
          'ЗАМ - ЗАМЕНА НАЗВАНИЯ ОТДЕЛА/',
          'ИСК - ИСКЛЮЧЕНИЕ ОТДЕЛА/');
MENU;

  if 'ПРО'=ДИP then begin ПPO end else if 
  'НОВ'=ДИP then begin HOB end else if 
  'ЗАМ'=ДИP then begin ЗAM end else if 
  'ИСК'=ДИP then begin ИCK end else if 
  'КОН'=ДИP then begin  begin KYДA:='НАРУЖУ';EXIT end  end else if 
  'ВЫХ'=ДИP then begin EXIT  end  ;
 end ;
END;



BEGIN REGIS END.
