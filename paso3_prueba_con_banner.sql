/* =============================================================================
   VOCATURO - PRUEBA: remitente 'Vocaturo' + banner de encabezado
   ============================================================================= */

DECLARE @VBODY NVARCHAR(MAX) = N'<p>Si el banner ocupa todo el ancho y ves la leyenda "720 x 110 px" nítida abajo a la derecha, está renderizando a tamaño real.</p>';

/* Cache-buster: Gmail (y otros clientes) cachean la imagen por URL exacta.
   Como venimos probando siempre con la misma URL, si ya la habían
   descargado una vez siguen mostrando esa copia vieja aunque el archivo
   del servidor cambie. Agregar ?v=<timestamp> hace que cada envío sea
   una URL "nueva" y fuerza la descarga fresca. Útil solo para testear:
   en el uso real (una sola vez por mail, a destinatarios que no repiten
   la misma imagen en loop) esto no hace falta. */
DECLARE @CacheBuster VARCHAR(30) = CONVERT(VARCHAR(30), GETDATE(), 120);
SET @CacheBuster = REPLACE(REPLACE(REPLACE(@CacheBuster,'-',''),':',''),' ','');

/* Tabla en vez de div: es el patrón estándar para email porque Outlook de
   escritorio (motor Word) ignora buena parte del CSS de bloques normales
   pero sí respeta ancho/alto de tablas e imágenes. width="100%" en la tabla
   +  max-width en el estilo hacen que ocupe todo el ancho disponible del
   mail sin pasarse del tamaño real del banner (720px). */
SET @VBODY =
    N'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:720px;margin:0 0 18px 0;">' +
        N'<tr><td>' +
            N'<img src="https://vocaturo.desa.interdev.online/img/vct-mail.png?v=' + @CacheBuster + N'" ' +
                 N'alt="Vocaturo" width="720" ' +
                 N'style="width:100%;max-width:720px;height:auto;display:block;border:0;" />' +
        N'</td></tr>' +
    N'</table>' +
    @VBODY;

EXEC msdb.dbo.sp_send_dbmail
     @profile_name = 'VocaturoProfile',
     @recipients   = 'martin.aja@squad.com.ar',
     @subject      = 'Prueba remitente + banner Vocaturo',
     @body         = @VBODY,
     @body_format  = 'HTML';
