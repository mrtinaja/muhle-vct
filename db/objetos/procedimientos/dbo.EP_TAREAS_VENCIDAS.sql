create PROCEDURE [dbo].[EP_TAREAS_VENCIDAS]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100))
AS
BEGIN	
	
 
 
 SELECT TOP 10 TIPO.Descripcion, ISNULL(CRON.Descripcion, SUB.Impresion) as Tarea,
	CASE 
		WHEN CRON.IDESTADO = 1 THEN '<i class="fas fa-circle w3-text-red w3-large"></i>'
		WHEN CRON.IDESTADO = 2 THEN '<i class="fas fa-circle w3-text-yellow w3-large"></i>' 
		WHEN CRON.IDESTADO = 3 THEN '<i class="fa fa-circle w3-text-orange w3-large"></i>' 
		WHEN CRON.IDESTADO = 4 THEN '<i class="fas fa-circle w3-text-green w3-large"></i>'
	END as Estado
FROM EP_CRONOGRAMA CRON
INNER JOIN EP_EMPRESAS EMP ON EMP.IdEmpresa=CRON.IdEmpresa
INNER JOIN EP_PLANTAS  P ON P.IdPlanta=CRON.IdPlanta
INNER JOIN [EP_TIPO_TAREA_CRON] TIPO ON TIPO.ID=CRON.IdTipoTareaCronograma
INNER JOIN [EP_SUBTIPO_TAREA_CRON] SUB ON SUB.IDSubtipoTareaCronograma=CRON.IDSubtipoTareaCronograma
INNER JOIN [EP_MESES] M on M.IDMes=CRON.IdMes
INNER JOIN [EP_ESTADOS] E on E.IdEstado=CRON.IdEstado
INNER JOIN [EP_PLANTAS_USUARIOS] PU ON PU.IdPlanta=CRON.IdPlanta
where PU.IdUsuario=@IAGENTE
  
 
END
