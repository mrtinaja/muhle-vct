 
CREATE PROCEDURE [dbo].[EP_EQUIPOS_GRD_CERTIF]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID as varchar(100))
AS
 
BEGIN	
 
	DECLARE 
	@EQ_SEL VARCHAR(36),
	@ACTION VARCHAR(50)
 
	SELECT @EQ_SEL=EQ_SEL, @ACTION=[ACTION] FROM TMT_CRON WHERE PAR_KEY = @IPKEYJOB;
 
 
	IF (@IAGENTE='admin') or (@IAGENTE='estrucplan')
		begin
			SELECT
				case when ec.estado='VIGENTE' then '<i class="fas fa-circle w3-text-green" style="cursor:pointer;" title="Poner Desvigente" onclick="saveSelection(''EQ_CERTIF_SEL'', '''+EC.ID+''');goto('''+@FORM_ID+''',''665B11DA-5FC3-4F2D-803D-3B0956A5C807'');return false;"></i>' else
				'<i class="fas fa-circle w3-text-red" style="cursor:pointer;" title="Poner Vigente"  onclick="saveSelection(''EQ_CERTIF_SEL'', '''+EC.ID+''');goto('''+@FORM_ID+''',''665B11DA-5FC3-4F2D-803D-3B0956A5C807'');return false;"></i>' end AS Estado,
				 EC.FechaDesde, EC.FechaHasta,
				'<a href="javascript:saveSelection(''EQ_CERTIF_SEL'', '''+EC.ID+''');goto('''+@FORM_ID+''',''E4A1CEA2-E7F1-42AC-9771-3C21A1DFE47A'');">Eliminar</a>&nbsp;&nbsp;<i class="fas fa-file-pdf w3-large" style="cursor:pointer;" title="Ver Certif." onclick="OpenAttach('''+ISNULL(PA.PKEY,'')+''','''+ISNULL(PA.FILE_NAME,'')+''');return false;"></i>' AS Opciones
			FROM EP_EQUIPOS_CERTIF EC
			LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT PA ON PA.PAR_KEY = EC.ID
			where IdEquipo=@EQ_SEL
			order by 1
		end
	else
		begin
			SELECT
				case when ec.estado='VIGENTE' then '<i class="fas fa-circle w3-text-green" title="Vigente"></i>' else
				'<i class="fas fa-circle w3-text-red" title="NO Vigente"></i>' end AS Estado,
				 EC.FechaDesde, EC.FechaHasta,
				'<i class="fas fa-file-pdf w3-large" style="cursor:pointer;" title="Ver Certif." onclick="OpenAttach('''+ISNULL(PA.PKEY,'')+''','''+ISNULL(PA.FILE_NAME,'')+''');return false;"></i>' AS Certificado
			FROM EP_EQUIPOS_CERTIF EC
			LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT PA ON PA.PAR_KEY = EC.ID
			where IdEquipo=@EQ_SEL
			order by 1
		end
 
END
