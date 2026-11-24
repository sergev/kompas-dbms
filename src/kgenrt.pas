{ Runtime of the loaders made by gen: reads the data section.

  Data: blocks NAME [v_v_…*v_…*] with fields separated by _ and records
  ended by *; NAME [] fires a format once with no values.  An outer
  РЕЖИМ [[ПОВТОР] … КОНЕЦ ] is accepted.  Line breaks are blanks; values
  are trimmed.  The data come from the file $KOMPAS_GENDATA, else from
  standard input (UTF-8). }
unit kgenrt;

{$mode objfpc}{$H+}

interface

uses krt;

function GNEXT(var fmt: alfa): boolean;
function GCOUNT: int64;
procedure GVALI(i, dp: int64; var x: int64);
procedure GVALR(i: int64; var x: double);
procedure GVALB(i: int64; var x: boolean);
procedure GVALA(i: int64; var x: array of char);
procedure GVALC(i: int64; var x: char);
procedure GUNKNOWN(var fmt: alfa);
procedure GDONE;

implementation

uses SysUtils, Classes, kgost, kdb;

type
  TRecd = record
    fmt: string;
    vals: array of string;
    line: integer;
  end;

var
  data: array of TRecd;
  cur: integer = -1;
  parsed: boolean = false;
  counts: TStringList;
  errs: integer = 0;
  hard0: int64 = 0;

procedure Say(const s: string);
begin
  { the loader prints in the internal code }
  writeln(Encode(s));
end;

procedure Parse;
var text, s, name, rec: string; i, n, line, depth, j: integer; f: TStringList;
    fn: string;

  procedure SkipWs;
  begin
    while (i <= n) and (text[i] in [' ', #10, #13, #9]) do begin
      if text[i] = #10 then inc(line);
      inc(i);
    end;
  end;

  procedure AddRec(const nm, body: string; empty: boolean);
  var p: integer; v: string;
  begin
    SetLength(data, length(data) + 1);
    with data[high(data)] do begin
      fmt := Copy(nm + '      ', 1, 6);
      SetLength(vals, 0);
      if empty then exit;
      v := '';
      for p := 1 to length(body) + 1 do
        if (p > length(body)) or (body[p] = '_') then begin
          SetLength(vals, length(vals) + 1);
          vals[high(vals)] := Trim(v);
          v := '';
        end else if body[p] = #10 then v := v + ' '
        else v := v + body[p];
    end;
    data[high(data)].line := line;
  end;

begin
  parsed := true;
  f := TStringList.Create;
  fn := GetEnvironmentVariable('KOMPAS_GENDATA');
  if fn <> '' then f.LoadFromFile(fn)
  else while not eof(input) do begin readln(s); f.Add(s); end;
  text := '';
  for j := 0 to f.Count - 1 do text := text + Encode(f[j]) + #10;
  i := 1; n := length(text); line := 1; depth := 0;
  while i <= n do begin
    SkipWs;
    if i > n then break;
    if text[i] = ']' then begin dec(depth); inc(i); continue; end;
    name := '';
    while (i <= n) and not (text[i] in [' ', #10, #13, '[', ']']) do begin
      name := name + text[i]; inc(i);
    end;
    SkipWs;
    if name = Encode('КОНЕЦ') then begin
      if (i <= n) and (text[i] = ']') then begin dec(depth); inc(i); end;
      continue;
    end;
    if (i > n) or (text[i] <> '[') then begin
      Say('ГЕН: ПРОПУЩЕНО В СТРОКЕ ' + IntToStr(line) + ': ' + Decode(name));
      while (i <= n) and (text[i] <> #10) do inc(i);
      continue;
    end;
    inc(i);
    if (i <= n) and (text[i] = '[') then begin
      { РЕЖИМ [[ПОВТОР] …: an option, then the blocks inside }
      while (i <= n) and (text[i] <> ']') do inc(i);
      inc(i);
      inc(depth);
      continue;
    end;
    { one block: records up to ] }
    rec := '';
    j := 0;
    while (i <= n) and (text[i] <> ']') do begin
      if text[i] = #10 then inc(line);
      if text[i] = '*' then begin
        AddRec(name, rec, false); inc(j); rec := '';
      end else rec := rec + text[i];
      inc(i);
    end;
    inc(i);
    if Trim(StringReplace(rec, #10, ' ', [rfReplaceAll])) <> '' then begin
      AddRec(name, rec, false); inc(j);
    end;
    if j = 0 then AddRec(name, '', true);
  end;
  f.Free;
end;

procedure Report;
var ln: string;
begin
  { an error of the previous record }
  if (cur >= 0) and (cur <= high(data)) and (KHARD <> hard0) then begin
    inc(errs);
    ln := 'ГЕН: ОШИБКА ' + KStatusText(KLASTHARD) + ': ' + Decode(TrimRight(data[cur].fmt)) +
      ' СТРОКА ' + IntToStr(data[cur].line);
    Say(ln);
  end;
  hard0 := KHARD;
end;

function GNEXT(var fmt: alfa): boolean;
var j: integer;
begin
  if not parsed then begin
    Parse;
    counts := TStringList.Create;
    hard0 := KHARD;
  end;
  Report;
  inc(cur);
  Result := cur <= high(data);
  if not Result then exit;
  for j := 1 to 6 do fmt[j] := data[cur].fmt[j];
  j := counts.IndexOfName(data[cur].fmt);
  if j < 0 then counts.Values[data[cur].fmt] := '1'
  else counts.ValueFromIndex[j] := IntToStr(StrToInt(counts.ValueFromIndex[j]) + 1);
end;

function GCOUNT: int64;
begin
  if (cur >= 0) and (cur <= high(data)) then Result := length(data[cur].vals)
  else Result := 0;
end;

function Val0(i: int64): string;
begin
  if (cur >= 0) and (cur <= high(data)) and (i >= 1) and (i <= length(data[cur].vals)) then
    Result := data[cur].vals[i - 1]
  else Result := '';
end;

function Num(i: int64): double;
var e: integer; s: string;
begin
  s := Val0(i);
  val(s, Result, e);
  if e <> 0 then begin
    if s <> '' then Say('ГЕН: НЕ ЧИСЛО "' + Decode(s) + '" СТРОКА ' +
      IntToStr(data[cur].line));
    Result := 0;
  end;
end;

procedure GVALI(i, dp: int64; var x: int64);
var v: double; k: integer;
begin
  v := Num(i);
  for k := 1 to dp do v := v * 10;
  x := round(v);
end;

procedure GVALR(i: int64; var x: double);
begin
  x := Num(i);
end;

procedure GVALB(i: int64; var x: boolean);
var s: string;
begin
  s := Copy(Val0(i), 1, 1);
  x := (s = 'T') or (s = '1') or (s = Encode('И')) or (s = Encode('Д'));
end;

procedure GVALA(i: int64; var x: array of char);
var s: string; j: integer;
begin
  s := Val0(i);
  for j := 0 to high(x) do
    if j < length(s) then x[j] := s[j + 1] else x[j] := ' ';
end;

procedure GVALC(i: int64; var x: char);
var s: string;
begin
  s := Val0(i);
  if s <> '' then x := s[1] else x := ' ';
end;

procedure GUNKNOWN(var fmt: alfa);
begin
  inc(errs);
  Say('ГЕН: НЕТ ФОРМАТА ' + Decode(TrimRight(fmt)) + ' СТРОКА ' + IntToStr(data[cur].line));
end;

procedure GDONE;
var j: integer;
begin
  Report;
  if counts = nil then counts := TStringList.Create;
  for j := 0 to counts.Count - 1 do
    writeln(counts.Names[j], ' ', counts.ValueFromIndex[j]:6);
  Say('ОШИБОК: ' + IntToStr(errs));
end;

end.
