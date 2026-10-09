 
CREATE PROCEDURE [dbo].[EP_DASHBOARD]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHTML	AS VARCHAR(MAX) OUTPUT)
AS
 
 DECLARE @ENOREALIZADO INT,
 @EREALIZADO INT,
 @EENPROCESO INT,
 @EFINALIZADO INT,
 @IPLANTA VARCHAR(50),
 @IEMPRESA VARCHAR(50),
 @EMPRESA_DESC AS VARCHAR(1000),
 @PLANTA_DESC AS VARCHAR(1000),
 @IESTADO_SEL AS VARCHAR(50),
 @IMES_SEL AS VARCHAR(50),
 @ITIPO_SERV_SEL AS VARCHAR(50),
 @UserName as varchar(100),
 @UrlFeed as varchar(100)
 
BEGIN	
	--No Realizado	1
	--Realizado	3
	--En Proceso	2
	--Finalizado	4
 
	--PLANTAS
	--SELECT DISTINCT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU
	--INNER JOIN GROUPSUSERMEMBERS G ON G.USERMEMBERID=PU.IDUSUARIO AND G.GROUPID='EP_CLIENTES'
	--INNER JOIN USERS U ON U.ID=G.USERMEMBERID
	--WHERE PU.IdUsuario='aabbate'
	
	--if (@IAGENTE='estrucplan')
		--. SET @UrlFeed = 'https://estrucplan.com.ar/?call_custom_simple_rss=1&csrp_cat=491';  21/05/2025 - LR: Se comentó el link anterior se reemplaza por el link de la línea de abajo
		SET @UrlFeed = 'https://estrucplan.com.ar/category/exclusivo-clientes/feed/';
	--else
	--	SET @UrlFeed = 'https://estrucplan.com.ar/feed/';
 
	SELECT @ENOREALIZADO=COUNT(1) FROM EP_CRONOGRAMA where IDESTADO=1 AND IDPlanta IN (	SELECT DISTINCT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU WHERE IdUsuario=@IAGENTE);
	SELECT @EENPROCESO=COUNT(1) FROM EP_CRONOGRAMA where IDESTADO=2 AND IDPlanta IN (	SELECT DISTINCT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU WHERE IdUsuario=@IAGENTE);
	SELECT @EREALIZADO=COUNT(1) FROM EP_CRONOGRAMA where IDESTADO=3 AND IDPlanta IN (	SELECT DISTINCT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU WHERE IdUsuario=@IAGENTE);
	SELECT @EFINALIZADO=COUNT(1) FROM EP_CRONOGRAMA where IDESTADO=4 AND IDPlanta IN (	SELECT DISTINCT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU WHERE IdUsuario=@IAGENTE);
	
	SET @OHTML = '
<!-- Header -->
  <header class="w3-container" style="padding-top:22px">
    <h5><b><i class="fa fa-home"></i>&nbsp;Inicio</b></h5>
  </header>
 
  <div class="w3-row-padding w3-margin-bottom">
    <div class="w3-third">
		<div class="w3-card-4">
			<div class="w3-container">
				<h4><b>Datos Utiles</b></h4>  
				<p><b><i class="fas fa-building"></i>&nbsp;Dirección</b>: Av. Rivadavia 18392, Morón, Bs. As.</p>
				<p><b><i class="fa fa-phone"></i>&nbsp;Líneas rotativas</b>: +54-11-46274383</p>
				<p><b><i class="fas fa-info-circle"></i>&nbsp;Institucional</b>: <a target="_blank" href="mailto:info@estrucplan.com.ar">info@estrucplan.com.ar</a></p>
				<p><b><i class="fa fa-file-powerpoint fa-fw"></i>&nbsp;Solicitar Presupuesto</b>: <a target="_blank" href="mailto:comercial@estrucplan.com.ar">comercial@estrucplan.com.ar</a></p>
				<p><b><i class="fas fa-briefcase"></i>&nbsp;Administración</b>: <a target="_blank" href="mailto:cobranzas@estrucplan.com.ar">cobranzas@estrucplan.com.ar</a></p>
			</div>
			
		</div>
		  <br>
		  <div class="w3-card-4 w3-padding">
		  	<div class="w3-container">
			<h4><b>Responsables Cronogramas</b></h4> 
			<div id="table1"></div> 
			</div>
		  </div>
		<br>
		  <div class="w3-card-4 w3-padding">
		  	<div class="w3-container">
			<h4><b>Certificaciones Estrucplan</b></h4> 
			 <table class="w3-table-all">
				<tr>
				  <td>OPDS</td>
				  <td><a href="https://estrucplan.com.ar/wp-content/uploads/2018/05/Estrucplan_Certificado.jpg" target="_blank">Descargar</a></td>
				</tr>
				<tr>
				  <td>APRA</td>
				  <td><a href="https://estrucplan.com.ar/wp-content/uploads/2018/05/Inscripcion-APRA.pdf" target="_blank">Descargar</a></td>
				</tr>
				<tr>
				  <td>ISO 9001</td>
				  <td><a href="https://estrucplan.com.ar/wp-content/uploads/2020/10/Certificados-2020.pdf" target="_blank">Descargar</a></td>
				</tr>
				<tr>
				  <td>Politica Calidad</td>
				  <td><a href="https://estrucplan.com.ar/wp-content/uploads/2018/05/Calidad.pdf" target="_blank">Descargar</a></td>
				</tr>
			  </table>
			  </div>
		  </div>
 
    </div>
    <div class="w3-twothird">
	 <div class="w3-row-padding w3-margin-bottom">
		<div class="w3-quarter">
		  <div class="w3-container w3-red w3-text-white w3-padding">
			<div class="w3-left w3-large"><i class="fa fa-calendar-times"></i>&nbsp;No Realizado</div>
			<br>
			<div class="w3-right w3-large">'+cast(@ENOREALIZADO as varchar)+'</div>
		  </div>
		</div>
		<div class="w3-quarter">
		  <div class="w3-container w3-yellow w3-text-white w3-padding">
			<div class="w3-left w3-large"><i class="fa fa-calendar-day"></i>&nbsp;En Proceso</div>
			<br>
			<div class="w3-right w3-large">'+cast(@EENPROCESO as varchar)+'</div>
		  </div>
		</div>
		<div class="w3-quarter">
		  <div class="w3-container w3-orange w3-text-white w3-padding">
	  		<div class="w3-left w3-large"><i class="fa fa-calendar-alt"></i>&nbsp;Realizado</div>
			<br>
			<div class="w3-right w3-large">'+cast(@EREALIZADO as varchar)+'</div>
		  </div>
		</div>
		<div class="w3-quarter">
		  <div class="w3-container w3-green w3-text-white w3-padding">
	  		<div class="w3-left w3-large"><i class="fa fa-calendar-check"></i>&nbsp;Finalizado</div>
			<br>
			<div class="w3-right w3-large">'+cast(@EFINALIZADO as varchar)+'</div>
		  </div>
		</div>
	  </div>
 
		<div class="w3-row">
			<h4><b>Tareas del mes</b></h4>
			<div id="table2"></div>
		</div>
		<div class="w3-row">
		  <div class="w3-container">
			 <h4><b>Novedades</b></h4>
				<div id="result"></div>
		  </div>
		</div>
 
 
 
 
    </div>
	
 
  </div>
 
 
  
  
  <!-- Footer -->
  <footer class="w3-container w3-padding-16 w3-light-grey">
    <p>Powered by <a href="https://muhle.io" target="_blank">Mühle | Squad</a></p>
  </footer>
  <script>
	BuildAjaxSPTable(''table1'', ''EP_DATOS_UTILES'', '''+@FORM_ID+''');
	BuildAjaxSPTable(''table2'', ''EP_TAREAS_PROX_VENC'', '''+@FORM_ID+''');
 
	jQuery.browser = {};
		(function () {
			jQuery.browser.msie = false;
			jQuery.browser.version = 0;
			if (navigator.userAgent.match(/MSIE ([0-9]+)\./)) {
				jQuery.browser.msie = true;
				jQuery.browser.version = RegExp.$1;
			}
		})();
 
	jQuery.getFeed({
		url: "'+@UrlFeed+'",
		success: function(feed) {
			 jQuery("result").append(''h4>''
            + ''<a href="''
            + feed.link
            + ''">''
            + feed.title
            + ''</a>''
            + ''</h4>'');
            
            var html = '''';
            
            for(var i = 0; i < feed.items.length && i < 5; i++) {
            
                var item = feed.items[i];
                
                html += ''<h6><b>''
                + ''<a style="text-decoration: none" target="_blank" href="''
                + item.link
                + ''">''
                + item.title
                + ''</a>''
                + ''</b></h6>'';
                
                html += ''<div class="w3-text-black">''
                + item.updated
                + ''</div>'';
                
                html += ''<div>''
                + item.description
                + ''</div>'';
            }
            
            jQuery("#result").append(html);
		}
	});
</script>'
 
 
 
  
 
END
