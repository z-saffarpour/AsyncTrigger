function Get-InitiatorIndexList {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$SchemaName,
        [string]$TableName,
        [string]$ColumnName,
        [string] $IndexType
    )
    $myClusteredIndexQuery = "SELECT myIndex.name as IndexName, myIndex.type_desc AS IndexType, STUFF(
    (
        SELECT ',' + QUOTENAME(myColumn.name)
        FROM sys.index_columns AS myIndexColumn
        INNER JOIN sys.columns AS myColumn ON myIndex.object_id = myColumn.object_id AND myColumn.column_id = myIndexColumn.column_id
        WHERE myIndexColumn.index_id = myIndex.index_id
              AND myIndexColumn.object_id = myIndex.object_id
              AND myColumn.name NOT IN ( 'DATAAREAID', 'DATAAREA', 'PARTITION' )
        FOR XML PATH( '' )
    ), 1, 1, '' ) as IndexColumns`nFROM sys.indexes AS myIndex`nWHERE myIndex.object_id = OBJECT_ID('$($SchemaName).$($TableName)')"

    if ($IndexType -eq "Clustered") {
        $myClusteredIndexQuery = $myClusteredIndexQuery + "`nAND myIndex.index_id = 1"
    }
    elseif ($IndexType -eq "NONClustered") {
        $myClusteredIndexQuery = $myClusteredIndexQuery + "`nAND myIndex.index_id > 1"
    }
    else {

    }
    $myIndexDataTable = ExecuteReader -serverName $ServerName -databaseName $DatabaseName -query $myClusteredIndexQuery
    $myIndexList = New-Object System.Collections.ArrayList
    foreach ($myIndexDataRow in $myIndexDataTable) {
        $myIndexItem = [PSCustomObject]@{
            IndexName    = [string]$myIndexDataRow["IndexName"];
            IndexType    = [string]$myIndexDataRow["IndexType"];
            IndexColumns = [string]$myIndexDataRow["IndexColumns"]
        }
        $myIndexList.Add($myIndexItem) | Out-Null
    }
    return , $myIndexList
}