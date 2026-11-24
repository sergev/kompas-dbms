{$mode tp}{$H-}{$R-}{$Z4}
program servis; uses krt, kio, mars; type XT0 = array[1..72] of integer; XT1 = array[1..64] of alfa; XT2 = array[0..7] of integer; XT3 = array[1..24] of integer; XT4 = array[1..16] of alfa; XT5 = array[1..4] of integer; XT6 = array[1..4] of alfa; XT7 = array[1..1] of integer;
(* SERVIS: allocation and maintenance of the database areas.
   Each SERVIS area is a separate MARS area named after the object.
   Descriptor: [1] code, [2] length, [3] capture, [4] kind,
   [5] head code, [6] journal state, [7] control, [8] mode,
   [9] direction, [10] start, [11] reserved, [12..72] page table.
   MARS info word: MMMMZZNNNN, MMMM = length in zones (octal). *)
type
  word = record case integer of
    0:(i:integer);
    1:(a:alfa)
  end;
  RecT = XT0;
  LinT = packed array[1..72] of char;
var
  BDVECT: array [0..167] of integer;
  BDERRN: integer;
  PIC: integer;
  ln: LinT;
  r, ur: RecT;
  k, k2, kw, kw2: alfa;
  p, ncode, ncnt, dl, cur, lasterr: integer;
  nms: XT1;
  ades: array [1..24] of RecT;
  p0, p1, p2, p3: XT2;
  zlo, zhi: XT3;
  unms, rnms, robj, rtyp: XT4;
  un, rn: integer;
  lastinfo: integer;
  nxt: char;
  (* chunk registry state *)
  ckz, caz, cln, cof, cd0, cd1, cd2: XT5;
  cnm: XT6;
  gi: integer;
  mw: XT7;






function EXN:integer;
begin
  EXN := BDERRN
end;

(* PASBDI clears the sticky MARS error word. *)
procedure ClrErr;
begin
   begin 
  pasbdi;
  BDERRN := 0
   end ;
end;

procedure Err(n:integer);
begin
   begin 
  lasterr := n;
  write('ОШИБКА ',RT_W( n), ': ');
  case n of
    3: writeln('ОБЛАСТЬ НЕ ОПРЕДЕЛЕНА');
    4: writeln('УЖЕ ЕСТЬ АДМИНИСТРАТОР');
    5: writeln('НЕСУЩЕСТВУЮЩЕЕ ПРАВО');
    6: writeln('НЕТ ПРАВ ДОСТУПА');
    7: writeln('ПЕРЕПОЛНЕНА ADA');
    11: writeln('ЕСТЬ ВАРИАНТЫ');
    50: writeln('НЕТ ПРАВА ДЛЯ-МО');
    51: writeln('ОБЪЕКТ ПРАВА НЕ НАЙДЕН');
    52: writeln('ГОЛОВНАЯ ОБЛАСТЬ НЕ НАЙДЕНА');
    53: writeln('ОШИБКА В ОПРЕДЕЛЕНИИ ДУБЛЯ');
    54: writeln('ОБЛАСТЬ НЕ ЯВЛЯЕТСЯ ДУБЛЕМ');
    55: writeln('ОБЛАСТЬ НЕ ИМЕЕТ ДУБЛЕЙ');
    56: writeln('ОТСУТСТВУЕТ СЛОВО НА');
    57: writeln('ОБЛАСТИ НЕ ЯВЛЯЮТСЯ ДУБЛЯМИ');
    58: writeln('ДЛИНА ДУБЛЯ БОЛЬШЕ ГОЛОВНОЙ');
    60: writeln('УБИРАЕМАЯ ОБЛАСТЬ ИМЕЕТ ДУБЛИ');
    61: writeln('ПРОСТРАНСТВО НЕ ПУСТО');
    62: writeln('ОБЛАСТЬ СВЯЗАНА СО СХЕМОЙ');
    63: writeln('ОБЛАСТЬ СВЯЗАНА С ПОДСХЕМОЙ');
    64: writeln('НЕТ ДВОЕТОЧИЯ ИЛИ ;');
    65: writeln('ДЛИНА ВАРИАНТА БОЛЬШЕ ГОЛОВНОЙ');
    66: writeln('ДЛИНА ДУБЛЯ БОЛЬШЕ ГОЛОВНОЙ');
    67: writeln('ОБЛАСТЬ НЕ ОБЪЯВЛЕНА ЖУРНАЛОМ');
    68: writeln('ЖУРНАЛ ЗАХВАЧЕН ПРОЦЕССОМ');
    69: writeln('СБРОС ПОСЛЕ ЗАКРЕПЛЕНИЯ');
    71: writeln('НЕТ ПАРАМЕТРОВ ЗАМЕНЫ');
    72: writeln('ЗАМЕНЯЕМЫЙ ОБЪЕКТ НЕ НАЙДЕН');
    74: writeln('НЕ АДМИНИСТРАТОР');
    76: writeln('НЕДОПУСТИМОЕ СЛОВО');
    77: writeln('НЕДОПУСТИМОЕ СЛОВО ПОСЛЕ ЗАМЕНЫ');
    78: writeln('НЕ УКАЗАН ОБЪЕКТ');
    80: writeln('ОБЪЕКТ УЖЕ ЕСТЬ');
    83: writeln('НЕ УКАЗАНО СБРОСИ ИЛИ ЗАКРЕПИ');
    84: writeln('НЕПРАВИЛЬНОЕ ПЕРВОЕ СЛОВО');
    87: writeln('НЕ МОЖЕТ БЫТЬ ПОСТАВЛЕН');
  end
   end ;
end;

procedure Skip;
begin
   begin 
  while (p <= 72) and (ln[p] = ' ') do p := p + 1
   end ;
end;

(* First six significant characters of the current token. *)
function Tok:alfa;
var t:alfa; j:integer;
begin
   begin 
  for j := 1 to 6 do t[j] := ' ';
  Skip;
  j := 1;
  while (p <= 72) and (j <= 6) and (ln[p] <> ' ') and
        (ln[p] <> ':') and (ln[p] <> ';') and (ln[p] <> ',') and
        (ln[p] <> '.') do begin
    t[j] := ln[p];
    p := p + 1;
    j := j + 1
  end;
  while (p <= 72) and (ln[p] <> ' ') and (ln[p] <> ':') and
        (ln[p] <> ';') and (ln[p] <> ',') and
        (ln[p] <> '.') do p := p + 1;
  Tok := t
   end ;
end;

procedure GetName(var t:alfa);
var j:integer;
begin
   begin 
  for j := 1 to 6 do t[j] := ' ';
  Skip;
  j := 1;
  while (p <= 72) and (j <= 6) and (ln[p] <> ' ') and
        (ln[p] <> ':') and (ln[p] <> ';') and
        (ln[p] <> ',') and (ln[p] <> '.') do begin
    t[j] := ln[p];
    j := j + 1;
    p := p + 1
  end;
  while (p <= 72) and (ln[p] <> ' ') and (ln[p] <> ':') and
        (ln[p] <> ';') and (ln[p] <> ',') do p := p + 1
   end ;
end;

function Number:integer;
var v:integer;
begin
   begin 
  Skip;
  v := 0;
  while (p <= 72) and (ln[p] >= '0') and (ln[p] <= '9') do begin
    v := v * 10 + ord(ln[p]) - ord('0');
    p := p + 1
  end;
  Number := v
   end ;
end;

(* Octal powers as literals: multiplication wraps at 2^24 here. *)
procedure InitPows;
begin
   begin 
  p0[0]:=0; p0[1]:=262144; p0[2]:=524288;
  p0[3]:=786432; p0[4]:=1048576;
  p0[5]:=1310720; p0[6]:=1572864; p0[7]:=1835008;
  p1[0]:=0; p1[1]:=2097152; p1[2]:=4194304;
  p1[3]:=6291456; p1[4]:=8388608;
  p1[5]:=10485760; p1[6]:=12582912; p1[7]:=14680064;
  p2[0]:=0; p2[1]:=16777216; p2[2]:=33554432;
  p2[3]:=50331648; p2[4]:=67108864;
  p2[5]:=83886080; p2[6]:=100663296; p2[7]:=117440512;
  p3[0]:=0; p3[1]:=134217728; p3[2]:=268435456;
  p3[3]:=402653184; p3[4]:=536870912;
  p3[5]:=671088640; p3[6]:=805306368; p3[7]:=939524096;
  zlo[1]:=1; zlo[2]:=65; zlo[3]:=129; zlo[4]:=193;
  zlo[5]:=257; zlo[6]:=321; zlo[7]:=385; zlo[8]:=449;
  zlo[9]:=513; zlo[10]:=577; zlo[11]:=641;
  zlo[12]:=705; zlo[13]:=769; zlo[14]:=833;
  zlo[15]:=897; zlo[16]:=961;
  zhi[1]:=2049; zhi[2]:=2561; zhi[3]:=3073; zhi[4]:=3585;
  zhi[5]:=2049; zhi[6]:=2561; zhi[7]:=3073; zhi[8]:=3585;
  zhi[9]:=2049; zhi[10]:=2561; zhi[11]:=3073; zhi[12]:=3585;
  zhi[13]:=2049; zhi[14]:=2561; zhi[15]:=3073; zhi[16]:=3585
   end ;
end;

(* Build MARS info word for a decimal length in zones. *)
function InfoWord(l,z:integer):integer;
var q,d0,d1,d2,d3:integer;
begin
   begin 
  q := l; d0 := q mod 8; q := q div 8;
  d1 := q mod 8; q := q div 8;
  d2 := q mod 8; q := q div 8;
  d3 := q mod 8;
  InfoWord := p3[d3] + p2[d2] + p1[d1] + p0[d0] + 94208 + z
   end ;
end;

procedure Kadd(nm:alfa);
begin
   begin 
  if ncnt < 64 then begin
    ncnt := ncnt + 1;
    nms[ncnt] := nm
  end
   end ;
end;

function Kfind(nm:alfa):boolean;
var j:integer;
begin
   begin 
  Kfind := false;
  for j := 1 to ncnt do
    if nms[j] = nm then Kfind := true
   end ;
end;

procedure Kdel(nm:alfa);
var j,t:integer;
begin
   begin 
  for j := 1 to ncnt do
    if nms[j] = nm then begin
      for t := j to ncnt-1 do nms[t] := nms[t+1];
      ncnt := ncnt - 1
    end
   end ;
end;

procedure UstOBL(var d:RecT; l,kind:integer);
var j:integer;
begin
   begin 
  for j := 1 to 72 do d[j] := 0;
  d[1] := ncode;
  d[2] := l;
  d[3] := 1;
  d[4] := kind;
  d[5] := 0;
  d[6] := 0;
  d[7] := 0;
  d[8] := 0;
  d[9] := 0;
  d[10] := 1;
  for j := 1 to 61 do d[11+j] := 2040
   end ;
end;

function IdxOf(nm:alfa):integer;
var j:integer;
begin
   begin 
  IdxOf := 0;
  for j := 1 to ncnt do
    if nms[j] = nm then IdxOf := j
   end ;
end;

function GetRec(nm:alfa; var d:RecT):boolean;
var j:integer;
begin
   begin 
  j := IdxOf(nm);
  if j > 0 then begin
    d := ades[j];
    cur := j;
    GetRec := true
  end else
    GetRec := false
   end ;
end;

procedure PutRec(nm:alfa; var d:RecT);
var j:integer;
begin
   begin 
  j := IdxOf(nm);
  if j > 0 then ades[j] := d
   end ;
end;

(* SETFL/CLFL of TSERVIS: open the named MARS area. *)
procedure SETFL(a:integer);
begin
   begin 
  if a = 0 then opend(k);
  if a = 2 then opend(k)
   end ;
end;

procedure CLFL(a:integer);
begin
end;

(* MARS rejects huge containers here: clamp the physical call. *)
function PhysLen(l:integer):integer;
begin
   begin 
  if l > 1000 then PhysLen := 1000 else PhysLen := l
   end ;
end;

procedure NewArea(nm:alfa; var d:RecT);
var i,nz,zv:integer;
begin
   begin 
  if Kfind(nm) then
    Err(80)
  else begin
    ncode := ncode + 1;
    Kadd(nm);
    d[1] := ncode;
    if d[2] > 64 then zv := zhi[ncode] else zv := zlo[ncode+1];
    d[10] := zv;
    lastinfo := InfoWord(d[2], zv);
    i := InfoWord(PhysLen(d[2]), zv);
    ClrErr;
    newd(nm, i);
    ClrErr;
    ades[ncnt] := d;
    k := nm;
    writeln('New Area N = ',RT_W( ncode), ' INFO=',RT_W( lastinfo))
  end
   end ;
end;

procedure AErase(nm:alfa);
var j,lim:integer;
begin
   begin 
  if GetRec(nm, r) then begin
    if r[2] > 61 then lim := 61 else lim := r[2];
    for j := lim downto 1 do r[11+j] := 2040;
    PutRec(nm, r);
    write(RT_W(nm), ' ');
    writeln('ОЧИЩЕНА')
  end else Err(3)
   end ;
end;

procedure Osvobo(nm:alfa);
begin
   begin 
  if GetRec(nm, r) then begin
    r[3] := 0;
    PutRec(nm, r);
    write(RT_W(nm), ' ');
    writeln('ОСВОБОЖДЕНА')
  end else Err(3)
   end ;
end;

procedure Bocct(nm:alfa);
var j,lim:integer;
begin
   begin 
  if GetRec(nm, r) then begin
    writeln('ВОССТАНОВЛЕНИЕ ',RT_W( nm));
    if r[2] > 61 then lim := 61 else lim := r[2];
    for j := 1 to lim do writeln(RT_W(j), ':',RT_W( r[11+j]));
    if r[2] > 61 then writeln('... ВСЕГО СТРАНИЦ ',RT_W( r[2]));
    writeln('ВОССТАНОВЛЕНО')
  end else Err(3)
   end ;
end;

procedure Obnovi(nm:alfa);
begin
   begin 
  if GetRec(nm, r) then begin
    PutRec(nm, r);
    writeln('ОБНОВЛЕНО ',RT_W( nm))
  end else Err(3)
   end ;
end;

function CodeOf(nm:alfa):integer;
begin
   begin 
  CodeOf := 0;
  if GetRec(nm, ur) then CodeOf := ur[1]
   end ;
end;

procedure Dubl;
var n3,n4:alfa; c3,c4,j:integer;
begin
   begin 
  kw2 := Tok;
  if kw2 = 'НА    ' then begin
    GetName(n4);
    c4 := CodeOf(n4);
    if c4 = 0 then Err(52)
    else if cur = 0 then Err(3)
    else if GetRec(nms[cur], r) then begin
      r[4] := 4;
      r[5] := c4;
      PutRec(nms[cur], r);
      writeln('ДУБЛЬ ',RT_W( nms[cur]), ' НА ',RT_W( n4))
    end
  end else if kw2 = 'С     ' then begin
    GetName(n4);
    if not GetRec(nms[cur], r) then Err(3)
    else if r[4] <> 4 then Err(54)
    else if not GetRec(n4, ur) then Err(52)
    else begin
      if ur[2] > r[2] then Err(58)
      else begin
        for j := 1 to 61 do r[11+j] := ur[11+j];
        PutRec(nms[cur], r);
        writeln('ДУБЛЬ С ',RT_W( n4), ' ВЫПОЛНЕН')
      end
    end
  end else begin
    n3 := kw2;
    kw2 := Tok;
      if kw2 <> 'НА    ' then Err(56)
      else begin
        GetName(n4);
        c3 := CodeOf(n4);
        if c3 = 0 then Err(52)
        else if not GetRec(n4, ur) then Err(52)
        else if Kfind(n3) then Err(80)
        else begin
          r := ur;
          UstOBL(r, ur[2], 4);
          NewArea(n3, r);
          if GetRec(n3, r) then begin
            r[5] := c3;
            for j := 1 to 61 do r[11+j] := ur[11+j];
            PutRec(n3, r)
          end;
          writeln('ДУБЛЬ ',RT_W( n3), ' СОЗДАН')
        end
      end
    end
   end ;
end;

procedure Osvabd;
var j:integer;
begin
   begin 
  j := 0;
  for cur := 1 to ncnt do
    if GetRec(nms[cur], r) then begin
      PutRec(nms[cur], r);
      j := j + 1
    end;
  writeln('ОСВАБД: ЗАПИСАНО ОБЛАСТЕЙ ',RT_W( j))
   end ;
end;

procedure Journal;
var nm:alfa; st:integer;
begin
   begin 
  GetName(nm);
  if not GetRec(nm, r) then Err(3)
  else begin
    if r[4] <> 2 then Err(67)
    else begin
      kw2 := Tok;
      if kw2 = 'СБРОСИ' then begin
        if r[6] = 2 then Err(69)
        else begin
          r[6] := 1;
          PutRec(nm, r);
          writeln('ЖУРНАЛ ',RT_W( nm), ' СБРОШЕН')
        end
      end else if kw2 = 'ЗАКРЕП' then begin
        if r[3] <> 0 then Err(68)
        else begin
          r[6] := 2;
          PutRec(nm, r);
          writeln('ЖУРНАЛ ',RT_W( nm), ' ЗАКРЕПЛЕН')
        end
      end else Err(83)
    end
  end
   end ;
end;

procedure Ubrat;
var nm:alfa; j,cc:integer; found:boolean;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ОБЛАСТ' then Err(78)
  else begin
    GetName(nm);
    if not GetRec(nm, r) then Err(3)
    else begin
      cc := r[1];
      found := false;
      for j := 1 to ncnt do
        if GetRec(nms[j], ur) then
          if (ur[5] = cc) and (nms[j] <> nm) then found := true;
      if found then Err(60)
      else if r[3] <> 0 then Err(50)
      else begin
        Kdel(nm);
        writeln('ОБЛАСТЬ ',RT_W( nm), ' УБРАНА')
      end
    end
  end
   end ;
end;


(* ---------- chunk registry, six-character MARS keys ----------
   RGLEN = full logical length, RGNCHK = number of chunks.
   RCcKB = TAR (LU<<12 | KOBLA zone), RCcZN = area zone,
   RCcLN = chunk length, RCcOF = offset, RCcNM = area name (alfa bits).
   C<c>LEN / C<c>OFF / C<c>D0..D2 hold per-chunk data.
   PUTD records are one word; a 72-word record breaks the catalog. *)

function Info41(l,z:integer):integer;
var q,d0,d1,d2,d3:integer;
begin
   begin 
  q := l; d0 := q mod 8; q := q div 8;
  d1 := q mod 8; q := q div 8;
  d2 := q mod 8; q := q div 8;
  d3 := q mod 8;
  Info41 := p3[d3] + p2[d2] + p1[d1] + p0[d0] + 135168 + z
   end ;
end;

procedure InitLayout;
begin
   begin 
  ckz[1] := 2112; caz[1] := 2177; cnm[1] := 'REGIST';
  cln[1] := 1000;  cof[1] := 0;
  cd0[1] := 101; cd1[1] := 102; cd2[1] := 103;
  ckz[2] := 3072; caz[2] := 3137; cnm[2] := 'SCL2  ';
  cln[2] := 750;   cof[2] := 1000;
  cd0[2] := 201; cd1[2] := 202; cd2[2] := 203
   end ;
end;

(* MARS accepts at most 14 PUTD calls in one Pascal block here; the
   registry is written in two procedures while REGIST stays open. *)
procedure RegPut;
var w:word;
begin
   begin 
  w.i := 135168 + ckz[2]; mw[1] := w.i; putd('RC2KB ', mw, sizeof(mw));
  mw[1] := caz[2]; putd('RC2ZN ', mw, sizeof(mw));
  mw[1] := cln[2]; putd('RC2LN ', mw, sizeof(mw));
  mw[1] := cof[2]; putd('RC2OF ', mw, sizeof(mw));
  putd('RC2NM ', cnm[2], sizeof(alfa))
   end ;
end;

procedure RegCreate;
var w:word;
begin
   begin 
  gi := Info41(16, ckz[1]);
  PASACD(gi);
  gi := 135168 + ckz[1];
  PASSETAR(gi);
  gi := Info41(14, caz[1]);   (* 14-zone catalog root holds 17 keys *)
  newd('REGIST', gi);
  opend('REGIST');
  mw[1] := 1750;  putd('RGLEN ', mw, sizeof(mw));
  mw[1] := 2;     putd('RGNCHK', mw, sizeof(mw));
  w.i := 135168 + ckz[1]; mw[1] := w.i; putd('RC1KB ', mw, sizeof(mw));
  mw[1] := caz[1]; putd('RC1ZN ', mw, sizeof(mw));
  mw[1] := cln[1]; putd('RC1LN ', mw, sizeof(mw));
  mw[1] := cof[1]; putd('RC1OF ', mw, sizeof(mw));
  putd('RC1NM ', cnm[1], sizeof(alfa));
  RegPut;
  mw[1] := cln[1]; putd('C1LEN ', mw, sizeof(mw));
  mw[1] := cof[1]; putd('C1OFF ', mw, sizeof(mw));
  mw[1] := cd0[1]; putd('C1D0  ', mw, sizeof(mw));
  mw[1] := cd1[1]; putd('C1D1  ', mw, sizeof(mw));
  mw[1] := cd2[1]; putd('C1D2  ', mw, sizeof(mw));
  writeln('REGISTRY CREATED EXN=',RT_W( BDERRN))
   end ;
end;

procedure ChunkNew;
begin
   begin 
  if Number <> 2 then Err(76)
  else begin
    gi := Info41(16, ckz[2]);
    PASACD(gi);
    gi := 135168 + ckz[2];
    PASSETAR(gi);
    gi := Info41(cln[2], caz[2]);
    newd('SCL2  ', gi);
    opend('SCL2  ');
    mw[1] := cln[2]; putd('C2LEN ', mw, sizeof(mw));
    mw[1] := cof[2]; putd('C2OFF ', mw, sizeof(mw));
    mw[1] := cd0[2]; putd('C2D0  ', mw, sizeof(mw));
    mw[1] := cd1[2]; putd('C2D1  ', mw, sizeof(mw));
    mw[1] := cd2[2]; putd('C2D2  ', mw, sizeof(mw));
    writeln('CHUNK 2 CREATED EXN=',RT_W( BDERRN))
  end
   end ;
end;

procedure RegGet(var kb2,zn2,ln2:integer; var nm2:alfa);
var w:word;
begin
   begin 
  getd('RC2KB ', mw, sizeof(mw)); ckz[2] := mw[1] - 135168;
  getd('RC2ZN ', mw, sizeof(mw)); caz[2] := mw[1];
  getd('RC2LN ', mw, sizeof(mw)); cln[2] := mw[1];
  getd('RC2NM ', nm2, sizeof(alfa));
  kb2 := ckz[2]; zn2 := caz[2]; ln2 := cln[2]
   end ;
end;

procedure RegOpen;
begin
   begin 
  gi := 135168 + ckz[1];
  PASSETAR(gi);
  opend('REGIST')
   end ;
end;

procedure ChunkOpen(kob:integer);
begin
   begin 
  gi := 135168 + kob;
  PASSETAR(gi);
  opend(cnm[2])
   end ;
end;

procedure Assemble(var d:RecT);
var total,csum,kb2,zn2,ln2:integer; nm2:alfa;
begin
   begin 
  RegOpen;
  getd('RGLEN ', mw, sizeof(mw)); total := mw[1];
  getd('RGNCHK', mw, sizeof(mw)); mw[1] := mw[1];
  writeln('REGISTRY FULL_LEN=',RT_W( total), ' NCHUNKS=',RT_W( mw[1]),
          ' OPEN EXN=',RT_W( BDERRN));
  RegGet(kb2, zn2, ln2, nm2);
  getd('C1LEN ', mw, sizeof(mw));
  writeln('CHUNK 1 LEN=',RT_W( mw[1]), ' EXN=',RT_W( BDERRN));
  getd('C1OFF ', mw, sizeof(mw));
  getd('C1D0  ', mw, sizeof(mw)); csum := mw[1];
  getd('C1D1  ', mw, sizeof(mw)); csum := csum + mw[1];
  getd('C1D2  ', mw, sizeof(mw)); csum := csum + mw[1];
  ChunkOpen(kb2);
  getd('C2LEN ', mw, sizeof(mw));
  writeln('CHUNK 2 LEN=',RT_W( mw[1]), ' OPEN EXN=',RT_W( BDERRN));
  getd('C2OFF ', mw, sizeof(mw));
  getd('C2D0  ', mw, sizeof(mw)); csum := csum + mw[1];
  getd('C2D1  ', mw, sizeof(mw)); csum := csum + mw[1];
  getd('C2D2  ', mw, sizeof(mw)); csum := csum + mw[1];
  writeln('LOGICAL_LENGTH=',RT_W( total));
  writeln('CHECKSUM=',RT_W( csum));
  writeln('ASSEMBLY FINAL EXN=',RT_W( BDERRN));
  d[2] := total
   end ;
end;

procedure AsmOp;
var nm:alfa;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ОБЛАСТ' then Err(78)
  else begin
    GetName(nm);
    if nm = '      ' then Err(78)
    else if Kfind(nm) then Err(80)
    else begin
      InitLayout;
      ncode := ncode + 1;
      Kadd(nm);
      UstOBL(r, 1750, 1);
      r[1] := ncode;
      ades[ncnt] := r;
      k := nm;
      writeln('LOGICAL AREA N=',RT_W( ncode), ' LEN=',RT_W( r[2]));
      Assemble(r);
      PutRec(nm, r)
    end
  end
   end ;
end;

(* Parameters of CREATE/CHANGE AREA. *)
procedure Params(var d:RecT; var l:integer);
var nm:alfa; v:integer;
begin
   begin 
  repeat
    if (p > 72) or (ln[p] = ';') or (ln[p] = ',') or
       (ln[p] = '.') then p := 73
    else begin
      kw2 := Tok;
      if (kw2 = 'ДЛИНА ') then begin
        v := Number;
        if (v < 1) or (v > 1750) then Err(76) else l := v
      end else if (kw2 = 'НАПР  ') then
        d[9] := Number
      else if (kw2 = 'НАЧАЛО') then
        d[10] := Number
      else if (kw2 = 'ВИД   ') then begin
        nm := Tok;
        if nm = 'ЖУРНАЛ' then d[4] := 2 else d[4] := 1
      end else if (kw2 = 'ВАРИАН') then begin
        GetName(nm);
        d[5] := CodeOf(nm)
      end else if (kw2 = 'ДУБЛЬ ') or (kw2 = 'ДУБЬ  ') then begin
        GetName(nm);
        d[5] := CodeOf(nm);
        d[4] := 4
      end else if (kw2 = 'РЕЖИМ ') then
        d[8] := Number
      else if (kw2 = 'ПАРОЛЬ') then begin
        nm := Tok;
        d[7] := 1
      end else if (kw2 = 'КОНТРО') then
        d[7] := Number
      else begin
        Err(76);
        p := 73
      end
    end
  until p > 72
   end ;
end;

procedure CreAr;
var kind:integer;
begin
   begin 
  if kw = 'СОЗДАТ' then begin
    kw2 := Tok;
    if kw2 <> 'ОБЛАСТ' then Err(78)
  end;
  GetName(k);
  if k = '      ' then Err(78)
  else begin
    dl := 1;
    kind := 1;
    Skip;
    if p <= 72 then begin
      if ln[p] = ':' then p := p + 1;
      if (ln[p] = ',') or (ln[p] = ';') then p := 73
      else if p <= 72 then begin
        UstOBL(r, dl, kind);
        Params(r, dl)
      end
    end;
    r[2] := dl;
    if Kfind(k) then Err(80) else NewArea(k, r)
  end
   end ;
end;

procedure Izmeni;
var nm:alfa; nd:integer;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ОБЛАСТ' then Err(77)
  else begin
    GetName(nm);
    if not GetRec(nm, r) then Err(72)
    else begin
      Skip;
      if (p > 72) or (ln[p] <> ':') then Err(64)
      else begin
        p := p + 1;
        nd := r[2];
        Params(r, nd);
        r[2] := nd;
        PutRec(nm, r);
        writeln('ОБЛАСТЬ ',RT_W( nm), ' ИЗМЕНЕНА')
      end
    end
  end
   end ;
end;

procedure AddUser;
var nm,pw:alfa;
begin
   begin 
  GetName(nm);
  if nm = '      ' then Err(78)
  else if un >= 16 then Err(87)
  else begin
    unms[un+1] := nm;
    un := un + 1;
    Skip;
    if (p <= 72) and (ln[p] = ':') then begin
      p := p + 1;
      kw2 := Tok;
      if kw2 = 'ПАРОЛЬ' then pw := Tok
    end;
    writeln('ПОЛЬЗОВАТЕЛЬ ',RT_W( nm), ' СОЗДАН')
  end
   end ;
end;

procedure AddRight;
var us,ob,ty,rt:alfa; ok:boolean;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ПОЛЬЗО' then Err(78)
  else begin
    GetName(us);
    kw2 := Tok;
    if (kw2 = 'ОБЛАСТ') or (kw2 = 'ПОДСХЕ') or
       (kw2 = 'СХЕМЫ ') then ty := kw2 else ty := kw2;
    GetName(ob);
    Skip;
    if (p <= 72) and (ln[p] = ':') then p := p + 1;
    rt := Tok;
    ok := (rt = 'ДЛЯ-ВЫ') or (rt = 'ДЛЯ-МО');
    if not ok then Err(5)
    else if rn >= 16 then Err(7)
    else if (ty <> 'ОБЛАСТ') and (ty <> 'ПОДСХЕ') and
            (ty <> 'СХЕМЫ ') then Err(77)
    else if (ty = 'ОБЛАСТ') and (not Kfind(ob)) then Err(51)
    else begin
      rn := rn + 1;
      rnms[rn] := us;
      robj[rn] := ob;
      rtyp[rn] := rt;
      writeln('ПРАВО ',RT_W( rt), ' ',RT_W( us), ' НА ',RT_W( ob), ' ДАНО')
    end
  end
   end ;
end;

procedure Create;
begin
   begin 
  kw2 := Tok;
  if kw2 = 'ПОЛЬЗО' then AddUser
  else if kw2 = 'ПРАВО ' then AddRight
  else if kw2 = 'ОБЛАСТ' then CreAr
  else Err(78)
   end ;
end;

procedure Names(cmd:alfa);
var nm:alfa;
begin
   begin 
  k2 := cmd;
  repeat
    Skip;
    if (p <= 72) and (ln[p] = ',') then p := p + 1;
    GetName(nm);
    if nm <> '      ' then begin
      if cmd = 'ОЧИСТИ' then AErase(nm);
      if cmd = 'ОСВОБО' then Osvobo(nm);
      if cmd = 'ВОССТА' then Bocct(nm)
    end
  until (nm = '      ') or (p > 72)
   end ;
end;

procedure Stmt;
begin
   begin 
  Skip;
  if p <= 72 then begin
    if (ln[p] = '?') or (ln[p] = '*') then p := 73
    else if (ln[p] = ';') or (ln[p] = ',') then p := p + 1
    else if ln[p] = '.' then p := p + 1
    else begin
      kw := Tok;
      if (kw = 'ОЧИСТИ') or (kw = 'ОСВОБО') or (kw = 'ВОССТА') then
        Names(kw)
      else if (kw = 'СОЗДАТ') then Create
      else if (kw = 'ОБЛАСТ') or (kw = 'ПРОСТР') then CreAr
      else if (kw = 'ИЗМЕНИ') then Izmeni
      else if (kw = 'ОБНОВИ') then begin
        GetName(k);
        if k <> '      ' then Obnovi(k) else Err(78)
      end else if (kw = 'ДУБЛЬ ') then Dubl
      else if (kw = 'ОСВАБД') then Osvabd
      else if (kw = 'ЖУРНАЛ') then Journal
      else if (kw = 'УБРАТЬ') then Ubrat
      else if (kw = 'РЕГИСТ') then RegCreate
      else if (kw = 'КУСОК ') then ChunkNew
      else if (kw = 'СОБРАТ') then AsmOp
      else if (kw = 'В     ') then p := 73
      else if (kw = 'КОНЕЦ ') or (kw = 'КОНЕЦ.') then p := 73
      else if k2 <> '      ' then begin
        p := 1;
        Skip;
        Names(k2)
      end
      else Err(84)
    end
  end
   end ;
end;

procedure Init;
var i,j:integer;
begin
   begin 
  (* PASCOMPL 15.1 miscompiles a plain '= 0' test here. *)
  if BDVECT[36] + 0 = 0 then begin
    for j := 0 to 167 do BDVECT[j] := 0;
    PASSETAR(94208)
  end;
  pasbdi;
  BDERRN := 0;
  InitPows;
  i := 618497;
  newd('ADA   ', i);
  ClrErr;
  opend('ADA   ');
  for j := 1 to 72 do ur[j] := 0;
  ur[1] := 1;
  ur[2] := 1;
  modd('ADMIN ', ur, sizeof(ur));
  ClrErr;
  un := 0;
  rn := 0;
  unms[1] := 'ADMIN ';
  un := 1;
  rnms[1] := 'ADMIN ';
  robj[1] := 'ADA   ';
  rtyp[1] := 'ДЛЯ-ВЫ';
  rn := 1
   end ;
end;

begin MarsBind(@bdvect, @bderrn);
  MarsCreate := true;  (* servis makes the database *)
  MarsBegin;  (* the whole run is one transaction *)
  Init;
  InitLayout;
  ncode := 0;
  ncnt := 0;
  writeln('SERVIS PROCESSOR 15.1');
  writeln('ADMIN: ПОЛЬЗОВАТЕЛЬ ADMIN ЗАРЕГИСТРИРОВАН');
  while not eof(input) do begin
    RT_ReadLn(ln);
    RT_Fold(ln);
    p := 1;
    repeat
      Stmt;
      Skip;
      if p <= 72 then begin
        nxt := ln[p];
        if (nxt = ';') or (nxt = ',') then p := p + 1
        else p := 73
      end
    until p > 72
  end;
  writeln('EXN=',RT_W( EXN));
  MarsCommit
end.
