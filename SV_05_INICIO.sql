USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[SV_05_INICIO] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SV_05_INICIO]
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

	/* ============================================================
	   HUB DE REPORTES - VERSION MODERNA
	   ------------------------------------------------------------
	   Reemplaza el listado w3-ul/w3-bar legacy por una grilla de
	   cards clickeables (mismo lenguaje visual que las cards de
	   Configuracion: icono + titulo + subtitulo, hover, etc).
	   Se mantienen intactos los goto(FORM_ID, GUID) de cada item
	   para no tocar la navegacion hacia las grillas de destino.
	   ============================================================ */
	SET @OHEADER = '
<div class="vct-page vct-page-main" data-vct-page data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <div class="vct-page-header">
        <h1 class="vct-page-title"><span data-vct-icon="chart-bar"></span>&nbsp;Reportes</h1>
    </div>
    <p class="vct-page-subtitle" style="margin:-10px 0 18px;">Accedé a los reportes y seguimientos del sistema.</p>
    <section class="vct-card">
        <div class="vct-card-body">
            <div class="vct-reports-grid">'

	SET @OMENU =
				'<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''D81D513F-B122-4452-AA37-27149EC0C02E'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="list-checks"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Parte de Actividades</strong>
						<small>Registro diario de actividades del equipo.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''F939CA2C-E6AA-45EC-8583-4108ADF04F7B'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="briefcase"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Seguimiento de Consultoría</strong>
						<small>Estado y avance de los proyectos de consultoría.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''85D675B6-2A9E-4513-A90E-59E888465C9C'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="shield-check"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Seguimiento de Auditoría</strong>
						<small>Estado y avance de las auditorías en curso.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''0287E26B-2E89-4816-9D25-0A6C1C5FEDDC'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="graduation-cap"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Seguimiento de Capacitación</strong>
						<small>Estado y avance de las capacitaciones dictadas.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''EAD5B2BE-755B-40F8-8C17-173A0DACAA4C'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="users"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Índice Ocupación Consultores</strong>
						<small>Nivel de ocupación del equipo de consultores.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''83A4857B-A604-4008-B608-0ADBE1B9B5BE'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="star"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Calificación Consultores</strong>
						<small>Evaluaciones y puntajes de los consultores.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''7A7D7C4F-0A0E-4313-B66B-B387D2D6FDFB'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="building-2"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Seguimiento de Hoteles</strong>
						<small>Gastos y reservas de alojamiento.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''08B425FF-02CF-4686-BBA2-062C2FF53C7E'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="plane"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Seguimiento de Pasajes</strong>
						<small>Gastos y reservas de pasajes aéreos.</small>
					</span>
				</button>
				<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''961EA09F-B7B9-4081-BFE4-014C1377D099'');">
					<span class="vct-reports-card-icon"><span data-vct-icon="car"></span></span>
					<span class="vct-reports-card-copy">
						<strong>Seguimiento de Remis/Taxi</strong>
						<small>Gastos de traslados en remis y taxi.</small>
					</span>
				</button>'+
				CASE WHEN @IAGENTE IN ('avocaturo','svocaturo','jjvocaturo','cbielsa','mbolivieri') THEN
					'<button type="button" class="vct-reports-card" onclick="goto('''+@FORM_ID+''',''361AE370-6363-45EF-A972-989A27FF2A87'');">
						<span class="vct-reports-card-icon"><span data-vct-icon="circle-dollar-sign"></span></span>
						<span class="vct-reports-card-copy">
							<strong>Rentabilidad Proyectos</strong>
							<small>Monto, costos y margen de los proyectos.</small>
						</span>
					</button>'
				ELSE '' END + '
            </div>
        </div>
    </section>
</div>'

END
