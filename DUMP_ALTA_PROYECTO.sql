/* ========================================================================
   DUMP_ALTA_PROYECTO - SOLO LECTURA. No modifica nada.
   Imprime en la pestana "Messages" la definicion completa de los objetos
   que usa el alta de proyecto (motor de eventos/gestiones y render de
   formularios) y las columnas de VCT_BUFFER.
   Uso: ejecutar (F5) -> pestana Messages -> Ctrl+A -> Ctrl+C -> pegar.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* ---- columnas de VCT_BUFFER (slots disponibles para el formulario) ---- */
DECLARE @COLS NVARCHAR(MAX) = N'';
SELECT @COLS = @COLS + c.name + N' ' + ty.name
     + CASE WHEN ty.name IN (N'varchar',N'char') THEN N'(' + CASE WHEN c.max_length=-1 THEN N'MAX' ELSE CONVERT(NVARCHAR(10),c.max_length) END + N')'
            WHEN ty.name IN (N'nvarchar',N'nchar') THEN N'(' + CASE WHEN c.max_length=-1 THEN N'MAX' ELSE CONVERT(NVARCHAR(10),c.max_length/2) END + N')'
            ELSE N'' END + N', '
FROM sys.columns c
INNER JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE c.object_id=OBJECT_ID(N'dbo.VCT_BUFFER')
ORDER BY c.column_id;
PRINT N'===== COLUMNAS dbo.VCT_BUFFER =====';
PRINT @COLS;
PRINT N'';

/* ---- definiciones ---- */
DECLARE @OBJ TABLE (ORDEN INT IDENTITY(1,1), NAME SYSNAME);
INSERT @OBJ(NAME) VALUES
 (N'dbo.VCT_EVENTO_PROCESAR'),
 (N'dbo.VCT_GESTION_CREAR'),
 (N'dbo.VCT_GESTION_PARTICIPANTE_AGREGAR'),
 (N'dbo.VCT_MAIN_RENDER_FORM'),
 (N'dbo.VCT_VW_GESTIONES_RESPONSABLES');

DECLARE @I INT = 1, @N INT = (SELECT COUNT(*) FROM @OBJ), @NAME SYSNAME,
        @D NVARCHAR(MAX), @TOTAL INT, @P INT, @E INT, @LINE NVARCHAR(MAX);

WHILE @I <= @N
BEGIN
    SELECT @NAME = NAME FROM @OBJ WHERE ORDEN = @I;
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME));

    PRINT N'';
    PRINT N'===== ' + @NAME + N' =====';

    IF @D IS NULL
        PRINT N'(no se encontro la definicion)';
    ELSE
    BEGIN
        SET @TOTAL = DATALENGTH(@D) / 2;
        SET @P = 1;
        WHILE @P <= @TOTAL
        BEGIN
            SET @E = CHARINDEX(NCHAR(10), @D, @P);
            IF @E = 0 SET @E = @TOTAL + 1;
            SET @LINE = SUBSTRING(@D, @P, @E - @P);
            IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13)
                SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);
            WHILE (DATALENGTH(@LINE) / 2) > 4000
            BEGIN
                PRINT SUBSTRING(@LINE, 1, 4000);
                SET @LINE = SUBSTRING(@LINE, 4001, 1000000);
            END;
            PRINT @LINE;
            SET @P = @E + 1;
        END;
    END;

    SET @I = @I + 1;
END;
