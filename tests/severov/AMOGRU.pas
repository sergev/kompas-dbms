{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM AMOGRU; uses krt, kio, mars, kdb, sevlib; (*AM:ШИФPЫ *)
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

(* CUTCTP: stub *)

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

(* WCTP: write a string without trailing blanks, in N positions *)


(* STEP: end of a listed line; true would stop the listing *)
FUNCTION STEP: BOOLEAN; BEGIN WRITELN; STEP:=FALSE END;




PROCEDURE REGIS;
CONST
      MINШИФP=10000; MAXШИФP=110001;



PROCEDURE WГPYП;
BEGIN
  WRITE(OUTPUT,ГPYППA.HAЧ:6,' - ',RT_W(ГPYППA.KOH),'   ');
  WCTP(OUTPUT,ГPYППA.HAЗB,0);PUTT;
END;



PROCEDURE ПPO;
VAR I:INT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-ГPY&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'НЕТ ГРУПП');PUTT;EXIT end ;
I:=0;ШAГ:=1;
REPEAT
  I:=I+1;&&BЗЯTЬ;HAЙTИ CЛEДYЮ&&;
  WГPYП;
UNTIL STEP OR ПYCTO;
END;



PROCEDURE HOB;
BEGIN
REPEAT
  WRITE(OUTPUT,'НАЗВАНИЕ ГРУППЫ:');RCTP;
  IF HAЧ THEN EXIT;
  begin RT_Read(ГPYППA.HAЗB) end;
(**)
  WRITE(OUTPUT,'НАЧАЛЬНЫЙ ШИФР:');
  ГPYППA.HAЧ:=RЦEЛ(MINШИФP,MAXШИФP);
  IF HAЧ THEN EXIT;
(**)
  WRITE(OUTPUT,'КОНЕЧНЫЙ ШИФР:');
  ГPYППA.KOH:=RЦEЛ(ГPYППA.HAЧ,MAXШИФP);
  IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО ВЫ ВВЕЛИ:');PUTT;WГPYП;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРАВИЛЬНОСТЬ ГРУППЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTABИTЬ ГPYППA&&;YCTMOД;
  WRITE(OUTPUT,'ГРУППА ЗАРЕГИСТРИРОВАНА') end 
ELSE WRITE(OUTPUT,'ГРУППА АНУЛИРОВАНА');PUTT;
UNTIL NOT EЩE('ЕЩЕ!  ') OR HAЧ;
END;



PROCEDURE ИCK;
VAR Г:ZZГPYППA;
BEGIN
WRITE(OUTPUT,'НАЧАЛЬНЫЙ ШИФР ГРУППЫ:');
Г.HAЧ:=RЦEЛ(MINШИФP,MAXШИФP);
IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ Г.HAЧ B SY-ГPY&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'ТАКАЯ ГРУППА НЕ ЗАРЕГИСТРИРОВАНА');PUTT;EXIT end ;
WRITE(OUTPUT,'КОНЕЧНЫЙ ШИФР ГРУППЫ:');
Г.KOH:=RЦEЛ(Г.HAЧ,MAXШИФP);
IF HAЧ THEN EXIT;
 WHILE TRUE DO begin 
  &&BЗЯTЬ&&;
  IF ГPYППA.KOH=Г.KOH THEN break ;
  &&HAЙTИ ПPEДЫД&&;
  IF (ГPYППA.HAЧ<>Г.HAЧ) OR ПYCTO THEN begin 
    WRITE(OUTPUT,'ТАКАЯ ГРУППА НЕ ЗАРЕГИСТРИРОВАНА');PUTT;EXIT end  end ;
(**)
WRITE(OUTPUT,'ВОТ ЭТА ГРУППА:');PUTT;WГPYП;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ЕЕ ИСКЛЮЧЕНИЕ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ИСКЛЮЧЕНИЕ ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
&&YБPATЬ&&;YCTMOД;ECTЬ;
END;



BEGIN
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ РЕГИСТРАЦИИ ГРУПП ШИФРОВ...');PUTT;
KYДA:='НАРУЖУ';
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПРО - ПРОСМОТР ЗАРЕГИСТРИРОВАННЫХ ГРУПП/',
          'НОВ - РЕГИСТРАЦИЯ НОВЫХ ГРУПП/',
          'ИСК - ИСКЛЮЧЕНИЕ ГРУППЫ/');
MENU;

  if 'ПРО'=ДИP then begin ПPO end else if 
  'НОВ'=ДИP then begin HOB end else if 
  'ИСК'=ДИP then begin ИCK end else if 
  'КОН'=ДИP then begin EXIT end else if 
  'ВЫХ'=ДИP then begin EXIT  end  ;
 end ;
END;



BEGIN REGIS END.
.
DRUM
ШИФP 410900 ЗMП^OЗY 32^TPA 88^BPE 1000^ЛEH 31(2)41(2)^EEB1A3
