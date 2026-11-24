{ transactions: nesting, abort, commit visibility, locking, reopen }
program txntest;

{$mode objfpc}{$H+}

uses SysUtils, BaseUnix, mpage, mtree;

var
  path: string;

function FileSize: int64;
var info: Stat;
begin
  fpStat(path, info);
  Result := info.st_size;
end;

procedure Die(const s: string);
begin
  writeln('FAIL: ', s);
  halt(1);
end;

function Dump: string;
var k, fk, fv: RawByteString;
begin
  Result := '';
  TxnBegin(false);
  k := '';
  if TSeekKey('', skFirst, fk, fv) then
    repeat
      if length(fv) > 8 then Result := Result + fk + '=<' + IntToStr(length(fv)) + '> '
      else Result := Result + fk + '=' + fv + ' ';
      k := fk;
    until not TSeekKey(k, skGT, fk, fv);
  TxnCommit;
  Result := Trim(Result);
  if Result = '' then Result := '(empty)';
end;

procedure Check(const where: string);
var s: string;
begin
  s := TCheck;
  if s <> '' then Die(where + ': ' + s);
end;

procedure Show(const what: string);
begin
  Check(what);
  writeln(what, ': ', Dump);
end;

{ many changes: splits, overflow values, deletes }
procedure Churn(tag: char);
var i: integer;
begin
  for i := 1 to 400 do TPut(tag + Format('%.4d', [i]), StringOfChar(tag, i * 7));
  for i := 1 to 400 do if i mod 3 <> 0 then TDel(tag + Format('%.4d', [i]));
  TDel('a');
end;

var
  t0: qword;
  pid: TPid;
  st: cint;
  ok: boolean;
  v: RawByteString;
  n: TPgno;
  t: qword;
  sz: int64;

begin
  path := 'txn.db';
  PgOpen(path);

  TxnBegin(true);
  TPut('a', '1'); TPut('b', '2');
  TxnCommit;
  Show('commit');

  { nested: only the outermost commit writes }
  t := PgTxnId;
  TxnBegin(true);
  TPut('c', '3');
  TxnBegin(true);
  TPut('d', '4');
  TxnCommit;
  writeln('inner commit wrote: ', PgTxnId <> t, ', depth ', TxnDepth);
  TxnCommit;
  writeln('outer commit wrote: ', PgTxnId <> t, ', depth ', TxnDepth);
  Show('nested');

  { abort rolls back the whole transaction; outer levels go on }
  TxnBegin(true);
  TPut('e', '5');
  Churn('x');
  TxnBegin(true);
  TPut('f', '6');
  TxnAbort;
  writeln('after abort: depth ', TxnDepth, ', e: ', TGet('e', v), ', f: ', TGet('f', v),
    ', a: ', TGet('a', v));
  TPut('g', '7');
  TxnCommit;
  Show('abort, then g');

  { a top-level abort writes nothing }
  n := PgCount;
  t := PgTxnId;
  sz := FileSize;
  TxnBegin(true);
  Churn('y');
  TxnAbort;
  writeln('top-level abort: depth ', TxnDepth, ', txnid kept ', PgTxnId = t,
    ', pages kept ', PgCount = n, ', file kept ', FileSize = sz);
  Show('top-level abort');

  { an empty write transaction writes nothing }
  t := PgTxnId;
  TxnBegin(true);
  TxnCommit;
  TxnBegin(true);
  TGet('a', v);
  TxnCommit;
  writeln('empty transactions wrote: ', PgTxnId <> t);

  { no writes in a read transaction }
  TxnBegin(false);
  try
    TPut('z', '9');
    writeln('write in a read transaction: allowed');
  except
    on e: EMars do writeln('write in a read transaction: refused');
  end;
  try
    TxnBegin(true);
    writeln('nested write in a read transaction: allowed');
  except
    on e: EMars do writeln('nested write in a read transaction: refused');
  end;
  TxnCommit;

  { a reader waits for the writer's commit, and sees all of it }
  TxnBegin(true);
  Churn('w');
  TPut('h', '8');
  Flush(output);
  pid := fpFork;
  if pid = 0 then begin
    t0 := GetTickCount64;
    PgAfterFork;
    PgOpen(path);
    TxnBegin(false);
    ok := TGet('h', v) and (v = '8') and TGet('w0399', v) and not TGet('w0400', v);
    TxnCommit;
    if not ok then halt(2);
    if GetTickCount64 - t0 < 250 then halt(3);
    halt(0);
  end;
  Sleep(400);
  TxnCommit;
  fpWaitPid(pid, @st, 0);
  writeln('reader blocked by the writer, then saw the whole commit: exit ', wexitstatus(st));

  { a writer waits for a reader }
  TxnBegin(false);
  Flush(output);
  pid := fpFork;
  if pid = 0 then begin
    t0 := GetTickCount64;
    PgAfterFork;
    PgOpen(path);
    TxnBegin(true);
    TPut('i', '9');
    TxnCommit;
    if GetTickCount64 - t0 < 250 then halt(3);
    halt(0);
  end;
  Sleep(400);
  writeln('i before the reader ends: ', TGet('i', v));
  TxnCommit;
  fpWaitPid(pid, @st, 0);
  writeln('writer blocked by the reader: exit ', wexitstatus(st));
  TxnBegin(false);
  writeln('i seen in a new transaction: ', TGet('i', v), ' ', v);
  TxnCommit;

  { another process's commit drops our cache }
  TxnBegin(false); TGet('a', v); TxnCommit;
  Flush(output);
  pid := fpFork;
  if pid = 0 then begin
    PgAfterFork;
    PgOpen(path);
    TxnBegin(true);
    TPut('a', 'changed');
    TxnCommit;
    halt(0);
  end;
  fpWaitPid(pid, @st, 0);
  TxnBegin(false); TGet('a', v); TxnCommit;
  writeln('a after another process changed it: ', v);

  { reopen }
  v := Dump;
  PgClose;
  PgOpen(path);
  writeln('reopen gives the same contents: ', Dump = v);
  Check('reopen');
  writeln('entries ', TStatEntries, ', free pages ', TStatFree);
end.
