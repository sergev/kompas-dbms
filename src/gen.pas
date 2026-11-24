{ GEN: the KOMPAS loader generator.

  Usage: gen [-k] [file]   (default: standard input, UTF-8)

  The deck: ИМЯ-ЗА name, ПОДСХЕМА schema, [ПЕРЕМЕННЫЕ v type, … КОНЕЦ],
  [ОГРАНИЧ … КОНЕЦ], [ПРОЦЕДУРЫ "Pascal"], ФОРМАТ name with fields
  REC.FLD_…* and an action ПАСКАЛ "…" or &&…&&, КОНЕЦ, then the data.
  As in the original GEN, the result is a loader program: it goes
  through predt and fpc and is run on the data.  -k keeps the
  work directory.  Job cards (*…) and labels (? …) are skipped. }
program gen;

{$mode objfpc}{$H+}

uses SysUtils, Classes, Process, kdb, kutf, mars;

type
  TFmt = record
    name: string;          { UTF-8 }
    fields: array of string;
    action: string;
  end;

var
  text: string;
  i, n, line: integer;
  loader, schema, procs, vars, data: string;
  fmts: array of TFmt;
  errors: integer = 0;
  keep: boolean = false;

procedure Error(const msg: string);
begin
  writeln('ГЕН: СТРОКА ', line, ': ', msg);
  inc(errors);
end;

function KW(const s: string): string;
begin
  Result := Name6(s);
end;

{ s folded as a name, blanks kept }
function FoldAll(const s: string): string;
begin
  Result := W2U(FoldW(U2W(s)));
end;

function IsSep(c: char): boolean;
begin
  Result := c in [' ', #9, #10, #13, '_', '*', '"', ',', ':', ';', '[', ']', '&'];
end;

{ at a line start: skip job cards and labels }
procedure SkipCards;
begin
  while (i <= n) and ((i = 1) or (text[i - 1] = #10)) and (text[i] in ['*', '?']) do begin
    while (i <= n) and (text[i] <> #10) do inc(i);
    if i <= n then begin inc(i); inc(line); end;
  end;
end;

procedure SkipWs;
begin
  repeat
    SkipCards;
    if (i <= n) and (text[i] in [' ', #9, #10, #13]) then begin
      if text[i] = #10 then inc(line);
      inc(i);
    end else break;
  until false;
end;

function Word: string;
begin
  SkipWs;
  Result := '';
  while (i <= n) and not IsSep(text[i]) do begin
    Result := Result + text[i]; inc(i);
  end;
end;

function Quoted: string;
begin
  SkipWs;
  Result := '';
  if (i > n) or (text[i] <> '"') then begin Error('ожидается "'); exit; end;
  inc(i);
  while (i <= n) and (text[i] <> '"') do begin
    if text[i] = #10 then inc(line);
    Result := Result + text[i]; inc(i);
  end;
  inc(i);
end;

function Fragment: string;
{ &&…&& at the current position }
var a: integer;
begin
  a := i;
  inc(i, 2);
  while (i < n) and not ((text[i] = '&') and (text[i + 1] = '&')) do begin
    if text[i] = #10 then inc(line);
    inc(i);
  end;
  inc(i, 2);
  Result := Copy(text, a, i - a);
end;

function PasType(const t: string; const len: string): string;
begin
  if KW(t) = KW('ЦЕЛОЕ') then Result := 'INTEGER'
  else if KW(t) = KW('ДЕЙСТВ') then Result := 'REAL'
  else if KW(t) = KW('ЛОГИЧЕ') then Result := 'BOOLEAN'
  else if KW(t) = KW('СИМВОЛ') then begin
    if (len = '') or (len = '1') then Result := 'CHAR'
    else Result := 'PACKED ARRAY[1..' + len + '] OF CHAR';
  end else begin
    Error('неизвестный тип ' + t);
    Result := 'INTEGER';
  end;
end;

procedure Variables;
var nm, t, len: string;
begin
  repeat
    nm := Word;
    if (nm = '') and (i <= n) and (text[i] = ',') then begin inc(i); continue; end;
    if (nm = '') or (KW(nm) = KW('КОНЕЦ')) then break;
    t := Word;
    len := '';
    if KW(t) = KW('СИМВОЛ') then len := Word;
    vars := vars + '  ' + nm + ': ' + PasType(t, len) + ';'#10;
    SkipWs;
    if (i <= n) and (text[i] = ',') then inc(i);
  until i > n;
end;

procedure Format1;
var f: TFmt; w: string;
begin
  f.name := Word;
  SetLength(f.fields, 0);
  f.action := '';
  repeat
    SkipWs;
    if i > n then break;
    if text[i] in ['_', '*', ',', ';'] then begin inc(i); continue; end;
    if (text[i] = '&') and (i < n) and (text[i + 1] = '&') then begin
      f.action := f.action + Fragment + #10;
      continue;
    end;
    w := Word;
    if w = '' then begin Error('непонятный символ ' + text[i]); inc(i); continue; end;
    if (KW(w) = KW('ФОРМАТ')) or (KW(w) = KW('КОНЕЦ')) then begin
      dec(i, length(w));
      break;
    end;
    if KW(w) = KW('ПАСКАЛ') then f.action := f.action + Quoted + #10
    else begin
      SetLength(f.fields, length(f.fields) + 1);
      f.fields[high(f.fields)] := w;
    end;
  until false;
  SetLength(fmts, length(fmts) + 1);
  fmts[high(fmts)] := f;
end;

procedure Definitions;
var w: string; f: TStringList; k, depth, base: integer; c: char;
begin
  repeat
    w := Word;
    if (w = '') and (i > n) then begin Error('нет КОНЕЦ'); exit; end;
    if w = '' then begin Error('непонятный символ ' + text[i]); inc(i); continue; end;
    if KW(w) = KW('ИМЯ-ЗА') then loader := Word
    else if KW(w) = KW('ПОДСХЕМА') then schema := Word
    else if KW(w) = KW('ПЕРЕМЕННЫЕ') then Variables
    else if KW(w) = KW('ОГРАНИЧ') then begin
      repeat w := Word; if (w = '') and (i <= n) then inc(i);
      until (KW(w) = KW('КОНЕЦ')) or (i > n);
    end else if KW(w) = KW('ПРОЦЕДУРЫ') then procs := procs + Quoted + #10
    else if KW(w) = KW('ФОРМАТ') then Format1
    else if KW(w) = KW('КОНЕЦ') then break
    else Error('неизвестное слово ' + w);
  until false;
  data := '';
  { the rest without job cards and labels }
  f := TStringList.Create;
  f.Text := Copy(text, i, n - i + 1);
  depth := 0; base := 0;
  for k := 0 to f.Count - 1 do begin
    w := f[k];
    { labels (? …) are never data; a job card (*…) only outside a block,
      inside one a line may start with * as data }
    if (w <> '') and ((w[1] = '?') or ((w[1] = '*') and (depth <= base))) then continue;
    data := data + w + #10;
    if (base = 0) and (Pos('РЕЖИМ', FoldAll(w)) > 0) and (Pos('[[', w) > 0) then
      base := 1;
    for c in w do
      if c = '[' then inc(depth) else if c = ']' then dec(depth);
  end;
  f.Free;
end;

{ the transfer of value v into REC.FLD or a variable }
function Assign(v: integer; const ref: string): string;
var p, r, f: integer; rn, fn: string; k: TKind;
begin
  Result := '';
  p := Pos('.', ref);
  if p = 0 then begin
    { a variable of ПЕРЕМЕННЫЕ: by its declared type }
    if Pos(FoldAll(ref + ': '), FoldAll(vars)) = 0 then begin
      Error('нет поля или переменной ' + ref); exit;
    end;
    if Pos(FoldAll(ref + ': INTEGER'), FoldAll(vars)) > 0 then
      Result := 'GVALI(' + IntToStr(v) + ', 0, ' + ref + ')'
    else if Pos(FoldAll(ref + ': REAL'), FoldAll(vars)) > 0 then
      Result := 'GVALR(' + IntToStr(v) + ', ' + ref + ')'
    else if Pos(FoldAll(ref + ': BOOLEAN'), FoldAll(vars)) > 0 then
      Result := 'GVALB(' + IntToStr(v) + ', ' + ref + ')'
    else if Pos(FoldAll(ref + ': CHAR;'), FoldAll(vars)) > 0 then
      Result := 'GVALC(' + IntToStr(v) + ', ' + ref + ')'
    else Result := 'GVALA(' + IntToStr(v) + ', ' + ref + ')';
    exit;
  end;
  rn := Copy(ref, 1, p - 1); fn := Copy(ref, p + 1, length(ref));
  r := KRecNo(rn);
  if r = 0 then begin Error('нет записи ' + rn); exit; end;
  f := KFieldNo(r, fn);
  if f = 0 then begin Error('нет поля ' + ref); exit; end;
  k := KFieldKind(r, f);
  case k of
    fkInt: Result := 'GVALI(' + IntToStr(v) + ', 0, ' + ref + ')';
    fkReal: Result := 'GVALR(' + IntToStr(v) + ', ' + ref + ')';
    fkBool: Result := 'GVALB(' + IntToStr(v) + ', ' + ref + ')';
    fkChar:
      if KFieldLen(r, f) = 1 then Result := 'GVALC(' + IntToStr(v) + ', ' + ref + ')'
      else Result := 'GVALA(' + IntToStr(v) + ', ' + ref + ')';
  end;
end;

function Pad6(const s: string): string;
begin
  { a format name as a Pascal string of 6 characters }
  Result := W2U(Copy(U2W(Name6(s)) + '      ', 1, 6));
end;

function Program1: string;
var j, k: integer; a: string;
begin
  Result := 'PROGRAM ZG(INPUT, OUTPUT);'#10 +
    'USES KRT, KIO, KDB, KGENRT;'#10 +
    '&&ПОДСХЕ ' + schema + '&&'#10 +
    'VAR ZZFMT: ALFA;'#10 + vars +
    procs + #10;
  for j := 0 to high(fmts) do begin
    Result := Result + 'PROCEDURE ZZF' + IntToStr(j + 1) + ';'#10'BEGIN'#10;
    for k := 0 to high(fmts[j].fields) do begin
      a := Assign(k + 1, fmts[j].fields[k]);
      if a <> '' then Result := Result + '  ' + a + ';'#10;
    end;
    if Trim(fmts[j].action) = '' then begin
      { no action: store the record of the first field }
      if length(fmts[j].fields) > 0 then
        Result := Result + '  &&ПОСТАВ ' + Copy(fmts[j].fields[0], 1,
          Pos('.', fmts[j].fields[0]) - 1) + '&&'#10;
    end else
      Result := Result + fmts[j].action;
    Result := Result + 'END;'#10;
  end;
  Result := Result + 'BEGIN'#10'  WHILE GNEXT(ZZFMT) DO'#10;
  for j := 0 to high(fmts) do
    Result := Result + '    IF ZZFMT = ''' + Pad6(fmts[j].name) + ''' THEN ZZF' +
      IntToStr(j + 1) + ' ELSE'#10;
  Result := Result + '    GUNKNOWN(ZZFMT);'#10'  GDONE'#10'END.'#10;
end;

procedure Save(const fn, s: string);
var fs: TFileStream;
begin
  fs := TFileStream.Create(fn, fmCreate);
  try
    if length(s) > 0 then fs.WriteBuffer(s[1], length(s));
  finally
    fs.Free;
  end;
end;

function Step(const exe: string; const args: array of string): boolean;
var p: TProcess; a: string;
begin
  p := TProcess.Create(nil);
  try
    p.Executable := exe;
    for a in args do p.Parameters.Add(a);
    p.Options := [poWaitOnExit];
    p.Execute;
    Result := p.ExitStatus = 0;
  finally
    p.Free;
  end;
end;

procedure RunLoader(const exe, dataf: string);
var p: TProcess; buf: array[0..4095] of char; k: integer; acc: string; j: integer;
begin
  p := TProcess.Create(nil);
  try
    p.Executable := exe;
    for j := 1 to GetEnvironmentVariableCount do
      p.Environment.Add(GetEnvironmentString(j));
    p.Environment.Add('KOMPAS_GENDATA=' + dataf);
    p.Options := [poUsePipes];
    p.Execute;
    p.CloseInput;
    acc := '';
    repeat
      k := p.Output.Read(buf, sizeof(buf));
      if k > 0 then begin
        SetString(text, PChar(@buf[0]), k);
        acc := acc + text;
        j := LastDelimiter(#10, acc);
        if j > 0 then begin
          write(Copy(acc, 1, j));
          Delete(acc, 1, j);
        end;
      end else if not p.Running then break
      else Sleep(5);
    until false;
    write(acc);
    p.WaitOnExit;
    if p.ExitStatus <> 0 then begin
      writeln('ГЕН: ЗАГРУЗЧИК ЗАВЕРШИЛСЯ С КОДОМ ', p.ExitStatus);
      errors := 1;
    end;
  finally
    p.Free;
  end;
end;

var
  f: TStringList;
  k: integer;
  src, home, work: string;
begin
  src := '';
  for k := 1 to ParamCount do
    if ParamStr(k) = '-k' then keep := true else src := ParamStr(k);
  f := TStringList.Create;
  if src <> '' then f.LoadFromFile(src)
  else while not eof(input) do begin readln(text); f.Add(text); end;
  text := f.Text;
  n := length(text); i := 1; line := 1;
  if not KSchemaOk then begin
    writeln('ГЕН: НЕТ СХЕМЫ (servis и ttc) В ', MarsPath);
    halt(2);
  end;
  procs := ''; vars := ''; loader := 'ZG'; schema := '';
  Definitions;
  if errors > 0 then halt(1);
  home := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..');
  work := IncludeTrailingPathDelimiter(GetTempDir) + 'kompas-gen-' + IntToStr(GetProcessID);
  ForceDirectories(work);
  Save(work + '/loader.pas', Program1);
  Save(work + '/data.txt', data);
  if not Step(home + '/bin/predt', [work + '/loader.pas', work + '/loader_fpc.pas']) or
     not Step('/bin/sh', ['-c', 'fpc -O1 -v0e -l- -Fu' + home + '/lib -FU' + work +
       ' -o' + work + '/loader ' + work + '/loader_fpc.pas > ' + work +
       '/fpc.log 2>&1 || { grep -v "^Free Pascal\|^Copyright" ' + work + '/fpc.log >&2; exit 1; }']) then begin
    writeln('ГЕН: ЗАГРУЗЧИК НЕ СОБРАН, СМ. ', work);
    halt(1);
  end;
  RunLoader(work + '/loader', work + '/data.txt');
  if keep then writeln('ГЕН: ФАЙЛЫ В ', work)
  else begin
    for src in ['loader.pas', 'loader_fpc.pas', 'loader', 'loader.o', 'data.txt',
                'fpc.log'] do
      DeleteFile(work + '/' + src);
    RemoveDir(work);
  end;
  if errors > 0 then halt(1);
end.
