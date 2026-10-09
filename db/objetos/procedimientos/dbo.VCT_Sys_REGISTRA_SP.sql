 
CREATE   PROCEDURE dbo.VCT_Sys_REGISTRA_SP
(
    @ACCION  VARCHAR(20),
    @SP_NAME VARCHAR(128),
    @SP_CODE VARCHAR(20) = NULL,
    @USUARIO VARCHAR(30) = 'administrador'
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @VOBJECT_ID INT,
            @VSCHEMA SYSNAME,
            @VSP_NAME SYSNAME,
            @VPKEY_SP VARCHAR(36),
            @VERROR VARCHAR(MAX);
 
    SET @ACCION = UPPER(LTRIM(RTRIM(ISNULL(@ACCION,''))));
    SET @SP_NAME = LTRIM(RTRIM(ISNULL(@SP_NAME,'')));
    SET @SP_CODE = NULLIF(LTRIM(RTRIM(ISNULL(@SP_CODE,''))),'');
    SET @USUARIO = ISNULL(NULLIF(LTRIM(RTRIM(@USUARIO)),''),'administrador');
 
    IF @ACCION NOT IN ('REGISTRAR','SINCRONIZAR','ELIMINAR')
    BEGIN
        RAISERROR('La accion debe ser REGISTRAR, SINCRONIZAR o ELIMINAR.',16,1);
        RETURN;
    END;
 
    IF @SP_NAME = ''
    BEGIN
        RAISERROR('Debe indicar @SP_NAME.',16,1);
        RETURN;
    END;
 
    /* Buscar SP físico */
    IF PARSENAME(@SP_NAME,2) IS NOT NULL
    BEGIN
        SELECT @VOBJECT_ID=P.object_id,@VSCHEMA=S.name,@VSP_NAME=P.name
        FROM sys.procedures P
        INNER JOIN sys.schemas S ON S.schema_id=P.schema_id
        WHERE P.name=PARSENAME(@SP_NAME,1)
          AND S.name=PARSENAME(@SP_NAME,2);
    END
    ELSE
    BEGIN
        IF (SELECT COUNT(*) FROM sys.procedures WHERE name=@SP_NAME)>1
        BEGIN
            RAISERROR('Existe mas de un SP con ese nombre. Indique schema.SP.',16,1);
            RETURN;
        END;
 
        SELECT @VOBJECT_ID=P.object_id,@VSCHEMA=S.name,@VSP_NAME=P.name
        FROM sys.procedures P
        INNER JOIN sys.schemas S ON S.schema_id=P.schema_id
        WHERE P.name=@SP_NAME;
    END;
 
    /* Para ELIMINAR se permite que el SP físico ya no exista */
    IF @VOBJECT_ID IS NULL AND @ACCION<>'ELIMINAR'
    BEGIN
        RAISERROR('El Stored Procedure indicado no existe en SQL Server.',16,1);
        RETURN;
    END;
 
    IF @VSP_NAME IS NULL
        SET @VSP_NAME=ISNULL(PARSENAME(@SP_NAME,1),@SP_NAME);
 
    IF @SP_CODE IS NULL
    BEGIN
        IF LEN(@VSP_NAME)>20
        BEGIN
            RAISERROR('El nombre supera los 20 caracteres de SP_CODE. Indique @SP_CODE.',16,1);
            RETURN;
        END;
        SET @SP_CODE=@VSP_NAME;
    END;
 
    IF LEN(@SP_CODE)>20
    BEGIN
        RAISERROR('SP_CODE no puede superar 20 caracteres.',16,1);
        RETURN;
    END;
 
    SELECT @VPKEY_SP=PKEY
    FROM dbo.STORED_PROCEDURES
    WHERE SP_NAME=@VSP_NAME;
 
    /* ELIMINAR */
    IF @ACCION='ELIMINAR'
    BEGIN
        IF @VPKEY_SP IS NULL
        BEGIN
            RAISERROR('El SP no se encuentra registrado en STORED_PROCEDURES.',16,1);
            RETURN;
        END;
 
        BEGIN TRY
            BEGIN TRAN;
 
            DELETE FROM dbo.SP_PRM_IN WHERE PAR_KEY=@VPKEY_SP;
            DELETE FROM dbo.SP_PRM_OUT WHERE PAR_KEY=@VPKEY_SP;
            DELETE FROM dbo.STORED_PROCEDURES WHERE PKEY=@VPKEY_SP;
 
            COMMIT;
 
            SELECT RESULTADO='OK',ACCION=@ACCION,SP_NAME=@VSP_NAME;
            RETURN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT>0 ROLLBACK;
            SET @VERROR='Error en VCT_Sys_REGISTRA_SP: '+ERROR_MESSAGE();
            RAISERROR(@VERROR,16,1);
            RETURN;
        END CATCH;
    END;
 
    IF @ACCION='REGISTRAR' AND @VPKEY_SP IS NOT NULL
    BEGIN
        RAISERROR('El SP ya esta registrado. Utilice SINCRONIZAR.',16,1);
        RETURN;
    END;
 
    IF EXISTS
    (
        SELECT 1
        FROM dbo.STORED_PROCEDURES
        WHERE SP_CODE=@SP_CODE
          AND (@VPKEY_SP IS NULL OR PKEY<>@VPKEY_SP)
    )
    BEGIN
        RAISERROR('SP_CODE ya esta utilizado por otro Stored Procedure.',16,1);
        RETURN;
    END;
 
    /* Leer firma REAL del SP */
    IF OBJECT_ID('tempdb..#PARAMETROS') IS NOT NULL DROP TABLE #PARAMETROS;
 
    SELECT
        PARAMETER_ID=P.parameter_id,
        PARAMETER_NAME=SUBSTRING(P.name,2,128),
        IS_OUTPUT=P.is_output,
        SQL_TYPE=T.name,
        PRM_LENGTH=
            CASE
                WHEN P.max_length=-1 THEN 999999
                WHEN T.name IN ('nvarchar','nchar') THEN P.max_length/2
                WHEN T.name IN ('varchar','char','binary','varbinary') THEN P.max_length
                WHEN T.name IN ('decimal','numeric') THEN P.precision
                WHEN T.name='bigint' THEN 19
                WHEN T.name='int' THEN 10
                WHEN T.name='smallint' THEN 5
                WHEN T.name='tinyint' THEN 3
                WHEN T.name='bit' THEN 1
                ELSE CASE WHEN P.max_length>0 THEN P.max_length ELSE 0 END
            END,
        PRM_INDEX=ROW_NUMBER() OVER
        (
            PARTITION BY P.is_output
            ORDER BY P.parameter_id
        )
    INTO #PARAMETROS
    FROM sys.parameters P
    INNER JOIN sys.types T ON T.user_type_id=P.user_type_id
    WHERE P.object_id=@VOBJECT_ID
      AND P.parameter_id>0;
 
    IF EXISTS(SELECT 1 FROM #PARAMETROS WHERE LEN(PARAMETER_NAME)>30)
    BEGIN
        RAISERROR('Existe un parametro cuyo nombre supera los 30 caracteres permitidos por PRM_CODE.',16,1);
        RETURN;
    END;
 
    BEGIN TRY
        BEGIN TRAN;
 
        /* STORED_PROCEDURES */
        IF @VPKEY_SP IS NULL
        BEGIN
            SET @VPKEY_SP=CONVERT(VARCHAR(36),NEWID());
 
            INSERT INTO dbo.STORED_PROCEDURES
            (
                PKEY,SP_CODE,SP_TYPE_CODE,SP_NAME,RETURN_CODE_IDR,
                SP_TIME_OUT,SP_TYPE_IDR,TS_BEGIN,TS_END,LOCAL_IDR,
                SP_DSN,SP_UID,SP_PWD,TS_USER_ID,SP_OBLIG,SP_CHECK,
                SP_DISPONIBLE,ENTIDAD_IDR,ENTIDAD,SP_DESCRIPCION
            )
            VALUES
            (
                @VPKEY_SP,@SP_CODE,'VCT_GESTION_1',@VSP_NAME,'0',
                5,'Atencion',GETDATE(),GETDATE(),'1',
                NULL,NULL,NULL,@USUARIO,'N',0,
                '0','0',NULL,@VSP_NAME
            );
        END
        ELSE
        BEGIN
            UPDATE dbo.STORED_PROCEDURES
            SET SP_CODE=@SP_CODE,
                SP_NAME=@VSP_NAME,
                TS_END=GETDATE(),
                TS_USER_ID=@USUARIO,
                SP_DESCRIPCION=@VSP_NAME
            WHERE PKEY=@VPKEY_SP;
        END;
 
        /* Eliminar INPUT que ya no existen o pasaron a OUTPUT */
        DELETE I
        FROM dbo.SP_PRM_IN I
        WHERE I.PAR_KEY=@VPKEY_SP
          AND NOT EXISTS
          (
              SELECT 1
              FROM #PARAMETROS P
              WHERE P.IS_OUTPUT=0
                AND P.PARAMETER_NAME=I.PRM_NAME
          );
 
        /* Eliminar OUTPUT que ya no existen o pasaron a INPUT */
        DELETE O
        FROM dbo.SP_PRM_OUT O
        WHERE O.PAR_KEY=@VPKEY_SP
          AND NOT EXISTS
          (
              SELECT 1
              FROM #PARAMETROS P
              WHERE P.IS_OUTPUT=1
                AND P.PARAMETER_NAME=O.PRM_NAME
          );
 
        /* Actualizar INPUT existentes */
        UPDATE I
        SET I.SP_CODE=@SP_CODE,
            I.PRM_CODE=P.PARAMETER_NAME,
            I.PRM_TYPE='Variable',
            I.PRM_VAL=
                CASE UPPER(P.PARAMETER_NAME)
                    WHEN 'IPKEYJOB' THEN 'ATT.JOB_PKEY'
                    WHEN 'FORM_ID'  THEN 'SESSION.FORM_ID'
                    WHEN 'IUNIDAD'  THEN 'ATT.ID_GROUP'
                    WHEN 'IAGENTE'  THEN 'ATT.ID_AGENT'
                    ELSE I.PRM_VAL
                END,
            I.PRM_DESDE=1,
            I.PRM_HASTA=CASE WHEN P.PRM_LENGTH=999999 THEN 999999 ELSE P.PRM_LENGTH END,
            I.PRM_INDEX=P.PRM_INDEX,
            I.TS_END=GETDATE(),
            I.PRM_DATA_TYPE='200',
            I.PRM_LENGTH=P.PRM_LENGTH,
            I.TS_USER_ID=@USUARIO,
            I.PRM_NAME=P.PARAMETER_NAME,
            I.PRM_SUBTYPE=
                CASE UPPER(P.PARAMETER_NAME)
                    WHEN 'IPKEYJOB' THEN 'Atributo fijo (Proceso)'
                    WHEN 'FORM_ID'  THEN 'Personalizado'
                    WHEN 'IUNIDAD'  THEN 'Atributo fijo (Actividad)'
                    WHEN 'IAGENTE'  THEN 'Atributo fijo (Actividad)'
                    ELSE I.PRM_SUBTYPE
                END
        FROM dbo.SP_PRM_IN I
        INNER JOIN #PARAMETROS P
            ON P.PARAMETER_NAME=I.PRM_NAME
           AND P.IS_OUTPUT=0
        WHERE I.PAR_KEY=@VPKEY_SP;
 
        /* Insertar INPUT nuevos */
        INSERT INTO dbo.SP_PRM_IN
        (
            PKEY,PAR_KEY,SP_CODE,PRM_CODE,PRM_TYPE,PRM_VAL,
            PRM_DESDE,PRM_HASTA,PRM_INDEX,TS_BEGIN,TS_END,
            PRM_DATA_TYPE,PRM_LENGTH,TS_USER_ID,PRM_NAME,PRM_SUBTYPE
        )
        SELECT
            CONVERT(VARCHAR(36),NEWID()),
            @VPKEY_SP,
            @SP_CODE,
            P.PARAMETER_NAME,
            'Variable',
            CASE UPPER(P.PARAMETER_NAME)
                WHEN 'IPKEYJOB' THEN 'ATT.JOB_PKEY'
                WHEN 'FORM_ID'  THEN 'SESSION.FORM_ID'
                WHEN 'IUNIDAD'  THEN 'ATT.ID_GROUP'
                WHEN 'IAGENTE'  THEN 'ATT.ID_AGENT'
                ELSE NULL
            END,
            1,
            CASE WHEN P.PRM_LENGTH=999999 THEN 999999 ELSE P.PRM_LENGTH END,
            P.PRM_INDEX,
            GETDATE(),
            GETDATE(),
            '200',
            P.PRM_LENGTH,
            @USUARIO,
            P.PARAMETER_NAME,
            CASE UPPER(P.PARAMETER_NAME)
                WHEN 'IPKEYJOB' THEN 'Atributo fijo (Proceso)'
                WHEN 'FORM_ID'  THEN 'Personalizado'
                WHEN 'IUNIDAD'  THEN 'Atributo fijo (Actividad)'
                WHEN 'IAGENTE'  THEN 'Atributo fijo (Actividad)'
                ELSE 'Personalizado'
            END
        FROM #PARAMETROS P
        WHERE P.IS_OUTPUT=0
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.SP_PRM_IN I
              WHERE I.PAR_KEY=@VPKEY_SP
                AND I.PRM_NAME=P.PARAMETER_NAME
          );
 
        /* Actualizar OUTPUT existentes */
        UPDATE O
        SET O.SP_CODE=@SP_CODE,
            O.PRM_CODE=P.PARAMETER_NAME,
            O.PRM_NAME=P.PARAMETER_NAME,
            O.PRM_LENGTH=999999,
            O.PRM_INDEX=P.PRM_INDEX,
            O.TS_END=GETDATE(),
            O.PRM_DATA_TYPE='200',
            O.TS_USER_ID=@USUARIO
        FROM dbo.SP_PRM_OUT O
        INNER JOIN #PARAMETROS P
            ON P.PARAMETER_NAME=O.PRM_NAME
           AND P.IS_OUTPUT=1
        WHERE O.PAR_KEY=@VPKEY_SP;
 
        /* Insertar OUTPUT nuevos */
        INSERT INTO dbo.SP_PRM_OUT
        (
            PKEY,PAR_KEY,SP_CODE,PRM_CODE,PRM_NAME,
            PRM_LENGTH,PRM_INDEX,TS_BEGIN,TS_END,
            PRM_DATA_TYPE,TS_USER_ID
        )
        SELECT
            CONVERT(VARCHAR(36),NEWID()),
            @VPKEY_SP,
            @SP_CODE,
            P.PARAMETER_NAME,
            P.PARAMETER_NAME,
            999999,
            P.PRM_INDEX,
            GETDATE(),
            GETDATE(),
            '200',
            @USUARIO
        FROM #PARAMETROS P
        WHERE P.IS_OUTPUT=1
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.SP_PRM_OUT O
              WHERE O.PAR_KEY=@VPKEY_SP
                AND O.PRM_NAME=P.PARAMETER_NAME
          );
 
        COMMIT;
 
        SELECT
            RESULTADO='OK',
            ACCION=@ACCION,
            SCHEMA_NAME=@VSCHEMA,
            SP_NAME=@VSP_NAME,
            SP_CODE=@SP_CODE,
            PKEY_SP=@VPKEY_SP;
 
        SELECT
            TIPO_PARAMETRO=CASE WHEN IS_OUTPUT=1 THEN 'OUT' ELSE 'IN' END,
            PARAMETER_NAME,
            SQL_TYPE,
            PRM_LENGTH,
            PRM_INDEX
        FROM #PARAMETROS
        ORDER BY PARAMETER_ID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        SET @VERROR='Error en VCT_Sys_REGISTRA_SP: '+ERROR_MESSAGE();
        RAISERROR(@VERROR,16,1);
    END CATCH;
END
