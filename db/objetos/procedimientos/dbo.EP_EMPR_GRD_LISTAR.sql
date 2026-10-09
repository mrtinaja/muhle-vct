 
CREATE PROCEDURE [dbo].[EP_EMPR_GRD_LISTAR]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID AS VARCHAR(100))
AS
 
BEGIN	
 
 
	SELECT Empresa, '<a href="javascript:saveSelection(''ID_EMPRESA_SEL'', '''+cast(IDEmpresa as varchar)+''');goto('''+@FORM_ID+''',''C902C963-5172-45A4-984B-DC9730767097'')">Ver Cronogramas</a>' AS Opciones
	FROM EP_EMPRESAS 
 
END
