CREATE   FUNCTION dbo.VCT_MIG_PROY_IMPORTE(@Texto varchar(max))
RETURNS numeric(15,2)
AS
BEGIN
 DECLARE @s varchar(max)=LTRIM(RTRIM(@Texto)),@coma int,@punto int,@dec int,@moneda bit=0;
 IF @s IS NULL OR @s='' RETURN NULL;
 IF LEFT(@s,1)='$' BEGIN SET @moneda=1; SET @s=LTRIM(RTRIM(SUBSTRING(@s,2,LEN(@s)))); END;
 IF @s='' RETURN NULL;
 IF @s LIKE '% %' OR @s COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9.,+-]%' RETURN NULL;
 SET @coma=CASE WHEN CHARINDEX(',',@s)>0 THEN LEN(@s)-CHARINDEX(',',REVERSE(@s))+1 ELSE 0 END;
 SET @punto=CASE WHEN CHARINDEX('.',@s)>0 THEN LEN(@s)-CHARINDEX('.',REVERSE(@s))+1 ELSE 0 END;
 IF @coma>0 AND @punto>0
 BEGIN
  -- Dos separadores solo se aceptan si todos los grupos de miles tienen tres digitos.
  DECLARE @sep char(1),@part varchar(max),@a int,@b int;
  SET @dec=CASE WHEN @coma>@punto THEN @coma ELSE @punto END;
  IF LEN(@s)-@dec NOT BETWEEN 1 AND 2 RETURN NULL;
  SET @sep=CASE WHEN @coma>@punto THEN '.' ELSE ',' END;
  SET @part=LEFT(@s,@dec-1);
  IF LEFT(@part,1) IN ('+','-') SET @part=SUBSTRING(@part,2,LEN(@part));
  IF CHARINDEX(CASE WHEN @sep='.' THEN ',' ELSE '.' END,@part)>0 RETURN NULL;
  IF RIGHT(@part,1)=@sep RETURN NULL;
  SET @a=CHARINDEX(@sep,@part);
  IF @a NOT BETWEEN 2 AND 4 RETURN NULL;
  SET @a+=1;
  WHILE @a<=LEN(@part)
  BEGIN
   SET @b=CHARINDEX(@sep,@part,@a); IF @b=0 SET @b=LEN(@part)+1;
   IF @b-@a<>3 RETURN NULL;
   SET @a=@b+1;
  END;
  SET @s=REPLACE(@s,@sep,''); SET @s=REPLACE(@s,',','.');
 END
 ELSE IF @coma>0 OR @punto>0
 BEGIN
  SET @dec=CASE WHEN @coma>0 THEN @coma ELSE @punto END;
  -- Formato del legado: $ y puntos con grupos de tres indican miles.
  IF @moneda=1 AND @coma=0 AND LEN(@s)-@punto=3
  BEGIN
   DECLARE @miles varchar(max)=@s,@pos int,@sig int;
   IF LEFT(@miles,1) IN ('+','-') SET @miles=SUBSTRING(@miles,2,LEN(@miles));
   SET @pos=CHARINDEX('.',@miles); IF @pos NOT BETWEEN 2 AND 4 RETURN NULL;
   SET @pos+=1;
   WHILE @pos<=LEN(@miles)
   BEGIN
    SET @sig=CHARINDEX('.',@miles,@pos); IF @sig=0 SET @sig=LEN(@miles)+1;
    IF @sig-@pos<>3 RETURN NULL;
    SET @pos=@sig+1;
   END;
   RETURN TRY_CAST(REPLACE(@s,'.','') AS numeric(15,2));
  END;
  IF LEN(@s)-@dec NOT BETWEEN 1 AND 2 RETURN NULL;
  IF @coma>0 AND LEN(@s)-LEN(REPLACE(@s,',',''))<>1 RETURN NULL;
  IF @punto>0 AND LEN(@s)-LEN(REPLACE(@s,'.',''))<>1 RETURN NULL;
  SET @s=REPLACE(@s,',','.');
 END;
 RETURN TRY_CAST(@s AS numeric(15,2));
END;
