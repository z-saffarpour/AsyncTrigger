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
-- =============================================
CREATE OR ALTER PROCEDURE ssbs.dbasp_create_target_object
(
	@TableName NVARCHAR(50),
	@ColumnName NVARCHAR(MAX),
	@IncludeClusteredIndex BIT = 1,
	@IncludeNonClusteredIndex BIT = 0
)
AS
BEGIN
	--===================================
	DECLARE @myStartPoint INT
	DECLARE @myEndPoint INT
	DECLARE @myTableName NVARCHAR(50)
	DECLARE @mySchemaName NVARCHAR(50)
	DECLARE @myScript NVARCHAR(MAX);
	DECLARE @NewLine NVARCHAR(10);
	DECLARE @myOperation NVARCHAR(10);
	DECLARE @myScriptColumnType NVARCHAR(MAX);
	DECLARE @myScriptColumn NVARCHAR(MAX);
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
	SET @myScript = @myScript + '@FileName = ' + REPLACE(@TableName,'.','_') + '_TARGET'+ @NewLine;
	SET @myScript = @myScript + '@myTableName = ' + @TableName + @NewLine;
	SET @myScript = @myScript + '@myColumnName = ' + @ColumnName + @NewLine
	SET @myScript = @myScript + N'*/' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;

	SET NOCOUNT ON;
	INSERT INTO @myColumnList(ColumnName, DataType, CharacterMaximumLength, IsNullable)
	SELECT [Name], [DataType], [CharacterMaximumLength], [IsNullable]
	FROM [ssbs].[dbafn_column_list] (@mySchemaName, @myTableName, @ColumnName, @IncludeClusteredIndex, @IncludeNonClusteredIndex)
	--=Create Table==========================================================
	SET @myScriptColumnType = N'';
	SET @myScriptColumn = N'';
	SET @myScript = N'';
	SELECT @myScriptColumnType = @myScriptColumnType + N'	' + QUOTENAME( ColumnName ) + N' '
								 + QUOTENAME(DataType)
								 + CASE WHEN CharacterMaximumLength IS NOT NULL THEN CONCAT( '(', CharacterMaximumLength, ')' )ELSE '' END + N' '
								 + CASE WHEN IsNullable = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + N',' + @NewLine
	FROM @myColumnList

	SELECT @myScriptColumn = STUFF(
							 (
								 SELECT ',' + QUOTENAME( ColumnName )
								 FROM @myColumnList
								 FOR XML PATH( '' )
							 ), 1, 1, '' );
	SET @myScript = @myScript + N'DROP TABLE IF EXISTS [ax].' + QUOTENAME( @myTableName ) + N';' + @NewLine;
	SET @myScript = @myScript + N'CREATE TABLE [ax].' + QUOTENAME( @myTableName ) + @NewLine;
	SET @myScript = @myScript + N'(' + @NewLine;
	SET @myScript = @myScript + @myScriptColumnType;
	SET @myScript = @myScript + N') ON [FG_AX]' + @NewLine;
	SET @myScript = @myScript + N'GO';
	EXECUTE ssbs.dbasp_print_text @myScript;
	--=Create INDEX ==========================================================
	SET @myScript = N'';
	IF @IncludeClusteredIndex = 1
	BEGIN
		SELECT @myScript = @myScript + N'CREATE ' + myIndex.type_desc + N' INDEX ' + QUOTENAME( myIndex.name ) + N' ON [ax].'
						   + QUOTENAME( OBJECT_NAME( myIndex.object_id )) + N' ( '
						   + STUFF(
							 (
								 SELECT ',' + QUOTENAME(myColumn.name)
								 FROM sys.index_columns AS myIndexColumn
								 INNER JOIN sys.columns AS myColumn ON myIndex.object_id = myColumn.object_id AND myColumn.column_id = myIndexColumn.column_id
								 WHERE myIndexColumn.index_id = myIndex.index_id
									   AND myIndexColumn.object_id = myIndex.object_id
									   AND myColumn.name NOT IN ( 'DATAAREAID', 'DATAAREA', 'PARTITION' )
								 FOR XML PATH( '' )
							 ), 1, 1, '' ) + N') WITH (FILLFACTOR= 90, PAD_INDEX=ON, SORT_IN_TEMPDB=ON) ON [FG_AX]' + @NewLine
		FROM sys.indexes AS myIndex
		WHERE myIndex.index_id = 1
			  AND myIndex.object_id = OBJECT_ID( @myTableName );
	END

	IF @IncludeNonClusteredIndex = 1
	BEGIN
		SELECT @myScript = @myScript + N'CREATE ' + myIndex.type_desc + N' INDEX ' + QUOTENAME( myIndex.name ) + N' ON [ax].'
						   + QUOTENAME( OBJECT_NAME( myIndex.object_id )) + N' ( '
						   + STUFF(
							 (
								 SELECT ',' + QUOTENAME(myColumn.name)
								 FROM sys.index_columns AS myIndexColumn
								 INNER JOIN sys.columns AS myColumn ON myIndex.object_id = myColumn.object_id AND myColumn.column_id = myIndexColumn.column_id
								 WHERE myIndexColumn.index_id = myIndex.index_id
									   AND myIndexColumn.object_id = myIndex.object_id
									   AND myColumn.name NOT IN ( 'DATAAREAID', 'DATAAREA', 'PARTITION' )
								 FOR XML PATH( '' )
							 ), 1, 1, '' ) + N') WITH (FILLFACTOR= 90, PAD_INDEX=ON, SORT_IN_TEMPDB=ON) ON [FG_AX]' + @NewLine
		FROM sys.indexes AS myIndex
		WHERE myIndex.index_id > 1
			  AND myIndex.object_id = OBJECT_ID( @myTableName );
	END
	SET @myScript = @myScript + N'GO' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;
	--=Create Procedure==========================================================
	SET @myScript = N'';
	SET @myScriptColumnType = N'';
	SELECT @myScriptColumnType = @myScriptColumnType + N'	    ' + QUOTENAME( ColumnName ) + N' '
								 + QUOTENAME(DataType)
								 + CASE WHEN CharacterMaximumLength IS NOT NULL THEN CONCAT( '(', CharacterMaximumLength, ')' )ELSE '' END + N' '
								 + CASE WHEN IsNullable = 'NO' THEN 'NOT NULL' ELSE 'NULL' END + N',' + @NewLine
	FROM @myColumnList
	SET @myScript = @myScript + N'CREATE OR ALTER PROCEDURE [ssbs].[proc_' + @myTableName + N']' + @NewLine;
	SET @myScript = @myScript + N'(' + @NewLine;
	SET @myScript = @myScript + N'    @myData XML,' + @NewLine;
	SET @myScript = @myScript + N'    @Operation VARCHAR(10)' + @NewLine;
	SET @myScript = @myScript + N')' + @NewLine;
	SET @myScript = @myScript + N'AS' + @NewLine;
	SET @myScript = @myScript + N'BEGIN' + @NewLine;
	SET @myScript = @myScript + N'    SET NOCOUNT ON;' + @NewLine;
	SET @myScript = @myScript + N'    CREATE TABLE #DataItemViaXML' + @NewLine;
	SET @myScript = @myScript + N'    (' + @NewLine;
	SET @myScript = @myScript + @myScriptColumnType + N'    );' + @NewLine;
	SET @myScript = @myScript + N'    --Extract Request Item Parameters' + @NewLine;
	SET @myScript = @myScript + N'    INSERT INTO #DataItemViaXML (' + @myScriptColumn + N')' + @NewLine;
	SET @myScript = @myScript + N'    SELECT';
	SET @myScript = @myScript 
					+ STUFF(
					  (
						  SELECT ',' + N' [myData].[RECORD].value( ''' + ColumnName + N'[1]'', ''' + DataType
								 + CASE WHEN CharacterMaximumLength IS NOT NULL THEN CONCAT( '(', CharacterMaximumLength, ')' )ELSE '' END + N''') AS '
								 + ColumnName
						  FROM @myColumnList
						  FOR XML PATH( '' )
					  ), 1, 1, '' ) + @NewLine;
	SET @myScript = @myScript + N'    FROM @myData.nodes(''/OKD365/RECORD'') AS myData(RECORD);' + @NewLine;
	SET @myScript = @myScript + N'    --Delete' + @NewLine;
	SET @myScript = @myScript + N'    IF (@Operation = ''DELETE'')' + @NewLine;
	SET @myScript = @myScript + N'    BEGIN' + @NewLine;
	SET @myScript = @myScript + N'        DELETE [myTarget]' + @NewLine;
	SET @myScript = @myScript + N'        FROM [ax].' + QUOTENAME(@myTableName) + N' AS myTarget' + @NewLine;
	SET @myScript = @myScript + N'        INNER JOIN #DataItemViaXML AS mySource ON [myTarget].[RECID] = [mySource].[RecId];' + @NewLine;
	SET @myScript = @myScript + N'    END;' + @NewLine;
	SET @myScript = @myScript + N'    --Update' + @NewLine;
	SET @myScript = @myScript + N'    IF (@Operation = ''UPDATE'')' + @NewLine;
	SET @myScript = @myScript + N'    BEGIN' + @NewLine;
	SET @myScript = @myScript + N'        UPDATE [myTarget]' + @NewLine;
	SET @myScript = @myScript + N'        SET' + @NewLine;
	SET @myScript = @myScript + N'            '
					+ STUFF(
					  (
						  SELECT ',' + '[myTarget].' + QUOTENAME( ColumnName ) + ' = [mySource].' + QUOTENAME( ColumnName )
						  FROM @myColumnList
						  FOR XML PATH( '' )
					  ), 1, 1, '' ) + @NewLine;
	SET @myScript = @myScript + N'        FROM [ax].' + QUOTENAME(@myTableName) + N' AS myTarget' + @NewLine;
	SET @myScript = @myScript + N'        INNER JOIN #DataItemViaXML AS mySource ON [mySource].[RECID] = [myTarget].[RecId];' + @NewLine;
	SET @myScript = @myScript + N'    END;' + @NewLine;
	SET @myScript = @myScript + N'    --Insert' + @NewLine;
	SET @myScript = @myScript + N'    IF (@Operation = ''INSERT'')' + @NewLine;
	SET @myScript = @myScript + N'    BEGIN' + @NewLine;
	SET @myScript = @myScript + N'        INSERT INTO [ax].' + QUOTENAME(@myTableName) + N'(' + @myScriptColumn + N')' + @NewLine;
	SET @myScript = @myScript + N'        SELECT ' + @myScriptColumn + @NewLine;
	SET @myScript = @myScript + N'        FROM #DataItemViaXML AS mySource;' + @NewLine;
	SET @myScript = @myScript + N'    END;' + @NewLine;
	SET @myScript = @myScript + N'    --Initialize' + @NewLine;
	SET @myScript = @myScript + N'    IF (@Operation = ''INITIALIZE'')' + @NewLine;
	SET @myScript = @myScript + N'    BEGIN' + @NewLine;
	SET @myScript = @myScript + N'        TRUNCATE TABLE [ax].' + QUOTENAME(@myTableName) + N';' + @NewLine;
	SET @myScript = @myScript + N'        INSERT INTO [ax].' + QUOTENAME(@myTableName) + N'(' + @myScriptColumn + N')' + @NewLine;
	SET @myScript = @myScript + N'        SELECT ' + @myScriptColumn + @NewLine;
	SET @myScript = @myScript + N'        FROM #DataItemViaXML AS mySource;' + @NewLine;
	SET @myScript = @myScript + N'    END;' + @NewLine;
	SET @myScript = @myScript + N'END;' + @NewLine;
	EXECUTE ssbs.dbasp_print_text @myScript;
END
GO