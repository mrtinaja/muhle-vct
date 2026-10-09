-- ============================================================================================
-- Autor: LDM
-- Fecha de creacion: 06/05/2017
-- Ultima modificacion: 06/05/2017
-- Ultima modificacion por: LDM
-- Tablas afectadas de lectura: 
-- Tablas afectadas de modificacion:  DSS_TBPHYSICAL_JOB,  DSS_TBATTENDED_CUSTOMER , DSS_TBPHYSICAL_CALL
-- Descripcion: Genera un tramite cerrado en las tablas historiales.
-- ===========================================================================================
 
CREATE PROCEDURE [dbo].[SP_SYS_NEW_PHYSICAL_JOB] 
 
-- Parametros comunes
 
@JOB_TYPE_CODE as varchar (100),
@PKEY_CLIENTE as varchar (100),
@NRO_DOC as numeric(8,0),
@DESC AS VARCHAR(100)
--@ID_AGENT as varchar (20),
--@ID_GROUP as varchar (50)
 
--@Phys_Job_ID_JOB_TYPE as varchar (20),
--@Phys_Job_JOB_RESULT_CODE as varchar (20)
AS
 
--Variables que voy a recuperar con un select
 
declare @JOB_REASON_CODE  varchar (50)
declare @JOB_SUBREASON_CODE as varchar (50)
declare @JOB_ORIGEN_CODE  varchar (50)
declare @ID_CALL_TYPE  varchar (20)
declare @Phys_Job_ID_JOB_TYPE varchar (20)
 
 
--------------------------------------------------------------------------------------------
--Estas variables estan seteadas en duro
 
 
declare @Phys_Job_STATE_CODE varchar (20)
declare @Phys_Job_ATT_STATE_CODE  varchar (20)
declare @Phys_Job_ATT_RESULT_CODE  varchar (20)
declare @Phys_Job_JOB_RESULT_CODE  varchar (20)
declare @Phys_Job_JOB_PRIORITY  varchar (20)
 
set @ID_CALL_TYPE='AUT_REGISTRO';
SET @Phys_Job_ID_JOB_TYPE=@JOB_TYPE_CODE;
set @Phys_Job_ATT_STATE_CODE  = 'Cerrado'
set @Phys_Job_STATE_CODE = 'CLOSED'
set @Phys_Job_ATT_RESULT_CODE = 'ENTREGADO'
set @Phys_Job_JOB_RESULT_CODE = 'ENTREGADO'
set @Phys_Job_JOB_PRIORITY = 'Normal'
 
-- Parametros para el INSERT de la tabla DSS_TBATTENDED_CUSTOMER
 
declare @Att_Cust_ATT_STATE_CODE  varchar (20)
declare @Att_Cust_ATT_RESULT_CODE  varchar (20)
 
set @Att_Cust_ATT_STATE_CODE = 'Cerrado'
set @Att_Cust_ATT_RESULT_CODE = 'ENTREGADO'
 
-- Parametros para el INSERT de la tabla DSS_TBPHYSICAL_CALL
 
declare @PhysCall_PHYS_STATE_CODE  varchar (20)
declare @PhysCall_PHYS_RESULT_CODE  varchar (20)
declare @PhysCall_DURACION_SEG  int
declare @PhysCall_ATT_STATE_CODE  varchar (20)
declare @PhysCall_ATT_RESULT_CODE  varchar (20)
 
set @PhysCall_PHYS_STATE_CODE = 'CLOSED'
set @PhysCall_PHYS_RESULT_CODE = 'SUCCESSFUL'
set @PhysCall_DURACION_SEG = '0'
set @PhysCall_ATT_STATE_CODE = 'Cerrado'
set @PhysCall_ATT_RESULT_CODE = 'ENTREGADO'
 
--Variables de tipo fecha,  comunes para mas de uno de los INSERT
 
DECLARE @FechaConMsEnCero  varchar (23) -- Formato 2005-05-09 09:54:37.000
DECLARE @FechaConHoraEnCero  varchar (22) -- Formato 2005-05-09 00:00:00.000
DECLARE @Hora  varchar (8) -- Formato 09:54:37
DECLARE @HoraMasUno  varchar (5) --Formato 9-10
 
--Auxiliares para armar los diferentes  formatos de Fecha
 
DECLARE @auxiliar  varchar (19)
DECLARE @auxiliar1  varchar (10)
DECLARE @auxiliar2  varchar (22)
DECLARE @auxiliar3  varchar (22)
DECLARE @auxiliar4  varchar (2)
 
-- Variables para obtener las Pkey de tabla
 
DECLARE @Pkey_Phys_Job  varchar (80)
DECLARE @Pkey_Att_Cust  varchar (50)
DECLARE @Pkey_Phys_Call  varchar (50)
 
-- Variable para la Custumer Primary ID
 
DECLARE @CUST_PRIMARY_ID  varchar (20)
 
--Variable para obtner el JOB_SEQ
 
DECLARE @JOB_SEQ  int
 
-- Armado de los diferentes formatos de fecha
 
set @auxiliar = (select convert (varchar(19),getdate(),20))
set @auxiliar = (select substring (@auxiliar ,1 ,19))
set @FechaConMsEnCero= @Auxiliar + '.000'
 
--devuelve la fecha con los milisegundos en cero: (2005-05-09 10:25:32.000)
---------------------------------------------------------------------------------------
set @auxiliar1 = (select convert (varchar(19),getdate(),20))
set @auxiliar1 = (select substring (@auxiliar1 ,1 ,10))
set @FechaConHoraEnCero= @Auxiliar1 --+ ' 00:00:00.000'
 
--devuelve la fecha con la hora la hora y los milisegundos en 0: ()
---------------------------------------------------------------------------------------
set @auxiliar2 = (select convert (varchar(22),getdate(),20))
set @Hora = (select substring (@auxiliar2 ,12 ,8))
 
--devuelve la hora: (12:45:03)
 
---------------------------------------------------------------------------------------
set @auxiliar3 = (select convert (varchar(22),getdate(),20))
set @auxiliar3 = (select substring (@auxiliar3 ,12 ,2))+ 1
set @auxiliar4 = (select datepart(hour,getdate()))
set @HoraMasUno = @auxiliar4 + '-'+ @auxiliar3
 
--devuelve la hora mas 1: (13)
 
---------------------------------------------------------------------------------------
--Devuelve la Pkey cprrespondiente para la tabla dada.
 
SET @Pkey_Att_Cust = NEWID();
 
SET @Pkey_Phys_Call = NEWID();
 
---------------------------------------------------------------------------------------
--Obtengo  la @CUST_PRIMARY_ID	
 
	set  @CUST_PRIMARY_ID = (select cust_primary_id from customer where pkey=@PKEY_CLIENTE)
---------------------------------------------------------------------------------------
-- Armo la Pkey de la tabla DSS_TBPHYSICAL_JOB
 
set @Pkey_Phys_Job = NEWID();
 
---------------------------------------------------------------------------------------
 
--Obtengo el JOB_SEQ
 
	INSERT INTO PHYSICAL_JOB  (PKEY , CUST_PRIMARY_ID , JOB_TYPE_CODE , JOB_STATE_CODE )
	VALUES (@Pkey_Phys_Job , @CUST_PRIMARY_ID , @Phys_Job_ID_JOB_TYPE , @Phys_Job_STATE_CODE)
	SET @JOB_SEQ = ( SELECT @@IDENTITY )
 
	DELETE FROM PHYSICAL_JOB
	WHERE PKEY = @Pkey_Phys_Job 
---------------------------------------------------------------------------------------
 
--SET @FechaConMsEnCero  = GETDATE()
--SET @FechaConHoraEnCero  = GETDATE()
--SET @Hora  = GETDATE()--SET @HoraMasUno
 
INSERT INTO DSS_TBPHYSICAL_JOB 
		(PKEY_PHYSICAL_JOB, 
		ID_CUSTOMER, 
		ID_JOB_TYPE, 
		JOB_STATE_CODE, 
		JOB_STATE_DATE_TIME, 
		JOB_RESULT_CODE, 
		ID_CAMPAIGN, 
		ID_AGENT, 
		ID_GROUP, 
		STATE_CALL, 
		SUBSTATE_CALL, 
		ID_TIME_ATT, 
		ID_FECHA_ATT, 
		ATT_STATE_CODE, 
		ATT_RESULT_CODE, 
		ID_CALL_TYPE, 
		JOB_START_DATE, 
		PKEY_ATTENDED_CUSTOMER, 
		JOB_MAX_END_DATE, 
		CUST_PRIMARY_ID, 
		ID_OPPORTUNITY, 
		ID_CONTACT, 
		ID_ACCOUNT, 
		JOB_PRIORITY, 
		JOB_ORIGEN_CODE, 
		JOB_REASON_CODE, 
		JOB_SEQ, 
		PREV_GROUP_CODE, 
		PREV_USER_ID, 
		ID_ENTITY_VALUE, 
		ID_ENTITY_TYPE, 
		PRODUCT_TYPE_ID, 
		BRAND_ID, 
		EXT_BRAND_ID, 
		ATTR_1, 
		RELATION_TYPE, 
		STATUS, 
		STATUS_DATE, 
		CUST_TYPE_CODE, 
		INTERNAL_ID, 
		JOB_STATE_DATE, 
		JOB_STATE_TIME, 
		JOB_START_DATE_TIME, 
		JOB_START_TIME, 
		JOB_SUBREASON_CODE)
		VALUES (@Pkey_Phys_Job , @PKEY_CLIENTE , @Phys_Job_ID_JOB_TYPE , @Phys_Job_STATE_CODE, @FechaConMsEnCero , @Phys_Job_JOB_RESULT_CODE ,
		'NO APLICA' , 'SYSTEM' , 'SISTEMAS_SENDEROS', ' ',  ' ' , @Hora , @FechaConHoraEnCero, @Phys_Job_ATT_STATE_CODE , @Phys_Job_ATT_RESULT_CODE ,
		@ID_CALL_TYPE, @FechaConHoraEnCero , @Pkey_Att_Cust , @FechaConMsEnCero , @CUST_PRIMARY_ID ,' ' ,  ' ' , NULL ,@Phys_Job_JOB_PRIORITY , @JOB_ORIGEN_CODE , 
		@JOB_REASON_CODE , @JOB_SEQ , ' ' , ' ' , ' ' , ' ' , NULL , NULL , NULL , NULL, NULL, NULL, NULL ,NULL, NULL , @FechaConHoraEnCero, @Hora  , @FechaConMsEnCero,
		@Hora  , @JOB_SUBREASON_CODE)
 
	INSERT INTO DSS_TBATTENDED_CUSTOMER
		(PKEY_ATTENDED_CUSTOMER,
		ID_CUSTOMER,
		ID_CALL_TYPE,
		ATT_STATE_CODE,
		ATT_STATE_DATE_TIME,
		ATT_RESULT_CODE,
		ID_CAMPAIGN,
		ID_AGENT,
		ID_GROUP,
		STATE_CALL,
		SUBSTATE_CALL,
		ID_TIME_ATT,
		ID_FECHA_ATT,
		ID_CAU_NOTCONTACT,
		COMMENTA,
		PKEY_PHYSICAL_JOB,
		ATT_MAX_END_DATE,
		MEDIA_ID1,
		PROGRAMMED_IDR,
		PROGRAMMED_DATE_TIME,
		TS_BEGIN,
		TS_END,
		TS_USER_ID)
		VALUES (@Pkey_Att_Cust, @PKEY_CLIENTE , @ID_CALL_TYPE, @Att_Cust_ATT_STATE_CODE , @FechaConMsEnCero , @Att_Cust_ATT_RESULT_CODE , 'NO APLICA' ,
		'SYSTEM' , 'SISTEMAS_SENDEROS', 'CLOSED' , 'SUCCESSFUL',  @Hora , @FechaConHoraEnCero, 'NO APLICA' ,' ' , @Pkey_Phys_Job,  @FechaConMsEnCero , NULL , 
		NULL , NULL ,@FechaConMsEnCero,@FechaConMsEnCero, 'SYSTEM')
 
	INSERT INTO DSS_TBPHYSICAL_CALL
		(PKEY_PHYSICAL_CALL,
		PKEY_ATTENDED_CUSTOMER,
		CALL_ID,
		CALL_DATE_TIME,
		CALL_DATE_TIME_END,
		ID_AGENT,
		ID_GROUP,
		PHYS_STATE_CODE,
		PHYS_RESULT_CODE,
		ANI,
		DNIS,
		IN_OUT_IDR,
		CALL_DATE,
		ID_FECHA,
		ID_TIME_PHYS,
		ID_DATE_END,
		ID_TIME_END,
		ID_RANGHOUR,
		DURACION_SEG,
		ID_CUSTOMER,
		ID_CAMPAIGN,
		ATT_RESULT_CODE,
		ATT_STATE_CODE,
		ID_CAU_NOTCONTACT,
		COMMENTA,
		PROGRAMMED_DATE_TIME,
		PKEY_PHYSICAL_JOB)
		VALUES (@Pkey_Phys_Call, @Pkey_Att_Cust, @ID_CALL_TYPE , @FechaConMsEnCero , @FechaConMsEnCero , 'SYSTEM' , 'SISTEMAS_SENDEROS', @PhysCall_PHYS_STATE_CODE , @PhysCall_PHYS_RESULT_CODE ,
		'gsAni' , 'gsDnis' , 'IN' , @FechaConMsEnCero , @FechaConHoraEnCero , @Hora , @FechaConHoraEnCero , @Hora , @HoraMasUno  , @PhysCall_DURACION_SEG , @PKEY_CLIENTE,
		'NO APLICA' , @PhysCall_ATT_RESULT_CODE, @PhysCall_ATT_STATE_CODE , 'NO APLICA' , ' ' , @FechaConMsEnCero, @Pkey_Phys_Job )
 
 
-- Inserto en la entidad principal del reclamo o consulta segun corresponda
 
DECLARE @pkeyEntidad as varchar(80)
 
SET @pkeyEntidad = NEWID()
 
INSERT INTO TMP_AUTORIZACIONES (PKEY, PAR_KEY, TS_BEGIN, TS_END, TS_USER_ID)
             VALUES (@pkeyEntidad, @Pkey_Phys_Job, GETDATE(),GETDATE(), 'SYSTEM')
	
	UPDATE [TMP_AUTORIZACIONES]
   SET [TIPO_DOC] = 'DU'
      ,[NRO_DOC] = @NRO_DOC
      ,[ESTADO_ANALISIS] ='ESTADO-OK'
      ,[OBSERVACIONES] = 'Generado automaticamente migracion bolsos sist. anterior'
      ,[FECHA_RECEP_AUTORIZACION] = CONVERT(VARCHAR,GETDATE(),103) + ' ' + CONVERT(VARCHAR,GETDATE(),108)
      ,[USUARIO_CARGA] = 'SYSTEM'
      ,[MEDIO] = 'PRESENCIAL'
      ,[FECHA_ORDEN] = GETDATE()
      ,[PRIORIDAD] = 'Normal'
      ,[TIPO_PRESTACION] = 'BOLSO_MAT'
      ,[TIPO_GESTION] = 'NUEVA'
      ,[CRONICO] = 'NO'
      ,[UNIDAD_INICIO] = 'SYSTEM'
      ,[AUTORIZADO] = 'SI'
      ,[FECHA_AUTORIZACION] = GETDATE()
      ,[DESTINO] = 'MUTUAL_SENDEROS'
      ,[AUTORIZADO_POR] = 'SYSTEM'
      ,[ENTREGADO] = 'SI'
      ,[DESC_PRESTACION] = 'Bolso de Maternidad para '+@DESC
 WHERE pkey = @pkeyEntidad
