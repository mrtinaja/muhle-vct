/* ========================================================================
   VCT_MAIN_SEND_EMAIL_FIX_COLUMNAS
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_SEND_EMAIL.
   El bloque de la agenda del consultor usaba columnas que no existen en el
   modelo nuevo, y el SP fallaba en CUALQUIER llamada con
   "Invalid column name 'IDVISITA'":
     VC.IDVISITA    -> VC.ID_VISITA
     VC.IDCONSULTOR -> VC.ID_CONSULTOR
     V.IDCLIENTE    -> el cliente sale del proyecto de la visita
                       (VCT_PROYECTOS_VISITAS no tiene IDCLIENTE)
   Nada mas cambia. Si algun fragmento no esta (o esta repetido), no aplica
   nada y avisa.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_SEND_EMAIL'));
DECLARE @s INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_SEND_EMAIL.',16,1);
    RETURN;
END;

IF CHARINDEX(N'VC.ID_VISITA', @D) > 0
BEGIN
    PRINT 'VCT_MAIN_SEND_EMAIL ya estaba corregido. No se hizo nada.';
    RETURN;
END;

DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'ON V.ID = VC.IDVISITA'),
 (N'LEFT JOIN dbo.VCT_CLIENTES CL WITH(NOLOCK) ON CL.ID = V.IDCLIENTE'),
 (N'WHERE VC.IDCONSULTOR = @ID_CONSULTOR');

DECLARE @bad NVARCHAR(400) = NULL;
SELECT TOP 1 @bad = mk FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad IS NOT NULL
BEGIN
    DECLARE @msg NVARCHAR(600) = N'El fragmento "' + @bad + N'" no esta (o esta repetido). No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

SET @D = REPLACE(@D, N'ON V.ID = VC.IDVISITA', N'ON V.ID = VC.ID_VISITA');
SET @D = REPLACE(@D, N'LEFT JOIN dbo.VCT_CLIENTES CL WITH(NOLOCK) ON CL.ID = V.IDCLIENTE',
                     N'LEFT JOIN dbo.VCT_PROYECTOS PRV WITH(NOLOCK) ON PRV.ID = V.ID_PROYECTO LEFT JOIN dbo.VCT_CLIENTES CL WITH(NOLOCK) ON CL.ID = PRV.IDCLIENTE');
SET @D = REPLACE(@D, N'WHERE VC.IDCONSULTOR = @ID_CONSULTOR', N'WHERE VC.ID_CONSULTOR = @ID_CONSULTOR');

/* CREATE -> ALTER en el encabezado del SP (si ya dice CREATE OR ALTER o ALTER, queda) */
DECLARE @p INT = CHARINDEX(N'PROCEDURE', @D), @pre NVARCHAR(60);
IF @p > 0
BEGIN
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
END;

IF PATINDEX(N'%ALTER%PROC%', @D) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_SEND_EMAIL corregido (columnas de visitas).';
GO

/* prueba sin enviar nada (modo preview): tiene que devolver ASUNTO y DESTINATARIO */
EXEC dbo.VCT_MAIN_SEND_EMAIL @CODIGO = 'PROYECTO_ANALISTA_ASIGNADO', @ID_ANALISTA = 120;
GO
