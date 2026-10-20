/* ============================================================================
   DIAG_ACCIONES_FORMS   (SOLO LECTURA - salida por SELECT -> :OUT la captura)
   ----------------------------------------------------------------------------
   Objetivo: encontrar a que form/GUID debe ir "Nueva" en la pantalla Acciones.
   - El TARGET_GUID lo lee VCT_MAIN_GET_ACTIONS de dbo.PrmActions.TargetGuid.
     Para ACCIONES.CREATE vino VACIO -> por eso "Nueva" rebota.
   1) PrmActions de ACCIONES.*  (lo que esta MAL: TargetGuid vacio)
   2) PrmActions de CLIENTES.* y CONSULTORES.*  (modulos donde "Nueva" SI anda:
      muestran a que GUID apunta un alta que funciona)
   3) STORED_PROCEDURES: forms registrados que mencionen ACCION (candidato destino
      + su GUID). Primero vuelca columnas para ubicar la col de GUID/nombre.
   No modifica nada.

   USO: SSMS -> menu Query -> "SQLCMD Mode" (activar) -> F5.
        Queda en: C:\Users\Usuario\Desktop\muhle-vct\_diag\ACCIONES_FORMS.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\ACCIONES_FORMS.txt
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1) PrmActions de ACCIONES (el que hay que arreglar) */
SELECT '1_ACCIONES' AS _Q, PA.*
FROM dbo.PrmActions PA
WHERE UPPER(PA.ActionID) LIKE 'ACCIONES.%'
ORDER BY PA.ActionID;

/* 2) PrmActions de modulos donde "Nueva" funciona (referencia de GUID valido) */
SELECT '2_REF_OK' AS _Q, PA.*
FROM dbo.PrmActions PA
WHERE UPPER(PA.ActionID) LIKE 'CLIENTES.%'
   OR UPPER(PA.ActionID) LIKE 'CONSULTORES.%'
   OR UPPER(PA.ActionID) LIKE 'PROVEEDORES.%'
ORDER BY PA.ActionID;

/* 3a) columnas de STORED_PROCEDURES (para ubicar la col de GUID y de nombre) */
SELECT '3a_COLS_SP' AS _Q, ORDINAL_POSITION AS POS, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS LEN
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'STORED_PROCEDURES'
ORDER BY ORDINAL_POSITION;

/* 3b) forms de STORED_PROCEDURES que mencionen ACCION (candidato destino + GUID) */
DECLARE @sql NVARCHAR(MAX);
SELECT @sql = N'SELECT ''3b_SP_ACCION'' AS _Q, * FROM dbo.STORED_PROCEDURES WHERE 1=0'
            + ISNULL((SELECT ' OR CONVERT(NVARCHAR(MAX),' + QUOTENAME(COLUMN_NAME) + ') LIKE ''%ACCION%'''
                      FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_NAME = 'STORED_PROCEDURES'
                        AND DATA_TYPE IN ('varchar','nvarchar','char','nchar','text','ntext')
                      FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'), '');
EXEC sys.sp_executesql @sql;

/* 3c) por si el form se llama VCT_MAIN_RENDER_FORM / alta generica */
SELECT @sql = N'SELECT ''3c_SP_FORM'' AS _Q, * FROM dbo.STORED_PROCEDURES WHERE 1=0'
            + ISNULL((SELECT ' OR CONVERT(NVARCHAR(MAX),' + QUOTENAME(COLUMN_NAME) + ') LIKE ''%RENDER_FORM%'''
                           + ' OR CONVERT(NVARCHAR(MAX),' + QUOTENAME(COLUMN_NAME) + ') LIKE ''%ALTA%'''
                      FROM INFORMATION_SCHEMA.COLUMNS
                      WHERE TABLE_NAME = 'STORED_PROCEDURES'
                        AND DATA_TYPE IN ('varchar','nvarchar','char','nchar','text','ntext')
                      FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'), '');
EXEC sys.sp_executesql @sql;

:OUT stdout
