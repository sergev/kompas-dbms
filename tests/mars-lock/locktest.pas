{ several processes on one file: 4 writers move units between 10
  accounts and count their transactions, 2 readers check in every read
  transaction that the accounts sum to 1000 and the counters agree }
program locktest;

{$mode objfpc}{$H+}

uses SysUtils, BaseUnix, mpage, mtree;

const
  Writers = 4;
  Readers = 2;
  Rounds = 1500;

var
  path: string;

function GetI(const k: RawByteString): int64;
var v: RawByteString;
begin
  if not TGet(k, v) then exit(0);
  Result := StrToInt64(v);
end;

procedure PutI(const k: RawByteString; x: int64);
begin
  TPut(k, IntToStr(x));
end;

procedure Writer(w: integer);
var i, a, b: integer; x: int64;
begin
  RandSeed := w;
  for i := 1 to Rounds do begin
    TxnBegin(true);
    a := random(10); b := random(10);
    x := random(20);
    PutI('acct' + IntToStr(a), GetI('acct' + IntToStr(a)) - x);
    PutI('acct' + IntToStr(b), GetI('acct' + IntToStr(b)) + x);
    PutI('count' + IntToStr(w), GetI('count' + IntToStr(w)) + 1);
    PutI('total', GetI('total') + 1);
    { some bulk, so pages split and get freed }
    TPut(Format('w%d-%.5d', [w, i]), StringOfChar('x', random(1500)));
    if i > 50 then TDel(Format('w%d-%.5d', [w, i - 50]));
    TxnCommit;
  end;
end;

{ number of transactions seen broken }
function Reader: integer;
var i, j: integer; sum, cnt: int64; t0: qword;
begin
  Result := 0;
  t0 := GetTickCount64;
  i := 0;
  repeat
    TxnBegin(false);
    sum := 0;
    for j := 0 to 9 do inc(sum, GetI('acct' + IntToStr(j)));
    cnt := 0;
    for j := 1 to Writers do inc(cnt, GetI('count' + IntToStr(j)));
    if (sum <> 1000) or (cnt <> GetI('total')) then inc(Result);
    j := GetI('total');
    TxnCommit;
    inc(i);
  until (j = Writers * Rounds) or (GetTickCount64 - t0 > 60000);
end;

var
  pids: array[1..Writers + Readers] of TPid;
  i, bad, st: cint;
  s: string;
  ok: boolean;

begin
  path := 'lock.db';
  PgOpen(path);
  TxnBegin(true);
  PutI('acct0', 1000);
  TxnCommit;
  PgClose;
  Flush(output);
  for i := 1 to Writers + Readers do begin
    pids[i] := fpFork;
    if pids[i] = 0 then begin
      PgOpen(path);
      PgSync := false;
      if i <= Writers then begin Writer(i); halt(0); end;
      halt(Reader);
    end;
  end;
  bad := 0;
  ok := true;
  for i := 1 to Writers + Readers do begin
    fpWaitPid(pids[i], @st, 0);
    if not wifexited(st) then ok := false
    else if i > Writers then inc(bad, wexitstatus(st))
    else if wexitstatus(st) <> 0 then ok := false;
  end;
  writeln('all processes ended normally: ', ok);
  writeln('broken read transactions: ', bad);
  PgOpen(path);
  TxnBegin(false);
  s := '';
  for i := 1 to Writers do s := s + ' ' + IntToStr(GetI('count' + IntToStr(i)));
  writeln('counters:', s, ', total ', GetI('total'));
  bad := 0;
  for i := 0 to 9 do inc(bad, GetI('acct' + IntToStr(i)));
  writeln('accounts sum to ', bad);
  TxnCommit;
  s := TCheck;
  if s = '' then s := 'ok';
  writeln('check: ', s, ', entries ', TStatEntries);
end.
