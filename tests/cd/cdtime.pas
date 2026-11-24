PROGRAM CDTIME(INPUT,OUTPUT);
&& ПОДСХЕ СХ-ДИС &&
VAR N, S: INTEGER;
BEGIN
  READ(N);
  &&ЖУРНАЛ ЖУ-ДИС&&
  ДИСК.НОМЕР := N;
  &&НАЙТИ ПО-КЛЮ В SY-ДИС&&
  IF СОСТ <> 0 THEN WRITELN('НЕТ ДИСКА ', N:1)
  ELSE BEGIN
    &&ВЗЯТЬ; НАЙТИ ВЛАДЕЛ В АР-ДИС; ВЗЯТЬ&&
    WRITELN(АРТИСТ.ИМЯ);
    WRITELN(ДИСК.НАЗВ);
    S := 0;
    &&НАЙТИ ПЕРВУЮ В ДИ-ТРЕ&&
    WHILE СОСТ = 0 DO BEGIN
      &&ВЗЯТЬ&&
      S := S + ТРЕК.ДЛИТ;
      &&НАЙТИ СЛЕДУЮ В ДИ-ТРЕ&&
    END;
    WRITELN('ВСЕГО ', S DIV 60:1, ' МИН ', S MOD 60:1, ' СЕК')
  END;
  &&ЗАВЕРШ&&
END.
