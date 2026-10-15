/* V360_RESUMEN_PROYECTOS_3_CSS_V3
   Sube SOLO el cache-busting del css de Resumen (vct-resumen-proyectos.css)
   de ?v=2 a ?v=3 en los cuatro V360. El cambio v2 del css pone las etiquetas
   del card mobile en una sola linea (no se parten "PROY ECTO", "CONS ULTO R").
   El JS NO cambia (sigue en ?v=2).

   Subir primero css/vct-resumen-proyectos.css (version v2) al servidor web.
   Re-ejecutable: si ya esta en ?v=3, no toca el procedimiento.
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

BEGIN TRY
    BEGIN TRANSACTION;
    WHILE @N<=4
    BEGIN
        SELECT @Name=Name FROM @Objects WHERE N=@N;
        SET @D=OBJECT_DEFINITION(OBJECT_ID(N'dbo.'+@Name));
        IF @D IS NULL
            RAISERROR('No se pudo leer dbo.%s. Se cancela todo el parche.',16,1,@Name);

        IF CHARINDEX(N'vct-resumen-proyectos.css?v=3',@D)>0
            PRINT @Name+': ya en ?v=3, sin cambios.';
        ELSE IF CHARINDEX(N'vct-resumen-proyectos.css?v=2',@D)=0
            PRINT @Name+': no carga vct-resumen-proyectos.css?v=2 (revisar que el instalador V2 este aplicado). Sin cambios.';
        ELSE
        BEGIN
            SET @D=REPLACE(@D,N'vct-resumen-proyectos.css?v=2',N'vct-resumen-proyectos.css?v=3');

            /* Normalizar CREATE/CREATE OR ALTER/ALTER solo en la cabecera (igual que el instalador). */
            SET @P=CHARINDEX(N'PROCEDURE',UPPER(@D));
            IF @P=0
                RAISERROR('No se identifico PROCEDURE en dbo.%s. Se cancela el parche.',16,1,@Name);
            SET @Prefix=LEFT(@D,@P-1);
            SET @CreatePos=CHARINDEX(REVERSE(N'CREATE'),REVERSE(UPPER(@Prefix)));
            SET @AlterPos=CHARINDEX(REVERSE(N'ALTER'),REVERSE(UPPER(@Prefix)));
            SET @CreatePos=CASE WHEN @CreatePos>0 THEN DATALENGTH(@Prefix)/2-@CreatePos-4 ELSE 0 END;
            SET @AlterPos=CASE WHEN @AlterPos>0 THEN DATALENGTH(@Prefix)/2-@AlterPos-3 ELSE 0 END;
            SET @Start=CASE WHEN @CreatePos>0 AND @P-@CreatePos<=40 THEN @CreatePos
                            WHEN @AlterPos>0 AND @P-@AlterPos<=40 THEN @AlterPos ELSE 0 END;
            IF @P=0 OR @Start=0
                RAISERROR('No se identifico la cabecera de dbo.%s. Se cancela el parche.',16,1,@Name);
            SET @D=STUFF(@D,@Start,@P-@Start,N'ALTER ');

            EXEC sys.sp_executesql @D;
            SET @Count=@Count+1;
            PRINT @Name+': css -> ?v=3.';
        END;
        SET @N=@N+1;
    END;
    COMMIT TRANSACTION;
    PRINT 'OK: bump de css Resumen a ?v=3. Procedimientos actualizados: '+CONVERT(VARCHAR(10),@Count)+'.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    DECLARE @Error NVARCHAR(4000)=ERROR_MESSAGE();
    RAISERROR('Parche cancelado y revertido: %s',16,1,@Error);
END CATCH;
GO
