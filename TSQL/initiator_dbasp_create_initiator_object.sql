-- =============================================
-- Author:		<Zahra Saffarpour>
-- Create date: <5/21/2023>
-- Version:		<3.0.0.0>
-- Description:	<>
-- Input Parameters:
-- @TableName
-- @ColumnName:
-- @IncludeClusteredIndex:
-- @IncludeNonClusteredIndex:
-- @EnableTrigger:
-- =============================================
CREATE OR ALTER   PROCEDURE ssbs.dbasp_create_initiator_object
(
	@TableName NVARCHAR(50),
	@ColumnName NVARCHAR(MAX),
	@IncludeClusteredIndex BIT = 1,
	@IncludeNonClusteredIndex BIT = 0,
	@EnableTrigger BIT = 0
)
AS
BEGIN
	--====================================
	DECLARE @myStartPoint INT
	DECLARE @myEndPoint INT
	DECLARE @myTableName NVARCHAR(50)
	DECLARE @mySchemaName NVARCHAR(50)
	DECLARE @myScript NVARCHAR(MAX);
	DECLARE @NewLine NVARCHAR(10);
	DECLARE @myOperation NVARCHAR(10);
	DECLARE @myColumnList AS TABLE (ColumnName sysname, DataType NVARCHAR(128), CharacterMaximumLength INT, IsNullable VARCHAR(3))

	SET @myStartPoint=0
	SET @myEndPoint=0
	SET @myStartPoint = CHARINDEX(N'.',@TableName)
	SET @myEndPoint = LEN(@TableName)-@myStartPoint

	SET @mySchemaName = SUBSTRING(@TableName,0,@myStartPoint) 
	SET @myTableName = SUBSTRING(@TableName,@myStartPoint+1,@myEndPoint)
	IF @myStartPoint = 0
	BEGIN
		SET @mySchemaName = 'dbo'
	END
	SET @ColumnName = '<INCLUDE:RECID,CreatedDatetime,ModifiedDatetime,DATAAREA,DATAAREAID><EXCLUDE:PARTITION,RecVersion,CREATEDBY,MODIFIEDBY,SHA1HASHHEX,SHA3HASHHEX>' + ',' + @ColumnName
	SET @NewLine = CHAR( 13 ) + CHAR( 10 );
	SET @myScript = N'';
	SET @myScript = @myScript + N'/*' + @NewLine;
	SET @myScript = @myScript + '@FileName = ' + REPLACE(@TableName,'.','_') + '_INITIATOR'+ @NewLine;
	SET @myScript = @myScript + '@myTableName = ' + @myTableName + @NewLine;
	SET @myScript = @myScript + '@myColumnName = ' + @ColumnName + @NewLine
	SET @myScript = @myScript + N'*/' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;

	SET NOCOUNT ON;
	INSERT INTO @myColumnList(ColumnName, DataType, CharacterMaximumLength, IsNullable)
	SELECT [Name], [DataType], [CharacterMaximumLength], [IsNullable]
	FROM [ssbs].[dbafn_column_list] (@mySchemaName, @myTableName, @ColumnName, @IncludeClusteredIndex, @IncludeNonClusteredIndex)
	--=INITIALIZE========================
	SET @myScript = N'';
	SET @myOperation = N'INITIALIZE';
	SET @myScript = @myScript + N'CREATE OR ALTER PROCEDURE [SSBS].[PROC_' + @myTableName + N'_INITIALIZE]' + @NewLine;
	SET @myScript = @myScript + N'AS' + @NewLine;
	SET @myScript = @myScript + N'BEGIN' + @NewLine;
	SET @myScript = @myScript + N'    SET NOCOUNT ON;' + @NewLine;
	SET @myScript = @myScript + N'    DECLARE @myMessage AS XML;' + @NewLine;
	SET @myScript = @myScript + N'    SET @myMessage =' + @NewLine;
	SET @myScript = @myScript + N'        (' + @NewLine;
	SET @myScript = @myScript + N'            SELECT GETDATE() AS ''@OPERATIONDATETIME'',' + @NewLine;
	SET @myScript = @myScript + N'                ''' + UPPER( @myOperation ) + N''' AS ''@OPERATION'',' + @NewLine;
	SET @myScript = @myScript + N'                ''' + @myTableName + N''' AS ''@TABLENAME'',' + @NewLine;
	SET @myScript = @myScript + N'                (' + @NewLine;
	SET @myScript = @myScript + N'                    SELECT' + @NewLine;
	SET @myScript = @myScript + N'                        '
					+ STUFF(
					  (
						  SELECT ',' + '[myData].' + QUOTENAME(ColumnName) + ' AS ''' + ColumnName + ''''
						  FROM @myColumnList
						  FOR XML PATH( '' )
					  ), 1, 1, '' ) + @NewLine;
	SET @myScript = @myScript + N'                    FROM ' + QUOTENAME(@mySchemaName) + '.' + QUOTENAME(@myTableName) + ' AS myData' + @NewLine;
	SET @myScript = @myScript + N'                    FOR XML PATH( ''RECORD'' ), TYPE' + @NewLine;
	SET @myScript = @myScript + N'                )' + @NewLine;
	SET @myScript = @myScript + N'                FOR XML PATH( ''OKD365'' )' + @NewLine;
	SET @myScript = @myScript + N'        );' + @NewLine;
	SET @myScript = @myScript + N'    EXECUTE [ssbs].[proc_OperationalGeneralSend] @myMessage;' + @NewLine;
	SET @myScript = @myScript + N'END;' + @NewLine;
	SET @myScript = @myScript + N'GO' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;
	--=Create  INSERT Trigger==========================================================
	SET @myScript = N'';
	SET @myOperation = N'INSERT';
	SET @myScript = @myScript + N'CREATE OR ALTER TRIGGER ' + QUOTENAME(@mySchemaName) + '.[SSBS_' + @myTableName + N'_AI]' + @NewLine;
	SET @myScript = @myScript + N'ON ' + QUOTENAME(@mySchemaName) + '.' + QUOTENAME(@myTableName) + @NewLine;
	SET @myScript = @myScript + N'AFTER ' + UPPER( @myOperation ) + @NewLine;
	SET @myScript = @myScript + N'AS' + @NewLine;
	SET @myScript = @myScript + N'BEGIN' + @NewLine;
	SET @myScript = @myScript + N'    SET NOCOUNT ON;' + @NewLine;
	SET @myScript = @myScript + N'    DECLARE @myMessage AS XML;' + @NewLine;
	SET @myScript = @myScript + N'    SET @myMessage =' + @NewLine;
	SET @myScript = @myScript + N'    (' + @NewLine;
	SET @myScript = @myScript + N'        SELECT GETDATE() AS ''@OPERATIONDATETIME'',' + @NewLine;
	SET @myScript = @myScript + N'               ''' + UPPER( @myOperation ) + N''' AS ''@OPERATION'',' + @NewLine;
	SET @myScript = @myScript + N'               ''' + @myTableName + N''' AS ''@TABLENAME'',' + @NewLine;
	SET @myScript = @myScript + N'               (' + @NewLine;
	SET @myScript = @myScript + N'					SELECT' + @NewLine;
	SET @myScript = @myScript + N'						'
					+ STUFF(
					  (
						  SELECT ',' + '[myData].' + QUOTENAME(ColumnName) + ' AS ''' + ColumnName + ''''
						  FROM @myColumnList
						  FOR XML PATH( '' )
					  ), 1, 1, '' ) + @NewLine;
	SET @myScript = @myScript + N'					FROM [Inserted] AS myData' + @NewLine;
	SET @myScript = @myScript + N'					FOR XML PATH( ''RECORD'' ), TYPE' + @NewLine;
	SET @myScript = @myScript + N'               )' + @NewLine;
	SET @myScript = @myScript + N'        FOR XML PATH( ''OKD365'' )' + @NewLine;
	SET @myScript = @myScript + N'    );' + @NewLine;
	SET @myScript = @myScript + N'    EXECUTE [ssbs].[proc_OperationalGeneralSend] @myMessage;' + @NewLine;
	SET @myScript = @myScript + N'END;' + @NewLine;
	SET @myScript = @myScript + N'GO' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;
	--=Create  UPDATE Trigger==========================================================
	SET @myScript = N'';
	SET @myOperation = N'UPDATE';
	SET @myScript = @myScript + N'CREATE OR ALTER TRIGGER ' + QUOTENAME(@mySchemaName) + '.[SSBS_' + @myTableName + N'_AU]' + @NewLine;
	SET @myScript = @myScript + N'ON ' + QUOTENAME(@mySchemaName) + '.' + QUOTENAME(@myTableName) + @NewLine;
	SET @myScript = @myScript + N'AFTER ' + UPPER( @myOperation ) + @NewLine;
	SET @myScript = @myScript + N'AS' + @NewLine;
	SET @myScript = @myScript + N'BEGIN' + @NewLine;
	SET @myScript = @myScript + N'    SET NOCOUNT ON;' + @NewLine;
	SET @myScript = @myScript + N'    DECLARE @myMessage AS XML;' + @NewLine;
	SET @myScript = @myScript + N'    SET @myMessage =' + @NewLine;
	SET @myScript = @myScript + N'    (' + @NewLine;
	SET @myScript = @myScript + N'        SELECT GETDATE() AS ''@OPERATIONDATETIME'',' + @NewLine;
	SET @myScript = @myScript + N'               ''' + UPPER( @myOperation ) + N''' AS ''@OPERATION'',' + @NewLine;
	SET @myScript = @myScript + N'               ''' + @myTableName + N''' AS ''@TABLENAME'',' + @NewLine;
	SET @myScript = @myScript + N'               (' + @NewLine;
	SET @myScript = @myScript + N'					SELECT' + @NewLine;
	SET @myScript = @myScript + N'						'
					+ STUFF(
					  (
						  SELECT ',' + '[myData].' + QUOTENAME(ColumnName) + ' AS ''' + ColumnName + ''''
						  FROM @myColumnList
						  FOR XML PATH( '' )
					  ), 1, 1, '' ) + @NewLine;
	SET @myScript = @myScript + N'					FROM [Inserted] AS myData' + @NewLine;
	SET @myScript = @myScript + N'					FOR XML PATH( ''RECORD'' ), TYPE' + @NewLine;
	SET @myScript = @myScript + N'               )' + @NewLine;
	SET @myScript = @myScript + N'        FOR XML PATH( ''OKD365'' )' + @NewLine;
	SET @myScript = @myScript + N'    );' + @NewLine;
	SET @myScript = @myScript + N'    EXECUTE [ssbs].[proc_OperationalGeneralSend] @myMessage;' + @NewLine;
	SET @myScript = @myScript + N'END;' + @NewLine;
	SET @myScript = @myScript + N'GO' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;
	--=Create  UPDATE Trigger==========================================================
	SET @myScript = N'';
	SET @myOperation = N'DELETE';
	SET @myScript = @myScript + N'CREATE OR ALTER TRIGGER ' + QUOTENAME(@mySchemaName) + '.[SSBS_' + @myTableName + N'_AD]' + @NewLine;
	SET @myScript = @myScript + N'ON ' + QUOTENAME(@mySchemaName) + '.' + QUOTENAME(@myTableName) + @NewLine;
	SET @myScript = @myScript + N'AFTER ' + UPPER( @myOperation ) + @NewLine;
	SET @myScript = @myScript + N'AS' + @NewLine;
	SET @myScript = @myScript + N'BEGIN' + @NewLine;
	SET @myScript = @myScript + N'    SET NOCOUNT ON;' + @NewLine;
	SET @myScript = @myScript + N'    DECLARE @myMessage AS XML;' + @NewLine;
	SET @myScript = @myScript + N'    SET @myMessage =' + @NewLine;
	SET @myScript = @myScript + N'    (' + @NewLine;
	SET @myScript = @myScript + N'        SELECT GETDATE() AS ''@OPERATIONDATETIME'',' + @NewLine;
	SET @myScript = @myScript + N'               ''' + UPPER( @myOperation ) + N''' AS ''@OPERATION'',' + @NewLine;
	SET @myScript = @myScript + N'               ''' + @myTableName + N''' AS ''@TABLENAME'',' + @NewLine;
	SET @myScript = @myScript + N'               (' + @NewLine;
	SET @myScript = @myScript + N'					SELECT [myData].[RECID] AS ''RECID''' + @NewLine;
	SET @myScript = @myScript + N'					FROM [Deleted] AS myData' + @NewLine;
	SET @myScript = @myScript + N'					FOR XML PATH( ''RECORD'' ), TYPE' + @NewLine;
	SET @myScript = @myScript + N'               )' + @NewLine;
	SET @myScript = @myScript + N'        FOR XML PATH( ''OKD365'' )' + @NewLine;
	SET @myScript = @myScript + N'    );' + @NewLine;
	SET @myScript = @myScript + N'    EXECUTE [ssbs].[proc_OperationalGeneralSend] @myMessage;' + @NewLine;
	SET @myScript = @myScript + N'END;' + @NewLine;
	SET @myScript = @myScript + N'GO' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;

	IF @EnableTrigger = 0
	BEGIN
		SET @myScript = N''; 
		SET @myScript = @myScript + N'DISABLE TRIGGER ' + QUOTENAME(@mySchemaName) + '.[SSBS_' + @myTableName + N'_AI] ON ' + QUOTENAME(@mySchemaName) + '.' + QUOTENAME(@myTableName) + @NewLine;
		SET @myScript = @myScript + N'GO' + @NewLine;
		SET @myScript = @myScript + N'DISABLE TRIGGER ' + QUOTENAME(@mySchemaName) + '.[SSBS_' + @myTableName + N'_AU] ON ' + QUOTENAME(@mySchemaName) + '.' +QUOTENAME(@myTableName) + @NewLine;
		SET @myScript = @myScript + N'GO' + @NewLine;
		SET @myScript = @myScript + N'DISABLE TRIGGER ' + QUOTENAME(@mySchemaName) + '.[SSBS_' + @myTableName + N'_AD] ON ' + QUOTENAME(@mySchemaName) + '.' +QUOTENAME(@myTableName) + @NewLine;
		SET @myScript = @myScript + N'GO' + @NewLine;
		EXECUTE ssbs.dbasp_print_text @myScript;
	END
END
GO

