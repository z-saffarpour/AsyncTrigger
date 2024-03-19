Function ExecuteNonQuery {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $serverName,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $databaseName,
        [Parameter(Mandatory = $true, Position = 2)]
        [string] $query
    )
    $mySqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $mySqlCommand.CommandText = $query
    $mySqlCommand.Connection = Get-Connection -serverName $serverName -databaseName $databaseName
    $mySqlCommand.CommandTimeout = 0
    $mySqlCommand.Connection.Open()
    $mySqlCommand.ExecuteNonQuery() | Out-Null
    $mySqlCommand.Connection.Close()
}