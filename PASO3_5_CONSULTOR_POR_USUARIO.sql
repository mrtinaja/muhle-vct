/* ========================================================================
   PASO3_5_CONSULTOR_POR_USUARIO  (solo modifica SPs; no toca datos)
   ------------------------------------------------------------------------
   Las pantallas buscan al consultor del usuario por
   VCT_CONSULTORES.ID_USUARIO_SEGURIDAD. Hay consultores con ese campo vacio
   (ej. Bracamonte, ID 50) y por eso su usuario ve Inicio, Acciones y la
   campanita en 0.
   Cambio: si el consultor NO tiene usuario cargado, se lo reconoce por la
   convencion de usuarios del sistema: inicial del nombre + apellido, en
   minusculas y sin espacios (Jorge Bracamonte -> jbracamonte). Si el
   campo esta cargado, manda el campo (no cambia nada para esos casos).
   Se aplica a todos los SPs que buscan el consultor del usuario
   (Inicio, Acciones, notificaciones, Vista 360 de proyecto, asignacion...):
   en cada uno se reemplaza solo la condicion de la busqueda sobre
   VCT_CONSULTORES (no la de VCT_EMPLEADOS). Marca CONS_LOGIN_V1.
   Re-ejecutable. Imprime cada SP modificado.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

/* condiciones que se buscan y su reemplazo */
DECLARE @PAT TABLE (ORD INT, BUSCA NVARCHAR(400), PONE NVARCHAR(1000));
INSERT INTO @PAT VALUES
 (1, N'LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'''')))) = @U',
     N'(LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'''')))) = @U OR (LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,''''))) = '''''
   + N' AND LOWER(REPLACE(LEFT(LTRIM(CONVERT(VARCHAR(150), NOMBRES)), 1) + LTRIM(RTRIM(CONVERT(VARCHAR(150), APELLIDOS))), '' '', '''')) = @U)) /* CONS_LOGIN_V1 */'),
 (2, N'LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''''))) = LTRIM(RTRIM(@IAGENTE))',
     N'(LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''''))) = LTRIM(RTRIM(@IAGENTE)) OR (LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''''))) = '''''
   + N' AND LOWER(REPLACE(LEFT(LTRIM(CONVERT(VARCHAR(150), C.NOMBRES)), 1) + LTRIM(RTRIM(CONVERT(VARCHAR(150), C.APELLIDOS))), '' '', '''')) = LOWER(LTRIM(RTRIM(@IAGENTE))))) /* CONS_LOGIN_V1 */');

DECLARE @SP SYSNAME, @D NVARCHAR(MAX), @P INT, @Q INT, @N INT, @CTX NVARCHAR(400), @PC INT, @PE INT,
        @BUSCA NVARCHAR(400), @PONE NVARCHAR(1000), @ORD INT;
DECLARE csp CURSOR LOCAL FAST_FORWARD FOR
    SELECT OBJECT_NAME(M.object_id)
    FROM sys.sql_modules M INNER JOIN sys.procedures PR ON PR.object_id = M.object_id
    WHERE M.[definition] LIKE N'%ID_USUARIO_SEGURIDAD%' AND M.[definition] LIKE N'%VCT_CONSULTORES%'
      AND M.[definition] NOT LIKE N'%CONS_LOGIN_V1%'
    ORDER BY 1;
OPEN csp;
FETCH NEXT FROM csp INTO @SP;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @D = OBJECT_DEFINITION(OBJECT_ID(N'dbo.' + @SP));
    SET @N = 0;
    SET @ORD = 0;
    WHILE 1 = 1
    BEGIN
        SELECT TOP 1 @ORD = ORD, @BUSCA = BUSCA, @PONE = PONE FROM @PAT WHERE ORD > @ORD ORDER BY ORD;
        IF @@ROWCOUNT = 0 BREAK;
        SET @P = CHARINDEX(@BUSCA, @D);
        WHILE @P > 0
        BEGIN
            /* solo si la busqueda es sobre VCT_CONSULTORES (lo ultimo nombrado antes de la condicion) */
            SET @CTX = REVERSE(SUBSTRING(@D, CASE WHEN @P > 300 THEN @P - 300 ELSE 1 END, CASE WHEN @P > 300 THEN 300 ELSE @P - 1 END));
            SET @PC = CHARINDEX(REVERSE(N'VCT_CONSULTORES'), @CTX);
            SET @PE = CHARINDEX(REVERSE(N'VCT_EMPLEADOS'), @CTX);
            IF @PC > 0 AND (@PE = 0 OR @PC < @PE)
            BEGIN
                SET @D = STUFF(@D, @P, LEN(@BUSCA), @PONE);
                SET @N = @N + 1;
                SET @P = CHARINDEX(@BUSCA, @D, @P + LEN(@PONE));
            END
            ELSE SET @P = CHARINDEX(@BUSCA, @D, @P + LEN(@BUSCA));
        END;
    END;

    IF @N > 0
    BEGIN
        SET @Q = CHARINDEX(N'CREATE', @D);
        WHILE @Q > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @Q + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
              AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @Q + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
            SET @Q = CHARINDEX(N'CREATE', @D, @Q + 1);
        IF @Q > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @Q + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
            SET @D = STUFF(@D, @Q, 6, N'ALTER');
        BEGIN TRY
            EXEC sp_executesql @D;
            PRINT 'OK   dbo.' + @SP + ': consultor por usuario (' + CONVERT(VARCHAR(10), @N) + ' busqueda/s).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO dbo.' + @SP + ': ' + ERROR_MESSAGE();
        END CATCH;
    END;
    FETCH NEXT FROM csp INTO @SP;
END;
CLOSE csp;
DEALLOCATE csp;

IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO

/* control (solo lectura): a que consultor reconoce cada usuario de consultor sin vinculo */
SELECT C.ID, CONVERT(VARCHAR(150), C.APELLIDOS) AS APELLIDOS, CONVERT(VARCHAR(150), C.NOMBRES) AS NOMBRES,
       LOWER(REPLACE(LEFT(LTRIM(CONVERT(VARCHAR(150), C.NOMBRES)), 1) + LTRIM(RTRIM(CONVERT(VARCHAR(150), C.APELLIDOS))), ' ', '')) AS USUARIO_RECONOCIDO,
       CASE WHEN EXISTS (SELECT 1 FROM dbo.Users U WHERE LOWER(LTRIM(RTRIM(U.Id))) = LOWER(REPLACE(LEFT(LTRIM(CONVERT(VARCHAR(150), C.NOMBRES)), 1) + LTRIM(RTRIM(CONVERT(VARCHAR(150), C.APELLIDOS))), ' ', '')))
            THEN 'SI' ELSE 'NO' END AS EXISTE_USUARIO
FROM dbo.VCT_CONSULTORES C
WHERE C.ID = 50;
GO
