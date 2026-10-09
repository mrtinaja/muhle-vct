/* ========================================================================
   MAILS_DESTINO_ESTEBAN  (CAMBIA DATOS: VCT_PRM_EMAIL_TEMPLATES)
   ------------------------------------------------------------------------
   Las plantillas de mail en modo prueba (destino LIBRE) mandaban a
   esteban.de.marco@squad.com.ar. La direccion correcta de Esteban es
   e.de.marco@squad.com.ar. Se corrige en destino y copia de todas las
   plantillas que la tengan. Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

SELECT CODIGO, DESTINO_TIPO, DESTINO_LIBRE, CC_LIBRE
FROM dbo.VCT_PRM_EMAIL_TEMPLATES
WHERE DESTINO_LIBRE LIKE '%esteban.de.marco%' OR CC_LIBRE LIKE '%esteban.de.marco%';

UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES
   SET DESTINO_LIBRE = REPLACE(DESTINO_LIBRE, 'esteban.de.marco@squad.com.ar', 'e.de.marco@squad.com.ar'),
       CC_LIBRE      = REPLACE(CC_LIBRE,      'esteban.de.marco@squad.com.ar', 'e.de.marco@squad.com.ar')
 WHERE DESTINO_LIBRE LIKE '%esteban.de.marco%' OR CC_LIBRE LIKE '%esteban.de.marco%';
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' plantillas corregidas.';

SELECT CODIGO, DESTINO_TIPO, DESTINO_LIBRE, CC_LIBRE
FROM dbo.VCT_PRM_EMAIL_TEMPLATES
WHERE DESTINO_LIBRE LIKE '%de.marco%' OR CC_LIBRE LIKE '%de.marco%';
GO
