USE SSBSInitiator
GO
-- =============================================
-- Author:		<Zahra Saffarpour>
-- Create date: <7/19/2023>
-- Version:		<3.0.0.0>
-- Description:	<>
-- Input Parameters:
-- @Object:
-- =============================================
DECLARE @Object NVARCHAR(128);
SET @Object = N'dbo.LOGISTICSLOCATION';
--====================
DECLARE @RowCount INT;
DECLARE @myTable AS TABLE ( ObjectName NVARCHAR(128), Type VARCHAR(10), TypDesc NVARCHAR(50), ParentName NVARCHAR(128), ObjectLevel INT );
DECLARE @mySchemaName NVARCHAR(50);
DECLARE @myTableName NVARCHAR(50);
DECLARE @myColumnName NVARCHAR(MAX);
DECLARE @myIncludeClusteredIndex BIT = 1;
DECLARE @myIncludeNonClusteredIndex BIT = 0;

SET NOCOUNT ON;
SET @mySchemaName = SUBSTRING( @Object, 0, CHARINDEX( '.', @Object ));
SET @myTableName = SUBSTRING( @Object, CHARINDEX( '.', @Object ) + 1, LEN( @Object ) - CHARINDEX( '.', @Object ));

INSERT INTO @myTable (ObjectName, Type, TypDesc, ParentName, ObjectLevel)
SELECT DISTINCT SCHEMA_NAME( myObject.[schema_id] ) + '.' + myObject.name AS ObjectName, myObject.type, myObject.type_desc AS TypDesc, NULL, 1
FROM sys.dm_sql_referenced_entities( @Object, 'OBJECT' ) AS myReferenced
INNER JOIN sys.objects AS myObject ON myReferenced.referenced_id = myObject.[object_id];

WHILE 1 = 1
BEGIN
    INSERT INTO @myTable (ObjectName, Type, TypDesc, ParentName, ObjectLevel)
    SELECT DISTINCT SCHEMA_NAME( myObject.[schema_id] ) + '.' + myObject.name AS ObjectName, myObject.type, myObject.type_desc AS TypDesc, myTable.ObjectName, myTable.ObjectLevel + 1 AS ObjectLevel
    FROM @myTable AS myTable
    CROSS APPLY sys.dm_sql_referenced_entities( myTable.ObjectName, 'OBJECT' ) AS myReferenced
    INNER JOIN sys.objects AS myObject ON myReferenced.referenced_id = myObject.[object_id]
    WHERE NOT EXISTS ( SELECT 1 FROM @myTable AS mySub WHERE myTable.ObjectName = mySub.ParentName );
    SET @RowCount = @@ROWCOUNT;
    IF @RowCount = 0
        BREAK;
END;

IF NOT EXISTS ( SELECT 1 FROM @myTable )
BEGIN
    INSERT INTO @myTable (ObjectName, Type, TypDesc, ParentName, ObjectLevel)
    SELECT DISTINCT SCHEMA_NAME( o.[schema_id] ) + '.' + o.name AS ObjectName, o.type, o.type_desc AS TypDesc, NULL, 1
    FROM sys.objects o
    WHERE SCHEMA_NAME( o.[schema_id] ) = @mySchemaName
          AND o.name = @myTableName;
END;

DECLARE myCursor CURSOR FOR
	SELECT ObjectName
	FROM @myTable AS myTable
	WHERE TypDesc = 'USER_TABLE'
		--AND NOT EXISTS(SELECT 1 FROM ssbs.InitiatorObject AS mySSBS WHERE mySSBS.TableName = myTable.ObjectName)
	GROUP BY ObjectName;
OPEN myCursor;
FETCH NEXT FROM myCursor INTO @myTableName;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @myColumnName = N'<ALL_COLUMNS>';
    SET @myIncludeClusteredIndex = 1;
    SET @myIncludeNonClusteredIndex = 0;
    EXECUTE ssbs.dbasp_create_initiator_object @TableName = @myTableName, @ColumnName = @myColumnName, @IncludeClusteredIndex = @myIncludeClusteredIndex, @IncludeNonClusteredIndex = @myIncludeNonClusteredIndex;
    PRINT CONCAT( '--', REPLICATE( '=', 150 ));
    FETCH NEXT FROM myCursor INTO @myTableName;
END;
CLOSE myCursor;
DEALLOCATE myCursor;