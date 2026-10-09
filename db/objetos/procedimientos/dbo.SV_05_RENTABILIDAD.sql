CREATE PROCEDURE [dbo].[SV_05_RENTABILIDAD]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OPANEL	AS VARCHAR(MAX) OUTPUT
 )
AS
 
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME,
		@VCLIENTE		VARCHAR(50),
		@VPERIODO		VARCHAR(50),
		@VESTADO		VARCHAR(50)
 
BEGIN	
	
	SELECT	@VFECHA_DESDE = FECHA_DESDE,
			@VFECHA_HASTA = FECHA_HASTA,
			@VCLIENTE	  = ISNULL(CLIENTE,''),
			@VPERIODO	  = ISNULL(PERIODO,''),
			@VESTADO	  = ISNULL(ESTADO,'')
	FROM	TMT_SV_05 WITH (NOLOCK)
	WHERE	PAR_KEY = @IPKEYJOB;
 
	-----------------------------------------------------------------------------------------
	-- 1. HEADER BARRA PRINCIPAL (BORGOÑA SOLIDO Y TEXTO LEGIBLE)
	-----------------------------------------------------------------------------------------
	SET @OHEADER = '
	<div class="vct-export-ignore" id="vctHeaderModule" style="padding:16px 0px 8px 0px;box-sizing:border-box;width:100%;clear:both;">
		<div style="width:100%;">
			<div class="w3-card-4 w3-round" style="overflow:hidden;">
				<div class="w3-bar w3-padding" style="background-color:#7f1d46 !important;color:#ffffff !important;display:flex !important;align-items:center !important;justify-content:space-between !important;width:100% !important;box-sizing:border-box;">
					
					<!-- TITULO A LA IZQUIERDA -->
					<div style="display:flex;align-items:center;margin-right:auto;">
						<span class="w3-muhle-text-14" style="color:#ffffff !important;font-weight:600;display:inline-flex;align-items:center;gap:8px;">
							<i class="fas fa-chart-pie fa-fw w3-large" style="color:#ffffff !important;"></i> Rentabilidad Proyectos
						</span>
					</div>
 
					<!-- ACCIONES A LA DERECHA -->
					<div style="display:flex;gap:10px;align-items:center;margin-left:auto;">
						<span style="color:#ffffff !important;padding:0;display:inline-flex;align-items:center;">
							<i class="fas fa-arrow-alt-circle-left w3-large" style="cursor:pointer;color:#ffffff !important;" title="Volver" onclick="goto('''+@FORM_ID+''',''3156A499-EF81-4F52-818A-AE94DAF5583B'');return false;"></i>
						</span>
					</div>
 
				</div>
			</div>
		</div>
	</div>'
 
	-----------------------------------------------------------------------------------------
	-- 2. FILTROS EN LÍNEA HORIZONTAL ESTRUCTURADOS (DISPOSICIÓN INMUNE AL MAIN.CSS)
	-----------------------------------------------------------------------------------------
	SET @OPANEL = '
	<div style="padding:0px 0px 12px 0px;box-sizing:border-box;width:100%;clear:both;">
		<div style="width:100%;">
			<div class="w3-card-4 w3-round w3-white" style="padding:16px;border:1px solid #e2e8f0;box-sizing:border-box;background:#ffffff !important;">
				
				<!-- CONTENEDOR FLEXBOX HORIZONTAL FORZADO INLINE -->
				<div style="display:flex !important;flex-direction:row !important;align-items:flex-end !important;gap:12px !important;width:100% !important;box-sizing:border-box !important;flex-wrap:nowrap !important;">
					
					<!-- FILTRO CLIENTE -->
					<div style="flex:2 !important;min-width:200px !important;display:block !important;">
						<label class="w3-muhle-text-12" style="font-weight:700 !important;color:#475569 !important;margin-bottom:4px !important;display:block !important;">
							<i class="fas fa-user"></i>&nbsp;Cliente
						</label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-12" id="cmb3" name="SP.CLIENTE" style="height:38px !important;width:100% !important;box-sizing:border-box !important;background:#fff !important;"></select>						
					</div>
 
					<!-- FILTRO ESTADO -->
					<div style="flex:1 !important;min-width:150px !important;display:block !important;">
						<label class="w3-muhle-text-12" style="font-weight:700 !important;color:#475569 !important;margin-bottom:4px !important;display:block !important;">
							<i class="fa fa-adjust"></i>&nbsp;Estado
						</label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-12" id="cmb4" name="SP.ESTADO" style="height:38px !important;width:100% !important;box-sizing:border-box !important;background:#fff !important;"></select>						
					</div>
 
					<!-- FILTRO PERIODO -->
					<div style="flex:1 !important;min-width:140px !important;display:block !important;">
						<label class="w3-muhle-text-12" style="font-weight:700 !important;color:#475569 !important;margin-bottom:4px !important;display:block !important;">
							<i class="fas fa-calendar"></i>&nbsp;Período (YYYY-MM)
						</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-12" type="month" name="SP.PERIODO" value="'+ISNULL(@VPERIODO,'')+'" style="height:38px !important;width:100% !important;box-sizing:border-box !important;background:#fff !important;">
					</div>
 
					<!-- BOTONES DE ACCIÓN LADO A LADO -->
					<div style="display:flex !important;gap:8px !important;align-items:center !important;height:38px !important;flex-shrink:0 !important;">
						<!-- BUSCAR -->
						<button class="w3-button w3-round w3-text-white" style="height:38px !important;padding:0 16px !important;background-color:#7f1d46 !important;color:#ffffff !important;display:inline-flex !important;align-items:center !important;justify-content:center !important;font-weight:600 !important;border:none !important;" title="Buscar" onclick="goto('''+@FORM_ID+''',''361AE370-6363-45EF-A972-989A27FF2A87'');return false;">
							<i class="fas fa-search"></i>
						</button>
 
						<!-- VER GRÁFICO -->
						<button class="w3-button w3-round w3-text-white" style="height:38px !important;padding:0 16px !important;background-color:#7f1d46 !important;color:#ffffff !important;display:inline-flex !important;align-items:center !important;justify-content:center !important;font-weight:600 !important;border:none !important;" title="Ver Gráfico" onclick="goto('''+@FORM_ID+''',''ED54D50C-E35F-4827-B15A-84CD851A328F'');return false;">
							<i class="fas fa-chart-pie fa-fw"></i>
						</button>
					</div>
 
				</div>
			</div>
		</div>
	</div>
 
	<!-- CONTENEDOR GRILLA DATATABLES -->
	<div style="padding:0px 0px 16px 0px;box-sizing:border-box;width:100%;clear:both;">
		<div style="width:100%;">
			<div class="w3-card-4 w3-round w3-white" style="padding:16px;border:1px solid #e2e8f0;box-sizing:border-box;background:#ffffff !important;">
	
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''VW_CLIENTES'', '''+ISNULL(@VCLIENTE,'')+''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '3C2B554E-4339-4492-90D3-AE93773FB5D1' + ''', ''' + ISNULL(@VESTADO,'') +''', '''');</script>'
 
END
