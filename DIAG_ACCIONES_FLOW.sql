/* ============================================================================
   DIAG_ACCIONES_FLOW   (SOLO LECTURA - salida por SELECT -> :OUT la captura)
   ----------------------------------------------------------------------------
   "Nueva" en Acciones hace next() -> window.next(FORM_ID) -> la plataforma rutea
   por STEP_TRANSACTION_FLOW segun el ACTION del buffer. Comparamos el ruteo de
   ACCIONES (rebota) contra CLIENTES (anda) para ver que transicion le falta a
   Acciones (o si apunta a un SP que no existe). No modifica nada.

   USO: SSMS -> menu Query -> "SQLCMD Mode" (activar) -> F5.
        Queda en: C:\Users\Usuario\Desktop\muhle-vct\_diag\ACCIONES_FLOW.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\ACCIONES_FLOW.txt
USE [MuhlePROD];
SET NOCOUNT ON;

/* 0) columnas de STEP_TRANSACTION_FLOW (para ubicar FROM/TO/ACTION/RETURN) */
SELECT '0_COLS_FLOW' AS _Q, ORDINAL_POSITION AS POS, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS LEN
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'STEP_TRANSACTION_FLOW'
ORDER BY ORDINAL_POSITION;

DECLARE @sql NVARCHAR(MAX);

/* 1) filas del flow que mencionen ACCIONES o el SP VCT_MAIN_ACCIONES */
SELECT @sql = N'SELECT ''1_FLOW_ACCIONES'' AS _Q, * FROM dbo.STEP_TRANSACTION_FLOW WHERE 1=0'
            + ISNULL((SELECT ' OR CONVERT(NVARCHAR(MAX),' + QUOTENAME(COLUMN_NAME) + ') LIKE ''%ACCION%'''
                      FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_NAME = 'STEP_TRANSACTION_FLOW'
                        AND DATA_TYPE IN ('varchar','nvarchar','char','nchar','text','ntext')
                      FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'), '');
EXEC sys.sp_executesql @sql;

/* 2) filas del flow que mencionen CLIENTES / el alta de cliente (referencia que anda) */
SELECT @sql = N'SELECT ''2_FLOW_CLIENTES'' AS _Q, * FROM dbo.STEP_TRANSACTION_FLOW WHERE 1=0'
            + ISNULL((SELECT ' OR CONVERT(NVARCHAR(MAX),' + QUOTENAME(COLUMN_NAME) + ') LIKE ''%CLIENTE%'''
                           + ' OR CONVERT(NVARCHAR(MAX),' + QUOTENAME(COLUMN_NAME) + ') LIKE ''%SV_02%'''
                      FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_NAME = 'STEP_TRANSACTION_FLOW'
                        AND DATA_TYPE IN ('varchar','nvarchar','char','nchar','text','ntext')
                      FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'), '');
EXEC sys.sp_executesql @sql;

/* 3) el FORM_ID de la pantalla Acciones: de que GUID sale VCT_MAIN_ACCIONES
      (PKEY en STORED_PROCEDURES) y a donde lo manda el flow */
SELECT '3_SP_ACCIONES_PKEY' AS _Q, PKEY, SP_CODE, SP_NAME
FROM dbo.STORED_PROCEDURES
WHERE SP_NAME LIKE '%VCT_MAIN_ACCIONES%' OR SP_CODE LIKE '%ACCION%';

:OUT stdout
