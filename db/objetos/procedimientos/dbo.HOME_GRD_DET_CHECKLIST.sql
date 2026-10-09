CREATE PROCEDURE [dbo].[HOME_GRD_DET_CHECKLIST]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO			VARCHAR(50),	
		@VSERVICIO			VARCHAR(50),
		@VID_HOJA			VARCHAR(50),
		@AcumuladoAbiertas	VARCHAR(max),
		@AcumuladoAbiertasSel	VARCHAR(max),
		@AcumuladoCerradas	VARCHAR(max),
		@AcumuladoCerradasSel	VARCHAR(max),
		@VABIERTA			VARCHAR(MAX),
		@VCERRADA			VARCHAR(MAX),
		@VSEPARADOR_A		INT,
		@VSEPARADOR_C		INT,
		@VQUERY				VARCHAR(MAX),
		@VID_AGENDA			VARCHAR(50)
 
BEGIN	
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VSERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VID_HOJA  = ISNULL(HOJA_RUTA_ID,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@AcumuladoAbiertas = COALESCE(@AcumuladoAbiertas + '; ' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'|'+DESC_DOC_DET, CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'|'+DESC_DOC_DET),
			@AcumuladoAbiertasSel = COALESCE(@AcumuladoAbiertasSel + '|' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'='+isnull(VALOR_DOC_DET,'false'), CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'='+isnull(VALOR_DOC_DET,'false'))	
	FROM	LK_PROYECTO_DOCUM_DET
	WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
	AND		GRUPO_DOC_DET = 'ABIERTAS'
 
	SET @AcumuladoAbiertas = @AcumuladoAbiertas + ';'
	SET @AcumuladoAbiertasSel = @AcumuladoAbiertasSel + '|'
 
	SELECT	@AcumuladoCerradas = COALESCE(@AcumuladoCerradas + '; ' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'|'+DESC_DOC_DET, CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'|'+DESC_DOC_DET),
			@AcumuladoCerradasSel = COALESCE(@AcumuladoCerradasSel + '|' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'='+isnull(VALOR_DOC_DET,'false'), CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'='+isnull(VALOR_DOC_DET,'false'))	
	FROM	LK_PROYECTO_DOCUM_DET
	WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
	AND		GRUPO_DOC_DET = 'CERRADAS'
 
	SET @AcumuladoCerradas = @AcumuladoCerradas + ';'
	SET @AcumuladoCerradasSel = @AcumuladoCerradasSel + '|'
 
	--<p style="font-style:italic;font-size:x-small;background-color:#AF7AC5;text-align:center">
	--<p style="font-size:xx-small;background-color:#D7BDE2;text-align:center">
 
	SET @VQUERY =	'SELECT	''<font color="#8E44AD"><p style="font-style:italic;font-size:x-small"><b>Abiertas</b></p></font>'' AS ''<font color  = "#ebeadb">Abiertas</font>'',
							''<font color="#D2B4DE"><p style="font-size:x-small"><b></b></p></font>''							AS ''<font color  = "#ebeadb">Valor</font>'',
							''<font color="#8E44AD"><p style="font-style:italic;font-size:x-small"><b>Cerradas</b></p></font>''	AS ''<font color  = "#ebeadb">Cerradas</font>'',
							''<font color="#D2B4DE"><p style="font-size:x-small"><b></b></p></font>''							AS ''<font color  = "#ebeadb">Dato</font>''
					 UNION ALL 
					 SELECT '
 
	WHILE LEN(@AcumuladoAbiertas) > 0 OR LEN(@AcumuladoCerradas) > 0
	BEGIN 
 
		SET @VSEPARADOR_A = CHARINDEX(';', @AcumuladoAbiertas ) -- Buscamos el caracter separador
		IF (@VSEPARADOR_A = 0)
		BEGIN
			SET @VABIERTA = @AcumuladoAbiertas
			SET @AcumuladoAbiertas = ''
		END
		ELSE
		BEGIN
 
			SET @VABIERTA = SUBSTRING(@AcumuladoAbiertas, 1, CHARINDEX(';',@AcumuladoAbiertas) - 1)
		
			SET @AcumuladoAbiertas = SUBSTRING(@AcumuladoAbiertas, CHARINDEX(';',@AcumuladoAbiertas) + 1, LEN(@AcumuladoAbiertas))
		
		END
 
		SET @VSEPARADOR_C = CHARINDEX(';', @AcumuladoCerradas ) -- Buscamos el caracter separador
		IF (@VSEPARADOR_C = 0)
		BEGIN
			SET @VCERRADA = @AcumuladoCerradas
			SET @AcumuladoCerradas = ''
		END
		ELSE
		BEGIN
			SET @VCERRADA = SUBSTRING(@AcumuladoCerradas, 1, CHARINDEX(';',@AcumuladoCerradas) - 1)
 
			SET @AcumuladoCerradas = SUBSTRING(@AcumuladoCerradas, CHARINDEX(';',@AcumuladoCerradas) + 1, LEN(@AcumuladoCerradas))
		END
		
		SET @VQUERY =	ISNULL(@VQUERY,'') + 
						''''+ '<font size="1">'+ISNULL(LTRIM(RTRIM(SUBSTRING(@VABIERTA,CHARINDEX('|',@VABIERTA) + 1,LEN(@VABIERTA)))),'') + '</font>' 
						+''','''+CASE WHEN ISNULL(@VABIERTA,'') = '' THEN '' ELSE '<input type="checkbox" id="'+ISNULL(LTRIM(RTRIM(SUBSTRING(@VABIERTA,1,CHARINDEX('|',@VABIERTA) -1))),'') +'"'+CASE WHEN ([dbo].[FN_GET_NORMA2](@AcumuladoAbiertasSel,ISNULL(LTRIM(RTRIM(SUBSTRING(@VABIERTA,1,CHARINDEX('|',@VABIERTA) -1))),'')) = 'true') THEN ' checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">' END   
						+ ''',''' + '<font size="1">'+ISNULL(LTRIM(RTRIM(SUBSTRING(@VCERRADA,CHARINDEX('|',@VCERRADA) + 1,LEN(@VCERRADA)))),'')+ '</font>' 
						+ ''','''+CASE WHEN ISNULL(@VCERRADA,'') = '' THEN '' ELSE '<input type="checkbox" id="'+ISNULL(LTRIM(RTRIM(SUBSTRING(@VCERRADA,1,CHARINDEX('|',@VCERRADA) -1))),'')+'"'+CASE WHEN ([dbo].[FN_GET_NORMA2](@AcumuladoCerradasSel,ISNULL(LTRIM(RTRIM(SUBSTRING(@VCERRADA,1,CHARINDEX('|',@VCERRADA) -1))),'')) = 'true') THEN ' checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">' END + ''''
						+' UNION ALL SELECT '
						--+CASE WHEN @VSEPARADOR_A <> 0 THEN ' UNION ALL SELECT ' ELSE '' END
 
	END
 
	SET @VQUERY =	SUBSTRING(@VQUERY,1,LEN(@VQUERY) - 17)
 
	EXEC(@VQUERY)
 
END
