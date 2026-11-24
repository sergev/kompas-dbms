{ Runtime of KOMPAS Pascal programs: types and Pascal I/O formats. }
unit krt;

{$mode objfpc}{$H-}

interface

type
  integer = int64;
  real = double;
  alfa = packed array[1..6] of char;

{ write(x) without width: the formats of the KOMPAS Pascal programs }
function RT_W(x: int64): string;
function RT_W(x: double): string;
function RT_W(x: boolean): string;
function RT_W(c: char): string;
function RT_W(const a: array of char): string;
{ write of an enumeration value: its name right-justified in 8 }
function RT_EnW(const s: string): string;
{ readln(x): a card is padded with blanks }
procedure RT_ReadLn(var a: array of char);
procedure RT_ReadLn(var x: int64);
procedure RT_ReadLn(var x: double);
procedure RT_ReadLn(var c: char);
{ read(x) from input: a word is padded with blanks }
procedure RT_Read(var a: array of char);
procedure RT_Read(var x: int64);
procedure RT_Read(var x: double);
procedure RT_Read(var c: char);
{ scratch files: true on the first reset/rewrite of a file variable }
function RT_First(p: pointer): boolean;
function RT_TmpName: string;
{ text file buffer F^ and GET(F) }
function RT_Peek(var f: text): char;
procedure RT_GetC(var f: text);
{ a <= b, not folded (FOR over an enum or subrange) }
function RT_Le(a, b: int64): boolean;
{ d := s as raw words: a set kept in an integer }
procedure RT_Copy(var d; dn: int64; const s; sn: int64);

implementation

function RT_W(x: int64): string;
var s: string;
begin
  str(x:10, s);
  RT_W := s
end;

function RT_W(x: double): string;
{ field 14, 4 decimals, 2-digit exponent }
var m: double; e: integer; s, t: string;
begin
  e := 0;
  m := abs(x);
  if m <> 0 then begin
    while m >= 10 do begin m := m / 10; inc(e) end;
    while m < 1 do begin m := m * 10; dec(e) end;
    if round(m * 10000) >= 100000 then begin m := m / 10; inc(e) end;
  end;
  str(m:0:4, s);
  if x < 0 then s := '-' + s;
  str(abs(e), t);
  if length(t) < 2 then t := '0' + t;
  if e < 0 then s := s + 'E-' + t else s := s + 'E+' + t;
  while length(s) < 14 do s := ' ' + s;
  RT_W := s
end;

function RT_W(x: boolean): string;
begin
  { field 8 }
  if x then RT_W := '    TRUE' else RT_W := '   FALSE'
end;

function RT_W(c: char): string;
begin
  RT_W := c
end;

function RT_W(const a: array of char): string;
var s: string; i: integer;
begin
  s := '';
  for i := 0 to high(a) do s := s + a[i];
  RT_W := s
end;

function RT_EnW(const s: string): string;
var r: string;
begin
  r := s;
  while length(r) < 8 do r := ' ' + r;
  RT_EnW := r
end;

procedure RT_ReadLn(var a: array of char);
var s: ansistring; i: integer;
begin
  readln(s);
  for i := 0 to high(a) do
    if i < length(s) then a[i] := s[i + 1] else a[i] := ' ';
end;

procedure RT_ReadLn(var x: int64);
begin readln(x) end;

procedure RT_ReadLn(var x: double);
begin readln(x) end;

procedure RT_ReadLn(var c: char);
begin readln(c) end;

procedure RT_Read(var a: array of char);
var i: integer;
begin
  for i := 0 to high(a) do
    if eof(input) or eoln(input) then a[i] := ' ' else read(a[i]);
end;

procedure RT_Read(var x: int64);
begin read(x) end;

procedure RT_Read(var x: double);
begin read(x) end;

procedure RT_Read(var c: char);
begin if eof(input) then c := ' ' else read(c) end;


var
  seen: array[0..255] of pointer;
  nseen: integer = 0;
  ntmp: integer = 0;

function RT_First(p: pointer): boolean;
var i: integer;
begin
  for i := 0 to nseen - 1 do
    if seen[i] = p then exit(false);
  seen[nseen] := p;
  inc(nseen);
  RT_First := true
end;

function RT_TmpName: string;
var s: string;
begin
  inc(ntmp);
  str(ntmp, s);
  RT_TmpName := 'pmfile' + s
end;


function RT_Peek(var f: text): char;
begin
  if eof(f) or eoln(f) then RT_Peek := ' '
  else RT_Peek := TextRec(f).BufPtr^[TextRec(f).BufPos];
end;

function RT_Le(a, b: int64): boolean;
begin
  RT_Le := a <= b;
end;

procedure RT_GetC(var f: text);
var c: char;
begin
  if eoln(f) then readln(f) else read(f, c);
end;



procedure RT_Copy(var d; dn: int64; const s; sn: int64);
begin
  FillChar(d, dn, 0);
  if sn < dn then Move(s, d, sn) else Move(s, d, dn)
end;

end.
