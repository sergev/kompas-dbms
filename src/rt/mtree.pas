{ MARS B+tree on mpage pages: byte keys (up to 255), byte values.
  A page: header, slots (u16 offsets, in key order), cells packed from
  the end.  Leaf cell: klen u8, flag u8 (1: value in overflow pages),
  vlen u32, key, value or first overflow page.  Branch cell: klen u8,
  child u32, key; the header's next field is the leftmost child, and a
  cell's child holds the keys >= its key.  Writes decode a page into a
  list of cells, change it and encode it into a copied page. }
unit mtree;

{$mode objfpc}{$H+}

interface

uses SysUtils, mpage;

const
  MaxKey = 255;
  MaxInline = 1024;

type
  TSeek = (skGE, skGT, skLE, skLT, skFirst, skLast);

function TGet(const k: RawByteString; out v: RawByteString): boolean;
procedure TPut(const k, v: RawByteString);
function TDel(const k: RawByteString): boolean;
function TSeekKey(const k: RawByteString; mode: TSeek; out fk, fv: RawByteString): boolean;
{ structure of the committed tree and freelist: '' if sound }
function TCheck: string;

var
  { set by TCheck }
  TStatEntries, TStatPages, TStatOver, TStatFree, TStatDepth: integer;

implementation

const
  Chunk = PageSize - HdrSize;
  MinFill = PageSize div 4;

type
  TNode = record
    leaf: boolean;
    left: TPgno;
    n: integer;
    c: array of RawByteString;
  end;
  TRes = record
    pg, right: TPgno;
    sep: RawByteString;
  end;
  ECheck = class(Exception);

procedure Fail(const s: string);
begin
  raise EMars.Create('mars tree: ' + s);
end;

{ byte order of keys }
function KCmp(const a, b: RawByteString): integer;
var m: integer;
begin
  m := length(a);
  if length(b) < m then m := length(b);
  Result := 0;
  if m > 0 then Result := CompareByte(a[1], b[1], m);
  if Result = 0 then Result := length(a) - length(b);
end;

{ --- raw pages --- }

function IsLeaf(b: PByte): boolean; inline;
begin
  Result := Get16(b, 4) = ptLeaf;
end;

function Cnt(b: PByte): integer; inline;
begin
  Result := Get16(b, 6);
end;

function Off(b: PByte; i: integer): integer; inline;
begin
  Result := Get16(b, HdrSize + 2 * i);
end;

function KeyPtr(b: PByte; i: integer; out len: integer): PByte;
var o: integer;
begin
  o := Off(b, i);
  len := b[o];
  if IsLeaf(b) then Result := b + o + 6 else Result := b + o + 5;
end;

function KeyAt(b: PByte; i: integer): RawByteString;
var p: PByte; len: integer;
begin
  p := KeyPtr(b, i, len);
  SetLength(Result, len);
  if len > 0 then Move(p^, Result[1], len);
end;

function CmpAt(b: PByte; i: integer; const k: RawByteString): integer;
var p: PByte; len, m: integer;
begin
  p := KeyPtr(b, i, len);
  m := len;
  if length(k) < m then m := length(k);
  Result := 0;
  if m > 0 then Result := CompareByte(p^, k[1], m);
  if Result = 0 then Result := len - length(k);
end;

{ first i with key >= k (lower) or key > k (upper) }
function Bound(b: PByte; const k: RawByteString; upper: boolean): integer;
var lo, hi, mid, c: integer;
begin
  lo := 0; hi := Cnt(b);
  while lo < hi do begin
    mid := (lo + hi) div 2;
    c := CmpAt(b, mid, k);
    if (c < 0) or (upper and (c = 0)) then lo := mid + 1 else hi := mid;
  end;
  Result := lo;
end;

function Kid(b: PByte; c: integer): TPgno;
begin
  if c = 0 then Result := Get32(b, 12) else Result := Get32(b, Off(b, c - 1) + 1);
end;

function CellLen(b: PByte; o: integer): integer;
begin
  if IsLeaf(b) then begin
    Result := 6 + b[o];
    if b[o + 1] = 1 then inc(Result, 4) else inc(Result, Get32(b, o + 2));
  end else
    Result := 5 + b[o];
end;

function ReadOver(p: TPgno; vlen: integer): RawByteString;
var b: PByte; n, at: integer;
begin
  SetLength(Result, vlen);
  at := 0;
  while p <> 0 do begin
    b := PgGet(p);
    if Get16(b, 4) <> ptOver then Fail(Format('page %d: not an overflow page', [p]));
    n := Get16(b, 6);
    if at + n > vlen then Fail(Format('page %d: overflow too long', [p]));
    Move(b[HdrSize], Result[at + 1], n);
    inc(at, n);
    p := Get32(b, 12);
  end;
  if at <> vlen then Fail('overflow too short');
end;

function ValAt(b: PByte; i: integer): RawByteString;
var o, klen, vlen: integer;
begin
  o := Off(b, i);
  klen := b[o];
  vlen := Get32(b, o + 2);
  if b[o + 1] = 1 then exit(ReadOver(Get32(b, o + 6 + klen), vlen));
  SetLength(Result, vlen);
  if vlen > 0 then Move(b[o + 6 + klen], Result[1], vlen);
end;

{ --- cells --- }

function CellKey(const c: RawByteString; leaf: boolean): RawByteString;
begin
  if leaf then Result := Copy(c, 7, ord(c[1])) else Result := Copy(c, 6, ord(c[1]));
end;

function CellChild(const c: RawByteString): TPgno;
begin
  Move(c[2], Result, 4);
end;

function BranchCell(const k: RawByteString; child: TPgno): RawByteString;
begin
  Result := chr(length(k)) + #0#0#0#0 + k;
  Move(child, Result[2], 4);
end;

function WriteOver(const v: RawByteString): TPgno;
var at, n: integer; p: TPgno; b: PByte;
begin
  Result := 0;
  at := ((length(v) - 1) div Chunk) * Chunk;
  while at >= 0 do begin
    n := length(v) - at;
    if n > Chunk then n := Chunk;
    p := PgNew(ptOver);
    b := PgBuf(p);
    Put16(b, 6, n);
    Put32(b, 12, Result);
    Move(v[at + 1], b[HdrSize], n);
    Result := p;
    dec(at, Chunk);
  end;
end;

procedure FreeOver(p: TPgno);
var q: TPgno;
begin
  while p <> 0 do begin
    q := Get32(PgGet(p), 12);
    PgFree(p);
    p := q;
  end;
end;

function LeafCell(const k, v: RawByteString): RawByteString;
var hdr: RawByteString; vlen: longword; p: TPgno;
begin
  vlen := length(v);
  SetLength(hdr, 6);
  hdr[1] := chr(length(k));
  Move(vlen, hdr[3], 4);
  if vlen > MaxInline then begin
    hdr[2] := #1;
    p := WriteOver(v);
    Result := hdr + k + #0#0#0#0;
    Move(p, Result[length(Result) - 3], 4);
  end else begin
    hdr[2] := #0;
    Result := hdr + k + v;
  end;
end;

procedure FreeCell(const c: RawByteString);
var p: TPgno;
begin
  if c[2] = #1 then begin
    Move(c[7 + ord(c[1])], p, 4);
    FreeOver(p);
  end;
end;

{ --- nodes --- }

procedure Decode(p: TPgno; out nd: TNode);
var b: PByte; i, o: integer;
begin
  b := PgGet(p);
  nd.leaf := IsLeaf(b);
  if not nd.leaf and (Get16(b, 4) <> ptBranch) then Fail(Format('page %d: not a tree page', [p]));
  nd.n := Cnt(b);
  if nd.leaf then nd.left := 0 else nd.left := Get32(b, 12);
  SetLength(nd.c, nd.n);
  for i := 0 to nd.n - 1 do begin
    o := Off(b, i);
    SetLength(nd.c[i], CellLen(b, o));
    Move(b[o], nd.c[i][1], length(nd.c[i]));
  end;
end;

function Bytes(const nd: TNode; a, z: integer): integer;
var i: integer;
begin
  Result := HdrSize;
  for i := a to z do inc(Result, 2 + length(nd.c[i]));
end;

procedure Encode(const nd: TNode; p: TPgno);
var b: PByte; i, o: integer;
begin
  b := PgBuf(p);
  FillChar(b[4], PageSize - 4, 0);
  if nd.leaf then Put16(b, 4, ptLeaf) else Put16(b, 4, ptBranch);
  Put16(b, 6, nd.n);
  Put32(b, 12, nd.left);
  o := PageSize;
  for i := 0 to nd.n - 1 do begin
    dec(o, length(nd.c[i]));
    Move(nd.c[i][1], b[o], length(nd.c[i]));
    Put16(b, HdrSize + 2 * i, o);
  end;
end;

procedure InsCell(var nd: TNode; i: integer; const c: RawByteString);
var j: integer;
begin
  SetLength(nd.c, nd.n + 1);
  for j := nd.n downto i + 1 do nd.c[j] := nd.c[j - 1];
  nd.c[i] := c;
  inc(nd.n);
end;

procedure DelCell(var nd: TNode; i: integer);
var j: integer;
begin
  for j := i to nd.n - 2 do nd.c[j] := nd.c[j + 1];
  dec(nd.n);
  SetLength(nd.c, nd.n);
end;

function NodeKid(const nd: TNode; c: integer): TPgno;
begin
  if c = 0 then Result := nd.left else Result := CellChild(nd.c[c - 1]);
end;

procedure SetKid(var nd: TNode; c: integer; p: TPgno);
begin
  if c = 0 then nd.left := p
  else Move(p, nd.c[c - 1][2], 4);
end;

{ position in a decoded node: lower or upper bound }
function NodeBound(const nd: TNode; const k: RawByteString; upper: boolean): integer;
var lo, hi, mid: integer; key: RawByteString;
begin
  lo := 0; hi := nd.n;
  while lo < hi do begin
    mid := (lo + hi) div 2;
    key := CellKey(nd.c[mid], nd.leaf);
    if (KCmp(key, k) < 0) or (upper and (KCmp(key, k) = 0)) then lo := mid + 1 else hi := mid;
  end;
  Result := lo;
end;

{ split an overfull node into l and r; sep is the first key of r }
procedure Split(const nd: TNode; out l, r: TNode; out sep: RawByteString);
var m, i, acc, total, lo, hi, rb, best: integer;
begin
  total := Bytes(nd, 0, nd.n - 1);
  if nd.leaf then begin lo := 1; hi := nd.n - 1; end
  else begin lo := 1; hi := nd.n - 2; end;
  if lo > hi then Fail('cannot split');
  { the split point where both halves fit and differ least }
  m := -1; best := MaxInt;
  acc := HdrSize;
  for i := 0 to lo - 2 do inc(acc, 2 + length(nd.c[i]));
  for i := lo to hi do begin
    inc(acc, 2 + length(nd.c[i - 1]));       { acc = bytes of cells 0..i-1 }
    if nd.leaf then rb := total - acc + HdrSize
    else rb := total - acc + HdrSize - 2 - length(nd.c[i]);
    if (acc <= PageSize) and (rb <= PageSize) and (abs(acc - rb) < best) then begin
      best := abs(acc - rb);
      m := i;
    end;
  end;
  if m < 0 then Fail('cannot split');
  l.leaf := nd.leaf; r.leaf := nd.leaf;
  l.left := nd.left;
  l.n := m;
  SetLength(l.c, m);
  for i := 0 to m - 1 do l.c[i] := nd.c[i];
  sep := CellKey(nd.c[m], nd.leaf);
  if nd.leaf then begin
    r.left := 0;
    r.n := nd.n - m;
    SetLength(r.c, r.n);
    for i := 0 to r.n - 1 do r.c[i] := nd.c[m + i];
  end else begin
    r.left := CellChild(nd.c[m]);
    r.n := nd.n - m - 1;
    SetLength(r.c, r.n);
    for i := 0 to r.n - 1 do r.c[i] := nd.c[m + 1 + i];
  end;
end;

{ the node into the page old (copied if clean; 0: a new page) }
function Store(const nd: TNode; old: TPgno): TRes;
var l, r: TNode; p, q: TPgno;
begin
  if old = 0 then p := PgNew(ptLeaf) else p := PgTouch(old);
  Result.right := 0;
  Result.sep := '';
  if Bytes(nd, 0, nd.n - 1) <= PageSize then
    Encode(nd, p)
  else begin
    Split(nd, l, r, Result.sep);
    Encode(l, p);
    q := PgNew(ptLeaf);
    Encode(r, q);
    Result.right := q;
  end;
  Result.pg := p;
end;

function Under(p: TPgno): boolean;
var b: PByte; i, used: integer;
begin
  b := PgGet(p);
  used := HdrSize;
  for i := 0 to Cnt(b) - 1 do inc(used, 2 + CellLen(b, Off(b, i)));
  Result := used < MinFill;
end;

{ child c of nd is underfull: merge it with a neighbour or share }
procedure Rebalance(var nd: TNode; c: integer);
var a: integer; pa, pb, lp, rp: TPgno; l, r, m, ml, mr: TNode; i: integer;
    sep: RawByteString;
begin
  if nd.n = 0 then exit;
  if c < nd.n then a := c else a := c - 1;
  pa := NodeKid(nd, a);
  pb := NodeKid(nd, a + 1);
  Decode(pa, l);
  Decode(pb, r);
  m.leaf := l.leaf;
  m.left := l.left;
  m.n := 0;
  SetLength(m.c, l.n + r.n + 1);
  for i := 0 to l.n - 1 do begin m.c[m.n] := l.c[i]; inc(m.n); end;
  if not m.leaf then begin
    m.c[m.n] := BranchCell(CellKey(nd.c[a], false), r.left);
    inc(m.n);
  end;
  for i := 0 to r.n - 1 do begin m.c[m.n] := r.c[i]; inc(m.n); end;
  SetLength(m.c, m.n);
  if Bytes(m, 0, m.n - 1) <= PageSize then begin
    lp := PgTouch(pa);
    Encode(m, lp);
    PgFree(pb);
    SetKid(nd, a, lp);
    DelCell(nd, a);
  end else begin
    Split(m, ml, mr, sep);
    lp := PgTouch(pa);
    rp := PgTouch(pb);
    Encode(ml, lp);
    Encode(mr, rp);
    SetKid(nd, a, lp);
    nd.c[a] := BranchCell(sep, rp);
  end;
end;

function Modify(pg: TPgno; const k, v: RawByteString; del: boolean): TRes;
var nd: TNode; i, c: integer; r: TRes;
begin
  Decode(pg, nd);
  if nd.leaf then begin
    i := NodeBound(nd, k, false);
    if (i < nd.n) and (KCmp(CellKey(nd.c[i], true), k) = 0) then begin
      FreeCell(nd.c[i]);
      if del then DelCell(nd, i) else nd.c[i] := LeafCell(k, v);
    end else if not del then
      InsCell(nd, i, LeafCell(k, v));
  end else begin
    c := NodeBound(nd, k, true);
    r := Modify(NodeKid(nd, c), k, v, del);
    SetKid(nd, c, r.pg);
    if r.right <> 0 then InsCell(nd, c, BranchCell(r.sep, r.right))
    else if Under(r.pg) then Rebalance(nd, c);
  end;
  Result := Store(nd, pg);
end;

procedure FixRoot(const r: TRes);
var nd: TNode; b: PByte; old: TPgno;
begin
  if r.right <> 0 then begin
    nd.leaf := false;
    nd.left := r.pg;
    nd.n := 1;
    SetLength(nd.c, 1);
    nd.c[0] := BranchCell(r.sep, r.right);
    TxRoot := Store(nd, 0).pg;
    exit;
  end;
  TxRoot := r.pg;
  repeat
    b := PgGet(TxRoot);
    if Cnt(b) > 0 then break;
    old := TxRoot;
    if IsLeaf(b) then TxRoot := 0 else TxRoot := Get32(b, 12);
    PgFree(old);
  until TxRoot = 0;
end;

{ --- the interface --- }

function FindLeaf(const k: RawByteString; out b: PByte; out i: integer): boolean;
var p: TPgno;
begin
  Result := false;
  p := TxRoot;
  if p = 0 then exit;
  b := PgGet(p);
  while not IsLeaf(b) do begin
    p := Kid(b, Bound(b, k, true));
    b := PgGet(p);
  end;
  i := Bound(b, k, false);
  Result := (i < Cnt(b)) and (CmpAt(b, i, k) = 0);
end;

function TGet(const k: RawByteString; out v: RawByteString): boolean;
var b: PByte; i: integer;
begin
  v := '';
  Result := FindLeaf(k, b, i);
  if Result then v := ValAt(b, i);
end;

procedure TPut(const k, v: RawByteString);
var nd: TNode;
begin
  if length(k) > MaxKey then Fail('key too long');
  if TxRoot = 0 then begin
    nd.leaf := true;
    nd.left := 0;
    nd.n := 1;
    SetLength(nd.c, 1);
    nd.c[0] := LeafCell(k, v);
    TxRoot := Store(nd, 0).pg;
  end else
    FixRoot(Modify(TxRoot, k, v, false));
end;

function TDel(const k: RawByteString): boolean;
var b: PByte; i: integer;
begin
  Result := FindLeaf(k, b, i);
  if Result then FixRoot(Modify(TxRoot, k, '', true));
end;

function SeekPg(pg: TPgno; const k: RawByteString; mode: TSeek;
  out fk, fv: RawByteString): boolean;
var b: PByte; i, c, j, n: integer; m: TSeek;
begin
  b := PgGet(pg);
  n := Cnt(b);
  if IsLeaf(b) then begin
    case mode of
      skGE: i := Bound(b, k, false);
      skGT: i := Bound(b, k, true);
      skLE: i := Bound(b, k, true) - 1;
      skLT: i := Bound(b, k, false) - 1;
      skFirst: i := 0;
    else i := n - 1;
    end;
    Result := (i >= 0) and (i < n);
    if Result then begin
      fk := KeyAt(b, i);
      fv := ValAt(b, i);
    end;
    exit;
  end;
  case mode of
    skFirst: c := 0;
    skLast: c := n;
  else c := Bound(b, k, true);
  end;
  Result := true;
  if mode in [skGE, skGT, skFirst] then begin
    for j := c to n do begin
      if j = c then m := mode else m := skFirst;
      if SeekPg(Kid(b, j), k, m, fk, fv) then exit;
    end;
  end else
    for j := c downto 0 do begin
      if j = c then m := mode else m := skLast;
      if SeekPg(Kid(b, j), k, m, fk, fv) then exit;
    end;
  Result := false;
end;

function TSeekKey(const k: RawByteString; mode: TSeek; out fk, fv: RawByteString): boolean;
begin
  fk := ''; fv := '';
  Result := (TxRoot <> 0) and SeekPg(TxRoot, k, mode, fk, fv);
end;

{ --- check --- }

var
  marked: array of boolean;
  leafDepth: integer;

procedure Bad(const s: string);
begin
  raise ECheck.Create(s);
end;

procedure Mark(p: TPgno; const what: string);
begin
  if (p < 2) or (p >= TPgno(length(marked))) then
    Bad(Format('%s: page %d out of range', [what, p]));
  if marked[p] then Bad(Format('%s: page %d used twice', [what, p]));
  marked[p] := true;
end;

procedure Walk(pg: TPgno; const lo, hi: RawByteString; hasLo, hasHi: boolean;
  d: integer; root: boolean);
var b: PByte; i, n, o, used, klen, vlen: integer; k, prev: RawByteString;
    q: TPgno; total: integer;
begin
  Mark(pg, 'tree');
  inc(TStatPages);
  b := PgGet(pg);
  if not (Get16(b, 4) in [ptLeaf, ptBranch]) then Bad(Format('page %d: type %d', [pg, Get16(b, 4)]));
  n := Cnt(b);
  used := HdrSize + 2 * n;
  for i := 0 to n - 1 do begin
    o := Off(b, i);
    if (o < HdrSize + 2 * n) or (o + 6 > PageSize) then Bad(Format('page %d: slot %d', [pg, i]));
    klen := b[o];
    if o + CellLen(b, o) > PageSize then Bad(Format('page %d: cell %d', [pg, i]));
    inc(used, CellLen(b, o));
    k := KeyAt(b, i);
    if (i > 0) and (KCmp(prev, k) >= 0) then Bad(Format('page %d: keys out of order at %d', [pg, i]));
    if hasLo and (KCmp(k, lo) < 0) then Bad(Format('page %d: key below the separator', [pg]));
    if hasHi and (KCmp(k, hi) >= 0) then Bad(Format('page %d: key above the separator', [pg]));
    prev := k;
    if IsLeaf(b) then begin
      vlen := Get32(b, o + 2);
      if b[o + 1] = 1 then begin
        if vlen <= MaxInline then Bad(Format('page %d: short value in overflow', [pg]));
        q := Get32(b, o + 6 + klen);
        total := 0;
        while q <> 0 do begin
          Mark(q, 'overflow');
          inc(TStatOver);
          if Get16(PgGet(q), 4) <> ptOver then Bad(Format('page %d: not overflow', [q]));
          inc(total, Get16(PgGet(q), 6));
          q := Get32(PgGet(q), 12);
        end;
        if total <> vlen then Bad(Format('page %d: overflow length', [pg]));
      end else if vlen > MaxInline then
        Bad(Format('page %d: long value inline', [pg]));
    end;
  end;
  if used > PageSize then Bad(Format('page %d: overfull', [pg]));
  if not root and (used < MinFill) then Bad(Format('page %d: underfull (%d)', [pg, used]));
  if IsLeaf(b) then begin
    inc(TStatEntries, n);
    if leafDepth < 0 then leafDepth := d
    else if d <> leafDepth then Bad(Format('page %d: leaf depth %d, not %d', [pg, d, leafDepth]));
    if root and (n = 0) then Bad('empty root leaf');
  end else begin
    if n = 0 then Bad(Format('page %d: branch with one child', [pg]));
    for i := 0 to n do begin
      if i = 0 then begin
        if i = n then Walk(Kid(b, i), lo, hi, hasLo, hasHi, d + 1, false)
        else Walk(Kid(b, i), lo, KeyAt(b, 0), hasLo, true, d + 1, false);
      end else if i = n then
        Walk(Kid(b, i), KeyAt(b, i - 1), hi, true, hasHi, d + 1, false)
      else
        Walk(Kid(b, i), KeyAt(b, i - 1), KeyAt(b, i), true, true, d + 1, false);
    end;
  end;
end;

function TCheck: string;
var own: boolean; ent, chain: TPgnos; i: integer;
begin
  Result := '';
  TStatEntries := 0; TStatPages := 0; TStatOver := 0; TStatFree := 0; TStatDepth := 0;
  own := TxnDepth = 0;
  if TxnWriting then exit('check inside a write transaction');
  if own then begin
    TxnBegin(false);
    PgDropCache;           { read every page from the file, with its CRC }
  end;
  try
    try
      marked := nil;
      SetLength(marked, PgCount);
      leafDepth := -1;
      if TxRoot <> 0 then Walk(TxRoot, '', '', false, false, 1, true);
      TStatDepth := leafDepth;
      if TStatDepth < 0 then TStatDepth := 0;
      PgFreeInfo(ent, chain);
      for i := 0 to high(chain) do Mark(chain[i], 'freelist');
      for i := 0 to high(ent) do Mark(ent[i], 'free');
      TStatFree := length(ent);
      for i := 2 to high(marked) do
        if not marked[i] then Bad(Format('page %d lost', [i]));
    except
      on e: ECheck do Result := e.Message;
      on e: EMars do Result := e.Message;
    end;
  finally
    if own then TxnCommit;
  end;
end;

end.
