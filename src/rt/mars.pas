{ MARS: the storage of KOMPAS (keyed data in areas) on a file store.
  Areas live in $MARS_DIR (default ./mars), one file per area. }
unit mars;

{$mode objfpc}{$H+}

interface

uses krt;

type
  TKey = packed array[0..5] of char;

var
  BDERRN0: int64;          { used when the program has no BDERRN }

procedure MarsBind(vec, err: pointer);
{ COMMON BDVECT and BDERRN as bound by the main program }
function MarsVec: pointer;
function MarsErr: pointer;

procedure PASACD(var i: int64);
procedure PASSETAR(i: int64);
procedure pasbdi;
procedure pasbd;

procedure newd(const name: array of char; info: int64);
procedure opend(const name: array of char);
procedure putd(const key: array of char; const d: array of char; n: int64);
procedure putd(const key: array of char; const d: array of int64; n: int64);
procedure putd(const key: array of char; const d; n: int64);
procedure getd(const key: array of char; var d: array of char; n: int64);
procedure getd(const key: array of char; var d: array of int64; n: int64);
procedure getd(const key: array of char; var d; n: int64);
procedure modd(const key: array of char; const d: array of char; n: int64);
procedure modd(const key: array of char; const d: array of int64; n: int64);
procedure modd(const key: array of char; const d; n: int64);
procedure deld(const key: array of char);

implementation

uses SysUtils, Classes;

type
  TEntry = record
    key: TKey;
    words: int64;
    handle: int64;           { datum handle: the bd-key }
    data: TBytes;
  end;
  TArea = record
    name: TKey;
    info: int64;
    nexth: int64;            { next datum handle }
    ent: array of TEntry;
  end;
  PVec = ^TVec;
  TVec = array[0..167] of int64;

var
  vec: PVec;
  err: ^int64;
  ownvec: TVec;
  areas: array of TArea;
  cur: integer = -1;       { current area }
  pos: integer = -1;       { cursor, -1 = zero key }
  { descriptor word of each area; BDVECT[24] points at the current one
    (30 octal, DB file descriptor location).  A program that writes
    through slot 24 spoils it. }
  desc: array[0..255] of int64;
  aptr: pointer;           { datum allocated by ALLOC }
  alen, awords: int64;

const
  eNoRec = 3; eNoName = 8; eExists = 9; eSys = 11; eNoPrev = 15; eNoNext = 16;
  { HYPOTHESIS: handles of a fresh area start at 6000 octal; the step is
    not known. }
  FirstHandle = 3072;
  HandleStep = 64;
  { token for BDVECT[30]: "address" of the current entry descriptor }
  EntTag = int64(1) shl 40;

  { BDVECT slots (MARS README, octal offsets) }
  sCode = 3; sKey = 8; sStore = 10; sData = 11; sLen = 13;
  sDesc = 24; sHandle = 29; sEntAdr = 30; sCurKey = 31; sInfo = 36; sCurLen = 39;

var
  kobla: int64 = 0;          { current catalogue: LU and zone of its info word }

function Dir: string;
begin
  Result := GetEnvironmentVariable('MARS_DIR');
  if Result = '' then Result := 'mars';
  Result := Result + '/k' + OctStr(kobla, 6);
end;

{ catalogue key of an info word MMMMZZNNNN: ZZNNNN with the two low
  octal digits of the zone cleared }
procedure Select(i: int64);
var k: int64;
begin
  k := (i and &777777) and not int64(&77);
  if k <> kobla then begin
    kobla := k;
    SetLength(areas, 0);
    cur := -1;
    pos := -1;
  end;
end;

procedure SetErr(e: int64);
begin
  err^ := e;
end;

{ the current area's descriptor is intact }
function Intact: boolean;
begin
  Result := (cur >= 0) and (desc[cur] = areas[cur].info);
  if not Result then SetErr(eNoName);
end;

function MkKey(const s: array of char): TKey;
var i: integer;
begin
  for i := 0 to 5 do
    if i <= high(s) then Result[i] := s[i] else Result[i] := ' ';
end;

function KeyFile(const k: TKey): string;
var i: integer;
begin
  Result := '';
  for i := 0 to 5 do Result := Result + IntToHex(ord(k[i]), 2);
end;

function Cmp(const a, b: TKey): integer;
var i: integer;
begin
  for i := 0 to 5 do
    if a[i] <> b[i] then exit(ord(a[i]) - ord(b[i]));
  Result := 0;
end;

procedure SaveArea(a: integer);
var f: TFileStream; i: integer; n: int64;
begin
  ForceDirectories(Dir);
  f := TFileStream.Create(Dir + '/' + KeyFile(areas[a].name) + '.area', fmCreate);
  try
    f.WriteBuffer(areas[a].info, 8);
    f.WriteBuffer(areas[a].nexth, 8);
    n := length(areas[a].ent);
    f.WriteBuffer(n, 8);
    for i := 0 to high(areas[a].ent) do
      with areas[a].ent[i] do begin
        f.WriteBuffer(key, 6);
        f.WriteBuffer(words, 8);
        f.WriteBuffer(handle, 8);
        n := length(data);
        f.WriteBuffer(n, 8);
        if n > 0 then f.WriteBuffer(data[0], n);
      end;
  finally
    f.Free;
  end;
end;

function FindArea(const k: TKey): integer;
var i: integer; fn: string; f: TFileStream; n, m, j: int64;
begin
  for i := 0 to high(areas) do
    if Cmp(areas[i].name, k) = 0 then exit(i);
  fn := Dir + '/' + KeyFile(k) + '.area';
  if not FileExists(fn) then exit(-1);
  i := length(areas);
  SetLength(areas, i + 1);
  areas[i].name := k;
  f := TFileStream.Create(fn, fmOpenRead);
  try
    f.ReadBuffer(areas[i].info, 8);
    f.ReadBuffer(areas[i].nexth, 8);
    f.ReadBuffer(n, 8);
    SetLength(areas[i].ent, n);
    for j := 0 to n - 1 do
      with areas[i].ent[j] do begin
        f.ReadBuffer(key, 6);
        f.ReadBuffer(words, 8);
        f.ReadBuffer(handle, 8);
        f.ReadBuffer(m, 8);
        SetLength(data, m);
        if m > 0 then f.ReadBuffer(data[0], m);
      end;
  finally
    f.Free;
  end;
  Result := i;
end;

{ greatest key <= k, or -1 }
function Floor(const k: TKey): integer;
var i: integer;
begin
  Result := -1;
  if cur < 0 then exit;
  for i := 0 to high(areas[cur].ent) do
    if Cmp(areas[cur].ent[i].key, k) <= 0 then Result := i else break;
end;

{ cursor state into BDVECT }
procedure ShowCursor;
begin
  if cur < 0 then exit;
  vec^[sCurKey] := 0;
  if (cur < 0) or (pos < 0) then exit;
  with areas[cur].ent[pos] do begin
    Move(key, vec^[sCurKey], 6);
    vec^[sCurLen] := words;
    vec^[sHandle] := handle;
  end;
  vec^[sEntAdr] := EntTag + pos * 2;
end;

{ insert key k with datum p/n at the floor position }
procedure Insert(const k: TKey; p: pointer; n, words: int64);
var i, j: integer;
begin
  i := Floor(k) + 1;
  with areas[cur] do begin
    SetLength(ent, length(ent) + 1);
    for j := high(ent) downto i + 1 do ent[j] := ent[j - 1];
    ent[i].key := k;
    ent[i].words := words;
    if nexth = 0 then nexth := FirstHandle;
    ent[i].handle := nexth;
    inc(nexth, HandleStep);
    SetLength(ent[i].data, n);
    if n > 0 then Move(p^, ent[i].data[0], n);
  end;
  pos := i;
  SaveArea(cur);
end;

procedure Replace(i: integer; p: pointer; n, words: int64);
begin
  with areas[cur].ent[i] do begin
    SetLength(data, n);
    if n > 0 then Move(p^, data[0], n);
  end;
  areas[cur].ent[i].words := words;
  pos := i;
  SaveArea(cur);
end;

procedure Store(const k: TKey; p: pointer; n, words: int64; replace: boolean);
var i: integer;
begin
  if not Intact then exit;
  i := Floor(k);
  if (i >= 0) and (Cmp(areas[cur].ent[i].key, k) = 0) then begin
    if not replace then begin SetErr(eExists); exit; end;
    mars.Replace(i, p, n, words);
  end else
    Insert(k, p, n, words);
  SetErr(0);
end;

procedure Fetch(const k: TKey; p: pointer; n: int64);
var i: integer; m: int64;
begin
  if not Intact then exit;
  i := Floor(k);
  if (i < 0) or (Cmp(areas[cur].ent[i].key, k) <> 0) then begin
    SetErr(eNoRec); exit;
  end;
  m := length(areas[cur].ent[i].data);
  if m > n then m := n;
  if m > 0 then Move(areas[cur].ent[i].data[0], p^, m);
  pos := i;
  vec^[sCurLen] := areas[cur].ent[i].words;
  SetErr(0);
end;

procedure Remove(i: integer);
var j: integer;
begin
  for j := i to high(areas[cur].ent) - 1 do
    areas[cur].ent[j] := areas[cur].ent[j + 1];
  SetLength(areas[cur].ent, length(areas[cur].ent) - 1);
  pos := i - 1;
  SaveArea(cur);
end;

procedure MarsBind(vec, err: pointer);
begin
  if vec <> nil then mars.vec := vec;
  if err <> nil then mars.err := err;
end;

function MarsVec: pointer;
begin
  Result := vec;
end;

function MarsErr: pointer;
begin
  Result := err;
end;

procedure PASACD(var i: int64);
var sr: TSearchRec;
begin
  { fresh KOBLA at this LU and zone: forget its areas }
  Select(i);
  if FindFirst(Dir + '/*.area', faAnyFile, sr) = 0 then begin
    repeat DeleteFile(Dir + '/' + sr.Name) until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  SetLength(areas, 0);
  cur := -1;
  vec^[sInfo] := i;
  SetErr(0);
end;

procedure PASSETAR(i: int64);
begin
  Select(i);
  { the real MARS leaves i+1 here: PASSETAR(270000c) -> 270001c (ZAT* etalons) }
  vec^[sInfo] := i + 1;
  SetErr(0);
end;

procedure pasbdi;
begin
  SetErr(0);
end;

function KeyArg: TKey;
begin
  Move(vec^[sKey], Result, 6);
end;

function Matches: boolean;
var k: TKey;
begin
  k := KeyArg;
  Result := (pos >= 0) and (Cmp(areas[cur].ent[pos].key, k) = 0);
end;

{ microprogram in vec[3], 6-bit ops from the low bits (MARS README) }
procedure pasbd;
var w, op, a, b, n: int64; ok: boolean;

  function Next: int64;
  begin
    Result := w and 63;
    w := w shr 6;
  end;

begin
  SetErr(0);
  w := vec^[sCode];
  while w <> 0 do begin
    op := Next;
    if not (op in [0, 43, 44]) and not Intact then break;
    case op of
      0: ;
      1: pos := -1;                                       { BEGIN }
      2: pos := high(areas[cur].ent);                     { LAST }
      3: if pos < 0 then begin SetErr(eNoPrev); break; end   { PREV }
         else dec(pos);
      4: if pos >= high(areas[cur].ent) then begin SetErr(eNoNext); break; end
         else inc(pos);                                   { NEXT }
      9: begin                                            { FIND }
           pos := Floor(KeyArg);
           { the handle operated upon: kept after DELKEY }
           if pos >= 0 then vec^[sHandle] := areas[cur].ent[pos].handle;
         end;
      12, 13: begin                                       { MATCH, NOMATCH }
            ok := Matches = (op = 12);
            if (w and 63) = 0 then begin
              { conditional form: on failure skip 00 and 3 ops }
              if not ok then begin Next; Next; Next; Next; end
              else Next;
            end else if not ok then begin
              if op = 12 then SetErr(eNoRec) else SetErr(eExists);
              break;
            end;
          end;
      16: if pos >= 0 then begin                          { UPDATE }
            n := vec^[sLen];
            Replace(pos, pointer(vec^[sData]), n * 8, n);
          end;
      17: begin                                           { ALLOC }
            aptr := pointer(vec^[sData]);
            awords := vec^[sLen];
            alen := awords * 8;
          end;
      18: if pos >= 0 then begin                          { GET }
            n := length(areas[cur].ent[pos].data);
            if n > vec^[sLen] * 8 then n := vec^[sLen] * 8;
            if n > 0 then Move(areas[cur].ent[pos].data[0], pointer(vec^[sData])^, n);
          end;
      19: ;                                               { FREE }
      22: Insert(KeyArg, aptr, alen, awords);             { ADDKEY }
      23: if pos >= 0 then Remove(pos);                   { DELKEY }
      32: break;                                          { STOP }
      43: begin                                           { ASSIGN }
            a := Next; b := Next;
            vec^[a] := vec^[b];
            if (a = sHandle) and (pos >= 0) then
              areas[cur].ent[pos].handle := vec^[a];
          end;
      44: begin                                           { STALLOC }
            a := Next;
            { mem[vec[a]] := vec[10]: writes the handle of the entry
              whose descriptor address is vec[30]+1 }
            if (pos >= 0) and (vec^[a] = EntTag + pos * 2 + 1) then begin
              areas[cur].ent[pos].handle := vec^[sStore];
              SaveArea(cur);
            end;
          end;
    else
      SetErr(eSys); break;
    end;
  end;
  ShowCursor;
end;

procedure newd(const name: array of char; info: int64);
var k: TKey; i: integer;
begin
  k := MkKey(name);
  if FindArea(k) >= 0 then begin SetErr(eExists); exit; end;
  i := length(areas);
  SetLength(areas, i + 1);
  areas[i].name := k;
  areas[i].info := info;
  areas[i].nexth := FirstHandle;
  SaveArea(i);
  SetErr(0);
end;

procedure opend(const name: array of char);
var i: integer;
begin
  i := FindArea(MkKey(name));
  if i < 0 then begin SetErr(eNoName); exit; end;
  cur := i;
  pos := -1;
  desc[i] := areas[i].info;
  vec^[sDesc] := PtrInt(@desc[i]);
  SetErr(0);
end;


procedure putd(const key: array of char; const d: array of char; n: int64);
begin Store(MkKey(key), @d, n, (n + 5) div 6, false); end;
procedure putd(const key: array of char; const d: array of int64; n: int64);
begin Store(MkKey(key), @d, n, n div 8, false); end;
procedure putd(const key: array of char; const d; n: int64);
begin Store(MkKey(key), @d, n, (n + 7) div 8, false); end;

procedure getd(const key: array of char; var d: array of char; n: int64);
begin Fetch(MkKey(key), @d, n); end;
procedure getd(const key: array of char; var d: array of int64; n: int64);
begin Fetch(MkKey(key), @d, n); end;
procedure getd(const key: array of char; var d; n: int64);
begin Fetch(MkKey(key), @d, n); end;

procedure modd(const key: array of char; const d: array of char; n: int64);
begin Store(MkKey(key), @d, n, (n + 5) div 6, true); end;
procedure modd(const key: array of char; const d: array of int64; n: int64);
begin Store(MkKey(key), @d, n, n div 8, true); end;
procedure modd(const key: array of char; const d; n: int64);
begin Store(MkKey(key), @d, n, (n + 7) div 8, true); end;

procedure deld(const key: array of char);
var i: integer; k: TKey;
begin
  k := MkKey(key);
  i := Floor(k);
  if (i < 0) or (Cmp(areas[cur].ent[i].key, k) <> 0) then begin
    SetErr(eNoRec); exit;
  end;
  Remove(i);
  SetErr(0);
end;

initialization
  vec := @ownvec;
  err := @BDERRN0;
end.
