/* DIAG_FLUJO_INICIO (solo lectura) - correr con Query > SQLCMD Mode
   Flujo de pasos de la actividad VCT_GESTION: desde el Inicio "continuar"
   va a Clientes; buscamos un salto (goto + codigo) que vuelva al mismo paso
   para poder grabar desde Acciones / campanita sin cambiar de pantalla. */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_FLUJO_INICIO.txt
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== columnas ===';
SELECT T.name AS TABLA, C.column_id, C.name AS COLUMNA, TY.name AS TIPO
FROM sys.tables T JOIN sys.columns C ON C.object_id = T.object_id JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE T.name IN ('STEP_TRANSACTION_FLOW','CONV_STRUCTURE_STEP_NORMAL','CONV_STRUCTURE_STEP_TRAN','STORED_PROCEDURES','CALL_CONV_STRUCTURES')
ORDER BY T.name, C.column_id;
GO

PRINT '=== STORED_PROCEDURES de MAIN ===';
EXEC (N'SELECT * FROM dbo.STORED_PROCEDURES WHERE CONVERT(NVARCHAR(MAX), SP_NAME) LIKE N''%VCT_MAIN%'' OR CONVERT(NVARCHAR(MAX), SP_CODE) LIKE N''%VCT_MAIN%''');
GO

PRINT '=== pasos que usan esos SP ===';
EXEC (N'SELECT * FROM dbo.CONV_STRUCTURE_STEP_NORMAL WHERE CONVERT(NVARCHAR(MAX), STEP_AGENT_CAPTION) LIKE N''%Inicio%'' OR CONVERT(NVARCHAR(MAX), STEP_AGENT_CAPTION) LIKE N''%Cliente%'' OR CONVERT(NVARCHAR(MAX), STEP_AGENT_CAPTION) LIKE N''%Proyecto%'' OR CONVERT(NVARCHAR(MAX), STEP_AGENT_CAPTION) LIKE N''%Dashboard%''');
GO

PRINT '=== transiciones ===';
EXEC (N'SELECT TOP 300 * FROM dbo.STEP_TRANSACTION_FLOW');
GO
