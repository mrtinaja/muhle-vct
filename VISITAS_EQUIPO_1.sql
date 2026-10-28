/* ============================================================================
   VISITAS_EQUIPO_1  (28/10/2026)  marca VIS_EQ_V1   (correr despues de VISITAS_HORAS_DIA_1.sql)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_PROYECTO_V360, Nueva / Editar visita: los consultores elegidos que no son del equipo del
   proyecto (grupo "Otros consultores con el servicio de la visita") se agregan solos al equipo, con rol
   Consultor, en la misma transaccion que la visita. El mensaje lo avisa.
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'VIS_EQ_V1', @D) > 0
    PRINT 'OK   el parche VIS_EQ_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'VIS_HD_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes VISITAS_HORAS_DIA_1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* eq_alta */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                END;' + NCHAR(10) + N'                COMMIT;' + NCHAR(10) + N'                SET @MSG = CASE WHEN @AG_ID IS NOT NULL THEN ''Visita actualizada.''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                END;' + NCHAR(10) + N'                /* VIS_EQ_V1: consultor de la visita que no es del equipo del proyecto -> se agrega al equipo como consultor */' + NCHAR(10) + N'                DECLARE @AG_EQN INT;' + NCHAR(10) + N'                INSERT INTO dbo.VCT_PROYECTOS_EQUIPO' + NCHAR(10) + N'                    (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL, FECHA_DESDE, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)' + NCHAR(10) + N'                SELECT @ID_PROYECTO, NULL, ''CONSULTOR'', NULL, C.CONS, RL.ID, 0, GETDATE(), ''ACTIVO'', ''Agregado desde una visita'', GETDATE(), @IAGENTE' + NCHAR(10) + N'                FROM @AGC C' + NCHAR(10) + N'                CROSS JOIN (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE CODIGO = ''CONSULTOR'') RL' + NCHAR(10) + N'                WHERE NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)' + NCHAR(10) + N'                                  WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = ''CONSULTOR'' AND EQ.ID_CONSULTOR = C.CONS AND EQ.ESTADO = ''ACTIVO'');' + NCHAR(10) + N'                SET @AG_EQN = @@ROWCOUNT;' + NCHAR(10) + N'                COMMIT;' + NCHAR(10) + N'                SET @MSG = CASE WHEN @AG_ID IS NOT NULL THEN ''Visita actualizada.''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' eq_alta'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* eq_msg */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ELSE CONVERT(VARCHAR(10), @AG_NG) + '' visita(s) agendada(s): una por consultor.'' END;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ELSE CONVERT(VARCHAR(10), @AG_NG) + '' visita(s) agendada(s): una por consultor.'' END' + NCHAR(10) + N'                         + CASE WHEN ISNULL(@AG_EQN, 0) > 0 THEN '' Se sum'' + CHAR(243) + '' al equipo del proyecto: '' + CONVERT(VARCHAR(10), @AG_EQN) + '' consultor(es).'' ELSE '''' END;';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' eq_msg'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    IF @F <> N''
        PRINT 'FALLO: no se encontraron (o estan repetidos) en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (VIS_EQ_V1).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
