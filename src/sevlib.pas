{ Native parts of the lost library of the Severov programs
  (tests/severov): file and output-line helpers, ЖУРНАЛ, КОНЕЦ, УНАР, COUNT. }
unit sevlib;

{$mode objfpc}{$H+}

interface

procedure FCOPY(var f, g: text);
{ УНАР(s): erase the members of the current occurrence of set s;
  COUNT(s): their number (external in the programs) }
procedure YHAP(s: int64);
function COUNT(s: int64): int64;
procedure FWRITE(var f: text);
{ ЖУРНАЛ('ЗАК'|'СБР', P), КОНЕЦ(P): close or drop the changes, end of
  work; P is the program's pre-close procedure.  The engine writes every
  change at once, so only P is called. }
type TProc = procedure;
procedure Q0416_YPHAQ041B_(const a: array of WideChar; p: TProc);
procedure Q0416_YPHAQ041B_(const a: UnicodeString; p: TProc);
procedure KOHEQ0426_(p: TProc);
procedure WCTP(var f: text; const s: array of WideChar; n: int64);
procedure WCTP(var f: text; const s: UnicodeString; n: int64);
procedure WQ0414_AT(var f: text; d: int64);
{ TPUT: the pending (unfinished) output line, its length, a char, drop it }
function ZZTLEN: int64;
function ZZTCH(i: int64): WideChar;
procedure ZZTCLR;

implementation

uses SysUtils, krt, kio, kdb, kutf;

{ Output keeps its unfinished line in pend (TPUT, FCOPY); whole lines go out.
  pw: pend as characters for ZZTLEN/ZZTCH. }
var pend: AnsiString = '';
    pw: UnicodeString = '';

procedure YHAP(s: int64);
begin
  KERASEMEMBERS(s);
end;

function COUNT(s: int64): int64;
begin
  Result := KCOUNT(s);
end;

procedure Q0416_YPHAQ041B_(const a: array of WideChar; p: TProc);
begin
  if (length(a) > 0) and (a[0] <> ' ') then p;
end;

procedure Q0416_YPHAQ041B_(const a: UnicodeString; p: TProc);
begin
  if (length(a) > 0) and (a[1] <> ' ') then p;
end;

procedure KOHEQ0426_(p: TProc);
begin
  p;
end;

{ FWRITE(OUT): end the output line; FWRITE(F): print scratch file F }
procedure FWRITE(var f: text);
var s: string;
begin
  if @f = @output then begin writeln; exit; end;
  reset(f);
  while not eof(f) do begin
    readln(f, s);
    writeln(s);
  end;
end;

procedure WCTP(var f: text; const s: UnicodeString; n: int64);
var t: UnicodeString; k: int64;
begin
  t := TrimRight(s);
  write(f, W2U(t));
  for k := length(t) + 1 to n do write(f, ' ');
end;

procedure WCTP(var f: text; const s: array of WideChar; n: int64);
var t: UnicodeString;
begin
  SetString(t, PWideChar(@s[0]), length(s));
  WCTP(f, t, n);
end;

procedure WQ0414_AT(var f: text; d: int64);
begin
  write(f, Format('%.2d.%.2d.%.2d', [d mod 100, d div 100 mod 100, d div 10000 mod 100]));
end;

{ FCOPY(F, OUT): the unfinished output line into scratch file F }
procedure FCOPY(var f, g: text);
begin
  { a scratch file: the program's own RESET keeps it }
  if RT_First(@f) then Assign(f, RT_TmpName);
  Rewrite(f);
  if @g = @output then begin Flush(Output); write(f, pend); end;
  Close(f);
end;


function CapWrite(var t: TextRec): longint;
var s: AnsiString;
    i: SizeInt;
begin
  if t.BufPos > 0 then begin
    SetString(s, PAnsiChar(t.BufPtr), t.BufPos);
    t.BufPos := 0;
    pend := pend + s;
    i := LastDelimiter(#10, pend);
    if i > 0 then begin
      KioPut(Copy(pend, 1, i));
      Delete(pend, 1, i);
    end;
  end;
  Result := 0;
end;

function ZZTLEN: int64;
begin
  Flush(Output);
  pw := U2W(pend);
  Result := length(pw);
end;

function ZZTCH(i: int64): WideChar;
begin
  Result := pw[i];
end;

procedure ZZTCLR;
begin
  pend := '';
  pw := '';
end;

initialization
  Flush(Output);
  TextRec(Output).InOutFunc := @CapWrite;
  TextRec(Output).FlushFunc := @CapWrite;
finalization
  Flush(Output);
  KioPut(pend);
  pend := '';
end.
