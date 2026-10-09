CREATE PROCEDURE [dbo].[HOME_INICIA_COTIZACION]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VESTADO  AS VARCHAR(50)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VESTADO = ISNULL(ESTADO_PROY,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	UPDATE	XAGENDA
	SET		ESTADO_PROY = CASE WHEN @VESTADO = '' THEN 'ENCURSO' ELSE @VESTADO END
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VESTADO = ISNULL(ESTADO_PROY,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-bar w3-large"></i>&nbsp;&nbsp;Propuestas</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''116FA485-BFEA-4883-AB54-CD2937DFD996'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
			<div class="w3-col w3-padding">
				<div class="w3-card-4 w3-round">
					<div class="w3-container w3-white w3-padding w3-round-up">
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado Proyecto</label>
							<select class="w3-input w3-round w3-border w3-muhle-text-12" id="cmb1" name="SP.ESTADO_PROY" onchange="goto('''+@FORM_ID+''',''1F3B9CBF-6330-4598-B517-9F8CCB08069E'');return false;">
							</select>
						</div>
						<div class="w3-col m1 w3-padding-small">
							<br>
							<button class="w3-button w3-muhle-text-14 w3-round w3-muhle-color w3-text-white" title="Buscar" onclick="goto('''+@FORM_ID+''',''1F3B9CBF-6330-4598-B517-9F8CCB08069E'');return false;"><i class="fas fa-search"></i></button>
						</div>
					</div>
				</div>
			</div>
	</div>
	<script>
		BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''8BFD95B3-1941-469E-97A7-3DBF4C875644'', '''+isnull(@VESTADO,'')+''', '''');
	</script>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	UPDATE	XAGENDA
	SET		NRO_COTIZA = NULL,
			CLAVE_COTIZA=NULL,
			CLIENTE = NULL,
			FECHA_COTIZA = NULL,
			ESTADO_COTIZA = NULL,
			ERROR = NULL,
			DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
 
 
