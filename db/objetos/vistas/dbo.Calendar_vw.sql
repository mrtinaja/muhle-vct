CREATE VIEW [dbo].[Calendar_vw]
AS
SELECT     ISNULL(dbo.PHYSICAL_LIST.PHYSICAL_LIST_DESC, '') AS campania, dbo.CUSTOMER.CUSTOMER_NAME, dbo.CUSTOMER.CUST_TYPE_CODE, 
                      dbo.CUSTOMER.CUST_PRIMARY_ID, dbo.CALL_TYPE.CALL_TYPE_DESC, dbo.JOB_TYPE.JOB_TYPE_DESC, 
                      dbo.CUSTOMER_TYPE.CUST_TYPE_DESC, UN.UNIT_DESCRIPTION, US.USER_NAME, coalesce(AC.PROGRAMMED_DATE_TIME,getdate()) AS programado, 
                      AC.ATT_STATE_CODE AS estado, AC.ATT_MAX_END_DATE AS vencimientoTarea, dbo.PHYSICAL_JOB.JOB_SEQ AS Tramite, 
                      dbo.PHYSICAL_JOB.JOB_PRIORITY, dbo.PHYSICAL_JOB.JOB_STATE_DATE, dbo.CUSTOMER.PKEY AS customer_pkey, 
                      dbo.PHYSICAL_JOB.JOB_START_DATE AS Iniciado, dbo.PHYSICAL_JOB.JOB_MAX_END_DATE AS vencimientoTramite
FROM         dbo.PHYSICAL_LIST RIGHT OUTER JOIN
                      dbo.ATTENDED_CUSTOMER AC INNER JOIN
                      dbo.CALL_TYPE ON AC.CALL_TYPE_CODE = dbo.CALL_TYPE.CALL_TYPE_CODE INNER JOIN
                      dbo.CUSTOMER INNER JOIN
                      dbo.PHYSICAL_JOB ON dbo.CUSTOMER.PKEY = dbo.PHYSICAL_JOB.PKEY_CUSTOMER INNER JOIN
                      dbo.JOB_TYPE ON dbo.PHYSICAL_JOB.JOB_TYPE_CODE = dbo.JOB_TYPE.JOB_TYPE_CODE AND 
                      dbo.CUSTOMER.CUST_TYPE_CODE = dbo.JOB_TYPE.CUST_TYPE_CODE INNER JOIN
                      dbo.CUSTOMER_TYPE ON dbo.CUSTOMER.CUST_TYPE_CODE = dbo.CUSTOMER_TYPE.CUST_TYPE_CODE ON 
                      AC.PKEY_JOB = dbo.PHYSICAL_JOB.PKEY ON dbo.PHYSICAL_LIST.PKEY = dbo.PHYSICAL_JOB.PKEY_CAMPAIGN LEFT OUTER JOIN
                      dbo.VW_SYS_UNIDAD UN ON AC.PREV_GROUPCODE = UN.UNIT_CODE LEFT OUTER JOIN
                      dbo.VW_SYS_USUARIO US ON AC.PREV_USERID = US.USER_ID
WHERE     (dbo.JOB_TYPE.JOB_READY_IDR = '1') AND (AC.ATT_STATE_CODE = 'Abierto' OR
                      AC.ATT_STATE_CODE = 'NOTWORKED') AND (AC.GROUP_CODE = 'VENTASERVICIOSCC') AND (AC.PROGRAMMED_IDR = 'SI') AND 
                      (AC.PROGRAMMED_DATE_TIME >= CONVERT(datetime, '1900-01-01 12:00:00 AM', 120)) AND (AC.PROGRAMMED_DATE_TIME <= CONVERT(datetime, 
                      '2099-12-31 12:00:00 AM', 120)) AND (AC.PKEY_CAMPAIGN = 'NO APLICA') AND (AC.USER_ID = 'gciapparelli') OR
                      (dbo.JOB_TYPE.JOB_READY_IDR = '1') AND (AC.ATT_STATE_CODE = 'Abierto' OR
                      AC.ATT_STATE_CODE = 'NOTWORKED') AND (AC.GROUP_CODE = 'VENTASERVICIOSCC') AND (AC.PROGRAMMED_IDR = 'AGENDADO') AND 
                      (AC.PKEY_CAMPAIGN = 'NO APLICA') AND (AC.USER_ID = 'gciapparelli') OR
                      (dbo.JOB_TYPE.JOB_READY_IDR = '1') AND (AC.ATT_STATE_CODE = 'Abierto' OR
                      AC.ATT_STATE_CODE = 'NOTWORKED') AND (AC.GROUP_CODE = 'VENTASERVICIOSCC') AND (AC.PROGRAMMED_IDR = 'NO') AND 
                      (AC.PKEY_CAMPAIGN = 'NO APLICA') AND (AC.USER_ID = 'gciapparelli') OR
                      (dbo.JOB_TYPE.JOB_READY_IDR = '1') AND (AC.ATT_STATE_CODE = 'Abierto' OR
                      AC.ATT_STATE_CODE = 'NOTWORKED') AND (AC.GROUP_CODE = 'VENTASERVICIOSCC') AND (AC.PROGRAMMED_IDR = 'SI') AND 
                      (AC.PROGRAMMED_DATE_TIME >= CONVERT(datetime, '1900-01-01 12:00:00 AM', 120)) AND (AC.PROGRAMMED_DATE_TIME <= CONVERT(datetime, 
                      '2099-12-31 12:00:00 AM', 120)) AND (AC.PKEY_CAMPAIGN <> 'NO APLICA') AND (AC.USER_ID = 'gciapparelli') AND 
                      (dbo.CALL_TYPE.VISIBLE_INBOX = '1') AND EXISTS
                          (SELECT     *
                            FROM          physical_list list
                            WHERE      list.pkey = AC.pkey_campaign AND (list.state_code = 'INICIADA' OR
                                                   (list.state_code = 'TERMINADA_NOTWORKED' AND physical_job.job_state_code = 'OPENED'))) OR
                      (dbo.JOB_TYPE.JOB_READY_IDR = '1') AND (AC.ATT_STATE_CODE = 'Abierto' OR
                      AC.ATT_STATE_CODE = 'NOTWORKED') AND (AC.GROUP_CODE = 'VENTASERVICIOSCC') AND (AC.PROGRAMMED_IDR = 'AGENDADO') AND 
                      (AC.PKEY_CAMPAIGN <> 'NO APLICA') AND (AC.USER_ID = 'gciapparelli') AND (dbo.CALL_TYPE.VISIBLE_INBOX = '1') AND EXISTS
                          (SELECT     *
                            FROM          physical_list list
                            WHERE      list.pkey = AC.pkey_campaign AND (list.state_code = 'INICIADA' OR
                                                   (list.state_code = 'TERMINADA_NOTWORKED' AND physical_job.job_state_code = 'OPENED'))) OR
                      (dbo.JOB_TYPE.JOB_READY_IDR = '1') AND (AC.ATT_STATE_CODE = 'Abierto' OR
                      AC.ATT_STATE_CODE = 'NOTWORKED') AND (AC.GROUP_CODE = 'VENTASERVICIOSCC') AND (AC.PROGRAMMED_IDR = 'NO') AND 
                      (AC.PKEY_CAMPAIGN <> 'NO APLICA') AND (AC.USER_ID = 'gciapparelli') AND (dbo.CALL_TYPE.VISIBLE_INBOX = '1') AND EXISTS
                          (SELECT     *
                            FROM          physical_list list
                            WHERE      list.pkey = AC.pkey_campaign AND (list.state_code = 'INICIADA' OR
                                                   (list.state_code = 'TERMINADA_NOTWORKED' AND physical_job.job_state_code = 'OPENED')))
 
 
