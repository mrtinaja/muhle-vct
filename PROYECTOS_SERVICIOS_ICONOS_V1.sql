/* ============================================================================
   PROYECTOS_SERVICIOS_ICONOS_V1
   ----------------------------------------------------------------------------
   En la tabla de Proyectos (VCT_MAIN_PROYECTOS) la columna Servicios muestra
   chips de TEXTO (<span class="vct-serv-chip ...">Auditoria</span>). Este parche
   la pasa a ICONOS (sin texto), iguales a la Vista 360 de Proyecto:
       <span class="vctdg-svc is-on is-XX" title="<desc>"><span data-vct-icon="<ico>"></span></span>
   donde XX = 2 letras del codigo del servicio (au/co/ca) e <ico> = clipboard-check
   (AU) / users (CA) / briefcase (CO), igual que @SRV_ICONS de VCT_MAIN_PROYECTO_V360.

   Tecnica: ubica el bloque que arma el chip por anclas de UN token (sin matchear
   multi-linea ni comillas) y hace STUFF. CREATE->ALTER. Falla-seguro: si no
   encuentra las anclas, RAISERROR y NO cambia nada. Re-ejecutable: si ya tiene
   el icono (vctdg-svc is-on is-), avisa. Compat 100 y 140.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @Q CHAR(1) = CHAR(39);
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTOS'));
DECLARE @A INT, @B INT, @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT;

IF @D IS NULL BEGIN RAISERROR('No existe dbo.VCT_MAIN_PROYECTOS.',16,1); RETURN; END;

/* ya aplicado? */
IF CHARINDEX(@Q+N'<span class="vctdg-svc is-on is-', @D) > 0
BEGIN PRINT 'PROYECTOS_SERVICIOS_ICONOS_V1 ya aplicado. Sin cambios.'; RETURN; END;

/* inicio del bloque del chip (la expresion SELECT de SERV_HTML) */
SET @A = CHARINDEX(@Q+N'<span class="vct-serv-chip ', @D);
IF @A = 0 BEGIN RAISERROR('No se encontro el chip de texto (vct-serv-chip). Sin cambios.',16,1); RETURN; END;

/* fin: el FROM de la subconsulta de servicios (primer FROM despues del chip) */
SET @B = CHARINDEX(N'FROM dbo.VCT_PROYECTOS_SERVICIOS XS', @D, @A);
IF @B = 0 OR @B <= @A BEGIN RAISERROR('No se encontro el FROM de la subconsulta de servicios. Sin cambios.',16,1); RETURN; END;

/* nueva expresion: icono por servicio (color is-XX por codigo, icono por AU/CA/CO) */
DECLARE @NEW NVARCHAR(MAX) =
      @Q+N'<span class="vctdg-svc is-on is-'+@Q
    + N' + LOWER(LEFT(ISNULL(PS.CODIGO,'+@Q+N'xx'+@Q+N'),2)) + '
    + @Q+N'" title="'+@Q
    + N' + REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,'+@Q+@Q+N'),'+@Q+N'&'+@Q+N','+@Q+N'&amp;'+@Q+N'),'+@Q+N'"'+@Q+N','+@Q+@Q+N'),'+@Q+N'<'+@Q+N','+@Q+@Q+N') + '
    + @Q+N'"><span data-vct-icon="'+@Q
    + N' + CASE UPPER(LEFT(ISNULL(PS.CODIGO,'+@Q+@Q+N'),2)) WHEN '+@Q+N'AU'+@Q+N' THEN '+@Q+N'clipboard-check'+@Q
    + N' WHEN '+@Q+N'CA'+@Q+N' THEN '+@Q+N'users'+@Q+N' ELSE '+@Q+N'briefcase'+@Q+N' END + '
    + @Q+N'"></span></span>'+@Q
    + N' ';   /* espacio antes del FROM */

/* reemplaza la expresion vieja (desde @A hasta justo antes del FROM) */
SET @D = STUFF(@D, @A, @B - @A, @NEW);

IF CHARINDEX(@Q+N'<span class="vctdg-svc is-on is-', @D) = 0
BEGIN RAISERROR('Post-STUFF no quedo el icono. Sin cambios.',16,1); RETURN; END;

/* ---- CREATE [OR ALTER] ... -> ALTER ---- */
SET @up = UPPER(@D); SET @cp = 0; SET @scan = 1;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC. Sin cambios.',16,1); RETURN; END;
IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER');
ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: PROYECTOS_SERVICIOS_ICONOS_V1 aplicado (Servicios como iconos en la tabla de Proyectos).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado al recrear el SP: %s',16,1,@e);
END CATCH;
GO
