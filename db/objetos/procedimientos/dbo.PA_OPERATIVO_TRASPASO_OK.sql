CREATE PROCEDURE [dbo].[PA_OPERATIVO_TRASPASO_OK](
@PKEY_JOB   AS VARCHAR(100))
AS
DECLARE @PKEY_OPERATIVO   AS VARCHAR(36);
DECLARE @NRO_OPERATIVO   AS INT;
 
BEGIN
	print 'pkeyjob='+@PKEY_JOB;
	SET @PKEY_OPERATIVO = (SELECT OPERATIVO_SEL FROM GBL_OPERATIVOS WHERE PAR_KEY = @PKEY_JOB );
	SET @NRO_OPERATIVO = (SELECT NRO_OPERATIVO FROM ABM_OPERATIVOS WHERE PKEY=@PKEY_OPERATIVO);
	print '@PKEY_OPERATIVO='+@PKEY_OPERATIVO;
	
	SELECT 	'<a href="javascript:window.open(''../aspx/TraspasosToExcel.aspx?nro_operativo='+CAST(@NRO_OPERATIVO AS VARCHAR)+''', ''Traspasos'', ''toolbar=no,menubar=no,scrollbars=yes,resizable=yes,width=800,height=600,top=10,left=10'')">Exportar Excel</a>' as Apellido,
	'' as Nombre, 
	'' as "Tipo Doc",
	'' as "Nro Doc",
	'' as CUIL,
	'' as "Estado",
	'' as Sexo,
	'' as "Estado Civil",
	'' as "Convenio",
	'' as "Fotocopia DNI",
	'' as "Validacion SSS",
	GETDATE() as "Fecha Traspaso"
	union
	SELECT 	APELLIDO Apellido,
	NOMBRE Nombre, 
	Tipo_doc as "Tipo Doc",
	nro_doc as "Nro Doc",
	ISNULL(CUIL,'') as CUIL,
	ESTADO as "Estado",
	ISNULL(sexo,'') as Sexo,
	ISNULL(estado_civil,'') as "Estado Civil",
	CONVENIO as "Convenio",
	case when OP_FOTOCOPIA_DNI='1' 
		then '<a><font color="green">DNI OK</font></a>' 
		else '<a><font color="red">Falta DNI</font></a>' 
	end "Fotocopia DNI",
	case when VALIDACION_SSS='SSS_OK' 
		then '<a><font color="green">VALIDADO OK</font></a>' 
		else '<a><font color="red">FALTA VALIDAR</font></a>' 
	end "Validacion SSS",
	FECHA_TRASPASO as  "Fecha Traspaso"
	FROM TITULARES T 
	WHERE T.PKEY_OPERATIVO = RTRIM(LTRIM(@PKEY_OPERATIVO)) 
	AND FECHA_TRASPASO IS NOT NULL
 
END
 
