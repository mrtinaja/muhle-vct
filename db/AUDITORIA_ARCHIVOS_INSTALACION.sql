/* ========================================================================
   AUDITORIA_ARCHIVOS_INSTALACION  (CREA TABLA, SP Y USUARIO DE SERVICIO)
   ------------------------------------------------------------------------
   Recibe los cambios de archivos que detecta el vigilante del servidor web
   (tools/vigilante/vigilar_archivos.ps1) y avisa por mail.
     - dbo.VCT_AUDITORIA_ARCHIVOS: una fila por archivo agregado/cambiado/borrado.
     - dbo.VCT_AUDITORIA_ARCHIVOS_AVISAR: la llama el vigilante; guarda las
       filas y manda UN mail con la lista (Database Mail, VocaturoProfile).
     - Login VIGILANTE_ARCHIVOS: solo puede ejecutar ese SP y mandar mail.
       La CLAVE la elige quien corre el script (reemplazar <CLAVE> abajo).
       Si el servidor web esta en el mismo dominio que SQL Server, se puede
       usar la cuenta de Windows de la tarea en vez de este login.
   Correr primero en DESARROLLO. Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('dbo.VCT_AUDITORIA_ARCHIVOS') IS NULL
BEGIN
    CREATE TABLE dbo.VCT_AUDITORIA_ARCHIVOS
    (
        ID            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VCT_AUDITORIA_ARCHIVOS PRIMARY KEY,
        FECHA         DATETIME       NOT NULL CONSTRAINT DF_VCT_AUD_ARCH_FECHA DEFAULT (GETDATE()),
        SERVIDOR      NVARCHAR(200)  NULL,
        ACCION        NVARCHAR(10)   NULL,   /* ALTA / CAMBIO / BAJA */
        RUTA          NVARCHAR(600)  NULL,
        TAMANO        BIGINT         NULL,
        MODIFICADO    NVARCHAR(30)   NULL,
        HASH          VARCHAR(64)    NULL,
        MAIL_ENVIADO  BIT            NOT NULL CONSTRAINT DF_VCT_AUD_ARCH_MAIL DEFAULT (0)
    );
    CREATE INDEX IX_VCT_AUDITORIA_ARCHIVOS_RUTA ON dbo.VCT_AUDITORIA_ARCHIVOS (RUTA, ID);
    PRINT 'Tabla dbo.VCT_AUDITORIA_ARCHIVOS creada.';
END
GO
CREATE OR ALTER PROCEDURE dbo.VCT_AUDITORIA_ARCHIVOS_AVISAR
(
    @SERVIDOR NVARCHAR(200),
    @LISTA    NVARCHAR(MAX)   /* lineas "ACCION<TAB>RUTA<TAB>TAMANO<TAB>MODIFICADO<TAB>HASH" separadas por salto de linea */
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PARA   VARCHAR(MAX) = 'martin.aja@squad.com.ar';
    DECLARE @PERFIL SYSNAME      = 'VocaturoProfile';

    DECLARE @NUEVAS TABLE (ID INT);
    DECLARE @RESTO NVARCHAR(MAX) = REPLACE(ISNULL(@LISTA, N''), NCHAR(13), N'') + NCHAR(10),
            @P INT, @L NVARCHAR(MAX), @C NVARCHAR(MAX), @I INT, @F TABLE (N INT, V NVARCHAR(600));

    WHILE LEN(@RESTO) > 0
    BEGIN
        SET @P = CHARINDEX(NCHAR(10), @RESTO);
        SET @L = LEFT(@RESTO, @P - 1);
        SET @RESTO = SUBSTRING(@RESTO, @P + 1, 2147483647);
        IF LEN(@L) = 0 CONTINUE;

        DELETE @F; SET @I = 1; SET @L = @L + NCHAR(9);
        WHILE CHARINDEX(NCHAR(9), @L) > 0
        BEGIN
            SET @C = LEFT(@L, CHARINDEX(NCHAR(9), @L) - 1);
            INSERT @F VALUES (@I, LEFT(@C, 600));
            SET @L = SUBSTRING(@L, CHARINDEX(NCHAR(9), @L) + 1, 2147483647);
            SET @I = @I + 1;
        END;

        INSERT dbo.VCT_AUDITORIA_ARCHIVOS (SERVIDOR, ACCION, RUTA, TAMANO, MODIFICADO, HASH)
        OUTPUT inserted.ID INTO @NUEVAS
        SELECT @SERVIDOR,
               (SELECT LEFT(V, 10) FROM @F WHERE N = 1),
               (SELECT V FROM @F WHERE N = 2),
               TRY_CONVERT(BIGINT, (SELECT V FROM @F WHERE N = 3)),
               (SELECT LEFT(V, 30) FROM @F WHERE N = 4),
               (SELECT LEFT(V, 64) FROM @F WHERE N = 5);
    END;

    DECLARE @CANT INT = (SELECT COUNT(*) FROM @NUEVAS);
    IF @CANT = 0 RETURN;

    DECLARE @CUERPO NVARCHAR(MAX) =
          N'Servidor web: ' + ISNULL(@SERVIDOR, N'?') + NCHAR(13) + NCHAR(10)
        + N'Detectado:    ' + CONVERT(NVARCHAR(19), GETDATE(), 120) + NCHAR(13) + NCHAR(10)
        + N'Archivos:     ' + CONVERT(NVARCHAR(10), @CANT) + NCHAR(13) + NCHAR(10) + NCHAR(13) + NCHAR(10)
        + ISNULL(STUFF((SELECT TOP 100 NCHAR(13) + NCHAR(10) + A.ACCION + N'  ' + A.RUTA
                              + ISNULL(N'  (' + CONVERT(NVARCHAR(20), A.TAMANO) + N' bytes, ' + A.MODIFICADO + N')', N'')
                        FROM dbo.VCT_AUDITORIA_ARCHIVOS A JOIN @NUEVAS N ON N.ID = A.ID
                        ORDER BY A.RUTA
                        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, N''), N'')
        + CASE WHEN @CANT > 100 THEN NCHAR(13) + NCHAR(10) + N'... y ' + CONVERT(NVARCHAR(10), @CANT - 100) + N' mas.' ELSE N'' END
        + NCHAR(13) + NCHAR(10) + NCHAR(13) + NCHAR(10)
        + N'Detalle: SELECT * FROM dbo.VCT_AUDITORIA_ARCHIVOS ORDER BY ID DESC'
        + NCHAR(13) + NCHAR(10)
        + N'Copia de cada version nueva: carpeta historial del vigilante en el servidor web.';

    BEGIN TRY
        DECLARE @ASUNTO NVARCHAR(255) = LEFT(N'[Archivos ' + ISNULL(@SERVIDOR, N'?') + N'] ' + CONVERT(NVARCHAR(10), @CANT) + N' archivo(s) cambiado(s)', 255);
        EXEC msdb.dbo.sp_send_dbmail
             @profile_name = @PERFIL, @recipients = @PARA,
             @subject = @ASUNTO, @body = @CUERPO, @body_format = 'TEXT';
        UPDATE A SET MAIL_ENVIADO = 1 FROM dbo.VCT_AUDITORIA_ARCHIVOS A JOIN @NUEVAS N ON N.ID = A.ID;
    END TRY
    BEGIN CATCH
        /* sin mail: los cambios quedan registrados igual */
    END CATCH;
END
GO
/* ---------------- Usuario de servicio (solo ejecutar el SP y mandar mail) ----------------
   Reemplazar <CLAVE> por una clave elegida por quien instala (no compartirla por chat).  */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'VIGILANTE_ARCHIVOS')
    CREATE LOGIN VIGILANTE_ARCHIVOS WITH PASSWORD = '<CLAVE>', CHECK_POLICY = ON, DEFAULT_DATABASE = [MuhlePROD];
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'VIGILANTE_ARCHIVOS')
    CREATE USER VIGILANTE_ARCHIVOS FOR LOGIN VIGILANTE_ARCHIVOS;
GRANT EXECUTE ON dbo.VCT_AUDITORIA_ARCHIVOS_AVISAR TO VIGILANTE_ARCHIVOS;
GO
USE [msdb];
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'VIGILANTE_ARCHIVOS')
    CREATE USER VIGILANTE_ARCHIVOS FOR LOGIN VIGILANTE_ARCHIVOS;
ALTER ROLE DatabaseMailUserRole ADD MEMBER VIGILANTE_ARCHIVOS;
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysmail_principalprofile pp
               JOIN msdb.dbo.sysmail_profile p ON p.profile_id = pp.profile_id
               JOIN sys.database_principals d ON d.sid = pp.principal_sid
               WHERE p.name = 'VocaturoProfile' AND d.name = 'VIGILANTE_ARCHIVOS')
    EXEC msdb.dbo.sysmail_add_principalprofile_sp @principal_name = 'VIGILANTE_ARCHIVOS', @profile_name = 'VocaturoProfile', @is_default = 0;
GO
PRINT 'Auditoria de archivos instalada. Siguiente paso: tools/vigilante/LEEME.md en el servidor web.';
GO
