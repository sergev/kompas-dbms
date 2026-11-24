{ PREDT: the KOMPAS Pascal front end.

  Usage: predt [in [out]]   (UTF-8; default standard input and output)

  Input: Free Pascal with Russian identifiers and embedded DML &&…&&.
  Output: plain Free Pascal, compiled with fpc -Fu<kompas lib>.

  Every &&…&& fragment is replaced by Pascal.  &&ПОДСХЕ X&& declares the
  records of the schema in $MARS_DIR: types ZZ<rec>, variables <rec>,
  ZZBDKEY, СОСТ and transfer procedures.  A statement fragment becomes
  begin … СОСТ:=KSTAT end; НАБ s and ЗП r become the numbers of a set and
  a record.  Then non-ASCII identifiers become ASCII names, string
  literals the internal code (kgost), and the program gets default
  directives (unless it has {$mode}) and uses krt, kio, kdb. }
program predt;

{$mode objfpc}{$H+}

uses SysUtils, Classes, kdb, kgost;

type
  TTok = record
    s: string;      { source text (UTF-8) }
    k: string;      { folded internal code, words only }
    kind: char;     { w word, l literal, p punctuation }
    a, b: integer;  { span in the fragment }
  end;

var
  src, outs, frag: string;
  toks: array of TTok;
  tp: integer;
  declared: boolean = false;
  errors: integer = 0;
  lineNo: integer = 1;
  isExpr: boolean;

function KW(const s: string): string;
begin
  Result := Copy(Encode(s), 1, 6);
end;

procedure Error(const msg: string);
begin
  writeln(stderr, 'predt: строка ', lineNo, ': ', msg);
  inc(errors);
end;

{ --- names --- }

function Ident(const internal: string): string;
{ a schema name as a Pascal identifier, or '' if it cannot be one }
var i: integer;
begin
  Result := Decode(TrimRight(internal));
  for i := 1 to length(Result) do
    if Result[i] in ['-', ' ', '.', '*'] then exit('');
end;

function RecVar(r: integer): string;
begin
  Result := Ident(KRecName(r));
end;

function FieldType(r, i: integer): string;
begin
  case KFieldKind(r, i) of
    fkInt: Result := 'integer';
    fkReal: Result := 'real';
    fkBool: Result := 'boolean';
    fkChar:
      if KFieldLen(r, i) = 1 then Result := 'char'
      else Result := 'packed array[1..' + IntToStr(KFieldLen(r, i)) + '] of char';
  end;
end;

function Declarations: string;
var r, i, n: integer; v: string;
begin
  Result := #10'type ZZBDKEY = integer;'#10;
  for r := 1 to KRecCount do begin
    v := RecVar(r);
    if v = '' then continue;
    Result := Result + '  ZZ' + v + ' = record'#10;
    n := KFieldCount(r);
    for i := 1 to n do begin
      Result := Result + '    ' + Ident(KFieldName(r, i)) + ': ' + FieldType(r, i);
      if i < n then Result := Result + ';';
      Result := Result + #10;
    end;
    if n = 0 then Result := Result + '    ZZDUMMY: integer'#10;
    Result := Result + '  end;'#10;
  end;
  Result := Result + 'var СОСТ: integer;'#10;
  for r := 1 to KRecCount do begin
    v := RecVar(r);
    if v <> '' then Result := Result + '  ' + v + ': ZZ' + v + ';'#10;
  end;
  for r := 1 to KRecCount do begin
    v := RecVar(r);
    if v = '' then continue;
    Result := Result + 'procedure ZZGET' + IntToStr(r) + ';'#10'begin KBEGINGET(' +
      IntToStr(r) + ');'#10;
    for i := 1 to KFieldCount(r) do
      Result := Result + '  KGETF(' + IntToStr(i) + ', ' + v + '.' +
        Ident(KFieldName(r, i)) + ');'#10;
    Result := Result + 'end;'#10;
    Result := Result + 'procedure ZZPUT' + IntToStr(r) + ';'#10'begin KBEGINPUT(' +
      IntToStr(r) + ');'#10;
    for i := 1 to KFieldCount(r) do
      Result := Result + '  KPUTF(' + IntToStr(i) + ', ' + v + '.' +
        Ident(KFieldName(r, i)) + ');'#10;
    Result := Result + 'end;'#10;
  end;
  { the current of the run unit, whatever its type }
  Result := Result + 'procedure ZZGETRU;'#10'begin'#10'  case KCURTYPE of'#10;
  for r := 1 to KRecCount do
    if RecVar(r) <> '' then
      Result := Result + '    ' + IntToStr(r) + ': ZZGET' + IntToStr(r) + ';'#10;
  Result := Result + '  end'#10'end;'#10;
  Result := Result + 'procedure ZZPUTRU;'#10'var t: integer;'#10'begin'#10 +
    '  t := KCURTYPE;'#10'  case t of'#10;
  for r := 1 to KRecCount do
    if RecVar(r) <> '' then
      Result := Result + '    ' + IntToStr(r) + ': ZZPUT' + IntToStr(r) + ';'#10;
  Result := Result + '  end;'#10'  KMODIFY(t)'#10'end;'#10;
end;

{ --- fragment lexer (UTF-8, words folded for keywords) --- }

procedure Lex(const s: string);
var i, n: integer; c: char;
  procedure Add(a, b: integer; kind: char);
  begin
    SetLength(toks, length(toks) + 1);
    toks[high(toks)].s := Copy(s, a, b - a);
    toks[high(toks)].kind := kind;
    toks[high(toks)].a := a;
    toks[high(toks)].b := b;
    if kind = 'w' then toks[high(toks)].k := Encode(toks[high(toks)].s)
    else toks[high(toks)].k := toks[high(toks)].s;
  end;
var a: integer;
begin
  SetLength(toks, 0);
  i := 1; n := length(s);
  while i <= n do begin
    c := s[i];
    if c in [' ', #9, #10, #13] then begin inc(i); continue; end;
    a := i;
    if c = '''' then begin
      inc(i);
      while (i <= n) and (s[i] <> '''') do inc(i);
      inc(i);
      Add(a, i, 'l');
    end else if (c in ['0'..'9', 'A'..'Z', 'a'..'z', '-', '_']) or (ord(c) >= 128) then begin
      while (i <= n) and ((s[i] in ['0'..'9', 'A'..'Z', 'a'..'z', '-', '_']) or
        (ord(s[i]) >= 128)) do inc(i);
      Add(a, i, 'w');
    end else begin
      inc(i);
      Add(a, i, 'p');
    end;
  end;
end;

function Tok: TTok;
begin
  if tp <= high(toks) then Result := toks[tp]
  else begin Result.s := ''; Result.k := ''; Result.kind := 'e'; Result.a := length(frag) + 1; Result.b := Result.a; end;
end;

function AtEnd: boolean;
begin
  Result := (tp > high(toks)) or ((toks[tp].kind = 'p') and (toks[tp].s = ';'));
end;

function IsKw(const k: string): boolean;
begin
  Result := (tp <= high(toks)) and (toks[tp].kind = 'w') and (Copy(toks[tp].k, 1, 6) = KW(k));
end;

function IsP(const p: string): boolean;
begin
  Result := (tp <= high(toks)) and (toks[tp].kind = 'p') and (toks[tp].s = p);
end;

procedure Skip; begin inc(tp); end;

function SetNo: integer;
begin
  Result := KSetNo(Copy(Tok.k, 1, 6));
  if Result = 0 then Error('нет набора ' + Tok.s);
  Skip;
end;

function RecNo: integer;
begin
  Result := KRecNo(Copy(Tok.k, 1, 6));
  if Result = 0 then Error('нет записи ' + Tok.s);
  Skip;
end;

{ raw source text from the current token up to a stop word or ; }
function RawUntil(const stop: string): string;
var a, b: integer;
begin
  a := Tok.a; b := a;
  while not AtEnd and not ((stop <> '') and IsKw(stop)) do begin
    b := Tok.b; Skip;
  end;
  Result := Trim(Copy(frag, a, b - a));
end;

{ the set after the last В of a key expression }
function KeyExprAndSet(var s: integer): string;
var j, last: integer; a: integer;
begin
  last := -1;
  j := tp;
  while (j <= high(toks)) and not ((toks[j].kind = 'p') and (toks[j].s = ';')) do begin
    if (toks[j].kind = 'w') and (Copy(toks[j].k, 1, 6) = KW('В')) then last := j;
    inc(j);
  end;
  if last < 0 then begin Error('нет В в НАЙТИ ПО-КЛЮ'); s := 0; exit(''); end;
  a := Tok.a;
  if last = tp then Result := ''
  else Result := Trim(Copy(frag, a, toks[last].a - a));
  tp := last + 1;
  s := SetNo;
end;

function FieldRef(r: integer; const name: string; var fi: integer): boolean;
begin
  fi := KFieldNo(r, Copy(Encode(name), 1, 6));
  Result := fi > 0;
  if not Result then Error('нет поля ' + name);
end;

{ name.fld after the current token; r = 0: by field name over all types }
function Stmt: string;
var s, r, fi: integer; e, t, f, v: string;
begin
  Result := '';
  if IsKw('НАЙТИ') then begin
    Skip;
    if IsKw('ПО-КЛЮ') then begin
      Skip;
      e := KeyExprAndSet(s);
      if s = 0 then exit;
      if e = '' then begin
        { the key from the record variable of the member }
        r := KSetMember(s);
        if KSetKey(s) = 0 then begin Error('набор без ключа: ' + Decode(KSetName(s))); exit; end;
        e := RecVar(r) + '.' + Ident(KFieldName(r, KSetKey(s)));
      end;
      Result := 'KFINDKEY(' + IntToStr(s) + ', ' + e + ')';
      exit;
    end;
    if IsKw('ПЕРВУЮ') then t := 'FIRST'
    else if IsKw('СЛЕДУЮ') then t := 'NEXT'
    else if IsKw('ПРЕДЫД') then t := 'PRIOR'
    else if IsKw('ПОСЛЕД') then t := 'LAST'
    else if IsKw('ВЛАДЕЛ') then t := 'OWNER'
    else if IsKw('В') then t := 'FIRST'
    else begin Error('неверный НАЙТИ: ' + Tok.s); exit; end;
    if not IsKw('В') then Skip;
    if IsKw('В') then begin
      Skip; s := SetNo;
      Result := 'KFIND' + t + '(' + IntToStr(s) + ')';
    end else if not AtEnd then begin
      r := RecNo;
      if t = 'FIRST' then Result := 'KFINDFIRSTREC(' + IntToStr(r) + ')'
      else Result := 'KFINDNEXTREC(' + IntToStr(r) + ')';
    end else if (t = 'NEXT') or (t = 'PRIOR') then
      Result := 'KFIND' + t + '(0)'
    else Error('нет набора');
  end else if IsKw('ВЗЯТЬ') then begin
    Skip;
    if IsKw('БД-КЛЮ') then begin
      Skip; r := RecNo;
      if IsKw('НА') then Skip;
      v := RawUntil('');
      Result := v + ' := KDBKEY(' + IntToStr(r) + ')';
    end else if IsP('.') then begin
      { ВЗЯТЬ.fld: the run unit, by type }
      Skip; f := Tok.s; Skip;
      Result := 'case KCURTYPE of ';
      for r := 1 to KRecCount do
        if (RecVar(r) <> '') and (KFieldNo(r, Copy(Encode(f), 1, 6)) > 0) then
          Result := Result + IntToStr(r) + ': begin KBEGINGET(0); KGETF(' +
            IntToStr(KFieldNo(r, Copy(Encode(f), 1, 6))) + ', ' + RecVar(r) + '.' + f + ') end; ';
      Result := Result + 'end';
    end else if AtEnd then
      Result := 'ZZGETRU'
    else begin
      r := RecNo;
      if IsP('.') then begin
        Skip; f := Tok.s; Skip;
        if not FieldRef(r, f, fi) then exit;
        if IsKw('НА') then begin
          Skip; v := RawUntil('');
        end else v := RecVar(r) + '.' + f;
        Result := 'begin KBEGINGET(' + IntToStr(r) + '); KGETF(' + IntToStr(fi) +
          ', ' + v + ') end';
      end else
        Result := 'ZZGET' + IntToStr(r);
    end;
  end else if IsKw('ЗАМЕНИ') then begin
    Skip;
    if IsKw('БД-КЛЮ') then begin
      Skip; r := RecNo;
      if IsKw('НА') then Skip;
      v := RawUntil('');
      Result := 'KSETCUR(' + IntToStr(r) + ', ' + v + ')';
    end else if AtEnd then
      Result := 'ZZPUTRU'
    else begin
      r := RecNo;
      if IsP('.') then begin
        Skip; f := Tok.s; Skip;
        if not FieldRef(r, f, fi) then exit;
        if IsKw('НА') then begin Skip; v := RawUntil(''); end
        else v := RecVar(r) + '.' + f;
        { a set expression into an integer element: as 32 bits }
        if (KFieldKind(r, fi) = fkInt) and ((Pos('*[', v) > 0) or (Pos('+[', v) > 0) or
           (Pos('-[', v) > 0) or ((v <> '') and (v[1] = '['))) then
          v := 'longint(' + v + ')';
        Result := 'begin KBEGINGET(' + IntToStr(r) + '); KPUTF(' + IntToStr(fi) + ', ' +
          v + '); KMODIFY(' + IntToStr(r) + ') end';
      end else
        Result := 'begin ZZPUT' + IntToStr(r) + '; KMODIFY(' + IntToStr(r) + ') end';
    end;
  end else if IsKw('ПОСТАВ') then begin
    Skip; r := RecNo;
    Result := 'begin ZZPUT' + IntToStr(r) + '; KSTORE(' + IntToStr(r) + ') end';
  end else if IsKw('ВКЛЮЧИ') then begin
    Skip; if IsKw('В') then Skip;
    s := SetNo;
    if (s > 0) and (KSetUsing(s) <> '') then begin
      { ВЫБОР … ИСПОЛЬЗ rec.fld: the owner by the key in rec.fld }
      v := KSetUsing(s);
      Result := 'KCONNECTKEY(' + IntToStr(s) + ', ' +
        Ident(Copy(v, 1, Pos('.', v) - 1)) + '.' + Ident(Copy(v, Pos('.', v) + 1, 10)) + ')';
    end else
      Result := 'KCONNECT(' + IntToStr(s) + ')';
  end else if IsKw('ИСКЛЮЧ') then begin
    Skip; if IsKw('В') or IsKw('ИЗ') then Skip;
    Result := 'KDISCONNECT(' + IntToStr(SetNo) + ')';
  end else if IsKw('УБРАТЬ') then begin
    Skip;
    if AtEnd then Result := 'KERASE(0)'
    else Result := 'KERASE(' + IntToStr(RecNo) + ')';
  end else if IsKw('ЖУРНАЛ') then begin
    Skip;
    v := Decode(Copy(Encode(Tok.s) + '      ', 1, 6)); Skip;
    Result := 'begin ZZJNAME := ''' + v + '''; KOPEN(ZZJNAME) end';
  end else if IsKw('КОМПАС') or IsKw('РЕЖИМ') or IsKw('БЕЗ-SS') then begin
    while not AtEnd do Skip;
    Result := '';
  end else if IsKw('ЗАВЕРШ') then begin
    Skip; Result := 'KCLOSE';
  end else if IsKw('ПОДСХЕ') then begin
    while not AtEnd do Skip;
    Result := '';
  end else begin
    Error('неизвестный оператор ЯМД: ' + Tok.s);
    while not AtEnd do Skip;
  end;
  if not AtEnd then begin
    Error('лишний текст: ' + Tok.s);
    while not AtEnd do Skip;
  end;
end;

{ one &&…&& fragment -> Pascal }
function Expand(const f: string): string;
var parts: string; st: string;
begin
  frag := f;
  Lex(f);
  tp := 0;
  isExpr := false;
  Result := '';
  { declarations }
  if IsKw('ПОДСХЕ') or IsKw('ЯЗЫК') then begin
    if IsKw('ЯЗЫК') then Error('ЯЗЫК не поддерживается');
    if not KSchemaOk then begin
      Error('нет схемы в MARS_DIR (сначала servis и ttc)');
      exit;
    end;
    if not declared then Result := Declarations + 'var ZZJNAME: alfa;'#10;
    declared := true;
    isExpr := true;
    exit;
  end;
  if IsKw('НАБ') then begin
    isExpr := true; Skip;
    Result := IntToStr(SetNo);
    exit;
  end;
  if IsKw('ЗП') then begin
    isExpr := true; Skip;
    Result := IntToStr(RecNo);
    exit;
  end;
  if not declared then Error('нет &&ПОДСХЕ&& до операторов ЯМД');
  parts := '';
  while tp <= high(toks) do begin
    if IsP(';') then begin Skip; continue; end;
    st := Stmt;
    if st <> '' then begin
      if parts <> '' then parts := parts + '; ';
      parts := parts + st;
    end;
  end;
  Result := 'begin ' + parts;
  if parts <> '' then Result := Result + '; ';
  Result := Result + 'СОСТ := KSTAT end';
end;

{ --- front end: Free Pascal with Russian names -> plain Free Pascal --- }

const
  Taken: array[0..15] of string = ('SYSTEM', 'STRING', 'UNIT', 'USES', 'OBJECT',
    'INLINE', 'ASM', 'INTERFACE', 'IMPLEMENTATION', 'CONSTRUCTOR', 'DESTRUCTOR',
    'INHERITED', 'OPERATOR', 'ABSOLUTE', 'RESULT', 'SHORTSTRING');

{ a name with non-ASCII letters -> ASCII; homoglyphs give the same name }
function AsciiName(const v: string): string;
var e: string; i: integer; c: char;
begin
  e := Encode(v);
  Result := '';
  for i := 1 to length(e) do begin
    c := e[i];
    if c in ['0'..'9', 'A'..'Z', 'a'..'z', '_'] then Result := Result + c
    else Result := Result + 'Q' + OctStr(GostOf(ord(c)), 2) + '_';
  end;
  if (Result = '') or not (Result[1] in ['A'..'Z', 'a'..'z', '_']) then
    Result := '_' + Result;
  for i := 0 to high(Taken) do
    if UpperCase(Result) = Taken[i] then exit('KN_' + Result);
end;

{ a string literal body -> FPC literal in the internal code }
function CodeLit(const body: string): string;
var e: string; i: integer; quoted: boolean;
begin
  e := Encode(body);
  Result := '';
  quoted := false;
  for i := 1 to length(e) do
    if (e[i] >= ' ') and (e[i] <= '~') then begin
      if not quoted then begin Result := Result + ''''; quoted := true; end;
      if e[i] = '''' then Result := Result + '''''' else Result := Result + e[i];
    end else begin
      if quoted then begin Result := Result + ''''; quoted := false; end;
      Result := Result + '#' + IntToStr(ord(e[i]));
    end;
  if quoted then Result := Result + '''';
  if Result = '' then Result := '''''';
end;

function HasUnit(const clause, u: string): boolean;
var t: string; i: integer;
begin
  t := ',' + StringReplace(StringReplace(clause, ' ', '', [rfReplaceAll]),
    ';', ',', [rfReplaceAll]);
  for i := 1 to length(t) do if t[i] in [#9, #10, #13] then t[i] := ',';
  t := StringReplace(t, ',,', ',', [rfReplaceAll]);
  Result := Pos(',' + u + ',', UpperCase(t)) > 0;
end;

{ packed array[1..N] of char at s[i..]: N and the position after it }
function CharArr(const s: string; i: integer; var len, e: integer): boolean;
  procedure Blank;
  begin
    while (i <= length(s)) and (s[i] in [' ', #9, #10, #13]) do inc(i);
  end;
  function Lit(const t: string): boolean;
  begin
    Blank;
    Result := UpperCase(Copy(s, i, length(t))) = t;
    if Result then inc(i, length(t));
  end;
var a: integer;
begin
  Result := false;
  if not Lit('ARRAY') or not Lit('[') or not Lit('1') or not Lit('..') then exit;
  Blank;
  a := i;
  while (i <= length(s)) and (s[i] in ['0'..'9']) do inc(i);
  if (i = a) or not TryStrToInt(Copy(s, a, i - a), len) then exit;
  if not Lit(']') or not Lit('OF') or not Lit('CHAR') then exit;
  if (i <= length(s)) and (s[i] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then exit;
  e := i;
  Result := true;
end;

function Front(const s: string): string;
var i, j, k, n, state: integer;
    w, clause, add, decl: string;
    hasMode, ascii: boolean;
    len, e: integer;
    shapes: array of integer;
begin
  Result := '';
  n := length(s);
  i := 1;
  state := 0;          { 0 before PROGRAM, 1 in its header, 2 after, 3 done }
  hasMode := false;
  SetLength(shapes, 0);
  while i <= n do begin
    if s[i] = '{' then begin
      j := i;
      while (j <= n) and (s[j] <> '}') do inc(j);
      if (state = 0) and (UpperCase(Copy(s, i, 6)) = '{$MODE') then hasMode := true;
      Result := Result + Copy(s, i, j - i + 1);
      i := j + 1;
    end else if (s[i] = '(') and (i < n) and (s[i + 1] = '*') then begin
      j := i + 2;
      while (j < n) and not ((s[j] = '*') and (s[j + 1] = ')')) do inc(j);
      Result := Result + Copy(s, i, j - i + 2);
      i := j + 2;
    end else if (s[i] = '/') and (i < n) and (s[i + 1] = '/') then begin
      j := i;
      while (j <= n) and (s[j] <> #10) do inc(j);
      Result := Result + Copy(s, i, j - i);
      i := j;
    end else if s[i] = '''' then begin
      w := '';
      j := i + 1;
      while j <= n do begin
        if s[j] = '''' then begin
          if (j < n) and (s[j + 1] = '''') then begin w := w + ''''; inc(j, 2); continue; end;
          break;
        end;
        w := w + s[j];
        inc(j);
      end;
      Result := Result + CodeLit(w);
      i := j + 1;
    end else if (s[i] in ['A'..'Z', 'a'..'z', '_']) or (ord(s[i]) >= 128) then begin
      j := i;
      while (j <= n) and ((s[j] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) or (ord(s[j]) >= 128)) do
        inc(j);
      w := Copy(s, i, j - i);
      ascii := true;
      for k := 1 to length(w) do if ord(w[k]) >= 128 then ascii := false;
      if not ascii then w := AsciiName(w)
      else if UpperCase(w) = 'SYSTEM' then w := 'KN_' + w;  { the KOMPAS record }
      { one named type per shape: TP-mode arrays of the same shape are
        otherwise incompatible }
      if (UpperCase(w) = 'PACKED') and CharArr(s, j, len, e) then begin
        if len = 6 then Result := Result + 'alfa'
        else begin
          Result := Result + 'ZZC' + IntToStr(len);
          k := 0;
          while (k <= high(shapes)) and (shapes[k] <> len) do inc(k);
          if k > high(shapes) then begin
            SetLength(shapes, k + 1);
            shapes[k] := len;
          end;
        end;
        i := e;
        continue;
      end;
      if (state = 0) and (UpperCase(w) = 'PROGRAM') then state := 1
      else if state = 2 then begin
        { the first word after the header: the program's uses or none }
        state := 3;
        if UpperCase(w) = 'USES' then begin
          clause := Copy(s, j, n);
          clause := Copy(clause, 1, Pos(';', clause));
          add := '';
          if not HasUnit(clause, 'KRT') then add := add + ' krt,';
          if not HasUnit(clause, 'KIO') then add := add + ' kio,';
          if not HasUnit(clause, 'KDB') then add := add + ' kdb,';
          Result := Result + w + add + clause + #1;
          i := j + length(clause);
          continue;
        end else
          w := 'uses krt, kio, kdb;'#10#1 + w;
      end;
      Result := Result + w;
      i := j;
    end else begin
      if (state = 1) and (s[i] = ';') then state := 2;
      Result := Result + s[i];
      inc(i);
    end;
  end;
  decl := '';
  for k := 0 to high(shapes) do
    decl := decl + 'type ZZC' + IntToStr(shapes[k]) + ' = packed array[1..' +
      IntToStr(shapes[k]) + '] of char;'#10;
  Result := StringReplace(Result, #1, decl, []);
  if not hasMode then
    Result := '{$mode tp}{$H-}{$R-}{$Z4}{$packset 4}'#10 + Result;
end;

{ --- driver --- }

function NextWord(i: integer): string;
{ the significant text after position i, upper case, for ELSE }
var j: integer;
begin
  j := i;
  while (j <= length(src)) and (src[j] in [' ', #9, #10, #13]) do inc(j);
  Result := Copy(Encode(Copy(src, j, 8)), 1, 4);
end;

var
  i, j, n: integer;
  incom: boolean;
  e, inName, outName: string;
  f: TStringList;
  fs: TFileStream;
begin
  if ParamCount >= 1 then inName := ParamStr(1) else inName := '';
  if ParamCount >= 2 then outName := ParamStr(2) else outName := '';
  f := TStringList.Create;
  if inName <> '' then f.LoadFromFile(inName)
  else begin
    while not eof(input) do begin readln(e); f.Add(e); end;
  end;
  src := f.Text;
  outs := '';
  i := 1; n := length(src); incom := false;
  while i <= n do begin
    if src[i] = #10 then inc(lineNo);
    if not incom and (src[i] = '(') and (i < n) and (src[i + 1] = '*') then begin
      incom := true; outs := outs + '(*'; inc(i, 2); continue;
    end;
    if incom and (src[i] = '*') and (i < n) and (src[i + 1] = ')') then begin
      incom := false; outs := outs + '*)'; inc(i, 2); continue;
    end;
    if not incom and (src[i] = '{') then begin
      j := i;
      while (j <= n) and (src[j] <> '}') do inc(j);
      outs := outs + Copy(src, i, j - i + 1);
      i := j + 1; continue;
    end;
    if not incom and (src[i] = '''') then begin
      j := i + 1;
      while (j <= n) and (src[j] <> '''') and (src[j] <> #10) do inc(j);
      outs := outs + Copy(src, i, j - i + 1);
      i := j + 1; continue;
    end;
    if (src[i] = '&') and (i < n) and (src[i + 1] = '&') then begin
      j := i + 2;
      while (j < n) and not ((src[j] = '&') and (src[j + 1] = '&')) do inc(j);
      e := Expand(Copy(src, i + 2, j - i - 2));
      while i < j do begin if src[i] = #10 then inc(lineNo); inc(i); end;
      i := j + 2;
      if incom then
        { a fragment inside a comment: (*=L0 &&ПОДСХЕ X&&*) }
        outs := outs + '*)' + e + '(*'
      else begin
        outs := outs + e;
        { a statement carries its own terminator, except before ELSE }
        if not isExpr and (e <> '') and (Copy(NextWord(i), 1, 1) <> ';') and
           (NextWord(i) <> Encode('ELSE')) then outs := outs + ';';
      end;
      continue;
    end;
    outs := outs + src[i];
    inc(i);
  end;
  outs := Front(outs);
  if outName <> '' then begin
    fs := TFileStream.Create(outName, fmCreate);
    try
      if length(outs) > 0 then fs.WriteBuffer(outs[1], length(outs));
    finally
      fs.Free;
    end;
  end else
    write(outs);
  if errors > 0 then halt(1);
end.
