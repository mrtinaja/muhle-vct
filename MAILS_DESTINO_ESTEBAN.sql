/* ========================================================================
   MAILS_DESTINO_ESTEBAN  (CAMBIA DATOS: VCT_PRM_EMAIL_TEMPLATES)
   ------------------------------------------------------------------------
   La direccion de Esteban para los mails en modo prueba (destino LIBRE) es
   esteban.de.marco@squad.com.ar. La plantilla PROYECTO_ANALISTA_ASIGNADO
   pudo quedar con e.de.marco@squad.com.ar (PROYECTO_ALTA_4). Se corrige en
   destino y copia de todas las plantillas. Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* antes */
SELECT CODIGO, DESTINO_TIPO, DESTINO_LIBRE, CC_LIBRE
FROM dbo.VCT_PRM_EMAIL_TEMPLATES
WHERE DESTINO_LIBRE LIKE '%de.marco%' OR CC_LIBRE LIKE '%de.marco%';

/* ';' o espacio delante evita tocar la direccion buena (esteban.de.marco) */
UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES
   SET DESTINO_LIBRE = LTRIM(REPLACE(REPLACE(';' + DESTINO_LIBRE, ';e.de.marco@squad.com.ar', ';esteban.de.marco@squad.com.ar'), ' e.de.marco@squad.com.ar', ' esteban.de.marco@squad.com.ar')),
       CC_LIBRE      = CASE WHEN CC_LIBRE IS NULL THEN NULL
                            ELSE LTRIM(REPLACE(REPLACE(';' + CC_LIBRE, ';e.de.marco@squad.com.ar', ';esteban.de.marco@squad.com.ar'), ' e.de.marco@squad.com.ar', ' esteban.de.marco@squad.com.ar')) END
 WHERE (';' + ISNULL(DESTINO_LIBRE,'') LIKE '%;e.de.marco@%' OR ISNULL(DESTINO_LIBRE,'') LIKE '% e.de.marco@%'
     OR ';' + ISNULL(CC_LIBRE,'') LIKE '%;e.de.marco@%' OR ISNULL(CC_LIBRE,'') LIKE '% e.de.marco@%');
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' plantillas corregidas.';

/* el ';' agregado al principio se saca */
UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES SET DESTINO_LIBRE = STUFF(DESTINO_LIBRE, 1, 1, '') WHERE DESTINO_LIBRE LIKE ';%';
UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES SET CC_LIBRE = STUFF(CC_LIBRE, 1, 1, '') WHERE CC_LIBRE LIKE ';%';

/* despues */
SELECT CODIGO, DESTINO_TIPO, DESTINO_LIBRE, CC_LIBRE
FROM dbo.VCT_PRM_EMAIL_TEMPLATES
WHERE DESTINO_LIBRE LIKE '%de.marco%' OR CC_LIBRE LIKE '%de.marco%';
GO
