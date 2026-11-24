{ the CD database as text: every set walk, the type chain of tracks,
  KCheck; and an MD5 of it, to compare dumps at a glance }
unit cddump;

{$mode objfpc}{$H+}{$codepage utf8}

interface

procedure PrintDump(const what: string);

implementation

uses SysUtils, Classes, md5, kdb;

function SN(const n: string): integer; begin Result := KSetNo(n); end;

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

procedure PrintDump(const what: string);
var arts, discs: TStringList; i, n: integer; d, c: string;
begin
  arts := TStringList.Create;
  discs := TStringList.Create;
  d := 'artists ' + Walk('SY-АРТ') + #10 + 'discs ' + Walk('SY-ДИС') + #10;
  KFINDFIRST(SN('SY-АРТ'));
  while KSTAT = kOk do begin KBEGINGET(0); arts.Add(Trim(KFieldText(1))); KFINDNEXT(SN('SY-АРТ')); end;
  KFINDFIRST(SN('SY-ДИС'));
  while KSTAT = kOk do begin KBEGINGET(0); discs.Add(Trim(KFieldText(1))); KFINDNEXT(SN('SY-ДИС')); end;
  for i := 0 to arts.Count - 1 do begin
    KFindKeyText(SN('SY-АРТ'), arts[i]);
    d := d + arts[i] + ': ' + Walk('АР-ДИС') + #10;
  end;
  for i := 0 to discs.Count - 1 do begin
    KFINDKEY(SN('SY-ДИС'), StrToInt64(discs[i]));
    d := d + discs[i] + ': ' + Walk('ДИ-ТРЕ') + #10;
  end;
  n := 0;
  KFINDFIRSTREC(KRecNo('ТРЕК'));
  while KSTAT = kOk do begin inc(n); KFINDNEXTREC(KRecNo('ТРЕК')); end;
  d := d + 'tracks ' + IntToStr(n);
  c := KCheck;
  if c = '' then c := 'ok';
  writeln(what, ': md5 ', MD5Print(MD5String(d)), ', check ', c);
  writeln(d);
  arts.Free;
  discs.Free;
end;

end.
