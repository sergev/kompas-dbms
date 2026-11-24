{ DML statements killed at every write of their commit: afterwards the
  chains are sound (KCheck) and the data are exactly those before or
  after the statement.  CD schema of tests/engine. }
program kdbcrash;

{$mode objfpc}{$H+}

uses SysUtils, Classes, BaseUnix, kdb, mpage, mars;

var
  path: string;
  backup: RawByteString;

function RN(const n: string): integer; begin Result := KRecNo(n); end;
function SN(const n: string): integer; begin Result := KSetNo(n); end;

procedure Die(const s: string);
begin
  writeln('FAIL: ', s);
  halt(1);
end;

procedure Store(const rec: string; const v: array of string);
var i, rt: integer;
begin
  rt := RN(rec);
  KBEGINPUT(rt);
  for i := 0 to high(v) do KPutText(i + 1, v[i]);
  KSTORE(rt);
end;

function Show: string;
var i: integer;
begin
  KBEGINGET(0);
  Result := '';
  for i := 1 to KFieldCount(KBufType) do Result := Result + ' ' + Trim(KFieldText(i));
end;

function Walk(const setn: string): string;
var s: integer;
begin
  s := SN(setn);
  KFINDFIRST(s);
  Result := '';
  while KSTAT = kOk do begin
    Result := Result + '[' + Show + ']';
    KFINDNEXT(s);
  end;
end;

{ everything reachable, as text }
function Dump: string;
var arts, discs: TStringList; i, n: integer; s: string;
begin
  arts := TStringList.Create;
  discs := TStringList.Create;
  Result := 'artists ' + Walk('SY-АРТ') + #10 + 'discs ' + Walk('SY-ДИС') + #10;
  KFINDFIRST(SN('SY-АРТ'));
  while KSTAT = kOk do begin KBEGINGET(0); arts.Add(Trim(KFieldText(1))); KFINDNEXT(SN('SY-АРТ')); end;
  KFINDFIRST(SN('SY-ДИС'));
  while KSTAT = kOk do begin KBEGINGET(0); discs.Add(Trim(KFieldText(1))); KFINDNEXT(SN('SY-ДИС')); end;
  for i := 0 to arts.Count - 1 do begin
    KFindKeyText(SN('SY-АРТ'), arts[i]);
    Result := Result + arts[i] + ': ' + Walk('АР-ДИС') + #10;
  end;
  for i := 0 to discs.Count - 1 do begin
    KFINDKEY(SN('SY-ДИС'), StrToInt64(discs[i]));
    Result := Result + discs[i] + ': ' + Walk('ДИ-ТРЕ') + #10;
  end;
  n := 0;
  KFINDFIRSTREC(RN('ТРЕК'));
  while KSTAT = kOk do begin inc(n); KFINDNEXTREC(RN('ТРЕК')); end;
  Result := Result + 'tracks ' + IntToStr(n);
  s := KCheck;
  if s <> '' then Die('check: ' + s);
  arts.Free;
  discs.Free;
end;

function ReadFile: RawByteString;
var f: TFileStream;
begin
  f := TFileStream.Create(path, fmOpenRead);
  try
    SetLength(Result, f.Size);
    f.ReadBuffer(Result[1], f.Size);
  finally
    f.Free;
  end;
end;

procedure WriteFile(const s: RawByteString);
var f: TFileStream;
begin
  f := TFileStream.Create(path, fmCreate);
  try
    f.WriteBuffer(s[1], length(s));
  finally
    f.Free;
  end;
end;

procedure Setup;
var a, d, t: integer; name: string;
begin
  for a := 1 to 3 do begin
    Store('АРТИСТ', ['АРТИСТ НОМЕР ' + IntToStr(a), 'РОССИЯ']);
    for d := 1 to 12 do begin
      name := Format('ДИСК %d АРТИСТА %d С ДЛИННЫМ НАЗВАНИЕМ', [d, a]);
      Store('ДИСК', [IntToStr(1000 + a * 100 + d), name, IntToStr(1980 + d), '10.00']);
      for t := 1 to 6 do
        Store('ТРЕК', [IntToStr(t), Format('ПЕСНЯ %d С ДИСКА %d-%d', [t, a, d]), '200']);
    end;
  end;
end;

{ one statement, with the finds that make its currency }
procedure Stmt(i: integer);
begin
  case i of
    0: begin
         KFindKeyText(SN('SY-АРТ'), 'АРТИСТ НОМЕР 2');
         Store('ДИСК', ['1250', 'НОВЫЙ ДИСК', '1985', '9.00']);
       end;
    1: begin
         KFINDKEY(SN('SY-ДИС'), int64(1305));
         Store('ТРЕК', ['9', 'НОВАЯ ПЕСНЯ', '199']);
       end;
    2: begin
         KFINDKEY(SN('SY-ДИС'), int64(1203));
         KBEGINGET(RN('ДИСК')); KPUTF(1, int64(999)); KMODIFY(0);
       end;
    3: begin
         KFINDKEY(SN('SY-ДИС'), int64(1107));
         KDISCONNECT(SN('АР-ДИС'));
       end;
    4: begin
         KFINDKEY(SN('SY-ДИС'), int64(1210));
         KERASEMEMBERS(SN('ДИ-ТРЕ'));
       end;
    5: begin
         KFINDKEY(SN('SY-ДИС'), int64(1112));
         KERASE(0);          { its tracks are disconnected }
       end;
  end;
  if KSTAT <> kOk then Die(Format('statement %d: status %d', [i, KSTAT]));
end;

const
  Names: array[0..5] of string = ('store disc', 'store track', 'modify key',
    'disconnect', 'erase members', 'erase disc');

var
  i, n, total, olds, news: integer;
  pid: TPid;
  st: cint;
  s0, s1, d: string;

begin
  if not KSchemaOk then Die('no schema');
  path := MarsPath;
  Setup;
  s0 := Dump;
  writeln('setup: ', KRecCount, ' record types, check ok');
  PgClose;
  backup := ReadFile;
  for i := 0 to 5 do begin
    { the statement without a crash: its I/Os and the new state }
    WriteFile(backup);
    MarsIoCount := 0;
    Stmt(i);
    total := MarsIoCount;
    s1 := Dump;
    if s1 = s0 then Die(Names[i] + ': changed nothing');
    PgClose;
    olds := 0; news := 0;
    for n := 1 to total + 1 do begin
      WriteFile(backup);
      Flush(output);
      pid := fpFork;
      if pid = 0 then begin
        MarsIoCount := 0;
        MarsCrashAt := n;
        Stmt(i);
        halt(0);
      end;
      fpWaitPid(pid, @st, 0);
      if (n <= total) <> wifsignaled(st) then Die(Format('%s: n=%d: not killed', [Names[i], n]));
      d := Dump;
      if d = s0 then inc(olds)
      else if d = s1 then inc(news)
      else Die(Format('%s: n=%d: neither the old nor the new state', [Names[i], n]));
      PgClose;
    end;
    writeln(Format('%-14s commit I/Os=%d: old state %d, new state %d, chains sound',
      [Names[i], total, olds, news]));
  end;
end.
