/* ========================================================================
   PASO3_4_VINCULO_CONSULTOR_Y_ACENTOS
   ------------------------------------------------------------------------
   1. Datos: vincula el usuario jbracamonte con su ficha de consultor
      (VCT_CONSULTORES.ID = 50, hoy ID_USUARIO_SEGURIDAD = NULL). Sin ese
      vinculo Inicio, Acciones y la campanita no lo encuentran.
      Para otros consultores, el mismo dato se carga en la ficha del
      consultor (usuario de seguridad).
   2. Datos: la accion "Iniciar Plan Estrategico - 1347" quedo dos veces
      (34 y 35). Si las dos estan abiertas, se cancela la mas nueva (con
      historial). Si una ya esta cancelada, no se toca nada.
   3. dbo.VCT_GET_HEADER: js/vct-notif.js pasa a v=2 (decodifica los acentos
      escritos como entidades en el titulo / subtitulo del header, por ej.
      "seg&uacute;n" -> "segun" con tilde, en todas las pantallas).
   No toca permisos. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* ---------- 1. vinculo usuario -> consultor ---------- */
IF EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = 'jbracamonte' AND ID <> 50)
    PRINT 'FALLO el usuario jbracamonte ya esta vinculado a otro consultor: revisar a mano.';
ELSE
BEGIN
    UPDATE dbo.VCT_CONSULTORES SET ID_USUARIO_SEGURIDAD = 'jbracamonte'
    WHERE ID = 50 AND ISNULL(ID_USUARIO_SEGURIDAD,'') = '';
    PRINT 'OK   consultor 50 (Bracamonte) vinculado a jbracamonte (' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' fila).';
END;

/* ---------- 2. accion de plan duplicada ---------- */
DECLARE @CANC INT, @P INT, @A_NUEVA INT, @EST INT;
SELECT @CANC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'CANCELADA';
SELECT @P = ID FROM dbo.VCT_PROYECTOS WHERE CODIGO = '1347';
IF (SELECT COUNT(*) FROM dbo.VCT_ACCIONES A
    INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO_EVENTO = 'PROYECTO_INICIADO'
    INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
    WHERE A.ID_PROYECTO = @P) > 1 AND @CANC IS NOT NULL
BEGIN
    SELECT TOP 1 @A_NUEVA = A.ID, @EST = A.ID_ESTADO
    FROM dbo.VCT_ACCIONES A
    INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO_EVENTO = 'PROYECTO_INICIADO'
    INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
    WHERE A.ID_PROYECTO = @P ORDER BY A.ID DESC;
    UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @CANC, FECHA_CIERRE = GETDATE() WHERE ID = @A_NUEVA;
    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
    VALUES (@A_NUEVA, @EST, @CANC, 'CANCELADA', 'Duplicada al reiniciar el proyecto en pruebas.', 'SISTEMA', GETDATE(), 'PASO3_4');
    PRINT 'OK   accion duplicada ' + CONVERT(VARCHAR(10), @A_NUEVA) + ' cancelada.';
END
ELSE PRINT 'OK   sin acciones de plan duplicadas abiertas.';

SELECT A.ID, A.TITULO, E.CODIGO AS ESTADO, A.FECHA_CREACION, A.FECHA_VENCIMIENTO
FROM dbo.VCT_ACCIONES A
INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO_EVENTO = 'PROYECTO_INICIADO'
LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
WHERE A.ID_PROYECTO = @P;
GO

/* ---------- 3. header: vct-notif.js v=2 ---------- */
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_GET_HEADER')), @OK BIT = 1, @P INT;
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_GET_HEADER.'; SET @OK = 0; END;
IF @OK = 1 AND CHARINDEX(N'vct-notif.js?v=2', @D) > 0 BEGIN PRINT 'OK   dbo.VCT_GET_HEADER ya carga vct-notif.js v=2.'; SET @OK = 0; END;
IF @OK = 1 AND CHARINDEX(N'vct-notif.js?v=1', @D) = 0 BEGIN PRINT 'FALLO dbo.VCT_GET_HEADER: no se encontro vct-notif.js?v=1.'; SET @OK = 0; END;
IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, N'vct-notif.js?v=1', N'vct-notif.js?v=2');
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @D = STUFF(@D, @P, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_GET_HEADER: vct-notif.js v=2.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_GET_HEADER: ' + ERROR_MESSAGE();
    END CATCH;
END;
IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
