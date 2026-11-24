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

(* FCBЯ: link records through two sets (stub) *)
PROCEDURE FCBЯ(S1, S2, R: INTEGER); BEGIN END;




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
    WRITE(OUTPUT,'HE OЦEHEHЫ CЛEДYЮЩИE HOMEPA:');PUTT end ;
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
WRITE(OUTPUT,'       ЦEHA=');
IF ЦEHA>0.0001 THEN WRITE(OUTPUT,ЦEHA:5:22)
               ELSE WRITE(OUTPUT,'!!!!!');
WRITE(OUTPUT,'  OCT=',OCTAT:0:23,
  '   ПPИ=',ПPИXOД:0:23,' PAC=',PACXOД:0:23,'  EД=',RT_W(EД[1]),RT_W(EД[2]),'  (');
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
WRITE(OUTPUT,'HOMEHKЛATYPHЫЙ HOMEP KAPTЫ:');
BEЩЬ.HOMEP:=BЦ(RBEЩ(ЦB(MATEP.HAЧ),ЦB(MATEP.KOH)));
IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-BEЩ&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'HET KAPTЫ C TAKИM HOMEPOM');PUTT;EXIT end ;
&&BЗЯTЬ;HAЙTИ BЛAДEЛ B MA-BEЩ;BЗЯTЬ&&;
WRITE(OUTPUT,'BOT ЭTA KAPTA:');PUTT;WKAPT;
KAPTA:=TRUE;
END;



PROCEDURE ПPO(PACX:BOOL);
VAR N:INT;
BEGIN
&&HAЙTИ ПEPBYЮ B SY-BEЩ&&;
IF ПYCTO THEN begin WRITE(OUTPUT,'HET KAPT');PUTT;EXIT end ;
&&BЗЯTЬ BEЩЬ.HOMEP HA MATEP.HAЧ;
HAЙTИ ПOCЛEД B SY-BEЩ;BЗЯTЬ BEЩЬ.HOMEP HA MATEP.KOH&&;
WRITE(OUTPUT,'C KAKOГO HOMEPA HAЧATЬ ПPOCMOTP (',
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
VAR EДИЗM:ALFA;
{$goto on} label XX_Q66_E_3986; BEGIN
WITH BEЩЬ DO REPEAT
&&HAЙTИ ПEPBYЮ B SY-MAT;BЗЯTЬ MATEP.HAЧ;
HAЙTИ ПOCЛEД B SY-MAT;BЗЯTЬ MATEP.KOH&&;
REPEAT
WRITE(OUTPUT,'HOMEHKЛATYPHЫЙ HOMEP:');
HOMEP:=BЦ(RBEЩ(ЦB(MATEP.HAЧ),ЦB(MATEP.KOH)));IF HAЧ THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-BEЩ&&;
IF MOЖHO THEN begin WRITE(OUTPUT,
  'KAPTA C TAKИM HOMEPOM YЖE ЗAPEГИCTPИPOBAHA, ПOBTOPИTE');PUTT end ;
UNTIL ПYCTO;
(**)
WRITE(OUTPUT,'HAЗBAHИE:');RCTP;
IF HAЧ THEN EXIT;
begin RT_Read(BEЩЬ.HAЗB) end;
(**)
WRITE(OUTPUT,'ЦEHA ИЗBECTHA!');
IF ДA THEN begin IF HAЧ THEN EXIT;
  WRITE(OUTPUT,'ЦEHA:');ЦEHA:=RBEЩ(MINЦEHA,MAXЦEHA) end 
ELSE begin IF HAЧ THEN EXIT;ЦEHA:=0.0 end ;
(**)
 WHILE TRUE DO begin 
WRITE(OUTPUT,'EДИHИЦA ИЗMEPEHИЯ (ШT,KГ,M,M2,M3,П,Л,T,ГP,K):');GETHAЧ;
IF HAЧ THEN EXIT;begin RT_Read(EД) end;WRITE(OUTPUT,
'ШT    KГ    M     M2    M3    П     Л     T     ГP    K     ');
RESET(OUTPUT);
WHILE NOT EOF(OUTPUT) DO begin 
  READ(OUTPUT,EДИЗM);IF EДИЗM=EД THEN begin ZZTCLR;goto XX_Q66_E_3986  end  end ;
ZZTCLR;
WRITE(OUTPUT,'TAKOЙ EДИHИЦЫ HET, ПOBTOPИTE');PUTT end ; XX_Q66_E_3986: ;
(**)
WRITE(OUTPUT,'ПPИXOД:');
ПPИXOД:=RBEЩ(MINKOЛ,MAXKOЛ);OCTAT:=ПPИXOД;PACXOД:=0;
IF HAЧ THEN EXIT;
(**)
HAЙMAT;&&BЗЯTЬ&&;
WRITE(OUTPUT,'BOT, ЧTO BЫ BBEЛИ:');PUTT;WKAPT;
WRITE(OUTPUT,'ПOДTBEPДИTE ПPABИЛЬHOCTЬ KAPTЫ');
IF ДA AND NOT HAЧ THEN begin 
  &&ПOCTABИTЬ BEЩЬ&&;ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
  &&BKЛЮЧИ B SY-ДBИ&&;
  IF BEЩЬ.ЦEHA<0.01 THEN begin &&BKЛЮЧИ B SY-БEЗ&&; end 
                    ELSE begin &&BKЛЮЧИ B SY-ЦEH&&; end ;
  YCTMOД;
  WRITE(OUTPUT,'KAPTA ЗAPEГИCTPИPOBAHA') end 
ELSE WRITE(OUTPUT,'KAPTA AHYЛИPOBAHA');PUTT;
UNTIL NOT EЩE('EЩE!  ');
END;



PROCEDURE ИCK;

BEGIN
IF NOT KAPTA THEN EXIT;
WRITE(OUTPUT,'ПOДTBEPДИTE EE ИCKЛЮЧEHИE:');
IF ДA AND NOT HAЧ THEN begin 
  YHAP(&&HAБ BE-BЗЯ&&);ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
  &&YБPATЬ BEЩЬ&&;YCTMOД;
  WRITE(OUTPUT,'KAPTA AHYЛИPOBAHA') end 
ELSE WRITE(OUTPUT,'KAPTA OCTABЛEHA');PUTT;
END;



PROCEDURE ПPИ;
VAR N:REAL;
BEGIN WITH BEЩЬ DO begin 
IF NOT KAPTA THEN EXIT;
WRITE(OUTPUT,'CKOЛЬKO ПPИШЛO:');
N:=RBEЩ(MINKOЛ,MAXKOЛ);ПPИXOД:=ПPИXOД+N;OCTAT:=OCTAT+N;
IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'BOT, ЧTO Y BAC ПOЛYЧИЛOCЬ:');PUTT;WKAPT;
WRITE(OUTPUT,'ПOДTBEPДИTE ПPИXOД ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ПPИXOД OTMEHЯETCЯ');PUTT;EXIT end ;
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
WRITE(OUTPUT,'HAЗBAHИE OTДEЛA:');OTДEЛ.HAЗB:=ROTД;IF HAЧ THEN EXIT;
WRITE(OUTPUT,'CKOЛЬKO YШЛO:');
N:=RBEЩ(MINKOЛ,OCTAT);IF HAЧ THEN EXIT;
PACXOД:=PACXOД+N;OCTAT:=OCTAT-N;
(**)
ЗAMEHA:=ECTЬBЗЯЛ;
IF NOT ЗAMEHA THEN BЗЯЛ.KOЛИЧ:=0;
(**)
WRITE(OUTPUT,'BOT, ЧTO Y BAC ПOЛYЧИЛOCЬ:');PUTT;WKAPT;
WRITE(OUTPUT,'       ',RT_W(OTДEЛ.HAЗB),
  ': ',BЗЯЛ.KOЛИЧ:0:23,'+',N:0:23,'=',BЗЯЛ.KOЛИЧ+N:0:23);PUTT;
WRITE(OUTPUT,'ПOДTBEPДИTE PACXOД ');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'PACXOД OTMEHЯETCЯ');PUTT;EXIT end ;
BЗЯЛ.KOЛИЧ:=BЗЯЛ.KOЛИЧ+N;
IF ЗAMEHA THEN begin &&ЗAMEHИTЬ BЗЯЛ&&; end 
ELSE begin &&ПOCTABИTЬ BЗЯЛ&&; end ;
ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];
&&ЗAMEHИTЬ BEЩЬ&&;
&&HAЙTИ ПO-KЛЮ B SY-ДBИ&&;
IF ПYCTO THEN begin &&HAЙTИ ПO-KЛЮ B SY-BEЩ;BKЛЮЧИ B SY-ДBИ&&; end ;
YCTMOД;ECTЬ;
UNTIL NOT EЩE('EЩE!  ');
 end END;



PROCEDURE ЦEH;
BEGIN
IF NOT KAPTA THEN EXIT;
&&HAЙTИ ПO-KЛЮ B SY-БEЗ&&;
IF ПYCTO THEN begin 
  WRITE(OUTPUT,'ЭTO ИЗДEЛИE YЖE OЦEHEHO');PUTT;EXIT end ;
(**)
WRITE(OUTPUT,'COOБЩИTE ЦEHY:');
BEЩЬ.ЦEHA:=RBEЩ(MINЦEHA,MAXЦEHA);
IF HAЧ THEN EXIT;
(**)
WRITE(OUTPUT,'BOT, ЧTO Y BAC ПOЛYЧИЛOCЬ:');PUTT;WKAPT;
WRITE(OUTPUT,'ПOДTBEPДИTE OЦEHKY');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'OЦEHKA OTMEHЯETCЯ');PUTT;EXIT end ;
&&ЗAMEHИ BEЩЬ;ИCKЛЮЧ B SY-БEЗ;BKЛЮЧИ B SY-ЦEH&&;
YCTMOД;ФЛAГИ:=ФЛAГИ-[OTЧOTД,OTЧCKЛ];ECTЬ;
END;



(*ИTOГOBAЯ ЧИCTKA*)
PROCEDURE ЧИC;

BEGIN
IF NOT (OTЧCKЛ IN ФЛAГИ) THEN begin 
  WRITE(OUTPUT,'CHAЧAЛA HAДO BЫДATЬ OTЧET ПO CKЛAДY');PUTT;EXIT end ;
IF NOT (OTЧOTД IN ФЛAГИ) THEN begin 
  WRITE(OUTPUT,'CHAЧAЛA HAДO BЫДATЬ OTЧET ПO OTДEЛAM');PUTT;EXIT end ;
IF NOT OЦEHEHO THEN begin 
  WRITE(OUTPUT,'ПO ЭTИM HOMEPAM ЧИCTKA ПPOИЗBOДИTCЯ HE БYДET');
  PUTT end ;
WRITE(OUTPUT,'ПOДTBEPДИTE ИTOГOBYЮ ЧИCTKY');
IF NOT ДA OR HAЧ THEN begin 
  WRITE(OUTPUT,'ЧИCTKA OTMEHЯETCЯ');PUTT;EXIT end ;
(**)
WRITE(OUTPUT,'ЖДИTE, ИДET ЧИCTKA...');PUTT;
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
WRITE(OUTPUT,'      ...BЫ B БЛOKE PEГИCTPAЦИИ KAPT...');PUTT;
KYДA:='HAPYЖY';
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПPO - ПPOCMOTP XPAHЯЩИXCЯ KAPT/',
          'OTД - ПPOCMOTP KAPT C PACXOДOM ПO OTДEЛAM/',
          'HOB - BBOД HOBЫX KAPT/',
          'ЦEH - OЦEHKA HAИMEHOBAHИЙ/',
          'ИCK - ИCKЛЮЧEHИE KAPT/',
          'ПPИ - ПPИXOД HAИMEHOBAHИЙ/',
          'PAC - PACXOД HAИMEHOBAHИЙ/',
          'ЧИC - ИTOГOBAЯ ЧИCTKA/');
MENU;

  if 'ПPO'=ДИP then begin ПPO(FALSE) end else if 
  'OTД'=ДИP then begin ПPO(TRUE) end else if 
  'ЧИC'=ДИP then begin ЧИC end else if 
  'ЦEH'=ДИP then begin ЦEH end else if 
  'HOB'=ДИP then begin HOB end else if 
  'ИCK'=ДИP then begin ИCK end else if 
  'ПPИ'=ДИP then begin ПPИ end else if 
  'PAC'=ДИP then begin PAC end else if 
  'KOH'=ДИP then begin EXIT end else if 
  'BЫX'=ДИP then begin EXIT  end   end ;
END;



BEGIN REGIS END.
