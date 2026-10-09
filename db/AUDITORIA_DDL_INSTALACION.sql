/* ========================================================================
   AUDITORIA_DDL_INSTALACION  (CREA TABLA + TRIGGER DE BASE)
   ------------------------------------------------------------------------
   Registra y avisa por mail cada CREATE / ALTER / DROP de procedimientos,
   funciones, vistas, triggers y tablas en MuhlePROD:
     - dbo.VCT_AUDITORIA_DDL: quien (login, maquina, programa), cuando,
       que objeto y el script completo que se ejecuto.
     - TR_VCT_AUDITORIA_DDL (trigger de base): guarda la fila y manda un
       mail con Database Mail (perfil VocaturoProfile).
   El trigger NUNCA frena un cambio: si el mail falla, el ALTER sigue
   igual y la fila queda con MAIL_ENVIADO = 0.

   Destinatarios: cambiar @PARA abajo (separar con ;).
   Correr primero en DESARROLLO. Se puede volver a correr.
   Para desactivarlo:  DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
   Para quitarlo:      DROP TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
   ======================================================================== */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('dbo.VCT_AUDITORIA_DDL') IS NULL
BEGIN
    CREATE TABLE dbo.VCT_AUDITORIA_DDL
    (
        ID            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VCT_AUDITORIA_DDL PRIMARY KEY,
        FECHA         DATETIME      NOT NULL CONSTRAINT DF_VCT_AUDITORIA_DDL_FECHA DEFAULT (GETDATE()),
        EVENTO        NVARCHAR(100) NULL,
        TIPO_OBJETO   NVARCHAR(60)  NULL,
        OBJETO        NVARCHAR(300) NULL,
        LOGIN_SQL     NVARCHAR(200) NULL,
        MAQUINA       NVARCHAR(200) NULL,
        PROGRAMA      NVARCHAR(300) NULL,
        SQL_TEXTO     NVARCHAR(MAX) NULL,
        MAIL_ENVIADO  BIT           NOT NULL CONSTRAINT DF_VCT_AUDITORIA_DDL_MAIL DEFAULT (0)
    );
    CREATE INDEX IX_VCT_AUDITORIA_DDL_OBJETO ON dbo.VCT_AUDITORIA_DDL (OBJETO, ID);
    PRINT 'Tabla dbo.VCT_AUDITORIA_DDL creada.';
END
GO
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0)
    DROP TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
GO
CREATE TRIGGER TR_VCT_AUDITORIA_DDL
ON DATABASE
FOR DDL_PROCEDURE_EVENTS, DDL_FUNCTION_EVENTS, DDL_VIEW_EVENTS, DDL_TRIGGER_EVENTS, DDL_TABLE_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;   /* un error del mail no debe deshacer el ALTER */

    DECLARE @PARA    VARCHAR(MAX) = 'martin.aja@squad.com.ar';
    DECLARE @PERFIL  SYSNAME      = 'VocaturoProfile';

    DECLARE @E XML = EVENTDATA(), @ID INT,
            @EVENTO NVARCHAR(100), @TIPO NVARCHAR(60), @OBJ NVARCHAR(300),
            @LOGIN NVARCHAR(200), @MAQ NVARCHAR(200), @PROG NVARCHAR(300), @SQL NVARCHAR(MAX);

    BEGIN TRY
        SELECT @EVENTO = @E.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
               @TIPO   = @E.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(60)'),
               @OBJ    = @E.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(128)') + N'.'
                       + @E.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)'),
               @LOGIN  = ORIGINAL_LOGIN(),
               @MAQ    = HOST_NAME(),
               @PROG   = APP_NAME(),
               @SQL    = @E.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');

        IF @OBJ = N'dbo.VCT_AUDITORIA_DDL' RETURN;

        INSERT dbo.VCT_AUDITORIA_DDL (EVENTO, TIPO_OBJETO, OBJETO, LOGIN_SQL, MAQUINA, PROGRAMA, SQL_TEXTO)
        VALUES (@EVENTO, @TIPO, @OBJ, @LOGIN, @MAQ, @PROG, @SQL);
        SET @ID = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        RETURN;
    END CATCH;

    BEGIN TRY
        DECLARE @ANT NVARCHAR(200) =
            (SELECT TOP 1 CONVERT(NVARCHAR(16), FECHA, 120) + N' por ' + ISNULL(LOGIN_SQL, N'?') + N' desde ' + ISNULL(MAQUINA, N'?')
             FROM dbo.VCT_AUDITORIA_DDL WHERE OBJETO = @OBJ AND ID < @ID ORDER BY ID DESC);

        DECLARE @ASUNTO NVARCHAR(255) = LEFT(N'[MuhlePROD ' + @@SERVERNAME + N'] ' + @EVENTO + N' ' + @OBJ, 255);
        DECLARE @CUERPO NVARCHAR(MAX) =
              N'Servidor: ' + @@SERVERNAME + NCHAR(13) + NCHAR(10)
            + N'Cambio:   ' + @EVENTO + N' ' + ISNULL(@TIPO, N'') + N' ' + @OBJ + NCHAR(13) + NCHAR(10)
            + N'Cuando:   ' + CONVERT(NVARCHAR(19), GETDATE(), 120) + NCHAR(13) + NCHAR(10)
            + N'Quien:    ' + ISNULL(@LOGIN, N'?') + N' desde ' + ISNULL(@MAQ, N'?') + N' (' + ISNULL(@PROG, N'?') + N')' + NCHAR(13) + NCHAR(10)
            + N'Cambio anterior de este objeto: ' + ISNULL(@ANT, N'ninguno registrado') + NCHAR(13) + NCHAR(10)
            + N'Registro completo: SELECT * FROM dbo.VCT_AUDITORIA_DDL WHERE ID = ' + CONVERT(NVARCHAR(12), @ID) + NCHAR(13) + NCHAR(10)
            + NCHAR(13) + NCHAR(10) + N'--- Primeros 3000 caracteres del script ---' + NCHAR(13) + NCHAR(10)
            + LEFT(ISNULL(@SQL, N''), 3000);

        EXEC msdb.dbo.sp_send_dbmail
             @profile_name = @PERFIL,
             @recipients   = @PARA,
             @subject      = @ASUNTO,
             @body         = @CUERPO,
             @body_format  = 'TEXT';

        UPDATE dbo.VCT_AUDITORIA_DDL SET MAIL_ENVIADO = 1 WHERE ID = @ID;
    END TRY
    BEGIN CATCH
        /* sin mail: el cambio queda registrado igual */
    END CATCH;
END
GO
PRINT 'Trigger TR_VCT_AUDITORIA_DDL instalado. Prueba: crear y borrar un SP de prueba y revisar el mail.';
GO
/* ---- Prueba (opcional): deberia llegar 2 mails ----
CREATE PROCEDURE dbo.ZZ_PRUEBA_AUDITORIA AS SELECT 1;
GO
DROP PROCEDURE dbo.ZZ_PRUEBA_AUDITORIA;
GO
SELECT TOP 5 * FROM dbo.VCT_AUDITORIA_DDL ORDER BY ID DESC;
*/
