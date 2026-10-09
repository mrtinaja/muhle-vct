/* Definiciones completas (una linea por fila) de las dos funciones lentas de Auditoria.
   Solo lectura. En SSMS: Ctrl+T (Results to Text), ejecutar, y pegarme TODO el resultado
   (o Results to File y guardarlo en la carpeta muhle-vct). */
USE [MuhlePROD]
GO
SET NOCOUNT ON;
EXEC sp_helptext 'dbo.FN_GET_TOTAL_HS_EJECUTADAS';
EXEC sp_helptext 'dbo.FN_GET_SERVICIO_DIAS';
EXEC sp_helptext 'dbo.FN_GET_SERVICIO_CONSULTORES';
GO
