{ MARS API and pasbd microprograms: the behaviour any store must keep }
program apitest;

{$mode objfpc}{$H+}{$codepage utf8}

uses SysUtils, mars;

type
  TV = array[0..167] of int64;
  PV = ^TV;

const
  oBEGIN = 1; oLAST = 2; oPREV = 3; oNEXT = 4; oFIND = 9; oMATCH = 12; oNOMATCH = 13;
  oUPDATE = 16; oALLOC = 17; oGET = 18; oFREE = 19; oADDKEY = 22; oDELKEY = 23;
  oSTOP = 32; oASSIGN = 43; oSTALLOC = 44;

var
  v: PV;
  e: ^int64;
  buf: array[0..15] of int64;

function Code(const ops: array of int64): int64;
var i: integer;
begin
  Result := 0;
  for i := high(ops) downto 0 do Result := (Result shl 6) or ops[i];
end;

function Hex(const s: RawByteString): string;
var i: integer;
begin
  Result := '';
  for i := 1 to length(s) do Result := Result + IntToHex(ord(s[i]), 2);
  if Result = '' then Result := '-';
end;

{ vec[31]: first 8 bytes of the current key }
function CurKey: string;
var b: RawByteString; n: integer;
begin
  SetLength(b, 8);
  Move(v^[31], b[1], 8);
  n := 8;
  while (n > 0) and (b[n] = #0) do dec(n);
  SetLength(b, n);
  Result := Hex(b);
end;

procedure SetKey(const s: RawByteString);
begin
  v^[8] := 0;
  if s <> '' then Move(s[1], v^[8], length(s));
end;

procedure Show(const what: string);
begin
  writeln(what, ': err=', e^, ' key=', CurKey, ' len=', v^[39], ' h=', v^[29]);
end;

procedure Run(const what: string; const ops: array of int64);
begin
  v^[3] := Code(ops);
  pasbd;
  Show(what);
end;

procedure Put(const k: RawByteString; a, b: int64);
var d: array[0..1] of int64;
begin
  d[0] := a; d[1] := b;
  putd(ByteKey(k), d, 16);
  writeln('putd ', Hex(k), ' ', a, ' ', b, ': err=', e^);
end;

procedure Get(const k: RawByteString; n: int64);
var d: array[0..3] of int64;
begin
  FillChar(d, sizeof(d), 0);
  getd(ByteKey(k), d, n);
  writeln('getd ', Hex(k), ' ', n, ': err=', e^, ' ', d[0], ' ', d[1], ' len=', v^[39]);
end;

procedure Scan(const what: string);
begin
  writeln('-- scan ', what);
  v^[3] := Code([oBEGIN]); pasbd;
  repeat
    v^[3] := Code([oNEXT]); pasbd;
    if e^ = 0 then Show('  next');
  until e^ <> 0;
  writeln('  end err=', e^);
  v^[3] := Code([oLAST]); pasbd;
  Show('  last');
  repeat
    v^[3] := Code([oPREV]); pasbd;
    Show('  prev');
  until e^ <> 0;
end;

var
  i: integer;
  d: array[0..1] of int64;
  name: UnicodeString;
  w: array[0..5] of WideChar;

begin
  v := PV(MarsVec);
  e := MarsErr;
  MarsCreate := true;

  writeln('== areas');
  newd(NameKey('AREA1')); writeln('newd AREA1: err=', e^);
  newd(NameKey('AREA1')); writeln('newd AREA1 again: err=', e^);
  newd(NameKey('AREA2  ')); writeln('newd AREA2 blanks: err=', e^);
  opend(NameKey('NONE')); writeln('opend NONE: err=', e^);
  opend(NameKey('AREA2')); writeln('opend AREA2: err=', e^);
  opend(NameKey('AREA1')); writeln('opend AREA1: err=', e^);

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
  modd(ByteKey('A'), d, 16); writeln('modd A: err=', e^);
  modd(ByteKey('D'), d, 8); writeln('modd D (new): err=', e^);
  Get('A', 16);
  Get('D', 16);
  putd(ByteKey('E'), d, 3); writeln('putd E 3 bytes: err=', e^);
  Get('E', 16);
  deld(ByteKey('AB')); writeln('deld AB: err=', e^);
  deld(ByteKey('AB')); writeln('deld AB again: err=', e^);
  Scan('AREA1');

  writeln('== find, match');
  SetKey('B'); Run('find B', [oFIND]);
  SetKey('BB'); Run('find BB', [oFIND]);
  SetKey(#0); Run('find #0', [oFIND]);
  SetKey('Z'); Run('find Z', [oFIND]);
  SetKey('B'); Run('find B match', [oFIND, oMATCH]);
  SetKey('BB'); Run('find BB match', [oFIND, oMATCH]);
  SetKey('B'); Run('find B nomatch', [oFIND, oNOMATCH]);
  SetKey('BB'); Run('find BB nomatch', [oFIND, oNOMATCH]);

  writeln('== get, update, alloc, addkey, delkey');
  for i := 0 to high(buf) do buf[i] := 0;
  v^[11] := PtrInt(@buf); v^[13] := 2;
  SetKey('C'); Run('find C get', [oFIND, oGET]);
  writeln('  buf ', buf[0], ' ', buf[1]);
  buf[0] := 33; buf[1] := 330; buf[2] := 3300; v^[13] := 3;
  SetKey('C'); Run('find C update', [oFIND, oUPDATE]);
  Get('C', 16);
  writeln('  len ', v^[39]);
  buf[0] := 55; buf[1] := 550; v^[13] := 2;
  SetKey('F'); Run('find F nomatch? alloc addkey', [oFIND, oNOMATCH, 0, oALLOC, oADDKEY, 0, oGET]);
  Get('F', 16);
  buf[0] := 66;
  SetKey('F'); Run('find F nomatch? alloc addkey (exists)', [oFIND, oNOMATCH, 0, oALLOC, oADDKEY, 0]);
  Get('F', 16);
  SetKey('F'); Run('find F match? get', [oFIND, oMATCH, 0, oGET, 0, 0]);
  SetKey('G'); Run('find G match? get (absent)', [oFIND, oMATCH, 0, oGET, 0, 0, oNEXT]);
  buf[0] := 77;
  SetKey('F'); Run('alloc addkey F (exists)', [oALLOC, oADDKEY, oNEXT]);
  Get('F', 16);
  SetKey('F'); Run('find F delkey', [oFIND, oDELKEY]);
  Get('F', 16);
  SetKey('F'); Run('find F free stop next', [oFIND, oFREE, oSTOP, oNEXT]);
  Run('bad op 5', [5]);
  Run('begin prev', [oBEGIN, oPREV]);
  Run('last next', [oLAST, oNEXT]);

  writeln('== handles');
  newd(NameKey('H')); opend(NameKey('H'));
  Put('K1', 1, 0); Put('K2', 2, 0); Put('K0', 0, 0);
  SetKey('K0'); Run('find K0', [oFIND]);
  SetKey('K1'); Run('find K1', [oFIND]);
  SetKey('K2'); Run('find K2', [oFIND]);
  deld(ByteKey('K2')); Put('K2', 2, 0);
  SetKey('K2'); Run('find K2 re-added', [oFIND]);
  modd(ByteKey('K1'), d, 16);
  SetKey('K1'); Run('find K1 modified', [oFIND]);
  v^[50] := 12345;
  SetKey('K0'); Run('find K0 assign h:=12345', [oFIND, oASSIGN, 29, 50]);
  SetKey('K0'); Run('find K0', [oFIND]);
  SetKey('K1'); Run('find K1', [oFIND]);
  v^[40] := v^[30] + 1; v^[10] := 999;
  Run('stalloc K1 999', [oSTALLOC, 40]);
  SetKey('K1'); Run('find K1', [oFIND]);
  v^[40] := v^[30] + 3; v^[10] := 777;
  Run('stalloc bad token', [oSTALLOC, 40]);
  SetKey('K1'); Run('find K1', [oFIND]);
  SetKey('K2'); Run('find K2', [oFIND]);
  v^[40] := v^[30] + 1; v^[10] := 4242;
  SetKey('K0'); Run('find K0 stale token', [oFIND, oSTALLOC, 40]);
  SetKey('K2'); Run('find K2', [oFIND]);
  Put('K3', 3, 0);   { saves the area after oASSIGN }

  writeln('== spoiled descriptor');
  opend(NameKey('AREA1'));
  PInt64(v^[24])^ := 0;
  Get('A', 16);
  Put('Q', 1, 1);
  Run('next', [oNEXT]);
  Run('nop', [0]);
  opend(NameKey('AREA1')); writeln('opend: err=', e^);
  Get('A', 16);

  writeln('== names');
  name := 'ЖУРНАЛ';
  newd(name); writeln('newd unicode: err=', e^);
  w[0] := #$0416; w[1] := #$0423; w[2] := #$0420; w[3] := #$041D; w[4] := #$0410; w[5] := #$041B;
  opend(w); writeln('opend widechar: err=', e^);
  putd(w, d, 16); writeln('putd widechar key: err=', e^);
  getd(name, d, 16); writeln('getd unicode key: err=', e^, ' ', d[0], ' ', d[1]);
  deld(name); writeln('deld unicode key: err=', e^);

  writeln('== clear, drop');
  newd(NameKey('CL')); opend(NameKey('CL'));
  Put('A', 1, 1); Put('B', 2, 2);
  SetKey('B'); Run('find B', [oFIND]);
  cleard(NameKey('CL')); writeln('cleard CL: err=', e^);
  Get('A', 16);
  Run('begin next', [oBEGIN, oNEXT]);
  Put('C', 3, 3);
  SetKey('C'); Run('find C (handles go on)', [oFIND]);
  dropd(NameKey('CL')); writeln('dropd CL: err=', e^);
  Run('next', [oNEXT]);
  opend(NameKey('CL')); writeln('opend CL: err=', e^);
  cleard(NameKey('CL')); writeln('cleard CL: err=', e^);
  dropd(NameKey('CL')); writeln('dropd CL: err=', e^);
  newd(NameKey('CL')); writeln('newd CL: err=', e^);
  opend(NameKey('CL'));
  Put('C', 4, 4);
  SetKey('C'); Run('find C (a new area)', [oFIND]);
  Get('A', 16);
end.
