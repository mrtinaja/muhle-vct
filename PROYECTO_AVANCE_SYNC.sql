/* ========================================================================
   PROYECTO_AVANCE_SYNC  (CAMBIA DATOS: VCT_PROYECTOS.PORCENTAJE_AVANCE)
   ------------------------------------------------------------------------
   Las Vista 360 de Cliente, Consultor y Empleado (lista, barra, "Avance
   promedio", tendencia) leen VCT_PROYECTOS.PORCENTAJE_AVANCE, que nadie
   actualizaba -> 0%. La Vista 360 de Proyecto calcula el avance con
   dbo.VCT_PROYECTO_AVANCE (lanzamiento 10% + plan 90%).
   En vez de tocar esas tres pantallas, se mantiene la columna al dia:
     1. dbo.VCT_PROYECTO_AVANCE: proyecto terminado/finalizado/cerrado = 100.
     2. dbo.VCT_PROYECTO_AVANCE_SYNC: graba el avance calculado en la columna
        (un proyecto o todos).
     3. Vista 360 de Proyecto: sincroniza el proyecto en cada carga, despues
        de procesar plan / lanzamiento / visitas (marca AVANCE_SYNC_V1).
     4. Carga inicial: todos los proyectos que hoy tienen 0 / vacio, o que
        ya tienen plan o lanzamiento nuevo. No pisa avances cargados a mano
        en proyectos viejos sin plan.
   Limite: si una gestion del plan se cierra desde otra pantalla (Acciones),
   la columna se actualiza la proxima vez que se abre la 360 del proyecto.
   Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* estados de proyecto (informativo, para ver los codigos de terminado) */
SELECT E.ID, E.CODIGO, E.DESCRIPCION, COUNT(P.ID) AS PROYECTOS
FROM dbo.VCT_PRM_PROYECTOS_ESTADOS E
LEFT JOIN dbo.VCT_PROYECTOS P ON P.ID_ESTADO = E.ID
GROUP BY E.ID, E.CODIGO, E.DESCRIPCION
ORDER BY E.ID;
GO

/* ---------------- 1. avance: terminado = 100 ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_AVANCE (@ID_PROYECTO INT)
RETURNS @R TABLE (AVANCE INT, DETALLE VARCHAR(200))
AS
BEGIN
    DECLARE @COD VARCHAR(50), @PASOS INT = 0, @NITEMS INT = 0, @PLAN DECIMAL(9,2) = 0, @V DECIMAL(9,2),
            @GT INT = 0, @GC INT = 0;

    SELECT @COD = ISNULL(ESTADO_CODIGO, ''),
           @PASOS = CASE WHEN ISNULL(CONSULTORES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(DATOS_CARGADOS,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(CONSIDERACIONES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(REUNION_OK,0) = 1 THEN 1 ELSE 0 END
    FROM dbo.VCT_PROYECTO_LANZ_ESTADO(@ID_PROYECTO);

    IF @COD LIKE 'FINALIZ%' OR @COD LIKE 'CERRAD%' OR @COD LIKE 'TERMIN%' OR @COD LIKE 'COMPLET%'
    BEGIN
        INSERT INTO @R VALUES (100, 'Proyecto finalizado');
        RETURN;
    END;

    SELECT @NITEMS = COUNT(*),
           @PLAN = ISNULL(AVG(CAST(C.AVANCE AS DECIMAL(9,2))), 0),
           @GT = ISNULL(SUM(C.G_TOTAL), 0),
           @GC = ISNULL(SUM(C.G_CUMPLIDAS), 0)
    FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO) C;

    IF @COD = 'ENCURSO' OR @NITEMS > 0 SET @PASOS = 4;

    SET @V = @PASOS * 2.5 + @PLAN * 0.9;
    IF @V > 100 SET @V = 100;

    INSERT INTO @R VALUES (
        CAST(ROUND(@V, 0) AS INT),
        CASE WHEN @NITEMS > 0 THEN 'Plan estrategico: ' + CASE WHEN ROUND(@PLAN,1) = FLOOR(ROUND(@PLAN,1)) THEN CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,1) AS INT))
                                                     ELSE REPLACE(CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,1) AS DECIMAL(5,1))), '.', ',') END + '% ('
                                   + CONVERT(VARCHAR(10), @GC) + ' de ' + CONVERT(VARCHAR(10), @GT) + ' gestiones)'
             WHEN @COD = 'ENCURSO' THEN 'Lanzado - plan estrategico pendiente'
             ELSE 'Lanzamiento: ' + CONVERT(VARCHAR(2), @PASOS) + ' de 4 pasos' END);
    RETURN;
END
GO

/* ---------------- 2. sincronizar ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_AVANCE_SYNC
(
    @ID_PROYECTO INT = NULL
)
AS
BEGIN
    /* Graba en VCT_PROYECTOS.PORCENTAJE_AVANCE el avance calculado.
       @ID_PROYECTO NULL = todos. No toca FECHA_UPD. */
    SET NOCOUNT ON;
    UPDATE P
       SET PORCENTAJE_AVANCE = A.AVANCE
      FROM dbo.VCT_PROYECTOS P
     CROSS APPLY dbo.VCT_PROYECTO_AVANCE(P.ID) A
     WHERE (@ID_PROYECTO IS NULL OR P.ID = @ID_PROYECTO)
       AND ISNULL(P.PORCENTAJE_AVANCE, -1) <> A.AVANCE;
END
GO

/* ---------------- 3. Vista 360 de Proyecto: sincroniza en cada carga ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @MK NVARCHAR(100) = N'/* AVANCE_V1: avance calculado', @s INT;

IF @D IS NULL
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
ELSE IF CHARINDEX(N'AVANCE_SYNC_V1', @D) > 0
    PRINT 'VCT_MAIN_PROYECTO_V360 ya sincronizaba el avance.';
ELSE IF (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @MK, N''))) / DATALENGTH(@MK) <> 1
    RAISERROR('No se encontro la marca AVANCE_V1 en VCT_MAIN_PROYECTO_V360. No se aplico la parte 3.',16,1);
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
    SET @s = CHARINDEX(@MK, @D);
    SET @D = STUFF(@D, @s, 0, N'/* AVANCE_SYNC_V1: la columna PORCENTAJE_AVANCE queda igual al avance calculado (listas de las otras 360) */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_AVANCE_SYNC @ID_PROYECTO=@ID_PROYECTO;
END TRY
BEGIN CATCH
END CATCH;

');
    SET @s = CHARINDEX(N'PROCEDURE', @D);
    IF CHARINDEX(N'CREATE', SUBSTRING(@D, CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END, 40)) > 0
       AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END, 40)) = 0
        SET @D = STUFF(@D, (CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END) + CHARINDEX(N'CREATE', SUBSTRING(@D, CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END, 40)) - 1, 6, N'ALTER ');
    EXEC sp_executesql @D;
    PRINT 'OK: VCT_MAIN_PROYECTO_V360 sincroniza el avance en cada carga.';
END;
GO

/* ---------------- 4. carga inicial ---------------- */
DECLARE @ANTES TABLE (ID INT PRIMARY KEY, ANTES INT);
INSERT INTO @ANTES (ID, ANTES)
SELECT P.ID, P.PORCENTAJE_AVANCE
FROM dbo.VCT_PROYECTOS P
WHERE ISNULL(P.PORCENTAJE_AVANCE, 0) = 0
   OR EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLANES PL WHERE PL.ID_PROYECTO = P.ID)
   OR EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES G
              INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
              WHERE G.ID_PROYECTO = P.ID AND ST.CODIGO IN ('CARGA_PLAN'));

UPDATE P
   SET PORCENTAJE_AVANCE = A.AVANCE
  FROM dbo.VCT_PROYECTOS P
 INNER JOIN @ANTES X ON X.ID = P.ID
 CROSS APPLY dbo.VCT_PROYECTO_AVANCE(P.ID) A
 WHERE ISNULL(P.PORCENTAJE_AVANCE, -1) <> A.AVANCE;
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' proyectos actualizados.';

SELECT TOP 20 P.ID, P.CODIGO, P.NOMBRE, X.ANTES, P.PORCENTAJE_AVANCE AS AHORA
FROM dbo.VCT_PROYECTOS P INNER JOIN @ANTES X ON X.ID = P.ID
WHERE ISNULL(X.ANTES, -1) <> P.PORCENTAJE_AVANCE
ORDER BY P.ID DESC;
GO

PRINT 'OK: avance sincronizado.';
GO
