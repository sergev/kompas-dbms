{ what apitest left, seen by a new process }
program reopen;

{$mode objfpc}{$H+}{$codepage utf8}

uses SysUtils, mars;

type
  TV = array[0..167] of int64;
  PV = ^TV;

var
  v: PV;
  e: ^int64;

function Hex(x: int64): string;
var b: RawByteString; i, n: integer;
begin
  SetLength(b, 8);
  Move(x, b[1], 8);
  n := 8;
  while (n > 0) and (b[n] = #0) do dec(n);
  Result := '';
  for i := 1 to n do Result := Result + IntToHex(ord(b[i]), 2);
  if Result = '' then Result := '-';
end;

procedure Dump(const area: string);
var d: array[0..3] of int64;
begin
  opend(NameKey(area));
  writeln('-- ', area, ' err=', e^);
  if e^ <> 0 then exit;
  v^[3] := 1; pasbd;
  repeat
    v^[3] := 4; pasbd;
    if e^ <> 0 then break;
    write('  ', Hex(v^[31]), ' len=', v^[39], ' h=', v^[29]);
    FillChar(d, sizeof(d), 0);
    v^[11] := PtrInt(@d); v^[13] := 4;
    v^[3] := 18; pasbd;
    writeln(' ', d[0], ' ', d[1], ' ', d[2]);
  until false;
end;

begin
  v := PV(MarsVec);
  e := MarsErr;
  Dump('AREA1');
  Dump('AREA2');
  Dump('H');
  Dump('ЖУРНАЛ');
end.
