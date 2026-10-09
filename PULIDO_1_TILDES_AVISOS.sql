/* ========================================================================
   PULIDO_1_TILDES_AVISOS
   ------------------------------------------------------------------------
   Los avisos verde/rojo de Lanzamiento, Plan Estrategico y Visitas (ficha
   del proyecto) salian sin tildes ("Gestion cumplida", "Item guardado",
   "reunion"...). Los mensajes se escribieron en ASCII a proposito (los
   scripts se pegan en SSMS sin problemas de codificacion).
     1. dbo.VCT_TXT_ES: recibe el texto YA escapado y reemplaza palabras
        enteras por su version con tilde en entidades HTML (&oacute;...).
     2. VCT_PROYECTO_LANZ_RENDER / _PLAN_RENDER / _VISITA_RENDER: el aviso
        pasa por dbo.VCT_TXT_ES. No se toca la logica.
   Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.VCT_TXT_ES (@S VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @S IS NULL OR @S = '' RETURN @S;
    DECLARE @W TABLE (N INT IDENTITY, A VARCHAR(40), B VARCHAR(80));
    INSERT INTO @W (A, B) VALUES
        ('Estrategico','Estrat&eacute;gico'),('estrategico','estrat&eacute;gico'),
        ('Gestion','Gesti&oacute;n'),('gestion','gesti&oacute;n'),
        ('Item','&Iacute;tem'),('item','&iacute;tem'),('items','&iacute;tems'),
        ('Reunion','Reuni&oacute;n'),('reunion','reuni&oacute;n'),
        ('Consideracion','Consideraci&oacute;n'),('consideracion','consideraci&oacute;n'),
        ('lider','l&iacute;der'),('Lider','L&iacute;der'),
        ('valida','v&aacute;lida'),('valido','v&aacute;lido'),('numero','n&uacute;mero'),
        ('todavia','todav&iacute;a'),('esta','est&aacute;'),('asi','as&iacute;'),
        ('quedo','qued&oacute;'),('creo','cre&oacute;'),('aviso','avis&oacute;'),('agrego','agreg&oacute;'),
        ('encontro','encontr&oacute;'),('envio','envi&oacute;'),('fallo','fall&oacute;'),
        ('parametria','parametr&iacute;a');

    /* bordes de palabra: espacio, punto, coma, dos puntos, parentesis, fin */
    DECLARE @R VARCHAR(MAX) = ' ' + @S + ' ', @i INT = 1, @n INT = (SELECT COUNT(*) FROM @W), @A VARCHAR(40), @B VARCHAR(80);
    WHILE @i <= @n
    BEGIN
        SELECT @A = A, @B = B FROM @W WHERE N = @i;
        IF @A <> @B
        BEGIN
            SET @R = REPLACE(@R COLLATE Latin1_General_CS_AS, ' ' + @A + ' ', ' ' + @B + ' ');
            SET @R = REPLACE(@R COLLATE Latin1_General_CS_AS, ' ' + @A + '.', ' ' + @B + '.');
            SET @R = REPLACE(@R COLLATE Latin1_General_CS_AS, ' ' + @A + ',', ' ' + @B + ',');
            SET @R = REPLACE(@R COLLATE Latin1_General_CS_AS, ' ' + @A + ':', ' ' + @B + ':');
            SET @R = REPLACE(@R COLLATE Latin1_General_CS_AS, ' ' + @A + ')', ' ' + @B + ')');
            SET @R = REPLACE(@R COLLATE Latin1_General_CS_AS, '(' + @A + ' ', '(' + @B + ' ');
        END;
        SET @i = @i + 1;
    END;
    RETURN SUBSTRING(@R, 2, LEN(@R + 'x') - 3);
END
GO

/* prueba */
SELECT dbo.VCT_TXT_ES('Proyecto iniciado: quedo En curso y se creo la gestion del Plan Estrategico para el consultor lider.') AS PRUEBA_1,
       dbo.VCT_TXT_ES('Item guardado. Se aviso al analista del cambio de fechas.') AS PRUEBA_2,
       dbo.VCT_TXT_ES('El proyecto ya fue iniciado o no esta en estado Confirmado.') AS PRUEBA_3;
GO

/* conectar en los tres render */
DECLARE @SPS TABLE (N INT IDENTITY, NOMBRE SYSNAME);
INSERT INTO @SPS (NOMBRE) VALUES ('VCT_PROYECTO_LANZ_RENDER'), ('VCT_PROYECTO_PLAN_RENDER'), ('VCT_PROYECTO_VISITA_RENDER');
DECLARE @i INT = 1, @NOM SYSNAME, @D NVARCHAR(MAX), @c INT, @kp INT, @kpre NVARCHAR(60);
WHILE @i <= 3
BEGIN
    SELECT @NOM = NOMBRE FROM @SPS WHERE N = @i;
    SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @NOM));
    IF @D IS NULL
        PRINT @NOM + ': no existe.';
    ELSE IF CHARINDEX(N'VCT_TXT_ES(', @D) > 0
        PRINT @NOM + ': ya usaba VCT_TXT_ES.';
    ELSE
    BEGIN
        SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, N'dbo.VCT_HTML_ESC(@ERROR)', N''))) / DATALENGTH(N'dbo.VCT_HTML_ESC(@ERROR)')
               + (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, N'dbo.VCT_HTML_ESC(@MENSAJE)', N''))) / DATALENGTH(N'dbo.VCT_HTML_ESC(@MENSAJE)');
        IF @c <> 2
            PRINT @NOM + ': se esperaban 2 avisos y hay ' + CONVERT(VARCHAR(10), @c) + '. Sin cambios.';
        ELSE
        BEGIN
            SET @D = REPLACE(@D, N'dbo.VCT_HTML_ESC(@ERROR)', N'dbo.VCT_TXT_ES(dbo.VCT_HTML_ESC(@ERROR))');
            SET @D = REPLACE(@D, N'dbo.VCT_HTML_ESC(@MENSAJE)', N'dbo.VCT_TXT_ES(dbo.VCT_HTML_ESC(@MENSAJE))');
            /* CREATE -> ALTER solo en el encabezado (las 40 letras antes de PROCEDURE) */
            SET @kp = CHARINDEX(N'PROCEDURE', @D);
            SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
            IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
                SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
            BEGIN TRY
                EXEC sp_executesql @D;
                PRINT 'OK: ' + @NOM + ' muestra los avisos con tildes.';
            END TRY
            BEGIN CATCH
                PRINT 'ERROR en ' + @NOM + ': ' + ERROR_MESSAGE();
            END CATCH;
        END;
    END;
    SET @i = @i + 1;
END;
GO
