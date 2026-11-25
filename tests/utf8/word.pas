program word(input, output);
(* names fold case and Latin look-alikes: cлoвo.иmя (Latin c, o, m) is СЛОВО.ИМЯ *)
&& подсхе сх-дис &&
var k: packed array[1..12] of char;
    i: integer;
begin
  read(k);
  cлoвo.иmя := k;
  &&найти по-клю в sy-сло&&
  if сост <> 0 then writeln('Нет слова ', k)
  else begin
    &&взять&&
    writeln(слово.имя, '=', слово.знач, '.');
    if слово.буква = 'ж' then writeln('Строчная ж')
    else if слово.буква = 'Ж' then writeln('Прописная Ж')
    else writeln('Буква ', слово.буква, ', код ', ord(слово.буква):1);
    i := 1;
    while (i <= 12) and (слово.имя[i] <> ' ') do i := i + 1;
    writeln('Длина ', i - 1:1)
  end
end.
