{ crash safety: a child commits a transaction and is killed before the
  n-th write or sync of the commit (or tears the n-th page write in half),
  for every n.  The file must then hold exactly the state before or after
  the transaction.  Also: a damaged meta page or tree page. }
program crashtest;

{$mode objfpc}{$H+}

uses SysUtils, Classes, BaseUnix, mpage, mtree;

var
  path: string;
  backup: RawByteString;
  s0, s1: RawByteString;

procedure Die(const s: string);
begin
  writeln('FAIL: ', s);
  halt(1);
end;

{ the message without the file name }
function Msg(const s: string): string;
begin
  Result := s;
  if Pos(path + ': ', Result) = 1 then Delete(Result, 1, length(path) + 2);
end;

function Bytes(n: integer): RawByteString;
var i: integer;
begin
  SetLength(Result, n);
  for i := 1 to n do Result[i] := chr(random(256));
end;

function Dump: RawByteString;
var k, fk, fv: RawByteString;
begin
  Result := '';
  TxnBegin(false);
  k := '';
  if TSeekKey('', skFirst, fk, fv) then
    repeat
      Result := Result + fk + #0 + IntToStr(length(fv)) + #0 + fv + #1;
      k := fk;
    until not TSeekKey(k, skGT, fk, fv);
  TxnCommit;
end;

function ReadFile: RawByteString;
var f: TFileStream;
begin
  f := TFileStream.Create(path, fmOpenRead);
  try
    SetLength(Result, f.Size);
    if f.Size > 0 then f.ReadBuffer(Result[1], f.Size);
  finally
    f.Free;
  end;
end;

procedure WriteFile(const s: RawByteString);
var f: TFileStream;
begin
  f := TFileStream.Create(path, fmCreate);
  try
    if s <> '' then f.WriteBuffer(s[1], length(s));
  finally
    f.Free;
  end;
end;

procedure Poke(off: int64; x: byte);
var s: RawByteString;
begin
  s := ReadFile;
  s[off + 1] := chr(ord(s[off + 1]) xor x);
  WriteFile(s);
end;

{ the transaction under test: splits, merges, overflow values }
procedure Change;
var i: integer; k: RawByteString;
begin
  RandSeed := 99;
  for i := 1 to 150 do begin
    k := Format('key%.4d', [random(700)]);
    case random(4) of
      0: TDel(k);
      1: TPut(k, Bytes(1025 + random(3000)));
    else TPut(k, Bytes(random(200)));
    end;
  end;
end;

{ commit I/Os of Change with sync on or off }
function CountIO(sync: boolean): integer;
begin
  WriteFile(backup);
  PgOpen(path);
  PgSync := sync;
  TxnBegin(true);
  Change;
  MarsIoCount := 0;
  TxnCommit;
  Result := MarsIoCount;
  if Dump <> s1 then Die('the change is not deterministic');
  PgClose;
end;

procedure Run(tear, sync: boolean);
var total, n, olds, news, kills: integer; pid: TPid; st: cint; d: RawByteString;
    s, how: string;
begin
  total := CountIO(sync);
  olds := 0; news := 0; kills := 0;
  for n := 1 to total + 1 do begin
    WriteFile(backup);
    Flush(output);
    pid := fpFork;
    if pid = 0 then begin
      PgOpen(path);
      PgSync := sync;
      TxnBegin(true);
      Change;
      MarsIoCount := 0;
      if tear then MarsTearAt := n else MarsCrashAt := n;
      TxnCommit;
      halt(0);
    end;
    fpWaitPid(pid, @st, 0);
    if wifsignaled(st) then inc(kills)
    else if wexitstatus(st) <> 0 then Die(Format('child exit %d at n=%d', [wexitstatus(st), n]));
    PgOpen(path);
    s := TCheck;
    if s <> '' then Die(Format('n=%d: %s', [n, Msg(s)]));
    d := Dump;
    if d = s0 then inc(olds)
    else if d = s1 then inc(news)
    else Die(Format('n=%d: neither the old nor the new state', [n]));
    PgClose;
  end;
  if tear then how := 'torn page' else how := 'kill';
  writeln(Format('%-9s sync=%-5s commit I/Os=%d: %d killed, old state %d, new state %d',
    [how, BoolToStr(sync, true), total, kills, olds, news]));
end;

var
  i: integer;
  v: RawByteString;
  slot: integer;

begin
  path := 'crash.db';
  PgOpen(path);
  PgSync := false;
  RandSeed := 1;
  TxnBegin(true);
  for i := 0 to 599 do
    if i mod 10 = 0 then TPut(Format('key%.4d', [i]), Bytes(1025 + random(4000)))
    else TPut(Format('key%.4d', [i]), Bytes(random(300)));
  TxnCommit;
  if TCheck <> '' then Die('setup');
  writeln('setup: ', TStatEntries, ' entries, ', TStatPages, ' tree pages, ',
    TStatOver, ' overflow pages');
  s0 := Dump;
  PgClose;
  backup := ReadFile;

  PgOpen(path);
  TxnBegin(true);
  Change;
  TxnCommit;
  s1 := Dump;
  PgClose;

  Run(false, true);
  Run(false, false);
  Run(true, true);
  Run(true, false);

  { the newest meta page damaged: the previous commit is used }
  WriteFile(backup);
  PgOpen(path);
  TxnBegin(true); Change; TxnCommit;
  slot := PgTxnId and 1;
  PgClose;
  Poke(slot * PageSize + 100, $55);
  PgOpen(path);
  writeln('bad newest meta: previous commit used: ', Dump = s0, ', check: ', TCheck = '');
  { the next commit goes over the bad one }
  TxnBegin(true); Change; TxnCommit;
  writeln('next commit: new state: ', Dump = s1, ', check: ', TCheck = '');
  PgClose;

  { a damaged tree page is reported, never used }
  PgOpen(path);
  TxnBegin(false); i := TxRoot; TxnCommit;
  PgClose;
  Poke(int64(i) * PageSize + PageSize - 10, $01);
  PgOpen(path);
  writeln('bad root page: check: ', Msg(TCheck));
  try
    TxnBegin(false);
    try
      TGet('key0001', v);
      writeln('bad root page: get: no error');
    finally
      TxnCommit;
    end;
  except
    on e: EMars do writeln('bad root page: get: ', Msg(e.Message));
  end;
  PgClose;

  { both meta pages damaged }
  WriteFile(backup);
  Poke(100, $55);
  Poke(PageSize + 100, $55);
  try
    PgOpen(path);
    writeln('both metas bad: opened');
  except
    on e: EMars do writeln('both metas bad: ', Msg(e.Message));
  end;
end.
