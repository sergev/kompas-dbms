{ MAD: the KOMPAS query language, on the kdb engine.

  Usage: mad [file]   (default: standard input, UTF-8)

  The text is parsed into a list of instructions with labels; ЕСЛИ with
  ТО_( … _)ИНАЧЕ … is lowered to jumps, so a jump may enter a block.
  ВЫДАТЬ (ВВ) prints one line: 'literals', .field of the current record,
  REC.FIELD of the current REC, and / for a line break. }
program mad;

{$mode objfpc}{$H+}

uses SysUtils, Classes, kdb, kgost;

type
  TTok = record
    s: string;       { internal code }
    kind: char;      { w word, l literal, p punctuation, e end }
    line: integer;
  end;
  TItem = record
    kind: char;      { l literal, f field, n newline }
    s: string;
    rec, fld: integer;   { rec 0: current of the run unit }
  end;
  TOp = (oNop, oFind, oGet, oGetKey, oSetKey, oOut, oJmp, oJz, oJnz, oEnd,
         oJournal);
  TIns = record
    op: TOp;
    sub: integer;    { find: 1 first 2 next 3 prior 4 last 5 owner 6 key
                       7 first of type 8 next of type }
    target: integer; { set, record; jumps: instruction or -label }
    key, lab: string;
    items: array of TItem;
    line: integer;
  end;

var
  toks: array of TTok;
  tp: integer;
  code: array of TIns;
  labels: TStringList;     { label -> instruction }
  fixups: TStringList;     { 'label' -> jump instruction index }
  errors: integer = 0;
  vars: TStringList;       { НА targets: name=value }
  gensym: integer = 0;

function KW(const s: string): string;
begin
  Result := Copy(Encode(s), 1, 6);
end;

procedure Error(line: integer; const msg: string);
begin
  writeln('ОШИБКА В СТРОКЕ ', line, ': ', msg);
  inc(errors);
end;

{ --- lexer --- }

function IsWordChar(c: char): boolean;
begin
  Result := (c in ['0'..'9', 'A'..'Z', 'a'..'z', '-']) or (ord(c) >= 128) or
    (c in ['#', '$', '@', '"']);
end;

procedure Lex(const text: string);
var i, n, line: integer; c: char; s: string;
  procedure Add(const v: string; k: char);
  begin
    SetLength(toks, length(toks) + 1);
    toks[high(toks)].s := v;
    toks[high(toks)].kind := k;
    toks[high(toks)].line := line;
  end;
begin
  i := 1; n := length(text); line := 1;
  while i <= n do begin
    c := text[i];
    if c = #10 then begin inc(line); inc(i); continue; end;
    if c in [' ', #13] then begin inc(i); continue; end;
    { comment ?* ... * }
    if (c = '?') and (i < n) and (text[i + 1] = '*') then begin
      inc(i, 2);
      while (i <= n) and (text[i] <> '*') do begin
        if text[i] = #10 then inc(line);
        inc(i);
      end;
      inc(i);
      continue;
    end;
    if c = '''' then begin
      s := ''; inc(i);
      while i <= n do begin
        if text[i] = '''' then begin
          if (i < n) and (text[i + 1] = '''') then begin s := s + ''''; inc(i, 2); continue; end;
          break;
        end;
        if text[i] = #10 then inc(line);
        s := s + text[i]; inc(i);
      end;
      inc(i);
      Add(s, 'l');
      continue;
    end;
    if (c = '_') and (i < n) and (text[i + 1] in ['(', ')']) then begin
      Add(c + text[i + 1], 'p'); inc(i, 2); continue;
    end;
    if (c = '<') and (i < n) and (text[i + 1] = '>') then begin
      Add('<>', 'p'); inc(i, 2); continue;
    end;
    if IsWordChar(c) then begin
      s := '';
      while (i <= n) and IsWordChar(text[i]) do begin s := s + text[i]; inc(i); end;
      Add(s, 'w');
      continue;
    end;
    Add(c, 'p');
    inc(i);
  end;
  Add('', 'e');
end;

{ --- parser --- }

function Tok: TTok; begin Result := toks[tp]; end;
function Peek(d: integer): TTok;
begin
  if tp + d <= high(toks) then Result := toks[tp + d] else Result := toks[high(toks)];
end;
procedure Skip; begin if tp < high(toks) then inc(tp); end;

function IsKw(const t: TTok; const k: string): boolean;
begin
  Result := (t.kind = 'w') and (Copy(t.s, 1, 6) = KW(k));
end;

function IsP(const t: TTok; const p: string): boolean;
begin
  Result := (t.kind = 'p') and (t.s = p);
end;

function Emit(op: TOp): integer;
begin
  SetLength(code, length(code) + 1);
  Result := high(code);
  code[Result].op := op;
  code[Result].line := Tok.line;
  code[Result].target := 0;
  code[Result].sub := 0;
end;

procedure JumpTo(i: integer; const lab: string);
begin
  code[i].lab := lab;
  fixups.AddObject(lab, TObject(PtrInt(i)));
end;

procedure DefLabel(const lab: string);
begin
  if labels.IndexOf(lab) >= 0 then Error(Tok.line, 'ПОВТОРНАЯ МЕТКА ' + Decode(lab));
  labels.AddObject(lab, TObject(PtrInt(length(code))));
end;

function NewLabel: string;
begin
  inc(gensym);
  Result := #1 + IntToStr(gensym);
end;

function SetOf(const t: TTok): integer;
begin
  Result := KSetNo(Copy(t.s, 1, 6));
  if Result = 0 then Error(t.line, 'НЕТ НАБОРА ' + Decode(t.s));
end;

function RecOf(const t: TTok): integer;
begin
  Result := KRecNo(Copy(t.s, 1, 6));
  if Result = 0 then Error(t.line, 'НЕТ ЗАПИСИ ' + Decode(t.s));
end;

procedure ParseStmts(stop: string); forward;

procedure ParseOut(i: integer);
var t: TTok; it: TItem; r: integer;
begin
  repeat
    t := Tok;
    it.kind := ' '; it.s := ''; it.rec := 0; it.fld := 0;
    if t.kind = 'l' then begin it.kind := 'l'; it.s := t.s; Skip; end
    else if IsP(t, '/') then begin it.kind := 'n'; Skip; end
    else if IsP(t, '.') then begin
      Skip; it.kind := 'f'; it.rec := 0; it.s := Copy(Tok.s, 1, 6); Skip;
    end else if (t.kind = 'w') and IsP(Peek(1), '.') then begin
      r := RecOf(t); Skip; Skip;
      it.kind := 'f'; it.rec := r; it.s := Copy(Tok.s, 1, 6);
      if (r > 0) and (KFieldNo(r, it.s) = 0) then
        Error(Tok.line, 'НЕТ ПОЛЯ ' + Decode(Tok.s));
      Skip;
    end else begin
      Error(t.line, 'НЕВЕРНЫЙ ЭЛЕМЕНТ ВЫДАЧИ ' + Decode(t.s));
      Skip;
    end;
    if it.kind <> ' ' then begin
      SetLength(code[i].items, length(code[i].items) + 1);
      code[i].items[high(code[i].items)] := it;
    end;
    if not IsP(Tok, ',') then break;
    Skip;
  until false;
end;

{ target or source of БД-КЛЮ: a name, maybe REC.FLD }
function VarName: string;
begin
  Result := Tok.s; Skip;
  if IsP(Tok, '.') then begin Skip; Result := Result + '.' + Tok.s; Skip; end;
end;

procedure ParseSimple;
var t: TTok; i: integer; l1, l2: string; neg: boolean;

  procedure Branch;
  { НА label, _( stmts _), or one statement }
  var j: integer;
  begin
    if IsKw(Tok, 'НА') then begin
      Skip; j := Emit(oJmp); JumpTo(j, Tok.s); Skip;
    end else if IsP(Tok, '_(') then begin
      Skip; ParseStmts('_)');
      if IsP(Tok, '_)') then Skip;
    end else
      ParseSimple;
  end;

begin
  t := Tok;
  { label }
  while (t.kind = 'w') and IsP(Peek(1), ':') do begin
    DefLabel(t.s); Skip; Skip; t := Tok;
  end;
  if IsP(t, ';') or IsP(t, '_)') or (t.kind = 'e') then exit;
  if IsKw(t, 'НАЙТИ') then begin
    Skip; i := Emit(oFind);
    t := Tok;
    if IsKw(t, 'ПЕРВУЮ') then code[i].sub := 1
    else if IsKw(t, 'СЛЕДУЮ') then code[i].sub := 2
    else if IsKw(t, 'ПРЕДЫД') then code[i].sub := 3
    else if IsKw(t, 'ПОСЛЕД') then code[i].sub := 4
    else if IsKw(t, 'ВЛАДЕЛ') then code[i].sub := 5
    else if IsKw(t, 'ПО-КЛЮ') then code[i].sub := 6
    else Error(t.line, 'НЕВЕРНЫЙ НАЙТИ ' + Decode(t.s));
    Skip;
    if code[i].sub = 6 then begin
      if IsKw(Tok, 'В') then Error(Tok.line, 'НЕТ КЛЮЧА')
      else begin code[i].key := Tok.s; Skip; end;
    end;
    if IsKw(Tok, 'В') then begin
      Skip; code[i].target := SetOf(Tok); Skip;
    end else if (Tok.kind = 'w') and (code[i].sub in [1, 2]) then begin
      { НАЙТИ ПЕРВУЮ <rec>: the records of a type }
      code[i].target := RecOf(Tok); code[i].sub := code[i].sub + 6; Skip;
    end else if code[i].sub in [1, 4, 5, 6] then
      Error(Tok.line, 'НЕТ НАБОРА');
  end else if IsKw(t, 'ВЗЯТЬ') then begin
    Skip;
    if IsKw(Tok, 'БД-КЛЮ') then begin
      Skip; i := Emit(oGetKey); code[i].target := RecOf(Tok); Skip;
      if IsKw(Tok, 'НА') then Skip;
      code[i].key := VarName;
    end else begin
      i := Emit(oGet);
      if Tok.kind = 'w' then begin code[i].target := RecOf(Tok); Skip; end;
    end;
  end else if IsKw(t, 'ЗАМЕНИ') and IsKw(Peek(1), 'БД-КЛЮ') then begin
    Skip; Skip; i := Emit(oSetKey); code[i].target := RecOf(Tok); Skip;
    if IsKw(Tok, 'НА') then Skip;
    code[i].key := VarName;
  end else if IsKw(t, 'ВЫДАТЬ') or IsKw(t, 'ВВ') then begin
    Skip; i := Emit(oOut); ParseOut(i);
  end else if IsKw(t, 'ЕСЛИ') then begin
    Skip;
    if not IsKw(Tok, 'СОС') then Error(Tok.line, 'ОЖИДАЕТСЯ СОС');
    Skip;
    neg := IsP(Tok, '<>');
    if not (IsP(Tok, '=') or neg) then Error(Tok.line, 'ОЖИДАЕТСЯ = ИЛИ <>');
    Skip;
    if Tok.s <> '0' then Error(Tok.line, 'ОЖИДАЕТСЯ 0');
    Skip;
    if not IsKw(Tok, 'ТО') then Error(Tok.line, 'ОЖИДАЕТСЯ ТО');
    Skip;
    l1 := NewLabel; l2 := NewLabel;
    { jump to else when the condition fails }
    if neg then i := Emit(oJz) else i := Emit(oJnz);
    JumpTo(i, l1);
    Branch;
    if IsKw(Tok, 'ИНАЧЕ') then begin
      i := Emit(oJmp); JumpTo(i, l2);
      DefLabel(l1);
      Skip;
      Branch;
      DefLabel(l2);
    end else
      DefLabel(l1);
  end else if IsKw(t, 'НА') then begin
    Skip; i := Emit(oJmp); JumpTo(i, Tok.s); Skip;
  end else if IsKw(t, 'КОНЕЦ') or (IsKw(t, 'К') and (t.s = KW('К'))) then begin
    Skip; Emit(oEnd);
  end else if IsKw(t, 'ЖУРНАЛ') then begin
    Skip; i := Emit(oJournal); code[i].key := Tok.s; Skip;
  end else if IsKw(t, 'РЕЖИМ') or IsKw(t, 'ПОДСХЕ') then begin
    Skip; Skip;
  end else if IsKw(t, 'ДЛЯ-ВЫ') or IsKw(t, 'СБРОСИ') or IsKw(t, 'ЗАВЕРШ') then
    Skip
  else begin
    Error(t.line, 'НЕИЗВЕСТНЫЙ ОПЕРАТОР ' + Decode(t.s));
    while not (IsP(Tok, ';') or (Tok.kind = 'e')) do Skip;
  end;
end;

procedure ParseStmts(stop: string);
begin
  while Tok.kind <> 'e' do begin
    if (stop <> '') and IsP(Tok, stop) then exit;
    ParseSimple;
    if IsP(Tok, ';') then Skip
    else if (stop <> '') and IsP(Tok, stop) then exit
    else if Tok.kind <> 'e' then begin
      { statements may also be separated by a line break only }
      if IsP(Tok, '_)') then begin Error(Tok.line, 'ЛИШНЯЯ _)'); Skip; end;
    end;
  end;
end;

procedure Resolve;
var i, j, k: integer;
begin
  for i := 0 to fixups.Count - 1 do begin
    k := PtrInt(fixups.Objects[i]);
    j := labels.IndexOf(fixups[i]);
    if j < 0 then Error(code[k].line, 'НЕТ МЕТКИ ' + Decode(fixups[i]))
    else code[k].target := PtrInt(labels.Objects[j]);
  end;
end;

{ --- run --- }

function FieldOf(const it: TItem): string;
var r, f: integer;
begin
  Result := '';
  if it.rec = 0 then KBEGINGET(0) else KBEGINGET(it.rec);
  if KSTAT <> kOk then exit;
  r := KBufType;
  f := KFieldNo(r, it.s);
  if f = 0 then exit;
  Result := KFieldText(f);
end;

procedure Run;
var pc, j: integer; st: int64; outl: string; it: TItem; k: int64;
    jn: array[0..5] of char;
begin
  pc := 0; st := 0;
  while (pc >= 0) and (pc <= high(code)) do begin
    with code[pc] do begin
      case op of
        oFind: begin
          case sub of
            1: KFINDFIRST(target);
            2: KFINDNEXT(target);
            3: KFINDPRIOR(target);
            4: KFINDLAST(target);
            5: KFINDOWNER(target);
            6: KFindKeyText(target, key);
            7: KFINDFIRSTREC(target);
            8: KFINDNEXTREC(target);
          end;
          st := KSTAT;
        end;
        oGet: begin KBEGINGET(target); st := KSTAT; end;
        oGetKey: begin
          k := KDBKEY(target); st := KSTAT;
          vars.Values[key] := IntToStr(k);
        end;
        oSetKey: begin
          k := StrToInt64Def(vars.Values[key], 0);
          KSETCUR(target, k); st := KSTAT;
        end;
        oOut: begin
          outl := '';
          for j := 0 to high(items) do begin
            it := items[j];
            case it.kind of
              'l': outl := outl + it.s;
              'n': begin writeln(TrimRight(Decode(outl))); outl := ''; end;
              'f': outl := outl + FieldOf(it);
            end;
          end;
          writeln(TrimRight(Decode(outl)));
        end;
        oJmp: begin pc := target; continue; end;
        oJz: if st = 0 then begin pc := target; continue; end;
        oJnz: if st <> 0 then begin pc := target; continue; end;
        oEnd: break;
        oJournal: begin
          for j := 0 to 5 do
            if j < length(key) then jn[j] := key[j + 1] else jn[j] := ' ';
          KOPEN(jn);
        end;
      end;
    end;
    inc(pc);
  end;
end;

var
  text, s: string;
  f: TStringList;
  i: integer;
begin
  f := TStringList.Create;
  if ParamCount >= 1 then f.LoadFromFile(ParamStr(1))
  else begin
    text := '';
    while not eof(input) do begin readln(s); f.Add(s); end;
  end;
  text := '';
  for i := 0 to f.Count - 1 do begin
    s := Encode(f[i]);
    { job cards *M, *MAD, *YESME; a lone * closes a comment }
    if (length(s) > 1) and (s[1] = '*') and (s[2] <> ' ') then s := '';
    text := text + s + #10;
  end;
  if not KSchemaOk then begin
    writeln('ОШИБКА: НЕТ СХЕМЫ (ttc) В ', GetEnvironmentVariable('MARS_DIR'));
    halt(2);
  end;
  labels := TStringList.Create;
  fixups := TStringList.Create;
  vars := TStringList.Create;
  Lex(text);
  tp := 0;
  ParseStmts('');
  Resolve;
  if errors > 0 then halt(1);
  Run;
end.
