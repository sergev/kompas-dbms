{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}
 PROGRAM ZATTAB; uses krt, kio, mars, kdb, sevlib; type XT0 = array[1..40] of integer; XT1 = array[1..2000] of char; (*ЗT:TAБЛ.ЗATPAT ЗA ПOCЛ.MECЯЦ*)
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


(* FWRITE: copy text file F to the output *)


(* PUT: end of an output line *)
PROCEDURE PUTT; BEGIN WRITELN END;
PROCEDURE PUTPT; BEGIN WRITELN END;
PROCEDURE PUTP; BEGIN WRITELN END;

(* МОЖНО, ПУСТО: the status of the last DML statement *)
FUNCTION МОЖНО: BOOLEAN; BEGIN МОЖНО:=СОСТ=0 END;
FUNCTION ПУСТО: BOOLEAN; BEGIN ПУСТО:=СОСТ<>0 END;

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


(* ПШИК: not used by the programs *)

(* FПАР: find the parameter A of the system *)
PROCEDURE FПАР(A: ALFA);
BEGIN &&НАЙТИ ПО-КЛЮ A В SY-ПАР&&; END;

(* TPUT: print the pending output line as a row of a table.  The program
   writes the cells ended by '!', sets TABLE[j].S (width) and TABLE[j].F
   (alignment), and ВСЕ after the last; '^' in a cell starts a new line
   in it.  R: РАЗ - '!' between cells, НАД/ПОД - a rule above/below,
   ПЕЧ/ЭКР - printer/screen (the same here).  The module is lost; the
   alignment (Ц centre, П right, else left) is a hypothesis. *)
TYPE TABLEREG=(РАЗ,НАД,ПОД,ПЕЧ,ЭКР,БЕЗ); const XEN_TABLEREG: array[TABLEREG] of string[8] = ('РАЗ','НАД','ПОД','ПЕЧ','ЭКР','БЕЗ'); type ZZTREGS=SET OF TABLEREG;
CONST ВСЕ=-1;
VAR TABLE: ARRAY[1..40] OF RECORD S: INTEGER; F: CHAR END;
PROCEDURE TPUT(R: ZZTREGS);
VAR N, I, J, K, L, W, ROWS, ROW, P, Q, A: INTEGER;
    CB, CE: XT0;
    S: XT1;
  PROCEDURE RULE;
  VAR I: INTEGER;
  BEGIN FOR I:=1 TO W DO WRITE(OUTPUT,'-'); WRITELN(OUTPUT) END;
BEGIN
  L:=ZZTLEN; N:=0; P:=1;
  WHILE (N<40) AND (TABLE[N+1].S<>ВСЕ) DO BEGIN
    N:=N+1; CB[N]:=P;
    WHILE (P<=L) AND (ZZTCH(P)<>'!') DO P:=P+1;
    CE[N]:=P-1; P:=P+1
  END;
  ROWS:=1; W:=1;
  FOR J:=1 TO N DO BEGIN
    K:=1;
    FOR I:=CB[J] TO CE[J] DO IF ZZTCH(I)='^' THEN K:=K+1;
    IF K>ROWS THEN ROWS:=K;
    W:=W+TABLE[J].S+1
  END;
  FOR I:=1 TO L DO IF I<=2000 THEN S[I]:=ZZTCH(I);
  ZZTCLR;
  IF НАД IN R THEN RULE;
  FOR ROW:=1 TO ROWS DO BEGIN
    IF РАЗ IN R THEN WRITE(OUTPUT,'!') ELSE WRITE(OUTPUT,' ');
    FOR J:=1 TO N DO BEGIN
      (* line ROW of the cell: P..Q *)
      P:=CB[J]; K:=1;
      WHILE (K<ROW) AND (P<=CE[J]) DO BEGIN
        IF S[P]='^' THEN K:=K+1; P:=P+1
      END;
      Q:=P-1;
      IF K=ROW THEN BEGIN
        Q:=P;
        WHILE (Q<=CE[J]) AND (S[Q]<>'^') DO Q:=Q+1;
        Q:=Q-1;
        WHILE (P<=Q) AND (S[P]=' ') DO P:=P+1;
        WHILE (Q>=P) AND (S[Q]=' ') DO Q:=Q-1
      END;
      IF Q-P+1>TABLE[J].S THEN Q:=P+TABLE[J].S-1;
      A:=TABLE[J].S-(Q-P+1);
      IF TABLE[J].F='Ц' THEN K:=A DIV 2
      ELSE IF TABLE[J].F='П' THEN K:=A
      ELSE K:=0;
      FOR I:=1 TO K DO WRITE(OUTPUT,' ');
      FOR I:=P TO Q DO WRITE(OUTPUT,RT_W(S[I]));
      FOR I:=K+1 TO A DO WRITE(OUTPUT,' ');
      IF РАЗ IN R THEN WRITE(OUTPUT,'!') ELSE WRITE(OUTPUT,' ')
    END;
    WRITELN(OUTPUT)
  END;
  IF ПОД IN R THEN RULE
END;

(* MINUSES: a line of minuses *)
PROCEDURE MINUSES; VAR I: INTEGER; BEGIN FOR I:=1 TO 72 DO WRITE('-'); WRITELN END;

(* WLF: N line feeds *)
PROCEDURE WLF(N: INTEGER); VAR I: INTEGER; BEGIN FOR I:=1 TO N DO WRITELN END;




PROCEDURE TAБЛЗAT;

TYPE
COLUMN=(
        ZTEMA   ,
        ZMEC    ,
        ZOTД    ,
        ZNOTД   ,
        ZЭTAП   ,
        ZBЫП    ,
        ZOЗAPП  ,
        ZДЗAPП  ,
        VЗAPП   ,
        VCTPAX  ,
        ZMATEP  ,
        ZKOMAH  ,
        ZCПEЦ   ,
        ZAMOP   ,
        ZCTOP   ,
        VПPOЧ   ,
        VHAKЛ   ,
        VЗAPH   ,
        VCБC    ,
        VЭФЗ    ,
        ZПOCH   ,
        ZПTPEC  ,
        ZПPБK   ,
        VPACЧ   ,
        ZOBЫШ   ,
        ZOГOC   ,
        ZHEПЛ   ,
        VOCT    ,
        VФPEЗ   ,
        VФMП    ,
        VФHTCP  ); const XEN_COLUMN: array[COLUMN] of string[8] = ('ZТЕМА','ZМЕС','ZОТД','ZNОТД','ZЭТАП','ZВЫП','ZОЗАРП','ZДЗАРП','VЗАРП','VСТРАХ','ZМАТЕР','ZКОМАН','ZСПЕЦ','ZАМОР','ZСТОР','VПРОЧ','VНАКЛ','VЗАРН','VСБС','VЭФЗ','ZПОСН','ZПТРЕС','ZПРБК','VРАСЧ','ZОВЫШ','ZОГОС','ZНЕПЛ','VОСТ','VФРЕЗ','VФМП','VФНТСР'); type
TYPPAR=(CEL,DEY,ALF,STR,LOG,DAT,MES,KVA); const XEN_TYPPAR: array[TYPPAR] of string[8] = ('CEL','DEY','ALF','STR','LOG','DAT','MES','KVA'); type
CELL=PACKED RECORD FRM:CHAR;CON:^CONTENT end ;
CONTENT=RECORD CASE TYP:TYPPAR OF
                   CEL,DAT,MES,KVA:(Ц:^ATCЦEЛ);
                   DEY:(Д:^ATCДEЙ);
                   ALF:(A:^ATCAЛФ);
                   STR:(C:^ATCCTP);
                   LOG:(Л:^ATCЛOГ) end ;
ATCЦEЛ=RECORD ЗH:INT end ;
ATCДEЙ=RECORD ЗH:REAL end ;
ATCAЛФ=RECORD ЗH:ALFA end ;
ATCCTP=RECORD ЗH:CTPOKA end ;
ATCЛOГ=RECORD ЗH:BOOL end ;



CONST FIRCOL=ZTEMA;LASCOL=VФHTCP;
      FIRLIN=1;LASLIN=48;

TYPE LINE=FIRLIN..LASLIN;



VAR
SCREEN:INT;EXPORT:TABLEREG;PRINTCALC:BOOL;
T:ARRAY [FIRCOL..LASCOL,FIRLIN..LASLIN ] OF CELL;
TOTAL:ARRAY [FIRLIN..LASLIN ] OF LINE;
MINLIN,MAXLIN,CURLIN:LINE;
SETCOL:RECORD ИCXДEЙ,BЫЧДEЙ,CYMДEЙ,CLEAN:SET OF COLUMN end ;
FORCOL:ARRAY [FIRCOL..LASCOL ] OF RECORD S:INT;F:CHAR END;
FORLIN:ARRAY [FIRLIN..LASLIN ] OF SET OF TABLEREG;







(*PACПEЧATKA HAБOPA
PROCEDURE WSET(S:SET OF TABLEREG);
CONST F=PAЗ;L=БEЗ;
VAR I:TABLEREG;
BEGIN
WRITE(OUT,'HAБOP:[');
FOR I:=F TO L DO IF I IN S THEN WRITE(OUT,I);
WRITE(OUT,' ]');PUTT;
END;*)



(*TИПЫ: ПEPEЧИCЛИMЫЙ --> ALFA*)
FUNCTION ИMЯ(И:COLUMN):ALFA;VAR F:TEXT;A:ALFA;
BEGIN begin if RT_First(@F) then assign(F, RT_TmpName); REWRITE(F) end;WRITE(F,RT_EnW(XEN_column[И]),'      ');begin if RT_First(@F) then assign(F, RT_TmpName); RESET(F) end;
WHILE RT_Peek(F)=' ' DO RT_GetC(F);READ(F,A);ИMЯ:=A END;


(*ИHИЦИAЛИЗAЦИЯ TAБЛИЦЫ*)
PROCEDURE INITTAB;
VAR C:COLUMN;L:LINE;
BEGIN
PRINTCALC:=TRUE;
WITH SETCOL DO begin 
  ИCXДEЙ:=[ZBЫП,ZOЗAPП,ZДЗAPП,ZMATEP,
           ZKOMAH,ZCПEЦ,ZAMOP,ZCTOP,
           ZПOCH,ZПTPEC,ZПPБK,ZOBЫШ,ZOГOC,ZHEПЛ];
  BЫЧДEЙ:=[VПPOЧ,VHAKЛ,VЗAPH ,
           VЗAPП,VCTPAX,VCБC,VPACЧ,VЭФЗ,VOCT,VФPEЗ,VФMП,VФHTCP];
  CYMДEЙ:=ИCXДEЙ+BЫЧДEЙ;
  CLEAN:=[FIRCOL..LASCOL];
 end ;
END;



(*BЫBOД CTOЛБЦA*)
PROCEDURE WCOL(C:COLUMN);
BEGIN WRITE(OUTPUT,RT_EnW(XEN_column[C]),'[',ORD(C)+1:0,']') END;



(*BЫЧИCЛEHИE BЫЧИCЛЯEMЫX KOЭФФИЦИEHTOB*)
PROCEDURE BЫЧKOЭФ;
VAR OБЩЗAPП:REAL;
PROCEDURE PДEЙ(A:ALFA;I:REAL);
BEGIN;&&HAЙTИ ПO-KЛЮ A B SY-ПAP;HAЙTИ ПEPBYЮ B ПA-ДEЙ;ЗAMEHИ&&;
END;
BEGIN
WITH HAKЛ DO begin OБЩЗAPП:=ЗAPП;
PДEЙ('ZКПРОЧ',ПPOЧ/OБЩЗAPП);
PДEЙ('ZКНАКЛ',HAKЛ/OБЩЗAPП);
PДEЙ('ZКЗАРН',ЗAHAK/OБЩЗAPП) end ;
END;



(*YMHOЖИTЬ CTOЛБEЦ HA KOЭФФИЦИEHT*)
PROCEDURE MUL(CR:COLUMN;A:ALFA);
VAR L:LINE;R:REAL;
BEGIN
FПAP(A);&&HAЙTИ ПEPBYЮ B ПA-ДEЙ;BЗЯTЬ ДEЙ.ЗH HA R&&;
if not RT_Le(ord(MINLIN ), ord( MAXLIN )) then else FOR L:=MINLIN TO MAXLIN DO
  T[CR,L].CON^.Д^.ЗH:=T[CR,L].CON^.Д^.ЗH * R;
IF PRINTCALC THEN begin 
  WCOL(CR);WRITE(OUTPUT,' * ',RT_W(A),'(',R:0:23,') --> ');WCOL(CR);PUTP end ;
END;



(*ДEЙCTBИE HAД CTOЛБЦAMИ*)
type XS1 = set of COLUMN; PROCEDURE MOV(CR:COLUMN;ZNAK:CHAR;SC:XS1  );
VAR C:COLUMN;L:LINE;ПEPBЫЙ:BOOL;
BEGIN
IF PRINTCALC THEN begin ПEPBЫЙ:=TRUE;WCOL(CR);WRITE(OUTPUT,' ',RT_W(ZNAK)) end ;
if not RT_Le(ord(MINLIN ), ord( MAXLIN )) then else FOR L:=MINLIN TO MAXLIN DO WITH T[CR,L].CON^.Д^ DO begin 
  if not RT_Le(ord(FIRCOL ), ord( LASCOL )) then else FOR C:=FIRCOL TO LASCOL DO IF C IN SC THEN begin 
    IF PRINTCALC AND (L=MINLIN) THEN begin 
      IF ПEPBЫЙ THEN ПEPBЫЙ:=FALSE ELSE WRITE(OUTPUT,' ',RT_W(ZNAK));
      WCOL(C);WRITE(OUTPUT,RT_W(CLF)) end ;
    
      if ZNAK='+' then begin ЗH:=ЗH+T[C,L].CON^.Д^.ЗH end else if 
      ZNAK='-' then begin ЗH:=ЗH-T[C,L].CON^.Д^.ЗH  end   end  end ;
IF PRINTCALC THEN begin WRITE(OUTPUT,' --> ');WCOL(CR);PUTP end ;
END;



(*ЗAПOЛHEHИE ЯЧEЙKИ*)
PROCEDURE FILL(TT:TYPPAR;CC:COLUMN;LL:LINE;FF:CHAR);
VAR I:INT;
BEGIN
WITH T[CC,LL] DO begin 
  NEW(CON);FRM:=FF;
  WITH CON^ DO begin 
    TYP:=TT;
    CASE TYP OF
      CEL,DAT,MES,KVA: begin NEW(Ц);Ц^.ЗH:=ЦEЛ.ЗH end ;
      DEY: begin NEW(Д);Д^.ЗH:=ДEЙ.ЗH end ;
      ALF: begin NEW(A);A^.ЗH:=AЛФ.ЗH end ;
      STR: begin NEW(C);C^.ЗH:=CTP.ЗH end ;
      LOG: begin NEW(Л);Л^.ЗH:=ЛOГ.ЗH end  end  end  end ;
END;



(*CYMMИPOBAHИE CTOЛБЦOB*)
PROCEDURE SUM(LR,LASTOT:LINE;NNEEWW:BOOL);
VAR C:COLUMN;L,NT:LINE;
BEGIN
if not RT_Le(ord(FIRCOL ), ord( LASCOL )) then else FOR C:=FIRCOL TO LASCOL DO IF C IN SETCOL.CYMДEЙ THEN begin 
  IF NNEEWW THEN begin ДEЙ.ЗH:=0.0;FILL(DEY,C,LR,'Ц') end ;
  WITH T[C,LR].CON^.Д^ DO begin 
    if not RT_Le(ord(1), ord( LASTOT )) then else FOR NT := 1 to LASTOT DO
      ЗH:=ЗH+T[C,TOTAL[NT]].CON^.Д^.ЗH end  end ;
(**)
IF NNEEWW THEN begin 
FORLIN[LR]:=[PAЗ,HAД,ПOД];
AЛФ.ЗH:='ИТОГО ';FILL(ALF,ZTEMA,LR,'П');
AЛФ.ЗH:='      ';FILL(ALF,ZMEC,LR,'Ц');
AЛФ.ЗH:='      ';FILL(ALF,ZNOTД,LR,'Ц');
AЛФ.ЗH:='      ';FILL(ALF,ZOTД,LR,'Ц');
AЛФ.ЗH:='      ';FILL(ALF,ZЭTAП,LR,'Ц') end ;
END;



(*DISPOSE BCEЙ TAБЛИЦЫ*)
PROCEDURE CLEAN(FIRLIN,MAXLIN:LINE);
VAR C:COLUMN;L:LINE;CONT:^CONTENT;
BEGIN
if not RT_Le(ord(FIRCOL ), ord( LASCOL )) then else FOR C:=FIRCOL TO LASCOL DO IF C IN SETCOL.CLEAN THEN
  if not RT_Le(ord(FIRLIN ), ord( MAXLIN )) then else FOR L:=FIRLIN TO MAXLIN DO begin 
    WITH T[C,L].CON^ DO CASE TYP OF
      CEL,DAT,MES,KVA:DISPOSE(Ц);
      DEY:DISPOSE(Д);
      ALF:DISPOSE(A);
      STR:DISPOSE(C);
      LOG:DISPOSE(Л) end ;
    CONT:=T[C,L].CON;DISPOSE(CONT) end ;
END;



(*ЗAПOЛHEHИE ШAПKИ TAБЛИЦЫ*)
PROCEDURE ЗAПШAП;
CONST SIZE=39;
VAR C:COLUMN;L:LINE;

(*FILL ШAПKИ*)
type XS2 = PACKED ARRAY [1..SIZE ] OF CHAR; PROCEDURE Z(JUNC:INT;C:COLUMN;N:XS2;S:INT);
VAR I:INT;
BEGIN
FOR I := 1 to SIZE DO CTP.ЗH[I]:=N[I];
FOR I:=SIZE+1 TO SCTPOKA DO CTP.ЗH[I]:=' ';
FORCOL[C].S:=S;
FILL(STR,C,L,'Ц');
END;

BEGIN
L:=FIRLIN;FORLIN[L]:=[PAЗ,HAД,ПOД];
Z( 0,ZTEMA   ,'НОМЕР^КАЛЬК^ТЕМЫ                       ', 7);
             (*                       XXXXXXX             *)
Z( 1,ZMEC    ,'МЕСЯЦ^ГОД                              ', 5);
             (*             XX.XX                         *)
Z(99,ZOTД    ,'ОТДЕЛ                                  ', 6);
             (*             XXXXXX                        *)
Z(99,ZNOTД   ,'N                                      ', 1);
             (*             X                             *)
Z(99,ZЭTAП   ,'ЭТАП                                   ', 4);
             (*             XXXXXX                        *)
Z( 2,ZBЫП    ,'ВЫПОЛН^ПО^ТЕМЕ                         ', 6);
             (*                       XXXXXX              *)
Z( 3,ZOЗAPП  ,'ЗАРПЛ^ОСН^ИСП                          ', 6);
             (*                 XXXXX.XX                  *)
Z( 4,ZДЗAPП  ,'ДОПОЛН^ЗАРПЛ^ОСН^ИСП                   ', 6);
             (*                     XXXX.XX               *)
Z(99,VЗAPП   ,'СУММАР^ЗАРПЛ^ОСН^ИСП                   ', 6);
             (*                    XXXXX.XX               *)
Z( 5,VCTPAX  ,'ОТЧ НА^СОЦ^СТРАХ                       ', 6);
             (*   0.14*(П3+П4)      XXXX.XX               *)
Z( 6,ZMATEP  ,'МАТЕР                                  ', 6);
             (*             XXXXX.XX                      *)
Z( 7,ZKOMAH  ,'КОМАНД                                 ', 6);
             (*                 XXX.XX                    *)
Z( 8,ZCПEЦ   ,'СПЕЦ^ОБОР                              ', 5);
             (*                    XXXXX                  *)
Z( 9,ZAMOP   ,'АМОРТ^НА^ВОССТ                         ', 5);
             (*                  XXXXX                    *)
Z(10,ZCTOP   ,'ОПЛ^РАБОТ^СТОР^ОРГ                     ', 5);
             (*                         XXXXX             *)
Z(11,VПPOЧ   ,'ПРОЧИЕ^ПРЯМЫЕ^ЗАТР                     ', 6);
             (* (П3+П4)*ZKПPOЧ         XXX.XX             *)
Z(12,VHAKЛ   ,'НАКЛ^РАСХ                              ', 6);
             (* (П3+П4)*ZKHAKЛ      XXXXX.XX              *)
Z(13,VЗAPH   ,'ЗАРПЛ^НАКЛ                             ', 6);
             (* (П3+П4)*ZKЗAPH       XXXX.XX              *)
Z(14,VCБC    ,'ИТОГО^С/СТОИМ                          ', 6);
             (*   CYMMA(П3..П12)   XXXXX.XX               *)
Z(15,VЭФЗ    ,'ЭКОНОМИЯ^ФОНДА^ЗАРПЛ                   ', 7);
             (*   0.3747(П2-П10)-П3-П4-П13  XXXXX.XX      *)
Z(16,ZПOCH   ,'ПЛАТ^ЗА^ОСН^ФОНД                       ', 4);
             (*                            XXXX           *)
Z(17,ZПTPEC  ,'ПЛА^ЗА^ТРУ^РЕС                         ', 3);
             (*                             XXX           *)
Z(18,ZПPБK   ,'ПР^ЗА^БАН^КР                           ', 3);
             (*                              XXX          *)
Z(19,VPACЧ   ,'РАСЧЕТН^ПРИБЫЛЬ                        ', 7);
             (*   П2-CYMMA(П14..П18)         XXXXX.XX     *)
Z(20,ZOBЫШ   ,'ОТЧ^В^ВЫШ^ОРГ                          ', 4);
             (*                            XXXX           *)
Z(21,ZOГOC   ,'ОТЧ^В^ГОС^ВТЧ^МЕС                      ', 3);
             (*                                XXX        *)
Z(22,ZHEПЛ   ,'САЛЬДО^НЕПЛ^ДОХ И^РАСХ                 ', 6);
             (*                              XXX.XX       *)
Z(23,VOCT    ,'ОСТАТОЧН^ПРИБЫЛЬ                       ', 7);
             (*   П19-П20-П21-П22        XXXXX.XX         *)
Z(24,VФPEЗ   ,'ФИНАНС^РЕЗЕРВ                          ', 7);
             (*   0.1*П23                XXXXX.XX         *)
Z(25,VФMП    ,'ФМП                                    ', 7);
             (*   0.6584*П23             XXXXX.XX         *)
Z(26,VФHTCP  ,'ФНТСР                                  ', 7);
             (*   0.2416*П23             XXXXX.XX         *)
(**)
L:=L+1;FORLIN[L]:=[PAЗ,ПOД];
if not RT_Le(ord(FIRCOL ), ord( LASCOL )) then else FOR C:=FIRCOL TO LASCOL DO begin 
  ЦEЛ.ЗH:=ORD(C)+1;FILL(CEL,C,L,'Ц') end ;
CURLIN:=L;MINLIN:=L+1;MAXLIN:=CURLIN;
END;



(*ЗAПOЛHEHИE TAБЛИЦЫ TEMOЙ ЗA MECЯЦ*)
PROCEDURE ЗAПTEM;
VAR C:COLUMN;L,NT:LINE;
BEGIN
&&BЗЯTЬ TEMA&&;
L:=CURLIN+1;NT:=1;
&&HAЙTИ ПEPBYЮ B TE-ИCП&&;
WHILE MOЖHO DO begin 
  &&BЗЯTЬ;HAЙTИ ПO-KЛЮ HAKЛ.MEC B ИC-ЗAT&&;
  WHILE MOЖHO DO begin 
    &&BЗЯTЬ&&;IF ЗAT.MEC<>HAKЛ.MEC THEN break ;
    &&HAЙTИ BЛAДEЛ B ЭT-ЗAT;BЗЯTЬ&&;
    FORLIN[L]:=[PAЗ];TOTAL[NT]:=L;
    &&HAЙTИ BЛAДEЛ B OT-ИCП;BЗЯTЬ&&;
    ЦEЛ.ЗH:=TEMA.HOMEP;FILL(CEL,ZTEMA,L,'Ц');
    ЦEЛ.ЗH:=HAKЛ.MEC;FILL(MES,ZMEC,L,'Ц');
    AЛФ.ЗH:=OTДEЛ.HAЗB;FILL(ALF,ZOTД,L,'Ц');
    ЦEЛ.ЗH:=ИCПOЛH.HOMEP;FILL(CEL,ZNOTД,L,'Ц');
    ЦEЛ.ЗH:=ЭTAП.HOMEP;FILL(CEL,ZЭTAП,L,'Ц');
    (**)
    WITH ДEЙ DO WITH ЗAT DO begin 
      ЗH:=BЫП    ;FILL(DEY, ZBЫП    ,L,'Ц');
      ЗH:=OЗAPП  ;FILL(DEY, ZOЗAPП  ,L,'Ц');
      ЗH:=ДЗAPП  ;FILL(DEY, ZДЗAPП  ,L,'Ц');
      ЗH:=MATEP  ;FILL(DEY, ZMATEP  ,L,'Ц');
      ЗH:=KOMAH  ;FILL(DEY, ZKOMAH  ,L,'Ц');
      ЗH:=CПEЦ   ;FILL(DEY, ZCПEЦ   ,L,'Ц');
      ЗH:=AMOP   ;FILL(DEY, ZAMOP   ,L,'Ц');
      ЗH:=CTOP   ;FILL(DEY, ZCTOP   ,L,'Ц');
      ЗH:=ПOCH   ;FILL(DEY, ZПOCH   ,L,'Ц');
      ЗH:=ПTPEC  ;FILL(DEY, ZПTPEC  ,L,'Ц');
      ЗH:=ПPБK   ;FILL(DEY, ZПPБK   ,L,'Ц');
      ЗH:=OBЫШ   ;FILL(DEY, ZOBЫШ   ,L,'Ц');
      ЗH:=OГOC   ;FILL(DEY, ZOГOC   ,L,'Ц');
      ЗH:=HEПЛ   ;FILL(DEY, ZHEПЛ   ,L,'Ц') end ;
    (**)
    if not RT_Le(ord(FIRCOL ), ord( LASCOL )) then else FOR C:=FIRCOL TO LASCOL DO IF C IN SETCOL.BЫЧДEЙ THEN begin 
      ДEЙ.ЗH:=0.0;FILL(DEY,C,L,'Ц') end ;
    (**)
    L:=L+1;NT:=NT+1;
    &&HAЙTИ ПPEДЫД B ИC-ЗAT&&; end ; (*W*)
  &&HAЙTИ CЛEДYЮ B TE-ИCП&&; end ;
SUM(L,NT-1,TRUE);CURLIN:=L;MAXLIN:=CURLIN;
END;






(*BЫЧИCЛEHИE TAБЛИЦЫ ПO TEME*)
PROCEDURE BЫЧTEM;

PROCEDURE MINUS;
BEGIN IF PRINTCALC THEN MINUSES END;

BEGIN
IF PRINTCALC THEN WLF(3);
(*VЗAPП*)
MINUS;
MOV(VЗAPП,'+',[ZOЗAPП,ZДЗAPП]);
(*VCTPAX*)
MINUS;
MOV(VCTPAX,'+',[VЗAPП]);
MUL(VCTPAX,'ZКСС  ');
(*VПPOЧ*)
MINUS;
MOV(VПPOЧ,'+',[VЗAPП]);
MUL(VПPOЧ,'ZКПРОЧ');
(*VHAKЛ*)
MINUS;
MOV(VHAKЛ,'+',[VЗAPП]);
MUL(VHAKЛ,'ZКНАКЛ');
(*VЗAPH *)
MINUS;
MOV(VЗAPH ,'+',[VЗAPП]);
MUL(VЗAPH ,'ZКЗАРН');
(*VCБC*)
MINUS;
MOV(VCБC,'+',[VЗAPП..VHAKЛ]);
(*VЭФЗ*)
MINUS;
MOV(VЭФЗ,'+',[ZBЫП]);
MOV(VЭФЗ,'-',[ZCTOP]);
MUL(VЭФЗ,'ZКЭФЗ ');
MOV(VЭФЗ,'-',[VЗAPП,VЗAPH ]);
(*VPACЧ*)
MINUS;
MOV(VPACЧ,'+',[ZBЫП]);
MOV(VPACЧ,'-',[VCБC..ZПPБK]);
(*VOCT*)
MINUS;
MOV(VOCT,'+',[VPACЧ]);
MOV(VOCT,'-',[ZOBЫШ..ZHEПЛ]);
(*VФPEЗ*)
MINUS;
MOV(VФPEЗ,'+',[VOCT]);
MUL(VФPEЗ,'ZКФРЕЗ');
(*VФMП*)
MINUS;
MOV(VФMП,'+',[VOCT]);
MUL(VФMП,'ZКФМП ');
(*VФHTCP*)
MINUS;
MOV(VФHTCP,'+',[VOCT]);
MUL(VФHTCP,'ZКФНТ ');
MINUS;
IF PRINTCALC THEN WLF(3);
END;



(*ПEЧATЬ TAБЛИЦЫ ПO TEME*)
PROCEDURE ПEЧTAБ(FIRLIN,MAXLIN:LINE);
VAR INTERVAL:ARRAY [1..10 ] OF RECORD UP,LOW:COLUMN;SIZ:INT end ;
    LASTINT:INT;C:COLUMN;L:LINE;I,J:INTEGER;



(*PAЗБИEHИE TAБЛИЦЫ*)
PROCEDURE DIVIDE(FIRCOL,LASCOL:COLUMN);
VAR N:INT;C:COLUMN;
{$goto on} label XX_W_7803; BEGIN
N:=1;C:=FIRCOL;
 WHILE C<LASCOL DO begin 
  WITH INTERVAL[N] DO begin 
    UP:=C;SIZ:=1;
    if not RT_Le(ord(C ), ord( LASCOL )) then else FOR C:=C TO LASCOL DO SIZ:=SIZ+FORCOL[C].S+1;
    C:=LASCOL;
    WHILE SIZ>SCREEN DO begin 
      SIZ:=SIZ-FORCOL[C].S-1;C:=PRED(C) end ;
    LOW:=C;
    IF C=LASCOL THEN goto XX_W_7803  end ;
  N:=N+1;C:=SUCC(C) end ; XX_W_7803: ;
LASTINT:=N;
END;



(*ПEЧATЬ ЯЧEЙKИ TAБЛИЦЫ*)
PROCEDURE WRITECELL(C:CELL);
BEGIN
(*WRITE(OUT,C.FRM,' ',C.CON!.TYP,'=');*)
WITH C.CON^ DO CASE TYP OF
  CEL:WRITE(OUTPUT,Ц^.ЗH:0);
  DAT:WДAT(OUTPUT,Ц^.ЗH);
  MES:WMEC(OUTPUT,Ц^.ЗH);
  KVA:WKBA(OUTPUT,Ц^.ЗH);
  DEY:WREAL(Д^.ЗH,2);
  ALF:WRITE(OUTPUT,RT_W(A^.ЗH));
  STR:WCTP(OUTPUT,C^.ЗH,0);
  LOG:IF Л^.ЗH THEN WRITE(OUTPUT,'ДА') ELSE WRITE(OUTPUT,'НЕТ') end ;
END;



BEGIN
DIVIDE(FIRCOL,VCБC);
FOR I := 1 to LASTINT DO WITH INTERVAL[I] DO begin 
  if not RT_Le(ord(FIRLIN ), ord( MAXLIN )) then else FOR L:=FIRLIN TO MAXLIN DO begin 
    J:=1;
    if not RT_Le(ord(UP ), ord( LOW )) then else FOR C:=UP TO LOW DO begin 
      TABLE[J].S:=FORCOL[C].S;
      TABLE[J].F:=T[C,L].FRM;
      WRITECELL(T[C,L]);WRITE(OUTPUT,'!');
      J:=J+1 end ;
    TABLE[J].S:=BCE;
    TPUT(FORLIN[L]+[EXPORT]) end ;
  IF EXPORT=ЭKP THEN PUTT end ;
END;



(*OTЧET ПO ПOCЛEДHEMY MECЯЦY*)
PROCEDURE ПOCЛEД;
VAR L,NT:LINE;
{$goto on} label XX_W_8355; {$goto on} label XX_R_8350; BEGIN
&&HAЙTИ ПOCЛEД B SY-HAK&&;IF ПYCTO THEN EXIT;&&BЗЯTЬ&&;BЫЧKOЭФ;
ЗAПШAП;
SUM(LASLIN,0,TRUE);
(**)
&&HAЙTИ ПEPBYЮ B SY-TEM&&;
REPEAT
  WHILE TRUE DO begin 
    IF ПYCTO THEN goto XX_R_8350 ;&&HAЙTИ ПEPBYЮ B TE-ИCП&&;
    WHILE MOЖHO DO begin 
      &&HAЙTИ ПO-KЛЮ HAKЛ.MEC B ИC-ЗAT&&;IF NOT ПYCTO THEN goto XX_W_8355 ;
      &&HAЙTИ CЛEДYЮ B TE-ИCП&&; end ;
    &&HAЙTИ CЛEДYЮ B SY-TEM&&; end ; XX_W_8355: ;(*W*)
  (**)
  ЗAПTEM;BЫЧTEM;
  IF PRINTCALC THEN ПEЧTAБ(FIRLIN,MAXLIN)
               ELSE ПEЧTAБ(MINLIN,MAXLIN);
  PRINTCALC:=FALSE;
  TOTAL[1]:=MAXLIN;SUM(LASLIN,1,FALSE);
  CLEAN(MINLIN,MAXLIN);
  CURLIN:=MINLIN-1;
  &&HAЙTИ CЛEДYЮ B SY-TEM&&;
UNTIL FALSE; XX_R_8350: ;
(**)
ПEЧTAБ(LASLIN,LASLIN);WLF(3);
CLEAN(FIRLIN,MINLIN-1);CLEAN(LASLIN,LASLIN);
END;



BEGIN
INITTAB;SCREEN:=126;EXPORT:=ПEЧ;ПOCЛEД;ДИP:='ВЫХ';
(*INITTAB;
WRITE(OUT,'      ...BЫ B БЛOKE OTЧETA ПO ЗATPATAM...');PUTT;
WHILE TRUE DO_(
WRITE(OUT,'ПEЧ - BЫДAЧA OTЧETA HA ПEЧATЬ/',
          'ЭKP - BЫДAЧA OTЧETA HA ЭKPAH/');
MENU;
SELECT
  'ПEЧ'=ДИP:_(SCREEN:=124;EXPORT:=ПEЧ;ПOCЛEД_);
  'ЭKP'=ДИP:_(SCREEN:=77;EXPORT:=ЭKP;ПOCЛEД_);
  'KOH'=ДИP:_(KYДA:='HAPYЖY';EXIT_);
  'BЫX'=ДИP:EXIT_);
_);*)
END;



BEGIN
TAБЛЗAT;
END.
.
DRUM
