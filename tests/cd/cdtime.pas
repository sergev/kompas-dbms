program cdtime(input, output);
&& подсхе сх-дис &&
var n, s: integer;
begin
  read(n);
  &&журнал жу-дис&&
  диск.номер := n;
  &&найти по-клю в sy-дис&&
  if сост <> 0 then writeln('Нет диска ', n:1)
  else begin
    &&взять; найти владел в ар-дис; взять&&
    writeln(артист.имя);
    writeln(диск.назв);
    s := 0;
    &&найти первую в ди-тре&&
    while сост = 0 do begin
      &&взять&&
      s := s + трек.длит;
      &&найти следую в ди-тре&&
    end;
    writeln('Всего ', s div 60:1, ' мин ', s mod 60:1, ' сек')
  end;
  &&заверш&&
end.
