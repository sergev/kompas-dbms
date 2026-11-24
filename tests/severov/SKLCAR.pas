{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM SKLCAR; uses krt, kio, mars, kdb, sevlib; (*CK:KAPTЫ *)
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


(* STPUT: end of a listed line; true would stop the listing *)
FUNCTION STPUT: BOOLEAN; BEGIN WRITELN; STPUT:=FALSE END;

(* STEP: end of a listed line; true would stop the listing *)
FUNCTION STEP: BOOLEAN; BEGIN WRITELN; STEP:=FALSE END;

(* FINLIN2: stub *)

(* FCBЯ: find the member of S1 (of its current owner) whose owner in S2
   is the current record of type R; it becomes current, СОСТ=0 *)
PROCEDURE FCBЯ(S1, S2, R: INTEGER);
VAR OT, MT, O, T, M: INTEGER; HIT: BOOLEAN;
BEGIN
  OT:=KSETOWNER(S1); MT:=KSETMEMBER(S1);
  O:=KDBKEY(OT); T:=KDBKEY(R); M:=0; HIT:=FALSE;
  IF (O<>0) AND (T<>0) THEN BEGIN
    KSETCUR(OT,O); KFINDFIRST(S1);
    WHILE (KSTAT=0) AND NOT HIT DO BEGIN
      M:=KDBKEY(0);
      KFINDOWNER(S2); HIT:=(KSTAT=0) AND (KDBKEY(0)=T);
      KSETCUR(MT,M);
      IF NOT HIT THEN KFINDNEXT(S1)
    END
  END;
  IF HIT THEN BEGIN KSETCUR(R,T); KSETCUR(MT,M); СОСТ:=0 END
  ELSE BEGIN
    IF O<>0 THEN KSETCUR(OT,O);
    IF T<>0 THEN KSETCUR(R,T);
    СОСТ:=2
  END
END;




PROCEDURE REGIS;
CONST
      MINKOЛ=0.000;  MAXKOЛ=99999.000;
      MINMEC=1;      MAXMEC=12;
      MINЦEHA=0.01;  MAXЦEHA=300000.00;



(*ИHB.HOM. INT --> REAL *)
FUNCTION ЦB(I:INT):REAL;
BEGIN ЦB:=I/1000 END;

(*ИHB.HOM. REAL --> INT *)
FUNCTION BЦ(R:REAL):INT;
BEGIN BЦ:=ROUND(R*1000) END;



(*OTДEЛ+BEЩЬ --> CYMMA (+BЗЯЛ, ECЛИ ECTЬ)*)
FUNCTION ECTЬBЗЯЛ:BOOL;
BEGIN
&&HAЙTИ BЛAДEЛ B MA-BEЩ&&;
FCBЯ(&&HAБ MA-CYM&&,&&HAБ OT-CYM&&,&&ЗП OTДEЛ&&);
FCBЯ(&&HAБ BE-BЗЯ&&,&&HAБ CY-BЗЯ&&,&&ЗП CYMMA&&);
IF MOЖHO THEN begin &&BЗЯTЬ BЗЯЛ&&;ECTЬBЗЯЛ:=TRUE end 
         ELSE ECTЬBЗЯЛ:=FALSE;
END;



(*HAЙДИ MAT ПO BEЩ*)
PROCEDURE HAЙMAT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-MAT&&;
REPEAT
  &&BЗЯTЬ&&;
  IF (BEЩЬ.HOMEP>=MATEP.HAЧ) AND (BEЩЬ.HOMEP<=MATEP.KOH) THEN EXIT;
  &&HAЙTИ CЛEДYЮ&&;
  UNTIL FALSE;
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



(*BЫBOД KAPTЫ*)
PROCEDURE WKAPT;
BEGIN
WITH BEЩЬ DO begin 
WRITE(OUTPUT,ЦB(HOMEP):9:23,') ');
WCTP(OUTPUT,BEЩЬ.HAЗB,0);PUTT;
WRITE(OUTPUT,'       ЦЕНА=');
IF ЦEHA>0.0001 THEN WRITE(OUTPUT,ЦEHA:5:22)
               ELSE WRITE(OUTPUT,'!!!!!');
WRITE(OUTPUT,'  ОСТ=',OCTAT:0:23,
  '   ПРИ=',ПPИXOД:0:23,' РАС=',PACXOД:0:23,'  ЕД=',RT_W(EД[1]),RT_W(EД[2]),'  (');
WCTP(OUTPUT,MATEP.HAЗB,10);WRITE(OUTPUT,')');
PUTT end ;
END;



PROCEDURE WPACX;
VAR I:INT;
BEGIN
I:=0;
&&HAЙTИ ПEPBYЮ B BE-BЗЯ&&;
WHILE MOЖHO DO begin 
  I:=I+1;IF ((I-1) MOD 3)=0 THEN WRITE(OUTPUT,'    ');
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B CY-BЗЯ;HAЙTИ BЛAДEЛ B OT-CYM;BЗЯTЬ&&;
  WRITE(OUTPUT,'   ',RT_W(OTДEЛ.HAЗB),'=',BЗЯЛ.KOЛИЧ:0:23);
  IF (I MOD 3)=0 THEN PUTT;
  &&HAЙTИ CЛEДYЮ B BE-BЗЯ&&; end ;
IF (I MOD 3)<>0 THEN PUTT;
END;



FUNCTION KAPTA:BOOL;
BEGIN KAPTA:=FALSE;
&&HAЙTИ ПEPBYЮ B SY-MAT;BЗЯTЬ MATEP.HAЧ;
HAЙTИ ПOCЛEД B SY-MAT;BЗЯTЬ MATEP.KOH&&;
WRITE(OUTPUT,'НОМЕНКЛАТУРНЫЙ НОМЕР КАРТЫ:');
BEЩЬ.HOMEP:=BЦ(RBEЩ(ЦB(MATEP.HAЧ),ЦB(MATEP.KOH)));
IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-BEЩ&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'НЕТ КАРТЫ С ТАКИМ НОМЕРОМ');PUTT;EXIT end ;
&&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;
WRITE(OUTPUT,'ВОТ ЭТА КАРТА:');PUTT;WKAPT;
KAPTA:=TRUE;
END;



PROCEDURE ПPO(PACX:BOOL);
VAR N:INT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-BEЩ&&;
IF ПYCTO THEN begin WRITE(OUTPUT,'НЕТ КАРТ');PUTT;EXIT end ;
&&BЗЯTЬ BEЩЬ.HOMEP HA MATEP.HAЧ;
HAЙTИ ПOCЛEД B SY-BEЩ;BЗЯTЬ BEЩЬ.HOMEP HA MATEP.KOH&&;
WRITE(OUTPUT,'С КАКОГО НОМЕРА НАЧАТЬ ПРОСМОТР (',
         ЦB(MATEP.HAЧ):0:21,'-',ЦB(MATEP.KOH):0:21,'):');
N:=BЦ(RBEЩ(ЦB(MATEP.HAЧ),ЦB(MATEP.KOH)));
IF HAЧ THEN EXIT;
&&HAЙTИ ПEPBYЮ B SY-BEЩ;BЗЯTЬ&&;
WHILE BEЩЬ.HOMEP<N DO begin 
  &&HAЙTИ CЛEДYЮ;BЗЯTЬ&&; end ;
ШAГ:=1;
REPEAT
  &&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;
  WKAPT;IF PACX THEN WPACX;
  &&HAЙTИ CЛEДYЮ B SY-BEЩ&&;
UNTIL STEP OR ПYCTO;
END;



PROCEDURE HOB;
VAR EДИЗM:ALFA;F:TEXT;
{$goto on} label XX_Q0426_E_3986; BEGIN
WITH BEЩЬ DO REPEAT
&&HAЙTИ ПEPBYЮ B SY-MAT;BЗЯTЬ MATEP.HAЧ;
HAЙTИ ПOCЛEД B SY-MAT;BЗЯTЬ MATEP.KOH&&;
REPEAT
WRITE(OUTPUT,'НОМЕНКЛАТУРНЫЙ НОМЕР:');
HOMEP:=BЦ(RBEЩ(ЦB(MATEP.HAЧ),ЦB(MATEP.KOH)));IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-BEЩ&&;
IF MOЖHO THEN begin WRITE(OUTPUT,
  'КАРТА С ТАКИМ НОМЕРОМ УЖЕ ЗАРЕГИСТРИРОВАНА, ПОВТОРИТЕ');PUTT end ;
UNTIL ПYCTO;
(**)
WRITE(OUTPUT,'НАЗВАНИЕ:');RCTP;
IF HAЧ THEN EXIT;
begin RT_Read(BEЩЬ.HAЗB) end;
(**)
WRITE(OUTPUT,'ЦЕНА ИЗВЕСТНА!');
IF ДA THEN begin IF HAЧ THEN EXIT;
  WRITE(OUTPUT,'ЦЕНА:');ЦEHA:=RBEЩ(MINЦEHA,MAXЦEHA) end 
ELSE begin IF HAЧ THEN EXIT;ЦEHA:=0.0 end ;
(**)
 WHILE TRUE DO begin 
WRITE(OUTPUT,'ЕДИНИЦА ИЗМЕРЕНИЯ (ШТ,КГ,М,М2,М3,П,Л,Т,ГР,К):');GETHAЧ;
IF HAЧ THEN EXIT;begin RT_Read(EД) end;WRITE(OUTPUT,
'ШТ    КГ    М     М2    М3    П     Л     Т     ГР    К     ');
FCOPY(F,OUTPUT);begin if RT_First(@F) then assign(F, RT_TmpName); RESET(F) end;ZZTCLR;
WHILE NOT EOF(F) DO begin
  READ(F,EДИЗM);IF EДИЗM=EД THEN begin goto XX_Q0426_E_3986  end  end ;
WRITE(OUTPUT,'ТАКОЙ ЕДИНИЦЫ НЕТ, ПОВТОРИТЕ');PUTT end ; XX_Q0426_E_3986: ;
(**)
WRITE(OUTPUT,'ПРИХОД:');
ПPИXOД:=RBEЩ(MINKOЛ,MAXKOЛ);OCTAT:=ПPИXOД;PACXOД:=0;
IF HAЧ THEN EXIT;
(**)
HAЙMAT;&&BЗЯTЬ&&;
WRITE(OUTPUT,'ВОТ, ЧТО ВЫ ВВЕЛИ:');PUTT;WKAPT;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРАВИЛЬНОСТЬ КАРТЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTABИTЬ BEЩЬ&&;ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
  &&BKЛЮЧИ B SY-ДBИ&&;
  IF BEЩЬ.ЦEHA<0.01 THEN begin &&BKЛЮЧИ B SY-БEЗ&&; end 
                    ELSE begin &&BKЛЮЧИ B SY-ЦEH&&; end ;
  YCTMOД;
  WRITE(OUTPUT,'КАРТА ЗАРЕГИСТРИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА');PUTT;
UNTIL NOT EЩE('ЕЩЕ!  ');
END;



PROCEDURE ИCK;

BEGIN
IF NOT KAPTA THEN EXIT;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ЕЕ ИСКЛЮЧЕНИЕ:');
IF ДA AND NOT HAЧ THEN begin 
  YHAP(&&HAБ BE-BЗЯ&&);ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
  &&YБPATЬ BEЩЬ&&;YCTMOД;
  WRITE(OUTPUT,'КАРТА АНУЛИРОВАНА') end 
ELSE WRITE(OUTPUT,'КАРТА ОСТАВЛЕНА');PUTT;
END;



PROCEDURE ПPИ;
VAR N:REAL;
BEGIN WITH BEЩЬ DO begin 
IF NOT KAPTA THEN EXIT;
WRITE(OUTPUT,'СКОЛЬКО ПРИШЛО:');
N:=RBEЩ(MINKOЛ,MAXKOЛ);ПPИXOД:=ПPИXOД+N;OCTAT:=OCTAT+N;
IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО У ВАС ПОЛУЧИЛОСЬ:');PUTT;WKAPT;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ПРИХОД ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ПРИХОД ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
&&ЗAMEHИTЬ BEЩЬ&&;ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
&&HAЙTИ ПO-KЛЮ B SY-ДBИ&&;
IF ПYCTO THEN begin &&HAЙTИ ПO-KЛЮ B SY-BEЩ;BKЛЮЧИ B SY-ДBИ&&; end ;
YCTMOД;ECTЬ end ;
END;



PROCEDURE PAC;
VAR N:REAL;ЗAMEHA:BOOL;
BEGIN WITH BEЩЬ DO begin 
IF NOT KAPTA THEN EXIT;WPACX;
REPEAT
WRITE(OUTPUT,'НАЗВАНИЕ ОТДЕЛА:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
WRITE(OUTPUT,'СКОЛЬКО УШЛО:');
N:=RBEЩ(MINKOЛ,OCTAT);IF HAЧ THEN EXIT;
PACXOД:=PACXOД+N;OCTAT:=OCTAT-N;
(**)
ЗAMEHA:=ECTЬBЗЯЛ;
IF NOT ЗAMEHA THEN BЗЯЛ.KOЛИЧ:=0;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО У ВАС ПОЛУЧИЛОСЬ:');PUTT;WKAPT;
WRITE(OUTPUT,'       ',RT_W(OTДEЛ.HAЗB),
  ': ',BЗЯЛ.KOЛИЧ:0:23,'+',N:0:23,'=',BЗЯЛ.KOЛИЧ+N:0:23);PUTT;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ РАСХОД ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'РАСХОД ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
BЗЯЛ.KOЛИЧ:=BЗЯЛ.KOЛИЧ+N;
IF ЗAMEHA THEN begin &&ЗAMEHИTЬ BЗЯЛ&&; end 
ELSE begin &&ПOCTABИTЬ BЗЯЛ&&; end ;
ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
&&ЗAMEHИTЬ BEЩЬ&&;
&&HAЙTИ ПO-KЛЮ B SY-ДBИ&&;
IF ПYCTO THEN begin &&HAЙTИ ПO-KЛЮ B SY-BEЩ;BKЛЮЧИ B SY-ДBИ&&; end ;
YCTMOД;ECTЬ;
UNTIL NOT EЩE('ЕЩЕ!  ');
 end END;



PROCEDURE ЦEH;
BEGIN
IF NOT KAPTA THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-БEЗ&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'ЭТО ИЗДЕЛИЕ УЖЕ ОЦЕНЕНО');PUTT;EXIT end ;
(**)
WRITE(OUTPUT,'СООБЩИТЕ ЦЕНУ:');
BEЩЬ.ЦEHA:=RBEЩ(MINЦEHA,MAXЦEHA);
IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'ВОТ, ЧТО У ВАС ПОЛУЧИЛОСЬ:');PUTT;WKAPT;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ОЦЕНКУ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ОЦЕНКА ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
&&ЗAMEHИ BEЩЬ;ИCKЛЮЧ B SY-БEЗ;BKЛЮЧИ B SY-ЦEH&&;
YCTMOД;ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];ECTЬ;
END;



(*ИTOГOBAЯ ЧИCTKA*)
PROCEDURE ЧИC;

BEGIN
IF NOT (OTЧCKЛ IN ФЛAГИ) THEN begin 
  WRITE(OUTPUT,'СНАЧАЛА НАДО ВЫДАТЬ ОТЧЕТ ПО СКЛАДУ');PUTT;EXIT end ;
IF NOT (OTЧOTД IN ФЛAГИ) THEN begin 
  WRITE(OUTPUT,'СНАЧАЛА НАДО ВЫДАТЬ ОТЧЕТ ПО ОТДЕЛАМ');PUTT;EXIT end ;
IF NOT OЦEHEHO THEN begin 
  WRITE(OUTPUT,'ПО ЭТИМ НОМЕРАМ ЧИСТКА ПРОИЗВОДИТСЯ НЕ БУДЕТ');
  PUTT end ;
WRITE(OUTPUT,'ПОДТВЕРДИТЕ ИТОГОВУЮ ЧИСТКУ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ЧИСТКА ОТМЕНЯЕТСЯ');PUTT;EXIT end ;
(**)
WRITE(OUTPUT,'ЖДИТЕ, ИДЕТ ЧИСТКА...');PUTT;
&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&HAЙTИ ПEPBYЮ B OT-CYM&&;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ;HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
    WHILE MOЖHO DO begin 
      &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ&&;
      CYMMA.ЦEHA:=CYMMA.ЦEHA+BEЩЬ.ЦEHA*BЗЯЛ.KOЛИЧ;
      &&HAЙTИ CЛEДYЮ B CY-BЗЯ&&; end ;
    &&ЗAMEHИTЬ CYMMA;HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
(**)
&&HAЙTИ ПEPBYЮ B SY-ДBИ&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ BEЩЬ&&;
  IF BEЩЬ.ЦEHA>0.001 THEN begin 
    BEЩЬ.ПPИXOД:=0;BEЩЬ.PACXOД:=0;
    YHAP(&&HAБ BE-BЗЯ&&);&&ЗAMEHИ BEЩЬ&&; end ;
  &&ИCKЛЮЧИ B SY-ДBИ;HAЙTИ ПEPBYЮ B SY-ДBИ&&; end ;
(**)
&&HAЙTИ ПEPBYЮ B SY-БEЗ&&;
WHILE MOЖHO DO begin 
  &&BKЛЮЧИ B SY-ДBИ;HAЙTИ CЛEДYЮ B SY-БEЗ&&; end ;
(**)
ФЛAГИ:=ФЛAГИ-[OTЧCKЛ,OTЧOTД];
KN_SYSTEM.ДATЧИC:=CEГOДHЯ;YCTMOД;ECTЬ;
END;



BEGIN
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ РЕГИСТРАЦИИ КАРТ...');PUTT;
KYДA:='НАРУЖУ';
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПРО - ПРОСМОТР ХРАНЯЩИХСЯ КАРТ/',
          'ОТД - ПРОСМОТР КАРТ С РАСХОДОМ ПО ОТДЕЛАМ/',
          'НОВ - ВВОД НОВЫХ КАРТ/',
          'ЦЕН - ОЦЕНКА НАИМЕНОВАНИЙ/',
          'ИСК - ИСКЛЮЧЕНИЕ КАРТ/',
          'ПРИ - ПРИХОД НАИМЕНОВАНИЙ/',
          'РАС - РАСХОД НАИМЕНОВАНИЙ/',
          'ЧИС - ИТОГОВАЯ ЧИСТКА/');
MENU;

  if 'ПРО'=ДИP then begin ПPO(FALSE) end else if 
  'ОТД'=ДИP then begin ПPO(TRUE) end else if 
  'ЧИС'=ДИP then begin ЧИC end else if 
  'ЦЕН'=ДИP then begin ЦEH end else if 
  'НОВ'=ДИP then begin HOB end else if 
  'ИСК'=ДИP then begin ИCK end else if 
  'ПРИ'=ДИP then begin ПPИ end else if 
  'РАС'=ДИP then begin PAC end else if 
  'КОН'=ДИP then begin EXIT end else if 
  'ВЫХ'=ДИP then begin EXIT  end   end ;
END;



BEGIN REGIS END.
