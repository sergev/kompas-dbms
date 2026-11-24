{ Runtime of KOMPAS Pascal programs: types and Pascal I/O formats.
  A char of a program is a WideChar; text files are UTF-8 (kutf). }
unit krt;

{$mode objfpc}{$H-}

interface

type
  integer = int64;
  real = double;
  alfa = packed array[1..6] of WideChar;

{ write(x) without width: the formats of the KOMPAS Pascal programs }
function RT_W(x: int64): string;
function RT_W(x: double): string;
function RT_W(x: boolean): string;
function RT_W(c: WideChar): AnsiString;
function RT_W(const a: array of WideChar): AnsiString;
{ write(a) of a char array (predt wraps the arguments it may be) }
function RT_S(const a: array of WideChar): AnsiString;
function RT_S(c: WideChar): AnsiString;
function RT_S(const s: UnicodeString): UnicodeString;
function RT_S(x: int64): int64;
function RT_S(x: double): double;
function RT_S(x: boolean): boolean;
{ write of an enumeration value: its name right-justified in 8 }
function RT_EnW(const s: UnicodeString): AnsiString;
{ readln(x): a card is padded with blanks }
procedure RT_ReadLn(var a: array of WideChar);
procedure RT_ReadLn(var x: int64);
procedure RT_ReadLn(var x: double);
procedure RT_ReadLn(var c: WideChar);
{ read(x) from input: a word is padded with blanks }
procedure RT_Read(var a: array of WideChar);
procedure RT_Read(var x: int64);
procedure RT_Read(var x: double);
procedure RT_Read(var c: WideChar);
{ read(f, a) of a char array: to the end of the line, blank padded }
procedure RT_Rd(var f: text; var a: array of WideChar);
{ one character of a UTF-8 text file }
function RT_GetW(var f: text): WideChar;
{ names in a buffer folded as kutf folds them }
procedure RT_Fold(var a: array of WideChar);
{ scratch files: true on the first reset/rewrite of a file variable }
function RT_First(p: pointer): boolean;
function RT_TmpName: string;
{ text file buffer F^ and GET(F) }
function RT_Peek(var f: text): WideChar;
procedure RT_GetC(var f: text);
{ a <= b, not folded (FOR over an enum or subrange) }
function RT_Le(a, b: int64): boolean;
{ d := s as raw words: a set kept in an integer }
procedure RT_Copy(var d; dn: int64; const s; sn: int64);

implementation

uses kutf;

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

function RT_W(c: WideChar): AnsiString;
begin
  RT_W := BufU(@c, 1)
end;

function RT_W(const a: array of WideChar): AnsiString;
begin
  if length(a) = 0 then RT_W := '' else RT_W := BufU(@a[0], length(a))
end;

function RT_S(const a: array of WideChar): AnsiString;
begin
  if length(a) = 0 then RT_S := '' else RT_S := BufU(@a[0], length(a))
end;

function RT_S(c: WideChar): AnsiString;
begin RT_S := BufU(@c, 1) end;

function RT_S(const s: UnicodeString): UnicodeString;
begin RT_S := s end;

function RT_S(x: int64): int64;
begin RT_S := x end;

function RT_S(x: double): double;
begin RT_S := x end;

function RT_S(x: boolean): boolean;
begin RT_S := x end;

function RT_EnW(const s: UnicodeString): AnsiString;
var r: UnicodeString;
begin
  r := s;
  while length(r) < 8 do r := ' ' + r;
  RT_EnW := W2U(r)
end;

{ the character at p (n bytes there), its length in l }
function Dec8(p: PAnsiChar; n: SizeInt; var l: SizeInt): WideChar;
var c, u: longint; i: SizeInt;
begin
  c := ord(p[0]);
  if c < $80 then begin l := 1; exit(WideChar(c)) end;
  if c and $E0 = $C0 then begin l := 2; u := c and $1F end
  else if c and $F0 = $E0 then begin l := 3; u := c and $0F end
  else begin l := 4; u := c and $07 end;
  if l > n then begin l := 1; exit(WideChar(c)) end;
  for i := 1 to l - 1 do u := (u shl 6) or (ord(p[i]) and $3F);
  if u > $FFFF then u := ord('?');
  Dec8 := WideChar(u)
end;

function RT_GetW(var f: text): WideChar;
var b: array[0..3] of AnsiChar; n, l: SizeInt;
begin
  read(f, b[0]);
  n := 1;
  if ord(b[0]) >= $C0 then begin
    if ord(b[0]) and $E0 = $C0 then l := 2
    else if ord(b[0]) and $F0 = $E0 then l := 3
    else l := 4;
    while (n < l) and not eof(f) and not eoln(f) do begin
      read(f, b[n]);
      inc(n)
    end
  end;
  RT_GetW := Dec8(@b[0], n, l)
end;

procedure RT_Rd(var f: text; var a: array of WideChar);
var i: SizeInt;
begin
  for i := 0 to high(a) do
    if eof(f) or eoln(f) then a[i] := ' ' else a[i] := RT_GetW(f);
end;

procedure RT_Fold(var a: array of WideChar);
var i: SizeInt;
begin
  for i := 0 to high(a) do a[i] := FoldChar(a[i])
end;

procedure RT_ReadLn(var a: array of WideChar);
var i: SizeInt;
begin
  for i := 0 to high(a) do
    if eof(input) or eoln(input) then a[i] := ' ' else a[i] := RT_GetW(input);
  readln
end;

procedure RT_ReadLn(var x: int64);
begin readln(x) end;

procedure RT_ReadLn(var x: double);
begin readln(x) end;

procedure RT_ReadLn(var c: WideChar);
begin
  if eof(input) or eoln(input) then c := ' ' else c := RT_GetW(input);
  readln
end;

procedure RT_Read(var a: array of WideChar);
var i: SizeInt;
begin
  for i := 0 to high(a) do
    if eof(input) or eoln(input) then a[i] := ' ' else a[i] := RT_GetW(input);
end;

procedure RT_Read(var x: int64);
begin read(x) end;

procedure RT_Read(var x: double);
begin read(x) end;

procedure RT_Read(var c: WideChar);
begin if eof(input) then c := ' ' else c := RT_GetW(input) end;


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


function RT_Peek(var f: text): WideChar;
var l: SizeInt;
begin
  if eof(f) or eoln(f) then RT_Peek := ' '
  else with TextRec(f) do
    RT_Peek := Dec8(@BufPtr^[BufPos], BufEnd - BufPos, l);
end;

function RT_Le(a, b: int64): boolean;
begin
  RT_Le := a <= b;
end;

procedure RT_GetC(var f: text);
begin
  if eoln(f) then readln(f) else RT_GetW(f);
end;



procedure RT_Copy(var d; dn: int64; const s; sn: int64);
begin
  FillChar(d, dn, 0);
  if sn < dn then Move(s, d, sn) else Move(s, d, dn)
end;

end.
