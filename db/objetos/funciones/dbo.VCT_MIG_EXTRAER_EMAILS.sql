 
CREATE   FUNCTION dbo.VCT_MIG_EXTRAER_EMAILS(@Original nvarchar(max))
RETURNS @Resultado TABLE (Orden int, EMAIL nvarchar(100), Excepcion nvarchar(max))
AS
BEGIN
 DECLARE @s nvarchar(max)=ISNULL(@Original,N''),@pos int=1,@arroba int,@inicio int,@fin int,@n int=0,@v nvarchar(max),@nota nvarchar(max),@siguiente nchar(1);
 WHILE @pos<=LEN(@s)
 BEGIN
  SET @arroba=CHARINDEX(N'@',@s,@pos); IF @arroba=0 BREAK;
  SET @inicio=@arroba-1;
  WHILE @inicio>0 AND SUBSTRING(@s,@inicio,1) COLLATE Latin1_General_100_BIN2 LIKE N'[A-Za-z0-9._%+-]' SET @inicio-=1;
  SET @inicio+=1; SET @fin=@arroba+1;
  WHILE @fin<=LEN(@s) AND SUBSTRING(@s,@fin,1) COLLATE Latin1_General_100_BIN2 LIKE N'[A-Za-z0-9.-]' SET @fin+=1;
  SET @v=SUBSTRING(@s,@inicio,@fin-@inicio); SET @nota=NULL;
  -- Do not silently fix malformed domains such as dominio.com,.ar.
  IF SUBSTRING(@s,@fin,2)=N',.' SET @nota=N'Dominio contiene puntuacion ambigua; EMAIL vacio, ver original.';
  IF LEN(@v)>100 SET @nota=N'Correo excede 100 caracteres; EMAIL vacio, ver original.';
  IF CHARINDEX(N'.',@v,CHARINDEX(N'@',@v)+2)=0 OR LEFT(@v,1) IN (N'.',N'@') OR RIGHT(@v,1) IN (N'.',N'@',N'-') OR @v LIKE N'%..%' OR @v LIKE N'%@@%'
   SET @nota=N'Correo no interpretable con seguridad; EMAIL vacio, ver original.';
  SET @n+=1;
  INSERT @Resultado VALUES(@n,CASE WHEN @nota IS NULL THEN CONVERT(nvarchar(100),@v) ELSE N'' END,@nota);
  SET @pos=CASE WHEN @fin>@arroba THEN @fin ELSE @arroba+1 END;
 END;
 IF @n=0 AND LTRIM(RTRIM(@s))<>N''
  INSERT @Resultado VALUES(1,N'',N'Campo informado sin correo identificable; EMAIL vacio, ver original.');
 RETURN;
END;
