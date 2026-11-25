{ MARS API: areas, entries, order, errors }
program apitest;

{$mode objfpc}{$H+}{$codepage utf8}

uses SysUtils, mars;

function Hex(const s: RawByteString): string;
var i: integer;
begin
  Result := '';
  for i := 1 to length(s) do Result := Result + IntToHex(ord(s[i]), 2);
  if Result = '' then Result := '-';
end;

procedure Put(const k: RawByteString; a, b: int64);
var d: array[0..1] of int64;
begin
  d[0] := a; d[1] := b;
  putd(ByteKey(k), d, 16);
  writeln('putd ', Hex(k), ' ', a, ' ', b, ': err=', MErr);
end;

procedure Get(const k: RawByteString; n: int64);
var d: array[0..3] of int64;
begin
  FillChar(d, sizeof(d), 0);
  getd(ByteKey(k), d, n);
  writeln('getd ', Hex(k), ' ', n, ': err=', MErr, ' ', d[0], ' ', d[1]);
end;

function Val(const d: RawByteString): string;
var w: array[0..1] of int64;
begin
  FillChar(w, sizeof(w), 0);
  if length(d) > 0 then
    if length(d) < 16 then Move(d[1], w, length(d)) else Move(d[1], w, 16);
  Result := Format('len=%d %d %d', [length(d), w[0], w[1]]);
end;

procedure Scan(const what: string);
var k, d: RawByteString; ok: boolean;
begin
  writeln('-- scan ', what);
  ok := firstd(k, d);
  while ok do begin
    writeln('  next ', Hex(k), ' ', Val(d));
    ok := nextd(k, d);
  end;
  writeln('  end err=', MErr);
  ok := lastd(k, d);
  while ok do begin
    writeln('  prev ', Hex(k), ' ', Val(d));
    ok := prevd(k, d);
  end;
  writeln('  end err=', MErr);
end;

var
  d: array[0..1] of int64;
  k, v: RawByteString;
  name: UnicodeString;
  w: array[0..5] of WideChar;

begin
  MarsCreate := true;

  writeln('== areas');
  newd(NameKey('AREA1')); writeln('newd AREA1: err=', MErr);
  newd(NameKey('AREA1')); writeln('newd AREA1 again: err=', MErr);
  newd(NameKey('AREA2  ')); writeln('newd AREA2 blanks: err=', MErr);
  getd(ByteKey('A'), d, 16); writeln('getd, no area open: err=', MErr);
  opend(NameKey('NONE')); writeln('opend NONE: err=', MErr);
  opend(NameKey('AREA2')); writeln('opend AREA2: err=', MErr);
  opend(NameKey('AREA1')); writeln('opend AREA1: err=', MErr);

  writeln('== put/get');
  Put('B', 2, 20);
  Put('A', 1, 10);
  Put('C  ', 3, 30);
  Put('Ж', 4, 40);
  Put(#0#1, 5, 50);
  Put('', 6, 60);
  Put('AB', 7, 70);
  Put('B', 9, 90);
  Get('B', 16);
  Get('C', 16);
  Get('Ж', 16);
  Get(#0#1, 16);
  Get('', 16);
  Get('AB', 8);
  Get('Z', 16);
  d[0] := 11; d[1] := 110;
  modd(ByteKey('A'), d, 16); writeln('modd A: err=', MErr);
  modd(ByteKey('D'), d, 8); writeln('modd D (new): err=', MErr);
  Get('A', 16);
  Get('D', 16);
  putd(ByteKey('E'), d, 3); writeln('putd E 3 bytes: err=', MErr);
  Get('E', 16);
  deld(ByteKey('AB')); writeln('deld AB: err=', MErr);
  deld(ByteKey('AB')); writeln('deld AB again: err=', MErr);
  Scan('AREA1');

  writeln('== next, prev from a key not there');
  k := 'BB'; writeln('next BB: ', nextd(k, v), ' ', Hex(k), ' ', Val(v));
  k := 'BB'; writeln('prev BB: ', prevd(k, v), ' ', Hex(k), ' ', Val(v));
  k := 'Z'; writeln('next Z: ', nextd(k, v), ' ', Hex(k), ' err=', MErr);
  k := ''; writeln('prev -: ', prevd(k, v), ' ', Hex(k), ' err=', MErr);
  opend(NameKey('AREA2'));
  writeln('first of empty: ', firstd(k, v), ' err=', MErr);
  writeln('last of empty: ', lastd(k, v), ' err=', MErr);

  writeln('== names');
  name := 'ЖУРНАЛ';
  newd(name); writeln('newd unicode: err=', MErr);
  w[0] := #$0416; w[1] := #$0423; w[2] := #$0420; w[3] := #$041D; w[4] := #$0410; w[5] := #$041B;
  opend(w); writeln('opend widechar: err=', MErr);
  putd(w, d, 16); writeln('putd widechar key: err=', MErr);
  getd(name, d, 16); writeln('getd unicode key: err=', MErr, ' ', d[0], ' ', d[1]);
  deld(name); writeln('deld unicode key: err=', MErr);

  writeln('== clear, drop');
  newd(NameKey('CL')); opend(NameKey('CL'));
  Put('A', 1, 1); Put('B', 2, 2);
  cleard(NameKey('CL')); writeln('cleard CL: err=', MErr);
  Get('A', 16);
  Scan('CL cleared');
  Put('C', 3, 3);
  dropd(NameKey('CL')); writeln('dropd CL: err=', MErr);
  Get('C', 16);
  writeln('first: ', firstd(k, v), ' err=', MErr);
  opend(NameKey('CL')); writeln('opend CL: err=', MErr);
  cleard(NameKey('CL')); writeln('cleard CL: err=', MErr);
  dropd(NameKey('CL')); writeln('dropd CL: err=', MErr);
  newd(NameKey('CL')); writeln('newd CL: err=', MErr);
  opend(NameKey('CL'));
  Get('C', 16);
  Put('C', 4, 4);
  Scan('CL new');
  opend(NameKey('AREA1'));
  Scan('AREA1 kept');
end.
