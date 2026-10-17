/* ============================================================================
   AGENDA_CONSULTOR_8_ACTIVIDADES   (marca ACTIVIDADES_V1)
   ----------------------------------------------------------------------------
   Modelo NUEVO: actividades del consultor CON HORARIO (hora desde/hasta),
   varias por dia -> habilita la vista semanal estilo Google Calendar.

   Convive con el modelo de DISPONIBILIDAD (VCT_PRM_AGENDA_CONSULTOR):
     - La disponibilidad (findes/feriados/bloqueos/capacidad) sigue igual y va
       de FONDO en la grilla.
     - Las ACTIVIDADES son los bloques de color con horario (reuniones, tareas,
       capacitaciones, auditorias, proyecto, otros).

   Objetos:
     1) Tabla    dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD
     2) Funcion  dbo.VCT_FN_AGENDA_ACTIVIDADES_RANGO(@CONS,@DESDE,@HASTA)
     Sin datos de demostracion. Re-ejecutable.

   Re-ejecutable. Compat 100/140 (sin OPENJSON/STRING_AGG/TRY_CONVERT).
   TIPO (define color en el front):
     REUNION_CLIENTE (azul) PROYECTO (verde) TAREA (naranja)
     CAPACITACION (violeta) AUDITORIA (rosa)  OTRO (gris)
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------------
   1) TABLA  VCT_AGENDA_CONSULTOR_ACTIVIDAD
   --------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD') IS NULL
BEGIN
    CREATE TABLE dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD
    (
        ID            INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_VCT_AGENDA_ACT PRIMARY KEY,
        ID_CONSULTOR  INT          NOT NULL
            CONSTRAINT FK_VCT_AGENDA_ACT_CONS REFERENCES dbo.VCT_CONSULTORES (ID),
        FECHA         DATE         NOT NULL,
        HORA_DESDE    TIME(0)      NOT NULL,
        HORA_HASTA    TIME(0)      NOT NULL,
        TIPO          VARCHAR(20)  NOT NULL
            CONSTRAINT DF_VCT_AGENDA_ACT_TIPO DEFAULT ('OTRO'),
        TITULO        VARCHAR(150) NOT NULL,
        SUBTITULO     VARCHAR(200) NULL,
        DESCRIPCION   VARCHAR(MAX) NULL,
        ID_PROYECTO   INT          NULL,
        ID_CLIENTE    INT          NULL,
        COLOR         VARCHAR(20)  NULL,   -- override opcional; si NULL, el color sale del TIPO
        ACTIVO        BIT          NOT NULL CONSTRAINT DF_VCT_AGENDA_ACT_ACT DEFAULT (1),
        FECHA_ALTA    DATETIME     NULL CONSTRAINT DF_VCT_AGENDA_ACT_FA DEFAULT (GETDATE()),
        USUARIO_ALTA  VARCHAR(100) NULL,
        FECHA_UPD     DATETIME     NULL,
        USUARIO_UPD   VARCHAR(100) NULL
    );
    CREATE INDEX IX_VCT_AGENDA_ACT_CONS_FECHA
        ON dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD (ID_CONSULTOR, FECHA) WHERE ACTIVO = 1;
    PRINT 'Tabla VCT_AGENDA_CONSULTOR_ACTIVIDAD creada.';
END
ELSE
    PRINT 'Tabla VCT_AGENDA_CONSULTOR_ACTIVIDAD ya existia. Sin cambios de estructura.';
GO

/* ---------------------------------------------------------------------------
   2) FUNCION  VCT_FN_AGENDA_ACTIVIDADES_RANGO
      Devuelve las actividades activas del consultor en el rango, ordenables
      por fecha/hora. HD/HH como VARCHAR 'HH:MM' listo para el front.
   --------------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.VCT_FN_AGENDA_ACTIVIDADES_RANGO
(
    @ID_CONSULTOR INT,
    @DESDE        DATE,
    @HASTA        DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        A.ID,
        A.ID_CONSULTOR,
        A.FECHA,
        CONVERT(VARCHAR(5), A.HORA_DESDE, 108) AS HD,   -- HH:MM
        CONVERT(VARCHAR(5), A.HORA_HASTA, 108) AS HH,
        A.TIPO,
        A.TITULO,
        A.SUBTITULO,
        A.COLOR,
        A.ID_PROYECTO,
        A.ID_CLIENTE
    FROM dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD A
    WHERE A.ID_CONSULTOR = @ID_CONSULTOR
      AND A.ACTIVO = 1
      AND A.FECHA BETWEEN @DESDE AND @HASTA
);
GO
PRINT 'Funcion VCT_FN_AGENDA_ACTIVIDADES_RANGO creada/actualizada.';
GO
