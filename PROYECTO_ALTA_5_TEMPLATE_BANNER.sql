/* ========================================================================
   PROYECTO_ALTA_5_TEMPLATE_BANNER
   ------------------------------------------------------------------------
   Template PROYECTO_ANALISTA_ASIGNADO armado con el MISMO formato que los
   templates que ya funcionan (TEST2, TEST3, VCT_MAIL_1, CASO-9): estructura
   del editor de Configuracion > Templates de email (celda
   data-vct-email-content) y banner bordo del servidor con URL absoluta.
   Asi se puede seguir editando desde el editor.
   Destino de prueba: el mismo de TEST3 (Martin y Esteban).
   ======================================================================== */
USE [MuhlePROD];
GO

UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES
   SET DESTINO_TIPO  = 'LIBRE',
       DESTINO_LIBRE = 'martin.aja@squad.com.ar; esteban.de.marco@squad.com.ar',
       CC_TIPO       = 'NINGUNO',
       CC_LIBRE      = NULL,
       HTML_CONTENIDO =
       '<!doctype html><html><head><meta charset="utf-8"><style>html,body{overflow-x:hidden;}</style></head>'
     + '<body style="margin:0;padding:0;background:#f3f5f7;">'
     + '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:#f3f5f7;padding:24px 0;"><tr><td align="center">'
     + '<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:600px;max-width:94%;background:#ffffff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;"><tr>'
     + '<td data-vct-email-content style="padding:20px 24px;color:#263247;font-family:Arial,sans-serif;font-size:14px;line-height:1.6;">'
     + '<img src="https://vocaturo.desa.interdev.online/img/vct-mail-banner-Bordeaux.png" alt="" width="600" height="90" style="max-width:100%;width:100%;height:auto;display:block;margin:0;">'
     + '<div><br></div>'
     + '<div style="font-size:17px;font-weight:bold;color:#66062D;">Nuevo proyecto asignado</div>'
     + '<div><br></div>'
     + '<div>Hola {{ANALISTA}},</div>'
     + '<div>Se te asign&oacute; como analista del proyecto <b>({{CODIGO_PROYECTO}}) {{PROYECTO}}</b> del cliente <b>{{CLIENTE}}</b>.</div>'
     + '<div><br></div>'
     + '<div><b>Servicios:</b> {{SERVICIOS}}</div>'
     + '<div><b>Normas:</b> {{NORMAS}}</div>'
     + '<div><b>Fecha l&iacute;mite de lanzamiento:</b> {{FECHA_LANZAMIENTO}}</div>'
     + '<div><br></div>'
     + '<div>Pr&oacute;ximos pasos: asignar el/los consultores, completar los datos de entrada (riesgos iniciales, acciones y consideraciones) y organizar la reuni&oacute;n de lanzamiento antes de esa fecha.</div>'
     + '<div><br></div>'
     + '<div>Pod&eacute;s verlo en <a href="https://vocaturo.desa.interdev.online/main/">https://vocaturo.desa.interdev.online/main/</a></div>'
     + '<div><br></div>'
     + '<div style="color:#6b7280;font-size:12px;">Tambi&eacute;n ten&eacute;s la gesti&oacute;n pendiente en el sistema. Mail generado autom&aacute;ticamente el {{FECHA}} a las {{HORA}}.</div>'
     + '</td></tr></table>'
     + '</td></tr></table></body></html>',
       FECHA_UPD  = GETDATE(),
       USUARIO_UPD = 'PROYECTO_ALTA'
 WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PROYECTO_ANALISTA_ASIGNADO';

SELECT CODIGO, DESTINO_TIPO, DESTINO_LIBRE, CC_TIPO, LEN(HTML_CONTENIDO) AS LARGO_HTML
FROM dbo.VCT_PRM_EMAIL_TEMPLATES
WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PROYECTO_ANALISTA_ASIGNADO';
GO
