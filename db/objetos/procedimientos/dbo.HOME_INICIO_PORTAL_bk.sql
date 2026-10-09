 
CREATE PROCEDURE [dbo].[HOME_INICIO_PORTAL_bk]
(
    @IPKEYJOB   AS VARCHAR(100),
    @FORM_ID    AS VARCHAR(100),
    @IUNIDAD    AS VARCHAR(100),
    @IAGENTE    AS VARCHAR(100),
    @OMENU      AS VARCHAR(MAX) OUTPUT,
    @OTABS      AS VARCHAR(MAX) OUTPUT,
    @OPAGINA    AS VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- ==========================================
    -- DEFINICIÓN DE ÍCONOS VECTORIALES (LUCIDE SVG)
    -- ==========================================
    DECLARE @SVG_TH_LARGE    NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>';
    DECLARE @SVG_HOME        NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>';
    DECLARE @SVG_SEARCH      NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>';
    DECLARE @SVG_TIMES       NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>';
    
    DECLARE @SVG_PLUS        NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/></svg>';
    DECLARE @SVG_PLUS_WHITE  NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>';
    DECLARE @SVG_MENU        NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#66062D" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/></svg>';
    DECLARE @SVG_EDIT        NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>';
    DECLARE @SVG_CALENDAR    NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>';
    DECLARE @SVG_CLIPBOARD   NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/></svg>';
    DECLARE @SVG_BOOK        NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#66062D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></svg>';
    DECLARE @SVG_STREET_VIEW NVARCHAR(MAX) = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="10" r="3"/><path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662"/></svg>';
    DECLARE @IMG_HEADER_LOGO NVARCHAR(MAX) = '<img src="../img/Vfondo Bordo.png" alt="Logo Vocaturo" style="width: 54px; height: 54px; object-fit: contain; display: block;" />';
 
    DECLARE
        @TOTAL_PROYECTOS            INT,
        @TOTAL_TERMINADOS           INT,
        @TOTAL_EN_CURSO             INT,
        @TOTAL_HORAS_PROY           INT,
        @TOTAL_HORAS_EJEC           INT,
        @TOTAL_HORAS_PEND           INT,
        @TOTAL_CLIENTES				INT,
        @TOTAL_CONSULTORES			INT,
        @TOTAL_MONTO				INT,
        @JSON_ESTADOS               NVARCHAR(MAX),
        @JSON_SERVICIOS             NVARCHAR(MAX),
        @HTML_TABLA_PLANIFICA       VARCHAR(MAX),
        @HTML_TABLA_PROYECTOS       VARCHAR(MAX),
        @HTML_PAGINADOR             VARCHAR(MAX),
        @HTML_SIDEBAR               VARCHAR(MAX) = '',
        @VNRO_PAGINA                INT,
        @V_PAGE_SIZE                INT,
        @V_PAGE_SIZE_RAW            VARCHAR(50),
        @V_OFFSET                   INT,
        @VTOTAL_PLANIFICA           INT,
        @VTOTAL_PAGINAS             INT,
        @VPAGINA_ACTUAL             INT,
        @VPAGINA_DESDE              INT,
        @VPAGINA_HASTA              INT,
        @VPAGINA_PREV               INT,
        @VPAGINA_NEXT               INT,
        @VBUSCA_CASO                VARCHAR(300),
        @VBUSCA_HTML                VARCHAR(300),
        @VFECHA_DESDE_TXT           VARCHAR(50),
        @VFECHA_HASTA_TXT           VARCHAR(50),
        @VFECHA_DESDE               DATETIME,
        @VFECHA_HASTA               DATETIME,
        @VFECHA_DESDE_HTML          VARCHAR(30),
        @VFECHA_HASTA_HTML          VARCHAR(30),
        @V_MODO_LIVIANO             INT,
        @V_SOLAPA                   VARCHAR(50);
 
    -- BLINDAJE ANTI-FALLO EN LA OBTENCIÓN DEL SIDEBAR
    BEGIN TRY
        EXEC [dbo].[HOME_GET_SIDEBAR]
            @IUNIDAD  = @IUNIDAD,
            @IAGENTE  = @IAGENTE,
            @FORM_ID  = @FORM_ID,
            @OSIDEBAR = @HTML_SIDEBAR OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SIDEBAR = '';
    END CATCH
 
    SET @VNRO_PAGINA = 0;
    SET @V_PAGE_SIZE = 25;
    SET @V_PAGE_SIZE_RAW = '25';
    SET @VBUSCA_CASO = '';
    SET @VFECHA_DESDE_TXT = '';
    SET @VFECHA_HASTA_TXT = '';
    SET @VFECHA_DESDE = NULL;
    SET @VFECHA_HASTA = NULL;
    SET @VFECHA_DESDE_HTML = '';
    SET @VFECHA_HASTA_HTML = '';
 
    SELECT
        @VNRO_PAGINA = CONVERT(INT, ISNULL(NRO_PAGINA, 0)),
        @V_PAGE_SIZE_RAW = ISNULL(BUFFER, '25'),
        @VBUSCA_CASO = ISNULL(FILTRO, ''),
        @VFECHA_DESDE_TXT = CASE WHEN FECHA_DESDE IS NULL THEN '' ELSE CONVERT(VARCHAR(10), FECHA_DESDE, 23) END,
        @VFECHA_HASTA_TXT = CASE WHEN FECHA_HASTA IS NULL THEN '' ELSE CONVERT(VARCHAR(10), FECHA_HASTA, 23) END,
        @V_SOLAPA = ISNULL(SOLAPA, '')
    FROM XAGENDA WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
	IF (@VFECHA_DESDE_TXT = '') BEGIN
		SELECT	@VFECHA_DESDE = CAST(Convert(CHAR(8),GETDATE() - 5,112) as DATETIME),
				@VFECHA_HASTA = CAST(Convert(CHAR(8),GETDATE() + 3,112) as DATETIME)
		FROM	Calendar 
		WHERE	Fecha = convert(varchar,GETDATE(),113)
 
		UPDATE	XAGENDA 
		SET		FECHA_DESDE = @VFECHA_DESDE, 
				FECHA_HASTA = @VFECHA_HASTA
		WHERE	PAR_KEY = @IPKEYJOB
 
		SELECT
			@VFECHA_DESDE_TXT = CASE WHEN FECHA_DESDE IS NULL THEN '' ELSE CONVERT(VARCHAR(10), FECHA_DESDE, 23) END,
			@VFECHA_HASTA_TXT = CASE WHEN FECHA_HASTA IS NULL THEN '' ELSE CONVERT(VARCHAR(10), FECHA_HASTA, 23) END
		FROM XAGENDA WITH (NOLOCK)
		WHERE PAR_KEY = @IPKEYJOB;
	END
 
    IF (@V_SOLAPA = '') BEGIN
        SET @V_SOLAPA= 'PLAN';
    END
 
    SET @VNRO_PAGINA = ISNULL(@VNRO_PAGINA, 0);
    SET @V_PAGE_SIZE_RAW = LTRIM(RTRIM(ISNULL(@V_PAGE_SIZE_RAW, '25')));
    SET @VBUSCA_CASO = LTRIM(RTRIM(ISNULL(@VBUSCA_CASO, '')));
    SET @VFECHA_DESDE_TXT = LTRIM(RTRIM(ISNULL(@VFECHA_DESDE_TXT, '')));
    SET @VFECHA_HASTA_TXT = LTRIM(RTRIM(ISNULL(@VFECHA_HASTA_TXT, '')));
 
    IF LEN(@VFECHA_DESDE_TXT) = 10 AND SUBSTRING(@VFECHA_DESDE_TXT, 5, 1) = '-' AND SUBSTRING(@VFECHA_DESDE_TXT, 8, 1) = '-' AND ISDATE(REPLACE(@VFECHA_DESDE_TXT, '-', '')) = 1
        SET @VFECHA_DESDE = CONVERT(DATETIME, REPLACE(@VFECHA_DESDE_TXT, '-', ''), 112);
 
    IF LEN(@VFECHA_HASTA_TXT) = 10 AND SUBSTRING(@VFECHA_HASTA_TXT, 5, 1) = '-' AND SUBSTRING(@VFECHA_HASTA_TXT, 8, 1) = '-' AND ISDATE(REPLACE(@VFECHA_HASTA_TXT, '-', '')) = 1
        SET @VFECHA_HASTA = CONVERT(DATETIME, REPLACE(@VFECHA_HASTA_TXT, '-', ''), 112);
 
    IF @VFECHA_DESDE = CONVERT(DATETIME, '19000101', 112) SET @VFECHA_DESDE = NULL;
    IF @VFECHA_HASTA = CONVERT(DATETIME, '19000101', 112) SET @VFECHA_HASTA = NULL;
 
    SET @VBUSCA_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@VBUSCA_CASO, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
 
    IF @VFECHA_DESDE IS NOT NULL SET @VFECHA_DESDE_HTML = CONVERT(VARCHAR(10), @VFECHA_DESDE, 23); ELSE SET @VFECHA_DESDE_HTML = '';
    IF @VFECHA_HASTA IS NOT NULL SET @VFECHA_HASTA_HTML = CONVERT(VARCHAR(10), @VFECHA_HASTA, 23); ELSE SET @VFECHA_HASTA_HTML = '';
 
    IF @V_PAGE_SIZE_RAW IN ('25', '50', '100') SET @V_PAGE_SIZE = CONVERT(INT, @V_PAGE_SIZE_RAW);
    ELSE BEGIN SET @V_PAGE_SIZE = 25; SET @V_PAGE_SIZE_RAW = '25'; END
 
    IF @VNRO_PAGINA < 0 SET @VNRO_PAGINA = 0;
    SET @V_MODO_LIVIANO = CASE WHEN @V_PAGE_SIZE = 100 THEN 1 ELSE 0 END;
 
    IF @V_SOLAPA = 'PLAN'
    BEGIN
        SELECT @VTOTAL_PLANIFICA = COUNT(1)
        FROM LK_AGENDA A WITH (NOLOCK)
        LEFT JOIN LK_PROYECTO P WITH (NOLOCK) ON P.ID_PROYECTO = A.ID_PROYECTO
        LEFT JOIN LK_CLIENTES C WITH (NOLOCK) ON C.ID_CLIENTE = ISNULL(A.ID_CLIENTE, P.ID_CLIENTE)
        WHERE (
            @VBUSCA_CASO = ''
            OR ISNULL(P.CODIGO, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(P.NORMA_REF, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(C.RAZON_SOCIAL_CLIENTE, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR CONVERT(VARCHAR(50), A.ID_AGENDA) LIKE '%' + @VBUSCA_CASO + '%'
            OR CONVERT(VARCHAR(50), A.ID_PROYECTO) LIKE '%' + @VBUSCA_CASO + '%'
        )
        AND (@VFECHA_DESDE IS NULL OR ISNULL(A.FECHA_HASTA, A.FECHA_ALTA) >= @VFECHA_DESDE)
        AND (@VFECHA_HASTA IS NULL OR A.FECHA_ALTA < DATEADD(DAY, 1, @VFECHA_HASTA));
    END
    ELSE IF @V_SOLAPA = 'PROYECTO'
    BEGIN
        SELECT @VTOTAL_PLANIFICA = COUNT(1)
        FROM LK_PROYECTO P WITH (NOLOCK)
        INNER JOIN LK_CLIENTES CLI WITH (NOLOCK) ON P.ID_CLIENTE = CLI.ID_CLIENTE
        WHERE P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
        AND (
            @VBUSCA_CASO = ''
            OR ISNULL(P.CODIGO, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(P.NORMA_REF, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(CLI.RAZON_SOCIAL_CLIENTE, '') LIKE '%' + @VBUSCA_CASO + '%'
        );
    END
 
    SET @VTOTAL_PLANIFICA = ISNULL(@VTOTAL_PLANIFICA, 0);
    SET @VTOTAL_PAGINAS = CASE WHEN @VTOTAL_PLANIFICA = 0 THEN 1 ELSE CEILING(CONVERT(DECIMAL(18,2), @VTOTAL_PLANIFICA) / CONVERT(DECIMAL(18,2), @V_PAGE_SIZE)) END;
 
    IF @VNRO_PAGINA >= @VTOTAL_PAGINAS SET @VNRO_PAGINA = @VTOTAL_PAGINAS - 1;
    IF @VNRO_PAGINA < 0 SET @VNRO_PAGINA = 0;
 
    SET @V_OFFSET = @VNRO_PAGINA * @V_PAGE_SIZE;
    SET @VPAGINA_ACTUAL = @VNRO_PAGINA + 1;
    SET @VPAGINA_PREV = @VNRO_PAGINA - 1;
    SET @VPAGINA_NEXT = @VNRO_PAGINA + 1;
    SET @VPAGINA_DESDE = CASE WHEN @VTOTAL_PLANIFICA = 0 THEN 0 ELSE @V_OFFSET + 1 END;
    SET @VPAGINA_HASTA = CASE WHEN (@V_OFFSET + @V_PAGE_SIZE) > @VTOTAL_PLANIFICA THEN @VTOTAL_PLANIFICA ELSE @V_OFFSET + @V_PAGE_SIZE END;
 
    SELECT
        @TOTAL_PROYECTOS = COUNT(*),
		@TOTAL_CLIENTES = COUNT(DISTINCT ID_CLIENTE),
        @TOTAL_TERMINADOS = SUM(CASE WHEN ISNULL(ESTADO_PROYECTO_TOTAL, '') = 'TERMINADO' THEN 1 ELSE 0 END),
        @TOTAL_EN_CURSO = SUM(CASE WHEN ISNULL(ESTADO_PROYECTO_TOTAL, '') <> 'TERMINADO' THEN 1 ELSE 0 END),
        @TOTAL_HORAS_PROY = SUM(ISNULL(TOTAL_HORAS_PROYECTADAS, 0)),
        @TOTAL_HORAS_EJEC = SUM(ISNULL(TOTAL_HORAS_EJECUTADAS, 0)),
        @TOTAL_MONTO = SUM(ISNULL(MONTO_PRESUP, 0))
    FROM LK_PROYECTO WITH (NOLOCK);
 
    SET @TOTAL_PROYECTOS = ISNULL(@TOTAL_PROYECTOS, 0);
    SET @TOTAL_TERMINADOS = ISNULL(@TOTAL_TERMINADOS, 0);
    SET @TOTAL_EN_CURSO = ISNULL(@TOTAL_EN_CURSO, 0);
    SET @TOTAL_HORAS_PROY = ISNULL(@TOTAL_HORAS_PROY, 0);
    SET @TOTAL_HORAS_EJEC = ISNULL(@TOTAL_HORAS_EJEC, 0);
    SET @TOTAL_MONTO = ISNULL(@TOTAL_MONTO, 0);
    SET @TOTAL_HORAS_PEND = CASE WHEN @TOTAL_HORAS_PROY - @TOTAL_HORAS_EJEC < 0 THEN 0 ELSE @TOTAL_HORAS_PROY - @TOTAL_HORAS_EJEC END;
    
	SELECT	@TOTAL_CONSULTORES = COUNT(DISTINCT ID_EMPLEADO) FROM LK_AGENDA_EMPLEADO;
 
    SELECT @JSON_ESTADOS = (
        SELECT label, value FROM (
            SELECT ISNULL(ESTADO_PROYECTO_TOTAL, 'Sin estado') AS label, COUNT(*) AS value
            FROM LK_PROYECTO WITH (NOLOCK)
            GROUP BY ISNULL(ESTADO_PROYECTO_TOTAL, 'Sin estado')
        ) X ORDER BY value DESC FOR JSON PATH
    );
 
    SELECT @JSON_SERVICIOS = (
        SELECT label, value FROM (
            SELECT
                CASE ID_TIPO_SERVICIO
                    WHEN 1 THEN 'Consultoría'
                    WHEN 2 THEN 'Auditoría'
                    WHEN 3 THEN 'Capacitación'
                    ELSE 'Otro'
                END AS label,
                COUNT(*) AS value
            FROM LK_PROYECTO_SERVICIO WITH (NOLOCK)
            GROUP BY CASE ID_TIPO_SERVICIO WHEN 1 THEN 'Consultoría' WHEN 2 THEN 'Auditoría' WHEN 3 THEN 'Capacitación' ELSE 'Otro' END
        ) X ORDER BY value DESC FOR JSON PATH
    );
 
    SET @JSON_ESTADOS = ISNULL(@JSON_ESTADOS, '[]');
    SET @JSON_SERVICIOS = ISNULL(@JSON_SERVICIOS, '[]');
 
    IF @V_SOLAPA = 'PLAN'
    BEGIN
        SET @HTML_TABLA_PLANIFICA = '';
 
        DECLARE @PAGE_IDS TABLE (ID_AGENDA INT PRIMARY KEY);
 
        INSERT INTO @PAGE_IDS (ID_AGENDA)
        SELECT A.ID_AGENDA
        FROM LK_AGENDA A WITH (NOLOCK)
        LEFT JOIN LK_PROYECTO P WITH (NOLOCK) ON P.ID_PROYECTO = A.ID_PROYECTO
        LEFT JOIN LK_CLIENTES C WITH (NOLOCK) ON C.ID_CLIENTE = ISNULL(A.ID_CLIENTE, P.ID_CLIENTE)
        WHERE (
            @VBUSCA_CASO = ''
            OR ISNULL(P.CODIGO, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(P.NORMA_REF, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(C.RAZON_SOCIAL_CLIENTE, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR CONVERT(VARCHAR(50), A.ID_AGENDA) LIKE '%' + @VBUSCA_CASO + '%'
            OR CONVERT(VARCHAR(50), A.ID_PROYECTO) LIKE '%' + @VBUSCA_CASO + '%'
        )
        AND (@VFECHA_DESDE IS NULL OR ISNULL(A.FECHA_HASTA, A.FECHA_ALTA) >= @VFECHA_DESDE)
        AND (@VFECHA_HASTA IS NULL OR A.FECHA_ALTA < DATEADD(DAY, 1, @VFECHA_HASTA))
        ORDER BY A.ID_AGENDA DESC
        OFFSET @V_OFFSET ROWS FETCH NEXT @V_PAGE_SIZE ROWS ONLY;
 
        DECLARE
            @C_ID_AGENDA INT,
            @C_ID_CLIENTE INT,
            @C_ID_PROYECTO INT,
            @C_PROYECTO_SERV_ID INT,
            @C_ID_SERVICIO INT,
            @C_ID_TIPO_SERVICIO INT,
            @C_NORMA VARCHAR(MAX),
            @C_FECHA DATETIME,
            @C_FECHA_HASTA DATETIME,
            @C_DIAS INT,
            @C_ID_CONSULTOR VARCHAR(100),
            @C_OBSERVADOR VARCHAR(MAX),
            @C_OBSERV_CALIF VARCHAR(MAX),
            @C_OBSERV_LOGISTICA VARCHAR(MAX),
            @C_RAZON_SOCIAL_CLIENTE VARCHAR(300),
            @C_CODIGO VARCHAR(100),
            @C_NORMA_REF VARCHAR(300),
            @C_ESTADO_PROYECTO_TOTAL VARCHAR(50),
            @C_SERVICIO_NOMBRE VARCHAR(300),
            @C_SERVICIO_TIPO VARCHAR(50),
            @C_CLIENTE_HTML VARCHAR(500),
            @C_PROYECTO_HTML VARCHAR(700),
            @C_SERVICIO_HTML VARCHAR(500),
            @C_OBSERVADOR_HTML VARCHAR(500),
            @C_OBSERV_CALIF_HTML VARCHAR(1000),
            @C_OBSERV_LOG_HTML VARCHAR(1000),
            @C_NORMA_HTML VARCHAR(1200),
            @C_ESTADO_HTML VARCHAR(300);
 
        DECLARE CUR_PLANIFICA CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            A.ID_AGENDA,
            A.ID_CLIENTE,
            A.ID_PROYECTO,
            ISNULL(A.PROYECTO_SERV_ID, 0),
            A.ID_SERVICIO,
            ISNULL(PS.ID_TIPO_SERVICIO, A.ID_SERVICIO),
            LEFT(ISNULL(A.NORMA, ''), 500),
            A.FECHA_ALTA,
            A.FECHA_HASTA,
            A.DIAS,
            CONVERT(VARCHAR(100), A.ID_CONSULTOR),
            LEFT(ISNULL(A.OBSERVADOR, ''), 200),
            LEFT(ISNULL(A.OBSERV_CALIF, ''), 500),
            LEFT(ISNULL(A.OBSERV_LOGISTICA, ''), 500),
            ISNULL(C.RAZON_SOCIAL_CLIENTE, 'Sin cliente'),
            ISNULL(P.CODIGO, ''),
            ISNULL(P.NORMA_REF, 'Sin proyecto asociado'),
            ISNULL(P.ESTADO_PROYECTO_TOTAL, 'Sin estado'),
            ISNULL(PS.NOMBRE, 'Sin servicio asociado')
        FROM @PAGE_IDS X
        INNER JOIN LK_AGENDA A WITH (NOLOCK) ON A.ID_AGENDA = X.ID_AGENDA
        LEFT JOIN LK_PROYECTO P WITH (NOLOCK) ON P.ID_PROYECTO = A.ID_PROYECTO
        LEFT JOIN LK_CLIENTES C WITH (NOLOCK) ON C.ID_CLIENTE = ISNULL(A.ID_CLIENTE, P.ID_CLIENTE)
        LEFT JOIN LK_PROYECTO_SERVICIO PS WITH (NOLOCK) ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
        ORDER BY A.ID_AGENDA DESC;
 
        OPEN CUR_PLANIFICA;
        FETCH NEXT FROM CUR_PLANIFICA INTO
            @C_ID_AGENDA, @C_ID_CLIENTE, @C_ID_PROYECTO, @C_PROYECTO_SERV_ID, @C_ID_SERVICIO, @C_ID_TIPO_SERVICIO, 
            @C_NORMA, @C_FECHA, @C_FECHA_HASTA, @C_DIAS, @C_ID_CONSULTOR, @C_OBSERVADOR, @C_OBSERV_CALIF, @C_OBSERV_LOGISTICA,
            @C_RAZON_SOCIAL_CLIENTE, @C_CODIGO, @C_NORMA_REF, @C_ESTADO_PROYECTO_TOTAL, @C_SERVICIO_NOMBRE;
 
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @C_SERVICIO_TIPO =
                CASE
                    WHEN @C_ID_TIPO_SERVICIO = 1 THEN 'Consultoría'
                    WHEN @C_ID_TIPO_SERVICIO = 2 THEN 'Auditoría'
                    WHEN @C_ID_TIPO_SERVICIO = 3 THEN 'Capacitación'
                    ELSE 'Servicio'
                END;
 
            SET @C_CLIENTE_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@C_RAZON_SOCIAL_CLIENTE, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_PROYECTO_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@C_NORMA_REF, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_SERVICIO_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@C_SERVICIO_NOMBRE, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_OBSERVADOR_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@C_OBSERVADOR, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_OBSERV_CALIF_HTML = REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(@C_OBSERV_CALIF, '') = '' THEN 'Sin Observaciones' ELSE @C_OBSERV_CALIF END, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_OBSERV_LOG_HTML = REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(@C_OBSERV_LOGISTICA, '') = '' THEN 'Sin Observaciones' ELSE @C_OBSERV_LOGISTICA END, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_NORMA_HTML = REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(@C_NORMA, '') = '' THEN 'Normas disponibles en el detalle' ELSE @C_NORMA END, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @C_ESTADO_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@C_ESTADO_PROYECTO_TOTAL, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
 
            SET @HTML_TABLA_PLANIFICA = @HTML_TABLA_PLANIFICA +
            '<tr class="vct-main-row" data-vct-row="' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + '">' +
                '<td class="vct-actions-cell" align="center">' +
                    '<div style="display:inline-flex;align-items:center;justify-content:center;gap:6px;">' +
                        CASE WHEN @V_MODO_LIVIANO = 1 THEN 
                            '<span class="vct-icon-action vct-icon-expand disabled" title="Detalle deshabilitado">' + @SVG_PLUS + '</span>'
                             ELSE '<button type="button" class="vct-icon-action vct-icon-expand" title="Ver detalle" onclick="vctToggleRowDetail(''' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + ''', this);return false;">' + @SVG_PLUS + '</button>' END +
                        '<span class="vct-action-menu-wrap">' +
                            '<button type="button" class="vct-icon-action vct-icon-menu" title="Acciones" onclick="vctToggleActionMenu(this, event);return false;">' + @SVG_MENU + '</button>' +
                            '<div class="vct-action-menu">' +
                                '<a href="#" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'', {TAB: 1, TAB_SERV: 1, TAB_AGENDA: 0, CLIENTE: ' + CONVERT(VARCHAR(50), @C_ID_CLIENTE) + ', PROYECTO_ID: ' + CONVERT(VARCHAR(50), @C_ID_PROYECTO) + ', PROYECTO_SERV_ID: ' + CONVERT(VARCHAR(50), @C_PROYECTO_SERV_ID) + ', AGENDA_ID: ' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + '});">' + @SVG_EDIT + ' <span>Servicio</span></a>' +
                                '<a href="#" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''413A3F03-AD67-44E3-8907-C81085611C20'', {AGENDA_ID: ' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + '});">' + @SVG_CALENDAR + ' <span>Agenda</span></a>' +
                                '<a href="#" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''413A3F03-AD67-44E3-8907-C81085611C20'', {AGENDA_ID: ' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + '});">' + @SVG_CLIPBOARD + ' <span>Informe</span></a>' +
                                '<a href="#" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''413A3F03-AD67-44E3-8907-C81085611C20'', {AGENDA_ID: ' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + '});">' + @SVG_BOOK + ' <span>Minuta Gestión</span></a>' +
                            '</div>' +
                        '</span>' +
                    '</div>' +
                '</td>' +
                '<td title="' + @C_CLIENTE_HTML + '"><div class="vct-client-title">' + @C_CLIENTE_HTML + '</div></td>' +
                '<td title="' + ISNULL('(' + @C_CODIGO + ') - ', '') + @C_PROYECTO_HTML + '">' +
                    '<div class="vct-project-title">' + ISNULL('(' + @C_CODIGO + ') - ', '') + @C_PROYECTO_HTML + '</div>' +
                    '<div class="vct-project-subtitle">' + @C_ESTADO_HTML + '</div>' +
                '</td>' +
                '<td title="' + @C_SERVICIO_TIPO + ' - ' + @C_SERVICIO_HTML + '">' +
                    '<div class="vct-service-text">' + @C_SERVICIO_TIPO + '</div>' +
                    '<div class="vct-project-subtitle">' + @C_SERVICIO_HTML + '</div>' +
                '</td>' +
                '<td style="text-align:center;"><span class="vct-table-date">' + CASE WHEN @C_FECHA IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), @C_FECHA, 103) END + '</span></td>' +
                '<td style="text-align:center;"><span class="vct-hours-badge"><strong>' + CONVERT(VARCHAR(20), ISNULL(@C_DIAS, 0)) + '</strong> d</span></td>' +
            '</tr>' +
            CASE WHEN @V_MODO_LIVIANO = 1 THEN '' ELSE
                '<tr class="vct-detail-row" id="vctDetail_' + CONVERT(VARCHAR(50), @C_ID_AGENDA) + '" style="display:none;">' +
                    '<td colspan="6">' +
                        '<div class="vct-row-detail-box">' +
                            '<div class="vct-detail-grid">' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Cliente</div><div class="vct-detail-value">' + @C_CLIENTE_HTML + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Proyecto</div><div class="vct-detail-value">' + ISNULL('(' + @C_CODIGO + ') - ', '') + @C_PROYECTO_HTML + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Servicio</div><div class="vct-detail-value">' + @C_SERVICIO_TIPO + ' - ' + @C_SERVICIO_HTML + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Estado proyecto</div><div class="vct-detail-value">' + @C_ESTADO_HTML + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Desde</div><div class="vct-detail-value">' + CASE WHEN @C_FECHA IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), @C_FECHA, 103) END + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Hasta</div><div class="vct-detail-value">' + CASE WHEN @C_FECHA_HASTA IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), @C_FECHA_HASTA, 103) END + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Días</div><div class="vct-detail-value">' + CONVERT(VARCHAR(20), ISNULL(@C_DIAS, 0)) + '</div></div>' +
                                '<div class="vct-detail-item"><div class="vct-detail-label">Profesional</div><div class="vct-detail-value">' + CASE WHEN ISNULL(@C_ID_CONSULTOR, '') = '' THEN 'Sin Consultor' ELSE 'Asignado' END + '</div></div>' +
                            '</div>' +
                            '<div class="vct-detail-notes">' +
                                '<div class="vct-detail-note"><span class="vct-detail-label">Observador:</span> ' + CASE WHEN ISNULL(@C_OBSERVADOR_HTML, '') = '' THEN 'Sin Observador' ELSE @C_OBSERVADOR_HTML END + '</div>' +
                                '<div class="vct-detail-note"><span class="vct-detail-label">Obs. Calificación:</span> ' + @C_OBSERV_CALIF_HTML + '</div>' +
                                '<div class="vct-detail-note"><span class="vct-detail-label">Obs. Logística:</span> ' + @C_OBSERV_LOG_HTML + '</div>' +
                                '<div class="vct-detail-note"><span class="vct-detail-label">Normas:</span> ' + @C_NORMA_HTML + '</div>' +
                            '</div>' +
                        '</div>' +
                    '</td>' +
                '</tr>' END;
 
            FETCH NEXT FROM CUR_PLANIFICA INTO
                @C_ID_AGENDA, @C_ID_CLIENTE, @C_ID_PROYECTO, @C_PROYECTO_SERV_ID, @C_ID_SERVICIO, @C_ID_TIPO_SERVICIO, 
                @C_NORMA, @C_FECHA, @C_FECHA_HASTA, @C_DIAS, @C_ID_CONSULTOR, @C_OBSERVADOR, @C_OBSERV_CALIF, @C_OBSERV_LOGISTICA,
                @C_RAZON_SOCIAL_CLIENTE, @C_CODIGO, @C_NORMA_REF, @C_ESTADO_PROYECTO_TOTAL, @C_SERVICIO_NOMBRE;
        END
 
        CLOSE CUR_PLANIFICA;
        DEALLOCATE CUR_PLANIFICA;
 
        IF ISNULL(@HTML_TABLA_PLANIFICA, '') = ''
            SET @HTML_TABLA_PLANIFICA = '<tr data-vct-empty="true"><td colspan="6" class="vct-empty-row">No hay visitas planificadas para mostrar.</td></tr>';
    END
    ELSE IF @V_SOLAPA = 'PROYECTO'
    BEGIN
        SET @HTML_TABLA_PROYECTOS = '';
 
        DECLARE
            @PR_ID_PROYECTO         INT,
            @PR_ID_CLIENTE          INT,
            @PR_CLIENTE_DESC        VARCHAR(300),
            @PR_CODIGO              VARCHAR(100),
            @PR_NORMA_REF           VARCHAR(300),
            @PR_ESTADO_DESC         VARCHAR(100),
            @PR_NIVEL_RIESGO        VARCHAR(50),
            @PR_FECHA_INICIO        DATETIME,
            @PR_FECHA_FIN           DATETIME,
            @PR_HORAS_PROY          INT,
            @PR_CLIENTE_HTML        VARCHAR(500),
            @PR_PROYECTO_HTML       VARCHAR(700),
            @PR_ESTADO_HTML         VARCHAR(200),
            @PR_HORAS_EJEC_STR      VARCHAR(100),
            @PR_SERVICIOS_HTML      VARCHAR(MAX);
 
        DECLARE CUR_PROYECTOS CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            P.ID_PROYECTO,
            P.ID_CLIENTE,
            ISNULL(CLI.RAZON_SOCIAL_CLIENTE, 'Sin cliente'),
            ISNULL(P.CODIGO, ''),
            ISNULL(P.NORMA_REF, 'Sin proyecto asociado'),
            ISNULL(CD.CAT_DATA_DESC, 'Sin Estado'),
            ISNULL(P.NIVEL_RIESGO, 'N/A'),
            P.FECHA_INICIO_REAL,
            P.FECHA_FIN_REAL,
            ISNULL(P.TOTAL_HORAS_PROYECTADAS, 0)
        FROM LK_PROYECTO P WITH (NOLOCK)
        INNER JOIN LK_CLIENTES CLI WITH (NOLOCK) ON P.ID_CLIENTE = CLI.ID_CLIENTE
        LEFT JOIN CAT_DATA CD WITH (NOLOCK) ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL 
            AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
        WHERE P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
        AND (
            @VBUSCA_CASO = ''
            OR ISNULL(P.CODIGO, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(P.NORMA_REF, '') LIKE '%' + @VBUSCA_CASO + '%'
            OR ISNULL(CLI.RAZON_SOCIAL_CLIENTE, '') LIKE '%' + @VBUSCA_CASO + '%'
        )
        ORDER BY CLI.RAZON_SOCIAL_CLIENTE, P.ID_PROYECTO DESC
        OFFSET @V_OFFSET ROWS FETCH NEXT @V_PAGE_SIZE ROWS ONLY;
 
        OPEN CUR_PROYECTOS;
 
        FETCH NEXT FROM CUR_PROYECTOS INTO
            @PR_ID_PROYECTO, @PR_ID_CLIENTE, @PR_CLIENTE_DESC, @PR_CODIGO, @PR_NORMA_REF, 
            @PR_ESTADO_DESC, @PR_NIVEL_RIESGO, @PR_FECHA_INICIO, @PR_FECHA_FIN, @PR_HORAS_PROY;
 
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @PR_CLIENTE_HTML  = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@PR_CLIENTE_DESC, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @PR_PROYECTO_HTML = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@PR_NORMA_REF, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            SET @PR_ESTADO_HTML   = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@PR_ESTADO_DESC, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
            
            SET @PR_HORAS_EJEC_STR = dbo.FN_GET_TOTAL_HS_EJECUTADAS('P', @PR_ID_PROYECTO, NULL, NULL);
            SET @PR_SERVICIOS_HTML = dbo.FN_GET_SERVICIOS_PROY(@PR_ID_PROYECTO, @FORM_ID, 'I');
 
            SET @HTML_TABLA_PROYECTOS = @HTML_TABLA_PROYECTOS +
            '<tr class="vct-main-row">' +
                '<td class="vct-actions-cell" align="center">' +
                    '<button type="button" class="vct-icon-action vct-icon-360" title="Vista 360" ' +
                    'onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'', {TAB: 1, TAB_SERV: 1, CLIENTE: ' + CONVERT(VARCHAR(50), @PR_ID_CLIENTE) + ', PROYECTO_ID: ' + CONVERT(VARCHAR(50), @PR_ID_PROYECTO) + ', PROYECTO: ' + CONVERT(VARCHAR(50), @PR_ID_PROYECTO) + '});">' +
                        @SVG_STREET_VIEW +
                    '</button>' +
                '</td>' +
                '<td><div class="vct-client-title">' + @PR_CLIENTE_HTML + '</div></td>' +
                '<td>' +
                    '<div class="vct-project-title">' + ISNULL('(' + @PR_CODIGO + ') - ', '') + @PR_PROYECTO_HTML + '</div>' +
                '</td>' +
                '<td style="text-align:center;">' +
                    '<div class="vct-project-subtitle"><strong>' + @PR_ESTADO_HTML + '</strong></div>' +
                '</td>' +
                '<td style="text-align:center;"><span class="vct-table-date">' + CASE WHEN @PR_FECHA_INICIO IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), @PR_FECHA_INICIO, 103) END + '</span></td>' +
                '<td style="text-align:center;"><span class="vct-hours-badge"><strong>' + ISNULL(@PR_HORAS_EJEC_STR, '0') + '</strong>/' + CONVERT(VARCHAR(20), @PR_HORAS_PROY) + '</span></td>' +
            '</tr>';
 
            FETCH NEXT FROM CUR_PROYECTOS INTO
                @PR_ID_PROYECTO, @PR_ID_CLIENTE, @PR_CLIENTE_DESC, @PR_CODIGO, @PR_NORMA_REF, 
                @PR_ESTADO_DESC, @PR_NIVEL_RIESGO, @PR_FECHA_INICIO, @PR_FECHA_FIN, @PR_HORAS_PROY;
        END
 
        CLOSE CUR_PROYECTOS;
        DEALLOCATE CUR_PROYECTOS;
 
        IF ISNULL(@HTML_TABLA_PROYECTOS, '') = ''
            SET @HTML_TABLA_PROYECTOS = '<tr data-vct-empty="true"><td colspan="6" class="vct-empty-row">No hay proyectos activos para mostrar.</td></tr>';
    END
 
    -- Paginación HTML
    SET @HTML_PAGINADOR =
        '<div class="vct-table-info">Mostrando ' + CONVERT(VARCHAR(20), @VPAGINA_DESDE) +
        ' a ' + CONVERT(VARCHAR(20), @VPAGINA_HASTA) +
        ' de ' + CONVERT(VARCHAR(20), @VTOTAL_PLANIFICA) +
        CASE WHEN @VBUSCA_CASO = '' AND @VFECHA_DESDE IS NULL AND @VFECHA_HASTA IS NULL THEN ' registros' ELSE ' registros filtrados' END +
        ' · Página ' + CONVERT(VARCHAR(20), @VPAGINA_ACTUAL) +
        ' de ' + CONVERT(VARCHAR(20), @VTOTAL_PAGINAS) +
        '</div><div class="vct-table-pager">';
 
    IF @VNRO_PAGINA > 0
        SET @HTML_PAGINADOR = @HTML_PAGINADOR +
            '<a href="#" class="vct-page-btn" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {NRO_PAGINA: 0, BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});">Primera</a>' +
            '<a href="#" class="vct-page-btn" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {NRO_PAGINA: ' + CONVERT(VARCHAR(20), @VPAGINA_PREV) + ', BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});">Anterior</a>';
    ELSE
        SET @HTML_PAGINADOR = @HTML_PAGINADOR + '<span class="vct-page-btn disabled">Primera</span><span class="vct-page-btn disabled">Anterior</span>';
 
    SET @HTML_PAGINADOR = @HTML_PAGINADOR + '<span class="vct-page-btn active">' + CONVERT(VARCHAR(20), @VPAGINA_ACTUAL) + '</span>';
 
    IF @VNRO_PAGINA < (@VTOTAL_PAGINAS - 1)
        SET @HTML_PAGINADOR = @HTML_PAGINADOR +
            '<a href="#" class="vct-page-btn" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {NRO_PAGINA: ' + CONVERT(VARCHAR(20), @VPAGINA_NEXT) + ', BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});">Siguiente</a>' +
            '<a href="#" class="vct-page-btn" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {NRO_PAGINA: ' + CONVERT(VARCHAR(20), (@VTOTAL_PAGINAS - 1)) + ', BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});">Última</a>';
    ELSE
        SET @HTML_PAGINADOR = @HTML_PAGINADOR + '<span class="vct-page-btn disabled">Siguiente</span><span class="vct-page-btn disabled">Última</span>';
 
    SET @HTML_PAGINADOR = @HTML_PAGINADOR + '</div>';
 
    -- OUTPUT @OMENU
    SET @OMENU = ISNULL(@HTML_SIDEBAR, '') + '
    <div class="vocaturo-portal" style="margin-top: 0px !important;">
        <div class="vocaturo-header-card">
            <div class="vocaturo-header-left">
                <div class="vocaturo-header-icon">' + @IMG_HEADER_LOGO + '</div>
                <div>
                    <div class="vocaturo-header-title">DASHBOARD</div>
                    <div class="vocaturo-header-subtitle">Gerencia</div>
                </div>
            </div>
            <div class="vocaturo-header-home"><span style="cursor:pointer" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {});">' + @SVG_HOME + '</span></div>
        </div>
 
        <div class="search-card">
            <div class="search-content">
                <div class="search-label">Buscar caso</div>
                <input id="buscaCaso" type="text" value="' + ISNULL(@VBUSCA_HTML, '') + '" 
                       placeholder="Código, cliente, norma o ID"
                       onkeydown="if(event.keyCode==13){return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {FILTRO: this.value, NRO_PAGINA: 0, BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});}">
 
                <a href="#" role="button"
                   onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {FILTRO: document.getElementById(''buscaCaso'').value, NRO_PAGINA: 0, BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});"
                   style="cursor:pointer;text-decoration:none;color:inherit;" title="Buscar caso">
                    ' + @SVG_SEARCH + '
                </a>
 
                <a href="#" role="button"
                   onclick="document.getElementById(''buscaCaso'').value='''';return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {FILTRO: '''', NRO_PAGINA: 0, BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});"
                   style="cursor:pointer;text-decoration:none;color:inherit;margin-left:8px;" title="Limpiar búsqueda">
                    ' + @SVG_TIMES + '
                </a>
            </div>
        </div>
    </div>';
 
    -- OUTPUT @OPAGINA
   SET @OPAGINA = '
    <style>
        .vocaturo-portal { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif !important; 
            margin-top: 0px !important; 
            max-width: 100% !important;
            box-sizing: border-box !important;
            padding: 0 4px !important;
        }
        .vocaturo-portal * { box-sizing: border-box !important; }
        
        /* HEADER Y BÚSQUEDA */
        .vocaturo-portal .vocaturo-header-card { background: #66062D !important; color: #ffffff !important; padding: 14px 20px !important; border-radius: 12px !important; display: flex !important; align-items: center !important; justify-content: space-between !important; margin-bottom: 15px !important; box-shadow: 0 4px 12px rgba(102,6,45,0.15) !important; }
        .vocaturo-portal .vocaturo-header-left { display: flex !important; align-items: center !important; gap: 12px !important; }
        .vocaturo-portal .vocaturo-header-icon { background: transparent !important; padding: 0 !important; border-radius: 0 !important; display: flex !important; align-items: center !important; justify-content: center !important; box-shadow: none !important; }
        .vocaturo-portal .vct-header-logo-img { height: 52px !important; width: 52px !important; object-fit: contain !important; display: block !important; mix-blend-mode: lighten !important; }
        .vocaturo-portal .vocaturo-header-title { font-size: 16px !important; font-weight: 700 !important; color: #ffffff !important; letter-spacing: 0.5px !important; }
        .vocaturo-portal .vocaturo-header-subtitle { font-size: 11px !important; color: rgba(255,255,255,0.8) !important; font-weight: 500 !important; }
        .vocaturo-portal .vocaturo-header-home { display: flex !important; align-items: center !important; justify-content: center !important; color: #ffffff !important; opacity: 0.9 !important; transition: opacity 0.2s !important; }
 
        .vocaturo-portal .search-card { background: #ffffff !important; border: 1px solid #e2e8f0 !important; border-radius: 12px !important; padding: 10px 16px !important; margin-bottom: 15px !important; box-shadow: 0 2px 8px rgba(0,0,0,0.03) !important; }
        .vocaturo-portal .search-content { display: flex !important; align-items: center !important; gap: 10px !important; flex-wrap: wrap !important; }
        .vocaturo-portal .search-label { font-size: 12px !important; font-weight: 700 !important; color: #66062D !important; text-transform: uppercase !important; white-space: nowrap !important; }
        .vocaturo-portal #buscaCaso { flex: 1 !important; min-width: 140px !important; height: 36px !important; border: 1px solid #cbd5e1 !important; border-radius: 8px !important; padding: 0 12px !important; font-size: 13px !important; color: #0f172a !important; outline: none !important; }
 
        /* METRIC CARDS */
        .vocaturo-portal .cards-container { display: flex !important; gap: 15px !important; margin-bottom: 20px !important; flex-wrap: wrap !important; }
        .vocaturo-portal .card { flex: 1 1 250px !important; min-width: 0 !important; background: #ffffff !important; border: 1px solid #e2e8f0 !important; border-radius: 12px !important; padding: 16px 20px !important; box-shadow: 0 4px 12px rgba(0,0,0,0.03) !important; }
        .vocaturo-portal .card-label { font-size: 12px !important; font-weight: 700 !important; color: #64748b !important; text-transform: uppercase !important; margin-bottom: 8px !important; }
        .vocaturo-portal .card-content { display: flex !important; align-items: baseline !important; justify-content: space-between !important; }
        .vocaturo-portal .card-value { font-size: 28px !important; font-weight: 800 !important; color: #66062D !important; }
        .vocaturo-portal .card-side { font-size: 12px !important; font-weight: 600 !important; text-align: right !important; }
        .vocaturo-portal .side-ok { color: #16a34a !important; }
        .vocaturo-portal .side-bad { color: #dc2626 !important; }
 
        /* ESTRUCTURA Y ALINEACIÓN DE GRÁFICOS Y LEYENDAS */
        .vocaturo-portal .vct-chart-row { display: flex !important; gap: 20px !important; margin-bottom: 20px !important; flex-wrap: wrap !important; align-items: stretch !important; width: 100% !important; }
        .vocaturo-portal .vct-chart-card { flex: 1 1 calc(50% - 10px) !important; background: #ffffff !important; border: 1px solid #e2e8f0 !important; border-radius: 12px !important; padding: 20px !important; min-width: 320px !important; box-shadow: 0 4px 12px rgba(0,0,0,0.02) !important; display: flex !important; flex-direction: column !important; box-sizing: border-box !important; }
        .vocaturo-portal .vct-chart-card-head { display: flex !important; justify-content: space-between !important; align-items: flex-start !important; margin-bottom: 16px !important; padding-bottom: 10px !important; border-bottom: 1px solid #f1f5f9 !important; }
        .vocaturo-portal .label-bigcard { font-size: 15px !important; font-weight: 700 !important; color: #1e293b !important; line-height: 1.2 !important; }
        .vocaturo-portal .vct-chart-subtitle { font-size: 12px !important; color: #64748b !important; margin-top: 3px !important; }
        .vocaturo-portal .vct-chart-badge { background-color: #f1f5f9 !important; color: #475569 !important; font-size: 10px !important; font-weight: 700 !important; padding: 4px 8px !important; border-radius: 6px !important; text-transform: uppercase !important; letter-spacing: 0.5px !important; }
        .vocaturo-portal .vct-chart-layout { display: flex !important; align-items: center !important; justify-content: space-between !important; gap: 15px !important; width: 100% !important; flex: 1 !important; flex-wrap: nowrap !important; }
        .vocaturo-portal .vct-chart-layout--donut .vct-chart-canvas-wrap { position: relative !important; height: 180px !important; flex: 1 1 auto !important; max-width: 220px !important; min-width: 160px !important; display: flex !important; align-items: center !important; justify-content: center !important; margin: 0 auto !important; }
        .vocaturo-portal .vct-chart-layout--bar .vct-chart-canvas-wrap { position: relative !important; height: 180px !important; flex: 1 1 auto !important; min-width: 0 !important; width: 100% !important; }
        .vocaturo-portal .vct-chart-legend { flex: 0 0 auto !important; font-size: 12px !important; margin-left: auto !important; text-align: right !important; }
        .vocaturo-portal .vct-chart-legend ul { list-style: none !important; margin: 0 !important; padding: 0 !important; display: flex !important; flex-direction: column !important; gap: 10px !important; }
        .vocaturo-portal .vct-chart-legend li { display: flex !important; align-items: center !important; justify-content: flex-end !important; gap: 6px !important; font-size: 12px !important; font-weight: 600 !important; white-space: nowrap !important; color: #334155 !important; }
        .vocaturo-portal .vct-chart-legend strong, .vocaturo-portal .vct-chart-legend b { font-weight: 800 !important; color: #0f172a !important; margin: 0 5px !important; display: inline-block !important; }
 
        /* ACCORDION Y TOOLBAR */
        .vocaturo-portal .vct-accordion-header { width: 100% !important; background: #ffffff !important; border: 1px solid #e2e8f0 !important; border-radius: 12px !important; padding: 14px 20px !important; display: flex !important; align-items: center !important; justify-content: space-between !important; cursor: pointer !important; font-weight: 700 !important; color: #0f172a !important; box-shadow: 0 2px 8px rgba(0,0,0,0.02) !important; }
        .vocaturo-portal .vct-accordion-item .vct-accordion-content { display: none !important; padding-top: 12px !important; }
        .vocaturo-portal .vct-accordion-item.active .vct-accordion-content { display: block !important; }
        .vocaturo-portal .vct-accordion-item .vct-arrow { transition: transform 0.2s ease !important; display: inline-block !important; }
        .vocaturo-portal .vct-accordion-item.active .vct-arrow { transform: rotate(180deg) !important; }
        .vocaturo-portal .vct-table-toolbar { display: flex !important; align-items: center !important; justify-content: space-between !important; margin-bottom: 12px !important; gap: 12px !important; flex-wrap: wrap !important; }
 
        /* FILTRO DE FECHAS BASE DESKTOP */
        .vocaturo-portal .vct-date-filter-demo { display: flex !important; flex-direction: row !important; align-items: center !important; gap: 8px !important; flex-wrap: wrap !important; }
        .vocaturo-portal .vct-date-field-demo { display: inline-flex !important; align-items: center !important; gap: 6px !important; height: 36px !important; padding: 0 8px !important; border: 1px solid #cbd5e1 !important; border-radius: 8px !important; background: #ffffff !important; }
        .vocaturo-portal .vct-date-field-demo label { margin: 0 !important; font-size: 10px !important; font-weight: 700 !important; color: #66062D !important; text-transform: uppercase !important; }
        .vocaturo-portal .vct-date-field-demo input[type=date] { border: 0 !important; outline: none !important; background: transparent !important; color: #0f172a !important; font-size: 11px !important; font-weight: 600 !important; padding: 0 !important; max-width: 110px !important; }
        .vocaturo-portal .vct-date-action-demo { width: 34px !important; height: 34px !important; border-radius: 8px !important; display: inline-flex !important; align-items: center !important; justify-content: center !important; color: #ffffff !important; background: #66062D !important; }
        .vocaturo-portal .vct-date-clear-demo { width: 34px !important; height: 34px !important; border-radius: 8px !important; display: inline-flex !important; align-items: center !important; justify-content: center !important; color: #66062D !important; background: #fee2e2 !important; }
 
        /* BOTÓN DE NUEVO PROYECTO (+) EN TOOLBAR */
        .vocaturo-portal .vct-btn-add-proy {
            display: inline-flex !important;
            align-items: center !important;
            gap: 6px !important;
            height: 32px !important;
            padding: 0 12px !important;
            background: #66062D !important;
            color: #ffffff !important;
            border-radius: 8px !important;
            font-size: 12px !important;
            font-weight: 700 !important;
            cursor: pointer !important;
            text-decoration: none !important;
            transition: background 0.2s ease !important;
            margin-left: 10px !important;
        }
        .vocaturo-portal .vct-btn-add-proy:hover {
            background: #4a0421 !important;
            color: #ffffff !important;
        }
 
        /* ====================================================
           🎯 TABLA Y MANEJO DE OVERFLOW DE FILAS
           ==================================================== */
        .vocaturo-portal .vct-table-scroll { 
            overflow: visible !important; 
            background: #ffffff !important; 
            border: 1px solid #e2e8f0 !important; 
            border-radius: 12px !important; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.03) !important; 
            width: 100% !important; 
        }
        
        .vocaturo-portal .vct-table { 
            table-layout: fixed !important; 
            width: 100% !important; 
            border-collapse: collapse !important; 
            font-size: 13px !important; 
            text-align: left !important; 
        }
        
        .vocaturo-portal .vct-table th { 
            background: #f8fafc !important; 
            color: #475569 !important; 
            font-weight: 700 !important; 
            padding: 10px 12px !important; 
            border-bottom: 1px solid #e2e8f0 !important; 
            font-size: 11px !important; 
            text-transform: uppercase !important; 
            letter-spacing: 0.5px !important; 
            white-space: nowrap !important;
            vertical-align: middle !important;
        }
        
        .vocaturo-portal .vct-table td { 
            padding: 10px 12px !important; 
            border-bottom: 1px solid #f1f5f9 !important; 
            color: #334155 !important; 
            vertical-align: middle !important; 
            max-width: 0 !important; 
            overflow: hidden !important; 
            text-overflow: ellipsis !important; 
            white-space: nowrap !important; 
        }
 
        /* 🔴 FILA CONTEXTUAL ELEVADA AL DESPLEGAR MENÚ */
        .vocaturo-portal .vct-main-row {
            position: relative !important;
            z-index: 1 !important;
        }
        .vocaturo-portal .vct-main-row.vct-row-active,
        .vocaturo-portal .vct-main-row:hover,
        .vocaturo-portal .vct-main-row:focus-within {
            z-index: 9999 !important;
        }
 
        .vocaturo-portal .vct-table th:nth-child(1), .vocaturo-portal .vct-table td:nth-child(1) { width: 90px !important; min-width: 90px !important; text-align: center !important; }  /* Acciones */
        .vocaturo-portal .vct-table th:nth-child(2), .vocaturo-portal .vct-table td:nth-child(2) { width: 22% !important; text-align: left !important; }    /* Cliente */
        .vocaturo-portal .vct-table th:nth-child(3), .vocaturo-portal .vct-table td:nth-child(3) { width: 38% !important; text-align: left !important; }    /* Proyecto */
        .vocaturo-portal .vct-table th:nth-child(4), .vocaturo-portal .vct-table td:nth-child(4) { width: 13% !important; text-align: center !important; }  /* Estado / Servicio */
        .vocaturo-portal .vct-table th:nth-child(5), .vocaturo-portal .vct-table td:nth-child(5) { width: 12% !important; text-align: center !important; }  /* Inicio */
        .vocaturo-portal .vct-table th:nth-child(6), .vocaturo-portal .vct-table td:nth-child(6) { width: 15% !important; text-align: center !important; }  /* Horas */
 
        .vocaturo-portal .vct-actions-cell { 
            white-space: nowrap !important; 
            width: 90px !important; 
            min-width: 90px !important; 
            text-align: center !important; 
            overflow: visible !important; 
        }
        
        .vocaturo-portal .vct-icon-action { border: none !important; background: transparent !important; padding: 0 !important; margin: 0 !important; cursor: pointer !important; outline: none !important; }
        
        .vocaturo-portal .vct-icon-expand,
        .vocaturo-portal .vct-icon-360,
        .vocaturo-portal .vct-icon-menu { 
            width: 28px !important; 
            height: 28px !important; 
            border-radius: 8px !important; 
            display: inline-flex !important; 
            align-items: center !important; 
            justify-content: center !important; 
            cursor: pointer !important; 
            transition: all 0.2s ease !important; 
            vertical-align: middle !important;
            margin: 0 1px !important;
        }
 
        .vocaturo-portal .vct-icon-expand { background: #eff6ff !important; border: 1px solid #dbeafe !important; }
        .vocaturo-portal .vct-icon-expand:hover { background: #dbeafe !important; transform: scale(1.05) !important; }
 
        .vocaturo-portal .vct-icon-360 { background: #fffbe3 !important; border: 1px solid #fef3c7 !important; }
        .vocaturo-portal .vct-icon-360:hover { background: #fef3c7 !important; transform: scale(1.05) !important; }
        
        .vocaturo-portal .vct-icon-menu { background: #fdf2f8 !important; border: 1px solid #fbcfe8 !important; }
        .vocaturo-portal .vct-icon-menu:hover { background: #fce7f3 !important; transform: scale(1.05) !important; }
 
        /* 🛠️ MENÚ FLOTANTE DESPLEGADO HACIA LA DERECHA (SOBRE CLIENTE) */
        .vocaturo-portal .vct-action-menu-wrap { 
            position: relative !important; 
            display: inline-flex !important; 
            vertical-align: middle !important;
        }
 
        .vocaturo-portal .vct-action-menu { 
            display: none !important; 
            position: absolute !important; 
            top: calc(100% + 2px) !important; 
            left: 0 !important; /* SE DESPLIEGA A LA DERECHA HACIA EL CLIENTE */
            right: auto !important;
            z-index: 999999 !important; 
            background: #ffffff !important; 
            border: 1px solid #cbd5e1 !important; 
            border-radius: 10px !important; 
            box-shadow: 0 10px 25px -3px rgba(0,0,0,0.2) !important; 
            padding: 4px !important; 
            min-width: 155px !important; 
            text-align: left !important; 
        }
 
        .vocaturo-portal .vct-action-menu-wrap.active .vct-action-menu,
        .vocaturo-portal .vct-action-menu-wrap:hover .vct-action-menu { 
            display: flex !important; 
            flex-direction: column !important; 
            gap: 2px !important; 
            animation: vctFadeIn 0.15s ease-out !important; 
        }
 
        @keyframes vctFadeIn {
            from { opacity: 0; transform: translateY(-4px); }
            to { opacity: 1; transform: translateY(0); }
        }
 
        .vocaturo-portal .vct-action-menu a { display: flex !important; align-items: center !important; gap: 8px !important; padding: 6px 10px !important; font-size: 11px !important; font-weight: 600 !important; color: #334155 !important; text-decoration: none !important; border-radius: 6px !important; transition: all 0.15s ease !important; }
        .vocaturo-portal .vct-action-menu a:hover { background: #f1f5f9 !important; color: #0f172a !important; padding-left: 12px !important; }
 
        .vocaturo-portal .vct-detail-row td { padding: 8px 12px 12px 12px !important; background: #f8fafc !important; border-bottom: 2px solid #e2e8f0 !important; max-width: none !important; white-space: normal !important; text-align: left !important; }
        .vocaturo-portal .vct-row-detail-box { background: #ffffff !important; border: 1px solid #e2e8f0 !important; border-radius: 12px !important; padding: 14px 18px !important; box-shadow: 0 4px 12px rgba(0,0,0,0.03) !important; text-align: left !important; margin-top: 2px !important; }
        .vocaturo-portal .vct-detail-grid { display: grid !important; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)) !important; gap: 12px 16px !important; margin-bottom: 12px !important; text-align: left !important; }
        .vocaturo-portal .vct-detail-item { display: flex !important; flex-direction: column !important; gap: 2px !important; text-align: left !important; }
        .vocaturo-portal .vct-detail-label { font-size: 10px !important; font-weight: 700 !important; color: #66062D !important; text-transform: uppercase !important; letter-spacing: 0.4px !important; text-align: left !important; }
        .vocaturo-portal .vct-detail-value { font-size: 12px !important; font-weight: 600 !important; color: #0f172a !important; word-break: break-word !important; text-align: left !important; }
        .vocaturo-portal .vct-detail-notes { border-top: 1px dashed #cbd5e1 !important; padding-top: 10px !important; display: flex !important; flex-direction: column !important; gap: 6px !important; text-align: left !important; align-items: flex-start !important; }
        .vocaturo-portal .vct-detail-note { font-size: 11px !important; color: #334155 !important; line-height: 1.4 !important; text-align: left !important; }
        .vocaturo-portal .vct-detail-note .vct-detail-label { color: #64748b !important; margin-right: 4px !important; font-size: 10px !important; text-align: left !important; }
 
        .vocaturo-portal .vct-table-footer { display: flex !important; align-items: center !important; justify-content: space-between !important; margin-top: 12px !important; padding: 10px 12px !important; background: #ffffff !important; border: 1px solid #e2e8f0 !important; border-radius: 12px !important; flex-wrap: wrap !important; gap: 10px !important; }
        .vocaturo-portal .vct-table-info { font-size: 11px !important; color: #64748b !important; font-weight: 500 !important; }
        .vocaturo-portal .vct-table-pager { display: flex !important; align-items: center !important; gap: 4px !important; flex-wrap: wrap !important; }
        .vocaturo-portal .vct-page-btn { display: inline-flex !important; align-items: center !important; justify-content: center !important; height: 30px !important; padding: 0 10px !important; border-radius: 6px !important; font-size: 11px !important; font-weight: 600 !important; color: #334155 !important; background: #ffffff !important; border: 1px solid #cbd5e1 !important; text-decoration: none !important; transition: all 0.15s !important; cursor: pointer !important; }
        .vocaturo-portal .vct-page-btn:hover:not(.disabled):not(.active) { background: #f1f5f9 !important; border-color: #94a3b8 !important; color: #0f172a !important; }
        .vocaturo-portal .vct-page-btn.active { background: #66062D !important; border-color: #66062D !important; color: #ffffff !important; }
        .vocaturo-portal .vct-page-btn.disabled { opacity: 0.5 !important; cursor: not-allowed !important; pointer-events: none !important; }
 
        .vocaturo-portal .vct-client-title,
        .vocaturo-portal .vct-project-title,
        .vocaturo-portal .vct-service-text {
            white-space: nowrap !important;
            overflow: hidden !important;
            text-overflow: ellipsis !important;
            max-width: 100% !important;
            display: block !important;
        }
 
        .vocaturo-portal .vct-client-title { font-weight: 700 !important; color: #0f172a !important; font-size: 12px !important; }
        .vocaturo-portal .vct-project-title { font-weight: 600 !important; color: #334155 !important; font-size: 12px !important; }
        .vocaturo-portal .vct-project-subtitle { font-size: 10px !important; color: #64748b !important; margin-top: 2px !important; }
        .vocaturo-portal .vct-service-text { font-weight: 600 !important; color: #0f172a !important; font-size: 12px !important; }
 
        @media screen and (max-width: 600px) {
            .vocaturo-portal { padding: 0 !important; overflow-x: hidden !important; }
            .vocaturo-portal .vocaturo-header-card { padding: 8px 10px !important; margin-bottom: 10px !important; }
            .vocaturo-portal .search-card { padding: 6px 8px !important; margin-bottom: 10px !important; }
            .vocaturo-portal .card { padding: 10px !important; flex: 1 1 100% !important; }
            .vocaturo-portal .vct-accordion-content { padding-top: 6px !important; }
 
            .vocaturo-portal .vct-table-toolbar { flex-direction: column !important; align-items: stretch !important; gap: 8px !important; }
            .vocaturo-portal .vct-table-length { display: flex !important; align-items: center !important; justify-content: space-between !important; font-size: 11px !important; width: 100% !important; }
            
            .vocaturo-portal .vct-date-filter-demo { width: 100% !important; display: grid !important; grid-template-columns: 1fr 1fr !important; gap: 6px !important; }
            .vocaturo-portal .vct-date-field-demo { height: 34px !important; padding: 0 4px !important; width: 100% !important; justify-content: center !important; }
            .vocaturo-portal .vct-date-field-demo label { font-size: 9px !important; }
            .vocaturo-portal .vct-date-field-demo svg { display: none !important; }
            .vocaturo-portal .vct-date-field-demo input[type=date] { font-size: 10px !important; width: 100% !important; font-weight: 700 !important; border: none !important; }
            
            .vocaturo-portal .vct-date-action-demo,
            .vocaturo-portal .vct-date-clear-demo { width: 100% !important; height: 32px !important; border-radius: 6px !important; }
 
            .vocaturo-portal .vct-table-footer { flex-direction: column !important; align-items: center !important; padding: 8px !important; gap: 8px !important; }
            .vocaturo-portal .vct-table-info { font-size: 10px !important; text-align: center !important; }
            .vocaturo-portal .vct-table-pager { display: flex !important; flex-wrap: wrap !important; justify-content: center !important; gap: 3px !important; width: 100% !important; }
            .vocaturo-portal .vct-page-btn { height: 26px !important; padding: 0 6px !important; font-size: 10px !important; border-radius: 4px !important; }
 
            .vocaturo-portal .vct-table th, 
            .vocaturo-portal .vct-table td { padding: 8px 4px !important; font-size: 11px !important; }
            .vocaturo-portal .vct-detail-grid { grid-template-columns: 1fr !important; gap: 8px !important; }
            .vocaturo-portal .vct-row-detail-box { padding: 10px !important; }
        }
 
        .vocaturo-portal .vct-chart-legend li {
            transition: all 0.25s ease !important;
            opacity: 1;
        }
 
        .vocaturo-portal .vct-chart-legend li.vct-legend-active {
            font-weight: 800 !important;
            color: #0f172a !important;
            transform: translateX(-3px) !important;
            opacity: 1 !important;
        }
 
        .vocaturo-portal .vct-chart-legend li.vct-legend-active strong {
            font-size: 13px !important;
            color: #66062D !important;
        }
 
        .vocaturo-portal .vct-chart-legend li.vct-legend-dimmed {
            opacity: 0.35 !important;
        }
    </style>
 
    <div class="vocaturo-portal">
        <div class="cards-container">
            <div class="card">
                <div class="card-label">Total de Proyectos</div>
                <div class="card-content">
                    <div class="card-value">' + CONVERT(VARCHAR(20), @TOTAL_PROYECTOS) + '</div>
                    <div class="card-side">
                        <div class="side-row side-ok">' + CONVERT(VARCHAR(20), @TOTAL_TERMINADOS) + ' Terminados</div>
                        <div class="side-row side-bad">' + CONVERT(VARCHAR(20), @TOTAL_EN_CURSO) + ' En curso</div>
                    </div>
                </div>
            </div>
 
            <div class="card">
                <div class="card-label">Horas Consultores</div>
                <div class="card-content">
                    <div class="card-value">' + CONVERT(VARCHAR(20), @TOTAL_HORAS_PROY) + '</div>
                    <div class="card-side">
                        <div class="side-row side-ok">' + CONVERT(VARCHAR(20), @TOTAL_HORAS_EJEC) + ' Ejecutadas</div>
                        <div class="side-row side-bad">' + CONVERT(VARCHAR(20), @TOTAL_HORAS_PEND) + ' Pendientes</div>
                    </div>
                </div>
            </div>
 
            <div class="card">
                <div class="card-label">Total de Clientes</div>
                <div class="card-content">
                    <div class="card-value">' + CONVERT(VARCHAR(30), @TOTAL_CLIENTES) + '</div>
                    <div class="card-side">
                        <div class="side-row side-ok">' + CONVERT(VARCHAR(30), @TOTAL_CONSULTORES) + ' Consultores</div>
                        <div class="side-row side-bad">$ ' + CONVERT(VARCHAR(30), @TOTAL_MONTO) + ' Monto</div>
                    </div>
                </div>
            </div>
        </div>
 
        <div class="cards-container vct-chart-row">
            <div class="card big-card vct-chart-card">
                <div class="vct-chart-card-head">
                    <div>
                        <div class="label-bigcard">Proyectos por Estado</div>
                        <div class="vct-chart-subtitle">Distribución de los Proyectos</div>
                    </div>
                    <span class="vct-chart-badge">Estado</span>
                </div>
                <div class="vct-chart-layout vct-chart-layout--donut">
                    <div class="vct-chart-canvas-wrap">
                        <canvas id="estadoChart"></canvas>
                    </div>
                    <div id="estadoLegend" class="vct-chart-legend"></div>
                </div>
            </div>
 
            <div class="card big-card vct-chart-card">
                <div class="vct-chart-card-head">
                    <div>
                        <div class="label-bigcard">Servicios por Tipo</div>
                        <div class="vct-chart-subtitle">Cantidad de Servicio</div>
                    </div>
                    <span class="vct-chart-badge">Servicios</span>
                </div>
                <div class="vct-chart-layout vct-chart-layout--bar">
                    <div class="vct-chart-canvas-wrap vct-chart-canvas-wrap--bar">
                        <canvas id="servicioChart"></canvas>
                    </div>
                    <div id="servicioLegend" class="vct-chart-legend vct-chart-legend--compact"></div>
                </div>
            </div>
        </div>
 
        <div class="vct-table-section">
            <div class="vct-accordion-item" id="vctPlanificacion">
                <button class="vct-accordion-header" type="button" onclick="return vctTogglePlanificacion(this);">
                    ' + CASE WHEN @V_SOLAPA = 'PLAN' THEN '<span class="label-bigcard">Planificación</span>'
                             WHEN @V_SOLAPA = 'PROYECTO' THEN '<span class="label-bigcard">Proyectos</span>'
                        END + '
                    <span class="vct-arrow">&#9660;</span>
                </button>
 
                <div class="vct-accordion-content">
                    <div class="vct-table-toolbar">
                        <div class="vct-table-length" style="display:flex;align-items:center;">
                            <span>Mostrar</span>
                            <select class="vct-page-size-select" style="height:32px;border:1px solid #cbd5e1;border-radius:8px;background:#fff;color:#1e293b;font-size:12px;padding:0 6px;cursor:pointer;margin:0 4px;"
                                onchange="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {BUFFER: this.value, NRO_PAGINA: 0});">
                                <option value="25" ' + CASE WHEN @V_PAGE_SIZE = 25 THEN 'selected="selected"' ELSE '' END + '>25</option>
                                <option value="50" ' + CASE WHEN @V_PAGE_SIZE = 50 THEN 'selected="selected"' ELSE '' END + '>50</option>
                                <option value="100" ' + CASE WHEN @V_PAGE_SIZE = 100 THEN 'selected="selected"' ELSE '' END + '>100</option>
                            </select>
                            <span>registros por página</span>
                            ' + CASE WHEN @V_SOLAPA = 'PROYECTO' THEN 
                                '<a href="#" class="vct-btn-add-proy" onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''4049307F-6C13-459D-AC01-54F97D942D1B'', {});" title="Crear Nuevo Proyecto">' + 
                                    @SVG_PLUS_WHITE + ' <span>Nuevo Proyecto</span>' + 
                                '</a>' ELSE '' END + '
                        </div>
 
                        ' + CASE WHEN @V_SOLAPA = 'PLAN' THEN '
                        <div class="vct-date-filter-demo">
                            <div class="vct-date-field-demo">
                                ' + @SVG_CALENDAR + '
                                <label>Desde</label>
                                <input id="fechaDesdePlanif" name="SP.FECHA_DESDE" type="date" value="' + ISNULL(@VFECHA_DESDE_HTML, '') + '">
                            </div>
 
                            <div class="vct-date-field-demo">
                                ' + @SVG_CALENDAR + '
                                <label>Hasta</label>
                                <input id="fechaHastaPlanif" name="SP.FECHA_HASTA" type="date" value="' + ISNULL(@VFECHA_HASTA_HTML, '') + '">
                            </div>
 
                            <a href="#" role="button"
                               onclick="return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {FECHA_DESDE: document.getElementById(''fechaDesdePlanif'').value, FECHA_HASTA: document.getElementById(''fechaHastaPlanif'').value, NRO_PAGINA: 0, BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});"
                               style="cursor:pointer;text-decoration:none;" title="Buscar por fechas">
                                <span class="vct-date-action-demo">' + @SVG_SEARCH + '</span>
                            </a>
 
                            <a href="#" role="button"
                               onclick="document.getElementById(''fechaDesdePlanif'').value='''';document.getElementById(''fechaHastaPlanif'').value='''';return vctNavegarConParametros(''' + @FORM_ID + ''', ''522967A7-DDC9-465B-969B-85997AE1B085'', {FECHA_DESDE: '''', FECHA_HASTA: '''', NRO_PAGINA: 0, BUFFER: ' + CONVERT(VARCHAR(20), @V_PAGE_SIZE) + '});"
                               style="cursor:pointer;text-decoration:none;" title="Limpiar fechas">
                                <span class="vct-date-clear-demo">' + @SVG_TIMES + '</span>
                            </a>
                        </div>' ELSE '' END + '
 
                        <div class="vct-table-search">
                            <span>Total:</span>
                            <strong>' + CONVERT(VARCHAR(20), @VTOTAL_PLANIFICA) + '</strong>
                        </div>
                    </div>
 
                    <div class="vct-table-scroll">
                        <table id="vctPlanificaTable" class="vct-table vct-table-compact">
                            <thead>
                                <tr>
                                    ' + CASE WHEN @V_SOLAPA = 'PLAN' THEN '
                                        <th class="vct-actions-col" style="text-align:center;"></th>
                                        <th style="text-align:left;">Cliente</th>
                                        <th style="text-align:left;">Proyecto</th>
                                        <th style="text-align:center;">Servicio</th>
                                        <th style="text-align:center;">Inicio</th>
                                        <th style="text-align:center;">Horas (Real/Est.)</th>'
                                    ELSE '
                                        <th class="vct-actions-col" style="text-align:center;"></th>
                                        <th style="text-align:left;">Cliente</th>
                                        <th style="text-align:left;">Proyecto</th>
                                        <th style="text-align:center;">Estado</th>
                                        <th style="text-align:center;">Inicio</th>
                                        <th style="text-align:center;">Horas (Real/Est.)</th>'
                                    END + '
                                </tr>
                            </thead>
                            <tbody>' + 
                                CASE WHEN @V_SOLAPA = 'PLAN' THEN ISNULL(@HTML_TABLA_PLANIFICA, '') 
                                     ELSE ISNULL(@HTML_TABLA_PROYECTOS, '') 
                                END + '
                            </tbody>
                        </table>
                    </div>
 
                    <div class="vct-table-footer">' + ISNULL(@HTML_PAGINADOR, '') + '</div>
                </div>
            </div>
        </div>
    </div>';
 
    -- OUTPUT @OTABS CON HELPER VCTTABLE INTEGRADODINÁMICO
    SET @OTABS = '
    <input type="hidden" name="SP.NRO_PAGINA">
    <input type="hidden" name="SP.BUFFER">
    <input type="hidden" name="SP.FILTRO">
    <input type="hidden" name="SP.TAB">
    <input type="hidden" name="SP.TAB_SERV">
    <input type="hidden" name="SP.TAB_AGENDA">
    <input type="hidden" name="SP.PROYECTO">
    <input type="hidden" name="SP.PROYECTO_ID">
    <input type="hidden" name="SP.PROYECTO_SERV_ID">
    <input type="hidden" name="SP.CLIENTE">
    <input type="hidden" name="SP.AGENDA_ID">
 
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
 
    <script>
        function vctNavegarConParametros(formId, targetGuid, params) {
            localStorage.setItem("HOME_PLANIFICACION_OPEN", "1");
 
            if (params && typeof params === "object") {
                Object.keys(params).forEach(function (key) {
                    var inputElem = document.querySelector(''input[name="SP.'' + key + ''"]'');
                    if (inputElem) {
                        inputElem.value = params[key];
                    }
                });
            }
 
            if (typeof goto === "function") {
                goto(formId, targetGuid);
            } else {
                console.error("Mühle Engine: Función goto() no encontrada.");
            }
 
            return false;
        }
 
        /* HELPER VCTTABLE PARALELA Y COMPATIBLE */
        function vctToggleActionMenu(btn, e) {
            if (e) {
                e.preventDefault();
                e.stopPropagation();
            }
            var wrap = btn.closest(".vct-action-menu-wrap");
            var row = btn.closest(".vct-main-row");
            if (!wrap) return false;
 
            var isCurrentlyActive = wrap.classList.contains("active");
 
            // Limpiar estados activos de todas las filas y menús
            document.querySelectorAll(".vct-action-menu-wrap.active").forEach(function(m) {
                m.classList.remove("active");
            });
            document.querySelectorAll(".vct-main-row.vct-row-active").forEach(function(r) {
                r.classList.remove("vct-row-active");
            });
 
            if (!isCurrentlyActive) {
                wrap.classList.add("active");
                if (row) row.classList.add("vct-row-active");
            }
 
            return false;
        }
 
        document.addEventListener("click", function(e) {
            if (!e.target.closest(".vct-action-menu-wrap")) {
                document.querySelectorAll(".vct-action-menu-wrap.active").forEach(function(m) {
                    m.classList.remove("active");
                });
                document.querySelectorAll(".vct-main-row.vct-row-active").forEach(function(r) {
                    r.classList.remove("vct-row-active");
                });
            }
        });
 
        function vctInitPlanificacionState() {
            var panel = document.getElementById("vctPlanificacion");
            if (!panel) return;
 
            var state = localStorage.getItem("HOME_PLANIFICACION_OPEN");
 
            if (state === null || state === "1") {
                panel.classList.add("active");
            } else {
                panel.classList.remove("active");
            }
        }
 
        function vctTogglePlanificacion(btn) {
            var panel = document.getElementById("vctPlanificacion");
            if (!panel) return false;
            panel.classList.toggle("active");
            localStorage.setItem("HOME_PLANIFICACION_OPEN", panel.classList.contains("active") ? "1" : "0");
            return false;
        }
 
        function vctToggleRowDetail(rowId, btn) {
            var detailRow = document.getElementById("vctDetail_" + rowId);
            if (!detailRow) return false;
 
            var svgPlus = ''<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/></svg>'';
            var svgMinus = ''<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 12h8"/></svg>'';
 
            if (detailRow.style.display === "none" || detailRow.style.display === "") {
                detailRow.style.display = "table-row";
                if (btn) {
                    btn.innerHTML = svgMinus;
                    btn.title = "Ocultar detalle";
                }
            } else {
                detailRow.style.display = "none";
                if (btn) {
                    btn.innerHTML = svgPlus;
                    btn.title = "Ver detalle";
                }
            }
            return false;
        }
 
        function vctHighlightLegend(legendContainerId, activeIndex) {
            var container = document.getElementById(legendContainerId);
            if (!container) return;
            var items = container.querySelectorAll("li");
 
            items.forEach(function(item, idx) {
                if (activeIndex === null || activeIndex === undefined) {
                    item.classList.remove("vct-legend-active", "vct-legend-dimmed");
                } else if (idx === activeIndex) {
                    item.classList.add("vct-legend-active");
                    item.classList.remove("vct-legend-dimmed");
                } else {
                    item.classList.remove("vct-legend-active");
                    item.classList.add("vct-legend-dimmed");
                }
            });
        }
 
        function vctRenderPieChart(canvasId, legendId, dataList) {
            var canvas = document.getElementById(canvasId);
            var legend = document.getElementById(legendId);
            if (!canvas || !dataList || !dataList.length) return;
 
            var labels = dataList.map(function(d) { return d.label; });
            var values = dataList.map(function(d) { return d.value; });
            var colors = ["#66062D", "#2563eb", "#059669", "#d97706", "#8b5cf6", "#dc2626"];
 
            if (legend) {
                var html = "<ul>";
                dataList.forEach(function(item, i) {
                    var color = colors[i % colors.length];
                    html += "<li data-index=''" + i + "''>" +
                                "<span style=''display:inline-block;width:10px;height:10px;border-radius:50%;background-color:" + color + ";margin-right:6px;''></span>" +
                                "<span>" + item.label + "</span>: <strong>" + item.value + "</strong>" +
                            "</li>";
                });
                html += "</ul>";
                legend.innerHTML = html;
            }
 
            var existingChart = Chart.getChart(canvasId);
            if (existingChart) existingChart.destroy();
 
            new Chart(canvas, {
                type: "pie",
                data: {
                    labels: labels,
                    datasets: [{
                        data: values,
                        backgroundColor: colors.slice(0, values.length),
                        borderWidth: 2,
                        borderColor: "#ffffff"
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    onHover: function(event, activeElements) {
                        if (activeElements && activeElements.length > 0) {
                            vctHighlightLegend(legendId, activeElements[0].index);
                        } else {
                            vctHighlightLegend(legendId, null);
                        }
                    }
                }
            });
        }
 
        function vctRenderBarChart(canvasId, legendId, dataList) {
            var canvas = document.getElementById(canvasId);
            var legend = document.getElementById(legendId);
            if (!canvas || !dataList || !dataList.length) return;
 
            var labels = dataList.map(function(d) { return d.label; });
            var values = dataList.map(function(d) { return d.value; });
            var colors = ["#66062D", "#2563eb", "#059669", "#d97706", "#8b5cf6", "#dc2626"];
 
            if (legend) {
                var html = "<ul>";
                dataList.forEach(function(item, i) {
                    var color = colors[i % colors.length];
                    html += "<li data-index=''" + i + "''>" +
                                "<span style=''display:inline-block;width:10px;height:10px;border-radius:50%;background-color:" + color + ";margin-right:6px;''></span>" +
                                "<span>" + item.label + "</span>: <strong>" + item.value + "</strong>" +
                            "</li>";
                });
                html += "</ul>";
                legend.innerHTML = html;
            }
 
            var existingChart = Chart.getChart(canvasId);
            if (existingChart) existingChart.destroy();
 
            new Chart(canvas, {
                type: "bar",
                data: {
                    labels: labels,
                    datasets: [{
                        data: values,
                        backgroundColor: colors.slice(0, values.length),
                        borderRadius: 6
                    }]
                },
                options: {
                    indexAxis: "y",
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { display: false },
                        y: { grid: { display: false }, ticks: { font: { size: 11, family: "Gotham" } } }
                    },
                    onHover: function(event, activeElements) {
                        if (activeElements && activeElements.length > 0) {
                            vctHighlightLegend(legendId, activeElements[0].index);
                        } else {
                            vctHighlightLegend(legendId, null);
                        }
                    }
                }
            });
        }
 
        setTimeout(vctInitPlanificacionState, 100);
 
        var vocDataEstados = ' + CONVERT(VARCHAR(MAX), @JSON_ESTADOS) + ';
        var vocDataServicios = ' + CONVERT(VARCHAR(MAX), @JSON_SERVICIOS) + ';
 
        setTimeout(function() {
            vctRenderPieChart("estadoChart", "estadoLegend", vocDataEstados);
            vctRenderBarChart("servicioChart", "servicioLegend", vocDataServicios);
        }, 150);
    </script>';
 
    UPDATE XAGENDA
    SET SERVICIO = NULL,
        ESTADO = NULL,
        INICIO_CLIENTE = NULL
    WHERE PAR_KEY = @IPKEYJOB;
 
END
