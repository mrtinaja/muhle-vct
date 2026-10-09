USE [MuhlePROD]
GO

-- Datos de prueba para validar el Reporte 1 (Actividad) en pantalla
EXEC dbo.VCT_LOG_AUDITORIA
     @MODULO = 'PERFILES', @ACCION = 'ALTA', @USER_ID = 'administrador',
     @REGISTRO_AFECTADO = 'GERENCIA', @DETALLE = 'Alta de perfil: Gerencia (prueba)';

EXEC dbo.VCT_LOG_AUDITORIA
     @MODULO = 'PERFILES', @ACCION = 'MODIFICACION', @USER_ID = 'administrador',
     @REGISTRO_AFECTADO = 'PROYECTOS', @DETALLE = 'Edición de perfil: Proyectos -> Proyectos Internos (prueba)';

EXEC dbo.VCT_LOG_AUDITORIA
     @MODULO = 'USUARIOS', @ACCION = 'ALTA', @USER_ID = 'administrador',
     @REGISTRO_AFECTADO = 'jperez', @DETALLE = 'Alta de usuario jperez (prueba)';

EXEC dbo.VCT_LOG_AUDITORIA
     @MODULO = 'USUARIOS', @ACCION = 'MODIFICACION', @USER_ID = 'administrador',
     @REGISTRO_AFECTADO = 'cromero', @DETALLE = 'Edición de usuario cromero (prueba)';

EXEC dbo.VCT_LOG_AUDITORIA
     @MODULO = 'ESTRUCTURA', @ACCION = 'ALTA', @USER_ID = 'administrador',
     @REGISTRO_AFECTADO = '12', @DETALLE = 'Alta de sector: Sector Prueba';

EXEC dbo.VCT_LOG_AUDITORIA
     @MODULO = 'PERFIL_ADMIN', @ACCION = 'ASOCIAR', @USER_ID = 'administrador',
     @REGISTRO_AFECTADO = 'GERENCIA', @DETALLE = 'Permiso "Crear clientes" habilitado para el perfil Gerencia (prueba)';

SELECT TOP 20 * FROM dbo.M_AUDITORIA_ADMIN ORDER BY Fecha DESC;
