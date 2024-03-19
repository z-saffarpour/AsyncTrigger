function Get-InitiatorColumnList {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$SchemaName,
        [string]$TableName,
        [string]$ColumnName
    )
    $myColumnListQuery = "SELECT [Name], [DataType], [CharacterMaximumLength], [IsNullable] `nFROM [ssbs].[dbafn_column_list] ('$($SchemaName)','$($TableName)','$($ColumnName)',1,0);"
    $myColumnListDataTable = ExecuteReader -serverName $ServerName -databaseName $DatabaseName -query $myColumnListQuery
    $myColumnList = New-Object System.Collections.ArrayList
    foreach ($myColumnListDataRow in $myColumnListDataTable) {
        $myColumnItem = [PSCustomObject]@{
            Name                   = [string]$myColumnListDataRow["Name"];
            DataType               = [string]$myColumnListDataRow["DataType"];
            CharacterMaximumLength = [string]$myColumnListDataRow["CharacterMaximumLength"];
            IsNullable             = [string]$myColumnListDataRow["IsNullable"]
        }
        $myColumnList.Add($myColumnItem) | Out-Null
    }
    return , $myColumnList
}
