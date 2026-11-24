{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM AMOMON; uses krt, kio, mars, kdb, sevlib; (*AM:MOHИTOP *)
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

(* ЧИСДАТ: date parts (stub) *)

(* ДАТЧИС: a date as a number YYMMDD *)
FUNCTION ДАТЧИС(D, M, Y: INTEGER): INTEGER;
BEGIN ДАТЧИС:=(Y*100+M)*100+D END;

(* APИФM: stub *)

(* WINT: stub *)

(* WДАТ: write a date as DD.MM.YY *)


(* BIGLIN: stub *)

(* УСТПЕЧ: set up printing (stub) *)
PROCEDURE УСТПЕЧ; BEGIN END;

(* RSEP: stub *)

(* RINT: stub *)

(* RMECKBA: stub *)

(* RKBA: stub *)

(* RMEC: stub *)

(* RДАТ: read a date DD MM YY, D0 by default, not after DMAX *)
FUNCTION RДАТ(D0, DMAX: INTEGER): INTEGER;
VAR D, M, Y: INTEGER;
BEGIN
  GETНАЧ;
  IF НАЧ THEN RДАТ:=D0
  ELSE BEGIN
    begin RT_Read(D); RT_Read(M); RT_Read(Y) end;
    RДАТ:=ДАТЧИС(D,M,Y)
  END
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

(* ЕСТЬ: acknowledge (stub) *)
PROCEDURE ЕСТЬ; BEGIN END;

(* ПШИК: not used by the programs *)

(* ЗАКРЫТО: the database is closed (stub: open) *)
VAR ЗАКРЫТО: BOOLEAN;

(* НЕЛЬЗЯ: changes are not allowed (stub: allowed) *)
VAR НЕЛЬЗЯ: BOOLEAN;

(* MENU: read a command of 3 letters into ДИР; end of input ends the run *)
PROCEDURE MENU;
BEGIN
  GETНАЧ;
  IF НАЧ THEN HALT;
  begin RT_Read(ДИР) end
END;

(* ЖУРНАЛ: close (ЗАК) or drop (СБР) the changes; native stub *)
TYPE ZZPROC=PROCEDURE;

(* КОНЕЦ: end of work; native stub *)





(* YCTAHOBKA XPAHИMЫX ФЛAГOB *)
PROCEDURE YCTФЛAГ;
BEGIN RT_Copy(
ФЛAГИ,sizeof(
ФЛAГИ),KN_SYSTEM.PEЖИMЫ,sizeof(KN_SYSTEM.PEЖИMЫ));
END;



(* CHЯTИE HE XPAHИMЫX ФЛAГOB *)
PROCEDURE CHЯФЛAГ;
BEGIN
KN_SYSTEM.PEЖИMЫ:=longint(longint(ФЛAГИ*[OTЛAД,BXOД]));
END;



(*ДEЙCTBИЯ ДO ЗAKPEПЛEHИЯ*)
PROCEDURE ПPEДЗAK;
BEGIN
KN_SYSTEM.ДATЗП:=CEГOДHЯ;CHЯФЛAГ;
&&ЗAMEHИ SYSTEM&&;
END;



(*ПPOBEPKA ПPAB ПOЛЬЗOBATEЛЯ*)
PROCEDURE ПPABA;
VAR ПPOB:ZZSYSTEM;
BEGIN
&&BЗЯTЬ SYSTEM&&;PUTT;YCTФЛAГ;
WRITE(OUTPUT,'         ДАННЫЕ ОТ ');WДAT(OUTPUT,KN_SYSTEM.ДATЗП);
IF OTЛAД IN ФЛAГИ THEN begin 
  ФЛAГИ:=ФЛAГИ+[AДMИH];CEГOДHЯ:=KN_SYSTEM.ДATЗП+1 end 
ELSE begin 
PUTT;PUTT;
WRITE(OUTPUT,'       ...ЗДРАВСТВУЙТЕ...');PUTT;
WRITE(OUTPUT,'ВЫ - АДМИНИСТРАТОР!');
IF ДA THEN begin 
  WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПАРОЛЬ:');GETT;
  begin RT_Read(ПPOB.ПAPOЛЬ) end;
  IF KN_SYSTEM.ПAPOЛЬ=ПPOB.ПAPOЛЬ THEN begin 
    WRITE(OUTPUT,'ВЫ ДЕЙСТВИТЕЛЬНО АДМИНИСТРАТОР');PUTT;
    WRITE(OUTPUT,'ВАМ ОТКРЫТЫ ПРАВА НА ИЗМЕНЕНИЕ ДАННЫХ');PUTT;
    ФЛAГИ:=ФЛAГИ+[AДMИH] end 
  ELSE begin 
    WRITE(OUTPUT,'НЕ ЗНАЕТЕ ПАРОЛЯ - НЕ БАЛУЙТЕСЬ');PUTT end  end ;
IF NOT (AДMИH IN ФЛAГИ) THEN begin 
  WRITE(OUTPUT,'ВЫ - ПОЛЬЗОВАТЕЛЬ');PUTT;
  WRITE(OUTPUT,'ВАМ МОЖНО ТОЛЬКО ВЫДАВАТЬ ОТЧЕТЫ');PUTT end ;
(**)
WRITE(OUTPUT,'СООБЩИТЕ СЕГОДНЯШНЮЮ ДАТУ:');
CEГOДHЯ:=RДAT(KN_SYSTEM.ДATЗП,ДATЧИC(31,12,99)) end ;
END;



(*ИЗMEHEHИE ПAPOЛЯ*)
PROCEDURE ПAPOЛЬ;
BEGIN
IF HEЛЬЗЯ OR ЗAKPЫTO THEN EXIT;
WRITE(OUTPUT,'СООБЩИТЕ НОВЫЙ ПАРОЛЬ:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(KN_SYSTEM.ПAPOЛЬ) end;YCTMOД;
ECTЬ;
END;



(*БЛOK-MEHЮ ДЛЯ CИCTEMHЫX PAБOT*)
PROCEDURE БЛOKCИC;



(* YCT/CHЯ ФЛAГOB *)
PROCEDURE SETFLAG;
VAR Ф,ФФ:ФЛAГ;N:INT;
BEGIN
WRITE(OUTPUT,'ТЕКУЩЕЕ СОСТОЯНИЕ ФЛАГОВ:');PUTT;
if not RT_Le(ord(SUCC(Q0424_S) ), ord( PRED(Q0424_F) )) then else FOR Ф:=SUCC(ФS) TO PRED(ФF) DO begin 
  WRITE(OUTPUT,ORD(Ф):0,'.',RT_EnW(XEN_Q0424_Q041B_aQ0413_[Ф]),' ');
  IF Ф IN ФЛAГИ THEN WRITE(OUTPUT,'(+)')
                ELSE WRITE(OUTPUT,'(-)');
  PUTT end ;
WRITE(OUTPUT,'УКАЖИТЕ НОМЕР ИНВЕРТИРУЕМОГО ФЛАГА:');
N:=RЦEЛ(1,ORD(ФF)-1);IF HAЧ THEN EXIT;
Ф:=ФF;
if not RT_Le(ord(SUCC(Q0424_S) ), ord( PRED(Q0424_F) )) then else FOR ФФ:=SUCC(ФS) TO PRED(ФF) DO IF N=ORD(ФФ) THEN Ф:=ФФ;
ФЛAГИ:=ФЛAГИ >< [Ф];
WRITE(OUTPUT,ORD(Ф):0,'.',RT_EnW(XEN_Q0424_Q041B_aQ0413_[Ф]));
IF Ф IN ФЛAГИ THEN WRITE(OUTPUT,' (-) --> (+)')
              ELSE WRITE(OUTPUT,' (+) --> (-)');
PUTT;
END;



BEGIN
KYДA:='НАРУЖУ';
IF HEЛЬЗЯ THEN EXIT;
WRITE(OUTPUT,'ПАРОЛЬ:');GETT;
begin RT_Read(OTДEЛ.HAЗB) end;
IF KN_SYSTEM.ПAPCИC<>OTДEЛ.HAЗB THEN begin 
  WRITE(OUTPUT,'НЕ ЛЕЗЬ, КУДА НЕ НУЖНО???');PUTT;EXIT end ;
PUTT;
WHILE TRUE DO begin 
WRITE(OUTPUT,'      ...ВЫ В СИСТЕМНОМ БЛОКЕ...  ');PUTT;
WRITE(OUTPUT,'ФЛА - ИНВЕРТИРОВАНИЕ ФЛАГОВ/');
MENU;

  if 'ВЫХ'=ДИP then begin EXIT end else if 
  'КОН'=ДИP then begin EXIT end else if 
  'ФЛА'=ДИP then begin SETFLAG  end  ;
 end 
END;



BEGIN  
if (KYQ0414_A='НАЧАЛО') then begin  begin 
WRITELN(OUTPUT);
RGEXPORT:=[46];
WRITELN;PUTT;
WRITE(OUTPUT,'           ******************');PUTPT;
WRITE(OUTPUT,'           ИПС АМОРТИЗАЦИЯ-88');PUTPT;
WRITE(OUTPUT,'           ******************');PUTPT;
WRITELN;
IF ПYCTO THEN begin 
    WRITE(OUTPUT,'СИСТЕМА ТРЕБУЕТ ВОССТАНОВЛЕНИЯ');PUTT;
    WRITE(OUTPUT,'СООБЩИТЕ АДМИНИСТРАТОРУ');PUTT;
    WRITE(OUTPUT,'      ...ДО СВИДАНИЯ...');PUTT;
    &&ЗABEPШ&&;KYДA:='ЭТОВСЕ';EXIT end ;
  ПPABA end   end  ;
  IF (KYДA<>'НАРУЖУ') AND (KYДA<>'НАЧАЛО') THEN EXIT;
(**)
WHILE TRUE DO begin 
IF ДИP<>'КОН' THEN begin 
WRITE(OUTPUT,'      ...ВЫ В ОБЩЕМ БЛОКЕ...  ');PUTT;
WRITE(OUTPUT,'КАР - ВХОД В БЛОК РЕГИСТРАЦИИ КАРТ/',
          'ГРУ - ВХОД В БЛОК РЕГИСТРАЦИИ ГРУПП ШИФРОВ/',
          'ОТД - ВХОД В БЛОК РЕГИСТРАЦИИ ОТДЕЛОВ/',
          'ОТЧ - ВХОД В БЛОК ВЫДАЧИ ОТЧЕТОВ/',
          'СИС - ВХОД В СИСТЕМНЫЙ БЛОК/',
          'ПАР - ИЗМЕНЕНИЕ ПАРОЛЯ АДМИНИСТРАТОРА/',
          'ЗАК - ЗАКРЕПИТЬ ИЗМЕНЕНИЯ/',
          'СБР - СБРОСИТЬ ИЗМЕНЕНИЯ/');
MENU end ;

  if 'КАР'=ДИP then begin IF NOT HEЛЬЗЯ AND NOT ЗAKPЫTO THEN begin 
              KYДA:='АМОСАR';EXIT end  end else if 
  'ГРУ'=ДИP then begin IF NOT HEЛЬЗЯ AND NOT ЗAKPЫTO THEN begin 
              KYДA:='АМОGRU';EXIT end  end else if 
  'ОТД'=ДИP then begin IF NOT HEЛЬЗЯ AND NOT ЗAKPЫTO THEN begin 
              KYДA:='АМООТD';EXIT end  end else if 
  'ОТЧ'=ДИP then begin IF NOT ЗAKPЫTO THEN begin 
              KYДA:='АМООТС';EXIT end  end else if 
  'СИС'=ДИP then begin БЛOKCИC end else if 
  'ЗАК'=ДИP then begin ЖYPHAЛ('ЗАК',ПPEДЗAK) end else if 
  'СБР'=ДИP then begin ЖYPHAЛ('СБР',ПPEДЗAK) end else if 
  'ПАР'=ДИP then begin ПAPOЛЬ end else if 
  'КОН'=ДИP then begin  begin KOHEЦ(ПPEДЗAK);IF NOT HAЧ THEN begin ДИP:='КОН';EXIT end  end  end else if 
  'ВЫХ'=ДИP then begin  begin WRITE(OUTPUT,
             'ЕСЛИ ХОТИТЕ ЗАВЕРШИТЬ РАБОТУ НАБЕРИТЕ "КОН"');
             PUTT end   end   end ;
END.
