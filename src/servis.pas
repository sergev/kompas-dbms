{$mode tp}{$H-}{$R-}{$Z4}
program servis; uses krt, kio, mars, kdb; type XT0 = array[1..11] of integer; XT1 = array[1..64] of alfa; XT4 = array[1..16] of alfa; XT5 = array[1..4] of integer;
(* SERVIS: allocation and maintenance of the database areas.
   Each SERVIS area is a separate MARS area named after the object.
   Descriptor: [1] code, [2] length, [3] capture, [4] kind,
   [5] head code, [6] journal state, [7] control, [8] mode,
   [9] direction, [10] start, [11] reserved. *)
type
  RecT = XT0;
  LinT = packed array[1..72] of char;
var
  BDVECT: array [0..167] of integer;
  BDERRN: integer;
  PIC: integer;
  ln: LinT;
  r, ur: RecT;
  k, k2, kw, kw2: alfa;
  p, ncode, ncnt, dl, cur, lasterr: integer;
  nms: XT1;
  ades: array [1..24] of RecT;
  unms, rnms, robj, rtyp: XT4;
  un, rn: integer;
  nxt: char;
  nn: XT5;






function EXN:integer;
begin
  EXN := BDERRN
end;

(* PASBDI clears the sticky MARS error word. *)
procedure ClrErr;
begin
   begin 
  pasbdi;
  BDERRN := 0
   end ;
end;

procedure Err(n:integer);
begin
   begin 
  lasterr := n;
  write('ОШИБКА ',RT_W( n), ': ');
  case n of
    3: writeln('ОБЛАСТЬ НЕ ОПРЕДЕЛЕНА');
    4: writeln('УЖЕ ЕСТЬ АДМИНИСТРАТОР');
    5: writeln('НЕСУЩЕСТВУЮЩЕЕ ПРАВО');
    6: writeln('НЕТ ПРАВ ДОСТУПА');
    7: writeln('ПЕРЕПОЛНЕНА ADA');
    11: writeln('ЕСТЬ ВАРИАНТЫ');
    50: writeln('НЕТ ПРАВА ДЛЯ-МО');
    51: writeln('ОБЪЕКТ ПРАВА НЕ НАЙДЕН');
    52: writeln('ГОЛОВНАЯ ОБЛАСТЬ НЕ НАЙДЕНА');
    53: writeln('ОШИБКА В ОПРЕДЕЛЕНИИ ДУБЛЯ');
    54: writeln('ОБЛАСТЬ НЕ ЯВЛЯЕТСЯ ДУБЛЕМ');
    55: writeln('ОБЛАСТЬ НЕ ИМЕЕТ ДУБЛЕЙ');
    56: writeln('ОТСУТСТВУЕТ СЛОВО НА');
    57: writeln('ОБЛАСТИ НЕ ЯВЛЯЮТСЯ ДУБЛЯМИ');
    58: writeln('ДЛИНА ДУБЛЯ БОЛЬШЕ ГОЛОВНОЙ');
    60: writeln('УБИРАЕМАЯ ОБЛАСТЬ ИМЕЕТ ДУБЛИ');
    61: writeln('ПРОСТРАНСТВО НЕ ПУСТО');
    62: writeln('ОБЛАСТЬ СВЯЗАНА СО СХЕМОЙ');
    63: writeln('ОБЛАСТЬ СВЯЗАНА С ПОДСХЕМОЙ');
    64: writeln('НЕТ ДВОЕТОЧИЯ ИЛИ ;');
    65: writeln('ДЛИНА ВАРИАНТА БОЛЬШЕ ГОЛОВНОЙ');
    66: writeln('ДЛИНА ДУБЛЯ БОЛЬШЕ ГОЛОВНОЙ');
    67: writeln('ОБЛАСТЬ НЕ ОБЪЯВЛЕНА ЖУРНАЛОМ');
    68: writeln('ЖУРНАЛ ЗАХВАЧЕН ПРОЦЕССОМ');
    69: writeln('СБРОС ПОСЛЕ ЗАКРЕПЛЕНИЯ');
    70: writeln('НЕТ ОБЛАСТИ ЖУРНАЛА');
    71: writeln('НЕТ ПАРАМЕТРОВ ЗАМЕНЫ');
    72: writeln('ЗАМЕНЯЕМЫЙ ОБЪЕКТ НЕ НАЙДЕН');
    74: writeln('НЕ АДМИНИСТРАТОР');
    76: writeln('НЕДОПУСТИМОЕ СЛОВО');
    77: writeln('НЕДОПУСТИМОЕ СЛОВО ПОСЛЕ ЗАМЕНЫ');
    78: writeln('НЕ УКАЗАН ОБЪЕКТ');
    80: writeln('ОБЪЕКТ УЖЕ ЕСТЬ');
    83: writeln('НЕ УКАЗАНО СБРОСИ ИЛИ ЗАКРЕПИ');
    84: writeln('НЕПРАВИЛЬНОЕ ПЕРВОЕ СЛОВО');
    87: writeln('НЕ МОЖЕТ БЫТЬ ПОСТАВЛЕН');
  end
   end ;
end;

procedure Skip;
begin
   begin 
  while (p <= 72) and (ln[p] = ' ') do p := p + 1
   end ;
end;

(* First six significant characters of the current token. *)
function Tok:alfa;
var t:alfa; j:integer;
begin
   begin 
  for j := 1 to 6 do t[j] := ' ';
  Skip;
  j := 1;
  while (p <= 72) and (j <= 6) and (ln[p] <> ' ') and
        (ln[p] <> ':') and (ln[p] <> ';') and (ln[p] <> ',') and
        (ln[p] <> '.') do begin
    t[j] := ln[p];
    p := p + 1;
    j := j + 1
  end;
  while (p <= 72) and (ln[p] <> ' ') and (ln[p] <> ':') and
        (ln[p] <> ';') and (ln[p] <> ',') and
        (ln[p] <> '.') do p := p + 1;
  Tok := t
   end ;
end;

procedure GetName(var t:alfa);
var j:integer;
begin
   begin 
  for j := 1 to 6 do t[j] := ' ';
  Skip;
  j := 1;
  while (p <= 72) and (j <= 6) and (ln[p] <> ' ') and
        (ln[p] <> ':') and (ln[p] <> ';') and
        (ln[p] <> ',') and (ln[p] <> '.') do begin
    t[j] := ln[p];
    j := j + 1;
    p := p + 1
  end;
  while (p <= 72) and (ln[p] <> ' ') and (ln[p] <> ':') and
        (ln[p] <> ';') and (ln[p] <> ',') do p := p + 1
   end ;
end;

function Number:integer;
var v:integer;
begin
   begin 
  Skip;
  v := 0;
  while (p <= 72) and (ln[p] >= '0') and (ln[p] <= '9') do begin
    v := v * 10 + ord(ln[p]) - ord('0');
    p := p + 1
  end;
  Number := v
   end ;
end;

procedure Kadd(nm:alfa);
begin
   begin 
  if ncnt < 64 then begin
    ncnt := ncnt + 1;
    nms[ncnt] := nm
  end
   end ;
end;

function Kfind(nm:alfa):boolean;
var j:integer;
begin
   begin 
  Kfind := false;
  for j := 1 to ncnt do
    if nms[j] = nm then Kfind := true
   end ;
end;

procedure Kdel(nm:alfa);
var j,t:integer;
begin
   begin 
  for j := 1 to ncnt do
    if nms[j] = nm then begin
      for t := j to ncnt-1 do begin
        nms[t] := nms[t+1];
        ades[t] := ades[t+1]
      end;
      ncnt := ncnt - 1
    end
   end ;
end;

procedure UstOBL(var d:RecT; l,kind:integer);
var j:integer;
begin
   begin 
  for j := 1 to 11 do d[j] := 0;
  d[1] := ncode;
  d[2] := l;
  d[3] := 1;
  d[4] := kind;
  d[5] := 0;
  d[6] := 0;
  d[7] := 0;
  d[8] := 0;
  d[9] := 0;
  d[10] := 1
   end ;
end;

function IdxOf(nm:alfa):integer;
var j:integer;
begin
   begin 
  IdxOf := 0;
  for j := 1 to ncnt do
    if nms[j] = nm then IdxOf := j
   end ;
end;

function GetRec(nm:alfa; var d:RecT):boolean;
var j:integer;
begin
   begin 
  j := IdxOf(nm);
  if j > 0 then begin
    d := ades[j];
    cur := j;
    GetRec := true
  end else
    GetRec := false
   end ;
end;

procedure PutRec(nm:alfa; var d:RecT);
var j:integer;
begin
   begin 
  j := IdxOf(nm);
  if j > 0 then ades[j] := d
   end ;
end;

(* SETFL/CLFL of TSERVIS: open the named MARS area. *)
procedure SETFL(a:integer);
begin
   begin 
  if a = 0 then opend(k);
  if a = 2 then opend(k)
   end ;
end;

procedure CLFL(a:integer);
begin
end;

procedure NewArea(nm:alfa; var d:RecT);
begin
   begin 
  if Kfind(nm) then
    Err(80)
  else begin
    ncode := ncode + 1;
    Kadd(nm);
    d[1] := ncode;
    ClrErr;
    newd(nm);
    ClrErr;
    ades[ncnt] := d;
    k := nm;
    writeln('New Area N = ',RT_W( ncode))
  end
   end ;
end;

procedure AErase(nm:alfa);
begin
   begin 
  if GetRec(nm, r) then begin
    cleard(nm);
    ClrErr;
    write(RT_W(nm), ' ');
    writeln('ОЧИЩЕНА')
  end else Err(3)
   end ;
end;

procedure Osvobo(nm:alfa);
begin
   begin 
  if GetRec(nm, r) then begin
    r[3] := 0;
    PutRec(nm, r);
    write(RT_W(nm), ' ');
    writeln('ОСВОБОЖДЕНА')
  end else Err(3)
   end ;
end;

(* ВОССТА: the after-images of the area from every journal area
   (ВИД ЖУРНАЛ), in the order written *)
procedure Bocct(nm:alfa);
var j,n,t:integer; found:boolean;
begin
   begin 
  if GetRec(nm, r) then begin
    writeln('ВОССТАНОВЛЕНИЕ ',RT_W( nm));
    found := false;
    t := 0;
    for j := 1 to ncnt do
      if ades[j][4] = 2 then begin
        n := KREPLAY(nms[j], nm);
        if n >= 0 then begin
          found := true;
          t := t + n
        end
      end;
    ClrErr;
    if not found then Err(70)
    else begin
      writeln('ЗАПИСЕЙ ',RT_W( t));
      writeln('ВОССТАНОВЛЕНО')
    end
  end else Err(3)
   end ;
end;

procedure Obnovi(nm:alfa);
begin
   begin 
  if GetRec(nm, r) then begin
    PutRec(nm, r);
    writeln('ОБНОВЛЕНО ',RT_W( nm))
  end else Err(3)
   end ;
end;

function CodeOf(nm:alfa):integer;
begin
   begin 
  CodeOf := 0;
  if GetRec(nm, ur) then CodeOf := ur[1]
   end ;
end;

procedure Dubl;
var n3,n4:alfa; c3,c4:integer;
begin
   begin 
  kw2 := Tok;
  if kw2 = 'НА    ' then begin
    GetName(n4);
    c4 := CodeOf(n4);
    if c4 = 0 then Err(52)
    else if cur = 0 then Err(3)
    else if GetRec(nms[cur], r) then begin
      r[4] := 4;
      r[5] := c4;
      PutRec(nms[cur], r);
      writeln('ДУБЛЬ ',RT_W( nms[cur]), ' НА ',RT_W( n4))
    end
  end else if kw2 = 'С     ' then begin
    GetName(n4);
    if not GetRec(nms[cur], r) then Err(3)
    else if r[4] <> 4 then Err(54)
    else if not GetRec(n4, ur) then Err(52)
    else begin
      if ur[2] > r[2] then Err(58)
      else begin
        writeln('ДУБЛЬ С ',RT_W( n4), ' ВЫПОЛНЕН')
      end
    end
  end else begin
    n3 := kw2;
    kw2 := Tok;
      if kw2 <> 'НА    ' then Err(56)
      else begin
        GetName(n4);
        c3 := CodeOf(n4);
        if c3 = 0 then Err(52)
        else if not GetRec(n4, ur) then Err(52)
        else if Kfind(n3) then Err(80)
        else begin
          r := ur;
          UstOBL(r, ur[2], 4);
          NewArea(n3, r);
          if GetRec(n3, r) then begin
            r[5] := c3;
            PutRec(n3, r)
          end;
          writeln('ДУБЛЬ ',RT_W( n3), ' СОЗДАН')
        end
      end
    end
   end ;
end;

procedure Osvabd;
var j:integer;
begin
   begin 
  j := 0;
  for cur := 1 to ncnt do
    if GetRec(nms[cur], r) then begin
      PutRec(nms[cur], r);
      j := j + 1
    end;
  writeln('ОСВАБД: ЗАПИСАНО ОБЛАСТЕЙ ',RT_W( j))
   end ;
end;

procedure Journal;
var nm:alfa; st:integer;
begin
   begin 
  GetName(nm);
  if not GetRec(nm, r) then Err(3)
  else begin
    if r[4] <> 2 then Err(67)
    else begin
      kw2 := Tok;
      if kw2 = 'СБРОСИ' then begin
        if r[6] = 2 then Err(69)
        else begin
          r[6] := 1;
          PutRec(nm, r);
          cleard(nm);
          ClrErr;
          writeln('ЖУРНАЛ ',RT_W( nm), ' СБРОШЕН')
        end
      end else if kw2 = 'ЗАКРЕП' then begin
        if r[3] <> 0 then Err(68)
        else begin
          r[6] := 2;
          PutRec(nm, r);
          writeln('ЖУРНАЛ ',RT_W( nm), ' ЗАКРЕПЛЕН')
        end
      end else Err(83)
    end
  end
   end ;
end;

procedure Ubrat;
var nm:alfa; j,cc:integer; found:boolean;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ОБЛАСТ' then Err(78)
  else begin
    GetName(nm);
    if not GetRec(nm, r) then Err(3)
    else begin
      cc := r[1];
      found := false;
      for j := 1 to ncnt do
        if GetRec(nms[j], ur) then
          if (ur[5] = cc) and (nms[j] <> nm) then found := true;
      if found then Err(60)
      else if r[3] <> 0 then Err(50)
      else begin
        Kdel(nm);
        dropd(nm);
        ClrErr;
        writeln('ОБЛАСТЬ ',RT_W( nm), ' УБРАНА')
      end
    end
  end
   end ;
end;


(* Parameters of CREATE/CHANGE AREA. *)
procedure Params(var d:RecT; var l:integer);
var nm:alfa; v:integer;
begin
   begin 
  repeat
    if (p > 72) or (ln[p] = ';') or (ln[p] = ',') or
       (ln[p] = '.') then p := 73
    else begin
      kw2 := Tok;
      if (kw2 = 'ДЛИНА ') then begin
        v := Number;
        if (v < 1) or (v > 1750) then Err(76) else l := v
      end else if (kw2 = 'НАПР  ') then
        d[9] := Number
      else if (kw2 = 'НАЧАЛО') then
        d[10] := Number
      else if (kw2 = 'ВИД   ') then begin
        nm := Tok;
        if nm = 'ЖУРНАЛ' then d[4] := 2 else d[4] := 1
      end else if (kw2 = 'ВАРИАН') then begin
        GetName(nm);
        d[5] := CodeOf(nm)
      end else if (kw2 = 'ДУБЛЬ ') or (kw2 = 'ДУБЬ  ') then begin
        GetName(nm);
        d[5] := CodeOf(nm);
        d[4] := 4
      end else if (kw2 = 'РЕЖИМ ') then
        d[8] := Number
      else if (kw2 = 'ПАРОЛЬ') then begin
        nm := Tok;
        d[7] := 1
      end else if (kw2 = 'КОНТРО') then
        d[7] := Number
      else begin
        Err(76);
        p := 73
      end
    end
  until p > 72
   end ;
end;

procedure CreAr;
var kind:integer;
begin
   begin 
  if kw = 'СОЗДАТ' then begin
    kw2 := Tok;
    if kw2 <> 'ОБЛАСТ' then Err(78)
  end;
  GetName(k);
  if k = '      ' then Err(78)
  else begin
    dl := 1;
    kind := 1;
    Skip;
    if p <= 72 then begin
      if ln[p] = ':' then p := p + 1;
      if (ln[p] = ',') or (ln[p] = ';') then p := 73
      else if p <= 72 then begin
        UstOBL(r, dl, kind);
        Params(r, dl)
      end
    end;
    r[2] := dl;
    if Kfind(k) then Err(80) else NewArea(k, r)
  end
   end ;
end;

procedure Izmeni;
var nm:alfa; nd:integer;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ОБЛАСТ' then Err(77)
  else begin
    GetName(nm);
    if not GetRec(nm, r) then Err(72)
    else begin
      Skip;
      if (p > 72) or (ln[p] <> ':') then Err(64)
      else begin
        p := p + 1;
        nd := r[2];
        Params(r, nd);
        r[2] := nd;
        PutRec(nm, r);
        writeln('ОБЛАСТЬ ',RT_W( nm), ' ИЗМЕНЕНА')
      end
    end
  end
   end ;
end;

procedure AddUser;
var nm,pw:alfa;
begin
   begin 
  GetName(nm);
  if nm = '      ' then Err(78)
  else if un >= 16 then Err(87)
  else begin
    unms[un+1] := nm;
    un := un + 1;
    Skip;
    if (p <= 72) and (ln[p] = ':') then begin
      p := p + 1;
      kw2 := Tok;
      if kw2 = 'ПАРОЛЬ' then pw := Tok
    end;
    writeln('ПОЛЬЗОВАТЕЛЬ ',RT_W( nm), ' СОЗДАН')
  end
   end ;
end;

procedure AddRight;
var us,ob,ty,rt:alfa; ok:boolean;
begin
   begin 
  kw2 := Tok;
  if kw2 <> 'ПОЛЬЗО' then Err(78)
  else begin
    GetName(us);
    kw2 := Tok;
    if (kw2 = 'ОБЛАСТ') or (kw2 = 'ПОДСХЕ') or
       (kw2 = 'СХЕМЫ ') then ty := kw2 else ty := kw2;
    GetName(ob);
    Skip;
    if (p <= 72) and (ln[p] = ':') then p := p + 1;
    rt := Tok;
    ok := (rt = 'ДЛЯ-ВЫ') or (rt = 'ДЛЯ-МО');
    if not ok then Err(5)
    else if rn >= 16 then Err(7)
    else if (ty <> 'ОБЛАСТ') and (ty <> 'ПОДСХЕ') and
            (ty <> 'СХЕМЫ ') then Err(77)
    else if (ty = 'ОБЛАСТ') and (not Kfind(ob)) then Err(51)
    else begin
      rn := rn + 1;
      rnms[rn] := us;
      robj[rn] := ob;
      rtyp[rn] := rt;
      writeln('ПРАВО ',RT_W( rt), ' ',RT_W( us), ' НА ',RT_W( ob), ' ДАНО')
    end
  end
   end ;
end;

procedure Create;
begin
   begin 
  kw2 := Tok;
  if kw2 = 'ПОЛЬЗО' then AddUser
  else if kw2 = 'ПРАВО ' then AddRight
  else if kw2 = 'ОБЛАСТ' then CreAr
  else Err(78)
   end ;
end;

procedure Names(cmd:alfa);
var nm:alfa;
begin
   begin 
  k2 := cmd;
  repeat
    Skip;
    if (p <= 72) and (ln[p] = ',') then p := p + 1;
    GetName(nm);
    if nm <> '      ' then begin
      if cmd = 'ОЧИСТИ' then AErase(nm);
      if cmd = 'ОСВОБО' then Osvobo(nm);
      if cmd = 'ВОССТА' then Bocct(nm)
    end
  until (nm = '      ') or (p > 72)
   end ;
end;

procedure Stmt;
begin
   begin 
  Skip;
  if p <= 72 then begin
    if (ln[p] = '?') or (ln[p] = '*') then p := 73
    else if (ln[p] = ';') or (ln[p] = ',') then p := p + 1
    else if ln[p] = '.' then p := p + 1
    else begin
      kw := Tok;
      if (kw = 'ОЧИСТИ') or (kw = 'ОСВОБО') or (kw = 'ВОССТА') then
        Names(kw)
      else if (kw = 'СОЗДАТ') then Create
      else if (kw = 'ОБЛАСТ') or (kw = 'ПРОСТР') then CreAr
      else if (kw = 'ИЗМЕНИ') then Izmeni
      else if (kw = 'ОБНОВИ') then begin
        GetName(k);
        if k <> '      ' then Obnovi(k) else Err(78)
      end else if (kw = 'ДУБЛЬ ') then Dubl
      else if (kw = 'ОСВАБД') then Osvabd
      else if (kw = 'ЖУРНАЛ') then Journal
      else if (kw = 'УБРАТЬ') then Ubrat
      else if (kw = 'В     ') then p := 73
      else if (kw = 'КОНЕЦ ') or (kw = 'КОНЕЦ.') then p := 73
      else if k2 <> '      ' then begin
        p := 1;
        Skip;
        Names(k2)
      end
      else Err(84)
    end
  end
   end ;
end;

(* The descriptors of the areas live in the MARS area SERVIS:
   #NCNT = count and last code, #NMS = the names, <name> = its RecT. *)
procedure LoadAreas;
var j:integer;
begin
   begin 
  newd('SERVIS');
  ClrErr;
  opend('SERVIS');
  getd('#NCNT ', nn, sizeof(nn));
  if BDERRN = 0 then begin
    ncnt := nn[1];
    ncode := nn[2];
    getd('#NMS  ', nms, sizeof(nms));
    for j := 1 to ncnt do getd(nms[j], ades[j], sizeof(RecT))
  end;
  ClrErr
   end ;
end;

procedure SaveAreas;
var j:integer;
begin
   begin 
  cleard('SERVIS');
  opend('SERVIS');
  nn[1] := ncnt; nn[2] := ncode; nn[3] := 0; nn[4] := 0;
  modd('#NCNT ', nn, sizeof(nn));
  modd('#NMS  ', nms, sizeof(nms));
  for j := 1 to ncnt do modd(nms[j], ades[j], sizeof(RecT));
  ClrErr
   end ;
end;

procedure Init;
var j:integer;
begin
   begin 
  pasbdi;
  BDERRN := 0;
  newd('ADA   ');
  ClrErr;
  opend('ADA   ');
  for j := 1 to 11 do ur[j] := 0;
  ur[1] := 1;
  ur[2] := 1;
  modd('ADMIN ', ur, sizeof(ur));
  ClrErr;
  un := 0;
  rn := 0;
  unms[1] := 'ADMIN ';
  un := 1;
  rnms[1] := 'ADMIN ';
  robj[1] := 'ADA   ';
  rtyp[1] := 'ДЛЯ-ВЫ';
  rn := 1
   end ;
end;

begin MarsBind(@bdvect, @bderrn);
  MarsCreate := true;  (* servis makes the database *)
  MarsBegin;  (* the whole run is one transaction *)
  Init;
  ncode := 0;
  ncnt := 0;
  LoadAreas;
  writeln('SERVIS PROCESSOR 15.1');
  writeln('ADMIN: ПОЛЬЗОВАТЕЛЬ ADMIN ЗАРЕГИСТРИРОВАН');
  while not eof(input) do begin
    RT_ReadLn(ln);
    RT_Fold(ln);
    p := 1;
    repeat
      Stmt;
      Skip;
      if p <= 72 then begin
        nxt := ln[p];
        if (nxt = ';') or (nxt = ',') then p := p + 1
        else p := 73
      end
    until p > 72
  end;
  writeln('EXN=',RT_W( EXN));
  SaveAreas;
  MarsCommit
end.
