{ MARS: the storage of KOMPAS (keyed data in areas).
  The whole database is one file, $MARS_DB (else $MARS_DIR/mars.db, else
  ./mars.db), a copy-on-write B+tree (mpage, mtree).  Tree keys:
    #0 kobla(3) name       an area: id u32, info i64, next handle i64
    #1 id(4, big-endian) key   an entry: words i64, handle i64, datum
    #2                     the next area id
  Every call is a transaction of its own unless MarsBegin opened one. }
unit mars;

{$mode objfpc}{$H+}

interface

uses krt;

type
  { a key: bytes, ordered as bytes; a name is its UTF-8, blanks trimmed }
  TKey = record
    b: RawByteString;
  end;

var
  BDERRN0: int64;          { used when the program has no BDERRN }

procedure MarsBind(vec, err: pointer);
{ COMMON BDVECT and BDERRN as bound by the main program }
function MarsVec: pointer;
function MarsErr: pointer;

{ a transaction around several calls: all of them commit or none }
procedure MarsBegin;
procedure MarsCommit;
procedure MarsAbort;
{ structure of the database file: '' if sound }
function MarsCheck: string;
{ the database file: $MARS_DB, else $MARS_DIR/mars.db, else mars.db }
function MarsPath: string;

var
  { a missing database file is made only when this is set (servis);
    otherwise every call fails with error 8 }
  MarsCreate: boolean = false;

procedure PASACD(var i: int64);
procedure PASSETAR(i: int64);
procedure pasbdi;
procedure pasbd;

function NameKey(const s: string): TKey;      { s in UTF-8 }
function ByteKey(const b: RawByteString): TKey;

procedure newd(const name: TKey; info: int64);
procedure opend(const name: TKey);
procedure putd(const key: TKey; const d: array of int64; n: int64);
procedure putd(const key: TKey; const d; n: int64);
procedure getd(const key: TKey; var d: array of int64; n: int64);
procedure getd(const key: TKey; var d; n: int64);
procedure modd(const key: TKey; const d: array of int64; n: int64);
procedure modd(const key: TKey; const d; n: int64);
procedure deld(const key: TKey);
{ the same with a name of a program: alfa or a literal; d is n bytes }
procedure newd(const name: array of WideChar; info: int64);
procedure opend(const name: array of WideChar);
procedure putd(const key: array of WideChar; const d: array of int64; n: int64);
procedure putd(const key: array of WideChar; const d; n: int64);
procedure getd(const key: array of WideChar; var d: array of int64; n: int64);
procedure getd(const key: array of WideChar; var d; n: int64);
procedure modd(const key: array of WideChar; const d: array of int64; n: int64);
procedure modd(const key: array of WideChar; const d; n: int64);
procedure deld(const key: array of WideChar);
procedure newd(const name: UnicodeString; info: int64);
procedure opend(const name: UnicodeString);
procedure putd(const key: UnicodeString; const d: array of int64; n: int64);
procedure putd(const key: UnicodeString; const d; n: int64);
procedure getd(const key: UnicodeString; var d: array of int64; n: int64);
procedure getd(const key: UnicodeString; var d; n: int64);
procedure modd(const key: UnicodeString; const d: array of int64; n: int64);
procedure modd(const key: UnicodeString; const d; n: int64);
procedure deld(const key: UnicodeString);

implementation

uses SysUtils, kutf, mpage, mtree;

type
  PVec = ^TVec;
  TVec = array[0..167] of int64;
  TOpened = record
    name: RawByteString;
    id: longword;
    info: int64;
  end;
  TEntry = record
    words, handle: int64;
    data: RawByteString;
  end;

var
  vec: PVec;
  err: ^int64;
  ownvec: TVec;
  { areas opened in the current catalogue; desc[i] is the descriptor
    word of opened[i], BDVECT[24] points at the current one (30 octal,
    DB file descriptor location).  A program that writes through slot 24
    spoils it. }
  opened: array of TOpened;
  desc: array[0..255] of int64;
  cur: integer = -1;       { current area }
  { cursor: the key of the current entry, or before the first }
  hasPos: boolean = false;
  posKey: RawByteString;
  serial: int64 = 0;       { changes when the cursor moves }
  aptr: pointer;           { datum allocated by ALLOC }
  alen, awords: int64;
  warned: boolean = false;

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

{ --- the file --- }

function MarsPath: string;
var dir: string;
begin
  Result := GetEnvironmentVariable('MARS_DB');
  if Result <> '' then exit;
  dir := GetEnvironmentVariable('MARS_DIR');
  if dir <> '' then Result := dir + '/mars.db' else Result := 'mars.db';
end;

function Open: boolean;
var dir: string; sr: TSearchRec;
begin
  Result := true;
  if PgIsOpen then exit;
  dir := GetEnvironmentVariable('MARS_DIR');
  if not warned and (GetEnvironmentVariable('MARS_DB') = '') and (dir <> '') and
     (FindFirst(dir + '/k*', faDirectory, sr) = 0) then begin
    warned := true;
    writeln(stderr, 'mars: ', dir, ' has areas of the old format (k*/*.area), ',
      'they are not used: rebuild the database');
    FindClose(sr);
  end;
  if not MarsCreate and not FileExists(MarsPath) then begin
    err^ := 8;               { eNoName }
    exit(false);
  end;
  PgOpen(MarsPath);
end;

function WBegin: boolean;
begin
  Result := Open;
  if Result then TxnBegin(true);
end;

function RBegin: boolean;
begin
  Result := Open;
  if Result then TxnBegin(false);
end;

var
  idle: integer = 0;        { MarsBegin calls without a database }

procedure MarsBegin;
begin
  if not WBegin then inc(idle);
end;

procedure MarsCommit;
begin
  if idle > 0 then dec(idle) else TxnCommit;
end;

procedure MarsAbort;
begin
  if idle > 0 then begin dec(idle); exit; end;
  TxnAbort;
end;

function MarsCheck: string;
begin
  if not Open then exit('no database ' + MarsPath);
  Result := TCheck;
end;

{ --- keys and values --- }

function BE32(x: longword): RawByteString;
begin
  SetLength(Result, 4);
  Result[1] := chr(x shr 24); Result[2] := chr((x shr 16) and 255);
  Result[3] := chr((x shr 8) and 255); Result[4] := chr(x and 255);
end;

function AreaKey(const name: RawByteString): RawByteString;
begin
  Result := #0 + chr((kobla shr 16) and 255) + chr((kobla shr 8) and 255) +
    chr(kobla and 255) + name;
end;

function Prefix(id: longword): RawByteString;
begin
  Result := #1 + BE32(id);
end;

function I64(const s: RawByteString; at: integer): int64;
begin
  Move(s[at], Result, 8);
end;

function S64(x: int64): RawByteString;
begin
  SetLength(Result, 8);
  Move(x, Result[1], 8);
end;

function AreaVal(id: longword; info, nexth: int64): RawByteString;
begin
  Result := BE32(id) + S64(info) + S64(nexth);
end;

function GetArea(const name: RawByteString; out id: longword; out info, nexth: int64): boolean;
var v: RawByteString;
begin
  Result := TGet(AreaKey(name), v);
  if not Result then exit;
  id := (longword(ord(v[1])) shl 24) or (longword(ord(v[2])) shl 16) or
    (longword(ord(v[3])) shl 8) or longword(ord(v[4]));
  info := I64(v, 5);
  nexth := I64(v, 13);
end;

function EntVal(const e: TEntry): RawByteString;
begin
  Result := S64(e.words) + S64(e.handle) + e.data;
end;

procedure DecEnt(const v: RawByteString; out e: TEntry);
begin
  e.words := I64(v, 1);
  e.handle := I64(v, 9);
  e.data := Copy(v, 17, length(v) - 16);
end;

{ --- catalogue and areas --- }

{ catalogue key of an info word MMMMZZNNNN: ZZNNNN with the two low
  octal digits of the zone cleared }
procedure Select(i: int64);
var k: int64;
begin
  k := (i and &777777) and not int64(&77);
  if k <> kobla then begin
    kobla := k;
    opened := nil;
    cur := -1;
    hasPos := false;
  end;
end;

procedure SetErr(e: int64);
begin
  err^ := e;
end;

{ the current area's descriptor is intact }
function Intact: boolean;
begin
  Result := (cur >= 0) and (desc[cur] = opened[cur].info);
  if not Result then SetErr(eNoName);
end;

function CurPrefix: RawByteString;
begin
  Result := Prefix(opened[cur].id);
end;

{ --- the cursor --- }

procedure MoveTo(const k: RawByteString);
begin
  hasPos := true;
  posKey := k;
  inc(serial);
end;

procedure Unset;
begin
  hasPos := false;
  inc(serial);
end;

{ an entry of the current area: mode from key k (without the prefix) }
function Seek(mode: TSeek; const k: RawByteString; out fk: RawByteString; out e: TEntry): boolean;
var p, full, v: RawByteString;
begin
  p := CurPrefix;
  case mode of
    skFirst: Result := TSeekKey(p, skGE, full, v);
    skLast: Result := TSeekKey(Prefix(opened[cur].id + 1), skLT, full, v);
  else Result := TSeekKey(p + k, mode, full, v);
  end;
  Result := Result and (Copy(full, 1, 5) = p);
  if Result then begin
    fk := Copy(full, 6, length(full) - 5);
    DecEnt(v, e);
  end;
end;

function GetEnt(const k: RawByteString; out e: TEntry): boolean;
var v: RawByteString;
begin
  Result := TGet(CurPrefix + k, v);
  if Result then DecEnt(v, e);
end;

procedure PutEnt(const k: RawByteString; const e: TEntry);
begin
  TPut(CurPrefix + k, EntVal(e));
end;

function ByteKey(const b: RawByteString): TKey;
begin
  Result.b := b;
end;

function NameKey(const s: string): TKey;
begin
  Result.b := TrimRight(s);
end;

function MkKey(const s: UnicodeString): TKey;
begin
  Result := NameKey(W2U(s));
end;

function MkKey(const s: array of WideChar): TKey;
begin
  if length(s) = 0 then Result.b := ''
  else Result := NameKey(BufU(@s[0], length(s)));
end;

function Datum(p: pointer; n: int64): RawByteString;
begin
  SetLength(Result, n);
  if n > 0 then Move(p^, Result[1], n);
end;

{ cursor state into BDVECT }
procedure ShowCursor;
var e: TEntry; k: RawByteString;
begin
  if cur < 0 then exit;
  vec^[sCurKey] := 0;
  if not hasPos then exit;
  k := posKey;
  if not GetEnt(k, e) then exit;
  { the first 8 bytes of the key }
  if length(k) > 0 then
    if length(k) < 8 then Move(k[1], vec^[sCurKey], length(k))
    else Move(k[1], vec^[sCurKey], 8);
  vec^[sCurLen] := e.words;
  vec^[sHandle] := e.handle;
  vec^[sEntAdr] := EntTag + serial * 2;
end;

{ a new entry with the next handle of the area }
procedure Insert(const k: RawByteString; p: pointer; n, words: int64);
var e: TEntry; id: longword; info, nexth: int64;
begin
  GetArea(opened[cur].name, id, info, nexth);
  if nexth = 0 then nexth := FirstHandle;
  e.words := words;
  e.handle := nexth;
  e.data := Datum(p, n);
  PutEnt(k, e);
  TPut(AreaKey(opened[cur].name), AreaVal(id, info, nexth + HandleStep));
  MoveTo(k);
end;

procedure Replace(const k: RawByteString; const old: TEntry; p: pointer; n, words: int64);
var e: TEntry;
begin
  e := old;
  e.data := Datum(p, n);
  e.words := words;
  PutEnt(k, e);
  MoveTo(k);
end;

procedure Remove(const k: RawByteString);
var fk: RawByteString; e: TEntry;
begin
  TDel(CurPrefix + k);
  { the cursor goes to the entry before }
  if Seek(skLT, k, fk, e) then MoveTo(fk) else Unset;
end;

procedure Store(const k: TKey; p: pointer; n, words: int64; replace: boolean);
var e: TEntry;
begin
  if not WBegin then exit;
  try
    if Intact then begin
      if GetEnt(k.b, e) then begin
        if replace then begin
          mars.Replace(k.b, e, p, n, words);
          SetErr(0);
        end else
          SetErr(eExists);
      end else begin
        Insert(k.b, p, n, words);
        SetErr(0);
      end;
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure Fetch(const k: TKey; p: pointer; n: int64);
var e: TEntry; m: int64;
begin
  if not RBegin then exit;
  try
    if Intact then begin
      if not GetEnt(k.b, e) then SetErr(eNoRec)
      else begin
        m := length(e.data);
        if m > n then m := n;
        if m > 0 then Move(e.data[1], p^, m);
        MoveTo(k.b);
        vec^[sCurLen] := e.words;
        SetErr(0);
      end;
    end;
  finally
    TxnCommit;
  end;
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
var pre, k, v, fk: RawByteString; id: longword; info, nexth: int64;
begin
  { fresh KOBLA at this LU and zone: forget its areas }
  Select(i);
  if not WBegin then exit;
  try
    pre := AreaKey('');
    k := pre;
    while TSeekKey(k, skGE, fk, v) and (Copy(fk, 1, 4) = pre) do begin
      GetArea(Copy(fk, 5, length(fk) - 4), id, info, nexth);
      while TSeekKey(Prefix(id), skGE, k, v) and (Copy(k, 1, 5) = Prefix(id)) do TDel(k);
      TDel(fk);
      k := pre;
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
  opened := nil;
  cur := -1;
  hasPos := false;
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

{ a key of up to 8 bytes in vec[8], zero padded }
function KeyArg: TKey;
var b: RawByteString; n: integer;
begin
  SetLength(b, 8);
  Move(vec^[sKey], b[1], 8);
  n := 8;
  while (n > 0) and (b[n] = #0) do dec(n);
  SetLength(b, n);
  Result := NameKey(b);
end;

function Matches: boolean;
begin
  Result := hasPos and (posKey = KeyArg.b);
end;

{ microprogram in vec[3], 6-bit ops from the low bits (MARS README) }
procedure Micro;
var w, op, a, b, n: int64; ok: boolean; fk: RawByteString; e: TEntry;

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
      1: Unset;                                           { BEGIN }
      2: if Seek(skLast, '', fk, e) then MoveTo(fk)       { LAST }
         else Unset;
      3: if not hasPos then begin SetErr(eNoPrev); break; end   { PREV }
         else if Seek(skLT, posKey, fk, e) then MoveTo(fk)
         else Unset;
      4: begin                                            { NEXT }
           if hasPos then ok := Seek(skGT, posKey, fk, e)
           else ok := Seek(skFirst, '', fk, e);
           if not ok then begin SetErr(eNoNext); break; end;
           MoveTo(fk);
         end;
      9: begin                                            { FIND }
           if Seek(skLE, KeyArg.b, fk, e) then begin
             MoveTo(fk);
             { the handle operated upon: kept after DELKEY }
             vec^[sHandle] := e.handle;
           end else
             Unset;
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
      16: if hasPos and GetEnt(posKey, e) then begin      { UPDATE }
            n := vec^[sLen];
            Replace(posKey, e, pointer(vec^[sData]), n * 8, n);
          end;
      17: begin                                           { ALLOC }
            aptr := pointer(vec^[sData]);
            awords := vec^[sLen];
            alen := awords * 8;
          end;
      18: if hasPos and GetEnt(posKey, e) then begin      { GET }
            n := length(e.data);
            if n > vec^[sLen] * 8 then n := vec^[sLen] * 8;
            if n > 0 then Move(e.data[1], pointer(vec^[sData])^, n);
          end;
      19: ;                                               { FREE }
      22: if GetEnt(KeyArg.b, e) then begin               { ADDKEY }
            SetErr(eExists); break;
          end else
            Insert(KeyArg.b, aptr, alen, awords);
      23: if hasPos then Remove(posKey);                  { DELKEY }
      32: break;                                          { STOP }
      43: begin                                           { ASSIGN }
            a := Next; b := Next;
            vec^[a] := vec^[b];
            if (a = sHandle) and hasPos and GetEnt(posKey, e) then begin
              e.handle := vec^[a];
              PutEnt(posKey, e);
            end;
          end;
      44: begin                                           { STALLOC }
            a := Next;
            { mem[vec[a]] := vec[10]: writes the handle of the entry
              whose descriptor address is vec[30]+1 }
            if hasPos and (vec^[a] = EntTag + serial * 2 + 1) and
               GetEnt(posKey, e) then begin
              e.handle := vec^[sStore];
              PutEnt(posKey, e);
            end;
          end;
    else
      SetErr(eSys); break;
    end;
  end;
  ShowCursor;
end;

procedure pasbd;
begin
  if not WBegin then exit;
  try
    Micro;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure newd(const name: TKey; info: int64);
var id: longword; i, n: int64; v: RawByteString;
begin
  if not WBegin then exit;
  try
    if GetArea(name.b, id, i, n) then SetErr(eExists)
    else begin
      id := 1;
      if TGet(#2, v) then id := I64(v, 1);
      TPut(#2, S64(id + 1));
      TPut(AreaKey(name.b), AreaVal(id, info, FirstHandle));
      SetErr(0);
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure opend(const name: TKey);
var i: integer; id: longword; info, nexth: int64; found: boolean;
begin
  if not RBegin then exit;
  try
    found := GetArea(name.b, id, info, nexth);
  finally
    TxnCommit;
  end;
  if not found then begin SetErr(eNoName); exit; end;
  i := 0;
  while (i < length(opened)) and (opened[i].name <> name.b) do inc(i);
  if i > high(desc) then raise EMars.Create('mars: too many areas');
  if i = length(opened) then SetLength(opened, i + 1);
  opened[i].name := name.b;
  opened[i].id := id;
  opened[i].info := info;
  cur := i;
  hasPos := false;
  desc[i] := info;
  vec^[sDesc] := PtrInt(@desc[i]);
  SetErr(0);
end;

procedure putd(const key: TKey; const d: array of int64; n: int64);
begin Store(key, @d, n, n div 8, false); end;
procedure putd(const key: TKey; const d; n: int64);
begin Store(key, @d, n, (n + 7) div 8, false); end;
procedure getd(const key: TKey; var d: array of int64; n: int64);
begin Fetch(key, @d, n); end;
procedure getd(const key: TKey; var d; n: int64);
begin Fetch(key, @d, n); end;
procedure modd(const key: TKey; const d: array of int64; n: int64);
begin Store(key, @d, n, n div 8, true); end;
procedure modd(const key: TKey; const d; n: int64);
begin Store(key, @d, n, (n + 7) div 8, true); end;

procedure deld(const key: TKey);
var e: TEntry;
begin
  if not WBegin then exit;
  try
    if Intact then begin
      if not GetEnt(key.b, e) then SetErr(eNoRec)
      else begin
        Remove(key.b);
        SetErr(0);
      end;
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure newd(const name: array of WideChar; info: int64);
begin newd(MkKey(name), info); end;
procedure opend(const name: array of WideChar);
begin opend(MkKey(name)); end;
procedure putd(const key: array of WideChar; const d: array of int64; n: int64);
begin putd(MkKey(key), d, n); end;
procedure putd(const key: array of WideChar; const d; n: int64);
begin putd(MkKey(key), d, n); end;
procedure getd(const key: array of WideChar; var d: array of int64; n: int64);
begin getd(MkKey(key), d, n); end;
procedure getd(const key: array of WideChar; var d; n: int64);
begin getd(MkKey(key), d, n); end;
procedure modd(const key: array of WideChar; const d: array of int64; n: int64);
begin modd(MkKey(key), d, n); end;
procedure modd(const key: array of WideChar; const d; n: int64);
begin modd(MkKey(key), d, n); end;
procedure deld(const key: array of WideChar);
begin deld(MkKey(key)); end;

procedure newd(const name: UnicodeString; info: int64);
begin newd(MkKey(name), info); end;
procedure opend(const name: UnicodeString);
begin opend(MkKey(name)); end;
procedure putd(const key: UnicodeString; const d: array of int64; n: int64);
begin putd(MkKey(key), d, n); end;
procedure putd(const key: UnicodeString; const d; n: int64);
begin putd(MkKey(key), d, n); end;
procedure getd(const key: UnicodeString; var d: array of int64; n: int64);
begin getd(MkKey(key), d, n); end;
procedure getd(const key: UnicodeString; var d; n: int64);
begin getd(MkKey(key), d, n); end;
procedure modd(const key: UnicodeString; const d: array of int64; n: int64);
begin modd(MkKey(key), d, n); end;
procedure modd(const key: UnicodeString; const d; n: int64);
begin modd(MkKey(key), d, n); end;
procedure deld(const key: UnicodeString);
begin deld(MkKey(key)); end;

initialization
  vec := @ownvec;
  err := @BDERRN0;
end.
