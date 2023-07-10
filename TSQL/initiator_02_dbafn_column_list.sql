-- =============================================
-- Author:		<Zahra Saffarpour>
-- Create date: <5/21/2023>
-- Version:		<3.0.0.0>
-- Description:	<Return list of related database names>
-- Input Parameters:
-- @SchemaName :
-- @TableName
-- @Columns:			'<ALL_COLUMNS>' or 'column_name1,column_name1,...,column_nameN' also you can use '<EXCLUDE:column_name1,column_name2,...,column_nameN>' and '<INCLUDE:column_name1,column_name2,...,column_nameN>' within only '<ALL_COLUMNS>' syntax 
--							Ex:'<ALL_COLUMNS><INCLUDE:RECID,ModifiedDatetime><EXCLUDE:Partition,RecVersion>'
-- @IncludeClusteredIndex:
-- @IncludeNonClusteredIndex:
-- =============================================
CREATE OR ALTER FUNCTION [ssbs].[dbafn_column_list] 
(
	@SchemaName NVARCHAR(50),
	@TableName NVARCHAR(50),
	@Columns NVARCHAR(MAX) = N'<ALL_COLUMNS>',
	@IncludeClusteredIndex BIT = 1,
	@IncludeNonClusteredIndex BIT = 1
)
RETURNS 
@ColumnList TABLE ([Name] NVARCHAR(255), [DataType] NVARCHAR(128), [CharacterMaximumLength] INT, [IsNullable] VARCHAR(3))
AS
BEGIN
	DECLARE @ListIsGenerated BIT
	DECLARE @StartPoint INT
	DECLARE @EndPoint INT
	DECLARE @ExceptNames NVARCHAR(MAX)
	DECLARE @IncludeNames NVARCHAR(MAX)

	DECLARE @myColumnList TABLE ([Name] NVARCHAR(255))

	SET @ListIsGenerated=0
	--Phase 0: Create Return List
	IF UPPER(@Columns) LIKE UPPER(N'%<ALL_COLUMNS>%')
	BEGIN
		SET @ListIsGenerated=1
		INSERT INTO @myColumnList ([Name]) 
		SELECT mySchemaColumn.COLUMN_NAME
		FROM INFORMATION_SCHEMA.COLUMNS AS mySchemaColumn
		WHERE mySchemaColumn.TABLE_SCHEMA = @SchemaName
			AND mySchemaColumn.TABLE_NAME = @TableName
	END

	IF @ListIsGenerated=0
	BEGIN
		INSERT INTO @myColumnList ([Name])
		SELECT mySchemaColumn.COLUMN_NAME
		FROM INFORMATION_SCHEMA.COLUMNS AS mySchemaColumn
		INNER JOIN [ssbs].dbafn_split(N',',@Columns) as myColumns ON mySchemaColumn.COLUMN_NAME = RTRIM(LTRIM(REPLACE(REPLACE(myColumns.Parameter,']',''),'[','')))
		WHERE mySchemaColumn.TABLE_SCHEMA = @SchemaName 
			AND mySchemaColumn.TABLE_NAME = @TableName
	END

	IF UPPER(@Columns) LIKE UPPER(N'%<INCLUDE:%>%')
	BEGIN
		SET @StartPoint=0
		SET @EndPoint=0
		SET @IncludeNames=N''
		SELECT @StartPoint = CHARINDEX(N'<INCLUDE:',@Columns)
		SELECT @EndPoint = CHARINDEX(N'>',RIGHT(@Columns,LEN(@Columns)-@StartPoint))
		IF @StartPoint>0 AND @EndPoint>0
		BEGIN
			SET @IncludeNames=REPLACE(SUBSTRING(@Columns,@StartPoint,@EndPoint),N'<INCLUDE:',N'')
			INSERT INTO @myColumnList ([Name]) 
			SELECT mySchemaColumn.COLUMN_NAME
			FROM INFORMATION_SCHEMA.COLUMNS AS mySchemaColumn
			INNER JOIN [ssbs].dbafn_split(N',',@IncludeNames) as myInclude ON mySchemaColumn.COLUMN_NAME = RTRIM(LTRIM(REPLACE(REPLACE(myInclude.Parameter,']',''),'[','')))
			WHERE mySchemaColumn.TABLE_SCHEMA = @SchemaName 
				AND mySchemaColumn.TABLE_NAME = @TableName
				AND LEN(myInclude.Parameter) > 0
				AND myInclude.Parameter NOT IN (SELECT [Name] FROM @myColumnList)
		END
	END

	IF UPPER(@Columns) LIKE UPPER(N'%<EXCLUDE:%>%')
	BEGIN
		SET @StartPoint=0
		SET @EndPoint=0
		SET @ExceptNames=N''
		SELECT @StartPoint = CHARINDEX(N'<EXCLUDE:',@Columns)
		SELECT @EndPoint = CHARINDEX(N'>',RIGHT(@Columns,LEN(@Columns)-@StartPoint))
		IF @StartPoint>0 AND @EndPoint>0
		BEGIN
			SET @ExceptNames=REPLACE(SUBSTRING(@Columns,@StartPoint,@EndPoint),N'<EXCLUDE:',N'')
			DELETE FROM @myColumnList WHERE [Name] IN (Select RTRIM(LTRIM(REPLACE(REPLACE(Parameter,']',''),'[',''))) FROM [ssbs].dbafn_split(N',',@ExceptNames) as myExclude WHERE LEN(myExclude.Parameter)>0)
		END
	END

	IF @IncludeClusteredIndex = 1
	BEGIN
		INSERT INTO @myColumnList ([Name])
		SELECT myColumn.name
		FROM sys.indexes AS myIndex
		INNER JOIN sys.index_columns AS myIndexColumn ON myIndexColumn.index_id = myIndex.index_id AND myIndexColumn.object_id = myIndex.object_id
		INNER JOIN sys.columns AS myColumn ON myColumn.column_id = myIndexColumn.column_id AND myColumn.object_id = myIndex.object_id
		INNER JOIN sys.tables AS myTable ON myColumn.object_id = myTable.object_id
		INNER JOIN sys.schemas AS mySchema ON mySchema.schema_id = myTable.schema_id
		WHERE myIndex.index_id = 1
				AND mySchema.name = @SchemaName
				AND myTable.name = @TableName
	END

	IF @IncludeNonClusteredIndex = 1
	BEGIN
		INSERT INTO @myColumnList ([Name])
		SELECT myColumn.name
		FROM sys.indexes AS myIndex
		INNER JOIN sys.index_columns AS myIndexColumn ON myIndexColumn.index_id = myIndex.index_id AND myIndexColumn.object_id = myIndex.object_id
		INNER JOIN sys.columns AS myColumn ON myColumn.column_id = myIndexColumn.column_id AND myColumn.object_id = myIndex.object_id
		INNER JOIN sys.tables AS myTable ON myColumn.object_id = myTable.object_id
		INNER JOIN sys.schemas AS mySchema ON mySchema.schema_id = myTable.schema_id
		WHERE myIndex.index_id > 1
				AND mySchema.name = @SchemaName
				AND myTable.name = @TableName
	END

	INSERT @ColumnList (Name, DataType, CharacterMaximumLength, IsNullable)
	SELECT mySchemaColumn.COLUMN_NAME, mySchemaColumn.DATA_TYPE, mySchemaColumn.CHARACTER_MAXIMUM_LENGTH, mySchemaColumn.IS_NULLABLE
	FROM INFORMATION_SCHEMA.COLUMNS AS mySchemaColumn
	WHERE mySchemaColumn.TABLE_SCHEMA = @SchemaName
		AND mySchemaColumn.TABLE_NAME = @TableName
		AND EXISTS(SELECT 1 FROM @myColumnList AS myColumn WHERE myColumn.Name = mySchemaColumn.COLUMN_NAME )
	RETURN 
END
GO