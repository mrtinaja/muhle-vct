-- ============================================================
-- Correccion de dbo.Calendar para el año 2026, en base al calendario
-- oficial (Resolucion 164/2025 -- dias no laborables con fines
-- turisticos -- + feriados inamovibles/trasladables de Ley 27.399).
-- Solo se tocan IsHoliday / Feriado / HolidayText, nunca las columnas
-- calculadas.
-- ============================================================

-- 1) Verificacion previa: confirmar el estado actual de las fechas que
--    vamos a tocar (deberia mostrar 0 en IsHoliday para las 9 altas, y
--    1 para el 18/11 que vamos a corregir).
SELECT Fecha, DiaNombre, IsHoliday, Feriado, HolidayText
FROM dbo.Calendar
WHERE Fecha IN (
    '2026-02-16','2026-02-17', -- Carnaval
    '2026-03-23',              -- Puente turistico (Resol. 164/2025)
    '2026-04-03',              -- Viernes Santo
    '2026-07-10',              -- Puente turistico (Resol. 164/2025)
    '2026-08-17',              -- Paso a la Inmortalidad de San Martin
    '2026-10-12',              -- Dia del Respeto a la Diversidad Cultural
    '2026-11-18',              -- INCORRECTO -- Soberania Nacional esta aca, deberia estar el 23
    '2026-11-23',              -- Dia de la Soberania Nacional (trasladado del viernes 20)
    '2026-12-07'               -- Puente turistico (Resol. 164/2025)
)
ORDER BY Fecha;

-- 2) CORRECCION: el 18/11 esta mal cargado (no es lunes, no corresponde
--    a ninguna regla de traslado). El feriado real es el 23/11. Se
--    limpia el 18/11 para que vuelva a ser un dia laborable normal.
UPDATE dbo.Calendar
   SET IsHoliday=0, Feriado=0, HolidayText=NULL
 WHERE Fecha='2026-11-18';

-- 3) ALTAS -- las 9 fechas que faltan
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Carnaval' WHERE Fecha='2026-02-16';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Carnaval' WHERE Fecha='2026-02-17';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Feriado puente turístico' WHERE Fecha='2026-03-23';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Viernes Santo' WHERE Fecha='2026-04-03';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Feriado puente turístico' WHERE Fecha='2026-07-10';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Paso a la Inmortalidad del General José de San Martín' WHERE Fecha='2026-08-17';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Día del Respeto a la Diversidad Cultural' WHERE Fecha='2026-10-12';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Día de la Soberanía Nacional' WHERE Fecha='2026-11-23';
UPDATE dbo.Calendar SET IsHoliday=1, Feriado=2, HolidayText='Feriado puente turístico' WHERE Fecha='2026-12-07';

-- 4) Verificacion posterior
SELECT Fecha, DiaNombre, IsHoliday, Feriado, HolidayText
FROM dbo.Calendar
WHERE Ano=2026 AND IsHoliday=1
ORDER BY Fecha;
