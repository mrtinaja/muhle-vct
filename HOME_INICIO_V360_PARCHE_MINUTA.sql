/* ========================================================================
   PARCHE HOME_INICIO_V360 - Minuta de Gestion / Anexos: guardado por tandas
   ------------------------------------------------------------------------
   Problema: el Guardar junta los campos cambiados en CALL.BUFFER
   ("id=valor|id=valor|") que admite 4000 caracteres. Una minuta con textos
   largos (ej. proyecto 1340: 4188) se corta y se pierden los ultimos campos.

   Cambio (solo el JS que inyecta este SP, en @OBUTTON, rama TAB_SERV 8/9):
     - mgGuardar(): si todo entra en un BUFFER, guarda igual que antes.
       Si no, lo parte en tandas (cortando SIEMPRE entre campos) y las manda
       una tras otra al mismo paso de grabado (441D2446...). Cada tanda
       re-usa el formulario que devuelve el servidor. Al final muestra la
       pagina como siempre. Si una tanda devuelve un alert de error, corta y
       la muestra.
     - Cada campo queda limitado a 3990 caracteres (id + "=" + valor + "|"
       tiene que entrar en un BUFFER).
     - "|" escrito por el usuario se reemplaza por "¦" (no rompe el armado).
       El "=" no hace falta: HOME_MODIFY_HOJA_RUTA separa en el PRIMER "=".
     - iniDic() separa en el PRIMER "=" (antes cortaba el texto en el
       primer "=" que tuviera).

   COMO APLICAR: en SSMS, Modificar dbo.HOME_INICIO_V360, buscar el bloque
   que empieza con
       CASE WHEN ((@VTAB_SERV = '8') OR (@VTAB_SERV = '9') AND (ISNULL(@VTAB_AGENDA,'') <> '')) THEN
   (dentro de SET @OBUTTON = ... ELSE ...) y reemplazarlo COMPLETO, hasta su
   ELSE '' END inclusive, por el bloque de abajo. Ejecutar (F5).
   ======================================================================== */

			CASE WHEN ((@VTAB_SERV = '8') OR (@VTAB_SERV = '9') AND (ISNULL(@VTAB_AGENDA,'') <> '')) THEN
						'<div class="w3-container" style="padding:1px;"></div>
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="return mgGuardar('''+@FORM_ID+''',''441D2446-B86C-4A60-AD37-1325060BFCCF'');">Guardar</btn>
						</div>
					</div>
				</div>
			</div>
			<div><img class="w3-muhle-logo" id="LogoIzq" src="../img/logo_izq.jpg" style="display:none;"></div>
			<div><img class="w3-muhle-logo" id="LogoDer" src="../img/logo_der.jpg" style="display:none;"></div>
			<script>
			var MG_MAX = 3990;
			var dic2 = {};
			function toggleCombo(i){
				if (i.value.length > MG_MAX) {
					i.value = i.value.substring(0, MG_MAX);
					alert("Cada campo admite hasta " + MG_MAX + " caracteres. El texto se recorto.");
				}
				dic2[i.id] = i.value;
			}
			function mgTexto(v){
				return String(v == null ? "" : v).replace(/\|/g, "\u00A6");
			}
			function mgLotes(){
				var lotes = [], act = "";
				for (var id in dic2) {
					var par = id + "=" + mgTexto(dic2[id]) + "|";
					if (act !== "" && act.length + par.length > MG_MAX) { lotes.push(act); act = ""; }
					act += par;
				}
				if (act !== "") lotes.push(act);
				return lotes;
			}
			function saveValuesCombo(i){
				var l = mgLotes();
				almacenarSeleccion(i, l.length ? l[0] : "");
			}
			function mgForm(doc){
				var b = doc.querySelector("[name^=\"CALL.BUFFER\"]");
				return b ? (b.form || b.closest("form")) : null;
			}
			function mgMostrar(data){
				$("#mainContainer").html(data);
				$("#loader").hide();
				$("#mainContainer").show();
			}
			function mgGuardar(formId, resultCode){
				var lotes = mgLotes();
				if (lotes.length <= 1) {
					almacenarSeleccion("BUFFER", lotes.length ? lotes[0] : "");
					goto(formId, resultCode);
					return false;
				}
				$("#mainContainer").hide();
				$("#loader").show();
				var n = 0;
				function enviar(f){
					var poner = function(sel, v){ var e = f.querySelector(sel); if (e) e.value = v; };
					poner("[name^=\"CALL.BUFFER\"]", lotes[n]);
					poner("[name=\"action_name\"]", "salto");
					poner("[name=\"ResultCode\"]", resultCode);
					$.ajax({
						type: "POST",
						url: "../task/Default.aspx",
						data: $(f).serialize(),
						dataType: "text",
						success: function(data){
							n++;
							if (n >= lotes.length) { mgMostrar(data); return; }
							var f2 = mgForm(new DOMParser().parseFromString(data, "text/html"));
							if (!f2 || /<script>\s*alert\(/.test(data) || data.indexOf("Finalize") > -1) {
								mgMostrar(data);
								alert("Se guardaron " + n + " de " + lotes.length + " partes de la minuta. Revise los datos y vuelva a guardar.");
								return;
							}
							enviar(f2);
						},
						error: function(r, s, e){
							console.log(s + " " + e);
							$("#loader").hide();
							$("#mainContainer").show();
							alert("No se pudo guardar la minuta (parte " + (n + 1) + " de " + lotes.length + "). Intente nuevamente.");
						}
					});
				}
				enviar(document.getElementById(formId));
				return false;
			}
			function iniDic(){
				var b = document.querySelector("[name^=\"CALL.BUFFER\"]");
				if (!b || !b.value) return;
				b.value.split("|").forEach(function(item){
					var p = item.indexOf("=");
					if (p > 0) dic2[item.substring(0, p)] = item.substring(p + 1);
				});
			}
			iniDic();
			(function mgTopes(k){
				var ts = document.querySelectorAll("textarea[maxlength]");
				for (var x = 0; x < ts.length; x++) { if (ts[x].maxLength > MG_MAX) ts[x].maxLength = MG_MAX; }
				if (k < 10) setTimeout(function(){ mgTopes(k + 1); }, 500);
			})(0);
			</script>'
			ELSE '' END
