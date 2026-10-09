CREATE PROCEDURE [dbo].[EP_EQUIPOS_GRD_LISTAR]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID as varchar(100))
AS
 
BEGIN	
 
	declare @TIPO VARCHAR(50),
	@ESTADO VARCHAR(50),
	@QUERY VARCHAR(MAX)
 
	set @QUERY=''
 
	UPDATE TMT_CRON SET [ACTION]='ADD_EQUIPO' WHERE PAR_KEY= @IPKEYJOB;
 
	select @TIPO=EQ_TIPO, @ESTADO= EQ_ESTADO from TMT_CRON where PAR_KEY=@IPKEYJOB;
 
	IF (ISNULL(@TIPO,'') <> '')
		BEGIN
		 SET @QUERY = @QUERY + ' AND E.TipoEquipo= ''' + @TIPO + ''''
		END
 
 
	IF (@IAGENTE='admin') or (@IAGENTE='estrucplan')
		begin
			IF (ISNULL(@ESTADO,'') <> '')
				BEGIN
				 SET @QUERY = @QUERY + ' AND E.Estado= '''+ @ESTADO +''''
				END
 
			SET @QUERY = 'SELECT cd2.cat_data_desc as ''Tipo Equipo'', NroEquipo, MarcaModelo, NroSerie, cd.cat_data_desc as ''Estado'',  EC.FechaDesde, EC.FechaHasta,
				case when isnull(PA.PKEY,'''') <> '''' then ''<i class="fas fa-file-pdf w3-large" style="cursor:pointer;" title="Ver Certif." onclick="OpenAttach(''''''+ISNULL(PA.PKEY,'''')+'''''',''''''+ISNULL(PA.FILE_NAME,'''')+'''''');return false;"></i>'' else '''' end AS Certif,
				''<a href="javascript:saveSelection(''''EQ_SEL'''', ''''''+E.ID+'''''');goto('''''+@FORM_ID+''''',''''59428F9C-C254-4B3D-950C-90F12F8A5121'''');">Editar</a>'' AS Opciones
				FROM EP_EQUIPOS E
				LEFT JOIN CAT_DATA CD ON E.Estado = CD.CAT_DATA_CODE AND CD.PAR_KEY=''53934364-A251-4B3D-82D4-51C390AAC1BA''
				LEFT JOIN CAT_DATA CD2  ON E.TipoEquipo = CD2.CAT_DATA_CODE AND CD2.PAR_KEY=''D21113EC-7A64-4C2F-9CDF-4C91094AA32B'' 
				LEFT JOIN EP_EQUIPOS_CERTIF EC ON EC.IdEquipo=E.Id AND EC.ESTADO=''VIGENTE''
				LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT PA ON PA.PAR_KEY = EC.ID
				WHERE 1=1' + @QUERY + ' order by E.TipoEquipo';
 
				exec(@QUERY);
 
		end
	else
		begin
				--SET @QUERY = 'SELECT cd2.cat_data_desc as ''Tipo Equipo'', NroEquipo as ''Nro. Equipo'', MarcaModelo as ''Marca/Modelo'', NroSerie as ''Nro. Serie'',  EC.FechaDesde, EC.FechaHasta,
				--case when isnull(PA.PKEY,'''') <> '''' then ''<i class="fas fa-file-pdf w3-large" style="cursor:pointer;" title="Ver Certif." onclick="OpenAttach(''''''+ISNULL(PA.PKEY,'''')+'''''',''''''+ISNULL(PA.FILE_NAME,'''')+'''''');return false;"></i>'' else '''' end AS ''Certif. Vigente'',
				--''<a href="javascript:saveSelection(''''EQ_SEL'''', ''''''+E.ID+'''''');goto('''''+@FORM_ID+''''',''''DBF56C35-BC49-4E38-9938-E0D7FE8D3559'''');">Hist. Certif.</a>'' AS Opciones
				--FROM EP_EQUIPOS E
				--LEFT JOIN CAT_DATA CD ON E.Estado = CD.CAT_DATA_CODE AND CD.PAR_KEY=''53934364-A251-4B3D-82D4-51C390AAC1BA''
				--LEFT JOIN CAT_DATA CD2  ON E.TipoEquipo = CD2.CAT_DATA_CODE AND CD2.PAR_KEY=''D21113EC-7A64-4C2F-9CDF-4C91094AA32B'' 
				--LEFT JOIN EP_EQUIPOS_CERTIF EC ON EC.IdEquipo=E.Id AND EC.ESTADO=''VIGENTE''
				--LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT PA ON PA.PAR_KEY = EC.ID
				--WHERE 1=1' + @QUERY + ' order by E.TipoEquipo';
 
				select 'Estamos realizando tareas de actualizacion de información de equipos...' as 'Info'
				
 
			
		end
 
		--exec(@QUERY);
 
END
