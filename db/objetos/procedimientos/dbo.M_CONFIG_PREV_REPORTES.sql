CREATE PROCEDURE [dbo].[M_CONFIG_PREV_REPORTES]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID AS VARCHAR(100),
 @PS_TITULO AS VARCHAR(MAX) OUTPUT,
 @PS_FORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
BEGIN
    SET NOCOUNT ON;
 
DECLARE @Id_Reporte			VARCHAR(50),
		@Desc_Reporte		VARCHAR(300),
		@VOPTIONS			VARCHAR(MAX),
		@VOPTIONS_MODULOS	VARCHAR(MAX),
		@VOPTIONS_ACCIONES	VARCHAR(MAX),
		@VOPTIONS_SECTORES	VARCHAR(MAX),
		@VOPTIONS_USUARIOS	VARCHAR(MAX),
		@VOPTIONS_PERFILES	VARCHAR(MAX),
		@VOPTIONS_PERMISOS	VARCHAR(MAX),
		@VFORM_ID_CLEAN		VARCHAR(100),
		@VHTML_HEADER		VARCHAR(MAX),
 
		--filtros--
		@VFECHA_DESDE		DATETIME,
		@VFECHA_HASTA		DATETIME,
		@VF_MODULO			VARCHAR(50),
		@VF_ACCION			VARCHAR(50),
		@VF_SECTOR			VARCHAR(50),
		@VF_USUARIO			VARCHAR(50),
		@VF_PERFIL			VARCHAR(50),
		@VF_PERMISO			VARCHAR(50)
 
	SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '')
 
	SELECT	@Id_Reporte		= ISNULL(ID_TASK_SEL,'')
	FROM	M_CONFIG
	WHERE	PAR_KEY = @IPKEYJOB
 
	--SETEO DEFAUL--
	IF (@Id_Reporte = '') BEGIN
		SET @Id_Reporte = '1'
 
		UPDATE	M_CONFIG
		SET		ID_TASK_SEL = @Id_Reporte
		WHERE	PAR_KEY = @IPKEYJOB
 
		SELECT	@Id_Reporte		= ISNULL(ID_TASK_SEL,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
	END
 
	--inicio reporte
	IF (@Id_Reporte = '1') BEGIN
 
		SELECT	@VFECHA_DESDE	= ISNULL(REP_FECHA_DESDE,''),
				@VFECHA_HASTA	= ISNULL(REP_FECHA_HASTA,''),
				@VF_MODULO		= ISNULL(REP_FILTRO1,''),
				@VF_ACCION		= ISNULL(REP_FILTRO2,''),
				@VF_USUARIO		= ISNULL(REP_FILTRO4,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
		--SETEO DEFAULT FECHAS--
		IF (@VFECHA_DESDE = '') BEGIN
 
			UPDATE	M_CONFIG
			SET		REP_FECHA_DESDE = GETDATE()-5,
					REP_FECHA_HASTA = GETDATE()
			WHERE	PAR_KEY = @IPKEYJOB
 
			SELECT	@VFECHA_DESDE	= ISNULL(REP_FECHA_DESDE,''),
					@VFECHA_HASTA	= ISNULL(REP_FECHA_HASTA,'')
			FROM	M_CONFIG
			WHERE	PAR_KEY = @IPKEYJOB
 
		END
 
		SET @VOPTIONS_MODULOS = '<option value="">Todos los módulos</option>'
 
		DECLARE @code_modulo VARCHAR(50), @desc_modulo varchar(300)
 
		DECLARE cursor_options_modulos CURSOR FOR
			SELECT	'USUARIOS', 'Usuarios'
			UNION
			SELECT	'PERFILES', 'Perfiles'
			UNION
			SELECT	'ESTRUCTURA', 'Estructura'
			UNION
			SELECT	'AREA', 'Areas'
			UNION
			SELECT	'PSESSIONS', 'Psessions'
			UNION
			SELECT	'PERFIL_ADMIN', 'Admin. Seguridad'
			ORDER BY 2
 
		OPEN cursor_options_modulos;
 
		FETCH NEXT FROM cursor_options_modulos INTO @code_modulo, @desc_modulo
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_MODULOS = ISNULL(@VOPTIONS_MODULOS,'') +
			'<option value="'+@code_modulo+'" '+CASE WHEN isnull(@VF_MODULO,'') = @code_modulo THEN 'selected="selected"' ELSE '' END+'>'+@desc_modulo+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_modulos INTO @code_modulo, @desc_modulo
		END;
 
		CLOSE cursor_options_modulos;
		DEALLOCATE cursor_options_modulos;
 
		SET @VOPTIONS_ACCIONES = '<option value="">Todas las acciones</option>'
 
		DECLARE @code_accion VARCHAR(50), @desc_accion varchar(300)
 
		DECLARE cursor_options_acciones CURSOR FOR
			SELECT	'ALTA', 'Alta'
			UNION
			SELECT	'MODIFICACION', 'Modificacion'
			UNION
			SELECT	'ASOCIAR', 'Asociar'
			UNION
			SELECT	'LOG IN', 'Log In'
			UNION
			SELECT	'LOG OFF', 'Log Off'
			ORDER BY 2
 
		OPEN cursor_options_acciones;
 
		FETCH NEXT FROM cursor_options_acciones INTO @code_accion, @desc_accion
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_ACCIONES = ISNULL(@VOPTIONS_ACCIONES,'') +
			'<option value="'+@code_accion+'" '+CASE WHEN isnull(@VF_ACCION,'') = @code_accion THEN 'selected="selected"' ELSE '' END+'>'+@desc_accion+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_acciones INTO @code_accion, @desc_accion
		END;
 
		CLOSE cursor_options_acciones;
		DEALLOCATE cursor_options_acciones;
 
		SET @VOPTIONS_USUARIOS = '<option value="">Todos los usuarios</option>'
 
		DECLARE @code_user VARCHAR(50), @desc_user varchar(300)
 
		DECLARE cursor_options_usuarios CURSOR FOR
			SELECT	Id,
					Name
			FROM	Users
			ORDER BY Name
 
		OPEN cursor_options_usuarios;
 
		FETCH NEXT FROM cursor_options_usuarios INTO @code_user, @desc_user
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_USUARIOS = ISNULL(@VOPTIONS_USUARIOS,'') +
			'<option value="'+@code_user+'" '+CASE WHEN isnull(@VF_USUARIO,'') = @code_user THEN 'selected="selected"' ELSE '' END+'>'+@desc_user+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_usuarios INTO @code_user, @desc_user
		END;
 
		CLOSE cursor_options_usuarios;
		DEALLOCATE cursor_options_usuarios;
 
	END
	-- fin reporte 1--
 
	--inicio reporte 2--
	IF (@Id_Reporte = '2') BEGIN
 
		SELECT	@VF_SECTOR		= ISNULL(REP_FILTRO3,''),
				@VF_USUARIO		= ISNULL(REP_FILTRO4,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
		SET @VOPTIONS_SECTORES = '<option value="">Todos los sectores</option>'
 
		DECLARE @code_sector VARCHAR(50), @desc_sector varchar(300)
 
		DECLARE cursor_options_sectores CURSOR FOR
			SELECT	CONVERT(VARCHAR,ID_SECTOR),
					DESC_SECTOR
			FROM	Sectores
			WHERE	ID_SECTOR NOT IN (29,30)
			ORDER BY DESC_SECTOR
 
		OPEN cursor_options_sectores;
 
		FETCH NEXT FROM cursor_options_sectores INTO @code_sector, @desc_sector
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_SECTORES = ISNULL(@VOPTIONS_SECTORES,'') +
			'<option value="'+@code_sector+'" '+CASE WHEN isnull(@VF_SECTOR,'') = @code_sector THEN 'selected="selected"' ELSE '' END+'>'+@desc_sector+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_sectores INTO @code_sector, @desc_sector
		END;
 
		CLOSE cursor_options_sectores;
		DEALLOCATE cursor_options_sectores;
 
		SET @VOPTIONS_USUARIOS = '<option value="">Todos los usuarios</option>'
 
		DECLARE @code_usuario VARCHAR(50), @desc_usuario varchar(300)
 
		DECLARE cursor_options_usuarios CURSOR FOR
			SELECT	Id,
					Name
			FROM	Users
			ORDER BY Name
 
		OPEN cursor_options_usuarios;
 
		FETCH NEXT FROM cursor_options_usuarios INTO @code_usuario, @desc_usuario
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_USUARIOS = ISNULL(@VOPTIONS_USUARIOS,'') +
			'<option value="'+@code_usuario+'" '+CASE WHEN isnull(@VF_USUARIO,'') = @code_usuario THEN 'selected="selected"' ELSE '' END+'>'+@desc_usuario+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_usuarios INTO @code_usuario, @desc_usuario
		END;
 
		CLOSE cursor_options_usuarios;
		DEALLOCATE cursor_options_usuarios;
 
	END
	-- fin reporte 2--
 
	--inicio reporte 3--
	IF (@Id_Reporte = '3') BEGIN
 
		SELECT	@VF_PERFIL		= ISNULL(REP_FILTRO5,''),
				@VF_PERMISO		= ISNULL(REP_FILTRO6,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
		SET @VOPTIONS_PERFILES = '<option value="">Todos los perfiles</option>'
 
		DECLARE @code_perfil VARCHAR(50), @desc_perfil varchar(300)
 
		DECLARE cursor_options_perfiles CURSOR FOR
			SELECT	ID, NAME
			FROM	Groups
			ORDER BY NAME
 
		OPEN cursor_options_perfiles;
 
		FETCH NEXT FROM cursor_options_perfiles INTO @code_perfil, @desc_perfil
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_PERFILES = ISNULL(@VOPTIONS_PERFILES,'') +
			'<option value="'+@code_perfil+'" '+CASE WHEN isnull(@VF_PERFIL,'') = @code_perfil THEN 'selected="selected"' ELSE '' END+'>'+@desc_perfil+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_perfiles INTO @code_perfil, @desc_perfil
		END;
 
		CLOSE cursor_options_perfiles;
		DEALLOCATE cursor_options_perfiles;
 
		SET @VOPTIONS_PERMISOS = '<option value="">Todos los permisos</option>'
 
		DECLARE @code_permiso VARCHAR(50), @desc_permiso varchar(300)
 
		DECLARE cursor_options_permisos CURSOR FOR
			SELECT	ID, NAME
			FROM	ACTIONS
			ORDER BY Name
 
		OPEN cursor_options_permisos;
 
		FETCH NEXT FROM cursor_options_permisos INTO @code_permiso, @desc_permiso
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
 
			SET @VOPTIONS_PERMISOS = ISNULL(@VOPTIONS_PERMISOS,'') +
			'<option value="'+@code_permiso+'" '+CASE WHEN isnull(@VF_PERMISO,'') = @code_permiso THEN 'selected="selected"' ELSE '' END+'>'+@desc_permiso+'</option>'
 
			-- Fetch the next row
			FETCH NEXT FROM cursor_options_permisos INTO @code_permiso, @desc_permiso
		END;
 
		CLOSE cursor_options_permisos;
		DEALLOCATE cursor_options_permisos;
 
	END
	-- fin reporte 3--
 
	/*armo el combo de reporte (nativo, estilo vct-select)*/
	IF (@Id_Reporte <> '') BEGIN
		SELECT	@Desc_Reporte = ISNULL(CAT_DATA_DESC,'')
		FROM	CAT_DATA
		WHERE	CAT_DATA_CODE = @Id_Reporte
		AND		PAR_KEY = '11352CCA-DABB-40C1-9D55-DDA0F228CB23'
	END
 
	DECLARE @code VARCHAR(50), @desc varchar(300), @option varchar(max)
 
	SET @VOPTIONS = ''
 
	DECLARE cursor_options CURSOR FOR
	SELECT	'<option value="'+CAT_DATA_CODE+'" '+CASE WHEN @Id_Reporte = CAT_DATA_CODE THEN 'selected="selected"' ELSE '' END+'>'+CAT_DATA_DESC+'</option>'
	FROM	CAT_DATA
	WHERE	PAR_KEY = '11352CCA-DABB-40C1-9D55-DDA0F228CB23'
	ORDER BY CAT_DATA_DESC
 
	OPEN cursor_options;
 
	FETCH NEXT FROM cursor_options INTO @option
 
	WHILE @@FETCH_STATUS = 0
	BEGIN
 
		SET @VOPTIONS = ISNULL(@VOPTIONS,'') + @option
 
		-- Fetch the next row
		FETCH NEXT FROM cursor_options INTO @option
	END;
 
	CLOSE cursor_options;
	DEALLOCATE cursor_options;
 
    -- Header estándar del módulo (mismo componente reutilizable que Usuarios/Menúes/Permisos)
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Reportes',
         @SUBTITLE            = 'Consulte los reportes de actividad y configuración del sistema',
         @MODULE_ICON         = 'pie-chart',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Resultados',
         @DEFAULT_TAB_ICON    = 'table',
         @DYNAMIC_TAB_ID      = '',
         @DYNAMIC_TAB_TITLE   = '',
         @DYNAMIC_TAB_ICON    = '',
         @SHOW_ACTION_BUTTON  = 0,
         @ACTION_BUTTON_TEXT  = '',
         @ACTION_BUTTON_ICON  = '',
         @ACTION_TARGET_TAB   = '',
         @ACTION_MODE         = '',
         @ACTION_ONCLICK      = '',
         @HTML                = @VHTML_HEADER OUTPUT;
 
    SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-module-header"', 'class="vct-module-header" style="position:relative;"');
 
    DECLARE @VBOTON_CIRCULAR VARCHAR(MAX) =
        '<button type="button" class="vct-circular-back-btn" onclick="goto(''' + @VFORM_ID_CLEAN + ''',''7D3F1524-6636-43C8-A690-25230419B312'');return false;" title="Volver">' +
            '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>' +
        '</button>';
 
    IF CHARINDEX('</div>', @VHTML_HEADER) > 0
    BEGIN
        SET @VHTML_HEADER = STUFF(@VHTML_HEADER, CHARINDEX('</div>', @VHTML_HEADER), 0, @VBOTON_CIRCULAR);
    END;
 
SET @PS_TITULO =
    CAST('<link rel="stylesheet" type="text/css" href="../css/vct-Table.css?v=18.0.0" />' AS VARCHAR(MAX)) +
    '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
    '<link rel="stylesheet" href="../css/vct-modal.css" />' +
    '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/flatpickr/4.6.13/flatpickr.min.css" />' +
    '<style>' +
        '.vct-module-heading { display:flex !important; align-items:center !important; gap:16px !important; }' +
        '.vct-module-icon { flex-shrink:0 !important; }' +
        '.vct-module-heading-text { display:flex !important; flex-direction:column !important; }' +
        '.vct-tabs-bar { display:none !important; }' +
 
        '.vct-circular-back-btn {' +
            'position:absolute !important;' +
            'top:50% !important;' +
            'transform:translateY(-50%) !important;' +
            'right:20px !important;' +
            'width:32px !important;' +
            'height:32px !important;' +
            'border-radius:50% !important;' +
            'background:#66062D !important;' +
            'border:1px solid rgba(255,255,255,.2) !important;' +
            'color:#ffffff !important;' +
            'display:inline-flex !important;' +
            'align-items:center !important;' +
            'justify-content:center !important;' +
            'cursor:pointer !important;' +
            'box-shadow:0 2px 5px rgba(0,0,0,.15) !important;' +
            'transition:all .2s ease !important;' +
            'z-index:100 !important;' +
        '}' +
        '.vct-circular-back-btn:hover { background:#4a0420 !important; transform:translateY(-50%) scale(1.05) !important; }' +
 
        '.vct-reportes-toolbar {' +
            'background:#ffffff !important;' +
            'display:flex !important;' +
            'align-items:center !important;' +
            'gap:12px !important;' +
            'padding:16px 20px !important;' +
            'margin:12px 0 0 0 !important;' +
            'box-sizing:border-box !important;' +
        '}' +
 
        '.vct-reportes-filters {' +
            'background:#ffffff !important;' +
            'display:flex !important;' +
            'align-items:flex-end !important;' +
            'flex-wrap:wrap !important;' +
            'gap:14px !important;' +
            'padding:0 20px 18px 20px !important;' +
            'box-sizing:border-box !important;' +
        '}' +
        '.vct-reportes-filters:empty { display:none !important; padding:0 !important; }' +
 
        /* flex-grow:1 con una base razonable: los campos que queden en la
           misma fila se reparten el espacio sobrante en vez de dejar
           huecos enormes en pantallas anchas o forzar 1 por línea en
           angostas. Cada variante solo cambia su "base" (basis), no si
           crece o no. */
        '.vct-field { display:flex !important; flex-direction:column !important; gap:6px !important; flex:1 1 200px !important; min-width:200px !important; max-width:none !important; }' +
        '.vct-field select, .vct-field input, .vct-field .vct-custom-select-wrapper, .vct-field .ts-wrapper { width:100% !important; }' +
        '.vct-reportes-filters .vct-field.vct-field-date { flex:1 1 160px !important; min-width:160px !important; }' +
        '.vct-reportes-filters .vct-field.vct-field-narrow { flex:1 1 200px !important; min-width:200px !important; }' +
        '.vct-reportes-filters .vct-field.vct-field-with-btn { flex:1 1 240px !important; min-width:240px !important; }' +
        '@media (max-width:640px){' +
            '.vct-reportes-filters .vct-field,' +
            '.vct-reportes-filters .vct-field.vct-field-date,' +
            '.vct-reportes-filters .vct-field.vct-field-narrow,' +
            '.vct-reportes-filters .vct-field.vct-field-with-btn,' +
            '.vct-reportes-toolbar .vct-field' +
            '{ flex:1 1 100% !important; max-width:100% !important; min-width:0 !important; }' +
            '.vct-reportes-toolbar,.vct-reportes-filters{ padding-left:14px !important; padding-right:14px !important; }' +
            '.vct-button-search{ width:100% !important; }' +
        '}' +
 
        '.flatpickr-calendar{background:#fff!important;border:1px solid #cbd5e1!important;border-radius:10px!important;box-shadow:0 12px 24px rgba(15,23,42,.14)!important;font-family:inherit!important;width:250px!important;font-size:12px!important;}' +
        '.flatpickr-calendar.arrowTop:before,.flatpickr-calendar.arrowTop:after{border-bottom-color:#cbd5e1!important;}' +
        '.flatpickr-months{padding:6px 6px 0 6px!important;}' +
        '.flatpickr-months .flatpickr-month{color:#0f172a!important;fill:#0f172a!important;height:28px!important;}' +
        '.flatpickr-current-month{font-size:12px!important;padding:0!important;}' +
        '.flatpickr-current-month .flatpickr-monthDropdown-months{font-weight:700!important;font-size:12px!important;}' +
        '.flatpickr-current-month input.cur-year{font-size:12px!important;}' +
        '.flatpickr-months .flatpickr-prev-month,.flatpickr-months .flatpickr-next-month{color:#66062D!important;fill:#66062D!important;top:6px!important;}' +
        '.flatpickr-months .flatpickr-prev-month:hover svg,.flatpickr-months .flatpickr-next-month:hover svg{fill:#66062D!important;}' +
        '.flatpickr-weekdays{background:#fff!important;height:22px!important;}' +
        'span.flatpickr-weekday{color:#64748b!important;font-weight:600!important;font-size:10px!important;line-height:22px!important;}' +
        '.flatpickr-days{width:250px!important;}' +
        '.dayContainer{width:250px!important;min-width:250px!important;max-width:250px!important;}' +
        '.flatpickr-day{border-radius:6px!important;font-weight:500!important;height:28px!important;line-height:28px!important;max-width:28px!important;font-size:11px!important;}' +
        '.flatpickr-day.selected,.flatpickr-day.selected:hover{background:#66062D!important;border-color:#66062D!important;color:#fff!important;}' +
        '.flatpickr-day.today{border-color:#66062D!important;}' +
        '.flatpickr-day:hover{background:#fdf2f6!important;}' +
        '.flatpickr-day.inRange{background:#fdf2f6!important;border-color:#fdf2f6!important;box-shadow:-5px 0 0 #fdf2f6,5px 0 0 #fdf2f6!important;}' +
        '.flatpickr-day.flatpickr-disabled{color:#cbd5e1!important;}' +
        '.flatpickr-time input:hover,.flatpickr-time .flatpickr-am-pm:hover{background:#fdf2f6!important;}' +
        '.vct-field label {' +
            'font-size:12px !important;' +
            'font-weight:600 !important;' +
            'color:#475569 !important;' +
            'display:flex !important;' +
            'align-items:center !important;' +
            'gap:6px !important;' +
        '}' +
 
        '.vct-select-input, .vct-date-input {' +
            'height:38px !important;' +
            'padding:0 12px !important;' +
            'font-size:13px !important;' +
            'font-weight:600 !important;' +
            'color:#0f172a !important;' +
            'background-color:#ffffff !important;' +
            'border:1px solid #cbd5e1 !important;' +
            'border-radius:8px !important;' +
            'width:100% !important;' +
            'box-sizing:border-box !important;' +
        '}' +
 
        '.vct-select-reporte { font-weight:700 !important; color:#66062D !important; }' +
        '.vct-reportes-toolbar { flex-direction:column !important; align-items:stretch !important; }' +
        /* OJO: .vct-reportes-toolbar tiene flex-direction:column (para que el
           campo Reporte se apile solo), así que acá el flex-basis controla el
           ALTO, no el ancho -- por eso el ancho se fija con width, no con la
           forma corta "flex: 0 1 320px" (que dejaba el campo de 320px de alto). */
        '.vct-reportes-toolbar .vct-field { flex:0 0 auto !important; width:320px !important; max-width:320px !important; min-width:240px !important; }' +
 
        '.vct-button-search {' +
            'height:38px !important;' +
            'width:38px !important;' +
            'flex-shrink:0 !important;' +
            'display:inline-flex !important;' +
            'align-items:center !important;' +
            'justify-content:center !important;' +
            'background:#66062D !important;' +
            'color:#ffffff !important;' +
            'border:none !important;' +
            'border-radius:8px !important;' +
            'cursor:pointer !important;' +
            'box-shadow:0 3px 10px rgba(102,6,45,.28) !important;' +
            'transition:background .2s ease !important;' +
        '}' +
        '.vct-button-search:hover { background:#4a0420 !important; }' +
 
        '.vct-reportes-results { padding:20px !important; box-sizing:border-box !important; }' +
        '.vct-reportes-results div[style*="justify-content:space-between"][style*="margin-top:15px"] { padding-top:15px !important; margin-top:15px !important; border-top:1px solid #f1f5f9 !important; }' +
 
        /* Una sola card blanca continua debajo del header (mismo ancho, sin
           salto ni sombra propia por sección): toolbar + filtros + resultados
           quedan unidos, con el borde inferior redondeado a juego con el
           header (que redondea arriba). */
        '.vct-reportes-card { background:#ffffff !important; margin:0 !important; border-radius:0 0 12px 12px !important; box-shadow:0 4px 12px rgba(15,23,42,.1) !important; overflow:hidden !important; }' +
        '.vct-reportes-card .vct-reportes-toolbar { margin-top:0 !important; }' +
        '.vct-reportes-card .vct-reportes-results { background:#ffffff !important; }' +
 
        '.vct-custom-select-wrapper{position:relative!important;width:100%!important;display:block!important;}' +
        '.vct-custom-select-trigger{width:100%!important;height:38px!important;min-height:38px!important;padding:0 12px!important;font-size:13px!important;font-weight:600!important;color:#0f172a!important;background:#fff!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 1px 2px rgba(0,0,0,.04)!important;display:flex!important;align-items:center!important;justify-content:space-between!important;cursor:pointer!important;text-align:left!important;}' +
        '.vct-custom-select-trigger:hover{border-color:#b7c4d7!important;}' +
        '.vct-custom-select-wrapper.is-open .vct-custom-select-trigger{border-color:#66062D!important;box-shadow:0 0 0 3px rgba(102,6,45,.12)!important;}' +
        '.vct-custom-select-trigger span{display:block!important;overflow:hidden!important;text-overflow:ellipsis!important;white-space:nowrap!important;}' +
        '.vct-custom-select-trigger i,.vct-custom-select-trigger svg{width:16px!important;height:16px!important;color:#66062D!important;stroke:#66062D!important;flex:0 0 auto!important;}' +
        '.vct-custom-select-options{display:none!important;position:absolute!important;top:calc(100% + 4px)!important;left:0!important;right:0!important;z-index:9999!important;margin:0!important;padding:4px!important;list-style:none!important;background:#fff!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 12px 24px rgba(15,23,42,.14)!important;max-height:220px!important;overflow:auto!important;}' +
        '.vct-custom-select-wrapper.is-open .vct-custom-select-options{display:block!important;}' +
        '.vct-custom-select-option{margin:0!important;padding:10px 12px!important;list-style:none!important;font-size:13px!important;font-weight:500!important;line-height:1.2!important;color:#0f172a!important;background:#fff!important;border-radius:6px!important;cursor:pointer!important;}' +
        '.vct-custom-select-option::marker{content:""!important;}' +
        '.vct-custom-select-option:hover,.vct-custom-select-option.is-selected{background:#66062D!important;color:#fff!important;}' +
 
        '#mainContainer .vct-grid-source table tr:has(.vct-perm-cell) td{vertical-align:top!important;}' +
        '#mainContainer .vct-grid-source table tr:has(.vct-perm-cell) td:first-child{width:25%!important;}' +
        '#mainContainer .vct-grid-source table tr:has(.vct-perm-cell) td:last-child{width:75%!important;}' +
        '#mainContainer .vct-grid-source:has(.vct-perm-cell) th:last-of-type{text-align:right!important;justify-content:flex-end!important;}' +
 
        '.vct-perm-cell{width:100%!important;box-sizing:border-box!important;padding:6px 0!important;text-align:right!important;}' +
 
        '.vct-perm-list{display:none!important;text-align:left!important;margin-top:12px!important;margin-left:auto!important;padding-top:12px!important;border-top:1px solid #f1f5f9!important;width:fit-content!important;max-width:100%!important;min-width:260px!important;}' +
        '.vct-perm-cell.is-open .vct-perm-list{display:block!important;}' +
 
        '.vct-perm-toggle-btn{display:inline-flex!important;align-items:center!important;gap:8px!important;height:30px!important;padding:0 14px 0 6px!important;font-size:12px!important;font-weight:700!important;color:#1f7a4d!important;background:#e6f4ec!important;border:1px solid transparent!important;border-radius:999px!important;cursor:pointer!important;white-space:nowrap!important;user-select:none!important;box-sizing:border-box!important;line-height:1!important;transition:background .15s ease,border-color .15s ease!important;}' +
        '.vct-perm-toggle-btn:hover{background:#d9eee2!important;}' +
        '.vct-perm-toggle-btn:focus{outline:none!important;box-shadow:0 0 0 3px rgba(31,122,77,.18)!important;}' +
        '.vct-perm-toggle-btn:focus:not(:focus-visible){box-shadow:none!important;}' +
        '.vct-perm-cell.is-open .vct-perm-toggle-btn{background:#1f7a4d!important;color:#fff!important;}' +
        '.vct-perm-count-pill{display:inline-flex!important;align-items:center!important;justify-content:center!important;min-width:20px!important;height:20px!important;padding:0 6px!important;font-size:11px!important;font-weight:800!important;color:#fff!important;background:#1f7a4d!important;border-radius:999px!important;flex-shrink:0!important;}' +
        '.vct-perm-cell.is-open .vct-perm-count-pill{background:rgba(255,255,255,.25)!important;}' +
        '.vct-perm-toggle-label-hide{display:none!important;}' +
        '.vct-perm-cell.is-open .vct-perm-toggle-label-show{display:none!important;}' +
        '.vct-perm-cell.is-open .vct-perm-toggle-label-hide{display:inline!important;}' +
        '.vct-perm-caret{transition:transform .2s ease!important;flex-shrink:0!important;}' +
        '.vct-perm-cell.is-open .vct-perm-caret{transform:rotate(180deg)!important;}' +
 
        '.vct-perm-row{padding:9px 14px 9px 12px!important;margin-bottom:6px!important;font-size:13px!important;font-weight:500!important;color:#334155!important;background:#f8fafc!important;border-right:3px solid #bfe3cf!important;border-radius:6px 0 0 6px!important;text-align:right!important;transition:background .15s ease!important;}' +
        '.vct-perm-row:hover{background:#eef2f5!important;}' +
        '.vct-perm-row:last-child{margin-bottom:0!important;}' +
        '.vct-perm-row.vct-perm-empty{font-style:italic!important;font-weight:400!important;color:#94a3b8!important;background:transparent!important;border-right-color:#e2e8f0!important;}' +
 
        /* Badges reutilizados en los reportes: mismo estilo (píldora chica
           con borde) que ya se usa en Sectores/Usuarios, para que todo
           el sistema se vea consistente. */
        '.vct-status-badge{display:inline-flex!important;align-items:center!important;gap:6px!important;padding:4px 8px!important;border-radius:999px!important;font-size:10.5px!important;font-weight:700!important;line-height:1!important;white-space:nowrap!important;}' +
        '.vct-status-badge .vct-status-dot{width:6px!important;height:6px!important;border-radius:50%!important;flex-shrink:0!important;background:currentColor!important;}' +
        '.vct-status-active{background:#ECFDF3!important;color:#166534!important;border:1px solid #BBF7D0!important;}' +
        '.vct-status-inactive{background:#F8FAFC!important;color:#64748b!important;border:1px solid #E2E8F0!important;}' +
 
        '.vct-level-badge{display:inline-flex!important;align-items:center!important;padding:4px 10px!important;border-radius:999px!important;font-size:10.5px!important;font-weight:700!important;line-height:1!important;white-space:nowrap!important;}' +
        '.vct-level-1{background:#FDF2F8!important;color:#66062D!important;border:1px solid #F3D2E1!important;}' +
        '.vct-level-2{background:#EFF6FF!important;color:#1D4ED8!important;border:1px solid #BFDBFE!important;}' +
        '.vct-level-3{background:#F8FAFC!important;color:#475569!important;border:1px solid #E2E8F0!important;}' +
 
        '.vct-action-badge{display:inline-flex!important;align-items:center!important;padding:4px 10px!important;border-radius:999px!important;font-size:10.5px!important;font-weight:700!important;line-height:1!important;white-space:nowrap!important;text-transform:capitalize!important;}' +
        '.vct-action-positive{background:#ECFDF3!important;color:#166534!important;border:1px solid #BBF7D0!important;}' +
        '.vct-action-negative{background:#FEF2F2!important;color:#B91C1C!important;border:1px solid #FECACA!important;}' +
        '.vct-action-neutral{background:#EFF6FF!important;color:#1D4ED8!important;border:1px solid #BFDBFE!important;}' +
        '.vct-action-muted{background:#F8FAFC!important;color:#64748b!important;border:1px solid #E2E8F0!important;}' +
    '</style>' +
 
    @VHTML_HEADER +
 
    '<div class="vct-reportes-card">' +
 
    '<div class="vct-reportes-toolbar">' +
        '<div class="vct-field">' +
            '<label>Reporte</label>' +
            '<select class="vct-select-input vct-select-custom vct-select-reporte" onchange="almacenarSeleccion(''ID_TASK_SEL'', this.value); goto(''' + @VFORM_ID_CLEAN + ''',''7D3F1524-6636-43C8-A690-25230419B312'');">' +
                ISNULL(@VOPTIONS,'') +
            '</select>' +
        '</div>' +
    '</div>' +
 
    '<div class="vct-reportes-filters">' +
        CASE WHEN @Id_Reporte = '1' THEN
        '<div class="vct-field vct-field-date">' +
            '<label><i data-lucide="calendar" style="width:13px;height:13px;"></i>Fecha Desde</label>' +
            '<input class="vct-date-input vct-flatpickr" type="text" autocomplete="off" name="SP.REP_FECHA_DESDE" value="'+CASE WHEN ISNULL(@VFECHA_DESDE,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_DESDE,23),'') END +'">' +
        '</div>' +
        '<div class="vct-field vct-field-date">' +
            '<label><i data-lucide="calendar" style="width:13px;height:13px;"></i>Fecha Hasta</label>' +
            '<input class="vct-date-input vct-flatpickr" type="text" autocomplete="off" name="SP.REP_FECHA_HASTA" value="'+CASE WHEN ISNULL(@VFECHA_HASTA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_HASTA,23),'') END +'">' +
        '</div>' +
        '<div class="vct-field vct-field-narrow">' +
            '<label><i data-lucide="boxes" style="width:13px;height:13px;"></i>Módulo</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO1">' + ISNULL(@VOPTIONS_MODULOS,'') + '</select>' +
        '</div>' +
        '<div class="vct-field vct-field-narrow">' +
            '<label><i data-lucide="settings-2" style="width:13px;height:13px;"></i>Acción</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO2">' + ISNULL(@VOPTIONS_ACCIONES,'') + '</select>' +
        '</div>' +
        '<div class="vct-field">' +
            '<label><i data-lucide="user" style="width:13px;height:13px;"></i>Usuario</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO4">' + ISNULL(@VOPTIONS_USUARIOS,'') + '</select>' +
        '</div>' +
        '<button type="button" class="vct-button-search" title="Buscar" onclick="goto('''+@VFORM_ID_CLEAN+''',''7D3F1524-6636-43C8-A690-25230419B312'');return false;"><i data-lucide="search" style="width:16px;height:16px;"></i></button>'
        WHEN @Id_Reporte = '2' THEN
        '<div class="vct-field vct-field-with-btn">' +
            '<label><i data-lucide="user" style="width:13px;height:13px;"></i>Usuario</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO4">' + ISNULL(@VOPTIONS_USUARIOS,'') + '</select>' +
        '</div>' +
        '<div class="vct-field vct-field-with-btn">' +
            '<label><i data-lucide="git-branch" style="width:13px;height:13px;"></i>Sector</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO3">' + ISNULL(@VOPTIONS_SECTORES,'') + '</select>' +
        '</div>' +
        '<button type="button" class="vct-button-search" title="Buscar" onclick="goto('''+@VFORM_ID_CLEAN+''',''7D3F1524-6636-43C8-A690-25230419B312'');return false;"><i data-lucide="search" style="width:16px;height:16px;"></i></button>'
        WHEN @Id_Reporte = '3' THEN
        '<div class="vct-field vct-field-with-btn">' +
            '<label><i data-lucide="users" style="width:13px;height:13px;"></i>Perfil</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO5">' + ISNULL(@VOPTIONS_PERFILES,'') + '</select>' +
        '</div>' +
        '<div class="vct-field vct-field-with-btn">' +
            '<label><i data-lucide="shield-check" style="width:13px;height:13px;"></i>Permiso</label>' +
            '<select class="vct-select-input vct-select-custom" name="SP.REP_FILTRO6">' + ISNULL(@VOPTIONS_PERMISOS,'') + '</select>' +
        '</div>' +
        '<button type="button" class="vct-button-search" title="Buscar" onclick="goto('''+@VFORM_ID_CLEAN+''',''7D3F1524-6636-43C8-A690-25230419B312'');return false;"><i data-lucide="search" style="width:16px;height:16px;"></i></button>'
        ELSE ''
        END +
    '</div>' +
 
    '<div class="vct-reportes-results">' +
        '<div class="vct-table-wrapper">';
 
SET @PS_FORMULARIO =
        CAST('</div>' AS VARCHAR(MAX)) +
    '</div>' +
    '</div>' +
 
    '<script src="../js/vct-Core.js?v=20260916-3"></script>' +
    '<script src="../js/vct-Tabs.js?v=20260916-3"></script>' +
    '<script src="../js/vct-Table.js?v=20260916-3"></script>' +
    '<script src="../js/vct-modal.js?v=20260916-3"></script>' +
    '<script src="../js/vct-Select.js?v=20260916-3"></script>' +
    '<script src="https://cdnjs.cloudflare.com/ajax/libs/flatpickr/4.6.13/flatpickr.min.js"></script>' +
    '<script src="https://cdnjs.cloudflare.com/ajax/libs/flatpickr/4.6.13/l10n/es.js"></script>' +
 
    '<script>' +
    '(function(){' +
    'function run(){' +
    'if(window.initVctCustomSelects){window.initVctCustomSelects(document.querySelector(".vct-reportes-toolbar")||document);window.initVctCustomSelects(document.querySelector(".vct-reportes-filters")||document);}' +
    'if(window.lucide&&typeof window.lucide.createIcons==="function"){window.lucide.createIcons();}' +
    'document.querySelectorAll(".flatpickr-calendar").forEach(function(cal){' +
        'var mc=document.getElementById("mainContainer");' +
        'if(!mc||!mc.contains(cal)){cal.parentNode&&cal.parentNode.removeChild(cal);}' +
    '});' +
    'if(window.flatpickr){' +
        'document.querySelectorAll(".vct-flatpickr").forEach(function(el){' +
            'if(el._flatpickr) return;' +
            'window.flatpickr(el,{' +
                'dateFormat:"Y-m-d",' +
                'altInput:true,' +
                'altInputClass:"vct-date-input vct-flatpickr-alt",' +
                'altFormat:"d/m/Y",' +
                'locale:(window.flatpickr.l10ns&&window.flatpickr.l10ns.es)||"default",' +
                'allowInput:true,' +
                'appendTo:el.closest(".vct-field")||el.parentNode' +
            '});' +
        '});' +
    '}' +
    '}' +
    'if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",run);}else{run();}' +
    'setTimeout(run,100);' +
    'setTimeout(run,400);' +
    'setTimeout(run,800);' +
    '})();' +
    '</script>';
 
END
