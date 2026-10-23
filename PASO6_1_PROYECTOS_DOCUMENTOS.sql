/* ============================================================================
   PASO6_1_PROYECTOS_DOCUMENTOS
   ----------------------------------------------------------------------------
   Crea dbo.VCT_PROYECTOS_DOCUMENTOS: documentos del proyecto (hoy la propuesta
   comercial; despues los del plan por item). El archivo NO se guarda aca: vive en
   la tabla del framework dbo.PHYSICAL_ATTACHED_DOCUMENT (upload task/UploadFile.ashx,
   archivo fisico en FILE_PATH). Esta tabla guarda la referencia (ID_ADJUNTO = PKEY).
     - Sin FK a PHYSICAL_ATTACHED_DOCUMENT (es del framework y no tiene PK).
     - Baja logica (ACTIVO / FECHA_BAJA / USUARIO_BAJA): el archivo no se borra.
   (VCT_PROYECTOS_DOCUMENTOS anterior se renombro a VCT_PROYECTOS_DATOS en PASO3_7.)
   No crea vistas, SPs ni permisos. Re-ejecutable: si la tabla existe, no hace nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID('dbo.VCT_PROYECTOS_DOCUMENTOS', 'U') IS NOT NULL
BEGIN
    PRINT 'VCT_PROYECTOS_DOCUMENTOS ya existe. No se hace nada.';
    RETURN;
END;

BEGIN TRY
    CREATE TABLE dbo.VCT_PROYECTOS_DOCUMENTOS (
        ID              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VCT_PROYECTOS_DOCUMENTOS PRIMARY KEY,
        ID_PROYECTO     INT           NOT NULL,
        ID_PLAN_ITEM    INT           NULL,          /* documentos por item del plan (a futuro) */
        TIPO            VARCHAR(30)   NOT NULL,      /* PROPUESTA_COMERCIAL, ... */
        ID_ADJUNTO      VARCHAR(36)   NOT NULL,      /* dbo.PHYSICAL_ATTACHED_DOCUMENT.PKEY */
        NOMBRE          VARCHAR(255)  NULL,          /* nombre original que se muestra */
        VISIBLE_CLIENTE BIT           NOT NULL CONSTRAINT DF_VCT_PROY_DOCS_VISIBLE DEFAULT (0),
        ACTIVO          BIT           NOT NULL CONSTRAINT DF_VCT_PROY_DOCS_ACTIVO  DEFAULT (1),
        FECHA_ALTA      DATETIME      NOT NULL CONSTRAINT DF_VCT_PROY_DOCS_FALTA   DEFAULT (GETDATE()),
        USUARIO_ALTA    VARCHAR(100)  NULL,
        FECHA_BAJA      DATETIME      NULL,
        USUARIO_BAJA    VARCHAR(100)  NULL,
        CONSTRAINT FK_VCT_PROY_DOCS_PROYECTO FOREIGN KEY (ID_PROYECTO) REFERENCES dbo.VCT_PROYECTOS (ID)
    );
    CREATE INDEX IX_VCT_PROY_DOCS_PROYECTO ON dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, TIPO, ACTIVO);
    CREATE INDEX IX_VCT_PROY_DOCS_ADJUNTO  ON dbo.VCT_PROYECTOS_DOCUMENTOS (ID_ADJUNTO);
    PRINT 'OK: VCT_PROYECTOS_DOCUMENTOS creada.';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('No se creo VCT_PROYECTOS_DOCUMENTOS: %s', 16, 1, @e);
END CATCH;
GO
