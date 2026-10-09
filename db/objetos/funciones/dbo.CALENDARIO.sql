CREATE FUNCTION [dbo].[CALENDARIO]
 
(
 
-- Add the parameters for the function here
 
@fIni smalldatetime
 
,@fFin smalldatetime
 
)
 
 
RETURNS
@MyCalendario TABLE (FECHA smalldatetime)
 
BEGIN 
 
DECLARE @d tinyint
 
SET @d = 0
 
WHILE @fIni <= @fFin
 
BEGIN
 
INSERT INTO @MyCalendario VALUES (@fIni)
 
SET @fIni = DATEADD(d, 1, @fIni)
 
END
 
RETURN
 
END
 
