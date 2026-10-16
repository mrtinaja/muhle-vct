/* ========================================================================
   PASO3_1_ALTA_RESPONSABLE
   ------------------------------------------------------------------------
   La primera accion del proyecto ("Asignacion de analista al proyecto",
   regla PROY_ANALISTA_ASIGNADO_REGISTRO) la hace quien carga el proyecto
   (Administracion), no el analista.
     1. Parametria: la regla pasa a DESTINATARIO_ROL = 'USUARIO_ALTA'
        (= el empleado del usuario que graba el alta).
     2. dbo.VCT_PROYECTO_ALTA_GUARDAR: acepta 'USUARIO_ALTA' y pone como
        responsable al empleado de @IAGENTE (si no tiene empleado, queda el
        analista). Se parchea la definicion actual (marca ALTA_USUARIO_V1).
     3. Datos: las acciones ya generadas por esa regla pasan al empleado
        del usuario que dio de alta el proyecto (VCT_ACCIONES.USUARIO_ALTA).
   No toca permisos. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* ---------- 1. parametria ---------- */
UPDATE dbo.VCT_PRM_ACCIONES_REGLAS
   SET DESTINATARIO_ROL = 'USUARIO_ALTA', FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO3_1'
 WHERE CODIGO = 'PROY_ANALISTA_ASIGNADO_REGISTRO' AND ISNULL(DESTINATARIO_ROL,'') <> 'USUARIO_ALTA';
PRINT 'OK   regla PROY_ANALISTA_ASIGNADO_REGISTRO: DESTINATARIO_ROL = USUARIO_ALTA (' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' fila).';
GO

/* ---------- 2. SP del alta ---------- */
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_GUARDAR')), @OK BIT = 1, @P INT,
        @A1 NVARCHAR(400) = N'WHERE ISNULL(PR.ID, -1) <> @ID_ROL_ANALISTA',
        @A2 NVARCHAR(400) = N'VALUES (@NEWA, ''RESPONSABLE'', ''EMPLEADO'', @ANALISTA, 1, ''ACTIVO'', GETDATE(), GETDATE(), @IAGENTE);';

IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_PROYECTO_ALTA_GUARDAR.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%ALTA_USUARIO_V1%' BEGIN PRINT 'OK   dbo.VCT_PROYECTO_ALTA_GUARDAR ya tenia el cambio.'; SET @OK = 0; END;
IF @OK = 1 AND (CHARINDEX(@A1, @D) = 0 OR CHARINDEX(@A2, @D) = 0)
BEGIN
    PRINT 'FALLO no se encontraron en dbo.VCT_PROYECTO_ALTA_GUARDAR los textos a reemplazar (validacion de rol o alta del responsable).';
    SET @OK = 0;
END;

IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @A1, @A1 + N' AND G.ROL <> ''USUARIO_ALTA'' /* ALTA_USUARIO_V1 */');
    SET @D = REPLACE(@D, @A2,
          N'SELECT @NEWA, ''RESPONSABLE'', ''EMPLEADO'','
        + N' CASE WHEN G.ROL = ''USUARIO_ALTA'' THEN ISNULL((SELECT TOP 1 E9.ID FROM dbo.VCT_EMPLEADOS E9 WITH(NOLOCK)'
        + N' WHERE LOWER(LTRIM(RTRIM(ISNULL(E9.ID_USUARIO_SEGURIDAD,'''')))) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'''')))) ORDER BY E9.ID DESC), @ANALISTA)'
        + N' ELSE @ANALISTA END, 1, ''ACTIVO'', GETDATE(), GETDATE(), @IAGENTE FROM @RG G WHERE G.ID = @RID;');

    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0
    BEGIN
        /* CREATE OR ALTER se ejecuta tal cual; CREATE PROCEDURE pasa a ALTER */
        IF LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
            SET @D = STUFF(@D, @P, 6, N'ALTER');
    END
    ELSE IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0 BEGIN PRINT 'FALLO no se encontro CREATE/ALTER PROCEDURE.'; SET @OK = 0; END;
END;

IF @OK = 1
BEGIN
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_PROYECTO_ALTA_GUARDAR: la accion de registro queda a cargo de quien da de alta el proyecto.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_GUARDAR: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO

/* ---------- 3. datos: acciones ya generadas por la regla ---------- */
UPDATE AP
   SET AP.ID_ENTIDAD = E.ID, AP.TIPO_ENTIDAD = 'EMPLEADO'
FROM dbo.VCT_ACCIONES_PARTICIPANTES AP
INNER JOIN dbo.VCT_ACCIONES A ON A.ID = AP.ID_ACCION
INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK) ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO = 'PROY_ANALISTA_ASIGNADO_REGISTRO'
CROSS APPLY (SELECT TOP 1 E9.ID FROM dbo.VCT_EMPLEADOS E9 WITH(NOLOCK)
             WHERE LOWER(LTRIM(RTRIM(ISNULL(E9.ID_USUARIO_SEGURIDAD,'')))) = LOWER(LTRIM(RTRIM(ISNULL(A.USUARIO_ALTA,''))))
             ORDER BY E9.ID DESC) E
WHERE AP.ROL_PARTICIPANTE = 'RESPONSABLE'
  AND NOT (AP.TIPO_ENTIDAD = 'EMPLEADO' AND AP.ID_ENTIDAD = E.ID);
PRINT 'OK   acciones de registro corregidas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT) + '.';

/* control: responsable y usuario que dio de alta, por proyecto */
SELECT TOP 20 A.ID AS ID_ACCION, P.CODIGO AS PROYECTO, A.USUARIO_ALTA, AP.TIPO_ENTIDAD, AP.ID_ENTIDAD,
       LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))) AS RESPONSABLE
FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK) ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO = 'PROY_ANALISTA_ASIGNADO_REGISTRO'
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO
LEFT JOIN dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK) ON AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE'
LEFT JOIN dbo.VCT_EMPLEADOS E WITH(NOLOCK) ON E.ID = AP.ID_ENTIDAD AND AP.TIPO_ENTIDAD = 'EMPLEADO'
ORDER BY A.ID DESC;
GO
