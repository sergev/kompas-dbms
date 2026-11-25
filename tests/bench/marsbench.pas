{ MARS timing: N putd, N random getd, a scan with nextd.
  Usage: marsbench N [batch]   (batch: all putd in one transaction) }
program marsbench;

{$mode objfpc}{$H+}

uses SysUtils, DateUtils, mars;

var
  n, i, k, cnt: integer;
  d: array[0..9] of int64;
  t: TDateTime;
  batch, ok: boolean;
  ks, ds: RawByteString;

function Key(i: integer): TKey;
begin
  Result := ByteKey(Format('%.8d', [i]));
end;

procedure Lap(const what: string);
begin
  writeln(Format('%-28s %8.2f s', [what, MilliSecondsBetween(Now, t) / 1000]));
  t := Now;
end;

begin
  n := StrToIntDef(ParamStr(1), 10000);
  batch := ParamStr(2) = 'batch';
  MarsCreate := true;
  newd(NameKey('BENCH'));
  opend(NameKey('BENCH'));
  for i := 0 to 9 do d[i] := i;
  t := Now;
  if batch then MarsBegin;
  for i := 1 to n do begin
    k := (int64(i) * 7919) mod n;
    d[0] := k;
    putd(Key(k), d, sizeof(d));
  end;
  if batch then MarsCommit;
  Lap(Format('%d putd', [n]));
  RandSeed := 1;
  for i := 1 to n do begin
    k := random(n);
    getd(Key(k), d, sizeof(d));
    if d[0] <> k then begin writeln('FAIL getd ', k); halt(1); end;
  end;
  Lap(Format('%d random getd', [n]));
  cnt := 0;
  ok := firstd(ks, ds);
  while ok do begin
    inc(cnt);
    ok := nextd(ks, ds);
  end;
  Lap(Format('scan of %d', [cnt]));
end.
