
function Log-InitiatorTargetObject {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$TableName,
        [string]$ColumnName,
        [bool]$IncludeClusteredIndex,
        [bool]$IncludeNonClusteredIndex
    )
    if ($IncludeClusteredIndex) {
        $myIncludeClusteredIndex = "1"
    }
    else {
        $myIncludeClusteredIndex = "0"
    }
    if ($IncludeNonClusteredIndex) {
        $myIncludeNonClusteredIndex = "1"
    }
    else {
        $myIncludeNonClusteredIndex = "0"
    }
    $myQuery = "INSERT INTO ssbs.TargetObject (TableName, IncludeClusteredIndex, IncludeNonClusteredIndex, ColumnName, ServerName, AppName, Username, Hostname, InsertDatetime)"
    $myQuery = $myQuery + "VALUES('$($TableName)',$($myIncludeClusteredIndex),$($myIncludeNonClusteredIndex),'$($ColumnName)',CAST(@@SERVERNAME AS NVARCHAR(128)),CAST(APP_NAME() AS NVARCHAR(256)), CAST(SUSER_SNAME() AS NVARCHAR(128)),CAST(HOST_NAME() AS NVARCHAR(128)), GETDATE());"
    ExecuteNonQuery -serverName $InitiatorServer -databaseName $InitiatorDatabase -query $myQuery
}
