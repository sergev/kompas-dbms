{ B+tree against a sorted-array model: random puts, deletes, gets and
  seeks with fixed seeds; TCheck validates the file after commits }
program treetest;

{$mode objfpc}{$H+}

uses SysUtils, mpage, mtree;

var
  mk, mv: array of RawByteString;   { the model, keys sorted }
  mn: integer;
  failures: integer = 0;
  checks: integer = 0;

function KCmp(const a, b: RawByteString): integer;
var m: integer;
begin
  m := length(a);
  if length(b) < m then m := length(b);
  Result := 0;
  if m > 0 then Result := CompareByte(a[1], b[1], m);
  if Result = 0 then Result := length(a) - length(b);
end;

function Hex(const s: RawByteString): string;
var i: integer;
begin
  Result := '';
  for i := 1 to length(s) do
    if i > 12 then begin Result := Result + '..'; break; end
    else Result := Result + IntToHex(ord(s[i]), 2);
end;

procedure Die(const s: string);
begin
  writeln('FAIL: ', s);
  halt(1);
end;

{ first index with key >= k }
function MFind(const k: RawByteString): integer;
var lo, hi, mid: integer;
begin
  lo := 0; hi := mn;
  while lo < hi do begin
    mid := (lo + hi) div 2;
    if KCmp(mk[mid], k) < 0 then lo := mid + 1 else hi := mid;
  end;
  Result := lo;
end;

procedure MPut(const k, v: RawByteString);
var i: integer;
begin
  i := MFind(k);
  if (i < mn) and (mk[i] = k) then begin mv[i] := v; exit; end;
  if mn = length(mk) then begin
    SetLength(mk, mn * 2 + 16);
    SetLength(mv, mn * 2 + 16);
  end;
  { shift the string pointers without touching their reference counts }
  if mn > i then begin
    Move(mk[i], mk[i + 1], (mn - i) * sizeof(pointer));
    Move(mv[i], mv[i + 1], (mn - i) * sizeof(pointer));
  end;
  pointer(mk[i]) := nil; pointer(mv[i]) := nil;
  mk[i] := k; mv[i] := v;
  inc(mn);
end;

function MDel(const k: RawByteString): boolean;
var i: integer;
begin
  i := MFind(k);
  Result := (i < mn) and (KCmp(mk[i], k) = 0);
  if not Result then exit;
  mk[i] := ''; mv[i] := '';
  if mn - 1 > i then begin
    Move(mk[i + 1], mk[i], (mn - 1 - i) * sizeof(pointer));
    Move(mv[i + 1], mv[i], (mn - 1 - i) * sizeof(pointer));
  end;
  dec(mn);
  pointer(mk[mn]) := nil; pointer(mv[mn]) := nil;
end;

{ the model's answer to a seek: index or -1 }
function MSeek(const k: RawByteString; mode: TSeek): integer;
var i: integer;
begin
  i := MFind(k);
  case mode of
    skGE: Result := i;
    skGT: if (i < mn) and (KCmp(mk[i], k) = 0) then Result := i + 1 else Result := i;
    skLE: if (i < mn) and (KCmp(mk[i], k) = 0) then Result := i else Result := i - 1;
    skLT: Result := i - 1;
    skFirst: Result := 0;
  else Result := mn - 1;
  end;
  if (Result < 0) or (Result >= mn) then Result := -1;
end;

procedure Check(const where: string);
var s: string;
begin
  s := TCheck;
  inc(checks);
  if s <> '' then Die(where + ': ' + s);
  if TStatEntries <> mn then
    Die(Format('%s: %d entries, model %d', [where, TStatEntries, mn]));
end;

procedure Scan(const where: string);
var k, fk, fv: RawByteString; i: integer;
begin
  TxnBegin(false);
  i := 0;
  k := '';
  if TSeekKey('', skFirst, fk, fv) then
    repeat
      if (i >= mn) or (fk <> mk[i]) or (fv <> mv[i]) then
        Die(Format('%s: forward scan at %d (%s)', [where, i, Hex(fk)]));
      inc(i);
      k := fk;
    until not TSeekKey(k, skGT, fk, fv);
  if i <> mn then Die(Format('%s: forward scan %d of %d', [where, i, mn]));
  if TSeekKey('', skLast, fk, fv) then
    repeat
      dec(i);
      if (i < 0) or (fk <> mk[i]) or (fv <> mv[i]) then
        Die(Format('%s: backward scan at %d', [where, i]));
      k := fk;
    until not TSeekKey(k, skLT, fk, fv);
  if i <> 0 then Die(where + ': backward scan short');
  TxnCommit;
end;

{ --- generators --- }

var
  mix: integer;
  seq: int64;

function Bytes(n: integer): RawByteString;
var i: integer;
begin
  SetLength(Result, n);
  for i := 1 to n do Result[i] := chr(random(256));
end;

function NewKey: RawByteString;
begin
  case mix of
    0: begin inc(seq); Result := 'k' + Format('%.8d', [seq]); end;
    1: begin dec(seq); Result := 'k' + Format('%.8d', [seq]); end;
    2: Result := Bytes(1 + random(20));
    3: Result := StringOfChar('p', 200) + Bytes(1 + random(40));
  else
    Result := Bytes(255);
  end;
end;

function NewVal: RawByteString;
var r: integer;
begin
  r := random(100);
  if r < 70 then Result := Bytes(random(65))
  else if r < 90 then Result := Bytes(65 + random(960))
  else Result := Bytes(1025 + random(5000));
end;

function AnyKey: RawByteString;
begin
  if (mn > 0) and (random(3) > 0) then Result := mk[random(mn)]
  else Result := NewKey;
end;

{ one random operation, compared with the model }
procedure Op;
var k, v, fk, fv: RawByteString; r, i: integer; mode: TSeek; found: boolean;
begin
  r := random(100);
  if r < 45 then begin
    if (mn > 0) and (random(4) = 0) then k := mk[random(mn)] else k := NewKey;
    v := NewVal;
    TPut(k, v);
    MPut(k, v);
  end else if r < 70 then begin
    k := AnyKey;
    if TDel(k) <> MDel(k) then Die('del ' + Hex(k));
  end else if r < 80 then begin
    k := AnyKey;
    found := TGet(k, v);
    i := MFind(k);
    if found <> ((i < mn) and (mk[i] = k)) then Die('get ' + Hex(k));
    if found and (v <> mv[i]) then Die('get value ' + Hex(k));
  end else begin
    k := AnyKey;
    if random(2) = 0 then k := k + chr(random(256));
    mode := TSeek(random(6));
    found := TSeekKey(k, mode, fk, fv);
    i := MSeek(k, mode);
    if found <> (i >= 0) then
      Die(Format('seek %d %s: found %s', [ord(mode), Hex(k), BoolToStr(found, true)]));
    if found and ((fk <> mk[i]) or (fv <> mv[i])) then
      Die(Format('seek %d %s: got %s want %s', [ord(mode), Hex(k), Hex(fk), Hex(mk[i])]));
  end;
end;

procedure Phase(const name: string; amix, seed, ops, checkEvery: integer);
var done, commits, n, i: integer;
begin
  mix := amix;
  RandSeed := seed;
  if mix = 1 then seq := 100000000 else seq := 0;
  done := 0; commits := 0;
  while done < ops do begin
    n := 1 + random(60);
    TxnBegin(true);
    for i := 1 to n do Op;
    TxnCommit;
    inc(done, n);
    inc(commits);
    if commits mod checkEvery = 0 then Check(Format('%s commit %d', [name, commits]));
  end;
  Check(name);
  Scan(name);
  writeln(Format('%-10s ops=%d entries=%d pages=%d over=%d free=%d depth=%d',
    [name, done, TStatEntries, TStatPages, TStatOver, TStatFree, TStatDepth]));
end;

procedure Drain(const name: string);
var k: RawByteString;
begin
  while mn > 0 do begin
    TxnBegin(true);
    while (mn > 0) and (random(200) > 0) do begin
      k := mk[random(mn)];
      if not TDel(k) then Die('drain ' + Hex(k));
      MDel(k);
    end;
    TxnCommit;
  end;
  Check(name);
  if (TStatPages <> 0) or (TxRoot <> 0) then Die(name + ': tree not empty');
  { TCheck accounts for every page: the rest are freelist pages }
  writeln(Format('%-10s entries=0 pages=0 file=%d free=%d', [name, PgCount, TStatFree]));
end;

{ put and delete the same set over and over: the file must stop growing }
procedure Steady;
var c, i: integer; size: array[1..12] of TPgno;
begin
  mix := 2;
  RandSeed := 77;
  for c := 1 to 12 do begin
    TxnBegin(true);
    for i := 1 to 1500 do begin
      MPut(NewKey, '');
    end;
    for i := 0 to mn - 1 do begin
      mv[i] := NewVal;
      TPut(mk[i], mv[i]);
    end;
    TxnCommit;
    Check('steady fill');
    TxnBegin(true);
    while mn > 0 do begin
      if not TDel(mk[mn - 1]) then Die('steady del');
      MDel(mk[mn - 1]);
    end;
    TxnCommit;
    size[c] := PgCount;
  end;
  Check('steady');
  writeln('steady     file stops growing: ',
    BoolToStr(size[12] = size[3], 'yes', Format('no (%d %d)', [size[3], size[12]])));
end;

begin
  PgOpen('tree.db');
  PgSync := false;
  Phase('seq', 0, 1, 15000, 20);
  Phase('reverse', 1, 2, 15000, 20);
  Phase('random', 2, 3, 40000, 20);
  Phase('prefix', 3, 4, 20000, 20);
  Phase('long', 4, 5, 15000, 20);
  Drain('drain');
  Phase('again', 2, 6, 30000, 25);
  Drain('drain2');
  Steady;
  PgClose;
  PgOpen('tree.db');
  Check('reopen');
  writeln('checks ', checks, ', failures ', failures);
end.
