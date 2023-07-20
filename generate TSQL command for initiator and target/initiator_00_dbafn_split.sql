USE SSBSInitiator
GO
-- =============================================  
-- Author:  <Golchoobian>  
-- Create date: <9/25/2013>  
-- Version:  <3.0.0.0>  
-- Description: <convert comma seperated string values to table of string values>  
-- Input Parameters:  
-- @delimiter:  'x' //Any single character used for spiliting string  
-- @array_string: '...' //Any string  
-- =============================================  
CREATE OR ALTER FUNCTION ssbs.[dbafn_split]
(   
	 -- Add the parameters for the function here  
	 @delimiter nvarchar(4000) = N',',   
	 @array_string nvarchar(MAX)  
)  
RETURNS TABLE   
AS  
RETURN   
(  
    WITH Pieces(Position, [start], [stop]) 
	AS 
	(  
      SELECT CAST(1 AS BIGINT), CAST(1 AS BIGINT), CAST(CHARINDEX(@delimiter, @array_string) AS BIGINT)  
      UNION ALL  
      SELECT CAST(Position + 1 AS BIGINT), CAST([stop] + 1 AS BIGINT), CAST(CHARINDEX(@delimiter, @array_string, [stop] + 1) AS BIGINT)  
      FROM Pieces  
      WHERE [stop] > 0  
    )  
    SELECT Position,  
      SUBSTRING(@array_string, [start], CASE WHEN [stop] > 0 THEN [stop]-[start] ELSE LEN(@array_string) END) AS Parameter  
    FROM Pieces  
)  
  
GO

