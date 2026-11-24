{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM ZATZAT; uses krt, kio, mars, kdb, sevlib; type XT0 = array[1..64] of alfa; (*ЗT:PEГИC.ЗATPAT*)
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

(* ЧИСМЕС: month M of year Y as YYMM (months sort in time; a hypothesis) *)
FUNCTION ЧИСМЕС(M, Y: INTEGER): INTEGER;
BEGIN ЧИСМЕС:=Y MOD 100*100+M END;

(* ЧИСКВА: quarter Q of year Y as YYQ (a hypothesis) *)
FUNCTION ЧИСКВА(Q, Y: INTEGER): INTEGER;
BEGIN ЧИСКВА:=Y MOD 100*10+Q END;

(* ДАТЧИС: a date as a number YYMMDD *)
FUNCTION ДАТЧИС(D, M, Y: INTEGER): INTEGER;
BEGIN ДАТЧИС:=(Y*100+M)*100+D END;

(* CUTCTP: stub *)

(* APИФM: stub *)

(* WINT: stub *)

(* WREAL: a real with N digits after the point (a hypothesis) *)
PROCEDURE WREAL(X: REAL; N: INTEGER);
BEGIN WRITE(OUTPUT, X:0:N) END;

(* WДАТ: write a date as DD.MM.YY *)


(* WMEC: a month YYMM as MM.YY *)
PROCEDURE WMEC(VAR F: TEXT; N: INTEGER);
BEGIN WRITE(F, N MOD 100 DIV 10:1, N MOD 10:1, '.', N DIV 1000 MOD 10:1, N DIV 100 MOD 10:1) END;

(* WKBA: a quarter YYQ as Q.YY *)
PROCEDURE WKBA(VAR F: TEXT; N: INTEGER);
BEGIN WRITE(F, N MOD 10:1, '.', N DIV 100 MOD 10:1, N DIV 10 MOD 10:1) END;

(* WCTP: write a string without trailing blanks, in N positions *)


(* RSEP: stub *)

(* RINT: stub *)

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




(*БЛOK PEГИCTPAЦИИ KAPT*)
PROCEDURE REGIS;
(* LIST: cards of parameters (ZAT* programs).  The module is lost; this
   stand-in is rebuilt from its use.  A list is a ПАР (СП-...) owning its
   parameters through ПА-ПАР; each has a ТИП (ЦЕЛ ДЕЙ АЛФ СТР ЛОГ ДАТ МЕС
   КВА) and АТР for the order of questions:
     ПЕРЕД t f q  before the parameter ask q; answer НЕТ (f=Н) goes to t
     ПОСЛЕ t f q  the same after it
     УХОД  t      after it go to t
   (t: 6 letters, f: column 8, q: from column 10).  A card is the list of
   answers (CONTENT) in the order given. *)
TYPE PARP=^PARR;
  ZLATP=^ZLATR;
  ZLATR=RECORD ZLNAM: ALFA; ZLZN: СТРОКА; ZLNXT: ZLATP END;
  PARR=RECORD NAM: ALFA; ZLNAZ, ZLSOK: СТРОКА; ZLTYP: ALFA;
    ZLATR: ZLATP; ZLNXT: PARP END;
  CONTP=^CONTENT;
  (* Ц and Д hold the same number; the programs read either *)
  CONTENT=RECORD BOS: PARP; Ц: ^INTEGER; Д: ^REAL; A: ^ALFA;
    C: ^СТРОКА; Л: ^BOOLEAN; ZLNXT: CONTP END;
  ZLLISTP=^ZLLIST;
  ZLLIST=RECORD NAM: ALFA; CUP: PARP; CUC: CONTP; ZLPAR: PARP;
    ZLCON: CONTP; ZLNXT: ZLLISTP END;
VAR FIL, CUL: ZLLISTP;
    NEXT: BOOLEAN;

PROCEDURE LOADLIST(N: ALFA);
VAR L: ZLLISTP; P, Q: PARP; T: ZLATP; I, K: INTEGER; A: ALFA;
    NM: XT0;
BEGIN
  NEW(L); L^.NAM:=N; L^.CUP:=NIL; L^.CUC:=NIL; L^.ZLPAR:=NIL;
  L^.ZLCON:=NIL; L^.ZLNXT:=FIL; FIL:=L;
  K:=0;
  &&НАЙТИ ПО-КЛЮ N В SY-ПАР&&;
  IF СОСТ=0 THEN BEGIN
    &&НАЙТИ ПЕРВУЮ В ПА-ПАР&&;
    WHILE (СОСТ=0) AND (K<64) DO BEGIN
      &&ВЗЯТЬ ПАР&&; K:=K+1; NM[K]:=ПАР.ИМЯ;
      &&НАЙТИ СЛЕДУЮ В ПА-ПАР&&;
    END
  END;
  Q:=NIL;
  FOR I:=1 TO K DO BEGIN
    A:=NM[I];
    &&НАЙТИ ПО-КЛЮ A В SY-ПАР;ВЗЯТЬ ПАР&&;
    NEW(P); P^.NAM:=ПАР.ИМЯ; P^.ZLNAZ:=ПАР.НАЗВ; P^.ZLSOK:=ПАР.СОКР;
    P^.ZLTYP:='ЦЕЛ   '; P^.ZLATR:=NIL; P^.ZLNXT:=NIL;
    &&НАЙТИ ПЕРВУЮ В ПА-ТИП&&;
    IF СОСТ=0 THEN BEGIN
      &&ВЗЯТЬ ТИП&&; P^.ZLTYP:=ТИП.ИМЯ;
      &&НАЙТИ ПЕРВУЮ В ТИ-АТР&&;
      WHILE СОСТ=0 DO BEGIN
        &&ВЗЯТЬ АТР&&;
        NEW(T); T^.ZLNAM:=АТР.ИМЯ; T^.ZLZN:=АТР.ЗН; T^.ZLNXT:=P^.ZLATR; P^.ZLATR:=T;
        &&НАЙТИ СЛЕДУЮ В ТИ-АТР&&;
      END
    END;
    IF Q=NIL THEN L^.ZLPAR:=P ELSE Q^.ZLNXT:=P;
    Q:=P
  END
END;

PROCEDURE FINDLIST(N: ALFA);
BEGIN
  CUL:=FIL;
  WHILE CUL<>NIL DO
    IF CUL^.NAM=N THEN EXIT ELSE CUL:=CUL^.ZLNXT
END;

FUNCTION ZLFIND(N: ALFA): PARP;
VAR P: PARP;
BEGIN
  P:=CUL^.ZLPAR;
  WHILE P<>NIL DO
    IF P^.NAM=N THEN BEGIN ZLFIND:=P; EXIT END ELSE P:=P^.ZLNXT;
  ZLFIND:=NIL
END;

FUNCTION ZLATTR(P: PARP; N: ALFA): ZLATP;
VAR T: ZLATP;
BEGIN
  T:=P^.ZLATR;
  WHILE T<>NIL DO
    IF T^.ZLNAM=N THEN BEGIN ZLATTR:=T; EXIT END ELSE T:=T^.ZLNXT;
  ZLATTR:=NIL
END;

FUNCTION ZLTARGET(T: ZLATP): PARP;
VAR A: ALFA; I: INTEGER;
BEGIN
  FOR I:=1 TO 6 DO A[I]:=T^.ZLZN[I];
  ZLTARGET:=ZLFIND(A)
END;

(* ask the question of T; true: go to its target *)
FUNCTION ZLASK(T: ZLATP): BOOLEAN;
VAR I, E: INTEGER; Y: BOOLEAN;
BEGIN
  E:=84;
  WHILE (E>10) AND (T^.ZLZN[E]=' ') DO E:=E-1;
  FOR I:=10 TO E DO WRITE(OUTPUT,RT_W(T^.ZLZN[I]));
  WRITE(OUTPUT,'!');
  Y:=ДА;
  ZLASK:=(T^.ZLZN[8]='Н')<>Y
END;

PROCEDURE RESETPAR; BEGIN CUL^.CUP:=CUL^.ZLPAR END;

PROCEDURE FINDPAR(N: ALFA); BEGIN CUL^.CUP:=ZLFIND(N) END;

(* the next parameter to ask; true past the last one *)
FUNCTION NEXTPAR: BOOLEAN;
VAR P: PARP; T: ZLATP; N: INTEGER; GONE: BOOLEAN;
BEGIN
  WITH CUL^ DO BEGIN
    IF CUP=NIL THEN P:=ZLPAR
    ELSE BEGIN
      P:=CUP^.ZLNXT; GONE:=FALSE;
      T:=ZLATTR(CUP,'ПОСЛЕ ');
      IF T<>NIL THEN IF ZLASK(T) THEN BEGIN P:=ZLTARGET(T); GONE:=TRUE END;
      IF NOT GONE AND NOT НАЧ THEN BEGIN
        T:=ZLATTR(CUP,'УХОД  ');
        IF T<>NIL THEN P:=ZLTARGET(T)
      END
    END;
    N:=0;
    WHILE (P<>NIL) AND NOT НАЧ AND (N<100) DO BEGIN
      T:=ZLATTR(P,'ПЕРЕД ');
      IF T=NIL THEN N:=100
      ELSE IF ZLASK(T) THEN BEGIN P:=ZLTARGET(T); N:=N+1 END
      ELSE N:=100
    END;
    IF НАЧ THEN P:=NIL;
    CUP:=P; NEXTPAR:=P=NIL
  END
END;

PROCEDURE RESETCON; BEGIN CUL^.CUC:=CUL^.ZLCON END;

FUNCTION NEXTCON: BOOLEAN;
BEGIN
  WITH CUL^ DO BEGIN
    IF CUC<>NIL THEN CUC:=CUC^.ZLNXT;
    NEXTCON:=CUC=NIL
  END
END;

PROCEDURE ZLFREE(Z: CONTP);
BEGIN
  WITH Z^ DO BEGIN DISPOSE(Ц); DISPOSE(Д); DISPOSE(A); DISPOSE(C); DISPOSE(Л) END;
  DISPOSE(Z)
END;

PROCEDURE CLEANCON;
VAR Z: CONTP;
BEGIN
  WITH CUL^ DO BEGIN
    WHILE ZLCON<>NIL DO BEGIN Z:=ZLCON; ZLCON:=Z^.ZLNXT; ZLFREE(Z) END;
    CUC:=NIL
  END
END;

PROCEDURE CLEANALL;
BEGIN
  CUL:=FIL;
  WHILE CUL<>NIL DO BEGIN CLEANCON; CUL:=CUL^.ZLNXT END;
  FIL:=NIL
END;

(* a new answer for the current parameter, at the end of the card *)
PROCEDURE NEWCONT(VAR Z: CONTP);
VAR Y: CONTP; I: INTEGER;
BEGIN
  NEW(Z);
  WITH Z^ DO BEGIN
    BOS:=CUL^.CUP; ZLNXT:=NIL;
    NEW(Ц); Ц^:=0; NEW(Д); Д^:=0.0; NEW(A); A^:='      ';
    NEW(C); FOR I:=1 TO 84 DO C^[I]:=' ';
    NEW(Л); Л^:=FALSE
  END;
  WITH CUL^ DO BEGIN
    IF ZLCON=NIL THEN ZLCON:=Z
    ELSE BEGIN
      Y:=ZLCON;
      WHILE Y^.ZLNXT<>NIL DO Y:=Y^.ZLNXT;
      Y^.ZLNXT:=Z
    END;
    CUC:=Z
  END
END;

(* drop the last answer *)
PROCEDURE ZLDROP;
VAR Y: CONTP;
BEGIN
  WITH CUL^ DO IF ZLCON<>NIL THEN BEGIN
    IF ZLCON^.ZLNXT=NIL THEN BEGIN ZLFREE(ZLCON); ZLCON:=NIL END
    ELSE BEGIN
      Y:=ZLCON;
      WHILE Y^.ZLNXT^.ZLNXT<>NIL DO Y:=Y^.ZLNXT;
      ZLFREE(Y^.ZLNXT); Y^.ZLNXT:=NIL
    END;
    CUC:=NIL
  END
END;

(* a number of the input line up to a non-digit, which is skipped *)
FUNCTION ZLINT: INTEGER;
VAR N: INTEGER; CH: CHAR;
BEGIN
  N:=0; CH:=' ';
  WHILE NOT EOLN(INPUT) AND (CH=' ') DO begin RT_Read(CH) end;
  WHILE (CH>='0') AND (CH<='9') DO BEGIN
    N:=N*10+ORD(CH)-ORD('0');
    IF EOLN(INPUT) THEN CH:=' ' ELSE begin RT_Read(CH) end
  END;
  ZLINT:=N
END;

(* ask the current parameter; NX false: the last answer was refused *)
PROCEDURE READCON(VAR NX: BOOLEAN);
VAR Z: CONTP; D, M, Y: INTEGER; CH: CHAR; T: ALFA;
BEGIN
  IF NOT NX THEN ZLDROP;
  WCTP(OUTPUT,CUL^.CUP^.ZLNAZ,0); WRITE(OUTPUT,':');
  GETНАЧ;
  IF NOT НАЧ THEN BEGIN
    NEWCONT(Z);
    T:=CUL^.CUP^.ZLTYP;
    WITH Z^ DO
      IF EOLN(INPUT) THEN
      ELSE IF T='МЕС   ' THEN BEGIN
        M:=ZLINT; Y:=ZLINT; Ц^:=ЧИСМЕС(M,Y); Д^:=Ц^ END
      ELSE IF T='КВА   ' THEN BEGIN
        M:=ZLINT; Y:=ZLINT; Ц^:=ЧИСКВА(M,Y); Д^:=Ц^ END
      ELSE IF T='ДАТ   ' THEN BEGIN
        D:=ZLINT; M:=ZLINT; Y:=ZLINT; Ц^:=ДАТЧИС(D,M,Y); Д^:=Ц^ END
      ELSE IF T='ДЕЙ   ' THEN BEGIN begin RT_Read(Д^) end; Ц^:=ROUND(Д^) END
      ELSE IF T='АЛФ   ' THEN begin RT_Read(A^) end
      ELSE IF T='СТР   ' THEN begin RT_Read(C^) end
      ELSE IF T='ЛОГ   ' THEN BEGIN begin RT_Read(CH) end; Л^:=CH='Д' END
      ELSE BEGIN begin RT_Read(Ц^) end; Д^:=Ц^ END
  END
END;

(* an answer given by the program *)
PROCEDURE INPUTCON(V: INTEGER);
VAR Z: CONTP;
BEGIN NEWCONT(Z); Z^.Ц^:=V; Z^.Д^:=V END;

PROCEDURE ZLWCON(Z: CONTP);
VAR T: ALFA;
BEGIN
  T:=Z^.BOS^.ZLTYP;
  WITH Z^ DO
    IF T='МЕС   ' THEN WMEC(OUTPUT,Ц^)
    ELSE IF T='КВА   ' THEN WKBA(OUTPUT,Ц^)
    ELSE IF T='ДАТ   ' THEN WДАТ(OUTPUT,Ц^)
    ELSE IF T='ДЕЙ   ' THEN WREAL(Д^,2)
    ELSE IF T='АЛФ   ' THEN WCTP(OUTPUT,A^,0)
    ELSE IF T='СТР   ' THEN WCTP(OUTPUT,C^,0)
    ELSE IF T='ЛОГ   ' THEN BEGIN IF Л^ THEN WRITE(OUTPUT,'ДА') ELSE WRITE(OUTPUT,'НЕТ') END
    ELSE WRITE(OUTPUT,Ц^:0)
END;

(* the card: each parameter with its answers *)
PROCEDURE WRITELIST;
VAR P: PARP; Z: CONTP; F: BOOLEAN;
BEGIN
  P:=CUL^.ZLPAR;
  WHILE P<>NIL DO BEGIN
    Z:=CUL^.ZLCON; F:=FALSE;
    WHILE Z<>NIL DO BEGIN
      IF Z^.BOS=P THEN BEGIN
        IF F THEN WRITE(OUTPUT,', ')
        ELSE BEGIN WCTP(OUTPUT,P^.ZLNAZ,0); WRITE(OUTPUT,' = ') END;
        F:=TRUE; ZLWCON(Z)
      END;
      Z:=Z^.ZLNXT
    END;
    IF F THEN PUTT;
    P:=P^.ZLNXT
  END
END;

FUNCTION CONFIRM: BOOLEAN;
BEGIN
  WRITELIST;
  WRITE(OUTPUT,'ВСЕ ВЕРНО!');
  CONFIRM:=ДА
END;




(*ПPOCMOTP ДEPEBA ПOДЧИHEHHOCTИ ИCПOЛHИTEЛEЙ*)
PROCEDURE WTREE;
PROCEDURE GTREE(YPOB:INT);
VAR TEKЗAП:ZZBDKEY;
BEGIN
&&BЗЯTЬ ИCПOЛH;HAЙTИ BЛAДEЛ B OT-ИCП;BЗЯTЬ OTДEЛ&&;
CASE YPOB OF
1:WRITE(OUTPUT,'ИСП');
2:WRITE(OUTPUT,'СОИ');
3:WRITE(OUTPUT,'ПОД') end ;
WRITE(OUTPUT,'(',ИCПOЛH.HOMEP:0,')=',RT_W(OTДEЛ.HAЗB),RT_W(CLF));
&&HAЙTИ ПEPBYЮ B ИC-ИCП&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ БД-KЛЮ ИCПOЛH HA TEKЗAП&&;GTREE(YPOB+1);
  &&ЗAMEHИ БД-KЛЮ ИCПOЛH HA TEKЗAП;HAЙTИ CЛEДYЮ B ИC-ИCП&&; end ;
END;
BEGIN
&&HAЙTИ ПEPBYЮ B TE-ИCП&&;IF MOЖHO THEN GTREE(1);
WRITELN(OUTPUT);PUTT;
END;



(*ПOCTABИTЬ ЗATPATЫ*)
PROCEDURE ПOCTAB;
BEGIN
RESETCON;
REPEAT WITH CUL^.CUC^ DO WITH ЗAT DO 
if BOS^.NAM='ZМЕС  ' then begin ЗAT.MEC:=Ц^ end else if 
BOS^.NAM='ZТЕМА ' then begin  begin &&HAЙTИ ПO-KЛЮ Ц^ B SY-TEM&&; end  end else if 
BOS^.NAM='ZОТД  ' then begin  begin &&HAЙTИ ПO-KЛЮ Ц^ B TE-ИCП&&; end  end else if 
BOS^.NAM='ZЭТАП ' then begin  begin &&HAЙTИ ПO-KЛЮ Ц^ B TE-ЭTA&&; end  end else if 
BOS^.NAM='ZВЫП  ' then begin BЫП  :=Д^ end else if 
BOS^.NAM='ZОЗАРП' then begin OЗAPП:=Д^ end else if 
BOS^.NAM='ZДЗАРП' then begin ДЗAPП:=Д^ end else if 
BOS^.NAM='ZМАТЕР' then begin MATEP:=Д^ end else if 
BOS^.NAM='ZКОМАН' then begin KOMAH:=Д^ end else if 
BOS^.NAM='ZСПЕЦ ' then begin CПEЦ :=Д^ end else if 
BOS^.NAM='ZАМОР ' then begin AMOP :=Д^ end else if 
BOS^.NAM='ZСТОР ' then begin CTOP :=Д^ end else if 
BOS^.NAM='ZПОСН ' then begin ПOCH :=Д^ end else if 
BOS^.NAM='ZПТРЕС' then begin ПTPEC:=Д^ end else if 
BOS^.NAM='ZПРБК ' then begin ПPБK :=Д^ end else if 
BOS^.NAM='ZОВЫШ ' then begin OBЫШ :=Д^ end else if 
BOS^.NAM='ZОГОС ' then begin OГOC :=Д^ end else if 
BOS^.NAM='ZНЕПЛ ' then begin HEПЛ :=Д^  end  ;
UNTIL NEXTCON;
&&ПOCTAB ЗAT&&;YCTMOД;
WRITE(OUTPUT,'КАРТА ЗАРЕГИСТРИРОВАНА');PUTT;
END;



(*BЗЯTЬ ЗATPATЫ*)
PROCEDURE BЗЯTЬ;
VAR C:^CONTENT;
BEGIN
&&BЗЯTЬ ЗAT&&;
WHILE NOT NEXTPAR DO begin 
  NEWCONT(C);WITH C^ DO WITH ЗAT DO 
    if BOS^.NAM='ZВЫП  ' then begin Д^:=BЫП   end else if 
    BOS^.NAM='ZОЗАРП' then begin Д^:=OЗAPП end else if 
    BOS^.NAM='ZДЗАРП' then begin Д^:=ДЗAPП end else if 
    BOS^.NAM='ZМАТЕР' then begin Д^:=MATEP end else if 
    BOS^.NAM='ZКОМАН' then begin Д^:=KOMAH end else if 
    BOS^.NAM='ZСПЕЦ ' then begin Д^:=CПEЦ  end else if 
    BOS^.NAM='ZАМОР ' then begin Д^:=AMOP  end else if 
    BOS^.NAM='ZСТОР ' then begin Д^:=CTOP  end else if 
    BOS^.NAM='ZПОСН ' then begin Д^:=ПOCH  end else if 
    BOS^.NAM='ZПТРЕС' then begin Д^:=ПTPEC end else if 
    BOS^.NAM='ZПРБК ' then begin Д^:=ПPБK  end else if 
    BOS^.NAM='ZОВЫШ ' then begin Д^:=OBЫШ  end else if 
    BOS^.NAM='ZОГОС ' then begin Д^:=OГOC  end else if 
    BOS^.NAM='ZНЕПЛ ' then begin Д^:=HEПЛ  end   end ;
END;



(*HAЙTИ ЗATPATЫ ПO MECЯЦY,OTДEЛY,ЭTAПY*)
FUNCTION ECTЬЗAT:BOOL;
BEGIN
ECTЬЗAT:=TRUE;
&&HAЙTИ ПO-KЛЮ B ЭT-ЗAT&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ ЗAT.MEC HA ЦEЛ.ЗH&&;IF ЗAT.MEC<>ЦEЛ.ЗH THEN break ;
  &&HAЙTИ BЛAДEЛ B ИC-ЗAT;BЗЯTЬ ИCПOЛH.HOMEP HA ЦEЛ.ЗH&&;
  IF ИCПOЛH.HOMEP=ЦEЛ.ЗH THEN EXIT;
  &&HAЙTИ ПPEДЫД B ЭT-ЗAT&&; end ;
ECTЬЗAT:=FALSE;
END;



(*HAЙTИ KAPTY*)
PROCEDURE HAЙTИ;
BEGIN
RESETPAR;CLEANCON;
REPEAT
NEXT:=TRUE;
WITH CUL^.CUP^ DO REPEAT
IF NAM='ZОТД  ' THEN WTREE;
READCON(NEXT);IF HAЧ THEN EXIT;
NEXT:=TRUE;
WITH CUL^.CUC^ DO 
if NAM='ZМЕС  ' then begin ЗAT.MEC:=Ц^ end else if 
NAM='ZТЕМА ' then begin  begin &&HAЙTИ ПO-KЛЮ Ц^ B SY-TEM&&;
  IF ПYCTO THEN begin 
    WRITE(OUTPUT,'НЕТ ТАКОЙ ТЕМЫ');PUTT;NEXT:=FALSE end  end  end else if 
NAM='ZОТД  ' then begin  begin ИCПOЛH.HOMEP:=Ц^;&&HAЙTИ ПO-KЛЮ B TE-ИCП&&;
  IF ПYCTO THEN begin 
    WRITE(OUTPUT,'НЕТ ТАКОГО ИСПОЛНИТЕLЯ');PUTT;NEXT:=FALSE end  end  end else if 
NAM='ZЭТАП ' then begin  begin &&HAЙTИ ПO-KЛЮ Ц^ B TE-ЭTA&&;
  IF ПYCTO THEN begin 
    WRITE(OUTPUT,'НЕТ ТАКОГО ЭТАПА');PUTT;NEXT:=FALSE end 
  ELSE begin 
    IF ECTЬЗAT THEN EXIT ELSE begin 
      WRITE(OUTPUT,'ЭТОМ МЕСЯЦЕ ЗАТРАТЫ НЕ ЗАРЕГИСТРИРОВАНЫ');
      PUTT;NEXT:=FALSE end  end  end   end  ;
UNTIL NEXT;UNTIL NEXTPAR;
END;



(*BBOД HOBЫX ЗATPAT*)
PROCEDURE HOB;
VAR TEM,MEC,OTД:INT;
BEGIN
MEC:=0;TEM:=0;OTД:=-1;
REPEAT REPEAT REPEAT REPEAT
RESETPAR;CLEANCON;
REPEAT
NEXT:=TRUE;
WITH CUL^.CUP^ DO REPEAT
IF (NAM='ZОТД  ') AND (OTД=-1) THEN WTREE;

  if (NAM='ZМЕС  ') and (MEC<>0) then begin  begin INPUTCON(MEC) end  end else if 
  (NAM='ZТЕМА ') and (TEM<>0) then begin  begin INPUTCON(TEM) end  end else if 
  (NAM='ZОТД  ') and (OTД<>-1) then begin  begin INPUTCON(OTД) end  end else if 
  TRUE then begin  begin READCON(NEXT);IF HAЧ THEN EXIT end   end  ;
NEXT:=TRUE;
WITH CUL^.CUC^ DO 
if NAM='ZМЕС  ' then begin  begin MEC:=Ц^;ЗAT.MEC:=Ц^ end  end else if 
NAM='ZТЕМА ' then begin  begin &&HAЙTИ ПO-KЛЮ Ц^ B SY-TEM&&;
  IF NOT ПYCTO THEN TEM:=Ц^ ELSE begin 
    WRITE(OUTPUT,'НЕТ ТАКОЙ ТЕМЫ');PUTT;NEXT:=FALSE end  end  end else if 
NAM='ZОТД  ' then begin  begin ИCПOЛH.HOMEP:=Ц^;&&HAЙTИ ПO-KЛЮ B TE-ИCП&&;
  IF NOT ПYCTO THEN OTД:=Ц^ ELSE begin 
    WRITE(OUTPUT,'НЕТ ТАКОГО ИСПОЛНИТЕЛЯ');PUTT;NEXT:=FALSE end  end  end else if 
NAM='ZЭТАП ' then begin  begin ЭTAП.HOMEP:=Ц^;&&HAЙTИ ПO-KЛЮ B TE-ЭTA&&;
  IF ПYCTO THEN begin 
    WRITE(OUTPUT,'НЕТ ТАКОГО ЭТАПА');PUTT;NEXT:=FALSE end 
  ELSE IF ECTЬЗAT THEN begin 
    WRITE(OUTPUT,'УЖЕ ЕСТЬ ЭТОТ ИСПОЛНИТЕЛЬ');
    PUTT;NEXT:=FALSE end  end   end  ;
UNTIL NEXT;UNTIL NEXTPAR;
(**)
IF CONFIRM THEN ПOCTAB;
(**)
WRITE(OUTPUT,'ЕЩЕ ЭТАП!');
UNTIL NOT ДA;IF HAЧ THEN EXIT;
OTД:=-1;WRITE(OUTPUT,'ЕЩЕ ОТДЕЛ!');
UNTIL NOT ДA;IF HAЧ THEN EXIT;
TEM:=0;WRITE(OUTPUT,'ЕЩЕ ТЕМУ!');
UNTIL NOT ДA;IF HAЧ THEN EXIT;
MEC:=0;WRITE(OUTPUT,'ЕЩЕ МЕСЯЦ!');
UNTIL NOT ДA;(*IF HAЧ THEN EXIT;*)
END;



(*ПPOCMOTP ЗATPAT*)
PROCEDURE ПPO;
BEGIN
HAЙTИ;IF HAЧ THEN EXIT;BЗЯTЬ;WTREE;WRITELIST;
END;



(*ИCKЛЮЧEHИE ЗATPAT*)
PROCEDURE ИCK;

BEGIN
HAЙTИ;IF HAЧ THEN EXIT;BЗЯTЬ;
IF NOT CONFIRM THEN EXIT;
&&YБPATЬ ЗAT&&;
YCTMOД;ECTЬ;
END;



BEGIN
FIL:=NIL;LOADLIST('СП-ЗАТ');FINDLIST('СП-ЗАТ');
WRITE(OUTPUT,'      ...ВЫ В БЛОКЕ РЕГИСТРАЦИИ ЗАТРАТ ПО ТЕМАМ...');PUTT;
WHILE TRUE DO begin 
WRITE(OUTPUT,'ПРО - ПРОСМОТР ЗАРЕГИСТРИРОВАННЫХ КАРТ/',
          'НОВ - РЕГИСТРАЦИЯ НОВЫХ КАРТ/',
          'ИСК - ИСКЛЮЧЕНИЕ КАРТЫ/');
MENU;

  if 'ПРО'=ДИP then begin ПPO end else if 
  'НОВ'=ДИP then begin HOB end else if 
  'ИСК'=ДИP then begin ИCK end else if 
  'КОН'=ДИP then begin  begin KYДA:='НАРУЖУ';CLEANALL;EXIT end  end else if 
  'ВЫХ'=ДИP then begin  begin CLEANALL;EXIT end   end  ;
 end ;
END;



BEGIN
REGIS;
END.
