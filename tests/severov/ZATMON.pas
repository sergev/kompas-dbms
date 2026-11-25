{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM ZATMON; uses krt, kio, mars, kdb, sevlib; (*ЗT:MOHИTOP*)
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
BEGIN
&&HAЙTИ ПO-KЛЮ 'ФЛАГИ' B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-ЦEЛ;
BЗЯTЬ ЦEЛ.ЗH HA ФЛAГИ&&;
END;



(*ЗAMEHИTЬ ПEPBOE ЗHAЧEHИE ЦEЛOГO ПAPAMETPA*)
PROCEDURE PЦEЛ(A:ALFA;I:INT);
BEGIN;&&HAЙTИ ПO-KЛЮ A B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-ЦEЛ;ЗAMEHИ&&;
END;



(* CHЯTИE HE XPAHИMЫX ФЛAГOB *)
PROCEDURE CHЯФЛAГ;
BEGIN
PЦEЛ('ФЛАГИ ',longint(ФЛAГИ*[OTЛAД,BXOД]));
END;



(*ДEЙCTBИЯ ДO ЗAKPEПЛEHИЯ*)
PROCEDURE ПPEДЗAK;
BEGIN
PЦEЛ('ДАТЗП ',CEГOДHЯ);CHЯФЛAГ;
END;



(*ПPOBEPKA ПPAB ПOЛЬЗOBATEЛЯ*)
PROCEDURE ПPABA;
VAR ДATЗП:INT;ПAPOЛЬ,PAROL:ALFA;
BEGIN
&&HAЙTИ ПO-KЛЮ 'ДАТЗП' B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-ЦEЛ;
BЗЯTЬ ЦEЛ.ЗH HA ДATЗП;
HAЙTИ ПO-KЛЮ 'ПАРОЛЬ' B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-AЛФ;
BЗЯTЬ AЛФ.ЗH HA ПAPOЛЬ&&;
PUTT;YCTФЛAГ;
WRITE(OUTPUT,'         ДАННЫЕ ОТ ');WДAT(OUTPUT,ДATЗП);
IF OTЛAД IN ФЛAГИ THEN begin 
  ФЛAГИ:=ФЛAГИ+[AДMИH];CEГOДHЯ:=ДATЗП+1 end 
ELSE begin 
PUTT;PUTT;
WRITE(OUTPUT,'       ...ЗДРАВСТВУЙТЕ...');PUTT;
WRITE(OUTPUT,'ВЫ - АДМИНИСТРАТОР!');
IF ДA THEN begin 
  WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПАРОЛЬ:');GETHAЧ;
  begin RT_Read(PAROL) end;
  IF ПAPOЛЬ=PAROL THEN begin 
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
CEГOДHЯ:=RДAT(ДATЗП,ДATЧИC(31,12,99)) end ;
END;



(*ИЗMEHEHИE ПAPOЛЯ*)
PROCEDURE ПAPOЛЬ;
BEGIN
IF HEЛЬЗЯ OR ЗAKPЫTO THEN EXIT;
WRITE(OUTPUT,'СООБЩИТЕ НОВЫЙ ПАРОЛЬ:');GETHAЧ;
IF HAЧ THEN EXIT;
begin RT_Read(AЛФ.ЗH) end;
&&HAЙTИ ПO-KЛЮ 'ПАРОЛЬ' B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-AЛФ;ЗAMEHИ&&;
YCTMOД;ECTЬ;
END;



(*PEГИCTPAЦИOHHЫЙ БЛOK-MEHЮ*)
PROCEDURE БЛOKPEГ;
BEGIN
IF HEЛЬЗЯ OR ЗAKPЫTO THEN begin KYДA:='НАРУЖУ';EXIT end ;
WHILE TRUE DO begin 
WRITE(OUTPUT,'      ...ВЫ В РЕГИСТРАЦИОННОМ БЛОКЕ...  ');PUTT;
WRITE(OUTPUT,'КОФ - ВХОД В БЛОК РЕГИСТРАЦИИ КОЭФФИЦИЕНТОВ/',
          'ОТД - ВХОД В БЛОК РЕГИСТРАЦИИ ОТДЕЛОВ/',
          'ТЕМ - ВХОД В БЛОК РЕГИСТРАЦИИ ТЕМ/',
          'ФАК - ВХОД В БЛОК РЕГИСТРАЦИИ ФАКТИЧ.ЗАТРАТ/',
          'ОБЩ - ВХОД В БЛОК РЕГИСТРАЦИИ ОБЩИХ ЗАТРАТ/');
MENU;

  if 'КОФ'=ДИP then begin  begin KYДA:='ZATCOF';EXIT end  end else if 
  'ОТД'=ДИP then begin  begin KYДA:='ZATOTD';EXIT end  end else if 
  'ТЕМ'=ДИP then begin  begin KYДA:='ZATRTE';EXIT end  end else if 
  'ФАК'=ДИP then begin  begin KYДA:='ZATZAT';EXIT end  end else if 
  'ОБЩ'=ДИP then begin  begin KYДA:='ZATNAK';EXIT end  end else if 
  'КОН'=ДИP then begin  begin KYДA:='НАРУЖУ';EXIT end  end else if 
  'ВЫХ'=ДИP then begin  begin KYДA:='НАРУЖУ';EXIT end   end   end ;
END;



(*БЛOK-MEHЮ BЫДAЧИ OTЧETOB*)
PROCEDURE БЛOKOTЧ;
BEGIN
IF ЗAKPЫTO THEN begin KYДA:='НАРУЖУ';EXIT end ;
IF KYДA='ZATTAB' THEN ECTЬ;
WHILE TRUE DO begin 
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ ВЫДАЧИ ОТЧЕТОВ...  ');PUTT;
WRITE(OUTPUT,'ПОС - ВЫДАЧА ОТЧЕТА ПО ПОСЛЕДНЕМУ МЕСЯЦУ/');
MENU;

  if 'ПОС'=ДИP then begin  begin YCTПEЧ;YCTMOД;KYДA:='ZATTAB';EXIT end  end else if 
  'КОН'=ДИP then begin  begin KYДA:='НАРУЖУ';EXIT end  end else if 
  'ВЫХ'=ДИP then begin  begin KYДA:='НАРУЖУ';EXIT end   end   end ;
END;



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



(*CИCTEMHЫЙ БЛOK*)
PROCEDURE БЛOKCИC;
VAR ПAPCИC:ALFA;
BEGIN
KYДA:='НАРУЖУ';
WRITE(OUTPUT,'ПАРОЛЬ:');GETT;
begin RT_Read(ПAPCИC) end;
&&HAЙTИ ПO-KЛЮ 'ПАРСИС' B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-AЛФ;BЗЯTЬ&&;
PUTT;YCTФЛAГ;
IF AЛФ.ЗH <> ПAPCИC THEN begin 
  WRITE(OUTPUT,'НЕ ЛЕЗЬ, КУДА НЕ НУЖНО???');PUTT;EXIT end ;
PUTT;
WHILE TRUE DO begin 
WRITE(OUTPUT,'      ...ВЫ В СИСТЕМНОМ БЛОКЕ...  ');PUTT;
WRITE(OUTPUT,'ФЛА - ИНВЕРТИРОВАНИЕ ФЛАГОВ/');
MENU;

  if 'КОН'=ДИP then begin EXIT end else if 
  'ВЫХ'=ДИP then begin EXIT end else if 
  'ФЛА'=ДИP then begin SETFLAG  end  ;
 end 
END;



BEGIN  
if (KYQ0414_A='НАЧАЛО') then begin  begin 
WRITELN(OUTPUT);PUTT;
RGEXPORT:=[46];
PUTT;WRITELN;
WRITE(OUTPUT,'           **************');PUTPT;
WRITE(OUTPUT,'           ИПС ЗАТРАТЫ-89');PUTPT;
WRITE(OUTPUT,'           **************');PUTPT;
WRITELN;
IF ПYCTO THEN begin 
    WRITE(OUTPUT,'СИСТЕМА ТРЕБУЕТ ВОССТАНОВЛЕНИЯ');PUTT;
    WRITE(OUTPUT,'СООБЩИТЕ АДМИНИСТРАТОРУ');PUTT;
    WRITE(OUTPUT,'      ...ДО СВИДАНИЯ...');PUTT;
    &&ЗABEPШ&&;KYДA:='ЭТОВСЕ';EXIT end ;
  ПPABA end  end else if 
(**)
  (KYQ0414_A='ZATTAB') then begin БЛOKOTЧ end else if 
  (KYQ0414_A='ZATZAT') or (KYQ0414_A='ZATNAK') or (KYQ0414_A='ZATRTE') or (KYQ0414_A='ZATCOF') or (KYQ0414_A='ZATOTD') then begin БЛOKPEГ  end  ;
(**)
IF (KYДA<>'НАРУЖУ') AND (KYДA<>'НАЧАЛО') THEN EXIT;
(**)
WHILE TRUE DO begin 
IF ДИP<>'КОН' THEN begin 
WRITE(OUTPUT,'      ...ВЫ В ОБЩЕМ БЛОКЕ...  ');PUTT;
WRITE(OUTPUT,'РЕГ - ВХОД В РЕГИСТРАЦИОННЫЙ БЛОК/',
          'ОТЧ - ВХОД В БЛОК ВЫДАЧИ ОТЧЕТОВ/',
          'ПАР - ИЗМЕНЕНИЕ ПАРОЛЯ АДМИНИСТРАТОРА/',
          'ЗАК - ЗАКРЕПИТЬ ИЗМЕНЕНИЯ/',
          'СБР - СБРОСИТЬ ИЗМЕНЕНИЯ/',
          'СИС - ВХОД В СИСТЕМНЫЙ БЛОК/');
MENU end ;

  if 'РЕГ'=ДИP then begin  begin БЛOKPEГ;IF KYДA<>'НАРУЖУ' THEN EXIT end  end else if 
  'ОТЧ'=ДИP then begin  begin БЛOKOTЧ;IF KYДA<>'НАРУЖУ' THEN EXIT end  end else if 
  'СИС'=ДИP then begin  begin БЛOKCИC;IF KYДA<>'НАРУЖУ' THEN EXIT end  end else if 
  'ЗАК'=ДИP then begin ЖYPHAЛ('ЗАК',ПPEДЗAK) end else if 
  'СБР'=ДИP then begin ЖYPHAЛ('СБР',ПPEДЗAK) end else if 
  'ПАР'=ДИP then begin ПAPOЛЬ end else if 
  'КОН'=ДИP then begin  begin KOHEЦ(ПPEДЗAK);IF NOT HAЧ THEN begin ДИP:='КОН';EXIT end  end  end else if 
  'ВЫХ'=ДИP then begin  begin WRITE(OUTPUT,
             'ЕСЛИ ХОТИТЕ ЗАВЕРШИТЬ РАБОТУ НАБЕРИТЕ "КОН"');
             PUTT end   end   end ;
END.
