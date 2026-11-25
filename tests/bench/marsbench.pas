{ MARS timing: N putd, N random getd, a scan with pasbd NEXT.
  Usage: marsbench N [batch]   (batch: all putd in one transaction)
  Build against the new MARS with -dNEWMARS. }
program marsbench;

{$mode objfpc}{$H+}

uses SysUtils, DateUtils, mars;

type
  TV = array[0..167] of int64;

var
  n, i, k, cnt: integer;
  d: array[0..9] of int64;
  t: TDateTime;
  v: ^TV;
  batch: boolean;

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
  v := MarsVec;
  {$ifdef NEWMARS} MarsCreate := true; {$endif}
  newd(NameKey('BENCH'));
  opend(NameKey('BENCH'));
  for i := 0 to 9 do d[i] := i;
  t := Now;
  {$ifdef NEWMARS} if batch then MarsBegin; {$endif}
  for i := 1 to n do begin
    k := (int64(i) * 7919) mod n;
    d[0] := k;
    putd(Key(k), d, sizeof(d));
  end;
  {$ifdef NEWMARS} if batch then MarsCommit; {$endif}
  Lap(Format('%d putd', [n]));
  RandSeed := 1;
  for i := 1 to n do begin
    k := random(n);
    getd(Key(k), d, sizeof(d));
    if d[0] <> k then begin writeln('FAIL getd ', k); halt(1); end;
  end;
  Lap(Format('%d random getd', [n]));
  v^[3] := 1; pasbd;
  cnt := 0;
  repeat
    v^[3] := 4; pasbd;
    if MarsErr <> nil then ;
    if PInt64(MarsErr)^ <> 0 then break;
    inc(cnt);
  until false;
  Lap(Format('scan of %d', [cnt]));
end.
