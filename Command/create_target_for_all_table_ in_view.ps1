##===================================================================================================================
Param
(
    [string]$InitiatorServer = "127.0.0.1\NODE",
    [string]$InitiatorDatabase = "AXDB",
    [string]$TargetServer = "127.0.0.1\NODE",
    [string]$TargetDatabase = "OperationalDB",
    [string]$TableName = "HCMPERSONALCONTACTRELATIONSHIP",
    [string]$ColumnName = '<ALL_COLUMNS>',
    [bool]$IncludeClusteredIndex = $true,
    [bool]$IncludeNonClusteredIndex = $false,
    [string]$OutputPath = 'C:\Dump\AsyncTrigger',
    [bool]$ReCreate = $true,
    [bool]$PrintOnly = $false
)
Clear-Host
##--==============================================================================================================
#Set-Location "$((Get-Location).path)\Command"
$ScriptRoot = (Get-Location).path
$myScriptItems = Get-ChildItem "$($ScriptRoot)\Functions" -Recurse -Include *.ps1
foreach ($myScriptItem in $myScriptItems) { 
    $myScriptItem.FullName
    . $myScriptItem.FullName
}
##===================================================================================================================
$myScriptList = New-Object System.Collections.ArrayList
$myResultList = New-Object System.Collections.ArrayList
$mySchemaName = [string]::Empty
$myTableName = [string]::Empty
$myFileName = [string]::Empty
##===================================================================================================================
$myTableSplited = $TableName.Split('.')
if ($myTableSplited.Count -eq 2) {
    $mySchemaName = $myTableSplited[0]
    $myTableName = $myTableSplited[1]
}
else {
    $mySchemaName = "dbo"
    $myTableName = $myTableSplited[0]
}
$myFileName = "$($mySchemaName)_$($myTableName)_TARGET.sql"
$myColumnName = '<INCLUDE:RECID,CreatedDatetime,ModifiedDatetime,DATAAREA,DATAAREAID><EXCLUDE:PARTITION,RecVersion,CREATEDBY,MODIFIEDBY,SHA1HASHHEX,SHA3HASHHEX,SID,HASH>' 
$myColumnName = $myColumnName + ',' + $ColumnName
$myTargetObjectList = Get-InitiatorTargetObject -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase
$myInitiatorList = Get-InitiatorReferenceList -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -SchemaName $mySchemaName $TableName $myTableName
foreach ($myInitiatorItem in $myInitiatorList) {
    $myInitiatorSchemaName = $myInitiatorItem.SchemaName
    $myInitiatorTableName = $myInitiatorItem.TableName
    if ($myInitiatorItem.TypDesc -eq "USER_TABLE") {
        if ($ReCreate -eq $true) {
            $myTargetScriptList = Get-TargetScript -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -SchemaName $myInitiatorSchemaName -TableName $myInitiatorTableName -ColumnName $myColumnName -IncludeClusteredIndex $IncludeClusteredIndex -IncludeNonClusteredIndex $IncludeNonClusteredIndex
            $myScriptList.AddRange($myTargetScriptList) | Out-Null
        }
        elseif (!($myTargetObjectList | Where-Object { $_.TableName -eq $($myInitiatorItem.ObjectName) })) {
            $myTargetScriptList = Get-TargetScript -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -SchemaName $myInitiatorSchemaName -TableName $myInitiatorTableName -ColumnName $myColumnName -IncludeClusteredIndex $IncludeClusteredIndex -IncludeNonClusteredIndex $IncludeNonClusteredIndex
            $myScriptList.AddRange($myTargetScriptList) | Out-Null
        }
    }
}
##===================================================================================================================
if ($PrintOnly -eq $false) {
    foreach ($myScriptItem in $myScriptList) {
        try {
            $myScript = $myScriptItem.Script
            ExecuteNonQuery -serverName $TargetServer -databaseName $TargetDatabase -query $myScript 
            $myResultList.Add($myScript) | Out-Null
            $myScript = "GO"
            $myResultList.Add($myScript) | Out-Null
            if ($myScriptItem.ObjectType -eq "CREATE Procedure") {
                $myObjectName = "$($myScriptItem.SchemaName).$($myScriptItem.TableName)"
                $myColumnName = $myScriptItem.ColumnName
                Log-InitiatorTargetObject -ServerName $InitiatorServer -DatabaseName $InitiatorDatabase -TableName $myObjectName -ColumnName $myColumnName -IncludeClusteredIndex $IncludeClusteredIndex -IncludeNonClusteredIndex $IncludeNonClusteredIndex
                
                $myScript = "GO"
                $myResultList.Add($myScript) | Out-Null
                $myScript = "--" + ("=" * 50)
                $myResultList.Add($myScript) | Out-Null
            }
        }
        catch {
            Write-Host $_ -ForegroundColor Red
            Write-Host $myScriptItem
        }
    }
}
else {
    foreach ($myScriptItem in $myScriptList) {
        $myScript = $myScriptItem.Script
        $myResultList.Add($myScript) | Out-Null
        $myScript = "GO"
        $myResultList.Add($myScript) | Out-Null
        if ($myScriptItem.ObjectType -eq "CREATE Procedure") {
            $myScript = "--" + ("=" * 50)
            $myResultList.Add($myScript) | Out-Null
        }
    }
}
##===================================================================================================================
if ($myResultList.Count -gt 0) {
    if (!(Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory | Out-Null
    }
    $myFilePath = Join-Path -Path $OutputPath -ChildPath $myFileName
    $myResultList | Out-File -FilePath $myFilePath
}