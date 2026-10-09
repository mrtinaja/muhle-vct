-- Definición completa de la función que arma el chequeo de permisos de MAIN
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_GET_ACTIONS')) AS Definicion;
GO

-- Las dos funciones scalares relacionadas, por si el chequeo real pasa por ahí
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_USER_HAS_ACTION')) AS Definicion;
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_USER_GET_ACTIONS')) AS Definicion;
GO

-- Y por si CONFIGURACION.EDIT/VIEW deberían tener fila en PrmActions y no la tienen:
SELECT * FROM dbo.PrmActions WHERE ActionID LIKE 'CONFIGURACION.%';
