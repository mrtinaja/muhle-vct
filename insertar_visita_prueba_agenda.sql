/* insertar_visita_prueba_agenda.sql
   Crea UNA visita de prueba en el mes calendario en curso, para el
   consultor 19 (Nowak), reusando el Cliente/Proyecto reales de su visita
   de enero 2026 (YPF S.A. / Mantenimiento del SGA) -- no se inventa un
   cliente falso, se copian los IDs de una visita real ya existente.

   Queda marcada de forma inconfundible en DESCRIPCION/USUARIO_ALTA para
   poder ubicarla y borrarla despues de probar. Al final del script te
   devuelve el ID nuevo de la visita -- guardalo para el DELETE de limpieza
   (comentado, al pie de este mismo archivo). */

SET NOCOUNT ON;

DECLARE @ID_CONSULTOR INT = 19;

-- Traemos IDCLIENTE/IDPROYECTO/IDPROYECTOSERVICIO/ESTADO de una visita real
-- ya cargada para ese consultor, para no inventar FKs.
DECLARE @IDCLIENTE INT, @IDPROYECTO INT, @IDPROYECTOSERVICIO INT, @ESTADO VARCHAR(20);

SELECT TOP 1
    @IDCLIENTE = V.IDCLIENTE,
    @IDPROYECTO = V.IDPROYECTO,
    @IDPROYECTOSERVICIO = V.IDPROYECTOSERVICIO,
    @ESTADO = V.ESTADO
FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
INNER JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID = VC.IDVISITA
WHERE VC.IDCONSULTOR = @ID_CONSULTOR
ORDER BY V.FECHA_DESDE DESC;

IF @IDCLIENTE IS NULL
BEGIN
    RAISERROR('No se encontro ninguna visita previa para el consultor %d de donde copiar Cliente/Proyecto.', 16, 1, @ID_CONSULTOR);
    RETURN;
END

DECLARE @NuevaVisita TABLE (ID INT);

INSERT INTO dbo.VCT_PROYECTOS_VISITAS
    (IDCLIENTE, IDPROYECTO, IDPROYECTOSERVICIO, FECHA_DESDE, FECHA_HASTA, DESCRIPCION, ESTADO, FECHA_ALTA, USUARIO_ALTA)
OUTPUT INSERTED.ID INTO @NuevaVisita
VALUES
    (@IDCLIENTE, @IDPROYECTO, @IDPROYECTOSERVICIO,
     DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 15), -- mitad del mes en curso
     NULL,
     'PRUEBA AGENDA - BORRAR - test de {{AGENDA}} en VCT_MAIN_SEND_EMAIL',
     @ESTADO,
     GETDATE(), 'TEST_AGENDA');

DECLARE @IDVISITA INT = (SELECT TOP 1 ID FROM @NuevaVisita);

INSERT INTO dbo.VCT_PROYECTOS_VISITAS_CONSULTORES
    (IDVISITA, IDCONSULTOR, FECHA_ALTA, USUARIO_ALTA)
VALUES
    (@IDVISITA, @ID_CONSULTOR, GETDATE(), 'TEST_AGENDA');

SELECT @IDVISITA AS ID_VISITA_CREADA, @ID_CONSULTOR AS ID_CONSULTOR, @IDCLIENTE AS ID_CLIENTE, @IDPROYECTO AS ID_PROYECTO;

/* ------------------------------------------------------------------------
   LIMPIEZA (correr despues de probar, reemplazando <ID_VISITA_CREADA>
   por el valor que te devolvio el SELECT de arriba):

   DELETE FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WHERE IDVISITA = <ID_VISITA_CREADA>;
   DELETE FROM dbo.VCT_PROYECTOS_VISITAS WHERE ID = <ID_VISITA_CREADA>;

   O, para borrar TODO lo que haya quedado marcado como prueba sin acordarte
   del ID exacto:

   DELETE VC FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
   INNER JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID = VC.IDVISITA
   WHERE V.USUARIO_ALTA = 'TEST_AGENDA';

   DELETE FROM dbo.VCT_PROYECTOS_VISITAS WHERE USUARIO_ALTA = 'TEST_AGENDA';
   ------------------------------------------------------------------------ */
