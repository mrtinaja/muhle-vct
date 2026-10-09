CREATE   FUNCTION dbo.VCT_MIG_INTERPRETAR_TELEFONO(@Original nvarchar(max))
RETURNS @Resultado TABLE (CODAREA numeric(4,0), NRO numeric(8,0), Excepcion nvarchar(max))
AS
BEGIN
 DECLARE @s nvarchar(max)=LTRIM(RTRIM(ISNULL(@Original,N''))),@g nvarchar(max)=N'',@d nvarchar(max)=N'',@c nchar(1),@i int=1,@anterior bit=0,@grupo nvarchar(100),@resto nvarchar(max),@area numeric(4,0),@nro numeric(8,0),@nota nvarchar(max)=N'';
 WHILE @i<=LEN(@s)
 BEGIN
  SET @c=SUBSTRING(@s,@i,1);
  IF @c COLLATE Latin1_General_100_BIN2 LIKE N'[0-9]'
  BEGIN
   SET @d+=@c; SET @g+=@c; SET @anterior=1;
  END
  ELSE IF @anterior=1 BEGIN SET @g+=N' '; SET @anterior=0; END;
  SET @i+=1;
 END;
 SET @g=RTRIM(@g);
 IF UPPER(@s) LIKE N'%INT.%' OR UPPER(@s) LIKE N'%INTERNO%' OR UPPER(@s) LIKE N'% INT %' OR UPPER(@s) LIKE N'%(INT%'
  SET @nota=N'No se separo automaticamente el numero del interno.';
 IF @nota=N'' AND LEFT(@g,3)=N'54 '
 BEGIN
  SET @g=LTRIM(SUBSTRING(@g,4,LEN(@g))); SET @d=SUBSTRING(@d,3,LEN(@d));
 END
 ELSE IF @nota=N'' AND LEFT(@d,2)=N'54' AND LEN(@d) IN (12,13)
 BEGIN
  SET @d=SUBSTRING(@d,3,LEN(@d)); SET @g=@d;
 END;
 IF @nota=N'' AND LEFT(@g,2)=N'9 ' AND LEN(@d)=11
 BEGIN SET @g=LTRIM(SUBSTRING(@g,3,LEN(@g))); SET @d=SUBSTRING(@d,2,LEN(@d)); END
 ELSE IF @nota=N'' AND LEFT(@d,1)=N'9' AND LEN(@d)=11 AND LEFT(@g,1)=N'9'
 BEGIN SET @d=SUBSTRING(@d,2,LEN(@d)); SET @g=@d; END;
 IF @nota=N'' AND LEFT(@g,2)=N'0 '
 BEGIN SET @g=LTRIM(SUBSTRING(@g,3,LEN(@g))); SET @d=SUBSTRING(@d,2,LEN(@d)); END;
 SET @grupo=LEFT(@g,CHARINDEX(N' ',@g+N' ')-1);
 SET @resto=REPLACE(LTRIM(SUBSTRING(@g,LEN(@grupo)+1,LEN(@g))),N' ',N'');
 IF @nota=N'' AND LEN(@resto)>=6 AND LEN(@resto)<=8 AND LEN(@grupo)>=2 AND LEN(@grupo)<=5
 BEGIN
  IF LEFT(@grupo,1)=N'0' SET @grupo=SUBSTRING(@grupo,2,LEN(@grupo));
  IF LEN(@grupo)<=4
  BEGIN SET @area=TRY_CAST(@grupo AS numeric(4,0)); SET @nro=TRY_CAST(@resto AS numeric(8,0)); END;
 END;
 -- Compact national numbers are split only for the unambiguous area 11 prefix.
 IF @nota=N'' AND @area IS NULL
 BEGIN
  IF LEFT(@d,1)=N'0' AND LEN(@d)=11 SET @d=SUBSTRING(@d,2,LEN(@d));
  IF LEN(@d)=10 AND LEFT(@d,2)=N'11'
  BEGIN SET @area=11; SET @nro=TRY_CAST(SUBSTRING(@d,3,8) AS numeric(8,0)); END
  ELSE IF LEN(@d) BETWEEN 6 AND 8
  BEGIN SET @area=0; SET @nro=TRY_CAST(@d AS numeric(8,0)); SET @nota=N'Numero local sin codigo de area verificable; CODAREA=0.'; END;
 END;
 IF @area IS NULL OR @nro IS NULL OR @nro<=0
 BEGIN
  SET @area=0; SET @nro=0;
  SET @nota=CASE WHEN @nota=N'' THEN N'Formato ambiguo, internacional no soportado o numero fuera de rango. CODAREA=0 y NRO=0; consultar texto original.' ELSE @nota+N' CODAREA=0 y NRO=0; consultar texto original.' END;
 END;
 INSERT @Resultado VALUES(@area,@nro,NULLIF(@nota,N''));
 RETURN;
END;
