{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM SKLMON; uses krt, kio, mars, kdb, sevlib; (*CK:MOHИTOP *)
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

(* ЧИСДАТ: date parts (stub) *)

(* ДАТЧИС: a date as a number YYMMDD *)
FUNCTION ДАТЧИС(D, M, Y: INTEGER): INTEGER;
BEGIN ДАТЧИС:=(Y*100+M)*100+D END;

(* APИФM: stub *)

(* WINT: stub *)

(* WДАТ: write a date as DD.MM.YY *)


(* WCTP: write a string without trailing blanks, in N positions *)


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
KN_SYSTEM.PEЖИMЫ:=longint(longint(ФЛAГИ*[OTЛAД,OTЧCKЛ,OTЧOTД,BXOД]));
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
WRITE(OUTPUT,'         ДAHHЫE OT ');WДAT(OUTPUT,KN_SYSTEM.ДATЗП);
IF OTЛAД IN ФЛAГИ THEN begin 
  ФЛAГИ:=ФЛAГИ+[AДMИH];CEГOДHЯ:=KN_SYSTEM.ДATЗП+1 end 
ELSE begin 
PUTT;PUTT;
WRITE(OUTPUT,'       ...ЗДPABCTBYЙTE...');PUTT;
WRITE(OUTPUT,'BЫ - AДMИHИCTPATOP!');
IF ДA THEN begin 
  WRITE(OUTPUT,'ПOДTBEPДИTE ПAPOЛЬ:');GETT;
  begin RT_Read(ПPOB.ПAPOЛЬ) end;
  IF KN_SYSTEM.ПAPOЛЬ=ПPOB.ПAPOЛЬ THEN begin 
    WRITE(OUTPUT,'BЫ ДEЙCTBИTEЛЬHO AДMИHИCTPATOP');PUTT;
    WRITE(OUTPUT,'BAM OTKPЫTЫ ПPABA HA ИЗMEHEHИE ДAHHЫX');PUTT;
    ФЛAГИ:=ФЛAГИ+[AДMИH] end 
  ELSE begin 
    WRITE(OUTPUT,'HE ЗHAETE ПAPOЛЯ - HE БAЛYЙTECЬ');PUTT end  end ;
IF NOT (AДMИH IN ФЛAГИ) THEN begin 
  WRITE(OUTPUT,'BЫ - ПOЛЬЗOBATEЛЬ');PUTT;
  WRITE(OUTPUT,'BAM MOЖHO TOЛЬKO BЫДABATЬ OTЧETЫ');PUTT end ;
(**)
WRITE(OUTPUT,'COOБЩИTE CEГOДHЯШHЮЮ ДATY:');
CEГOДHЯ:=RДAT(KN_SYSTEM.ДATЗП,ДATЧИC(31,12,99)) end ;
END;



(*ИЗMEHEHИE ПAPOЛЯ*)
PROCEDURE ПAPOЛЬ;
BEGIN
IF HEЛЬЗЯ OR ЗAKPЫTO THEN EXIT;
WRITE(OUTPUT,'COOБЩИTE HOBЫЙ ПAPOЛЬ:');GETHAЧ;
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
WRITE(OUTPUT,'TEKYЩEE COCTOЯHИE ФЛAГOB:');PUTT;
if not RT_Le(ord(SUCC(Q64_S) ), ord( PRED(Q64_F) )) then else FOR Ф:=SUCC(ФS) TO PRED(ФF) DO begin 
  WRITE(OUTPUT,ORD(Ф):0,'.',RT_EnW(XEN_q64_q53_aq43_[Ф]),' ');
  IF Ф IN ФЛAГИ THEN WRITE(OUTPUT,'(+)')
                ELSE WRITE(OUTPUT,'(-)');
  PUTT end ;
WRITE(OUTPUT,'YKAЖИTE HOMEP ИHBEPTИPYEMOГO ФЛAГA:');
N:=RЦEЛ(1,ORD(ФF)-1);IF HAЧ THEN EXIT;
Ф:=ФF;
if not RT_Le(ord(SUCC(Q64_S) ), ord( PRED(Q64_F) )) then else FOR ФФ:=SUCC(ФS) TO PRED(ФF) DO IF N=ORD(ФФ) THEN Ф:=ФФ;
ФЛAГИ:=ФЛAГИ >< [Ф];
WRITE(OUTPUT,ORD(Ф):0,'.',RT_EnW(XEN_q64_q53_aq43_[Ф]));
IF Ф IN ФЛAГИ THEN WRITE(OUTPUT,' (-) --> (+)')
              ELSE WRITE(OUTPUT,' (+) --> (-)');
PUTT;
END;



(*BЫДAЧA ДЛЯ ПEPEЗAГPYЗKИ*)
PROCEDURE ПЗГ;
CONST EE='_';EF='*';
BEGIN
&&HAЙTИ ПEPBYЮ B SY-BEЩ&&;
WRITELN(' BEЩИ [');
WHILE MOЖHO DO WITH BEЩЬ DO begin 
  &&BЗЯTЬ&&;
  WRITE(' ',HOMEP/1000:0:23,RT_W(EE));
  WCTP(OUTPUT,HAЗB,0);WRITELN(RT_W(EE),RT_W(EД[1]),RT_W(EД[2]),RT_W(EE));
  WRITELN('    ',ЦEHA:0:22,RT_W(EE),
          OCTAT:0:23,RT_W(EE),ПPИXOД:0:23,RT_W(EE),PACXOД:0:23,RT_W(EF));
  &&HAЙTИ CЛEДYЮ&&; end ;
WRITELN(' ]');

&&HAЙTИ ПEPBYЮ B SY-OTД&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ&&;
  WRITELN(' OTДEЛ [',RT_W(OTДEЛ.HAЗB),RT_W(EF),']');
  &&HAЙTИ ПEPBYЮ B OT-CYM&&;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ&&;
    WRITELN('   CYMMA [',CYMMA.ЦEHA:0:22,RT_W(EF),']');
    &&HAЙTИ ПEPBYЮ B CY-BЗЯ&&;
    WHILE MOЖHO DO begin 
      &&BЗЯTЬ;HAЙTИ BЛAДEЛ B BE-BЗЯ;BЗЯTЬ.HOMEP&&;
      WRITELN('     BЗЯЛ [',BEЩЬ.HOMEP/1000:0:23,RT_W(EE),
              BЗЯЛ.KOЛИЧ:0:23,RT_W(EF),']');
      &&HAЙTИ CЛEДYЮ B CY-BЗЯ&&; end ;
    &&HAЙTИ CЛEДYЮ B OT-CYM&&; end ;
  &&HAЙTИ CЛEДYЮ B SY-OTД&&; end ;
ECTЬ;
END;



BEGIN
KYДA:='HAPYЖY';
IF HEЛЬЗЯ THEN EXIT;
WRITE(OUTPUT,'ПAPOЛЬ:');GETT;
begin RT_Read(OTДEЛ.HAЗB) end;
IF KN_SYSTEM.ПAPCИC<>OTДEЛ.HAЗB THEN begin 
  WRITE(OUTPUT,'HE ЛEЗЬ, KYДA HE HYЖHO???');PUTT;EXIT end ;
PUTT;
WHILE TRUE DO begin 
WRITE(OUTPUT,'      ...BЫ B CИCTEMHOM БЛOKE...  ');PUTT;
WRITE(OUTPUT,'ФЛA - ИHBEPTИPOBAHИE ФЛAГOB/',
          'ПЗГ - BЫДAЧA ДAHHЫX ДЛЯ ПEPEЗAГPYЗKИ/');
MENU;

  if 'ФЛA'=ДИP then begin SETFLAG end else if 
  'ПЗГ'=ДИP then begin ПЗГ end else if 
  'BЫX'=ДИP then begin EXIT end else if 
  'KOH'=ДИP then begin EXIT  end  ;
 end 
END;



BEGIN  
if (KYQ44_A='HAЧAЛO') then begin  begin 
WRITELN(OUTPUT);
RGEXPORT:=[46];
WRITELN;
WRITE(OUTPUT,'           ************');PUTPT;
WRITE(OUTPUT,'           ИПC CKЛAД-88');PUTPT;
WRITE(OUTPUT,'           ************');PUTPT;
WRITELN;
IF ПYCTO THEN begin 
    WRITE(OUTPUT,'CИCTEMA TPEБYET BOCCTAHOBЛEHИЯ');PUTT;
    WRITE(OUTPUT,'COOБЩИTE AДMИHИCTPATOPY');PUTT;
    WRITE(OUTPUT,'      ...ДO CBИДAHИЯ...');PUTT;
    &&ЗABEPШ&&;KYДA:='ЭTOBCE';EXIT end ;
  ПPABA end   end  ;
  IF (KYДA<>'HAPYЖY') AND (KYДA<>'HAЧAЛO') THEN EXIT;
(**)
WHILE TRUE DO begin 
IF ДИP<>'KOH' THEN begin 
WRITE(OUTPUT,'      ...BЫ B OБЩEM БЛOKE...  ');PUTT;
WRITE(OUTPUT,'KAP - BXOД B БЛOK PEГИCTPAЦИИ KAPT/',
          'OTЧ - BXOД B БЛOK BЫДAЧИ OTЧETOB/',
          'OTД - BXOД B БЛOK PEГИCTPAЦИИ OTДEЛOB/',
          'CИC - BXOД B CИCTEMHЫЙ БЛOK/',
          'ПAP - ИЗMEHEHИE ПAPOЛЯ AДMИHИCTPATOPA/',
          'ЗAK - ЗAKPEПИTЬ ИЗMEHEHИЯ/',
          'CБP - CБPOCИTЬ ИЗMEHEHИЯ/');
MENU end ;

  if 'KAP'=ДИP then begin IF NOT HEЛЬЗЯ AND NOT ЗAKPЫTO THEN begin 
              KYДA:='SKLCAR';EXIT end  end else if 
  'OTЧ'=ДИP then begin IF NOT ЗAKPЫTO THEN begin 
              KYДA:='SKLOTC';EXIT end  end else if 
  'OTД'=ДИP then begin IF NOT HEЛЬЗЯ AND NOT ЗAKPЫTO THEN begin 
              KYДA:='SKLOTD';EXIT end  end else if 
  'CИC'=ДИP then begin БЛOKCИC end else if 
  'ЗAK'=ДИP then begin ЖYPHAЛ('ЗAK',ПPEДЗAK) end else if 
  'CБP'=ДИP then begin ЖYPHAЛ('CБP',ПPEДЗAK) end else if 
  'ПAP'=ДИP then begin ПAPOЛЬ end else if 
  'KOH'=ДИP then begin  begin KOHEЦ(ПPEДЗAK);IF NOT HAЧ THEN begin ДИP:='KOH';EXIT end  end  end else if 
  'BЫX'=ДИP then begin  begin WRITE(OUTPUT,
             'ECЛИ XOTИTE ЗABEPШИTЬ PAБOTY HAБEPИTE "KOH"');
             PUTT end   end   end ;
END.
