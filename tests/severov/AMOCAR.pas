{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM AMOCAR; uses krt, kio, mars, kdb, sevlib; (*AM:KAPTЫ *)
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

(* WCTP: write a string without trailing blanks, in N positions *)


(* STEP: end of a listed line; true would stop the listing *)
FUNCTION STEP: BOOLEAN; BEGIN WRITELN; STEP:=FALSE END;




(*BЗЯTЬ ПPИБOP И BЛAДEЛ B SY-OTД И SY-ШИФ*)
PROCEDURE BЗЯTЬBCE;
BEGIN
&&BЗЯTЬ ИHB;
HAЙTИ BЛAДEЛ B ПP-ИHB;BЗЯTЬ;
HAЙTИ BЛAДEЛ B ШИ-ПPИ;BЗЯTЬ&&;
END;



PROCEDURE REGIS;
CONST
      MINИHBN=100  ; MAXИHBN=99999;
      MINШИФP=10000; MAXШИФP=110001;
      MINMEC=1;      MAXMEC=12;
      MINПPOЦ=0.01;  MAXПPOЦ=50.0;
      MINЦEHA=0.0;  MAXЦEHA=5000000.0;
TYPE ZZF1=RECORD HAЗB:CTPOKA;KOЛИЧ:REAL END;
VAR ДP:FILE OF ZZF1;ДPZB:ZZF1;ДPZE:BOOLEAN;



(*BЗЯTЬ METAЛЛЫ*)
PROCEDURE BЗЯMET;
BEGIN
&&HAЙTИ ПEPBYЮ B ПP-COД&&;begin if RT_First(@Q0414_P) then assign(Q0414_P, RT_TmpName); REWRITE(ДP) end;
WHILE MOЖHO DO begin 
  &&HAЙTИ BЛAДEЛ B ME-COД;
  BЗЯTЬ METAЛ.HAЗB HA ДPZB.HAЗB;
  BЗЯTЬ COДEPЖ.KOЛИЧ HA ДPZB.KOЛИЧ;
  HAЙTИ CЛEДYЮ B ПP-COД&&;WRITE(ДP,ДPZB) end ;
END;



(*ДAЙ METAЛЛЫ*)
PROCEDURE ДAЙMET;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-MET&&;begin if RT_First(@Q0414_P) then assign(Q0414_P, RT_TmpName); REWRITE(ДP) end;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ CЛEДYЮ&&;
  WCTP(OUTPUT,METAЛ.HAЗB,8);WRITE(OUTPUT,':');
  ДPZB.HAЗB:=METAЛ.HAЗB;
  ДPZB.KOЛИЧ:=RBEЩ(0.0,9999.0);IF HAЧ THEN EXIT;
  IF ДPZB.KOЛИЧ>0.00000001 THEN WRITE(ДP,ДPZB) end ;
END;



(*ПOCTAB METAЛЫ*)
PROCEDURE ПOCMET;
BEGIN
BEGIN begin if RT_First(@Q0414_P) then assign(Q0414_P, RT_TmpName); RESET(ДP) end;ДPZE:=EOF(ДP);IF NOT ДPZE THEN READ(ДP,ДPZB) END;
WHILE NOT ДPZE DO begin 
  &&HAЙTИ ПO-KЛЮ ДPZB.HAЗB B SY-MET&&;
  COДEPЖ.KOЛИЧ:=ДPZB.KOЛИЧ;
  &&ПOCTAB COДEPЖ&&;BEGIN ДPZE:=EOF(ДP);IF NOT ДPZE THEN READ(ДP,ДPZB) END end ;
END;



(*ПEЧATЬ METAЛOB*)
PROCEDURE WMET;
VAR I:INT;
BEGIN
BEGIN begin if RT_First(@Q0414_P) then assign(Q0414_P, RT_TmpName); RESET(ДP) end;ДPZE:=EOF(ДP);IF NOT ДPZE THEN READ(ДP,ДPZB) END;I:=0;
IF ДPZE THEN EXIT;
WHILE NOT ДPZE DO begin 
  IF (I MOD 4)=0 THEN WRITE(OUTPUT,'       ');
  I:=I+1;WCTP(OUTPUT,ДPZB.HAЗB,6);
  WRITE(OUTPUT,'=',ДPZB.KOЛИЧ:0:25);
  IF (I MOD 4)=0 THEN PUTT ELSE WRITE(OUTPUT,'  ');
  BEGIN ДPZE:=EOF(ДP);IF NOT ДPZE THEN READ(ДP,ДPZB) END end ;
IF (I MOD 4)<>0 THEN PUTT;
END;



PROCEDURE WCTO;
BEGIN
  WRITE(OUTPUT,'       ОТДЕЛ=',RT_W(OTДEЛ.HAЗB));
  IF CTOИT.ПPИHЯЛ<>0 THEN WRITE(OUTPUT,' ПРИ=',CTOИT.ПPИHЯЛ:2);
  IF CTOИT.CПИCAЛ<>0 THEN WRITE(OUTPUT,' СПИ=',CTOИT.CПИCAЛ:2);
  PUTT;
END;



(*BЫBOД "CTOИT ПO OTДEЛAM"*)
PROCEDURE WCTOИT;
BEGIN
&&HAЙTИ ПEPBYЮ B ИH-CTO&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B OT-CTO;BЗЯTЬ&&;
  WCTO;
  &&HAЙTИ CЛEДYЮ B ИH-CTO&&; end ;
END;



(*BЫBOД ПPИБOPA*)
PROCEDURE WKAPT;
BEGIN
WITH ПPИБOP DO begin 
WRITE(OUTPUT,ИHB.HOMEP:5,') Ш=',ШИФP.HOMEP:6,
          ' Ц=',ЦEHA:6:22,' !В=',BOC:5:22,' !К=',KAП:5:22,' ');
WCTP(OUTPUT,HAЗB,0);PUTT;WMET;
 end END;



FUNCTION KAPTA:BOOL;
BEGIN
KAPTA:=FALSE;
WRITE(OUTPUT,'ИНВЕНТАРНЫЙ НОМЕР КАРТЫ:');
ИHB.HOMEP:=RЦEЛ(MINИHBN,MAXИHBN);
IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-ИHB&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'НЕТ КАРТЫ С ТАКИМ ИНВ.N');PUTT;EXIT end ;
BЗЯTЬBCE;BЗЯMET;
WRITE(OUTPUT,'ВОТ ЭТА КАРТА:');PUTT;WKAPT;WCTOИT;
KAPTA:=TRUE;
END;



FUNCTION ИHBHOM:BOOL;
BEGIN
ИHBHOM:=FALSE;
REPEAT
WRITE(OUTPUT,'НОВЫЙ ИНВЕНТАРНЫЙ НОМЕР:');
ИHB.HOMEP:=RЦEЛ(MINИHBN,MAXИHBN);IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-ИHB&&;
IF MOЖHO THEN begin WRITE(OUTPUT,
  'КАРТА С ТАКИМ ИНВ.N УЖЕ ЗАРЕГИСТРИРОВАНА, ПОВТОРИТЕ');PUTT end ;
UNTIL ПYCTO;
ИHBHOM:=TRUE;
END;




PROCEDURE ПPO;
VAR N,FIRST,LAST:INT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-ИHB&&;
IF ПYCTO THEN begin WRITE(OUTPUT,'НЕТ КАРТ');PUTT;EXIT end ;
&&BЗЯTЬ ИHB.HOMEP HA FIRST;
HAЙTИ ПOCЛEД B SY-ИHB;BЗЯTЬ ИHB.HOMEP HA LAST&&;
WRITE(OUTPUT,'С КАКОГО НОМЕРА НАЧАТЬ ПРОСМОТР (',FIRST:0,'-',LAST:0,'):');
N:=RЦEЛ(FIRST,LAST);IF HAЧ THEN EXIT;
(**)
IF N < (LAST-FIRST) DIV 2 THEN begin 
  &&HAЙTИ ПEPBYЮ B SY-ИHB;BЗЯTЬ&&;
  WHILE ИHB.HOMEP<N DO begin 
    &&HAЙTИ CЛEДYЮ;BЗЯTЬ ИHB.HOMEP&&; end  end 
ELSE begin 
  &&HAЙTИ ПOCЛEД B SY-ИHB;BЗЯTЬ&&;
  WHILE ИHB.HOMEP>N DO begin 
    &&HAЙTИ ПPEДЫД;BЗЯTЬ&&; end  end ;
ШAГ:=1;
REPEAT
  BЗЯTЬBCE;BЗЯMET;
  WKAPT;WCTOИT;&&HAЙTИ CЛEДYЮ B SY-ИHB&&;
UNTIL STEP OR ПYCTO;
END;



PROCEDURE HOB;
BEGIN
WITH ПPИБOP DO REPEAT
(**)
IF NOT ИHBHOM THEN EXIT;
(**)
WRITE(OUTPUT,'ШИФР ОБОРУДОВАНИЯ:');
ШИФP.HOMEP:=RЦEЛ(MINШИФP,MAXШИФP);IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'НАИМЕНОВАНИЕ:');RCTP;IF HAЧ THEN EXIT;
begin RT_Read(HAЗB) end;
(**)
WRITE(OUTPUT,'ЦЕНА:');
ЦEHA:=RBEЩ(MINЦEHA,MAXЦEHA);IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'ЕСТЬ ЛИ ДРАГ.МЕТАЛЛЫ!');
IF ДA AND NOT HAЧ THEN ДAЙMET ELSE begin if RT_First(@Q0414_P) then assign(Q0414_P, RT_TmpName); REWRITE(ДP) end;
IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'! НА ВОССТАНОВЛЕНИЕ:');
BOC:=RBEЩ(MINПPOЦ,MAXПPOЦ);IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'! НА КАП.РЕМОНТ:');
KAП:=RBEЩ(0.0,MAXПPOЦ);IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'МЕСЯЦ ПРИОБРЕТЕНИЯ:');
CTOИT.ПPИHЯЛ:=RЦEЛ(MINMEC,MAXMEC);IF HAЧ THEN EXIT;
(**)
CTOИT.CПИCAЛ:=0;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО ВЫ ВВЕЛИ:');PUTT;WKAPT;WCTO;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРАВИЛЬНОСТЬ КАРТЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&HAЙTИ ПO-KЛЮ ШИФP.HOMEP B SY-ШИФ&&;
  IF ПYCTO THEN begin &&ПOCTAB ШИФP&&; end ;
  &&ПOCTAB ПPИБOP;ПOCTAB ИHB;ПOCTAB CTOИT&&;ПOCMET;
  YCTMOД;
  WRITE(OUTPUT,'КАРТА ЗАРЕГИСТРИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА');PUTT;
UNTIL NOT EЩE('ЕЩЕ!  ') OR HAЧ;
END;



PROCEDURE KOП;
BEGIN
IF NOT KAPTA THEN EXIT;
REPEAT
(**)
IF NOT ИHBHOM THEN EXIT;
(**)
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'МЕСЯЦ ПРИОБРЕТЕНИЯ:');
CTOИT.ПPИHЯЛ:=RЦEЛ(MINMEC,MAXMEC);
IF HAЧ THEN EXIT;
(**)
CTOИT.CПИCAЛ:=0;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО ПОЛУЧИЛОСЬ:');PUTT;WKAPT;WCTO;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРАВИЛЬНОСТЬ КАРТЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTAB ИHB;ПOCTAB CTOИT&&;YCTMOД;
  WRITE(OUTPUT,'КАРТА ЗАРЕГИСТРИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА');PUTT;
UNTIL NOT EЩE('ЕЩЕ!  ') OR HAЧ;
END;



PROCEDURE ПOB;
BEGIN
IF NOT KAPTA THEN EXIT;
&&HAЙTИ ПEPBYЮ B ИH-CTO;BЗЯTЬ&&;
IF CTOИT.CПИCAЛ<>0 THEN begin WRITE(OUTPUT,
  'ПОВТОРЯТЬ МОЖНО ТОЛЬКО НИ РАЗУ НЕ СПИСАННЫЕ НАИМЕНОВАНИЯ');
  PUTT;EXIT end ;
REPEAT
(**)
IF NOT ИHBHOM THEN EXIT;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО ПОЛУЧИЛОСЬ:');PUTT;WKAPT;WCTO;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРАВИЛЬНОСТЬ КАРТЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTAB ИHB;ПOCTAB CTOИT&&;YCTMOД;
  WRITE(OUTPUT,'КАРТА ЗАРЕГИСТРИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА');PUTT;
UNTIL NOT EЩE('ЕЩЕ!  ') OR HAЧ;
END;



PROCEDURE ИCK;
VAR OTД:ALFA;DEL:BOOL;


BEGIN
IF NOT KAPTA THEN EXIT;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ЕЕ ИСКЛЮЧЕНИЕ:');
IF ДA AND NOT HAЧ THEN begin 
  YHAP(&&HAБ ИH-CTO&&);&&YБPATЬ ИHB&&;
  IF COUNT(&&HAБ ПP-ИHB&&)=0 THEN begin 
    YHAP(&&HAБ ПP-COД&&);&&YБPATЬ ПPИБOP&&; end ;
  IF COUNT(&&HAБ ШИ-ПPИ&&)=0 THEN begin &&YБPATЬ ШИФP&&; end ;
  YCTMOД;WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА ОСТАВЛЕНА');PUTT;
END;



PROCEDURE CПИ;
VAR N:INT;
BEGIN
IF NOT KAPTA THEN EXIT;
&&HAЙTИ ПOCЛEД B ИH-CTO;BЗЯTЬ;HAЙTИ BЛAДEЛ B OT-CTO;BЗЯTЬ&&;
IF CTOИT.CПИCAЛ<>0 THEN begin 
  WRITE(OUTPUT,'ЭТО НАИМЕНОВАНИЕ УЖЕ СПИСАНО');PUTT;EXIT end ;
(**)
WRITE(OUTPUT,'МЕСЯЦ СПИСАНИЯ:');
N:=CTOИT.ПPИHЯЛ;IF N=0 THEN N:=MINMEC;
CTOИT.CПИCAЛ:=RЦEЛ(N,MAXMEC);
IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО У ВАС ПОЛУЧИЛОСЬ:');PUTT;WCTO;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ СПИСАНИЕ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'СПИСАНИЕ ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
&&ЗAMEHИTЬ CTOИT&&;YCTMOД;ECTЬ;
END;



PROCEDURE ПEP;
VAR N,KYП,ПPOД,MECПEP:INT;HOBOT:ALFA;HECTOЯЛ:BOOL;
BEGIN
IF NOT KAPTA THEN EXIT;
&&HAЙTИ ПOCЛEД B ИH-CTO;BЗЯTЬ;HAЙTИ BЛAДEЛ B OT-CTO;BЗЯTЬ&&;
IF CTOИT.CПИCAЛ<>0 THEN begin 
  WRITE(OUTPUT,'ЭТО НАИМЕНОВАНИЕ УЖЕ СПИСАНО');PUTT;EXIT end ;
(**)
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');HOBOT:=ROTД;IF HAЧ THEN EXIT;
IF HOBOT=OTДEЛ.HAЗB THEN begin 
  WRITE(OUTPUT,'ЭТО НАИМЕНОВАНИЕ УЖЕ ЧИСЛИТСЯ В ЭТОМ ОТДЕЛЕ');
  PUTT;EXIT end ;
WRITE(OUTPUT,'МЕСЯЦ ПЕРЕДАЧИ:');
N:=CTOИT.ПPИHЯЛ;IF N=0 THEN N:=MINMEC;
MECПEP:=RЦEЛ(N+1,MAXMEC);
IF HAЧ THEN EXIT;
(**)
IF MECПEP=1 THEN CTOИT.CПИCAЛ:=12
            ELSE CTOИT.CПИCAЛ:=MECПEP-1;
HECTOЯЛ:=CTOИT.ПPИHЯЛ>CTOИT.CПИCAЛ;
WRITE(OUTPUT,'СПИСАН:');WCTO;
KYП:=CTOИT.ПPИHЯЛ;ПPOД:=CTOИT.CПИCAЛ;
CTOИT.ПPИHЯЛ:=MECПEP;CTOИT.CПИCAЛ:=0;OTДEЛ.HAЗB:=HOBOT;
WRITE(OUTPUT,'ПРИНЯТ:');WCTO;
IF HECTOЯЛ THEN begin WRITE(OUTPUT,
  'ПЕРЕДАЮЩИЙ ОТДЕЛ БУДЕТ ИСКЛЮЧЕН ИЗ СПИСКОВ ЭТОГО НАИМЕНОВАНИЯ');
  PUTT end ;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПЕРЕВОД');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ПЕРЕВОД ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
CTOИT.ПPИHЯЛ:=KYП;CTOИT.CПИCAЛ:=ПPOД;
IF HECTOЯЛ THEN begin &&YБPATЬ CTOИT&&; end 
           ELSE begin &&ЗAMEHИ CTOИT&&; end ;
CTOИT.ПPИHЯЛ:=MECПEP;CTOИT.CПИCAЛ:=0;
&&HAЙTИ ПO-KЛЮ HOBOT B SY-OTД;ПOCTAB CTOИT&&;YCTMOД;ECTЬ;
END;



BEGIN
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ РЕГИСТРАЦИИ КАРТ...');PUTT;
KYДA:='НАРУЖУ';
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПРО - ПРОСМОТР ХРАНЯЩИХСЯ КАРТ/',
          'НОВ - ВВОД НОВЫХ КАРТ/',
          'ПОВ - ПОВТОРЕНИЕ КАРТЫ В ОТДЕЛЕ/',
          'КОП - КОПИРОВАНИЕ КАРТЫ ИЗ ОТДЕЛА В ОТДЕЛ/',
          'ИСК - ИСКЛЮЧЕНИЕ КАРТ/',
          'ПЕР - ПЕРЕДАЧА НАИМ.В ДРУГОЙ ОТДЕЛ/',
          'СПИ - СПИСАНИЕ НАИМЕНОВАНИЙ/');
MENU;

  if 'ПРО'=ДИP then begin ПPO end else if 
  'ПОВ'=ДИP then begin ПOB end else if 
  'КОП'=ДИP then begin KOП end else if 
  'ПЕР'=ДИP then begin ПEP end else if 
  'НОВ'=ДИP then begin HOB end else if 
  'ИСК'=ДИP then begin ИCK end else if 
  'СПИ'=ДИP then begin CПИ end else if 
  'КОН'=ДИP then begin EXIT end else if 
  'ВЫХ'=ДИP then begin EXIT  end   end ;
END;



BEGIN REGIS END.
