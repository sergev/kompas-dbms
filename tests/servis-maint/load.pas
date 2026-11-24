{ journaled changes: stores, a key change, disconnect/connect, erase }
program load;

{$mode objfpc}{$H+}{$codepage utf8}

uses SysUtils, kdb, cddump;

function RN(const n: string): integer; begin Result := KRecNo(n); end;
function SN(const n: string): integer; begin Result := KSetNo(n); end;

procedure Store(const rec: string; const v: array of string);
var i, rt: integer;
begin
  rt := RN(rec);
  KBEGINPUT(rt);
  for i := 0 to high(v) do KPutText(i + 1, v[i]);
  KSTORE(rt);
  if KSTAT <> kOk then writeln('store ', rec, ' ', v[0], ': status ', KSTAT);
end;

var
  j: array[0..5] of WideChar;
  u: UnicodeString;
  i, a, d, t: integer;
  k: int64;

begin
  u := 'ЖУ-ДИС';
  for i := 0 to 5 do j[i] := u[i + 1];
  KOPEN(j);
  for a := 1 to 2 do begin
    Store('АРТИСТ', ['АРТИСТ ' + IntToStr(a), 'РОССИЯ']);
    for d := 1 to 3 do begin
      Store('ДИСК', [IntToStr(1000 + a * 10 + d), Format('ДИСК %d-%d', [a, d]), IntToStr(1980 + d), '10.00']);
      for t := 1 to 3 do
        Store('ТРЕК', [IntToStr(t), Format('ПЕСНЯ %d-%d-%d', [a, d, t]), '200']);
    end;
  end;
  { renumber 1012 to 1000: SY-ДИС reorders }
  KFINDKEY(SN('SY-ДИС'), int64(1012));
  KBEGINGET(RN('ДИСК')); KPUTF(1, int64(1000)); KMODIFY(0);
  writeln('modify: ', KSTAT);
  { move disc 1013 from artist 1 to artist 2 }
  KFINDKEY(SN('SY-ДИС'), int64(1013));
  k := KDBKEY(RN('ДИСК'));
  KDISCONNECT(SN('АР-ДИС'));
  writeln('disconnect: ', KSTAT);
  KFindKeyText(SN('SY-АРТ'), 'АРТИСТ 2');
  KSETCUR(0, k);
  KCONNECT(SN('АР-ДИС'));
  writeln('connect: ', KSTAT);
  { erase disc 1022 with its tracks }
  KFINDKEY(SN('SY-ДИС'), int64(1022));
  KERASEMEMBERS(SN('ДИ-ТРЕ'));
  KFINDKEY(SN('SY-ДИС'), int64(1022));
  KERASE(0);
  writeln('erase: ', KSTAT);
  PrintDump('loaded');
end.
