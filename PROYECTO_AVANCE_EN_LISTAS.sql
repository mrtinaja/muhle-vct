/* ========================================================================
   PROYECTO_AVANCE_EN_LISTAS
   ------------------------------------------------------------------------
   Las listas de proyectos de la Vista 360 de Cliente, Consultor y Empleado
   mostraban 0%: leen VCT_PROYECTOS.PORCENTAJE_AVANCE, que nadie actualiza.
   La Vista 360 de Proyecto ya usa dbo.VCT_PROYECTO_AVANCE (lanzamiento 10%
   + plan 90%). Este parche hace que las tres listas usen el mismo calculo.
   Por cada SP: si TODAS sus referencias a PORCENTAJE_AVANCE son
   "ISNULL(P.PORCENTAJE_AVANCE,0)", las reemplaza; si no, no lo toca y
   muestra donde aparece (para ajustarlo a mano). Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @SPS TABLE (N INT IDENTITY, NOMBRE SYSNAME);
INSERT INTO @SPS (NOMBRE) VALUES ('VCT_MAIN_CLIENTES_V360'), ('VCT_MAIN_CONSULTORES_V360'), ('VCT_MAIN_EMPLEADOS_V360');

DECLARE @MK NVARCHAR(100) = N'ISNULL(P.PORCENTAJE_AVANCE,0)',
        @NEW NVARCHAR(200) = N'ISNULL((SELECT TOP 1 AV_X.AVANCE FROM dbo.VCT_PROYECTO_AVANCE(P.ID) AV_X),0)',
        @i INT = 1, @NOM SYSNAME, @D NVARCHAR(MAX), @TOT INT, @EXACT INT, @p INT, @msg NVARCHAR(4000);

WHILE @i <= (SELECT MAX(N) FROM @SPS)
BEGIN
    SELECT @NOM = NOMBRE FROM @SPS WHERE N = @i;
    SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @NOM));

    IF @D IS NULL
        PRINT @NOM + ': no existe. Sin cambios.';
    ELSE
    BEGIN
        SET @TOT = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, N'PORCENTAJE_AVANCE', N''))) / DATALENGTH(N'PORCENTAJE_AVANCE');
        SET @EXACT = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @MK, N''))) / DATALENGTH(@MK);

        IF @TOT = 0
            PRINT @NOM + ': no usa PORCENTAJE_AVANCE (ya estaba corregido). Sin cambios.';
        ELSE IF @TOT <> @EXACT
        BEGIN
            PRINT @NOM + ': tiene ' + CONVERT(VARCHAR(10), @TOT) + ' referencias a PORCENTAJE_AVANCE y solo '
                  + CONVERT(VARCHAR(10), @EXACT) + ' con la forma esperada. Sin cambios. Donde aparece:';
            SET @p = CHARINDEX(N'PORCENTAJE_AVANCE', @D);
            WHILE @p > 0
            BEGIN
                SET @msg = N'   ...' + REPLACE(REPLACE(SUBSTRING(@D, CASE WHEN @p > 80 THEN @p - 80 ELSE 1 END, 180), NCHAR(13), N' '), NCHAR(10), N' ') + N'...';
                PRINT @msg;
                SET @p = CHARINDEX(N'PORCENTAJE_AVANCE', @D, @p + 1);
            END;
        END
        ELSE
        BEGIN
            SET @D = REPLACE(@D, @MK, @NEW);
            SET @p = CHARINDEX(N'PROCEDURE', @D);
            IF CHARINDEX(N'CREATE', SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, 40)) > 0
               AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, 40)) = 0
                SET @D = STUFF(@D, (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, 40)) - 1, 6, N'ALTER ');
            BEGIN TRY
                EXEC sp_executesql @D;
                PRINT 'OK: ' + @NOM + ' (' + CONVERT(VARCHAR(10), @EXACT) + ' reemplazos) usa el avance calculado.';
            END TRY
            BEGIN CATCH
                PRINT 'ERROR en ' + @NOM + ': ' + ERROR_MESSAGE() + ' (sin cambios)';
            END CATCH;
        END;
    END;
    SET @i = @i + 1;
END;
GO
