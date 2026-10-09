CREATE   FUNCTION dbo.VCT_MIG_PROY_SEPARAR_IDS(@Lista varchar(max))
RETURNS @R TABLE(ORDEN int,TOKEN varchar(1000),ID int)
AS
BEGIN
 DECLARE @i int=1,@j int,@n int=0,@s varchar(max)=ISNULL(@Lista,''),@t varchar(1000);
 WHILE @i<=LEN(@s)
 BEGIN
  SET @j=CHARINDEX('|',@s,@i); IF @j=0 SET @j=LEN(@s)+1;
  SET @t=LTRIM(RTRIM(SUBSTRING(@s,@i,@j-@i))); SET @n+=1;
  INSERT @R VALUES(@n,@t,CASE WHEN @t<>'' AND @t COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%' AND TRY_CAST(@t AS int)>0 THEN TRY_CAST(@t AS int) END);
  SET @i=@j+1;
 END;
 RETURN;
END;
