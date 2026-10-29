/* ========================================================================
   DUMP_INICIO_SP
   ------------------------------------------------------------------------
   Vuelca la definicion COMPLETA del SP que arma la pantalla INICIO (el que
   tiene el grafico con la clase CSS "vct-dash-vlbl"), linea por linea, en la
   pestaña "Messages" de SSMS (sin truncar). SOLO LEE: no crea ni modifica nada.

   Sirve para corregir sobre la version VIGENTE del servidor:
     - el subtitulo que sale con "&uacute;" literal (hay que usar el caracter),
     - y el grafico cuyas etiquetas de meses se superponen en celular.

   USO
     1) Ejecutar (F5).
     2) Pestaña "Messages" -> clic adentro -> Ctrl+A -> Ctrl+C.
     3) Pegar en el Bloc de notas y guardar como:
        C:\Users\Usuario\Desktop\muhle-vct\INICIO_SP_SERVIDOR.sql
        (Guardar como -> Tipo: Todos los archivos -> Codificacion: UTF-8)
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* localizar el SP del Inicio por una marca unica del grafico */
DECLARE @NAME SYSNAME = (
    SELECT TOP 1 OBJECT_SCHEMA_NAME(m.object_id) + '.' + OBJECT_NAME(m.object_id)
    FROM sys.sql_modules m
    WHERE m.definition LIKE '%vct-dash-vlbl%'
    ORDER BY LEN(m.definition) DESC
);

IF @NAME IS NULL
BEGIN
    PRINT 'No se encontro ningun SP con "vct-dash-vlbl".';
    PRINT 'Avisar: puede que el grafico use otra clase. Buscar entonces el SP del Inicio a mano.';
    RETURN;
END;

PRINT '==== SP DEL INICIO: ' + @NAME + ' ====';
PRINT '';

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@NAME));
DECLARE @TOTAL INT = DATALENGTH(@D) / 2;
DECLARE @P INT = 1, @E INT, @LINE NVARCHAR(MAX);

WHILE @P <= @TOTAL
BEGIN
    SET @E = CHARINDEX(NCHAR(10), @D, @P);
    IF @E = 0 SET @E = @TOTAL + 1;

    SET @LINE = SUBSTRING(@D, @P, @E - @P);

    IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13)
        SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);

    WHILE (DATALENGTH(@LINE) / 2) > 4000
    BEGIN
        PRINT SUBSTRING(@LINE, 1, 4000);
        SET @LINE = SUBSTRING(@LINE, 4001, 1000000);
    END;

    PRINT @LINE;
    SET @P = @E + 1;
END;
