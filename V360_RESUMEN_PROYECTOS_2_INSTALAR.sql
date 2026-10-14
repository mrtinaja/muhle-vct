/* V360_RESUMEN_PROYECTOS_V2
   Aplica sobre las definiciones VIGENTES de los cuatro procedimientos.
   Carga los assets que corrigen las tablas de proyectos recientes.
   Subir primero css/vct-resumen-proyectos.css y js/vct-resumen-proyectos.js.
   Re-ejecutable: si la marca existe, no vuelve a modificar el procedimiento.
   No altera consultas, permisos, calculos ni registros de negocio.
*/
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @Objects TABLE (N INT PRIMARY KEY, Name SYSNAME);
INSERT INTO @Objects VALUES
    (1,'VCT_MAIN_CONSULTORES_V360'),
    (2,'VCT_MAIN_EMPLEADOS_V360'),
    (3,'VCT_MAIN_CLIENTES_V360'),
    (4,'VCT_MAIN_PROVEEDORES_V360');
DECLARE @N INT=1,@Name SYSNAME,@D NVARCHAR(MAX),@P INT,@CreatePos INT,@AlterPos INT,@Start INT,
        @Prefix NVARCHAR(MAX),@Count INT=0;
DECLARE @AssetCode NVARCHAR(MAX)=N'
    /* VCT_RESUMEN_PROYECTOS_V2 */
    SET @OUTPARAM1 = ISNULL(@OUTPARAM1, '''')
        + ''<link rel="stylesheet" href="../css/vct-resumen-proyectos.css?v=2">''
        + ''<script src="../js/vct-resumen-proyectos.js?v=2"></script>'';
';

BEGIN TRY
    BEGIN TRANSACTION;
    WHILE @N<=4
    BEGIN
        SELECT @Name=Name FROM @Objects WHERE N=@N;
        SET @D=OBJECT_DEFINITION(OBJECT_ID(N'dbo.'+@Name));
        IF @D IS NULL
        BEGIN
            RAISERROR('No se pudo leer dbo.%s. Se cancela toda la instalacion.',16,1,@Name);
        END;
        IF CHARINDEX(N'VCT_RESUMEN_PROYECTOS_V2',@D)>0
            PRINT @Name+': ya aplicado, sin cambios.';
        ELSE
        BEGIN
            /* El HTML puede venir de un renderer compartido; no se exige una clase literal. */
            IF CHARINDEX(N'@OUTPARAM1',UPPER(@D))=0
                RAISERROR('dbo.%s no tiene el parametro de salida OUTPARAM1. Se cancela la instalacion.',16,1,@Name);

            IF CHARINDEX(N'VCT_RESUMEN_PROYECTOS_V1',@D)>0
            BEGIN
                SET @D=REPLACE(@D,N'VCT_RESUMEN_PROYECTOS_V1',N'VCT_RESUMEN_PROYECTOS_V2');
                SET @D=REPLACE(@D,N'vct-resumen-proyectos.css?v=1',N'vct-resumen-proyectos.css?v=2');
                SET @D=REPLACE(@D,N'vct-resumen-proyectos.js?v=1',N'vct-resumen-proyectos.js?v=2');
            END;

            /* Normalizar CREATE/CREATE OR ALTER/ALTER solo en la cabecera. */
            SET @P=CHARINDEX(N'PROCEDURE',UPPER(@D));
            IF @P=0
                RAISERROR('No se identifico PROCEDURE en dbo.%s. Se cancela la instalacion.',16,1,@Name);
            SET @Prefix=LEFT(@D,@P-1);
            SET @CreatePos=CHARINDEX(REVERSE(N'CREATE'),REVERSE(UPPER(@Prefix)));
            SET @AlterPos=CHARINDEX(REVERSE(N'ALTER'),REVERSE(UPPER(@Prefix)));
            SET @CreatePos=CASE WHEN @CreatePos>0 THEN DATALENGTH(@Prefix)/2-@CreatePos-4 ELSE 0 END;
            SET @AlterPos=CASE WHEN @AlterPos>0 THEN DATALENGTH(@Prefix)/2-@AlterPos-3 ELSE 0 END;
            SET @Start=CASE WHEN @CreatePos>0 AND @P-@CreatePos<=40 THEN @CreatePos
                            WHEN @AlterPos>0 AND @P-@AlterPos<=40 THEN @AlterPos ELSE 0 END;
            IF @P=0 OR @Start=0
                RAISERROR('No se identifico la cabecera de dbo.%s. Se cancela la instalacion.',16,1,@Name);
            SET @D=STUFF(@D,@Start,@P-@Start,N'ALTER ');

            /* Insertar al final del cuerpo sin reemplazar el codigo vigente. */
            IF CHARINDEX(N'VCT_RESUMEN_PROYECTOS_V2',@D)=0
            BEGIN
            WHILE DATALENGTH(@D)>0 AND UNICODE(RIGHT(@D,1)) IN (9,10,13,32,59)
                SET @D=LEFT(@D,DATALENGTH(@D)/2-1);
            IF RIGHT(UPPER(@D),3)<>N'END'
                RAISERROR('El final de dbo.%s no coincide con END. Se cancela la instalacion.',16,1,@Name);
            SET @D=STUFF(@D,DATALENGTH(@D)/2-2,0,@AssetCode);
            END;
            EXEC sys.sp_executesql @D;
            SET @Count=@Count+1;
        END;
        SET @N=@N+1;
    END;
    COMMIT TRANSACTION;
    PRINT 'OK: assets de Resumen cargados. Procedimientos actualizados: '+CONVERT(VARCHAR(10),@Count)+'.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    DECLARE @Error NVARCHAR(4000)=ERROR_MESSAGE();
    RAISERROR('Instalacion cancelada y revertida: %s',16,1,@Error);
END CATCH;
GO
