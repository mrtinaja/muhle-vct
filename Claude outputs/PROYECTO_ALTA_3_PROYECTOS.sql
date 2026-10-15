/* ========================================================================
   PROYECTO_ALTA_3_PROYECTOS                                (paso 3 de 3)
   ------------------------------------------------------------------------
   Entrada 1 del alta: pantalla Proyectos (sidebar), boton "Nuevo".
   Parchea dbo.VCT_MAIN_PROYECTOS por anclas sobre la definicion vigente
   del servidor (no se reescribe el SP). Requiere PROYECTO_ALTA_2_SP.sql.

   Como funciona (mismo mecanismo que "Otros estados", sin ACTION nuevo):
     - "Nuevo" se muestra solo si VCT_MAIN_GET_ACTIONS(@IUNIDAD,'PROYECTOS')
       devuelve una accion CREATE (ya lo calculaba el SP en @BTN_NUEVO).
       El boton guarda TEXTO30='PRY_MODO_ALTA' y refresca el mismo paso
       (js/vct-proyectos.js v5, ya instalado).
     - TEXTO30='PRY_MODO_ALTA'    -> VCT_PROYECTO_ALTA_RENDER (cliente a elegir)
     - TEXTO30='PRY_ALTA_GUARDAR' -> VCT_PROYECTO_ALTA_GUARDAR
           error -> vuelve el formulario con el error y lo cargado
           ok    -> grilla de proyectos con aviso + boton "Ver proyecto"
                    (accion VIEW de VCT_MAIN_GET_ACTIONS, valor = id nuevo)
     - Cancelar -> TEXTO30='PRY_MODO_VIGENTES' -> grilla.
   Assets nuevos solo en modo alta: css/vct-proyecto-nuevo.css?v=1,
   js/vct-proyecto-nuevo.js?v=1 (no se pisan los vct-proyecto-alta.* viejos).
   Re-ejecutable: si ya tiene la marca PROYECTO_ALTA_V1 no hace nada.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_PROYECTOS')),
        @P INT, @Q INT, @TRG_ON BIT = 0, @ANC NVARCHAR(400), @BLK NVARCHAR(MAX);

IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_PROYECTOS.'; RETURN; END;
IF @D LIKE N'%PROYECTO_ALTA_V1%' BEGIN PRINT 'OK   VCT_MAIN_PROYECTOS ya tiene PROYECTO_ALTA_V1. No se hizo nada.'; RETURN; END;
IF OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER') IS NULL OR OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_GUARDAR') IS NULL
BEGIN PRINT 'FALLO falta correr PROYECTO_ALTA_2_SP.sql.'; RETURN; END;

/* CREATE ... PROCEDURE -> ALTER PROCEDURE */
SET @P = PATINDEX(N'%CREATE%PROCEDURE%', @D);
SET @Q = CHARINDEX(N'PROCEDURE', @D, @P);
IF @P = 0 OR @Q = 0 BEGIN PRINT 'FALLO no se encontro el encabezado CREATE PROCEDURE.'; RETURN; END;
SET @D = STUFF(@D, @P, @Q + LEN(N'PROCEDURE') - @P, N'ALTER PROCEDURE');

/* ---------- ancla 1: despues de calcular @BTN_NUEVO ---------- */
SET @ANC = N'SET @BTN_NUEVO = ISNULL(@BTN_NUEVO,'''');';
SET @P = CHARINDEX(@ANC, @D);
IF @P = 0 BEGIN PRINT 'FALLO ancla 1 no encontrada: ' + @ANC; RETURN; END;

SET @BLK = N'

    /* PROYECTO_ALTA_V1: alta de proyecto en pagina completa sobre el mismo paso.
       Permiso = la accion CREATE ya resuelta en @BTN_NUEVO (VCT_MAIN_GET_ACTIONS). */
    DECLARE @ALTA_ERR VARCHAR(1000) = '''', @ALTA_MSG VARCHAR(1000) = '''', @ALTA_ID INT = NULL,
            @ALTA_HTML VARCHAR(MAX) = '''', @ALTA_OK VARCHAR(MAX) = '''', @ALTA_VER VARCHAR(MAX) = '''';
    IF @BTN_NUEVO <> ''''
        SET @BTN_NUEVO = ''<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pry-modo="PRY_MODO_ALTA" data-vct-tooltip="Nuevo proyecto">''
                       + ''<span data-vct-icon="plus"></span><span>Nuevo</span></button>'';
    IF @B_CMD IN (''PRY_MODO_ALTA'',''PRY_ALTA_GUARDAR'') AND @BTN_NUEVO <> ''''
    BEGIN
        UPDATE dbo.VCT_BUFFER SET TEXTO30 = NULL WHERE PAR_KEY = @IPKEYJOB;

        IF @B_CMD = ''PRY_ALTA_GUARDAR''
            EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR @IPKEYJOB = @IPKEYJOB, @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE,
                 @ID_CLIENTE_FIJO = NULL, @ID_PROYECTO = @ALTA_ID OUTPUT, @ERROR = @ALTA_ERR OUTPUT, @MENSAJE = @ALTA_MSG OUTPUT;

        IF @B_CMD = ''PRY_MODO_ALTA'' OR ISNULL(@ALTA_ERR,'''') <> ''''
        BEGIN
            EXEC dbo.VCT_PROYECTO_ALTA_RENDER @IPKEYJOB = @IPKEYJOB, @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE,
                 @ID_CLIENTE = NULL, @ERROR = @ALTA_ERR, @CMD_GUARDAR = ''PRY_ALTA_GUARDAR'', @CMD_CANCELAR = ''PRY_MODO_VIGENTES'',
                 @HTML = @ALTA_HTML OUTPUT;
            SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'''') + @ASSETS
                + ''<link rel="stylesheet" href="../css/vct-proyecto-nuevo.css?v=1"><script src="../js/vct-proyecto-nuevo.js?v=1"></script>''
                + ''<div class="vct-page vct-page-main vct-proy-page" data-vct-page data-vct-sidebar-id="'' + CONVERT(VARCHAR(20), ISNULL(@SIDEBAR_ID,0)) + ''" data-vct-form-id="'' + @FORM_ESC + ''">''
                + ISNULL(@ALTA_HTML,'''') + ''</div>'';
            RETURN;
        END;

        /* alta OK: aviso arriba de la grilla + Ver proyecto (accion VIEW) */
        SELECT TOP 1 @ALTA_VER = dbo.VCT_MAIN_RENDER_ACTION(A.ACTION_ID, A.TITLE, A.ICON, A.STORAGE_KEY, A.TARGET_TAB, A.TARGET_GUID,
                                                            CONVERT(VARCHAR(20), @ALTA_ID), ''vct-btn vct-btn-secondary vct-btn-sm'', ''Ver proyecto'')
        FROM #ACT A WHERE A.ACTION_TYPE = ''VIEW'' ORDER BY A.SORT_ORDER, A.ID_PRM;
        SET @ALTA_OK = ''<div class="vct-card vct-pry-nuevo-ok" style="display:flex;align-items:center;gap:12px;padding:12px 16px;margin:0 0 14px;border-left:3px solid #059669;">''
                     + ''<span data-vct-icon="check" style="color:#059669"></span><span style="flex:1;font-size:12px">''
                     + REPLACE(REPLACE(ISNULL(@ALTA_MSG,''''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' + ISNULL(@ALTA_VER,'''') + ''</div>'';
    END;';
SET @D = STUFF(@D, @P + LEN(@ANC), 0, @BLK);

/* ---------- ancla 2: aviso de alta OK arriba de los KPIs ---------- */
SET @ANC = N'+ @KPIS';
SET @P = CHARINDEX(@ANC, @D);
IF @P = 0 BEGIN PRINT 'FALLO ancla 2 no encontrada: ' + @ANC; RETURN; END;
SET @D = STUFF(@D, @P, LEN(@ANC), N'+ ISNULL(@ALTA_OK,'''') + @KPIS');

/* ---------- aplicar ---------- */
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG_ON = 1;
END;

BEGIN TRY
    EXEC sp_executesql @D;
    PRINT 'OK   dbo.VCT_MAIN_PROYECTOS con alta de proyecto (PROYECTO_ALTA_V1).';
END TRY
BEGIN CATCH
    PRINT 'FALLO dbo.VCT_MAIN_PROYECTOS: ' + ERROR_MESSAGE();
END CATCH;

IF @TRG_ON = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
