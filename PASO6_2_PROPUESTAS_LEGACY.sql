/* ============================================================================
   PASO6_2_PROPUESTAS_LEGACY
   ----------------------------------------------------------------------------
   Vincula la propuesta comercial del sistema anterior a cada proyecto migrado:
     LK_PROYECTO.ID_COTIZACION -> LK_COTIZACIONES.ID_ADJUNTO -> PHYSICAL_ATTACHED_DOCUMENT
     (VCT_PROYECTOS.ID = LK_PROYECTO.ID_PROYECTO, lo mantiene la migracion).
   Inserta en VCT_PROYECTOS_DOCUMENTOS (TIPO PROPUESTA_COMERCIAL) solo si:
     - el adjunto existe en PHYSICAL_ATTACHED_DOCUMENT y el proyecto existe en VCT_PROYECTOS;
     - ese proyecto no tiene ya ese adjunto vinculado (re-ejecutable, no duplica).
   NO toca PHYSICAL_ATTACHED_DOCUMENT ni las LK_* (no mueve archivos ni cambia PAR_KEY).
   LK_PROYECTO_DOCUM no se migra. Requiere PASO6_1.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON;

IF OBJECT_ID('dbo.VCT_PROYECTOS_DOCUMENTOS', 'U') IS NULL
BEGIN RAISERROR('Falta VCT_PROYECTOS_DOCUMENTOS: correr antes PASO6_1.', 16, 1); RETURN; END;

DECLARE @N INT = 0, @YA INT = 0;
SELECT @YA = COUNT(*) FROM dbo.VCT_PROYECTOS_DOCUMENTOS WHERE TIPO = 'PROPUESTA_COMERCIAL';

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, TIPO, ID_ADJUNTO, NOMBRE, VISIBLE_CLIENTE, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
    SELECT V.ID, 'PROPUESTA_COMERCIAL', A.PKEY,
           LEFT(COALESCE(NULLIF(LTRIM(RTRIM(A.ATTACHED_MESSAGE)), ''), A.FILE_NAME, 'Propuesta comercial'), 255),
           0, 1, ISNULL(A.TS_BEGIN, GETDATE()), LEFT(ISNULL(A.TS_USER_ID, 'MIGRACION'), 100)
    FROM dbo.LK_PROYECTO P
    INNER JOIN dbo.LK_COTIZACIONES C ON C.ID_COTIZACION = P.ID_COTIZACION
    INNER JOIN dbo.PHYSICAL_ATTACHED_DOCUMENT A ON A.PKEY COLLATE DATABASE_DEFAULT = C.ID_ADJUNTO COLLATE DATABASE_DEFAULT
    INNER JOIN dbo.VCT_PROYECTOS V ON V.ID = P.ID_PROYECTO
    WHERE NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS D
                      WHERE D.ID_PROYECTO = V.ID AND D.TIPO = 'PROPUESTA_COMERCIAL'
                        AND D.ID_ADJUNTO COLLATE DATABASE_DEFAULT = A.PKEY COLLATE DATABASE_DEFAULT);
    SET @N = @@ROWCOUNT;
    COMMIT TRANSACTION;
    PRINT 'OK: propuestas vinculadas ahora: ' + CONVERT(VARCHAR(10), @N) + ' (ya habia: ' + CONVERT(VARCHAR(10), @YA) + ').';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado (no se vinculo nada): %s', 16, 1, @e);
END CATCH;
GO
