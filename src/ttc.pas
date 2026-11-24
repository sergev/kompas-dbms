{$mode tp}{$H-}{$R-}{$Z4}
program ttc15; uses krt, kio, mars; type XT0 = array[1..40] of alfa; XT1 = array[1..1000] of alfa; XT2 = array[1..40] of integer;
(* TTC: the schema translator (DDL).
   Reads YOD operators from INPUT and writes the schema into MARS
   containers CXHD/CXFL/CXAT of catalogue 270000 for kdb.pas:
   NUM: counts; Tnnn: type; Rnnn: record; Frrrff: field; Snnn: set;
   Asssaa: set attribute.  Sizes keep all digits; CИMBOЛ n keeps n. *)
type
  Lint = packed array[1..72] of char;
  Dta  = packed array[1..48] of char;
  Num8 = packed array[1..10] of char;
var
  BDVECT: array [0..167] of integer;
  BDERRN: integer;
  PIC: integer;
  ln: Lint;
  p, i, j, k: integer;
  kw, a, b, c, q, w, pol: alfa;
  num, w8: Num8;
  cur, nerr: integer;
  tn, tb, ts: XT0;
  tcnt: integer;
  rn: XT0;
  rf, rt, rs, rm: XT1;
  rcnt: XT2;
  rnum: integer;
  sn, sm, so: XT0;
  sa, sv: XT1;
  bv: array [1..1000] of Num8;
  scnt: XT2;
  snum: integer;
  done, ign: boolean;
  curar: alfa;
  ra: XT0;
  tl: XT0;
  tz: array [1..40] of Num8;
  rl: XT1;
  rz: array [1..1000] of Num8;
  d: Dta;



function IsBlank(s:alfa):boolean;
var j:integer; t:boolean;
begin
  t := true;
  for j:=1 to 6 do if s[j] <> ' ' then t := false;
  IsBlank := t
end;
procedure Clr(var s:alfa);
var j:integer;
begin for j:=1 to 6 do s[j]:=' ' 
end;
procedure Skip;
begin while (p <= 72) and (ln[p]=' ') do p := p+1 
end;
procedure SkipSep;
begin
  while (p <= 72) and ((ln[p]=' ') or (ln[p]=':') or (ln[p]=';') or
        (ln[p]=',') or (ln[p]='.')) do p := p+1;
  if (p <= 72) and ((ln[p]='?') or (ln[p]='*')) then p := 73
end;
procedure Tok(var t:alfa);
var j:integer;
begin
  Clr(t); Skip; j := 1;
  while (p <= 72) and (j <= 6) and (ln[p]<>' ') and (ln[p]<>':') and
        (ln[p]<>';') and (ln[p]<>',') and (ln[p]<>'.') and
        (ln[p]<>'?') and (ln[p]<>'*') do begin
    t[j] := ln[p]; p := p+1; j := j+1
  end;
  while (p <= 72) and (ln[p]<>' ') and (ln[p]<>':') and
        (ln[p]<>';') and (ln[p]<>',') and (ln[p]<>'.') and
        (ln[p]<>'?') and (ln[p]<>'*') do p := p+1
end;
procedure GetNum(var z:Num8);
var j:integer;
begin
  for j:=1 to 10 do z[j]:=' ';
  Skip; j := 1;
  while (p <= 72) and (ln[p] >= '0') and (ln[p] <= '9') and
        (j <= 10) do begin
    z[j] := ln[p]; p := p+1; j := j+1
  end
end;
procedure Tok8(var z:Num8);
var j:integer;
begin
  for j:=1 to 10 do z[j]:=' ';
  Skip; j := 1;
  while (p <= 72) and (j <= 10) and (ln[p]<>' ') and (ln[p]<>':') and
        (ln[p]<>';') and (ln[p]<>',') and (ln[p]<>'?') and
        (ln[p]<>'*') do begin
    z[j] := ln[p]; p := p+1; j := j+1
  end
end;
procedure Copy6(src:Num8; var dst:alfa);
var j:integer;
begin for j:=1 to 6 do dst[j] := src[j] 
end;
procedure Put6(var x:Dta; o:integer; s:alfa);
var j:integer;
begin for j:=1 to 6 do x[o+j-1] := s[j] 
end;
procedure ClearD;
var j:integer;
begin for j:=1 to 48 do d[j]:=' ' 
end;
procedure KeyN(c:char; n,w:integer; var key:alfa);
(* c, then n in w digits, blank padded *)
var j:integer;
begin
  Clr(key); key[1] := c;
  for j := w+1 downto 2 do begin
    key[j] := chr(ord('0') + (n mod 10)); n := n div 10
  end
end;
procedure PutNum(o,w,n:integer);
var j:integer;
begin
  for j := o+w-1 downto o do begin
    d[j] := chr(ord('0') + (n mod 10)); n := n div 10
  end
end;
procedure PutNum8(o:integer; z:Num8);
var j:integer;
begin for j:=1 to 10 do d[o+j-1] := z[j] 
end;
procedure InitMars;
var iw:integer;
begin
  (* the catalogue made by SERVIS is kept: no PASACD *)
  PASSETAR(94208);
  pasbdi; BDERRN := 0;
  iw := 618496 + 1; newd('CXHD  ', iw);
pasbdi; BDERRN := 0;
  iw := 618496 + 2; newd('CXFL  ', iw);
pasbdi; BDERRN := 0;
  iw := 618496 + 3; newd('CXAT  ', iw);
pasbdi; BDERRN := 0
end;
procedure PutHere(key:alfa);
begin
  modd(key, d, sizeof(d));
  if BDERRN <> 0 then begin
    nerr := nerr+1;
    writeln('MARS ERR ',RT_W( BDERRN), ' KEY=',RT_W( key))
  end;
  pasbdi; BDERRN := 0
end;
procedure AddType;
begin
  if tcnt < 40 then begin
    tcnt := tcnt+1;
    Tok(q); tn[tcnt] := q;
    Tok(q); tb[tcnt] := q;
    Clr(w); ts[tcnt] := w; tl[tcnt] := w;
    for j:=1 to 10 do tz[tcnt][j] := ' ';
    Tok(q);
    if (q[1] >= '0') and (q[1] <= '9') then begin
      tl[tcnt] := q; Tok(q)
    end;
    if q = 'РАЗМЕР' then begin
      GetNum(num); Copy6(num, w); ts[tcnt] := w; tz[tcnt] := num
    end
  end
end;
procedure AddRec;
begin
  if rnum < 40 then begin
    rnum := rnum+1;
    Tok(q); rn[rnum] := q; rcnt[rnum] := 0; cur := 2;
    ra[rnum] := curar
  end
end;
procedure AddSet;
begin
  if snum < 40 then begin
    snum := snum+1;
    Tok(q); sn[snum] := q;
    Clr(w); sm[snum] := w; so[snum] := w;
    scnt[snum] := 0; cur := 3
  end
end;
procedure AddFld;
begin
  if (cur = 2) and (rnum > 0) then
    if rcnt[rnum] < 25 then begin
      rcnt[rnum] := rcnt[rnum]+1;
      k := rcnt[rnum];
      Tok(q); rf[(rnum-1)*25+k] := q;
      Tok(q); rt[(rnum-1)*25+k] := q;
      Clr(w); rs[(rnum-1)*25+k] := w; rm[(rnum-1)*25+k] := w;
      rl[(rnum-1)*25+k] := w;
      for j:=1 to 10 do rz[(rnum-1)*25+k][j] := ' ';
      Tok(q);
      if (q[1] >= '0') and (q[1] <= '9') then begin
        rl[(rnum-1)*25+k] := q; Tok(q)
      end;
      if q = 'РАЗМЕР' then begin
        GetNum(num); Copy6(num, w); rs[(rnum-1)*25+k] := w;
        rz[(rnum-1)*25+k] := num;
        Tok(q)
      end;
      if q = 'КОНСИМ' then rm[(rnum-1)*25+k] := q
    end
end;
procedure AddAtt(x,y:alfa);
begin
  if (cur = 3) and (snum > 0) then
    if scnt[snum] < 25 then begin
      scnt[snum] := scnt[snum]+1;
      k := scnt[snum];
      sa[(snum-1)*25+k] := x; sv[(snum-1)*25+k] := y;
      for j:=1 to 10 do w8[j]:=' ';
      bv[(snum-1)*25+k] := w8;
      if x = 'УПОРЯД' then sm[snum] := y;
      if x = 'ВЛАДЕЛ' then so[snum] := y;
      if x = 'ЧЛЕН  ' then sm[snum] := y
    end
end;
procedure DoAtt(x:alfa);
var y:alfa; z:Num8;
begin
  if x = 'УПОРЯД' then begin
    Tok(y);
    if not IsBlank(y) then AddAtt(x,y);
    Tok(y);
    if not IsBlank(y) then AddAtt(pol,y)
  end else if x = 'ВЫБОР ' then begin
    Tok(y);
    if not IsBlank(y) then AddAtt(x,y);
    Tok(y);
    Tok8(z);
    if z[1] <> ' ' then bv[(snum-1)*25+scnt[snum]] := z
  end else begin
    Tok(y);
    AddAtt(x,y)
  end
end;
procedure StoreAll;
begin
  opend('CXHD  ');
  ClearD; PutNum(1,3,tcnt); PutNum(4,3,rnum); PutNum(7,3,snum);
  PutHere('NUM   ');
  for i:=1 to tcnt do begin
    ClearD; Put6(d,1,tn[i]); Put6(d,7,tb[i]); Put6(d,13,tl[i]);
    PutNum8(19,tz[i]);
    KeyN('T',i,3,q); PutHere(q)
  end;
  for i:=1 to rnum do begin
    opend('CXHD  ');
    ClearD; Put6(d,1,rn[i]); Put6(d,7,ra[i]); PutNum(13,3,rcnt[i]);
    KeyN('R',i,3,q); PutHere(q);
    opend('CXFL  ');
    for j:=1 to rcnt[i] do begin
      ClearD; Put6(d,1,rf[(i-1)*25+j]); Put6(d,7,rt[(i-1)*25+j]);
      Put6(d,13,rl[(i-1)*25+j]); PutNum8(19,rz[(i-1)*25+j]);
      Put6(d,29,rm[(i-1)*25+j]);
      KeyN('F',i*100+j,5,q); PutHere(q)
    end
  end;
  for i:=1 to snum do begin
    opend('CXHD  ');
    ClearD; Put6(d,1,sn[i]); PutNum(7,3,scnt[i]);
    KeyN('S',i,3,q); PutHere(q);
    opend('CXAT  ');
    for j:=1 to scnt[i] do begin
      ClearD; Put6(d,1,sa[(i-1)*25+j]); Put6(d,7,sv[(i-1)*25+j]);
      PutNum8(13,bv[(i-1)*25+j]);
      KeyN('A',i*100+j,5,q); PutHere(q)
    end
  end
end;
procedure PrintAll;
var z:Num8;
begin
  writeln('=== TYPES ',RT_W( tcnt), ' ===');
  for i:=1 to tcnt do
    writeln(' ',RT_W( tn[i]), ' BASE=',RT_W( tb[i]), ' SZ=',RT_W( ts[i]));
  writeln('=== RECORDS ',RT_W( rnum), ' ===');
  for i:=1 to rnum do begin
    writeln(' ',RT_W( rn[i]), ' FIELDS=',RT_W( rcnt[i]));
    for j:=1 to rcnt[i] do
      writeln('   ',RT_W( rf[(i-1)*25+j]), ' ',RT_W( rt[(i-1)*25+j]),
              ' ',RT_W( rs[(i-1)*25+j]), ' ',RT_W( rm[(i-1)*25+j]))
  end;
  writeln('=== SETS ',RT_W( snum), ' ===');
  for i:=1 to snum do begin
    writeln(' ',RT_W( sn[i]), ' MEMBER=',RT_W( sm[i]), ' OWNER=',RT_W( so[i]),
            ' ATT=',RT_W( scnt[i]));
    for j:=1 to scnt[i] do begin
      writeln('   ',RT_W( sa[(i-1)*25+j]), ' ',RT_W( sv[(i-1)*25+j]));
      z := bv[(i-1)*25+j];
      if z[1] <> ' ' then
        writeln('      ИСПОЛЬЗ ',RT_W( z))
    end
  end
end;
begin MarsBind(@bdvect, @bderrn);
  InitMars;
  tcnt := 0; rnum := 0; snum := 0; cur := 0; nerr := 0;
  done := false; pol := 'ПОЛЕ  '; Clr(curar);
  writeln('TTC15');
  while not eof(input) and not done do begin
    for j:=1 to 72 do ln[j] := ' ';
    RT_ReadLn(ln);
    RT_Fold(ln);
    p := 1;
    while (p <= 72) and not done do begin
      SkipSep;
      if p <= 72 then begin
        Tok(kw);
        if IsBlank(kw) then p := 73 else
        if (kw='КОНЕЦ.') or (kw='КОНЕЦ ') then done := true else
        if kw = 'ТИП   ' then AddType else
        if kw = 'ЗАПИСЬ' then AddRec else
        if kw = 'НАБОР ' then AddSet else
        if kw = 'ОБЛАСТ' then begin Tok(a); curar := a end else
        if kw = 'ЭЛ    ' then AddFld else
        if (kw='ЧЛЕН  ') or (kw='ВЛАДЕЛ') or (kw='ПРИВЯЗ') or
           (kw='УПОРЯД') or (kw='ИСКЛЮЧ') or (kw='ВКЛЮЧЕ') or
           (kw='ДУБЛИК') or (kw='КОНСИМ') or (kw='ВРУЧНУ') or
           (kw='ИЕРАРХ') or (kw='ОДНОЗН') or
           (kw='ВЫБОР ') then DoAtt(kw)
        else p := 73
      end
    end
  end;
  StoreAll;
  PrintAll;
  writeln('SAVED=',RT_W( tcnt+rnum+snum), ' MARSERR=',RT_W( nerr));
  writeln('EXN=',RT_W( BDERRN))
end.
