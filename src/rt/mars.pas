{ MARS: the storage of KOMPAS (keyed data in areas).
  The whole database is one file, $MARS_DB (else $MARS_DIR/mars.db, else
  ./mars.db), a copy-on-write B+tree (mpage, mtree).  Tree keys:
    #0 name                    an area: its id (u32, big-endian)
    #1 id key                  an entry: its datum
    #2                         the next area id
  Every call is a transaction of its own unless MarsBegin opened one. }
unit mars;

{$mode objfpc}{$H+}

interface

type
  { a key: bytes, ordered as bytes; a name is its UTF-8, blanks trimmed }
  TKey = record
    b: RawByteString;
  end;

const
  eNoRec = 3;        { no such entry }
  eNoName = 8;       { no such area, no area open, or no database file }
  eExists = 9;       { the area or the entry exists }

var
  { error of the last call: 0 or one of e* }
  MErr: int64 = 0;

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
    otherwise every call fails with eNoName }
  MarsCreate: boolean = false;

function NameKey(const s: string): TKey;      { s in UTF-8 }
function ByteKey(const b: RawByteString): TKey;

{ areas; opend makes an area the open one, which the other calls use }
procedure newd(const name: TKey);
procedure opend(const name: TKey);
{ all entries of an area deleted, the area kept; the area deleted }
procedure cleard(const name: TKey);
procedure dropd(const name: TKey);

{ entries, d is n bytes: putd adds (eExists if there), modd adds or
  replaces, getd copies at most n bytes }
procedure putd(const key: TKey; const d; n: int64);
procedure getd(const key: TKey; var d; n: int64);
procedure modd(const key: TKey; const d; n: int64);
procedure deld(const key: TKey);

{ entries in key order: the first, the last, the one after or before
  key; false (eNoRec) if none }
function firstd(out key, data: RawByteString): boolean;
function lastd(out key, data: RawByteString): boolean;
function nextd(var key: RawByteString; out data: RawByteString): boolean;
function prevd(var key: RawByteString; out data: RawByteString): boolean;

{ the same with a name of a program: alfa or a literal }
procedure newd(const name: array of WideChar);
procedure opend(const name: array of WideChar);
procedure cleard(const name: array of WideChar);
procedure dropd(const name: array of WideChar);
procedure putd(const key: array of WideChar; const d; n: int64);
procedure getd(const key: array of WideChar; var d; n: int64);
procedure modd(const key: array of WideChar; const d; n: int64);
procedure deld(const key: array of WideChar);
procedure newd(const name: UnicodeString);
procedure opend(const name: UnicodeString);
procedure cleard(const name: UnicodeString);
procedure dropd(const name: UnicodeString);
procedure putd(const key: UnicodeString; const d; n: int64);
procedure getd(const key: UnicodeString; var d; n: int64);
procedure modd(const key: UnicodeString; const d; n: int64);
procedure deld(const key: UnicodeString);

implementation

uses SysUtils, kutf, mpage, mtree;

var
  curName: RawByteString;    { the open area }
  curId: longword = 0;       { its id, 0: none }
  warned: boolean = false;

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
    MErr := eNoName;
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

{ --- keys --- }

function BE32(x: longword): RawByteString;
begin
  SetLength(Result, 4);
  Result[1] := chr(x shr 24); Result[2] := chr((x shr 16) and 255);
  Result[3] := chr((x shr 8) and 255); Result[4] := chr(x and 255);
end;

function UnBE32(const v: RawByteString): longword;
begin
  Result := (longword(ord(v[1])) shl 24) or (longword(ord(v[2])) shl 16) or
    (longword(ord(v[3])) shl 8) or longword(ord(v[4]));
end;

function AreaKey(const name: RawByteString): RawByteString;
begin
  Result := #0 + name;
end;

function Prefix(id: longword): RawByteString;
begin
  Result := #1 + BE32(id);
end;

function GetArea(const name: RawByteString; out id: longword): boolean;
var v: RawByteString;
begin
  Result := TGet(AreaKey(name), v);
  if Result then id := UnBE32(v);
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

{ an area is open }
function Ready: boolean;
begin
  Result := curId <> 0;
  if not Result then MErr := eNoName;
end;

{ --- areas --- }

procedure newd(const name: TKey);
var id: longword; v: RawByteString;
begin
  if not WBegin then exit;
  try
    if GetArea(name.b, id) then MErr := eExists
    else begin
      id := 1;
      if TGet(#2, v) then id := UnBE32(v);
      TPut(#2, BE32(id + 1));
      TPut(AreaKey(name.b), BE32(id));
      MErr := 0;
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure opend(const name: TKey);
var id: longword; found: boolean;
begin
  if not RBegin then exit;
  try
    found := GetArea(name.b, id);
  finally
    TxnCommit;
  end;
  if not found then begin MErr := eNoName; exit; end;
  curName := name.b;
  curId := id;
  MErr := 0;
end;

{ an area cleared (drop: and deleted) }
procedure ClearArea(const name: TKey; drop: boolean);
var id: longword; k, v: RawByteString;
begin
  if not WBegin then exit;
  try
    if not GetArea(name.b, id) then MErr := eNoName
    else begin
      while TSeekKey(Prefix(id), skGE, k, v) and (Copy(k, 1, 5) = Prefix(id)) do TDel(k);
      if drop then begin
        TDel(AreaKey(name.b));
        if curName = name.b then curId := 0;
      end;
      MErr := 0;
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure cleard(const name: TKey);
begin ClearArea(name, false); end;
procedure dropd(const name: TKey);
begin ClearArea(name, true); end;

{ --- entries --- }

procedure Store(const k: TKey; p: pointer; n: int64; replace: boolean);
var v: RawByteString;
begin
  if not WBegin then exit;
  try
    if Ready then begin
      if not replace and TGet(Prefix(curId) + k.b, v) then MErr := eExists
      else begin
        TPut(Prefix(curId) + k.b, Datum(p, n));
        MErr := 0;
      end;
    end;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

procedure putd(const key: TKey; const d; n: int64);
begin Store(key, @d, n, false); end;
procedure modd(const key: TKey; const d; n: int64);
begin Store(key, @d, n, true); end;

procedure getd(const key: TKey; var d; n: int64);
var v: RawByteString;
begin
  if not RBegin then exit;
  try
    if Ready then begin
      if not TGet(Prefix(curId) + key.b, v) then MErr := eNoRec
      else begin
        if n > length(v) then n := length(v);
        if n > 0 then Move(v[1], d, n);
        MErr := 0;
      end;
    end;
  finally
    TxnCommit;
  end;
end;

procedure deld(const key: TKey);
begin
  if not WBegin then exit;
  try
    if Ready then
      if TDel(Prefix(curId) + key.b) then MErr := 0 else MErr := eNoRec;
    TxnCommit;
  except
    TxnAbort;
    raise;
  end;
end;

{ --- entries in key order --- }

function Step(mode: TSeek; const k: RawByteString; out fk, data: RawByteString): boolean;
var p, full: RawByteString;
begin
  Result := false;
  if not RBegin then exit;
  try
    if Ready then begin
      p := Prefix(curId);
      case mode of
        skFirst: Result := TSeekKey(p, skGE, full, data);
        skLast: Result := TSeekKey(Prefix(curId + 1), skLT, full, data);
      else Result := TSeekKey(p + k, mode, full, data);
      end;
      Result := Result and (Copy(full, 1, 5) = p);
      if Result then begin
        fk := Copy(full, 6, length(full) - 5);
        MErr := 0;
      end else
        MErr := eNoRec;
    end;
  finally
    TxnCommit;
  end;
end;

function firstd(out key, data: RawByteString): boolean;
begin Result := Step(skFirst, '', key, data); end;
function lastd(out key, data: RawByteString): boolean;
begin Result := Step(skLast, '', key, data); end;

function nextd(var key: RawByteString; out data: RawByteString): boolean;
var fk: RawByteString;
begin
  Result := Step(skGT, key, fk, data);
  if Result then key := fk;
end;

function prevd(var key: RawByteString; out data: RawByteString): boolean;
var fk: RawByteString;
begin
  Result := Step(skLT, key, fk, data);
  if Result then key := fk;
end;

{ --- names of a program --- }

procedure newd(const name: array of WideChar);
begin newd(MkKey(name)); end;
procedure opend(const name: array of WideChar);
begin opend(MkKey(name)); end;
procedure cleard(const name: array of WideChar);
begin cleard(MkKey(name)); end;
procedure dropd(const name: array of WideChar);
begin dropd(MkKey(name)); end;
procedure putd(const key: array of WideChar; const d; n: int64);
begin putd(MkKey(key), d, n); end;
procedure getd(const key: array of WideChar; var d; n: int64);
begin getd(MkKey(key), d, n); end;
procedure modd(const key: array of WideChar; const d; n: int64);
begin modd(MkKey(key), d, n); end;
procedure deld(const key: array of WideChar);
begin deld(MkKey(key)); end;

procedure newd(const name: UnicodeString);
begin newd(MkKey(name)); end;
procedure opend(const name: UnicodeString);
begin opend(MkKey(name)); end;
procedure cleard(const name: UnicodeString);
begin cleard(MkKey(name)); end;
procedure dropd(const name: UnicodeString);
begin dropd(MkKey(name)); end;
procedure putd(const key: UnicodeString; const d; n: int64);
begin putd(MkKey(key), d, n); end;
procedure getd(const key: UnicodeString; var d; n: int64);
begin getd(MkKey(key), d, n); end;
procedure modd(const key: UnicodeString; const d; n: int64);
begin modd(MkKey(key), d, n); end;
procedure deld(const key: UnicodeString);
begin deld(MkKey(key)); end;

end.
