 
/* ============================================================================
   VCT_MAIN_SEND_EMAIL
   ----------------------------------------------------------------------------
   Dado el codigo de un template (dbo.VCT_PRM_EMAIL_TEMPLATES) y, opcionalmente,
   los IDs de las entidades involucradas en el envio, resuelve de forma
   dinamica:
     - El destinatario final (segun DESTINO_TIPO del template) y su CC.
     - El reemplazo de las variables {{...}} del ASUNTO y del HTML_CONTENIDO
       con los datos reales de esas entidades.
 
   Parametros (todos menos @CODIGO son opcionales; solo se resuelven las
   variables cuyo ID correspondiente fue informado):
     @CODIGO        - codigo del template a usar (obligatorio)
     @ID_CONSULTOR  - VCT_CONSULTORES.ID  -> resuelve {{CONSULTOR}} y {{AGENDA}}
                       ({{AGENDA}} = grilla de calendario mensual (mes en
                       curso) con los dias que tienen visita resaltados en
                       bordo y el/los cliente(s) de cada una adentro de la
                       celda -- mismo lenguaje visual que el calendario de
                       feriados de VCT_MAIN_CALENDARIO. Solo se reemplaza en
                       el cuerpo del mail, nunca en el asunto, porque es HTML.)
     @ID_PROYECTO   - VCT_PROYECTOS.ID    -> resuelve {{PROYECTO}}
     @ID_ANALISTA   - VCT_EMPLEADOS.ID    -> resuelve {{ANALISTA}}
     @ID_CLIENTE    - VCT_CLIENTES.ID     -> resuelve {{CLIENTE}}
     @PROFILE_NAME  - perfil de Database Mail. Si se informa, el SP ADEMAS
                       envia el mail con sp_send_dbmail. Si se omite (NULL,
                       default), el SP solo resuelve y devuelve los datos
                       sin enviar nada (modo preview/consulta).
 
   {{FECHA}}/{{HORA}}/{{MES}}/{{ANIO}} siempre se resuelven, con la fecha/hora
   del momento del envio (no dependen de ningun @ID). {{MES}} va en letras
   (ej. "Septiembre"), {{ANIO}} con 4 digitos (ej. "2026").
 
   Variables NO resueltas por este SP (quedan tal cual en el texto si no se
   reemplazan a mano antes de enviar):
     {{SERVICIO}}  - no se pidio un @ID_SERVICIO; sumar cuando se necesite.
     {{GERENCIA}}  - no tiene entidad/ID asociado en el modelo actual.
     {{AGENDA}}    - si no se paso @ID_CONSULTOR, queda tal cual.
 
   El email de cada entidad se resuelve contra dbo.VCT_EMAILS (patron
   polimorfico TIPO_ENTIDAD + ID_ENTIDAD), tomando el marcado PRINCIPAL='SI'
   si existe, sino el primero por ID.
   ============================================================================ */
CREATE   PROCEDURE [dbo].[VCT_MAIN_SEND_EMAIL]
 
    @CODIGO        VARCHAR(50),
    @ID_CONSULTOR  INT = NULL,
    @ID_PROYECTO   INT = NULL,
    @ID_ANALISTA   INT = NULL,
    @ID_CLIENTE    INT = NULL,
    @PROFILE_NAME  VARCHAR(200) = NULL
 
 
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ASUNTO        VARCHAR(500),
            @BODY          VARCHAR(MAX),
            @DESTINO_TIPO  VARCHAR(20),
            @DESTINO_LIBRE VARCHAR(1000),
            @CC_TIPO       VARCHAR(20),
            @CC_LIBRE      VARCHAR(1000),
            @ESTADO        VARCHAR(20);
 
 
    SELECT
        @ASUNTO=ASUNTO, @BODY=HTML_CONTENIDO,
        @DESTINO_TIPO=DESTINO_TIPO, @DESTINO_LIBRE=DESTINO_LIBRE,
        @CC_TIPO=CC_TIPO, @CC_LIBRE=CC_LIBRE, @ESTADO=ESTADO
    FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK)
    WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT =
          UPPER(LTRIM(RTRIM(@CODIGO))) COLLATE DATABASE_DEFAULT;
 
    IF @ASUNTO IS NULL
    BEGIN
        SELECT
            CAST(NULL AS VARCHAR(500))  AS ASUNTO,
            CAST(NULL AS VARCHAR(MAX))  AS HTML_CONTENIDO,
            CAST(NULL AS VARCHAR(1000)) AS DESTINATARIO,
            CAST(NULL AS VARCHAR(1000)) AS CC,
            'No existe un template con codigo '+@CODIGO AS ERROR_MSG;
        RETURN;
    END
 
    -- ---------- Consultor ----------
    DECLARE @CONSULTOR_NOMBRES VARCHAR(300), @CONSULTOR_APELLIDOS VARCHAR(300), @CONSULTOR_EMAIL VARCHAR(100);
    IF @ID_CONSULTOR IS NOT NULL
    BEGIN
        SELECT @CONSULTOR_NOMBRES=NOMBRES, @CONSULTOR_APELLIDOS=APELLIDOS
        FROM dbo.VCT_CONSULTORES WITH(NOLOCK) WHERE ID=@ID_CONSULTOR;
 
        SELECT TOP 1 @CONSULTOR_EMAIL=EMAIL
        FROM dbo.VCT_EMAILS WITH(NOLOCK)
        WHERE TIPO_ENTIDAD='CONSULTOR' AND ID_ENTIDAD=@ID_CONSULTOR
        ORDER BY CASE WHEN PRINCIPAL='SI' THEN 0 ELSE 1 END, ID;
    END
 
    -- ---------- Agenda del consultor: grilla de calendario mensual con las
    -- visitas del mes en curso (mismo lenguaje visual que el calendario de
    -- feriados de VCT_MAIN_CALENDARIO, pero con clientes en vez de feriados).
    -- Se arma con <table> (no grid/flex: Outlook renderiza con el motor de
    -- Word y no los soporta) reusando dbo.Calendar para no calcular semanas
    -- ni dias del mes a mano.
    DECLARE @AGENDA_HTML VARCHAR(MAX);
    IF @ID_CONSULTOR IS NOT NULL
    BEGIN
        DECLARE @MES_DESDE DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        DECLARE @MES_HASTA DATE = DATEADD(MONTH, 1, @MES_DESDE);
        DECLARE @MES_NOMBRE VARCHAR(20), @MES_ANIO VARCHAR(4);
        SELECT @MES_NOMBRE = MesNombre, @MES_ANIO = CAST(Ano AS VARCHAR(4))
        FROM dbo.Calendar WHERE Fecha = @MES_DESDE;
 
        DECLARE @SemMin INT, @SemMax INT;
        SELECT @SemMin = MIN(SemanaMes), @SemMax = MAX(SemanaMes)
        FROM dbo.Calendar WHERE Fecha >= @MES_DESDE AND Fecha < @MES_HASTA;
 
        DECLARE @CAL_FILAS VARCHAR(MAX) = '';
        DECLARE @Sem INT = @SemMin;
        DECLARE @DiaSem INT, @CeldaFecha DATE, @CeldaDia INT, @CeldaVisitas VARCHAR(MAX);
 
        WHILE @Sem <= @SemMax
        BEGIN
            DECLARE @FILA VARCHAR(MAX) = '<tr>';
            SET @DiaSem = 1;
            WHILE @DiaSem <= 7
            BEGIN
                SELECT @CeldaFecha = Fecha, @CeldaDia = Dia
                FROM dbo.Calendar
                WHERE Fecha >= @MES_DESDE AND Fecha < @MES_HASTA
                  AND SemanaMes = @Sem AND DiaSemana = @DiaSem;
 
                IF @CeldaFecha IS NULL
                    SET @FILA = @FILA + '<td style="width:14%;height:60px;padding:4px;border:1px solid #ececec;background:#fff;"></td>';
                ELSE
                BEGIN
                    SET @CeldaVisitas = '';
                    SELECT @CeldaVisitas = @CeldaVisitas +
                            CASE WHEN @CeldaVisitas = '' THEN '' ELSE '<br>' END +
                            REPLACE(REPLACE(REPLACE(ISNULL(CL.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;')
                    FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK)
                    INNER JOIN dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK) ON V.ID = VC.ID_VISITA
                    LEFT JOIN dbo.VCT_PROYECTOS PRV WITH(NOLOCK) ON PRV.ID = V.ID_PROYECTO LEFT JOIN dbo.VCT_CLIENTES CL WITH(NOLOCK) ON CL.ID = PRV.IDCLIENTE
                    WHERE VC.ID_CONSULTOR = @ID_CONSULTOR
                      AND CAST(V.FECHA_DESDE AS DATE) = @CeldaFecha;
 
                    IF @CeldaVisitas = ''
                        SET @FILA = @FILA +
                            '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#fafafa;font-size:11px;color:#8a8a8a;">' +
                            CAST(@CeldaDia AS VARCHAR(2)) + '</td>';
                    ELSE
                        SET @FILA = @FILA +
                            '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#66062D;">' +
                            '<div style="font-size:11px;font-weight:700;color:#fff;">' + CAST(@CeldaDia AS VARCHAR(2)) + '</div>' +
                            '<div style="font-size:9.5px;line-height:1.25;color:#fff;margin-top:2px;">' + @CeldaVisitas + '</div>' +
                            '</td>';
                END
 
                SET @CeldaFecha = NULL;
                SET @DiaSem = @DiaSem + 1;
            END
            SET @FILA = @FILA + '</tr>';
            SET @CAL_FILAS = @CAL_FILAS + @FILA;
            SET @Sem = @Sem + 1;
        END
 
        DECLARE @CAL_HEADER VARCHAR(MAX) =
            '<tr>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Dom</th>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Lun</th>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Mar</th>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Mie</th>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Jue</th>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Vie</th>' +
            '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Sab</th>' +
            '</tr>';
 
        SET @AGENDA_HTML =
            '<div style="font-size:13px;font-weight:700;color:#1a1a1a;margin-bottom:8px;">' + @MES_NOMBRE + ' ' + @MES_ANIO + '</div>' +
            '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;width:100%;">' +
            @CAL_HEADER + @CAL_FILAS + '</table>';
    END
 
    -- ---------- Analista (VCT_EMPLEADOS) ----------
    DECLARE @ANALISTA_NOMBRES VARCHAR(150), @ANALISTA_APELLIDOS VARCHAR(150), @ANALISTA_EMAIL VARCHAR(100);
    IF @ID_ANALISTA IS NOT NULL
    BEGIN
        SELECT @ANALISTA_NOMBRES=NOMBRES, @ANALISTA_APELLIDOS=APELLIDOS
        FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE ID=@ID_ANALISTA;
 
        SELECT TOP 1 @ANALISTA_EMAIL=EMAIL
        FROM dbo.VCT_EMAILS WITH(NOLOCK)
        WHERE TIPO_ENTIDAD='EMPLEADO' AND ID_ENTIDAD=@ID_ANALISTA
        ORDER BY CASE WHEN PRINCIPAL='SI' THEN 0 ELSE 1 END, ID;
    END
 
    -- ---------- Cliente ----------
    DECLARE @CLIENTE_RAZON_SOCIAL VARCHAR(300), @CLIENTE_EMAIL VARCHAR(100);
    IF @ID_CLIENTE IS NOT NULL
    BEGIN
        SELECT @CLIENTE_RAZON_SOCIAL=RAZON_SOCIAL
        FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID=@ID_CLIENTE;
 
        SELECT TOP 1 @CLIENTE_EMAIL=EMAIL
        FROM dbo.VCT_EMAILS WITH(NOLOCK)
        WHERE TIPO_ENTIDAD='CLIENTE' AND ID_ENTIDAD=@ID_CLIENTE
        ORDER BY CASE WHEN PRINCIPAL='SI' THEN 0 ELSE 1 END, ID;
    END
 
    -- ---------- Proyecto ----------
    DECLARE @PROYECTO_NOMBRE VARCHAR(300);
    IF @ID_PROYECTO IS NOT NULL
        SELECT @PROYECTO_NOMBRE=NOMBRE FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID=@ID_PROYECTO;
 
    -- ---------- Destinatario final segun DESTINO_TIPO del template ----------
    DECLARE @DESTINATARIO VARCHAR(1000),
            @DEST_NOMBRES VARCHAR(300),
            @DEST_APELLIDOS VARCHAR(300);
 
    SELECT
        @DESTINATARIO = CASE @DESTINO_TIPO
                            WHEN 'CONSULTOR' THEN @CONSULTOR_EMAIL
                            WHEN 'ANALISTA'  THEN @ANALISTA_EMAIL
                            WHEN 'CLIENTE'   THEN @CLIENTE_EMAIL
                            WHEN 'LIBRE'     THEN @DESTINO_LIBRE
                            ELSE NULL -- GERENCIA: sin entidad/ID asociado todavia
                        END,
        @DEST_NOMBRES = CASE @DESTINO_TIPO
                            WHEN 'CONSULTOR' THEN @CONSULTOR_NOMBRES
                            WHEN 'ANALISTA'  THEN @ANALISTA_NOMBRES
                            ELSE NULL
                        END,
        @DEST_APELLIDOS = CASE @DESTINO_TIPO
                            WHEN 'CONSULTOR' THEN @CONSULTOR_APELLIDOS
                            WHEN 'ANALISTA'  THEN @ANALISTA_APELLIDOS
                            ELSE NULL
                        END;
 
    -- ---------- CC (mismo criterio que el destinatario) ----------
    DECLARE @CC VARCHAR(1000);
    SELECT @CC = CASE @CC_TIPO
                    WHEN 'CONSULTOR' THEN @CONSULTOR_EMAIL
                    WHEN 'ANALISTA'  THEN @ANALISTA_EMAIL
                    WHEN 'CLIENTE'   THEN @CLIENTE_EMAIL
                    WHEN 'LIBRE'     THEN @CC_LIBRE
                    ELSE NULL -- NINGUNO o GERENCIA sin ID
                 END;
 
    -- ---------- Reemplazo de variables ----------
    DECLARE @FECHA VARCHAR(10) = CONVERT(VARCHAR(10), GETDATE(), 103),
            @HORA  VARCHAR(5)  = CONVERT(VARCHAR(5), GETDATE(), 108),
            @MES   VARCHAR(20) = CASE MONTH(GETDATE())
                                    WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
                                    WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
                                    WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
                                    WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
                                  END,
            @ANIO  VARCHAR(4)  = CONVERT(VARCHAR(4), YEAR(GETDATE()));
 
    SET @ASUNTO = REPLACE(@ASUNTO, '{{NOMBRE}}',    ISNULL(@DEST_NOMBRES,''));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{APELLIDO}}',  ISNULL(@DEST_APELLIDOS,''));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{EMAIL}}',     ISNULL(@DESTINATARIO,''));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{PROYECTO}}',  ISNULL(@PROYECTO_NOMBRE,''));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{ANALISTA}}',  LTRIM(RTRIM(ISNULL(@ANALISTA_APELLIDOS,'')+' '+ISNULL(@ANALISTA_NOMBRES,''))));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{CONSULTOR}}', LTRIM(RTRIM(ISNULL(@CONSULTOR_APELLIDOS,'')+' '+ISNULL(@CONSULTOR_NOMBRES,''))));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{CLIENTE}}',   ISNULL(@CLIENTE_RAZON_SOCIAL,''));
    SET @ASUNTO = REPLACE(@ASUNTO, '{{FECHA}}',     @FECHA);
    SET @ASUNTO = REPLACE(@ASUNTO, '{{HORA}}',      @HORA);
    SET @ASUNTO = REPLACE(@ASUNTO, '{{MES}}',       @MES);
    SET @ASUNTO = REPLACE(@ASUNTO, '{{ANIO}}',      @ANIO);
 
    SET @BODY = REPLACE(@BODY, '{{NOMBRE}}',    ISNULL(@DEST_NOMBRES,''));
    SET @BODY = REPLACE(@BODY, '{{APELLIDO}}',  ISNULL(@DEST_APELLIDOS,''));
    SET @BODY = REPLACE(@BODY, '{{EMAIL}}',     ISNULL(@DESTINATARIO,''));
    SET @BODY = REPLACE(@BODY, '{{PROYECTO}}',  ISNULL(@PROYECTO_NOMBRE,''));
    SET @BODY = REPLACE(@BODY, '{{ANALISTA}}',  LTRIM(RTRIM(ISNULL(@ANALISTA_APELLIDOS,'')+' '+ISNULL(@ANALISTA_NOMBRES,''))));
    SET @BODY = REPLACE(@BODY, '{{CONSULTOR}}', LTRIM(RTRIM(ISNULL(@CONSULTOR_APELLIDOS,'')+' '+ISNULL(@CONSULTOR_NOMBRES,''))));
    SET @BODY = REPLACE(@BODY, '{{CLIENTE}}',   ISNULL(@CLIENTE_RAZON_SOCIAL,''));
    SET @BODY = REPLACE(@BODY, '{{FECHA}}',     @FECHA);
    SET @BODY = REPLACE(@BODY, '{{HORA}}',      @HORA);
    SET @BODY = REPLACE(@BODY, '{{MES}}',       @MES);
    SET @BODY = REPLACE(@BODY, '{{ANIO}}',      @ANIO);
 
    -- {{AGENDA}} es HTML (una lista) -- solo tiene sentido reemplazarla en el
    -- cuerpo, nunca en el asunto. Si no se paso @ID_CONSULTOR, el token
    -- queda tal cual (mismo criterio que {{SERVICIO}}/{{GERENCIA}}).
    IF @ID_CONSULTOR IS NOT NULL
        SET @BODY = REPLACE(@BODY, '{{AGENDA}}', @AGENDA_HTML);
 
    DECLARE @ADVERTENCIA VARCHAR(500) =
        CASE WHEN @DESTINATARIO IS NULL THEN 'No se pudo resolver el destinatario (revisar IDs pasados vs. DESTINO_TIPO="'+ISNULL(@DESTINO_TIPO,'')+'" del template).'
             WHEN @BODY LIKE '%{{%}}%' OR @ASUNTO LIKE '%{{%}}%' THEN 'El asunto o el cuerpo contienen variables sin resolver (ej. {{SERVICIO}}, {{GERENCIA}} o {{AGENDA}} sin @ID_CONSULTOR).'
             ELSE NULL
        END;
 
    -- ---------- Envio (solo si se informo @PROFILE_NAME) ----------
    DECLARE @ENVIADO BIT = 0;
    IF @PROFILE_NAME IS NOT NULL
    BEGIN
        IF @DESTINATARIO IS NULL
            SET @ADVERTENCIA = ISNULL(@ADVERTENCIA,'')+' No se envio: falta destinatario.';
        ELSE
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name      = @PROFILE_NAME,
                @recipients        = @DESTINATARIO,
                @copy_recipients   = @CC,
                @subject           = @ASUNTO,
                @body              = @BODY,
                @body_format       = 'HTML';
            SET @ENVIADO = 1;
        END;
    END;
 
    SELECT
        @ASUNTO       AS ASUNTO,
        @BODY         AS HTML_CONTENIDO,
        @DESTINATARIO AS DESTINATARIO,
        @CC           AS CC,
        @ENVIADO      AS ENVIADO,
        @ADVERTENCIA  AS ADVERTENCIA;
END
