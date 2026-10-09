/* insert_calendar_2028_2035.sql
   Genera los registros de dbo.Calendar para 2028-01-01 a 2035-12-31 inclusive,
   replicando exactamente el formato de las filas existentes (2018-2027):
   - DiaSemana/SemanaAno via DATEPART con DATEFIRST=7 (domingo=1 ... sabado=7)
   - DiaNombre/MesNombre en español, sin tildes (ej. "Miercoles", "Sabado")
   - SemanaMes = semana calendario dentro del mes (misma logica de DATEPART(WEEK,..))
   - MesAno = Mes*10000+Ano (ej. diciembre/2027 = 122027)
   - IsHoliday/HolidayText/Feriado en blanco (0/NULL/0) -- el alta real de feriados
     la hace VCT_MAIN_CALENDARIO despues, esto solo crea el "esqueleto" de fechas.
   Idempotente: no inserta fechas que ya existan en la tabla. */

SET DATEFIRST 7;
SET NOCOUNT ON;

;WITH Fechas AS (
    SELECT CAST('2028-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY,1,Fecha)
    FROM Fechas
    WHERE Fecha < '2035-12-31'
)
INSERT INTO dbo.Calendar
(
    Fecha, Dia, DiaSemana, DiaNombre, FinDeSemana, IsHoliday, HolidayText,
    DiaAno, SemanaMes, SemanaAno, Mes, MesNombre, Quarter, Ano, MesAno,
    PrimerDiaMes, UltimoDiaMes, PrimerDiaQuarter, UltimoDiaQuarter,
    PrimerDiaAno, UltimoDiaAno, PrimerDiaSiguienteMes, PrimerDiaSiguienteAno,
    Feriado
)
SELECT
    f.Fecha,
    DAY(f.Fecha) AS Dia,
    DATEPART(WEEKDAY,f.Fecha) AS DiaSemana,
    CASE DATEPART(WEEKDAY,f.Fecha)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END AS DiaNombre,
    CASE WHEN DATEPART(WEEKDAY,f.Fecha) IN (1,7) THEN 1 ELSE 0 END AS FinDeSemana,
    0 AS IsHoliday,
    NULL AS HolidayText,
    DATEPART(DAYOFYEAR,f.Fecha) AS DiaAno,
    DATEPART(WEEK,f.Fecha) - DATEPART(WEEK,DATEFROMPARTS(YEAR(f.Fecha),MONTH(f.Fecha),1)) + 1 AS SemanaMes,
    DATEPART(WEEK,f.Fecha) AS SemanaAno,
    MONTH(f.Fecha) AS Mes,
    CASE MONTH(f.Fecha)
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END AS MesNombre,
    DATEPART(QUARTER,f.Fecha) AS Quarter,
    YEAR(f.Fecha) AS Ano,
    MONTH(f.Fecha)*10000 + YEAR(f.Fecha) AS MesAno,
    DATEFROMPARTS(YEAR(f.Fecha),MONTH(f.Fecha),1) AS PrimerDiaMes,
    EOMONTH(f.Fecha) AS UltimoDiaMes,
    DATEFROMPARTS(YEAR(f.Fecha),(DATEPART(QUARTER,f.Fecha)-1)*3+1,1) AS PrimerDiaQuarter,
    EOMONTH(DATEFROMPARTS(YEAR(f.Fecha),DATEPART(QUARTER,f.Fecha)*3,1)) AS UltimoDiaQuarter,
    DATEFROMPARTS(YEAR(f.Fecha),1,1) AS PrimerDiaAno,
    DATEFROMPARTS(YEAR(f.Fecha),12,31) AS UltimoDiaAno,
    DATEADD(MONTH,1,DATEFROMPARTS(YEAR(f.Fecha),MONTH(f.Fecha),1)) AS PrimerDiaSiguienteMes,
    DATEFROMPARTS(YEAR(f.Fecha)+1,1,1) AS PrimerDiaSiguienteAno,
    0 AS Feriado
FROM Fechas f
WHERE NOT EXISTS (SELECT 1 FROM dbo.Calendar c WHERE c.Fecha = f.Fecha)
OPTION (MAXRECURSION 0);

SELECT MIN(Fecha) AS DesdeInsertado, MAX(Fecha) AS HastaInsertado, COUNT(*) AS TotalFilas
FROM dbo.Calendar
WHERE Fecha BETWEEN '2028-01-01' AND '2035-12-31';
