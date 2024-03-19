function Get-TargetScript {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$SchemaName,
        [string]$TableName,
        [string]$ColumnName,
        [bool]$IncludeClusteredIndex,
        [bool]$IncludeNonClusteredIndex
    )
    $myScriptList = New-Object System.Collections.ArrayList
    $myScriptList.Add([PSCustomObject]@{SchemaName = $SchemaName; TableName = $TableName; ColumnName = $ColumnName; ObjectType = "Comment"; Script = "/*`n@FileName = $($SchemaName)_$($TableName)_TARGET.sql`n@myTableName = [$($SchemaName)].[$($TableName)]`n@myColumnName = $($myColumnName)`n*/" }) | Out-Null
    ##===================================================
    $myColumnList = Get-InitiatorColumnList -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -SchemaName $SchemaName -TableName $TableName -ColumnName $myColumnName
    $myColumnScript = Get-InitiatorColumnScript -ColumnList $myColumnList
    $myCreateTableScript = "DROP TABLE IF EXISTS [ax].[$($TableName)]`nCREATE TABLE [ax].[$($TableName)]`n(`n$($myColumnScript)`n) ON [FG_AX];"
    $myScriptList.Add([PSCustomObject]@{SchemaName = $SchemaName; TableName = $TableName; ColumnName = $ColumnName; ObjectType = "CREATE TABLE"; Script = $myCreateTableScript }) | Out-Null
    ##===================================================
    if ($IncludeClusteredIndex) {
        $myIndexList = Get-InitiatorIndexList -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -SchemaName $SchemaName -TableName $TableName -IndexType "Clustered"
        foreach ($myIndexItem in $myIndexList) {
            $myScriptItem = "CREATE $($myIndexItem.IndexType) INDEX [$($myIndexItem.IndexName)] ON [ax].[$($TableName)] ($($myIndexItem.IndexColumns))`nWITH (FILLFACTOR= 90, PAD_INDEX=ON, SORT_IN_TEMPDB=ON)`nON [FG_AX];"
            $myScriptList.Add([PSCustomObject]@{SchemaName = $SchemaName; TableName = $TableName; ColumnName = $ColumnName; ObjectType = "CREATE Clustered INDEX"; Script = $myScriptItem }) | Out-Null
        }
    }
    ##===================================================
    if ($IncludeNonClusteredIndex) {
        $myIndexList = Get-InitiatorIndexList -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -SchemaName $SchemaName -TableName $TableName -IndexType "NONClustered"
        foreach ($myIndexItem in $myIndexList) {
            $myScriptItem = "CREATE $($myIndexItem.IndexType) INDEX [$($myIndexItem.IndexName)] ON [ax].[$($TableName)] ($($myIndexItem.IndexColumns))`nWITH (FILLFACTOR= 90, PAD_INDEX=ON, SORT_IN_TEMPDB=ON)`nON [FG_AX];"
            $myScriptList.Add([PSCustomObject]@{SchemaName = $SchemaName; TableName = $TableName; ColumnName = $ColumnName; ObjectType = "CREATE NONClustered INDEX"; Script = $myScriptItem }) | Out-Null
        }
    }    
    ##===================================================
    $myProcedureScript = Get-InitiatorProcedureScript -TableName $TableName -ColumnList $myColumnList
    $myScriptList.Add([PSCustomObject]@{SchemaName = $SchemaName; TableName = $TableName; ColumnName = $ColumnName; ObjectType = "CREATE Procedure"; Script = $myProcedureScript }) | Out-Null
    return , $myScriptList
}