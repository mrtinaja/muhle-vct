CREATE  PROCEDURE [dbo].[SV_05_INICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OMENU		AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE
 
	SELECT	@VFECHA_DESDE = PrimerDiaMes, 
			@VFECHA_HASTA = UltimoDiaMes 
	FROM	Calendar 
	WHERE	Fecha = convert(varchar,GETDATE(),113)	
 
	UPDATE	TMT_SV_05
	SET		FECHA_DESDE = @VFECHA_DESDE, 
			FECHA_HASTA = @VFECHA_HASTA
	WHERE	PAR_KEY = @IPKEYJOB	
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-pie w3-large"></i>&nbsp;&nbsp;Reportes</span>
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
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''D81D513F-B122-4452-AA37-27149EC0C02E'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Parte de Actividades</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''F939CA2C-E6AA-45EC-8583-4108ADF04F7B'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Seguimiento de Consultoria</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''85D675B6-2A9E-4513-A90E-59E888465C9C'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Seguimiento de Auditoria</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''0287E26B-2E89-4816-9D25-0A6C1C5FEDDC'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Seguimiento de Capacitación</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''EAD5B2BE-755B-40F8-8C17-173A0DACAA4C'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Índice Ocupación Consultores</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''83A4857B-A604-4008-B608-0ADBE1B9B5BE'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Calificación Consultores</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''7A7D7C4F-0A0E-4313-B66B-B387D2D6FDFB'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Seguimiento de Hoteles</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''08B425FF-02CF-4686-BBA2-062C2FF53C7E'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Seguimiento de Pasajes</b></a>
				  </div>
				</li>
				<li class="w3-bar">      
				  <div class="w3-bar-item">
					<i class="fas fa-angle-right w3-large"></i>
					<a href="javascript:onclick=goto('''+@FORM_ID+''',''961EA09F-B7B9-4081-BFE4-014C1377D099'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Seguimiento de Remis/Taxi</b></a>
				  </div>
				</li>'+
				CASE WHEN dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'RENTABILIDAD.VIEW')=1 THEN
					'<li class="w3-bar">      
					  <div class="w3-bar-item">
						<i class="fas fa-angle-right w3-large"></i>
						<a href="javascript:onclick=goto('''+@FORM_ID+''',''361AE370-6363-45EF-A972-989A27FF2A87'');" class="w3-ul w3-muhle-text-14" style="color:#7f1d46"><b>Rentabilidad Proyectos</b></a>
					  </div>
					</li>'
				ELSE '' END + '
			  </ul>
			</div>
		</div>
	</div>
</div>'
 
END
