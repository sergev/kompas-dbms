{ GOST 10859 and the internal 8-bit code of KOMPAS.  Encode: UTF-8 ->
  internal bytes (upper case, Latin and Cyrillic homoglyphs merged);
  Decode: internal bytes -> UTF-8. }
unit kgost;

{$mode objfpc}{$H+}

interface

function Encode(const s: string): string;
function Decode(const s: string): string;
{ one internal byte folded as Encode folds it: upper case, homoglyphs }
function Fold(c: char): char;
{ GOST code of an internal byte, 0 if none }
function GostOf(b: byte): integer;

implementation

const
  CYR: array[0..127] of word = (
    48, 49, 50, 51, 52, 53, 54, 55,
    56, 57, 43, 45, 47, 44, 46, 32,
    9192, 8593, 40, 41, 215, 61, 59, 91,
    93, 42, 8216, 8217, 8800, 60, 62, 58,
    1040, 1041, 1042, 1043, 1044, 1045, 1046, 1047,
    1048, 1049, 1050, 1051, 1052, 1053, 1054, 1055,
    1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063,
    1064, 1065, 1067, 1068, 1069, 1070, 1071, 68,
    70, 71, 73, 74, 76, 78, 81, 82,
    83, 85, 86, 87, 90, 8254, 10877, 10878,
    8744, 8743, 8835, 172, 247, 8801, 37, 9671,
    124, 8213, 95, 33, 34, 1066, 176, 8242,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 9252, 92, 0, 0);

  ASCII2G: array[0..95] of byte = (
    15, 91, 92, 28, 87, 86, 81, 27, 18, 19, 25, 10,
    13, 11, 14, 12, 0, 1, 2, 3, 4, 5, 6, 7,
    8, 9, 31, 22, 29, 21, 30, 94, 17, 32, 34, 49,
    63, 37, 64, 65, 45, 66, 67, 42, 68, 44, 69, 46,
    48, 70, 71, 72, 50, 73, 74, 75, 53, 51, 76, 23,
    125, 24, 77, 90, 26, 32, 34, 49, 63, 37, 64, 65,
    45, 66, 67, 42, 68, 44, 69, 46, 48, 70, 71, 72,
    50, 73, 74, 75, 53, 51, 76, 85, 88, 15, 83, 15);

  INTOFG: array[0..127] of byte = (
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 43, 45,
    47, 44, 46, 32, 144, 64, 40, 41, 148, 61, 59, 91,
    93, 42, 96, 39, 35, 60, 62, 58, 65, 161, 66, 163,
    164, 69, 166, 167, 168, 169, 75, 171, 77, 72, 79, 175,
    80, 67, 84, 89, 180, 88, 182, 183, 184, 185, 186, 187,
    188, 189, 190, 68, 70, 71, 73, 74, 76, 78, 81, 82,
    83, 85, 86, 87, 90, 94, 206, 207, 208, 38, 210, 126,
    212, 123, 37, 36, 124, 217, 95, 33, 34, 221, 63, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235,
    236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247,
    248, 249, 250, 251, 252, 92, 254, 255);

  GOFINT: array[0..255] of smallint = (
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    15, 91, 92, 28, 87, 86, 81, 27, 18, 19, 25, 10, 13, 11, 14, 12,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 31, 22, 29, 21, 30, 94,
    17, 32, 34, 49, 63, 37, 64, 65, 45, 66, 67, 42, 68, 44, 69, 46,
    48, 70, 71, 72, 50, 73, 74, 75, 53, 51, 76, 23, 125, 24, 77, 90,
    26, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 85, 88, -1, 83, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    16, -1, -1, -1, 20, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, 33, -1, 35, 36, -1, 38, 39, 40, 41, -1, 43, -1, -1, -1, 47,
    -1, -1, -1, -1, 52, -1, 54, 55, 56, 57, 58, 59, 60, 61, 62, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 78, 79,
    80, -1, 82, -1, 84, -1, -1, -1, -1, 89, -1, -1, -1, 93, -1, 95,
    96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
    112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, -1, 126, 127);

function ToGost(u: longint): integer;
var g: integer;
begin
  if (u >= $20) and (u < $80) then exit(ASCII2G[u - $20]);
  if (u >= $410) and (u <= $44F) then begin
    if (u = $42A) or (u = $44A) then exit(93);
    u := $410 + (u - $410) mod 32;
  end;
  if (u = $401) or (u = $451) then exit(37);
  for g := 0 to high(CYR) do
    if CYR[g] = u then exit(g);
  if u = $2015 then exit(89);
  Result := 15;
end;

function Encode(const s: string): string;
var i, n, u: longint; c: byte;
begin
  Result := '';
  i := 1;
  while i <= length(s) do begin
    c := ord(s[i]);
    if c < $80 then begin u := c; n := 1 end
    else if c and $E0 = $C0 then begin u := c and $1F; n := 2 end
    else if c and $F0 = $E0 then begin u := c and $0F; n := 3 end
    else begin u := c and $07; n := 4 end;
    for c := 1 to n - 1 do
      if i + c <= length(s) then u := (u shl 6) or (ord(s[i + c]) and $3F);
    inc(i, n);
    if u = $FEFF then continue;
    if (u = 10) or (u = 13) or (u = 9) then begin
      if u = 9 then Result := Result + ' ' else Result := Result + chr(u);
      continue;
    end;
    Result := Result + chr(INTOFG[ToGost(u)]);
  end;
end;

function Utf8(u: longint): string;
begin
  if u < $80 then Result := chr(u)
  else if u < $800 then Result := chr($C0 or (u shr 6)) + chr($80 or (u and $3F))
  else Result := chr($E0 or (u shr 12)) + chr($80 or ((u shr 6) and $3F)) +
    chr($80 or (u and $3F));
end;

function Decode(const s: string): string;
var i, g: integer; b: byte;
begin
  Result := '';
  for i := 1 to length(s) do begin
    b := ord(s[i]);
    if b = 10 then begin Result := Result + #10; continue end;
    g := GOFINT[b];
    if (g < 0) and (b >= $20) and (b < $80) then g := ASCII2G[b - $20];
    if (g >= 0) and (CYR[g] <> 0) then Result := Result + Utf8(CYR[g]);
  end;
end;

function GostOf(b: byte): integer;
begin
  Result := GOFINT[b];
  if Result < 0 then Result := 0;
end;

function Fold(c: char): char;
begin
  if (c >= 'a') and (c <= 'z') then exit(chr(ord(c) - 32));
  Result := c;
end;

end.
