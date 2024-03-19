function Get-InitiatorTargetObject {
    param (
        [string]$ServerName,
        [string]$DatabaseName
    )
    $myList = New-Object System.Collections.ArrayList
    $myQuery = "SELECT TableName, ColumnName FROM ssbs.TargetObject ORDER BY RECID DESC"
    $myDataTable = ExecuteReader -serverName $ServerName -databaseName $DatabaseName -query $myQuery
    foreach ($myDataRow in $myDataTable) {
        $myList.Add([PSCustomObject]@{TableName = $myDataRow["TableName"]; ColumnName = $myDataRow["ColumnName"] }) | Out-Null
    }
    return , $myList
}
