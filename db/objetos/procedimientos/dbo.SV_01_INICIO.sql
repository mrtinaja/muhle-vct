CREATE   PROCEDURE [dbo].[SV_01_INICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OMENU		AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE
 
	--SELECT	1	as '<div>Opción</div>', 
	--		'<a style="cursor: pointer;color:blue" title="ABM Tipos Servicio" 
	--		 onclick="goto('''+@FORM_ID+''',''C6AD6921-F54B-4D59-94BE-1951BADC0AA3'');"><u>ABM Tipos Servicio</u></a>'	as '<div>Proceso</div>'
	--UNION ALL
	--SELECT	2,
	--		'<a style="cursor: pointer;color:blue" title="ABM Documentación" 
	--		 onclick="goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');"><u>ABM Documentación</u></a>'
	--UNION ALL
	--SELECT	3,
	--		'<a style="cursor: pointer;color:blue" title="ABM Documentación Relacionada" 
	--		 onclick="goto('''+@FORM_ID+''',''8374CCC7-378F-488E-950F-4AFFA6B56BD0'');"><u>ABM Documentación Relacionada</u></a>'
	--UNION ALL
	--SELECT	4,
	--		'<a style="cursor: pointer;color:blue" title="ABM Aptitudes" 
	--		 onclick="goto('''+@FORM_ID+''',''F6941E7F-13B6-483D-8513-CE40C0C35C6C'');"><u>ABM Aptitudes</u></a>'
	--UNION ALL
	--SELECT	5,
	--		'<a style="cursor: pointer;color:blue" title="ABM Empleado Aptitudes" 
	--		 onclick="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');"><u>ABM Empleado Aptitudes</u></a>'
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-cog w3-large"></i>&nbsp;&nbsp;Parametria</span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
SET @OMENU = 
		'<div class="w3-container">
			  <ul class="w3-ul w3-card-4 w3-border">
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>ABM Documentacion</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''F6941E7F-13B6-483D-8513-CE40C0C35C6C'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>ABM Aptitudes</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>ABM Empleado Aptitudes</b></a>
				  </div>
				</li>
			  </ul>
			</div>
		</div>
	</div>
</div>'
 
UPDATE	TMT_SV_01
SET		DESCRIPCION_TS = NULL,
		ESTADO_TS = NULL,
		CODIGO_DOC = NULL,
		DESCRIPCION_DOC = NULL,
		COMENTARIO_DOC = NULL,
		ESTADO_DOC = NULL,
		DETALLE_DOC = NULL,
		CLAVE_DOC = NULL,
		CLAVE_DETALLE = NULL,
		COMENTARIO_DET = NULL,
		DESCRIPCION_DET = NULL,
		ESTADO_DET = NULL,
		GRUPO_DET = NULL,
		TIPO_SERVICIO = NULL,
		DESCRIPCION_APT = NULL,
		ESTADO_APT = NULL,
		EMPLEADO = NULL,
		APTITUD = NULL,
		CALIFICACION = NULL,
		OBSERVACION = NULL,
		ERROR = NULL,
		ID_EMPLE_APTITUD = NULL,
		ORDEN = NULL
WHERE	PAR_KEY = @IPKEYJOB
 
END
 
