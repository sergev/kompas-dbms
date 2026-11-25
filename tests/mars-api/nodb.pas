{ no database file: every call fails, and no file is made }
program nodb;

{$mode objfpc}{$H+}

uses SysUtils, mars;

var
  d: array[0..1] of int64;

begin
  d[0] := 1; d[1] := 2;
  opend(NameKey('AREA1')); writeln('opend: err=', MErr);
  MErr := 0; getd(NameKey('A'), d, 16); writeln('getd: err=', MErr);
  MErr := 0; putd(NameKey('A'), d, 16); writeln('putd: err=', MErr);
  MErr := 0; newd(NameKey('AREA1')); writeln('newd: err=', MErr);
  MErr := 0; MarsBegin; deld(NameKey('A')); MarsCommit; writeln('deld in MarsBegin: err=', MErr);
  writeln('check: ', MarsCheck <> '');
  writeln('file made: ', FileExists(MarsPath));
end.
