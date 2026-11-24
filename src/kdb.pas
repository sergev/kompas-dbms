{ KOMPAS engine for Linux: CODASYL records and sets over MARS.

  The schema is read from catalogue 270000 as ttc stores
  it (CXHD/CXFL/CXAT).  Records live in the MARS containers of their areas
  (made by SERVIS); the MARS key of a record is its DB-key.

  Record words: [0] type, [1] next and [2] prior of the type chain, then
  per set owned (first, last), per set as member (next, prior, owner),
  then the fields.  DB-key 1 is the anchor: [1] next DB-key, [2] the
  SYSTEM record, then (first, last) of every set (singular sets) and of
  every type chain.

  Status KSTAT (HYPOTHESIS, doc/open-questions.md): 0 ok, 1 end of set, 2 not
  found, 3 duplicate key, 4 no current record, 5 membership error,
  6 bad record/set/field, 7 storage error, 8 no schema. }
unit kdb;

{$mode objfpc}{$H+}

interface

uses krt;

const
  kOk = 0; kEnd = 1; kNotFound = 2; kDup = 3; kNoCur = 4; kMember = 5;
  kBad = 6; kStorage = 7; kNoSchema = 8;

type
  TKind = (fkInt, fkReal, fkChar, fkBool);

var
  KSTAT: int64 = 0;
  KHARD: int64 = 0;        { errors other than end of set and not found }
  KLASTHARD: int64 = 0;

{ --- DML for programs (names are numbers given by predt) --- }
procedure KOPEN(const journal: array of char);
procedure KCLOSE;
procedure KFINDFIRST(s: int64);
procedure KFINDLAST(s: int64);
procedure KFINDNEXT(s: int64);       { s = 0: the set of the last find }
procedure KFINDPRIOR(s: int64);
procedure KFINDOWNER(s: int64);
procedure KFINDKEY(s: int64; v: int64);
procedure KFINDKEY(s: int64; v: double);
procedure KFINDKEY(s: int64; const v: array of char);
procedure KFINDFIRSTREC(r: int64);
procedure KFINDNEXTREC(r: int64);
{ field transfer: KBEGINGET(r) loads the current r (0: of the run unit),
  KBEGINPUT(r) starts an empty buffer of type r }
procedure KBEGINGET(r: int64);
procedure KBEGINPUT(r: int64);
procedure KGETF(i: int64; var x: int64);
procedure KGETF(i: int64; var x: double);
procedure KGETF(i: int64; var x: boolean);
procedure KGETF(i: int64; var x: array of char);
procedure KGETF(i: int64; var x: char);
procedure KGETF(i: int64; var x);          { a set: the low 32 bits }
procedure KPUTF(i: int64; x: int64);
procedure KPUTF(i: int64; x: double);
procedure KPUTF(i: int64; x: boolean);
procedure KPUTF(i: int64; const x: array of char);
procedure KPUTF(i: int64; x: char);
procedure KPUTF(i: int64; const x);        { a set: the low 32 bits }
procedure KSTORE(r: int64);
procedure KMODIFY(r: int64);         { the loaded buffer back to its record }
procedure KERASE(r: int64);          { r = 0: current of the run unit }
procedure KCONNECT(s: int64);
{ ВЫБОР t ИСПОЛЬЗ r.f: the owner is the member of set t with key v }
procedure KCONNECTKEY(s: int64; v: int64);
procedure KCONNECTKEY(s: int64; v: double);
procedure KCONNECTKEY(s: int64; const v: array of char);
procedure KDISCONNECT(s: int64);
function KCURTYPE: int64;            { type of the current of the run unit }
function KDBKEY(r: int64): int64;    { current of type r, 0: run unit }
procedure KSETCUR(r, k: int64);      { make DB-key k current }
function KCOUNT(s: int64): int64;    { members of the current occurrence }
procedure KERASEMEMBERS(s: int64);   { erase all members of the occurrence }

{ --- schema and generic access, for mad and predt --- }
function KSchemaOk: boolean;
function KRecCount: integer;
function KSetCount: integer;
function KRecNo(const name: string): integer;
function KSetNo(const name: string): integer;
function KRecName(r: integer): string;
function KSetName(s: integer): string;
function KSetOwner(s: integer): integer;   { 0: singular }
function KSetMember(s: integer): integer;
function KSetKey(s: integer): integer;     { key field of the member, 0: none }
{ ВЫБОР: 'REC.FLD' of ИСПОЛЬЗ, '' if none }
function KSetUsing(s: integer): string;
function KFieldCount(r: integer): integer;
function KFieldNo(r: integer; const name: string): integer;
function KFieldName(r, i: integer): string;
function KFieldKind(r, i: integer): TKind;
function KFieldLen(r, i: integer): integer;  { chars of a CИMBOЛ field }
function KFieldSize(r, i: integer): string;  { PAЗMEP digits, '' if none }
function KFieldText(i: integer): string;     { field i of the loaded buffer }
function KBufType: integer;
procedure KPutText(i: integer; const s: string);  { into the put buffer }
procedure KFindKeyText(s: integer; const t: string);
function KStatusText(st: int64): string;
{ chain integrity of the whole database: '' or the first fault }
function KCheck: string;

implementation

uses SysUtils, mars, kgost;

type
  TKey = mars.TKey;

type
  TField = record
    name: string;
    kind: TKind;
    len: integer;          { chars }
    size: string;          { PAЗMEP digits }
    off, words: integer;
  end;
  TRec = record
    name, area: string;
    ai: integer;           { area index }
    f: array of TField;
    tnext: integer;        { word of the type chain }
    fstart: integer;       { first word of the fields }
    nwords: integer;
  end;
  TSet = record
    name: string;
    owner, member: integer;  { owner 0: singular }
    keyf: integer;
    dup, manual: boolean;
    selname, using: string;  { ВЫБОР set ИСПОЛЬЗ rec.fld }
    selset: integer;
    ownoff, memoff: integer; { owner (first,last), member (next,prior,owner) }
  end;
  TWords = array of int64;

var
  loaded: boolean = false;
  failed: boolean = false;
  recs: array of TRec;       { 1-based }
  sets: array of TSet;       { 1-based }
  areas: array of string;
  anchorWords: integer;
  cRU: int64 = 0;
  cRec: array of int64;
  cSet: array of int64;
  lastSet: integer = 0;
  buf: TWords;               { field transfer buffer }
  bufType: integer = 0;
  bufKey: int64 = 0;
  jname: string = '';
  jseq: int64 = 0;

procedure SetSt(v: int64);
begin
  KSTAT := v;
  if not (v in [kOk, kEnd, kNotFound]) then begin
    inc(KHARD);
    KLASTHARD := v;
  end;
end;

{ --- MARS access --- }

function MErr: int64;
begin
  Result := PInt64(MarsErr)^;
end;

procedure MClr;
begin
  PInt64(MarsErr)^ := 0;
end;

function Pad6(const s: string): string;
begin
  Result := Copy(s + '      ', 1, 6);
end;

function K6(const s: string): TKey;
var i: integer; t: string;
begin
  t := Pad6(s);
  for i := 0 to 5 do Result[i] := t[i + 1];
end;

function DbKeyName(k: int64; ai: integer): string;
var i: integer;
begin
  SetLength(Result, 6);
  Result[1] := chr(ai + 1);
  for i := 6 downto 2 do begin
    Result[i] := chr(k and 255);
    k := k shr 8;
  end;
end;

function AreaOf(k: int64): integer;
begin
  { the area is the top byte of a DB-key }
  Result := (k shr 40) and 255;
end;

function MakeKey(n: int64; ai: integer): int64;
begin
  Result := (int64(ai) shl 40) or n;
end;

function OpenArea(ai: integer): boolean;
begin
  MClr;
  opend(K6(areas[ai]));
  Result := MErr = 0;
end;

function ReadW(k: int64; var w: TWords): boolean;
var ai: integer; n: int64;
begin
  Result := false;
  ai := AreaOf(k);
  if (ai > high(areas)) or not OpenArea(ai) then exit;
  SetLength(w, 512);
  FillChar(w[0], length(w) * 8, 0);
  MClr;
  getd(K6(DbKeyName(k and $FFFFFFFFFF, ai)), w[0], length(w) * 8);
  Result := MErr = 0;
  if Result then begin
    n := w[0];
    if n = 0 then SetLength(w, anchorWords)
    else SetLength(w, recs[n].nwords);
  end;
end;

function WriteW(k: int64; const w: TWords; fresh: boolean): boolean;
var ai: integer; key: string;
begin
  Result := false;
  ai := AreaOf(k);
  if (ai > high(areas)) or not OpenArea(ai) then exit;
  key := DbKeyName(k and $FFFFFFFFFF, ai);
  MClr;
  if fresh then putd(K6(key), w[0], length(w) * 8)
  else modd(K6(key), w[0], length(w) * 8);
  Result := MErr = 0;
end;

function DeleteW(k: int64): boolean;
var ai: integer;
begin
  Result := false;
  ai := AreaOf(k);
  if (ai > high(areas)) or not OpenArea(ai) then exit;
  MClr;
  deld(K6(DbKeyName(k and $FFFFFFFFFF, ai)));
  Result := MErr = 0;
end;

procedure Journal(op: char; k: int64; const w: TWords);
var key: string; i: integer; n: int64;
begin
  if jname = '' then exit;
  MClr;
  opend(K6(jname));
  if MErr <> 0 then exit;
  inc(jseq);
  SetLength(key, 6);
  key[1] := op;
  n := jseq;
  for i := 6 downto 2 do begin key[i] := chr(n and 255); n := n shr 8; end;
  MClr;
  if length(w) > 0 then modd(K6(key), w[0], length(w) * 8)
  else modd(K6(key), k, 8);
end;

{ --- schema --- }

function Row(const area, key: string; var d: string): boolean;
begin
  SetLength(d, 48);
  FillChar(d[1], 48, ' ');
  MClr;
  opend(K6(area));
  if MErr <> 0 then exit(false);
  getd(K6(key), d[1], 48);
  Result := MErr = 0;
end;

function Fld(const d: string; o, n: integer): string;
begin
  Result := TrimRight(Copy(d, o, n));
end;

function Num(const s: string): integer;
begin
  Result := StrToIntDef(Trim(s), 0);
end;

function KeyN(c: char; n, w: integer): string;
begin
  Result := c + Format('%.*d', [w, n]);
end;

function AreaIndex(const a: string): integer;
var i: integer;
begin
  for i := 0 to high(areas) do
    if areas[i] = a then exit(i);
  Result := length(areas);
  SetLength(areas, Result + 1);
  areas[Result] := a;
end;

procedure Load;
var d, a, v, first: string;
    nt, nr, ns, i, j, n, w: integer;
    tn, tb, tl, tz: array of string;
    r: integer;

  procedure SetKind(var f: TField; const typ: string; const ln, sz: string);
  var k: integer; b, l, z: string;
  begin
    b := typ; l := ln; z := sz;
    for k := 0 to nt - 1 do
      if tn[k] = typ then begin
        b := tb[k];
        if l = '' then l := tl[k];
        if z = '' then z := tz[k];
      end;
    if b = Encode('ЦЕЛОЕ') then f.kind := fkInt
    else if b = Encode('ДЕЙСТВ') then f.kind := fkReal
    else if b = Encode('ЛОГИЧЕ') then f.kind := fkBool
    else f.kind := fkChar;
    f.len := Num(l);
    if (f.kind = fkChar) and (f.len <= 0) then f.len := 6;
    f.size := z;
    if f.kind = fkChar then f.words := (f.len + 7) div 8 else f.words := 1;
  end;

begin
  loaded := true;
  failed := true;
  PASSETAR(&270000);
  if not Row('CXHD', 'NUM', d) then exit;
  nt := Num(Copy(d, 1, 3)); nr := Num(Copy(d, 4, 3)); ns := Num(Copy(d, 7, 3));
  SetLength(tn, nt); SetLength(tb, nt); SetLength(tl, nt); SetLength(tz, nt);
  for i := 1 to nt do begin
    if not Row('CXHD', KeyN('T', i, 3), d) then exit;
    tn[i - 1] := Fld(d, 1, 6); tb[i - 1] := Fld(d, 7, 6);
    tl[i - 1] := Fld(d, 13, 6); tz[i - 1] := Trim(Copy(d, 19, 10));
  end;
  SetLength(recs, nr + 1);
  SetLength(areas, 0);
  first := '';
  for i := 1 to nr do begin
    if not Row('CXHD', KeyN('R', i, 3), d) then exit;
    recs[i].name := Fld(d, 1, 6);
    recs[i].area := Fld(d, 7, 6);
    if (first = '') and (recs[i].area <> '') then first := recs[i].area;
    n := Num(Copy(d, 13, 3));
    SetLength(recs[i].f, n + 1);
    for j := 1 to n do begin
      if not Row('CXFL', KeyN('F', i * 100 + j, 5), d) then exit;
      recs[i].f[j].name := Fld(d, 1, 6);
      SetKind(recs[i].f[j], Fld(d, 7, 6), Fld(d, 13, 6), Trim(Copy(d, 19, 10)));
    end;
  end;
  if first = '' then exit;
  for i := 1 to nr do begin
    if recs[i].area = '' then recs[i].area := first;
    recs[i].ai := AreaIndex(recs[i].area);
  end;
  SetLength(sets, ns + 1);
  for i := 1 to ns do begin
    if not Row('CXHD', KeyN('S', i, 3), d) then exit;
    sets[i].name := Fld(d, 1, 6);
    n := Num(Copy(d, 7, 3));
    sets[i].owner := 0; sets[i].member := 0; sets[i].keyf := 0;
    sets[i].dup := false; sets[i].manual := false;
    sets[i].selname := ''; sets[i].using := ''; sets[i].selset := 0;
    for j := 1 to n do begin
      if not Row('CXAT', KeyN('A', i * 100 + j, 5), d) then exit;
      a := Fld(d, 1, 6); v := Fld(d, 7, 6);
      if a = Encode('ВЛАДЕЛ') then sets[i].owner := KRecNo(v)
      else if a = Encode('ЧЛЕН') then sets[i].member := KRecNo(v)
      else if a = Encode('ДУБЛИК') then sets[i].dup := true
      else if (a = Encode('ВКЛЮЧЕ')) and (v = Encode('ВРУЧНУ')) then
        sets[i].manual := true
      else if a = Encode('ПОЛЕ') then sets[i].keyf := -1
      else if a = Encode('ВЫБОР') then begin
        sets[i].selname := v;
        sets[i].using := Trim(Copy(d, 13, 10));
      end;
    end;
    { key field: the ПОЛЕ attribute, resolved against the member }
    if sets[i].keyf = -1 then begin
      sets[i].keyf := 0;
      for j := 1 to n do
        if Row('CXAT', KeyN('A', i * 100 + j, 5), d) and
           (Fld(d, 1, 6) = Encode('ПОЛЕ')) and (sets[i].member > 0) then
          sets[i].keyf := KFieldNo(sets[i].member, Fld(d, 7, 6));
    end;
    if sets[i].member = 0 then exit;
  end;
  for i := 1 to ns do
    if sets[i].selname <> '' then sets[i].selset := KSetNo(sets[i].selname);
  { word layout }
  for r := 1 to nr do begin
    w := 1;
    recs[r].tnext := w; inc(w, 2);
    recs[r].nwords := w;
  end;
  for i := 1 to ns do begin
    if sets[i].owner > 0 then begin
      sets[i].ownoff := recs[sets[i].owner].nwords;
      inc(recs[sets[i].owner].nwords, 2);
    end else
      sets[i].ownoff := 3 + 2 * (i - 1);
    sets[i].memoff := recs[sets[i].member].nwords;
    inc(recs[sets[i].member].nwords, 3);
  end;
  for r := 1 to nr do begin
    recs[r].fstart := recs[r].nwords;
    for j := 1 to high(recs[r].f) do begin
      recs[r].f[j].off := recs[r].nwords;
      inc(recs[r].nwords, recs[r].f[j].words);
    end;
  end;
  anchorWords := 3 + 2 * ns + 2 * nr;
  SetLength(cRec, nr + 1);
  SetLength(cSet, ns + 1);
  failed := false;
end;

function Ready: boolean;
begin
  if not loaded then Load;
  Result := not failed;
  if failed then SetSt(kNoSchema);
end;

function KSchemaOk: boolean;
begin
  Result := Ready;
end;

function KRecCount: integer;
begin
  if Ready then Result := high(recs) else Result := 0;
end;

function KSetCount: integer;
begin
  if Ready then Result := high(sets) else Result := 0;
end;

function KRecNo(const name: string): integer;
var i: integer;
begin
  for i := 1 to high(recs) do
    if recs[i].name = TrimRight(name) then exit(i);
  Result := 0;
end;

function KSetNo(const name: string): integer;
var i: integer;
begin
  for i := 1 to high(sets) do
    if sets[i].name = TrimRight(name) then exit(i);
  Result := 0;
end;

function KRecName(r: integer): string; begin Result := recs[r].name; end;
function KSetName(s: integer): string; begin Result := sets[s].name; end;
function KSetOwner(s: integer): integer; begin Result := sets[s].owner; end;
function KSetMember(s: integer): integer; begin Result := sets[s].member; end;
function KSetKey(s: integer): integer; begin Result := sets[s].keyf; end;
function KSetUsing(s: integer): string;
begin
  if sets[s].selset > 0 then Result := sets[s].using else Result := '';
end;
function KFieldCount(r: integer): integer; begin Result := high(recs[r].f); end;

function KFieldNo(r: integer; const name: string): integer;
var i: integer;
begin
  for i := 1 to high(recs[r].f) do
    if recs[r].f[i].name = TrimRight(name) then exit(i);
  Result := 0;
end;

function KFieldName(r, i: integer): string; begin Result := recs[r].f[i].name; end;
function KFieldKind(r, i: integer): TKind; begin Result := recs[r].f[i].kind; end;
function KFieldLen(r, i: integer): integer; begin Result := recs[r].f[i].len; end;
function KFieldSize(r, i: integer): string; begin Result := recs[r].f[i].size; end;

{ --- anchor --- }

const
  AnchorKey = 1;

function AnchorK: int64;
begin
  Result := MakeKey(AnchorKey, 0);
end;

function GetAnchor(var w: TWords): boolean;
begin
  Result := ReadW(AnchorK, w);
  if not Result then begin
    SetLength(w, anchorWords);
    FillChar(w[0], anchorWords * 8, 0);
    w[0] := 0;
    w[1] := 2;
    Result := WriteW(AnchorK, w, true);
  end;
end;

function TypeFirstOff(r: integer): integer;
begin
  Result := 3 + 2 * high(sets) + 2 * (r - 1);
end;

{ --- chains: owner o (record or the anchor), member m --- }

function RType(k: int64): integer;
var w: TWords;
begin
  if (k = 0) or not ReadW(k, w) then exit(-1);
  Result := w[0];
end;

{ (first,last) words of the occurrence of set s owned by o }
procedure OwnerSlots(s: integer; o: int64; var w: TWords);
begin
  if not ReadW(o, w) then SetLength(w, 0);
end;

function Less(s: integer; const a, b: TWords): integer;
{ compare the key field of members a and b: <0, 0, >0 }
var f: TField; x, y: double; i: integer; ca, cb: char;
begin
  Result := 0;
  if sets[s].keyf = 0 then exit;
  f := recs[sets[s].member].f[sets[s].keyf];
  case f.kind of
    fkInt, fkBool:
      if a[f.off] < b[f.off] then Result := -1
      else if a[f.off] > b[f.off] then Result := 1;
    fkReal: begin
      x := PDouble(@a[f.off])^; y := PDouble(@b[f.off])^;
      if x < y then Result := -1 else if x > y then Result := 1;
    end;
    fkChar:
      for i := 0 to f.len - 1 do begin
        ca := PChar(@a[f.off])[i]; cb := PChar(@b[f.off])[i];
        if ca <> cb then begin
          if ord(ca) < ord(cb) then Result := -1 else Result := 1;
          exit;
        end;
      end;
  end;
end;

function Link(s: integer; m, o: int64; var mw: TWords): integer;
{ connect member m (words mw, written here) into the occurrence of o }
var ow, xw, pw: TWords; x, p: int64; mo, oo, c: integer;
begin
  mo := sets[s].memoff; oo := sets[s].ownoff;
  if mw[mo + 2] <> 0 then exit(kMember);
  if not ReadW(o, ow) then exit(kStorage);
  { position: before the first member with a greater key }
  p := ow[oo + 1];
  x := 0;
  if sets[s].keyf > 0 then begin
    x := ow[oo];
    p := 0;
    while x <> 0 do begin
      if not ReadW(x, xw) then exit(kStorage);
      c := Less(s, mw, xw);
      if (c = 0) and not sets[s].dup then exit(kDup);
      if c < 0 then break;
      p := x;
      x := xw[mo];
    end;
  end;
  mw[mo] := x; mw[mo + 1] := p; mw[mo + 2] := o;
  if not WriteW(m, mw, false) then exit(kStorage);
  if p <> 0 then begin
    if not ReadW(p, pw) then exit(kStorage);
    pw[mo] := m;
    if not WriteW(p, pw, false) then exit(kStorage);
  end;
  if x <> 0 then begin
    if not ReadW(x, xw) then exit(kStorage);
    xw[mo + 1] := m;
    if not WriteW(x, xw, false) then exit(kStorage);
  end;
  if not ReadW(o, ow) then exit(kStorage);
  if p = 0 then ow[oo] := m;
  if x = 0 then ow[oo + 1] := m;
  if not WriteW(o, ow, false) then exit(kStorage);
  Result := kOk;
end;

function Unlink(s: integer; m: int64; var mw: TWords): integer;
var ow, xw: TWords; o, nx, pr: int64; mo, oo: integer;
begin
  mo := sets[s].memoff; oo := sets[s].ownoff;
  o := mw[mo + 2];
  if o = 0 then exit(kMember);
  nx := mw[mo]; pr := mw[mo + 1];
  if pr <> 0 then begin
    if not ReadW(pr, xw) then exit(kStorage);
    xw[mo] := nx; WriteW(pr, xw, false);
  end;
  if nx <> 0 then begin
    if not ReadW(nx, xw) then exit(kStorage);
    xw[mo + 1] := pr; WriteW(nx, xw, false);
  end;
  if not ReadW(o, ow) then exit(kStorage);
  if ow[oo] = m then ow[oo] := nx;
  if ow[oo + 1] = m then ow[oo + 1] := pr;
  WriteW(o, ow, false);
  mw[mo] := 0; mw[mo + 1] := 0; mw[mo + 2] := 0;
  WriteW(m, mw, false);
  Result := kOk;
end;

{ --- currency --- }

procedure MakeCurrent(k: int64; s0: integer);
var w: TWords; t, s: integer;
begin
  if not ReadW(k, w) then exit;
  t := w[0];
  cRU := k;
  cRec[t] := k;
  for s := 1 to high(sets) do begin
    if (sets[s].member = t) and (w[sets[s].memoff + 2] <> 0) then cSet[s] := k
    else if sets[s].owner = t then cSet[s] := k;
  end;
  if s0 > 0 then begin
    cSet[s0] := k;
    lastSet := s0;
  end;
end;

{ owner of the occurrence selected by the current of set s }
function Occurrence(s: integer; var o: int64): boolean;
var w: TWords; c: int64; t: integer;
begin
  Result := false;
  if sets[s].owner = 0 then begin o := AnchorK; exit(true); end;
  c := cSet[s];
  if c = 0 then exit;
  if not ReadW(c, w) then exit;
  t := w[0];
  if t = sets[s].owner then o := c
  else if (t = sets[s].member) and (w[sets[s].memoff + 2] <> 0) then o := w[sets[s].memoff + 2]
  else exit;
  Result := true;
end;

function Bad(s: int64; isSet: boolean): boolean;
begin
  if not Ready then exit(true);
  if isSet then Result := (s < 1) or (s > high(sets))
  else Result := (s < 1) or (s > high(recs));
  if Result then SetSt(kBad);
end;

procedure FindEnd(s: integer; last: boolean);
var o: int64; w: TWords; k: int64;
begin
  if Bad(s, true) then exit;
  if not Occurrence(s, o) then begin SetSt(kNoCur); exit; end;
  if not ReadW(o, w) then begin SetSt(kStorage); exit; end;
  if last then k := w[sets[s].ownoff + 1] else k := w[sets[s].ownoff];
  if k = 0 then begin SetSt(kEnd); lastSet := s; exit; end;
  MakeCurrent(k, s);
  SetSt(kOk);
end;

procedure KFINDFIRST(s: int64); begin FindEnd(s, false); end;
procedure KFINDLAST(s: int64); begin FindEnd(s, true); end;

procedure Step(s: integer; fwd: boolean);
var c, k: int64; w: TWords; t: integer;
begin
  if s = 0 then s := lastSet;
  if Bad(s, true) then exit;
  lastSet := s;
  c := cSet[s];
  if sets[s].owner = 0 then t := 0 else t := -1;
  if c = 0 then begin
    { singular set with no current: start at its end }
    if t = 0 then FindEnd(s, not fwd) else SetSt(kNoCur);
    exit;
  end;
  if not ReadW(c, w) then begin SetSt(kStorage); exit; end;
  if (w[0] = sets[s].member) and (w[sets[s].memoff + 2] <> 0) then begin
    if fwd then k := w[sets[s].memoff] else k := w[sets[s].memoff + 1];
  end else if w[0] = sets[s].owner then begin
    if fwd then k := w[sets[s].ownoff] else k := w[sets[s].ownoff + 1];
  end else begin
    SetSt(kNoCur); exit;
  end;
  if k = 0 then begin SetSt(kEnd); exit; end;
  MakeCurrent(k, s);
  SetSt(kOk);
end;

procedure KFINDNEXT(s: int64); begin Step(s, true); end;
procedure KFINDPRIOR(s: int64); begin Step(s, false); end;

procedure KFINDOWNER(s: int64);
var o: int64;
begin
  if Bad(s, true) then exit;
  if (sets[s].owner = 0) then begin SetSt(kNotFound); exit; end;
  if not Occurrence(s, o) then begin SetSt(kNoCur); exit; end;
  MakeCurrent(o, s);
  SetSt(kOk);
end;

{ find by key: the last member equal to the probe kw (HYPOTHESIS) }
procedure FindKey(s: integer; const kw: TWords);
var o, x, hit: int64; ow, xw: TWords;
begin
  if not Occurrence(s, o) then begin SetSt(kNoCur); exit; end;
  if not ReadW(o, ow) then begin SetSt(kStorage); exit; end;
  x := ow[sets[s].ownoff];
  hit := 0;
  while x <> 0 do begin
    if not ReadW(x, xw) then begin SetSt(kStorage); exit; end;
    if Less(s, kw, xw) = 0 then hit := x
    else if (hit <> 0) and (sets[s].keyf > 0) then break;
    x := xw[sets[s].memoff];
  end;
  lastSet := s;
  if hit = 0 then begin SetSt(kNotFound); exit; end;
  MakeCurrent(hit, s);
  SetSt(kOk);
end;

function Probe(s: integer; var kw: TWords; var f: TField): boolean;
begin
  Result := false;
  if Bad(s, true) then exit;
  if sets[s].keyf = 0 then begin SetSt(kBad); exit; end;
  f := recs[sets[s].member].f[sets[s].keyf];
  SetLength(kw, recs[sets[s].member].nwords);
  FillChar(kw[0], length(kw) * 8, 0);
  Result := true;
end;

procedure PutChars(var w: TWords; const f: TField; p: PChar; n: integer);
var i: integer; d: PChar;
begin
  d := PChar(@w[f.off]);
  for i := 0 to f.len - 1 do
    if i < n then d[i] := p[i] else d[i] := ' ';
end;

procedure KFINDKEY(s: int64; v: int64);
var kw: TWords; f: TField; st: string;
begin
  if not Probe(s, kw, f) then exit;
  case f.kind of
    fkInt, fkBool: kw[f.off] := v;
    fkReal: PDouble(@kw[f.off])^ := v;
    fkChar: begin st := IntToStr(v); PutChars(kw, f, PChar(st), length(st)); end;
  end;
  FindKey(s, kw);
end;

procedure KFINDKEY(s: int64; v: double);
var kw: TWords; f: TField;
begin
  if not Probe(s, kw, f) then exit;
  case f.kind of
    fkInt, fkBool: kw[f.off] := round(v);
    fkReal: PDouble(@kw[f.off])^ := v;
    fkChar: ;
  end;
  FindKey(s, kw);
end;

procedure KFINDKEY(s: int64; const v: array of char);
var kw: TWords; f: TField; t: string;
begin
  if not Probe(s, kw, f) then exit;
  SetString(t, PChar(@v[0]), length(v));
  case f.kind of
    fkInt, fkBool: kw[f.off] := StrToInt64Def(Trim(t), 0);
    fkReal: PDouble(@kw[f.off])^ := StrToFloatDef(Trim(t), 0);
    fkChar: PutChars(kw, f, PChar(t), length(t));
  end;
  FindKey(s, kw);
end;

procedure KFindKeyText(s: integer; const t: string);
var kw: TWords; f: TField; e: integer; v: double;
begin
  if not Probe(s, kw, f) then exit;
  case f.kind of
    fkInt, fkBool: begin val(Trim(t), v, e); kw[f.off] := round(v); end;
    fkReal: begin val(Trim(t), v, e); PDouble(@kw[f.off])^ := v; end;
    fkChar: PutChars(kw, f, PChar(t), length(t));
  end;
  FindKey(s, kw);
end;

procedure TypeStep(r: integer; first: boolean);
var aw, w: TWords; k: int64;
begin
  if Bad(r, false) then exit;
  if first then begin
    if not GetAnchor(aw) then begin SetSt(kStorage); exit; end;
    k := aw[TypeFirstOff(r)];
  end else begin
    if (cRec[r] = 0) or not ReadW(cRec[r], w) then begin SetSt(kNoCur); exit; end;
    k := w[recs[r].tnext];
  end;
  if k = 0 then begin SetSt(kEnd); exit; end;
  MakeCurrent(k, 0);
  SetSt(kOk);
end;

procedure KFINDFIRSTREC(r: int64); begin TypeStep(r, true); end;
procedure KFINDNEXTREC(r: int64); begin TypeStep(r, false); end;

{ --- SYSTEM: a singleton record, found or made on first use --- }

function SystemRec(r: integer): boolean;
begin
  Result := recs[r].name = Encode('SYSTEM');
end;

procedure NewRecord(r: integer; var w: TWords; var k: int64; var st: integer); forward;

procedure EnsureSystem(r: integer);
var aw, w: TWords; k: int64; st: integer;
begin
  if (cRec[r] <> 0) or not SystemRec(r) then exit;
  if not GetAnchor(aw) then exit;
  if aw[2] = 0 then begin
    SetLength(w, recs[r].nwords);
    FillChar(w[0], length(w) * 8, 0);
    w[0] := r;
    NewRecord(r, w, k, st);
    if st <> kOk then exit;
    GetAnchor(aw);
    aw[2] := k;
    WriteW(AnchorK, aw, false);
  end;
  cRec[r] := aw[2];
end;

{ --- field transfer --- }

procedure KBEGINGET(r: int64);
var k: int64;
begin
  bufType := 0;
  if not Ready then exit;
  if r = 0 then k := cRU
  else begin
    if Bad(r, false) then exit;
    EnsureSystem(r);
    k := cRec[r];
  end;
  if (k = 0) or not ReadW(k, buf) then begin SetSt(kNoCur); exit; end;
  bufType := buf[0];
  bufKey := k;
  SetSt(kOk);
end;

procedure KBEGINPUT(r: int64);
begin
  bufType := 0;
  if Bad(r, false) then exit;
  SetLength(buf, recs[r].nwords);
  FillChar(buf[0], length(buf) * 8, 0);
  buf[0] := r;
  bufType := r;
  bufKey := 0;
  SetSt(kOk);
end;

function FieldOk(i: int64; var f: TField): boolean;
begin
  Result := (bufType > 0) and (i >= 1) and (i <= high(recs[bufType].f));
  if Result then f := recs[bufType].f[i];
end;

procedure KGETF(i: int64; var x: int64);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  case f.kind of
    fkInt, fkBool: x := buf[f.off];
    fkReal: x := round(PDouble(@buf[f.off])^);
    fkChar: x := StrToInt64Def(Trim(KFieldText(i)), 0);
  end;
end;

procedure KGETF(i: int64; var x: double);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  case f.kind of
    fkInt, fkBool: x := buf[f.off];
    fkReal: x := PDouble(@buf[f.off])^;
    fkChar: x := 0;
  end;
end;

procedure KGETF(i: int64; var x: boolean);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  x := buf[f.off] <> 0;
end;

procedure KGETF(i: int64; var x: array of char);
var f: TField; j: integer; s: string;
begin
  if not FieldOk(i, f) then exit;
  if f.kind = fkChar then SetString(s, PChar(@buf[f.off]), f.len)
  else s := KFieldText(i);
  for j := 0 to high(x) do
    if j < length(s) then x[j] := s[j + 1] else x[j] := ' ';
end;

procedure KGETF(i: int64; var x: char);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  if f.kind = fkChar then x := PChar(@buf[f.off])[0];
end;

procedure KPUTF(i: int64; x: int64);
var f: TField; s: string;
begin
  if not FieldOk(i, f) then exit;
  case f.kind of
    fkInt, fkBool: buf[f.off] := x;
    fkReal: PDouble(@buf[f.off])^ := x;
    fkChar: begin s := IntToStr(x); PutChars(buf, f, PChar(s), length(s)); end;
  end;
end;

procedure KPUTF(i: int64; x: double);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  case f.kind of
    fkInt, fkBool: buf[f.off] := round(x);
    fkReal: PDouble(@buf[f.off])^ := x;
    fkChar: ;
  end;
end;

procedure KPUTF(i: int64; x: boolean);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  buf[f.off] := ord(x);
end;

procedure KPUTF(i: int64; const x: array of char);
var f: TField; s: string;
begin
  if not FieldOk(i, f) then exit;
  SetString(s, PChar(@x[0]), length(x));
  KPutText(i, s);
end;

procedure KPUTF(i: int64; x: char);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  if f.kind = fkChar then PutChars(buf, f, @x, 1);
end;

{ sets kept in integer elements (ЗАМЕНИ ЦЕЛ.ЗН НА ФЛАГИ, tests/gold-zt0):
  a set of up to 32 elements is 4 bytes in FPC }
procedure KGETF(i: int64; var x);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  PLongWord(@x)^ := LongWord(buf[f.off]);
end;

procedure KPUTF(i: int64; const x);
var f: TField;
begin
  if not FieldOk(i, f) then exit;
  buf[f.off] := PLongWord(@x)^;
end;

function KBufType: integer;
begin
  Result := bufType;
end;

procedure KPutText(i: integer; const s: string);
var f: TField; t: string; e: integer; v: double;
begin
  if not FieldOk(i, f) then exit;
  case f.kind of
    fkChar: PutChars(buf, f, PChar(s), length(s));
    fkInt: begin
      t := Trim(s);
      val(t, v, e);
      if e <> 0 then v := 0;
      buf[f.off] := round(v);
    end;
    fkReal: begin
      val(Trim(s), v, e);
      if e <> 0 then v := 0;
      PDouble(@buf[f.off])^ := v;
    end;
    fkBool: buf[f.off] := ord((Trim(s) <> '') and (Trim(s) <> '0') and
      (UpCase(Trim(s)[1]) <> 'F'));
  end;
end;

{ PAЗMEP digits: nines are integer digits, trailing zeros decimals
  (HYPOTHESIS: 99900 is 999.00, tests/gold-ck0 prices 0.20 and 44.00) }
procedure Digits(const size: string; var ip, dp: integer);
var i: integer;
begin
  ip := 0; dp := 0;
  for i := length(size) downto 1 do
    if (size[i] = '0') and (ip = 0) then inc(dp) else inc(ip);
end;

function KFieldText(i: integer): string;
var f: TField; ip, dp: integer; v: double;
begin
  Result := '';
  if not FieldOk(i, f) then exit;
  case f.kind of
    fkChar: SetString(Result, PChar(@buf[f.off]), f.len);
    fkBool: if buf[f.off] <> 0 then Result := 'T' else Result := 'F';
    fkInt: begin
      Digits(f.size, ip, dp);
      if dp = 0 then Result := IntToStr(buf[f.off])
      else begin
        v := buf[f.off];
        for ip := 1 to dp do v := v / 10;
        Result := FloatToStrF(v, ffFixed, 18, dp);
      end;
    end;
    fkReal: begin
      v := PDouble(@buf[f.off])^;
      Digits(f.size, ip, dp);
      if f.size = '' then Result := FloatToStr(v)
      else Result := FloatToStrF(v, ffFixed, 18, dp);
    end;
  end;
  if (f.kind <> fkChar) and (DefaultFormatSettings.DecimalSeparator <> '.') then
    Result := StringReplace(Result, DefaultFormatSettings.DecimalSeparator, '.', []);
end;

{ --- store, modify, erase --- }

procedure NewRecord(r: integer; var w: TWords; var k: int64; var st: integer);
var aw, pw: TWords; last: int64; off: integer;
begin
  st := kStorage;
  if not GetAnchor(aw) then exit;
  k := MakeKey(aw[1], recs[r].ai);
  inc(aw[1]);
  { the type chain }
  off := TypeFirstOff(r);
  last := aw[off + 1];
  w[recs[r].tnext] := 0;
  w[recs[r].tnext + 1] := last;
  if last = 0 then aw[off] := k else begin
    if not ReadW(last, pw) then exit;
    pw[recs[r].tnext] := k;
    if not WriteW(last, pw, false) then exit;
  end;
  aw[off + 1] := k;
  if not WriteW(AnchorK, aw, false) then exit;
  if not WriteW(k, w, true) then exit;
  Journal('S', k, w);
  st := kOk;
end;

procedure DropRecord(r: integer; k: int64; var w: TWords);
var aw, xw: TWords; nx, pr: int64; off: integer;
begin
  if not GetAnchor(aw) then exit;
  off := TypeFirstOff(r);
  nx := w[recs[r].tnext]; pr := w[recs[r].tnext + 1];
  if pr <> 0 then begin
    ReadW(pr, xw); xw[recs[r].tnext] := nx; WriteW(pr, xw, false);
  end else aw[off] := nx;
  if nx <> 0 then begin
    ReadW(nx, xw); xw[recs[r].tnext + 1] := pr; WriteW(nx, xw, false);
  end else aw[off + 1] := pr;
  WriteW(AnchorK, aw, false);
  DeleteW(k);
  Journal('E', k, nil);
end;

procedure KSTORE(r: int64);
var w: TWords; k, o: int64; s, st, j: integer; done: array of integer;
begin
  if Bad(r, false) then exit;
  if bufType <> r then KBEGINPUT(r);
  w := Copy(buf);
  for s := 1 to high(sets) do
    if sets[s].member = r then begin
      w[sets[s].memoff] := 0; w[sets[s].memoff + 1] := 0; w[sets[s].memoff + 2] := 0;
    end;
  { the owners first: every automatic set needs a current occurrence }
  for s := 1 to high(sets) do
    if (sets[s].member = r) and not sets[s].manual and not Occurrence(s, o) then begin
      SetSt(kNoCur); exit;
    end;
  NewRecord(r, w, k, st);
  if st <> kOk then begin SetSt(st); exit; end;
  SetLength(done, 0);
  for s := 1 to high(sets) do
    if (sets[s].member = r) and not sets[s].manual then begin
      Occurrence(s, o);
      ReadW(k, w);
      st := Link(s, k, o, w);
      if st <> kOk then begin
        { undo }
        for j := 0 to high(done) do begin ReadW(k, w); Unlink(done[j], k, w); end;
        ReadW(k, w);
        DropRecord(r, k, w);
        SetSt(st);
        exit;
      end;
      SetLength(done, length(done) + 1);
      done[high(done)] := s;
    end;
  MakeCurrent(k, 0);
  SetSt(kOk);
end;

{ a member of the occurrence of o has the key of kw }
function HasKey(s: integer; o: int64; const kw: TWords): boolean;
var w: TWords; x: int64;
begin
  Result := false;
  if not ReadW(o, w) then exit;
  x := w[sets[s].ownoff];
  while x <> 0 do begin
    if not ReadW(x, w) then exit;
    if Less(s, kw, w) = 0 then exit(true);
    x := w[sets[s].memoff];
  end;
end;

procedure KMODIFY(r: int64);
var w: TWords; s, st: integer; o: int64; t: integer;
begin
  if not Ready then exit;
  if r <> 0 then begin
    if Bad(r, false) then exit;
    { a buffer filled by KBEGINPUT: write it over the current r }
    if bufKey = 0 then begin
      EnsureSystem(r);
      if cRec[r] = 0 then begin SetSt(kNoCur); exit; end;
      if not ReadW(cRec[r], w) then begin SetSt(kStorage); exit; end;
      bufKey := cRec[r];
      { keep the links of the stored record }
      Move(w[1], buf[1], (recs[r].fstart - 1) * 8);
    end;
  end;
  if (bufType = 0) or (bufKey = 0) or ((r <> 0) and (bufType <> r)) then begin
    SetSt(kNoCur); exit;
  end;
  t := bufType;
  if not ReadW(bufKey, w) then begin SetSt(kStorage); exit; end;
  { a new key must not clash: checked before any change }
  for s := 1 to high(sets) do
    if (sets[s].member = t) and (sets[s].keyf > 0) and not sets[s].dup and
       (w[sets[s].memoff + 2] <> 0) and (Less(s, w, buf) <> 0) and
       HasKey(s, w[sets[s].memoff + 2], buf) then begin
      SetSt(kDup); exit;
    end;
  { reorder the keyed sets whose key changed }
  for s := 1 to high(sets) do
    if (sets[s].member = t) and (sets[s].keyf > 0) and (w[sets[s].memoff + 2] <> 0) and
       (Less(s, w, buf) <> 0) then begin
      o := w[sets[s].memoff + 2];
      Unlink(s, bufKey, w);
      ReadW(bufKey, w);
      Move(buf[recs[t].fstart], w[recs[t].fstart],
        (recs[t].nwords - recs[t].fstart) * 8);
      st := Link(s, bufKey, o, w);
      if st <> kOk then begin SetSt(st); exit; end;
      ReadW(bufKey, w);
    end;
  if recs[t].nwords > recs[t].fstart then
    Move(buf[recs[t].fstart], w[recs[t].fstart],
      (recs[t].nwords - recs[t].fstart) * 8);
  if not WriteW(bufKey, w, false) then begin SetSt(kStorage); exit; end;
  Journal('M', bufKey, w);
  buf := Copy(w);
  SetSt(kOk);
end;

procedure Forget(k: int64; var w: TWords);
var s, t: integer;
begin
  t := w[0];
  if cRU = k then cRU := 0;
  if cRec[t] = k then cRec[t] := 0;
  for s := 1 to high(sets) do
    if cSet[s] = k then begin
      { keep the position: the prior member, else the owner }
      if (sets[s].member = t) and (w[sets[s].memoff + 2] <> 0) then begin
        if w[sets[s].memoff + 1] <> 0 then cSet[s] := w[sets[s].memoff + 1]
        else if sets[s].owner > 0 then cSet[s] := w[sets[s].memoff + 2]
        else cSet[s] := 0;
      end else cSet[s] := 0;
    end;
end;

procedure EraseKey(k: int64);
var w, mw: TWords; s, t: integer; m, nx: int64;
begin
  if not ReadW(k, w) then begin SetSt(kStorage); exit; end;
  t := w[0];
  Forget(k, w);
  for s := 1 to high(sets) do begin
    if (sets[s].member = t) and (w[sets[s].memoff + 2] <> 0) then begin
      Unlink(s, k, w);
      ReadW(k, w);
    end;
    { members of an owned occurrence are disconnected (HYPOTHESIS) }
    if sets[s].owner = t then begin
      m := w[sets[s].ownoff];
      while m <> 0 do begin
        if not ReadW(m, mw) then break;
        nx := mw[sets[s].memoff];
        Unlink(s, m, mw);
        if cSet[s] = m then cSet[s] := 0;
        m := nx;
      end;
      ReadW(k, w);
    end;
  end;
  DropRecord(t, k, w);
  SetSt(kOk);
end;

procedure KERASE(r: int64);
var k: int64;
begin
  if not Ready then exit;
  if r = 0 then k := cRU
  else begin
    if Bad(r, false) then exit;
    k := cRec[r];
  end;
  if k = 0 then begin SetSt(kNoCur); exit; end;
  EraseKey(k);
end;

procedure KERASEMEMBERS(s: int64);
var o, m: int64; ow: TWords;
begin
  if Bad(s, true) then exit;
  if not Occurrence(s, o) then begin SetSt(kNoCur); exit; end;
  repeat
    if not ReadW(o, ow) then break;
    m := ow[sets[s].ownoff];
    if m <> 0 then EraseKey(m);
  until (m = 0) or (KSTAT <> kOk);
  SetSt(kOk);
end;

function KCOUNT(s: int64): int64;
var o, m: int64; w: TWords;
begin
  Result := 0;
  if Bad(s, true) then exit;
  if not Occurrence(s, o) then begin SetSt(kNoCur); exit; end;
  if not ReadW(o, w) then exit;
  m := w[sets[s].ownoff];
  while m <> 0 do begin
    inc(Result);
    if not ReadW(m, w) then break;
    m := w[sets[s].memoff];
  end;
  SetSt(kOk);
end;

procedure KCONNECT(s: int64);
var o, k: int64; w: TWords;
begin
  if Bad(s, true) then exit;
  k := cRec[sets[s].member];
  if k = 0 then k := cRU;
  if (k = 0) or not ReadW(k, w) or (w[0] <> sets[s].member) then begin
    SetSt(kNoCur); exit;
  end;
  if not Occurrence(s, o) or (o = k) then begin
    { the member itself is current of s: the occurrence is its owner's }
    if sets[s].owner = 0 then o := AnchorK
    else if cRec[sets[s].owner] <> 0 then o := cRec[sets[s].owner]
    else begin SetSt(kNoCur); exit; end;
  end;
  SetSt(Link(s, k, o, w));
  if KSTAT = kOk then MakeCurrent(k, s);
end;

{ connect the current member of s under the owner found by key in the
  selection set t (it must be a set of the owner type) }
procedure ConnectSel(s: integer; const kw: TWords);
var k, o: int64; w: TWords; t: integer;
begin
  t := sets[s].selset;
  k := cRec[sets[s].member];
  if k = 0 then k := cRU;
  if (k = 0) or not ReadW(k, w) or (w[0] <> sets[s].member) then begin
    SetSt(kNoCur); exit;
  end;
  FindKey(t, kw);
  if KSTAT <> kOk then exit;
  o := cRec[sets[t].member];
  ReadW(k, w);
  SetSt(Link(s, k, o, w));
  if KSTAT = kOk then MakeCurrent(k, s);
end;

function SelProbe(s: int64; var kw: TWords; var f: TField): boolean;
begin
  Result := false;
  if Bad(s, true) then exit;
  if sets[s].selset = 0 then begin SetSt(kBad); exit; end;
  Result := Probe(sets[s].selset, kw, f);
end;

procedure KCONNECTKEY(s: int64; v: int64);
var kw: TWords; f: TField;
begin
  if not SelProbe(s, kw, f) then exit;
  case f.kind of
    fkInt, fkBool: kw[f.off] := v;
    fkReal: PDouble(@kw[f.off])^ := v;
    fkChar: ;
  end;
  ConnectSel(s, kw);
end;

procedure KCONNECTKEY(s: int64; v: double);
var kw: TWords; f: TField;
begin
  if not SelProbe(s, kw, f) then exit;
  case f.kind of
    fkInt, fkBool: kw[f.off] := round(v);
    fkReal: PDouble(@kw[f.off])^ := v;
    fkChar: ;
  end;
  ConnectSel(s, kw);
end;

procedure KCONNECTKEY(s: int64; const v: array of char);
var kw: TWords; f: TField;
begin
  if not SelProbe(s, kw, f) then exit;
  if f.kind = fkChar then PutChars(kw, f, @v[0], length(v));
  ConnectSel(s, kw);
end;

procedure KDISCONNECT(s: int64);
var k: int64; w: TWords;
begin
  if Bad(s, true) then exit;
  k := cRec[sets[s].member];
  if k = 0 then k := cRU;
  if (k = 0) or not ReadW(k, w) or (w[0] <> sets[s].member) then begin
    SetSt(kNoCur); exit;
  end;
  if cSet[s] = k then Forget(k, w);
  SetSt(Unlink(s, k, w));
end;

function KCURTYPE: int64;
var w: TWords;
begin
  Result := 0;
  if Ready and (cRU <> 0) and ReadW(cRU, w) then Result := w[0];
end;

function KDBKEY(r: int64): int64;
begin
  Result := 0;
  if not Ready then exit;
  if r = 0 then Result := cRU
  else if not Bad(r, false) then begin
    EnsureSystem(r);
    Result := cRec[r];
  end;
  if Result = 0 then SetSt(kNoCur) else SetSt(kOk);
end;

procedure KSETCUR(r, k: int64);
var w: TWords;
begin
  if not Ready then exit;
  if (k = 0) or not ReadW(k, w) or ((r <> 0) and (w[0] <> r)) then begin
    SetSt(kNotFound); exit;
  end;
  MakeCurrent(k, 0);
  SetSt(kOk);
end;

procedure KOPEN(const journal: array of char);
var s: string;
begin
  SetString(s, PChar(@journal[0]), length(journal));
  jname := TrimRight(s);
  if Ready then SetSt(kOk);
end;

procedure KCLOSE;
begin
  SetSt(kOk);
end;

function KStatusText(st: int64): string;
begin
  case st of
    kOk: Result := 'OK';
    kEnd: Result := 'КОНЕЦ НАБОРА';
    kNotFound: Result := 'НЕТ ЗАПИСИ';
    kDup: Result := 'ДУБЛИКАТ КЛЮЧА';
    kNoCur: Result := 'НЕТ ТЕКУЩЕЙ';
    kMember: Result := 'ОШИБКА ЧЛЕНСТВА';
    kBad: Result := 'НЕВЕРНОЕ ИМЯ';
    kStorage: Result := 'ОШИБКА ПАМЯТИ';
    kNoSchema: Result := 'НЕТ СХЕМЫ';
  else
    Result := '?';
  end;
end;

function KCheck: string;
var aw, w, xw, ow: TWords; r, s: integer; k, p, o, x: int64; n: integer;
begin
  Result := '';
  if not Ready then exit('no schema');
  if not GetAnchor(aw) then exit('no anchor');
  for r := 1 to high(recs) do begin
    k := aw[TypeFirstOff(r)]; p := 0; n := 0;
    while k <> 0 do begin
      if not ReadW(k, w) then exit(Format('type %d: lost %d', [r, k]));
      if w[0] <> r then exit(Format('type %d: %d has type %d', [r, k, w[0]]));
      if w[recs[r].tnext + 1] <> p then exit(Format('type %d: prior of %d', [r, k]));
      { member links of every set }
      for s := 1 to high(sets) do
        if sets[s].member = r then begin
          o := w[sets[s].memoff + 2];
          if o = 0 then continue;
          x := w[sets[s].memoff];
          if x <> 0 then begin
            if not ReadW(x, xw) then exit(Format('set %d: lost next of %d', [s, k]));
            if xw[sets[s].memoff + 1] <> k then exit(Format('set %d: next/prior at %d', [s, k]));
            if xw[sets[s].memoff + 2] <> o then exit(Format('set %d: owner at %d', [s, x]));
            if Less(s, w, xw) > 0 then exit(Format('set %d: order at %d', [s, k]));
            if (Less(s, w, xw) = 0) and (sets[s].keyf > 0) and not sets[s].dup then
              exit(Format('set %d: duplicate at %d', [s, k]));
          end else begin
            if not ReadW(o, ow) then exit(Format('set %d: lost owner of %d', [s, k]));
            if ow[sets[s].ownoff + 1] <> k then exit(Format('set %d: last of %d', [s, o]));
          end;
          if w[sets[s].memoff + 1] = 0 then begin
            if not ReadW(o, ow) then exit(Format('set %d: lost owner of %d', [s, k]));
            if ow[sets[s].ownoff] <> k then exit(Format('set %d: first of %d', [s, o]));
          end;
        end;
      p := k; inc(n);
      k := w[recs[r].tnext];
    end;
    if aw[TypeFirstOff(r) + 1] <> p then exit(Format('type %d: last', [r]));
  end;
end;

end.
