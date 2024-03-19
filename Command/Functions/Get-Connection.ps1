#return Connection String
Function Get-Connection {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $serverName,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $databaseName
    )
    $mySqlConnection = New-Object System.Data.SqlClient.SqlConnection
    # Connectionstring setting for loclaluehine database with window authentication
    $mySqlConnection.ConnectionString = "server=$($serverName);database=$($databaseName);trusted_connection=True"
    return $mySqlConnection
}