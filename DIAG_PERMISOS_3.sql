/* ========================================================================
   DIAG_PERMISOS_3 - SOLO LECTURA. No modifica nada.
   Propone el vinculo usuario (Users) <-> consultor / empleado cruzando por
   EMAIL y, si no hay email, por NOMBRE (Apellido Nombres). Tambien lista
   quienes no tienen usuario y que usuarios del perfil PROYECTOS no
   coinciden con ningun consultor ni empleado (candidatos a depurar).
   Uso: ejecutar y copiar TODA la columna "linea" de la pestana Results.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));
IF OBJECT_ID('tempdb..#ENT') IS NOT NULL DROP TABLE #ENT;
CREATE TABLE #ENT (tipo NVARCHAR(20), id INT, nombre NVARCHAR(300), estado NVARCHAR(30), usuario NVARCHAR(100));
IF OBJECT_ID('tempdb..#VINC') IS NOT NULL DROP TABLE #VINC;
CREATE TABLE #VINC (usuario NVARCHAR(100), tipo NVARCHAR(20), id INT, via NVARCHAR(10));

/* ---- cargar consultores y empleados en una sola tabla de trabajo ---- */
DECLARE @t TABLE (n INT IDENTITY(1,1), tabla SYSNAME, tipo NVARCHAR(20));
INSERT @t(tabla,tipo) VALUES (N'VCT_CONSULTORES',N'CONSULTOR'),(N'VCT_EMPLEADOS',N'EMPLEADO');
DECLARE @i INT=1, @tabla SYSNAME, @tipo NVARCHAR(20), @full NVARCHAR(300),
        @a NVARCHAR(300), @nm NVARCHAR(300), @es NVARCHAR(300), @us NVARCHAR(300), @sql NVARCHAR(MAX);
WHILE @i<=2
BEGIN
    SELECT @tabla=tabla,@tipo=tipo FROM @t WHERE n=@i;
    SET @full=N'dbo.'+@tabla;
    SET @a  = CASE WHEN COL_LENGTH(@full,'APELLIDOS') IS NOT NULL THEN N'ISNULL(CONVERT(NVARCHAR(150),X.APELLIDOS),N'''')'
                   WHEN COL_LENGTH(@full,'APELLIDO')  IS NOT NULL THEN N'ISNULL(CONVERT(NVARCHAR(150),X.APELLIDO),N'''')'
                   ELSE N'N''''' END;
    SET @nm = CASE WHEN COL_LENGTH(@full,'NOMBRES') IS NOT NULL THEN N'ISNULL(CONVERT(NVARCHAR(150),X.NOMBRES),N'''')'
                   WHEN COL_LENGTH(@full,'NOMBRE')  IS NOT NULL THEN N'ISNULL(CONVERT(NVARCHAR(150),X.NOMBRE),N'''')'
                   ELSE N'N''''' END;
    SET @es = CASE WHEN COL_LENGTH(@full,'ESTADO') IS NOT NULL THEN N'ISNULL(CONVERT(NVARCHAR(30),X.ESTADO),N'''')' ELSE N'N''''' END;
    SET @us = CASE WHEN COL_LENGTH(@full,'ID_USUARIO_SEGURIDAD') IS NOT NULL THEN N'ISNULL(CONVERT(NVARCHAR(100),X.ID_USUARIO_SEGURIDAD),N'''')' ELSE N'N''''' END;
    SET @sql = N'INSERT #ENT(tipo,id,nombre,estado,usuario) SELECT N'''+@tipo+N''', X.ID, LTRIM(RTRIM('+@a+N'+N'' ''+'+@nm+N')), '+@es+N', '+@us+N' FROM '+@full+N' X';
    EXEC(@sql);
    SET @i+=1;
END;

/* ---- vinculos propuestos ---- */
INSERT #VINC(usuario,tipo,id,via)
SELECT DISTINCT UPPER(LTRIM(RTRIM(U.Id))), X.tipo, X.id, N'email'
FROM dbo.Users U
INNER JOIN dbo.VCT_EMAILS E
        ON LOWER(LTRIM(RTRIM(E.EMAIL))) COLLATE DATABASE_DEFAULT = LOWER(LTRIM(RTRIM(U.Email))) COLLATE DATABASE_DEFAULT
INNER JOIN #ENT X
        ON X.tipo COLLATE DATABASE_DEFAULT = UPPER(LTRIM(RTRIM(E.TIPO_ENTIDAD))) COLLATE DATABASE_DEFAULT
       AND X.id = E.ID_ENTIDAD
WHERE NULLIF(LTRIM(RTRIM(ISNULL(U.Email,N''))),N'') IS NOT NULL;

INSERT #VINC(usuario,tipo,id,via)
SELECT DISTINCT UPPER(LTRIM(RTRIM(U.Id))), X.tipo, X.id, N'nombre'
FROM dbo.Users U
INNER JOIN #ENT X
        ON LTRIM(RTRIM(X.nombre)) COLLATE Latin1_General_CI_AI = LTRIM(RTRIM(U.Name)) COLLATE Latin1_General_CI_AI
WHERE NULLIF(LTRIM(RTRIM(X.nombre)),N'') IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM #VINC V WHERE V.usuario=UPPER(LTRIM(RTRIM(U.Id))));

/* ---- A. propuesta ---- */
INSERT #O(linea) VALUES (N'=== A. VINCULO PROPUESTO: usuario | perfil actual | entidad | estado entidad | via | usuario ya cargado en la entidad ===');
INSERT #O(linea)
SELECT V.usuario+N' | '+ISNULL((SELECT TOP 1 CONVERT(NVARCHAR(100),M.GroupId) FROM dbo.GroupsUserMembers M WHERE UPPER(LTRIM(RTRIM(M.UserMemberId)))=V.usuario),N'(sin perfil)')
      +N' | '+V.tipo+N' #'+CONVERT(NVARCHAR(20),V.id)+N' '+X.nombre
      +N' | '+X.estado+N' | '+V.via+N' | '+ISNULL(NULLIF(X.usuario,N''),N'-')
FROM #VINC V
INNER JOIN #ENT X ON X.tipo=V.tipo AND X.id=V.id
ORDER BY V.tipo,X.estado,X.nombre,V.usuario;

/* ---- B. entidades activas sin usuario candidato ---- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== B. CONSULTORES/EMPLEADOS ACTIVOS SIN USUARIO CANDIDATO (hay que crearles usuario en el admin): entidad | email(s) ===');
INSERT #O(linea)
SELECT X.tipo+N' #'+CONVERT(NVARCHAR(20),X.id)+N' '+X.nombre+N' | '
      +ISNULL(STUFF((SELECT N', '+CONVERT(NVARCHAR(200),E.EMAIL)
                     FROM dbo.VCT_EMAILS E
                     WHERE UPPER(LTRIM(RTRIM(E.TIPO_ENTIDAD))) COLLATE DATABASE_DEFAULT = X.tipo COLLATE DATABASE_DEFAULT AND E.ID_ENTIDAD=X.id
                     FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N''),N'(sin email)')
FROM #ENT X
WHERE UPPER(X.estado)=N'ACTIVO'
  AND NULLIF(X.usuario,N'') IS NULL
  AND NOT EXISTS (SELECT 1 FROM #VINC V WHERE V.tipo=X.tipo AND V.id=X.id)
ORDER BY X.tipo,X.nombre;

/* ---- C. usuarios PROYECTOS sin coincidencia ---- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== C. USUARIOS DEL PERFIL PROYECTOS SIN COINCIDENCIA con ningun consultor ni empleado (revisar / depurar): usuario | nombre | email ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(100),M.UserMemberId)+N' | '+ISNULL(CONVERT(NVARCHAR(200),U.Name),N'')+N' | '+ISNULL(CONVERT(NVARCHAR(200),U.Email),N'')
FROM dbo.GroupsUserMembers M
LEFT JOIN dbo.Users U ON U.Id=M.UserMemberId
WHERE UPPER(LTRIM(RTRIM(M.GroupId)))=N'PROYECTOS'
  AND NOT EXISTS (SELECT 1 FROM #VINC V WHERE V.usuario=UPPER(LTRIM(RTRIM(M.UserMemberId))))
ORDER BY M.UserMemberId;

/* ---- D. usuarios con mas de una coincidencia (ambiguos) ---- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== D. USUARIOS CON MAS DE UNA COINCIDENCIA (ambiguos, decidir a mano): usuario | cantidad ===');
INSERT #O(linea)
SELECT V.usuario+N' | '+CONVERT(NVARCHAR(10),COUNT(*))
FROM #VINC V
GROUP BY V.usuario
HAVING COUNT(*)>1
ORDER BY V.usuario;

DECLARE @nFilas INT=(SELECT COUNT(*) FROM #O);
PRINT N'Filas generadas: '+CONVERT(NVARCHAR(10),@nFilas)+N'. Copiar la columna "linea" de la pestana Results.';

SELECT linea FROM #O ORDER BY id;
GO
