PROGRAM WORD(INPUT,OUTPUT);
(* KOMPAS Pascal folds Latin look-alikes: CЛOBO.ИMЯ is СЛОВО.ИМЯ *)
&& ПОДСХЕ СХ-ДИС &&
VAR K: PACKED ARRAY[1..12] OF CHAR;
    I: INTEGER;
BEGIN
  READ(K);
  CЛOBO.ИMЯ := K;
  &&НАЙТИ ПО-КЛЮ В SY-СЛО&&
  IF СОСТ <> 0 THEN WRITELN('НЕТ СЛОВА ', K)
  ELSE BEGIN
    &&ВЗЯТЬ&&
    WRITELN(СЛОВО.ИМЯ, '=', СЛОВО.ЗНАЧ, '.');
    IF СЛОВО.БУКВА = 'ж' THEN WRITELN('СТРОЧНАЯ ж')
    ELSE IF СЛОВО.БУКВА = 'Ж' THEN WRITELN('ПРОПИСНАЯ Ж')
    ELSE WRITELN('БУКВА ', СЛОВО.БУКВА, ' КОД ', ORD(СЛОВО.БУКВА):1);
    I := 1;
    WHILE (I <= 12) AND (СЛОВО.ИМЯ[I] <> ' ') DO I := I + 1;
    WRITELN('ДЛИНА ', I - 1:1)
  END
END.
