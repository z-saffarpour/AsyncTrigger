function Get-InitiatorProcedureScript {
    param (
        [string]$TableName,
        [System.Collections.ArrayList] $ColumnList
    )
    $myColumnNameScript = [string]::Empty
    $myColumnCreateXMLScript = [string]::Empty
    $myColumnInsertScript = [string]::Empty
    $myColumnXMLScript = [string]::Empty
    $myColumnUpdateScript = [string]::Empty
    foreach ($myColumnItem in $myColumnList) {
        if (![string]::IsNullOrEmpty($myColumnNameScript)) {
            $myColumnNameScript = $myColumnNameScript + ",`n" 
        }
        $myColumnNameScript = $myColumnNameScript + "        [$($myColumnItem.Name)]" 

        if (![string]::IsNullOrEmpty($myColumnCreateXMLScript)) {
            $myColumnCreateXMLScript = $myColumnCreateXMLScript + ",`n" 
        }
        $myColumnCreateXMLScript = $myColumnCreateXMLScript + "	[$($myColumnItem.Name)] [$($myColumnItem.DataType)] " 
        if ($myColumnItem.CharacterMaximumLength -eq -1) {
            $myColumnCreateXMLScript = $myScript + "(MAX)"
        }
        elseif ($null -ne $myColumnItem.CharacterMaximumLength -and ![string]::IsNullOrEmpty($myColumnItem.CharacterMaximumLength)) {
            $myColumnCreateXMLScript = $myColumnCreateXMLScript + "($($myColumnItem.CharacterMaximumLength)) "
        }

        if (![string]::IsNullOrEmpty($myColumnXMLScript)) {
            $myColumnXMLScript = $myColumnXMLScript + ",`n" 
        }
        $myColumnXMLScript = $myColumnXMLScript + "           ISNULL([myData].[RECORD].value( '$($myColumnItem.Name)[1]', '$($myColumnItem.DataType)" 

        if ($myColumnItem.CharacterMaximumLength -eq -1) {
            $myColumnXMLScript = $myColumnXMLScript + "(MAX)"
        }
        elseif ($null -ne $myColumnItem.CharacterMaximumLength -and ![string]::IsNullOrEmpty($myColumnItem.CharacterMaximumLength)) {
            $myColumnXMLScript = $myColumnXMLScript + "($($myColumnItem.CharacterMaximumLength))"
        }

        if ($myColumnItem.DataType -eq "int" -or $myColumnItem.DataType -eq "bigint" -or $myColumnItem.DataType -eq "numeric" ) {
            $myColumnXMLScript = $myColumnXMLScript + "'),0)"
        }
        elseif ($myColumnItem.DataType -eq "nvarchar" ) {
            $myColumnXMLScript = $myColumnXMLScript + "'),'')"
        }
        elseif ($myColumnItem.DataType -eq "datetime" ) {
            $myColumnXMLScript = $myColumnXMLScript + "'),'1900-01-01')"
        }
        elseif ($myColumnItem.DataType -eq "uniqueidentifier" ) {
            $myColumnXMLScript = $myColumnXMLScript + "'),'{00000000-0000-0000-0000-000000000000}')"
        }
        else {
            $myColumnXMLScript = $myColumnXMLScript + "')"
        }

        $myColumnXMLScript = $myColumnXMLScript + " AS $($myColumnItem.Name)"

        if (![string]::IsNullOrEmpty($myColumnInsertScript)) {
            $myColumnInsertScript = $myColumnInsertScript + ",`n" 
        }
        $myColumnInsertScript = $myColumnInsertScript + "            [$($myColumnItem.Name)]" 

        if (![string]::IsNullOrEmpty($myColumnUpdateScript)) {
            $myColumnUpdateScript = $myColumnUpdateScript + ",`n" 
        }
        $myColumnUpdateScript = $myColumnUpdateScript + "            [myTarget].[$($myColumnItem.Name)] = [mySource].[$($myColumnItem.Name)]" 
    }

    $myScript = [string]::Empty
    $myScript = $myScript + "CREATE OR ALTER PROCEDURE [ssbs].[proc_$($TableName)]`n(`n    @myData XML,`n    @Operation VARCHAR(10)`n)`n"
    $myScript = $myScript + "AS`n"
    $myScript = $myScript + "BEGIN`n"
    $myScript = $myScript + "    SET NOCOUNT ON;`n"
    #$myScript = $myScript + "    CREATE TABLE #DataItemViaXML`n    (`n$($myColumnCreateXMLScript)`n    );`n"
    $myScript = $myScript + "    --Extract Request Item Parameters`n"
    #$myScript = $myScript + "    INSERT INTO #DataItemViaXML`n    (`n$($myColumnNameScript)`n    )`n"
    $myScript = $myScript + "    SELECT `n$($myColumnXMLScript)`n"
    $myScript = $myScript + "    INTO #DataItemViaXML`n"
    $myScript = $myScript + "    FROM @myData.nodes('/OKD365/RECORD') AS myData(RECORD);`n"
    $myScript = $myScript + "    --Delete`n"
    $myScript = $myScript + "    IF (@Operation = 'DELETE' AND EXISTS(SELECT 1 FROM #DataItemViaXML))`n"
    $myScript = $myScript + "    BEGIN`n"
    $myScript = $myScript + "        DELETE [myTarget]`n"
    $myScript = $myScript + "        FROM [ax].[$($TableName)] AS myTarget`n"
    $myScript = $myScript + "        INNER JOIN #DataItemViaXML AS mySource ON [myTarget].[RECID] = [mySource].[RecId];`n"
    $myScript = $myScript + "    END;`n"
    $myScript = $myScript + "    --Update`n"
    $myScript = $myScript + "    IF (@Operation = 'UPDATE' AND EXISTS(SELECT 1 FROM #DataItemViaXML))`n"
    $myScript = $myScript + "    BEGIN`n"
    $myScript = $myScript + "        UPDATE [myTarget]`n"
    $myScript = $myScript + "        SET`n$($myColumnUpdateScript)`n"
    $myScript = $myScript + "        FROM [ax].[$($TableName)] AS myTarget`n"
    $myScript = $myScript + "        INNER JOIN #DataItemViaXML AS mySource ON [mySource].[RECID] = [myTarget].[RecId];`n"
    $myScript = $myScript + "    END;`n"
    $myScript = $myScript + "    --Insert`n"
    $myScript = $myScript + "    IF (@Operation = 'INSERT' AND EXISTS(SELECT 1 FROM #DataItemViaXML))`n"
    $myScript = $myScript + "    BEGIN`n"
    $myScript = $myScript + "        INSERT INTO [ax].[$($TableName)]`n        (`n$($myColumnInsertScript)`n        )`n"
    $myScript = $myScript + "        SELECT `n$($myColumnInsertScript)`n"
    $myScript = $myScript + "        FROM #DataItemViaXML AS mySource;`n"
    $myScript = $myScript + "    END;`n"
    $myScript = $myScript + "    --Initialize`n"
    $myScript = $myScript + "    IF (@Operation = 'INITIALIZE' AND EXISTS(SELECT 1 FROM #DataItemViaXML))`n"
    $myScript = $myScript + "    BEGIN`n"
    $myScript = $myScript + "        TRUNCATE TABLE [ax].[$($TableName)];`n"
    $myScript = $myScript + "        INSERT INTO [ax].[$($TableName)]`n        (`n$($myColumnInsertScript)`n        )`n"
    $myScript = $myScript + "        SELECT `n$($myColumnInsertScript)`n"
    $myScript = $myScript + "        FROM #DataItemViaXML AS mySource;`n"
    $myScript = $myScript + "    END;`n"
    $myScript = $myScript + "END;"
    return , $myScript
}