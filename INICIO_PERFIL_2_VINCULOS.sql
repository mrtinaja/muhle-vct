/* ========================================================================
   INICIO_PERFIL_2_VINCULOS  (CAMBIA DATOS: VCT_CONSULTORES.ID_USUARIO_SEGURIDAD)
   ------------------------------------------------------------------------
   El Inicio muestra "Mis visitas y plan" al usuario vinculado a un
   consultor. Hoy ningun consultor real tiene usuario vinculado (solo los
   de prueba). Se vinculan los que ya tienen usuario en el admin
   (coincidencias de DIAG_PERMISOS_3, controladas por apellido).
   Es lo mismo que activar "Ingresa al sistema" + usuario en la ficha del
   consultor (la restriccion CK_VCT_CONSULTORES_USUARIO pide las dos cosas). Solo completa vinculos vacios; no pisa ninguno.
   Volver atras: bloque comentado al final.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

DECLARE @V TABLE (ID_CONSULTOR INT, APELLIDO VARCHAR(100), USUARIO VARCHAR(100));
INSERT INTO @V VALUES
    (3,   'Blanco',     'xblanco'),
    (5,   'Cavana',     'lcavana'),
    (9,   'Di Yelsi',   'cdiyelsi'),
    (12,  'Gils Carbo', 'sgilscarbo'),
    (18,  'Neumann',    'vneumann'),
    (19,  'Nowak',      'mnowak'),
    (127, 'Maturo',     'vmaturo');

/* antes */
SELECT V.USUARIO, C.ID, C.APELLIDOS, C.NOMBRES, C.ESTADO, C.ID_USUARIO_SEGURIDAD AS VINCULO_ACTUAL,
       CASE WHEN C.ID IS NULL THEN 'NO EXISTE EL CONSULTOR'
            WHEN C.APELLIDOS NOT LIKE '%' + V.APELLIDO + '%' THEN 'APELLIDO NO COINCIDE: no se toca'
            WHEN NULLIF(LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''))),'') IS NOT NULL AND C.ID_USUARIO_SEGURIDAD <> '0' THEN 'YA TENIA VINCULO: no se toca'
            WHEN NOT EXISTS (SELECT 1 FROM dbo.Users U WHERE U.Id = V.USUARIO) THEN 'NO EXISTE EL USUARIO'
            WHEN EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES X WHERE X.ID_USUARIO_SEGURIDAD = V.USUARIO AND X.ID <> V.ID_CONSULTOR) THEN 'USUARIO YA USADO POR OTRO'
            ELSE 'SE VINCULA' END AS ACCION
FROM @V V LEFT JOIN dbo.VCT_CONSULTORES C ON C.ID = V.ID_CONSULTOR;

UPDATE C
   SET INGRESA_SISTEMA = 1, ID_USUARIO_SEGURIDAD = V.USUARIO, FECHA_UPD = GETDATE(), USUARIO_UPD = 'INICIO_PERFIL'
  FROM dbo.VCT_CONSULTORES C
 INNER JOIN @V V ON V.ID_CONSULTOR = C.ID
 WHERE C.APELLIDOS LIKE '%' + V.APELLIDO + '%'
   AND (NULLIF(LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''))),'') IS NULL OR C.ID_USUARIO_SEGURIDAD = '0')
   AND EXISTS (SELECT 1 FROM dbo.Users U WHERE U.Id = V.USUARIO)
   AND NOT EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES X WHERE X.ID_USUARIO_SEGURIDAD = V.USUARIO AND X.ID <> V.ID_CONSULTOR);
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' consultores vinculados a su usuario.';

/* despues */
SELECT C.ID, C.APELLIDOS, C.NOMBRES, C.ID_USUARIO_SEGURIDAD AS USUARIO
FROM dbo.VCT_CONSULTORES C
WHERE NULLIF(LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''))),'') IS NOT NULL AND C.ID_USUARIO_SEGURIDAD <> '0'
ORDER BY C.APELLIDOS;
GO

/* VOLVER ATRAS (no se ejecuta solo):
UPDATE dbo.VCT_CONSULTORES SET INGRESA_SISTEMA = 0, ID_USUARIO_SEGURIDAD = NULL
 WHERE USUARIO_UPD = 'INICIO_PERFIL' AND ID IN (3,5,9,12,18,19,127);
*/
