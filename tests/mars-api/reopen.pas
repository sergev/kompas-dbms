{ what apitest left, seen by a new process }
program reopen;

{$mode objfpc}{$H+}{$codepage utf8}

uses SysUtils, mars;

function Hex(const s: RawByteString): string;
var i: integer;
begin
  Result := '';
  for i := 1 to length(s) do Result := Result + IntToHex(ord(s[i]), 2);
  if Result = '' then Result := '-';
end;

procedure Dump(const area: string);
var k, d: RawByteString; w: array[0..1] of int64; ok: boolean;
begin
  opend(NameKey(area));
  writeln('-- ', area, ' err=', MErr);
  if MErr <> 0 then exit;
  ok := firstd(k, d);
  while ok do begin
    FillChar(w, sizeof(w), 0);
    if length(d) > 0 then
      if length(d) < 16 then Move(d[1], w, length(d)) else Move(d[1], w, 16);
    writeln('  ', Hex(k), ' len=', length(d), ' ', w[0], ' ', w[1]);
    ok := nextd(k, d);
  end;
end;

begin
  Dump('AREA1');
  Dump('AREA2');
  Dump('CL');
  Dump('ЖУРНАЛ');
  Dump('NONE');
end.
