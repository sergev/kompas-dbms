{ no database file: every call fails, and no file is made }
program nodb;

{$mode objfpc}{$H+}

uses SysUtils, mars;

var
  e: ^int64;
  d: array[0..1] of int64;

begin
  e := MarsErr;
  d[0] := 1; d[1] := 2;
  opend(NameKey('AREA1')); writeln('opend: err=', e^);
  e^ := 0; getd(NameKey('A'), d, 16); writeln('getd: err=', e^);
  e^ := 0; putd(NameKey('A'), d, 16); writeln('putd: err=', e^);
  e^ := 0; newd(NameKey('AREA1')); writeln('newd: err=', e^);
  e^ := 0; MarsBegin; deld(NameKey('A')); MarsCommit; writeln('deld in MarsBegin: err=', e^);
  writeln('check: ', MarsCheck <> '');
  writeln('file made: ', FileExists(MarsPath));
end.
