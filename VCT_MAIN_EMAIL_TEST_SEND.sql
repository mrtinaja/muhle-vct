USE [MuhlePROD]
GO

-- Si no sabés el nombre de tu perfil de Database Mail, primero corré:
-- SELECT name FROM msdb.dbo.sysmail_profile;

DECLARE @CODIGO        VARCHAR(50)  = 'VCT_MAIL_1';   -- codigo del template a probar
DECLARE @DESTINATARIO  VARCHAR(400) = 'martin.aja@squad.com.ar'; -- destinatario de prueba
DECLARE @PROFILE_NAME  VARCHAR(200) = 'NOMBRE_DEL_PERFIL'; -- <-- completar con tu perfil de Database Mail

DECLARE @T TABLE (
    ID INT, CODIGO VARCHAR(50), DESCRIPCION VARCHAR(200), TIPO_ENVIO VARCHAR(20),
    DESTINO_TIPO VARCHAR(20), DESTINO_LIBRE VARCHAR(400),
    CC_TIPO VARCHAR(20), CC_LIBRE VARCHAR(400),
    ESTADO VARCHAR(20), ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX)
);

INSERT INTO @T
EXEC dbo.VCT_MAIN_EMAIL_TEMPLATE_GET @CODIGO = @CODIGO;

DECLARE @ASUNTO VARCHAR(500), @BODY VARCHAR(MAX);
SELECT @ASUNTO = ASUNTO, @BODY = HTML_CONTENIDO FROM @T;

IF @BODY IS NULL
BEGIN
    RAISERROR('No se encontro el template %s.', 16, 1, @CODIGO);
    RETURN;
END

/* Reemplazo de variables por datos de prueba
   (mismo listado que el panel "Variables disponibles" del editor) */
SET @ASUNTO = REPLACE(@ASUNTO, '{{NOMBRE}}',    'Juan');
SET @ASUNTO = REPLACE(@ASUNTO, '{{APELLIDO}}',  'Perez');
SET @ASUNTO = REPLACE(@ASUNTO, '{{EMAIL}}',     'juan.perez@ejemplo.com');
SET @ASUNTO = REPLACE(@ASUNTO, '{{PROYECTO}}',  'Proyecto de prueba');
SET @ASUNTO = REPLACE(@ASUNTO, '{{SERVICIO}}',  'Consultoria');
SET @ASUNTO = REPLACE(@ASUNTO, '{{ANALISTA}}',  'Garcia, Maria');
SET @ASUNTO = REPLACE(@ASUNTO, '{{GERENCIA}}',  'Gerencia de Operaciones');
SET @ASUNTO = REPLACE(@ASUNTO, '{{CONSULTOR}}', 'Lopez, Carlos');
SET @ASUNTO = REPLACE(@ASUNTO, '{{CLIENTE}}',   'Cliente de prueba S.A.');
SET @ASUNTO = REPLACE(@ASUNTO, '{{FECHA}}',     CONVERT(VARCHAR(10), GETDATE(), 103));
SET @ASUNTO = REPLACE(@ASUNTO, '{{HORA}}',      CONVERT(VARCHAR(5), GETDATE(), 108));

-- {{AGENDA}} es HTML (una grilla de calendario): solo tiene sentido en el
-- cuerpo, no en el asunto. Muestra de prueba con 2 dias resaltados, no un
-- mes completo -- alcanza para chequear el estilo visual (mismo look que
-- el calendario de feriados de VCT_MAIN_CALENDARIO).
DECLARE @AGENDA_PRUEBA VARCHAR(MAX) =
    '<div style="font-size:13px;font-weight:700;color:#1a1a1a;margin-bottom:8px;">Septiembre 2026</div>' +
    '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;width:100%;">' +
    '<tr>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Dom</th>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Lun</th>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Mar</th>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Mie</th>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Jue</th>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Vie</th>' +
    '<th style="width:14%;padding:4px;font-size:10px;color:#8a8a8a;">Sab</th>' +
    '</tr><tr>' +
    '<td style="width:14%;height:60px;padding:4px;border:1px solid #ececec;background:#fff;"></td>' +
    '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#fafafa;font-size:11px;color:#8a8a8a;">1</td>' +
    '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#66062D;"><div style="font-size:11px;font-weight:700;color:#fff;">2</div><div style="font-size:9.5px;line-height:1.25;color:#fff;margin-top:2px;">Cliente de prueba S.A.</div></td>' +
    '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#fafafa;font-size:11px;color:#8a8a8a;">3</td>' +
    '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#66062D;"><div style="font-size:11px;font-weight:700;color:#fff;">4</div><div style="font-size:9.5px;line-height:1.25;color:#fff;margin-top:2px;">Otro Cliente S.A.</div></td>' +
    '<td style="width:14%;height:60px;padding:4px;vertical-align:top;border:1px solid #ececec;background:#fafafa;font-size:11px;color:#8a8a8a;">5</td>' +
    '<td style="width:14%;height:60px;padding:4px;border:1px solid #ececec;background:#fff;"></td>' +
    '</tr></table>';

SET @BODY = REPLACE(@BODY, '{{NOMBRE}}',    'Juan');
SET @BODY = REPLACE(@BODY, '{{APELLIDO}}',  'Perez');
SET @BODY = REPLACE(@BODY, '{{EMAIL}}',     'juan.perez@ejemplo.com');
SET @BODY = REPLACE(@BODY, '{{PROYECTO}}',  'Proyecto de prueba');
SET @BODY = REPLACE(@BODY, '{{SERVICIO}}',  'Consultoria');
SET @BODY = REPLACE(@BODY, '{{ANALISTA}}',  'Garcia, Maria');
SET @BODY = REPLACE(@BODY, '{{GERENCIA}}',  'Gerencia de Operaciones');
SET @BODY = REPLACE(@BODY, '{{CONSULTOR}}', 'Lopez, Carlos');
SET @BODY = REPLACE(@BODY, '{{CLIENTE}}',   'Cliente de prueba S.A.');
SET @BODY = REPLACE(@BODY, '{{FECHA}}',     CONVERT(VARCHAR(10), GETDATE(), 103));
SET @BODY = REPLACE(@BODY, '{{HORA}}',      CONVERT(VARCHAR(5), GETDATE(), 108));
SET @BODY = REPLACE(@BODY, '{{AGENDA}}',    @AGENDA_PRUEBA);

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = @PROFILE_NAME,
    @recipients   = @DESTINATARIO,
    @subject      = @ASUNTO,
    @body         = @BODY,
    @body_format  = 'HTML';
