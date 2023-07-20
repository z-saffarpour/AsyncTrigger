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
DECLARE @myObject NVARCHAR(128);
SET @myObject = N'dbo.REGIONVIEW';
DECLARE @myTable AS TABLE ( ObjectName NVARCHAR(128), Type VARCHAR(10), TypDesc NVARCHAR(50), ParentName NVARCHAR(128), ObjectLevel INT);
DECLARE @RowCount INT;

INSERT INTO @myTable (ObjectName, Type, TypDesc, ParentName, ObjectLevel)
SELECT DISTINCT SCHEMA_NAME( o.[schema_id] ) + '.' + o.name AS ObjectName, o.type, o.type_desc AS TypDesc, NULL,1
FROM sys.dm_sql_referenced_entities( @myObject, 'OBJECT' ) d
INNER JOIN sys.objects o ON d.referenced_id = o.[object_id];

WHILE 1 = 1
BEGIN
    INSERT INTO @myTable (ObjectName, Type, TypDesc, ParentName, ObjectLevel)
    SELECT DISTINCT SCHEMA_NAME( o.[schema_id] ) + '.' + o.name AS ObjectName, o.type, o.type_desc AS TypDesc, myTable.ObjectName , myTable.ObjectLevel + 1 AS ObjectLevel
    FROM @myTable AS myTable
    CROSS APPLY sys.dm_sql_referenced_entities( myTable.ObjectName, 'OBJECT' ) d
    INNER JOIN sys.objects o ON d.referenced_id = o.[object_id]
    WHERE NOT EXISTS ( SELECT 1 FROM @myTable AS mySub WHERE myTable.ObjectName = mySub.ParentName );
    SET @RowCount = @@ROWCOUNT;
    IF @RowCount = 0
        BREAK;
END;
SELECT ROW_NUMBER() OVER(ORDER BY CASE WHEN Type = 'U' THEN 1 WHEN Type = 'IF' THEN 2 WHEN Type = 'FN' THEN 3 WHEN Type = 'V' THEN 4 ELSE 6 END, myResult.ObjectLevel DESC) AS RowNumber, myResult.ObjectName, myResult.TypDesc,myResult.ObjectLevel
FROM
(
    SELECT ObjectName, Type, TypDesc, MAX(ObjectLevel) AS ObjectLevel
    FROM @myTable
	GROUP BY ObjectName, Type, TypDesc
) AS myResult