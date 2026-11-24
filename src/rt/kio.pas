{ Standard input and output of KOMPAS Pascal programs: UTF-8 (kutf). }
unit kio;

{$mode objfpc}{$H+}

interface

{ write UTF-8 bytes to standard output, past its buffer }
procedure KioPut(const s: AnsiString);

implementation

uses SysUtils, kutf;

procedure KioPut(const s: AnsiString);
begin
  if s <> '' then FileWrite(1, s[1], length(s));
end;

end.
