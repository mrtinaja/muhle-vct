CREATE PROCEDURE [dbo].[PA_OPERATIVO_TRASPASO](
@PKEY_JOB   AS VARCHAR(100))
AS
DECLARE @PKEY_OPERATIVO   AS VARCHAR(36);
 
BEGIN
	print 'pkeyjob='+@PKEY_JOB;
	SET @PKEY_OPERATIVO = (SELECT OPERATIVO_SEL FROM GBL_OPERATIVOS WHERE PAR_KEY = @PKEY_JOB );
	print '@PKEY_OPERATIVO='+@PKEY_OPERATIVO;
	
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
	case 
		when ENVIAR_TRASPASO='1'  AND OP_FOTOCOPIA_DNI='1' AND VALIDACION_SSS='SSS_OK' AND FECHA_TRASPASO IS NULL
			then '<a><font color="green">TRASPASO OK</font></a>' 
		when FECHA_TRASPASO IS NOT NULL
			then '<a><font color="green">TRASPASO YA REALIZADO</font></a>' 
		ELSE '<a><font color="red">TRASPASO ERROR</font></a>' 
	end "Enviar Traspaso",
	FECHA_TRASPASO as  "Fecha Traspaso"
	FROM TITULARES T 
	WHERE T.PKEY_OPERATIVO = RTRIM(LTRIM(@PKEY_OPERATIVO)) 
	ORDER BY APELLIDO
 
END
 
