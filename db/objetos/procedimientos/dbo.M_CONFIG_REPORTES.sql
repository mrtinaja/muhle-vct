CREATE   PROCEDURE [dbo].[M_CONFIG_REPORTES]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID AS VARCHAR(100))
AS
 
BEGIN
    SET NOCOUNT ON;
 
	DECLARE @ID_REPORTE		VARCHAR(50),
			@VFECHA_DESDE	DATETIME,
			@VFECHA_HASTA	DATETIME,
			@VF_MODULO		VARCHAR(50),
			@VF_ACCION		VARCHAR(50),
			@VF_SECTOR		VARCHAR(50),
			@VF_USUARIO		VARCHAR(50),
			@VF_PERFIL		VARCHAR(50),
			@VF_PERMISO		VARCHAR(50)
 
	SELECT	@ID_REPORTE = ISNULL(ID_TASK_SEL,'')
	FROM	M_CONFIG
	WHERE	PAR_KEY = @IPKEYJOB
 
	-- Sin reporte seleccionado
	IF (@ID_REPORTE = '') BEGIN
		SELECT '<div class="w3-center w3-muhle-text-12">Debe Seleccionar un Reporte</div>'		AS '<div class="w3-center w3-muhle-text-12">Mensaje</div>'
		RETURN;
	END
 
	-- Reporte 1: Actividad (Auditoria) sobre M_AUDITORIA_ADMIN
	IF (@ID_REPORTE = '1') BEGIN
 
		SELECT	@VFECHA_DESDE	= ISNULL(REP_FECHA_DESDE,''),
				@VFECHA_HASTA	= ISNULL(REP_FECHA_HASTA,''),
				@VF_MODULO		= ISNULL(REP_FILTRO1,''),
				@VF_ACCION		= ISNULL(REP_FILTRO2,''),
				@VF_USUARIO		= ISNULL(REP_FILTRO4,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
		IF OBJECT_ID('tempdb..#TmpReporte1') IS NOT NULL
			DROP TABLE #TmpReporte1;
 
		SELECT
			[Fecha]              = ISNULL(CONVERT(VARCHAR, aud.Fecha, 120), ''),
			[Modulo]             = ISNULL(aud.Modulo, ''),
			[Accion]             = '<span class="vct-action-badge ' +
			                          CASE UPPER(ISNULL(aud.Accion,''))
			                              WHEN 'ALTA' THEN 'vct-action-positive'
			                              WHEN 'ASOCIAR' THEN 'vct-action-positive'
			                              WHEN 'LOG IN' THEN 'vct-action-positive'
			                              WHEN 'DESASOCIAR' THEN 'vct-action-negative'
			                              WHEN 'BAJA' THEN 'vct-action-negative'
			                              WHEN 'MODIFICACION' THEN 'vct-action-neutral'
			                              WHEN 'LOG OFF' THEN 'vct-action-muted'
			                              ELSE 'vct-action-neutral'
			                          END + '">' + ISNULL(aud.Accion, '') + '</span>',
			[Usuario Modif]   = ISNULL(aud.UsuarioId, ''),
			[Registro]		   = ISNULL(aud.RegistroAfectado, ''),
			Detalle            = ISNULL(aud.Detalle, '')
		INTO #TmpReporte1
		FROM	dbo.M_AUDITORIA_ADMIN aud WITH (NOLOCK)
		WHERE	(@VFECHA_DESDE IS NULL OR CONVERT(DATE, aud.Fecha) >= CONVERT(DATE, @VFECHA_DESDE))
		AND		(@VFECHA_HASTA IS NULL OR CONVERT(DATE, aud.Fecha) <= CONVERT(DATE, @VFECHA_HASTA))
		AND		(ISNULL(@VF_MODULO,'')  = '' OR aud.Modulo = @VF_MODULO)
		AND		(ISNULL(@VF_ACCION,'')  = '' OR aud.Accion = @VF_ACCION)
		AND		(ISNULL(@VF_USUARIO,'') = '' OR aud.UsuarioId = @VF_USUARIO)
		ORDER BY aud.Fecha DESC;
 
		EXEC dbo.vct_RenderGrid
		     @TempTableName = '#TmpReporte1',
		     @FormId        = @FORM_ID,
		     @ActionsJson   = '[]',
		     @PageSize      = 10,
		     @HiddenColumns = '',
		     @HtmlColumns   = 'Accion',
		     @ScriptVersion = '16.1.0';
 
		IF OBJECT_ID('tempdb..#TmpReporte1') IS NOT NULL
			DROP TABLE #TmpReporte1;
 
		RETURN;
	END
 
	-- Reporte 2: Usuarios x Sector
	IF (@ID_REPORTE = '2') BEGIN
 
		SELECT	@VF_SECTOR = ISNULL(REP_FILTRO3,''),
				@VF_USUARIO = ISNULL(REP_FILTRO4,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
		IF OBJECT_ID('tempdb..#TmpReporte2') IS NOT NULL
			DROP TABLE #TmpReporte2;
 
		SELECT
			Usuario                = ISNULL(u.Id, ''),
			[Apellido y Nombre]    = ISNULL(u.Name, ''),
			Email                  = ISNULL(u.Email, ''),
			Estado                 = CASE WHEN u.State = 1
			                              THEN '<span class="vct-status-badge vct-status-active"><span class="vct-status-dot"></span>' + ISNULL(cd.cat_data_desc,'Activa') + '</span>'
			                              ELSE '<span class="vct-status-badge vct-status-inactive"><span class="vct-status-dot"></span>' + ISNULL(cd.cat_data_desc,'No Activa') + '</span>'
			                          END
		INTO #TmpReporte2
		FROM	UsersSector US
				INNER JOIN Users U ON us.Id_User = u.Id
				LEFT OUTER JOIN cat_data cd ON CONVERT(VARCHAR, u.State) = cd.ATTR1 AND cd.PAR_KEY = '3ECEABE3-13FD-4779-ADE7-CDECF2EC3992'
		WHERE	1 = 1
		AND		Id_User = CASE WHEN ISNULL(@VF_USUARIO,'') = '' THEN CONVERT(VARCHAR,US.Id_User) ELSE ISNULL(@VF_USUARIO,'') END
		AND		CONVERT(VARCHAR,US.ID_SECTOR) = CASE WHEN ISNULL(@VF_SECTOR,'') = '' THEN CONVERT(VARCHAR,US.ID_SECTOR) ELSE ISNULL(@VF_SECTOR,'') END
		ORDER BY 1;
 
		EXEC dbo.vct_RenderGrid
		     @TempTableName = '#TmpReporte2',
		     @FormId        = @FORM_ID,
		     @ActionsJson   = '[]',
		     @PageSize      = 10,
		     @HiddenColumns = '',
		     @HtmlColumns   = 'Estado',
		     @ScriptVersion = '16.2.0';
 
		IF OBJECT_ID('tempdb..#TmpReporte2') IS NOT NULL
			DROP TABLE #TmpReporte2;
 
		RETURN;
	END
 
	-- Reporte 3: Permisos por Perfil
	IF (@ID_REPORTE = '3') BEGIN
 
		SELECT	@VF_PERFIL = ISNULL(REP_FILTRO5,''),
				@VF_PERMISO = ISNULL(REP_FILTRO6,'')
		FROM	M_CONFIG
		WHERE	PAR_KEY = @IPKEYJOB
 
		IF OBJECT_ID('tempdb..#TmpReporte3') IS NOT NULL
			DROP TABLE #TmpReporte3;
 
		CREATE TABLE #TmpReporte3 (Perfil VARCHAR(300), Permisos VARCHAR(MAX));
 
		DECLARE @VGID		VARCHAR(100),
				@VGNAME		VARCHAR(300),
				@VPID		VARCHAR(100),
				@VPNAME		VARCHAR(300),
				@VROWS		VARCHAR(MAX),
				@VPCOUNT	INT,
				@VCELL		VARCHAR(MAX)
 
		DECLARE cursor_perfiles_rep3 CURSOR LOCAL FOR
			SELECT	g.Id, ISNULL(g.Name,'')
			FROM	Groups g
			WHERE	(ISNULL(@VF_PERFIL,'') = '' OR g.Id = @VF_PERFIL)
			AND		EXISTS (
						SELECT 1 FROM GroupsActions ga
						WHERE ga.GroupId = g.Id
						AND (ISNULL(@VF_PERMISO,'') = '' OR ga.ActionId = @VF_PERMISO)
					)
			ORDER BY g.Name
 
		OPEN cursor_perfiles_rep3;
		FETCH NEXT FROM cursor_perfiles_rep3 INTO @VGID, @VGNAME
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @VROWS = ''
			SET @VPCOUNT = 0
 
			DECLARE cursor_permisos_rep3 CURSOR LOCAL FOR
				SELECT	a.Id, ISNULL(a.Name,'')
				FROM	GroupsActions ga
						LEFT OUTER JOIN Actions a ON ga.ActionId = a.Id
				WHERE	ga.GroupId = @VGID
				AND		(ISNULL(@VF_PERMISO,'') = '' OR ga.ActionId = @VF_PERMISO)
				ORDER BY a.Name
 
			OPEN cursor_permisos_rep3;
			FETCH NEXT FROM cursor_permisos_rep3 INTO @VPID, @VPNAME
 
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @VROWS = ISNULL(@VROWS,'') + '<div class="vct-perm-row">' + @VPNAME + '</div>'
				SET @VPCOUNT = @VPCOUNT + 1
				FETCH NEXT FROM cursor_permisos_rep3 INTO @VPID, @VPNAME
			END;
 
			CLOSE cursor_permisos_rep3;
			DEALLOCATE cursor_permisos_rep3;
 
			SET @VCELL =
				'<div class="vct-perm-cell">' +
					'<span role="button" tabindex="0" class="vct-perm-toggle-btn" onclick="this.closest(''.vct-perm-cell'').classList.toggle(''is-open'');">' +
						'<span class="vct-perm-count-pill">' + CONVERT(VARCHAR,@VPCOUNT) + '</span>' +
						'<span class="vct-perm-toggle-label-show">Ver todos</span>' +
						'<span class="vct-perm-toggle-label-hide">Ocultar</span>' +
						'<svg class="vct-perm-caret" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>' +
					'</span>' +
					'<div class="vct-perm-list">' + ISNULL(NULLIF(@VROWS,''),'<div class="vct-perm-row vct-perm-empty">Sin permisos asignados.</div>') + '</div>' +
				'</div>'
 
			INSERT INTO #TmpReporte3 (Perfil, Permisos) VALUES (@VGNAME, @VCELL)
 
			FETCH NEXT FROM cursor_perfiles_rep3 INTO @VGID, @VGNAME
		END;
 
		CLOSE cursor_perfiles_rep3;
		DEALLOCATE cursor_perfiles_rep3;
 
		EXEC dbo.vct_RenderGrid
		     @TempTableName = '#TmpReporte3',
		     @FormId        = @FORM_ID,
		     @ActionsJson   = '[]',
		     @PageSize      = 10,
		     @HiddenColumns = '',
		     @HtmlColumns   = 'Permisos',
		     @ScriptVersion = '16.0.0';
 
		IF OBJECT_ID('tempdb..#TmpReporte3') IS NOT NULL
			DROP TABLE #TmpReporte3;
 
		RETURN;
	END
 
	-- Reporte 4: Estructura de Sectores
	IF (@ID_REPORTE = '4') BEGIN
 
		IF OBJECT_ID('tempdb..#TmpReporte4') IS NOT NULL
			DROP TABLE #TmpReporte4;
 
			SELECT	[Perfil]    = ISNULL(Name, ''),
					[Email]     = ISNULL(Email, ''),
					[Nivel]     = '<span class="vct-level-badge vct-level-1">Nivel 1</span>'
			INTO	#TmpReporte4
			FROM	Groups g
			WHERE	ID = 'GERENCIA'
			UNION ALL
			SELECT	[Perfil]    = ISNULL(Name, ''),
					[Email]     = ISNULL(Email, ''),
					[Nivel]     = '<span class="vct-level-badge vct-level-2">Nivel 2</span>'
			FROM	Groups g
			WHERE	ID <> 'GERENCIA'
			AND		ID <> 'SQUAD'
			ORDER BY 3,1 ;
 
		EXEC dbo.vct_RenderGrid
		     @TempTableName = '#TmpReporte4',
		     @FormId        = @FORM_ID,
		     @ActionsJson   = '[]',
		     @PageSize      = 10,
		     @HiddenColumns = '',
		     @HtmlColumns   = 'Nivel',
		     @ScriptVersion = '16.1.0';
 
		IF OBJECT_ID('tempdb..#TmpReporte4') IS NOT NULL
			DROP TABLE #TmpReporte4;
 
		RETURN;
	END
END
