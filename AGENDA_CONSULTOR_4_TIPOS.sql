/* ============================================================================
   AGENDA_CONSULTOR_4_TIPOS
   ----------------------------------------------------------------------------
   Amplia la agenda del consultor a TIPOS (como el productivo):
     DISPONIBLE (azul, carga horas), LICENCIA (rosa, motivo), OCUPADO/personal
     (gris), POTENCIAL (naranja, descripcion), ORGANISMO (teal, descripcion),
     OBSERVACION (coral, descripcion). Ademas, derivados en el calendario:
     ASIGNADO (verde, sale de las visitas), FERIADO fijo (rojo) / movible
     (violeta) (de dbo.Calendar) y NO_CARGADO (blanco).

   1) Agrega columnas TIPO y DESCRIPCION a VCT_PRM_AGENDA_CONSULTOR.
   2) Migra las filas existentes a un TIPO.
   3) Reescribe VCT_FN_AGENDA_CONSULTOR_RANGO para devolver el ESTADO por tipo
      + asignado + feriado + no-cargado, con HORAS y una NOTA (cliente/motivo/desc).

   Re-ejecutable. Compat 100/140.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO

/* ---------- 1) columnas nuevas ---------- */
IF COL_LENGTH('dbo.VCT_PRM_AGENDA_CONSULTOR','TIPO') IS NULL
    ALTER TABLE dbo.VCT_PRM_AGENDA_CONSULTOR ADD TIPO VARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.VCT_PRM_AGENDA_CONSULTOR','DESCRIPCION') IS NULL
    ALTER TABLE dbo.VCT_PRM_AGENDA_CONSULTOR ADD DESCRIPCION VARCHAR(400) NULL;
GO

/* ---------- 2) migrar filas existentes a un TIPO ---------- */
UPDATE dbo.VCT_PRM_AGENDA_CONSULTOR
   SET TIPO = CASE
                WHEN DISPONIBLE = 1 THEN 'DISPONIBLE'
                WHEN UPPER(ISNULL(MOTIVO,'')) LIKE '%LICEN%' THEN 'LICENCIA'
                ELSE 'OCUPADO'
              END
 WHERE TIPO IS NULL;
GO

/* ---------- 3) funcion de rango con ESTADO por tipo ---------- */
CREATE OR ALTER FUNCTION dbo.VCT_FN_AGENDA_CONSULTOR_RANGO
(
    @ID_CONSULTOR INT,
    @DESDE        DATE,
    @HASTA        DATE
)
RETURNS TABLE
AS
RETURN
(
    WITH OCUP_RAW AS
    (
        /* horas REGISTRADAS por dia */
        SELECT R.FECHA AS F, CONVERT(DECIMAL(9,2), ISNULL(R.HORAS,0)) AS H
        FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R
        WHERE R.ID_CONSULTOR = @ID_CONSULTOR
          AND R.FECHA BETWEEN @DESDE AND @HASTA
        UNION ALL
        /* horas PLANIFICADAS prorrateadas, en dias sin registro de esa visita */
        SELECT cal.Fecha,
               CONVERT(DECIMAL(9,2), ISNULL(VC.HORAS_PLANIFICADAS,0))
                   / NULLIF(COALESCE(NULLIF(V.DIAS,0), DC.N), 0)
        FROM dbo.VCT_PROYECTOS_VISITAS V
        JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA=V.ID AND VC.ID_CONSULTOR=@ID_CONSULTOR
        JOIN dbo.Calendar cal ON cal.Fecha BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))
        CROSS APPLY (SELECT COUNT(*) AS N FROM dbo.Calendar c2 WHERE c2.Fecha BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))) DC
        WHERE cal.Fecha BETWEEN @DESDE AND @HASTA
          AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R2 WHERE R2.ID_VISITA=V.ID AND R2.ID_CONSULTOR=@ID_CONSULTOR AND R2.FECHA=cal.Fecha)
    ),
    OCUP AS ( SELECT F, CONVERT(DECIMAL(9,2),SUM(H)) AS HORAS FROM OCUP_RAW GROUP BY F ),
    BASE AS
    (
        SELECT
            cal.Fecha,
            cal.IsHoliday,
            cal.HolidayText,
            CONVERT(INT, ISNULL(cal.Feriado,0)) AS FER_TIPO,   /* 1 fijo, 2 movible */
            AG.TIPO        AS AG_TIPO,
            AG.MOTIVO      AS AG_MOT,
            AG.DESCRIPCION AS AG_DESC,
            AG.DISPONIBLE  AS AG_DISP,
            CONVERT(DECIMAL(5,2), ISNULL(AG.HORAS_CAPACIDAD,8)) AS AG_HORAS,
            CONVERT(DECIMAL(9,2), ISNULL(O.HORAS,0)) AS OCUP
        FROM dbo.Calendar cal
        LEFT JOIN dbo.VCT_PRM_AGENDA_CONSULTOR AG ON AG.ID_CONSULTOR=@ID_CONSULTOR AND AG.FECHA=cal.Fecha
        LEFT JOIN OCUP O ON O.F=cal.Fecha
        WHERE cal.Fecha BETWEEN @DESDE AND @HASTA
    )
    SELECT
        @ID_CONSULTOR AS ID_CONSULTOR,
        B.Fecha AS FECHA,
        /* ESTADO: asignado (visita) > feriado > tipo cargado > no cargado */
        CASE
            WHEN B.OCUP > 0                         THEN 'ASIGNADO'
            WHEN B.IsHoliday = 1 AND B.FER_TIPO = 2 THEN 'FERIADO_MOV'
            WHEN B.IsHoliday = 1                    THEN 'FERIADO_FIJO'
            WHEN B.AG_TIPO IS NOT NULL              THEN B.AG_TIPO
            ELSE 'NO_CARGADO'
        END AS ESTADO,
        B.AG_TIPO AS TIPO,
        B.AG_MOT  AS MOTIVO,
        B.AG_DESC AS DESCRIPCION,
        /* horas a mostrar: asignado=visita; disponible=capacidad; resto=0 */
        CONVERT(DECIMAL(6,1),
            CASE WHEN B.OCUP > 0 THEN B.OCUP
                 WHEN B.AG_TIPO = 'DISPONIBLE' THEN B.AG_HORAS
                 ELSE 0 END) AS HORAS,
        /* nota para la celda */
        CASE
            WHEN B.OCUP > 0 THEN ISNULL((
                    SELECT TOP 1 LTRIM(RTRIM(ISNULL(NULLIF(C.RAZON_SOCIAL,''), P.NOMBRE)))
                    FROM dbo.VCT_PROYECTOS_VISITAS V
                    JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA=V.ID AND VC.ID_CONSULTOR=@ID_CONSULTOR
                    JOIN dbo.VCT_PROYECTOS P ON P.ID=V.ID_PROYECTO
                    LEFT JOIN dbo.VCT_CLIENTES C ON C.ID=P.IDCLIENTE
                    WHERE B.Fecha BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))
                    ORDER BY V.FECHA_DESDE DESC), 'Asignado')
            WHEN B.IsHoliday = 1 THEN B.HolidayText
            WHEN B.AG_TIPO = 'LICENCIA' THEN ISNULL(B.AG_MOT,'Licencia')
            WHEN B.AG_TIPO IN ('POTENCIAL','ORGANISMO','OBSERVACION') THEN ISNULL(B.AG_DESC,'')
            WHEN B.AG_TIPO = 'DISPONIBLE' THEN 'Disponible'
            WHEN B.AG_TIPO = 'OCUPADO' THEN ISNULL(NULLIF(B.AG_DESC,''),'Ocupado / personal')
            ELSE ''
        END AS NOTA
    FROM BASE B
);
GO
PRINT 'OK: VCT_FN_AGENDA_CONSULTOR_RANGO con tipos + VCT_PRM_AGENDA_CONSULTOR.TIPO/DESCRIPCION.';
GO
