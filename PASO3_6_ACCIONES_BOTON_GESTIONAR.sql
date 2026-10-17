/* ========================================================================
   PASO3_6_ACCIONES_BOTON_GESTIONAR  (solo modifica el SP; no toca datos)
   ------------------------------------------------------------------------
   dbo.VCT_MAIN_ACCIONES (Vencidas / Hoy / Proximas / Sin fecha / Todas):
     - se saca el menu de 3 puntos de cada fila;
     - en su lugar va el boton "Gestionar" (vct-btn vct-btn-new vct-btn-sm,
       sin icono), igual al de la pestana Acciones de la Vista 360;
       sigue llevando a la Vista 360 del proyecto;
     - la columna pasa de 44 a 110 (mismo ancho que en la Vista 360).
   Parchea la definicion vigente. Marca ACC_GESTIONAR_BTN_V1. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_ACCIONES')), @OK BIT = 1, @P INT,
        @B1 NVARCHAR(400) = N'A.ID_PROYECTO), ''vctdg-menu-item'', P.TITLE)',
        @B2 NVARCHAR(400) = N'''<button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>''',
        @B3 NVARCHAR(400) = N'''<div class="vctdg-rowmenu-items" hidden>'' + A.MENU + ''</div>''',
        @B4 NVARCHAR(400) = N'<th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>';

IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_ACCIONES.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%ACC_GESTIONAR_BTN_V1%' BEGIN PRINT 'OK   dbo.VCT_MAIN_ACCIONES ya tenia el boton Gestionar.'; SET @OK = 0; END;
IF @OK = 1 AND (CHARINDEX(@B1, @D) = 0 OR CHARINDEX(@B2, @D) = 0 OR CHARINDEX(@B3, @D) = 0 OR CHARINDEX(@B4, @D) = 0)
BEGIN
    PRINT 'FALLO dbo.VCT_MAIN_ACCIONES: no se encontro ('
        + CASE WHEN CHARINDEX(@B1, @D) = 0 THEN 'clase del item Gestionar ' ELSE '' END
        + CASE WHEN CHARINDEX(@B2, @D) = 0 THEN 'boton 3 puntos ' ELSE '' END
        + CASE WHEN CHARINDEX(@B3, @D) = 0 THEN 'contenedor del menu ' ELSE '' END
        + CASE WHEN CHARINDEX(@B4, @D) = 0 THEN 'columna del menu' ELSE '' END + ').';
    SET @OK = 0;
END;

IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @B1, N'A.ID_PROYECTO), ''vct-btn vct-btn-new vct-btn-sm'', P.TITLE)');
    SET @D = REPLACE(@D, @B2, N''''' /* ACC_GESTIONAR_BTN_V1 */');
    SET @D = REPLACE(@D, @B3, N'REPLACE(A.MENU, ''<span data-vct-icon="arrow-right"></span>'', '''')');
    SET @D = REPLACE(@D, @B4, N'<th class="vct-col-action" data-vct-width="110" data-vct-export-ignore="true"></th>');

    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @D = STUFF(@D, @P, 6, N'ALTER');

    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_ACCIONES: boton Gestionar por fila (sin menu de 3 puntos).';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_ACCIONES: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
