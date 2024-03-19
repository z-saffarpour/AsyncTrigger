function Get-InitiatorReferenceList {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$SchemaName,
        [string]$TableName
    )
    $myQuery = [string]::Empty
    $myQuery = $myQuery + "DECLARE @mySchemaName NVARCHAR(50);`nDECLARE @myTableName NVARCHAR(50);`nDECLARE @myObjectName NVARCHAR(100);`nDECLARE @myRowCount INT;`nDECLARE @myTable AS TABLE (ObjectID INT ,SchemaName NVARCHAR(128),TableName NVARCHAR(128), ObjectName NVARCHAR(128), Type VARCHAR(10), TypDesc NVARCHAR(50), ParentName NVARCHAR(128), ObjectLevel INT );`n"
    $myQuery = $myQuery + "SET @mySchemaName = '$($SchemaName)';`nSET @myTableName = '$($TableName)';`nSET @myObjectName = @mySchemaName + '.' + @myTableName`nSET NOCOUNT ON;`n"
    $myQuery = $myQuery + "INSERT INTO @myTable (ObjectID, SchemaName, TableName, ObjectName, Type, TypDesc, ParentName, ObjectLevel)`n"
    $myQuery = $myQuery + "SELECT DISTINCT myObject.object_id, SCHEMA_NAME(myObject.[schema_id]) AS SchemaName, myObject.name AS TableName, SCHEMA_NAME(myObject.[schema_id]) + '.' + myObject.name AS ObjectName, myObject.type AS Type, myObject.type_desc AS TypDesc, NULL AS ParentName, 1 AS ObjectLevel`n"
    $myQuery = $myQuery + "FROM sys.dm_sql_referenced_entities(@myObjectName, 'OBJECT' ) AS myReferenced`n"
    $myQuery = $myQuery + "INNER JOIN sys.objects AS myObject ON myReferenced.referenced_id = myObject.[object_id];`n"
    $myQuery = $myQuery + "WHILE 1 = 1`n"
    $myQuery = $myQuery + "BEGIN`n"
    $myQuery = $myQuery + "    INSERT INTO @myTable (ObjectID, SchemaName, TableName, ObjectName, Type, TypDesc, ParentName, ObjectLevel)`n"
    $myQuery = $myQuery + "    SELECT DISTINCT myObject.object_id, SCHEMA_NAME(myObject.[schema_id]) AS SchemaName, myObject.name AS TableName, SCHEMA_NAME(myObject.[schema_id]) + '.' + myObject.name AS ObjectName, myObject.type, myObject.type_desc AS TypDesc, myTable.ObjectName, myTable.ObjectLevel + 1 AS ObjectLevel`n"
    $myQuery = $myQuery + "    FROM @myTable AS myTable`n"
    $myQuery = $myQuery + "    CROSS APPLY sys.dm_sql_referenced_entities( myTable.ObjectName, 'OBJECT' ) AS myReferenced`n"
    $myQuery = $myQuery + "    INNER JOIN sys.objects AS myObject ON myReferenced.referenced_id = myObject.[object_id]`n"
    $myQuery = $myQuery + "    WHERE NOT EXISTS (SELECT 1 FROM @myTable AS mySub WHERE mySub.ObjectID = myObject.[object_id]);`n"
    $myQuery = $myQuery + "    SET @myRowCount = @@ROWCOUNT;`n"
    $myQuery = $myQuery + "    IF @myRowCount = 0`n"
    $myQuery = $myQuery + "        BREAK;`n"
    $myQuery = $myQuery + "END;`n"
    $myQuery = $myQuery + "IF NOT EXISTS ( SELECT 1 FROM @myTable )`n"
    $myQuery = $myQuery + "BEGIN`n"
    $myQuery = $myQuery + "    INSERT INTO @myTable (ObjectID, SchemaName, TableName, ObjectName, Type, TypDesc, ParentName, ObjectLevel)`n"
    $myQuery = $myQuery + "    SELECT DISTINCT myObject.object_id, SCHEMA_NAME(myObject.[schema_id]) AS SchemaName, myObject.name AS TableName,SCHEMA_NAME(myObject.[schema_id]) + '.' + myObject.name AS ObjectName, myObject.type AS Type, myObject.type_desc AS TypDesc, NULL AS ParentName, 1 AS ObjectLevel`n"
    $myQuery = $myQuery + "    FROM sys.objects AS myObject`n"
    $myQuery = $myQuery + "    WHERE SCHEMA_NAME( myObject.[schema_id] ) = @mySchemaName AND myObject.name = @myTableName;`n"
    $myQuery = $myQuery + "END;`n"
    $myQuery = $myQuery + "SELECT SchemaName, TableName, ObjectName, Type, TypDesc, ParentName, ObjectLevel`n"
    $myQuery = $myQuery + "FROM @myTable AS myTable`n"
    #$myQuery = $myQuery + "WHERE NOT EXISTS(SELECT 1 FROM ssbs.TargetObject AS mySSBS WHERE mySSBS.TableName = myTable.ObjectName)`n"

    $myDataTable = ExecuteReader -serverName $InitiatorServer -databaseName $InitiatorDatabase -query $myQuery

    $myList = New-Object System.Collections.ArrayList
    foreach ($myDataRow in $myDataTable) {
        $myItem = [PSCustomObject]@{
            SchemaName  = $myDataRow["SchemaName"];
            TableName   = $myDataRow["TableName"];
            ObjectName  = $myDataRow["ObjectName"];
            Type        = $myDataRow["Type"];
            TypDesc     = $myDataRow["TypDesc"];
            ParentName  = $myDataRow["ParentName"];
            ObjectLevel = $myDataRow["ObjectLevel"];
        }
        $myList.Add($myItem) | Out-Null
    }
    return , $myList
}