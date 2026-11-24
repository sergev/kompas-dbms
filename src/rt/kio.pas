{ Standard input and output of KOMPAS Pascal programs in UTF-8.
  The programs work in the internal 8-bit code (kgost); this unit
  converts Input from UTF-8 and Output to UTF-8. }
unit kio;

{$mode objfpc}{$H+}

interface

{ write internal-code bytes to standard output, converted }
procedure KioPut(const s: AnsiString);

implementation

uses SysUtils, kgost;

var
  rest: AnsiString = '';    { incomplete UTF-8 sequence of the last read }
  inq: AnsiString = '';     { converted input not yet in the buffer }

procedure KioPut(const s: AnsiString);
var u: AnsiString;
begin
  if s = '' then exit;
  u := Decode(s);
  if u <> '' then FileWrite(1, u[1], length(u));
end;

function OutFunc(var t: TextRec): longint;
var s: AnsiString;
begin
  if t.BufPos > 0 then begin
    SetString(s, PAnsiChar(t.BufPtr), t.BufPos);
    t.BufPos := 0;
    KioPut(s);
  end;
  Result := 0;
end;

{ length of the complete UTF-8 prefix of s }
function Whole(const s: AnsiString): SizeInt;
var i, n: SizeInt; c: byte;
begin
  i := length(s);
  n := 0;
  while (i >= 1) and (n < 4) do begin
    c := ord(s[i]);
    if c and $C0 <> $80 then begin
      if c < $80 then exit(length(s));
      if c and $E0 = $C0 then n := 2
      else if c and $F0 = $E0 then n := 3
      else n := 4;
      if length(s) - i + 1 >= n then exit(length(s));
      exit(i - 1);
    end;
    dec(i);
    inc(n);
  end;
  Result := length(s);
end;

function InFunc(var t: TextRec): longint;
var buf: array[0..4095] of char;
    got: longint;
    s: AnsiString;
    k: SizeInt;
begin
  got := 1;
  while (inq = '') and (got > 0) do begin
    got := FileRead(0, buf, sizeof(buf));
    if got <= 0 then begin
      s := rest;
      rest := '';
    end else begin
      SetString(s, PAnsiChar(@buf[0]), got);
      s := rest + s;
      k := Whole(s);
      rest := Copy(s, k + 1, length(s));
      SetLength(s, k);
    end;
    inq := Encode(s);
  end;
  k := length(inq);
  if k > t.BufSize then k := t.BufSize;
  if k > 0 then Move(inq[1], t.BufPtr^, k);
  Delete(inq, 1, k);
  t.BufPos := 0;
  t.BufEnd := k;
  Result := 0;
end;

initialization
  Flush(Output);
  TextRec(Output).InOutFunc := @OutFunc;
  TextRec(Output).FlushFunc := @OutFunc;
  TextRec(Input).InOutFunc := @InFunc;
  TextRec(Input).FlushFunc := nil;
finalization
  Flush(Output);
end.
