CREATE PROCEDURE [dbo].[HOME_MODIFY_VIATICO]
(@IPKEYJOB	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE	@VID					VARCHAR(50),
		@VSERVICIO				VARCHAR(50),
		@VID_HOJA				VARCHAR(50),
		@VPROVEEDOR_ID			VARCHAR(50),
		@VTIPO_PROV				VARCHAR(50),
		@VNRO_FACTURA_PROV		VARCHAR(50),
		@VCANT_PERSONAS_PROV	VARCHAR(50),
		@VDESCRIP_SERVICIO_PROV	VARCHAR(100),
		@VFECHA_FACTURA_PROV	DATETIME,
		@VPRECIO_FINAL_PROV		NUMERIC(12,2),
		@VFORMA_PAGO_PROV		VARCHAR(50),
		@VCANT_CUOTAS_PROV		VARCHAR(50),
		@VESTADO_PAGO_PROV		VARCHAR(50),
		@VFECHA_ULT_PAGO_PROV	DATETIME,
		@VPRECIO_CUOTA_PROV		NUMERIC(12,2),
		@VFECHA_PROX_VTO_PROV	DATETIME,
		@VSALDO_PEND_PROV		NUMERIC(12,2),
		@VDESTINO_PROV			VARCHAR(100),
		@VFECHA_DESDE_SERV_PROV	DATETIME,
		@VFECHA_HASTA_SERV_PROV	DATETIME,
		@VID_AGENDA				VARCHAR(50),
		@VERROR				VARCHAR(50),
		@VTIPO_CONSULTOR	VARCHAR(50),
		@VCONSULTOR			VARCHAR(50),
		@VTIENE_CONS		VARCHAR(50),
		@VTIENE_OBS			VARCHAR(50),
		@VDESC_PAGO			VARCHAR(300)
BEGIN
 
	SELECT	@VID_AGENDA = ISNULL(AGENDA_ID,''),
			@VID = ISNULL(PROYECTO_SERV_ID,''),
			@VID_HOJA  = ISNULL(HOJA_RUTA_ID,''),
			@VPROVEEDOR_ID	=	ISNULL(PROVEEDOR_ID,''),
			@VTIPO_PROV		=	ISNULL(TIPO_PROV,''),
			@VNRO_FACTURA_PROV = ISNULL(NRO_FACTURA_PROV,''),
			@VCANT_PERSONAS_PROV =	ISNULL(CANT_PERSONAS_PROV,''),
			@VDESCRIP_SERVICIO_PROV = ISNULL(DESCRIP_SERVICIO_PROV,''),
			@VFECHA_FACTURA_PROV = 	NULLIF(ISNULL(FECHA_FACTURA_PROV,''),''),
			@VPRECIO_FINAL_PROV	= ISNULL(PRECIO_FINAL_PROV,0),--ISNULL(replace(replace(PRECIO_FINAL_PROV,',',''),'.',''),''),
			@VFORMA_PAGO_PROV	= ISNULL(FORMA_PAGO_PROV,''),
			@VCANT_CUOTAS_PROV	= ISNULL(CANT_CUOTAS_PROV,''),
			@VESTADO_PAGO_PROV	= ISNULL(ESTADO_PAGO_PROV,''),
			@VFECHA_ULT_PAGO_PROV = ISNULL(FECHA_ULT_PAGO_PROV,''),
			@VPRECIO_CUOTA_PROV	= ISNULL(PRECIO_CUOTA_PROV,0),--ISNULL(replace(replace(PRECIO_CUOTA_PROV,',',''),'.',''),''),
			@VFECHA_PROX_VTO_PROV = ISNULL(FECHA_PROX_VTO_PROV,''),
			@VSALDO_PEND_PROV	= ISNULL(SALDO_PEND_PROV,0),--ISNULL(replace(replace(SALDO_PEND_PROV,',',''),'.',''),''),
			@VDESTINO_PROV	= ISNULL(DESTINO_PROV,''),
			@VFECHA_DESDE_SERV_PROV = ISNULL(FECHA_DESDE_SERV_PROV,''),
			@VFECHA_HASTA_SERV_PROV	= ISNULL(FECHA_HASTA_SERV_PROV,''),
			@VERROR = ISNULL(ERROR,''),
			@VTIPO_CONSULTOR = ISNULL(TIPO_CONSULTOR_PROV,''),
			@VCONSULTOR = ISNULL(CONSULTOR_PROV,''),
			@VDESC_PAGO = ISNULL(DESC_FORMA_PAGO_PROV,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN	
 
		IF (@VTIPO_PROV = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Tipo Viatico</b></font>
							  </div>
							</div>
							</body>
							</html>'
			
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
			
		END
 
		IF (@VPROVEEDOR_ID = '' AND @VTIPO_PROV <> 'AUTO') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Proveedor</b></font>
							  </div>
							</div>
							</body>
							</html>'
			
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
			
		END
 
		IF (@VTIPO_CONSULTOR = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Corresponde</b></font>
							  </div>
							</div>
							</body>
							</html>'
			
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
			
		END
 
		--SELECT * FROM [dbo].[FN_GET_OBSERVADOR] (1)
		SELECT TOP 1 @VTIENE_CONS = CAT_DATA_CODE FROM [dbo].[FN_GET_CONSULTORES] (@VID_AGENDA) --= 'SC'
 
		--SELECT TOP 1 CAT_DATA_CODE FROM [dbo].[FN_GET_CONSULTORES] (7)
 
		IF (@VTIPO_CONSULTOR = 'CONSULTOR' AND @VTIENE_CONS = 'SC') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>No Puede Seleccionar la opcion CONSULTOR si la Agenda NO tiene Consultor/es</b></font>
							  </div>
							</div>
							</body>
							</html>'
			
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
			
		END ELSE BEGIN
 
			IF (@VCONSULTOR = '') BEGIN
			
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Consultor/Observador</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
		END
 
		SELECT TOP 1 @VTIENE_OBS = CAT_DATA_CODE FROM [dbo].[FN_GET_OBSERVADOR] (@VID_AGENDA) --= 'SC'
		
		IF (@VTIPO_CONSULTOR = 'OBSERVADOR' AND @VTIENE_OBS= 'SO') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>No Puede Seleccionar la opcion OBSERVADOR si la Agenda NO tiene Observador</b></font>
							  </div>
							</div>
							</body>
							</html>'
			
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
			
		END ELSE BEGIN
 
			IF (@VCONSULTOR = '') BEGIN
			
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Consultor/Observador</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END			
		END
 
		IF (@VPROVEEDOR_ID = '9999' AND @VDESCRIP_SERVICIO_PROV = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
								<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Descripcion Servicio si el Proveedor es "Otros"</b></font>
								</div>
							</div>
							</body>
							</html>'
			
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		UPDATE	LK_PROYECTO_VIATICOS 
		SET		ID_PROVEEDOR = @VPROVEEDOR_ID,
				TIPO_PROVEEDOR = @VTIPO_PROV,
				NRO_FC = @VNRO_FACTURA_PROV ,
				CANT_PERSONAS = @VCANT_PERSONAS_PROV,	 
				DESCRIP_SERVICIO = @VDESCRIP_SERVICIO_PROV,
				FECHA_FC = @VFECHA_FACTURA_PROV,
				PRECIO_FINAL = @VPRECIO_FINAL_PROV,	
				FORMA_PAGO = @VFORMA_PAGO_PROV,	
				CANT_CUOTAS = @VCANT_CUOTAS_PROV,		
				ESTADO_PAGO = @VESTADO_PAGO_PROV,	
				FECHA_ULT_PAGO = @VFECHA_ULT_PAGO_PROV,	
				PRECIO_CUOTA = @VPRECIO_CUOTA_PROV,	
				PROX_VENCIMIENTO = @VFECHA_PROX_VTO_PROV,
				SALDO_PEND = @VSALDO_PEND_PROV,	
				DESTINO = @VDESTINO_PROV,		
				FECHA_DESDE_SERV = @VFECHA_DESDE_SERV_PROV,
				FECHA_HASTA_SERV = @VFECHA_HASTA_SERV_PROV,
				TIPO_CONSULTOR = @VTIPO_CONSULTOR,
				ID_CONSULTOR = @VCONSULTOR,
				DESC_FORMA_PAGO = @VDESC_PAGO
		WHERE	ID_PROYECTO_VIATICOS = @VID_HOJA
 
		/*UPDATE	XAGENDA
		SET		HOJA_RUTA_ID = NULL,
				PROVEEDOR_ID = NULL,
				TIPO_PROV = NULL,
				NRO_FACTURA_PROV = NULL,
				CANT_PERSONAS_PROV = NULL,
				DESCRIP_SERVICIO_PROV = NULL,
				FECHA_FACTURA_PROV = NULL,
				PRECIO_FINAL_PROV = NULL,
				FORMA_PAGO_PROV = NULL,
				CANT_CUOTAS_PROV = NULL,
				ESTADO_PAGO_PROV = NULL,
				FECHA_ULT_PAGO_PROV = NULL,
				PRECIO_CUOTA_PROV = NULL,
				FECHA_PROX_VTO_PROV = NULL,
				SALDO_PEND_PROV = NULL,
				DESTINO_PROV = NULL,
				FECHA_DESDE_SERV_PROV = NULL,
				FECHA_HASTA_SERV_PROV = NULL,
				TIPO_CONSULTOR_PROV = NULL,
				CONSULTOR_PROV = NULL
		WHERE	PAR_KEY = @IPKEYJOB*/
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	XAGENDA
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
