/* ========================================================================
   CONSULTOR_SERVICIOS_1_MODELO
   ------------------------------------------------------------------------
   Base del pedido de Esteban (reunion 09/10): la calificacion del consultor
   es por NORMA Y SERVICIO (la misma norma puede estar hasta 3 veces, una por
   servicio: Consultoria / Auditoria / Capacitacion).

   Este script NO asume el esquema: lo detecta y solo agrega lo que falta.
   - Informa (PRINT) las tablas y columnas reales de:
       VCT_CONSULTORES_SERVICIOS, VCT_CONSULTORES_NORMAS y el maestro de
       servicios (PRM_SERVICIOS / VCT_PRM_SERVICIOS).
   - Si VCT_CONSULTORES_NORMAS no tiene columna de servicio, agrega
       ID_SERVICIO INT NULL (no toca las filas existentes).
   - Crea un indice unico sobre (consultor, norma, servicio) solo para las
       filas con servicio cargado, para que no se repita la misma norma en el
       mismo servicio (validacion de duplicados que pidio Esteban).

   Seguro de correr y re-ejecutable. No borra datos. Anda en compat 100 y 140.
   Correr DESPUES de que vuelva la base; leer los PRINT para confirmar el
   modelo antes de los parches de la Vista 360 y del lanzamiento.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- 1. maestro de servicios ---------- */
DECLARE @SERV_MASTER SYSNAME = NULL;
IF OBJECT_ID('dbo.VCT_PRM_SERVICIOS','U') IS NOT NULL SET @SERV_MASTER = 'dbo.VCT_PRM_SERVICIOS';
ELSE IF OBJECT_ID('dbo.PRM_SERVICIOS','U') IS NOT NULL SET @SERV_MASTER = 'dbo.PRM_SERVICIOS';

IF @SERV_MASTER IS NULL
    PRINT 'AVISO: no se encontro el maestro de servicios (VCT_PRM_SERVICIOS ni PRM_SERVICIOS).';
ELSE
BEGIN
    PRINT 'Maestro de servicios: ' + @SERV_MASTER;
    DECLARE @sm NVARCHAR(MAX) = N'SELECT * FROM ' + @SERV_MASTER + N' ORDER BY 1;';
    EXEC sp_executesql @sm;
END;
GO

/* ---------- 2. VCT_CONSULTORES_SERVICIOS: existe? columnas? ---------- */
IF OBJECT_ID('dbo.VCT_CONSULTORES_SERVICIOS','U') IS NULL
    PRINT 'AVISO: NO existe dbo.VCT_CONSULTORES_SERVICIOS (habria que crearla para la seccion Servicios del consultor).';
ELSE
BEGIN
    PRINT 'dbo.VCT_CONSULTORES_SERVICIOS - columnas:';
    SELECT C.column_id AS COL, C.name AS COLUMNA, TY.name AS TIPO, C.is_nullable AS NULEABLE, C.is_identity AS IDENTITY_
    FROM sys.columns C JOIN sys.types TY ON TY.user_type_id = C.user_type_id
    WHERE C.object_id = OBJECT_ID('dbo.VCT_CONSULTORES_SERVICIOS') ORDER BY C.column_id;
    SELECT COUNT(*) AS FILAS_SERVICIOS, COUNT(DISTINCT ID_CONSULTOR) AS CONSULTORES
    FROM dbo.VCT_CONSULTORES_SERVICIOS;
END;
GO

/* ---------- 3. VCT_CONSULTORES_NORMAS: columnas y deteccion ---------- */
IF OBJECT_ID('dbo.VCT_CONSULTORES_NORMAS','U') IS NULL
BEGIN
    PRINT 'ERROR: no existe dbo.VCT_CONSULTORES_NORMAS. No se aplica nada.';
    RETURN;
END;

PRINT 'dbo.VCT_CONSULTORES_NORMAS - columnas:';
SELECT C.column_id AS COL, C.name AS COLUMNA, TY.name AS TIPO, C.is_nullable AS NULEABLE, C.is_identity AS IDENTITY_
FROM sys.columns C JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE C.object_id = OBJECT_ID('dbo.VCT_CONSULTORES_NORMAS') ORDER BY C.column_id;
GO

/* columna que vincula al consultor */
DECLARE @LINK SYSNAME =
    CASE WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_CONSULTOR')  IS NOT NULL THEN 'ID_CONSULTOR'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','IDCONSULTOR')   IS NOT NULL THEN 'IDCONSULTOR'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','CONSULTOR_ID')  IS NOT NULL THEN 'CONSULTOR_ID' END;

/* columna de la norma */
DECLARE @NORM SYSNAME =
    CASE WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_NORMA')  IS NOT NULL THEN 'ID_NORMA'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','IDNORMA')   IS NOT NULL THEN 'IDNORMA'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','NORMA_ID')  IS NOT NULL THEN 'NORMA_ID'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_NORMAS') IS NOT NULL THEN 'ID_NORMAS' END;

/* columna de servicio, si ya existe con algun nombre */
DECLARE @SERV SYSNAME =
    CASE WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_SERVICIO') IS NOT NULL THEN 'ID_SERVICIO'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','IDSERVICIO')  IS NOT NULL THEN 'IDSERVICIO'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','SERVICIO_ID') IS NOT NULL THEN 'SERVICIO_ID'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_SERVICIOS') IS NOT NULL THEN 'ID_SERVICIOS' END;

PRINT 'Columna consultor: ' + ISNULL(@LINK,'(no encontrada)')
    + ' | norma: ' + ISNULL(@NORM,'(no encontrada)')
    + ' | servicio: ' + ISNULL(@SERV,'(no existe, se agrega)');

IF @LINK IS NULL OR @NORM IS NULL
BEGIN
    PRINT 'ERROR: no se detecta la columna de consultor o de norma. No se aplica nada.';
    RETURN;
END;

/* ---------- 4. agregar ID_SERVICIO si no existe ---------- */
IF @SERV IS NULL
BEGIN
    ALTER TABLE dbo.VCT_CONSULTORES_NORMAS ADD ID_SERVICIO INT NULL;
    SET @SERV = 'ID_SERVICIO';
    PRINT 'OK: se agrego la columna ID_SERVICIO INT NULL a VCT_CONSULTORES_NORMAS.';
END
ELSE
    PRINT 'La columna de servicio ya existia (' + @SERV + '): sin cambios de estructura.';
GO

/* ---------- 5. indice unico: una norma por servicio y consultor ----------
   Solo para filas con servicio cargado (filtered index), asi no choca con las
   filas historicas que todavia tienen el servicio en NULL. */
DECLARE @LINK SYSNAME =
    CASE WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_CONSULTOR')  IS NOT NULL THEN 'ID_CONSULTOR'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','IDCONSULTOR')   IS NOT NULL THEN 'IDCONSULTOR'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','CONSULTOR_ID')  IS NOT NULL THEN 'CONSULTOR_ID' END;
DECLARE @NORM SYSNAME =
    CASE WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_NORMA')  IS NOT NULL THEN 'ID_NORMA'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','IDNORMA')   IS NOT NULL THEN 'IDNORMA'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','NORMA_ID')  IS NOT NULL THEN 'NORMA_ID'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_NORMAS') IS NOT NULL THEN 'ID_NORMAS' END;
DECLARE @SERV SYSNAME =
    CASE WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_SERVICIO') IS NOT NULL THEN 'ID_SERVICIO'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','IDSERVICIO')  IS NOT NULL THEN 'IDSERVICIO'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','SERVICIO_ID') IS NOT NULL THEN 'SERVICIO_ID'
         WHEN COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','ID_SERVICIOS') IS NOT NULL THEN 'ID_SERVICIOS' END;

IF @LINK IS NOT NULL AND @NORM IS NOT NULL AND @SERV IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_VCT_CONS_NORMAS_SERV' AND object_id = OBJECT_ID('dbo.VCT_CONSULTORES_NORMAS'))
    BEGIN
        /* primero: hay duplicados ya cargados que impedirian el indice? */
        DECLARE @dup INT, @q NVARCHAR(MAX);
        SET @q = N'SELECT @o = COUNT(*) FROM (SELECT ' + QUOTENAME(@LINK) + N',' + QUOTENAME(@NORM) + N',' + QUOTENAME(@SERV) +
                 N' FROM dbo.VCT_CONSULTORES_NORMAS WHERE ' + QUOTENAME(@SERV) + N' IS NOT NULL' +
                 N' GROUP BY ' + QUOTENAME(@LINK) + N',' + QUOTENAME(@NORM) + N',' + QUOTENAME(@SERV) +
                 N' HAVING COUNT(*) > 1) D;';
        EXEC sp_executesql @q, N'@o INT OUTPUT', @o = @dup OUTPUT;

        IF ISNULL(@dup,0) > 0
            PRINT 'AVISO: hay ' + CONVERT(VARCHAR(10),@dup) + ' combinacion(es) norma+servicio repetida(s); limpiar antes de crear el indice unico.';
        ELSE
        BEGIN
            SET @q = N'CREATE UNIQUE INDEX UX_VCT_CONS_NORMAS_SERV ON dbo.VCT_CONSULTORES_NORMAS (' +
                     QUOTENAME(@LINK) + N',' + QUOTENAME(@NORM) + N',' + QUOTENAME(@SERV) +
                     N') WHERE ' + QUOTENAME(@SERV) + N' IS NOT NULL;';
            EXEC sp_executesql @q;
            PRINT 'OK: indice unico UX_VCT_CONS_NORMAS_SERV creado (una norma por servicio y consultor).';
        END;
    END
    ELSE
        PRINT 'El indice UX_VCT_CONS_NORMAS_SERV ya existia.';
END;
GO

PRINT '=== CONSULTOR_SERVICIOS_1_MODELO: fin ===';
GO
