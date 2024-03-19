function Get-InitiatorColumnScript {
    param (
        [System.Collections.ArrayList] $ColumnList
    )
    $myScript = [string]::Empty
    foreach ($myColumnItem in $myColumnList) {
        $myScript = $myScript + "	[$($myColumnItem.Name)] [$($myColumnItem.DataType)] " 
        if ($myColumnItem.CharacterMaximumLength -eq -1) {
            $myScript = $myScript + "(MAX)"
        }
        elseif ($null -ne $myColumnItem.CharacterMaximumLength -and ![string]::IsNullOrEmpty($myColumnItem.CharacterMaximumLength)) {
            $myScript = $myScript + "($($myColumnItem.CharacterMaximumLength)) "
        }
        if ($myColumnItem.IsNullable -eq "NO") {
            $myScript = $myScript + "NOT NULL "
        }
        else {
            $myScript = $myScript + "NULL "
        }
        $myScript = $myScript + ",`n"
    }
    return , $myScript
}