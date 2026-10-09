/* ========================================================================
   PERMISOS FASE 1 - B) RENTABILIDAD POR PERMISO EN VEZ DE USUARIOS A MANO
   ------------------------------------------------------------------------
   Reemplaza la lista de usuarios escrita en el codigo
     @IAGENTE IN ('avocaturo','svocaturo','jjvocaturo','cbielsa','mbolivieri')
   por el permiso del perfil: dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'RENTABILIDAD.VIEW').
   Se aplica a VCT_MAIN_REPORTES (obligatorio) y SV_05_INICIO (hub legacy de
   reportes; si ya no tiene la lista, se omite).
   CORRER DESPUES de PERMISOS_FASE1_A_PERFILES.sql (si no, nadie veria
   Rentabilidad). PARCHE sobre la definicion VIGENTE: si un fragmento no se
   encuentra, NO aplica nada y avisa.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID('dbo.VCT_PERFIL_PUEDE') IS NULL
BEGIN
    RAISERROR('Falta dbo.VCT_PERFIL_PUEDE: correr primero PERMISOS_FASE1_A_PERFILES.sql.',16,1);
    RETURN;
END;
IF NOT EXISTS (SELECT 1 FROM dbo.GroupsActions WHERE UPPER(GroupId)='GERENCIA' AND UPPER(ActionId)='RENTABILIDAD.VIEW')
BEGIN
    RAISERROR('GERENCIA aun no tiene RENTABILIDAD.VIEW: correr primero PERMISOS_FASE1_A_PERFILES.sql.',16,1);
    RETURN;
END;

DECLARE @D NVARCHAR(MAX), @s INT, @mk NVARCHAR(MAX), @c INT;

/* ================= VCT_MAIN_REPORTES ================= */
SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_REPORTES'));
IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_REPORTES.',16,1);
    RETURN;
END;

IF CHARINDEX(N'VCT_PERFIL_PUEDE',@D) > 0
    PRINT 'VCT_MAIN_REPORTES ya usa VCT_PERFIL_PUEDE. No se hizo nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
    SET @mk = N'CASE WHEN @IAGENTE IN (''avocaturo'',''svocaturo'',''jjvocaturo'',''cbielsa'',''mbolivieri'') THEN 1 ELSE 0 END';
    SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
    IF @c <> 1
    BEGIN
        RAISERROR('No se encontro (o esta repetida) la lista de usuarios de Rentabilidad en VCT_MAIN_REPORTES. No se aplico nada.',16,1);
        RETURN;
    END;
    SET @D = REPLACE(@D, @mk, N'dbo.VCT_PERFIL_PUEDE(@IUNIDAD,''RENTABILIDAD.VIEW'')');

    SET @s = CHARINDEX(N'CREATE', @D);
    IF @s > 0 AND @s < 4000 AND CHARINDEX(N'PROC', SUBSTRING(@D, @s, 40)) > 0
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0
    BEGIN
        RAISERROR('La definicion de VCT_MAIN_REPORTES no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
        RETURN;
    END;
    EXEC sp_executesql @D;
    PRINT 'OK: VCT_MAIN_REPORTES usa RENTABILIDAD.VIEW del perfil.';
END;

/* ================= SV_05_INICIO (hub legacy) ================= */
SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.SV_05_INICIO'));
IF @D IS NULL
    PRINT 'SV_05_INICIO no existe: omitido.';
ELSE IF CHARINDEX(N'VCT_PERFIL_PUEDE',@D) > 0
    PRINT 'SV_05_INICIO ya usa VCT_PERFIL_PUEDE: omitido.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
    SET @mk = N'CASE WHEN @IAGENTE IN (''avocaturo'',''svocaturo'',''jjvocaturo'',''cbielsa'',''mbolivieri'') THEN';
    SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
    IF @c <> 1
        PRINT 'SV_05_INICIO no tiene la lista de usuarios exactamente una vez: omitido (revisar a mano).';
    ELSE
    BEGIN
        SET @D = REPLACE(@D, @mk, N'CASE WHEN dbo.VCT_PERFIL_PUEDE(@IUNIDAD,''RENTABILIDAD.VIEW'')=1 THEN');
        SET @s = CHARINDEX(N'CREATE', @D);
        IF @s > 0 AND @s < 4000 AND CHARINDEX(N'PROC', SUBSTRING(@D, @s, 40)) > 0
            SET @D = STUFF(@D, @s, 6, N'ALTER ');
        IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0
            PRINT 'SV_05_INICIO: la definicion no contiene ALTER/CREATE PROCEDURE: omitido.';
        ELSE
        BEGIN
            EXEC sp_executesql @D;
            PRINT 'OK: SV_05_INICIO usa RENTABILIDAD.VIEW del perfil.';
        END;
    END;
END;
GO
