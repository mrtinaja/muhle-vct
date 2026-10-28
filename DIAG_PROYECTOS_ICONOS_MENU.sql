/* ============================================================================
   DIAG_PROYECTOS_ICONOS_MENU  v2 (solo lectura, PRINT-based)
   Vuelca: A) VCT_MAIN_PROYECTO_V360 (iconos de servicio + menu 3 puntos, ref)
           B) VCT_MAIN_PROYECTOS (como arma hoy la celda Servicios + la fila, target)
   SSMS F5. Pegame la pestana Messages.
   NOTA: nombres de variables distintos entre si (SQL es case-insensitive: @P == @p).
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @DEFV NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @DEFP NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTOS'));
DECLARE @POS INT, @INI INT, @KK INT, @TMP NVARCHAR(MAX);

PRINT '################ A) VCT_MAIN_PROYECTO_V360 (referencia: iconos + menu) ################';
IF @DEFV IS NULL PRINT '  !!! NO EXISTE'; ELSE
BEGIN
    PRINT '  LARGO: '+CONVERT(VARCHAR(20),LEN(@DEFV));
    PRINT '  pos data-vct-svc      : '+CONVERT(VARCHAR(20),CHARINDEX('data-vct-svc',@DEFV));
    PRINT '  pos vctdg-svc         : '+CONVERT(VARCHAR(20),CHARINDEX('vctdg-svc',@DEFV));
    PRINT '  pos row-menu-trigger  : '+CONVERT(VARCHAR(20),CHARINDEX('row-menu-trigger',@DEFV));
    PRINT '  pos vct-table-action  : '+CONVERT(VARCHAR(20),CHARINDEX('vct-table-action',@DEFV));
    SET @POS = CHARINDEX('data-vct-svc',@DEFV);
    IF @POS=0 SET @POS=CHARINDEX('vctdg-svc',@DEFV);
    IF @POS=0 SET @POS=CHARINDEX('row-menu-trigger',@DEFV);
    IF @POS=0 SET @POS=1;
    SET @INI = CASE WHEN @POS>1500 THEN @POS-1500 ELSE 1 END;
    SET @TMP = SUBSTRING(@DEFV,@INI,7000);
    SET @KK=1;
    WHILE @KK<=LEN(@TMP) BEGIN PRINT SUBSTRING(@TMP,@KK,3500); SET @KK=@KK+3500; END;
END

PRINT '';
PRINT '################ B) VCT_MAIN_PROYECTOS (target: celda Servicios + fila) ################';
IF @DEFP IS NULL PRINT '  !!! NO EXISTE'; ELSE
BEGIN
    PRINT '  LARGO: '+CONVERT(VARCHAR(20),LEN(@DEFP));
    PRINT '  pos serv-chip         : '+CONVERT(VARCHAR(20),CHARINDEX('serv-chip',@DEFP));
    PRINT '  pos SERV_HTML         : '+CONVERT(VARCHAR(20),CHARINDEX('SERV_HTML',@DEFP));
    PRINT '  pos scan-eye          : '+CONVERT(VARCHAR(20),CHARINDEX('scan-eye',@DEFP));
    PRINT '  pos vct-ini-link      : '+CONVERT(VARCHAR(20),CHARINDEX('vct-ini-link',@DEFP));
    PRINT '  pos data-vct-store    : '+CONVERT(VARCHAR(20),CHARINDEX('data-vct-store',@DEFP));
    SET @POS = CHARINDEX('serv-chip',@DEFP);
    IF @POS=0 SET @POS=CHARINDEX('SERV_HTML',@DEFP);
    IF @POS=0 SET @POS=1;
    SET @INI = CASE WHEN @POS>1500 THEN @POS-1500 ELSE 1 END;
    SET @TMP = SUBSTRING(@DEFP,@INI,8000);
    SET @KK=1;
    WHILE @KK<=LEN(@TMP) BEGIN PRINT SUBSTRING(@TMP,@KK,3500); SET @KK=@KK+3500; END;
END
PRINT '################ FIN ################';
