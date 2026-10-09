/* ========================================================================
   DUMP_SP_DEFINICION
   ------------------------------------------------------------------------
   Imprime la definicion COMPLETA de un SP, linea por linea, en la pestaña
   "Messages" de SSMS (sin truncar). Solo lee: no crea ni modifica nada.

   USO
     1) Cambiar @NAME si hace falta (por defecto: VCT_MAIN_CONFIGURACION).
     2) Ejecutar (F5).
     3) Ir a la pestaña "Messages" -> clic adentro -> Ctrl+A -> Ctrl+C.
     4) Pegar en el Bloc de notas y guardar como:
        C:\Users\Usuario\Desktop\muhle-vct\VCT_MAIN_CONFIGURACION_SERVIDOR.sql
        (Guardar como -> Tipo: Todos los archivos -> Codificacion: UTF-8)
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @NAME SYSNAME = 'dbo.VCT_MAIN_CONFIGURACION';

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@NAME));

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro la definicion de %s (revisar nombre / permiso VIEW DEFINITION).',16,1,@NAME);
    RETURN;
END;

DECLARE @TOTAL INT = DATALENGTH(@D) / 2;   -- caracteres reales (LEN ignora espacios finales)
DECLARE @P INT = 1, @E INT, @LINE NVARCHAR(MAX);

WHILE @P <= @TOTAL
BEGIN
    SET @E = CHARINDEX(NCHAR(10), @D, @P);
    IF @E = 0 SET @E = @TOTAL + 1;

    SET @LINE = SUBSTRING(@D, @P, @E - @P);

    /* quitar el CR de los saltos CRLF */
    IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13)
        SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);

    /* PRINT admite 4000 caracteres: las lineas mas largas se parten */
    WHILE (DATALENGTH(@LINE) / 2) > 4000
    BEGIN
        PRINT SUBSTRING(@LINE, 1, 4000);
        SET @LINE = SUBSTRING(@LINE, 4001, 1000000);
    END;

    PRINT @LINE;
    SET @P = @E + 1;
END;
