{ Text of KOMPAS: UTF-8 outside, UTF-16 (WideChar) inside programs and
  the database.  Names (keywords, schema names) are folded: upper case,
  Ё as Е, and Latin letters that look Cyrillic (A B C E H K M O P T X Y)
  as Cyrillic.  Data are never folded.  Text files and standard streams
  are UTF-8 whatever the locale. }
unit kutf;

{$mode objfpc}{$H+}

interface

function U2W(const s: string): UnicodeString;
function W2U(const s: UnicodeString): string;
{ s[1..n] of a WideChar buffer as UTF-8 }
function BufU(p: PWideChar; n: integer): string;
function FoldChar(c: WideChar): WideChar;
function FoldW(const s: UnicodeString): UnicodeString;
{ a name: folded, trimmed }
function FoldName(const s: string): string;
{ a name of KOMPAS: folded, first 6 characters, trimmed }
function Name6(const s: string): string;
{ characters in a UTF-8 string }
function ULen(const s: string): integer;

implementation

uses {$ifdef unix}cwstring,{$endif} SysUtils;

function U2W(const s: string): UnicodeString;
begin
  Result := UTF8Decode(s);
end;

function W2U(const s: UnicodeString): string;
var r: RawByteString;
begin
  r := UTF8Encode(s);
  SetCodePage(r, CP_ACP, false);
  Result := r;
end;

function BufU(p: PWideChar; n: integer): string;
var w: UnicodeString;
begin
  SetString(w, p, n);
  Result := W2U(w);
end;

function FoldChar(c: WideChar): WideChar;
var u: word;
begin
  u := ord(c);
  if (u >= ord('a')) and (u <= ord('z')) then dec(u, 32)
  else if (u >= $430) and (u <= $44F) then dec(u, 32)
  else if (u = $401) or (u = $451) then u := $415;
  case u of
    ord('A'): u := $410;
    ord('B'): u := $412;
    ord('C'): u := $421;
    ord('E'): u := $415;
    ord('H'): u := $41D;
    ord('K'): u := $41A;
    ord('M'): u := $41C;
    ord('O'): u := $41E;
    ord('P'): u := $420;
    ord('T'): u := $422;
    ord('X'): u := $425;
    ord('Y'): u := $423;
  end;
  Result := WideChar(u);
end;

function FoldW(const s: UnicodeString): UnicodeString;
var i: integer;
begin
  Result := s;
  UniqueString(Result);
  for i := 1 to length(Result) do Result[i] := FoldChar(Result[i]);
end;

function FoldName(const s: string): string;
begin
  Result := TrimRight(W2U(FoldW(U2W(s))));
end;

function Name6(const s: string): string;
begin
  Result := TrimRight(W2U(Copy(FoldW(U2W(s)), 1, 6)));
end;

function ULen(const s: string): integer;
begin
  Result := length(U2W(s));
end;

initialization
  DefaultSystemCodePage := CP_UTF8;
  DefaultFileSystemCodePage := CP_UTF8;
  DefaultRTLFileSystemCodePage := CP_UTF8;
  SetTextCodePage(Input, CP_UTF8);
  SetTextCodePage(Output, CP_UTF8);
  SetTextCodePage(StdErr, CP_UTF8);
end.
