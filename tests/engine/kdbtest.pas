{ Engine test on the CD schema of linux/Tutorial.md (cd.ddl, areas made
  by servis).  Prints set walks; checks chain integrity after each step. }
program kdbtest;

{$mode objfpc}{$H+}

uses SysUtils, kdb, kgost;

var
  fails: integer = 0;

function RN(const n: string): integer; begin Result := KRecNo(Encode(n)); end;
function SN(const n: string): integer; begin Result := KSetNo(Encode(n)); end;

procedure Check(const what: string);
var c: string;
begin
  c := KCheck;
  if c <> '' then begin
    writeln('FAIL ', what, ': ', c);
    inc(fails);
  end;
end;

procedure Expect(st: int64; const what: string);
begin
  if KSTAT <> st then begin
    writeln('FAIL ', what, ': status ', KSTAT, ' expected ', st);
    inc(fails);
  end;
  Check(what);
end;

procedure Store(const rec: string; const v: array of string);
var i, rt: integer;
begin
  rt := RN(rec);
  KBEGINPUT(rt);
  for i := 0 to high(v) do KPutText(i + 1, Encode(v[i]));
  KSTORE(rt);
end;

function Show(rec: integer): string;
var i: integer;
begin
  KBEGINGET(rec);
  Result := Decode(KRecName(KBufType)) + ':';
  for i := 1 to KFieldCount(KBufType) do
    Result := Result + ' ' + Trim(Decode(KFieldText(i)));
end;

procedure Walk(const setn: string; back: boolean);
var s: integer; line: string;
begin
  s := SN(setn);
  if back then KFINDLAST(s) else KFINDFIRST(s);
  line := setn + ':';
  while KSTAT = kOk do begin
    line := line + ' [' + Show(0) + ']';
    if back then KFINDPRIOR(s) else KFINDNEXT(s);
  end;
  writeln(line);
end;

var k: int64; name: array[1..40] of char; i: integer;
begin
  if not KSchemaOk then begin writeln('NO SCHEMA'); halt(1); end;
  writeln('records ', KRecCount, ' sets ', KSetCount);
  Store('АРТИСТ', ['КИНО', 'РОССИЯ']); Expect(kOk, 'store artist');
  Store('ДИСК', ['1002', 'ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ', '1989', '14.00']); Expect(kOk, 'store disc');
  Store('ТРЕК', ['3', 'ПАЧКА СИГАРЕТ', '268']); Expect(kOk, 'track 3');
  Store('ТРЕК', ['1', 'ЗВЕЗДА ПО ИМЕНИ СОЛНЦЕ', '225']); Expect(kOk, 'track 1');
  Store('ТРЕК', ['2', 'ПЕСНЯ БЕЗ СЛОВ', '230']); Expect(kOk, 'track 2');
  Store('ТРЕК', ['2', 'ДУБЛЬ', '1']); Expect(kDup, 'duplicate track');
  Store('ДИСК', ['1001', 'ГРУППА КРОВИ', '1988', '12.50']); Expect(kOk, 'disc 1001');
  Store('ТРЕК', ['1', 'ГРУППА КРОВИ', '286']); Expect(kOk, 'track');
  Store('АРТИСТ', ['АКВАРИУМ', 'РОССИЯ']); Expect(kOk, 'artist 2');
  Store('ДИСК', ['1003', 'РАДИО АФРИКА', '1983', '10.00']); Expect(kOk, 'disc 1003');
  Walk('SY-АРТ', false);
  Walk('SY-ДИС', false);
  Walk('SY-ДИС', true);
  { tracks of 1002 by key }
  KFINDKEY(SN('SY-ДИС'), int64(1002)); Expect(kOk, 'find key');
  Walk('ДИ-ТРЕ', false);
  KFINDOWNER(SN('АР-ДИС')); Expect(kOk, 'owner');
  writeln('owner: ', Show(0));
  Walk('АР-ДИС', false);
  KFINDKEY(SN('SY-ДИС'), int64(999)); Expect(kNotFound, 'no key');
  { string key }
  FillChar(name, sizeof(name), ' ');
  name[1] := 'X';
  KFindKeyText(SN('SY-АРТ'), Encode('АКВАРИУМ')); Expect(kOk, 'artist by name');
  writeln('found: ', Show(0));
  { modify: renumber disc 1003 to 1000, SY-ДИС reorders }
  KFINDKEY(SN('SY-ДИС'), int64(1003));
  KBEGINGET(RN('ДИСК')); KPUTF(1, int64(1000)); KMODIFY(0); Expect(kOk, 'modify key');
  Walk('SY-ДИС', false);
  { modify to a duplicate key fails }
  KBEGINGET(RN('ДИСК')); KPUTF(1, int64(1001)); KMODIFY(0); Expect(kDup, 'modify dup');
  { DB-key }
  k := KDBKEY(RN('ДИСК'));
  KFINDFIRST(SN('SY-ДИС'));
  KSETCUR(RN('ДИСК'), k); Expect(kOk, 'set current');
  writeln('by db-key: ', Show(0));
  { disconnect from АР-ДИС, connect to КИНО }
  KDISCONNECT(SN('АР-ДИС')); Expect(kOk, 'disconnect');
  KFindKeyText(SN('SY-АРТ'), Encode('КИНО'));
  KSETCUR(RN('ДИСК'), k);
  KFindKeyText(SN('SY-АРТ'), Encode('КИНО'));
  KSETCUR(0, k);
  KCONNECT(SN('АР-ДИС')); Expect(kOk, 'connect');
  KFindKeyText(SN('SY-АРТ'), Encode('КИНО'));
  Walk('АР-ДИС', false);
  { type chain }
  KFINDFIRSTREC(RN('ТРЕК')); i := 0;
  while KSTAT = kOk do begin inc(i); KFINDNEXTREC(RN('ТРЕК')); end;
  writeln('tracks: ', i);
  { erase a disc: its tracks are disconnected }
  KFINDKEY(SN('SY-ДИС'), int64(1002));
  writeln('tracks of 1002: ', KCOUNT(SN('ДИ-ТРЕ')));
  KFINDKEY(SN('SY-ДИС'), int64(1002));
  KERASEMEMBERS(SN('ДИ-ТРЕ')); Expect(kOk, 'erase members');
  KFINDKEY(SN('SY-ДИС'), int64(1002));
  KERASE(0); Expect(kOk, 'erase');
  Walk('SY-ДИС', false);
  KFINDFIRSTREC(RN('ТРЕК')); i := 0;
  while KSTAT = kOk do begin inc(i); KFINDNEXTREC(RN('ТРЕК')); end;
  writeln('tracks: ', i);
  { SYSTEM-less schema: next in an empty set }
  if fails = 0 then writeln('ALL OK') else writeln('FAILS ', fails);
end.
