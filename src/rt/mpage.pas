{ MARS file store: pages, copy-on-write transactions, freelist, locking.
  One file.  Pages 0 and 1 are meta pages; the valid one with the higher
  txnid is current.  A write transaction never overwrites a page the
  current meta reaches: changed pages get new numbers, and the commit
  writes them, syncs, then writes the other meta page and syncs.
  Readers hold flock LOCK_SH, a writer LOCK_EX, per transaction. }
unit mpage;

{$mode objfpc}{$H+}

interface

uses SysUtils, BaseUnix;

const
  PageSize = 4096;
  HdrSize = 20;
  { page header: crc u32 @0 (of bytes 4..), type u16 @4, n u16 @6,
    pgno u32 @8, next u32 @12, spare @16 }
  ptMeta = 1; ptBranch = 2; ptLeaf = 3; ptOver = 4; ptFree = 5;

type
  TPgno = longword;
  TPgnos = array of TPgno;
  EMars = class(Exception);

var
  TxRoot: TPgno;               { tree root of the open transaction, 0: empty }
  PgSync: boolean = true;      { fsync at commit; PgOpen sets it from MARS_SYNC }
  { test hooks: SIGKILL before the n-th write or sync of a commit;
    tear: write half of the n-th page, then SIGKILL }
  MarsCrashAt: integer = 0;
  MarsTearAt: integer = 0;
  MarsIoCount: integer = 0;

procedure PgOpen(const path: string);
procedure PgClose;
{ in a forked child: forget the parent's file, lock and transaction }
procedure PgAfterFork;
function PgIsOpen: boolean;
procedure TxnBegin(write: boolean);
procedure TxnCommit;
{ roll back everything since the outermost TxnBegin and close one level,
  like TxnCommit; outer levels go on from the rolled back state }
procedure TxnAbort;
function TxnDepth: integer;
function TxnWriting: boolean;

function PgGet(p: TPgno): PByte;         { read only }
function PgNew(typ: integer): TPgno;     { a dirty zeroed page }
function PgTouch(p: TPgno): TPgno;       { writable copy, maybe a new number }
function PgBuf(p: TPgno): PByte;         { buffer of a dirty page }
procedure PgFree(p: TPgno);
procedure PgDropCache;

{ committed state, for checks }
function PgCount: TPgno;
procedure PgFreeInfo(out entries, chain: TPgnos);
function PgTxnId: qword;

function Get16(p: PByte; off: integer): word; inline;
function Get32(p: PByte; off: integer): longword; inline;
procedure Put16(p: PByte; off: integer; v: word); inline;
procedure Put32(p: PByte; off: integer; v: longword); inline;
function Crc32(p: PByte; n: integer): longword;

implementation

uses Unix;

const
  Magic: array[0..7] of char = 'KMARS1'#0#0;
  Version = 1;
  FreePer = (PageSize - HdrSize) div 4;
  CacheMax = 16384;
  MetaHead = 64;               { bytes of a meta page that hold its fields }

var
  fd: cint = -1;
  fpath: string;
  { committed state as of the transaction start }
  mTxn: qword;
  mRoot, mFree, mNpages: TPgno;
  { the open transaction }
  depth: integer = 0;
  writing: boolean = false;
  tNpages: TPgno;
  cache: array of PByte;
  dirty: array of boolean;
  ncached: integer = 0;
  cacheTxn: qword = 0;
  dlist: TPgnos; ndirty: integer;
  avail: TPgnos; navail: integer;      { free at the last commit, pop = lowest }
  pend: TPgnos; npend: integer;        { freed now, free after commit }
  oldFree: TPgnos;                     { pages of the committed freelist }
  crcTab: array[0..7, 0..255] of longword;
  lastHead: array[0..1, 0..MetaHead - 1] of byte;
  headOk: boolean = false;

function Get16(p: PByte; off: integer): word; inline;
begin Move(p[off], Result, 2); end;
function Get32(p: PByte; off: integer): longword; inline;
begin Move(p[off], Result, 4); end;
procedure Put16(p: PByte; off: integer; v: word); inline;
begin Move(v, p[off], 2); end;
procedure Put32(p: PByte; off: integer; v: longword); inline;
begin Move(v, p[off], 4); end;

procedure InitCrc;
var i, j: integer; c: longword;
begin
  for i := 0 to 255 do begin
    c := i;
    for j := 1 to 8 do
      if odd(c) then c := (c shr 1) xor $EDB88320 else c := c shr 1;
    crcTab[0, i] := c;
  end;
  for i := 0 to 255 do
    for j := 1 to 7 do
      crcTab[j, i] := (crcTab[j - 1, i] shr 8) xor crcTab[0, crcTab[j - 1, i] and $FF];
end;

{ CRC-32, slicing by 8 (little-endian) }
function Crc32(p: PByte; n: integer): longword;
var a, b: longword;
begin
  Result := $FFFFFFFF;
  while n >= 8 do begin
    Move(p^, a, 4);
    Move(p[4], b, 4);
    a := a xor Result;
    Result := crcTab[7, a and $FF] xor crcTab[6, (a shr 8) and $FF] xor
      crcTab[5, (a shr 16) and $FF] xor crcTab[4, a shr 24] xor
      crcTab[3, b and $FF] xor crcTab[2, (b shr 8) and $FF] xor
      crcTab[1, (b shr 16) and $FF] xor crcTab[0, b shr 24];
    inc(p, 8);
    dec(n, 8);
  end;
  while n > 0 do begin
    Result := crcTab[0, (Result xor p^) and $FF] xor (Result shr 8);
    inc(p);
    dec(n);
  end;
  Result := not Result;
end;

procedure Fail(const s: string);
begin
  raise EMars.Create(fpath + ': ' + s);
end;

{ --- raw I/O with the crash hooks --- }

procedure Hook;
begin
  inc(MarsIoCount);
  if MarsIoCount = MarsCrashAt then fpKill(fpGetPid, SIGKILL);
end;

procedure WriteRaw(p: TPgno; buf: PByte);
begin
  Hook;
  if MarsIoCount = MarsTearAt then begin
    fpPWrite(fd, PChar(buf), PageSize div 2, int64(p) * PageSize);
    fpKill(fpGetPid, SIGKILL);
  end;
  if fpPWrite(fd, PChar(buf), PageSize, int64(p) * PageSize) <> PageSize then
    Fail(Format('write of page %d failed', [p]));
end;

procedure Sync;
begin
  if not PgSync then exit;
  Hook;
  if fpfsync(fd) <> 0 then Fail('fsync failed');
end;

procedure Seal(p: TPgno; buf: PByte);
begin
  Put32(buf, 8, p);
  Put32(buf, 0, Crc32(buf + 4, PageSize - 4));
end;

function Sealed(p: TPgno; buf: PByte): boolean;
begin
  Result := (Get32(buf, 0) = Crc32(buf + 4, PageSize - 4)) and (Get32(buf, 8) = p);
end;

{ --- cache --- }

procedure Grow(p: TPgno);
var n: integer;
begin
  if p < TPgno(length(cache)) then exit;
  n := length(cache) * 2;
  if n <= integer(p) then n := p + 64;
  SetLength(cache, n);
  SetLength(dirty, n);
end;

procedure PgDropCache;
var i: integer;
begin
  for i := 0 to high(cache) do
    if (cache[i] <> nil) and not dirty[i] then begin
      FreeMem(cache[i]);
      cache[i] := nil;
    end;
  ncached := ndirty;
end;

function PgGet(p: TPgno): PByte;
var buf: PByte;
begin
  if (p < 2) or ((depth > 0) and (p >= tNpages)) then
    Fail(Format('page %d out of range', [p]));
  Grow(p);
  if cache[p] = nil then begin
    buf := GetMem(PageSize);
    if (fpPRead(fd, PChar(buf), PageSize, int64(p) * PageSize) <> PageSize) or
       not Sealed(p, buf) then begin
      FreeMem(buf);
      Fail(Format('page %d damaged', [p]));
    end;
    cache[p] := buf;
    inc(ncached);
  end;
  Result := cache[p];
end;

function PgBuf(p: TPgno): PByte;
begin
  if (p >= TPgno(length(dirty))) or not dirty[p] then
    Fail(Format('page %d not writable', [p]));
  Result := cache[p];
end;

{ --- meta --- }

function ReadMeta(slot: integer; buf: PByte; out txn: qword; out root, free, np: TPgno): boolean;
begin
  Result := false;
  if not Sealed(slot, buf) or (Get16(buf, 4) <> ptMeta) or
     not CompareMem(@buf[HdrSize], @Magic, 8) then exit;
  if (Get32(buf, HdrSize + 8) <> Version) or (Get32(buf, HdrSize + 12) <> PageSize) then
    Fail('unknown format version');
  Move(buf[HdrSize + 16], txn, 8);
  root := Get32(buf, HdrSize + 24);
  free := Get32(buf, HdrSize + 28);
  np := Get32(buf, HdrSize + 32);
  Result := true;
end;

procedure WriteMeta(txn: qword; root, free, np: TPgno);
var buf: array[0..PageSize - 1] of byte; slot: integer;
begin
  FillChar(buf, PageSize, 0);
  slot := txn and 1;
  Put16(@buf, 4, ptMeta);
  Move(Magic, buf[HdrSize], 8);
  Put32(@buf, HdrSize + 8, Version);
  Put32(@buf, HdrSize + 12, PageSize);
  Move(txn, buf[HdrSize + 16], 8);
  Put32(@buf, HdrSize + 24, root);
  Put32(@buf, HdrSize + 28, free);
  Put32(@buf, HdrSize + 32, np);
  Seal(slot, @buf);
  WriteRaw(slot, @buf);
end;

{ both metas in one read; their CRCs are checked again only when their
  heads (all their fields) differ from the last ones checked }
procedure LoadMeta;
var buf: array[0..2 * PageSize - 1] of byte; t0, t1: qword;
    r0, r1, f0, f1, n0, n1: TPgno; ok0, ok1: boolean;
begin
  if fpPRead(fd, PChar(@buf[0]), 2 * PageSize, 0) <> 2 * PageSize then Fail('no valid meta page');
  if headOk and CompareMem(@buf[0], @lastHead[0], MetaHead) and
     CompareMem(@buf[PageSize], @lastHead[1], MetaHead) then exit;
  headOk := false;
  ok0 := ReadMeta(0, @buf[0], t0, r0, f0, n0);
  ok1 := ReadMeta(1, @buf[PageSize], t1, r1, f1, n1);
  if ok0 and (not ok1 or (t0 > t1)) then begin
    mTxn := t0; mRoot := r0; mFree := f0; mNpages := n0;
  end else if ok1 then begin
    mTxn := t1; mRoot := r1; mFree := f1; mNpages := n1;
  end else
    Fail('no valid meta page');
  Move(buf[0], lastHead[0], MetaHead);
  Move(buf[PageSize], lastHead[1], MetaHead);
  headOk := true;
end;

procedure Lock(op: cint);
begin
  while fpFlock(fd, op) <> 0 do
    if fpGetErrno <> ESysEINTR then Fail('flock failed');
end;

procedure PgOpen(const path: string);
var st: Stat;
begin
  if fd >= 0 then begin
    if path = fpath then exit;
    PgClose;
  end;
  fpath := path;
  headOk := false;
  PgSync := GetEnvironmentVariable('MARS_SYNC') <> '0';
  if ExtractFileDir(path) <> '' then ForceDirectories(ExtractFileDir(path));
  fd := fpOpen(path, O_RDWR or O_CREAT, &644);
  if fd < 0 then Fail('cannot open');
  Lock(LOCK_SH);
  try
    if fpFStat(fd, st) <> 0 then Fail('cannot stat');
    if st.st_size < 2 * PageSize then begin
      Lock(LOCK_EX);           { a new file: the first opener writes the metas }
      if fpFStat(fd, st) <> 0 then Fail('cannot stat');
      if st.st_size < 2 * PageSize then begin
        WriteMeta(0, 0, 0, 2);
        WriteMeta(1, 0, 0, 2);
        Sync;
      end;
    end;
    LoadMeta;
  finally
    Lock(LOCK_UN);
  end;
  cacheTxn := mTxn;
end;

function PgIsOpen: boolean;
begin
  Result := fd >= 0;
end;

procedure DropAll;
var i: integer;
begin
  for i := 0 to high(cache) do
    if cache[i] <> nil then FreeMem(cache[i]);
  cache := nil; dirty := nil;
  ncached := 0; ndirty := 0;
end;

procedure PgAfterFork;
begin
  if fd < 0 then exit;
  DropAll;
  fpClose(fd);     { the parent still holds the shared lock: no LOCK_UN }
  fd := -1;
  depth := 0;
end;

procedure PgClose;
begin
  if fd < 0 then exit;
  if depth > 0 then begin
    TxnAbort;
    depth := 0;
    Lock(LOCK_UN);
  end;
  DropAll;
  fpClose(fd);
  fd := -1;
end;

{ --- freelist --- }

procedure ReadFreelist(head: TPgno; out entries, chain: TPgnos);
var p: TPgno; b: PByte; i, n, ne, nc: integer;
begin
  entries := nil; chain := nil; ne := 0; nc := 0;
  p := head;
  while p <> 0 do begin
    b := PgGet(p);
    if Get16(b, 4) <> ptFree then Fail(Format('page %d: not a freelist page', [p]));
    SetLength(chain, nc + 1); chain[nc] := p; inc(nc);
    n := Get16(b, 6);
    SetLength(entries, ne + n);
    for i := 0 to n - 1 do entries[ne + i] := Get32(b, HdrSize + 4 * i);
    inc(ne, n);
    p := Get32(b, 12);
  end;
end;

procedure SortDesc(var a: TPgnos; n: integer);
  procedure QS(l, r: integer);
  var i, j: integer; x, t: TPgno;
  begin
    i := l; j := r; x := a[(l + r) div 2];
    repeat
      while a[i] > x do inc(i);
      while x > a[j] do dec(j);
      if i <= j then begin t := a[i]; a[i] := a[j]; a[j] := t; inc(i); dec(j); end;
    until i > j;
    if l < j then QS(l, j);
    if i < r then QS(i, r);
  end;
begin
  if n > 1 then QS(0, n - 1);
end;

procedure PgFreeInfo(out entries, chain: TPgnos);
begin
  ReadFreelist(mFree, entries, chain);
end;

function PgCount: TPgno;
begin
  Result := mNpages;
end;

function PgTxnId: qword;
begin
  Result := mTxn;
end;

{ --- transactions --- }

procedure Push(var a: TPgnos; var n: integer; p: TPgno);
begin
  if n >= length(a) then SetLength(a, n * 2 + 16);
  a[n] := p;
  inc(n);
end;

procedure StartWrite;
var i: integer; t: TPgno;
begin
  ReadFreelist(mFree, avail, oldFree);
  navail := length(avail);
  { stored ascending: reverse, so that a pop takes the lowest }
  for i := 0 to navail div 2 - 1 do begin
    t := avail[i]; avail[i] := avail[navail - 1 - i]; avail[navail - 1 - i] := t;
  end;
  npend := 0;
  ndirty := 0;
  tNpages := mNpages;
  TxRoot := mRoot;
end;

procedure TxnBegin(write: boolean);
begin
  if fd < 0 then Fail('not open');
  if depth > 0 then begin
    if write and not writing then Fail('write in a read transaction');
    inc(depth);
    exit;
  end;
  if write then Lock(LOCK_EX) else Lock(LOCK_SH);
  try
    LoadMeta;
    if (mTxn <> cacheTxn) or (ncached > CacheMax) then begin
      DropAll;
      cacheTxn := mTxn;
    end;
    depth := 1;
    writing := write;
    tNpages := mNpages;
    TxRoot := mRoot;
    if write then StartWrite;
  except
    depth := 0;
    Lock(LOCK_UN);
    raise;
  end;
end;

function TxnDepth: integer;
begin
  Result := depth;
end;

function TxnWriting: boolean;
begin
  Result := (depth > 0) and writing;
end;

procedure Discard;
var i: integer; p: TPgno;
begin
  for i := 0 to ndirty - 1 do begin
    p := dlist[i];
    if dirty[p] then begin
      dirty[p] := false;
      FreeMem(cache[p]);
      cache[p] := nil;
      dec(ncached);
    end;
  end;
  ndirty := 0;
end;

procedure TxnAbort;
begin
  if depth = 0 then exit;
  dec(depth);
  if not writing then begin
    if depth = 0 then Lock(LOCK_UN);
    exit;
  end;
  Discard;
  if depth = 0 then Lock(LOCK_UN)
  else StartWrite;
end;

function PgNew(typ: integer): TPgno;
begin
  if not TxnWriting then Fail('no write transaction');
  if navail > 0 then begin
    dec(navail);
    Result := avail[navail];
  end else begin
    Result := tNpages;
    inc(tNpages);
  end;
  Grow(Result);
  if cache[Result] <> nil then FreeMem(cache[Result])
  else inc(ncached);
  cache[Result] := GetMem(PageSize);
  FillChar(cache[Result]^, PageSize, 0);
  Put16(cache[Result], 4, typ);
  dirty[Result] := true;
  Push(dlist, ndirty, Result);
end;

function PgTouch(p: TPgno): TPgno;
begin
  if (p < TPgno(length(dirty))) and dirty[p] then exit(p);
  PgGet(p);
  Result := PgNew(0);
  Move(cache[p]^, cache[Result]^, PageSize);
  PgFree(p);
end;

procedure PgFree(p: TPgno);
begin
  if (p < TPgno(length(dirty))) and dirty[p] then begin
    dirty[p] := false;           { stays in dlist, skipped at commit }
    Push(avail, navail, p);
  end else
    Push(pend, npend, p);
end;

procedure WriteFreelist(out head: TPgno);
var pages, all: TPgnos; k, i, j, n, total: integer; b: PByte;
begin
  { the new freelist pages come out of the free set itself }
  k := 0; pages := nil;
  while navail + npend + length(oldFree) > k * FreePer do begin
    SetLength(pages, k + 1);
    pages[k] := PgNew(ptFree);
    inc(k);
  end;
  total := navail + npend + length(oldFree);
  SetLength(all, total);
  n := 0;
  for i := 0 to navail - 1 do begin all[n] := avail[i]; inc(n); end;
  for i := 0 to npend - 1 do begin all[n] := pend[i]; inc(n); end;
  for i := 0 to high(oldFree) do begin all[n] := oldFree[i]; inc(n); end;
  SortDesc(all, total);
  head := 0;
  n := total;                     { fill from the end: ascending order }
  for i := k - 1 downto 0 do begin
    b := PgBuf(pages[i]);
    j := 0;
    while (j < FreePer) and (n > 0) do begin
      dec(n);
      Put32(b, HdrSize + 4 * j, all[n]);
      inc(j);
    end;
    Put16(b, 6, j);
    Put32(b, 12, head);
    head := pages[i];
  end;
end;

procedure TxnCommit;
var i: integer; p, head: TPgno;
begin
  if depth = 0 then Fail('commit without a transaction');
  if depth > 1 then begin dec(depth); exit; end;
  if not writing or ((ndirty = 0) and (npend = 0) and (TxRoot = mRoot)) then begin
    depth := 0;
    Lock(LOCK_UN);
    exit;
  end;
  try
    WriteFreelist(head);
    for i := 0 to ndirty - 1 do begin
      p := dlist[i];
      if dirty[p] then begin
        Seal(p, cache[p]);
        WriteRaw(p, cache[p]);
      end;
    end;
    Sync;
    WriteMeta(mTxn + 1, TxRoot, head, tNpages);
    Sync;
    inc(mTxn);
    mRoot := TxRoot; mFree := head; mNpages := tNpages;
    cacheTxn := mTxn;
    for i := 0 to ndirty - 1 do dirty[dlist[i]] := false;
    ndirty := 0;
  except
    Discard;
    depth := 0;
    Lock(LOCK_UN);
    raise;
  end;
  depth := 0;
  Lock(LOCK_UN);
end;

initialization
  InitCrc;
finalization
  PgClose;
end.
