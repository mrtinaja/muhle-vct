/* preview_agenda_html.sql
   Reproduce el mismo armado de {{AGENDA}} de VCT_MAIN_SEND_EMAIL, pero con
   un rango de fechas elegido a mano en vez de "mes en curso" -- solo para
   ver el HTML resultante con datos reales, ya que en este ambiente (desa)
   no hay visitas cargadas para el mes actual. No modifica nada. */

DECLARE @ID_CONSULTOR INT = 19;          -- <-- cambia por el consultor que quieras probar
DECLARE @DESDE DATE = '2026-01-01';      -- <-- rango de prueba (Nowak tiene visita el 2026-01-13)
DECLARE @HASTA DATE = '2026-02-01';

DECLARE @AGENDA_ITEMS VARCHAR(MAX) = '';

SELECT @AGENDA_ITEMS = @AGENDA_ITEMS + '<li>' +
        REPLACE(REPLACE(REPLACE(ISNULL(CL.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
        ' &ndash; ' +
        REPLACE(REPLACE(REPLACE(ISNULL(PR.NOMBRE,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
        '</li>'
FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK)
INNER JOIN dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK) ON V.ID = VC.IDVISITA
LEFT JOIN dbo.VCT_CLIENTES CL WITH(NOLOCK) ON CL.ID = V.IDCLIENTE
LEFT JOIN dbo.VCT_PROYECTOS PR WITH(NOLOCK) ON PR.ID = V.IDPROYECTO
WHERE VC.IDCONSULTOR = @ID_CONSULTOR
  AND V.FECHA_DESDE >= @DESDE
  AND V.FECHA_DESDE < @HASTA
ORDER BY V.FECHA_DESDE;

DECLARE @AGENDA_HTML VARCHAR(MAX) =
    CASE WHEN @AGENDA_ITEMS = '' THEN 'Sin visitas programadas este mes.'
         ELSE '<ul style="margin:0;padding-left:18px;">' + @AGENDA_ITEMS + '</ul>'
    END;

SELECT @AGENDA_HTML AS AGENDA_HTML_RESULTANTE;
